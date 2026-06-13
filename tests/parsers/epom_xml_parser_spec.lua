local MiniTest = require('mini.test')
local EffectivePomParser = require('maven.parsers.epom_xml_parser')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

local single_plugin_epom = [[
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <groupId>com.example</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0.0</version>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
      </plugin>
    </plugins>
  </build>
</project>
]]

T['parse single plugin'] = function()
  local result = EffectivePomParser.parse(single_plugin_epom)
  eq(result.group_id, 'com.example')
  eq(result.artifact_id, 'my-app')
  eq(result.version, '1.0.0')
  eq(#result.plugins, 1)
  eq(result.plugins[1].group_id, 'org.apache.maven.plugins')
  eq(result.plugins[1].artifact_id, 'maven-compiler-plugin')
  eq(result.plugins[1].version, '3.8.1')
end

local multiple_plugins_epom = [[
<project>
  <groupId>com.example</groupId>
  <artifactId>multi-plugin</artifactId>
  <version>2.0.0</version>
  <build>
    <plugins>
      <plugin>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.8.1</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
    </plugins>
  </build>
</project>
]]

T['parse multiple plugins with default groupId'] = function()
  local result = EffectivePomParser.parse(multiple_plugins_epom)
  eq(result.group_id, 'com.example')
  eq(result.artifact_id, 'multi-plugin')
  eq(result.version, '2.0.0')
  eq(#result.plugins, 2)

  eq(result.plugins[1].group_id, 'org.apache.maven.plugins')
  eq(result.plugins[1].artifact_id, 'maven-compiler-plugin')
  eq(result.plugins[1].version, '3.8.1')

  eq(result.plugins[2].group_id, 'org.apache.maven.plugins')
  eq(result.plugins[2].artifact_id, 'maven-surefire-plugin')
  eq(result.plugins[2].version, '2.22.2')
end

T['parse errors on missing project'] = function()
  MiniTest.expect.error(function()
    EffectivePomParser.parse('<invalid><root/></invalid>')
  end)
end

T['parse errors on missing groupId'] = function()
  MiniTest.expect.error(function()
    EffectivePomParser.parse('<project><artifactId>a</artifactId><version>1</version><build><plugins><plugin><artifactId>p</artifactId><version>1</version></plugin></plugins></build></project>')
  end)
end

return T
