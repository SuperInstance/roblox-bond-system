-- tests/bondsystem_extended_test.lua
-- Extended tests for BondSystem — tier thresholds, behavior flags,
-- open hooks, proximity, tier transitions, confession system.
-- Overnight creative loop.

local testkit = require("testkit")
local expect = testkit.expect

-- Mock typeof
if not typeof then
    _G.typeof = function(v)
        local t = type(v)
        if t == "table" and v._robloxType then return v._robloxType end
        return t
    end
end

-- Mock game services
local mockConnections = {}
local mockPlayers = {}

local mockPlayerService = {
    PlayerAdded = {
        Connect = function(_, callback)
            table.insert(mockConnections, {event = "PlayerAdded", callback = callback})
            return {Connected = true}
        end
    },
    PlayerRemoving = {
        Connect = function(_, callback)
            table.insert(mockConnections, {event = "PlayerRemoving", callback = callback})
            return {Connected = true}
        end
    }
}

-- Mock game object
game = {
    GetService = function(self, serviceName)
        if serviceName == "Players" then return mockPlayerService end
        return nil
    end
}

-- Mock task.spawn
task = task or {}
task.spawn = task.spawn or function(fn, ...) return fn(...) end

-- Mock math.random to make tests deterministic
math.randomseed(42)

local BondSystem = testkit.loadModule("/home/eileen/projects/roblox-bond-system/src/BondSystem.lua")

-- ============================================================
-- TIER THRESHOLD TESTS
-- ============================================================
describe("tier thresholds", function()
    it("Stranger is 0 points", function()
        BondSystem.setTier("test_thresholds", 0)
        expect(BondSystem.getPoints("test_thresholds")):toBe(0)
        expect(BondSystem.getTier("test_thresholds")):toBe(0)
    end)

    it("Acquaintance at 10 points", function()
        BondSystem.setTier("test_thresholds", 1)
        expect(BondSystem.getTier("test_thresholds")):toBe(1)
        expect(BondSystem.getPoints("test_thresholds")):toBe(10)
    end)

    it("Companion at 30 points", function()
        BondSystem.setTier("test_thresholds", 2)
        expect(BondSystem.getTier("test_thresholds")):toBe(2)
        expect(BondSystem.getPoints("test_thresholds")):toBe(30)
    end)

    it("Trusted at 70 points", function()
        BondSystem.setTier("test_thresholds", 3)
        expect(BondSystem.getTier("test_thresholds")):toBe(3)
        expect(BondSystem.getPoints("test_thresholds")):toBe(70)
    end)

    it("Ally at 150 points", function()
        BondSystem.setTier("test_thresholds", 4)
        expect(BondSystem.getTier("test_thresholds")):toBe(4)
        expect(BondSystem.getPoints("test_thresholds")):toBe(150)
    end)
end)

-- ============================================================
-- BEHAVIOR FLAGS PER TIER
-- ============================================================
describe("tier 0 behaviors (Stranger)", function()
    local behaviors
    beforeAll(function()
        BondSystem.setTier("test_beh0", 0)
        behaviors = BondSystem.getBehaviors("test_beh0")
    end)

    it("uses formal address", function()
        expect(behaviors.uses_formal_address):toBe(true)
    end)

    it("does NOT argue", function()
        expect(behaviors.argues):toBe(false)
    end)

    it("does NOT use nicknames", function()
        expect(behaviors.uses_nicknames):toBe(false)
    end)

    it("does NOT volunteer work", function()
        expect(behaviors.volunteers_work):toBe(false)
    end)

    it("does NOT use 'we'", function()
        expect(behaviors.uses_we):toBe(false)
    end)

    it("leaves things unfinished", function()
        expect(behaviors.leaves_things_unfinished):toBe(true)
    end)
end)

describe("tier 2 behaviors (Companion)", function()
    local behaviors
    beforeAll(function()
        BondSystem.setTier("test_beh2", 2)
        behaviors = BondSystem.getBehaviors("test_beh2")
    end)

    it("argues", function()
        expect(behaviors.argues):toBe(true)
    end)

    it("volunteers work", function()
        expect(behaviors.volunteers_work):toBe(true)
    end)

    it("uses nicknames", function()
        expect(behaviors.uses_nicknames):toBe(true)
    end)

    it("does NOT use 'we' yet", function()
        expect(behaviors.uses_we):toBe(false)
    end)

    it("does NOT delegate", function()
        expect(behaviors.delegates_to_player):toBe(false)
    end)
end)

