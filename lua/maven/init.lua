local highlights = require('maven.highlights')
local MavenConfig = require('maven.config')
local sources = require('maven.sources')
local explorer = require('maven.ui.explorer')

local M = {}

---comment
M.setup = function(opts)
  MavenConfig.merge(opts)
  highlights.setup()
end

M.open_explorer = function()
  local workspace_path = vim.fn.getcwd()
  local projects = sources.scan_projects(workspace_path)
  explorer.mount(projects)
end

return M
