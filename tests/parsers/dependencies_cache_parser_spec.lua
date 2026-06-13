local MiniTest = require('mini.test')
local DependenciesCacheParser = require('maven.parsers.dependencies_cache_parser')
local Project = require('maven.sources.project')
local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse returns empty list when no cache file exists'] = function()
  local result = DependenciesCacheParser.parse('non-existent-key')
  eq(#result, 0)
end

T['dump and parse roundtrip'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local dependencies = {
    Project.Dependency('id-1', nil, 'com.example', 'lib-a', '1.0.0', 'compile', false, nil, 1024),
    Project.Dependency(
      'id-2',
      'id-1',
      'com.example',
      'lib-b',
      '2.0.0',
      'test',
      true,
      '1.0.0',
      2048
    ),
    Project.Dependency('id-3', nil, 'org.other', 'lib-c', '3.0.0', nil, false, nil),
  }

  DependenciesCacheParser.dump('test-key', dependencies)

  local result = DependenciesCacheParser.parse('test-key')
  eq(#result, 3)

  eq(result[1].id, 'id-1')
  eq(result[1].parent_id, nil)
  eq(result[1].group_id, 'com.example')
  eq(result[1].artifact_id, 'lib-a')
  eq(result[1].version, '1.0.0')
  eq(result[1].scope, 'compile')
  eq(result[1].is_duplicate, false)
  eq(result[1].conflict_version, nil)
  eq(result[1].size, 1024)

  eq(result[2].id, 'id-2')
  eq(result[2].parent_id, 'id-1')
  eq(result[2].group_id, 'com.example')
  eq(result[2].artifact_id, 'lib-b')
  eq(result[2].version, '2.0.0')
  eq(result[2].scope, 'test')
  eq(result[2].is_duplicate, true)
  eq(result[2].conflict_version, '1.0.0')
  eq(result[2].size, 2048)

  eq(result[3].id, 'id-3')
  eq(result[3].parent_id, nil)
  eq(result[3].group_id, 'org.other')
  eq(result[3].artifact_id, 'lib-c')
  eq(result[3].version, '3.0.0')
  eq(result[3].scope, nil)
  eq(result[3].is_duplicate, false)
  eq(result[3].conflict_version, nil)
  eq(result[3].size, nil)

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

return T
