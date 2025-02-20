local addonName, addon = ...

local BULLETPOINT_ICON = "Interface\\QUESTFRAME\\UI-Quest-BulletPoint"

local node = {
    name = "gold"
}

addon:insertNode(node.name)
addon:RegisterEvent("ADDON_LOADED", node.name) 
addon:RegisterEvent("PLAYER_ENTERING_WORLD", node.name) 
addon:RegisterEvent("PLAYER_MONEY", node.name) 

--[[
    FUNCTIONS
]]

function addon:FormatMoney(amount)
    if not amount then return end
    local isNegative = amount < 0
    amount = math.abs(amount) -- Use absolute value for formatting

    local gold = math.floor(amount / (100 * 100))
    local silver = math.floor((amount % (100 * 100)) / 100)
    local copper = amount % 100

    local goldIcon = addon:setTexture ("Interface\\MoneyFrame\\UI-GoldIcon", 12)
    local silverIcon = addon:setTexture("Interface\\MoneyFrame\\UI-SilverIcon", 12)
    local copperIcon = addon:setTexture("Interface\\MoneyFrame\\UI-CopperIcon", 12)

    local result = ""

    if gold > 0 then
        result = result .. string.format("%d%s", gold, goldIcon)
    end
    if silver > 0 then
        result = result .. string.format("%d%s", silver, silverIcon)
    end
    if copper > 0 or result == "" then -- Always show copper if nothing else is shown
        result = result .. string.format("%d%s", copper, copperIcon)
    end

    if isNegative then
        result = "-" .. result -- Prepend negative sign
    end

    return result
end

function addon:SessionReset_gold()

    addon:insertNode(node.name)
    local money = GetMoney()
    
    addon.session[node.name] = addon.session[node.name] or {
        start = money,
        total = 0,
        earned = 0,
        spent = 0
    }
    addon:updateContent_gold ()
end

--[[
    EVENTS FUNCTIONS
]]

 function addon:PLAYER_MONEY_GOLD()
    
    local money = GetMoney()
    --if addon.session[node.name].start == 0 then addon.session[node.name].start = money end
    local amount = money - addon.session[node.name].start

    if amount == 0 then return end
    
    if amount > 0 then 
        addon.session[node.name].earned = addon.session[node.name].earned + amount
    else 
        addon.session[node.name].spent = addon.session[node.name].spent + math.abs(amount)
    end

    addon.session[node.name].total = addon.session[node.name].earned - addon.session[node.name].spent

    addon.session[node.name].start = money

    addon:updateContent_gold ()

end

function addon:ADDON_LOADED_GOLD(name)
    
    if name ~= addonName then return end
    
    --local money = GetMoney()
    
    addon.session[node.name] = addon.session[node.name] or {
        start = 0,
        total = 0,
        earned = 0,
        spent = 0
    }
    addon:updateContent_gold ()

end

function addon:PLAYER_ENTERING_WORLD_GOLD()
    local money = GetMoney()
    if addon.session[node.name].start == 0 then addon.session[node.name].start = money end
end


function addon:updateContent_gold ()
    local icon = addon:setTexture(BULLETPOINT_ICON)
    if not addon.session[node.name].earned or not addon.session[node.name].spent or not addon.session[node.name].start then return end
    
    addon.UI.toggleButton[node.name]:SetEnabled(true)

    local earned = addon.session[node.name].earned
    local spent = addon.session[node.name].spent
    local balance = earned - spent

    local uppercaseFirstTotal = node.name:sub(1, 1):upper() .. node.name:sub(2)
    local title = addon:FormatMoney(addon:GetAmountPerHour(balance))

    local titleString = string.format("%s/h: |cFFFFFFFF%s|r", uppercaseFirstTotal, title)

    local content = {}
    content[1] = string.format("%sTotal: |cFFFFD100%s|r", icon, addon:FormatMoney(balance)) 
    content[2] = string.format("%sEarned: |cFFFFD100%s|r", icon, addon:FormatMoney(earned)) 
    content[3] = string.format("%sSpent: |cFFFFD100%s|r", icon, addon:FormatMoney(spent)) 

    addon.titleText[node.name] = titleString

    addon.bodyText[node.name] =  {}

    for _, text in ipairs(content) do
        table.insert(addon.bodyText[node.name], {
        text = text,
        node = node.name
    })
    end

    addon.UI:UpdateNodesContent()
end
