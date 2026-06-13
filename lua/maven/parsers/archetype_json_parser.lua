local Archetype = require('maven.sources.archetype')
local FileUtils = require('maven.utils.fs')

---@class ArchetypeJsonParser
local ArchetypeJsonParser = {}

---Parse the json file
---@param json_path string
function ArchetypeJsonParser:parse_file(json_path)
  local text = FileUtils.read(json_path)
  local data = vim.fn.json_decode(text)
  return vim.tbl_map(function(item)
    return Archetype.new(item.artifact_id, item.group_id, item.versions, item.description)
  end, data)
end

---Export the archetypes to json file
---@param json_path string
function ArchetypeJsonParser:export(archetypes, json_path)
  local json_text = vim.fn.json_encode(archetypes)
  FileUtils.write(json_path, json_text)
end

return ArchetypeJsonParser
