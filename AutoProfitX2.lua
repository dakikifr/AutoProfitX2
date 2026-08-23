local L = LibStub("AceLocale-3.0"):GetLocale("AutoProfitX2")
local tooltip = LibStub("LibGratuity-3.0")
local charSettings, eList
local name = UnitName("player")
local realm = GetRealmName()
local level = UnitLevel("player")
local totalProfit = 0
-- WoW 12.0+ secret value safety
local issecretvalue = issecretvalue or function() return false end
--make proficiency table local (defined in proficiencies.lua)
local _, apx_CLASS = UnitClass("player")
local apx_class = LOCALIZED_CLASS_NAMES_MALE[apx_CLASS]
local prof = AutoProfitX2_Proficiencies[apx_CLASS] or {}
local infArmorProf = {}
AutoProfitX2_Proficiencies = nil
--default button position
local buttonY = -37
local buttonX = -41
local DEFAULT_SPIN_RATE = 0.6

AutoProfitX2 = LibStub("AceAddon-3.0"):NewAddon("AutoProfitX2", "AceConsole-3.0", "AceEvent-3.0")

-- Optims
local strformat = string.format
local strgmatch = string.gmatch
local strmatch = string.match

--some strings commonly used in addon
-- WoW 12.0+: item links now use |cnIQx instead of |cXXXXXXXX
local linkMatch = "|c[^|]+|Hitem.-|h%[.-%]|h|r"
local classMatch = strformat(ITEM_CLASSES_ALLOWED, "([%w, ]*)")

-- Event-driven selling state
local sellMasterList = {} -- persistent list: {link, id, bag, slot, sold, totalPrice}
local sellQueue = {}      -- indices into masterList for current pass
local sellQueueIndex = 0
local sellOnComplete = nil
local isSelling = false
local sellRetryCount = 0
local sellSafetyTimer = nil
local MAX_SELL_RETRIES = 5
local SELL_TIMEOUT = 0.2 -- seconds to wait for ITEM_LOCK_CHANGED before skipping
local SELL_DEBUG = false -- set to true to enable debug prints

--[[

local helper functions

--]]

--performs deep copy of a table
local function tdeepcopy(from)
	if type(from) == "table" then
		local t = {}
		for k, v in pairs(from) do
			if type(v) == "table" then
				t[k] = tdeepcopy(v)
			else
				t[k] = v
			end
		end
		return t
	end
	return from
end

--returns a formatted money string
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"

local function coppertogold(copper, showGold)
	local strValue = ""
	local val
	val = math.floor(copper / COPPER_PER_GOLD)
	copper = mod(copper, COPPER_PER_GOLD)
	if val > 0 or showGold then
		strValue = val .. GOLD_ICON .. " "
	end

	val = math.floor(copper / COPPER_PER_SILVER)
	copper = mod(copper, COPPER_PER_SILVER)
	if val > 0 or strValue ~= "" then
		strValue = strValue .. val .. SILVER_ICON .. " "
	end

	return strValue .. copper .. COPPER_ICON
end

--[[

Main APX functions

--]]

function AutoProfitX2:OnInitialize()
	local defaults = {
		char = {
			autoSell = false,
			silent = false,
			showTotal = true,
			buttonYpos = buttonY,
			buttonXpos = buttonX,
			checkSoulbound = false,
			checkInfArmor = false,
			buttonSpin = "3"
		},
		global = {
			[realm] = {
				[name] = {
					exceptionList = {},
					forceSellList = {}
				}
			}
		},
	};

	--register database
	self.db = LibStub("AceDB-3.0"):New("AutoProfitX2DB", defaults)

	--initialize charSettings variable
	charSettings = self.db.char

	--initialize eList variable
	eList = self.db.global[realm][name].exceptionList

	--register chat commands: /apx opens options directly
	self:RegisterChatCommand("apx", function() APX_Options_Toggle() end)
	self:RegisterChatCommand("AutoProfitX2", function() APX_Options_Toggle() end)

	-- Initialize force sell list if missing
	if not self.db.global[realm][name].forceSellList then
		self.db.global[realm][name].forceSellList = {}
	end

	-- Minimap button
	self:CreateMinimapButton()

	if level < 40 then
		infArmorProf = AutoProfitX2_InfArmorProficiencies_Sub40[apx_CLASS] or {}
	else
		infArmorProf = AutoProfitX2_InfArmorProficiencies_Over40[apx_CLASS] or {}
	end
