<br/>
<div align="center">
  <a  href="https://github.com/oclay1st/maven.nvim">
    <img src="assets/maven.png" alt="Logo" >
  </a>
</div>

**maven.nvim** is a plugin to use Maven in Neovim.

<table>
  <tr>
    <td> <img src="assets/console.png"  align="center" alt="1" width = 418x></td>
    <td><img src="assets/dependencies.png" align="center" alt="2" width = 418px></td>
   </tr>
   <tr>
    <td><img src="assets/archetypes.png" align="center" alt="3" width = 418px></td>
    <td><img src="assets/commands.png" align="center" alt="4" width = 418px></td>
  </tr>
</table>

## ✨ Features

- Create projects from archetypes
- Execute lifecycle goals, plugins goals and custom commands
- List dependencies and their relationship
- Analyze dependencies usages, conflicts and duplications
- Enqueue multiple goal executions
- Show the output of the commands executions
- Cache dependencies, plugins and command options

## ⚡️ Requirements

-  Neovim 0.10 or superior
-  For Unix systems:
   - `unzip`
-  For Windows systems(untested):
   - `GNU tar`

## 📦 Installation

### lazy.nvim

```lua
{
   "oclay1st/maven.nvim",
   cmd = { "Maven", "MavenInit", "MavenExec", "MavenFavorites" },
   dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      -- optional which-key group registration
      {
        'folke/which-key.nvim',
        opts = { spec = { { mode = { 'n', 'v' }, { '<leader>M', group = 'Maven', icon = { icon = '', color = 'red' } } } } },
      },
   },
   opts = {}, -- options, see default configuration
   keys = {
      { '<leader>Mm', '<cmd>Maven<cr>', desc = 'Maven Projects' },
      { '<leader>Mf', '<cmd>MavenFavorites<cr>', desc = 'Maven Favorite Commands' }
   }
}
```

## ⚙️  Default configuration

```lua
{
  mvn_executable = 'mvn', -- Example: mvn, ./mvnw or a path to Maven executable, if you are on windows use mvn.cmd
  project_scanner_depth = 5,
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
  projects_view = {
    custom_commands = {
    -- Example: 
    -- {
    --   name = "lazy",
    --   cmd_args = { "clean", "package", "-DskipTests" },
    --   description = "clean package and skip tests",
    -- }
    },
    position = 'right',
    size = 65,
  },
  dependencies_view = {
    size = { -- see the nui doc for details about size
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
      height = '34%',
    },
    border = { style = 'rounded' },
  },
  default_arguments_view = {
    arguments = { },
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
