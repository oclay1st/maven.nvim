local Path = require('plenary.path')
local Project = require('maven.sources.project')
local XmlParser = require('maven.vendor.xml2lua.XmlParser')
local TreeHandler = require('maven.vendor.xml2lua.TreeHandler')

---@class PluginParser
local PluginParser = {}

---@return Project.Goal[]
local function build_goals(_xml, prefix)
  assert(_xml.plugin.mojos, 'Tag <mojos> not found on plugin file')
  local goals = {}
  local data = _xml.plugin.mojos.mojo
  if vim.islist(data) then
    for _, item in ipairs(data) do
      local goal = Project.Goal(item.goal, prefix)
      table.insert(goals, goal)
    end
  else
    local goal = Project.Goal(data.goal, prefix)
    table.insert(goals, goal)
  end
  return goals
end

---Parse the plugin xml content
---@param plugin_xml_content string
---@return Project.Plugin
function PluginParser.parse(plugin_xml_content)
  local xml_handler = TreeHandler:new()
  local xml_parser = XmlParser.new(xml_handler, {})
  xml_parser:parse(plugin_xml_content)
  local _xml = xml_handler.root
  assert(_xml.plugin, 'Tag <plugin> not found on plugin file')
  local group_id = assert(_xml.plugin.groupId, 'Tag <groupId> not found on plugin file')
  local artifact_id = assert(_xml.plugin.artifactId, 'Tag <artifactId> not found on plugin file')
  local version = assert(_xml.plugin.version, 'Tag <version> not found on plugin file')
  local goal_prefix = assert(_xml.plugin.goalPrefix, 'Tag <goalPrefix> not found on plugin file')
  local goals = build_goals(_xml, goal_prefix)
  return Project.Plugin(group_id, artifact_id, version, goals)
end

---Parse the plugin xml file
---@param plugin_xml_path string
---@return Project.Plugin
function PluginParser.parse_file(plugin_xml_path)
  local _xml_content = Path:new(plugin_xml_path):read()
  return PluginParser.parse(_xml_content)
end

return PluginParser
