local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local NuiText = require('nui.text')
local Popup = require('nui.popup')
local Input = require('nui.input')
local Text = require('nui.text')
local Layout = require('nui.layout')
local event = require('nui.utils.autocmd').event
local highlights = require('maven.config.highlights')
local MavenConfig = require('maven.config')
local Utils = require('maven.utils')

---@class DependenciesView
---@field private _dependencies_win NuiPopup
---@field private _dependencies_tree NuiTree
---@field private _dependency_usages_win NuiPopup
---@field private _dependency_usages_tree NuiTree
---@field private _dependency_filter NuiInput
---@field private _dependencies_header NuiLine
---@field private _dependency_usages_header NuiLine
---@field private _dependency_details_win NuiPopup
---@field private _layout NuiLayout
---@field private _default_opts table
---@field private _prev_win number
---@field private _is_filter_visible boolean
---@field private _filter_value string
---@field dependencies Project.Dependency[]
---@field project_name string
---@field project_artifact_id string
---@field project_version string
local DependenciesView = {}

DependenciesView.__index = DependenciesView

function DependenciesView.new(project_name, project_artifact_id, project_version, dependencies)
  return setmetatable({
    project_name = project_name,
    project_artifact_id = project_artifact_id,
    project_version = project_version,
    dependencies = dependencies,
    _default_opts = {
      ns_id = MavenConfig.namespace,
      buf_options = {
        buftype = 'nofile',
        swapfile = false,
        filetype = 'maven',
        undolevels = -1,
      },
      win_options = {
        cursorline = true,
        colorcolumn = '',
        signcolumn = 'no',
        number = false,
        relativenumber = false,
        spell = false,
        list = false,
        winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT,
      },
    },
    _prev_win = vim.api.nvim_get_current_win(),
    _is_filter_visible = false,
  }, DependenciesView)
end

---Create dependency node
---@param dependency Project.Dependency
---@return NuiTree.Node
local function create_tree_node(dependency)
  return NuiTree.Node({
    id = dependency.id,
    text = dependency.artifact_id .. ':' .. dependency.version,
    name = dependency.group_id .. ':' .. dependency.artifact_id,
    group_id = dependency.group_id,
    artifact_id = dependency.artifact_id,
    version = dependency.version,
    scopes = dependency.scope and { dependency.scope } or {},
    is_duplicate = dependency.is_duplicate,
    has_conflict = dependency.conflict_version and true or false,
    conflict_version = dependency.conflict_version,
    size = dependency.size,
  })
end

---Filter the related dependencies by name
---@param name string
---@param indexed_dependencies table
local function filter_dependencies(name, indexed_dependencies)
  local filtered_dependencies = {}
  local filtered = {}
  for _, dependency in pairs(indexed_dependencies) do
    if name == dependency.group_id .. ':' .. dependency.artifact_id then
      local pos_to_insert = #filtered_dependencies + 1
      local id = dependency.id
      while id ~= nil and filtered[id] == nil do
        filtered[id] = 1
        table.insert(filtered_dependencies, pos_to_insert, indexed_dependencies[id])
        id = indexed_dependencies[id].parent_id
      end
    end
  end
  return filtered_dependencies
end

