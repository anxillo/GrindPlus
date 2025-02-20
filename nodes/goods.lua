local addonName, addon = ...

local ITEMLINK_MAX_LENGTH = 20

local node = {
    name = "goods"
}

addon:insertNode(node.name)

addon:RegisterEvent("ADDON_LOADED", node.name)
addon:RegisterEvent("CHAT_MSG_LOOT", node.name)

function addon:SessionReset_goods()

    addon:insertNode(node.name)

    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        goods = {}
    }

    addon:updateContent_goods()

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
    local isTradeGood = (classID == 7)
    local isQualityCommonOrAbove = (itemRarity >= 1) 
    return (isTradeGood) and isQualityCommonOrAbove
end

function addon:updateContent_goods()

    if not addon.session[node.name].total then return end

    local total = addon.session[node.name].total
    local title = ""
    title  = string.format("Trade goods total: |ccFFFFFFF%s|r",total)

    addon.titleText[node.name] = title
    addon.bodyText[node.name] =  {}

    for key, data in pairs(addon.session[node.name].goods) do
        local icon = addon:setTexture(data.icon)
        local ID = data.ID
        local rarity = data.itemRarity
        local total = data.total
        local itemPerHour = addon:GetAmountPerHour(total)

        local cleanItemLink = node:TruncateItemLink(data.itemLink, ITEMLINK_MAX_LENGTH)
        local totalStr = string.format("|cffffd700%s|r (%d/h)", total, itemPerHour)
        local content = string.format("%s %s: %s", icon or "?", cleanItemLink or "?", totalStr)

        

        table.insert(addon.bodyText[node.name], {
            text = content,
            node = node.name,
            ID = ID,
            rarity = rarity,
            total = total
        })
    end

        -- Sort the table by rarity and then by total (higher to lower)
        table.sort(addon.bodyText[node.name], function(a, b)
            if a.rarity == b.rarity then
                return a.total > b.total  -- Sort by number if classifications are the same
            else
                return a.rarity > b.rarity  -- Sort by classification first
            end
        end)

    addon.UI:UpdateNodesContent()

end

--[[
    EVENTS FUNCTIONS
]]

function addon:CHAT_MSG_LOOT_GOODS(...)
    
    local text = select(1, ...)
    local itemLink, quantity = node:GetLootString(text)
    local itemName,itemRarity, itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID = node:GetItemInformation(itemLink)


    --if worthy save to the database
    if itemLink and node:IsWorthy(itemRarity, classID, subclassID) then
        addon.session[node.name].total = addon.session[node.name].total + quantity

        if not addon.session[node.name].goods[itemName] then
            addon.session[node.name].goods[itemName] = {
                total = 0,
                ID = itemID,
                icon = icon,
                itemLink = itemLink,
                itemRarity = itemRarity
            }
        end

        addon.session[node.name].goods[itemName].total = addon.session[node.name].goods[itemName].total + quantity
        
        addon:updateContent_goods()

    end

end

function addon:ADDON_LOADED_GOODS(name)

    if name ~= addonName then return end
    addon.session[node.name] = addon.session[node.name] or {
        total = 0,
        goods = {}
    }

    addon:updateContent_goods()

end