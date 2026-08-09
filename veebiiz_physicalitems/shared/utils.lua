--[[
    VeeBiiz Physical Items — Shared Utilities
]]

VPI = VPI or {}
VPI.Utils = VPI.Utils or {}

---@param value any
---@return boolean
function VPI.Utils.IsVec3(value)
    return type(value) == 'vector3' or (type(value) == 'table' and value.x and value.y and value.z and not value.w)
end

---@param a vector3|table
---@param b vector3|table
---@return number
function VPI.Utils.Distance(a, b)
    local ax, ay, az = a.x or a[1], a.y or a[2], a.z or a[3]
    local bx, by, bz = b.x or b[1], b.y or b[2], b.z or b[3]
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param coords vector3|table
---@return number, number, number
function VPI.Utils.UnpackCoords(coords)
    return coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]
end

---@param rot vector3|table|nil
---@return number, number, number
function VPI.Utils.UnpackRot(rot)
    if not rot then return 0.0, 0.0, 0.0 end
    return rot.x or rot[1] or 0.0, rot.y or rot[2] or 0.0, rot.z or rot[3] or 0.0
end

---@param tbl table
---@return table
function VPI.Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == 'table' and VPI.Utils.DeepCopy(v) or v
    end
    return copy
end

---@param list table|nil
---@param value any
---@return boolean
function VPI.Utils.Contains(list, value)
    if not list then return false end
    for i = 1, #list do
        if list[i] == value then return true end
    end
    return false
end

---@param itemName string
---@return table|nil
function VPI.Utils.GetItemDef(itemName)
    if not itemName then return nil end
    local items = Config and Config.Items or {}
    return items[itemName]
end

---@param zoneId string
---@return table|nil
function VPI.Utils.GetZone(zoneId)
    local zones = Config and Config.Zones or {}
    return zones[zoneId]
end

---@param zoneId string
---@param socketId string
---@return table|nil
function VPI.Utils.GetSocket(zoneId, socketId)
    local zone = VPI.Utils.GetZone(zoneId)
    if not zone or not zone.sockets then return nil end
    for i = 1, #zone.sockets do
        if zone.sockets[i].id == socketId then
            return zone.sockets[i]
        end
    end
    return nil
end

---@param socket table
---@param itemName string
---@return boolean
function VPI.Utils.SocketAllowsItem(socket, itemName)
    if not socket or not itemName then return false end
    local allowed = socket.allowedItems
    if not allowed or #allowed == 0 then return true end
    return VPI.Utils.Contains(allowed, itemName)
end

---@param metadata any
---@return string
function VPI.Utils.EncodeJson(metadata)
    if metadata == nil then return '{}' end
    if type(metadata) == 'string' then return metadata end
    local ok, encoded = pcall(json.encode, metadata)
    return ok and encoded or '{}'
end

---@param raw any
---@return table
function VPI.Utils.DecodeJson(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, decoded = pcall(json.decode, raw)
    return (ok and type(decoded) == 'table') and decoded or {}
end

---@param msg string
---@param ... any
function VPI.Utils.Debug(msg, ...)
    if not Config or not Config.Debug then return end
    local args = { ... }
    if #args > 0 then
        print(('[vpi:debug] ' .. msg):format(table.unpack(args)))
    else
        print('[vpi:debug] ' .. tostring(msg))
    end
end

---@param model string|number
---@return number
function VPI.Utils.ModelHash(model)
    if type(model) == 'number' then return model end
    return joaat(model)
end
