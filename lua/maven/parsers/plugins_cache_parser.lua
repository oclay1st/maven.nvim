local Path = require('plenary.path')
local Utils = require('maven.utils')
local Project = require('maven.sources.project')

local M = {}

---@class PluginCache
---@field group_id string
---@field artifact_id string
---@field version string

--- Parse the plugins cache
M.parse = function(key)
  local plugins_json = Path:new(Utils.maven_cache_path, 'plugins', key .. '.json')
  local plugins = {}
  if plugins_json:exists() then
    local data = plugins_json:read()
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
  local plugins_cache_path = Path:new(Utils.maven_cache_path, 'plugins')
  if not plugins_cache_path:exists() then
    plugins_cache_path:mkdir()
  end
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
  --- @type Path
  local cache_json = plugins_cache_path:joinpath(key .. '.json')
  cache_json:write(data, 'w')
end

return M
