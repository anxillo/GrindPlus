local addonName, addon = ...

local UI = {}

addon.UI = UI

UI.nodeIsVisible = {}

local MAIN_FRAME_WIDTH = 220
local NODE_TITLE_HEIGHT = 18
local MAX_VISIBLE_ROWS = 6
local ELEMENT_HEIGHT = 16

--[[local NODE_BUTTON_TEXTURE_EXPAND_NORMAL = "Interface\\AddOns\\".. addonName .. "\\media\\minus-up.png"
local NODE_BUTTON_TEXTURE_EXPAND_PUSHED = "Interface\\AddOns\\".. addonName .. "\\media\\minus-down.png"
local NODE_BUTTON_TEXTURE_COLLAPSE_NORMAL = "Interface\\AddOns\\".. addonName .. "\\media\\plus-up.png"
local NODE_BUTTON_TEXTURE_COLLAPSE_PUSHED = "Interface\\AddOns\\".. addonName .. "\\media\\plus-down.png" ]]

local NODE_BUTTON_TEXTURE_EXPAND_NORMAL = "Interface\\Buttons\\UI-PlusButton-Up"
local NODE_BUTTON_TEXTURE_EXPAND_PUSHED = "Interface\\Buttons\\UI-PlusButton-Down"
local NODE_BUTTON_TEXTURE_COLLAPSE_NORMAL = "Interface\\Buttons\\UI-MinusButton-Up"
local NODE_BUTTON_TEXTURE_COLLAPSE_PUSHED = "Interface\\Buttons\\UI-MinusButton-Down"
local LOCALIZATION_RESET_SESSION_CONFIRMATION_EN = "Do you want to reset the session?\nTimer and data will be reset"



--[[
        FUNCTIONS
]]

function UI:UpdateZoneText(zone)
    UI.zoneString:SetText(zone)
end 

function addon:setTexture (ID, size, xOffset, yOffset)
    if not ID then 
        local empty = ""
        return empty
    end
    local size = size or 16
    local xOffset = xOffset or 1
    local yOffset = yOffset or 0
    local textureString = "|T" .. ID .. ":" .. size .. ":" .. size .. ":".. xOffset ..":".. yOffset .."|t "
    return textureString
end

function addon:showGameTooltip(button, ID)
    --GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        --GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetItemByID(ID) -- Replace with your item ID
        --GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)             
end

function addon:Popup(text, OnAccept, OnCancel, button1, button2)
    local text = text or CONFIRM_CONTINUE
    local button1 = button1 or YES
    local button2 = button2 or NO
    
    StaticPopupDialogs["GrindPlus_RESET_SESSION"] = {
        text = text,
        button1 = button1,
        button2 = button2,
        OnAccept = function()
            if OnAccept then
                OnAccept()  -- Call the provided OnAccept callback
            end
        end,
        OnCancel = function()
            if OnCancel then
                OnCancel()  -- Call the provided OnCancel callback
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }
    StaticPopup_Show("GrindPlus_RESET_SESSION")
end

--[[
        NODES UI
]]

function UI:ToggleNode(node)

    UI.nodeIsVisible[node] = UI.nodeIsVisible[node] or false
    
    local visible = UI.nodeIsVisible[node]

    if visible then
        UI.toggleButton[node]:SetNormalTexture(NODE_BUTTON_TEXTURE_EXPAND_NORMAL)
        UI.toggleButton[node]:SetPushedTexture(NODE_BUTTON_TEXTURE_EXPAND_PUSHED)
        UI.scrollBox[node] :Hide()
        UI.nodeIsVisible[node] = false
    else
        UI.toggleButton[node]:SetNormalTexture(NODE_BUTTON_TEXTURE_COLLAPSE_NORMAL)
        UI.toggleButton[node]:SetPushedTexture(NODE_BUTTON_TEXTURE_COLLAPSE_PUSHED)
        UI.scrollBox[node] :Show()
        UI.nodeIsVisible[node] = true
    end
    UI:Refresh()
end

function UI:UpdateNodesContent()
    local nodes = addon.nodes

    for _, node in ipairs(nodes) do

        UI.titleString[node]:SetText(addon.titleText[node])

        --content
        if not addon.bodyText[node] then return end

        --flush old data 
        if UI.dataProvider[node] then
            UI.dataProvider[node]:Flush()
        end
        
        for _, data in pairs(addon.bodyText[node]) do
            UI.dataProvider[node]:Insert(data)
        end
    end
    UI:Refresh()

