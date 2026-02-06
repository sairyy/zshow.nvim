local rtp = vim.split(package.path, ';')
rtp[#rtp+1] = 'lua/?.lua'
rtp[#rtp+1] = 'lua/?/init.lua'

local library = { vim.env.VIMRUNTIME }

---@type string?
local zpack = vim
    .iter(vim.api.nvim_get_runtime_file('', true))
    :find(function(p) return p:match('zpack%.nvim') end)

if zpack then
    library[#library+1] = zpack
end

local conf =  {
    cmd = { 'emmylua_ls' },
    filetypes = { 'lua' },
    root_markers = {
        '.luarc.json',
        '.emmyrc.json',
        '.luacheckrc',
        '.git',
    },
    workspace_required = false,

    on_init = function() end,

    settings = {
        Lua = {
            workspace = {
                library = library,
            },
            runtime = {
                requirePattern = rtp,
                version = "LuaJIT"
            },
        },
    },
}

return conf
