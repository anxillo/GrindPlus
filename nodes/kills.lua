local addonName, addon = ...

local BULLETPOINT_ICON = "Interface\\QUESTFRAME\\UI-Quest-BulletPoint"
local ELITE_ICON = "Interface\\AddOns\\".. addonName .. "\\media\\gold.png"
local NORMAL_ICON = "Interface\\AddOns\\".. addonName .. "\\media\\silver.png"
local BOTH_ICON = "Interface\\AddOns\\".. addonName .. "\\media\\silvergold.png"
local BOSS_ICON = "Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull"

local node = {
    name = "kills",
    damagedEnemies = {},
    damagedEnemiesClassification = {}
}



addon:insertNode(node.name)

addon:RegisterEvent("ADDON_LOADED", node.name)
addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", node.name)

function addon:SessionReset_kills()

    addon:insertNode(node.name)

    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        kills = {}
    }

    addon:updateContent_kills()

end

function node:GetUnitClassification(unit)
    local classification = UnitClassification(unit)
    
    
    local classificationTable = {
        normal = 1,
        elite = 2,
        rare = 3,
        rareelite = 4,
        worldboss = 5,
    }


    return classificationTable[classification] or 0
end


function addon:updateContent_kills()

    if not addon.session[node.name].total then return end


    local total = addon.session[node.name].total
    local title = string.format("Kills total: |ccFFFFFFF%s|r",total)


    addon.titleText[node.name] = title
    addon.bodyText[node.name] =  {}

    for key, data in pairs(addon.session[node.name].kills) do

        local icon = addon:setTexture(BULLETPOINT_ICON)
        local classificationIconTable ={
            c1 = "",
            c2 = ELITE_ICON,
            c3 = NORMAL_ICON,
            c4 = BOTH_ICON,
            c5 = BOSS_ICON,
        }
        local classificationString = addon:setTexture(classificationIconTable["c" .. data.unitClassification])
        
        local content = string.format("%s%s: |cffffd700%d%s|r", icon, key,data.total, classificationString )
        
        table.insert(addon.bodyText[node.name], {
            classification = data.unitClassification,
            text = content,
            node = node.name,
            total = data.total
        })
    end

    -- Sort the table by classification (higher to lower)
    table.sort(addon.bodyText[node.name], function(a, b)
        if a.classification == b.classification then
            return a.total > b.total  -- Sort by number if classifications are the same
        else
            return a.classification > b.classification  -- Sort by classification first
        end
    end)




    addon.UI:UpdateNodesContent()

end




--[[
    EVENTS FUNCTIONS
]]

function addon:ADDON_LOADED_KILLS (name)

    if name ~= addonName then return end

    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        kills = {}
    }

    addon:updateContent_kills()
    
end

function addon:COMBAT_LOG_EVENT_UNFILTERED_KILLS()

    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    local timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, 
            sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
            spellID, spellName, spellSchool, amount = CombatLogGetCurrentEventInfo()
    
    if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then -- I m related to those subevents. 

        if subEvent == "SPELL_DAMAGE" or subEvent == "SWING_DAMAGE" or subEvent == "RANGED_DAMAGE" then
            
             node.damagedEnemies[destGUID] = true -- Mark as damaged by player
             
             if destGUID == UnitGUID("target") then

                node.damagedEnemiesClassification[destGUID] = node:GetUnitClassification("target")

             end
             
         end

    end

    if subEvent == "UNIT_DIED" and node.damagedEnemies[destGUID] then
        
        local unitClassification = node.damagedEnemiesClassification[destGUID] or 1

        addon.session[node.name].total = addon.session[node.name].total + 1

        if not addon.session[node.name].kills[destName] then
            addon.session[node.name].kills[destName] ={
                total = 0,
                unitClassification = unitClassification
            }  
        end

        addon.session[node.name].kills[destName].total = addon.session[node.name].kills[destName].total + 1

        node.damagedEnemies[destGUID] = nil -- Cleanup memory

        addon:updateContent_kills()

    end
end