end

function UI:InitializeNodes()

    UI.titleFrame = {}
    UI.toggleButton = {}
    UI.titleString = {}
    UI.scrollBox = {}
    UI.scrollBar = {}
    UI.dataProvider = {}
    UI.scrollView ={}
    
    UI.titleFrameTexture = {}
    local nodes = addon.nodes
   
    local nodesWidth = UI.nodesFrame:GetWidth()
    local titleHeight = NODE_TITLE_HEIGHT

    local offsetY = 0
    

    for _, node in ipairs(nodes) do

        local title = node:sub(1, 1):upper() .. node:sub(2) .. ": "

        -- TitleFrame
        UI.titleFrame[node] = CreateFrame("Frame","titleFrame_".. node, UI.nodesFrame)
        UI.titleFrame[node]:SetSize(nodesWidth-10, titleHeight)

        UI.titleFrameTexture[node] = UI.titleFrame[node]:CreateTexture(nil, "BACKGROUND")
        UI.titleFrameTexture[node]:SetAllPoints(UI.titleFrame[node])
        UI.titleFrameTexture[node]:SetColorTexture(0, 0, 0, 0.25)

        UI.titleFrame[node]:SetPoint("TOPLEFT", UI.nodesFrame, "TOPLEFT", 0, -offsetY)
        offsetY = offsetY + NODE_TITLE_HEIGHT + 5  -- Adjust spacing
        UI.titleFrame[node]:Hide()

        -- ToggleButton
        UI.toggleButton[node] = CreateFrame("Button", "ToggleButton_" .. node, UI.titleFrame[node], "GrindPlusToggleButtonTemplate")
        UI.toggleButton[node]:SetPoint("TOPLEFT", UI.titleFrame[node], "TOPLEFT")
        UI.toggleButton[node]:SetEnabled(false)
        UI.toggleButton[node]:SetScript("OnClick", function(self) UI:ToggleNode(node) end)

        -- Title String
        UI.titleString[node] = UI.titleFrame[node]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        UI.titleString[node]:SetPoint("TOPLEFT", UI.toggleButton[node], "TOPRIGHT", 3, -3)
        UI.titleString[node]:SetText(title)

        -- Scrollbox
        UI.scrollBox[node] = CreateFrame("Frame", "ScrollBox" .. node, UI.nodesFrame, "WowScrollBoxList")
        UI.scrollBox[node]:SetPoint("TOP", UI.titleFrame[node], "BOTTOM")
        UI.scrollBox[node]:SetSize(nodesWidth-10, 100)
        UI.scrollBox[node]:Hide()

        -- Scrollbar
        UI.scrollBar[node] = CreateFrame("EventFrame", nil, UIParent, "MinimalScrollBar")
        UI.scrollBar[node]:SetPoint("TOPLEFT", UI.scrollBox[node], "TOPRIGHT", -5, -3)
        UI.scrollBar[node]:SetPoint("BOTTOMLEFT", UI.scrollBox[node], "BOTTOMRIGHT", -5, 3)
        --UI.scrollBar[node]:SetHideIfUnscrollable(true)
        UI.scrollBar[node]:Hide()

        -- Setup Scrolling

        --[[
                LIST INITIALIZER FUNCTION
        ]]
        local function ScrollViewInit(button, elementData)
            local bodyText = elementData.text
            --local bodyText = string.sub(elementData.text .. "...", 1, MAX_BODY_CHARACTER_LENGHT)
            button.bodyText:SetText(bodyText)
            if elementData.ID then
                addon:showGameTooltip(button, elementData.ID)
            end
        end

        UI.dataProvider[node] = CreateDataProvider()

        UI.scrollView[node] = CreateScrollBoxListLinearView()
        UI.scrollView[node]:SetDataProvider(UI.dataProvider[node])
        UI.scrollView[node]:SetElementInitializer("GrindPlusNodeBodyTemplate", ScrollViewInit)

        ScrollUtil.InitScrollBoxListWithScrollBar(UI.scrollBox[node], UI.scrollBar[node], UI.scrollView[node])

    end
    
end

