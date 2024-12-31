local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local Path = require('plenary.path')
local event = require('nui.utils.autocmd').event
local highlights = require('maven.config.highlights')
local MavenConfig = require('maven.config')
local Utils = require('maven.utils')
local ArchetypeList = require('maven.ui.components.archetype_list')
local CommandBuilder = require('maven.utils.cmd_builder')
local Console = require('maven.utils.console')

---@class InitializerView
---@field private _project_name_component NuiInput
---@field private _project_name string
---@field private _project_package_component NuiInput
---@field private _project_package string
---@field private _archetype_component ArchetypeList
---@field private _archetype Archetype
---@field private _archetype_version_component NuiPopup
---@field private _archetype_version string
---@field private _directory_component NuiPopup
---@field private _directory string
---@field private _default_opts table
---@field private _prev_win number
local InitializerView = {}
InitializerView.__index = InitializerView

---@return InitializerView
function InitializerView.new()
  local buf_options = {
    buftype = 'nofile',
    swapfile = false,
    filetype = 'maven',
    undolevels = -1,
  }
  local win_options = {
    colorcolumn = '',
    signcolumn = 'no',
    number = false,
    relativenumber = false,
    spell = false,
    list = false,
  }
  return setmetatable({
    _default_opts = {
      ns_id = MavenConfig.namespace,
      position = '50%',
      size = { height = '100%', width = 50 },
      buf_options = buf_options,
      win_options = win_options,
      border = {
        text = {
          top_align = 'center',
        },
      },
    },
    _prev_win = vim.api.nvim_get_current_win(),
  }, InitializerView)
end

---@private Create project name component
function InitializerView:_create_project_name_component()
  self._project_name_component = Input(
    vim.tbl_deep_extend('force', self._default_opts, {
      border = {
        text = { top = ' Create Maven Project - Name 1/5 ' },
        style = MavenConfig.options.initializer_view.project_name_win.border.style,
        padding = MavenConfig.options.initializer_view.project_name_win.border.padding
          or { 0, 0, 0, 0 },
      },
    }),
    {
      prompt = '> ',
      on_change = function(value)
        self._project_name = value
      end,
    }
  )
  local function submit()
    if vim.fn.trim(self._project_name) == '' then
      vim.notify('Empty project name', vim.log.levels.ERROR)
    else
      vim.cmd('stopinsert')
      vim.schedule(function()
        self._project_name_component:hide()
        self._project_package_component:show()
      end)
    end
  end
  self._project_name_component:map('n', '<CR>', submit)
  self._project_name_component:map('i', '<CR>', submit)
  self._project_name_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end, { noremap = true })
  self._project_name_component:on(event.BufLeave, function()
    self._project_name_component:hide()
  end)
end

---@private Create project package component
function InitializerView:_create_project_package_component()
  self._project_package_component = Input(
    vim.tbl_deep_extend('force', self._default_opts, {
      border = {
        text = { top = ' Create Maven Project - Package 2/5 ' },
        style = MavenConfig.options.initializer_view.project_package_win.border.style,
        padding = MavenConfig.options.initializer_view.project_package_win.border.padding
          or { 0, 0, 0, 0 },
      },
    }),
    {
      default_value = MavenConfig.options.initializer_view.project_package_win.default_value or '',
      prompt = '> ',
      on_change = function(value)
        self._project_package = value
      end,
    }
  )
  local function submit()
    if not string.match(self._project_package, '(%w+)%.(%w+)') then
      vim.notify('Bad package name format', vim.log.levels.ERROR)
    else
      vim.cmd('stopinsert')
      vim.schedule(function()
        self._project_package_component:hide()
        self._archetype_component:show()
      end)
    end
  end
  self._project_package_component:map('n', '<CR>', submit)
  self._project_package_component:map('i', '<CR>', submit)
  self._project_package_component:map('n', '<bs>', function()
    self._project_package_component:hide()
    self._project_name_component:show()
  end)
  self._project_package_component:on(event.BufLeave, function()
    self._project_package_component:hide()
  end)
  self._project_package_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end, { noremap = true })
end

function InitializerView:_create_archetypes_component()
  self._archetype_component = ArchetypeList({
    title = ' Create Maven Project - Archetype 3/5 ',
    width = self._default_opts.size.width,
    position = self._default_opts.position,
    on_submit_archetype = function(archetype)
      self._archetype = archetype
      self._archetype_component:hide()
      self._archetype_version_component:show()
    end,
  })
  self._archetype_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._archetype_component:map('n', '<bs>', function()
    self._archetype_component:hide()
    self._project_package_component:show()
  end)
end

