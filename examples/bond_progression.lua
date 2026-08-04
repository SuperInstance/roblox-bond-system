-- examples/bond_progression.lua
-- Player going from Stranger to Partner over 10 builds using BondSystem.
-- Place in StarterPlayerScripts (LocalScript) for demo, or ServerScript for production.
--
-- Simulates a full relationship arc:
--   Session 1: Player builds a small house (Stranger → Acquaintance)
--   Session 2: Player returns next day, builds a tower, argues about design
--   Session 3: Player modifies instead of replacing, completes an open hook
--   Session 4: Player builds independently, reaches Trusted
--   Session 5: Player finishes everything, reaches Ally
--
-- Shows:
--   • BondSystem.recordBuild() — first-build-of-session bonus
--   • BondSystem.recordReturn() — returning after 24h
--   • BondSystem.recordModifyNotReplace() — investing in existing work
--   • BondSystem.recordHookCompleted() — the CORE LOOP
--   • BondSystem.recordArguedAndWon() — pushing back
--   • Tier transitions with voice lines
--   • Behavioral changes at each tier (formal → informal → arguing → "we")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BondSystem = require(ReplicatedStorage:WaitForChild("BondSystem"))

local PLAYER_ID = "TestPlayer"

-- ============================================================
--  Wire up hooks for the demo
-- ============================================================

BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    local names = BondSystem.getTierNames()
    print(string.format("\n🔄 TIER CHANGE: %s → %s\n",
        names[oldTier], names[newTier]))
end

BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    print(string.format("  🗣️ NPC says: \"%s\"", line))
end

BondSystem.hooks.onBondEvent = function(playerId, eventType, points)
    local sign = points >= 0 and "+" or ""
    print(string.format("  📊 Bond event: %s (%s%d points)",
        eventType, sign, points))
end

-- Mock persistence (in production: DataStoreService)
local mockDataStore = {}
BondSystem.hooks.persist = function(playerId, tier, bondPoints)
    mockDataStore[playerId] = { tier = tier, bondPoints = bondPoints }
end
BondSystem.hooks.load = function(playerId)
    return mockDataStore[playerId] and mockDataStore[playerId].tier,
           mockDataStore[playerId] and mockDataStore[playerId].bondPoints
end

-- ============================================================
--  Initialize
-- ============================================================

BondSystem.init()
print("\n" .. string.rep("═", 60))
print("  BOND PROGRESSION SIMULATION — 5 Sessions, 10 Builds")
print(string.rep("═", 60))

-- Helper: show current state
local function showState(session, buildNum)
    local tier = BondSystem.getTier(PLAYER_ID)
    local tierName = BondSystem.getTierName(PLAYER_ID)
    local points = BondSystem.getPoints(PLAYER_ID)
    local behaviors = BondSystem.getBehaviors(PLAYER_ID)

    print(string.format("\n── Session %d, Build %d ──", session, buildNum))
    print(string.format("  Tier: %d (%s) | Points: %d", tier, tierName, points))
    print(string.format("  Formal: %s | Argues: %s | Uses 'we': %s | Volunteers: %s",
        tostring(behaviors.uses_formal_address),
        tostring(behaviors.argues),
        tostring(behaviors.uses_we),
        tostring(behaviors.volunteers_work)))
end

-- Helper: simulate an NPC dialogue line based on bond tier
local function npcSay(context)
    local tier = BondSystem.getTier(PLAYER_ID)
    local behaviors = BondSystem.getBehaviors(PLAYER_ID)

    -- NPC voice shifts with tier
    if behaviors.uses_formal_address then
        print(string.format("  🗣️ NPC: \"Understood. I will construct that for you.\" (%s)", context))
    elseif behaviors.argues and math.random() > 0.5 then
        print(string.format("  🗣️ NPC: \"Hmm, I'd do it differently — but fine, your call.\" (%s)", context))
    elseif behaviors.uses_we then
        print(string.format("  🗣️ NPC: \"We can build this together. I'll handle the foundation.\" (%s)", context))
    else
        print(string.format("  🗣️ NPC: \"Sure thing! Let me get started on that.\" (%s)", context))
    end
end

-- ============================================================
--  Session 1: First time player (Stranger)
-- ============================================================

print("\n\n▶▶ SESSION 1: First Contact\n")
-- Simulate returning (sets lastSeen far enough back for the return bonus later)
local data = BondSystem.getPlayerData(PLAYER_ID)
data.lastSeen = os.time() - (86400 * 2)  -- 2 days ago

BondSystem.recordBuild(PLAYER_ID)  -- +1 first_build_of_session
showState(1, 1)
npcSay("player arrives for the first time")

BondSystem.recordBuild(PLAYER_ID)  -- builds again (no bonus, just updates lastSeen)
BondSystem.recordBuild(PLAYER_ID)
showState(1, 3)

-- Player builds a small house
BondSystem.recordBuild(PLAYER_ID)
npcSay("building a house")
showState(1, 4)

-- By now the player should be Acquaintance (need 10 points for tier 1)
-- Let's say the player completed a hook (something the NPC left unfinished)
BondSystem.registerOpenHook(PLAYER_ID, "house_roof",
    "The roof was left unfinished from last time",
    Vector3.new(0, 10, 0))
