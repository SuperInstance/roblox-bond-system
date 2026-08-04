-- examples/tier_gating.lua
-- Locking content behind bond tiers using BondSystem.
-- Place in StarterPlayerScripts (LocalScript) or ServerScript.
--
-- Demonstrates tier-gated game content:
--   • Tier 0 (Stranger): Basic blocks only, no customization
--   • Tier 1 (Acquaintance): Unlock colors and materials
--   • Tier 2 (Companion): Unlock advanced shapes, NPC gives tips
--   • Tier 3 (Trusted): Unlock special builds, shared workspace
--   • Tier 4 (Ally): Full creative mode, delegate builds to NPC
--
-- This pattern lets you gate content through RELATIONSHIP rather than
-- grinding or paywalls — players unlock features by engaging deeply
-- with the building system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local BondSystem = require(ReplicatedStorage:WaitForChild("BondSystem"))

-- ============================================================
--  Tier-gated content definitions
-- ============================================================

-- Build commands available at each tier
local TIER_BUILD_PERKS = {
    [0] = {
        label = "Basic Builder",
        maxParts = 20,
        allowedMaterials = { "SmoothPlastic", "Wood" },
        allowedShapes = { "Block" },
        canUseColors = false,
        canBuildAtNight = false,
        npcAssists = false,
    },
    [1] = {
        label = "Apprentice",
        maxParts = 50,
        allowedMaterials = { "SmoothPlastic", "Wood", "WoodPlanks", "Brick", "Concrete" },
        allowedShapes = { "Block", "Ball" },
        canUseColors = true,
        canBuildAtNight = false,
        npcAssists = false,
    },
    [2] = {
        label = "Journeyman",
        maxParts = 100,
        allowedMaterials = {
            "SmoothPlastic", "Wood", "WoodPlanks", "Brick", "Concrete",
            "Slate", "Granite", "Marble", "Metal", "Glass",
        },
        allowedShapes = { "Block", "Ball", "Cylinder", "Wedge" },
        canUseColors = true,
        canBuildAtNight = true,
        npcAssists = true,  -- NPC will volunteer to help
    },
    [3] = {
        label = "Master Builder",
        maxParts = 250,
        allowedMaterials = {},  -- empty = all materials
        allowedShapes = {},     -- empty = all shapes
        canUseColors = true,
        canBuildAtNight = true,
        npcAssists = true,
        canModifyNPCBuilds = true,
        sharedWorkspace = true,
    },
    [4] = {
        label = "Architect (Full Trust)",
        maxParts = 0,  -- 0 = unlimited
        allowedMaterials = {},
        allowedShapes = {},
        canUseColors = true,
        canBuildAtNight = true,
        npcAssists = true,
        canModifyNPCBuilds = true,
        sharedWorkspace = true,
        canDelegateToNPC = true,  -- NPC will build FOR the player
        canMarkUnfinished = true, -- Player can leave hooks for NPC
    },
}

-- ============================================================
--  Gate check functions
-- ============================================================

-- Cache the perk table for performance
local function getPerks(playerId)
    local tier = BondSystem.getTier(playerId)
    return TIER_BUILD_PERKS[tier] or TIER_BUILD_PERKS[0]
end

--[[
    Check if a player can use a specific material.
    @param playerId string
    @param material string -- material name
    @return boolean
]]
local function canUseMaterial(playerId, material)
    local perks = getPerks(playerId)
    if #perks.allowedMaterials == 0 then return true end  -- empty = all allowed
    for _, m in ipairs(perks.allowedMaterials) do
        if m == material then return true end
    end
    return false
end

--[[
    Check if a player can build more parts.
    @param playerId string
    @param currentPartCount number
    @return boolean
]]
local function canBuildMore(playerId, currentPartCount)
    local perks = getPerks(playerId)
    if perks.maxParts == 0 then return true end  -- 0 = unlimited
    return currentPartCount < perks.maxParts
end

--[[
    Check if a player can use a specific shape.
    @param playerId string
    @param shape string
    @return boolean
]]
local function canUseShape(playerId, shape)
    local perks = getPerks(playerId)
    if #perks.allowedShapes == 0 then return true end
    for _, s in ipairs(perks.allowedShapes) do
        if s == shape then return true end
    end
    return false
end

--[[
    Check if the NPC will assist the player.
    Tier 2+: NPC volunteers help. Tier 3+: NPC can build independently.
    @param playerId string
    @return boolean
]]
local function npcWillAssist(playerId)
    return getPerks(playerId).npcAssists
end

-- ============================================================
--  Content unlock notifications
-- ============================================================