---@private Create dependencies window
function DependenciesView:_create_dependencies_win()
  local dependencies_win_opts = vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    border = {
      text = { top = ' Resolved Dependencies (' .. self.project_name .. ') ' },
      style = MavenConfig.options.dependencies_view.resolved_dependencies_win.border.style,
      padding = MavenConfig.options.dependencies_view.resolved_dependencies_win.border.padding
        or { 0, 0, 0, 0 },
    },
  })
  self._dependencies_win = Popup(dependencies_win_opts)
  self:_create_dependencies_tree()
  local indexed_dependencies = {}
  for _, item in ipairs(self.dependencies) do
    indexed_dependencies[item.id] = item
  end
  self._dependencies_win:on(event.CursorMoved, function()
    self._dependency_usages_tree:set_nodes({})
    local filtered_dependencies = self.dependencies
    local current_node = self._dependencies_tree:get_node()
    if current_node then
      filtered_dependencies = filter_dependencies(current_node.name, indexed_dependencies)
    end
    for _, dependency in pairs(filtered_dependencies) do
      local parent_id = dependency.parent_id and '-' .. dependency.parent_id or nil
      local node = create_tree_node(dependency)
      self._dependency_usages_tree:add_node(node, parent_id)
      if parent_id then
        self._dependency_usages_tree:get_node(parent_id):expand()
      end
    end
    self._dependency_usages_tree:render(2)
    self._dependency_usages_header:highlight(
      self._dependency_usages_win.bufnr,
      MavenConfig.namespace,
      1
    )
  end)
  self._dependencies_win:map('n', { 'i' }, function()
    local current_node = self._dependencies_tree:get_node()
    if current_node == nil then
      return
    end
    self:_show_dependency_detials(current_node)
  end, { nowait = true })
  ---Setup the filter
  self._dependencies_win:map('n', { '/', 's' }, function()
    self:_toggle_filter()
  end, { noremap = true, nowait = true })
  self._dependencies_win:map('n', { '<c-l>', '<c-s>' }, function()
    vim.api.nvim_set_current_win(self._dependency_usages_win.winid)
  end, { nowait = true })
  self._dependencies_win:map('n', { 'os' }, function()
    self:_sort_dependencies_by_size()
  end, { noremap = true, nowait = true })
  self._dependencies_win:map('n', { 'on' }, function()
    self:_sort_dependencies_by_name()
  end, { noremap = true, nowait = true })
end

---@private Create the dependencies header
function DependenciesView:_create_dependencies_header()
  local header = NuiLine()
  header:append(' ' .. MavenConfig.options.icons.maven .. ' ', highlights.SPECIAL)
  header:append(self.project_artifact_id .. ':' .. self.project_version .. ' ', highlights.BOLD)
  header:append('(' .. self.project_name .. ')', highlights.COMMENT)
  local spaces = vim.api.nvim_win_get_width(self._dependencies_win.winid) - header:width()
  header:append(string.format('%' .. spaces .. 's  ', 'Size '), highlights.BOLD)
  vim.api.nvim_set_option_value('modifiable', true, { buf = self._dependencies_win.bufnr })
  vim.api.nvim_set_option_value('readonly', false, { buf = self._dependencies_win.bufnr })
  header:render(self._dependencies_win.bufnr, MavenConfig.namespace, 1)
  vim.api.nvim_set_option_value('modifiable', false, { buf = self._dependencies_win.bufnr })
  vim.api.nvim_set_option_value('readonly', true, { buf = self._dependencies_win.bufnr })
  self._dependencies_header = header
end

