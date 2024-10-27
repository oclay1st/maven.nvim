local Path = require('plenary.path')
local Archetype = require('maven.sources.archetype')

---@class ArchetypeJsonParser
local ArchetypeJsonParser = {}

---Parse the json file
---@param json_path string
function ArchetypeJsonParser:parse_file(json_path)
  local lines = Path:new(json_path):readlines()
  local data = vim.fn.json_decode(lines)
  return vim.tbl_map(function(item)
    return Archetype.new(item.artifact_id, item.group_id, item.versions, item.description)
  end, data)
end

---Export the archetypes to json file
---@param json_path string
function ArchetypeJsonParser:export(archetypes, json_path)
  local json_text = vim.fn.json_encode(archetypes)
  Path:new(json_path):write(json_text, 'w')
end

return ArchetypeJsonParser
