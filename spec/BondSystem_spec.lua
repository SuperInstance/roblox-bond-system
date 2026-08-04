--[[
    BondSystem Test Suite
    ─────────────────────
    Tests for tier transitions, bond overflow, negative XP flooring,
    behavior flags, open hooks, confession system, API surface,
    nil/edge inputs, type mismatches, and extreme values.

    Run with TestEZ or similar Roblox test runner.
]]

local BondSystem = require(script.Parent.src.BondSystem)

return function()

    describe("BondSystem module", function()
        it("is a table", function()
            expect(type(BondSystem)).to.equal("table")
        end)

        it("has all public methods", function()
            expect(BondSystem.init).to.be.a("function")
            expect(BondSystem.recordBuild).to.be.a("function")
            expect(BondSystem.recordHookCompleted).to.be.a("function")
            expect(BondSystem.recordIndependentBuild).to.be.a("function")
            expect(BondSystem.recordModifyNotReplace).to.be.a("function")
            expect(BondSystem.recordArguedAndWon).to.be.a("function")
            expect(BondSystem.recordReturn).to.be.a("function")
            expect(BondSystem.recordDeleteWithoutInspection).to.be.a("function")
            expect(BondSystem.addPoints).to.be.a("function")
            expect(BondSystem.getTier).to.be.a("function")
            expect(BondSystem.getPoints).to.be.a("function")
            expect(BondSystem.getTierName).to.be.a("function")
            expect(BondSystem.getBehaviors).to.be.a("function")
            expect(BondSystem.getProgress).to.be.a("function")
            expect(BondSystem.getPlayerData).to.be.a("function")
            expect(BondSystem.setTier).to.be.a("function")
            expect(BondSystem.registerOpenHook).to.be.a("function")
            expect(BondSystem.hasOpenHooks).to.be.a("function")
            expect(BondSystem.getOpenHooks).to.be.a("function")
            expect(BondSystem.checkHookProximity).to.be.a("function")
        end)
    end)

    -- ── Tier Thresholds & Names ───────────────────────────────

    describe("tier thresholds and names", function()
        it("has 5 tiers (0-4)", function()
            local thresholds = BondSystem.getThresholds()
            expect(thresholds[0]).to.equal(0)
            expect(thresholds[4]).to.equal(150)
        end)

        it("tier names are correct", function()
            local names = BondSystem.getTierNames()
            expect(names[0]).to.equal("Stranger")
            expect(names[1]).to.equal("Acquaintance")
            expect(names[2]).to.equal("Companion")
            expect(names[3]).to.equal("Trusted")
            expect(names[4]).to.equal("Ally")
        end)

        it("thresholds are monotonically increasing", function()
            local t = BondSystem.getThresholds()
            for i = 1, 4 do
                expect(t[i]).to.be.greaterThan(t[i - 1])
            end
        end)

        it("has exactly 5 tier names", function()
            local names = BondSystem.getTierNames()
            local count = 0
            for _ in pairs(names) do count += 1 end
            expect(count).to.equal(5)
        end)
    end)

    -- ── Tier Transitions ──────────────────────────────────────

    describe("tier transitions", function()
        it("starts at tier 0 (Stranger)", function()
            local tier = BondSystem.getTier("test_player_new")
            expect(tier).to.equal(0)
        end)

        it("transitions to Acquaintance at 10 points", function()
            BondSystem.addPoints("test_transition", 9)
            expect(BondSystem.getTier("test_transition")).to.equal(0)
            BondSystem.addPoints("test_transition", 1)
            expect(BondSystem.getTier("test_transition")).to.equal(1)
            expect(BondSystem.getTierName("test_transition")).to.equal("Acquaintance")
        end)

        it("transitions to Companion at 30 points", function()
            BondSystem.addPoints("test_comp", 30)
            expect(BondSystem.getTier("test_comp")).to.equal(2)
        end)

        it("transitions to Trusted at 70 points", function()
            BondSystem.addPoints("test_trust", 70)
            expect(BondSystem.getTier("test_trust")).to.equal(3)
        end)

        it("transitions to Ally at 150 points", function()
            BondSystem.addPoints("test_ally", 150)
            expect(BondSystem.getTier("test_ally")).to.equal(4)
        end)

        it("does not exceed tier 4 (Ally)", function()
            BondSystem.addPoints("test_overflow", 9999)
            expect(BondSystem.getTier("test_overflow")).to.equal(4)
        end)

        it("transitions correctly at exact threshold boundaries", function()
            BondSystem.addPoints("test_boundary_29", 29)
            expect(BondSystem.getTier("test_boundary_29")).to.equal(1)
            BondSystem.addPoints("test_boundary_30", 30)
            expect(BondSystem.getTier("test_boundary_30")).to.equal(2)
        end)

        it("getTierName for unknown player returns 'Stranger'", function()
            expect(BondSystem.getTierName("totally_unknown_player_xyz")).to.equal("Stranger")
        end)
    end)

    -- ── Negative XP Flooring ──────────────────────────────────

    describe("negative XP flooring", function()
        it("does not drop below tier floor on negative event", function()
            BondSystem.setTier("test_neg", 2)
            expect(BondSystem.getTier("test_neg")).to.equal(2)
            BondSystem.addPoints("test_neg", -100)
            expect(BondSystem.getTier("test_neg")).to.equal(2)
            expect(BondSystem.getPoints("test_neg")).to.equal(30)
        end)

        it("deleted_without_inspection only costs 1 point (floored)", function()
            BondSystem.setTier("test_del", 1)
            BondSystem.recordDeleteWithoutInspection("test_del")
            expect(BondSystem.getPoints("test_del")).to.equal(10)
        end)

        it("flooring at tier 0 keeps points at 0", function()
            BondSystem.addPoints("test_floor0", -50)
            expect(BondSystem.getPoints("test_floor0")).to.equal(0)
        end)
    end)

    -- ── Behavior Flags ────────────────────────────────────────

    describe("behavior flags", function()
        it("Stranger is formal and doesn't argue", function()
            BondSystem.setTier("test_behavior_0", 0)
            local b = BondSystem.getBehaviors("test_behavior_0")
            expect(b.uses_formal_address).to.equal(true)
            expect(b.argues).to.equal(false)
            expect(b.uses_we).to.equal(false)
        end)

        it("Ally uses we, argues, delegates, and shares opinions", function()
            BondSystem.setTier("test_behavior_4", 4)
            local b = BondSystem.getBehaviors("test_behavior_4")
            expect(b.uses_we).to.equal(true)
            expect(b.argues).to.equal(true)
            expect(b.delegates_to_player).to.equal(true)
            expect(b.shares_opinions).to.equal(true)
            expect(b.leaves_things_unfinished).to.equal(false)
        end)

        it("Companion argues but doesn't use 'we'", function()
            BondSystem.setTier("test_behavior_2", 2)
            local b = BondSystem.getBehaviors("test_behavior_2")
            expect(b.argues).to.equal(true)
            expect(b.uses_we).to.equal(false)
        end)

        it("Trusted uses 'we' and argues", function()
            BondSystem.setTier("test_behavior_3", 3)
            local b = BondSystem.getBehaviors("test_behavior_3")
            expect(b.uses_we).to.equal(true)
            expect(b.argues).to.equal(true)
        end)
    end)

    -- ── Behavioral Queries ────────────────────────────────────

    describe("behavioral queries", function()
        it("shouldUseWe is true at tier 3+", function()
            BondSystem.setTier("test_we_2", 2)
            expect(BondSystem.shouldUseWe("test_we_2")).to.equal(false)
            BondSystem.setTier("test_we_3", 3)
            expect(BondSystem.shouldUseWe("test_we_3")).to.equal(true)
        end)

        it("argumentsUnlocked at tier 2+", function()
            BondSystem.setTier("test_arg_1", 1)
            expect(BondSystem.argumentsUnlocked("test_arg_1")).to.equal(false)
            BondSystem.setTier("test_arg_2", 2)
            expect(BondSystem.argumentsUnlocked("test_arg_2")).to.equal(true)
        end)

        it("leavesThingsUnfinished is false at tier 4", function()
            BondSystem.setTier("test_unfin_3", 3)
            expect(BondSystem.leavesThingsUnfinished("test_unfin_3")).to.equal(true)
            BondSystem.setTier("test_unfin_4", 4)
            expect(BondSystem.leavesThingsUnfinished("test_unfin_4")).to.equal(false)
        end)
    end)

    -- ── Custom Events ─────────────────────────────────────────

    describe("custom events", function()
        it("can register and fire custom event types", function()
            BondSystem.registerEventType("custom_heroic", 10)
            BondSystem.addPoints("test_custom", 0)
            local initial = BondSystem.getPoints("test_custom")
            BondSystem.fireEvent("test_custom", "custom_heroic")
            expect(BondSystem.getPoints("test_custom") - initial).to.equal(10)
        end)

        it("warns on unknown event type without crashing", function()
            expect(function()
                BondSystem.fireEvent("test_unknown", "nonexistent_event")
            end).never.to.throw()
        end)

        it("custom event with negative points respects tier floor", function()
            BondSystem.registerEventType("custom_penalty", -5)
            BondSystem.setTier("test_penalty", 2)  -- 30 points
            BondSystem.fireEvent("test_penalty", "custom_penalty")
            expect(BondSystem.getPoints("test_penalty")).to.equal(30)
        end)

        it("custom event with zero points is a no-op", function()
            BondSystem.registerEventType("custom_noop", 0)
            BondSystem.addPoints("test_noop", 20)
            local before = BondSystem.getPoints("test_noop")
            BondSystem.fireEvent("test_noop", "custom_noop")
            expect(BondSystem.getPoints("test_noop")).to.equal(before)
        end)
    end)

    -- ── Progress ──────────────────────────────────────────────

    describe("progress", function()
        it("returns correct progress info", function()
            BondSystem.setTier("test_prog", 1)
            local progress = BondSystem.getProgress("test_prog")
            expect(progress).to.be.a("table")
            expect(progress.nextTier).to.equal(2)
        end)

        it("returns nil nextTier at max tier", function()
            BondSystem.setTier("test_prog_max", 4)
            local progress = BondSystem.getProgress("test_prog_max")
            expect(progress.nextTier).never.to.be.ok()
        end)

        it("progress from tier 0 has nextTier 1", function()
            BondSystem.setTier("test_prog_0", 0)
            local progress = BondSystem.getProgress("test_prog_0")
            expect(progress.nextTier).to.equal(1)
        end)
    end)

    -- ── setTier (admin) ───────────────────────────────────────

    describe("setTier (admin)", function()
        it("clamps to valid range (low)", function()
            BondSystem.setTier("test_clamp_low", -5)
            expect(BondSystem.getTier("test_clamp_low")).to.equal(0)
        end)

        it("clamps to valid range (high)", function()
            BondSystem.setTier("test_clamp_high", 99)
            expect(BondSystem.getTier("test_clamp_high")).to.equal(4)
        end)

        it("accepts nil playerId without crashing", function()
            expect(function()
                BondSystem.setTier(nil, 2)
            end).never.to.throw()
        end)
    end)

    -- ── Open Hooks ────────────────────────────────────────────

    describe("open hooks", function()
        it("registers and finds open hooks", function()
            BondSystem.registerOpenHook("test_hook", "unfinished_wall",
                "An incomplete stone wall", Vector3.new(100, 10, 50))
            expect(BondSystem.hasOpenHooks("test_hook")).to.equal(true)
            local hooks = BondSystem.getOpenHooks("test_hook")
            expect(hooks.unfinished_wall).to.be.ok()
        end)

        it("checkHookProximity finds nearby hooks", function()
            BondSystem.registerOpenHook("test_prox", "nearby_item",
                "A nearby unfinished item", Vector3.new(100, 10, 50))
            local hookId = BondSystem.checkHookProximity("test_prox", Vector3.new(105, 10, 50))
            expect(hookId).to.be.ok()
        end)

        it("checkHookProximity returns nil for distant position", function()
            BondSystem.registerOpenHook("test_far", "far_item",
                "A far unfinished item", Vector3.new(100, 10, 50))
            local hookId = BondSystem.checkHookProximity("test_far", Vector3.new(500, 10, 500))
            expect(hookId).never.to.be.ok()
        end)

        it("hasOpenHooks returns false for unknown player", function()
            expect(BondSystem.hasOpenHooks("nonexistent_player")).to.equal(false)
        end)

        it("getOpenHooks returns empty for unknown player", function()
            local hooks = BondSystem.getOpenHooks("nonexistent_player_xyz")
            expect(hooks).to.be.a("table")
        end)

        it("checkHookProximity with nil position does not crash", function()
            BondSystem.registerOpenHook("test_nil_pos", "item",
                "desc", Vector3.new(0, 0, 0))
            expect(function()
                BondSystem.checkHookProximity("test_nil_pos", nil)
            end).never.to.throw()
        end)

        it("registerOpenHook with nil description does not crash", function()
            expect(function()
                BondSystem.registerOpenHook("test_nil_desc", "item", nil, Vector3.new(0, 0, 0))
            end).never.to.throw()
        end)
    end)

    -- ── Confession System ─────────────────────────────────────

    describe("confession system", function()
        it("shouldDeliverConfession is false below tier 4", function()
            BondSystem.setTier("test_conf_3", 3)
            expect(BondSystem.shouldDeliverConfession("test_conf_3")).to.equal(false)
        end)

        it("shouldDeliverConfession is true at tier 4", function()
            BondSystem.setTier("test_conf_4", 4)
            expect(BondSystem.shouldDeliverConfession("test_conf_4")).to.equal(true)
        end)

        it("markConfessionDelivered prevents re-delivery", function()
            BondSystem.setTier("test_conf_mark", 4)
            expect(BondSystem.shouldDeliverConfession("test_conf_mark")).to.equal(true)
            BondSystem.markConfessionDelivered("test_conf_mark")
            expect(BondSystem.shouldDeliverConfession("test_conf_mark")).to.equal(false)
        end)

        it("shouldDeliverConfession false at tier 0", function()
            BondSystem.setTier("test_conf_0", 0)
            expect(BondSystem.shouldDeliverConfession("test_conf_0")).to.equal(false)
        end)
    end)

    -- ── Nil & Type Mismatch Inputs ────────────────────────────

    describe("nil and type mismatch inputs", function()
        it("getTier with nil playerId returns 0", function()
            local tier = BondSystem.getTier(nil)
            expect(tier).to.equal(0)
        end)

        it("getPoints with nil playerId returns 0", function()
            local pts = BondSystem.getPoints(nil)
            expect(pts).to.equal(0)
        end)

        it("getBehaviors with nil playerId returns tier 0 behaviors", function()
            local b = BondSystem.getBehaviors(nil)
            expect(b).to.be.a("table")
        end)

        it("addPoints with nil playerId does not crash", function()
            expect(function()
                BondSystem.addPoints(nil, 10)
            end).never.to.throw()
        end)

        it("addPoints with nil points does not crash", function()
            expect(function()
                BondSystem.addPoints("test_nil_pts", nil)
            end).never.to.throw()
        end)

        it("addPoints with string points does not crash", function()
            expect(function()
                BondSystem.addPoints("test_str_pts", "not_a_number")
            end).never.to.throw()
        end)
    end)

    -- ── Extreme Values ────────────────────────────────────────

    describe("extreme values", function()
        it("addPoints with very large value jumps to max tier", function()
            BondSystem.addPoints("test_huge", 1e15)
            expect(BondSystem.getTier("test_huge")).to.equal(4)
        end)

        it("addPoints with very large negative floored at tier 0", function()
            BondSystem.addPoints("test_huge_neg", -1e15)
            expect(BondSystem.getTier("test_huge_neg")).to.equal(0)
            expect(BondSystem.getPoints("test_huge_neg")).to.equal(0)
        end)

        it("setTier with very large number clamps to 4", function()
            BondSystem.setTier("test_set_huge", 1e10)
            expect(BondSystem.getTier("test_set_huge")).to.equal(4)
        end)

        it("setTier with very large negative clamps to 0", function()
            BondSystem.setTier("test_set_tiny", -1e10)
            expect(BondSystem.getTier("test_set_tiny")).to.equal(0)
        end)
    end)
end
