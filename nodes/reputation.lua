local addonName, addon = ...

local BULLETPOINT_ICON = "Interface\\QUESTFRAME\\UI-Quest-BulletPoint"
local LOCALIZATION_NEW_FACTION_RESET_SESSION_CONFIRMATION_EN = "It seems your faction in the Experience bar has changed.\nDo you want to reset the session?"

local node = {
    name = "reputation"
}

addon:insertNode(node.name)

addon:RegisterEvent("ADDON_LOADED", node.name)
addon:RegisterEvent("PLAYER_ENTERING_WORLD", node.name)
addon:RegisterEvent("UPDATE_FACTION", node.name)

--[[
    FUNCTIONS
]]

function addon:SessionReset_reputation()
    
    addon:insertNode(node.name)

    local name, standingID, minRep, maxRep, currentRep = GetWatchedFactionInfo()

    addon.session[node.name] = addon.session[node.name] or {
        start = currentRep,
        last = 0,
        total = 0,
        repName = name
    }

    addon:updateContent_reputation()

end

--[[
    EVENTS FUNCTIONS
]]

function addon:UPDATE_FACTION_REPUTATION()
    
    local name, standingID, minRep, maxRep, currentRep = GetWatchedFactionInfo()

    if not name then 
        addon.nodeIsActive[node.name] = false
        return
    else
        addon.nodeIsActive[node.name] = true
    end

    local amount = currentRep - addon.session[node.name].start

    if addon.session[node.name].repName == "" then 
        addon.session[node.name].repName = name
    end

    if addon.session[node.name].repName ~= name then
        addon:Popup(LOCALIZATION_NEW_FACTION_RESET_SESSION_CONFIRMATION_EN, function()
            addon:ResetSession()
        end)
    end

    if amount == 0 then return end

    if amount < 0 then -- negative gain
        amount = 0
    end

    addon.session[node.name].total = addon.session[node.name].total + amount
    addon.session[node.name].last = amount
    addon.session[node.name].start = currentRep
    addon.session[node.name].repName = name

    addon:updateContent_reputation()
end

function addon:ADDON_LOADED_REPUTATION(name)
    
    if name ~= addonName then return end

    addon.session[node.name] = addon.session[node.name] or {
        start = 0,
        last = 0,
        total = 0,
        repName = ""
    }
    addon:updateContent_reputation()

end

function addon:PLAYER_ENTERING_WORLD_REPUTATION()
    local name, standingID, minRep, maxRep, currentRep = GetWatchedFactionInfo()
    if addon.session[node.name].start == 0 then addon.session[node.name].start = currentRep end
end

function addon:updateContent_reputation()

    local icon = addon:setTexture(BULLETPOINT_ICON)

    if not addon.session[node.name].start or not addon.session[node.name].total or not addon.session[node.name].last then return end

    local name, standingID, minRep, maxRep, currentRep = GetWatchedFactionInfo()

    local total = addon.session[node.name].total
    local last = addon.session[node.name].last   
    local currentReputation = addon.session[node.name].start
    local maxReputation = maxRep
    local reputationNeeded = maxReputation - currentReputation

    local rph = addon:GetAmountPerHour(total)
    local ttl =  rph > 0 and (reputationNeeded / rph) or -1 
    local ktl = last > 0 and math.ceil(reputationNeeded / last) or -1 -- avoid division by zero

    local ttlString = (ttl > 0) and addon:FormatTime(ttl * 3600) or "N/A"
    local ktlString = (ktl > 0) and tostring(ktl) or "N/A"

    local title = string.format("Reputation/h: |ccFFFFFFF%d|r",rph)

    local content = {}
    content[1] = string.format("%sTotal reputation: |cFFFFD100%d|r", icon, total)
    content[2] = string.format("%sTime To Level rep: |cFFFFD100%s|r", icon, ttlString)
    content[3] = string.format("%sKills To Level rep: |cFFFFD100%s|r", icon, ktlString)

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