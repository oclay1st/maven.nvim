---@class MavenConfig
local M = {}

M.namespace = vim.api.nvim_create_namespace('maven')

---@class ExplorerWindow
---@field position string
---@field size integer

---@class CustomCommand
---@field name string lifecycle name
---@field description string
---@field cmd_args string[] the list of args

---@class MavenOptions
---@field explorer_window ExplorerWindow
---@field mvn_executable string the name or path of mvn
---@field custom_commands CustomCommand[]
local defaultOptions = {
  explorer_window = {
    position = 'right',
    size = 68,
  },
  mvn_executable = 'mvn',
  custom_commands = {},
}

---@type MavenOptions
M.options = defaultOptions

M.merge = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
