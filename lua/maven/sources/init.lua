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
local ProjectsCacheParser = require('maven.parsers.projects_cache_parser')
local PluginsCacheParser = require('maven.parsers.plugins_cache_parser')
local HelpOptionsCacheParser = require('maven.parsers.help_options_cache_parser')
local CommandBuilder = require('maven.utils.cmd_builder')
local Utils = require('maven.utils')
local console = require('maven.utils.console')

local pom_xml_file_pattern = '**/pom.xml$'

local M = {}

local scanned_pom_list ---@type string[]

local custom_commands ---@type string[]

---Sort all projects and modules
---@param projects Project[]
local function sort_projects(projects)
  table.sort(projects, function(a, b)
    return string.lower(a.name) < string.lower(b.name)
  end)
  for _, project in ipairs(projects) do
    if #project.modules ~= 0 then
      sort_projects(project.modules)
    end
  end
end

local create_custom_commands = function()
  local _commands = {}
  for index, custom_command in ipairs(MavenConfig.options.projects_view.custom_commands) do
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

--- Load the project cache
--- @param pom_xml_path string
--- @return ProjectCache | nil
M.load_project_cache = function(pom_xml_path)
  local projects_cache = ProjectsCacheParser:parse()
  for _, item in ipairs(projects_cache) do
    if item.path == pom_xml_path then
      return item
    end
  end
end

---Load the maven projects given a directory
---@param base_path string
M.scan_projects = function(base_path, callback)
  scanned_pom_list = {}
  custom_commands = create_custom_commands()
  local projects = {}
  scan.scan_dir_async(base_path, {
    search_pattern = pom_xml_file_pattern,
    depth = MavenConfig.options.project_scanner_depth,
    on_insert = function(pom_xml_path, _)
      if not vim.tbl_contains(scanned_pom_list, pom_xml_path) then
        local project = M.create_project_from_pom(pom_xml_path)
        table.insert(projects, project)
        table.insert(scanned_pom_list, pom_xml_path)
      end
    end,
    on_exit = function()
      sort_projects(projects)
      callback(projects)
    end,
  })
end

M.load_project_dependencies = function(pom_xml_path, force, callback)
  if not force and M.load_dependencies_cache(pom_xml_path, callback) then
    return
  end
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.txt'
  local show_output = MavenConfig.options.console.show_dependencies_load_execution
  local _callback = function(state)
    local dependencies
    if state == Utils.SUCCEED_STATE then
      local dependency_tree_path = Path:new(output_dir, output_filename)
      dependencies = DependencyTreeParser.parse_file(dependency_tree_path:absolute())
      M.create_dependencies_cache(pom_xml_path, dependency_tree_path)
      dependency_tree_path:rm()
    elseif state == Utils.FAILED_STATE then
      local error_msg = 'Error loading dependencies. '
      if not show_output then
        error_msg = error_msg .. 'Enable the console output for more details.'
      end
      vim.notify(error_msg, vim.log.levels.ERROR)
    end
    callback(state, dependencies)
  end
  local command =
    CommandBuilder.build_mvn_dependencies_cmd(pom_xml_path, output_dir, output_filename)
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

--- Load the dependencies cache
--- @param pom_xml_path string
--- @param callback function
--- @return boolean
M.load_dependencies_cache = function(pom_xml_path, callback)
  if not MavenConfig.options.cache.enable_dependencies_cache then
    return false
  end
  local project_cache = M.load_project_cache(pom_xml_path)
  if not project_cache then
    return false
  end
  local cache_path = Path:new(Utils.maven_cache_path, 'dependencies', project_cache.key .. '.txt')
  if not cache_path:exists() then
    return false
  end
  local dependencies = DependencyTreeParser.parse_file(cache_path:absolute())
  if #dependencies == 0 then
    return false
  end
  callback(Utils.SUCCEED_STATE, dependencies)
  return true
end

