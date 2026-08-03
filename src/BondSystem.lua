--!strict
--[[
    BondSystem — Behavior-Triggered Relationship Module for Roblox
    ===============================================================
    A standalone, zero-dependency relationship engine.

    Instead of grinding XP, players deepen relationships through
    meaningful behavior. Each tier changes how the world reacts
    to them — not through UI notifications, but through behavior
    shifts that the player feels naturally.

    Five Tiers (0-indexed):
        0 — Stranger        (0–9 points)     Transactional.
        1 — Acquaintance    (10–29 points)   Noticed. Drops formality.
        2 — Companion       (30–69 points)   Will argue. Volunteers help.
        3 — Trusted         (70–149 points)  Says "we." Shared world.
        4 — Ally            (150+ points)    Full trust. Full honesty.

    Behavior Triggers:
        +1   first_build_of_session — showing up
        +5   hook_completed — finished something left unfinished (CORE LOOP)
        +3   independent_build — built something without being asked
        +2   modify_not_replace — improved existing work instead of replacing
        +4   argued_and_won — pushed back and was right
        +2   returned_next_day — came back after 24h+ absence
        -1   deleted_without_inspection — dismissed work without looking

    Integration:
        Use the hooks table to wire up your own systems:
            BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier) ... end
            BondSystem.hooks.onBondEvent = function(playerId, eventType, points) ... end
            BondSystem.hooks.onTransitionLine = function(playerId, tier, line) ... end
            BondSystem.hooks.persist = function(playerId, tier, bondPoints) ... end
            BondSystem.hooks.load = function(playerId) -> tier, bondPoints ... end

    Usage:
        local BondSystem = require(path.to.BondSystem)
        BondSystem.init()

        BondSystem.recordBuild("player1")
        local tier = BondSystem.getTier("player1")
        local behaviors = BondSystem.getBehaviors("player1")
        if behaviors.argues then print("They'll push back now.") end

    License: MIT
]]

local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Bond point thresholds for each tier (cumulative).
local TIER_THRESHOLDS = {
    [0] = 0,     -- Stranger
    [1] = 10,    -- Acquaintance
    [2] = 30,    -- Companion
    [3] = 70,    -- Trusted
    [4] = 150,   -- Ally
}

-- Maximum tier index
local MAX_TIER = 4

-- Tier names
local TIER_NAMES = {
    [0] = "Stranger",
    [1] = "Acquaintance",
    [2] = "Companion",
    [3] = "Trusted",
    [4] = "Ally",
}

-- Tier descriptions (design reference, not shown to player)
local TIER_DESCRIPTIONS = {
    [0] = "Transactional. Formal. Does the job, states the facts, offers one opinion. No personal references.",
    [1] = "Drops formality. References previous interactions. Begins asking questions. First personal details emerge.",
    [2] = "Disagreement unlocked. Volunteers help unprompted. Uses nicknames. Compliments are earned, specific, deflected.",
    [3] = "Speaks in 'we.' Treats the world as shared. Asks the player to do things. May refuse work out of preference. Remembers conversation, not just actions.",
    [4] = "Full honesty. Delegates to the player. Stops holding things back. The deepest level of trust.",
}

