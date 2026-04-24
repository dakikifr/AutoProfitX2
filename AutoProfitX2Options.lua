--[[
	AutoProfitX2 Options Panel
	Graphical configuration interface for AutoProfitX2 addon.
	Opened via /apx options
	Style based on KikiUtils options panel.
]]

-------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------
local PANEL_WIDTH = 700
local PANEL_HEIGHT = 520
local SIDEBAR_WIDTH = 140
local CONTENT_PADDING = 10
local ROW_HEIGHT = 34
local ICON_SIZE = 28
local SECTION_SPACING = 12
local CHECKBOX_SPACING = 28

-------------------------------------------------------------------
-- Local state
-------------------------------------------------------------------
local mainFrame = nil
local activeCategoryIndex = 1
local categoryPanels = {}
local categoryButtons = {}

-- Ignore list panel state
local ignoreListFrames = {}
local ignoreScrollChild = nil

-- Force sell list panel state
local forceSellListFrames = {}
local forceSellScrollChild = nil

-------------------------------------------------------------------
-- Forward declarations
-------------------------------------------------------------------
local RefreshIgnoreList, RefreshForceSellList

-------------------------------------------------------------------
-- Data access helpers
-------------------------------------------------------------------
local function GetDB()
	return AutoProfitX2 and AutoProfitX2.db or nil
end

local function GetCharSettings()
	local db = GetDB()
	return db and db.char or nil
end

local function GetExceptionList()
	local db = GetDB()
	if not db then return {} end
	local realm = GetRealmName()
	local name = UnitName("player")
	if db.global and db.global[realm] and db.global[realm][name] then
		return db.global[realm][name].exceptionList or {}
	end
	return {}
end

local function GetForceSellList()
	local db = GetDB()
	if not db then return {} end
	local realm = GetRealmName()
	local name = UnitName("player")
	if db.global and db.global[realm] and db.global[realm][name] then
		return db.global[realm][name].forceSellList or {}
	end
	return {}
end

local function SetExceptionList(list)
	local db = GetDB()
	if not db then return end
	local realm = GetRealmName()
	local name = UnitName("player")
	if db.global and db.global[realm] and db.global[realm][name] then
		db.global[realm][name].exceptionList = list
	end
end

local function SetForceSellList(list)
	local db = GetDB()
	if not db then return end
	local realm = GetRealmName()
	local name = UnitName("player")
	if db.global and db.global[realm] and db.global[realm][name] then
		db.global[realm][name].forceSellList = list
	end
end

local function AddToExceptionList(itemID)
	local list = GetExceptionList()
	list[tostring(itemID)] = true
	SetExceptionList(list)
end

local function RemoveFromExceptionList(itemID)
	local list = GetExceptionList()
	list[itemID] = nil
	list[tostring(itemID)] = nil
	SetExceptionList(list)
end

local function AddToForceSellList(itemID)
	local list = GetForceSellList()
	list[tostring(itemID)] = true
	SetForceSellList(list)
end

local function RemoveFromForceSellList(itemID)
	local list = GetForceSellList()
	list[itemID] = nil
	list[tostring(itemID)] = nil
	SetForceSellList(list)
end

-------------------------------------------------------------------
-- Item link / ID extraction (WoW 12.0+ compatible)
-------------------------------------------------------------------
-- Extracts item ID from an item link string (handles both old |cXXXXXXXX and new |cnIQx formats)
local function ExtractItemID(text)
	-- Try to extract from a full item link
	local id = string.match(text, "|Hitem:(%d+)")
	if id then return id end
	-- Try plain number
	if tonumber(text) then return text end
	return nil
end

-- Extracts the first item link from text (WoW 12.0+ compatible)
local function ExtractItemLink(text)
	-- Match new format: |cnIQx|Hitem:...|h[...]|h|r
	local link = string.match(text, "(|cnIQ%d|Hitem.-|h%[.-%]|h|r)")
	if link then return link end
	-- Match old format: |cXXXXXXXX|Hitem:...|h[...]|h|r
	link = string.match(text, "(|c%x+|Hitem.-|h%[.-%]|h|r)")
	if link then return link end
	return nil
end

-------------------------------------------------------------------
-- Handle item drop from cursor (drag & drop from bags/inventory)
-------------------------------------------------------------------
local function HandleItemDrop(editBox)
	local cursorType, itemID, itemLink = GetCursorInfo()
	if cursorType == "item" then
		-- itemID is the item ID, itemLink is the full link
		if itemLink then
			editBox:SetText(itemLink)
		elseif itemID then
			local _, link = GetItemInfo(itemID)
			if link then
				editBox:SetText(link)
			else
				editBox:SetText(tostring(itemID))
			end
		end
		ClearCursor()
		return true
	end
	return false