---@private Create the dependencies tree
function DependenciesView:_create_dependencies_tree()
  self._dependencies_tree = NuiTree({
    ns_id = MavenConfig.namespace,
    bufnr = self._dependencies_win.bufnr,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(' ')
      local icon = node.has_conflict and MavenConfig.options.icons.warning
        or MavenConfig.options.icons.package
      local icon_highlight = node.has_conflict and highlights.WARN or highlights.SPECIAL
      line:append(icon .. ' ', icon_highlight)
      line:append(node.text)
      if #node.scopes == 1 then
        line:append(' (' .. node.scopes[1] .. ')', highlights.COMMENT)
      elseif #node.scopes > 1 then
        local scope_text = #node.scopes == 1 and 'scope' or 'scopes'
        line:append(' (' .. #node.scopes .. ' ' .. scope_text .. ')', highlights.COMMENT)
      end
      if self._dependencies_win.winid then
        local width = vim.api.nvim_win_get_width(self._dependencies_win.winid) - line:width()
        local size = Utils.humanize_size(node.size) or '-'
        line:append(string.format('%' .. width .. 's  ', size .. ' '), highlights.COMMENT)
      end
      return line
    end,
  })
  local nodes = self:_create_dependencies_tree_nodes()
  self._dependencies_tree:set_nodes(nodes)
  self._dependencies_tree:render(2)
end

---@private Create the node list of dependencies
function DependenciesView:_create_dependencies_tree_nodes()
  local nodes_indexes = {}
  for _, dependency in ipairs(self.dependencies) do
    local name = dependency.group_id .. ':' .. dependency.artifact_id
    if nodes_indexes[name] == nil then
      local node = create_tree_node(dependency)
      nodes_indexes[name] = node
    elseif
      dependency.scope and not vim.tbl_contains(nodes_indexes[name].scopes, dependency.scope)
    then
      table.insert(nodes_indexes[name].scopes, dependency.scope)
    end
    if dependency.conflict_version then
      nodes_indexes[name].has_conflict = true
    end
    if dependency.is_duplicate then
      nodes_indexes[name].is_duplicate = true
    end
  end
  local nodes = vim.tbl_values(nodes_indexes)
  table.sort(nodes, function(a, b)
    return string.lower(a.artifact_id) < string.lower(b.artifact_id)
  end)
  return nodes
end

---@private Toggle filter
function DependenciesView:_toggle_filter()
  if self._is_filter_visible then
    self._dependency_filter:hide()
    if self._filter_value == '' then
      self._dependencies_win.border:set_text('bottom')
    else
      self._dependencies_win.border:set_text(
        'bottom',
        Text(' Filtered by: "' .. self._filter_value .. '" ', highlights.COMMENT),
        'left'
      )
    end
    vim.cmd('stopinsert')
  else
    self._dependency_filter:show()
    vim.cmd('startinsert!')
  end
  self._is_filter_visible = not self._is_filter_visible
end

---@private Sort the dependencies by size
function DependenciesView:_sort_dependencies_by_size()
  local nodes = self._dependencies_tree:get_nodes()
  table.sort(nodes, function(a, b)
    if a.size == nil then
      return false
    end
    if b.size == nil then
      return true
    end
    return a.size > b.size
  end)
  self._dependencies_tree:set_nodes(nodes)
  self._dependencies_tree:render()
end

---@private Sort the dependencies by size
function DependenciesView:_sort_dependencies_by_name()
  local nodes = self._dependencies_tree:get_nodes()
  table.sort(nodes, function(a, b)
    return string.lower(a.artifact_id) < string.lower(b.artifact_id)
  end)
  self._dependencies_tree:set_nodes(nodes)
  self._dependencies_tree:render()
end

---@private Create dependency usages window
function DependenciesView:_create_dependency_usages_win()
  local dependency_usages_win_opts = vim.tbl_deep_extend('force', self._default_opts, {
    border = {
      text = { top = ' Dependency Usages ' },
      style = MavenConfig.options.dependencies_view.dependency_usages_win.border.style,
      padding = MavenConfig.options.dependencies_view.dependency_usages_win.border.padding
        or { 0, 0, 0, 0 },
    },
  })
  self._dependency_usages_win = Popup(dependency_usages_win_opts)
  self:_create_dependency_usages_tree()
  self._dependency_usages_win:map('n', '<enter>', function()
    local node = self._dependency_usages_tree:get_node()
    if node == nil then
      return
    end
    local updated = false
    if node:is_expanded() then
      updated = node:collapse() or updated
    else
      updated = node:expand() or updated
    end
    if updated then
      self._dependency_usages_tree:render()
    end
  end)
  self._dependency_usages_win:map('n', { '<c-h>', '<c-s>' }, function()
    vim.api.nvim_set_current_win(self._dependencies_win.winid)
  end, { nowait = true })
end

---@private Create the dependency usages tree
function DependenciesView:_create_dependency_usages_tree()
  self._dependency_usages_tree = NuiTree({
    ns_id = MavenConfig.namespace,
    bufnr = self._dependency_usages_win.bufnr,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(' ' .. string.rep('  ', node:get_depth() - 1))
      if node:has_children() then
        line:append(node:is_expanded() and ' ' or ' ', highlights.SPECIAL)
      else
        line:append('  ')
      end
      local icon = MavenConfig.options.icons.package
      local icon_highlight = highlights.SPECIAL
      if node.conflict_version and not node:has_children() then
        icon_highlight = highlights.WARN
        icon = MavenConfig.options.icons.warning
      end
      line:append(icon .. ' ', icon_highlight)
      if node.is_duplicate and not node:has_children() then
        line:append(node.text, highlights.COMMENT)
      else
        line:append(node.text)
      end
      if #node.scopes ~= 0 then
        line:append(' (' .. node.scopes[1] .. ')', highlights.COMMENT)
      end
      if node.conflict_version and not node:has_children() then
        line:append(' conflict with ' .. node.conflict_version, highlights.ERROR)
      end
      return line
    end,
  })
end

---@private Create the dependency usages header
function DependenciesView:_create_dependency_usages_header()
  local header = NuiLine()
  header:append(' ' .. MavenConfig.options.icons.maven .. ' ', highlights.SPECIAL)
  header:append(self.project_artifact_id .. ':' .. self.project_version .. ' ', highlights.BOLD)
  header:append('(' .. self.project_name .. ')', highlights.COMMENT)
  vim.api.nvim_set_option_value('modifiable', true, { buf = self._dependency_usages_win.bufnr })
  vim.api.nvim_set_option_value('readonly', false, { buf = self._dependency_usages_win.bufnr })
  header:render(self._dependency_usages_win.bufnr, MavenConfig.namespace, 1)
  vim.api.nvim_set_option_value('modifiable', false, { buf = self._dependency_usages_win.bufnr })
  vim.api.nvim_set_option_value('readonly', true, { buf = self._dependency_usages_win.bufnr })
  self._dependency_usages_header = header
end

---@private React on filter change
function DependenciesView:_on_filter_change(search, dependencies_nodes)
  self._filter_value = search
  vim.schedule(function()
    local nodes = {}
    local _search = string.gsub(search, '%W', '%%%1') -- scape special characters
    for _, node in ipairs(dependencies_nodes) do
      if string.find(node.name, _search) then
        table.insert(nodes, node)
      end
    end
    self._dependencies_tree:set_nodes(nodes)
    self._dependencies_tree:render()
    vim.api.nvim_win_set_cursor(self._dependencies_win.winid, { 1, 0 })
  end)
end

---@private Create the dependency filter component
function DependenciesView:_create_dependency_filter()
  local win_height = vim.api.nvim_win_get_height(self._dependencies_win.winid)
  local relative_row = win_height - 1
  local win_width = vim.api.nvim_win_get_width(self._dependencies_win.winid)
  local dependencies_nodes = self._dependencies_tree:get_nodes()
  self._dependency_filter = Input({
    ns_id = MavenConfig.namespace,
    relative = 'win',
    position = {
      row = relative_row,
      col = 0,
    },
    size = {
      width = win_width,
    },
    zindex = 60,
    border = {
      text = {
        top = 'Filter',
        top_align = 'center',
      },
      style = MavenConfig.options.dependencies_view.filter_win.border.style,
      padding = MavenConfig.options.dependencies_view.filter_win.border.padding or { 0, 0, 0, 0 },
    },
  }, {
    prompt = NuiText(MavenConfig.options.icons.search .. '  ', highlights.SPECIAL),
    on_change = function(value)
      self:_on_filter_change(value, dependencies_nodes)
    end,
  })

  self._dependency_filter:map('i', '<enter>', function()
    self:_toggle_filter()
  end, { noremap = true, nowait = true })
  self._dependency_filter:map('n', '<enter>', function()
    self:_toggle_filter()
  end, { noremap = true, nowait = true })
  self._dependency_filter:map('n', { '<esc>', 'q' }, function()
    self:_toggle_filter()
  end, { noremap = true, nowait = true })
end

function DependenciesView:_create_dependency_details()
  local opts = vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    relative = 'win',
    position = '50%',
    size = MavenConfig.options.dependencies_view.dependency_details_win.size,
    border = {
      text = { top = ' Dependency Details ' },
      style = MavenConfig.options.dependencies_view.dependency_details_win.border.style,
      padding = MavenConfig.options.dependencies_view.dependency_details_win.border.padding
        or { 0, 0, 0, 0 },
    },
    zindex = 60,
  })
  self._dependency_details_win = Popup(opts)
  self._dependency_details_win:on(event.BufLeave, function()
    self._dependency_details_win:unmount()
  end)
  self._dependency_details_win:map('n', { '<esc>', 'q' }, function()
    self._dependency_details_win:unmount()
  end)
