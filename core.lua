POHSaved = POHSaved or {}
if not POHSaved.orders then
    POHSaved.orders = {}
end

local function generateUniqueID(expirationTime, itemID, orderID)
    local data = tostring(expirationTime) .. tostring(itemID) .. tostring(orderID)
    local hash = 0
    for i = 1, #data do
        local char = string.byte(data, i)
        hash = (hash * 31 + char) % 2 ^ 32
    end
    local unique_id = string.format("%08x", hash)
    return unique_id
end

ProfessionsCrafterTableCellCustomHideMixin = CreateFromMixins(TableBuilderCellMixin)

local function updateOrderAlpha()
    local dataProvider = ProfessionsFrame.OrdersPage.BrowseFrame.OrderList.ScrollBox:GetDataProvider()
    local collection = dataProvider:GetCollection()
    for i = 1, #collection do
        local uniqID = (generateUniqueID(collection[i].option.expirationTime, collection[i].option.itemID, collection[i].option.orderID))
        if (POHSaved.orders[uniqID]) then
            _G["PublicOrdersCustomHideColumn" .. uniqID]:GetParent():GetParent():SetAlpha(0.2)
        else
            _G["PublicOrdersCustomHideColumn" .. uniqID]:GetParent():GetParent():SetAlpha(1.0)
        end
    end
end

local function updateOrderList()
    local dataProvider = ProfessionsFrame.OrdersPage.BrowseFrame.OrderList.ScrollBox:GetDataProvider()
    local dbswaps = {}
    local function swapOrders()
        local collection = dataProvider:GetCollection()
        for i = 1, #collection do
            local uniqID = (generateUniqueID(collection[i].option.expirationTime, collection[i].option.itemID, collection[i].option.orderID))
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

    swapOrders()
    updateOrderAlpha()
end



EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", function()
    function ProfessionsCrafterTableCellCustomHideMixin:Populate(rowData, dataIndex)
        local order = rowData.option
        local uniqID = (generateUniqueID(order.expirationTime, order.itemID, order.orderID))

        ProfessionsTableCellTextMixin.SetText(self, "")

        local _, e = self.Text:GetPoint()
        if (not _G["PublicOrdersCustomHideColumn" .. uniqID]) then
            local checkBox = CreateFrame("CheckButton", "PublicOrdersCustomHideColumn" .. uniqID, e,
                "ChatConfigCheckButtonTemplate")
            checkBox:SetChecked(POHSaved.orders[uniqID])
            checkBox:SetPoint("CENTER", e, "CENTER", -10, 0)
            checkBox:SetScript("OnClick", function()
                POHSaved.orders[uniqID] = checkBox:GetChecked()
                updateOrderList()
            end)

            local isDebug = false
            if isDebug then
                checkBox:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(checkBox, "ANCHOR_RIGHT")
                    GameTooltip:AddLine("OfferCID: " .. uniqID)
                    GameTooltip:Show()
                end)

                checkBox:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        else
            _G["PublicOrdersCustomHideColumn" .. uniqID]:SetParent(e)
            _G["PublicOrdersCustomHideColumn" .. uniqID]:SetPoint("CENTER", e, "CENTER", -10, 0)
        end
    end

    hooksecurefunc(ProfessionsFrame.OrdersPage, "SetupTable", function(self)
        local PTC = ProfessionsTableConstants;
        if self.orderType == 3 then
            local column = self.tableBuilder:AddFixedWidthColumn(self, PTC.NoPadding, 60, PTC.Tip.LeftCellPadding,
                PTC.Tip.RightCellPadding, nil, "ProfessionsCrafterTableCellCustomHideTemplate")
            column:ConstructHeader("BUTTON", "ProfessionsCrafterTableHeaderStringTemplate", self, "Hide")
            self.tableBuilder:Arrange()
        end
    end)

    hooksecurefunc(ProfessionsFrame.OrdersPage, "ShowGeneric", function()
        updateOrderList()
    end)
end)
