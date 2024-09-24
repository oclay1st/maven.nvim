local random = math.random
local Path = require('plenary.path')
local M = {}

M.uuid = function()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

M.maven_data_path = Path:new(vim.fn.stdpath('cache'), 'maven'):absolute()

M.maven_local_repository_path = Path:new(vim.loop.os_homedir(), '.m2', 'repository'):absolute()

M.maven_plugin_xml_path = 'META-INF/maven/plugin.xml'

return M
