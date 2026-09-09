# veebiiz_hydrotest

Test de compétence **Hydro-Québec** pour FiveM : le joueur entre son nom, répond à des questions tirées au hasard, et les admins gèrent la banque via une UI.

## Install

1. Copy `veebiiz_hydrotest` into your server `resources` folder.
2. Add to `server.cfg`:

```cfg
ensure veebiiz_hydrotest
add_ace group.admin hydrotest.admin allow
```

3. Edit `config/config.lua` (nombre de questions, seuil de réussite, thème).
4. Seed / edit questions in `data/questions.json` (or in-game with `/hydroadmin`).

## Commands

| Command | Role |
|---------|------|
| `/hydrotest` | Open the test (name → random questions → result) |
| `/hydroadmin` | Open the question editor (ACE `hydrotest.admin` or admin framework group) |

## Features

- Name entry before starting
- Random draw of `Config.QuestionsPerTest` from active questions
- Answer order shuffled per question
- Pass / fail against `Config.PassPercent`
- Admin CRUD: create, edit, delete, activate/deactivate questions
- Persists edits to `data/questions.json` via `SaveResourceFile`
- Sample bank includes **Sécurité**, **Batterie**, **Consignation**, **Urgence**, etc.
- Optional metadata reward on pass (`Config.OnPass`)
- Browser preview without FiveM:
  - `web/index.html?preview=1` — take the test
  - `web/index.html?preview=admin` — admin editor

## Exports

```lua
exports['veebiiz_hydrotest']:Open()
exports['veebiiz_hydrotest']:OpenAdmin()
exports['veebiiz_hydrotest']:Close()
exports['veebiiz_hydrotest']:IsOpen()
```

## Theme

Teal Hydro-Québec–inspired (`#00A3A1`). Override via `Config.Theme`.