---Create the dependencies cache
---@param pom_xml_path string
---@param dependency_tree_path Path
M.create_dependencies_cache = function(pom_xml_path, dependency_tree_path)
  if not MavenConfig.options.cache.enable_dependencies_cache then
    return
  end
  local key = ProjectsCacheParser.register(pom_xml_path)
  ---@type Path
  local dependencies_cache_path = Path:new(Utils.maven_cache_path, 'dependencies')
  if not dependencies_cache_path:exists() then
    dependencies_cache_path:mkdir()
  end
  local cache_path = dependencies_cache_path:joinpath(key .. '.txt')
  dependency_tree_path:copy({ destination = cache_path })
end

M.load_project_plugins = function(pom_xml_path, force, callback)
  if not force and M.load_plugins_cache(pom_xml_path, callback) then
    return
  end
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.epom'
  local file_path = Path:new(output_dir, output_filename)
  local absolute_file_path = file_path:absolute()
  local show_output = MavenConfig.options.console.show_plugins_load_execution
  local _callback = function(state)
    local plugins
    if state == Utils.SUCCEED_STATE then
      local epom = EffectivePomParser.parse_file(absolute_file_path)
      file_path:rm()
      -- map to a plugin list
      plugins = vim.tbl_map(function(item)
        return Project.Plugin(item.group_id, item.artifact_id, item.version)
      end, epom.plugins)
      -- sort the plugin list
      table.sort(plugins, function(a, b)
        return string.lower(a:get_short_name()) < string.lower(b:get_short_name())
      end)
      M.create_plugins_cache(pom_xml_path, plugins)
    elseif state == Utils.FAILED_STATE then
      local error_msg = 'Error loading plugins. '
      if not show_output then
        error_msg = error_msg .. 'Enable the console output for more details.'
      end
      vim.notify(error_msg, vim.log.levels.ERROR)
    end
    callback(state, plugins)
  end
  local command = CommandBuilder.build_mvn_effective_pom_cmd(pom_xml_path, absolute_file_path)
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_plugins_cache = function(pom_xml_path, callback)
  if not MavenConfig.options.cache.enable_plugins_cache then
    return false
  end
  local project_cache = M.load_project_cache(pom_xml_path)
  if not project_cache then
    return false
  end
  local plugins = PluginsCacheParser.parse(project_cache.key)
  if #plugins == 0 then
    return false
  end
  callback(Utils.SUCCEED_STATE, plugins)
  return true
end

M.create_plugins_cache = function(pom_xml_path, plugins)
  if not MavenConfig.options.cache.enable_plugins_cache then
    return
  end
  local key = ProjectsCacheParser.register(pom_xml_path)
  PluginsCacheParser.dump(key, plugins)
end

M.load_project_plugin_details = function(group_id, artifact_id, version, callback)
  local _callback = function(state, job)
    local plugin
    if state == Utils.SUCCEED_STATE then
      local xml_content = table.concat(job:result(), ' ')
      plugin = PluginXmlParser.parse(xml_content)
    elseif state == Utils.FAILED_STATE then
      vim.notify('Error loading plugin details.', vim.log.levels.ERROR)
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

M.load_help_options = function(force, callback)
  if not force and M.load_help_options_cache(callback) then
    return
  end
  local _callback = function(state, job)
    local help_options
    if state == Utils.SUCCEED_STATE then
      local output_lines = job:result()
      help_options = HelpOptionsParser.parse(output_lines)
      M.create_help_options_cache(help_options)
    elseif state == Utils.FAILED_STATE then
      vim.notify('Error loading help options.', vim.log.levels.ERROR)
    end
    callback(state, help_options)
  end
  local command = CommandBuilder.build_mvn_help_cmd()
  console.execute_command(command.cmd, command.args, false, _callback)
end

M.load_help_options_cache = function(callback)
  if not MavenConfig.options.cache.enable_help_options_cache then
    return false
  end
  local options = HelpOptionsCacheParser.parse()
  if #options == 0 then
    return false
  end
  callback(Utils.SUCCEED_STATE, options)
  return true
end

M.create_help_options_cache = function(options)
  if not MavenConfig.options.cache.enable_help_options_cache then
    return
  end
  HelpOptionsCacheParser.dump(options)
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
  ---
  local data_path = Path:new(Utils.maven_data_path)
  if not data_path:exists() then
    data_path:mkdir()
  end
end

return M
