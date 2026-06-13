local MiniTest = require('mini.test')
local ProjectsCacheParser = require('maven.parsers.projects_cache_parser')
local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse returns empty list when no cache file exists'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local result = ProjectsCacheParser.parse()
  eq(#result, 0)

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

T['register creates a new entry and returns a key'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local key = ProjectsCacheParser.register('/path/to/pom.xml')
  eq(type(key), 'string')
  eq(#key > 0, true)

  local projects = ProjectsCacheParser.parse()
  eq(#projects, 1)
  eq(projects[1].path, '/path/to/pom.xml')
  eq(projects[1].key, key)

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

T['register returns existing key for known path'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local key1 = ProjectsCacheParser.register('/path/to/pom.xml')
  local key2 = ProjectsCacheParser.register('/path/to/pom.xml')

  eq(key1, key2)

  local projects = ProjectsCacheParser.parse()
  eq(#projects, 1)

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

T['register handles multiple distinct paths'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local key_a = ProjectsCacheParser.register('/path/a/pom.xml')
  local key_b = ProjectsCacheParser.register('/path/b/pom.xml')

  eq(key_a ~= key_b, true)

  local projects = ProjectsCacheParser.parse()
  eq(#projects, 2)

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

return T
