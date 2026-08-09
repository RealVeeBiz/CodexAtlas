# VeeBiiz Bartender

Bar / bartender **extension** for [`veebiiz_physicalitems`](../veebiiz_physicalitems).

Inventory bottles and glasses become persistent world props. Place them into bar sockets, pour, mix, add ice/garnish, drink, and wash — all driven by the physical-items core.

## Requirements

- `veebiiz_physicalitems`
- `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`, `qbx_core` (same as the core)

## Install

1. Ensure both resources are in your `resources` folder.
2. Import items from `items_ox_inventory.lua` into ox_inventory.
3. Adjust socket coordinates in `config/zones.lua` (`bahama_bar`) to match your MLO.
4. Grant the `bartender` job (or change `BarConfig.Job`).
5. Add to `server.cfg` **after** the physical-items core:

```cfg
ensure veebiiz_physicalitems
ensure veebiiz_bartender
```

## Gameplay loop

1. Use **Whisky** from inventory → prop attaches to hand.
2. Walk to a **Bottle Slot** → green ghost preview → **ENTER** to snap place.
3. Use **Glass** → place into a **Glass Slot**.
4. Take the whisky bottle again.
5. Look at the glass → UI shows **Pour**.
6. Confirm → pour animation, glass state updates, bottle ml decreases.
7. Optionally carry **Ice** / **Lemon** and apply to the glass.
8. Carry **Coke** and **Mix** into a whisky glass for whisky-coke (or tonic into vodka).

## Custom cocktails

```lua
exports.veebiiz_bartender:RegisterCocktail({
    id = 'custom_cocktail',
    label = 'Mix Special',
    interaction = 'mix',
    sourceItems = { 'tonic' },
    targetItems = { 'glass' },
    requireTargetState = { liquid = 'vodka' },
    consumeSource = 80,
    addToTarget = { liquid = 'vodka_tonic', amountDelta = 80 },
    animation = 'pour',
    duration = 2000,
})
```

Or append to `config/recipes.lua` and restart the resource.

## Config

| File | Purpose |
|------|---------|
| `config/config.lua` | Job name, boot delay, optional starter stock |
| `config/items.lua` | Physical item defs (models, carry, default state) |
| `config/recipes.lua` | Pour / mix / ice / garnish recipes |
| `config/zones.lua` | Bar zone + bottle/glass/mixing sockets |
