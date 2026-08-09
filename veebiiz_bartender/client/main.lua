--[[
    Client bootstrap for the bartender extension.

    Zone/item sync is handled by veebiiz_physicalitems (Register* → net events
    and late-join SYNC_RUNTIME). This file is reserved for bar-specific UX.
]]

CreateThread(function()
    while GetResourceState('veebiiz_physicalitems') ~= 'started' do
        Wait(200)
    end
    print('[veebiiz_bartender] Client ready — bar extension active.')
end)
