local MiniTest = require('mini.test')
local PomParser = require('maven.parsers.pom_xml_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local full_pom = [[
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0.0</version>
  <name>My App</name>
</project>
]]

T['parse full pom'] = function()
  local result = PomParser.parse(full_pom)
  eq(result.group_id, 'com.example')
  eq(result.artifact_id, 'my-app')
  eq(result.version, '1.0.0')
  eq(result.name, 'My App')
  eq(#result.module_paths, 0)
end

local minimal_pom = [[
<project>
  <artifactId>minimal-app</artifactId>
</project>
]]

T['parse minimal pom with only artifactId'] = function()
  local result = PomParser.parse(minimal_pom)
  eq(result.group_id, nil)
  eq(result.artifact_id, 'minimal-app')
  eq(result.version, nil)
  eq(result.name, nil)
  eq(#result.module_paths, 0)
end

local pom_with_modules = [[
<project>
  <groupId>com.example</groupId>
  <artifactId>parent</artifactId>
  <version>1.0.0</version>
  <modules>
    <module>module-a</module>
    <module>module-b</module>
    <module>module-c</module>
  </modules>
</project>
]]

T['parse pom with modules'] = function()
  local result = PomParser.parse(pom_with_modules)
  eq(result.group_id, 'com.example')
  eq(result.artifact_id, 'parent')
  eq(result.version, '1.0.0')
  eq(#result.module_paths, 3)
  eq(result.module_paths[1], 'module-a')
  eq(result.module_paths[2], 'module-b')
  eq(result.module_paths[3], 'module-c')
end

local pom_single_module = [[
<project>
  <groupId>com.example</groupId>
  <artifactId>single-module</artifactId>
  <version>1.0.0</version>
  <modules>
    <module>only-module</module>
  </modules>
</project>
]]

T['parse pom with single module'] = function()
  local result = PomParser.parse(pom_single_module)
  eq(#result.module_paths, 1)
  eq(result.module_paths[1], 'only-module')
end

T['parse errors on missing project tag'] = function()
  MiniTest.expect.error(function()
    PomParser.parse('<invalid><root/></invalid>')
  end)
end

T['parse errors on missing artifactId'] = function()
  MiniTest.expect.error(function()
    PomParser.parse('<project><groupId>g</groupId></project>')
  end)
end

return T