-- Bond event point values
local BOND_EVENTS = {
    first_build_of_session = 1,
    hook_completed = 5,
    independent_build = 3,
    modify_not_replace = 2,
    argued_and_won = 4,
    returned_next_day = 2,
    deleted_without_inspection = -1,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- BEHAVIORAL UNLOCKS PER TIER
-- ═══════════════════════════════════════════════════════════════════════════

local TIER_BEHAVIORS = {
    [0] = {
        uses_formal_address = true,
        references_previous_builds = false,
        asks_questions = false,
        argues = false,
        volunteers_work = false,
        uses_we = false,
        asks_player_to_build = false,
        refuses_work = false,
        remembers_conversation = false,
        confesses_pattern = false,
        delegates_to_player = false,
        leaves_things_unfinished = true,
        uses_nicknames = false,
        shares_opinions = false,
    },
    [1] = {
        uses_formal_address = false,
        references_previous_builds = true,
        asks_questions = true,
        argues = false,
        volunteers_work = false,
        uses_we = false,
        asks_player_to_build = false,
        refuses_work = false,
        remembers_conversation = false,
        confesses_pattern = false,
        delegates_to_player = false,
        leaves_things_unfinished = true,
        uses_nicknames = false,
        shares_opinions = true,
    },
    [2] = {
        uses_formal_address = false,
        references_previous_builds = true,
        asks_questions = true,
        argues = true,
        volunteers_work = true,
        uses_we = false,
        asks_player_to_build = false,
        refuses_work = false,
        remembers_conversation = false,
        confesses_pattern = false,
        delegates_to_player = false,
        leaves_things_unfinished = true,
        uses_nicknames = true,
        shares_opinions = true,
    },
    [3] = {
        uses_formal_address = false,
        references_previous_builds = true,
        asks_questions = true,
        argues = true,
        volunteers_work = true,
        uses_we = true,
        asks_player_to_build = true,
        refuses_work = true,
        remembers_conversation = true,
        confesses_pattern = false,
        delegates_to_player = false,
        leaves_things_unfinished = true,
        uses_nicknames = true,
        shares_opinions = true,
    },
    [4] = {
        uses_formal_address = false,
        references_previous_builds = true,
        asks_questions = true,
        argues = true,
        volunteers_work = true,
        uses_we = true,
        asks_player_to_build = true,
        refuses_work = true,
        remembers_conversation = true,
        confesses_pattern = true,
        delegates_to_player = true,
        leaves_things_unfinished = false,
        uses_nicknames = true,
        shares_opinions = true,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- TIER TRANSITION LINES
-- ═══════════════════════════════════════════════════════════════════════════
-- These fire ONCE on tier transition. Override or extend via
-- BondSystem.setTransitionLines(tier, { "line1", "line2", ... }).

local TIER_TRANSITION_LINES = {
    [1] = {
        "Back again. Same kind of thing? You've got a type.",
        "Noticed you kept at it. Good. That one's yours.",
        "Second time. You're serious about this.",
    },
    [2] = {
        "That's good work. Better than mine would've been — don't let it go to your head.",
        "You've got opinions. Good. I've been waiting for someone to argue with.",
        "Nah. Do it yourself, you'll do it better. Been watching you.",
    },
    [3] = {
        "Been thinking about this since last time. We both know the ground here.",
        "We'll need more for this one.",
        "I need a hand. Help me out and I'll handle the rest.",
    },
    [4] = {
        "You've got a better eye for this than I do. Your call — I'll build whatever you point at.",
        "It runs. It's yours.",
        "I'll say it plain: I trust your judgment. That doesn't happen often.",
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- MODULE
-- ═══════════════════════════════════════════════════════════════════════════

local BondSystem = {}

-- Integration hooks. Wire these up to your own systems.
-- All hooks are optional. If nil, they're skipped.
BondSystem.hooks = {
    -- Fired when a player's tier changes.
    -- function(playerId: string, oldTier: number, newTier: number)
    onTierChanged = nil,

    -- Fired on every bond event.
    -- function(playerId: string, eventType: string, points: number)
    onBondEvent = nil,

    -- Fired when a transition voice line is selected.
    -- function(playerId: string, tier: number, line: string)
    onTransitionLine = nil,

    -- Persistence: save bond state. Fire-and-forget.
    -- function(playerId: string, tier: number, bondPoints: number)
    persist = nil,

    -- Persistence: load bond state on join.
    -- function(playerId: string) -> tier: number, bondPoints: number
    load = nil,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

-- Per-player state keyed by player ID.
local playerData: { [string]: { [string]: any } } = {}

-- Open hooks per player. Keyed by hookId.
local openHooks: { [string]: { [string]: { [string]: any } } } = {}

-- Get or create player bond data.
local function getData(playerId: string): { [string]: any }
    if not playerData[playerId] then
        playerData[playerId] = {
            bondPoints = 0,
            tier = 0,
            lastSeen = os.time(),
            sessionFirstBuild = false,
            behaviors = TIER_BEHAVIORS[0],
            eventLog = {},
            openHookCount = 0,
            totalHooks = 0,
            hooksCompleted = 0,
            confessionGiven = false,
        }
    end
    return playerData[playerId]
end

-- Get the tier for a given bond point total.
local function calculateTier(bondPoints: number): number
    local tier = 0
    for checkTier = MAX_TIER, 0, -1 do
        if bondPoints >= TIER_THRESHOLDS[checkTier] then
            tier = checkTier
            break
        end
    end
    return tier
end

-- Record a bond event in the player's event log (keeps last 20).
local function logEvent(playerId: string, eventType: string, points: number)
    local data = getData(playerId)
    local log = data.eventLog
    if typeof(log) ~= "table" then
        log = {}
        data.eventLog = log
    end
    table.insert(log, 1, {
        event = eventType,
        points = points,
        timestamp = os.time(),
    })
    while #log > 20 do
        table.remove(log, #log)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TIER TRANSITION HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

local function onTierChanged(playerId: string, oldTier: number, newTier: number)
    print(string.format("[BondSystem] %s bond tier: %d → %d (%s)",
        playerId, oldTier, newTier, TIER_NAMES[newTier] or "?"))

    local data = getData(playerId)
    data.behaviors = TIER_BEHAVIORS[newTier] or TIER_BEHAVIORS[0]

    -- Fire transition line
    local lines = TIER_TRANSITION_LINES[newTier]
    if lines and #lines > 0 then
        local line = lines[math.random(1, #lines)]
        if BondSystem.hooks.onTransitionLine then
            BondSystem.hooks.onTransitionLine(playerId, newTier, line)
        end
        print(string.format("[BondSystem] Tier transition line: \"%s\"", line))
    end

    -- Persist
    if BondSystem.hooks.persist then
        BondSystem.hooks.persist(playerId, newTier, data.bondPoints)
    end

    -- Notify external systems
    if BondSystem.hooks.onTierChanged then
        BondSystem.hooks.onTierChanged(playerId, oldTier, newTier)
    end
end

-- Core: apply bond points from a behavior event and check for tier change.
local function applyBondEvent(playerId: string, eventType: string): number
    local data = getData(playerId)
    local points = BOND_EVENTS[eventType]
    if points == nil then
        warn(string.format("[BondSystem] Unknown bond event: %s", eventType))
        return 0
    end

    local oldTier = data.tier
    local oldPoints = data.bondPoints

    -- Negative events can't drop below the current tier floor.
    if points < 0 then
        local tierFloor = TIER_THRESHOLDS[oldTier] or 0
        local newPoints = oldPoints + points
        if newPoints < tierFloor then
            newPoints = tierFloor
        end
        data.bondPoints = newPoints
        local applied = newPoints - oldPoints
        logEvent(playerId, eventType, applied)
        if BondSystem.hooks.onBondEvent then
            BondSystem.hooks.onBondEvent(playerId, eventType, applied)
        end
        return applied
    end

    -- Positive event
    data.bondPoints = oldPoints + points
    logEvent(playerId, eventType, points)

    if BondSystem.hooks.onBondEvent then
        BondSystem.hooks.onBondEvent(playerId, eventType, points)
    end

    -- Check for tier change
    local newTier = calculateTier(data.bondPoints)
    if newTier > oldTier then
        data.tier = newTier
        onTierChanged(playerId, oldTier, newTier)
    end

    return points
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Initialize the BondSystem. Hooks into player join/leave.
    Call this once when your server starts.
]]
function BondSystem.init()
    Players.PlayerAdded:Connect(function(player)
        local data = getData(player.Name)
        data.sessionFirstBuild = false
        -- lastSeen is NOT set here; onPlayerJoin reads the persisted value
        -- from getData() (which retains lastSeen from the previous session
        -- if the load hook restores it), then updates it after the return check.

        -- Load persisted state if a load hook is wired
        if BondSystem.hooks.load then
            task.spawn(function()
                local storedTier, storedPoints = BondSystem.hooks.load(player.Name)
                if storedTier and (storedTier > 0 or (storedPoints and storedPoints > 0)) then
                    local state = getData(player.Name)
                    state.tier = storedTier
                    state.bondPoints = storedPoints or 0
                    state.behaviors = TIER_BEHAVIORS[storedTier] or TIER_BEHAVIORS[0]
                    print(string.format("[BondSystem] %s loaded: tier %d (%s), %d bond points",
                        player.Name, storedTier, TIER_NAMES[storedTier] or "?", storedPoints or 0))
                end
            end)
        end

        -- Check for return after >24h absence BEFORE updating lastSeen.
        -- This was dead code before because init() set lastSeen = os.time()
        -- before calling onPlayerJoin, making absenceSeconds always ~0.
        BondSystem.onPlayerJoin(player.Name)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local data = getData(player.Name)
        if BondSystem.hooks.persist then
            BondSystem.hooks.persist(player.Name, data.tier, data.bondPoints)
        end
    end)

    -- Validate tier thresholds
    for i = 1, MAX_TIER do
        assert(TIER_THRESHOLDS[i] > TIER_THRESHOLDS[i - 1],
            string.format("[BondSystem] Tier thresholds not monotonically increasing at %d", i))
    end

    print("[BondSystem] Initialized — behavior-triggered bond system, 5 tiers:")
    for i = 0, MAX_TIER do
        print(string.format("  Tier %d: %s (%d+ points)", i, TIER_NAMES[i], TIER_THRESHOLDS[i]))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PUBLIC API — BEHAVIOR TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Record a build/action event. Awards "showing up" bonus on first per session.
    @param playerId string
]]
function BondSystem.recordBuild(playerId: string)
    local data = getData(playerId)
    if not data.sessionFirstBuild then
        data.sessionFirstBuild = true
        applyBondEvent(playerId, "first_build_of_session")
    end
    data.lastSeen = os.time()
end

--[[
    Record that the player finished something left unfinished (CORE LOOP, +5).
    @param playerId string
    @param hookId string? -- optional hook identifier
]]
function BondSystem.recordHookCompleted(playerId: string, hookId: string?)
    local data = getData(playerId)
    data.hooksCompleted = (data.hooksCompleted or 0) + 1

    if hookId and openHooks[playerId] and openHooks[playerId][hookId] then
        openHooks[playerId][hookId].completed = true
        data.openHookCount = math.max(0, (data.openHookCount or 0) - 1)
    end

    applyBondEvent(playerId, "hook_completed")
end

--[[
    Record independent building (+3). Player did something without being asked.
    @param playerId string
]]
function BondSystem.recordIndependentBuild(playerId: string)
    applyBondEvent(playerId, "independent_build")
end

--[[
    Record asking to modify rather than replace (+2). Shows investment.
    @param playerId string
]]
function BondSystem.recordModifyNotReplace(playerId: string)
    applyBondEvent(playerId, "modify_not_replace")
end

--[[
    Record that the player argued back and won (+4).
    @param playerId string
]]
function BondSystem.recordArguedAndWon(playerId: string)
    applyBondEvent(playerId, "argued_and_won")
end

--[[
    Record returning after >24h absence (+2).
    @param playerId string
]]
function BondSystem.recordReturn(playerId: string)
    local data = getData(playerId)
    local now = os.time()
    local lastSeen = data.lastSeen or now
    local absenceSeconds = now - lastSeen

    if absenceSeconds >= 86400 then
        applyBondEvent(playerId, "returned_next_day")
    end

    data.lastSeen = now
    data.sessionFirstBuild = false
end

--[[
    Record deleting work without inspecting (-1, floored at tier).
    @param playerId string
]]
function BondSystem.recordDeleteWithoutInspection(playerId: string)
    applyBondEvent(playerId, "deleted_without_inspection")
end

--[[
    Add raw bond points for custom events not in the standard table.
    @param playerId string
    @param amount number -- can be negative
]]
function BondSystem.addPoints(playerId: string, amount: number)
    local data = getData(playerId)
    local oldTier = data.tier
    local oldPoints = data.bondPoints

    if amount < 0 then
        local tierFloor = TIER_THRESHOLDS[oldTier] or 0
        local newPoints = oldPoints + amount
        if newPoints < tierFloor then
            newPoints = tierFloor
        end
        data.bondPoints = newPoints
        logEvent(playerId, "custom", newPoints - oldPoints)
    else
        data.bondPoints = oldPoints + amount
        logEvent(playerId, "custom", amount)
    end

    if BondSystem.hooks.onBondEvent then
        BondSystem.hooks.onBondEvent(playerId, "custom", amount)
    end

    local newTier = calculateTier(data.bondPoints)
    if newTier > oldTier then
        data.tier = newTier
        onTierChanged(playerId, oldTier, newTier)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- OPEN HOOK MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Register an open hook — something left unfinished for the player to discover.
    @param playerId string
    @param hookId string -- unique identifier
    @param description string -- what was left unfinished
    @param position Vector3? -- world position for proximity detection
]]
function BondSystem.registerOpenHook(playerId: string, hookId: string, description: string, position: Vector3?)
    if not openHooks[playerId] then
        openHooks[playerId] = {}
    end
    openHooks[playerId][hookId] = {
        description = description,
        position = position,
        createdSession = os.time(),
        completed = false,
    }
    local data = getData(playerId)
    data.openHookCount = (data.openHookCount or 0) + 1
    data.totalHooks = (data.totalHooks or 0) + 1
end

--[[
    Check if a player has open (uncompleted) hooks.
    @param playerId string
    @return boolean
]]
function BondSystem.hasOpenHooks(playerId: string): boolean
    local hooks = openHooks[playerId]
    if not hooks then return false end
    for _, hook in pairs(hooks) do
        if not hook.completed then
            return true
        end
    end
    return false
end

--[[
    Get all open hooks for a player.
    @param playerId string
    @return table -- map of hookId -> hook data
]]
function BondSystem.getOpenHooks(playerId: string): { [string]: any }
    local result: { [string]: any } = {}
    local hooks = openHooks[playerId]
    if not hooks then return result end
    for hookId, hook in pairs(hooks) do
        if not hook.completed then
            result[hookId] = hook
        end
    end
    return result
end

--[[
    Check if a build position is near an open hook.
    @param playerId string
    @param position Vector3
    @return string? -- hookId if match found
]]
function BondSystem.checkHookProximity(playerId: string, position: Vector3): string?
    local hooks = openHooks[playerId]
    if not hooks then return nil end
    for hookId, hook in pairs(hooks) do
        if not hook.completed and hook.position then
            local hookPos = hook.position
            if typeof(hookPos) == "Vector3" then
                local distance = (position - hookPos).Magnitude
                if distance <= 30 then
                    return hookId
                end
            end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- QUERIES — TIER & BEHAVIOR
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Get the current bond tier (0-indexed).
    @param playerId string
    @return number -- 0 to MAX_TIER
]]
function BondSystem.getTier(playerId: string): number
    return getData(playerId).tier
end

--[[
    Get bond point total.
    @param playerId string
    @return number
]]
function BondSystem.getPoints(playerId: string): number
    return getData(playerId).bondPoints
end

--[[
    Get the tier name (e.g. "Stranger", "Ally").
    @param playerId string
    @return string
]]
function BondSystem.getTierName(playerId: string): string
    return TIER_NAMES[getData(playerId).tier] or "Unknown"
end

--[[
    Get bond progress toward the next tier.
    For internal/admin use — the player should never see a progress bar.
    @param playerId string
    @return table -- { current, needed, nextTier, pct }
]]
function BondSystem.getProgress(playerId: string): { [string]: any }
    local data = getData(playerId)
    local currentTier = data.tier

    if currentTier >= MAX_TIER then
        return {
            current = data.bondPoints,
            needed = TIER_THRESHOLDS[MAX_TIER],
            nextTier = nil,
            pct = 1.0,
        }
    end

    local currentThreshold = TIER_THRESHOLDS[currentTier]
    local nextThreshold = TIER_THRESHOLDS[currentTier + 1]
    local pointsIntoTier = data.bondPoints - currentThreshold
    local pointsForTier = nextThreshold - currentThreshold

    return {
        current = pointsIntoTier,
        needed = pointsForTier,
        nextTier = currentTier + 1,
        pct = pointsForTier > 0 and (pointsIntoTier / pointsForTier) or 0,
    }
end

--[[
    Get full player bond data snapshot.
    @param playerId string
    @return table
]]
function BondSystem.getPlayerData(playerId: string): { [string]: any }
    local data = getData(playerId)
    return {
        bondPoints = data.bondPoints,
        tier = data.tier,
        tierName = TIER_NAMES[data.tier],
        tierDescription = TIER_DESCRIPTIONS[data.tier],
        behaviors = data.behaviors,
        hooksCompleted = data.hooksCompleted or 0,
        openHookCount = data.openHookCount or 0,
        totalHooks = data.totalHooks or 0,
        lastSeen = data.lastSeen,
        eventLog = data.eventLog,
        progress = BondSystem.getProgress(playerId),
        confessionGiven = data.confessionGiven or false,
    }
end

--[[
    Get the full behavior flag set for a player's current tier.
    This is the primary integration point — check these flags to
    determine how NPCs/AI should behave toward the player.
    @param playerId string
    @return table -- boolean flags
]]
function BondSystem.getBehaviors(playerId: string): { [string]: any }
    return getData(playerId).behaviors or TIER_BEHAVIORS[0]
end

--[[
    Get tier thresholds (for external systems).
    @return table
]]
function BondSystem.getThresholds(): { [string]: any }
    return TIER_THRESHOLDS
end

--[[
    Get tier names (for external systems).
    @return table
]]
function BondSystem.getTierNames(): { [string]: any }
    return TIER_NAMES
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BEHAVIORAL QUERIES
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Check if player has reached at least the given tier.
    @param playerId string
    @param minTier number -- 0 to 4
    @return boolean
]]
function BondSystem.hasTier(playerId: string, minTier: number): boolean
    return BondSystem.getTier(playerId) >= minTier
