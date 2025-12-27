---@class zshow.info
---@field name string
---@field url string
---@field version? string git revision

local M = {}

---@param plugin zpack.Spec
local function resolve_url(plugin)
    return plugin.src
        or plugin.url
        or (plugin.dir and vim.uv.fs_realpath(plugin.dir))
        or ('https://github.com/%s'):format(plugin[1])
end

---@param spec zpack.Spec
---@param plugin? zpack.Plugin
---@return boolean
local function resolve_enabled(spec, plugin)
    if spec.enabled ~= nil then
        if type(spec.enabled) == 'function' then
            return spec.enabled()
        else
            return spec.enabled
        end
    elseif spec.cond ~= nil then
        if type(spec.cond) == 'function' then
            return spec.cond(plugin) ---@diagnostic disable-line: param-type-mismatch
        else
            return spec.cond
        end
    end

    return true
end

function M.get_plugininfo()
    local zp = require('zpack.state')

    local plugin_info = {
        ---@type zshow.info[]
        loaded = {},
        ---@type zshow.info[]
        unloaded = {},
        ---@type zshow.info[]
        disabled = {},
    }

    for _, plug in pairs(zp.spec_registry) do
        local info = {
            name = plug.spec.name,
            url = resolve_url(plug.spec),
            version = vim.pack.get({ plug.spec.name })[1].rev ---@diagnostic disable-line: need-check-nil
        }

        if plug.loaded then
            table.insert(plugin_info.loaded, info)
        elseif not resolve_enabled(plug.spec, plug.plugin) then
            table.insert(plugin_info.disabled, info)
        else
            table.insert(plugin_info.unloaded, info)
        end
    end

    -- zpack does not keep track of itself
    local zpack = vim.pack.get({ 'zpack.nvim' })[1]
    ---@cast zpack -nil

    table.insert(plugin_info.loaded, {
        name = zpack.spec.name,
        url = zpack.spec.src,
        version = zpack.rev,
    })

    return plugin_info
end

return M
