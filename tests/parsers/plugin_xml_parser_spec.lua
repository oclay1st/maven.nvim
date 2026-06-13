local MiniTest = require('mini.test')
local PluginParser = require('maven.parsers.plugin_xml_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local single_mojo_plugin = [[
<?xml version="1.0" encoding="UTF-8"?>
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <version>3.8.1</version>
  <goalPrefix>compiler</goalPrefix>
  <mojos>
    <mojo>
      <goal>compile</goal>
    </mojo>
  </mojos>
</plugin>
]]

T['parse single mojo'] = function()
  local result = PluginParser.parse(single_mojo_plugin)
  eq(result.group_id, 'org.apache.maven.plugins')
  eq(result.artifact_id, 'maven-compiler-plugin')
  eq(result.version, '3.8.1')
  eq(#result.goals, 1)
  eq(result.goals[1].name, 'compile')
  eq(result.goals[1].prefix, 'compiler')
  eq(result.goals[1].full_name, 'compiler:compile')
end

local multiple_mojos_plugin = [[
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-surefire-plugin</artifactId>
  <version>2.22.2</version>
  <goalPrefix>surefire</goalPrefix>
  <mojos>
    <mojo>
      <goal>test</goal>
    </mojo>
    <mojo>
      <goal>help</goal>
    </mojo>
  </mojos>
</plugin>
]]

T['parse multiple mojos'] = function()
  local result = PluginParser.parse(multiple_mojos_plugin)
  eq(#result.goals, 2)
  eq(result.goals[1].name, 'test')
  eq(result.goals[1].prefix, 'surefire')
  eq(result.goals[2].name, 'help')
  eq(result.goals[2].prefix, 'surefire')
end

T['parse errors on missing plugin tag'] = function()
  MiniTest.expect.error(function()
    PluginParser.parse('<invalid><root/></invalid>')
  end)
end

T['parse errors on missing mandatory fields'] = function()
  MiniTest.expect.error(function()
    PluginParser.parse('<plugin><groupId>g</groupId></plugin>')
  end)
end

return T
