local Utils = require('maven.utils')

---@class Project
---@field id string
---@field private _compact_name  string
---@field pom_xml_path string
---@field root_path string
---@field name string
---@field group_id string
---@field artifact_id string
---@field version string
---@field lifecycles Project.Lifecycle[]
---@field dependencies Project.Dependency[]
---@field plugins Project.Plugin[]
---@field commands Project.Command[]
---@field modules table[string|Project[]]
local Project = {}
Project.__index = Project

---Create a new instance of a Project
---@param root_path string
---@param pom_xml_path string
---@param group_id string
---@param artifact_id string
---@param version string
---@param name? string
---@param dependencies? Project.Dependency[]
---@param plugins? Project.Plugin[]
---@param commands? Project.Command[]
---@param modules? Project[]
---@return Project
function Project.new(
  root_path,
  pom_xml_path,
  group_id,
  artifact_id,
  version,
  name,
  dependencies,
  plugins,
  commands,
  modules
)
  return setmetatable({
    id = Utils.uuid(),
    lifecycles = Project.default_lifecycles(),
    root_path = root_path,
    pom_xml_path = pom_xml_path,
    group_id = group_id or '',
    artifact_id = artifact_id,
    version = version or '',
    name = name or artifact_id,
    dependencies = dependencies or {},
    plugins = plugins or {},
    commands = commands or {},
    modules = modules or {},
  }, Project)
end

---Get default lifecycles
---@return Project.Lifecycle[]
function Project.default_lifecycles()
  return {
    Project.Lifecycle('clean', 'remove files of the previous build', 'clean'),
    Project.Lifecycle('validate', 'validate the project is correct', 'validate'),
    Project.Lifecycle('compile', 'compile the source code of the project', 'compile'),
    Project.Lifecycle('test', 'run the project tests', 'test'),
    Project.Lifecycle('package', 'package the compiled code', 'package'),
    Project.Lifecycle('verify', 'verify the package is valid', 'verify'),
    Project.Lifecycle('install', 'install the package into the local repository', 'install'),
    Project.Lifecycle('site', "generate the project's site documentation", 'site'),
    Project.Lifecycle('deploy', 'deploy to the remote repository', 'deploy'),
  }
end

---Set dependencies
---@param dependencies Project.Dependency[]
function Project:set_dependencies(dependencies)
  self.dependencies = dependencies
end

---Set plugins
---@param plugins Project.Plugin[]
function Project:set_plugins(plugins)
  self.plugins = plugins
end

---@param module Project
function Project:add_module(module)
  table.insert(self.modules, module)
end

---Replace plugin
---@param plugin Project.Plugin
function Project:replace_plugin(plugin)
  for index, item in ipairs(self.plugins) do
    if
      item.group_id == plugin.group_id
      and item.artifact_id == plugin.artifact_id
      and item.version == plugin.version
    then
      self.plugins[index] = plugin
    end
  end
end

---Set commands
---@param commands Project.Command[]
function Project:set_commands(commands)
  self.commands = commands
end

---@return string
function Project:get_compact_name()
  return self.group_id .. ':' .. self.artifact_id .. ':' .. self.version
end

---@class Project.Command
---@field name string
---@field description string
---@field cmd_args string[]
local Command = {}

Command.__index = Command

---@param name string
---@param description string
---@param cmd_args string[]
---@return table
function Project.Command(name, description, cmd_args)
  local self = {}
  setmetatable(self, Command)
  self.name = name
  self.description = description
  self.cmd_args = cmd_args
  return self
end

---@class Project.Lifecycle
---@field name string
---@field description string
---@field cmd_arg string
local Lifecycle = {}

Lifecycle.__index = Lifecycle

---@param name string
---@param description string
---@param cmd_arg string
---@return table
function Project.Lifecycle(name, description, cmd_arg)
  local self = {}
  setmetatable(self, Lifecycle)
  self.name = name
  self.description = description
  self.cmd_arg = cmd_arg
  return self
end

---@class Project.Dependency
---@field id string
---@field parent_id string | nil
---@field group_id string
---@field artifact_id string
---@field version string
---@field size number | nil
---@field scope string
---@field is_duplicate boolean
---@field conflict_version string
local Dependency = {}
Dependency.__index = Dependency

---@alias Dependency Project.Dependency

---@return string
function Dependency:get_compact_name()
  return self.group_id .. ':' .. self.artifact_id .. ':' .. self.version
end

---@param id string
---@param parent_id string | nil
---@param group_id string
---@param artifact_id string
---@param version string
---@param scope? string
---@param is_duplicate? boolean
---@param conflict_version? string
---@param size? number
---@return Project.Dependency
function Project.Dependency(
  id,
  parent_id,
  group_id,
  artifact_id,
  version,
  scope,
  is_duplicate,
  conflict_version,
  size
)
  local self = {}
  setmetatable(self, Dependency)
  self.id = id
  self.parent_id = parent_id
  self.group_id = group_id or ''
  self.artifact_id = artifact_id
  self.version = version or ''
  self.scope = scope
  self.is_duplicate = is_duplicate or false
  self.conflict_version = conflict_version
  self.size = size
  return self
end

---@class Project.Plugin
---@field group_id string
---@field artifact_id string
---@field version string
---@field goal_prefix string
---@field goals? Project.Goal[]
local Plugin = {}

Plugin.__index = Plugin

---@alias Plugin Project.Plugin

local plugin_patterns = {
  '%-maven%-plugin',
  '%-maven',
  'maven%-',
  '%-plugin%-maven',
  '%-plugin',
  'plugin%-',
}

---@return string
function Plugin:get_compact_name()
  return self.group_id .. ':' .. self.artifact_id .. ':' .. self.version
end
---Get mini name
--- TODO: review logic
---@return string
function Plugin:get_short_name()
  local name = self.artifact_id
  for _, pattern in ipairs(plugin_patterns) do
    name, _ = string.gsub(name, pattern, '')
  end
  return name
end

---Add a goal to the list of goals
---@param goal Project.Goal
function Plugin:add_goal(goal)
  table.insert(self.goals, goal)
end

---Set goal prefix
---@param goal_prefix string
function Plugin:set_goal_prefix(goal_prefix)
  self.goal_prefix = assert(goal_prefix, 'Goal prefix required')
end

---@param group_id string
---@param artifact_id string
---@param version string
---@param goal_prefix? string
---@param goals? Project.Goal[]
---@return Project.Plugin
function Project.Plugin(group_id, artifact_id, version, goal_prefix, goals)
  local self = {}
  setmetatable(self, Plugin)
  self.group_id = group_id or ''
  self.artifact_id = artifact_id
  self.version = version or ''
  self.goal_prefix = goal_prefix or ''
  self.goals = goals or {}
  return self
end

---@class Project.Goal
---@field name string
local Goal = {}

Goal.__index = Goal

---@alias Goal Project.Goal

---@param name string
---@return  Project.Goal
function Project.Goal(name) --- it could grow
  local self = {}
  setmetatable(self, Goal)
  self.name = name
  return self
end

return Project
