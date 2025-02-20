local addonName, addon = ...

local ITEMLINK_MAX_LENGTH = 25

local node = {
    name = "loot"
}

addon:insertNode(node.name)

addon:RegisterEvent("ADDON_LOADED", node.name)
addon:RegisterEvent("CHAT_MSG_LOOT", node.name)

function addon:SessionReset_loot()

    addon:insertNode(node.name)

    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        loot = {}
    }

    addon:updateContent_loot()

end

function node:GetLootString(msg)
    if type(msg) ~= "string" or msg == "" then
        return nil, nil  -- Prevent errors on invalid input
    end
    local multiPattern = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    local singlePattern = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
    local itemLink, quantity = msg:match(multiPattern)
    if itemLink and quantity then
        return itemLink, tonumber(quantity)
    end
    itemLink = msg:match(singlePattern)
    if itemLink then
        return itemLink, 1 
    end
    return nil, nil
end

function node:TruncateItemLink(itemLink, maxLength)
    return itemLink:gsub("(|Hitem:[^|]+|h)%[([^%]]+)%](|h)", function(startTag, itemName, endTag)
        if #itemName > maxLength then
            return startTag .. itemName:sub(1, maxLength) .. " ..." .. endTag
        else
            return startTag .. itemName .. endTag
        end
    end)
end



-- GetItemInformation: request item info based on itemLink
-- return itemName, itemRarity, itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
function node:GetItemInformation(itemLink)

    if not itemLink or type(itemLink) ~= "string" then
        --print("Invalid itemLink")
        return nil
    end

    local colorToRarity = {
        ["9d9d9d"] = 0,    -- Gray
        ["ffffff"] = 1,    -- Common (White)
        ["1eff00"] = 2,    -- Uncommon (Green)
        ["0070dd"] = 3,    -- Rare (Blue)
        ["a335ee"] = 4,    -- Epic (Purple)
        ["ff8000"] = 5     -- Legendary (Orange)
    }
    local item = string.match(itemLink, "item:(%d+)")
    local itemName = string.match(itemLink, "%[(.-)%]")
    local colorCode = string.match(itemLink, "|c%x%x(%x%x%x%x%x%x)")
    local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = GetItemInfoInstant(item)
    local itemRarity = colorToRarity[colorCode:sub(1, 6):lower()] or 0
    return itemName,itemRarity, itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID

end

-- IsWorthy: check if item is worthy to be saved in the list
-- worthy: green or more recipe, weapon or armor
-- need value, ID and ClassId
function node:IsWorthy(itemRarity, classID, subclassID)
    local isWeapon = (classID == 2)
    local isArmor = (classID == 4)
    local isRecipe = (classID == 9)
    local isQualityUncommonOrAbove = (itemRarity >= 2) -- should be >= 2 but 0 for test purposes
    return (isWeapon or isArmor or isRecipe) and isQualityUncommonOrAbove
end

function addon:updateContent_loot()

    if not addon.session[node.name].total then return end

    local total = addon.session[node.name].total
    local title = ""
    local dropRate = 0
    local totalKills = 0
    
    if not addon.session["kills"] or not addon.session["kills"].total then
        title  = string.format("Loot total: |ccFFFFFFF%s|r",total)
    else
        totalKills = addon.session["kills"].total or 0
        dropRate = (totalKills > 0) and ((total / totalKills) * 100) or 0
        title  = string.format("Loot total: |ccFFFFFFF%s (%.2f%%) |r",total, dropRate)
    end

    addon.titleText[node.name] = title
    addon.bodyText[node.name] =  {}

    for key, data in pairs(addon.session[node.name].loot) do
        local icon = addon:setTexture(data.icon)
        local ID = data.ID
        local rarity = data.itemRarity

        --local cleanItemLink = data.itemLink and data.itemLink:gsub("[%[%]]", "") or "?" 
        local cleanItemLink = node:TruncateItemLink(data.itemLink, ITEMLINK_MAX_LENGTH)
        local totalStr = data.total and data.total > 1 and string.format("(%d)", data.total) or ""
        local content = string.format("%s %s %s", icon or "?", cleanItemLink or "?", totalStr)

        

        table.insert(addon.bodyText[node.name], {
            text = content,
            node = node.name,
            ID = ID,
            rarity = rarity,
        })
    end

    -- sort table by rarity
    table.sort(addon.bodyText[node.name], function(a, b)
        return a.rarity > b.rarity
    end)

    addon.UI:UpdateNodesContent()

end

--[[
    EVENTS FUNCTIONS
]]

function addon:CHAT_MSG_LOOT_LOOT(...)
    
    local text = select(1, ...)
    local itemLink = node:GetLootString(text)
    local itemName,itemRarity, itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = node:GetItemInformation(itemLink)

    --if worthy save to the database
    if itemLink and node:IsWorthy(itemRarity, classID, subclassID) then
        addon.session[node.name].total = addon.session[node.name].total + 1

        if not addon.session[node.name].loot[itemName] then
            addon.session[node.name].loot[itemName] = {
                total = 0,
                ID = itemID,
                icon = icon,
                itemLink = itemLink,
                itemRarity = itemRarity
            }
        end

        addon.session[node.name].loot[itemName].total = addon.session[node.name].loot[itemName].total + 1
        
        --addon:updateContent_loot()

    end
    addon:updateContent_loot()
end

function addon:ADDON_LOADED_LOOT(name)

    if name ~= addonName then return end
    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        loot = {}
    }

    addon:updateContent_loot()

end