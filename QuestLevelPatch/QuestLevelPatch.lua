--------------------------------------------------------------------------------------------------------
--                                    QuestLevelPatch variables                                       --
--------------------------------------------------------------------------------------------------------
local QuestLevel_original_GetQuestLogTitle = GetQuestLogTitle;
local QuestLevel_original_GetGossipAvailableQuests = GetGossipAvailableQuests;
local QuestLevel_original_GetGossipActiveQuests = GetGossipActiveQuests;

--------------------------------------------------------------------------------------------------------
--                                QuestLevelPatch hooked funcitons                                    --
--------------------------------------------------------------------------------------------------------
function GetQuestLogTitle(questIndex)
	questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = QuestLevel_original_GetQuestLogTitle(questIndex)
	if (questTitle and (not isHeader)) then
		questTitle = "["..level.."] "..questTitle
	end
	
	return questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID
end

function GetGossipAvailableQuests()
	-- name, level, isTrivial, isDaily, isRepeatable, ... = GetGossipAvailableQuests()
    local availableQuests = { QuestLevel_original_GetGossipAvailableQuests() }
    local i = 1
    while(availableQuests[i]) do
        availableQuests[i] = "["..availableQuests[i+1].."] "..availableQuests[i]
        i = i + 5
    end
	
	return unpackAvailableQuests(availableQuests)
end

function GetGossipActiveQuests()
	-- name, level, isTrivial, isDaily, ... = GetGossipActiveQuests()
    local activeQuests = { QuestLevel_original_GetGossipActiveQuests() }
    local i = 1
    while(activeQuests[i]) do
        activeQuests[i] = "["..activeQuests[i+1].."] "..activeQuests[i]
        i = i + 4
    end
	
	return unpackActiveQuests(activeQuests)
end

--------------------------------------------------------------------------------------------------------
--                                    QuestLevelPatch funcitons                                       --
--------------------------------------------------------------------------------------------------------
function unpackAvailableQuests(t, i)
	i = i or 1
	if t[i] then
		return t[i], t[i+1], t[i+2], t[i+3], t[i+4], unpackAvailableQuests(t, i+5)
	end
end

function unpackActiveQuests(t, i)
	i = i or 1
	if t[i] then
		return t[i], t[i+1], t[i+2], t[i+3], unpackActiveQuests(t, i+4)
	end
end
