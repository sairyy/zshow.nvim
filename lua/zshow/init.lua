local M = {}

---@param opts? zshow.config
function M.setup(opts)
    vim.g.zshow_opts = require('zshow.config').resolve(opts)
end

---@param opts? zshow.config
function M.open(opts)
    local resolved = require('zshow.config').resolve(opts)

    local render = require('zshow.render')
    return render.display_window(resolved)
end

return M