describe("tier 4 behaviors (Ally)", function()
    local behaviors
    beforeAll(function()
        BondSystem.setTier("test_beh4", 4)
        behaviors = BondSystem.getBehaviors("test_beh4")
    end)

    it("uses 'we'", function()
        expect(behaviors.uses_we):toBe(true)
    end)

    it("delegates to player", function()
        expect(behaviors.delegates_to_player):toBe(true)
    end)

    it("confesses pattern", function()
        expect(behaviors.confesses_pattern):toBe(true)
    end)

    it("does NOT leave things unfinished", function()
        expect(behaviors.leaves_things_unfinished):toBe(false)
    end)

    it("does NOT use formal address", function()
        expect(behaviors.uses_formal_address):toBe(false)
    end)
end)

-- ============================================================
-- BEHAVIORAL QUERY FUNCTIONS
-- ============================================================
describe("behavioral queries", function()
    beforeAll(function()
        BondSystem.setTier("test_queries", 0)
    end)

    it("shouldUseWe is false at tier 0", function()
        expect(BondSystem.shouldUseWe("test_queries")):toBe(false)
    end)

    it("shouldUseWe is true at tier 3", function()
        BondSystem.setTier("test_queries", 3)
        expect(BondSystem.shouldUseWe("test_queries")):toBe(true)
    end)

    it("argumentsUnlocked false at tier 1", function()
        BondSystem.setTier("test_queries", 1)
        expect(BondSystem.argumentsUnlocked("test_queries")):toBe(false)
    end)

    it("argumentsUnlocked true at tier 2", function()
        BondSystem.setTier("test_queries", 2)
        expect(BondSystem.argumentsUnlocked("test_queries")):toBe(true)
    end)

    it("shouldDelegate false at tier 3", function()
        BondSystem.setTier("test_queries", 3)
        expect(BondSystem.shouldDelegate("test_queries")):toBe(false)
    end)

    it("shouldDelegate true at tier 4", function()
        BondSystem.setTier("test_queries", 4)
        expect(BondSystem.shouldDelegate("test_queries")):toBe(true)
    end)

    it("leavesThingsUnfinished true at tier 3", function()
        BondSystem.setTier("test_queries", 3)
        expect(BondSystem.leavesThingsUnfinished("test_queries")):toBe(true)
    end)

    it("leavesThingsUnfinished false at tier 4", function()
        BondSystem.setTier("test_queries", 4)
        expect(BondSystem.leavesThingsUnfinished("test_queries")):toBe(false)
    end)

    it("hasTier checks minimum tier", function()
        BondSystem.setTier("test_queries", 2)
        expect(BondSystem.hasTier("test_queries", 0)):toBe(true)
        expect(BondSystem.hasTier("test_queries", 1)):toBe(true)
        expect(BondSystem.hasTier("test_queries", 2)):toBe(true)
        expect(BondSystem.hasTier("test_queries", 3)):toBe(false)
        expect(BondSystem.hasTier("test_queries", 4)):toBe(false)
    end)
end)

-- ============================================================
-- BOND EVENT POINTS
-- ============================================================
describe("bond events", function()
    it("first_build_of_session gives +1", function()
        BondSystem.setTier("test_events", 0)
        BondSystem.recordBuild("test_events")
        expect(BondSystem.getPoints("test_events")):toBe(1)
    end)

    it("first_build only fires once per session", function()
        BondSystem.setTier("test_events2", 0)
        BondSystem.recordBuild("test_events2")
        BondSystem.recordBuild("test_events2")
        BondSystem.recordBuild("test_events2")
        -- Only +1 from first build
        expect(BondSystem.getPoints("test_events2")):toBe(1)
    end)

    it("independent_build gives +3", function()
        BondSystem.setTier("test_events3", 0)
        BondSystem.recordIndependentBuild("test_events3")
        expect(BondSystem.getPoints("test_events3")):toBe(3)
    end)

    it("hook_completed gives +5", function()
        BondSystem.setTier("test_events4", 0)
        BondSystem.recordHookCompleted("test_events4")
        expect(BondSystem.getPoints("test_events4")):toBe(5)
    end)

    it("argued_and_won gives +4", function()
        BondSystem.setTier("test_events5", 0)
        BondSystem.recordArguedAndWon("test_events5")
        expect(BondSystem.getPoints("test_events5")):toBe(4)
    end)

    it("modify_not_replace gives +2", function()
        BondSystem.setTier("test_events6", 0)
        BondSystem.recordModifyNotReplace("test_events6")
        expect(BondSystem.getPoints("test_events6")):toBe(2)
    end)

    it("deleted_without_inspection gives -1", function()
        BondSystem.setTier("test_events7", 0)
        BondSystem.recordDeleteWithoutInspection("test_events7")
        expect(BondSystem.getPoints("test_events7")):toBe(0) -- floored at tier 0
    end)

    it("deleted_without_inspection floors at current tier", function()
        BondSystem.setTier("test_events8", 2)
        -- At tier 2, threshold is 30, points = 30
        BondSystem.recordDeleteWithoutInspection("test_events8")
        expect(BondSystem.getPoints("test_events8")):toBe(30) -- floored at 30
    end)
end)

