local Path = require('plenary.path')
local XmlParser = require('maven.vendor.xml2lua.XmlParser')
local TreeHandler = require('maven.vendor.xml2lua.TreeHandler')

---@class EffectivePomPlugin
---@field group_id string
---@field artifact_id string
---@field version string

---@class EffectivePom
---@field group_id string
---@field artifact_id string
---@field version string
---@field plugins EffectivePomPlugin[]

---@class EffectivePomParser
local EffectivePomParser = {}

---@return EffectivePomPlugin[]
local function build_epom_plugins(_xml)
  assert(_xml.project.build, 'Tag <build> not found on epom')
  assert(_xml.project.build.plugins, 'Tag <plugins> not found on epom')
  local plugins = {} ---@type EffectivePomPlugin[]
  local data = _xml.project.build.plugins.plugin
  if vim.islist(data) then
    for _, item in ipairs(data) do
      table.insert(plugins, {
        group_id = item.groupId or 'org.apache.maven.plugins',
        artifact_id = item.artifactId,
        version = item.version,
      })
    end
  else
    table.insert(plugins, {
      group_id = data.groupId or 'org.apache.maven.plugins',
      artifact_id = data.artifactId,
      version = data.version,
    })
  end
  return plugins
end

---Parse the epom xml content
---@return EffectivePom
function EffectivePomParser.parse(epom_xml_content)
  local xml_handler = TreeHandler:new()
  local xml_parser = XmlParser.new(xml_handler, {})
  xml_parser:parse(epom_xml_content)
  local _xml = xml_handler.root
  assert(_xml.project, 'Tag <plugin> not found on epom file')
  return {
    group_id = assert(_xml.project.groupId, 'Tag <groupId> not found on epom file'),
    artifact_id = assert(_xml.project.artifactId, 'Tag <artifactId> not found on epom file'),
    version = assert(_xml.project.version, 'Tag <version> not found on epom file'),
    plugins = build_epom_plugins(_xml),
  }
end

---Parse the epom xml file
function EffectivePomParser.parse_file(epom_xml_path)
  local _xml_content = Path:new(epom_xml_path):read()
  return EffectivePomParser.parse(_xml_content)
end

return EffectivePomParser
