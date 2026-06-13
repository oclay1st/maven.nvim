local Utils = require('maven.utils')
local Project = require('maven.sources.project')
local FileUtils = require('maven.utils.fs')

local M = {}

---Parse the favorite commands cache
---@param key string
---@return Project.Favorite[]
M.parse = function(key)
  local favorite_commands_path =
    vim.fs.joinpath(Utils.maven_cache_path, 'favorite_commands', key .. '.json')
  local favorite_commands = {}
  if FileUtils.is_file(favorite_commands_path) then
    local data = FileUtils.read(favorite_commands_path)
    local cache = vim.json.decode(data)
    for _, item in ipairs(cache) do
      table.insert(
        favorite_commands,
        Project.Favorite(item.name, item.type, item.description, item.cmd_args)
      )
    end
  end
  return favorite_commands
end

---Dump the favorites commands to a file
---@param key string
---@param favorite_commands Project.Favorite[]
M.dump = function(key, favorite_commands)
  local favorite_commands_cache_dir = vim.fs.joinpath(Utils.maven_cache_path, 'favorite_commands')
  FileUtils.mkdir(favorite_commands_cache_dir)
  local favorite_commands_cache = {}
  for _, command in pairs(favorite_commands) do
    table.insert(favorite_commands_cache, {
      name = command.name,
      type = command.type,
      description = command.description,
      cmd_args = command.cmd_args,
    })
  end
  local data = vim.json.encode(favorite_commands_cache)
  local cache_json = vim.fs.joinpath(favorite_commands_cache_dir, key .. '.json')
  FileUtils.write(cache_json, data)
end

return M
