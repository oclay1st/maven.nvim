local MiniTest = require('mini.test')
local ArchetypeCatalogParser = require('maven.parsers.archetype_catalog_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local archetypes_xml = [[
<?xml version="1.0" encoding="UTF-8"?>
<archetype-catalog>
  <archetypes>
    <archetype>
      <groupId>com.example</groupId>
      <artifactId>example-archetype</artifactId>
      <version>1.0.0</version>
      <description>Example archetype</description>
    </archetype>
    <archetype>
      <groupId>com.example</groupId>
      <artifactId>example-archetype</artifactId>
      <version>1.0.1</version>
    </archetype>
    <archetype>
      <groupId>org.other</groupId>
      <artifactId>other-archetype</artifactId>
      <version>2.0.0</version>
      <description>Other archetype</description>
    </archetype>
  </archetypes>
</archetype-catalog>
]]

T['parse multiple archetypes'] = function()
  local result = ArchetypeCatalogParser.parse(archetypes_xml)
  eq(#result, 2)

  eq(result[1].artifact_id, 'example-archetype')
  eq(result[1].group_id, 'com.example')
  eq(result[1].versions, { '1.0.0', '1.0.1' })
  eq(result[1].description, 'Example archetype')

  eq(result[2].artifact_id, 'other-archetype')
  eq(result[2].group_id, 'org.other')
  eq(result[2].versions, { '2.0.0' })
  eq(result[2].description, 'Other archetype')
end

local multiple_no_desc_xml = [[
<archetype-catalog>
  <archetypes>
    <archetype>
      <groupId>com.example</groupId>
      <artifactId>no-desc-one</artifactId>
      <version>1.0.0</version>
    </archetype>
    <archetype>
      <groupId>org.other</groupId>
      <artifactId>no-desc-two</artifactId>
      <version>2.0.0</version>
    </archetype>
  </archetypes>
</archetype-catalog>
]]

T['parse archetypes without description'] = function()
  local result = ArchetypeCatalogParser.parse(multiple_no_desc_xml)
  eq(#result, 2)
  eq(result[1].artifact_id, 'no-desc-one')
  eq(result[1].group_id, 'com.example')
  eq(result[1].versions, { '1.0.0' })
  eq(result[1].description, nil)
  eq(result[2].artifact_id, 'no-desc-two')
  eq(result[2].description, nil)
end

T['respects max number of versions'] = function()
  local xml_parts = {
    '<archetype-catalog><archetypes>',
  }
  for i = 1, 15 do
    table.insert(
      xml_parts,
      [[
    <archetype>
      <groupId>com.example</groupId>
      <artifactId>many-versions</artifactId>
      <version>1.0.]]
    )
    table.insert(xml_parts, tostring(i))
    table.insert(
      xml_parts,
      [[</version>
    </archetype>]]
    )
  end
  table.insert(xml_parts, '</archetypes></archetype-catalog>')

  local result = ArchetypeCatalogParser.parse(table.concat(xml_parts))
  eq(#result, 1)
  eq(#result[1].versions, 10)
  eq(result[1].versions[1], '1.0.1')
  eq(result[1].versions[10], '1.0.10')
end

return T
