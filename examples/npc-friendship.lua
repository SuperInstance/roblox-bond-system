--[[
    Example: NPC Friendship
    =======================
    A blacksmith NPC that warms up to the player through repeated
    positive interactions. Demonstrates custom tier names, transition
    lines, and behavior-driven dialogue.

    Requires: BondSystem in ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BondSystem = require(script.Parent.BondSystem)

-- ── Customize for the blacksmith ─────────────────────────────────────────

BondSystem.setTierNames({
    [0] = "Stranger",
    [1] = "Known Face",
    [2] = "Friendly",
    [3] = "Old Friend",
    [4] = "Sworn Brother",
})

BondSystem.setTransitionLines(1, {
    "Back again? Same kind of work? You've got a type.",
    "Oh, it's you. Good — I was getting bored.",
    "You keep showing up. I respect that.",
})

BondSystem.setTransitionLines(2, {
    "That's decent work. Don't let it go to your head, though.",
    "You've got opinions now? Good. About time.",
    "Nah, you do it. You're better at this than I thought.",
})

BondSystem.setTransitionLines(3, {
    "We make a good team. Don't tell anyone I said that.",
    "I need your help with something. Yeah, YOU specifically.",
    "We've been at this a while now, haven't we?",
})

BondSystem.setTransitionLines(4, {
    "You're the only one I trust with the forge. It's yours as much as mine.",
    "I don't say this often: you're family now. Deal with it.",
})

-- ── Hook up dialogue display ─────────────────────────────────────────────

BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    local player = Players:FindFirstChild(playerId)
    if not player then return end

    -- Replace with your actual dialogue GUI
    local gui = player:WaitForChild("PlayerGui"):FindFirstChild("DialogueGui")
    if gui then
        local label = gui:FindFirstChild("TextLabel", true)
        if label then
            label.Text = "[Blacksmith]: " .. line
        end
    end

    print(string.format("[Blacksmith → %s]: %s", playerId, line))
end

-- ── Persistence (DataStore) ──────────────────────────────────────────────

local DataStoreService = game:GetService("DataStoreService")
local bondStore = DataStoreService:GetDataStore("BlacksmithBonds")

BondSystem.hooks.persist = function(playerId, tier, points)
    pcall(function()
        bondStore:SetAsync(playerId, { tier = tier, points = points })
    end)
end

BondSystem.hooks.load = function(playerId)
    local success, data = pcall(function()
        return bondStore:GetAsync(playerId)
    end)
    if success and data then
        return data.tier, data.points
    end
    return nil, nil
end

-- ── Initialize ───────────────────────────────────────────────────────────

BondSystem.init()

-- ── Game hooks ───────────────────────────────────────────────────────────

-- When the player brings ore to the blacksmith
local function onPlayerBringsOre(player)
    BondSystem.recordBuild(player.Name)
end

-- When the player forges something independently
local function onPlayerForgesIndependently(player)
    BondSystem.recordIndependentBuild(player.Name)
end

-- When the player asks to modify a weapon instead of buying a new one
local function onPlayerModifiesWeapon(player)
    BondSystem.recordModifyNotReplace(player.Name)
end

-- When the player finishes a weapon the blacksmith left incomplete
local function onPlayerFinishesWeapon(player, weaponId)
    BondSystem.recordHookCompleted(player.Name, weaponId)
end

-- ── Dialogue selection based on tier ─────────────────────────────────────

local function getBlacksmithGreeting(playerId)
    local behaviors = BondSystem.getBehaviors(playerId)

    if behaviors.uses_we then
        -- Tier 3+: "we" language
        return "Hey partner. What are we working on today?"
    elseif behaviors.argues then
        -- Tier 2: casual, opinionated
        return "Back again? Fine. Let's see what you've got this time."
    elseif behaviors.references_previous_builds then
        -- Tier 1: recognizes the player
        return "Oh, it's you again. Same kind of work?"
    else
        -- Tier 0: formal
        return "State your business."
    end
end

-- ── Example: Register an open hook ───────────────────────────────────────
-- The blacksmith leaves a sword half-finished on the anvil

local function leaveSwordUnfinished(player)
    BondSystem.registerOpenHook(
        player.Name,
        "unfinished_sword_" .. player.Name,
        "A sword cooling on the anvil, missing its hilt wrapping.",
        Vector3.new(50, 5, 100)  -- anvil position
    )
end

-- When the player interacts with the anvil area, check proximity
local function onPlayerInteractAnvil(player, position)
    local hookId = BondSystem.checkHookProximity(player.Name, position)
    if hookId then
        BondSystem.recordHookCompleted(player.Name, hookId)
        print("[Blacksmith]: Huh. You finished it. Not bad.")
    end
end
