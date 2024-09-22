local xml2lua = require('xml2lua')
local handler = require('xmlhandler.tree')

---@class PomParser
---@field pom_xml_path string
---@field private _xml table
local PomParser = {}
PomParser.__index = PomParser

---@param pom_xml_path string
---@return PomParser
function PomParser.new(pom_xml_path)
  local self = {}
  setmetatable(self, PomParser)
  self.pom_xml_path = pom_xml_path
  return self
end

---Parse the xml file
function PomParser:parse()
  local content = xml2lua.loadFile(self.pom_xml_path)
  local xml_handler = handler:new()
  local xml_parser = xml2lua.parser(xml_handler)
  xml_parser:parse(content)
  self._xml = xml_handler.root
  assert(self._xml.project, 'Tag <project> not found on pom file')
end

---@return string
function PomParser:get_group_id()
  return self._xml.project.groupId
end

---@return string
function PomParser:get_artifact_id()
  return assert(
    self._xml.project.artifactId,
    'Tag <artifactId> not found on pom file: ' .. self.pom_xml_path
  )
end

---@return string
function PomParser:get_version()
  return self._xml.project.version
end

---@return string
function PomParser:get_name()
  return self._xml.project.name
end

---@return string[]
function PomParser:get_modules_paths()
  local modules = {}
  if self._xml.project.modules then
    if vim.islist(self._xml.project.modules.module) then
      for _, item in ipairs(self._xml.project.modules.module) do
        table.insert(modules, item)
      end
    else
      table.insert(modules, self._xml.project.modules.module)
    end
  end
  return modules
end

return PomParser
