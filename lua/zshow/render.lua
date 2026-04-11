local M = {}

local state = {
    bufnr = -1,
    winid = -1,

    ns = vim.api.nvim_create_namespace('zshow.ns')
}

---@param sha_str string
---@return string
local function short_sha(sha_str)
    return sha_str:sub(1, 7)
end

---@param buf zshow.ContentBuffer
---@param opts zshow.config.formatting
local function render_header(buf, plugins, opts)
    local total = #plugins.loaded + #plugins.unloaded + #plugins.disabled

    buf:empty_line()
       :append(opts.listchars[1], 'ZShowListItem')
       :append(' ')
       :append('Total', 'ZShowSectionName')
       :append(': ')
       :append(
           ('%d plugin%s'):format(total, total ~= 1 and 's' or ''),
           'ZShowPluginCount'
       )
       :endl()
end

---@param category string
---@param plugins zshow.info[]
---@param buf zshow.ContentBuffer
---@param opts zshow.config.formatting
local function render_category(category, plugins, buf, opts)
    buf:empty_line()
       :append(opts.listchars[1], 'ZShowListItem')
       :append(' ')
       :append(category, 'ZShowSectionName')
       :append(': ')
       :append(
            ('(%d plugin%s)'):format(#plugins, #plugins ~= 1 and 's' or ''),
            'ZShowPluginCount'
       )
       :endl()

    table.sort(plugins, function(a, b) return a.name < b.name end)

    for _, plugin in ipairs(plugins) do
        buf:append('  ')
           :append(opts.listchars[2], 'ZShowListItem')
           :append(' ')
           :append(plugin.name, 'ZShowPlugin')

        if opts.show_version and plugin.version then
            local version = plugin.version

            if opts.short_sha then
                version = short_sha(version)
            end

            buf:append(' ')
               :append(('(%s)'):format(version), 'ZShowGitSha')
        end

        buf:endl()
    end
end

---@param bufnr integer
---@param content zshow.ContentBuffer
local function render_extmarks(bufnr, content)
    -- line, col 1-indexed
    for line, col_start, col_end, tok in content:token_iter() do
        if tok:get_hl() ~= nil then
            vim.api.nvim_buf_set_extmark(bufnr, state.ns, line-1, col_start-1, {
                hl_group = tok:get_hl(),
                end_col = col_end-1,
            })
        end
    end
end

---@param opts zshow.config.formatting
local function render_plugininfo(bufnr, plugins, opts)
    local ContentBuffer = require('zshow.content-buffer')
    local content = ContentBuffer.new()

    render_header(content, plugins, opts)
    render_category('Loaded', plugins.loaded, content, opts)
    render_category('Not Loaded', plugins.unloaded, content, opts)
    render_category('Disabled', plugins.disabled, content, opts)

    local lines = content:get_full_text()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- text highlights
    vim.api.nvim_buf_clear_namespace(bufnr, state.ns, 0, -1)
    render_extmarks(bufnr, content)
end

local function add_keymaps(bufnr)
    ---@param lhs string
    ---@param rhs string|fun()
    ---@param opts? vim.keymap.set.Opts
    local function map(lhs, rhs, opts)
        opts = opts or {}
        opts.buffer = bufnr

        vim.keymap.set('n', lhs, rhs, opts)
    end

    map('q', '<cmd>close<cr>', { desc = 'Close window' })
    map('<esc>', '<cmd>close<cr>', { desc = 'Close window' })

    map('u', function()
        vim.pack.update(nil, { force = true })
    end, { desc = 'Update all plugins' })

    map('U', function()
        local plug_name = vim.fn.expand('<cWORD>')

        -- fail silently if not a plugin
        if not require('zshow.data').get_plugin(plug_name) then return end

        vim.pack.update({ plug_name }, { force = true })
    end, { desc = 'Update plugin at cursor' })

    map('K', function()
        local plug_name = vim.fn.expand('<cWORD>')

        local plugin = require('zshow.data').get_plugin(plug_name)
        if not plugin then return end

        -- check if it's a local directory
        vim.uv.fs_stat(plugin.url, function(err, sb)
            if err or not sb then
                vim.ui.open(('%s/commit/%s'):format(plugin.url, plugin.version))
            else
                vim.schedule(function()
                    vim.cmd.tabedit { plugin.url }
                end)
            end
        end)
    end, { desc = 'Open plugin URI' })
end

---@param opts zshow.config.formatting
local function populate_window(bufnr, _winid, opts)
    local info = require('zshow.data').get_plugininfo()

    vim.api.nvim_set_option_value('modifiable', true, { buf = state.bufnr })
    render_plugininfo(bufnr, info, opts)
    vim.api.nvim_set_option_value('modifiable', false, { buf = state.bufnr })

    add_keymaps(bufnr)
end

---@param bufnr integer
---@param opts zshow.add_backdrop.opts
local function add_backdrop(bufnr, opts)
    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('zshow::open', { clear = true }),
        once = true,
        pattern = 'zshow',
        callback = function(args)
            if args.buf == bufnr then
                require('zshow.util').add_backdrop(args.buf, opts)
            end
        end
    })
end

---@param opts zshow.__config
function M.display_window(opts)
    if not opts.win_config.border then
        ---@diagnostic disable-next-line: assign-type-mismatch
        opts.win_config.border = vim.o.winborder == ''
            and 'single'
            or vim.o.winborder
    end

    local width = opts.win_config.width or math.floor(vim.o.columns * opts.width)
    local height = opts.win_config.height or math.floor(vim.o.lines * opts.height)

    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)


    ---@type vim.api.keyset.win_config
    local win_config = vim.tbl_deep_extend('keep', opts.win_config, {
        relative = 'editor',
        style = 'minimal',

        width = width,
        height = height,
        row = row,
        col = col,
    })

    state.bufnr = vim.api.nvim_create_buf(false, true)

    if not vim.api.nvim_win_is_valid(state.winid) then
        state.winid = vim.api.nvim_open_win(state.bufnr, true, win_config)
    end

    populate_window(state.bufnr, state.winid, opts.formatting)

    if opts.backdrop.enable then
        local backdrop_opts = opts.backdrop
        backdrop_opts.enable = nil ---@cast backdrop_opts zshow.add_backdrop.opts
        backdrop_opts.zindex = opts.win_config.zindex

        add_backdrop(state.bufnr, backdrop_opts)
    end

    vim.api.nvim_set_option_value('winblend', opts.winblend, { win = state.winid })

    vim.api.nvim_set_option_value('filetype', 'zshow', { buf = state.bufnr })

    vim.api.nvim_set_option_value('readonly', true, { buf = state.bufnr })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.bufnr })

    vim.api.nvim_create_autocmd('PackChanged', {
        buffer = state.bufnr,
        group = vim.api.nvim_create_augroup('zshow::rerender', { clear = true }),
        callback = function()
            populate_window(state.bufnr, state.winid, opts.formatting)
        end
    })

    return { bufnr = state.bufnr, winid = state.winid }
end

return M
