POHSaved = POHSaved or {}
if not POHSaved.orders then
    POHSaved.orders = {}
end

local sessionOrders = {}

local function generateUniqueID(order)
    local data = tostring(order.expirationTime) .. tostring(order.itemID) .. tostring(order.orderID)
    --local data = tostring(order.orderID)
    local hash = 0
    for i = 1, #data do
        local char = string.byte(data, i)
        hash = (hash * 31 + char) % 2 ^ 32
    end
    local unique_id = string.format("%08x", hash)
    return unique_id
end

ProfessionsCrafterTableCellCustomHideMixin = CreateFromMixins(TableBuilderCellMixin)

local function setAlphaRow(order, value)
    order:GetParent():GetParent():SetAlpha(value)
end

local function updateOrderAlpha()
    local dataProvider = ProfessionsFrame.OrdersPage.BrowseFrame.OrderList.ScrollBox:GetDataProvider()
    local collection = dataProvider:GetCollection()
    for i = 1, #collection do
        local uniqID = (generateUniqueID(collection[i].option))
        if (POHSaved.orders[uniqID]) then
            setAlphaRow(_G["PublicOrdersCustomHideColumn" .. uniqID], 0.2)
        else
            setAlphaRow(_G["PublicOrdersCustomHideColumn" .. uniqID], 1.0)
        end
    end
end

local function updateOrderList()
    local dataProvider = ProfessionsFrame.OrdersPage.BrowseFrame.OrderList.ScrollBox:GetDataProvider()
    local dbswaps = {}

    local function swapOrders()
        local collection = dataProvider:GetCollection()
        for i = 1, #collection do
            local uniqID = (generateUniqueID(collection[i].option))
            if (POHSaved.orders[uniqID]) then
                if not dbswaps[uniqID] then
                    dbswaps[uniqID] = true
                    dataProvider:MoveElementDataToIndex(collection[i], #collection)
                    swapOrders()
                    return
                else
                    --
                end
            end
        end
    end

    --swapOrders()
    updateOrderAlpha()
end


local function resetOrderList()
    for k, v in pairs(sessionOrders) do
        _G["PublicOrdersCustomHideColumn" .. k]:Hide()
        setAlphaRow(_G["PublicOrdersCustomHideColumn" .. k], 1.0)
    end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", function()
    --hooksecurefunc(ProfessionsCrafterTableCellCommissionMixin, "Populate", function(self, rowData)
    --    local order = rowData.option;
    --    local hasRewards = order.npcOrderRewards and #order.npcOrderRewards > 0;
    --
    --    if hasRewards then
    --        for idx, reward in ipairs(order.npcOrderRewards) do
    --        	local _,_,_,_,_,_,_,_,_, itemTexture = C_Item.GetItemInfo(reward.itemLink)
    --            local texture = self:CreateTexture(nil, "BACKGROUND")
    --            texture:SetTexture(itemTexture)
    --            texture:SetSize(16, 16)
    --            texture:SetPoint("LEFT", self, "LEFT", -20 + ((idx-1) * 20), 0)
    --		end
    --
    --      end
    --  end)

    hooksecurefunc(ProfessionsCrafterTableCellExpirationMixin, "Populate", function(self, rowData)
        local isDebug = false
        local order = rowData.option
        local uniqID = (generateUniqueID(order))
        if (order.orderType == 3) then
            local remainingTime = Professions.GetCraftingOrderRemainingTime(order.expirationTime);
            local seconds = remainingTime >= 60 and remainingTime or 60; -- Never show < 1min
            local timeText = Professions.OrderTimeLeftFormatter:Format(seconds);
            if seconds <= Constants.ProfessionConsts.PUBLIC_CRAFTING_ORDER_STALE_THRESHOLD then
                timeText = ERROR_COLOR:WrapTextInColorCode(timeText);
            end

            ProfessionsTableCellTextMixin.SetText(self, isDebug and uniqID or timeText)
            self.Text:SetJustifyH("LEFT")
            self.Text:ClearAllPoints()
            self.Text:SetPoint("TOPLEFT", 0, 0)
            self.Text:SetPoint("BOTTOMRIGHT", -33, 0)

            local _, e = self.Text:GetPoint()
            if (not _G["PublicOrdersCustomHideColumn" .. uniqID]) then
                local checkBox = CreateFrame("CheckButton", "PublicOrdersCustomHideColumn" .. uniqID, e,
                    "ChatConfigCheckButtonTemplate")
                checkBox:SetChecked(POHSaved.orders[uniqID])
                checkBox:SetPoint("CENTER", e, "CENTER", 5, 0)
                checkBox:SetScript("OnClick", function()
                    POHSaved.orders[uniqID] = checkBox:GetChecked()
                    updateOrderList()
                end)
                sessionOrders[uniqID] = true

                checkBox:SetScript("OnEnter", function(self)
                    self:GetParent():GetParent():OnEnter()
                    if isDebug then
                        GameTooltip:SetOwner(checkBox, "ANCHOR_RIGHT")
                        GameTooltip:AddLine("OfferCID: " .. uniqID)
                        GameTooltip:Show()
                    end
                end)

                checkBox:SetScript("OnLeave", function(self)
                    self:GetParent():GetParent():OnLeave()
                    if isDebug then
                        GameTooltip:Hide()
                    end
                end)
            else
                _G["PublicOrdersCustomHideColumn" .. uniqID]:Show()
                _G["PublicOrdersCustomHideColumn" .. uniqID]:SetParent(e)
                _G["PublicOrdersCustomHideColumn" .. uniqID]:SetPoint("CENTER", e, "CENTER", 5, 0)
            end
        else
            if (_G["PublicOrdersCustomHideColumn" .. uniqID]) then
                _G["PublicOrdersCustomHideColumn" .. uniqID]:Hide()
                _G["PublicOrdersCustomHideColumn" .. uniqID]:SetParent(nil)
            end
        end
    end)

    ProfessionsFrame.OrdersPage:HookScript("OnHide", function()
        resetOrderList()
    end)

    hooksecurefunc(ProfessionsFrame.OrdersPage, "SendOrderRequest", function(self)
        resetOrderList()
    end)

    hooksecurefunc(ProfessionsFrame.OrdersPage, "ShowGeneric", function(self)
        if self.orderType == 3 then
            updateOrderList()
        else
            resetOrderList()
        end
    end)
end)
