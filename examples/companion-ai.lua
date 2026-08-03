--[[
    Example: Companion AI
    =====================
    An AI companion whose combat behavior, dialogue, and autonomy
    change based on bond level. At low tiers the companion is a
    hired sword. At high tiers they're a trusted partner who
    follows the player's lead.

    Requires: BondSystem in ServerScriptService
]]

local Players = game:GetService("Players")
local BondSystem = require(script.Parent.BondSystem)

-- ── Customize tiers for a companion ──────────────────────────────────────

BondSystem.setTierNames({
    [0] = "Hired Sword",
    [1] = "Traveling Companion",
    [2] = "Trusted Ally",
    [3] = "Sworn Partner",
    [4] = "Bonded",
})

BondSystem.setTransitionLines(1, {
    "You fight better than I expected. I noticed.",
    "Same road again tomorrow? ...Good.",
})

BondSystem.setTransitionLines(2, {
    "I've got your back. Not because I'm paid to — because I want to.",
    "You're not half bad at this. Don't tell anyone I said that.",
})

BondSystem.setTransitionLines(3, {
    "We move as one now. Your instincts, my blade.",
    "I'm not going anywhere. We're in this together.",
})

BondSystem.setTransitionLines(4, {
    "I follow you because I choose to. There's nowhere else I'd rather be.",
    "You're not my employer. You're my family. Say the word and I'm there.",
})

-- ── Hook: Update companion model on tier change ──────────────────────────

BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    local player = Players:FindFirstChild(playerId)
    if not player then return end

    local companion = workspace:FindFirstChild("Companion_" .. playerId)
    if not companion then return end

    -- Visual changes per tier (e.g., companion gets new gear)
    if newTier >= 2 then
        -- Give companion matching colors to player
        local playerColor = player.Character and player.Character:FindFirstChild("Body Colors")
        if playerColor then
            -- Mirror player's color scheme on companion
        end
    end

    if newTier >= 3 then
        -- Unlock coordinated abilities
        grantAbility(player, "CoordinatedStrike")
    end

    if newTier >= 4 then
        -- Unlock ultimate team ability
        grantAbility(player, "BondedFury")
    end
end

-- ── Companion behavior configuration ─────────────────────────────────────

local CompanionState = {
    FOLLOW_DISTANCE_CLOSE = 5,
    FOLLOW_DISTANCE_NORMAL = 12,
    FOLLOW_DISTANCE_FAR = 20,
}

local function getCompanionBehavior(playerId)
    local behaviors = BondSystem.getBehaviors(playerId)

    return {
        -- Tier 0-1: follows at a distance, fights independently
        -- Tier 2+: stays close, coordinates attacks
        followDistance = behaviors.argues and
            CompanionState.FOLLOW_DISTANCE_CLOSE or
            CompanionState.FOLLOW_DISTANCE_NORMAL,

        -- Tier 2+: proactively attacks threats near the player
        proactiveCombat = behaviors.argues or false,

        -- Tier 3+: calls out enemy positions, shares information
        tacticalCommunication = behaviors.uses_we or false,

        -- Tier 3+: will refuse to engage in fights the companion
        -- thinks are bad ideas
        willDisengage = behaviors.refuses_work or false,

        -- Tier 4: defers entirely to player's tactical calls
        deferToPlayer = behaviors.delegates_to_player or false,

        -- Tier 2+: uses casual banter and nicknames
        useBanter = behaviors.uses_nicknames or false,

        -- Tier 1+: comments on the environment, references past battles
        referencesHistory = behaviors.references_previous_builds or false,
    }
end

-- ── Companion AI update loop ─────────────────────────────────────────────

local function updateCompanionAI(playerId)
    local config = getCompanionBehavior(playerId)
    local companion = workspace:FindFirstChild("Companion_" .. playerId)
    local player = Players:FindFirstChild(playerId)
    if not companion or not player or not player.Character then return end

    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Follow behavior
    local companionHRP = companion:FindFirstChild("HumanoidRootPart")
    if companionHRP then
        local distance = (companionHRP.Position - hrp.Position).Magnitude
        if distance > config.followDistance then
            local humanoid = companion:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:MoveTo(hrp.Position)
            end
        end
    end

    -- Combat behavior
    if config.proactiveCombat then
        -- Scan for nearby enemies and engage
        for _, enemy in ipairs(workspace:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
                local enemyDist = (enemy.HumanoidRootPart.Position - hrp.Position).Magnitude
                if enemyDist < 30 then
                    -- Engage the enemy
                    local humanoid = companion:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid:MoveTo(enemy.HumanoidRootPart.Position)
                    end
                    break
                end
            end
        end
    end
end

-- ── Companion dialogue ───────────────────────────────────────────────────

local function getCompanionLine(playerId, situation)
    local config = getCompanionBehavior(playerId)
    local tier = BondSystem.getTier(playerId)

    if situation == "idle" then
        if tier >= 4 then
            return "Nothing to do? Good. I could use the quiet."
        elseif config.useBanter then
            return "You hear that? Probably nothing. Probably."
        elseif config.referencesHistory then
            return "This reminds me of that mess we got into last week."
        else
            return nil  -- silent at tier 0
        end
    end

    if situation == "combat_start" then
        if config.deferToPlayer then
            return "Your call. Where do you need me?"
        elseif config.tacticalCommunication then
            return "Three on the left. I'll take the right."
        elseif config.proactiveCombat then
            return "I've got them."
        else
            return nil  -- silent, just fights
        end
    end

    if situation == "low_health" then
        if tier >= 3 then
            return "Fall back. I'll hold them. GO."
        elseif config.useBanter then
            return "You look terrible. Mind standing behind me?"
        else
            return nil
        end
    end

    if situation == "victory" then
        if tier >= 4 then
            return "Clean work. As always."
        elseif config.useBanter then
            return "Not bad. I did most of it, but not bad."
        elseif config.referencesHistory then
            return "Easier than last time."
        else
            return nil
        end
    end
end

-- ── Bond triggers in combat ──────────────────────────────────────────────

-- When the companion goes down and the player saves them
local function onPlayerSavesCompanion(player)
    BondSystem.addPoints(player.Name, 4)
end

-- When the player and companion defeat a boss together
local function onSharedVictory(player)
    BondSystem.recordHookCompleted(player.Name, "boss_fight")
end

-- When the player gives the companion a better weapon
local function onPlayerGivesGift(player)
    BondSystem.recordModifyNotReplace(player.Name)
end

-- When the player disobeys the companion's advice and wins
local function onPlayerDefiesCompanion(player)
    BondSystem.recordArguedAndWon(player.Name)
end

-- ── Main loop ────────────────────────────────────────────────────────────

BondSystem.init()

game:GetService("RunService").Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        updateCompanionAI(player.Name)
    end
end)

-- Helper stub
function grantAbility(player, abilityName)
    -- Implement your ability unlock system here
    print("[Companion] Granted " .. abilityName .. " to " .. player.Name)
end
