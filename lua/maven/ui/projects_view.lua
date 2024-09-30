local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local NuiSplit = require('nui.split')
local DependenciesView = require('maven.ui.dependencies_view')
local HelpView = require('maven.ui.help_view')
local Sources = require('maven.sources')
local Utils = require('maven.utils')
local CommandBuilder = require('maven.utils.cmd_builder')
local Console = require('maven.utils.console')
local MavenConfig = require('maven.config')
local highlights = require('maven.highlights')
local icons = require('maven.ui.icons')

local M = {}

local _is_visible = false ---@type boolean

local win

local node_type_props = {
  command = {
    icon = icons.default.command,
    started_state_msg = ' ..running ',
    pending_state_msg = ' ..pending ',
  },
  commands = { icon = icons.default.tool_folder },
  lifecycle = {
    icon = icons.default.tool,
    started_state_msg = ' ..running ',
    pending_state_msg = ' ..pending ',
  },
  lifecycles = { icon = icons.default.tool_folder },
  plugin_goal = {
    icon = icons.default.tool,
    started_state_msg = ' ..running ',
    pending_state_msg = ' ..pending ',
  },
  dependency = { icon = icons.default.package },
  dependencies = {
    icon = icons.default.tool_folder,
    started_state_msg = ' ..loading ',
    pending_state_msg = ' ..pending ',
  },
  plugin = {
    icon = icons.default.plugin,
    started_state_msg = ' ..loading ',
    pending_state_msg = ' ..pending ',
  },
  plugins = {
    icon = icons.default.tool_folder,
    started_state_msg = ' ..loading ',
    pending_state_msg = ' ..pending ',
  },
  project = { icon = icons.default.project },
}

---Lookup for a project inside a list of projects and sub-projects (modules)
---@param id string
---@param projects Project[]
---@return Project
local lookup_project = function(id, projects)
  local project ---@type Project
  for _, item in ipairs(projects) do
    if item.id == id then
      project = item
    end
  end
  return assert(project, 'Project not found')
end

---Execute the command node
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_command_node = function(node, tree, project)
  local command = CommandBuilder.build_mvn_cmd(project.pom_xml_path, node.cmd_args)
  local show_output = MavenConfig.options.console.show_command_execution
  Console.execute_command(command.cmd, command.args, show_output, function(state)
    vim.schedule(function()
      node.state = state
      tree:render()
    end)
  end)
end

---Execute the lifecycle goal node
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_lifecycle_node = function(node, tree, project)
  local command = CommandBuilder.build_mvn_cmd(project.pom_xml_path, { node.cmd_arg })
  local show_output = MavenConfig.options.console.show_lifecycle_execution
  Console.execute_command(command.cmd, command.args, show_output, function(state)
    vim.schedule(function()
      node.state = state
      tree:render()
    end)
  end)
end

---Execute the plugin goal node
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_plugin_goal = function(node, tree, project)
  local command = CommandBuilder.build_mvn_cmd(project.pom_xml_path, { node.cmd_arg })
  local show_output = MavenConfig.options.console.show_plugin_goal_execution
  Console.execute_command(command.cmd, command.args, show_output, function(state)
    vim.schedule(function()
      node.state = state
      tree:render()
    end)
  end)
end

---Load the dependency nodes for the tree
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
---@param on_success? fun()
local load_dependencies_nodes = function(node, tree, project, on_success)
  Sources.load_project_dependencies(project.pom_xml_path, function(state, dependencies)
    vim.schedule(function()
      if Utils.SUCCEED_STATE == state then
        project:set_dependencies(dependencies)
        for _, dependency in ipairs(dependencies) do
          local dependency_node = NuiTree.Node({
            id = dependency.id,
            text = dependency:get_compact_name(),
            type = 'dependency',
            scope = dependency.scope,
            project_id = project.id,
            is_duplicate = dependency.is_duplicate,
          })
          local _parent_id = dependency.parent_id and '-' .. dependency.parent_id or node:get_id()
          tree:add_node(dependency_node, _parent_id)
        end
        node.is_loaded = true
        if on_success then
          on_success()
        else
          node:expand()
        end
      end
      node.state = state
      tree:render()
    end)
  end)
