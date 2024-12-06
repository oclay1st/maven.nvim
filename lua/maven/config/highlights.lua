local M = {}

M.NORMAL = 'MavenNormal'
M.SPECIAL = 'MavenSpecial'
M.COMMENT = 'MavenComment'
M.TITLE = 'MavenTitle'
M.INFO = 'MavenInfo'
M.WARN = 'MavenWarn'
M.ERROR = 'MavenError'
M.CURSOR_LINE = 'MavenCursorLine'
local highlights = {
  {
    name = M.NORMAL,
    config = { default = true, link = 'Normal' },
  },
  {
    name = M.CURSOR_LINE,
    config = { default = true, link = 'CursorLine' },
  },
  {
    name = M.SPECIAL,
    config = { default = true, link = 'Special' },
  },
  {
    name = M.COMMENT,
    config = { default = true, link = 'Comment' },
  },
  {
    name = M.TITLE,
    config = { default = true, link = 'Title' },
  },
  {
    name = M.ERROR,
    config = { default = true, italic = true, link = 'DiagnosticError' },
  },
  {
    name = M.WARN,
    config = { default = true, italic = true, link = 'DiagnosticWarn' },
  },
  {
    name = M.INFO,
    config = { default = true, italic = true, link = 'DiagnosticInfo' },
  },
}

M.DEFAULT_WIN_HIGHLIGHT = 'Normal:MavenNormal,NormalNC:MavenNormalNC,CursorLine:MavenCursorLine'

function M.setup()
  for _, v in ipairs(highlights) do
    vim.api.nvim_set_hl(0, v.name, v.config)
  end
end

return M