BondSystem.recordHookCompleted(PLAYER_ID, "house_roof")  -- +5 (CORE LOOP!)
showState(1, 5)

-- ============================================================
--  Session 2: Return next day (Acquaintance → Companion?)
-- ============================================================

print("\n\n▶▶ SESSION 2: Returning Player\n")

-- Simulate time passage (24h+)
data = BondSystem.getPlayerData(PLAYER_ID)
data.lastSeen = os.time() - (86400 + 3600)  -- 25 hours ago

BondSystem.recordReturn(PLAYER_ID)  -- +2 returned_next_day
BondSystem.recordBuild(PLAYER_ID)   -- +1 first_build_of_session
showState(2, 1)
npcSay("player returns after a day")

-- Player builds a tower
BondSystem.recordBuild(PLAYER_ID)
BondSystem.recordIndependentBuild(PLAYER_ID)  -- +3 independent_build
npcSay("player builds without being asked")

-- Player argues about the design AND wins
BondSystem.recordArguedAndWon(PLAYER_ID)  -- +4 argued_and_won
print("  💢 Player argued with the NPC about tower height — and won!")
showState(2, 2)

-- Another hook completed
BondSystem.registerOpenHook(PLAYER_ID, "tower_windows",
    "Windows were left out of the tower",
    Vector3.new(5, 15, 5))
BondSystem.recordHookCompleted(PLAYER_ID, "tower_windows")  -- +5
showState(2, 3)

-- ============================================================
--  Session 3: Modifications and investment (Companion → Trusted?)
-- ============================================================

print("\n\n▶▶ SESSION 3: Deepening Relationship\n")

data = BondSystem.getPlayerData(PLAYER_ID)
data.lastSeen = os.time() - (86400 * 3)  -- 3 days later

BondSystem.recordReturn(PLAYER_ID)   -- +2
BondSystem.recordBuild(PLAYER_ID)    -- +1
npcSay("third visit")

-- Player improves existing work instead of deleting
BondSystem.recordModifyNotReplace(PLAYER_ID)  -- +2
print("  🔧 Player modified existing work instead of replacing")
npcSay("modifying instead of replacing")

-- Two more hook completions
BondSystem.registerOpenHook(PLAYER_ID, "garden_path",
    "Garden path left incomplete",
    Vector3.new(10, 0, 15))
BondSystem.recordHookCompleted(PLAYER_ID, "garden_path")  -- +5

BondSystem.registerOpenHook(PLAYER_ID, "fountain",
    "Fountain plumbing unfinished",
    Vector3.new(3, 0, 20))
BondSystem.recordHookCompleted(PLAYER_ID, "fountain")  -- +5

showState(3, 1)

-- ============================================================
--  Session 4: Full trust (Trusted → Ally?)
-- ============================================================

print("\n\n▶▶ SESSION 4: The Final Push\n")

data = BondSystem.getPlayerData(PLAYER_ID)
data.lastSeen = os.time() - (86400 * 2)

BondSystem.recordReturn(PLAYER_ID)   -- +2
BondSystem.recordBuild(PLAYER_ID)    -- +1
npcSay("player returns")

-- Lots of independent work
BondSystem.recordIndependentBuild(PLAYER_ID)  -- +3
BondSystem.recordIndependentBuild(PLAYER_ID)  -- +3
BondSystem.recordModifyNotReplace(PLAYER_ID)  -- +2

-- One more hook
BondSystem.registerOpenHook(PLAYER_ID, "watchtower",
    "Watchtower left without a roof",
    Vector3.new(20, 0, 0))
BondSystem.recordHookCompleted(PLAYER_ID, "watchtower")  -- +5

showState(4, 1)

-- ============================================================
--  Final State: Check if player reached Ally
-- ============================================================

print("\n\n" .. string.rep("═", 60))
print("  FINAL STATE")
print(string.rep("═", 60))

local finalData = BondSystem.getPlayerData(PLAYER_ID)
print(string.format("  Tier: %d (%s)", finalData.tier, finalData.tierName))
print(string.format("  Bond Points: %d", finalData.bondPoints))
print(string.format("  Hooks Completed: %d", finalData.hooksCompleted))

local progress = finalData.progress
if progress.nextTier then
    print(string.format("  Progress to next: %d/%d (%.0f%%)",
        progress.current, progress.needed, progress.pct * 100))
else
    print("  MAX TIER REACHED")
end

-- Check behavioral unlocks
local b = finalData.behaviors
print("\n  Behavioral Profile:")
print(string.format("    Argues:        %s", tostring(b.argues)))
print(string.format("    Volunteers:    %s", tostring(b.volunteers_work)))
print(string.format("    Uses 'we':     %s", tostring(b.uses_we)))
print(string.format("    Delegates:     %s", tostring(b.delegates_to_player)))
print(string.format("    Remembers:     %s", tostring(b.remembers_conversation)))
print(string.format("    Uses nicknames: %s", tostring(b.use_nicknames)))

-- Check for confession
if BondSystem.shouldDeliverConfession(PLAYER_ID) then
    print("\n  🤐 One-time confession available!")
    BondSystem.markConfessionDelivered(PLAYER_ID)
    print("  🗣️ NPC: \"I built here for thirty years before you showed up.")
    print("         I was ready to stop. I'm not anymore.\"")
end

print("\n" .. string.rep("═", 60))
