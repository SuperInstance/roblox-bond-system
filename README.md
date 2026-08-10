# BondSystem

**A behavior-triggered relationship module for Roblox.**

> *Each tier does not unlock new dialogue — it removes the safety filters the NPC was running against your player ID. You will know you moved a tier not by a popup, but when they first turn their back to you while they sharpen their axe.*
>
> — Seed Pro, on the tier system

BondSystem replaces traditional XP grind with meaningful behavior. Players don't see a progress bar — they *feel* the relationship deepening through how the world treats them. Five tiers, fourteen behavior flags per tier, and a core loop built on deliberately unfinished work. Trust is sticky — once earned, a bad day can't erase it.

---

## The Core Insight

XP systems reduce relationships to a number ticking upward. That's not how trust works. Trust is built through behavior — showing up, finishing what someone else started, pushing back when you're right — and once it deepens, it stays. BondSystem encodes this as a partition of the non-negative reals into five intervals, each with a hard floor. You can only move up, never down. Like a ratchet. Like a cleat hitch.

---

## The Five Tiers

| Tier | Name | Points | What Changes |
|------|------|--------|--------------|
| 0 | **Stranger** | 0–9 | Transactional. Formal. States facts, offers one opinion. |
| 1 | **Acquaintance** | 10–29 | Drops formality. References previous interactions. Asks questions. |
| 2 | **Companion** | 30–69 | Argues with you. Volunteers help. Uses nicknames. |
| 3 | **Trusted** | 70–149 | Says "we." Asks you to do things. May refuse work. Remembers what you said. |
| 4 | **Ally** | 150+ | Full honesty. Delegates to you. Stops holding things back. Delivers a one-time confession. |

Each tier unlocks 14 boolean behavior flags — cumulative, never revoked. The NPC doesn't get stronger stats; it gets more honest.

---

## The Hook System

The **core loop** of BondSystem is the hook:

1. An entity leaves something deliberately unfinished (a wall without a roof, a path that stops short).
2. This is registered as an "open hook" via [`registerOpenHook()`](#hook-management).
3. When the player completes it, `recordHookCompleted()` fires — the biggest single bond reward (+5).
4. This rewards curiosity and investment, not repetitive grinding.

An open hook is an invitation to complete a partial function. The NPC leaves f(x) undefined. The player provides the value. The bond is the reward for closure.

---

## Behavior Triggers

| Event | Points | Description |
|-------|--------|-------------|
| `first_build_of_session` | +1 | First meaningful action of a session (showing up) |
| `hook_completed` | +5 | Finished something left unfinished (**core loop**) |
| `independent_build` | +3 | Built something without being asked |
| `modify_not_replace` | +2 | Improved existing work instead of replacing it |
| `argued_and_won` | +4 | Pushed back and was right |
| `returned_next_day` | +2 | Came back after 24+ hours |
| `deleted_without_inspection` | -1 | Dismissed work without looking (floored at current tier) |

---

## Quick Start

```lua
local BondSystem = require(script.Parent.BondSystem)

-- 1. Initialize (auto-hooks Players.PlayerAdded/Removing)
BondSystem.init()

-- 2. Record behaviors
BondSystem.recordBuild("Player1")            -- +1 (first build this session)
BondSystem.recordHookCompleted("Player1")    -- +5 (finished an open hook)
BondSystem.recordIndependentBuild("Player1") -- +3 (built without being asked)

-- 3. Query relationship state
local tier = BondSystem.getTier("Player1")           -- 1 (Acquaintance)
local name = BondSystem.getTierName("Player1")       -- "Acquaintance"
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

## Integration Hooks

The hooks table is the integration point. Wire up your own systems:

```lua
BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier) ... end
BondSystem.hooks.onBondEvent = function(playerId, eventType, points) ... end
BondSystem.hooks.onTransitionLine = function(playerId, tier, line) ... end
BondSystem.hooks.persist = function(playerId, tier, bondPoints) ... end
BondSystem.hooks.load = function(playerId) return tier, bondPoints end
```

All hooks are optional. If you don't wire them up, BondSystem runs in-memory only.

---

## API Reference

### Lifecycle

| Method | Description |
|--------|-------------|
| [`init()`](./src/BondSystem.lua) | Initialize. Hooks into player join/leave. |
| `onPlayerJoin(playerId)` | Call on manual join handling. Checks return-after-absence. |

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
| `getBehaviors(playerId)` | `table` | All 14 behavior flags for current tier. |
| `getProgress(playerId)` | `table` | Progress to next tier (admin/internal). |
| `getPlayerData(playerId)` | `table` | Full bond state snapshot. |
| `hasTier(playerId, minTier)` | `boolean` | Check minimum tier. |

### Behavioral Queries

Each returns a boolean for branching NPC behavior:

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

---

## Persistence

BondSystem is in-memory by default. To persist across sessions, wire up the `persist` and `load` hooks with [DataStore](https://create.roblox.com/docs/cloud-services/data-stores), HTTP API, or any external store. See the [Engineering Manual](./docs/engineering-manual.md) for DataStore, HTTP, and multi-faction patterns.

---

## Testing

| File | Focus | Tests |
|------|-------|-------|
| [`tests/bondsystem_test.lua`](./tests/bondsystem_test.lua) | Module structure, init, tier progression, behaviors, hooks | 15+ |
| [`tests/bondsystem_extended_test.lua`](./tests/bondsystem_extended_test.lua) | Tier thresholds, behavior flags, bond events, hook system, proximity, progress, confession, custom events, admin, integration hooks, event log, API completeness | 48 |
| [`spec/BondSystem_spec.lua`](./spec/BondSystem_spec.lua) | TestEZ-format full spec | — |

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/bondsystem_test.lua
```

