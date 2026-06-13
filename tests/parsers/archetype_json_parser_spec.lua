local MiniTest = require('mini.test')
local ArchetypeJsonParser = require('maven.parsers.archetype_json_parser')
local Archetype = require('maven.sources.archetype')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse_file returns archetypes from json file'] = function()
  local tmpfile = vim.fn.tempname()
  local json_data = vim.fn.json_encode({
    {
      artifact_id = 'arch-one',
      group_id = 'com.example',
      versions = { '1.0.0', '1.0.1' },
      description = 'First',
    },
    { artifact_id = 'arch-two', group_id = 'org.other', versions = { '2.0.0' }, description = nil },
  })
  FileUtils.write(tmpfile, json_data)

  local result = ArchetypeJsonParser:parse_file(tmpfile)
  eq(#result, 2)
  eq(result[1].artifact_id, 'arch-one')
  eq(result[1].group_id, 'com.example')
  eq(result[1].versions, { '1.0.0', '1.0.1' })
  eq(result[1].description, 'First')
  eq(result[2].artifact_id, 'arch-two')
  eq(result[2].group_id, 'org.other')
  eq(result[2].versions, { '2.0.0' })
  eq(result[2].description, nil)

  FileUtils.delete(tmpfile)
end

T['export writes archetypes to json file'] = function()
  local archetypes = {
    Archetype.new('arch-a', 'com.a', { '1.0.0' }, 'Description A'),
    Archetype.new('arch-b', 'com.b', { '2.0.0' }),
  }

  local tmpfile = vim.fn.tempname()
  ArchetypeJsonParser:export(archetypes, tmpfile)

  local text = FileUtils.read(tmpfile)
  local data = vim.fn.json_decode(text)
  eq(#data, 2)
  eq(data[1].artifact_id, 'arch-a')
  eq(data[1].group_id, 'com.a')
  eq(data[2].artifact_id, 'arch-b')
  eq(data[2].group_id, 'com.b')

  FileUtils.delete(tmpfile)
end

return T
