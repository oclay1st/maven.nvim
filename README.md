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
   keys = {
      {
        "<Leader>M",
        function()
          require("maven").toggle_projects_view()
        end,
        desc = "Maven",
      },
   }
}
```

## ⚙️  Default configuration

```lua
{
  projects_view = {
    position = 'right',
    size = 65,
  },
  initializer_view = {
    default_package = '', -- Example: io.github.username
    workspaces = {
      { name = "HOME", path = vim.loop.os_homedir() },
      { name = "CURRENT_DIR", path = vim.fn.getcwd() },
    },
  },
  console = {
    show_command_execution = true,
    show_lifecycle_execution = true,
    show_plugin_goal_execution = true,
    show_dependencies_load_execution = false,
    show_plugins_load_execution = false,
    show_project_create_execution = false,
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
  mvn_executable = 'mvn',
  custom_commands = {
    -- Example: 
    -- {
    --   name = "lazy",
    --   cmd_args = { "clean", "package", "-DskipTests" },
    --   description = "clean package and skip tests",
    -- }
  }, 
  project_scanner_depth = 5
}
```