end

-------------------------------------------------------------------
-- UI Helper: Create a section header
-------------------------------------------------------------------
local function CreateSectionHeader(parent, text, yOffset)
	local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 10, yOffset)
	header:SetText(text)
	header:SetTextColor(1, 0.82, 0)

	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(0.6, 0.5, 0.2, 0.6)
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
	line:SetPoint("RIGHT", parent, "RIGHT", -10, 0)

	return header, yOffset - header:GetStringHeight() - 6
end

-------------------------------------------------------------------
-- UI Helper: Create a checkbox
-------------------------------------------------------------------
local function CreateCheckbox(parent, label, x, y, getValue, setValue)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", x, y)
	cb:SetSize(26, 26)

	local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
	text:SetText(label)
	cb.label = text

	cb:SetChecked(getValue())
	cb:SetScript("OnClick", function(self)
		setValue(self:GetChecked())
	end)

	return cb
end

-------------------------------------------------------------------
-- Create the main options frame
-------------------------------------------------------------------
local function CreateMainFrame()
	local f = CreateFrame("Frame", "AutoProfitX2OptionsFrame", UIParent, "BackdropTemplate")
	f:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	f:SetBackdropColor(0.05, 0.05, 0.1, 0.92)
	f:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetFrameStrata("DIALOG")
	f:SetFrameLevel(100)
	f:Hide()

	-- Title
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -12)
	title:SetText("AutoProfitX2 - Options")
	title:SetTextColor(1, 0.82, 0)

	-- Version
	local version = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	version:SetPoint("TOP", title, "BOTTOM", 0, -2)
	local ver = C_AddOns and C_AddOns.GetAddOnMetadata("AutoProfitX2", "Version") or "?"
	version:SetText("v" .. ver)
	version:SetTextColor(0.6, 0.6, 0.6)

	-- Close button
	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -2, -2)

	-- Escape to close
	tinsert(UISpecialFrames, "AutoProfitX2OptionsFrame")

	return f
end

-------------------------------------------------------------------
-- Create the sidebar
-------------------------------------------------------------------
local function CreateSidebar(parent)
	local sidebar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	sidebar:SetPoint("TOPLEFT", 8, -42)
	sidebar:SetPoint("BOTTOMLEFT", 8, 8)
	sidebar:SetWidth(SIDEBAR_WIDTH)
	sidebar:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	sidebar:SetBackdropColor(0.1, 0.1, 0.15, 0.7)
	sidebar:SetBackdropBorderColor(0.4, 0.35, 0.15, 0.8)

	local categories = { "General", "Ignore List", "Force Sell" }
	for i, catName in ipairs(categories) do
		local btn = CreateFrame("Button", nil, sidebar)
		btn:SetSize(SIDEBAR_WIDTH - 16, 32)
		btn:SetPoint("TOPLEFT", 8, -8 - (i - 1) * 36)

		local bg = btn:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.3, 0.25, 0.1, 0)
		btn.bg = bg

		local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("LEFT", 10, 0)
		text:SetText(catName)
		btn.text = text

		local hl = btn:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(0.4, 0.35, 0.15, 0.3)

		btn:SetScript("OnClick", function()
			activeCategoryIndex = i
			APX_Options_ShowCategory(i)
		end)

		categoryButtons[i] = btn
	end

	return sidebar
end

-------------------------------------------------------------------
-- Category button highlight
-------------------------------------------------------------------
local function UpdateCategoryHighlight()
	for i, btn in ipairs(categoryButtons) do
		if i == activeCategoryIndex then
			btn.bg:SetColorTexture(0.4, 0.35, 0.1, 0.6)
			btn.text:SetTextColor(1, 0.82, 0)
		else
			btn.bg:SetColorTexture(0, 0, 0, 0)
			btn.text:SetTextColor(1, 1, 1)
		end
	end
end

-------------------------------------------------------------------
-- Create the content area
-------------------------------------------------------------------
local function CreateContentArea(parent)
	local content = CreateFrame("Frame", nil, parent)
	content:SetPoint("TOPLEFT", SIDEBAR_WIDTH + 16, -42)
	content:SetPoint("BOTTOMRIGHT", -8, 8)
	return content
end

