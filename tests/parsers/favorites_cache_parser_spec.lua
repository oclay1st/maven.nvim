local MiniTest = require('mini.test')
local FavoritesCacheParser = require('maven.parsers.favorites_cache_parser')
local Project = require('maven.sources.project')
local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse returns empty list when no cache file exists'] = function()
  local result = FavoritesCacheParser.parse('non-existent-key')
  eq(#result, 0)
end

T['dump and parse roundtrip'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local favorites = {
    Project.Favorite('clean', 'lifecycle', 'Clean the project', { 'clean' }),
    Project.Favorite('test', 'lifecycle', 'Run tests', { 'test' }),
    Project.Favorite('my-goal', 'goal', nil, { 'plugin:my-goal' }),
  }

  FavoritesCacheParser.dump('test-key', favorites)

  local result = FavoritesCacheParser.parse('test-key')
  eq(#result, 3)

  eq(result[1].name, 'clean')
  eq(result[1].type, 'lifecycle')
  eq(result[1].description, 'Clean the project')
  eq(result[1].cmd_args, { 'clean' })

  eq(result[2].name, 'test')
  eq(result[2].type, 'lifecycle')
  eq(result[2].description, 'Run tests')
  eq(result[2].cmd_args, { 'test' })

  eq(result[3].name, 'my-goal')
  eq(result[3].type, 'goal')
  eq(result[3].description, nil)
  eq(result[3].cmd_args, { 'plugin:my-goal' })

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

return T
