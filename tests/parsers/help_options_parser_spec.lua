local MiniTest = require('mini.test')
local HelpOptionsParser = require('maven.parsers.help_options_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parses single options with descriptions'] = function()
  local lines = {
    'usage: mvn [options] [<goal(s)>] [<phase(s)>]',
    '',
    'Options:',
    ' -A,--also-make                                    Also make',
    ' -B,--batch-mode                                   Batch mode',
  }

  local result = HelpOptionsParser.parse(lines)
  eq(#result, 4)
  eq(result[1].name, '-A')
  eq(result[1].description, 'Also make')
  eq(result[2].name, '--also-make')
  eq(result[2].description, 'Also make')
  eq(result[3].name, '-B')
  eq(result[3].description, 'Batch mode')
  eq(result[4].name, '--batch-mode')
  eq(result[4].description, 'Batch mode')
end

T['skips header lines before index 4'] = function()
  local lines = {
    'header 1',
    'header 2',
    'header 3',
    ' -opt                                           Description',
  }

  local result = HelpOptionsParser.parse(lines)
  eq(#result, 1)
end

T['appends multi-line descriptions'] = function()
  local lines = {
    'usage: mvn [options]',
    '',
    'Options:',
    ' -opt                                             First line of',
    '                                                   description',
  }

  local result = HelpOptionsParser.parse(lines)
  eq(#result, 1)
  eq(result[1].name, '-opt')
  eq(result[1].description, 'First line of description')
end

T['handles options without comma separation'] = function()
  local lines = {
    'usage: mvn [options]',
    '',
    'Options:',
    ' -D,--define <arg>                                Define a system property',
  }

  local result = HelpOptionsParser.parse(lines)
  eq(#result, 2)
  eq(result[1].name, '-D')
  eq(result[1].description, 'Define a system property')
  eq(result[2].name, '--define <arg>')
  eq(result[2].description, 'Define a system property')
end

T['returns empty list for only header lines'] = function()
  local lines = {
    'usage: mvn',
    '',
    'Options:',
  }

  local result = HelpOptionsParser.parse(lines)
  eq(#result, 0)
end

return T
