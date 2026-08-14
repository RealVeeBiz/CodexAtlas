# veebiiz_pausemenu

Custom pause menu for FiveM. Replaces the default GTA V escape menu with a black & yellow NUI showing live player data, server rules, and community links.

## Install

1. Copy `veebiiz_pausemenu` into your server `resources` folder.
2. Add to `server.cfg`:

```cfg
ensure veebiiz_pausemenu
```

3. Edit `config/config.lua`:
   - `Config.ServerName` / `Config.ServerTagline`
   - `Config.Rules`
   - `Config.Links` (Discord, website, store, etc.)

## Features

- Blocks the native pause menu (ESC / P) and opens this UI instead
- Live player snapshot: name, ID, ping, job, cash, bank, online count
- Auto-detects **Qbox**, **QBCore**, or **ESX** (falls back to standalone)
- Rules tab + community links (opens in the player browser)
- Map / Settings hand-off to native front-end menus
- Disconnect with confirmation
- `/pausemenu` command + exports: `Open`, `Close`, `Toggle`, `IsOpen`

## Theme

Black base with yellow accents (`#F5C518`). Adjust `Config.Theme.primary` if you want a different yellow.

## Preview NUI in a browser

Open `web/index.html?preview=1` to review layout without FiveM.
