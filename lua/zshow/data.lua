---@class zshow.info
---@field name string
---@field url string
---@field version string git revision

local M = {}

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

---@param name string
---@return zshow.info?
function M.get_plugin(name)
    local ok, plug = pcall(vim.pack.get, { name })
    if not ok or not plug then
        return
    end

    local data = plug[1] --[[@as vim.pack.PlugData]]
    return {
        name = data.spec.name,
        url = data.spec.src,
        version = data.rev
    }
end

function M.get_plugininfo()
    local zp = require('zpack.state')
    local plugins = vim.pack.get()

    local plugin_info = {
        ---@type zshow.info[]
        loaded = {},
        ---@type zshow.info[]
        unloaded = {},
        ---@type zshow.info[]
        disabled = {},
    }

    for _, plug in ipairs(plugins) do
        local info = {
            name = plug.spec.name,
            url = plug.spec.src,
            version = plug.rev,
        }

        -- zpack does not keep track of itself
        if not plug.spec.src:match('zpack%.nvim') then
            local zspec = zp.spec_registry[plug.spec.src]

            if not zspec or not resolve_enabled(zspec.spec, zspec.plugin) then
                table.insert(plugin_info.disabled, info)
            elseif zspec.loaded then
                table.insert(plugin_info.loaded, info)
            else
                table.insert(plugin_info.unloaded, info)
            end
        else
            table.insert(plugin_info.loaded, info)
        end
    end

    return plugin_info
end

return M
