---@class PluginsParser
---@field effective_pom_xml_path string
local PluginsParser = {}
PluginsParser.__index = PluginsParser

---@param effective_pom_xml_path string
---@return PluginsParser
function PluginsParser.new(effective_pom_xml_path)
  local self = {}
  setmetatable(self, PluginsParser)
  self.effective_pom_xml_path = effective_pom_xml_path
  return self
end

---Resolve plugins
---@return Project.Plugin[]
function PluginsParser:parse()
  print(self.effective_pom_xml_path)
  local plugins = {}
  return plugins
end

return PluginsParser
