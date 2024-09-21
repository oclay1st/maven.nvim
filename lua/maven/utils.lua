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

M.build_cmd_args = function(pom_xml_path, extra_cmd_args)
  local lifecycle_cmd_args = {
    '-B',
    '-N',
    '-f',
    pom_xml_path,
  }
  for _, value in ipairs(extra_cmd_args) do
    table.insert(lifecycle_cmd_args, value)
  end
  return lifecycle_cmd_args
end

M.build_dependencies_cmd_args = function(pom_xml_path, output_dir, output_filename)
  return {
    '-B',
    '-N',
    '-f',
    pom_xml_path,
    'com.github.ferstl:depgraph-maven-plugin:4.0.2:graph',
    '-DgraphFormat=text',
    '-DshowVersions=true',
    '-DshowGroupIds=true',
    '-DshowDuplicates=true',
    '-DshowConflicts=true',
    '-DoutputDirectory=' .. output_dir,
    '-DoutputFileName=' .. output_filename,
  }
end

M.build_effective_pom_cmd_args = function(pom_xml_path, output_file)
  return {
    '-B',
    '-N',
    '-f',
    pom_xml_path,
    'help:effective-pom',
    '-Doutput=' .. output_file,
  }
end

return M
