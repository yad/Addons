local MAJOR, MINOR = "LibQuestItem-1.0", 100000 + tonumber(("$Revision: 1$"):match("(%d+)"))
local LibQuestItem = LibStub:NewLibrary(MAJOR, MINOR)

if not LibQuestItem then return end -- no need to update

LibQuestItem.callbacks = LibQuestItem.callbacks or LibStub("CallbackHandler-1.0"):New(LibQuestItem)
local callbacks = LibQuestItem.callbacks

-- -----
-- local upvalues
-- -----
local _G = getfenv(0)

local ipairs				= _G.ipairs
--local next					= _G.next
local pairs					= _G.pairs
local select				= _G.select
--local time					= _G.time
local tonumber				= _G.tonumber
local tostring				= _G.tostring
--local type					= _G.type

local GetContaineritemId			= _G.GetContaineritemId
local GetContainerNumSlots			= _G.GetContainerNumSlots
local GetInventoryitemId			= _G.GetInventoryitemId
local GetInventorySlotInfo			= _G.GetInventorySlotInfo
local GetItemInfo					= _G.GetItemInfo

--local strfind				= _G.string.find
local strformat				= _G.string.format
--local strgmatch				= _G.string.gmatch
--local strmatch				= _G.string.match
local strlen				= _G.string.len

--local table_concat			= _G.table.concat
--local table_insert			= _G.table.insert
--local table_remove			= _G.table.remove
--local table_sort			= _G.table.sort


-- -----
-- lib variables
-- -----
LibQuestItem.frame = LibQuestItem.frame	or CreateFrame("Frame", "LibQuestItem10Frame") -- our event frame

-- -----
-- localization
-- -----
local LOCALE_QUEST = select(12, GetAuctionItemClasses()) or "Quest"

-- -----
-- local helpers
-- -----
local PATTERN_itemid = "item:(%-?%d+):%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+"
local PATTERN_itemlink = "|c%x+|H"..PATTERN_itemid.."|h%[.-%]|h|r"
local FORMAT_itemid = "item:%d:0:0:0:0:0:0:0"
--local FORMAT_itemlink = "|Hitem:%d:0:0:0:0:0:0:0|h"

local questItems = {}
local usableQuestItems = {}
local startsQuestItems = {}
local activeQuestItems = {}

local bagIds = {
	KEYRING_CONTAINER,
	0, 1, 2, 3, 4
}

local inventorySlots = {
	(GetInventorySlotInfo("HeadSlot")),
	(GetInventorySlotInfo("NeckSlot")),
	(GetInventorySlotInfo("ShoulderSlot")),
	(GetInventorySlotInfo("BackSlot")),
	(GetInventorySlotInfo("ChestSlot")),
	(GetInventorySlotInfo("ShirtSlot")),
	(GetInventorySlotInfo("TabardSlot")),
	(GetInventorySlotInfo("WristSlot")),
	(GetInventorySlotInfo("HandsSlot")),
	(GetInventorySlotInfo("WaistSlot")),
	(GetInventorySlotInfo("LegsSlot")),
	(GetInventorySlotInfo("FeetSlot")),
	(GetInventorySlotInfo("Finger0Slot")),
	(GetInventorySlotInfo("Finger1Slot")),
	(GetInventorySlotInfo("Trinket0Slot")),
	(GetInventorySlotInfo("Trinket1Slot")),
	(GetInventorySlotInfo("MainHandSlot")),
	(GetInventorySlotInfo("SecondaryHandSlot")),
	(GetInventorySlotInfo("RangedSlot")),
	(GetInventorySlotInfo("AmmoSlot")),
	(GetInventorySlotInfo("Bag0Slot")),
	(GetInventorySlotInfo("Bag1Slot")),
	(GetInventorySlotInfo("Bag2Slot")),
	(GetInventorySlotInfo("Bag3Slot")),
}

-- -----
-- local functions
-- -----
local function getbaseid(link)
	if link then
		if type(link) == "number" then return link end
		local baseid = strmatch(link, PATTERN_itemlink)
		if not baseid then
			baseid = strmatch(link, PATTERN_itemid)
		end
		if not baseid then
			baseid = link
		end
		return tonumber(baseid)
	end
	return
end

local function IsQuestItem(itemId)
	local itemType, itemSubType = select(6, GetItemInfo(itemId))
	return (itemType == LOCALE_QUEST or itemSubType == LOCALE_QUEST)
end

local function IsUsableItem(itemId)
	local itemSpell = GetItemSpell(itemId)
	return itemSpell and (strlen(itemSpell) > 0)
end