function UI:Refresh()

    local previousElement = UI.nodesFrame
    --local nodesFrameHeight = 0
    local nodes = addon.nodes
    

    --check if scrollbar is needed before show. 
    local function ShowScrollBar(node)
        local bodyRows = UI.dataProvider[node]:GetSize()
        if bodyRows >= MAX_VISIBLE_ROWS+1 then
            UI.scrollBar[node]:Show()
        else
            UI.scrollBar[node]:Hide()
        end
    end

    local function ResizeScrollBox(node)
        local bodyRows = UI.dataProvider[node]:GetSize()
        if bodyRows > MAX_VISIBLE_ROWS then 
            bodyRows = MAX_VISIBLE_ROWS
        end
        local scrollBoxHeight = ELEMENT_HEIGHT * bodyRows
        UI.scrollBox[node]:SetHeight(scrollBoxHeight)
    end

    for _, node in ipairs(nodes) do

        local isActive = addon.nodeIsActive[node]
        local isVisible = UI.nodeIsVisible[node]
        local hasBody = not UI.dataProvider[node]:IsEmpty()
        local isNotNew = addon.session[node] and addon.session[node].total ~= 0 or false
        
        if isActive and isNotNew then

            UI.titleFrame[node]:Show()

            if hasBody then
                UI.toggleButton[node]:SetEnabled(true)
            else
                UI.toggleButton[node]:SetEnabled(false)
            end

            if previousElement == UI.nodesFrame then
                UI.titleFrame[node]:SetPoint("TOPLEFT", previousElement, "TOPLEFT", 0, -2)
            else
                UI.titleFrame[node]:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0 , -2)
            end
            
            if not isVisible  then
                --UI.toggleButton[node]:SetEnabled(false)
                UI.scrollBox[node]:Hide()
                UI.scrollBar[node]:Hide()
                previousElement = UI.titleFrame[node]
            else
                --UI.toggleButton[node]:SetEnabled(true)
                ResizeScrollBox(node)
                UI.scrollBox[node]:Show()
                --UI.scrollBar[node]:Show()
                ShowScrollBar(node)
                previousElement = UI.scrollBox[node]
            end

        else 
            UI.titleFrame[node]:Hide()
            UI.scrollBox[node]:Hide()
            UI.scrollBar[node]:Hide()
        
        end
   
    end

end

--[[
        MAIN UI 
]]



-- Main Frame

UI.mainFrame = CreateFrame("Frame", "MainFrame", UIParent)
UI.mainFrame:SetSize(MAIN_FRAME_WIDTH, 200)
UI.mainFrame:SetPoint("CENTER", UIParent, "CENTER")
UI.mainFrame:SetMovable(true)
UI.mainFrame:EnableMouse(true)
UI.mainFrame:RegisterForDrag("LeftButton")
UI.mainFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
UI.mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)



-- Zone String

UI.zoneString = UI.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
UI.zoneString:SetPoint("TOPLEFT", UI.mainFrame, "TOPLEFT" ,5 , -5)
UI.zoneString:SetText("Unknown")

-- Clock Frame 

UI.clockFrame = CreateFrame("Frame","clockFrame", UI.mainFrame, "BackdropTemplate" )
UI.clockFrame:SetSize(MAIN_FRAME_WIDTH -10, 40)
UI.clockFrame:SetPoint("TOPLEFT", UI.zoneString, "BOTTOMLEFT", 0, -5)
UI.clockFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

-- clock string

UI.clockString = UI.clockFrame:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Large")
UI.clockString:SetPoint("CENTER", UI.clockFrame, "CENTER")
UI.clockString:SetText("00:00:00")

-- A nodes frame inside mainFrame to hold node elements

UI.nodesFrame = CreateFrame("Frame", "NodesFrame", UI.mainFrame)
UI.nodesFrame:SetPoint("TOPLEFT", UI.clockFrame, "BOTTOMLEFT", 0, 0)
UI.nodesFrame:SetSize(MAIN_FRAME_WIDTH , 300)


-- Reset Button

UI.resetButton = CreateFrame("Button", "ResetButton_", UI.mainFrame, "GrindPlusResetButtonTemplate")
UI.resetButton:SetPoint("TOPRIGHT", UI.mainFrame, "TOPRIGHT", -5, 0)
UI.resetButton:SetScript("OnClick", function(self)
    addon:Popup(LOCALIZATION_RESET_SESSION_CONFIRMATION_EN, function()
        addon:ResetSession()
    end)
end)




