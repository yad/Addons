local DGV = DugisGuideViewer
if not DGV then return end
L = DugisLocals
local patch4_0 = patch4_0
-- Arrays containing all professions available in WoW
local mainprof = {L["Alchemy"], L["Blacksmithing"], L["Enchanting"], L["Engineering"], L["Jewelcrafting"], L["Leatherworking"], L["Mining"], L["Tailoring"], L["Inscription"], 
L["Cooking"], L["First Aid"], L["Poisons"], L["Runeforging"], L["Fishing"], L["Herbalism"], L["Skinning"]}
-- Arrays containing professions known by the character and their skill levels
local professions = {}
local professionsmax = {}
--Called from TRADE_SKILL_UPDATE event
function DGV:UpdateProfessions()
local i, val, skillIndex
if DugisGuideViewer:isValidGuide(CurrentTitle) == true then
professions = {}
professionsmax = {}
if DugisGuideViewer.gtype[CurrentTitle] == "E" then --achieve/prof guide type
--Enable lines 23 - 33 for patch 4.0.1 functions
if patch4_0 == true then
DebugPrint("patch4_0 profs")
local profs = {}
--prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
profs[1], profs[2], profs[3], profs[4], profs[5], profs[6] = GetProfessions();
for i, val in pairs(profs) do
local name, icon, skillLevel, maxSkillLevel = GetProfessionInfo(val)
professions[name] = skillLevel 
professionsmax[name] = maxSkillLevel
--DebugPrint("prof name"..name.."prof level"..skillLevel)
end
--Enable lines 35 - 50 for PRE patch 4.0.1 functions
else
DebugPrint("patch3_3 profs")
for skillIndex = 1, GetNumSkillLines() do
local skillName, isHeader, _, skillRank, _, _, maxSkillLevel = GetSkillLineInfo(skillIndex)
if isHeader == nil then
for key,value in pairs(mainprof) do  
if value == skillName then
if value == L["Mining"] then
value = L["Smelting"]
end
professions[value] = skillRank
professionsmax[value] = maxSkillLevel
end
end
end
end
end
local guidesize = DGV:getGuideSize(CurrentTitle, string.split("\n","\n"..DGV.guides[CurrentTitle]()))
for i=1, guidesize do
if self:ProfessionCompletedAtGuideIndex(i) then 
self:SetChkToComplete(i) 
if i == CurrentQuestIndex then self:MoveToNextQuest() end
end
end
end
end
end
function DugisGuideViewer:ProfessionCompletedAtGuideIndex(guideindx)
local prof, prof2, proflvl, ret, profmax
ret = false
--achieve/prof guide
if self.gtype[CurrentTitle] == "E" then 
prof, proflvl = self:ReturnTag("P", guideindx)
prof2, profmax = self:ReturnTag("PM", guideindx)
if (prof and DGV:HasProfession(prof) and self:GetProfessionLevel(prof) >= proflvl) or
(prof2 and DGV:HasProfession(prof2) and self:GetProfessionMaxLevel(prof2) >= profmax) then
--DebugPrint("prof="..prof.."proflvl="..proflvl.."guideindex="..guideindx)
ret = true
end
end
return ret
end
--Input: Profession name string
--Returns: Level of profession or nil if no profession by that name
function DGV:GetProfessionLevel(profname)
if professions[profname] then
return professions[profname]
end
return nil
end
--Input: Profession name string
--Returns: Level of max profession or nil if no profession by that name
function DGV:GetProfessionMaxLevel(profname)
if professionsmax[profname] then
return professionsmax[profname]
end
return nil
end
--Input: Profession name string
--Returns: true or false if they have that profession
function DGV:HasProfession(profname)
if professions[profname] then
return professions[profname]
end
return nil
end
function DGV:PrintProfessions()
for skillIndex = 1, GetNumSkillLines() do
skillName, isHeader, _, skillRank, _, _, _, _, _, _, _, _, _ = GetSkillLineInfo(skillIndex)
if isHeader == nil then
for key,value in pairs(mainprof) do  
if value == skillName then
DebugPrint("PROF:"..value.."LEVEL:"..skillRank)
end
end
end
end
end
function DGV:ScanTradeSkills()
local tradeItemCount, tradeItemName, tradeItemType, tradeItemLink, producedItemCount
local tradeItemTool, reagentCount, tradeItemRecipeLink
local reagentName, singleReagentCount, reagentItemLink, currentTradeSkillLevel, tradeSkillName
local i, j
playerName = UnitName("player")
tradeItemCount = GetNumTradeSkills()
tradeSkillName, currentTradeSkillLevel, _ = GetTradeSkillLine()
for i = 1, tradeItemCount do
tradeItemName, tradeItemType, _, _ = GetTradeSkillInfo(i)
_, producedItemCount = GetTradeSkillNumMade(i)
-- Scan recipe
if tradeItemType ~= "header" then
tradeItemLink = GetTradeSkillItemLink(i)
tradeItemTool = GetTradeSkillTools(i)
reagentCount = GetTradeSkillNumReagents(i)
tradeItemRecipeLink = GetTradeSkillRecipeLink(i)
end
if (tradeItemType and tradeItemName) then
if tradeItemType ~= "header" then
DebugPrint("tradeItemName="..tradeItemName)
if tradeItemLink and (reagentCount ~= nil) and tradeItemRecipeLink then
if (self:CheckReagents(i, reagentCount)) then
-- Add reagents
for j = 1, reagentCount do
reagentName, _, singleReagentCount, _ = GetTradeSkillReagentInfo(i, j)
reagentItemLink = GetTradeSkillReagentItemLink(i, j)
DebugPrint("reagentName="..reagentName)
end
end
end
end
end
end
end
function DGV:CheckReagents(recipeID, reagentCount)
local singleReagentCount, reagentName, reagentItemLink, i
for j = 1, reagentCount do
reagentName, _, singleReagentCount, _ = GetTradeSkillReagentInfo(recipeID, j)
reagentItemLink = GetTradeSkillReagentItemLink(recipeID, j)
if reagentName == nil  or singleReagentCount == nil or reagentItemLink == nil then
return false
end
end
return true
end
