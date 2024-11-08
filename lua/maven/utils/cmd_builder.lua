local MavenConfig = require('maven.config')

---@class Command
---@field cmd string
---@field args string[]

---@class CommandBuilder
local CommandBuilder = {}

---Normalize param
---@param value string
---@return string
local function normalize(value)
  return '"' .. value .. '"'
end

---Build the mvn cmd
---@param pom_xml_path string
---@param extra_args string[]
---@return Command
CommandBuilder.build_mvn_cmd = function(pom_xml_path, extra_args)
  local _args = {
    '-B',
    '-N',
    '--file=' .. normalize(pom_xml_path),
  }
  for _, value in ipairs(extra_args) do
    table.insert(_args, value)
  end
  return {
    cmd = MavenConfig.options.mvn_executable,
    args = _args,
  }
end

---Build the dependency tree cmd
---@param pom_xml_path string
---@param output_dir string
---@param output_filename string
---@return Command
CommandBuilder.build_mvn_dependencies_cmd = function(pom_xml_path, output_dir, output_filename)
  return {
    cmd = MavenConfig.options.mvn_executable,
    args = {
      '-B',
      '-N',
      '--file=' .. normalize(pom_xml_path),
      'com.github.ferstl:depgraph-maven-plugin:4.0.2:graph',
      '-DgraphFormat=text',
      '-DshowVersions=true',
      '-DshowGroupIds=true',
      '-DshowDuplicates=true',
      '-DshowConflicts=true',
      '-DoutputDirectory=' .. output_dir,
      '-DoutputFileName=' .. output_filename,
    },
  }
end

---Build the effective pom cmd
---@param pom_xml_path string
---@param output_file string
---@return Command
CommandBuilder.build_mvn_effective_pom_cmd = function(pom_xml_path, output_file)
  return {
    cmd = MavenConfig.options.mvn_executable,
    args = {
      '-B',
      '-N',
      '--file=' .. normalize(pom_xml_path),
      'help:effective-pom',
      '-Doutput=' .. output_file,
    },
  }
end

---Build the cmd to read a file inside a zip
---@param zip_file_path string
---@param file_to_read_path string
---@return Command
CommandBuilder.build_read_zip_file_cmd = function(zip_file_path, file_to_read_path)
  return {
    cmd = 'unzip',
    args = {
      '-p',
      zip_file_path,
      file_to_read_path,
    },
  }
end

---Build the  help cmd
---@return Command
CommandBuilder.build_mvn_help_cmd = function()
  return {
    cmd = MavenConfig.options.mvn_executable,
    args = { '--help' },
  }
end

---Build the create project cmd
---@param project_name string
---@param project_package string
---@param archetype_group_id string
---@param archetype_artifact_id string
---@param archetype_version string
---@param directory string
---@return Command
CommandBuilder.create_project = function(
  project_name,
  project_package,
  archetype_group_id,
  archetype_artifact_id,
  archetype_version,
  directory
)
  return {
    cmd = MavenConfig.options.mvn_executable,
    args = {
      'archetype:generate',
      '-DartifactId=' .. project_name,
      '-DgroupId=' .. project_package,
      '-DarchetypeGroupId=' .. archetype_group_id,
      '-DarchetypeArtifactId=' .. archetype_artifact_id,
      '-DarchetypeVersion=' .. archetype_version,
      '-DoutputDirectory=' .. directory,
      '-DarchetypeCatalog=local',
      '-DinteractiveMode=false',
    },
  }
end

return CommandBuilder
