local Utils = require('maven.utils')
local Project = require('maven.sources.project')
local FileUtils = require('maven.utils.fs')

local M = {}

---@class DependencyCache
---@field id string
---@field parent_id string | nil
---@field group_id string
---@field artifact_id string
---@field version string
---@field scope string
---@field is_duplicate boolean
---@field conflict_version string
---@field size? number

--- Parse the dependencies cache
M.parse = function(key)
  local dependencies_json = vim.fs.joinpath(Utils.maven_cache_path, 'dependencies', key .. '.json')
  local dependencies = {}
  if FileUtils.is_file(dependencies_json) then
    local data = FileUtils.read(dependencies_json)
    local dependencies_cache = vim.json.decode(data) ---@type DependencyCache[]
    for _, item in ipairs(dependencies_cache) do
      table.insert(
        dependencies,
        Project.Dependency(
          item.id,
          item.parent_id,
          item.group_id,
          item.artifact_id,
          item.version,
          item.scope,
          item.is_duplicate,
          item.conflict_version,
          item.size
        )
      )
    end
  end
  return dependencies
end

--- Dump the dependencies cache to file
--- @param  key string
--- @param dependencies Project.Dependency[]
M.dump = function(key, dependencies)
  local dependencies_cache_path = vim.fs.joinpath(Utils.maven_cache_path, 'dependencies')
  FileUtils.mkdir(dependencies_cache_path)
  ---@type DependencyCache[]
  local dependencies_cache = {}
  for _, dependency in ipairs(dependencies) do
    table.insert(dependencies_cache, {
      id = dependency.id,
      parent_id = dependency.parent_id,
      group_id = dependency.group_id,
      artifact_id = dependency.artifact_id,
      version = dependency.version,
      scope = dependency.scope,
      is_duplicate = dependency.is_duplicate,
      conflict_version = dependency.conflict_version,
      size = dependency.size,
    })
  end
  local data = vim.json.encode(dependencies_cache)
  local cache_json = vim.fs.joinpath(dependencies_cache_path, key .. '.json')
  FileUtils.write(cache_json, data)
end

return M
