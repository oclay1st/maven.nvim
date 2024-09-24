local Project = require('maven.sources.project')
local xml2lua = require('xml2lua')
local handler = require('xmlhandler.tree')

---@class PluginParser
local PluginParser = {}

---@return Project.Goal[]
local function build_goals(_xml)
  assert(_xml.plugin.mojos, 'Tag <mojos> not found on plugin file')
  local goals = {}
  local data = _xml.plugin.mojos.mojo
  if vim.islist(data) then
    for _, item in ipairs(data) do
      local goal = Project.Goal(item.goal)
      table.insert(goals, goal)
    end
  else
    local goal = Project.Goal(data.goal)
    table.insert(goals, goal)
  end
  return goals
end

---Parse the plugin xml content
---@param plugin_xml_content string
---@return Project.Plugin
function PluginParser.parse(plugin_xml_content)
  local xml_handler = handler:new()
  local xml_parser = xml2lua.parser(xml_handler)
  xml_parser:parse(plugin_xml_content)
  local _xml = xml_handler.root
  assert(_xml.plugin, 'Tag <plugin> not found on plugin file')
  local group_id = assert(_xml.plugin.groupId, 'Tag <groupId> not found on plugin file')
  local artifact_id = assert(_xml.plugin.artifactId, 'Tag <artifactId> not found on plugin file')
  local version = assert(_xml.plugin.version, 'Tag <version> not found on plugin file')
  local goal_prefix = assert(_xml.plugin.goalPrefix, 'Tag <goalPrefix> not found on plugin file')
  local goals = build_goals(_xml)
  return Project.Plugin(group_id, artifact_id, version, goal_prefix, goals)
end

---Parse the plugin xml file
---@param plugin_xml_path string
---@return Project.Plugin
function PluginParser.parse_file(plugin_xml_path)
  local xml_content = xml2lua.loadFile(plugin_xml_path)
  return PluginParser.parse(xml_content)
end

return PluginParser
