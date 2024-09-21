local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local NuiSplit = require('nui.split')
local NuiPopup = require('nui.popup')
local Path = require('plenary.path')
local DependenciesParser = require('maven.parsers.dependencies_parser')
local PluginsParser = require('maven.parsers.plugins_parser')
local Utils = require('maven.utils')
local Console = require('maven.ui.console')
local MavenConfig = require('maven.config')
local highlights = require('maven.highlights')
local icons = require('maven.ui.icons')

local M = {}

local console = Console.new()

local node_types = {
  command = { icon = icons.default.command },
  commands = { icon = icons.default.tool_folder },
  lifecycle = { icon = icons.default.tool },
  lifecycles = { icon = icons.default.tool_folder },
  goal = { icon = icons.default.command },
  dependency = { icon = icons.default.package },
  dependencies = { icon = icons.default.tool_folder },
  plugin = { icon = icons.default.plugin },
  plugins = { icon = icons.default.tool_folder },
  project = { icon = icons.default.project },
}

---Lookup for a project inside a list of projects and sub-projects (modules)
---@param path string
---@param projects Project[]
---@return Project
local lookup_project = function(path, projects)
  for _, value in ipairs(projects) do
    if value.root_path == path then
      return value
    end
    error('Project not found')
  end
end

---Load the dependency nodes for the tree
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_dependencies_nodes = function(node, tree, project)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.txt'
  local args = Utils.build_dependencies_cmd_args(project.pom_xml_path, output_dir, output_filename)
  local on_success = function()
    vim.schedule(function()
      local file_path = Path:new(output_dir, output_filename)
      local parser = DependenciesParser.new(file_path:absolute())
      local dependencies = parser:parse()
      file_path:rm()
      local dependency_nodes = {}
      for _, dependency in ipairs(dependencies) do
        if dependency.parent_id == nil then
          local dependency_node = NuiTree.Node({
            id = dependency.id,
            text = dependency:get_compact_name(),
            type = 'dependency',
            scope = dependency.scope,
            project_path = project.root_path,
          })
          table.insert(dependency_nodes, dependency_node)
        end
      end
      node.is_loaded = true
      tree:set_nodes(dependency_nodes, node._id)
      node:expand()
      tree:render()
    end)
  end
  console:execute_mvn_command(args, false, on_success)
end

---Load the plugin nodes for the tree
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_plugins_nodes = function(node, tree, project)
  local output_dir = Utils.maven_data_path
  local output_filename = Utils.uuid() .. '.epom'
  local file_path = Path:new(output_dir, output_filename)
  local absolute_file_path = file_path:absolute()
  local args = Utils.build_effective_pom_cmd_args(project.pom_xml_path, absolute_file_path)
  local on_success = function()
    vim.schedule(function()
      local parser = PluginsParser.new(absolute_file_path)
      local plugins = parser:parse()
      file_path:rm()
      local plugin_nodes = {}
      for _, plugin in ipairs(plugins) do
        local plugin_node = NuiTree.Node({
          text = plugin:get_compact_name(),
          type = 'plugin',
          project_path = project.root_path,
        })
        table.insert(plugin_nodes, plugin_node)
      end
      node.is_loaded = true
      tree:set_nodes(plugin_nodes, node._id)
      node:expand()
      tree:render()
    end)
  end
  console:execute_mvn_command(args, true, on_success)
end

---Create a project node
---@param project Project
---@return NuiTree.Node
local create_project_node = function(project)
  ---Map lifecycle nodes
  local lifecycle_nodes = {}
  for index, lifecycle in ipairs(project.lifecycles) do
    lifecycle_nodes[index] = NuiTree.Node({
      text = lifecycle.name,
      type = 'lifecycle',
      description = lifecycle.description,
      cmd_arg = lifecycle.cmd_arg,
      project_path = project.root_path,
    })
  end

  ---Map command nodes
  local command_nodes = {}
  for index, command in ipairs(project.commands) do
    command_nodes[index] = NuiTree.Node({
      text = command.name,
      type = 'command',
      description = command.description,
      cmd_args = command.cmd_args,
      project_path = project.root_path,
    })
  end

  ---Map Commands node
  local commands_node = NuiTree.Node({
    text = 'Commands',
    type = 'commands',
    project_path = project.root_path,
  }, command_nodes)

  ---Map Lifecycles node
  local lifecycles_node = NuiTree.Node({
    text = 'Lifecycle',
    type = 'lifecycles',
    project_path = project.root_path,
  }, lifecycle_nodes)

  ---Map Dependencies node
  local dependencies_node = NuiTree.Node({
    text = 'Dependencies',
    type = 'dependencies',
    is_loaded = false,
    cmd_args = { '' },
    project_path = project.root_path,
  })

  ---Map Plugins node
  local plugins_node = NuiTree.Node({
    text = 'Plugins',
    type = 'plugins',
    is_loaded = false,
    project_path = project.root_path,
  })

  local project_nodes = { lifecycles_node, dependencies_node, plugins_node }

  if not vim.tbl_isempty(command_nodes) then
    table.insert(project_nodes, 1, commands_node)
  end

  return NuiTree.Node({
    id = Utils.uuid(),
    text = project.name or project.artifact_id,
    type = 'project',
    project_path = project.root_path,
  }, project_nodes)
