---@class zshow.info
---@field name string
---@field url string
---@field version? string git revision

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
        vim.notify(
            'zshow: could not fetch spec for: ' .. name,
            vim.log.levels.ERROR
        )
        return
    end

    local data = plug[1] --[[@as vim.pack.PlugData]]
    return {
        name = data.spec.name,
        url = data.spec.src,
        version = data.rev
    }
end

---@param name string
---@return string?
local function get_plugin_version(name)
    local zp = require('zpack.state')

    local spec = vim.iter(vim.tbl_values(zp.spec_registry))
        :find(function(sp)
            return sp.plugin.spec.name == name
        end)

    if not spec then
        do return end
        local ok, packspec = pcall(vim.pack.get, { name })
        if not ok or not packspec then return end

        return packspec[1].rev:gsub(1, 7)
    end

    local path = spec.plugin.path
    local rv = vim.system(
        { 'git', 'rev-parse', '--short', 'HEAD' },
        { cwd = path, text = true }
    ):wait()

    return (rv.stdout or ''):gsub('\n', '') -- sha
end

function M.get_plugininfo()
    local zp = require('zpack.state')
    local plugins = vim.tbl_values(zp.spec_registry)

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
            name = plug.plugin.spec.name,
            url = plug.plugin.spec.src,
        }

        -- HACK: lazy fetch 'version', as vim.pack.get()
        -- is too slow at it due to IO
        setmetatable(info, { __index = function (self, k)
            if k == 'version' then
                if not rawget(self, 'version') then
                    local ver = get_plugin_version(rawget(self, 'name'))
                    if not ver then return nil end

                    rawset(self, 'version', ver)
                end
            end

            return rawget(self, k)
        end })

        if not resolve_enabled(plug.spec, plug.plugin) then
            table.insert(plugin_info.disabled, info)
        elseif plug.loaded then
            table.insert(plugin_info.loaded, info)
        else
            table.insert(plugin_info.unloaded, info)
        end
    end

    -- zpack does not keep track of itself
    local zpack_plug = vim.iter(zp.registered_plugin_names)
        :find(function(name) return name:match('zpack') and name end)

    if not zpack_plug then
        vim.notify(
            'zshow: could not locate zpack plugin. skipping...',
            vim.log.levels.WARN
        )
    else
        table.insert(plugin_info.loaded, M.get_plugin(zpack_plug))
    end

    return plugin_info
end

return M
