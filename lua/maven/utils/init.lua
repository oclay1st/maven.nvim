local random = math.random
local Path = require('plenary.path')
local M = {}

M.STARTED_STATE = 'STARTED'
M.SUCCEED_STATE = 'SUCCEED'
M.FAILED_STATE = 'FAILED'
M.PENDING_STATE = 'PENDING'

M.uuid = function()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

M.maven_data_path = Path:new(vim.fn.stdpath('data'), 'maven'):absolute()
M.maven_cache_path = Path:new(vim.fn.stdpath('cache'), 'maven'):absolute()

M.maven_local_repository_path = Path:new(Path.path.home, '.m2', 'repository'):absolute()

M.maven_plugin_xml_path = 'META-INF/maven/plugin.xml'

M.archetypes_catalog_url = 'https://repo.maven.apache.org/maven2/archetype-catalog.xml'

---@type Path
M.archetypes_json_path = Path:new(M.maven_data_path, 'archetypes.json')

---@type Path
M.local_catalog_path = Path:new(M.maven_local_repository_path, 'archetype-catalog.xml')

---@type Path
M.local_central_catalog_path =
  Path:new(M.maven_local_repository_path, 'archetype-catalog-central.xml')

M.get_plugin_root_dir = function()
  local source = debug.getinfo(1).source

  if jit and jit.os and string.lower(jit.os) == 'windows' then
    source = source:gsub('/', '\\')
  end

  local dir_path = source:match('@(.*/)') or source:match('@(.*\\)')
  if dir_path == nil then
    return nil
  end
  return dir_path .. '..'
end

M.humanize_size = function(size)
  if not size then
    return nil
  end
  local units = { 'B', 'KB', 'MB', 'GB', 'TB' }
  local unit_index = 1

  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end
  return string.format('%.2f %s', size, units[unit_index])
end

M.get_jar_file_path = function(group_id, artifact_id, version)
  return Path:new(
    M.maven_local_repository_path,
    group_id:gsub('%.', Path.path.sep),
    artifact_id,
    version,
    artifact_id .. '-' .. version .. '.jar'
  ):absolute()
end

return M
