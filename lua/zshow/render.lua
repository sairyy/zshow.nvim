local M = {}

local state = {
    bufnr = -1,
    winid = -1,

    ns = vim.api.nvim_create_namespace('zshow.ns')
}

---@param buf zshow.ContentBuffer
---@param opts zshow.config.formatting
local function render_header(buf, plugins, opts)
    local total = #plugins.loaded + #plugins.unloaded + #plugins.disabled

    buf:empty_line()
        ---@diagnostic disable-next-line: param-type-mismatch
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
        ---@diagnostic disable-next-line: param-type-mismatch
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
            ---@diagnostic disable-next-line: param-type-mismatch
           :append(opts.listchars[2], 'ZShowListItem')
           :append(' ')
           :append(plugin.name, 'ZShowPlugin')

        if opts.show_version then
            buf:append(' ')
            :append(
                ('(%s)'):format(plugin.version:sub(1, 7)),
                'Comment' 
            )
        end

        buf:endl()
    end
end

---@param bufnr integer
---@param line integer
---@param token_iter Iter
local function render_line_exts(bufnr, line, token_iter)
    local col = 0
    token_iter:each(function(_idx, tok)
        ---@cast tok zshow.ContentBuffer.line_token
        local text = tok:get_text()

        if tok:get_hl() ~= nil then
            vim.api.nvim_buf_set_extmark(bufnr, state.ns, line-1, col, {
                hl_group = tok:get_hl(),
                end_col = col + #text
            })
        end
        col = col + #text
    end)
end

---@param opts zshow.config.formatting
local function render_plugininfo(bufnr, plugins, opts)
    local ContentBuffer = require('zshow.content-buffer')
    local content = ContentBuffer.new()

    render_header(content, plugins, opts)
    render_category('Loaded', plugins.loaded, content, opts)
    render_category('Not Loaded', plugins.unloaded, content, opts)
    render_category('Disabled', plugins.disabled, content, opts)

    local lines = {}
    for i = 1, content:linecount() do
        lines[#lines+1] = content:get_line_text(i)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- text highlights
    vim.api.nvim_buf_clear_namespace(bufnr, state.ns, 0, -1)
    for line = 1, content:linecount() do
        render_line_exts(bufnr, line, vim.iter(content:token_iter(line)))
    end
end

---@param opts zshow.config.formatting
local function populate_window(bufnr, _winid, opts)
    local info = require('zshow.data').get_plugininfo()

    vim.keymap.set('n', 'q', '<cmd>close<cr>', {
        buffer = state.bufnr, desc = 'close window'
    })
    vim.keymap.set('n', '<Esc>', '<cmd>close<cr>', {
        buffer = state.bufnr, desc = 'close window'
    })

    vim.keymap.set('n', 'K', function()
        local line = vim.api.nvim_get_current_line()
        local plugin = line:match('^%s*%S+%s+([^%s]+)')

        ---@type zshow.info
        local match = vim.iter(vim.tbl_values(info)) --[[@as Iter]]
            :flatten()
            :find(function(p) return p.name == plugin end)
            
        vim.uv.fs_stat(match.url, function(err, sb)
            if err or not sb then
                vim.ui.open(('%s/commit/%s'):format(match.url, match.version))
            else
                vim.cmd.tabedit { match.url }
            end
        end)
    end, { buffer = state.bufnr, desc = 'open plugin uri' })

    render_plugininfo(bufnr, info, opts)
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

        vim.api.nvim_create_autocmd('FileType', {
            group = vim.api.nvim_create_augroup('zshow::open', { clear = true }),
            once = true,
            pattern = 'zshow',
            callback = function(args)
                if args.buf == state.bufnr then
                    require('zshow.util').add_backdrop(args.buf, backdrop_opts)
                end
            end
        })
    end

    vim.api.nvim_set_option_value('winblend', opts.winblend, { win = state.winid })

    vim.api.nvim_set_option_value('filetype', 'zshow', { buf = state.bufnr })

    vim.api.nvim_set_option_value('modifiable', false, { buf = state.bufnr })
    vim.api.nvim_set_option_value('readonly', true, { buf = state.bufnr })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = state.bufnr })

    return { bufnr = state.bufnr, winid = state.winid }
end

return M
