--[[
    Integration — ox_inventory (server)
]]

VPI = VPI or {}
VPI.Inventory = VPI.Inventory or {}

local RESOURCE = 'ox_inventory'

local function ready()
    return GetResourceState(RESOURCE) == 'started'
end

---@param source number
---@param item string
---@param count number|nil
---@return number
function VPI.Inventory.GetItemCount(source, item, count)
    if not ready() then return 0 end
    return exports.ox_inventory:GetItemCount(source, item) or 0
end

---@param source number
---@param item string
---@param count number
---@param metadata table|nil
---@return boolean, string|nil
function VPI.Inventory.RemoveItem(source, item, count, metadata)
    if not ready() then return false, 'inventory_unavailable' end
    local ok = exports.ox_inventory:RemoveItem(source, item, count or 1, metadata)
    return ok and true or false, ok and nil or 'missing_item'
end

---@param source number
---@param item string
---@param count number
---@param metadata table|nil
---@return boolean, string|nil
function VPI.Inventory.AddItem(source, item, count, metadata)
    if not ready() then return false, 'inventory_unavailable' end
    local ok = exports.ox_inventory:AddItem(source, item, count or 1, metadata)
    return ok and true or false, ok and nil or 'inventory_full'
end

---@param source number
---@param item string
---@return table|nil
function VPI.Inventory.GetSlotWithItem(source, item)
    if not ready() then return nil end
    if exports.ox_inventory.GetSlotWithItem then
        return exports.ox_inventory:GetSlotWithItem(source, item)
    end
    return nil
end

---@param source number
---@param item string
---@param metadata table|nil
---@return boolean, table|nil, string|nil
function VPI.Inventory.TakePhysicalItem(source, item, metadata)
    local slot = VPI.Inventory.GetSlotWithItem(source, item)
    local meta = metadata
    if slot and slot.metadata then
        meta = slot.metadata
    end

    local ok, err = VPI.Inventory.RemoveItem(source, item, 1, meta)
    if not ok then return false, nil, err end
    return true, meta, nil
end

---@param source number
---@param item string
---@param state table|nil
---@param meta table|nil
---@return boolean, string|nil
function VPI.Inventory.GivePhysicalItem(source, item, state, meta)
    local metadata = VPI.Utils.DeepCopy(meta or {})
    metadata.vpi = metadata.vpi or {}
    metadata.vpi.state = state or metadata.vpi.state or {}
    metadata.vpi.physical = true
    return VPI.Inventory.AddItem(source, item, 1, metadata)
end
