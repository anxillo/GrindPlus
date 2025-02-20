local addonName, addon = ...

local BULLETPOINT_ICON = "Interface\\QUESTFRAME\\UI-Quest-BulletPoint"
--local MAX_PLAYER_LEVEL = 60

local node = {
    name = "xp"
}

addon:insertNode(node.name)

if UnitLevel("player") == GetMaxPlayerLevel() then
    addon.nodeIsActive[node.name] = false
end



addon:RegisterEvent("ADDON_LOADED", node.name)
addon:RegisterEvent("PLAYER_ENTERING_WORLD", node.name)
addon:RegisterEvent("PLAYER_XP_UPDATE", node.name)

--[[
    FUNCTIONS
]]

function addon:SessionReset_xp()
    
    addon:insertNode(node.name)

    local xp = UnitXP("player")

    addon.session[node.name] = addon.session[node.name] or {
        start = xp,
        last = 0,
        total = 0,
    }

    addon:updateContent_xp()

end

--[[
    EVENTS FUNCTIONS
]]

function addon:PLAYER_XP_UPDATE_XP()
    
    local currentXp = UnitXP("player")

    local amount = currentXp - addon.session[node.name].start

    if amount < 0 then -- new level. do an approximation (faster)
        amount = currentXp
    end

    addon.session[node.name].total = addon.session[node.name].total + amount
    addon.session[node.name].last = amount
    addon.session[node.name].start = currentXp

    addon:updateContent_xp()
end

function addon:ADDON_LOADED_XP(name)
    
    if name ~= addonName then return end
    --local xp = UnitXP("player")

    addon.session[node.name] = addon.session[node.name] or {
        start = 0,
        last = 0,
        total = 0,
    }
    addon:updateContent_xp()

end

function addon:PLAYER_ENTERING_WORLD_XP()
    local xp = UnitXP("player")
    if addon.session[node.name].start == 0 then addon.session[node.name].start = xp end
end

function addon:updateContent_xp()

    local icon = addon:setTexture(BULLETPOINT_ICON)

    if not addon.session[node.name].start or not addon.session[node.name].total or not addon.session[node.name].last then return end

    local total = addon.session[node.name].total
    local last = addon.session[node.name].last
    local currentXp = addon.session[node.name].start
    local maxXp = UnitXPMax("player")
    local xpNeeded = maxXp - currentXp

    local xph = addon:GetAmountPerHour(total)
    local ttl =  xph > 0 and (xpNeeded / xph) or -1 
    local ktl = last > 0 and math.ceil(xpNeeded / last) or -1 -- avoid division by zero

    local ttlString = (ttl > 0) and addon:FormatTime(ttl * 3600) or "N/A"
    local ktlString = (ktl > 0) and tostring(ktl) or "N/A"

    local title = string.format("kXP/h: |ccFFFFFFF%.2f|r",xph/1000)

    local content = {}
    content[1] = string.format("%sTotal xp: |cFFFFD100%d|r", icon, total)
    content[2] = string.format("%sTime To Level: |cFFFFD100%s|r", icon, ttlString)
    content[3] = string.format("%sKills To Level: |cFFFFD100%s|r", icon, ktlString)

    addon.titleText[node.name] = title

    addon.bodyText[node.name] =  {}

    for _, text in ipairs(content) do
        table.insert(addon.bodyText[node.name], {
        text = text,
        node = node.name
    })
    end

    addon.UI:UpdateNodesContent()

end

