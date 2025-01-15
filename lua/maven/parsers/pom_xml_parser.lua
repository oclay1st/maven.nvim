local Path = require('plenary.path')
local XmlParser = require('maven.vendor.xml2lua.XmlParser')
local TreeHandler = require('maven.vendor.xml2lua.TreeHandler')

---@class Pom
---@field group_id? string
---@field artifact_id string
---@field version? string
---@field name? string
---@field module_paths string[]

---@class PomParser
local PomParser = {}

---Parse the modules paths
---@return string[]
local function parse_modules_paths(_xml)
  local modules = {}
  if _xml.project.modules then
    if vim.islist(_xml.project.modules.module) then
      for _, item in ipairs(_xml.project.modules.module) do
        table.insert(modules, item)
      end
    else
      table.insert(modules, _xml.project.modules.module)
    end
  end
  return modules
end

---Parse the pom xml content
---@return Pom
function PomParser.parse(pom_xml_content)
  local xml_handler = TreeHandler:new()
  local xml_parser = XmlParser.new(xml_handler, {})
  xml_parser:parse(pom_xml_content)
  local _xml = xml_handler.root
  assert(_xml.project, 'Tag <project> not found on pom file')
  return {
    group_id = _xml.project.groupId,
    artifact_id = assert(_xml.project.artifactId, 'Tag <artifactId> not found on pom file'),
    version = _xml.project.version,
    name = _xml.project.name,
    module_paths = parse_modules_paths(_xml),
  }
end

---Parse the pom xml file
---@return Pom
function PomParser.parse_file(pom_xml_path)
  local _xml_content = Path:new(pom_xml_path):read()
  return PomParser.parse(_xml_content)
end

return PomParser
