# 🧩 zshow.nvim

A simple plugin for viewing installed plugins managed by [zpack.nvim](https://github.com/zuqini/zpack.nvim).

It opens a floating window listing plugins grouped by load status and provides
basic interaction for inspecting plugin sources.

---

## ✨ Features

- Plugins sorted according to their load status:
    + Loaded
    + Not loaded (if `lazy = true` in zpack Spec)
    + Disabled
- Press `K` on a plugin name to open its git repo on a web browser
    + local repos are opened with `:tabedit` instead
- Quickly close the window with `q` or `<Esc>`


![Github couldn't load the preview: https://gitlab.com/sairy/zshow.nvim#-features](./.gitlab/demo.mp4)


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
    -- uncomment the line above and
    -- comment the below one for the githuh version
    src = 'https://gitlab.com/sairy/zpack.nvim',
    lazy = false, -- no need for lazy loading
    init = function()
        -- your config here
    end
}
```

Other plugin managers are unsupported.

---

## ⚙️ Configuration

There's no configuration required to just use the plugin, but you can use the
`vim.g.zshow_opts` variable to customize some UI aspects.

A compatibility `setup()` function exists, which just sets the opts table as
the value for `vim.g.zshow_opts`.
```lua
require('zshow').setup(opts) -- will set `vim.g.zshow_opts = opts`
```

### Default configuration:

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
        listchars = { '-', '+' },   -- characters to use in listings based on nesting level
        show_version = true,        -- display git commit SHA
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
| `ZShowListItem`    | Listing nest indicators ('-', '+')    | `Character`, bold     |
| `ZShowSectionName` | Name of the section (Loaded, etc.)    | `NormalFloat`, bold   |
| `ZShowPlugin`      | Plugin name                           | `NormalFloat`         |
| `ZShowPluginCount` | Plugin count number                   | `Comment`             |
| `ZShowGitSha`      | Plugin git SHA                        | `Comment`             |

---

## 🛠 Commands / Keybindings

zshow.nvim provides the command `ZShow` to open the plugin window.

Inside the window, the following bindings are available:
- `q` / `<Esc>` - close the window
- `K` - open the plugin's git repo (uses `vim.ui.open`)
    + local repos are opened with `:tabedit` instead

No glabal keybindings are created by default, but you can add your own:

```lua
vim.keymap.set('n', '<leader>zs', '<cmd>ZShow<cr>', { desc = 'View installed plugins' })

vim.keymap.set('n', '<leader>zo', function()
    require('zshow').open {
        -- values passed here will override (for this function call only)
        -- those set via `vim.g.zshow_opts`
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

- [zpack.nvim](https://github.com/zuqini/zpack.nvim): plugin manager
- [nvimdev/nvim-plugin-template](https://github.com/nvimdev/nvim-plugin-template): plugin template
- [adriankarlen/plugin-view.nvim](https://github.com/adriankarlen/plugin-view.nvim): similar project
  for vanilla `vim.pack`