end

function AutoProfitX2:OnEnable()
	--register events
	self:RegisterEvent("MERCHANT_SHOW", "OnMerchantShow")
end

--returns a table with all your characters that have used AutoProfitX2
function AutoProfitX2:GetCharList(info, value)
	local tbl = {}
	for rlm, charList in pairs(self.db.global) do
		for char in pairs(charList) do
			if char ~= name or rlm ~= realm then
				local n = char .. "@" .. rlm
				tbl[n] = n
			end
		end
	end

	return tbl
end

--add global exceptions
function AutoProfitX2:AddGlobal(info, exceptions)
	local itemID
	for link in strgmatch(exceptions, linkMatch) do
		itemID = self:GetID(link)
		if itemID then
			--add it to all exception lists
			for realm, charList in pairs(self.db.global) do
				for char, charSettings in pairs(charList) do
					charSettings.exceptionList[itemID] = true
				end
			end

			self:Print(L["Added LINK to exception list for all characters."](link))
		else
			self:Print(L["Invalid item link provided."])
		end
	end

	if AutoProfitX2_SellButton:IsVisible() then
		self:OnShowButton(AutoProfitX_SellButton)
	end
end

--rem exceptions globaly
function AutoProfitX2:RemGlobal(infos, exceptions)
	local itemID
	for link in strgmatch(exceptions, linkMatch) do
		itemID = self:GetID(link)
		if itemID then
			for realm, charList in pairs(self.db.global) do
				for char, charSettings in pairs(charList) do
					charSettings.exceptionList[itemID] = nil
				end
			end

			self:Print(L["Removed LINK from all exception lists."](link))
		else
			self:Print(L["Invalid item link provided."])
		end
	end

	if AutoProfitX2_SellButton:IsVisible() then
		self:OnShowButton(AutoProfitX_SellButton)
	end
end

--add/remve local exceptions
function AutoProfitX2:AddRemLocal(info, exceptions)
	local itemID

	for link in strgmatch(exceptions, linkMatch) do
		itemID = self:GetID(link)
		if itemID then
			if eList[itemID] then
				eList[itemID] = nil
				self:Print(L["Removed LINK from exception list."](link))
			else
				eList[itemID] = true
				self:Print(L["Added LINK to exception list."](link))
			end
		else
			self:Print(L["Invalid item link provided."])
		end
	end

	if AutoProfitX2_SellButton:IsVisible() then
		self:OnShowButton(AutoProfitX_SellButton)
	end
end

--display exception list
function AutoProfitX2:ListExceptions()
	local link
	local dispHeader = true

	for i in pairs(eList) do
		if dispHeader then
			self:Print(L["Exceptions:"])
			dispHeader = false
		end

		_, link = GetItemInfo(i)
		if link then
			self:Print(link)
		end
	end

	if dispHeader then
		self:Print(L["Your exception list is empty."])
	end
end

--toggle auto sell
function AutoProfitX2:ToggleAutoSell()
	charSettings.autoSell = not charSettings.autoSell
	if charSettings.autoSell then
		self:RegisterEvent("MERCHANT_SHOW", "OnMerchantShow")
		AutoProfitX2_SellButton:Hide()
	else
		self:UnregisterEvent("MERCHANT_SHOW")
		AutoProfitX2_SellButton:Show()
	end
end

--purge exception list
function AutoProfitX2:PurgeExceptionList()
	eList = {}
	self.db.global[realm][name].exceptionList = eList
	self:Print(L["Deleted all exceptions."])
end

--import exception list
--fromChar must be a string with name@realm
function AutoProfitX2:ImportExceptionList(info, fromChar)
	local iName, iRealm = strsplit("@", fromChar)
	if iName then
		if self.db.global[iRealm] and self.db.global[iRealm][iName] and self.db.global[iRealm][iName].exceptionList then
			eList = tdeepcopy(self.db.global[iRealm][iName].exceptionList)
			self.db.global[realm][name].exceptionList = eList
			self:Print(L["Exception list imported from NAME on REALM."](iName, iRealm))
		else
			self:Print(L["Exception list could not be found for NAME on REALM."](iName, iRealm))
		end
		return
	end
