QuestItemBar = LibStub("AceAddon-3.0"):NewAddon("QuestItemBar", "AceConsole-3.0", "AceEvent-3.0")

local LQI = LibStub("LibQuestItem-1.0", true)
local L = LibStub("AceLocale-3.0"):GetLocale("QuestItemBar")

--LOCAL TABLES AND VARS
local itemUpdateNeeded = false
local questItemLinks = {}
local buttonSize = 36

--UTILITY FUNCTION
local PATTERN_itemid = "item:(%-?%d+):%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+"
local PATTERN_itemlink = "|c%x+|H"..PATTERN_itemid.."|h%[.-%]|h|r"
function QuestItemBar:GetItemId(link)
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

local function OnReceiveDragItem()
	local infoType, itemID, itemLink = GetCursorInfo()
	ClearCursor()
	if infoType == "item" then
		if LQI.questItems[itemID] then
			QuestItemBar:IgnoreItem(_, itemID)
		else
			QuestItemBar:AlwaysShowItem(_, itemID)
		end
	end
end

--GUI FUNCTIONS
function QuestItemBar:CreateAnchor()
	local f = CreateFrame("Frame",self.name.."Anchor",UIParent)
	
	f.buttons = {}

	f:SetClampedToScreen(true)
	f:SetHeight(buttonSize)
	f:SetWidth(buttonSize)

	f:SetAlpha(self.db.profile.bar.alpha)
	f:SetScale(self.db.profile.bar.scale)
	f:SetMovable(not self.db.profile.bar.locked)
	f:SetPoint(self.db.profile.bar.relativePoint, self.db.profile.bar.x, self.db.profile.bar.y)
	
	if self.db.profile.bar.hide then f:Hide()
	else f:Show() end

	local overlay = CreateFrame("Frame", f:GetName() .. "Overlay", f)
	f.overlay = overlay
	overlay:EnableMouse(true)
	overlay:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	overlay:SetBackdropColor(0,0,0,1)
	overlay:SetBackdropBorderColor(0.3,0.3,0.3,1)
	
	overlay:SetFrameLevel(f:GetFrameLevel() + 10)
	overlay:ClearAllPoints()
	overlay:SetAllPoints(f)
	if self.db.profile.bar.locked then overlay:Hide()
	else overlay:Show() end
	
	overlay:EnableMouse(true)
	overlay:SetScript("OnMouseDown",function(frame, button)
		local parent = frame:GetParent()
		if button == "LeftButton" and parent:IsMovable() then
			parent:StartMoving()
		end
	end)
	overlay:SetScript("OnMouseUp",function(frame, button)
		if button == "LeftButton" then
			local parent = frame:GetParent()
			parent:StopMovingOrSizing()
			local _, _, relativePoint, x, y = parent:GetPoint()
			QuestItemBar:SaveBarPosition(relativePoint, x, y)
		elseif button == "RightButton" then
			QuestItemBar:ChangeBarDirection()
			QuestItemBar:UpdateBar()
		end
	end)
	overlay:SetScript("OnReceiveDrag", OnReceiveDragItem)
		
	f.ClearButtonKeyBinds = function(self)
		for _,button in ipairs(self.buttons) do
			button.hotkey:SetText("")
		end
	end
	
	return f
end

