local M = {}

M.namespace = vim.api.nvim_create_namespace('maven')

M.MAVEN_NORMAL_TEXT = 'MavenNormalText'
M.MAVEN_SPECIAL_TEXT = 'MavenSpecialText'
M.MAVEN_DIM_TEXT = 'MavenDimText'
M.MAVEN_SPECIAL_TITLE = 'MavenSpecialTitle'
M.MAVEN_ERROR_TEXT = 'MavenErrorText'

local highlights = {
  {
    name = M.MAVEN_NORMAL_TEXT,
    config = { default = true, link = 'NonText' },
  },
  {
    name = M.MAVEN_SPECIAL_TEXT,
    config = { default = true, link = 'Special' },
  },
  {
    name = M.MAVEN_DIM_TEXT,
    config = { default = true, link = 'Comment' },
  },
  {
    name = M.MAVEN_SPECIAL_TITLE,
    config = { default = true, link = 'Title' },
  },
  {
    name = M.MAVEN_ERROR_TEXT,
    config = { default = true, italic = true, fg = '#c53b53' },
  },
}

function M.setup()
  for _, v in ipairs(highlights) do
    vim.api.nvim_set_hl(0, v.name, v.config)
  end
end

return M