end

---Load the plugin nodes for the tree
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_plugins_nodes = function(node, tree, project)
  Sources.load_project_plugins(project.pom_xml_path, function(state, plugins)
    vim.schedule(function()
      if Utils.SUCCEED_STATE == state then
        project:set_plugins(plugins)
        local plugin_nodes = {}
        for _, plugin in ipairs(project.plugins) do
          local plugin_node = NuiTree.Node({
            id = Utils.uuid(),
            text = plugin:get_short_name(),
            type = 'plugin',
            project_id = project.id,
            is_loaded = false,
            group_id = plugin.group_id,
            artifact_id = plugin.artifact_id,
            version = plugin.version,
            description = plugin:get_compact_name(),
          })
          table.insert(plugin_nodes, plugin_node)
        end
        node.is_loaded = true
        tree:set_nodes(plugin_nodes, node._id)
        node:expand()
      end
      node.state = state
      tree:render()
    end)
  end)
end

---Load the goal nodes for the tree
---@param node NuiTree.Node
---@param tree NuiTree
---@param project Project
local load_plugin_nodes = function(node, tree, project)
  Sources.load_project_plugin_details(
    node.group_id,
    node.artifact_id,
    node.version,
    function(state, plugin)
      vim.schedule(function()
        if Utils.SUCCEED_STATE == state then
          project:replace_plugin(plugin)
          local goal_nodes = {}
          for _, goal in ipairs(plugin.goals) do
            local goal_node = NuiTree.Node({
              text = plugin.goal_prefix .. ':' .. goal.name,
              type = 'plugin_goal',
              cmd_arg = plugin.goal_prefix .. ':' .. goal.name,
              project_id = project.id,
            })
            table.insert(goal_nodes, goal_node)
          end
          node.is_loaded = true
          tree:set_nodes(goal_nodes, node._id)
          node:expand()
        end
        node.state = state
        tree:render()
      end)
    end
  )
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
      started_state_message = 'running',
      project_id = project.id,
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
      started_state_message = 'running',
      project_id = project.id,
    })
  end

  ---Map Commands node
  local commands_node = NuiTree.Node({
    text = 'Commands',
    type = 'commands',
    project_id = project.id,
  }, command_nodes)

  ---Map Lifecycles node
  local lifecycles_node = NuiTree.Node({
    text = 'Lifecycle',
    type = 'lifecycles',
    project_id = project.id,
  }, lifecycle_nodes)

  ---Map Dependencies node
  local dependencies_node = NuiTree.Node({
    id = project.id .. '-dependencies',
    text = 'Dependencies',
    type = 'dependencies',
    is_loaded = false,
    cmd_args = { '' },
    started_state_message = 'loading',
    project_id = project.id,
  })

  ---Map Plugins node
  local plugins_node = NuiTree.Node({
    text = 'Plugins',
    type = 'plugins',
    is_loaded = false,
    started_state_message = 'loading',
    project_id = project.id,
  })

  local project_nodes = { lifecycles_node, dependencies_node, plugins_node }
  if #command_nodes > 0 then
    table.insert(project_nodes, 1, commands_node)
  end

  return NuiTree.Node({
    id = project.id,
    text = project.name,
    type = 'project',
    project_id = project.id,
  }, project_nodes)
end

---Create  the tree component
---@param bufnr any
local create_tree = function(bufnr)
  return NuiTree({
    ns_id = MavenConfig.namespace,
    bufnr = bufnr,
    prepare_node = function(node)
      local props = node_type_props[node.type]
      local line = NuiLine()
      line:append(' ' .. string.rep('  ', node:get_depth() - 1))

      if node:has_children() or node.is_loaded == false then
        line:append(node:is_expanded() and ' ' or ' ', 'SpecialChar')
      else
        line:append('  ')
      end
      line:append(props.icon .. ' ', 'SpecialChar')
      if node.type == 'dependency' and node.is_duplicate and not node:has_children() then
        line:append(node.text, highlights.DIM_TEXT)
      else
        line:append(node.text)
      end
      if node.state == Utils.STARTED_STATE then
        line:append(props.started_state_msg, 'DiagnosticVirtualTextInfo')
      elseif node.state == Utils.PENDING_STATE then
        line:append(props.pending_state_msg, 'DiagnosticVirtualTextWarn')
      end
      if node.description then
        line:append(' (' .. node.description .. ')', highlights.DIM_TEXT)
      end
      return line
    end,
  })
