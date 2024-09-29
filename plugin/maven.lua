vim.api.nvim_create_user_command('Maven', function()
  require('maven').toggle()
end, { desc = 'Toggles Maven UI', bar = true, nargs = 0 })
