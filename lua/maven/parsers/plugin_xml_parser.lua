local Project = require('maven.sources.project')
local xml2lua = require('xml2lua')
local handler = require('xmlhandler.tree')

---@class PluginParser
---@field  private _xml  any
---@field  plugin_xml_path  string
local PluginParser = {}
PluginParser.__index = PluginParser

---Create a new Plugin xml parser
---@param plugin_xml_path string
---@return PluginParser
function PluginParser.new(plugin_xml_path)
  local self = {}
  setmetatable(self, PluginParser)
  self.plugin_xml_path = plugin_xml_path
  return self
end

---Parse the plugin xml file
function PluginParser:parse()
  local content = xml2lua.loadFile(self.plugin_xml_path)
  local xml_handler = handler:new()
  local xml_parser = xml2lua.parser(xml_handler)
  xml_parser:parse(content)
  self._xml = xml_handler.root
  assert(self._xml.plugin, 'Tag <plugin> not found on plugin file')
end

---@return string
function PluginParser:get_goal_prefix()
  return assert(self._xml.plugin.goalPrefix, 'Tag <goalPrefix> not found on plugin file')
end

---@return Project.Goal[]
function PluginParser:get_goals()
  assert(self._xml.plugin.mojos, 'Tag <mojos> not found on plugin file')
  local goals = {}
  local data = self._xml.plugin.mojos.mojo
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

return PluginParser
