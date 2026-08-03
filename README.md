# BondSystem

**A behavior-triggered relationship module for Roblox.**

BondSystem replaces traditional XP grind with meaningful behavior. Players don't see a progress bar — they *feel* the relationship deepening through how the world treats them.

---

## Why Not XP?

XP systems reduce relationships to a number ticking upward. BondSystem takes a different approach:

- **No visible progress bar.** Players never see "47/70 to next tier." They notice the relationship has changed because the NPC starts treating them differently.
- **Behavior drives progression.** Completing tasks, showing independence, pushing back in disagreement — these are what deepen bonds, not repetitive grinding.
- **Each tier changes behavior, not stats.** Going from tier 2 to tier 3 doesn't give +5 strength. It means the NPC starts saying "we" instead of "I," asks the player for help, and refuses work because they think the player would do it better.
- **Negative events are floored.** You can't drop below your current tier. Once trust is earned, a bad day doesn't erase it.

---

## The Five Tiers

| Tier | Name | Points | What Changes |
|------|------|--------|--------------|
| 0 | **Stranger** | 0–9 | Transactional. Formal. States facts, offers one opinion. |
| 1 | **Acquaintance** | 10–29 | Drops formality. References previous interactions. Asks questions. |
| 2 | **Companion** | 30–69 | Argues with you. Volunteers help. Uses nicknames. |
| 3 | **Trusted** | 70–149 | Says "we." Asks you to do things. May refuse work. Remembers what you said. |
| 4 | **Ally** | 150+ | Full honesty. Delegates to you. Stops holding things back. |

---

## Behavior Triggers

These are the events that generate bond points:

| Event | Points | Description |
|-------|--------|-------------|
| `first_build_of_session` | +1 | First meaningful action of a session (showing up) |
| `hook_completed` | +5 | Finished something left unfinished (**core loop**) |
| `independent_build` | +3 | Built something without being asked |
| `modify_not_replace` | +2 | Improved existing work instead of replacing it |
| `argued_and_won` | +4 | Pushed back and was right |
| `returned_next_day` | +2 | Came back after 24+ hours |
| `deleted_without_inspection` | -1 | Dismissed work without looking (floored at current tier) |

### The Hook System

The **core loop** of BondSystem is the hook:

1. An entity leaves something deliberately unfinished (a wall without a roof, a path that stops short).
2. This is registered as an "open hook."
3. When the player completes it, `recordHookCompleted()` fires — the biggest single bond reward (+5).
4. This rewards curiosity and investment, not just task completion.

You can register hooks with world positions and use `checkHookProximity()` to auto-detect when a player builds near an unfinished area.

---

## Hook Mechanics

The hooks table is the integration point. Wire up your own systems:

```lua
local BondSystem = require(script.Parent.BondSystem)

BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    -- Fire a cutscene, change NPC dialogue, unlock a quest, etc.
    print(playerId .. " is now tier " .. newTier)
end

BondSystem.hooks.onBondEvent = function(playerId, eventType, points)
    -- Analytics, achievements, sound effects
end

BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    -- Display the transition line via your dialogue system
    print("[NPC]: " .. line)
end

BondSystem.hooks.persist = function(playerId, tier, bondPoints)
    -- Save to DataStore, your API, wherever
end

BondSystem.hooks.load = function(playerId)
    -- Return stored tier and points
    return 2, 45  -- or nil if no saved data
end
```

All hooks are optional. If you don't wire them up, BondSystem runs in-memory only.

---

## Quick Start

```lua
local BondSystem = require(script.Parent.BondSystem)

-- 1. Initialize (auto-hooks Players.PlayerAdded/Removing)
BondSystem.init()

-- 2. Record behaviors
BondSystem.recordBuild("Player1")           -- +1 (first build this session)
BondSystem.recordHookCompleted("Player1")   -- +5 (finished an open hook)
BondSystem.recordIndependentBuild("Player1") -- +3 (built without being asked)

-- 3. Query relationship state
local tier = BondSystem.getTier("Player1")          -- 1 (Acquaintance)
local name = BondSystem.getTierName("Player1")      -- "Acquaintance"
local behaviors = BondSystem.getBehaviors("Player1")

-- 4. Branch behavior based on tier
if behaviors.argues then
    -- NPC will disagree with the player now
end
if behaviors.uses_we then
    -- NPC says "we" instead of "I"
end
```

---

## API Reference

### Lifecycle

| Method | Description |
|--------|-------------|
| `BondSystem.init()` | Initialize. Hooks into player join/leave. |
| `BondSystem.onPlayerJoin(playerId)` | Call on manual join handling. Checks return-after-absence. |

