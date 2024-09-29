local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local Sources = require('maven.sources')
local ProjectView = require('maven.ui.projects_view')

---@class Maven
local M = {}

local is_mounted = false

---Setup the plugin
M.setup = function(opts)
  MavenConfig.setup(opts)
  highlights.setup()
end

M.toggle = function()
  if not is_mounted then
    local workspace_path = vim.fn.getcwd()
    local projects = Sources.scan_projects(workspace_path)
    ProjectView.mount(projects)
    is_mounted = true
  else
    ProjectView.toggle()
  end
end

return M
