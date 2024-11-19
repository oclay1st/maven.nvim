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
---@field show_project_create_execution boolean
---@field clean_before_execution boolean

---@class InitializerView
---@field default_package string
---@field workspaces Workspace[]

---@class Workspace
---@field name string
---@field path string

---@class MavenOptions
---@field projects_view? ProjectsView
---@field console ConsoleView
---@field mvn_executable string the name or path of mvn
---@field custom_commands CustomCommand[]
---@field project_scanner_depth number
local defaultOptions = {
  mvn_executable = 'mvn',
  project_scanner_depth = 5,
  custom_commands = {},
  projects_view = {
    position = 'right',
    size = 65,
  },
  dependencies_view = {
    size = {
      width = '60%',
      height = '80%',
    },
    resolved_dependencies_win = {
      border = { style = 'rounded' },
    },
    dependency_usages_win = {
      border = { style = 'rounded' },
    },
    filter_win = {
      border = { style = 'rounded' },
    },
  },
  initializer_view = {
    name_win = {
      border = { style = 'rounded' },
    },
    package_win = {
      default_value = '',
      border = { style = 'rounded' },
    },
    archetypes_win = {
      input_win = {
        border = {
          style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
        },
      },
      options_win = {
        border = {
          style = { '', '', '', '│', '╯', '─', '╰', '│' },
        },
      },
    },
    archetype_version_win = {
      border = { style = 'rounded' },
    },
    workspaces_win = {
      options = {
        { name = 'HOME', path = vim.loop.os_homedir() },
        { name = 'CURRENT_DIR', path = vim.fn.getcwd() },
      },
      border = { style = 'rounded' },
    },
  },
  execute_view = {
    size = {
      width = '40%',
      height = '60%',
    },
    input_win = {
      border = {
        style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
      },
    },
    options_win = {
      border = {
        style = { '', '', '', '│', '╯', '─', '╰', '│' },
      },
    },
  },
  help_view = {
    size = {
      width = '80%',
      height = '20%',
    },
    border = { style = 'rounded' },
  },
  console = {
    show_command_execution = true,
    show_lifecycle_execution = true,
    show_plugin_goal_execution = true,
    show_dependencies_load_execution = false,
    show_plugins_load_execution = false,
    show_project_create_execution = true,
    clean_before_execution = true,
  },
  icons = {
    plugin = '',
    package = '',
    new_folder = '',
    tree = '󰙅',
    expanded = ' ',
    collapsed = ' ',
    maven = '',
    project = '',
    tool_folder = '',
    tool = '',
    command = '',
    help = '󰘥',
    package_dependents = '',
    package_dependencies = '',
    warning = '',
    entry = ' ',
    search = '',
  },
}

---@type MavenOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
