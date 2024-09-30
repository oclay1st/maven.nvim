---@class MavenConfig
local M = {}

M.namespace = vim.api.nvim_create_namespace('maven')

---@class ProjectsView
---@field position string
---@field size integer

---@class CustomCommand
---@field name string lifecycle name
---@field description string
---@field cmd_args string[] the list of args

---@class ConsoleView
---@field show_lifecycle_execution boolean
---@field show_command_execution boolean
---@field show_plugin_goal_execution boolean
---@field show_dependencies_load_execution boolean
---@field show_plugins_load_execution boolean

---@class MavenOptions
---@field projects_view? ProjectsView
---@field console ConsoleView
---@field mvn_executable string the name or path of mvn
---@field custom_commands CustomCommand[]
local defaultOptions = {
  projects_view = {
    position = 'right',
    size = 68,
  },
  console = {
    show_command_execution = true,
    show_lifecycle_execution = true,
    show_plugin_goal_execution = true,
    show_dependencies_load_execution = false,
    show_plugins_load_execution = false,
  },
  mvn_executable = 'mvn',
  custom_commands = {},
}

---@type MavenOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
