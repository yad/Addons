BankStack = LibStub("AceAddon-3.0"):NewAddon("BankStack", "AceEvent-3.0")
local core = BankStack
local L = LibStub("AceLocale-3.0"):GetLocale("BankStack")
core.L = L

local debugf = tekDebug and tekDebug:GetFrame("BankStack")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end
core.Debug = Debug

--Bindings locales:
BINDING_HEADER_BANKSTACK_HEAD = L['BINDING_HEADER_BANKSTACK_HEAD']
BINDING_NAME_BANKSTACK = L['BINDING_NAME_BANKSTACK']
BINDING_NAME_COMPRESS = L['BINDING_NAME_COMPRESS']
BINDING_NAME_BAGSORT = L['BINDING_NAME_BAGSORT']

function core:OnInitialize()
	local oldDB
	if BankStackDB and not BankStackDB.profileKeys then
		-- upgrade the database!
		oldDB = BankStackDB
		BankStackDB = nil
	end
	
	self.db_object = LibStub("AceDB-3.0"):New("BankStackDB", {
		profile = {
			verbosity = 1,
			junk = true,
			soul = true,
			conjured = false,
			soulbound = true,
			ignore = {},
			groups = {},
			fubar_keybinds={
				['BUTTON1'] = 'sortbags',
				['ALT-BUTTON1'] = 'sortbank',
				['CTRL-BUTTON1'] = 'compressbags',
				['ALT-CTRL-BUTTON1'] = 'compressbank',
				['SHIFT-BUTTON1'] = 'stackbank',
				['ALT-SHIFT-BUTTON1'] = 'stackbags',
				['CTRL-SHIFT-BUTTON1'] = false,
				['ALT-CTRL-SHIFT-BUTTON1'] = false,
			},
			conservative_guild = true,
		},
	}, "Default")
	self.db = self.db_object.profile
	self.db_object.RegisterCallback(self, "OnProfileChanged", function()
		self.db = self.db_object.profile
	end)

	if oldDB then
		local copy = function(from, to)
			for k,v in pairs(from) do
				if type(v) == 'table' then
					to[k] = copy(v, type(to[k]) == 'table' and to[k] or {})
				else
					to[k] = v
				end
			end
			return to
		end
		copy(oldDB, self.db)
	end

	if self.setup_config then
		self.setup_config()
	end

	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("GUILDBANKFRAME_OPENED")
	self:RegisterEvent("GUILDBANKFRAME_CLOSED")
end

local frame = CreateFrame("Frame")
local t, WAIT_TIME = 0, 0.05
frame:SetScript("OnUpdate", function(frame, time_since_last)
	if (core.bankrequired and not core.bank_open) or (core.guildbankrequired and not core.guild_bank_open) then
		Debug(core.bankrequired and "bank required" or "guild bank required")
		core.StopStacking(L.at_bank)
	end
	t = t + (time_since_last or 0.01)
	if t > WAIT_TIME then
		t = 0
		core.DoMoves()
	end
end)
frame:Hide() -- stops OnUpdate from running

core.frame = frame

--Inner workings:
function core.announce(level, message, r, g, b)
	if level > core.db.verbosity then return end
	DEFAULT_CHAT_FRAME:AddMessage(message, r, g, b)
end

-- http://wowwiki.com/API_TYPE_bagID
local bank_bags = {BANK_CONTAINER}
for i = NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
	table.insert(bank_bags, i)
end
core.bank_bags = bank_bags
local player_bags = {}
for i = 0, NUM_BAG_SLOTS do
	table.insert(player_bags, i)
end
core.player_bags = player_bags
local all_bags = {BANK_CONTAINER}
for i = 0, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
	table.insert(all_bags, i)
end
core.all_bags = all_bags
local guild = {51,52,53,54,55,56}
core.guild = guild
local all_bags_with_guild = {}
for _,bag in ipairs(all_bags) do table.insert(all_bags_with_guild, bag) end
for _,bag in ipairs(guild) do table.insert(all_bags_with_guild, bag) end
core.all_bags_with_guild = all_bags_with_guild

local function is_valid_bag(bagid)
	return (bagid == BANK_CONTAINER or ((bagid >= 0) and bagid <= NUM_BAG_SLOTS+NUM_BANKBAGSLOTS))