end

--[[
    Should this entity use informal "we" phrasing? (Tier 3+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldUseWe(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 3
end

--[[
    Are arguments/disagreement unlocked? (Tier 2+)
    @param playerId string
    @return boolean
]]
function BondSystem.argumentsUnlocked(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 2
end

--[[
    Should this entity use nicknames? (Tier 2+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldUseNicknames(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 2
end

--[[
    Should this entity reference previous interactions? (Tier 1+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldReferenceHistory(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 1
end

--[[
    Should this entity volunteer unprompted help? (Tier 2+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldVolunteerWork(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 2
end

--[[
    Should this entity ask the player to do things? (Tier 3+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldAskPlayerToBuild(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 3
end

--[[
    Should this entity refuse work out of preference? (Tier 3+)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldRefuseWork(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 3
end

--[[
    Should this entity delegate to the player? (Tier 4)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldDelegate(playerId: string): boolean
    return BondSystem.getTier(playerId) >= 4
end

--[[
    Should things be left unfinished? (Tier 0-3: yes, Tier 4: no)
    @param playerId string
    @return boolean
]]
function BondSystem.leavesThingsUnfinished(playerId: string): boolean
    return BondSystem.getTier(playerId) < 4
end

--[[
    Is the one-time confession available? (Tier 4, not yet delivered)
    @param playerId string
    @return boolean
]]
function BondSystem.shouldDeliverConfession(playerId: string): boolean
    local data = getData(playerId)
    return data.tier >= 4 and not data.confessionGiven
end

--[[
    Mark the confession as delivered. Can only happen once per player.
    @param playerId string
]]
function BondSystem.markConfessionDelivered(playerId: string)
    local data = getData(playerId)
    data.confessionGiven = true
    if BondSystem.hooks.persist then
        BondSystem.hooks.persist(playerId, data.tier, data.bondPoints)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SESSION MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Called when a player joins. Checks for return-after-absence.
    @param playerId string
]]
function BondSystem.onPlayerJoin(playerId: string)
    local data = getData(playerId)
    local now = os.time()
    local lastSeen = data.lastSeen or now
    local absenceSeconds = now - lastSeen

    if absenceSeconds >= 86400 then
        applyBondEvent(playerId, "returned_next_day")
    end

    data.sessionFirstBuild = false
    data.lastSeen = now
end

--[[
    Force-set a player's bond tier (admin/debug).
    @param playerId string
    @param tier number -- 0 to 4
]]
function BondSystem.setTier(playerId: string, tier: number)
    tier = math.clamp(math.floor(tier), 0, MAX_TIER)
    local data = getData(playerId)
    local oldTier = data.tier

    data.tier = tier
    data.bondPoints = TIER_THRESHOLDS[tier] or 0
    data.behaviors = TIER_BEHAVIORS[tier] or TIER_BEHAVIORS[0]

    if tier ~= oldTier then
        onTierChanged(playerId, oldTier, tier)
    elseif BondSystem.hooks.persist then
        BondSystem.hooks.persist(playerId, tier, data.bondPoints)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CUSTOMIZATION
-- ═══════════════════════════════════════════════════════════════════════════

--[[
    Set custom tier names. Call before init().
    @param names table -- { [0] = "Name0", [1] = "Name1", ... }
]]
function BondSystem.setTierNames(names: { [number]: string })
    for i = 0, MAX_TIER do
        if names[i] then
            TIER_NAMES[i] = names[i]
        end
    end
end

--[[
    Set custom tier descriptions.
    @param descriptions table -- { [0] = "desc0", [1] = "desc1", ... }
]]
function BondSystem.setTierDescriptions(descriptions: { [number]: string })
    for i = 0, MAX_TIER do
        if descriptions[i] then
            TIER_DESCRIPTIONS[i] = descriptions[i]
        end
    end
end

--[[
    Set custom transition lines for a tier.
    @param tier number
    @param lines table -- array of strings
]]
function BondSystem.setTransitionLines(tier: number, lines: { string })
    TIER_TRANSITION_LINES[tier] = lines
end

--[[
    Set custom tier thresholds. Call before init().
    Thresholds must be monotonically increasing.
    @param thresholds table -- { [0] = 0, [1] = 10, ... }
]]
function BondSystem.setThresholds(thresholds: { [number]: number })
    for i = 0, MAX_TIER do
        if thresholds[i] ~= nil then
            TIER_THRESHOLDS[i] = thresholds[i]
        end
    end
    -- Validate
    for i = 1, MAX_TIER do
        assert(TIER_THRESHOLDS[i] > TIER_THRESHOLDS[i - 1],
            string.format("[BondSystem] Thresholds must be increasing at %d", i))
    end
end

--[[
    Add a custom bond event type and point value.
    @param eventType string
    @param points number -- can be negative
]]
function BondSystem.registerEventType(eventType: string, points: number)
    BOND_EVENTS[eventType] = points
end

--[[
    Fire a custom (or standard) bond event.
    @param playerId string
    @param eventType string
]]
function BondSystem.fireEvent(playerId: string, eventType: string)
    applyBondEvent(playerId, eventType)
end

return BondSystem
