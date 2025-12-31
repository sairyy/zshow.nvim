local M = {}

---@class zshow.config.backdrop : zshow.add_backdrop.opts
---@field enable? boolean enable backdrop

---@alias zshow.config.win_opts vim.api.keyset.win_config

---@class zshow.config.formatting
---@field listchars string[] characters to use in listings based on nesting level
---@field show_version boolean display git commit SHA
---@field short_sha boolean use short SHA when displaying commit info

---@class zshow.__config
---@field winblend   integer    window pseudo-transparency
---@field width      number     window width as a % of neovim's width (e.g.: 0.6)
---@field height     number     window height as a % of neovim's height (e.g.: 0.6)
---
---@field backdrop   zshow.config.backdrop      dimming of windows in the background
---@field formatting zshow.config.formatting    ui formatting options
---@field win_config zshow.config.win_opts      options passed to |nvim_open_win|
M.default_config = {
    winblend = 0,
    width = 0.6,
    height = 0.6,

    backdrop = {
        enable = false,
        -- only take effect if `enable` set to true
        winblend = 50,
        respect_transparent_bg = true,
    },

    formatting = {
        listchars = { '-', '+' },
        show_version = true,
        short_sha = true,
    },

    win_config = {
        zindex = 50,
        title = ' Plugins ',
        title_pos = 'center',
    },
}

---@alias zshow.config Partial<zshow.__config>

---@param opts? zshow.config
---@return zshow.config
function M.resolve(opts)
    opts = vim.tbl_deep_extend(
        'force',
        M.default_config,
        vim.g.zshow_opts or {},
        opts or {}
    )

    vim.validate('winblend', opts.winblend, function(wb)
        return wb >= 0 and wb <= 100
    end, '0 < number < 100')

    vim.validate('width', opts.width, function(x)
        return x > 0 and x < 1
    end, '0 < number < 1')

    vim.validate('height', opts.height, function(h)
        return h > 0 and h < 1
    end, '0 < number < 1')

    return opts
end

return M
