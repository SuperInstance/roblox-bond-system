# BondSystem — User Guide

## What Is BondSystem?

BondSystem is a **relationship system** for Roblox games. Instead of XP bars and grinding, relationships grow through **meaningful behavior**. The player never sees a number — they feel the change because the world starts treating them differently.

Think of it like real relationships: you don't level up a friendship. You just notice one day that someone calls you by a nickname, or starts trusting you with important things.

---

## Quick Start (5 Minutes)

### Step 1: Install

Create a `ModuleScript` in `ServerScriptService` named `BondSystem` and paste in the contents of `src/BondSystem.lua`.

### Step 2: Initialize

In any server script:

```lua
local BondSystem = require(script.Parent.BondSystem)

BondSystem.init()
```

That's it! BondSystem is now running. It will automatically track players joining and leaving.

### Step 3: Record Events

When a player does something meaningful, tell BondSystem:

```lua
-- Player built something
BondSystem.recordBuild(player.Name)

-- Player finished something that was left unfinished
BondSystem.recordHookCompleted(player.Name)

-- Player built something without being asked
BondSystem.recordIndependentBuild(player.Name)
```

### Step 4: Check the Relationship

```lua
local tier = BondSystem.getTier(player.Name)       -- 0 through 4
local name = BondSystem.getTierName(player.Name)    -- e.g. "Companion"
local behaviors = BondSystem.getBehaviors(player.Name)

if behaviors.argues then
    -- This NPC will now disagree with the player
end
```

---

## Understanding Tiers

There are five tiers. Each one changes how the world should react to the player.

### Tier 0 — Stranger (0–9 points)
The player is new. NPCs are formal, do their job, and don't get personal. Think of a shopkeeper you've never met — polite, transactional, forgettable.

### Tier 1 — Acquaintance (10–29 points)
The player has been around enough to be recognized. NPCs drop formality, start referencing previous interactions, and ask questions. Think of a barista who remembers your usual.

### Tier 2 — Companion (30–69 points)
The relationship has depth. NPCs will argue with the player, volunteer help unprompted, and use nicknames. Compliments are earned and specific. Think of a coworker you've bonded with over shared projects.

### Tier 3 — Trusted (70–149 points)
The player is no longer a guest — they're part of the group. NPCs say "we" instead of "I," ask the player to do things for them, and may refuse work because they think the player would do it better. They remember what the player *said*, not just what they *did*.

### Tier 4 — Ally (150+ points)
Full trust. NPCs stop holding things back, delegate entirely to the player, and are completely honest. This is the deepest relationship available.

---

## How Bond Points Work

Bond points are earned through **specific behaviors**, not grinding:

| What the Player Does | Points | Why |
|----------------------|--------|-----|
| Shows up and builds (first time per session) | +1 | Presence matters |
| Finishes something left unfinished | +5 | **This is the core loop** — curiosity and investment |
| Builds something without being asked | +3 | Independence is valued |
| Modifies existing work instead of replacing it | +2 | Investment in what's there |
| Argues back and wins | +4 | Pushback deepens trust |
| Returns after being away 24+ hours | +2 | Continuity matters |
| Deletes work without inspecting it | -1 | Dismissal has consequences (but won't drop below current tier) |

### The Floor Rule

Negative events **cannot** drop a player below their current tier. If someone is at tier 3 (70+ points), even repeated negative events will floor them at 70, not below. Once trust is earned, it's durable.

---

## The Hook System (The Fun Part)

The most powerful tool in BondSystem is the **open hook** — something deliberately left unfinished for the player to discover.

### How It Works

1. An NPC builds something but leaves a piece incomplete.
2. You register this as an open hook:

```lua
BondSystem.registerOpenHook(
    player.Name,
    "tower_roof",
    "The tower is missing its roof",
    Vector3.new(100, 50, 200)  -- world position
)
```

3. Later, when the player builds near that position, you can auto-detect it:

```lua
local nearbyHook = BondSystem.checkHookProximity(player.Name, buildPosition)
if nearbyHook then
    BondSystem.recordHookCompleted(player.Name, nearbyHook)
    -- +5 points! The biggest single reward.
end
```

4. Or let the player complete it manually and just call:

```lua
BondSystem.recordHookCompleted(player.Name, "tower_roof")
```

### Why Hooks Matter

Hooks create a gameplay loop: **bait → discovery → completion → reward**. The player feels like they're choosing to engage, not following a checklist. And the +5 reward is the largest single bond gain, making hooks the primary driver of relationship progression.

---

## Responding to Tier Changes

The most important hook is `onTierChanged`. This is where you make the player *feel* the relationship shifting:

```lua
BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    local player = game.Players:FindFirstChild(playerId)
    if not player then return end

    if newTier == 1 then
        -- NPC starts using the player's name
        -- NPC references previous interactions
    elseif newTier == 2 then
        -- NPC starts arguing
        -- NPC volunteers help
    elseif newTier == 3 then
        -- NPC starts saying "we"
        -- NPC asks the player to do things
    elseif newTier == 4 then
        -- NPC delegates entirely
        -- NPC is fully honest
    end
end
```

### Transition Lines

Each tier change picks a random **transition line** — a piece of dialogue that marks the moment. You can customize these:

```lua
BondSystem.setTransitionLines(2, {
    "You've got opinions. Good. I've been waiting for someone to argue with.",
    "Nah. Do it yourself, you'll do it better. Been watching you.",
})
```

Wire up `onTransitionLine` to display these through your dialogue system:

```lua
BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    local player = game.Players:FindFirstChild(playerId)
    showDialogue(player, npcName, line)
end
```

---

## Saving Progress

By default, BondSystem is in-memory only — progress is lost when the server restarts. To save it:

```lua
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("BondSystem")

BondSystem.hooks.persist = function(playerId, tier, points)
    pcall(function()
        store:SetAsync(playerId, { tier = tier, points = points })
    end)
end

BondSystem.hooks.load = function(playerId)
    local success, data = pcall(function()
        return store:GetAsync(playerId)
    end)
    if success and data then
        return data.tier, data.points
    end
    return nil, nil
end
```

When these hooks are wired, BondSystem automatically saves on tier changes, player leave, and confession delivery. It loads saved data on player join.

---

## Customizing Everything

BondSystem is designed to be themed for your game:

```lua
-- Rename tiers for your game's setting
BondSystem.setTierNames({
    [0] = "Outsider",
    [1] = "Initiate",
    [2] = "Member",
    [3] = "Veteran",
    [4] = "Legend",
})

-- Adjust point thresholds (call before init)
BondSystem.setThresholds({
    [0] = 0,
    [1] = 5,
    [2] = 15,
    [3] = 40,
    [4] = 100,
})

-- Add custom events
BondSystem.registerEventType("saved_from_danger", 6)
BondSystem.registerEventType("betrayed_trust", -3)

-- Fire them
BondSystem.fireEvent(player.Name, "saved_from_danger")
```

---

## Common Patterns

### Branching Dialogue

```lua
local function getNPCDialogue(playerId)
    local behaviors = BondSystem.getBehaviors(playerId)

    if behaviors.uses_we then
        return "We should head to the mines together."
    elseif behaviors.argues then
        return "You again? Fine. Let's see what you've got."
    elseif behaviors.references_previous_builds then
        return "Back again? Same kind of work?"
    else
        return "State your business."
    end
end
```

### Gating Content

```lua
local function canAccessDragonQuest(playerId)
    return BondSystem.hasTier(playerId, 3)
end
```

### Multiple NPCs Sharing a System

If all NPCs share one relationship system with the player:

```lua
BondSystem.recordBuild(player.Name)
-- All NPCs see the same tier
```

If each NPC has an independent relationship, use compound keys:

```lua
BondSystem.recordBuild("blacksmith:" .. player.Name)
BondSystem.recordBuild("merchant:" .. player.Name)
```

---

## Troubleshooting

**"My events aren't giving points"** — Make sure you're using the right player ID. If you call `recordBuild("Player1")` but check `getTier("player1")`, they won't match. Case-sensitive.

**"The tier won't go up"** — Check that your thresholds are correct. Use `getProgress(playerId)` to see how close the player is.

**"Points reset on rejoin"** — You haven't wired up persistence hooks. See the Saving Progress section above.

**"onTierChanged isn't firing"** — Make sure you set the hook *before* calling `init()`, or at least before the events that trigger the change.

**"I want to reset a player"** — Use `setTier(playerId, 0)` to reset to Stranger.