-- ============================================================
-- TIER PROGRESSION VIA EVENTS
-- ============================================================
describe("tier progression through events", function()
    it("reaches tier 1 through builds", function()
        BondSystem.setTier("test_prog", 0)
        -- first_build (+1) then we need 9 more
        BondSystem.recordBuild("test_prog") -- +1
        -- need 9 more points
        for i = 1, 3 do
            BondSystem.recordIndependentBuild("test_prog") -- +3 each = +9
        end
        expect(BondSystem.getTier("test_prog")):toBe(1)
    end)

    it("reaches tier 2 through hook completions", function()
        BondSystem.setTier("test_prog2", 0)
        for i = 1, 6 do
            BondSystem.recordHookCompleted("test_prog2") -- +5 each = +30
        end
        expect(BondSystem.getTier("test_prog2")):toBe(2)
    end)

    it("reaches tier 4 through argued_and_won", function()
        BondSystem.setTier("test_prog3", 0)
        for i = 1, 38 do
            BondSystem.recordArguedAndWon("test_prog3") -- +4 each = +152
        end
        expect(BondSystem.getTier("test_prog3")):toBe(4)
    end)
end)

-- ============================================================
-- HOOKS
-- ============================================================
describe("hooks system", function()
    it("registerOpenHook increments counts", function()
        BondSystem.setTier("test_hooks", 0)
        BondSystem.registerOpenHook("test_hooks", "hook1", "unfinished bridge")
        local data = BondSystem.getPlayerData("test_hooks")
        expect(data.openHookCount):toBe(1)
        expect(data.totalHooks):toBe(1)
    end)

    it("hasOpenHooks returns true after registering", function()
        BondSystem.setTier("test_hooks2", 0)
        expect(BondSystem.hasOpenHooks("test_hooks2")):toBe(false)
        BondSystem.registerOpenHook("test_hooks2", "h1", "desc")
        expect(BondSystem.hasOpenHooks("test_hooks2")):toBe(true)
    end)

    it("getOpenHooks returns uncompleted hooks", function()
        BondSystem.setTier("test_hooks3", 0)
        BondSystem.registerOpenHook("test_hooks3", "h1", "desc1")
        BondSystem.registerOpenHook("test_hooks3", "h2", "desc2")
        local hooks = BondSystem.getOpenHooks("test_hooks3")
        expect(type(hooks)):toBe("table")
        expect(hooks.h1 ~= nil):toBe(true)
        expect(hooks.h2 ~= nil):toBe(true)
    end)

    it("recordHookCompleted marks hook as completed", function()
        BondSystem.setTier("test_hooks4", 0)
        BondSystem.registerOpenHook("test_hooks4", "h1", "desc")
        BondSystem.recordHookCompleted("test_hooks4", "h1")
        expect(BondSystem.hasOpenHooks("test_hooks4")):toBe(false)
        local data = BondSystem.getPlayerData("test_hooks4")
        expect(data.hooksCompleted):toBe(1)
    end)

    it("multiple hooks can be open simultaneously", function()
        BondSystem.setTier("test_hooks5", 0)
        BondSystem.registerOpenHook("test_hooks5", "h1", "d1")
        BondSystem.registerOpenHook("test_hooks5", "h2", "d2")
        BondSystem.registerOpenHook("test_hooks5", "h3", "d3")
        expect(BondSystem.hasOpenHooks("test_hooks5")):toBe(true)
        local data = BondSystem.getPlayerData("test_hooks5")
        expect(data.openHookCount):toBe(3)
    end)

    it("completing one hook leaves others open", function()
        BondSystem.setTier("test_hooks6", 0)
        BondSystem.registerOpenHook("test_hooks6", "h1", "d1")
        BondSystem.registerOpenHook("test_hooks6", "h2", "d2")
        BondSystem.recordHookCompleted("test_hooks6", "h1")
        expect(BondSystem.hasOpenHooks("test_hooks6")):toBe(true)
        local open = BondSystem.getOpenHooks("test_hooks6")
        expect(open.h1):toBeNil()
        expect(open.h2 ~= nil):toBe(true)
    end)
end)

