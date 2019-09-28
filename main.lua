local ADDON_ID = 'Bam'
local BAM_SOUND = 'Interface/AddOns/Bam/sounds/bam.ogg'
local BAAAM_SOUND = 'Interface/AddOns/Bam/sounds/baaam.ogg'
local THROTTLE_SECONDS = 2

local ADDON_VERSION = GetAddOnMetadata(ADDON_ID, 'Version')
local ADDON_TITLE = GetAddOnMetadata(ADDON_ID, 'Title')
local PLAYER_GUID = UnitGUID('player')

local function ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

local function printBam(...)
  print('|cFF9BDBF5'..ADDON_TITLE, 'v'..ADDON_VERSION, ...)
end

local function formatBlue(msg)
  return format('|cFF9BDBF5%s|r', msg)
end

local function formatSetting(setting)
  if (setting) then
    return '|cFF4caf50ENABLED|r'
  else
    return '|cFFf44336DISABLED|r'
  end
end

local function throttle(func, seconds)
  local lastCalled = 0

  return function(...)
    if (time() - lastCalled < seconds) then
      return
    end
    
    lastCalled = time()
    return func(...)
  end
end

local throttledBamSound = throttle(function() PlaySoundFile(BAM_SOUND, 'Master') end, THROTTLE_SECONDS)
local throttledBaaamSound = throttle(function() PlaySoundFile(BAAAM_SOUND, 'Master') end, THROTTLE_SECONDS)

-- Application Code

local f = CreateFrame("Frame")
f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
f:SetScript("OnEvent", function(self, event)
  self:OnEvent(event, CombatLogGetCurrentEventInfo())
end)

function f:OnEvent(event, ...)
  local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...
  local spellId, spellName, spellSchool
  local environmentalType
  local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
  
  if (subevent == "SWING_DAMAGE") then
    amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
  elseif (subevent == "ENVIRONMENTAL_DAMAGE") then
    environmentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
  else
    spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, ...)
  end
  
  if (ends_with(subevent, '_DAMAGE') and critical and sourceGUID == PLAYER_GUID) then
    if (BamCharSettings['TRIGGER_ON_SWING'] or spellId) then
      if (overkill and overkill > 0) and BamCharSettings['BAAAM_ON_OVERKILL'] then
        if (BamCharSettings['THROTTLE_SOUNDS']) then
          throttledBaaamSound()
        else
          PlaySoundFile(BAAAM_SOUND, 'Master')
        end
      else
        if (BamCharSettings['THROTTLE_SOUNDS']) then
          throttledBamSound()
        else
          PlaySoundFile(BAM_SOUND, 'Master')
        end
      end
    end
  end
end

SLASH_BAM1 = '/bam'
SlashCmdList['BAM'] = function(command)
  if (command == 'swing') then
    BamCharSettings['TRIGGER_ON_SWING'] = not BamCharSettings['TRIGGER_ON_SWING']
    printBam('-- Sound trigger on Weapon(swing) crits', formatSetting(BamCharSettings['TRIGGER_ON_SWING']))
  elseif (command == 'overkill') then
    BamCharSettings['BAAAM_ON_OVERKILL'] = not BamCharSettings['BAAAM_ON_OVERKILL']
    printBam('-- Different Baaam! sound for Overkill crits', formatSetting(BamCharSettings['BAAAM_ON_OVERKILL']))
  elseif (command == 'throttle') then
    BamCharSettings['THROTTLE_SOUNDS'] = not BamCharSettings['THROTTLE_SOUNDS']
    printBam('-- Only play sounds every ' .. THROTTLE_SECONDS .. ' seconds (ANTI-BLIZZARD MODE! NO BABABABABABAM!)', formatSetting(BamCharSettings['THROTTLE_SOUNDS']))
  else
    throttledBamSound()
    printBam('Config')
    print('  Plays Bam! sounds every time you crit!|n|n')
    print('/bam swing|n-- Toggle Sound trigger on Weapon(Swing) crits.', 'Currently', formatSetting(BamCharSettings['TRIGGER_ON_SWING']))
    print('/bam overkill|n-- Toggle Different Baaam! sound for Overkill crits.', 'Currently', formatSetting(BamCharSettings['BAAAM_ON_OVERKILL']))
    print('/bam throttle|n-- Toggle Only play sounds every 2 seconds (ANTI-BLIZZARD MODE! NO BABABABABABAM!).', 'Currently', formatSetting(BamCharSettings['THROTTLE_SOUNDS']))
  end
end

local loadingFrame = CreateFrame("FRAME")
loadingFrame:RegisterEvent("ADDON_LOADED")
loadingFrame:SetScript("OnEvent", function(self, event, name)
  if (name == ADDON_ID) then 
    if (BamCharSettings == nil) then
      printBam('Welcome to Bam! Setting defaults...')
      BamCharSettings = {}
    end

    if (BamCharSettings['TRIGGER_ON_SWING'] == nil) then
      BamCharSettings['TRIGGER_ON_SWING'] = true
      print('-- Trigger on Weapon Swings', formatSetting(BamCharSettings['TRIGGER_ON_SWING']))
    end

    if (BamCharSettings['BAAAM_ON_OVERKILL'] == nil) then
      BamCharSettings['BAAAM_ON_OVERKILL'] = true
      print('-- Play BAAAM sound on Overkill', formatSetting(BamCharSettings['BAAAM_ON_OVERKILL']))
    end
    if (BamCharSettings['THROTTLE_SOUNDS'] == nil) then
      BamCharSettings['THROTTLE_SOUNDS'] = false
      print('-- Only play sounds every ' .. THROTTLE_SECONDS .. ' seconds (ANTI-BLIZZARD MODE! NO BABABABABABAM!)', formatSetting(BamCharSettings['THROTTLE_SOUNDS']))
    end
  end
end)