end

--MERCHANT_SHOW event handler
function AutoProfitX2:OnMerchantShow()
	if charSettings.autoSell then
		-- Small delay to ensure MerchantFrame is fully visible
		C_Timer.After(0.1, function()
			if not MerchantFrame:IsVisible() then return end
			local profit = self:GetProfit()
			local hasProfit = (not issecretvalue(profit)) and (profit > 0)
			if hasProfit then
				self:SellJunk(function(actualProfit)
					if charSettings.showTotal and actualProfit and actualProfit > 0 then
						self:Print("|cFF00FF00" .. L["Total profits: PROFIT"]("|r" .. coppertogold(actualProfit)))
					end
				end)
			end
		end)
	else
		--register BAG_UPDATE event for updating button
		self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
		self:RegisterEvent("MERCHANT_CLOSED", "OnMerchantClosed")
	end
end

--MERCHANT_CLOSED event handler
function AutoProfitX2:OnMerchantClosed()
	self:UnregisterEvent("MERCHANT_CLOSED")
	self:UnregisterEvent("BAG_UPDATE")
	self:StopSelling()
end

--BAG_UPDATE event handler
function AutoProfitX2:OnBagUpdate(this)
	--update icon
	if AutoProfitX2_SellButton:IsVisible() then
		self:OnShowButton(this)
	end
end

--returns itemID of the item when provided with an item link
function AutoProfitX2:GetID(link)
	return strmatch(link, "item:(%d+)")
end

--sells junk items with retry verification
-- onComplete: optional callback fired after all items are verified sold (or max retries reached)
function AutoProfitX2:SellJunk(onComplete)
	if not (MerchantFrame:IsVisible() and MerchantFrame.selectedTab == 1) then return end

	-- Build master list: scan all bags for junk
	wipe(sellMasterList)
	for bag = 0, 5 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local link = C_Container.GetContainerItemLink(bag, slot)
			if link then
				local junk, itemSellPrice = self:IsJunk(link, bag, slot)
				if junk then
					if itemSellPrice == 0 then
						if not charSettings.silent then
							self:Print(L["Item LINK is junk, but cannot be sold."](link))
						end
					else
						local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
						local count = itemInfo and itemInfo.stackCount or 1
						if issecretvalue(count) then count = 1 end
						tinsert(sellMasterList,
							{ link = link, bag = bag, slot = slot, sold = false, totalPrice = itemSellPrice * count })
					end
				end
			end
		end
	end

	if #sellMasterList == 0 then return end

	sellRetryCount = 0
	self:SellPass(onComplete)
end

--runs one sell pass on unsold items from the master list
function AutoProfitX2:SellPass(onComplete)
	if SELL_DEBUG then self:Print("|cFFAAAAFF[Debug] SellPass: retry #" .. sellRetryCount .. "|r") end
	if not (MerchantFrame:IsVisible() and MerchantFrame.selectedTab == 1) then
		self:StopSelling()
		if onComplete then onComplete() end
		return
	end

	-- Build queue of unsold item indices
	wipe(sellQueue)
	for i, entry in ipairs(sellMasterList) do
		if not entry.sold then
			tinsert(sellQueue, i)
		end
	end

	if #sellQueue == 0 then
		-- All sold
		self:FinishSelling(onComplete)
		return
	end

	sellQueueIndex = 0
	sellOnComplete = onComplete
	isSelling = true
	self:RegisterEvent("ITEM_LOCK_CHANGED", "OnSellItemLockChanged")
	self:SellNextItem()
end

