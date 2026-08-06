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

    -- ── Behavior Trigger Functions ────────────────────────────

    describe("behavior trigger functions", function()
        it("recordBuild awards first-build bonus once per session", function()
            local id = "test_recordBuild_session"
            local before = BondSystem.getPoints(id)
            BondSystem.recordBuild(id)
            expect(BondSystem.getPoints(id) - before).to.equal(1)
            -- Second call in same session should not award bonus
            local after = BondSystem.getPoints(id)
            BondSystem.recordBuild(id)
            expect(BondSystem.getPoints(id)).to.equal(after)
        end)

        it("recordHookCompleted awards +5 points", function()
            local id = "test_hook_pts"
            local before = BondSystem.getPoints(id)
            BondSystem.recordHookCompleted(id)
            expect(BondSystem.getPoints(id) - before).to.equal(5)
        end)

        it("recordHookCompleted with hookId completes the open hook", function()
            local id = "test_hook_complete"
            BondSystem.registerOpenHook(id, "hook_a", "desc", Vector3.new(0, 0, 0))
            expect(BondSystem.hasOpenHooks(id)).to.equal(true)
            BondSystem.recordHookCompleted(id, "hook_a")
            -- The hook should now be completed
            expect(BondSystem.hasOpenHooks(id)).to.equal(false)
        end)

        it("recordHookCompleted increments hooksCompleted counter", function()
            local id = "test_hook_counter"
            BondSystem.recordHookCompleted(id)
            BondSystem.recordHookCompleted(id)
            local data = BondSystem.getPlayerData(id)
            expect(data.hooksCompleted).to.be.greaterThan(1)
        end)

        it("recordIndependentBuild awards +3 points", function()
            local id = "test_indep"
            local before = BondSystem.getPoints(id)
            BondSystem.recordIndependentBuild(id)
            expect(BondSystem.getPoints(id) - before).to.equal(3)
        end)

        it("recordModifyNotReplace awards +2 points", function()
            local id = "test_modify"
            local before = BondSystem.getPoints(id)
            BondSystem.recordModifyNotReplace(id)
            expect(BondSystem.getPoints(id) - before).to.equal(2)
        end)

        it("recordArguedAndWon awards +4 points", function()
            local id = "test_argued"
            local before = BondSystem.getPoints(id)
            BondSystem.recordArguedAndWon(id)
            expect(BondSystem.getPoints(id) - before).to.equal(4)
        end)

        it("recordReturn does not award if <24h since lastSeen", function()
            local id = "test_return_short"
            -- Player was just seen (getData sets lastSeen to os.time())
            local before = BondSystem.getPoints(id)
            BondSystem.recordReturn(id)
            expect(BondSystem.getPoints(id)).to.equal(before)
        end)
    end)

    -- ── Hook Callbacks ────────────────────────────────────────

    describe("hook callbacks", function()
        it("onBondEvent fires when points are awarded", function()
            local fired = false
            local receivedEvent = nil
            local receivedPoints = nil
            BondSystem.hooks.onBondEvent = function(playerId, eventType, points)
                if playerId == "test_callback" then
                    fired = true
                    receivedEvent = eventType
                    receivedPoints = points
                end
            end
            BondSystem.addPoints("test_callback", 10)
            expect(fired).to.equal(true)
            expect(receivedEvent).to.equal("custom")
            expect(receivedPoints).to.equal(10)
            BondSystem.hooks.onBondEvent = nil
        end)

        it("onTierChanged fires on tier promotion", function()
            local oldTierReceived = nil
            local newTierReceived = nil
            BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
                if playerId == "test_tier_cb" then
                    oldTierReceived = oldTier
                    newTierReceived = newTier
                end
            end
            BondSystem.addPoints("test_tier_cb", 10) -- triggers 0 → 1
            expect(oldTierReceived).to.equal(0)
            expect(newTierReceived).to.equal(1)
            BondSystem.hooks.onTierChanged = nil
        end)

        it("persist hook fires on setTier", function()
            local persisted = false
            local persistedTier = nil
            BondSystem.hooks.persist = function(playerId, tier, bondPoints)
                if playerId == "test_persist" then
                    persisted = true
                    persistedTier = tier
                end
            end
            BondSystem.setTier("test_persist", 3)
            expect(persisted).to.equal(true)
            expect(persistedTier).to.equal(3)
            BondSystem.hooks.persist = nil
        end)

        it("onTransitionLine fires on tier change", function()
            local lineReceived = nil
            local tierReceived = nil
            BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
                if playerId == "test_trans_line" then
                    lineReceived = line
                    tierReceived = tier
                end
            end
            BondSystem.addPoints("test_trans_line", 10) -- 0 → 1
            expect(tierReceived).to.equal(1)
            expect(lineReceived).to.be.a("string")
            BondSystem.hooks.onTransitionLine = nil
        end)
    end)

    -- ── Event Log ─────────────────────────────────────────────

    describe("event log", function()
        it("logs events and caps at 20 entries", function()
            local id = "test_eventlog"
            for _ = 1, 30 do
                BondSystem.addPoints(id, 1)
            end
            local data = BondSystem.getPlayerData(id)
            expect(#data.eventLog).to.equal(20)
        end)

        it("event log entries have event, points, and timestamp", function()
            local id = "test_eventlog_shape"
            BondSystem.addPoints(id, 5)
            local data = BondSystem.getPlayerData(id)
            local entry = data.eventLog[1]
            expect(entry.event).to.be.ok()
            expect(entry.points).to.be.ok()
            expect(entry.timestamp).to.be.ok()
        end)
    end)

    -- ── getPlayerData Snapshot ────────────────────────────────

    describe("getPlayerData", function()
        it("returns a complete snapshot", function()
            BondSystem.setTier("test_snapshot", 2)
            local data = BondSystem.getPlayerData("test_snapshot")
            expect(data.bondPoints).to.be.a("number")
            expect(data.tier).to.equal(2)
            expect(data.tierName).to.equal("Companion")
            expect(data.tierDescription).to.be.a("string")
            expect(data.behaviors).to.be.a("table")
            expect(data.hooksCompleted).to.be.a("number")
            expect(data.openHookCount).to.be.a("number")
            expect(data.totalHooks).to.be.a("number")
            expect(data.lastSeen).to.be.ok()
            expect(data.eventLog).to.be.a("table")
            expect(data.progress).to.be.a("table")
            expect(data.confessionGiven).to.equal(false)
        end)
    end)

    -- ── hasTier ───────────────────────────────────────────────

    describe("hasTier", function()
        it("returns true when player meets the minimum tier", function()
            BondSystem.setTier("test_hastier_2", 2)
            expect(BondSystem.hasTier("test_hastier_2", 0)).to.equal(true)
            expect(BondSystem.hasTier("test_hastier_2", 1)).to.equal(true)
            expect(BondSystem.hasTier("test_hastier_2", 2)).to.equal(true)
        end)

        it("returns false when player is below the tier", function()
            BondSystem.setTier("test_hastier_low", 1)
            expect(BondSystem.hasTier("test_hastier_low", 2)).to.equal(false)
            expect(BondSystem.hasTier("test_hastier_low", 3)).to.equal(false)
        end)

        it("returns true at exact tier 4 check", function()
            BondSystem.setTier("test_hastier_4", 4)
            expect(BondSystem.hasTier("test_hastier_4", 4)).to.equal(true)
        end)
    end)

    -- ── Additional Behavioral Queries ─────────────────────────

    describe("additional behavioral queries", function()
        it("shouldUseNicknames is false at tier 1, true at tier 2+", function()
            BondSystem.setTier("test_nick_1", 1)
            expect(BondSystem.shouldUseNicknames("test_nick_1")).to.equal(false)
            BondSystem.setTier("test_nick_2", 2)
            expect(BondSystem.shouldUseNicknames("test_nick_2")).to.equal(true)
        end)

        it("shouldReferenceHistory is false at tier 0, true at tier 1+", function()
            BondSystem.setTier("test_hist_0", 0)
            expect(BondSystem.shouldReferenceHistory("test_hist_0")).to.equal(false)
            BondSystem.setTier("test_hist_1", 1)
            expect(BondSystem.shouldReferenceHistory("test_hist_1")).to.equal(true)
        end)

        it("shouldVolunteerWork is false at tier 1, true at tier 2+", function()
            BondSystem.setTier("test_volun_1", 1)
            expect(BondSystem.shouldVolunteerWork("test_volun_1")).to.equal(false)
            BondSystem.setTier("test_volun_2", 2)
            expect(BondSystem.shouldVolunteerWork("test_volun_2")).to.equal(true)
        end)

        it("shouldAskPlayerToBuild is false at tier 2, true at tier 3+", function()
            BondSystem.setTier("test_ask_2", 2)
            expect(BondSystem.shouldAskPlayerToBuild("test_ask_2")).to.equal(false)
            BondSystem.setTier("test_ask_3", 3)
            expect(BondSystem.shouldAskPlayerToBuild("test_ask_3")).to.equal(true)
        end)

        it("shouldRefuseWork is false at tier 2, true at tier 3+", function()
            BondSystem.setTier("test_refuse_2", 2)
            expect(BondSystem.shouldRefuseWork("test_refuse_2")).to.equal(false)
            BondSystem.setTier("test_refuse_3", 3)
            expect(BondSystem.shouldRefuseWork("test_refuse_3")).to.equal(true)
        end)

        it("shouldDelegate is false at tier 3, true at tier 4", function()
            BondSystem.setTier("test_deleg_3", 3)
            expect(BondSystem.shouldDelegate("test_deleg_3")).to.equal(false)
            BondSystem.setTier("test_deleg_4", 4)
            expect(BondSystem.shouldDelegate("test_deleg_4")).to.equal(true)
        end)
    end)

    -- ── Customization Functions ───────────────────────────────

    describe("customization", function()
        it("setTierNames overrides names", function()
            BondSystem.setTierNames({
                [0] = "Outsider",
                [1] = "Known",
                [2] = "Friendly",
                [3] = "Inner",
                [4] = "Family",
            })
            local names = BondSystem.getTierNames()
            expect(names[0]).to.equal("Outsider")
            expect(names[4]).to.equal("Family")
            -- Restore defaults
            BondSystem.setTierNames({
                [0] = "Stranger",
                [1] = "Acquaintance",
                [2] = "Companion",
                [3] = "Trusted",
                [4] = "Ally",
            })
        end)

        it("setTransitionLines sets custom lines", function()
            BondSystem.setTransitionLines(1, { "Custom transition!" })
            local lineReceived = nil
            BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
                if playerId == "test_custom_lines" then
                    lineReceived = line
                end
            end
            BondSystem.addPoints("test_custom_lines", 10)
            expect(lineReceived).to.equal("Custom transition!")
            BondSystem.hooks.onTransitionLine = nil
        end)

        it("setThresholds changes tier boundaries", function()
            BondSystem.setThresholds({
                [0] = 0,
                [1] = 5,
                [2] = 15,
                [3] = 35,
                [4] = 75,
            })
            BondSystem.addPoints("test_custom_thresh", 5)
            expect(BondSystem.getTier("test_custom_thresh")).to.equal(1)
            BondSystem.addPoints("test_custom_thresh", 10) -- total 15
            expect(BondSystem.getTier("test_custom_thresh")).to.equal(2)
            -- Restore defaults
            BondSystem.setThresholds({
                [0] = 0,
                [1] = 10,
                [2] = 30,
                [3] = 70,
                [4] = 150,
            })
        end)
    end)

    -- ── Multiple Tier Transitions ─────────────────────────────

    describe("multi-tier progression", function()
        it("can progress through all tiers via behavior triggers", function()
            local id = "test_full_progression"
            -- Tier 0 → 1 (need 10 points)
            BondSystem.recordBuild(id)           -- +1
            BondSystem.recordIndependentBuild(id) -- +3
            BondSystem.recordModifyNotReplace(id) -- +2
            BondSystem.recordArguedAndWon(id)     -- +4  = 10 → tier 1
            expect(BondSystem.getTier(id)).to.equal(1)

            -- Tier 1 → 2 (need 30 points, have 10)
            BondSystem.recordHookCompleted(id)    -- +5 = 15
            BondSystem.recordHookCompleted(id)    -- +5 = 20
            BondSystem.recordHookCompleted(id)    -- +5 = 25
            BondSystem.recordIndependentBuild(id) -- +3 = 28
            BondSystem.recordModifyNotReplace(id) -- +2 = 30 → tier 2
            expect(BondSystem.getTier(id)).to.equal(2)
        end)

        it("addPoints with large negative after reaching tier 4 floors at tier 4", function()
            local id = "test_floor_tier4"
            BondSystem.setTier(id, 4)
            expect(BondSystem.getPoints(id)).to.equal(150)
            BondSystem.addPoints(id, -1000)
            expect(BondSystem.getPoints(id)).to.equal(150) -- floored
            expect(BondSystem.getTier(id)).to.equal(4)
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