local function ScanBags()
	for _, bagid in ipairs(bagIds) do
		local size = GetContainerNumSlots(bagid)
		if size then
			for slotid = 1, size do
				local itemId = GetContainerItemID(bagid, slotid)
				local isQuestItem, questId, isActive = GetContainerItemQuestInfo(bagid, slotid)
				
				if itemId and (isQuestItem or IsQuestItem(itemId)) then
					questItems[itemId] = true
					if IsUsableItem(itemId) or questId then
						usableQuestItems[itemId] = true
					end
					startsQuestItems[itemId] = questId
					activeQuestItems[itemId] = isActive
				end
			end
		end
	end
end

local function ScanInventory()
	for _, slot in ipairs(inventorySlots) do
		local itemId = GetInventoryItemID("player", slot)
		if itemId and IsQuestItem(itemId) then
			questItems[itemId] = true
			usableQuestItems[itemId] = IsUsableItem(itemId)
		end
	end
end

local function ScanQuestLog()	
	for questIndex = 1, GetNumQuestLogEntries() do
		local itemLink, icon, charges = GetQuestLogSpecialItemInfo(questIndex)
		if itemLink then
			local itemId = getbaseid(itemLink)
			questItems[itemId] = true
			usableQuestItems[itemId] = true
			activeQuestItems[itemId] = true
		end
	end
end

-- -----
-- public API
-- -----
LibQuestItem.questItems = questItems
LibQuestItem.usableQuestItems = usableQuestItems
LibQuestItem.startsQuestItems = startsQuestItems
LibQuestItem.activeQuestItems = activeQuestItems

function LibQuestItem:Scan()
	--[===[@debug@
	print("LibQuestItem:Scan()")
	--@end-debug@]===]
	
	itemScanNeeded = false
	
	wipe(questItems)
	wipe(usableQuestItems)
	wipe(startsQuestItems)
	wipe(activeQuestItems)

	ScanInventory()
	ScanBags()
	ScanQuestLog()

	--[===[@debug@
	for k, _ in pairs(questItems) do
		print(k .. " Item Link: " .. self:GetItemString(k) .. " Usable: " .. tostring(usableQuestItems[k]) .. " Starts Quest: " .. tostring(startsQuestItems[k]) .. " Quest Active: " .. tostring(activeQuestItems[k]))
	end
	--@end-debug@]===]
	
	callbacks:Fire("LibQuestItem_Update")
end

-- function LibQuestItem:GetQuestItems(forceRescan)
	-- if forceRescan or itemScanNeeded then
		-- LibQuestItem:Scan()
	-- end
	-- return questItems
-- end

function LibQuestItem:GetItemString(itemId)
	return strformat(FORMAT_itemid, itemId)
end

function LibQuestItem:IsQuestItem(itemId)
	return LibQuestItem.questItems[itemId]
end

function LibQuestItem:IsUsable(itemId)
	return usableQuestItems[itemId]
end

function LibQuestItem:StartsQuestId(itemId)
	return startsQuestItems[itemId]
end

function LibQuestItem:IsQuestActive(itemId)
	return activeQuestItems[itemId]
end

-- -----
-- OnEvent and OnUpdate handlers / event registering
-- -----
local eventmap = {
	["BAG_UPDATE"] = "ITEMS_UPDATED",
	["UNIT_INVENTORY_CHANGED"] = "ITEMS_UPDATED",
	
	["PLAYER_ENTERING_WORLD"] = "PLAYER_ENTERING_WORLD",
	["PLAYER_LEAVING_WORLD"] = "PLAYER_LEAVING_WORLD",
	["PLAYER_REGEN_ENABLED"] = "PLAYER_REGEN_ENABLED",
	["PLAYER_REGEN_DISABLED"] = "PLAYER_REGEN_DISABLED",
}

LibQuestItem.frame:SetScript("OnEvent", function(self, event, ...)
	local eventfunc = eventmap[event]
	if eventfunc then
		LibQuestItem[eventfunc](LibQuestItem, ...)
	end
end)

for event in pairs(eventmap) do
	LibQuestItem.frame:RegisterEvent(event)
end

local total_elapsed = 0
LibQuestItem.frame:SetScript("OnUpdate", function(self, elapsed)
	total_elapsed = total_elapsed + elapsed
	if total_elapsed < 1 then return end
	total_elapsed = 0
	if itemScanNeeded and not InCombatLockdown() then
		LibQuestItem:Scan()
	end
	LibQuestItem.frame:Hide()
end)

-- -----
-- event functions
-- -----
function LibQuestItem:ITEMS_UPDATED()
	itemScanNeeded = true
	LibQuestItem.frame:Show()
end

function LibQuestItem:PLAYER_ENTERING_WORLD()
	itemScanNeeded = true
	LibQuestItem.frame:Show()
end

function LibQuestItem:PLAYER_LEAVING_WORLD()
	LibQuestItem.frame:Hide()
end

function LibQuestItem:PLAYER_REGEN_ENABLED()
	LibQuestItem.frame:Show()
end

function LibQuestItem:PLAYER_REGEN_DISABLED()
	LibQuestItem.frame:Hide()
end