### Behavior Triggers

| Method | Points | Description |
|--------|--------|-------------|
| `recordBuild(playerId)` | +1 | First build per session. |
| `recordHookCompleted(playerId, hookId?)` | +5 | Finished an open hook. |
| `recordIndependentBuild(playerId)` | +3 | Built without being asked. |
| `recordModifyNotReplace(playerId)` | +2 | Modified instead of replaced. |
| `recordArguedAndWon(playerId)` | +4 | Argued back and won. |
| `recordReturn(playerId)` | +2 | Returned after 24h+ absence. |
| `recordDeleteWithoutInspection(playerId)` | -1 | Deleted without looking. |
| `addPoints(playerId, amount)` | custom | Raw points (any custom event). |
| `fireEvent(playerId, eventType)` | varies | Fire any registered event type. |

### Hook Management

| Method | Description |
|--------|-------------|
| `registerOpenHook(playerId, hookId, description, position?)` | Register unfinished work for the player to discover. |
| `hasOpenHooks(playerId)` | Boolean — are there unfinished hooks? |
| `getOpenHooks(playerId)` | Table of all open hooks. |
| `checkHookProximity(playerId, position)` | Returns hookId if near an open hook (within 30 studs). |

### Tier & Behavior Queries

| Method | Returns | Description |
|--------|---------|-------------|
| `getTier(playerId)` | `number` (0–4) | Current tier. |
| `getPoints(playerId)` | `number` | Total bond points. |
| `getTierName(playerId)` | `string` | Tier name (e.g. "Ally"). |
| `getBehaviors(playerId)` | `table` | All behavior flags for current tier. |
| `getProgress(playerId)` | `table` | Progress to next tier (internal/admin). |
| `getPlayerData(playerId)` | `table` | Full bond state snapshot. |
| `hasTier(playerId, minTier)` | `boolean` | Check minimum tier. |

### Behavioral Queries

Each returns a boolean for branching NPC/AI behavior:

| Method | Unlocks At |
|--------|------------|
| `shouldUseWe(playerId)` | Tier 3+ |
| `argumentsUnlocked(playerId)` | Tier 2+ |
| `shouldUseNicknames(playerId)` | Tier 2+ |
| `shouldReferenceHistory(playerId)` | Tier 1+ |
| `shouldVolunteerWork(playerId)` | Tier 2+ |
| `shouldAskPlayerToBuild(playerId)` | Tier 3+ |
| `shouldRefuseWork(playerId)` | Tier 3+ |
| `shouldDelegate(playerId)` | Tier 4 |
| `leavesThingsUnfinished(playerId)` | Tier 0–3 (true), Tier 4 (false) |
| `shouldDeliverConfession(playerId)` | Tier 4, not yet delivered |
| `markConfessionDelivered(playerId)` | One-time flag. |

### Customization

| Method | Description |
|--------|-------------|
| `setTierNames(names)` | Override tier names. Call before `init()`. |
| `setTierDescriptions(descriptions)` | Override tier descriptions. |
| `setTransitionLines(tier, lines)` | Custom dialogue for tier transitions. |
| `setThresholds(thresholds)` | Custom point thresholds. Call before `init()`. |
| `registerEventType(name, points)` | Add a custom event type. |

### Admin

| Method | Description |
|--------|-------------|
| `setTier(playerId, tier)` | Force-set tier (debug/admin). |
| `getThresholds()` | Get tier threshold table. |
| `getTierNames()` | Get tier names table. |

---

## Examples

### 1. NPC Friendship

An NPC that warms up to the player through repeated positive interactions.

```lua
local BondSystem = require(script.Parent.BondSystem)

-- Customize for a blacksmith NPC
BondSystem.setTierNames({
    [0] = "Stranger",
    [1] = "Known Face",
    [2] = "Friendly",
    [3] = "Old Friend",
    [4] = "Sworn Brother",
})

BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    local player = game.Players:FindFirstChild(playerId)
    if player then
        -- Display via your dialogue GUI
        showDialogue(player, "Blacksmith", line)
    end
end

BondSystem.init()

-- When the player brings ore to the blacksmith
BondSystem.recordBuild(player.Name)

-- When the player forges something independently
BondSystem.recordIndependentBuild(player.Name)
```

### 2. Quest Giver Trust

A quest giver who only offers high-stakes quests to trusted players.

