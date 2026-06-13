local Utils = require('maven.utils')
local Project = require('maven.sources.project')
local FileUtils = require('maven.utils.fs')

local M = {}

---@class PluginCache
---@field group_id string
---@field artifact_id string
---@field version string

--- Parse the plugins cache
M.parse = function(key)
  local plugins_json = vim.fs.joinpath(Utils.maven_cache_path, 'plugins', key .. '.json')
  local plugins = {}
  if FileUtils.is_file(plugins_json) then
    local data = FileUtils.read(plugins_json)
    local plugins_cache = vim.json.decode(data)
    for _, item in ipairs(plugins_cache) do
      table.insert(plugins, Project.Plugin(item.group_id, item.artifact_id, item.version))
    end
  end
  return plugins
end

--- Dump the plugins cache to file
--- @param  key string
--- @param plugins Project.Plugin[]
M.dump = function(key, plugins)
  local plugins_cache_path = vim.fs.joinpath(Utils.maven_cache_path, 'plugins')
  FileUtils.mkdir(plugins_cache_path)
  ---@type PluginCache[]
  local plugins_cache = {}
  for _, plugin in ipairs(plugins) do
    table.insert(plugins_cache, {
      group_id = plugin.group_id,
      artifact_id = plugin.artifact_id,
      version = plugin.version,
    })
  end
  local data = vim.json.encode(plugins_cache)
  local cache_json = vim.fs.joinpath(plugins_cache_path, key .. '.json')
  FileUtils.write(cache_json, data)
end

return M