-------------------------------------------------------------------
-- GENERAL OPTIONS PANEL
-------------------------------------------------------------------
local function CreateGeneralPanel(parent)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel:Hide()

	local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)

	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(scrollFrame:GetWidth() or (PANEL_WIDTH - SIDEBAR_WIDTH - 60))

	panel:SetScript("OnShow", function()
		scrollChild:SetWidth(scrollFrame:GetWidth())
	end)

	local yPos = -10

	local _, newY = CreateSectionHeader(scrollChild, "Selling Options", yPos)
	yPos = newY - 4

	CreateCheckbox(scrollChild, "Auto Sell (sell junk when opening vendor)", 16, yPos,
		function()
			local cs = GetCharSettings(); return cs and cs.autoSell
		end,
		function(v)
			local cs = GetCharSettings()
			if not cs then return end
			local wantOn = v and true or false
			local isOn = cs.autoSell and true or false
			if wantOn ~= isOn then
				AutoProfitX2:ToggleAutoSell()
			end
		end
	)
	yPos = yPos - CHECKBOX_SPACING

	CreateCheckbox(scrollChild, "Sales Reports (print sold items in chat)", 16, yPos,
		function()
			local cs = GetCharSettings(); return cs and not cs.silent or false
		end,
		function(v)
			local cs = GetCharSettings(); if cs then cs.silent = not v end
		end
	)
	yPos = yPos - CHECKBOX_SPACING

	CreateCheckbox(scrollChild, "Show Profit (print total profit after sale)", 16, yPos,
		function()
			local cs = GetCharSettings(); return cs and cs.showTotal or false
		end,
		function(v)
			local cs = GetCharSettings(); if cs then cs.showTotal = v end
		end
	)
	yPos = yPos - CHECKBOX_SPACING

	yPos = yPos - SECTION_SPACING
	local _, newY2 = CreateSectionHeader(scrollChild, "Button", yPos)
	yPos = newY2 - 4

	-- Reset button position
	local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
	resetBtn:SetSize(180, 24)
	resetBtn:SetPoint("TOPLEFT", 16, yPos)
	resetBtn:SetText("Reset Button Position")
	resetBtn:SetScript("OnClick", function()
		AutoProfitX2:SetButtonPosition(-41, -37)
	end)
	yPos = yPos - 34

	scrollChild:SetHeight(math.abs(yPos) + 20)

	categoryPanels[1] = panel
	return panel
end

