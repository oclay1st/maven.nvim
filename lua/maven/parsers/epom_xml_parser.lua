local Project = require('maven.sources.project')
local xml2lua = require('xml2lua')
local handler = require('xmlhandler.tree')

---@class EffectivePomParser
---@field  private _xml  any
---@field  epom_xml_path  string
local EffectivePomParser = {}
EffectivePomParser.__index = EffectivePomParser

---@param epom_xml_path string
---@return EffectivePomParser
function EffectivePomParser.new(epom_xml_path)
  local self = {}
  setmetatable(self, EffectivePomParser)
  self.epom_xml_path = epom_xml_path
  return self
end

---Parse the epom file
function EffectivePomParser:parse()
  local content = xml2lua.loadFile(self.epom_xml_path)
  local xml_handler = handler:new()
  local xml_parser = xml2lua.parser(xml_handler)
  xml_parser:parse(content)
  self._xml = xml_handler.root
end

---@return string
function EffectivePomParser:get_group_id()
  return self._xml.project.groupId
end

---@return string
function EffectivePomParser:get_artifact_id()
  return assert(
    self._xml.project.artifactId,
    'Tag <artifactId> not found on epom file: ' .. self.epom_xml_path
  )
end

---@return string
function EffectivePomParser:get_version()
  return self._xml.project.version
end

---@return string
function EffectivePomParser:get_name()
  return self._xml.project.name
end

---@return Project.Plugin[]
function EffectivePomParser:get_plugins()
  assert(self._xml.project.build, 'Tag <build> not found on epom file: ' .. self.epom_xml_path)
  assert(
    self._xml.project.build.plugins,
    'Tag <plugins> not found on epom file: ' .. self.epom_xml_path
  )
  local plugins = {} ---@type table
  local data = self._xml.project.build.plugins.plugin
  if vim.islist(data) then
    for _, item in ipairs(self._xml.project.build.plugins.plugin) do
      local group_id = item.groupId or 'org.apache.maven.plugins'
      local artifact_id = item.artifactId
      local version = item.version
      local plugin = Project.Plugin(group_id, artifact_id, version)
      table.insert(plugins, plugin)
    end
  else
    local plugin = Project.Plugin(data.groupId, data.artifactId, data.version)
    table.insert(plugins, plugin)
  end
  return plugins
end

return EffectivePomParser
