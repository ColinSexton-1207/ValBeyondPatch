-- Gives every party member the patch's toggle passives (off by default), and
-- swaps out the original mod's rule passive while Spell Freedom is toggled on.
-- Logs go to the Script Extender console, prefixed with [ValBeyondPatch].

local function Log(message, ...)
    Ext.Utils.Print("[ValBeyondPatch] " .. string.format(message, ...))
end

local Toggles = {
    "VBP_SpellFreedom",
    "VBP_VanillaShortRests",
}

-- Toggle status -> original passives to remove while it's on.
local Replaces = {
    VBP_SPELL_FREEDOM = { "OneSpellWithASpellSlotPerTurn" },
}

local function IsPlayer(character)
    return #Osi.DB_Players:Get(character) > 0
end

local function ApplyReplacements(character, status)
    local enabled = Osi.HasActiveStatus(character, status) == 1
    for _, passive in ipairs(Replaces[status]) do
        local has = Osi.HasPassive(character, passive) == 1
        if enabled and has then
            Osi.RemovePassive(character, passive)
            Log("%s: removed %s", character, passive)
        elseif not enabled and not has and IsPlayer(character) then
            -- The original mod grants these to players only.
            Osi.AddPassive(character, passive)
            Log("%s: restored %s", character, passive)
        end
    end
end

local function SyncCharacter(character)
    for _, passive in ipairs(Toggles) do
        if Osi.HasPassive(character, passive) ~= 1 then
            Osi.AddPassive(character, passive)
            Log("%s: granted %s", character, passive)
        end
    end
    for status in pairs(Replaces) do
        ApplyReplacements(character, status)
    end
end

local function SyncParty()
    local rows = Osi.DB_Players:Get(nil)
    Log("syncing %d player characters", #rows)
    for _, row in pairs(rows) do
        SyncCharacter(row[1])
    end
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function() SyncParty() end)
Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", SyncCharacter)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status)
    if Replaces[status] then
        ApplyReplacements(character, status)
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status)
    if Replaces[status] then
        ApplyReplacements(character, status)
    end
end)

Log("server script loaded")