-------------------------------------------------------------------
-- ITEM LIST PANEL (shared for Ignore and Force Sell)
-------------------------------------------------------------------
local function CreateItemListPanel(parent, panelIndex, getListFunc, addFunc, removeFunc, listLabel, addHelpText)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetAllPoints()
	panel:Hide()

	local listFrames = {}
	local scrollChild = nil

	-- List header
	local header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 8, -8)
	header:SetText(listLabel)
	header:SetTextColor(0.9, 0.8, 0.5)

	-- Clear all button
	local clearBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	clearBtn:SetSize(80, 22)
	clearBtn:SetPoint("TOPRIGHT", -30, -6)
	clearBtn:SetText("Clear All")
	clearBtn:SetScript("OnClick", function()
		-- Confirm dialog
		StaticPopupDialogs["APX_CLEAR_LIST_" .. panelIndex] = {
			text = "Remove ALL items from this list?",
			button1 = "Yes",
			button2 = "No",
			OnAccept = function()
				local list = getListFunc()
				wipe(list)
				if panelIndex == 2 then
					RefreshIgnoreList()
				else
					RefreshForceSellList()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("APX_CLEAR_LIST_" .. panelIndex)
	end)

	-- Scroll frame for item list
	local listFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
	listFrame:SetPoint("TOPLEFT", 4, -28)
	listFrame:SetPoint("RIGHT", -4, 0)
	listFrame:SetHeight(310)
	listFrame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	listFrame:SetBackdropColor(0.08, 0.08, 0.12, 0.7)
	listFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.6)

	local listScroll = CreateFrame("ScrollFrame", "APX_ListScroll_" .. panelIndex, listFrame, "UIPanelScrollFrameTemplate")
	listScroll:SetPoint("TOPLEFT", 4, -4)
	listScroll:SetPoint("BOTTOMRIGHT", -24, 4)

	scrollChild = CreateFrame("Frame")
	listScroll:SetScrollChild(scrollChild)
	scrollChild:SetWidth(listScroll:GetWidth() or 400)
	scrollChild:SetHeight(1)

	-- Refresh function
	local function RefreshList()
		for _, row in ipairs(listFrames) do
			row:Hide()
			row:SetParent(nil)
		end
		wipe(listFrames)

		local items = getListFunc()
		local yPos = 0
		local idx = 0

		for itemID in pairs(items) do
			idx = idx + 1
			local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)

			local row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
			row:SetSize(scrollChild:GetWidth() - 4, ROW_HEIGHT)
			row:SetPoint("TOPLEFT", 2, -yPos)
			row:SetBackdrop({
				bgFile = "Interface/Tooltips/UI-Tooltip-Background",
				edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
				edgeSize = 10,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
			})
			row:SetBackdropColor(0.12, 0.12, 0.18, 0.6)
			row:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)

			-- Item icon
			local icon = row:CreateTexture(nil, "ARTWORK")
			icon:SetSize(ICON_SIZE, ICON_SIZE)
			icon:SetPoint("LEFT", 4, 0)
			icon:SetTexture(itemTexture or 134400)
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

			-- Item name
			local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
			nameText:SetPoint("RIGHT", row, "RIGHT", -36, 0)
			nameText:SetJustifyH("LEFT")
			nameText:SetWordWrap(false)

			if itemLink then
				-- Strip the color code to just show the colored name
				nameText:SetText(itemLink)
			elseif itemName then
				nameText:SetText(itemName)
			else
				nameText:SetText("Item #" .. tostring(itemID) .. " (loading...)")
				-- Request item info async
				local item = Item:CreateFromItemID(tonumber(itemID))
				if item then
					item:ContinueOnItemLoad(function()
						if panelIndex == 2 then
							RefreshIgnoreList()
						else
							RefreshForceSellList()
						end
					end)
				end
			end

			-- Delete button
			local delBtn = CreateFrame("Button", nil, row)
			delBtn:SetSize(22, 22)
			delBtn:SetPoint("RIGHT", -6, 0)
			delBtn:SetNormalTexture("Interface/Buttons/UI-GroupLoot-Pass-Up")
			delBtn:SetHighlightTexture("Interface/Buttons/UI-GroupLoot-Pass-Highlight")
			local capturedID = itemID
			delBtn:SetScript("OnClick", function()
				removeFunc(capturedID)
				if panelIndex == 2 then
					RefreshIgnoreList()
				else
					RefreshForceSellList()
				end
			end)
			delBtn:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText("Remove this item")
				GameTooltip:Show()
			end)
			delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

			-- Tooltip on hover
			row:EnableMouse(true)
			row:SetScript("OnEnter", function(self)
				self:SetBackdropColor(0.2, 0.2, 0.3, 0.8)
				local iid = tonumber(capturedID)
				if iid then
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
					GameTooltip:SetItemByID(iid)
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function(self)
				self:SetBackdropColor(0.12, 0.12, 0.18, 0.6)
				GameTooltip:Hide()
			end)

			listFrames[idx] = row
			yPos = yPos + ROW_HEIGHT + 2
		end

		scrollChild:SetHeight(math.max(yPos + 20, 100))
	end

	-- Fix scroll child width on show and refresh
	panel:SetScript("OnShow", function()
		C_Timer.After(0.01, function()
			scrollChild:SetWidth(listScroll:GetWidth())
			RefreshList()
		end)
	end)

	-- Add item section
	local addLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	addLabel:SetPoint("TOPLEFT", 8, -346)
	addLabel:SetText("Add Item:")
	addLabel:SetTextColor(0.9, 0.8, 0.5)

	-- Drop zone
	local dropZone = CreateFrame("Button", nil, panel, "BackdropTemplate")
	dropZone:SetPoint("TOPLEFT", 4, -364)
	dropZone:SetPoint("RIGHT", -4, 0)
	dropZone:SetHeight(40)
	dropZone:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	dropZone:SetBackdropColor(0.15, 0.2, 0.15, 0.5)
	dropZone:SetBackdropBorderColor(0.3, 0.5, 0.3, 0.7)

	local dropIcon = dropZone:CreateTexture(nil, "ARTWORK")
	dropIcon:SetSize(24, 24)
	dropIcon:SetPoint("LEFT", 10, 0)
	dropIcon:SetTexture("Interface/PaperDollInfoFrame/Character-Plus")

	local dropText = dropZone:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	dropText:SetPoint("LEFT", dropIcon, "RIGHT", 8, 0)
	dropText:SetText(addHelpText)
	dropText:SetTextColor(0.5, 0.9, 0.5)

	-- Edit box for typing item name/link
	local addEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
	addEditBox:SetSize(300, 22)
	addEditBox:SetPoint("TOPLEFT", 14, -410)
	addEditBox:SetAutoFocus(false)
	addEditBox:SetFontObject(GameFontHighlightSmall)

	local addInfoText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	addInfoText:SetPoint("LEFT", addEditBox, "RIGHT", 10, 0)
	addInfoText:SetText("Drag item here or type name/link, then press Enter or Add")
	addInfoText:SetTextColor(0.5, 0.5, 0.5)

	-- Add button
	local addBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	addBtn:SetSize(60, 22)
	addBtn:SetPoint("TOPLEFT", 14, -436)
	addBtn:SetText("Add")

	local function DoAddItem()
		local text = addEditBox:GetText()
		if not text or text == "" then return end

		-- Try to extract item ID from link
		local itemID = ExtractItemID(text)
		if itemID then
			addFunc(itemID)
			addEditBox:SetText("")
			RefreshList()
			if AutoProfitX2 then
				local _, link = GetItemInfo(itemID)
				if link then
					AutoProfitX2:Print("Added " .. link .. " to list.")
				else
					AutoProfitX2:Print("Added item #" .. itemID .. " to list.")
				end
			end
			return
		end

		-- Try as item name - search by name
		local _, link, _, _, _, _, _, _, _, _ = GetItemInfo(text)
		if link then
			itemID = ExtractItemID(link)
			if itemID then
				addFunc(itemID)
				addEditBox:SetText("")
				RefreshList()
				if AutoProfitX2 then
					AutoProfitX2:Print("Added " .. link .. " to list.")
				end
				return
			end
		end

		-- Item not found yet, might need server query
		if AutoProfitX2 then
			AutoProfitX2:Print("Item not found. Try dragging the item or using an item link.")
		end
	end

	addBtn:SetScript("OnClick", DoAddItem)
	addEditBox:SetScript("OnEnterPressed", function(self)
		DoAddItem()
		self:ClearFocus()
	end)
	addEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	-- Handle drop on the drop zone
	local function HandleDrop()
		local cursorType, itemID, itemLink = GetCursorInfo()
		if cursorType == "item" then
			local id = nil
			if itemLink then
				id = ExtractItemID(itemLink)
			end
			if not id and itemID then
				id = tonumber(itemID)
			end
			if id then
				addFunc(id)
				ClearCursor()
				RefreshList()
				if AutoProfitX2 then
					local _, link = GetItemInfo(id)
					if link then
						AutoProfitX2:Print("Added " .. link .. " to list.")
					end
				end
				return true
			end
			ClearCursor()
		end
		return false
	end

	dropZone:SetScript("OnClick", HandleDrop)
	dropZone:SetScript("OnReceiveDrag", HandleDrop)

	-- Also accept drop on edit box
	addEditBox:SetScript("OnReceiveDrag", function()
		HandleItemDrop(addEditBox)
	end)
	addEditBox:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			HandleItemDrop(self)
		end
	end)

	-- Hover effect on drop zone
	dropZone:SetScript("OnEnter", function(self)
		local cursorType = GetCursorInfo()
		if cursorType == "item" then
			self:SetBackdropColor(0.2, 0.4, 0.2, 0.8)
			self:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)
		end
	end)
	dropZone:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.15, 0.2, 0.15, 0.5)
		self:SetBackdropBorderColor(0.3, 0.5, 0.3, 0.7)
	end)

	categoryPanels[panelIndex] = panel

	return panel, RefreshList
