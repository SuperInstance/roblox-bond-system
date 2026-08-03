# BondSystem — Engineering Manual

## Architecture

BondSystem is a single-file Lua module (~700 lines) with zero external dependencies. It manages relationship state for an arbitrary number of players, keyed by string IDs.

### Design Principles

1. **Behavior, not numbers.** The player never sees a progress bar. Tier transitions are communicated through behavioral changes in external systems (dialogue, NPC actions, quest availability).
2. **Hooks over coupling.** Instead of requiring specific services, BondSystem exposes a `hooks` table. Consumers wire up their own persistence, dialogue, and notification systems.
3. **Floor, not ceiling.** Negative events cannot drop a player below their current tier floor. Trust is sticky.
4. **Discrete events.** Bond points come from specific, meaningful behaviors — not time spent or repetitive actions.

### Module Structure

```
BondSystem.lua
├── Configuration (thresholds, names, descriptions, events, behaviors)
├── State Management (playerData, openHooks)
├── Tier Transition Handling
├── Public API
│   ├── Lifecycle (init, onPlayerJoin)
│   ├── Behavior Triggers (recordBuild, recordHookCompleted, etc.)
│   ├── Hook Management (registerOpenHook, checkHookProximity, etc.)
│   ├── Queries (getTier, getBehaviors, getProgress, etc.)
│   ├── Behavioral Queries (shouldUseWe, argumentsUnlocked, etc.)
│   └── Customization (setTierNames, registerEventType, etc.)
└── return BondSystem
```

---

## Trigger System

### How Triggers Work

Each trigger is a simple function call that:

1. Looks up the point value from `BOND_EVENTS`.
2. Applies the points to the player's total.
3. Checks if the new total crosses a tier threshold.
4. If yes, fires `onTierChanged` → which fires transition lines, `onTierChanged` hook, and persistence.
5. Fires `onBondEvent` hook for every event (analytics, achievements).

### The Core Loop: Hooks

The hook system is the heart of BondSystem. It creates a gameplay loop:

```
Entity leaves work unfinished
    → registerOpenHook(playerId, hookId, description, position)
    → Player explores and finds the unfinished work
    → Player completes it
    → checkHookProximity(playerId, buildPosition) detects it
    → recordHookCompleted(playerId, hookId)
    → +5 bond points (the largest single reward)
```

This rewards curiosity, investment, and attention — not grinding.

### Negative Events

Only one negative trigger exists by default: `deleted_without_inspection` (-1). This is floored at the current tier threshold, meaning a player at tier 2 (30 points) can never go below 30 points from negative events.

### Custom Events

Two mechanisms for custom triggers:

- **`registerEventType(name, points)`** — adds a new entry to the `BOND_EVENTS` table. Fire it with `fireEvent(playerId, name)`.
- **`addPoints(playerId, amount)`** — bypass the event table entirely. Useful for one-off events or dynamic point values.

---

## Tier Behaviors

Each tier has 14 boolean behavior flags. These are cumulative — each tier enables everything from prior tiers plus new behaviors.

| Flag | T0 | T1 | T2 | T3 | T4 |
|------|----|----|----|----|----|
| `uses_formal_address` | ✓ | | | | |
| `references_previous_builds` | | ✓ | ✓ | ✓ | ✓ |
| `asks_questions` | | ✓ | ✓ | ✓ | ✓ |
| `shares_opinions` | | ✓ | ✓ | ✓ | ✓ |
| `argues` | | | ✓ | ✓ | ✓ |
| `volunteers_work` | | | ✓ | ✓ | ✓ |
| `uses_nicknames` | | | ✓ | ✓ | ✓ |
| `uses_we` | | | | ✓ | ✓ |
| `asks_player_to_build` | | | | ✓ | ✓ |
| `refuses_work` | | | | ✓ | ✓ |
| `remembers_conversation` | | | | ✓ | ✓ |
| `leaves_things_unfinished` | ✓ | ✓ | ✓ | ✓ | |
| `confesses_pattern` | | | | | ✓ |
| `delegates_to_player` | | | | | ✓ |

### Querying Behaviors

```lua
local behaviors = BondSystem.getBehaviors(playerId)

if behaviors.argues then
    -- NPC can disagree
end
if behaviors.uses_we then
    -- Use shared language
end
```

Or use the convenience methods:

```lua
if BondSystem.shouldDelegate(playerId) then
    -- Tier 4 behavior
end
```

### Customizing Behaviors

The behavior table is internal but queryable. To add game-specific behavior flags, track them externally keyed by tier:

```lua
local customBehaviors = {
    [0] = { can_open_shop = false },
    [1] = { can_open_shop = false },
    [2] = { can_open_shop = true },
    -- ...
}

local function getCustomBehavior(playerId)
    local tier = BondSystem.getTier(playerId)
    return customBehaviors[tier] or {}
end
```

---

## Persistence Patterns

### Pattern 1: In-Memory Only (Default)

No persistence hooks wired. State is lost on server shutdown. Good for testing or ephemeral sessions.

### Pattern 2: DataStore

```lua
local DataStoreService = game:GetService("DataStoreService")
local store = DataStoreService:GetDataStore("BondSystem_v1")

BondSystem.hooks.persist = function(playerId, tier, points)
    pcall(function()
        store:SetAsync("bond_" .. playerId, {
            tier = tier,
            points = points,
        })
    end)
end

BondSystem.hooks.load = function(playerId)
    local success, data = pcall(function()
        return store:GetAsync("bond_" .. playerId)
    end)
    if success and data then
        return data.tier, data.points
    end
    return nil, nil
end
```

### Pattern 3: External API (HTTP)

```lua
local HttpService = game:GetService("HttpService")
local API_URL = "https://your-api.example.com"

BondSystem.hooks.persist = function(playerId, tier, points)
    task.spawn(function()
        pcall(function()
            HttpService:RequestAsync({
                Url = API_URL .. "/bonds/" .. playerId,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ tier = tier, points = points }),
            })
        end)
    end)
end

BondSystem.hooks.load = function(playerId)
    -- Must return synchronously. Use a cached approach:
    local cache = _G.bondCache or {}
    _G.bondCache = cache

    if cache[playerId] then
        return cache[playerId].tier, cache[playerId].points
    end

    -- Pre-load on PlayerAdded before init
    task.spawn(function()
        local ok, response = pcall(function()
            return HttpService:RequestAsync({
                Url = API_URL .. "/bonds/" .. playerId,
                Method = "GET",
            })
        end)
        if ok and response.Success then
            local data = HttpService:JSONDecode(response.Body)
            cache[playerId] = data
        end
    end)

    return nil, nil
end
```

### Persistence Timing

- **On tier change**: `onTierChanged` → `hooks.persist` fires automatically.
- **On player leave**: `init()` hooks `Players.PlayerRemoving` → `hooks.persist`.
- **On confession**: `markConfessionDelivered()` → `hooks.persist`.
- **On `setTier`**: Fires `onTierChanged` (if tier actually changed) or direct `hooks.persist`.

### Multi-Faction Pattern

BondSystem uses string keys. To track multiple factions:

```lua
local function key(faction, playerId) return faction .. ":" .. playerId end

-- Record events per-faction
BondSystem.recordBuild(key("merchants", player.Name))
BondSystem.recordBuild(key("guard", player.Name))
```

This works because each key gets its own entry in `playerData`. The only caveat is that `init()` hooks into `Players.PlayerAdded/Removing` using `player.Name` directly — for multi-faction use, skip `init()` and manage join/leave manually, or clear faction data on leave.

---

## Event Log

Each player has an event log (capped at 20 entries) accessible via `getPlayerData().eventLog`. Each entry:

```lua
{
    event = "hook_completed",
    points = 5,
    timestamp = 1691000000,
}
```

Useful for debugging and for personality systems that reference recent behavior.

---

## Thread Safety

BondSystem is designed for Roblox's single-threaded Lua execution model. All state mutations happen synchronously. The only async operations are:

- `hooks.persist` calls (wrapped in `task.spawn` where applicable inside `init()`)
- `hooks.load` calls (wrapped in `task.spawn` inside `init()`)

External hook implementations should handle their own error recovery via `pcall`.

---

## Testing Approach

To test BondSystem without a live Roblox environment:

1. Mock `game:GetService("Players")` with a table that has `PlayerAdded` and `PlayerRemoving` signal mocks.
2. Call functions directly with string player IDs.
3. Assert on `getTier()`, `getPoints()`, and hook callbacks.

Example test structure:

```lua
local BondSystem = require("BondSystem")

-- Track tier changes
local changes = {}
BondSystem.hooks.onTierChanged = function(pid, old, new)
    table.insert(changes, { pid = pid, old = old, new = new })
end

-- Simulate events
for i = 1, 10 do
    BondSystem.recordBuild("TestPlayer")
end

assert(BondSystem.getTier("TestPlayer") >= 1, "Should be at least Acquaintance")
assert(#changes > 0, "Should have fired tier change")
```
