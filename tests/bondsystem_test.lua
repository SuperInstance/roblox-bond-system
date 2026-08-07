-- tests/bondsystem_test.lua
-- TestKit-compatible tests for BondSystem behavior-triggered relationship module.

local testkit = require("testkit")
local expect = testkit.expect

-- Mock typeof
if not typeof then
    _G.typeof = function(v)
        local t = type(v)
        if t == "table" and v._robloxType then return v._robloxType end
        return t
    end
    rawset(_G, "typeof", _G.typeof)
end

-- Mock Vector3 (used in registerOpenHook)
Vector3 = { new = function(x, y, z) return {X=x or 0, Y=y or 0, Z=z or 0} end }
rawset(_G, "Vector3", Vector3)

local BondSystem = testkit.loadModule("/home/eileen/projects/roblox-bond-system/src/BondSystem.lua")

describe("BondSystem module structure", function()
    it("exports a table", function()
        expect(type(BondSystem)):toBe("table")
    end)

    it("has init function", function()
        expect(type(BondSystem.init)):toBe("function")
    end)

    it("has recordBuild function", function()
        expect(type(BondSystem.recordBuild)):toBe("function")
    end)

    it("has getTier function", function()
        expect(type(BondSystem.getTier)):toBe("function")
    end)

    it("has getPoints function", function()
        expect(type(BondSystem.getPoints)):toBe("function")
    end)

    it("has getBehaviors function", function()
        expect(type(BondSystem.getBehaviors)):toBe("function")
    end)

    it("has addPoints function", function()
        expect(type(BondSystem.addPoints)):toBe("function")
    end)
end)

describe("BondSystem init", function()
    it("init completes without error", function()
        BondSystem.init()
        expect(true):toBe(true) -- if we got here, init didn't crash
    end)
end)

describe("BondSystem tier progression", function()
    beforeAll(function()
        BondSystem.init()
    end)

    it("starts at tier 0 (Stranger) for new player", function()
        local tier = BondSystem.getTier("new_player")
        expect(tier):toBe(0)
    end)

    it("starts at 0 points for new player", function()
        local points = BondSystem.getPoints("new_player")
        expect(points):toBe(0)
    end)

    it("recordBuild adds points", function()
        BondSystem.init()
        BondSystem.recordBuild("test_player_1")
        local points = BondSystem.getPoints("test_player_1")
        expect(points > 0):toBe(true)
    end)

    it("multiple events accumulate points", function()
        BondSystem.init()
        BondSystem.recordBuild("test_player_2")
        BondSystem.recordBuild("test_player_2")
        BondSystem.recordBuild("test_player_2")
        local points = BondSystem.getPoints("test_player_2")
        expect(points >= 1):toBe(true)
    end)

    it("tier increases when enough points", function()
        BondSystem.init()
        -- Add enough points to reach tier 1 (10+ points)
        BondSystem.addPoints("test_player_3", 15)
        local tier = BondSystem.getTier("test_player_3")
        expect(tier >= 1):toBe(true)
    end)

    it("tier does not decrease on negative events", function()
        BondSystem.init()
        -- Get to tier 1
        BondSystem.addPoints("test_player_4", 15)
        local tier1 = BondSystem.getTier("test_player_4")
        expect(tier1 >= 1):toBe(true)

        -- Record a negative event
        BondSystem.recordDeleteWithoutInspection("test_player_4")
        local tier2 = BondSystem.getTier("test_player_4")
        -- Tier should not drop below where it was
        expect(tier2 >= tier1):toBe(true)
    end)
end)

describe("BondSystem behaviors", function()
    it("getBehaviors returns a table", function()
        BondSystem.init()
        local behaviors = BondSystem.getBehaviors("behavior_test")
        expect(type(behaviors)):toBe("table")
    end)
end)

describe("BondSystem tier names", function()
    it("getTierName returns a string", function()
        BondSystem.init()
        local name = BondSystem.getTierName("name_test")
        expect(type(name)):toBe("string")
    end)

    it("returns 'Stranger' for new players", function()
        BondSystem.init()
        local name = BondSystem.getTierName("stranger_test")
        expect(name):toBe("Stranger")
    end)
end)

describe("BondSystem progress", function()
    it("getProgress returns a table with data", function()
        BondSystem.init()
        BondSystem.recordBuild("progress_test")
        local progress = BondSystem.getProgress("progress_test")
        expect(type(progress)):toBe("table")
    end)
end)

describe("BondSystem hook system", function()
    it("hasOpenHooks returns false for new player", function()
        BondSystem.init()
        local has = BondSystem.hasOpenHooks("hook_test")
        expect(has):toBe(false)
    end)

    it("registerOpenHook does not crash", function()
        BondSystem.init()
        BondSystem.registerOpenHook("hook_test_2", "hook_1", "A mysterious door")
        expect(true):toBe(true)
    end)

    it("hasOpenHooks returns true after registering", function()
        BondSystem.init()
        BondSystem.registerOpenHook("hook_test_3", "hook_1", "A mysterious door")
        local has = BondSystem.hasOpenHooks("hook_test_3")
        expect(has):toBe(true)
    end)
end)
