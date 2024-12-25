vim.api.nvim_create_user_command('Maven', function()
  require('maven').toggle_projects_view()
end, { desc = 'Toggles Maven UI', bar = true, nargs = 0 })

vim.api.nvim_create_user_command('MavenExec', function()
  require('maven').show_execution_view()
end, { desc = 'Show Maven Execute UI', bar = true, nargs = 0 })

vim.api.nvim_create_user_command('MavenInit', function()
  require('maven').show_initializer_view()
end, { desc = 'Show Maven Initializer UI', bar = true, nargs = 0 })
