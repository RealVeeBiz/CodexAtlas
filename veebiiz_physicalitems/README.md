# VeeBiiz Physical Items

**Inventory item → physical prop → carry → zone socket → snap place → interact → persist.**

A production-ready FiveM core framework for Qbox / ox_inventory that turns inventory items into real GTA V world props. Objects can be picked up, carried, placed into **predefined sockets**, moved, and interacted with — with custom NUI, object state, and MariaDB persistence.

This is a **core framework**, not a bartender-only script. Bartending is provided by the sibling extension resource [`veebiiz_bartender`](../veebiiz_bartender).

---

## Requirements

| Resource       | Purpose              |
|----------------|----------------------|
| `ox_lib`       | Callbacks, notify, progress |
| `ox_inventory` | Item take / give     |
| `ox_target`    | Optional targeting   |
| `oxmysql`      | Persistence          |
| `qbx_core`     | Jobs / identity (Qbox) |
| MariaDB        | `physical_objects`   |

---

## Install

1. Copy `veebiiz_physicalitems` into your `resources` folder.
2. Run `sql/physical_objects.sql` (or let the resource auto-create the table).
3. Add to `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbx_core
ensure veebiiz_physicalitems
ensure veebiiz_bartender
```

4. For a working bar, also install [`veebiiz_bartender`](../veebiiz_bartender) and import its `items_ox_inventory.lua`.
5. Align bar socket coordinates in the bartender `config/zones.lua` (or use `/pieditor`).
6. Grant ACE for the zone editor if needed:

```cfg
add_ace group.admin vpi.editor allow
```

---

## Core concepts

### Physical items
Configured in `config/items.lua` or via `RegisterItem`.

### Zones & sockets
Objects **cannot** be free-placed. They snap only into sockets defined in `config/zones.lua` (or the in-game editor).

### Ghost preview
While carrying, approaching a socket shows a semi-transparent ghost:
- **Green / blue marker** = valid
- **Red** = invalid (`Invalid placement`)
- **ENTER** place · **BACKSPACE / ESC** cancel

### Object state
Dynamic JSON state (e.g. liquid, amount, ice) is stored in MariaDB `metadata` and synced to clients.

### Streaming
Clients only spawn props within `Config.Streaming.distance` (default 100m).

---

## Exports

```lua
exports.veebiiz_physicalitems:RegisterItem('pizza', {
    label = 'Pizza',
    model = 'prop_pizza_box_01',
    interactions = { 'pickup', 'place', 'eat' },
    carry = {
        bone = 57005,
        position = vec3(0.2, 0.0, -0.05),
        rotation = vec3(0.0, 0.0, 0.0),
    },
})

exports.veebiiz_physicalitems:RegisterZone('kitchen', { ... })
exports.veebiiz_physicalitems:RegisterSocket('kitchen', { id = 'counter_01', ... })
exports.veebiiz_physicalitems:RegisterInteraction('slice', { label = 'Slice', icon = 'scissors', priority = 70 })
exports.veebiiz_physicalitems:RegisterRecipe({ ... })

local obj = exports.veebiiz_physicalitems:CreateObject({
    zone_id = 'bahama_bar',
    slot_id = 'bottle_01',
    item = 'whisky',
})

exports.veebiiz_physicalitems:RemoveObject(obj.id)
exports.veebiiz_physicalitems:GetObject(id)
exports.veebiiz_physicalitems:GetObjectsNear(coords, 15.0)
exports.veebiiz_physicalitems:UpdateObjectState(id, { amount = 100 })
exports.veebiiz_physicalitems:StartCarryItem(source, 'whisky')
```

### ox_inventory use hook

```lua
['whisky'] = {
    label = 'Whisky',
    stack = false,
    server = { export = 'veebiiz_physicalitems.usePhysicalItem' },
}
```

---

## Interactions

Built-ins: `pickup`, `place`, `move`, `rotate`, `inspect`, `use`, `pour`, `fill`, `drink`, `eat`, `cook`, `wash`, `repair`, `mix`, `open`, `close`, `add_ice`, `add_garnish`.

Object↔object compatibility is resolved through `config/recipes.lua` / `RegisterRecipe`.

---

## Zone editor

```
/pieditor
```

Authorized users (ACE `vpi.editor` or configured jobs) can create/edit zones & sockets. Runtime saves go to `config/runtime_zones/<zone>.json`. Commit important layouts back into `config/zones.lua` for source control.

---

## Security

All mutations are validated server-side:
- distance, zone, socket compatibility
- inventory presence
- ownership (`public` / `player` / `job` / `zone`)
- cooldowns & object locks
- anti-duplication on take / place / move

Never trust client-supplied state or coordinates for persistence — socket transforms are authoritative.

---

## Debug

```lua
Config.Debug = true
```

Shows zone / socket / object / entity / item / distance / state overlays and NUI debug panel.

---

## Architecture

```
VeeBiiz Physical Items
├── Core
│   ├── Object Manager
│   ├── Zone / Socket Manager
│   ├── Interaction Manager
│   ├── Placement Manager
│   ├── Persistence Manager
│   └── Streaming Manager
├── Integrations
│   ├── Qbox
│   ├── ox_inventory
│   ├── ox_lib
│   └── ox_target
└── Extensions
    ├── veebiiz_bartender  (bar / pour / mix)
    ├── Cooking
    ├── Mechanics
    └── ...
```

---

## Project layout

See `fxmanifest.lua` for load order. Key folders:

- `config/` — items, zones, interactions, recipes
- `client/` — streaming, carry, placement, targeting, NUI bridge
- `server/` — validation, persistence, inventory, exports
- `integrations/` — framework adapters
- `web/` — custom interaction UI + zone editor
- `sql/` — schema
- `../veebiiz_bartender/` — bartender / bar extension
- `examples/bartender/` — pointer to the bartender resource

---

## License

Proprietary — VeeBiiz. Use on your own servers; do not resell without permission.