---@private Create the Java component
function InitializerView:_create_archetype_version_component()
  local opts = vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    win_options = {
      cursorline = true,
      winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT,
    },
    border = {
      text = { top = ' Create Maven Project - Archetype Version 4/5 ' },
      style = MavenConfig.options.initializer_view.archetype_version_win.border.style,
      padding = MavenConfig.options.initializer_view.archetype_version_win.border.padding
        or { 0, 0, 0, 0 },
    },
  })
  self._archetype_version_component = Popup(opts)
  local options_tree = Tree({
    ns_id = MavenConfig.namespace,
    bufnr = self._archetype_version_component.bufnr,
    prepare_node = function(node)
      return Line({ Text(' ' .. node.text) })
    end,
  })
  self._archetype_version_component:on(event.BufWinEnter, function()
    self._archetype_version_component:update_layout(vim.tbl_deep_extend('force', opts, {
      size = { height = #self._archetype.versions },
    }))
    local nodes = vim.tbl_map(function(version)
      return Tree.Node({ text = version })
    end, self._archetype.versions)
    options_tree:set_nodes(nodes)
    options_tree:render()
  end)

  self._archetype_version_component:on(event.BufLeave, function()
    self._archetype_version_component:hide()
  end)
  self._archetype_version_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._archetype_version_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._archetype_version = current_node.text
    self._archetype_version_component:hide()
    self._directory_component:show()
  end)
  self._archetype_version_component:map('n', '<bs>', function()
    self._archetype_version_component:hide()
    self._archetype_component:show()
  end)
end

---@private Create the directory component
function InitializerView:_create_directory_component()
  self._directory_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    size = { height = #MavenConfig.options.initializer_view.workspaces_win.options },
    win_options = {
      cursorline = true,
      winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT,
    },
    border = {
      text = { top = ' Create Maven Project - Directory 5/5 ' },
      style = MavenConfig.options.initializer_view.workspaces_win.border.style,
      padding = MavenConfig.options.initializer_view.workspaces_win.border.padding
        or { 0, 0, 0, 0 },
    },
  }))
  local options_tree = Tree({
    ns_id = MavenConfig.namespace,
    bufnr = self._directory_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ' .. node.text)
      line:append(' ' .. node.project_path, highlights.COMMENT)
      return line
    end,
  })
  local nodes = {}
  for _, workspace in ipairs(MavenConfig.options.initializer_view.workspaces_win.options) do
    local node = Tree.Node({
      text = workspace.name,
      path = workspace.path,
      project_path = workspace.path,
    })
    table.insert(nodes, node)
  end
  options_tree:set_nodes(nodes)
  options_tree:render()
  self._directory_component:on(event.BufWinEnter, function()
    for _, node in ipairs(options_tree:get_nodes()) do
      node.project_path = node.path .. Path.path.sep .. self._project_name
    end
    options_tree:render()
  end)
  self._directory_component:on(event.BufLeave, function()
    self._directory_component:hide()
  end)
  self._directory_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._directory_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._directory = current_node.path
    local _created = self:_create_project()
    if _created then
      self:_quit_all(true)
      if vim.api.nvim_win_is_valid(self._prev_win) then
        vim.api.nvim_set_current_win(self._prev_win)
      end
    end
  end)
  self._directory_component:map('n', '<bs>', function()
    self._directory_component:hide()
    self._archetype_version_component:show()
  end)
end

function InitializerView:_create_project()
  ---@type Path
  local project_directory = Path:new(self._directory, self._project_name)
  if project_directory:exists() then
    vim.notify('Directory already exists', vim.log.levels.ERROR)
    return false
  end
  project_directory:mkdir()
  local _callback = function(state)
    vim.schedule(function()
      if state == Utils.SUCCEED_STATE then
        local choice = vim.fn.confirm(
          'Project created successfully \nDo you want to switch to the New Project?',
          '&Yes\n&No'
        )
        if choice == 1 then
          vim.api.nvim_set_current_dir(project_directory:absolute())
          require('maven').refresh()
        end
      elseif state == Utils.FAILED_STATE then
        vim.notify('Error creating project: ' .. self._project_name, vim.log.levels.ERROR)
      end
    end)
  end
  vim.notify('Creating a new Maven Project...')
  local command = CommandBuilder.create_project(
    vim.trim(self._project_name),
    vim.trim(self._project_package),
    self._archetype.group_id,
    self._archetype.artifact_id,
    self._archetype_version,
    self._directory
  )
  local show_output = MavenConfig.options.console.show_project_create_execution
  Console.execute_command(
    command.cmd,
    command.args,
    show_output,
    _callback,
    project_directory:absolute()
  )
  return true
end

---@private Quit all
function InitializerView:_quit_all(force)
  local buf = vim.api.nvim_get_current_buf()
  local wins = {
    self._project_package_component,
    self._project_name_component,
    self._archetype_component,
    self._archetype_version_component,
    self._directory_component,
  }
  local outside = true
  for _, win in ipairs(wins) do
    if win.bufnr == buf then
      outside = false
    end
  end
  if outside or force then
    for _, win in ipairs(wins) do
      win:unmount()
    end
    if vim.api.nvim_win_is_valid(self._prev_win) then
      vim.api.nvim_set_current_win(self._prev_win)
    end
  end
end

---Mount the window view
function InitializerView:mount()
  -- create the package input
  self:_create_project_package_component()
  -- create the name input
  self:_create_project_name_component()
  -- crate the archetypes list
  self:_create_archetypes_component()
  -- crate the archetypes version list
  self:_create_archetype_version_component()
  -- create the directory
  self:_create_directory_component()
  -- mount the first component
  self._project_name_component:show()
end

return InitializerView
