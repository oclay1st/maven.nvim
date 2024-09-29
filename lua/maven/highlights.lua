local M = {}

M.NORMAL_TEXT = 'MavenNormalText'
M.SPECIAL_TEXT = 'MavenSpecialText'
M.DIM_TEXT = 'MavenDimText'
M.SPECIAL_TITLE = 'MavenSpecialTitle'
M.ERROR_TEXT = 'MavenErrorText'

local highlights = {
  {
    name = M.NORMAL_TEXT,
    config = { default = true, link = 'NonText' },
  },
  {
    name = M.SPECIAL_TEXT,
    config = { default = true, link = 'Special' },
  },
  {
    name = M.DIM_TEXT,
    config = { default = true, link = 'Comment' },
  },
  {
    name = M.SPECIAL_TITLE,
    config = { default = true, link = 'Title' },
  },
  {
    name = M.ERROR_TEXT,
    config = { default = true, italic = true, fg = '#c53b53' },
  },
}

function M.setup()
  for _, v in ipairs(highlights) do
    vim.api.nvim_set_hl(0, v.name, v.config)
  end
end

return M
