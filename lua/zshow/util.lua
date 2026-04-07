local M = {}

local is_transparent_bg = function ()
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
    return normal.bg == nil
end

---@class zshow.add_backdrop.opts
---@field winblend? integer winblend to use; defaults to 50
---@field zindex? integer backdrop window zindex; defaults to 50
---@field respect_transparent_bg? boolean don't add backdrop if neovim has a transparent background; defaults to true

---@param bufnr integer
---@param opts? zshow.add_backdrop.opts
function M.add_backdrop(bufnr, opts)
    opts = vim.tbl_extend('keep', opts or {}, {
        winblend = 50,
        zindex = 50,
        respect_transparent_bg = true,
    }) --[[@as zshow.add_backdrop.opts]]
    ---@cast opts.zindex -nil

    local backdrop_bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(backdrop_bufnr, false, {
        relative = 'editor',
        row = 0,
        col = 0,
        width = vim.o.columns,
        height = vim.o.lines,
        focusable = false,
        style = 'minimal',
        border = 'none',
        zindex = opts.zindex - 1,
        hide = opts.respect_transparent_bg and is_transparent_bg(),
    })

    vim.wo[winid].winhighlight = 'Normal:' .. 'ZShowBackdrop'
    vim.wo[winid].winblend = opts.winblend
    vim.bo[backdrop_bufnr].buftype = 'nofile'

    -- close backdrop when the reference buffer is closed
    vim.api.nvim_create_autocmd({ 'WinClosed', 'BufLeave' }, {
        once = true,
        buffer = bufnr,
        callback = function ()
            if vim.api.nvim_win_is_valid(winid) then
                vim.api.nvim_win_close(winid, true)
            end
            if vim.api.nvim_buf_is_valid(backdrop_bufnr) then
                vim.api.nvim_buf_delete(backdrop_bufnr, { force = true })
            end
        end,
    })

    if opts.respect_transparent_bg then
        vim.api.nvim_create_autocmd('ColorScheme', {
            buffer = bufnr,
            callback = function ()
                if vim.api.nvim_win_is_valid(winid) then
                    vim.api.nvim_win_set_config(winid, { hide = is_transparent_bg() })
                end
            end,
        })
    end
end

return M