```lua
local BondSystem = require(script.Parent.BondSystem)
BondSystem.init()

function offerQuest(player, questId)
    if questId == "dragon_slayer" and not BondSystem.hasTier(player.Name, 3) then
        showDialogue(player, "QuestMaster",
            "You're not ready for that. Come back when you've proven yourself.")
        return
    end

    -- Offer the quest
    startQuest(player, questId)
end

-- Completing quests builds trust
function onQuestCompleted(player, questId)
    BondSystem.recordHookCompleted(player.Name, questId)
end
```

### 3. Companion AI

An AI companion whose combat behavior changes with bond level.

```lua
local BondSystem = require(script.Parent.BondSystem)
BondSystem.init()

function getCompanionBehavior(playerId)
    local behaviors = BondSystem.getBehaviors(playerId)

    return {
        -- At tier 0, companion fights independently
        -- At tier 2+, they coordinate with player
        coordinateAttacks = behaviors.argues,  -- willing to disagree = willing to coordinate
        -- At tier 3+, they protect the player proactively
        proactiveDefense = behaviors.uses_we,
        -- At tier 4, they follow player's lead entirely
        deferToPlayer = behaviors.delegates_to_player,
        -- At tier 2+, they use casual banter
        useNicknames = behaviors.uses_nicknames,
    }
end
```

### 4. Faction Reputation

Track standing with multiple factions using separate BondSystem instances.

```lua
-- BondSystem is a module, so you can require it multiple times
-- and use playerId as "factionId:playerName" to namespace.

local BondSystem = require(script.Parent.BondSystem)

-- Customize for the Merchants Guild
BondSystem.setTierNames({
    [0] = "Outsider",
    [1] = "Recognized",
    [2] = "Member",
    [3] = "Trader",
    [4] = "Guildmaster",
})

BondSystem.init()

-- Use compound keys for faction tracking
local function makeFactionKey(factionId, playerId)
    return factionId .. ":" .. playerId
end

function onTradeCompleted(player, factionId)
    local key = makeFactionKey(factionId, player.Name)
    BondSystem.recordBuild(key)
end

function getFactionStanding(player, factionId)
    local key = makeFactionKey(factionId, player.Name)
    return BondSystem.getTierName(key), BondSystem.getTier(key)
end
```

### 5. Mentor-Student Progression

A mentor who gradually delegates more responsibility as trust builds.

```lua
local BondSystem = require(script.Parent.BondSystem)

BondSystem.setTierNames({
    [0] = "Novice",
    [1] = "Student",
    [2] = "Apprentice",
    [3] = "Journeyman",
    [4] = "Master",
})

BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    local player = game.Players:FindFirstChild(playerId)
    if not player then return end

    if newTier == 2 then
        -- Unlock advanced techniques
        grantAbility(player, "AdvancedCrafting")
    elseif newTier == 3 then
        -- Mentor starts giving solo assignments
        grantAbility(player, "SoloQuests")
    elseif newTier == 4 then
        -- Full delegation — mentor steps back
        showDialogue(player, "Mentor",
            "You don't need me watching anymore. Take the workshop. It's yours.")
        grantAbility(player, "WorkshopOwnership")
    end
end

BondSystem.init()

-- Student completes a lesson
function onLessonCompleted(player)
    BondSystem.recordHookCompleted(player.Name)
end

-- Student practices independently
function onIndependentPractice(player)
    BondSystem.recordIndependentBuild(player.Name)
end

-- Student corrects the mentor (rare and powerful)
function onStudentCorrection(player)
    BondSystem.recordArguedAndWon(player.Name)
end
```

---

## Persistence

BondSystem is in-memory by default. To persist across sessions, wire up the `persist` and `load` hooks:

### DataStore Example

```lua
local DataStoreService = game:GetService("DataStoreService")
local bondStore = DataStoreService:GetDataStore("BondSystem")

BondSystem.hooks.persist = function(playerId, tier, bondPoints)
    pcall(function()
        bondStore:SetAsync(playerId, { tier = tier, points = bondPoints })
    end)
end

BondSystem.hooks.load = function(playerId)
    local data = bondStore:GetAsync(playerId)
    if data then
        return data.tier, data.points
    end
    return nil, nil
end
```

---

## Installation

### With Rojo

1. Copy `src/BondSystem.lua` into your project's `src/` directory.
2. Use the `default.project.json` as your Rojo project file, or merge the tree into your existing project.

### Manual

1. Create a `ModuleScript` in `ServerScriptService`.
2. Paste the contents of `src/BondSystem.lua`.
3. `require()` it from your server scripts.

---

## License

MIT — see [LICENSE](LICENSE).
