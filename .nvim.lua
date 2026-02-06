vim.opt.runtimepath:append('.nvim')

vim.schedule(function()
    vim.lsp.enable('emmylua_ls')
end)
