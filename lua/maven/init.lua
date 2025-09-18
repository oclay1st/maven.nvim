local highlights = require('maven.config.highlights')
local MavenConfig = require('maven.config')
local Sources = require('maven.sources')
local ProjectView = require('maven.ui.projects_view')
local ExecutionView = require('maven.ui.execution_view')
local InitializerView = require('maven.ui.initializer_view')
local ArgumentView = require('maven.ui.arguments_view')
local FavoritesView = require('maven.ui.favorites_view')

local M = {}

local projects_view ---@type ProjectView
local execution_view ---@type ExecutionView
local initializer_view ---@type InitializerView
local argument_view ---@type ArgumentView

---Setup the plugin
M.setup = function(opts)
  MavenConfig.setup(opts)
  Sources.setup()
  highlights.setup()
end

local function load_projects_view()
  local workspace_path = vim.fn.getcwd()
  projects_view = ProjectView.new()
  projects_view:mount()
  projects_view:set_loading(true)
  Sources.scan_projects(workspace_path, function(projects)
    vim.schedule(function()
      projects_view:refresh_projects(projects)
      projects_view:set_loading(false)
    end)
  end)
end

M.toggle_projects_view = function()
  if not projects_view then
    load_projects_view()
  else
    projects_view:toggle()
  end
end

M.reset_projects_view = function()
  if projects_view then
    projects_view:unmount()
  end
  load_projects_view()
end

M.refresh_projects_view = function(projects)
  if projects_view then
    projects_view:refresh_projects(projects)
  end
end

M.show_execution_view = function()
  if not execution_view then
    execution_view = ExecutionView:new()
  end
  execution_view:mount()
end

M.show_initializer_view = function()
  if not initializer_view then
    initializer_view = InitializerView.new()
  end
  initializer_view:mount()
end

M.show_argument_view = function()
  if not argument_view then
    argument_view = ArgumentView.new()
  end
  argument_view:mount()
end

---Show favorite commands
---@param projects? Project[]
M.show_favorite_commands = function(projects)
  local workspace_path = vim.fn.getcwd()
  if projects == nil then
    Sources.scan_projects(workspace_path, function(_projects)
      vim.schedule(function()
        local favorite_view = FavoritesView.new(_projects)
        favorite_view:mount()
      end)
    end)
  else
    local favorite_view = FavoritesView.new(projects)
    favorite_view:mount()
  end
end

return M