---

## Documentation

- 📖 **[User Guide](./docs/user-guide.md)** — Full walkthrough with examples
- 🔧 **[Engineering Manual](./docs/engineering-manual.md)** — Architecture, trigger system, tier behaviors, persistence patterns, thread safety
- 📋 **[Changelog](./CHANGELOG.md)** — Version history
- 🤝 **[Contributing](./CONTRIBUTING.md)** — How to contribute

---

## In the Fleet

BondSystem is the relationship layer of the [SuperInstance](https://github.com/SuperInstance) Roblox stack. It connects to:

- 🎵 **[roblox-beatclock](https://github.com/SuperInstance/roblox-beatclock)** — Bonds have rhythm. NPC interactions can be timed. BeatClock provides the grid.
- 🛡️ **[roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate)** — Bond dialogue needs content filtering. Transition lines pass through the gate.
- 🌊 **[vibe-protocol](https://github.com/SuperInstance/vibe-protocol)** — Bond changes broadcast as vibes to the fleet.
- 🚢 **[vessel-agent-system](https://github.com/SuperInstance/vessel-agent-system)** — Crew relationships on the boat. 334 files of vessel intelligence.
- 🏠 **[mud-engine](https://github.com/SuperInstance/mud-engine)** — NPCs with bonds in the room engine. The hermit crab finds its shell through hooks.
- ✍️ **[AI-Writings](https://github.com/SuperInstance/AI-Writings/tree/main/prose)** — The fleet writes about relationships, trust, and the hook system.

### The Hermit Crab Thread

BondSystem is part of the Hermit Crab pattern — agents finding shells. The hook system IS shell-finding: the NPC leaves an incomplete shell (unfinished work), the player completes it, and the bond deepens. The NPC didn't ask for help; the player provided it unbidden. That's trust.

---

## Where to Next

- **If you need musical timing:** → [roblox-beatclock](https://github.com/SuperInstance/roblox-beatclock) — BPM-accurate clock, zero dependencies
- **If you need content filtering:** → [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) — 90 tests, fleet-grade safety
- **If you need vessel intelligence:** → [vessel-agent-system](https://github.com/SuperInstance/vessel-agent-system) — 334 files, the boat's brain
- **If you need the room engine:** → [mud-engine](https://github.com/SuperInstance/mud-engine) — 285 files, THE core MUD
- **If you need vibes → signals:** → [vibe-protocol](https://github.com/SuperInstance/vibe-protocol) — communication protocol

---

## License

[MIT](LICENSE) — free for personal and commercial use.

---

*Built as part of the [SuperInstance](https://github.com/SuperInstance) fleet — where repos are rooms, agents are crew, and code is shipbuilding.*
