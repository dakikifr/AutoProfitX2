--[[
	AutoProfitX2 - saved item ID migrations

	Blizzard sometimes *replaces* items instead of editing them in place. When
	that happens the item IDs we saved in the exception / force sell lists stop
	resolving for good: GetItemInfo() keeps returning nil, Item:CreateFromItemID()
	never fires its callback, and the options panel stays stuck on
	"Item #<id> (loading...)".

	Patch 12.1 (Midnight, 2026-08-11) did exactly that to housing dyes: the 62
	per-color dyes were removed and every stack the player owned was mailed back
	as one of the 9 new per-family "Housing Dye" items. The Teal family was
	retired entirely, its colors split between Blue and Green.

	The table below maps every removed item to its replacement. It is applied on
	every load and is idempotent (a replacement ID is never a key), so it also
	repairs lists restored from a backup or copied over from another account.
--]]

-- Patch 12.1 replacement dyes
local DYE_BLACK  = 274464
local DYE_BLUE   = 274468
local DYE_BROWN  = 274469
local DYE_GREEN  = 274470
local DYE_ORANGE = 274471
local DYE_PURPLE = 274472
local DYE_RED    = 274473
local DYE_WHITE  = 274474
local DYE_YELLOW = 274475

local MIGRATIONS = {
	--[[ Patch 12.1: per-color housing dyes -> per-family Housing Dyes ]]
	[258838] = DYE_YELLOW, -- Gold Dye
	[259053] = DYE_BROWN,  -- Warm Teak Dye
	[259078] = DYE_WHITE,  -- Basic Birch Dye
	[259096] = DYE_BROWN,  -- Mesquite Brown Dye
	[259097] = DYE_YELLOW, -- Pinewood Dye
	[259098] = DYE_BLACK,  -- Darkwood Dye
	[259099] = DYE_WHITE,  -- Highland Birch Dye
	[259100] = DYE_YELLOW, -- Holy Oak Tan Dye
	[259101] = DYE_BROWN,  -- Pale Umber Dye
	[259102] = DYE_RED,    -- Mahogany Dye
	[259103] = DYE_BROWN,  -- Heartwood Dye
	[259104] = DYE_BLACK,  -- Stormsteel Dye
	[259105] = DYE_ORANGE, -- Copper Dye
	[259106] = DYE_YELLOW, -- Zandalari Gold Dye
	[259107] = DYE_YELLOW, -- Brass Dye
	[259108] = DYE_ORANGE, -- Bronze Dye
	[259109] = DYE_BLACK,  -- Dark Iron Dye
	[259110] = DYE_BLUE,   -- Kul Tiran Steel Dye (Teal family retired)
	[259111] = DYE_BLACK,  -- Ironclaw Dye
	[259112] = DYE_BROWN,  -- Dark Gold Dye
	[259113] = DYE_RED,    -- Horde Red Dye
	[259114] = DYE_GREEN,  -- Lush Green Dye
	[259115] = DYE_BLUE,   -- Alliance Blue Dye
	[259116] = DYE_PURPLE, -- Kirin Tor Violet Dye
	[259117] = DYE_YELLOW, -- Sandfury Yellow Dye
	[259118] = DYE_ORANGE, -- Elwynn Pumpkin Dye
	[259119] = DYE_PURPLE, -- Netherstorm Fuchsia Dye
	[259120] = DYE_WHITE,  -- Bone-White Dye
	[259121] = DYE_BLACK,  -- Obsidium Black Dye
	[259122] = DYE_BROWN,  -- Earthen Brown Dye
	[259123] = DYE_BLACK,  -- Stormheim Grey Dye
	[259124] = DYE_GREEN,  -- Silversage Green Dye
	[259125] = DYE_GREEN,  -- Un'Goro Green Dye (Teal family retired)
	[259126] = DYE_PURPLE, -- Void Violet Dye
	[259127] = DYE_RED,    -- Firebloom Red Dye
	[259128] = DYE_BROWN,  -- Kalimdor Sand Dye
	[259129] = DYE_BLUE,   -- Zephras Blue Dye
	[259130] = DYE_PURPLE, -- Nightsong Lilac Dye
	[259131] = DYE_PURPLE, -- Arcwine Dye
	[259132] = DYE_ORANGE, -- Kodohide Brown Dye
	[259133] = DYE_GREEN,  -- Dustwallow Green Dye
	[259134] = DYE_GREEN,  -- Emerald Dreaming Dye
	[259135] = DYE_BLUE,   -- Midnight Blue Dye
	[259136] = DYE_BLUE,   -- Vortex Teal Dye (Teal family retired)
	[259137] = DYE_YELLOW, -- Sungrass Yellow Dye
	[259138] = DYE_YELLOW, -- Savannah Gold Dye
	[259139] = DYE_RED,    -- Gilnean Rose Dye
	[259140] = DYE_PURPLE, -- Moonberry Amethyst Dye
	[259141] = DYE_BROWN,  -- Vol'dun Taupe Dye
	[259142] = DYE_RED,    -- Ratchet Rust Dye
	[259143] = DYE_GREEN,  -- Gravemoss Green Dye
	[259144] = DYE_PURPLE, -- Forsaken Plum Dye
	[259145] = DYE_BROWN,  -- Timbermaw Brown Dye
	[259146] = DYE_BLUE,   -- Nazjatar Navy Dye
	[259147] = DYE_GREEN,  -- Grizzly Hills Green Dye
	[259148] = DYE_BLUE,   -- Tidesage Teal Dye (Teal family retired)
	[259149] = DYE_WHITE,  -- Highborne Marble Dye
	[259150] = DYE_GREEN,  -- Earthroot Dye
	[259151] = DYE_RED,    -- Deep Mageroyal Red Dye
	[259152] = DYE_RED,    -- Hinterlands Hickory Dye
	[259153] = DYE_BLUE,   -- Dusk Lily Grey Dye
	[259154] = DYE_RED,    -- Rain Poppy Red Dye
	[262628] = DYE_BLUE,   -- Teal Dye Pigment (Teal family retired)
}

--replaces every retired item ID of a list by its replacement, returns how many were converted
--list keys are item IDs stored as strings, several old IDs can collapse onto the same new one
local function MigrateList(list)
	if type(list) ~= "table" then return 0 end

	local replacements, converted = nil, 0
	for key in pairs(list) do
		local id = tonumber(key)
		local newID = id and MIGRATIONS[id]
		if newID then
			list[key] = nil
			replacements = replacements or {}
			replacements[tostring(newID)] = true
			converted = converted + 1
		end
	end

	--only add the new keys once the traversal is over
	if replacements then
		for key in pairs(replacements) do
			list[key] = true
		end
	end

	return converted
end

--migrates the lists of every character on every realm, returns how many entries were converted
function AutoProfitX2_MigrateItemIDs(db)
	if type(db) ~= "table" or type(db.global) ~= "table" then return 0 end

	local converted = 0
	for _, characters in pairs(db.global) do
		if type(characters) == "table" then
			for _, data in pairs(characters) do
				if type(data) == "table" then
					converted = converted + MigrateList(data.exceptionList)
					converted = converted + MigrateList(data.forceSellList)
				end
			end
		end
	end

	return converted
end
