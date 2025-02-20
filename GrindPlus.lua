local addonName, addon = ...
local LOCALIZATION_RESET_SESSION_CONFIRMATION_EN = "Do you want to reset the session?\nTimer and data will be reset"
local LOCALIZATION_DUNGEON_RESET_SESSION_CONFIRMATION_EN = "It seems you have entered an instance.\nDo you want to reset Your session?"

local elapsedTime = 0            -- OnUpdate elapsed timeSinceLastUpdate
    addon.nodes = {}
    addon.nodeIsActive = {}
    
    addon.events = {}
    --addon.hasContent = {}
    --addon.isContentChanged = {}
    addon.titleText = {}
    addon.bodyText = {}
    addon.session = {}
    addon.session.clock = {
        sessionStartTime = GetTime(),
        time = 0
    }


function addon:UpdateZone()
    C_Timer.After(2, function()
        local zone = GetZoneText()
        --addon:CheckZone()
        addon.UI:UpdateZoneText(zone)
    end)
end

-- check if new zone is a dungeon or raid
--[[function addon:CheckZone()
    local name, type, difficultyIndex, difficultyName, maxPlayers,
    dynamicDifficulty, isDynamic, instanceMapId, lfgID = GetInstanceInfo()
    if type == "party" or type == "raid" then
        addon:Popup(LOCALIZATION_DUNGEON_RESET_SESSION_CONFIRMATION_EN,function()
            addon:ResetSession()
        end)
    end
end ]]

--[[
        PROCESS NODES
]]

function addon:insertNode(nodeName)
    
    for _, registeredNode in ipairs(addon.nodes) do
        if registeredNode == nodeName then
            --print("node '" .. nodeName .. "' is already registered.")
            return
        end
    end

    table.insert(addon.nodes, nodeName)

    addon.nodeIsActive[nodeName] = true

end

function addon:RegisterEvent(event, node)

    local handlerName =""
    if not node then 
        handlerName = event
    else
        handlerName = event .. "_" .. string.upper(node)
    end

    if not addon.events[event] then
        addon.events[event] = {}
        addon.eventFrame:RegisterEvent(event) 
    end

    for _, registeredHandler in ipairs(addon.events[event]) do
        if registeredHandler == handlerName then
            print("Handler '" .. handlerName .. "' is already registered for event '" .. event .. "'.")
            return
        end
    end

    table.insert(addon.events[event], handlerName)

end


--[[
        INITIALIZE ADDON
]]

function addon:Initialize() 
    addon:DBLoad()
    addon.session.clock.sessionStartTime = GetTime()
    addon.UI:InitializeNodes()
    addon.UI:Refresh()
    addon:UpdateZone()
end

--[[
        RESET SESSION
]]

function addon:ResetSession()
    addon.session = {}
    addon.session.clock = {
        sessionStartTime = GetTime(),
        time = 0
    }

    addon:UpdateZone()
    --reset nodes
    for _, node in ipairs(addon.nodes) do
        addon["SessionReset_" .. node]()
    end
    addon.UI:Refresh()
end

--[[
        DATABASE
]]

function addon:DBSave()
    addon.session.clock.time = addon.session.clock.time + (GetTime() - addon.session.clock.sessionStartTime)

    GrindPlusDB = GrindPlusDB or {}

    if not GrindPlusDB.session then
        GrindPlusDB.session = {}
    end

    --[[if not GrindPlusDB.settins then
        GrindPlusDB.settings = {}
    end ]]

    GrindPlusDB.session = addon.session

    GrindPlusDB.settings = addon.nodeIsActive

end

function addon:DBLoad()
    GrindPlusDB = GrindPlusDB or {}

    if not GrindPlusDB.session then
        GrindPlusDB.session = {}
    end
    if not GrindPlusDB.settings then
        GrindPlusDB.settings = {}
    else
        addon.nodeIsActive = GrindPlusDB.settings
    end

    if GrindPlusDB.session then
        for k, v in pairs(GrindPlusDB.session) do
            addon.session[k] = v
        end
    end

end

--[[
        CLOCK
]]

-- Format time
function addon:FormatTime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if days == 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%d days, %02d:%02d:%02d", days, hours, minutes, secs)
    end
end

-- Clock update (every second)
function addon:UpdateClock()
    local clockSeconds = addon.session.clock.time + (GetTime() - addon.session.clock.sessionStartTime)
    if addon.UI.clockString then
        addon.UI.clockString:SetText(addon:FormatTime(clockSeconds))
    end
end

-- Get the amount for hour
function addon:GetAmountPerHour(amount)
    if not amount then return end
    local time = addon.session.clock.time + (GetTime() - addon.session.clock.sessionStartTime)
    
    if time > 0 and amount > 0 then
        return 3600 * amount / time
    else
        return 0
    end
end

--[[
        EVENTS FUNCTIONS
]]

function addon:ADDON_LOADED(name)
    if name ~= addonName then return end
    addon:Initialize()
end

function addon:PLAYER_ENTERING_WORLD()
end

function addon:PLAYER_LOGOUT()
    addon:DBSave()
end

function addon:ZONE_CHANGED_NEW_AREA ()
    addon:UpdateZone()
    --addon:CheckZone()

end

--[[
        EVENTS HANDLING      
]]

    addon.eventFrame = CreateFrame("Frame")

    addon:RegisterEvent("ADDON_LOADED")
    addon:RegisterEvent("PLAYER_ENTERING_WORLD")
    addon:RegisterEvent("PLAYER_LOGOUT")
    addon:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    addon.eventFrame:SetScript("OnEvent", function(self, event, ...)
        local handlers = addon.events[event]
    
        if not handlers then return end  
    
        for _, handlerName in ipairs(handlers) do
            local handler = addon[handlerName]  
            if type(handler) == "function" then
                handler(addon, ...)  
            else
                --print("Warning: Handler '" .. handlerName .. "' for event '" .. event .. "' is not a function.")
            end
        end
    end)
    
    addon.eventFrame:SetScript("OnUpdate", function(self, elapsed)
        elapsedTime = elapsedTime + elapsed

        if elapsedTime >= 1 then
            elapsedTime = 0
            addon:UpdateClock()
            --addon:updateContent_gold ()
            --addon.UI:UpdateNodesContent()
        end
    end)



--[[
        SLASH COMMANDS
]]

local function SlashHandler(msg, editbox)
    
    if msg == "" then
        
        print("|cff00ff00GrindPlus:|r ")
        print("- |cffffd700reset|r: reset session.")
        print("use the following commands to toggle the data on and off:")
        for _, node in ipairs(addon.nodes) do
            print("- |cffffd700" ..node .. "|r: now is " .. ( addon.nodeIsActive[node] and "|cff00ff00ON|r." or "|cffff0000OFF|r."))
        end

    elseif addon.nodeIsActive[msg] ~= nil then
        addon.nodeIsActive[msg] = not addon.nodeIsActive[msg]
        print("|cff00ff00GrindPlus:|r "..msg .. ": now is " .. ( addon.nodeIsActive[msg] and "|cff00ff00ON|r." or "|cffff0000OFF|r."))
        addon.UI:Refresh()

    elseif msg == "reset" then
        addon:Popup(LOCALIZATION_RESET_SESSION_CONFIRMATION_EN, function()
            addon:ResetSession()
        end)

    else
        print("Invalid command. Type |cff00ff00/grindplus|r for help.")

    end
end



SlashCmdList["GRINDPLUS"] = SlashHandler
SLASH_GRINDPLUS1 = "/grindplus"

