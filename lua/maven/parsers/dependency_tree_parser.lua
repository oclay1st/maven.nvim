local Project = require('maven.sources.project')
local context_manager = require('plenary.context_manager')
local Utils = require('maven.utils')
local with = context_manager.with
local open = context_manager.open

---@class DependencyTreeParser
local DependencyTreeParser = {}

DependencyTreeParser.__index = DependencyTreeParser

---Fix an issue with the dependency graph plugin
---@param dependencies Project.Dependency[]
--- FIXME: some dependencies marked as duplicate have children.
local regenerate_dependencies = function(dependencies)
  for _, item in ipairs(dependencies) do
    if item.is_duplicate then
      local children = vim.tbl_filter(function(dep)
        return dep.parent_id == item.id
      end, dependencies)
      if #children > 0 then
        local correct_dependency = vim.tbl_filter(function(dep)
          return dep:get_compact_name() == item:get_compact_name() and not dep.is_duplicate
        end, dependencies)
        for _, child in ipairs(children) do
          child.parent_id = correct_dependency[1].id
        end
      end
    end
  end
end

---Parse the dependency text
---@param text string
---@param id string
---@param parent_id string | nil
---@return Project.Dependency
local parse_dependency = function(text, id, parent_id)
  local pattern = '(.-):(.-):(.-):(%w+[/?%w+]*)%s?(.*)'
  local group_id, artifact_id, version, scope, comment = text:match(pattern)
  comment = comment or ''
  local is_duplicate = comment:find('duplicate') ~= nil
  local conflict_version = nil
  local real_version = comment:match('conflict: (.-)%)')
  if real_version then
    conflict_version = version
    version = real_version
  end
  local _, count_scopes = string.gsub(scope, '(%w+)/?', '')
  scope = count_scopes == 1 and scope or nil
  return Project.Dependency(
    id,
    parent_id,
    group_id,
    artifact_id,
    version,
    scope,
    is_duplicate,
    conflict_version
  )
end

---Resolve dependencies
---@return Project.Dependency[]
function DependencyTreeParser.parse_file(tree_file_path)
  local dependencies = {}
  with(open(tree_file_path), function(reader)
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

return DependencyTreeParser
