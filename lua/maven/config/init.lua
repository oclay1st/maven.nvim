---@class MavenConfig
local M = {}

M.namespace = vim.api.nvim_create_namespace('maven')

---@class CustomCommand
---@field name string lifecycle name
---@field description string
---@field cmd_args string[] the list of args

---@class ProjectsView
---@field custom_commands CustomCommand[]
---@field position string
---@field size integer

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

---@class Cache
---@field enable_dependencies_cache boolean
---@field enable_plugins_cache boolean
---@field enable_help_options_cache boolean

---@class MavenOptions
---@field projects_view? ProjectsView
---@field console ConsoleView
---@field mvn_executable string the name or path of mvn
---@field project_scanner_depth number
---@field enable_cache boolean
---@field cache Cache
local defaultOptions = {
  mvn_executable = 'mvn',
  project_scanner_depth = 5,
  projects_view = {
    custom_commands = {},
    position = 'right',
    size = 65,
  },
  dependencies_view = {
    size = {
      width = '70%',
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
    dependency_details_win = {
      size = {
        width = '80%',
        height = '6',
      },
      border = { style = 'rounded' },
    },
  },
  initializer_view = {
    project_name_win = {
      border = { style = 'rounded' },
    },
    project_package_win = {
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
  execution_view = {
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
      height = '35%',
    },
    border = { style = 'rounded' },
  },
  default_arguments_view = {
    arguments = {},
    size = {
      width = '40%',
      height = '30%',
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
  favorite_commands_view = {
    size = {
      width = '40%',
      height = '30%',
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
  console = {
    show_command_execution = true,
    show_lifecycle_execution = true,
    show_plugin_goal_execution = true,
    show_dependencies_load_execution = false,
    show_plugins_load_execution = false,
    show_project_create_execution = true,
    clean_before_execution = true,
  },
  cache = {
    enable_dependencies_cache = true,
    enable_plugins_cache = true,
    enable_help_options_cache = true,
  },
  icons = {
    plugin = '',
    package = '',
    new = '',
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
    argument = '',
    favorite = '',
  },
}

---@type MavenOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
