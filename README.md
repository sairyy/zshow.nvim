# 🧩 zshow.nvim

A simple plugin for viewing installed plugins managed by [zpack.nvim](https://github.com/zuqini/zpack.nvim).

It opens a floating window, listing plugins grouped by their load status and allows
opening their corresponding repo, whether remote or local.

---

## ✨ Features

- Plugins sorted according to their load status:
    + Loaded
    + Not loaded (`lazy = true` or `cmd`/`event`/`ft`/`keys` defined in zpack Spec)
    + Disabled (`cond = false`)
- Press `K` on a plugin name to open its git repo on a web browser
    + local repos are opened with `:tabedit` instead
- Update all plugins by pressing `u`
    + pressing `U` while hovering over a plugin name will update that plugin only.
- Quickly close the window with `q` or `<Esc>`

> [!note]
> For plugins to show up as "Disabled" they must have `cond = false` in their spec.
> Plugins with `enabled = false` become invisible to both `zshow` and `zpack`.

![Github couldn't load the preview; view it on Gitlab instead](.gitlab/demo.mp4)


---

## 📦 Requirements

* Neovim `>= 0.12.0` ([same as zpack](https://github.com/zuqini/zpack.nvim?tab=readme-ov-file#requirements))

---

## 🚀 Installation

Using **[zpack.nvim](https://github.com/zuqini/zpack.nvim)**:

```lua
---@type zpack.Spec
return {
    -- 'sairyy/zshow.nvim',
    -- uncomment the line above and comment the one below for the GitHub mirror
    src = 'https://gitlab.com/sairy/zpack.nvim',
    lazy = false, -- no need for lazy loading
    init = function()
        vim.g.zshow_opts = {
            -- your config here
        }
    end
}
```

It doesn't make much sense to use this plugin with managers other than zpack.

---

## ⚙️ Configuration

No configuration is needed to just use the plugin, but the `vim.g.zshow_opts`
variable can be used to customize some UI elements.

Alternatively, you can use the provided `setup()` function, which just sets its
table argument as the value for `vim.g.zshow_opts`.
```lua
require('zshow').setup(opts) -- will set `vim.g.zshow_opts = opts`
```

### Default configuration

```lua
{
    winblend = 0,   -- window pseudo-transparency
    width = 0.6,    -- window width as a % of neovim's width
    height = 0.6,   -- window height as a % of neovim's height

    -- dim windows behind zshow's window
    backdrop = {
        enable = false,
        -- only take effect if `enable` set to true
        winblend = 50,                  -- how much to dim by
        respect_transparent_bg = true,  -- only dim if background isn't transparent
    },

    formatting = {
        listchars = { '●', '○' },   -- characters to use in listings based on nesting level
        show_version = true,        -- display git commit SHA
        short_sha = true,           -- use short commit SHA if `show_version = true`
    },

    -- same options as |nvim_open_win()|
    -- if win_config.{width,height} are supplied, they override the above
    -- `width` and `height` fields
    win_config = {
        zindex = 50,
        title = ' Plugins ',
        title_pos = 'center',
    },
}
```

---

## 🌈 Highlights

| Highlight          | What                                  | Default               |
| ------------------ | ------------------------------------- | --------------------- |
| `ZShowListItem`    | Listing nest indicators ('●', '○')    | `Character`, bold     |
| `ZShowSectionName` | Name of the section (Loaded, etc.)    | `NormalFloat`, bold   |
| `ZShowPlugin`      | Plugin name                           | `NormalFloat`         |
| `ZShowPluginCount` | Plugin count number                   | `Comment`             |
| `ZShowGitSha`      | Plugin git SHA                        | `Comment`             |
| `ZShowBackdrop`    | Window backdrop (if enabled)          | `bg = #000000`

---

## 🛠 Commands and Keymaps

zshow.nvim provides the command `ZShow` to open the plugin window.

Inside the window, the following mappings are available:
- `q` / `<Esc>`: close the window
- `K`: open the git repo of the plugin on top of the cursor
    + uses `vim.ui.open` for remote plugins
    + local repos are opened with `:tabedit` instead
- `u`: update all plugins
- `U`: update the plugin on top of the cursor

> [!note]
> The two update mappings above try to update plugins without user confirmation.
> If you wish to review changes first, use `:ZUpdate` like usual.

No global keymaps are created by default, but you can add your own:

```lua
vim.keymap.set('n', '<leader>zs', '<cmd>ZShow<cr>', { desc = 'View installed plugins' })

vim.keymap.set('n', '<leader>zo', function()
    require('zshow').open {
        -- values passed here will temporarily override those set
        -- via `vim.g.zshow_opts`
    }
end, { desc = 'View installed plugins' })
```

---

## 🤝 Contributing

Feel free to open an issue or submit an MR if you find a bug or have any suggestions.

- [issues](https://gitlab.com/sairy/zshow.nvim/-/issues/new)
- [merge requests](https://gitlab.com/sairy/zshow.nvim/-/merge_requests/new)

---

## 📋 References

- [zuqini/zpack.nvim](https://github.com/zuqini/zpack.nvim): plugin manager
- [nvimdev/nvim-plugin-template](https://github.com/nvimdev/nvim-plugin-template): plugin template
- [adriankarlen/plugin-view.nvim](https://github.com/adriankarlen/plugin-view.nvim): similar project for vanilla `vim.pack`
