local random = math.random
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

M.maven_data_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'maven')
M.maven_cache_path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'maven')

M.maven_local_repository_path = vim.fs.joinpath(vim.fn.expand('~'), '.m2', 'repository')

M.maven_plugin_xml_path = 'META-INF/maven/plugin.xml'

M.archetypes_catalog_url = 'https://repo.maven.apache.org/maven2/archetype-catalog.xml'

M.archetypes_json_path = vim.fs.joinpath(M.maven_data_path, 'archetypes.json')
M.local_catalog_path = vim.fs.joinpath(M.maven_local_repository_path, 'archetype-catalog.xml')

M.local_central_catalog_path =
  vim.fs.joinpath(M.maven_local_repository_path, 'archetype-catalog-central.xml')

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

M.path_separator = (function()
  if jit then
    local os = string.lower(jit.os)
    if os ~= 'windows' then
      return '/'
    else
      return '\\'
    end
  else
    return package.config:sub(1, 1)
  end
end)()

M.get_jar_file_path = function(group_id, artifact_id, version)
  return vim.fs.joinpath(
    M.maven_local_repository_path,
    group_id:gsub('%.', M.path_separator),
    artifact_id,
    version,
    artifact_id .. '-' .. version .. '.jar'
  )
end

return M