end

---Show the dependency info
function DependenciesView:_show_dependency_detials(node)
  self:_create_dependency_details()
  local properties = {
    { key = 'Group: ', value = node.group_id },
    { key = 'Artifact: ', value = node.artifact_id },
    { key = 'Version: ', value = node.version },
    { key = 'Size: ', value = Utils.humanize_size(node.size) },
    { key = 'Scopes: ', value = #node.scopes ~= 0 and table.concat(node.scopes, ' ') or nil },
  }
  self._dependency_details_win:mount()
  for index, property in ipairs(properties) do
    local line = NuiLine()
    line:append(string.format(' %14s', property.key), highlights.SPECIAL)
    line:append(' -> ', highlights.COMMENT)
    line:append(property.value or '-')
    line:render(self._dependency_details_win.bufnr, MavenConfig.namespace, index)
  end
  vim.api.nvim_set_option_value('modifiable', false, { buf = self._dependency_details_win.bufnr })
  vim.api.nvim_set_option_value('readonly', true, { buf = self._dependency_details_win.bufnr })
end

---@private Create the component layout
function DependenciesView:_create_layout()
  self._layout = Layout(
    {
      ns_id = MavenConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = MavenConfig.options.dependencies_view.size,
    },
    Layout.Box({
      Layout.Box(self._dependencies_win, { size = '50%' }),
      Layout.Box(self._dependency_usages_win, { size = '50%' }),
    }, { dir = 'row' })
  )
  local wins = { self._dependencies_win, self._dependency_usages_win }
  for _, win in pairs(wins) do
    win:on(event.BufLeave, function()
      vim.schedule(function()
        local current_buf = vim.api.nvim_get_current_buf()
        for _, w in pairs(wins) do
          if w.bufnr == current_buf then
            return
          end
        end
        self._dependency_filter:unmount()
        self._layout:unmount()
        vim.api.nvim_set_current_win(self._prev_win)
      end)
    end)
    win:map('n', { '<esc>', 'q' }, function()
      self._dependency_filter:unmount()
      self._layout:unmount()
      vim.api.nvim_set_current_win(self._prev_win)
    end)
  end
end

---Mount component
function DependenciesView:mount()
  ---Setup the dependencies window
  self:_create_dependencies_win()
  ---Setup the dependency usages window
  self:_create_dependency_usages_win()
  ---Setup the layout
  self:_create_layout()
  ---Mount the layout
  self._layout:mount()
  ---Setup the dependencies header after the layout get mount
  self:_create_dependencies_header()
  ---Setup the dependency usages header after the layout get mount
  self:_create_dependency_usages_header()
  ---Setup the dependency filter after the layout get mount
  self:_create_dependency_filter()
  ---Render the dependencies tree to show the size
  self._dependencies_tree:render()
end

return DependenciesView