--sells the next item in the current pass queue
function AutoProfitX2:SellNextItem()
	if sellSafetyTimer then
		sellSafetyTimer:Cancel()
		sellSafetyTimer = nil
	end

	if not MerchantFrame:IsVisible() then
		self:StopSelling()
		return
	end

	sellQueueIndex = sellQueueIndex + 1
	if sellQueueIndex > #sellQueue then
		-- Current pass finished: mark sold items and verify
		local cb = sellOnComplete
		self:StopSelling()
		self:VerifyAndRetry(cb)
		return
	end

	local entry = sellMasterList[sellQueue[sellQueueIndex]]
	if not entry then
		self:SellNextItem()
		return
	end
	C_Container.UseContainerItem(entry.bag, entry.slot)

	-- Safety timer: skip to next if ITEM_LOCK_CHANGED doesn't fire
	local expectedQueueIndex = sellQueueIndex
	sellSafetyTimer = C_Timer.NewTimer(SELL_TIMEOUT, function()
		sellSafetyTimer = nil
		if isSelling and sellQueueIndex == expectedQueueIndex then
			self:SellNextItem()
		end
	end)
end

--ITEM_LOCK_CHANGED handler
function AutoProfitX2:OnSellItemLockChanged(_, bag, slot)
	if not isSelling then return end
	local masterIdx = sellQueue[sellQueueIndex]
	if not masterIdx then return end
	local entry = sellMasterList[masterIdx]
	if not entry then return end
	if entry and bag == entry.bag and slot == entry.slot then
		if SELL_DEBUG then self:Print("|cFFAAAAFF[Debug] ITEM_LOCK_CHANGED: " .. entry.link .. "|r") end
		if sellSafetyTimer then
			sellSafetyTimer:Cancel()
			sellSafetyTimer = nil
		end
		self:SellNextItem()
	end
end

--after a pass, wait for BAG_UPDATE_DELAYED then re-scan bags to find unsold items
function AutoProfitX2:VerifyAndRetry(onComplete)
	if SELL_DEBUG then
		local soldCount, unsoldCount = 0, 0
		for _, e in ipairs(sellMasterList) do if e.sold then soldCount = soldCount + 1 else unsoldCount = unsoldCount + 1 end end
		self:Print("|cFFAAAAFF[Debug] VerifyAndRetry: sold=" ..
			soldCount .. " unsold=" .. unsoldCount .. " retryCount=" .. sellRetryCount .. "|r")
	end
	if not (MerchantFrame:IsVisible() and MerchantFrame.selectedTab == 1) then
		self:FinishSelling(onComplete)
		return
	end

	-- Wait for BAG_UPDATE_DELAYED so bag contents are up-to-date before re-scanning
	-- Safety timer in case BAG_UPDATE_DELAYED doesn't fire (e.g., all sells failed)
	sellOnComplete = onComplete
	self:RegisterEvent("BAG_UPDATE_DELAYED", "OnVerifyBagUpdateDelayed")
	sellSafetyTimer = C_Timer.NewTimer(1.0, function()
		sellSafetyTimer = nil
		if SELL_DEBUG then AutoProfitX2:Print("|cFFAAAAFF[Debug] VerifyAndRetry safety timer fired|r") end
		AutoProfitX2:OnVerifyBagUpdateDelayed()
	end)
end

--BAG_UPDATE_DELAYED handler for verify step
function AutoProfitX2:OnVerifyBagUpdateDelayed()
	pcall(function() self:UnregisterEvent("BAG_UPDATE_DELAYED") end)
	if sellSafetyTimer then
		sellSafetyTimer:Cancel()
		sellSafetyTimer = nil
	end
	if SELL_DEBUG then self:Print("|cFFAAAAFF[Debug] OnVerifyBagUpdateDelayed fired|r") end
	local cb = sellOnComplete
	if not (MerchantFrame:IsVisible() and MerchantFrame.selectedTab == 1) then
		self:FinishSelling(cb)
		return
	end
	self:RescanAndRetry(cb)
end

