local MiniTest = require('mini.test')
local PluginsCacheParser = require('maven.parsers.plugins_cache_parser')
local Project = require('maven.sources.project')
local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse returns empty list when no cache file exists'] = function()
  local result = PluginsCacheParser.parse('non-existent-key')
  eq(#result, 0)
end

T['dump and parse roundtrip'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local plugins = {
    Project.Plugin('org.apache.maven.plugins', 'maven-compiler-plugin', '3.8.1'),
    Project.Plugin('org.apache.maven.plugins', 'maven-surefire-plugin', '2.22.2'),
  }

  PluginsCacheParser.dump('test-key', plugins)

  local result = PluginsCacheParser.parse('test-key')
  eq(#result, 2)

  eq(result[1].group_id, 'org.apache.maven.plugins')
  eq(result[1].artifact_id, 'maven-compiler-plugin')
  eq(result[1].version, '3.8.1')

  eq(result[2].group_id, 'org.apache.maven.plugins')
  eq(result[2].artifact_id, 'maven-surefire-plugin')
  eq(result[2].version, '2.22.2')

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

return T
