local Project = require('maven.sources.project')
local context_manager = require('plenary.context_manager')
local Utils = require('maven.utils')
local with = context_manager.with
local open = context_manager.open

---@class DependenciesParser
---@field tree_file_path string
local DependenciesParser = {}

DependenciesParser.__index = DependenciesParser

---@param tree_file_path string
---@return DependenciesParser
function DependenciesParser.new(tree_file_path)
  local self = {}
  setmetatable(self, DependenciesParser)
  self.tree_file_path = tree_file_path
  return self
end

---Parse the dependency text
---@param text string
---@param id string
---@param parent_id string | nil
---@return Project.Dependency
local parse_dependency = function(text, id, parent_id)
  local pattern = '(.-):(.-):(.-):(%w+)%s?(.*)'
  local group_id, artifact_id, version, scope, comment = text:match(pattern)
  print('scope: ' .. scope .. ' comment: ' .. (comment or ''))
  return Project.Dependency(id, parent_id, group_id, artifact_id, version, scope)
  -- end
end

---Resolve dependencies
---@return Project.Dependency[]
function DependenciesParser:parse()
  local dependencies = {}
  with(open(self.tree_file_path), function(reader)
    reader:read() --- skip the name of the project
    local space_indentation = 3 --- all the  node are indent on multiple of 3 spaces
    local deep_dependency = {}
    for line in reader:lines() do
      local clean_line = string.gsub(line, '[%+%\\%|]', ' ')
      local dependency_id = Utils.uuid()
      local character_position = assert(string.find(clean_line, '%-')) --- get all characters until -
      local spaces = character_position - 2 --- the character itself and the first line character
      local deep_index = spaces / space_indentation
      deep_dependency[deep_index] = dependency_id
      local parent_dependency_id = deep_dependency[deep_index - 1]
      local dependency_text = string.sub(clean_line, character_position + 2)
      local dependency = parse_dependency(dependency_text, dependency_id, parent_dependency_id)
      table.insert(dependencies, dependency)
    end
  end)
  return dependencies
end

return DependenciesParser
