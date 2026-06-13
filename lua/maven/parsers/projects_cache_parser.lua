local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')

---@class ProjectCache
---@field path string
---@field key string

local M = {}

---Parse the projects cache file
---@return ProjectCache[]
M.parse = function()
  local projects_json = vim.fs.joinpath(Utils.maven_cache_path, 'projects.json')
  if FileUtils.is_file(projects_json) then
    local data = FileUtils.read(projects_json)
    if data and data ~= '' then
      local projects_cache = vim.json.decode(data)
      return projects_cache
    end
  end
  return {}
end

M.register = function(path)
  FileUtils.mkdir(Utils.maven_cache_path)
  local data = {}
  local projects_json = vim.fs.joinpath(Utils.maven_cache_path, 'projects.json')
  if FileUtils.is_file(projects_json) then
    local text_data = FileUtils.read(projects_json)
    data = vim.json.decode(text_data)
  end
  local key = nil
  for _, item in ipairs(data) do
    if item.path == path then
      return item.key
    end
  end
  key = Utils.uuid()
  table.insert(data, { path = path, key = key })
  local text_data = vim.json.encode(data)
  FileUtils.write(projects_json, text_data)
  return key
end

return M
