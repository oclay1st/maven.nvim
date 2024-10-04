local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local Sources = require('maven.sources')
local ProjectView = require('maven.ui.projects_view')

---@class Maven
local M = {}

local projects_view

---Setup the plugin
M.setup = function(opts)
  MavenConfig.setup(opts)
  highlights.setup()
end

M.toggle = function()
  if not projects_view then
    local workspace_path = vim.fn.getcwd()
    local projects = Sources.scan_projects(workspace_path)
    projects_view = ProjectView.new(projects)
    projects_view:mount()
  else
    projects_view:toggle()
  end
end

return M
