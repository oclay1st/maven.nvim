local xml2lua = require('xml2lua')
local handler = require('xmlhandler.tree')
local Archetype = require('maven.sources.archetype')

---@class ArchetypeCatalogParser
local ArchetypeCatalogParser = {}

local MAX_NUMBER_OF_VERSIONS = 10

local function _lookup(group_id, artifact_id, archetypes)
  for _, archetype in ipairs(archetypes) do
    if archetype.group_id == group_id and archetype.artifact_id == artifact_id then
      return archetype
    end
  end
end

---Parse the catalog content
---@param catalog_xml_content string
---@return Archetype[]
function ArchetypeCatalogParser.parse(catalog_xml_content)
  local archetypes = {} ---@type Archetype[]
  local xml_handler = handler:new()
  local xml_parser = xml2lua.parser(xml_handler)
  xml_parser:parse(catalog_xml_content)
  local _xml = xml_handler.root
  local data = _xml['archetype-catalog'].archetypes.archetype
  for _, item in ipairs(data) do
    local _archetype = _lookup(item.groupId, item.artifactId, archetypes)
    if _archetype and #_archetype.versions < MAX_NUMBER_OF_VERSIONS then
      table.insert(_archetype.versions, item.version)
    elseif not _archetype then
      _archetype = Archetype.new(item.artifactId, item.groupId, { item.version }, item.description)
      table.insert(archetypes, _archetype)
    end
  end
  return archetypes
end

---Parse the catalog xml file
function ArchetypeCatalogParser.parse_file(catalog_xml_path)
  local content = xml2lua.loadFile(catalog_xml_path)
  return ArchetypeCatalogParser.parse(content)
end

return ArchetypeCatalogParser
