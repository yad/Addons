﻿--[[
Name: LibBabble-Class-3.0
Revision: $Rev: 50 $
Author(s): ckknight (ckknight@gmail.com)
Website: http://ckknight.wowinterface.com/
Description: A library to provide localizations for classes.
Dependencies: None
License: MIT
Locales: enUS, deDE, frFR, zhCN, zhTW, koKR, esES, esMX, ruRU
]]

local MAJOR_VERSION = "LibBabble-Class-3.0"
local MINOR_VERSION = 90000 + tonumber(("$Revision: 50 $"):match("%d+"))

if not LibStub then error("LibBabble-Class-3.0 requires LibStub.") end
local lib = LibStub("LibBabble-3.0"):New(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

lib:SetBaseTranslations {
	["Warlock"] = "Warlock",
	["Warrior"] = "Warrior",
	["Hunter"] = "Hunter",
	["Mage"] = "Mage",
	["Priest"] = "Priest",
	["Druid"] = "Druid",
	["Paladin"] = "Paladin",
	["Shaman"] = "Shaman",
	["Rogue"] = "Rogue",
	["Death Knight"] = "Death Knight",
	
	["WARLOCK"] = "Warlock",
	["WARRIOR"] = "Warrior",
	["HUNTER"] = "Hunter",
	["MAGE"] = "Mage",
	["PRIEST"]  = "Priest",
	["DRUID"] = "Druid",
	["PALADIN"] = "Paladin",
	["SHAMAN"] = "Shaman",
	["ROGUE"] = "Rogue",
	["DEATH KNIGHT"] = "Death Knight",
}

local l = GetLocale()
if l == "enUS" then
	lib:SetCurrentTranslations(true)
elseif l == "deDE" then
	lib:SetCurrentTranslations {
		["Warlock"] = "Hexenmeister",
		["Warrior"] = "Krieger",
		["Hunter"] = "Jäger",
		["Mage"] = "Magier",
		["Priest"] = "Priester",
		["Druid"] = "Druide",
		["Paladin"] = "Paladin",
		["Shaman"] = "Schamane",
		["Rogue"] = "Schurke",
		["Death Knight"] = "Todesritter",

		["WARLOCK"] = "Hexenmeisterin",
		["WARRIOR"] = "Kriegerin",
		["HUNTER"] = "Jägerin",
		["MAGE"] = "Magierin",
		["PRIEST"] = "Priesterin",
		["DRUID"] = "Druidin",
		["PALADIN"] = "Paladin",
		["SHAMAN"] = "Schamanin",
		["ROGUE"] = "Schurkin",
		["DEATH KNIGHT"] = "Todesritter",
	}
elseif l == "frFR" then
	lib:SetCurrentTranslations {
		["Warlock"] = "Démoniste",
		["Warrior"] = "Guerrier",
		["Hunter"] = "Chasseur",
		["Mage"] = "Mage",
		["Priest"] = "Prêtre",
		["Druid"] = "Druide",
		["Paladin"] = "Paladin",
		["Shaman"] = "Chaman",
		["Rogue"] = "Voleur",
		["Death Knight"] = "Chevalier de la mort",

		["WARLOCK"] = "Démoniste",
		["WARRIOR"] = "Guerrière",
		["HUNTER"] = "Chasseresse",
		["MAGE"] = "Mage",
		["PRIEST"] = "Prêtresse",
		["DRUID"] = "Druidesse",
		["PALADIN"] = "Paladin",
		["SHAMAN"] = "Chamane",
		["ROGUE"] = "Voleuse",
		["DEATH KNIGHT"] = "Chevalier de la mort",
	}
elseif l == "zhCN" then
	lib:SetCurrentTranslations {
		["Warlock"] = "术士",
		["Warrior"] = "战士",
		["Hunter"] = "猎人",
		["Mage"] = "法师",
		["Priest"] = "牧师",
		["Druid"] = "德鲁伊",
		["Paladin"] = "圣骑士",
		["Shaman"] = "萨满祭司",
		["Rogue"] = "潜行者",
		["Death Knight"] = "死亡骑士",

		["WARLOCK"] = "术士",
		["WARRIOR"] = "战士",
		["HUNTER"] = "猎人",
		["MAGE"] = "法师",
		["PRIEST"] = "牧师",
		["DRUID"] = "德鲁伊",
		["PALADIN"] = "圣骑士",
		["SHAMAN"] = "萨满祭司",
		["ROGUE"] = "潜行者",
		["DEATH KNIGHT"] = "死亡骑士",
	}
elseif l == "zhTW" then
	lib:SetCurrentTranslations {
		["Warlock"] = "術士",
		["Warrior"] = "戰士",
		["Hunter"] = "獵人",
		["Mage"] = "法師",
		["Priest"] = "牧師",
		["Druid"] = "德魯伊",
		["Paladin"] = "聖騎士",
		["Shaman"] = "薩滿",
		["Rogue"] = "盜賊",
		["Death Knight"] = "死亡騎士",

		["WARLOCK"] = "術士",
		["WARRIOR"] = "戰士",
		["HUNTER"] = "獵人",
		["MAGE"] = "法師",
		["PRIEST"] = "牧師",
		["DRUID"] = "德魯伊",
		["PALADIN"] = "聖騎士",
		["SHAMAN"] = "薩滿",
		["ROGUE"] = "盜賊",
		["DEATH KNIGHT"] = "死亡騎士",
	}
elseif l == "koKR" then
	lib:SetCurrentTranslations {
		["Warlock"] = "흑마법사",
		["Warrior"] = "전사",
		["Hunter"] = "사냥꾼",
		["Mage"] = "마법사",
		["Priest"] = "사제",
		["Druid"] = "드루이드",
		["Paladin"] = "성기사",
		["Shaman"] = "주술사",
		["Rogue"] = "도적",
		["Death Knight"] = "죽음의 기사",
		
		["WARLOCK"] = "흑마법사",
		["WARRIOR"] = "전사",
		["HUNTER"] = "사냥꾼",
		["MAGE"] = "마법사",
		["PRIEST"] = "사제",
		["DRUID"] = "드루이드",
		["PALADIN"] = "성기사",
		["SHAMAN"] = "주술사",
		["ROGUE"] = "도적",
		["DEATH KNIGHT"] = "죽음의 기사",
	}
elseif l == "esES" then
	lib:SetCurrentTranslations {
		["Warlock"] = "Brujo",
		["Warrior"] = "Guerrero",
		["Hunter"] = "Cazador",
		["Mage"] = "Mago",
		["Priest"] = "Sacerdote",
		["Druid"] = "Druida",
		["Paladin"] = "Paladín",
		["Shaman"] = "Chamán",
		["Rogue"] = "Pícaro",
		["Death Knight"] = "Caballero de la muerte",
		
		["WARLOCK"] = "Bruja",
		["WARRIOR"] = "Guerrera",
		["HUNTER"] = "Cazadora",
		["MAGE"] = "Maga",
		["PRIEST"] = "Sacerdotisa",
		["DRUID"] = "Druida",
		["PALADIN"] = "Paladín",
		["SHAMAN"] = "Chamán",
		["ROGUE"] = "Pícara",
		["DEATH KNIGHT"] = "Caballero de la muerte",
	}
elseif l == "esMX" then
	lib:SetCurrentTranslations {
		["Warlock"] = "Brujo",
		["Warrior"] = "Guerrero",
		["Hunter"] = "Cazador",
		["Mage"] = "Mago",
		["Priest"] = "Sacerdote",
		["Druid"] = "Druida",
		["Paladin"] = "Paladín",
		["Shaman"] = "Chamán",
		["Rogue"] = "Pícaro",
		["Death Knight"] = "Caballero de la muerte",
		
		["WARLOCK"] = "Bruja",
		["WARRIOR"] = "Guerrera",
		["HUNTER"] = "Cazadora",
		["MAGE"] = "Maga",
		["PRIEST"] = "Sacerdotisa",
		["DRUID"] = "Druida",
		["PALADIN"] = "Paladín",
		["SHAMAN"] = "Chamán",
		["ROGUE"] = "Pícara",
		["DEATH KNIGHT"] = "Caballero de la muerte",
	}
elseif l == "ruRU" then
	lib:SetCurrentTranslations {
		["Warlock"] = "Чернокнижник",
		["Warrior"] = "Воин",
		["Hunter"] = "Охотник",
		["Mage"] = "Маг",
		["Priest"] = "Жрец",
		["Druid"] = "Друид",
		["Paladin"] = "Паладин",
		["Shaman"] = "Шаман",
		["Rogue"] = "Разбойник",
		["Death Knight"] = "Рыцарь смерти",
		
		["WARLOCK"] = "Чернокнижница",
		["WARRIOR"] = "Воин",
		["HUNTER"] = "Охотница",
		["MAGE"] = "Маг",
		["PRIEST"] = "Жрица",
		["DRUID"] = "Друид",
		["PALADIN"] = "Паладин",
		["SHAMAN"] = "Шаманка",
		["ROGUE"] = "Разбойница",
		["DEATH KNIGHT"] = "Рыцарь смерти",
		
	}
else
	error(("%s: Locale %q not supported"):format(MAJOR_VERSION, GAME_LOCALE))
end
