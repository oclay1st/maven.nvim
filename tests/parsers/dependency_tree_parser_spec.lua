local MiniTest = require('mini.test')
local DependencyTreeParser = require('maven.parsers.dependency_tree_parser')
local FileUtils = require('maven.utils.fs')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['parse_file parses simple dependency tree'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
+- com.example:dep-a:1.0.0:compile
\- com.example:dep-b:2.0.0:test
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 2)

  eq(result[1].group_id, 'com.example')
  eq(result[1].artifact_id, 'dep-a')
  eq(result[1].version, '1.0.0')
  eq(result[1].scope, 'compile')
  eq(result[1].is_duplicate, false)
  eq(result[1].conflict_version, nil)

  eq(result[2].group_id, 'com.example')
  eq(result[2].artifact_id, 'dep-b')
  eq(result[2].version, '2.0.0')
  eq(result[2].scope, 'test')
  eq(result[2].is_duplicate, false)
  eq(result[2].conflict_version, nil)

  FileUtils.delete(tmpfile)
end

T['parse_file handles nested dependencies'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
+- com.example:parent:1.0.0:compile
|  \- com.example:child:1.0.0:runtime
\- com.example:sibling:1.0.0:provided
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 3)

  eq(result[1].group_id, 'com.example')
  eq(result[1].artifact_id, 'parent')
  eq(result[1].parent_id, nil)

  eq(result[2].group_id, 'com.example')
  eq(result[2].artifact_id, 'child')
  eq(result[2].parent_id, result[1].id)

  eq(result[3].group_id, 'com.example')
  eq(result[3].artifact_id, 'sibling')
  eq(result[3].parent_id, nil)

  FileUtils.delete(tmpfile)
end

T['parse_file marks duplicate dependencies'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
+- com.example:dep:1.0.0:compile
\- com.example:dep:1.0.0:compile (duplicate)
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 2)

  eq(result[1].is_duplicate, false)
  eq(result[2].is_duplicate, true)

  FileUtils.delete(tmpfile)
end

T['parse_file resolves conflict versions'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
\- com.example:dep:2.0.0:compile (conflict: 1.0.0)
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 1)

  eq(result[1].group_id, 'com.example')
  eq(result[1].artifact_id, 'dep')
  eq(result[1].version, '1.0.0')
  eq(result[1].conflict_version, '2.0.0')

  FileUtils.delete(tmpfile)
end

T['parse_file handles deep nesting'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
+- com.example:a:1.0.0:compile
|  +- com.example:b:1.0.0:compile
|     \- com.example:c:1.0.0:runtime
\- com.example:d:1.0.0:test
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 4)

  eq(result[1].artifact_id, 'a')
  eq(result[1].parent_id, nil)

  eq(result[2].artifact_id, 'b')
  eq(result[2].parent_id, result[1].id)

  eq(result[3].artifact_id, 'c')
  eq(result[3].parent_id, result[2].id)

  eq(result[4].artifact_id, 'd')
  eq(result[4].parent_id, nil)

  FileUtils.delete(tmpfile)
end

T['parse_file handles scope with classifier'] = function()
  local tree_text = [[com.example:example:jar:1.0.0
\- com.example:dep:1.0.0:jar/jdk17
]]
  local tmpfile = vim.fn.tempname()
  FileUtils.write(tmpfile, tree_text)

  local result = DependencyTreeParser.parse_file(tmpfile)
  eq(#result, 1)
  eq(result[1].group_id, 'com.example')
  eq(result[1].artifact_id, 'dep')
  eq(result[1].version, '1.0.0')
  eq(result[1].scope, nil)

  FileUtils.delete(tmpfile)
end

return T
