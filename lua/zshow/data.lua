---@class zshow.info
---@field name      string  plugin name
---@field url       string  git repo url
---@field version?  string  git revision

local M = {}

---@return zshow.info?
local function find_zpack()
    local ok, plugs = pcall(vim.pack.get, nil, { info = false })
    if not ok or not plugs or #plugs == 0 then
        local err = plugs --[[@as string]]
        vim.notify(
            ('zshow: could not fetch plugin specs: %s'):format(err),
            vim.log.levels.ERROR
        )
        return nil
    end ---@cast plugs -string

    for _, p in ipairs(plugs) do
        if p.spec.src:match('zpack%.nvim$') then
            return {
                name = p.spec.name,
                url = p.spec.src,
                version = p.rev,
            }
        end
    end

    return nil
end

---@param name string
---@return zshow.info?
function M.get_plugin(name)
    local ok, plug = pcall(vim.pack.get, { name }, { info = false })
    if not ok or not plug or #plug == 0 then
        local err = plug --[[@as string]]
        vim.notify(
            ('zshow: could not fetch spec for: %s\n%s'):format(name, err),
            vim.log.levels.ERROR
        )
        return
    end

    local data = plug[1] --[[@as vim.pack.PlugData]]
    return {
        name = data.spec.name,
        url = data.spec.src,
        version = data.rev,
    }
end

function M.get_plugininfo()
    local zp = require('zpack.api')

    local plugin_info = {
        ---@type zshow.info[]
        loaded = {},
        ---@type zshow.info[]
        unloaded = {},
        ---@type zshow.info[]
        disabled = {},
    }

    for _, p in ipairs(zp.get_plugins()) do
        local info = {
            name = p.name,
            url = p.src,
        }

        -- get plugin revision from `vim.pack` since zpack doesn't store it
        -- `{ info = false }` prevents `vim.pack` from fetching additional git info
        local packs = vim.pack.get({ info.name }, { info = false })

        if not packs or #packs == 0 then
            vim.notify(
                'zshow: could not find plugin in vim.pack: ' .. info.name,
                vim.log.levels.WARN
            )
        else
            info.version = packs[1].rev
        end

        if p.status == 'disabled' then
            table.insert(plugin_info.disabled, info)
        elseif p.status == 'loaded' then
            table.insert(plugin_info.loaded, info)
        else
            table.insert(plugin_info.unloaded, info)
        end
    end

    -- zpack does not keep track of itself
    -- so we add it manually to `info.loaded`
    local zpack_plug = find_zpack()
    if not zpack_plug then
        vim.notify(
            'zshow: could not find zpack. Skipping...',
            vim.log.levels.WARN
        )
    else
        table.insert(plugin_info.loaded, zpack_plug)
    end

    return plugin_info
end

return M
