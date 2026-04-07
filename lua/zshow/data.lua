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
            return spec.cond(plugin)
        else
            return spec.cond
        end
    end

    return true
end

---@param plugin_names string[]
---@return zshow.info?
local function find_zpack(plugin_names)
    for _, name in ipairs(plugin_names) do
        if name:match('zpack') then
            local candidate = M.get_plugin(name)
            if candidate and candidate.url:match('zpack%.nvim$') then
                return candidate
            end
        end
    end

    return nil
end

---@param name string
---@return zshow.info?
function M.get_plugin(name)
    local ok, plug = pcall(vim.pack.get, { name }, { info = false })
    if not ok or not plug or #plug == 0 then
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

function M.get_plugininfo()
    local zp = require('zpack.state')
    local plugins = zp.spec_registry

    local plugin_info = {
        ---@type zshow.info[]
        loaded = {},
        ---@type zshow.info[]
        unloaded = {},
        ---@type zshow.info[]
        disabled = {},
    }

    for src, plug in pairs(plugins) do
        local pack_spec = zp.src_to_pack_spec[src]

        local info = {
            name = pack_spec.name --[[@as string]],
            url = pack_spec.src,
        }

        -- get plugin revision from `vim.pack` since zpack doesn't store it
        -- `{ info = false }` prevents `vim.pack` from fetching additional git info
        local packs = vim.pack.get({ info.name }, { info = false })

        assert(packs and #packs == 1, 'zshow: could not find plugin in vim.pack: ' .. info.name)
        info.version = packs[1].rev

        local zspec = plug.merged_spec or plug.specs[1]

        if not resolve_enabled(zspec, plug.plugin) then
            table.insert(plugin_info.disabled, info)
        elseif plug.load_status == 'loaded' then
            table.insert(plugin_info.loaded, info)
        else
            table.insert(plugin_info.unloaded, info)
        end
    end

    -- zpack does not keep track of itself
    -- so we add it manually to `info.loaded`
    local zpack_plug = find_zpack(zp.registered_plugin_names)

    if not zpack_plug then
        vim.notify(
            'zshow: could not find zpack. skipping...',
            vim.log.levels.WARN
        )
    else
        table.insert(plugin_info.loaded, zpack_plug)
    end

    return plugin_info
end

return M
