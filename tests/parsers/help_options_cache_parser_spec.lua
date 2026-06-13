local MiniTest = require('mini.test')
local HelpOptionsCacheParser = require('maven.parsers.help_options_cache_parser')
local Utils = require('maven.utils')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse returns empty list when no cache file exists'] = function()
  local result = HelpOptionsCacheParser.parse()
  eq(#result, 0)
end

T['dump and parse roundtrip'] = function()
  local orig_path = Utils.maven_cache_path
  local tmpdir = vim.fn.tempname()
  Utils.maven_cache_path = tmpdir
  FileUtils.mkdir(tmpdir)

  local options = {
    { name = '-A', description = 'Also make' },
    { name = '-B', description = 'Batch mode' },
  }

  HelpOptionsCacheParser.dump(options)

  local result = HelpOptionsCacheParser.parse()
  eq(#result, 2)
  eq(result[1].name, '-A')
  eq(result[1].description, 'Also make')
  eq(result[2].name, '-B')
  eq(result[2].description, 'Batch mode')

  Utils.maven_cache_path = orig_path
  vim.fn.delete(tmpdir, 'rf')
end

return T
