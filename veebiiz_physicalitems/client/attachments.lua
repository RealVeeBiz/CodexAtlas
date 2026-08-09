--[[
    Client — Entity attachments (carry bones)
]]

VPI = VPI or {}
VPI.Attachments = VPI.Attachments or {}

---@param entity number
---@param itemName string
---@return boolean
function VPI.Attachments.AttachToHand(entity, itemName)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    local def = VPI.Utils.GetItemDef(itemName) or {}
    local carry = def.carry or {}
    local bone = carry.bone or VPI.Constants.DEFAULT_BONE
    local pos = carry.position or vec3(0.12, 0.02, -0.02)
    local rot = carry.rotation or vec3(-80.0, 0.0, 0.0)

    local ped = PlayerPedId()
    local boneIndex = GetPedBoneIndex(ped, bone)

    AttachEntityToEntity(
        entity,
        ped,
        boneIndex,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, 1, true
    )
    return true
end

---@param entity number
function VPI.Attachments.Detach(entity)
    if entity and DoesEntityExist(entity) and IsEntityAttached(entity) then
        DetachEntity(entity, true, true)
    end
end
