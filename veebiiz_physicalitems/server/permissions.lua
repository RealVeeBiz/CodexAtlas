--[[
    Server — Permissions
]]

VPI = VPI or {}
VPI.Permissions = VPI.Permissions or {}

---@param source number
---@param object table
---@param action string
---@return boolean, string|nil
function VPI.Permissions.CanInteract(source, object, action)
    if not object then return false, 'missing_object' end

    local def = VPI.Utils.GetItemDef(object.item)
    local ownership = object.ownership or (def and def.permissions and def.permissions.ownership) or 'public'
    local job = object.job or (def and def.permissions and def.permissions.job)
    local owner = object.owner

    if not VPI.Validation.CanAccessOwnership(source, ownership, owner, job) then
        return false, 'no_permission'
    end

    if action == 'pickup' and def and def.canPickup == false then
        return false, 'cannot_pickup'
    end
    if action == 'move' and def and def.canMove == false then
        return false, 'cannot_move'
    end
    if action == 'place' and def and def.canPlace == false then
        return false, 'cannot_place'
    end

    local zone = object.zone_id and VPI.Utils.GetZone(object.zone_id)
    if zone then
        local zoneOwnership = zone.ownership or 'public'
        if not VPI.Validation.CanAccessOwnership(source, zoneOwnership, nil, zone.job) then
            return false, 'zone_permission'
        end
    end

    return true, nil
end

---@param source number
---@return boolean
function VPI.Permissions.CanUseEditor(source)
    if not Config.Editor.enabled then return false end
    return VPI.Framework.IsAdmin(source)
end