local function buttonOnEnter(self)
	QuestItemBar.anchor:SetAlpha(QuestItemBar.db.profile.bar.alphaHover)
	if ( GetCVar("UberTooltips") == "1" ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:SetHyperlink(self:GetAttribute("item"))
end
local function buttonOnLeave()
	QuestItemBar.anchor:SetAlpha(QuestItemBar.db.profile.bar.alpha)
	GameTooltip:Hide() 
end
local function buttonOnUpdate(self)
	local itemLink = self:GetAttribute("item")
	local inRange = IsItemInRange(itemLink, "target")
	if inRange == 0 then
		local color = QuestItemBar.db.profile.bar.oorColor
		self.icon:SetVertexColor(color.r, color.g, color.b)
	else
		self.icon:SetVertexColor(1, 1, 1)
	end
end
local function buttonOnClick(self)
	if QuestItemBar.db.profile.autoKeyBind then
		local key = QuestItemBar.db.profile.autoKeyBindKey
		self:GetParent():ClearButtonKeyBinds()
		SetBindingClick(key, self:GetName(), 'LeftButton')
		key = key:gsub('ALT%-', 'A')
		key = key:gsub('CTRL%-', 'C')
		key = key:gsub('SHIFT%-', 'S')
		self.hotkey:SetText(key)
	end
end
		
function QuestItemBar:CreateItemButton(index, parent)
	if parent.buttons[index] then
		return parent.buttons[index]
	end

	local buttonName = self.name.."Button"..index
	local button = CreateFrame("Button", buttonName, parent, "SecureActionButtonTemplate")
	
	button:SetWidth(buttonSize)
	button:SetHeight(buttonSize)

	button:SetScript("OnEnter", buttonOnEnter)
	button:SetScript("OnLeave", buttonOnLeave)
	button:SetScript("OnUpdate", buttonOnUpdate)
	button:SetScript("OnReceiveDrag", OnReceiveDragItem)
	button:HookScript("OnClick", buttonOnClick)
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	
	button.icon = button:CreateTexture(buttonName.."Icon","BORDER")
	button.icon:SetAllPoints()
	
	--button.border = button:CreateTexture(buttonName.."Border","OVERLAY")
	--button.border:SetTexture([[Interface\Buttons\UI-ActionButton-Border]])
		
	button.cooldown = CreateFrame("Cooldown", buttonName.."Cooldown", button, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints()
	
	button.hotkey = button:CreateFontString(buttonName.."Hotkey", "OVERLAY", "NumberFontNormal")
	button.hotkey:SetPoint("TOPRIGHT", button, -1, 0)
	
	button.count = button:CreateFontString(buttonName.."Count", "OVERLAY", "NumberFontNormal")
	button.count:SetPoint("BOTTOMRIGHT", button.icon, -1, 1)
	
	button.flash = button:CreateTexture(buttonName.."Flash", "OVERLAY")
	button.flash:Hide()
	
	if self.LBFGroup then
		self.LBFGroup:AddButton(button)
	end
	
	parent.buttons[index] = button
	return button
end

function QuestItemBar:SetButtonPoint(index)
	local dir = self.db.profile.bar.direction
	local padding = self.db.profile.bar.padding
	local button = self.anchor.buttons[index]
	local parent
	local itemsPerRow = self.db.profile.bar.itemsPerRow
	local newRowDirection = self.db.profile.bar.newRowDirection
	local rowPadding = 0
	
	if index == 1 then
		parent = self.anchor
		if QuestItemBar.db.profile.bar.locked then
			padding = -buttonSize
		end
	elseif index > 1 then
		if mod(index-1, itemsPerRow) == 0 then --if button should "create" a new row, set row padding to button size and anchor button to mover/anchor
			rowPadding = newRowDirection * ( (buttonSize + padding) * floor(index/itemsPerRow) )
			padding = -buttonSize
			parent = self.anchor
		else
			parent = self.anchor.buttons[index - 1]
		end
	end
	
	button:ClearAllPoints() 
	if dir == "RIGHT" then
		button:SetPoint("LEFT", parent, "RIGHT", padding, -rowPadding)
	elseif dir == "LEFT" then
		button:SetPoint("RIGHT", parent, "LEFT", -padding, rowPadding)
	elseif dir == "UP" then
		button:SetPoint("BOTTOM", parent, "TOP", rowPadding, padding)
	elseif dir == "DOWN" then
		button:SetPoint("TOP", parent, "BOTTOM", -rowPadding, -padding)
	end
end

function QuestItemBar:AddButton(index, itemLink)
	local button = self:CreateItemButton(index, self.anchor)
	
	button.icon:SetTexture(GetItemIcon(itemLink))
	local count = GetItemCount(itemLink)
	button.count:SetText(count and count > 1 and count or "")
	
	button:SetAttribute("type*","item")
	button:SetAttribute("item", LQI:GetItemString(itemLink))
	
	self:SetButtonPoint(index)

	button:Show()
end

function QuestItemBar:UpdateBar()
	if InCombatLockdown() then return end
	
	if QuestItemBar.db.profile.bar.locked then
		self.anchor.overlay:Hide()
	else
		self.anchor.overlay:Show()
	end

	--Hide all anchor.buttons
	for i = 1, #self.anchor.buttons do
		self.anchor.buttons[i]:Hide()
	end
	
	local items
	if QuestItemBar.db.profile.bar.onlyUsable then
		items = LQI.usableQuestItems
	else
		items = LQI.questItems
	end
	
	local ignoredItems = self.db.profile.ignoredItems
	local index = 1
	for itemId, _ in pairs(items) do
		if not ignoredItems[itemId] then
			self:AddButton(index, itemId)
			index = index + 1
		end	
	end
	--Always shown items
	for itemId, _ in pairs(self.db.profile.alwaysShowItems) do
		if GetItemCount(itemId) > 0 then
			self:AddButton(index, itemId)
			index = index + 1
		end
	end
end
--END GUI FUNCTIONS

function QuestItemBar:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("QuestItemBarDB", self.defaults, "Default")

	self:SetupOptions()
	self:LoadLDB()
	
	self.anchor = self:CreateAnchor()
	
	self:LoadLBF()
end

function QuestItemBar:OnEnable()
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	
	LQI.RegisterCallback(self, "LibQuestItem_Update")
end

function QuestItemBar:LibQuestItem_Update()
	self:UpdateBar()
end

function QuestItemBar:ACTIONBAR_UPDATE_COOLDOWN()
	for _, button in ipairs(self.anchor.buttons) do
		if button:IsShown() then
			local itemLink = button:GetAttribute("item")
			CooldownFrame_SetTimer(button.cooldown, GetItemCooldown(itemLink))
		end
	end
end

function QuestItemBar:SaveBarPosition(relativePoint, x, y)
	self.db.profile.bar.relativePoint = relativePoint
	self.db.profile.bar.x = x
	self.db.profile.bar.y = y
end

function QuestItemBar:ChangeBarDirection(dir)
	if not dir then
		dir = self.db.profile.bar.direction
		
		if dir == "UP" then dir = "RIGHT"
		elseif dir == "RIGHT" then dir = "DOWN"
		elseif dir == "DOWN" then dir = "LEFT"
		elseif dir == "LEFT" then dir = "UP"
		end
	end
	
	self.db.profile.bar.direction = dir
end

--LibDataBroker
local LDB = LibStub("LibDataBroker-1.1", true)
--Ripped from Bartender4
function QuestItemBar:LoadLDB()
	local LDBObj = LibStub("LibDataBroker-1.1"):NewDataObject(self.name, {
		type = "launcher",
		label = self.name,
		OnClick = function(_, msg)
			if msg == "LeftButton" then
				QuestItemBar:ToggleHidden()
			elseif msg == "RightButton" then
				if IsShiftKeyDown() then
					QuestItemBar:OpenConfig()
				else
					QuestItemBar:ToggleLock()
				end
			end
		end,
		icon = "Interface\\Icons\\inv_misc_bag_17",
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine(self.name)
			tooltip:AddLine(L["|cffffff00Click|r to toggle bar visibility"])
			tooltip:AddLine(L["|cffffff00Right-click|r to toggle locked state and anchor"])
			tooltip:AddLine(L["|cffffff00Shift-right-click|r to open the options menu"])
		end,
	})
end

--LibButtonFacade
local LBF = LibStub("LibButtonFacade", true)
function QuestItemBar:LoadLBF()
	if LBF then
		local group = LBF:Group("QuestItemBar", "QuestItemBar1")
		
		group.SkinID = self.db.profile.skin.ID or "Zoomed"
		group.Backdrop = self.db.profile.skin.Backdrop
		group.Gloss = self.db.profile.skin.Gloss
		group.Colors = self.db.profile.skin.Colors
		
		LBF:RegisterSkinCallback("QuestItemBar", self.SkinChanged, self)
		
		--group:Skin(skin.ID, skin.Gloss, skin.Backdrop, skin.Colors or {})
		
		self.LBFGroup = group
	end
end

function QuestItemBar:SkinChanged(SkinID, Gloss, Backdrop, Group, Button, Colors)
	self.db.profile.skin.ID = SkinID
	self.db.profile.skin.Gloss = Gloss
	self.db.profile.skin.Backdrop = Backdrop
	self.db.profile.skin.Colors = Colors
end