--re-scans bags after BAG_UPDATE_DELAYED and retries selling unsold items
function AutoProfitX2:RescanAndRetry(onComplete)
	-- Clear bag/slot for unsold entries
	for _, entry in ipairs(sellMasterList) do
		if not entry.sold then
			entry.bag = nil
			entry.slot = nil
		end
	end

	-- Build lookup of unsold entries by item ID
	local unsoldByID = {}
	for i, entry in ipairs(sellMasterList) do
		if not entry.sold then
			local id = self:GetID(entry.link)
			if id then
				unsoldByID[id] = unsoldByID[id] or {}
				tinsert(unsoldByID[id], i)
			end
		end
	end

	-- Scan bags to relocate unsold items
	for bag = 0, 5 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local link = C_Container.GetContainerItemLink(bag, slot)
			if link then
				local id = self:GetID(link)
				if id and unsoldByID[id] and #unsoldByID[id] > 0 then
					local masterIdx = tremove(unsoldByID[id], 1)
					sellMasterList[masterIdx].bag = bag
					sellMasterList[masterIdx].slot = slot
				end
			end
		end
	end

	-- Items not found in bags anymore were actually sold
	for _, entry in ipairs(sellMasterList) do
		if not entry.sold and not entry.bag then
			entry.sold = true
		end
	end

	-- Check if any unsold items still have a bag slot (need retry)
	local hasUnsold = false
	local unsoldCount = 0
	for _, entry in ipairs(sellMasterList) do
		if not entry.sold then
			hasUnsold = true
			unsoldCount = unsoldCount + 1
		end
	end

	if SELL_DEBUG then self:Print("|cFFAAAAFF[Debug] RescanAndRetry: " .. unsoldCount .. " items still unsold|r") end

	if not hasUnsold then
		self:FinishSelling(onComplete)
		return
	end

	-- Check retry limit before re-selling
	sellRetryCount = sellRetryCount + 1
	if sellRetryCount >= MAX_SELL_RETRIES then
		if SELL_DEBUG then self:Print("|cFFAAAAFF[Debug] Max retries reached, finishing|r") end
		self:FinishSelling(onComplete)
		return
	end

	-- Retry selling unsold items
	self:SellPass(onComplete)
end

--prints the sell summary and calls onComplete
function AutoProfitX2:FinishSelling(onComplete)
	local actualProfit = 0
	if not charSettings.silent then
		for _, entry in ipairs(sellMasterList) do
			if entry.sold then
				self:Print(L["Sold LINK."](entry.link))
			end
		end
	end
	for _, entry in ipairs(sellMasterList) do
		if entry.sold then
			actualProfit = actualProfit + (entry.totalPrice or 0)
		end
	end
	wipe(sellMasterList)
	if onComplete then onComplete(actualProfit) end
end

--stops the current selling pass and cleans up event/timer state
function AutoProfitX2:StopSelling()
	isSelling = false
	sellOnComplete = nil
	sellQueueIndex = 0
	if sellSafetyTimer then
		sellSafetyTimer:Cancel()
		sellSafetyTimer = nil
	end
	if self.UnregisterEvent then
		pcall(function() self:UnregisterEvent("ITEM_LOCK_CHANGED") end)
		pcall(function() self:UnregisterEvent("BAG_UPDATE_DELAYED") end)
	end
end

--returns true if item is junk
function AutoProfitX2:IsJunk(link, bag, slot)
	local _, _, quality, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(link)
	-- WoW 12.0+: itemSellPrice and quality may be secret values
	if itemSellPrice and issecretvalue(itemSellPrice) then
		itemSellPrice = 0
	end
	if quality and issecretvalue(quality) then
		quality = 1 -- treat as non-junk when secret
	end
	local id = self:GetID(link)

	-- Force sell list: always sell regardless of quality
	local forceSellList = self.db.global[realm] and self.db.global[realm][name] and
			self.db.global[realm][name].forceSellList or {}
	if forceSellList[id] then
		return true, itemSellPrice
	end

	if eList[id] then
		-- in the exception/ignore list: never sell
		return false, itemSellPrice
	end

	-- Not in the list, return true if it's poor quality
	if quality == 0 then
		return true, itemSellPrice
	end

	--Not poor quality, check if it's usable
	--[[if charSettings.checkSoulbound and bag and slot and not self:IsUsable(bag,slot,link) then
		return true, itemSellPrice
	end]]

	return false, itemSellPrice
end

