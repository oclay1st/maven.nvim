local Utils = require('maven.utils')
local MavenConfig = require('maven.config')
local uv = vim.loop
local Queue = require('maven.utils.queue')

local M = {}

local _buf
local _win
local _buf_name = 'maven://MavenConsole'
local _jobs = {} ---@type Job[]
local _queue = Queue.new()

local line_patterns = {
  { pattern = '^%[INFO%]', hl = 'DiagnosticInfo', col_start = 1, col_end = 5 },
  { pattern = '^%[WARNING%]', hl = 'DiagnosticWarn', col_start = 1, col_end = 8 },
  { pattern = '^%[ERROR%]', hl = 'DiagnosticError', col_start = 1, col_end = 6 },
  { pattern = '^%[INFO%] BUILD FAILURE', hl = 'DiagnosticError', col_start = 7, col_end = 20 },
  { pattern = '^%[INFO%] BUILD SUCCESS', hl = 'DiagnosticOk', col_start = 7, col_end = 20 },
  { pattern = '^>> Executing', hl = 'DiagnosticOk', col_start = 0, col_end = 14 },
}

local function highlight_buf_line(buf, line, line_number)
  for _, item in ipairs(line_patterns) do
    if string.find(line, item.pattern) then
      vim.api.nvim_buf_add_highlight(buf, 0, item.hl, line_number, item.col_start, item.col_end)
    end
  end
end

local function set_buf_modifiable(value)
  vim.api.nvim_set_option_value('modifiable', value, { buf = _buf })
  vim.api.nvim_set_option_value('readonly', not value, { buf = _buf })
end

---Append a new line to the console
---@param line string
local append_line = function(line)
  if line == nil then
    return --nothing to do
  end
  local last_line = vim.api.nvim_buf_line_count(_buf)
  vim.fn.appendbufline(_buf, last_line - 1, line)
  highlight_buf_line(_buf, line, last_line - 1)
  pcall(vim.api.nvim_win_set_cursor, _win, { last_line, 0 })
end

local function setup_buffer()
  if not _win or _win == 0 or not vim.api.nvim_win_is_valid(_win) then
    _win = vim.fn.win_getid(vim.fn.winnr('#'))
  end
  vim.api.nvim_set_current_win(_win)
  if _buf and vim.api.nvim_buf_is_valid(_buf) then
    if not vim.api.nvim_buf_is_loaded(_buf) then
      vim.api.nvim_buf_delete(_buf, { force = true, unload = false })
    else
      vim.api.nvim_set_current_buf(_buf)
      return --nothing to do
    end
  end
  _buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(_buf, _buf_name)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = _buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = _buf })
  vim.api.nvim_set_option_value('filetype', 'maven_console', { buf = _buf })
  vim.api.nvim_set_option_value('undolevels', -1, { buf = _buf })
  vim.api.nvim_set_current_buf(_buf)
  vim.api.nvim_create_autocmd({ 'BufUnload' }, {
    pattern = _buf_name,
    callback = function()
      _queue:cancel_all()
    end,
  })
end

---Execute maven command
---@param command string
---@param args string[]
---@param show_output boolean
---@param callback? fun(state: string, ...)
---@param cwd? string
function M.execute_command(command, args, show_output, callback, cwd)
  if show_output then
    setup_buffer()
  end

  local _std_handler = function(_, data)
    if show_output and data ~= nil then
      vim.schedule(function()
        local lines = vim.split(data, '\n')
        for _, line in ipairs(lines) do
          if line ~= '' then
            append_line(line)
          end
        end
      end)
    end
  end

  if _queue.active > 0 then
    if callback then
      callback(Utils.PENDING_STATE)
    end
  end

  _queue
    :enqueue(vim.list_extend({ command }, args), {
      cwd = cwd,
      text = true,
      on_start = function()
        if show_output then
          vim.schedule(function()
            set_buf_modifiable(true)
            if MavenConfig.options.console.clean_before_execution then
              vim.api.nvim_buf_set_lines(_buf, 0, -1, false, {})
            end
            local message = '>> Executing: ' .. command .. ' ' .. table.concat(args, ' ')
            append_line(message)
            append_line('')
          end)
        end
        if callback then
          callback(Utils.STARTED_STATE)
        end
      end,
      stdout = _std_handler,
      stderr = _std_handler,
    })
    :next(function()
      if show_output then
        vim.schedule(function()
          if not MavenConfig.options.console.clean_before_execution then
            append_line('')
          end
          set_buf_modifiable(false)
        end)
      end
      if callback then
        callback(Utils.SUCCEED_STATE)
      end
    end)
    :catch(function()
      if callback then
        callback(Utils.FAILED_STATE)
      end
    end)
end

return M
