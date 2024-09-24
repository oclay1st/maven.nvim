local Job = require('plenary.job')
local MavenConfig = require('maven.config')

---@class Console
---@field buf number
---@field win number
---@field job table
local Console = {}

Console.__index = Console

---Create a new console
---@return Console
function Console.new()
  local self = {}
  setmetatable(self, Console)
  return self
end

---Append a new line to the console
---@param line string
---@param buf number
---@param win number
local append = function(line, buf, win)
  vim.schedule(function()
    local buf_info = vim.fn.getbufinfo(buf)
    if buf_info[1] ~= nil then
      local last_line = buf_info[1].linecount
      vim.fn.appendbufline(buf, last_line, line)
      pcall(vim.api.nvim_win_set_cursor, win, { last_line + 1, 0 })
    end
  end)
end

function Console:create_buffer()
  self.win = vim.fn.win_getid(vim.fn.winnr('#'))
  vim.api.nvim_set_current_win(self.win)
  vim.cmd('enew')
  self.buf = vim.api.nvim_get_current_buf()
  if not pcall(vim.api.nvim_buf_set_name, self.buf, 'maven://MavenConsole') then
    vim.api.nvim_buf_set_name(self.buf, 'maven://MavenConsole')
  end
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = self.buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = self.buf })
  vim.api.nvim_set_option_value('filetype', 'maven_console', { buf = self.buf })
  vim.api.nvim_set_option_value('undolevels', -1, { buf = self.buf })
  return self.buf
end

---Execute maven command
---@param command string
---@param args string[]
---@param show_output boolean
---@param on_success? function
---@param on_failure? function
function Console:execute_command(command, args, show_output, on_success, on_failure)
  if show_output == true then
    self.buf = self.buf or self:create_buffer()
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
  end
  local job = Job:new({
    command = command,
    args = args,
    on_stdout = function(_, data)
      if show_output and self.buf then
        append(data, self.buf, self.win)
      end
    end,
    on_stderr = function(_, data)
      if show_output and self.buf then
        append(data, self.buf, self.win)
      end
    end,
  })
  if on_success then
    job:after_success(on_success)
  end

  if on_failure then
    job:after_failure(on_failure)
  end

  job:start()
end

return Console
