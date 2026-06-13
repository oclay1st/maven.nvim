local MiniTest = require('mini.test')
local Utils = require('maven.utils')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['should have states'] = function()
  eq(Utils.STARTED_STATE, 'STARTED')
  eq(Utils.FAILED_STATE, 'FAILED')
  eq(Utils.SUCCEED_STATE, 'SUCCEED')
  eq(Utils.PENDING_STATE, 'PENDING')
end

return T
