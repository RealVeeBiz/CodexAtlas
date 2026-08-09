--[[
    Server — Persistence (MariaDB / oxmysql)
]]

VPI = VPI or {}
VPI.Persistence = VPI.Persistence or {}

local TABLE = nil

local function tableName()
    TABLE = TABLE or (Config.Persistence.table or 'physical_objects')
    return TABLE
end

---@param row table
---@return table
local function mapRow(row)
    return {
        id = row.id,
        zone_id = row.zone_id,
        slot_id = row.slot_id,
        item = row.item,
        model = row.model,
        x = row.x + 0.0,
        y = row.y + 0.0,
        z = row.z + 0.0,
        rot_x = row.rot_x + 0.0,
        rot_y = row.rot_y + 0.0,
        rot_z = row.rot_z + 0.0,
        metadata = VPI.Utils.DecodeJson(row.metadata),
        state = VPI.Utils.DecodeJson(row.metadata).state or VPI.Utils.DecodeJson(row.metadata),
        owner = row.owner,
        ownership = VPI.Utils.DecodeJson(row.metadata).ownership,
        job = VPI.Utils.DecodeJson(row.metadata).job,
        locked_by = nil,
        created_at = row.created_at,
        updated_at = row.updated_at,
    }
end

function VPI.Persistence.EnsureSchema()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `zone_id` VARCHAR(64) NOT NULL,
            `slot_id` VARCHAR(64) NOT NULL,
            `item` VARCHAR(64) NOT NULL,
            `model` VARCHAR(128) NOT NULL,
            `x` DOUBLE NOT NULL,
            `y` DOUBLE NOT NULL,
            `z` DOUBLE NOT NULL,
            `rot_x` DOUBLE NOT NULL DEFAULT 0,
            `rot_y` DOUBLE NOT NULL DEFAULT 0,
            `rot_z` DOUBLE NOT NULL DEFAULT 0,
            `metadata` LONGTEXT NULL,
            `owner` VARCHAR(64) NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_zone_slot` (`zone_id`, `slot_id`),
            KEY `idx_item` (`item`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(tableName()))
end

---@return table[]
function VPI.Persistence.LoadAll()
    local rows = MySQL.query.await(('SELECT * FROM `%s`'):format(tableName())) or {}
    local objects = {}
    for i = 1, #rows do
        objects[#objects + 1] = mapRow(rows[i])
    end
    return objects
end

---@param data table
---@return number|nil
function VPI.Persistence.Insert(data)
    local metadata = {
        state = data.state or {},
        ownership = data.ownership,
        job = data.job,
        extra = data.metadata or {},
    }

    local id = MySQL.insert.await(
        ('INSERT INTO `%s` (zone_id, slot_id, item, model, x, y, z, rot_x, rot_y, rot_z, metadata, owner) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(tableName()),
        {
            data.zone_id,
            data.slot_id,
            data.item,
            data.model,
            data.x, data.y, data.z,
            data.rot_x or 0.0, data.rot_y or 0.0, data.rot_z or 0.0,
            VPI.Utils.EncodeJson(metadata),
            data.owner,
        }
    )
    return id
end

---@param id number
---@param data table
---@return boolean
function VPI.Persistence.Update(id, data)
    local existing = VPI.Objects and VPI.Objects.Get(id)
    local metadata = {
        state = data.state or (existing and existing.state) or {},
        ownership = data.ownership or (existing and existing.ownership),
        job = data.job or (existing and existing.job),
        extra = data.metadata or (existing and existing.metadata) or {},
    }

    local affected = MySQL.update.await(
        ('UPDATE `%s` SET zone_id = ?, slot_id = ?, item = ?, model = ?, x = ?, y = ?, z = ?, rot_x = ?, rot_y = ?, rot_z = ?, metadata = ?, owner = ? WHERE id = ?'):format(tableName()),
        {
            data.zone_id,
            data.slot_id,
            data.item,
            data.model,
            data.x, data.y, data.z,
            data.rot_x or 0.0, data.rot_y or 0.0, data.rot_z or 0.0,
            VPI.Utils.EncodeJson(metadata),
            data.owner,
            id,
        }
    )
    return (affected or 0) > 0
end

---@param id number
---@param state table
---@return boolean
function VPI.Persistence.UpdateState(id, state)
    local obj = VPI.Objects.Get(id)
    if not obj then return false end
    obj.state = state
    return VPI.Persistence.Update(id, obj)
end

---@param id number
---@return boolean
function VPI.Persistence.Delete(id)
    local affected = MySQL.update.await(('DELETE FROM `%s` WHERE id = ?'):format(tableName()), { id })
    return (affected or 0) > 0
end

---@param zoneId string
---@param slotId string
---@return number
function VPI.Persistence.CountInSocket(zoneId, slotId)
    local row = MySQL.single.await(
        ('SELECT COUNT(*) AS cnt FROM `%s` WHERE zone_id = ? AND slot_id = ?'):format(tableName()),
        { zoneId, slotId }
    )
    return row and row.cnt or 0
end