--returns false if a soulbound item cannot be used by player class
function AutoProfitX2:IsUsable(bag, slot, link)
	--if it's not soulbound then you can always use it
	tooltip:SetBagItem(bag, slot)
	if not tooltip:Find(ITEM_SOULBOUND) then
		return true
	end

	--check if item has class requirement
	local _, _, classes = tooltip:Find(classMatch)
	if classes then
		local found = false
		classes = { strsplit(L["LIST_SEPARATOR"], classes) }
		for _, c in ipairs(classes) do
			if apx_class == c then
				found = true
			end
		end
		if not found then
			--class not in the list so you can't use it
			return false
		end
	end

	--check if class can ever use this item
	local _, _, _, _, _, iType, iSubType, _, iEquipLoc = GetItemInfo(link)
	local tbl = prof[iType]
	if tbl and (tbl[iSubType] or (tbl.noOffhand and iEquipLoc == "INVTYPE_WEAPONOFFHAND")) then
		return false
	end

	--seems usable
	return true
end

--returns the sum of all junk item sell prices
function AutoProfitX2:GetProfit()
	totalProfit = 0
	if MerchantFrame:IsVisible() then
		local bagSlots, link
		for bag = 0, 5 do
			bagSlots = C_Container.GetContainerNumSlots(bag)
			if bagSlots > 0 then
				for slot = 1, bagSlots do
					link = C_Container.GetContainerItemLink(bag, slot)
					if link then
						local junk, itemSellPrice = AutoProfitX2:IsJunk(link, bag, slot)
						if junk and itemSellPrice ~= 0 then
							local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
							local count = itemInfo and itemInfo.stackCount or 1
							if issecretvalue(count) then count = 1 end
							totalProfit = totalProfit + count * itemSellPrice
						end
					end
				end
			end
		end
	end
	return totalProfit
end

--[[

Minimap button (supports round, square, and hybrid minimap shapes)

]]

