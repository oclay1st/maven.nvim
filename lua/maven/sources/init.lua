local scan = require('plenary.scandir')
local Project = require('maven.sources.project')
local MavenConfig = require('maven.config')
local Path = require('plenary.path')
local PomParser = require('maven.parsers.pom_xml_parser')
local EffectivePomParser = require('maven.parsers.epom_xml_parser')
local DependencyTreeParser = require('maven.parsers.dependency_tree_parser')
local PluginXmlParser = require('maven.parsers.plugin_xml_parser')
local CommandBuilder = require('maven.utils.cmd_builder')
local Utils = require('maven.utils')
local Console = require('maven.utils.console')
local console = Console.new()

local pom_xml_file_pattern = '**/pom.xml$'

local M = {}

local create_custom_commands = function()
  local custom_commands = {}
  for index, custom_command in ipairs(MavenConfig.options.custom_commands) do
    custom_commands[index] =
      Project.Command(custom_command.name, custom_command.description, custom_command.cmd_args)
  end
  return custom_commands
end

local create_project_from_pom = function(pom_xml_path)
  local pom = PomParser.parse_file(pom_xml_path)
  local project_path = pom_xml_path:gsub(pom_xml_file_pattern, '')
  return Project:new(
    project_path,
    pom_xml_path,
    pom.group_id,
    pom.artifact_id,
    pom.version,
    pom.name
  )
end

---Load the maven projects given a directory
---@param base_path string
---@return Project[]
M.scan_projects = function(base_path)
  local projects = {}
  local custom_commands = create_custom_commands()
  scan.scan_dir(base_path, {
    search_pattern = pom_xml_file_pattern,
    depth = 10,
    on_insert = function(pom_xml_path, _)
      local project = create_project_from_pom(pom_xml_path)
      project:set_commands(custom_commands)
      table.insert(projects, project)
    end,
  })
  return projects
end

M.load_project_dependencies = function(pom_xml_path, callback)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.txt'
  local _on_success = function()
    local file_path = Path:new(output_dir, output_filename)
    local dependencies = DependencyTreeParser.parse_file(file_path:absolute())
    file_path:rm()
    callback(dependencies)
  end
  local _on_failure = function()
    callback(nil)
  end
  local command =
    CommandBuilder.build_mvn_dependencies_cmd(pom_xml_path, output_dir, output_filename)
  local show_output = MavenConfig.options.console.show_dependencies_load_execution
  console:execute_command(command.cmd, command.args, show_output, _on_success, _on_failure)
end

M.load_project_plugins = function(pom_xml_path, callback)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.epom'
  local file_path = Path:new(output_dir, output_filename)
  local absolute_file_path = file_path:absolute()
  local _on_success = function()
    local epom = EffectivePomParser.parse_file(absolute_file_path)
    file_path:rm()
    local plugins = vim.tbl_map(function(item)
      return Project.Plugin(item.group_id, item.artifact_id, item.version)
    end, epom.plugins)
    callback(plugins)
  end
  local _on_failure = function()
    callback(nil)
  end
  local command = CommandBuilder.build_mvn_effective_pom_cmd(pom_xml_path, absolute_file_path)
  local show_output = MavenConfig.options.console.show_plugins_load_execution
  console:execute_command(command.cmd, command.args, show_output, _on_success, _on_failure)
end

M.load_project_plugin_details = function(group_id, artifact_id, version, callback)
  local _on_success = function(job)
    local xml_content = table.concat(job:result(), ' ')
    local plugin = PluginXmlParser.parse(xml_content)
    callback(plugin)
  end
  local _on_failure = function()
    callback(nil)
  end
  local jar_file_path = Path:new(
    Utils.maven_local_repository_path,
    string.gsub(group_id, '%.', Path.path.sep),
    artifact_id,
    version,
    artifact_id .. '-' .. version .. '.jar'
  ):absolute()
  local command = CommandBuilder.build_read_zip_file_cmd(jar_file_path, Utils.maven_plugin_xml_path)
  console:execute_command(command.cmd, command.args, false, _on_success, _on_failure)
end

return M