-- ============================================================
-- PROGRESS QUERIES
-- ============================================================
describe("progress", function()
    it("returns correct progress at tier 0", function()
        BondSystem.setTier("test_progress", 0)
        local p = BondSystem.getProgress("test_progress")
        expect(p.current):toBe(0)
        expect(p.needed):toBe(10) -- 10 - 0
        expect(p.nextTier):toBe(1)
        expect(p.pct):toBe(0)
    end)

    it("returns nil nextTier at max tier", function()
        BondSystem.setTier("test_progress", 4)
        local p = BondSystem.getProgress("test_progress")
        expect(p.nextTier):toBeNil()
        expect(p.pct):toBe(1.0)
    end)

    it("calculates partial progress", function()
        BondSystem.setTier("test_progress2", 0)
        BondSystem.addPoints("test_progress2", 5)
        local p = BondSystem.getProgress("test_progress2")
        expect(p.current):toBe(5)
        expect(p.needed):toBe(10)
        expect(p.pct):toBe(0.5)
    end)
end)

-- ============================================================
-- ADD POINTS
-- ============================================================
describe("addPoints", function()
    it("adds positive points", function()
        BondSystem.setTier("test_addpts", 0)
        BondSystem.addPoints("test_addpts", 10)
        expect(BondSystem.getPoints("test_addpts")):toBe(10)
    end)

    it("adding points can trigger tier change", function()
        BondSystem.setTier("test_addpts2", 0)
        BondSystem.addPoints("test_addpts2", 30)
        expect(BondSystem.getTier("test_addpts2")):toBe(2)
    end)

    it("negative points floor at tier threshold", function()
        BondSystem.setTier("test_addpts3", 2) -- points = 30
        BondSystem.addPoints("test_addpts3", -100)
        -- Should floor at 30 (tier 2 threshold)
        expect(BondSystem.getPoints("test_addpts3")):toBe(30)
    end)
end)

-- ============================================================
-- TIER NAMES
-- ============================================================
describe("tier names", function()
    it("returns correct name for each tier", function()
        BondSystem.setTier("test_names", 0)
        expect(BondSystem.getTierName("test_names")):toBe("Stranger")
        BondSystem.setTier("test_names", 1)
        expect(BondSystem.getTierName("test_names")):toBe("Acquaintance")
        BondSystem.setTier("test_names", 2)
        expect(BondSystem.getTierName("test_names")):toBe("Companion")
        BondSystem.setTier("test_names", 3)
        expect(BondSystem.getTierName("test_names")):toBe("Trusted")
        BondSystem.setTier("test_names", 4)
        expect(BondSystem.getTierName("test_names")):toBe("Ally")
    end)
end)

-- ============================================================
-- CONFESSION SYSTEM
-- ============================================================
describe("confession system", function()
    it("shouldDeliverConfession false at tier 0", function()
        BondSystem.setTier("test_conf", 0)
        expect(BondSystem.shouldDeliverConfession("test_conf")):toBe(false)
    end)

    it("shouldDeliverConfession false at tier 3", function()
        BondSystem.setTier("test_conf", 3)
        expect(BondSystem.shouldDeliverConfession("test_conf")):toBe(false)
    end)

    it("shouldDeliverConfession true at tier 4", function()
        BondSystem.setTier("test_conf2", 4)
        expect(BondSystem.shouldDeliverConfession("test_conf2")):toBe(true)
    end)

    it("shouldDeliverConfession false after delivery", function()
        BondSystem.setTier("test_conf3", 4)
        BondSystem.markConfessionDelivered("test_conf3")
        expect(BondSystem.shouldDeliverConfession("test_conf3")):toBe(false)
    end)

    it("markConfessionDelivered is one-time", function()
        BondSystem.setTier("test_conf4", 4)
        BondSystem.markConfessionDelivered("test_conf4")
        BondSystem.markConfessionDelivered("test_conf4")
        -- Still false — can't deliver twice
        expect(BondSystem.shouldDeliverConfession("test_conf4")):toBe(false)
    end)
end)

-- ============================================================
-- CUSTOM EVENTS
-- ============================================================
describe("custom event types", function()
    it("can register and fire custom events", function()
        BondSystem.setTier("test_custom", 0)
        BondSystem.registerEventType("rescued_from_drowning", 15)
        BondSystem.fireEvent("test_custom", "rescued_from_drowning")
        expect(BondSystem.getPoints("test_custom")):toBe(15)
    end)

    it("can register negative custom events", function()
        BondSystem.setTier("test_custom2", 0)
        BondSystem.registerEventType("betrayed_trust", -50)
        -- At tier 0, floor is 0, so can't go below
        BondSystem.fireEvent("test_custom2", "betrayed_trust")
        expect(BondSystem.getPoints("test_custom2")):toBe(0)
    end)
end)

