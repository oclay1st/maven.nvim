local Object = require('nui.object')
local Tree = require('nui.tree')
local Popup = require('nui.popup')
local Input = require('nui.input')
local Line = require('nui.line')
local Text = require('nui.text')
local highlights = require('maven.config.highlights')
local Layout = require('nui.layout')
local MavenConfig = require('maven.config')
local Sources = require('maven.sources')
local Utils = require('maven.utils')

---@class archetypes_options
---@field title string
---@field width string | number
---@field position string
---@field on_submit_archetype fun(item: Archetype)

---@class ArchetypeList
---@field _options archetypes_options
---@field private _options_nodes NuiTree.Node
---@field _default_opts table
local ArchetypeList = Object('ArchetypeList')

---Create a new ArchetypeList
---@param options archetypes_options
function ArchetypeList:init(options)
  self._options = options
  self._default_opts = {
    ns_id = MavenConfig.namespace,
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
  self:_create_components()
end

---Map to archetype node
---@param archetype Archetype
local function map_archetype_node(archetype)
  return Tree.Node({
    id = Utils.uuid(),
    text = archetype.artifact_id,
    type = 'archetype',
    item = archetype,
  })
end

---@private Create the options component
function ArchetypeList:_create_options_component()
  self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    win_options = { cursorline = true },
  }, { border = MavenConfig.options.initializer_view.archetypes_win.options_win.border }))
  self:_create_options_tree()
  self._options_component:map('n', '<enter>', function()
    self:_submit_option()
  end)
  self._options_component:map('n', { 'i' }, function()
    vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
    vim.api.nvim_set_current_win(self._input_component.winid)
    vim.api.nvim_win_set_cursor(self._input_component.winid, { 1, 0 })
    vim.cmd('startinsert!')
  end)
end

---@private Create the options tree list
function ArchetypeList:_create_options_tree()
  self._options_tree = Tree({
    ns_id = MavenConfig.namespace,
    bufnr = self._options_component.bufnr,
    prepare_node = function(node)
      local line = Line({ Text(' ') })
      if node.type == 'archetype' then
        line:append(MavenConfig.options.icons.package, highlights.SPECIAL_TEXT)
        line:append(' ' .. node.text)
        line:append(' (' .. node.item.group_id .. ')', highlights.DIM_TEXT)
      elseif node.type == 'loading' then
        line:append(MavenConfig.options.icons.search .. ' ' .. node.text, highlights.SPECIAL_TEXT)
        line:append('(from Catalog)', highlights.DIM_TEXT)
      else
        line:append(' ' .. node.text)
      end
      return line
    end,
  })
  self._options_tree:render()
  local default_archetypes = Sources.load_default_archetype_catalog()
  local nodes = {}
  for _, archetype in ipairs(default_archetypes) do
    table.insert(nodes, map_archetype_node(archetype))
  end
  table.insert(nodes, Tree.Node({ text = 'Load more archetypes...', type = 'loading' }))
  self:_refresh_options_tree(nodes)
end

---@private Refresh the options tree
function ArchetypeList:_refresh_options_tree(nodes)
  self._options_nodes = nodes
  self._options_tree:set_nodes(self._options_nodes)
  self._options_tree:render()
end

---@private Handle option submit
function ArchetypeList:_submit_option()
  local node = self._options_tree:get_node()
  if not node then
    return
  end
  if node.type == 'loading' then
    Sources.load_archetype_catalog(function(archetypes)
      vim.schedule(function()
        local _nodes = {}
        for _, item in ipairs(archetypes) do
          table.insert(_nodes, map_archetype_node(item))
        end
        self:_refresh_options_tree(_nodes)
      end)
    end)
  else
    self._options.on_submit_archetype(node.item)
  end
end

---@private Create the input component
function ArchetypeList:_create_input_component()
  self._input_component = Input(
    vim.tbl_deep_extend('force', self._default_opts, {
      border = {
        text = { top = self._options.title, top_align = 'center' },
      },
    }, { border = MavenConfig.options.initializer_view.archetypes_win.input_win.border }),
    {
      prompt = '> ',
      on_change = function(query)
        self:_on_input_change(query)
      end,
    }
  )
  local function move_next()
    vim.api.nvim_set_current_win(self._options_component.winid)
    vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
  end
  self._input_component:map('n', '<enter>', function()
    self:_submit_option()
  end)
  self._input_component:map('i', '<enter>', function()
    self:_submit_option()
    vim.cmd('stopinsert')
  end)
  self._input_component:map('i', { '<C-n>', '<Down>' }, move_next)
  self._input_component:map('n', { 'j', '<C-n>', '<Down>' }, move_next)
end

---@private On input change handler
---@param query any
function ArchetypeList:_on_input_change(query)
  local _query = string.gsub(query, '%W', '%%%1')
  vim.schedule(function()
    local filtered_nodes = vim.tbl_filter(function(node)
      return _query == '' or string.match(node.text, _query)
    end, self._options_nodes)
    self._options_tree:set_nodes(filtered_nodes)
    self._options_tree:render()
    if self._options_component.winid then
      vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
    end
  end)
end

---@private Crete the layout
function ArchetypeList:_create_layout()
  self._layout = Layout(
    {
      ns_id = MavenConfig.namespace,
      position = self._options.position,
      size = {
        width = self._options.width,
        height = 12,
      },
    },
    Layout.Box({
      Layout.Box(self._input_component, { size = { height = 1, width = '100%' } }),
      Layout.Box(self._options_component, { size = '100%' }),
    }, { dir = 'col' })
  )
end

---@private Create the components
function ArchetypeList:_create_components()
  -- Create options list
  self:_create_options_component()
  --Create the input component
  self:_create_input_component()
  -- create the layout
  self:_create_layout()
end

function ArchetypeList:show()
  self._layout:show()
end

function ArchetypeList:hide()
  self._layout:hide()
end

function ArchetypeList:unmount()
  self._layout:unmount()
end

-- set key map
---@param mode string check `:h :map-modes`
---@param key string|string[] key for the mapping
---@param handler string | fun(): nil handler for the mapping
---@param opts? table<"'expr'"|"'noremap'"|"'nowait'"|"'remap'"|"'script'"|"'silent'"|"'unique'", boolean>
---@return nil
function ArchetypeList:map(mode, key, handler, opts, ___force___)
  self._input_component:map(mode, key, handler, opts, ___force___)
  self._options_component:map(mode, key, handler, opts, ___force___)
end

return ArchetypeList
