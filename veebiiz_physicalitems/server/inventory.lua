--[[
    Server — Inventory bridge helpers
]]

VPI = VPI or {}
VPI.Inv = VPI.Inv or {}

---@param source number
---@param itemName string
---@return boolean, table|nil, string|nil
function VPI.Inv.ConsumeForPlacement(source, itemName)
    if not Config.Security.validateInventory then
        return true, {}, nil
    end

    local ok, meta, err = VPI.Inventory.TakePhysicalItem(source, itemName)
    if not ok then return false, nil, err end

    local def = VPI.Utils.GetItemDef(itemName)
    local state = {}
    if meta and meta.vpi and meta.vpi.state then
        state = VPI.Utils.DeepCopy(meta.vpi.state)
    elseif def and def.defaultState then
        state = VPI.Utils.DeepCopy(def.defaultState)
    end

    return true, { metadata = meta or {}, state = state }, nil
end

---@param source number
---@param object table
---@return boolean, string|nil
function VPI.Inv.ReturnObject(source, object)
    if not Config.Security.validateInventory then
        return true, nil
    end
    return VPI.Inventory.GivePhysicalItem(source, object.item, object.state, object.metadata)
end