-- ============================================================
-- SET TIER (admin)
-- ============================================================
describe("setTier admin function", function()
    it("clamps to valid range", function()
        BondSystem.setTier("test_admin", 0)
        BondSystem.setTier("test_admin", 99) -- clamp to 4
        expect(BondSystem.getTier("test_admin")):toBe(4)
    end)

    it("clamps negative to 0", function()
        BondSystem.setTier("test_admin2", 0)
        BondSystem.setTier("test_admin2", -5)
        expect(BondSystem.getTier("test_admin2")):toBe(0)
    end)

    it("floors fractional tiers", function()
        BondSystem.setTier("test_admin3", 0)
        BondSystem.setTier("test_admin3", 2.7)
        expect(BondSystem.getTier("test_admin3")):toBe(2)
    end)

    it("sets points to threshold", function()
        BondSystem.setTier("test_admin4", 0)
        BondSystem.setTier("test_admin4", 3)
        expect(BondSystem.getPoints("test_admin4")):toBe(70)
    end)
end)

-- ============================================================
-- HOOKS (integration callbacks)
-- ============================================================
describe("integration hooks", function()
    it("onTierChanged fires on tier change", function()
        local fired = false
        local oldT, newT
        BondSystem.hooks.onTierChanged = function(pid, ot, nt)
            fired = true
            oldT = ot
            newT = nt
        end
        BondSystem.setTier("test_hook_fire", 0)
        BondSystem.addPoints("test_hook_fire", 50)
        expect(fired):toBe(true)
        expect(newT):toBe(2)
        -- Reset hook
        BondSystem.hooks.onTierChanged = nil
    end)

    it("onBondEvent fires on events", function()
        local lastEvent, lastPoints
        BondSystem.hooks.onBondEvent = function(pid, evt, pts)
            lastEvent = evt
            lastPoints = pts
        end
        BondSystem.setTier("test_hook_fire2", 0)
        BondSystem.recordIndependentBuild("test_hook_fire2")
        expect(lastEvent):toBe("independent_build")
        expect(lastPoints):toBe(3)
        BondSystem.hooks.onBondEvent = nil
    end)
end)

-- ============================================================
-- EVENT LOG
-- ============================================================
describe("event log", function()
    it("logs events", function()
        BondSystem.setTier("test_log", 0)
        BondSystem.recordBuild("test_log")
        BondSystem.recordIndependentBuild("test_log")
        local data = BondSystem.getPlayerData("test_log")
        expect(type(data.eventLog)):toBe("table")
        expect(#data.eventLog > 0):toBe(true)
    end)

    it("keeps last 20 events", function()
        BondSystem.setTier("test_log2", 0)
        for i = 1, 25 do
            BondSystem.addPoints("test_log2", 1)
        end
        local data = BondSystem.getPlayerData("test_log2")
        expect(#data.eventLog <= 20):toBe(true)
    end)
end)

-- ============================================================
-- API COMPLETENESS
-- ============================================================
describe("API completeness", function()
    local expectedFunctions = {
        "init", "recordBuild", "recordHookCompleted", "recordIndependentBuild",
        "recordModifyNotReplace", "recordArguedAndWon", "recordReturn",
        "recordDeleteWithoutInspection", "addPoints", "registerOpenHook",
        "hasOpenHooks", "getOpenHooks", "checkHookProximity",
        "getTier", "getPoints", "getTierName", "getProgress",
        "getPlayerData", "getBehaviors", "getThresholds", "getTierNames",
        "hasTier", "shouldUseWe", "argumentsUnlocked", "shouldUseNicknames",
        "shouldReferenceHistory", "shouldVolunteerWork",
        "shouldAskPlayerToBuild", "shouldRefuseWork", "shouldDelegate",
        "leavesThingsUnfinished", "shouldDeliverConfession",
        "markConfessionDelivered", "onPlayerJoin", "setTier",
        "setTierNames", "setTierDescriptions", "setTransitionLines",
        "setThresholds", "registerEventType", "fireEvent",
    }

    for _, funcName in ipairs(expectedFunctions) do
        it("exports " .. funcName, function()
            expect(type(BondSystem[funcName])):toBe("function")
        end)
    end
end)
