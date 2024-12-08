<br/>
<div align="center">
  <a  href="https://github.com/oclay1st/maven.nvim">
    <img src="assets/maven.png" alt="Logo" >
  </a>
</div>

**maven.nvim** is a plugin to use Maven in Neovim.

<div>
  <img src ="assets/screenshot.png">
</div>

## 🔥 Status
This plugin is under **Development**.

## ✨ Features

- Create projects from archetypes
- Execute lifecycle goals, plugins goals and custom commands
- List dependencies and their relationship
- Analyze dependencies usages, conflicts and duplications
- Enqueue multiple goal executions
- Show the output of the commands executions

## ⚡️ Requirements

-  For Unix systems:
   - `unzip`
-  For Windows systems(untested):
   - `GNU tar`

## 📦 Installation

### lazy.nvim

```lua
{
   "oclay1st/maven.nvim",
   cmd = { "Maven", "MavenInit", "MavenExec" },
   dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
   },
   opts = {}, -- options, see default configuration
   keys = { { "<Leader>M", "<cmd>Maven<cr>", desc = "Maven" } }
}
```

## ⚙️  Default configuration

```lua
{
  mvn_executable = 'mvn',
  project_scanner_depth = 5,
  custom_commands = {
    -- Example: 
    -- {
    --   name = "lazy",
    --   cmd_args = { "clean", "package", "-DskipTests" },
    --   description = "clean package and skip tests",
    -- }
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
  projects_view = {
    position = 'right',
    size = 65,
  },
  dependencies_view = {
    size = { -- see the nui doc for details about size
      width = '70%',
      height = '80%',
    },
    resolved_dependencies_win = {
      border = { style = 'rounded' }, -- see the nui doc for details about border
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
      default_value = '', -- Example: io.github.username
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
```

## 🎨 Highlight Groups

<!-- colors:start -->

| Highlight Group | Default Group | Description |
| --- | --- | --- |
| **MavenNormal** | ***Normal*** | Normal text |
| **MavenNormalNC** | ***NormalNC*** | Normal text on non current window |
| **MavenCursorLine** | ***CursorLine*** | Cursor line text |
| **MavenSpecial** | ***Special*** | Special text |
| **MavenComment** | ***Comment*** | Comment text |
| **MavenTitle** | ***Title*** | Title text |
| **MavenError** | ***DiagnosticError*** | Error text |
| **MavenWarn** | ***DiagnosticWarn*** | Warning text |
| **MavenInfo** | ***DiagnosticInfo*** | Info text |

<!-- colors:end -->
