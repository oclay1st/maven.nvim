local scan = require('plenary.scandir')
local Project = require('maven.sources.project')
local MavenConfig = require('maven.config')
local PomParser = require('maven.parsers.pom_xml_parser')

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

return M