end

-------------------------------------------------------------------
-- Show a specific category
-------------------------------------------------------------------
function APX_Options_ShowCategory(index)
	activeCategoryIndex = index
	UpdateCategoryHighlight()
	for i, panel in pairs(categoryPanels) do
		if i == index then
			panel:Show()
		else
			panel:Hide()
		end
	end
end

-------------------------------------------------------------------
-- Initialize and show options
-------------------------------------------------------------------
function APX_Options_Toggle()
	if mainFrame and mainFrame:IsShown() then
		mainFrame:Hide()
		return
	end

	if not mainFrame then
		mainFrame = CreateMainFrame()
		local sidebar = CreateSidebar(mainFrame)
		local content = CreateContentArea(mainFrame)

		CreateGeneralPanel(content)

		local _, refreshIgnore = CreateItemListPanel(content, 2,
			GetExceptionList,
			AddToExceptionList,
			RemoveFromExceptionList,
			"Ignored Items (never sell these):",
			"Drag & Drop an item here from your bags"
		)
		RefreshIgnoreList = refreshIgnore

		local _, refreshForce = CreateItemListPanel(content, 3,
			GetForceSellList,
			AddToForceSellList,
			RemoveFromForceSellList,
			"Force Sell Items (always sell these):",
			"Drag & Drop an item here from your bags"
		)
		RefreshForceSellList = refreshForce
	end

	mainFrame:Show()
	APX_Options_ShowCategory(activeCategoryIndex)
end
