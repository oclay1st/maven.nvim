local CommandBuilder = {}

CommandBuilder.build_mvn_args = function(pom_xml_path, extra_args)
  local _args = {
    '-B',
    '-N',
    '-f',
    pom_xml_path,
  }
  for _, value in ipairs(extra_args) do
    table.insert(_args, value)
  end
  return _args
end

CommandBuilder.build_mvn_dependencies_args = function(pom_xml_path, output_dir, output_filename)
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

CommandBuilder.build_mvn_effective_pom_args = function(pom_xml_path, output_file)
  return {
    '-B',
    '-N',
    '-f',
    pom_xml_path,
    'help:effective-pom',
    '-Doutput=' .. output_file,
  }
end

return CommandBuilder