local UNLOCK_MESSAGES = {
    [1] = {
        "Colors unlocked. You can now paint your builds.",
        "New materials available: Brick, Concrete, WoodPlanks.",
    },
    [2] = {
        "Advanced shapes unlocked: Cylinder, Wedge, Ball.",
        "I'll help you build now. Just ask — or don't, I'll figure it out.",
        "You can build at night. The lanterns stay on for you.",
    },
    [3] = {
        "All materials and shapes unlocked.",
        "Shared workspace active. We can build together.",
        "You can modify my builds now. I trust your judgment.",
    },
    [4] = {
        "No limits. Build whatever you want, wherever you want.",
        "I can build FOR you now. Just point, I'll make it.",
        "Full creative control. It's yours.",
    },
}

local function notifyUnlocks(playerId, newTier)
    local messages = UNLOCK_MESSAGES[newTier]
    if not messages then return end

    local perks = TIER_BUILD_PERKS[newTier]
    print(string.format("\n🎉 NEW PERKS UNLOCKED: %s (Tier %d)", perks.label, newTier))
    for _, msg in ipairs(messages) do
        print(string.format("  ✦ %s", msg))
    end
end

-- ============================================================
--  Wire into BondSystem tier changes
-- ============================================================

BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    notifyUnlocks(playerId, newTier)
end

-- ============================================================
--  Demo: simulate tier progression and show gated content
-- ============================================================

local PLAYER_ID = "TestBuilder"

BondSystem.init()

-- Helper: try to build something and check if it's allowed
local function tryBuild(playerId, action, ...)
    local tier = BondSystem.getTier(playerId)
    local tierName = BondSystem.getTierName(playerId)
    local ok, reason

    if action == "material" then
        local material = ...
        ok = canUseMaterial(playerId, material)
        reason = ok and "✅ allowed" or ("❌ blocked — " .. material .. " not available at " .. tierName)
    elseif action == "shape" then
        local shape = ...
        ok = canUseShape(playerId, shape)
        reason = ok and "✅ allowed" or ("❌ blocked — " .. shape .. " not available at " .. tierName)
    elseif action == "partCount" then
        local count = ...
        ok = canBuildMore(playerId, count)
        reason = ok and "✅ can build more" or ("❌ blocked — at part limit (" .. count .. "/" .. getPerks(playerId).maxParts .. ")")
    elseif action == "assist" then
        ok = npcWillAssist(playerId)
        reason = ok and "✅ NPC volunteers to help" or "❌ NPC won't assist yet"
    elseif action == "delegate" then
        ok = BondSystem.shouldDelegate(playerId)
        reason = ok and "✅ NPC will build FOR you" or "❌ delegation not unlocked yet"
    end

    print(string.format("  [%s %s] %s: %s", tierName, tier, action, reason))
    return ok
end

-- Run simulation
print("\n" .. string.rep("═", 60))
print("  TIER GATING SIMULATION")
print(string.rep("═", 60))

-- Tier 0: Stranger
print("\n── TIER 0: Stranger ──")
tryBuild(PLAYER_ID, "material", "SmoothPlastic")
tryBuild(PLAYER_ID, "material", "Glass")
tryBuild(PLAYER_ID, "shape", "Block")
tryBuild(PLAYER_ID, "shape", "Cylinder")
tryBuild(PLAYER_ID, "partCount", 15)
tryBuild(PLAYER_ID, "partCount", 25)
tryBuild(PLAYER_ID, "assist")

-- Grant tier 1
BondSystem.setTier(PLAYER_ID, 1)
print("\n── TIER 1: Acquaintance ──")
tryBuild(PLAYER_ID, "material", "Brick")
tryBuild(PLAYER_ID, "material", "Metal")
tryBuild(PLAYER_ID, "shape", "Ball")
tryBuild(PLAYER_ID, "shape", "Wedge")

-- Grant tier 2
BondSystem.setTier(PLAYER_ID, 2)
print("\n── TIER 2: Companion ──")
tryBuild(PLAYER_ID, "material", "Glass")
tryBuild(PLAYER_ID, "shape", "Cylinder")
tryBuild(PLAYER_ID, "shape", "Wedge")
tryBuild(PLAYER_ID, "assist")
tryBuild(PLAYER_ID, "delegate")

-- Grant tier 3
BondSystem.setTier(PLAYER_ID, 3)
print("\n── TIER 3: Trusted ──")
tryBuild(PLAYER_ID, "material", "Neon")
tryBuild(PLAYER_ID, "partCount", 200)
tryBuild(PLAYER_ID, "partCount", 251)

-- Grant tier 4
BondSystem.setTier(PLAYER_ID, 4)
print("\n── TIER 4: Ally ──")
tryBuild(PLAYER_ID, "material", "Neon")
tryBuild(PLAYER_ID, "partCount", 999)
tryBuild(PLAYER_ID, "delegate")

print("\n" .. string.rep("═", 60))
print("  Content unlocks are driven by relationship depth,")
print("  not grinding or payment. Players earn tools by building well.")
print(string.rep("═", 60))
