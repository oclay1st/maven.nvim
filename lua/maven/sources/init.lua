local scan = require('plenary.scandir')
local curl = require('plenary.curl')
local Project = require('maven.sources.project')
local MavenConfig = require('maven.config')
local Path = require('plenary.path')
local PomParser = require('maven.parsers.pom_xml_parser')
local EffectivePomParser = require('maven.parsers.epom_xml_parser')
local DependencyTreeParser = require('maven.parsers.dependency_tree_parser')
local PluginXmlParser = require('maven.parsers.plugin_xml_parser')
local HelpOptionsParser = require('maven.parsers.help_options_parser')
local ArchetypeCatalogParser = require('maven.parsers.archetype_catalog_parser')
local ArchetypeJsonParser = require('maven.parsers.archetype_json_parser')
local CommandBuilder = require('maven.utils.cmd_builder')
local Utils = require('maven.utils')
local console = require('maven.utils.console')

local pom_xml_file_pattern = '**/pom.xml$'

local M = {}

local scanned_pom_list ---@type string[]

local custom_commands ---@type string[]

local create_custom_commands = function()
  local _commands = {}
  for index, custom_command in ipairs(MavenConfig.options.custom_commands) do
    _commands[index] =
      Project.Command(custom_command.name, custom_command.description, custom_command.cmd_args)
  end
  return _commands
end

M.create_project_from_pom = function(pom_xml_path)
  local pom = PomParser.parse_file(pom_xml_path)
  local project_path = pom_xml_path:gsub(pom_xml_file_pattern, '')
  local project =
    Project.new(project_path, pom_xml_path, pom.group_id, pom.artifact_id, pom.version, pom.name)
  project:set_commands(custom_commands)
  for _, module_path in ipairs(pom.module_paths) do
    local module_pom = Path:new(project_path, module_path, 'pom.xml') ---@type Path
    local module_pom_path = module_pom:absolute()
    if module_pom:exists() and not vim.tbl_contains(scanned_pom_list, module_pom_path) then
      local module_project = M.create_project_from_pom(module_pom_path)
      project:add_module(module_project)
      table.insert(scanned_pom_list, module_pom_path)
    end
  end
  return project
end

---Load the maven projects given a directory
---@param base_path string
M.scan_projects = function(base_path, callback)
  scanned_pom_list = {}
  custom_commands = create_custom_commands()
  local projects = {}
  scan.scan_dir_async(base_path, {
    search_pattern = pom_xml_file_pattern,
    depth = 10,
    on_insert = function(pom_xml_path, _)
      if not vim.tbl_contains(scanned_pom_list, pom_xml_path) then
        local project = M.create_project_from_pom(pom_xml_path)
        table.insert(projects, project)
        table.insert(scanned_pom_list, pom_xml_path)
      end
    end,
    on_exit = function()
      callback(projects)
    end,
  })
end

M.load_project_dependencies = function(pom_xml_path, callback)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.txt'
  local _callback = function(state)
    local dependencies
    if Utils.SUCCEED_STATE == state then
      local file_path = Path:new(output_dir, output_filename)
      dependencies = DependencyTreeParser.parse_file(file_path:absolute())
      file_path:rm()
    end
    callback(state, dependencies)
  end
  local command =
    CommandBuilder.build_mvn_dependencies_cmd(pom_xml_path, output_dir, output_filename)
  local show_output = MavenConfig.options.console.show_dependencies_load_execution
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_project_plugins = function(pom_xml_path, callback)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.epom'
  local file_path = Path:new(output_dir, output_filename)
  local absolute_file_path = file_path:absolute()
  local _callback = function(state)
    local plugins
    if Utils.SUCCEED_STATE == state then
      local epom = EffectivePomParser.parse_file(absolute_file_path)
      file_path:rm()
      plugins = vim.tbl_map(function(item)
        return Project.Plugin(item.group_id, item.artifact_id, item.version)
      end, epom.plugins)
    end
    callback(state, plugins)
  end
  local command = CommandBuilder.build_mvn_effective_pom_cmd(pom_xml_path, absolute_file_path)
  local show_output = MavenConfig.options.console.show_plugins_load_execution
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_project_plugin_details = function(group_id, artifact_id, version, callback)
  local _callback = function(state, job)
    local plugin
    if Utils.SUCCEED_STATE == state then
      local xml_content = table.concat(job:result(), ' ')
      plugin = PluginXmlParser.parse(xml_content)
    end
    callback(state, plugin)
  end
  local jar_file_path = Path:new(
    Utils.maven_local_repository_path,
    string.gsub(group_id, '%.', Path.path.sep),
    artifact_id,
    version,
    artifact_id .. '-' .. version .. '.jar'
  ):absolute()
  local command = CommandBuilder.build_read_zip_file_cmd(jar_file_path, Utils.maven_plugin_xml_path)
  console.execute_command(command.cmd, command.args, false, _callback)
end

M.load_help_options = function(callback)
  local _callback = function(state, job)
    local help_options
    if Utils.SUCCEED_STATE == state then
      local output_lines = job:result()
      help_options = HelpOptionsParser.parse(output_lines)
    end
    callback(state, help_options)
  end
  local command = CommandBuilder.build_mvn_help_cmd()
  console.execute_command(command.cmd, command.args, false, _callback)
end

M.load_archetype_catalog = function(callback)
  if Utils.archetypes_json_path:exists() then
    local archetypes = ArchetypeJsonParser:parse_file(Utils.archetypes_json_path:absolute())
    callback(archetypes)
  elseif Utils.local_catalog_path:exists() then
    local catalog_path = Utils.local_catalog_path:absolute()
    local archetypes = ArchetypeCatalogParser.parse_file(catalog_path)
    callback(archetypes)
    ArchetypeJsonParser:export(archetypes, Utils.archetypes_json_path:absolute())
  elseif Utils.local_central_catalog_path:exists() then
    local catalog_path = Utils.local_central_catalog_path:absolute()
    local archetypes = ArchetypeCatalogParser.parse_file(catalog_path)
    callback(archetypes)
    ArchetypeJsonParser:export(archetypes, Utils.archetypes_json_path:absolute())
  else
    local catalog_path = Utils.local_catalog_path:absolute()
    curl.get(Utils.archetypes_catalog_url, {
      output = catalog_path,
      callback = function()
        vim.schedule(function()
          local archetypes = ArchetypeCatalogParser.parse_file(catalog_path)
          callback(archetypes)
          ArchetypeJsonParser:export(archetypes, Utils.archetypes_json_path:absolute())
        end)
      end,
      on_error = function(message)
        vim.notify(message, vim.log.levels.ERROR)
      end,
    })
  end
end

M.load_default_archetype_catalog = function()
  ---@type  Path
  local catalog_path = Path:new(Utils.get_plugin_root_dir(), 'sources', 'default_archetypes.json')
  return ArchetypeJsonParser:parse_file(catalog_path:absolute())
end

M.setup = function()
  ---@type Path
  local data_path = Path:new(Utils.maven_data_path)
  if not data_path:exists() then
    data_path:mkdir()
  end
end

return M
