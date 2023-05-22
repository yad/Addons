-- first, create a frame to respond to events
local RPHelmFrame = CreateFrame("FRAME", nil, UIParent)
RPHelmFrame:Hide()

RPHelm = {}
RPHelm_config = {}

-- defaults
RPHelm_config.master = 1
RPHelm_config.helmcombat = 1
RPHelm_config.helmnocombat = nil
RPHelm_config.cloakcombat = 1
RPHelm_config.cloaknocombat = 1

RPHelm_config.pvpascombat = nil

local debugmode = false
local incombat = false

local function Debug(text)
  if debugmode then
    print(text)
  end
end

function RPHelm.AutoSwitch(force)
  -- if we're turned off and this gets called, do nothing
  -- unless it's a force (i.e., the player told us to)
  if not RPHelm_config.master and force ~= 1 then 
    return 
  end
  Debug("RPHelm.AutoSwitch called")
  if incombat then
    ShowHelm(RPHelm_config.helmcombat)
    ShowCloak(RPHelm_config.cloakcombat)
  else
    ShowHelm(RPHelm_config.helmnocombat)
    ShowCloak(RPHelm_config.cloaknocombat)
  end
end

local function PVPTest()
  if UnitIsPVP("player") or UnitIsPVPFreeForAll("player") then 
    return true
  else
    return false
  end
end

function RPHelm.OnEvent(self, event, unit)
  if event == "PLAYER_REGEN_DISABLED" then
    -- we're entering combat, for real
    incombat = true
    Debug("RPHelm: player entered combat")
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- we're leaving combat
    -- next line may be a little confusing.  It's logically equivalent
    -- to "not (RPHelm_config.pvpascombat and PVPTest())"
    -- but doing it this way lets us "shortcut" out if the pvpascombat
    -- flag is off
    if not RPHelm_config.pvpascombat or not PVPTest() then
       incombat = false
       Debug("RPHelm: player left combat")
    end
  elseif event == "UNIT_FACTION" then
    -- someone's PVP status changed. See if our player is in PVP, if 
    -- the player wants us changing on PVP
    if RPHelm_config.pvpascombat and PVPTest() then
      incombat = true
    -- we don't switch off the combat flag if the player really is in
    -- combat!
    elseif not UnitAffectingCombat("player") then
      incombat = false
    end
  end
  -- and lastly, having figured out if we're "in combat", call
  -- AutoSwitch() to do the actual work
  RPHelm.AutoSwitch()
end 

RPHelmFrame:SetScript("OnEvent", RPHelm.OnEvent)
RPHelmFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
RPHelmFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
RPHelmFrame:RegisterEvent("UNIT_FACTION")

-- Slash commands
function RPHelm.mainslash(str)

  -- parse flags (e.g., [mod:shift], but ignore target info
  str, _ = SecureCmdOptionParse(str)
  
  -- if all flags were removed, ignore the command
  if str == nil then
    return
  end

  -- if str is master, toggle the master switch
  -- if str is debug, turn on/off debugging
  -- if str is ready or combat, put us "in combat"
  -- if str is unready or nocombat, take us "out of combat"
  -- otherwise, show the GUI
  if str == "master" then
    RPHelm.ToggleOption("master") 
  elseif str == "debug" then
    debugmode = not debugmode
    if debugmode then print("Debugging mode on.") 
    else print("Debugging mode off.") end
  elseif str == "ready" or str == "combat" then
    incombat = true
    RPHelm.AutoSwitch(1)
  elseif str == "unready" or str == "nocombat" then
    incombat = false
    RPHelm.AutoSwitch(1)
  else
    InterfaceOptionsFrame_OpenToCategory(RPHelmOptions)
    RPHelm.AutoSwitch()
  end
end

SLASH_RPHELMMAIN1 = "/rphelm"
SlashCmdList["RPHELMMAIN"] = RPHelm.mainslash

function RPHelm.cloakslash(str)
  local args = {}
  
  Debug("/cloak called with "..str)
  
  -- parse flags (e.g., [mod:shift]), but ignore target info
  str, _ = SecureCmdOptionParse(str)
  
  -- if all options were removed, then don't do anything
  if str == nil then
    return
  end
  Debug("after parsing, options are: "..str)
  
  for v in string.gmatch(str, "[^ ]+") do
    tinsert(args, v)
  end
  if args[1] and ( strlower(args[1]) == "show" or strlower(args[1]) == "on" ) then
    ShowCloak(1)
  elseif args[1] and ( strlower(args[1]) == "hide" or strlower(args[1]) == "off" ) then
    ShowCloak(nil)
  else
    if ShowingCloak() then
      ShowCloak(nil)
    else
      ShowCloak(1)
    end
  end
end

SLASH_RPHELMCLOAK1 = "/cloak"
SlashCmdList["RPHELMCLOAK"] = RPHelm.cloakslash

function RPHelm.helmslash(str)
  local args = {}
  
  -- parse flags (e.g., [mod:shift]), but ignore target info
  str, _ = SecureCmdOptionParse(str)
  
  -- if all options were removed, then don't do anything
  if str == nil then
    return
  end
  
  for v in string.gmatch(str, "[^ ]+") do
    tinsert(args, v)
  end
  if args[1] and ( strlower(args[1]) == "show" or strlower(args[1]) == "on" ) then
    ShowHelm(1)
  elseif args[1] and ( strlower(args[1]) == "hide" or strlower(args[1]) == "off" ) then
    ShowHelm(nil)
  else
    if ShowingHelm() then
      ShowHelm(nil)
    else
      ShowHelm(1)
    end
  end
end

SLASH_RPHELMHELM1 = "/helm"
SlashCmdList["RPHELMHELM"] = RPHelm.helmslash

-- GUI functions

function RPHelm.OptionsOnLoad(panel)
  panel.name = "RPHelm"
  panel.ok = nil
  panel.cancel = nil
  RPHelmOptionsVersion:SetText(GetAddOnMetadata("RPHelm","Version"))
  InterfaceOptions_AddCategory(panel)
end

function RPHelm.CheckButtonText(self, text, tooltiptext)
  local textobj = _G[self:GetName().."Text"]
  textobj:SetText(text)
  self.tooltipText = tooltiptext
end

function RPHelm.ToggleOption(option)
  if RPHelm_config[option] == nil then
    RPHelm_config[option] = 1
  else
    RPHelm_config[option] = nil
  end
  if option == "master" then
    if RPHelm_config.master == 1 then
      RPHelmFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
      RPHelmFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
      RPHelmFrame:RegisterEvent("UNIT_FACTION")
    else
      RPHelmFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
      RPHelmFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
      RPHelmFrame:UnregisterEvent("UNIT_FACTION")
    end
  end
  RPHelm.AutoSwitch()
end
