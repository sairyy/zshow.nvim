if vim.g.loaded_zshow ~= nil then
    return
end

---@param name string Highlight group name
---@param val vim.api.keyset.highlight Highlight definition map
local set_hl = function (name, val)
    val.default = true -- do not override existing definitions
    vim.api.nvim_set_hl(0, name, val)
end

---[plugin highlights]---
set_hl('ZShowListItem', {
    bg = vim.api.nvim_get_hl(0, { name = 'Character' }).bg,
    fg = vim.api.nvim_get_hl(0, { name = 'Character' }).fg,
    bold = true,
})
set_hl('ZShowSectionName', {
    bg = vim.api.nvim_get_hl(0, { name = 'NormalFloat' }).bg,
    fg = vim.api.nvim_get_hl(0, { name = 'NormalFloat' }).fg,
    bold = true,
})
set_hl('ZShowPlugin', { link = 'NormalFloat' })
set_hl('ZShowPluginCount', { link = 'Comment' })
---


---[plugin commands]---
vim.api.nvim_create_user_command('ZShow', function()
    require('zshow').open()
end, { desc = 'Open zpack.nvim plugin overview' })
---


---
vim.g.loaded_zshow = true