end

---Create the header line
---@return NuiLine
local create_header = function()
  local line = NuiLine()
  local separator = '  '
  line:append(' ' .. icons.default.maven .. ' Maven ' .. separator, highlights.SPECIAL_TEXT)
  line:append(
    icons.default.entry .. '' .. icons.default.tree .. ' Analyze Dependencies',
    highlights.SPECIAL_TEXT
  )
  line:append('<D>' .. separator, highlights.NORMAL_TEXT)
  line:append(icons.default.entry .. '' .. icons.default.help .. ' Help', highlights.SPECIAL_TEXT)
  line:append('<?>' .. separator, highlights.NORMAL_TEXT)
  return line
end

---Setup key maps
---@param tree NuiTree
---@param projects Project[]
local setup_win_maps = function(tree, projects)
  win:map('n', { '<esc>', 'q' }, function()
    M.hide()
  end)

  win:map('n', 'D', function()
    local node = tree:get_node()
    if node == nil then
      vim.notify('Not project selected')
      return
    end
    local project = lookup_project(node.project_id, projects)
    local dependencies_node = tree:get_node('-' .. project.id .. '-dependencies')
    assert(dependencies_node, "Dependencies node doesn't exist on project: " .. project.root_path)
    if dependencies_node.is_loaded then
      DependenciesView.mount(project.name, project.dependencies)
    else
      load_dependencies_nodes(dependencies_node, tree, project, function()
        DependenciesView.mount(project.name, project.dependencies)
      end)
    end
  end, { noremap = true, nowait = true })

  win:map('n', '?', function()
    HelpView.mount()
  end)

  win:map('n', '<enter>', function()
    local node = tree:get_node()
    if node == nil then
      return
    end
    local updated = false
    local project = lookup_project(node.project_id, projects)
    if node.type == 'command' then
      load_command_node(node, tree, project)
    elseif node.type == 'lifecycle' then
      load_lifecycle_node(node, tree, project)
    elseif node.type == 'dependencies' and not node.is_loaded then
      load_dependencies_nodes(node, tree, project)
    elseif node.type == 'plugins' and not node.is_loaded then
      load_plugins_nodes(node, tree, project)
    elseif node.type == 'plugin' and not node.is_loaded then
      load_plugin_nodes(node, tree, project)
    elseif node.type == 'plugin_goal' then
      load_plugin_goal(node, tree, project)
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
    relative = 'editor',
    position = MavenConfig.options.projects_view.position,
    size = MavenConfig.options.projects_view.size,
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

  win = NuiSplit(default_win_options)
  ---Mount the component
  win:mount()
  _is_visible = true

  ---Create the header  line
  local header_line = create_header()
  header_line:render(win.bufnr, MavenConfig.namespace, 1)

  ---Create the Projects line
  local project_line = NuiLine()
  local project_text = ' Projects:'
  if #projects == 0 then
    project_text = project_text .. ' (create a new project) '
  end
  project_line:append(project_text, highlights.DIM_TEXT)
  project_line:render(win.bufnr, MavenConfig.namespace, 2)

  ---Create the tree
  local tree = create_tree(win.bufnr)
  local nodes = {}
  for index, value in ipairs(projects) do
    nodes[index] = create_project_node(value)
  end
  tree:set_nodes(nodes)

  ---Setup maps
  setup_win_maps(tree, projects)

  ---Render the tree
  tree:render(3)
  header_line:highlight(win.bufnr, MavenConfig.namespace, 1)
  project_line:highlight(win.bufnr, MavenConfig.namespace, 2)
  tree:render()
end

M.hide = function()
  win:hide()
  _is_visible = false
end

M.show = function()
  win:show()
  _is_visible = true
end

M.toggle = function()
  if _is_visible then
    M.hide()
  else
    M.show()
  end
end

return M
