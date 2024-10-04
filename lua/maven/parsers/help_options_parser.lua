local HelpOptionsParser = {}

---Parse help options
---@param help_content_lines any
---@return Option[]
HelpOptionsParser.parse = function(help_content_lines)
  local options = {}
  for index, line in ipairs(help_content_lines) do
    if index > 3 then
      if string.find(line, '^%s%-') then
        local opts, description = string.match(line, '(.+)%s%s(.+)')
        table.insert(options, { name = vim.trim(opts), description = description })
      elseif string.find(line, '^%s%s') then
        local more_description = string.match(line, '%s%s(%w.+)') or ''
        options[#options].description = options[#options].description .. ' ' .. more_description
      end
    end
  end
  local simple_options = {}
  for _, option in ipairs(options) do
    for opt in string.gmatch(option.name, '[^%,]+') do
      table.insert(simple_options, { name = vim.trim(opt), description = option.description })
    end
  end
  return simple_options
end

return HelpOptionsParser