end

---Prepare node visualization
---@param node any
---@return NuiLine
local prepare_node = function(node)
  local icon = node_types[node.type] and node_types[node.type].icon or ' '
  local line = NuiLine()
  line:append(' ' .. string.rep('  ', node:get_depth() - 1))

  if node:has_children() or node.is_loaded == false then
    line:append(node:is_expanded() and ' ' or ' ', 'SpecialChar')
  else
    line:append('  ')
  end
  line:append(icon .. ' ', 'SpecialChar')
  line:append(node.text)
  if (node.type == 'command' or node.type == 'lifecycle') and node.description then
    line:append(' (' .. node.description .. ')', highlights.MAVEN_DIM_TEXT)
  end
  if node.type == 'dependency' then
    line:append(' (' .. node.scope .. ')', highlights.MAVEN_DIM_TEXT)
  end
  return line
end

---Create  the tree component
---@param bufnr any
local create_tree = function(bufnr)
  return NuiTree({
    ns_id = MavenConfig.namespace,
    bufnr = bufnr,
    prepare_node = function(node)
      return prepare_node(node)
    end,
  })
end

local create_header = function()
  local line = NuiLine()
  local separator = '  '
  line:append(' ' .. icons.default.maven .. ' Maven' .. separator, highlights.MAVEN_SPECIAL_TEXT)
  line:append(icons.default.new_folder .. ' Create Project', highlights.MAVEN_SPECIAL_TEXT)
  line:append('<a>' .. separator, highlights.MAVEN_NORMAL_TEXT)
  line:append(icons.default.tree .. ' Analyze Dependencies', highlights.MAVEN_SPECIAL_TEXT)
  line:append('<D>' .. separator, highlights.MAVEN_NORMAL_TEXT)
  line:append(icons.default.help .. ' Help', highlights.MAVEN_SPECIAL_TEXT)
  line:append('<H>' .. separator, highlights.MAVEN_NORMAL_TEXT)
  return line
end

local setup_win_maps = function(win, tree, projects)
  win:mount()
  win:map('n', 'q', function()
    win:unmount()
  end)

  win:map('n', '<enter>', function()
    local updated = false
    local node = tree:get_node()
    if node == nil then
      return
    end
    local project = lookup_project(node.project_path, projects)
    if node.type == 'command' then
      local args = Utils.build_cmd_args(project.pom_xml_path, node.cmd_args)
      console:execute_mvn_command(args, true)
    elseif node.type == 'lifecycle' then
      local args = Utils.build_cmd_args(project.pom_xml_path, { node.cmd_arg })
      console:execute_mvn_command(args, true)
    elseif node.type == 'dependencies' and not node.is_loaded then
      load_dependencies_nodes(node, tree, project)
    elseif node.type == 'plugins' and not node.is_loaded then
      load_plugins_nodes(node, tree, project)
    end

    if node:is_expanded() then
      updated = node:collapse() or updated
    else
      updated = node:expand() or updated
    end
    if updated then
      tree:render()
    end
  end, { noremap = true, nowait = true })
end

---Mount the explorer component
---@param projects Project[]
M.mount = function(projects)
  local default_win_options = {
    ns_id = MavenConfig.namespace,
    relative = 'win',
    position = MavenConfig.options.explorer_window.position,
    size = MavenConfig.options.explorer_window.size,
    buf_options = {
      buftype = 'nofile',
      swapfile = false,
      filetype = 'maven',
      undolevels = -1,
    },
    win_options = {
      colorcolumn = '',
      signcolumn = 'no',
      number = false,
      relativenumber = false,
      spell = false,
      list = false,
    },
  }

  local win = nil
  if MavenConfig.options.explorer_window.position == 'float' then
    win = NuiPopup(default_win_options)
  else
    win = NuiSplit(default_win_options)
  end

  ---Create the header  line
  local header_line = create_header()
  header_line:render(win.bufnr, MavenConfig.namespace, 1)

  ---Create the Projects lines
  local project_line = NuiLine()
  project_line:append(' Projects:', highlights.MAVEN_DIM_TEXT)
  project_line:render(win.bufnr, MavenConfig.namespace, 2)

  ---Create the tree
  local tree = create_tree(win.bufnr)
  local nodes = {}
  for index, value in ipairs(projects) do
    nodes[index] = create_project_node(value)
  end
  tree:set_nodes(nodes)

  ---Setup maps
  setup_win_maps(win, tree, projects)

  ---Render the tree
  tree:render(3)
  header_line:highlight(win.bufnr, MavenConfig.namespace, 1)
  project_line:highlight(win.bufnr, MavenConfig.namespace, 2)
  tree:render()
end

return M