do
	-- Minimap shape table (from LibDBIcon-1.0) - true = round in that quadrant
	local minimapShapes = {
		["ROUND"]                 = { true, true, true, true },
		["SQUARE"]                = { false, false, false, false },
		["CORNER-TOPLEFT"]        = { false, false, false, true },
		["CORNER-TOPRIGHT"]       = { false, false, true, false },
		["CORNER-BOTTOMLEFT"]     = { false, true, false, false },
		["CORNER-BOTTOMRIGHT"]    = { true, false, false, false },
		["SIDE-LEFT"]             = { false, true, false, true },
		["SIDE-RIGHT"]            = { true, false, true, false },
		["SIDE-TOP"]              = { false, false, true, true },
		["SIDE-BOTTOM"]           = { true, true, false, false },
		["TRICORNER-TOPLEFT"]     = { false, true, true, true },
		["TRICORNER-TOPRIGHT"]    = { true, false, true, true },
		["TRICORNER-BOTTOMLEFT"]  = { true, true, false, true },
		["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
	}

	local rad, cos, sin, sqrt, max, min = math.rad, math.cos, math.sin, math.sqrt, math.max, math.min
	local deg, atan2 = math.deg, math.atan2
	local BUTTON_RADIUS = 5

	local function UpdateButtonPosition(button, position)
		local angle = rad(position or 225)
		local x, y, q = cos(angle), sin(angle), 1
		if x < 0 then q = q + 1 end
		if y > 0 then q = q + 2 end
		local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
		local quadTable = minimapShapes[minimapShape] or minimapShapes["ROUND"]
		local w = (Minimap:GetWidth() / 2) + BUTTON_RADIUS
		local h = (Minimap:GetHeight() / 2) + BUTTON_RADIUS
		if quadTable[q] then
			-- Round quadrant: position on circle
			x, y = x * w, y * h
		else
			-- Square quadrant: clamp to rectangle edge
			local diagW = sqrt(2 * (w) ^ 2) - 10
			local diagH = sqrt(2 * (h) ^ 2) - 10
			x = max(-w, min(x * diagW, w))
			y = max(-h, min(y * diagH, h))
		end
		button:ClearAllPoints()
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end

	function AutoProfitX2:CreateMinimapButton()
		-- Saved position (angle around minimap)
		if not self.db.char.minimapPos then
			self.db.char.minimapPos = 220
		end

		local btn = CreateFrame("Button", "AutoProfitX2_MinimapButton", Minimap)
		btn:SetSize(33, 33)
		btn:SetFrameStrata("MEDIUM")
		btn:SetFrameLevel(8)
		btn:SetClampedToScreen(true)
		btn:SetMovable(true)
		btn:RegisterForDrag("RightButton")
		btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

		-- Background circle
		local overlay = btn:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		overlay:SetPoint("TOPLEFT")

		local bg = btn:CreateTexture(nil, "BACKGROUND")
		bg:SetSize(25, 25)
		bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
		bg:SetPoint("TOPLEFT", 2, -4)

		-- Coin icon (same as the sell button)
		local icon = btn:CreateTexture(nil, "ARTWORK")
		icon:SetSize(21, 21)
		icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
		icon:SetPoint("CENTER", 0, -1)

		-- Drag handlers
		local isDragging = false
		btn:SetScript("OnDragStart", function(self)
			isDragging = true
			self:LockHighlight()
			GameTooltip:Hide()
			self:SetScript("OnUpdate", function(self)
				local mx, my = Minimap:GetCenter()
				local px, py = GetCursorPosition()
				local scale = Minimap:GetEffectiveScale()
				px, py = px / scale, py / scale
				local pos = deg(atan2(py - my, px - mx)) % 360
				AutoProfitX2.db.char.minimapPos = pos
				UpdateButtonPosition(self, pos)
			end)
		end)
		btn:SetScript("OnDragStop", function(self)
			isDragging = false
			self:SetScript("OnUpdate", nil)
			self:UnlockHighlight()
		end)

		-- Click to open options
		btn:SetScript("OnClick", function()
			APX_Options_Toggle()
		end)

		-- Tooltip
		btn:SetScript("OnEnter", function(self)
			if isDragging then return end
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText("AutoProfitX2")
			GameTooltip:AddLine("Click to open options", 1, 1, 1)
			GameTooltip:AddLine("Right-click drag to move", 0.7, 0.7, 0.7)
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		UpdateButtonPosition(btn, self.db.char.minimapPos)

		-- Re-position after UI is fully loaded (custom minimap addons may resize late)
		local reposFrame = CreateFrame("Frame")
		reposFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		reposFrame:SetScript("OnEvent", function(f)
			f:UnregisterAllEvents()
			C_Timer.After(0.5, function()
				UpdateButtonPosition(btn, AutoProfitX2.db.char.minimapPos)
			end)
		end)

		-- Apply hide setting
		if self.db.char.hideMinimapButton then
			btn:Hide()
		end

		-- Store reference for toggling
		self.minimapButton = btn
	end
end

--[[

Button functions

]]

--drags button APX button
function AutoProfitX2:DragButton()
	--farthest right and left positions on the merchant frame (relative to merchant frame)
	local MAX_RIGHT = -41
	local MAX_LEFT = -280
	local detatch = false
	local scale = MerchantFrame:GetEffectiveScale()
	local cursorOffset = 1
	--current cursor x coordinate
	local xpos, ypos = GetCursorPosition()
	xpos = xpos / scale
	ypos = ypos / scale
	--merchant fame position (right border of frame)
	local mwpos = MerchantFrame:GetRight()

	if IsShiftKeyDown() or charSettings.buttonXpos > MAX_RIGHT or charSettings.buttonXpos < MAX_LEFT or charSettings.buttonYpos ~= buttonY then
		detatch = true
	end

	--cursor x offset from merchant frame's right border
	xpos = xpos - mwpos - cursorOffset

	--if detatched, set y position
	--otherwise check if x is in bounds
	if detatch then
		local mwypos = MerchantFrame:GetTop()
		ypos = ypos - mwypos - cursorOffset
	else
		--check if cursor is not outside the topbar of merchant frame
		if xpos > MAX_RIGHT then
			xpos = MAX_RIGHT
		elseif xpos < MAX_LEFT then
			xpos = MAX_LEFT
		end
		ypos = nil
	end

	--position button
	self:SetButtonPosition(xpos, ypos)
end

function AutoProfitX2:OnEnterButton(this)
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:SetText(L["Sell Junk Items"])
	local profit = self:GetProfit()
	--spin button if on mouse-over is selected
	if charSettings.buttonSpin == "2" then
		self:ButtonSpin()
	end
	-- WoW 12.0+: profit might still be secret if GetItemInfo behaves unexpectedly
	local profitIsSecret = issecretvalue(profit)
	local hasProfit = (not profitIsSecret) and (profit > 0)
	if hasProfit then
		--spin button if on mouse-over and profit is selected
		if charSettings.buttonSpin == "1" then
			self:ButtonSpin()
		end
		-- WoW 12.0+: Do NOT use SetTooltipMoney(GameTooltip, ...) from addon code.
		-- It permanently taints GameTooltip's internal MoneyFrame, causing
		-- "secret number tainted by AutoProfitX2" errors on all future item tooltips.
		GameTooltip:AddLine(coppertogold(profit, true), 1.0, 1.0, 1.0)
	else
		GameTooltip:AddLine(L["You have no junk items in your inventory."], 1.0, 1.0, 1.0, 1)
	end
	GameTooltip:Show()
end

function AutoProfitX2:OnLeaveButton()
	GameTooltip:Hide()
	if charSettings.buttonSpin ~= "3" then
		self:ButtonStopSpin()
	end
end

function AutoProfitX2:OnClickButton()
	local profit = self:GetProfit()
	local profitIsSecret = issecretvalue(profit)
	if (not profitIsSecret) and profit > 0 then
		GameTooltip:Hide()
		self:SellJunk(function(actualProfit)
			if charSettings.showTotal and actualProfit and actualProfit > 0 then
				self:Print("|cFF00FF00" .. L["Total profits: PROFIT"]("|r" .. coppertogold(actualProfit)))
			end
		end)
		if charSettings.buttonSpin ~= "2" then
			self:ButtonStopSpin()
		end
	end
end

function AutoProfitX2:OnShowButton(this)
	if charSettings.autoSell then
		this:Hide()
	end
	local profit = self:GetProfit()
	local hasProfit = (not issecretvalue(profit)) and (profit > 0)
	if charSettings.buttonSpin == "3" and hasProfit then
		self:ButtonSpin()
	end
	if hasProfit then
		AutoProfitX2_SellButton_TreasureModel:SetAlpha(1)
	else
		AutoProfitX2_SellButton_TreasureModel:SetAlpha(0.2)
	end
end

function AutoProfitX2:SetButtonPosition(buttonXpos, buttonYpos)
	buttonXpos = tonumber(buttonXpos)
	buttonYpos = tonumber(buttonYpos)

	if buttonXpos then
		charSettings.buttonXpos = buttonXpos
	end

	if buttonYpos then
		charSettings.buttonYpos = buttonYpos
	end

	AutoProfitX2_SellButton:SetPoint("TOPRIGHT", "MerchantFrame", "TOPRIGHT", charSettings.buttonXpos,
		charSettings.buttonYpos)
end

function AutoProfitX2:ButtonSpin(spinRate)
	spinRate = tonumber(spinRate)
	if not spinRate then
		spinRate = DEFAULT_SPIN_RATE
	end

	AutoProfitX2_SellButton_TreasureModel.rotRate = spinRate
end

function AutoProfitX2:ButtonStopSpin()
	AutoProfitX2_SellButton_TreasureModel.rotRate = 0
end

--[[

Temporary features

--]]
--updates the exception list from pre 2.0 APX
function AutoProfitX2:UpdateExceptionLists()
	if AutoProfitX2_Settings then
		for realm, charList in pairs(AutoProfitX2_Settings) do
			for char, settings in pairs(charList) do
				for itemID in pairs(settings.ExceptionList) do
					if tonumber(itemID) then
						if not self.db.global[realm] then
							self.db.global[realm] = { [char] = { exceptionList = { [itemID] = true } } }
						elseif not self.db.global[realm][char] then
							self.db.global[realm][char] = { exceptionList = { [itemID] = true } }
						else
							self.db.global[realm][char].exceptionList[itemID] = true
						end
					end
				end
			end
		end
	end
	--get rid of old variables
	AutoProfitX2_Settings = nil
	AutoProfitX2_ExceptionlistVersion = nil

	self:Print(L["Exceptions updated."])
end
