local L = LibStub("AceLocale-3.0"):GetLocale("QuestItemBar")

--CONFIG
QuestItemBar.defaults = {
    profile = {
		skin = {
			ID = "DreamLayout",
			Gloss = 0,
			Backdrop = true,
			Colors = {},
		},
		bar = {
			relativePoint = "CENTER",
			x = 0,
			y = 0,
			direction = "RIGHT",
			alpha = 1,
			alphaHover = 1,
			scale = 1,
			padding = 1,
			itemsPerRow = 20,
			newRowDirection = 1,
			locked = false,
			hidden = false,
			onlyUsable = false,
			oorColor = { r = 1, g = 0, b = 0 }
		},
		autoKeyBind = false,
		autoKeyBindKey = "ALT-Q",
		ignoredItems = {},
		alwaysShowItems = {},
    },
}
--END CONFIG

--Ripped from Recount. Thanks!
local function deepCopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

--OPTIONS
QuestItemBar.consoleOptions = {
	type = "group",
	handler = QuestItemBar,
	args = {
		lock = {
			order = 1,
			type = "toggle",
			name = L["Lock bar"],
			desc = L["Lock bar and hide anchor."],
			set = "SetLock",
			get = function() return QuestItemBar.db.profile.bar.locked end,
		},
		hide = {
			order = 2,
			type = "toggle",
			name = L["Hide bar"],
			desc = L["Hide bar."],
			set = "SetHidden",
			get = function() return QuestItemBar.db.profile.bar.hide end,
		},
		onlyUsable = {
			order = 3,
			type = "toggle",
			name = L["Show only usable items"],
			desc = L["Show only usable items and hide all other quest items."],
			set = "SetUsable",
			get = function() return QuestItemBar.db.profile.bar.onlyUsable end,
		},
		
		styleheader1 = {
			order = 10,
			type = "header",
			name = L["Bar Style & Layout"],
		},
		alpha = {
			order = 11,
			name = L["Alpha"],
			desc = L["Configure the alpha of the bar."],
			type = "range",
			min = 0, max = 1, bigStep = 0.1,
			get = function() return QuestItemBar.db.profile.bar.alpha end,
			set = "SetAlpha",
		},
		alphaHover = {
			order = 12,
			name = L["Alpha on hover"],
			desc = L["Configure the alpha of the bar when mouse is over."],
			type = "range",
			min = .1, max = 1, bigStep = 0.1,
			get = function() return QuestItemBar.db.profile.bar.alphaHover end,
			set = "SetAlphaHover",
		},
		scale = {
			order = 13,
			name = L["Scale"],
			desc = L["Configure the scale of the bar."],
			type = "range",
			min = .1, max = 2, step = 0.05,
			get = function() return QuestItemBar.db.profile.bar.scale end,
			set = "SetScale",
		},
		padding = {
			order = 14,
			type = "range",
			name = L["Padding"],
			desc = L["Configure the padding of the buttons."],
			min = -10, max = 20, step = 1,
			get = function() return QuestItemBar.db.profile.bar.padding end,
			set = "SetPadding",
		},
		oorColor = {
			order = 15,
			type = "color",
			name = L["Out of range color"],
			desc = L["Configure the out of range color of the buttons."],
			get = function(info)
				local color = QuestItemBar.db.profile.bar[info[#info]]
				return color.r, color.g, color.b
			end,
			set = "SetColor",
		},
		direction = {
			order = 16,
			type = "select",
			name = L["Direction"],
			desc = L["Configure the direction of the buttons from the anchor."],
			values = { UP = L["Up"], DOWN = L["Down"], LEFT = L["Left"], RIGHT = L["Right"] },
			get = function() return QuestItemBar.db.profile.bar.direction end,
			set = "SetDirection",
		},
		itemsPerRow = {
			order = 17,
			type = "range",
			name = L["Items per row/column"],
			desc = L["Number of items before a new row/column is created. 0 = No limit."],
			min = 2, max = 40, step = 1,
			get = function() return QuestItemBar.db.profile.bar.itemsPerRow end,
			set = "SetItemsPerRow",
		},
		newRowDirection = {
			order = 18,
			type = "select",
			name = L["New row/column direction"],
			desc = L["Set the direction of new created row/column (Clockwise/Counterclockwise)"],
			values = { [1] = L["Clockwise"], [-1] = L["Counterclockwise"] },
			get = function() return QuestItemBar.db.profile.bar.newRowDirection end,
			set = "SetNewRowDirection",
		},
		
		styleheader2 = {
			order = 20,
			type = "header",
			name = L["Ignore/always show items"],
		},
		ignoreItem = {
			order = 21,
			name = L["Ignore item"],
			desc = L["Ignore a item and it will not be shown."],
			type = "input",
			set = "IgnoreItem",
		},
		listIgnored = {
			order = 22,
			name = L["List ignored items"],
			type = "execute",
			func = "ListIgnoredItems",
		},
		alwaysShowItem = {
			order = 23,
			name = L["Always show item"],
			desc = L["Always show a item even if it is not a quest item."],
			type = "input",
			set = "AlwaysShowItem",
		},
		listAlwaysShown = {
			order = 24,
			name = L["List items always shown"],
			type = "execute",
			func = "ListAlwaysShowItems",
		},

		styleheader3 = {
			order = 30,
			type = "header",
			name = L["Auto KeyBind Settings"],
		},
		autoKeyBind = {
			order = 31,
			name = L["Use auto key binding"],
			desc = L["Automatically bind a key to the last used item."],
			type = "toggle",
			set = function(_, value) QuestItemBar.db.profile.autoKeyBind = value end,
			get = function() return QuestItemBar.db.profile.autoKeyBind end,
		},		
		autoKeyBindKey = {
			order = 32,
			name = L["Key"],
			desc = L["Key to use for automatic key binding."],
			type = "keybinding",
			set = function(_, value) QuestItemBar.db.profile.autoKeyBindKey = value end,
			get = function() return QuestItemBar.db.profile.autoKeyBindKey end,
		},
		
		config = {
			order = 100,
			name = L["Open config UI"],
			desc = L["Open the blizzard configuration UI."],
			type = "execute",
			guiHidden = true,
			func = "OpenConfig",
		},
	},
}
QuestItemBar.options = deepCopy(QuestItemBar.consoleOptions)
--END OPTIONS

function QuestItemBar:SetAlpha(_, value)
	self.db.profile.bar.alpha = value
	self.anchor:SetAlpha(value)
end

function QuestItemBar:SetAlphaHover(_, value)
	self.db.profile.bar.alphaHover = value
end

function QuestItemBar:SetScale(_, value)
	self.db.profile.bar.scale = value
	self.anchor:SetScale(value)
end

function QuestItemBar:SetPadding(_, value)
	self.db.profile.bar.padding = value
	self:UpdateBar()
end

function QuestItemBar:SetColor(info, r, g, b)
	local color = self.db.profile.bar[info[#info]]
	color.r, color.g, color.b = r, g, b
end

function QuestItemBar:SetDirection(_, value)
	self.db.profile.bar.direction = value
	self:UpdateBar()
end

function QuestItemBar:SetItemsPerRow(_, value)
	self.db.profile.bar.itemsPerRow = value
	self:UpdateBar()
end

function QuestItemBar:SetNewRowDirection(_, value)
	self.db.profile.bar.newRowDirection = value
	self:UpdateBar()
end

function QuestItemBar:SetLock(_, value)
	QuestItemBar.db.profile.bar.locked = value
	self.anchor:SetMovable(not value)	
	self:UpdateBar()
end

function QuestItemBar:ToggleLock()
	self:SetLock(_, not self.db.profile.bar.locked)
end

function QuestItemBar:SetHidden(_, value)
	QuestItemBar.db.profile.bar.hide = value
	if QuestItemBar.db.profile.bar.hide then
		QuestItemBar.anchor:Hide()
	else
		QuestItemBar.anchor:Show()
	end
end

function QuestItemBar:ToggleHidden()
	self:SetHidden(_, not QuestItemBar.db.profile.bar.hide)
end

function QuestItemBar:SetUsable(_, value)
	self.db.profile.bar.onlyUsable = value
	self:UpdateBar()
end

function QuestItemBar:IgnoreItem(_, value)
	--if not value then return end
	local _, itemLink = GetItemInfo(value or "")
	if itemLink then
		local itemId = self:GetItemId(itemLink)
		local ignoredItems = self.db.profile.ignoredItems
		if ignoredItems[itemId] then
			ignoredItems[itemId] = nil
			self:Print(itemLink .. L[" is not ignored anymore."])
		else
			ignoredItems[itemId] = true
			self:Print(itemLink .. L[" is now ignored."])
		end
	else
		self:Print(L["The value passed have to be a itemString, itemName or itemLink. Example: /qib ignoreItem Hearthstone"])
	end
	
	self:UpdateBar()
end

function QuestItemBar:ListIgnoredItems()
	local ignoredItems = self.db.profile.ignoredItems
	local text = L["Ignored items: "]
	for item,_ in pairs(ignoredItems) do
		text = text .. select(2, GetItemInfo(item))
	end
	self:Print(text)
end

function QuestItemBar:AlwaysShowItem(_, value)
	--if not value then return end
	local _, itemLink = GetItemInfo(value or "")
	if itemLink then
		local itemId = self:GetItemId(itemLink)
		local alwaysShowItems = self.db.profile.alwaysShowItems
		if alwaysShowItems[itemId] then
			alwaysShowItems[itemId] = nil
			self:Print(itemLink .. L[" is not always shown."])
		else
			alwaysShowItems[itemId] = true
			self:Print(itemLink .. L[" is now always shown."])
		end
	else
		self:Print(L["The value passed have to be a itemString, itemName or itemLink. Example: /qib alwaysShowItem Hearthstone"])
	end
	
	self:UpdateBar()
end

function QuestItemBar:ListAlwaysShowItems()
	local alwaysShowItems = self.db.profile.alwaysShowItems
	local text = L["Items alway shown: "]
	for item,_ in pairs(alwaysShowItems) do
		text = text .. select(2, GetItemInfo(item))
	end
	self:Print(text)
end

function QuestItemBar:OpenConfig()
	if InCombatLockdown() then return end
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame.Profiles)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function QuestItemBar:SetupOptions()
	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self.options.args.profiles.order = 2
		
	LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, QuestItemBar.consoleOptions, {L[self.name], L["qib"]})
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("QuestItemBar Profile", self.options.args.profiles)
	
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, L[self.name])
	self.optionsFrame.Profiles = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("QuestItemBar Profile", L["Profile"], self.name)
	
	self.optionsFrame[L["About"]] = LibStub("LibAboutPanel").new(self.name, self.name)
end
