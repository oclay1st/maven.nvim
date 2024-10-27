local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local Sources = require('maven.sources')
local ProjectView = require('maven.ui.projects_view')
local ExecuteView = require('maven.ui.execute_view')
local InitializerView = require('maven.ui.initializer_view')

---@class Maven
local M = {}
---@type ProjectView
local projects_view
---@type ExecuteView
local execute_view
---@type InitializerView
local initializer_view

---Setup the plugin
M.setup = function(opts)
  MavenConfig.setup(opts)
  Sources.setup()
  highlights.setup()
end

local function load_projects_view()
  local workspace_path = vim.fn.getcwd()
  local projects = Sources.scan_projects(workspace_path)
  projects_view = ProjectView.new(projects)
  projects_view:mount()
end

M.toggle_projects_view = function()
  if not projects_view then
    load_projects_view()
  else
    projects_view:toggle()
  end
end

M.refresh = function()
  if projects_view then
    projects_view:unmount()
  end
  load_projects_view()
end

M.show_execute_view = function()
  if not execute_view then
    execute_view = ExecuteView:new()
  end
  execute_view:mount()
end

M.show_initializer_view = function()
  if not initializer_view then
    initializer_view = InitializerView.new()
  end
  initializer_view:mount()
end
return M
