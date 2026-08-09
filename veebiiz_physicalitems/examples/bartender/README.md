# Bartender Extension Example

This is an **extension** of `veebiiz_physicalitems`, not a core dependency.

## Setup

1. Ensure `veebiiz_physicalitems` is started.
2. Import item definitions from `items_ox_inventory.lua` into ox_inventory.
3. Adjust socket coordinates in `config/zones.lua` (`bahama_bar`) to match your MLO.
4. Grant the `bartender` job (or change ownership in config).

## Gameplay loop

1. Use **Whisky** from inventory → prop attaches to hand.
2. Walk to a **Bottle Slot** → green ghost preview → **ENTER** to snap place.
3. Use **Glass** → place into a **Glass Slot**.
4. Take the whisky bottle again.
5. Look at the glass → UI shows **Pour**.
6. Confirm → pour animation, glass state updates, bottle ml decreases.
7. Optionally carry **Ice** / **Lemon** and apply to the glass.
8. Carry **Coke** and **Mix** into a whisky glass for whisky-coke.

## Registering custom cocktails

```lua
exports.veebiiz_physicalitems:RegisterRecipe({
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