end
core.is_valid_bag = is_valid_bag
local function is_bank_bag(bagid)
	return (bagid == BANK_CONTAINER or (bagid > NUM_BAG_SLOTS and bagid <= NUM_BANKBAGSLOTS))
end
core.is_bank_bag = is_bank_bag
local function is_guild_bank_bag(bagid)
	-- Note that this is an artificial slot id, which we're using internally to trigger usage of guild bank functions.
	-- Guild bank slots are: 51, 52, 53, 54, 55, 56.
	-- I couldn't find a constant for the maximum number of guild bank tabs; it's currently 6.
	return (bagid > 50 and bagid <= 56)
end
core.is_guild_bank_bag = is_guild_bank_bag

local core_groups = {
	bank = bank_bags,
	bags = player_bags,
	all = all_bags,
	guild = guild,
	guild1 = {51,},
	guild2 = {52,},
	guild3 = {53,},
	guild4 = {54,},
	guild5 = {55,},
	guild6 = {56,},
}
core.groups = core_groups
function core.get_group(id)
	Debug ("get_group", id)
	if id == "bank" and core.guild_bank_open then
		local tab = GetCurrentGuildBankTab()
		if tab then
			return core_groups["guild" .. tab]
		end
	end
	if not core.db.groups[id] and string.match(id, "[-%d,]+") then
		Debug("Looks like a bag list", id)
		local bags = {}
		for b in string.gmatch(id, "-?%d+") do
			table.insert(bags, tonumber(b))
		end
		Debug("Parsed out", #bags)
		return bags
	end
	return core_groups[id] or core.db.groups[id]
end
function core.contains_bank_bag(group)
	for _,bag in ipairs(group) do
		if is_bank_bag(bag) then return true end
	end
end
function core.contains_guild_bank_bag(group)
	for _,bag in ipairs(group) do
		if is_guild_bank_bag(bag) then return true end
	end
end

function core.check_for_banks(bags)
	--Check {bags} to see if any of them are in the bank / guild bank.  Print a warning if they are.
	if core.contains_bank_bag(bags) then
		if not core.bank_open then
			core.announce(0, L.at_bank, 1, 0, 0)
			return true
		end
		core.bankrequired = true
	end
	if core.contains_guild_bank_bag(bags) then
		if not core.guild_bank_open then
			core.announce(0, L.at_bank, 1, 0, 0)
			return true
		end
		core.guildbankrequired = true
	end
end

do
	local tooltip
	function core.CheckTooltipFor(bag, slot, text)
		if not tooltip then
			tooltip = CreateFrame("GameTooltip", "BankStackTooltip", nil, "GameTooltipTemplate")
			tooltip:SetOwner(UIParent, "ANCHOR_NONE")
			--core.tooltip = tooltip
		end
		if slot and not bag then
			-- just showing tooltip for an itemid
			-- uses rather innocent checking so that slot can be a link or an itemid
			local link = tostring(slot) -- so that ":match" is guaranteed to be okay
			if not link:match("item:") then
				link = "item:"..link
			end
			tooltip:SetHyperlink(link)
		elseif is_guild_bank_bag(bag) then
			tooltip:SetGuildBankItem(bag-50, slot)
		else
			tooltip:SetBagItem(bag, slot)
		end
		for i=2, tooltip:NumLines() do
			local left = _G["BankStackTooltipTextLeft"..i]
			--local right = _G["BankStackTooltipTextRight"..i]
			if left and left:IsShown() and string.match(left:GetText(), text) then return true end
			--if right and right:IsShown() and string.match(right:GetText(), text) then return true end
		end
		return false
	end
end

local function encode_bagslot(bag, slot) return (bag*100) + slot end
local function decode_bagslot(int) return math.floor(int/100), int % 100 end
local function encode_move(source, target) return (source*10000)+target end
local function decode_move(move)
	local s = math.floor(move/10000)
	local t = move%10000
	s = (t>9000) and (s+1) or s
	t = (t>9000) and (t-10000) or t
	return s, t
end
local function link_to_id(link) return link and tonumber(string.match(link, "item:(%d+)")) end -- "item" because we only care about items, duh
core.encode_bagslot = encode_bagslot
core.decode_bagslot = decode_bagslot
core.encode_move = encode_move
core.decode_move = decode_move
core.link_to_id = link_to_id

do
	local bag_role, bagiter_forwards, bagiter_backwards
	function bagiter_forwards(baglist, i)
		i = i + 1
		local step = 1
		for _,bag in ipairs(baglist) do
			local slots = core.GetNumSlots(bag, bag_role)
			if i > slots + step then
				step = step + slots
			else
				for slot=1, slots do
					if step == i then
						return i, bag, slot
					end
					step = step + 1
				end
			end
		end
		bag_role = nil
	end
	function bagiter_backwards(baglist, i)
		i = i + 1
		local step = 1
		for ii=#baglist, 1, -1 do
			local bag = baglist[ii]
			local slots = core.GetNumSlots(bag, bag_role)
			if i > slots + step then
				step = step + slots
			else
				for slot=slots, 1, -1 do
					if step == i then
						return i, bag, slot
					end
					step = step + 1
				end
			end
		end
		bag_role = nil
	end

	-- Iterate over bags and slots
	-- e.g. for _, bag, slot in core.IterateBags({1,2,3}) do ... end
	function core.IterateBags(baglist, reverse, role)
		bag_role = role
		return (reverse and bagiter_backwards or bagiter_forwards), baglist, 0
	end
end

-- Wrapper functions to allow for pretending that the guild bank and bags are the same.
function core.GetNumSlots(bag, role)
	-- role: "withdraw", "deposit", "both"; defaults to "both", as that is the most restrictive
	-- (Whether you intend to put things into or take things out of this bag.  Only affects guild bank slots.)
	-- The main complication here is the guild bank.
	if is_guild_bank_bag(bag) then
		if not role then role = "deposit" end
		local tab = bag - 50
		local name, icon, canView, canDeposit, numWithdrawals = GetGuildBankTabInfo(tab)
		--(numWithdrawals is negative if you have unlimited withdrawals available.)
		if name and canView and ((role == "withdraw" and numWithdrawals ~= 0) or (role == "deposit" and canDeposit) or (role == "both" and numWithdrawals ~= 0 and canDeposit)) then
			return 98 -- MAX_GUILDBANK_SLOTS_PER_TAB (some bag addons stop Blizzard_GuildBankUI from loading, making the constant unavailable)
		end
	else
		return GetContainerNumSlots(bag)
	end
	return 0
end

function core.GetItemInfo(bag, slot)
	if is_guild_bank_bag(bag) then
		local tab = bag - 50
		return GetGuildBankItemInfo(tab, slot)
	else
		return GetContainerItemInfo(bag, slot)
	end
end

function core.GetItemLink(bag, slot)
	if is_guild_bank_bag(bag) then
		local tab = bag - 50
		return GetGuildBankItemLink(tab, slot)
	else
		return GetContainerItemLink(bag, slot)
	end
end

function core.PickupItem(bag, slot)
	if is_guild_bank_bag(bag) then
		local tab = bag - 50
		return PickupGuildBankItem(tab, slot)
	else
		return PickupContainerItem(bag, slot)
	end
end

function core.SplitItem(bag, slot, amount)
	if is_guild_bank_bag(bag) then
		local tab = bag - 50
		return SplitGuildBankItem(tab, slot, amount)
	else
		return SplitContainerItem(bag, slot, amount)
	end
end

function core.CanItemGoInBag(item, bag)
	if is_guild_bank_bag(bag) then
		-- almost anything can go in a guild bank... apart from:
		if
			core.CheckTooltipFor(false, item, ITEM_SOULBOUND)
			or
			core.CheckTooltipFor(false, item, ITEM_CONJURED)
			or
			core.CheckTooltipFor(false, item, ITEM_BIND_QUEST)
		then
			return false
		end
		return true
	end
	-- since we now know this isn't a guild bank we can just use the bag id provided
	local item_family = GetItemFamily(item)
	if item_family > 0 then
		-- if the item is a profession bag, this will actually be the bag_family, and it should be zero
		local equip_slot = select(9, GetItemInfo(item))
		if equip_slot == "INVTYPE_BAG" then
			item_family = 1
		end
	end
	local bag_family = select(2, GetContainerNumFreeSlots(bag))
	return bag_family == 0 or bit.band(item_family, bag_family) > 0
end

--Respond to events:
function core:BANKFRAME_OPENED()
	core.bank_open = true
end
function core:BANKFRAME_CLOSED()
	core.bank_open = false
end
function core:GUILDBANKFRAME_OPENED()
	core.guild_bank_open = true
	Debug("GUILDBANKFRAME_OPENED")
end
function core:GUILDBANKFRAME_CLOSED()
	core.guild_bank_open = false
	Debug("GUILDBANKFRAME_CLOSED")
end

local moves = {--[[encode_move(encode_bagslot(),encode_bagslot(target)),. ..--]]}
core.moves = moves

local bag_ids = {}
local bag_stacks = {}
local bag_maxstacks = {}
core.bag_ids, core.bag_stacks, core.bag_maxstacks = bag_ids, bag_stacks, bag_maxstacks
local function update_location(from, to)
	-- When I move something from (3,12) to (0,1), the contents of (0,1) are now in (3,12).
	-- Therefore if I find later that I need to move something from (0,1), I actually need to move whatever wound up in (3,12).
	-- This function updates the various cache tables to reflect current locations.
	if (bag_ids[from] == bag_ids[to]) and (bag_stacks[to] < bag_maxstacks[to]) then
		-- If they're the same type we might have to deal with stacking.
		local stack_size = bag_maxstacks[to]
		if (bag_stacks[to] + bag_stacks[from]) > stack_size then
			-- only some of the items have been moved, since the total is greater than the stack size
			bag_stacks[from] = bag_stacks[from] - (stack_size - bag_stacks[to])
			bag_stacks[to] = stack_size
		else
			-- from is empty, since everything in it has been moved
			bag_stacks[to] = bag_stacks[to] + bag_stacks[from]
			bag_stacks[from] = nil
			bag_ids[from] = nil
			bag_maxstacks[from] = nil
		end
	else
		bag_ids[from], bag_ids[to] = bag_ids[to], bag_ids[from]
		bag_stacks[from], bag_stacks[to] = bag_stacks[to], bag_stacks[from]
		bag_maxstacks[from], bag_maxstacks[to] = bag_maxstacks[to], bag_maxstacks[from]
	end
end
function core.ScanBags()
	for _, bag, slot in core.IterateBags(all_bags_with_guild) do
		local bagslot = encode_bagslot(bag, slot)
		local itemid = link_to_id(core.GetItemLink(bag, slot))
		if itemid then
			bag_ids[bagslot] = itemid
			bag_stacks[bagslot] = select(2, core.GetItemInfo(bag, slot))
			bag_maxstacks[bagslot] = select(8, GetItemInfo(itemid))
		end
	end
end
function core.AddMove(source, destination)
	update_location(source, destination)
	table.insert(moves, 1, encode_move(source, destination))
end

local moves_underway, last_itemid, lock_stop
local STUTTER_INTERVAL, STUTTER_WAIT, PROCESSING_WAIT = 0.05, 0, 0.1
local move_tracker = {}

local function debugtime(start, msg) Debug("took", GetTime() - start, msg or '') end
function core.DoMoves()
	Debug("DoMoves", #moves)
	if CursorHasItem() then
		local itemid = link_to_id(select(3, GetCursorInfo()))
		if last_itemid ~= itemid then
			-- We didn't pick up whatever is on the cursor; things could get really screwed up if we carry on. Abort!
			Debug("Aborted because", last_itemid or 'nil', '~=', itemid or 'nil')
			return core.StopStacking(L.confused)
		end
	end
	
	if lock_stop then
		Debug("Checking whether it's safe to move again")
		for slot,itemid in pairs(move_tracker) do
			Debug("checking whether", slot, "contains", itemid, link_to_id(core.GetItemLink(decode_bagslot(slot))))
			if link_to_id(core.GetItemLink(decode_bagslot(slot))) ~= itemid then
				Debug("Stopping DoMoves because last move hasn't happened yet.", slot, itemid)
				WAIT_TIME = PROCESSING_WAIT
				return --give processing time to happen
			end
			move_tracker[slot] = nil
		end
	end
	
	last_itemid, lock_stop = nil, nil
	wipe(move_tracker)
	
	if core.dataobject then core.dataobject.text = #moves .. " moves to go" end
	local start, success, move_id, target_id, move_source, move_target, was_guild
	start = GetTime()
	if #moves > 0 then for i=#moves, 1, -1 do
		success, move_id, move_source, target_id, move_target, was_guild = core.DoMove(moves[i])
		if not success then
			debugtime(start, move_id or 'unspecified') -- repurposing for debugging
			WAIT_TIME = PROCESSING_WAIT
			lock_stop = true
			return -- take a break!
		end
		move_tracker[move_source] = target_id
		move_tracker[move_target] = move_id
		last_itemid = move_id
		table.remove(moves, i)
		if moves[i-1] then
			-- Guild bank CursorHasItem/CursorItemInfo isn't working, so slow down for it.
			if was_guild then
				local next_source, next_target = decode_move(moves[i-1])
				if core.db.conservative_guild or move_tracker[next_source] or move_tracker[next_target] then
					Debug("fake-guild-locking is in effect", core.db.conservative_guild and "conservative" or "locking")
					WAIT_TIME = PROCESSING_WAIT
					lock_stop = true
					debugtime(start, 'guild bank sucks')
					return
				end
			end
			if (GetTime() - start) > STUTTER_INTERVAL then
				-- avoiding the lags
				WAIT_TIME = STUTTER_WAIT
				debugtime(start, "stutter-avoider")
				return
			end
		end
	end end
	debugtime(start, 'done')
	core.announce(1, L.complete, 1, 1, 1)
	core.StopStacking()
end

function core.DoMove(move)
	if CursorHasItem() then
		return false, 'cursorhasitem'
	end
	local source, target = decode_move(move)
	local source_bag, source_slot = decode_bagslot(source)
	local target_bag, target_slot = decode_bagslot(target)
	local _, source_count, source_locked = core.GetItemInfo(source_bag, source_slot)
	local _, target_count, target_locked = core.GetItemInfo(target_bag, target_slot)
	
	if source_locked or target_locked then
		return false, 'source/target_locked'
	end

	local source_link = core.GetItemLink(source_bag, source_slot)
	local source_itemid = link_to_id(source_link)
	local target_itemid = link_to_id(core.GetItemLink(target_bag, target_slot))
	if not source_itemid then
		if move_tracker[source] then
			return false, 'move incomplete'
		else
			Debug("Aborted because not source_itemid", source_bag, source_slot, source_link, source_itemid or 'nil')
			return core.StopStacking(L.confused)
		end
	end
	local stack_size = select(8, GetItemInfo(source_itemid))
	
	core.announce(2, string.format(L.moving, source_link), 1,1,1)
	
	if
		(source_itemid == target_itemid)
		and
		(target_count ~= stack_size)
		and
		((target_count + source_count) > stack_size)
	then
		core.SplitItem(source_bag, source_slot, stack_size - target_count)
	else
		core.PickupItem(source_bag, source_slot)
	end
	local guildbank = is_guild_bank_bag(source_bag)
	if CursorHasItem() or guildbank then
		-- CursorHasItem doesn't work on the guild bank
		core.PickupItem(target_bag, target_slot)
	end

	if guildbank then
		QueryGuildBankTab(source_bag - 50)
	end
	if is_guild_bank_bag(target_bag) then
		QueryGuildBankTab(target_bag - 50)
	end
	
	-- Debug("Moved", source, source_itemid, target, target_itemid, guildbank)
	return true, source_itemid, source, target_itemid, target, guildbank
end

function core.StartStacking()
	wipe(bag_maxstacks)
	wipe(bag_stacks)
	wipe(bag_ids)
	wipe(move_tracker)
	
	if #moves > 0 then
		core.running = true
		core.announce(1, string.format(L.to_move, #moves), 1, 1, 1)
		frame:Show()
	else
		core.announce(1, L.perfect, 1, 1, 1)
	end
end

function core.StopStacking(message)
	core.running = false
	core.bankrequired = false
	core.guildbankrequired = false
	wipe(moves)
	wipe(move_tracker)
	frame:Hide()
	if core.dataobject then
		core.dataobject.text = core.dataobject.label
	end
	if message then
		core.announce(1, message, 1, 0, 0)
	end
end

do
	local safe = {
		[BANK_CONTAINER]=true,
		[0]=true,
	}
	function core.IsSpecialtyBag(bagid)
		if safe[bagid] or is_guild_bank_bag(bagid) then return false end
		local invslot = ContainerIDToInventoryID(bagid)
		if not invslot then return false end
		local bag = GetInventoryItemLink("player", invslot)
		if not bag then return false end
		local item_type, item_subtype = select(6, GetItemInfo(bag))
		if item_type == L.CONTAINER and item_subtype == L.BAG then
			return false
		end
		return item_subtype
	end
end

