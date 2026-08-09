--[[
    VeeBiiz Physical Items — Placement Zones & Sockets

    Objects can ONLY be placed into sockets inside registered zones.
    Core ships with no zones. Extensions (e.g. veebiiz_bartender) register via:
      exports.veebiiz_physicalitems:RegisterZone(id, definition)
      exports.veebiiz_physicalitems:RegisterSocket(zoneId, socket)
    Or use /pieditor and commit runtime JSON back into an extension config.
]]

Config = Config or {}
Config.Zones = Config.Zones or {}

--[[
    Zone schema:
    {
        id = string,
        label = string,
        coords = vec3,          -- zone center
        radius = number,        -- simple radius zone (or use points/poly)
        points = vec3[]?,       -- optional poly points
        minZ / maxZ,
        ownership = 'public'|'job'|'zone'|'player',
        job = string?,
        sockets = { Socket, ... }
    }

    Socket schema:
    {
        id = string,
        label = string,
        coords = vec3,
        rotation = vec3,
        allowedItems = string[],
        allowedCategories = string[]?,
        maxObjects = number,
        allowedInteractions = string[]?,
        ownership = string?,
        job = string?,
        metadataRules = table?,
    }
]]
