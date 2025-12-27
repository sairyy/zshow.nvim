local M = {}

---@param opts? zshow.config
function M.setup(opts)
    vim.g.zshow_opts = require('zshow.config').resolve(opts)
end

---@param opts? zshow.config
function M.open(opts)
    local config = require('zshow.config')

    opts = config.resolve(opts)

    vim.validate('winblend', opts.winblend, function(wb)
        return wb >= 0 and wb <= 100
    end, '0 < number < 100')

    vim.validate('width', opts.width, function(x)
        return x > 0 and x < 1
    end, '0 < number < 1')

    vim.validate('height', opts.height, function(h)
        return h > 0 and h < 1
    end, '0 < number < 1')

    local render = require('zshow.render')
    return render.display_window(opts)
end

return M
