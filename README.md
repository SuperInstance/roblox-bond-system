# BondSystem

> *No visible progress bar. No XP grind. You feel the relationship change because the world starts treating you differently.*
>
> **Behavior-triggered relationship engine for Roblox. Five tiers. Zero dependencies. 63 tests.**

BondSystem replaces traditional reputation grinding with **meaningful behavior**. Players don't see "47/70 to next tier." They notice the NPC starts saying "we" instead of "I," argues with them, volunteers help, and eventually stops holding things back.

---

## The Five Tiers

Trust is a ladder with sticky rungs. Once you've held a tier, a bad day can't take it away.

| Tier | Name | Points | What Changes |
|------|------|--------|--------------|
| 0 | **Stranger** | 0–9 | Transactional. Formal. States facts, offers one opinion. |
| 1 | **Acquaintance** | 10–29 | Drops formality. References previous interactions. Asks questions. |
| 2 | **Companion** | 30–69 | Argues with you. Volunteers help. Uses nicknames. |
| 3 | **Trusted** | 70–149 | Says "we." Asks you to do things. May refuse work. Remembers what you said. |
| 4 | **Ally** | 150+ | Full honesty. Delegates to you. Stops holding things back. One-time confession. |

Each tier is a hard floor, not a soft slope. Negative events cannot drag a bond past the tier it has already held fast through — just as a properly tied mooring will not slip below the cleat it was fastened to.

---

## Why Not XP?

XP systems reduce relationships to a number ticking upward. BondSystem takes a different approach:

- **No visible progress bar.** The player feels trust through NPC behavior changes, not UI notifications.
- **Behavior drives progression.** Completing unfinished work, building independently, arguing and winning — these are what deepen bonds.
- **Each tier changes behavior, not stats.** Going from tier 2 to tier 3 doesn't give +5 strength. It means the NPC starts saying "we" and asks the player for help.
- **Negative events are floored.** Once trust is earned, a bad day doesn't erase it. Trust is sticky.

---

## The Core Loop: Hooks

The heart of BondSystem is the **hook system** — a gameplay loop that rewards curiosity and investment:

```
Entity leaves work unfinished
    → registerOpenHook(playerId, hookId, description, position)
    → Player explores and finds the unfinished work
    → Player completes it
    → checkHookProximity(playerId, buildPosition) detects it
    → recordHookCompleted(playerId, hookId)
    → +5 bond points (the largest single reward)
```

This is not grinding. The NPC leaves a torn net on the deck, a jammed winch, a half-baited line. You don't get paid for noticing it — you get paid in the shared rhythm of fixing it. The NPC doesn't thank you with a progress bar. They just start handing you the good knife instead of the dull one.

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

Add custom events with `registerEventType(name, points)` or `addPoints(playerId, amount)`.

---

## Quick Start

```lua
local BondSystem = require(script.Parent.BondSystem)

BondSystem.init()

-- Record behaviors
BondSystem.recordBuild("Player1")             -- +1 (first build this session)
BondSystem.recordHookCompleted("Player1")      -- +5 (finished an open hook)
BondSystem.recordIndependentBuild("Player1")   -- +3 (built without being asked)

-- Query relationship state
local tier = BondSystem.getTier("Player1")            -- 1 (Acquaintance)
local name = BondSystem.getTierName("Player1")        -- "Acquaintance"
local behaviors = BondSystem.getBehaviors("Player1")

-- Branch behavior based on tier
if behaviors.argues then
    -- NPC will disagree with the player now
end
if behaviors.uses_we then
    -- NPC says "we" instead of "I"
end
```

---

## Hook System: Integration Point

Wire up your own systems through the `hooks` table:

```lua
BondSystem.hooks.onTierChanged = function(playerId, oldTier, newTier)
    -- Fire a cutscene, change NPC dialogue, unlock a quest
end

BondSystem.hooks.onBondEvent = function(playerId, eventType, points)
    -- Analytics, achievements, sound effects
end

BondSystem.hooks.onTransitionLine = function(playerId, tier, line)
    -- Display the transition line via your dialogue system
end

BondSystem.hooks.persist = function(playerId, tier, bondPoints)
    -- Save to DataStore, your API, wherever
end

BondSystem.hooks.load = function(playerId)
    -- Return stored tier and points
    return 2, 45
end
```

All hooks are optional. Without them, BondSystem runs in-memory only.

---

## Tier Behaviors

Each tier has 14 boolean behavior flags — cumulative as trust deepens:

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

Query them with `getBehaviors(playerId)` or convenience methods like `shouldUseWe(playerId)`, `argumentsUnlocked(playerId)`, `shouldDelegate(playerId)`.

---

## Installation

### With Rojo

1. Copy [`src/BondSystem.lua`](src/BondSystem.lua) into your project.
2. Add to your `default.project.json`:

```json
{
  "ServerScriptService": {
    "BondSystem": {
      "$path": "../roblox-bond-system/src/BondSystem.lua"
    }
  }
}
```

### Manual

1. Create a `ModuleScript` in `ServerScriptService`.
2. Paste the contents of [`src/BondSystem.lua`](src/BondSystem.lua).
3. `require()` it from your server scripts.

---

## API Reference

### Lifecycle

| Method | Description |
|--------|-------------|
| [`init()`](src/BondSystem.lua) | Initialize. Hooks into `Players.PlayerAdded/Removing`. |
| [`onPlayerJoin(playerId)`](src/BondSystem.lua) | Manual join handling. Checks return-after-absence. |

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
| `addPoints(playerId, amount)` | custom | Raw points. |
| `fireEvent(playerId, eventType)` | varies | Fire any registered event type. |

### Hook Management

| Method | Description |
|--------|-------------|
| `registerOpenHook(playerId, hookId, description, position?)` | Register unfinished work. |
| `hasOpenHooks(playerId)` | Boolean. |
| `getOpenHooks(playerId)` | Table of all open hooks. |
| `checkHookProximity(playerId, position)` | Returns hookId if within 30 studs. |

### Tier & Behavior Queries

| Method | Returns |
|--------|---------|
| `getTier(playerId)` | `number` (0–4) |
| `getPoints(playerId)` | `number` |
| `getTierName(playerId)` | `string` |
| `getBehaviors(playerId)` | behavior flags table |
| `getProgress(playerId)` | progress to next tier (admin) |
| `getPlayerData(playerId)` | full state snapshot |
| `hasTier(playerId, minTier)` | `boolean` |

### Customization

| Method | Description |
|--------|-------------|
| `setTierNames(names)` | Override tier names. Call before `init()`. |
| `setTierDescriptions(descriptions)` | Override tier descriptions. |
| `setTransitionLines(tier, lines)` | Custom dialogue for transitions. |
| `setThresholds(thresholds)` | Custom point thresholds. Call before `init()`. |
| `registerEventType(name, points)` | Add a custom event type. |

---

## Testing

| Test File | Lines | What It Covers |
|-----------|-------|----------------|
| [`tests/bondsystem_test.lua`](tests/bondsystem_test.lua) | 164 | Module structure, init, tier computation, point awards, tier transitions, negative events flooring |
| [`tests/bondsystem_extended_test.lua`](tests/bondsystem_extended_test.lua) | 623 | All behavior triggers, hook management, proximity detection, behavioral queries, customization, persistence hooks, multi-faction, edge cases |
| [`spec/BondSystem_spec.lua`](spec/BondSystem_spec.lua) | 759 | TestEZ-format spec — comprehensive coverage including session management, confession delivery, event log, long-session scenarios |

**63 tests total.** Run with:

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/bondsystem_test.lua
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/bondsystem_extended_test.lua
```

---

## Examples

| Example | What It Does |
|---------|-------------|
| [`npc-friendship.lua`](examples/npc-friendship.lua) | NPC that warms up through repeated positive interactions. |
| [`companion-ai.lua`](examples/companion-ai.lua) | AI companion whose combat behavior, dialogue, and autonomy change with bond level. |
| [`bond_progression.lua`](examples/bond_progression.lua) | Quest giver who only offers high-stakes quests to trusted players. |
| [`tier_gating.lua`](examples/tier_gating.lua) | Faction reputation with separate tiers per faction. |

---

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/user-guide.md) | Beginner-friendly walkthrough |
| [Engineering Manual](docs/engineering-manual.md) | Architecture, trigger system, persistence patterns, testing strategy |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [TestKit](testkit/init.lua) | Minimal Lua test framework for running Roblox tests outside Studio |

---

## In the Fleet

BondSystem is the relationship layer for the [SuperInstance](https://github.com/SuperInstance) fleet. It connects to:

- [**roblox-beatclock**](https://github.com/SuperInstance/roblox-beatclock) — Bonds have rhythm. NPC interactions can be timed to musical beats. The clock provides the grid; bonds provide the meaning.
- [**roblox-filtergate**](https://github.com/SuperInstance/roblox-filtergate) — Bonds need safety. Transition lines and NPC dialogue pass through content filtering before reaching the player.
- [**vibe-protocol**](https://github.com/SuperInstance/vibe-protocol) — Vibes become signals. Bond tier changes can emit vibe-protocol packets for fleet-wide awareness.
- [**vessel-agent-system**](https://github.com/SuperInstance/vessel-agent-system) — The vessel's crew has relationships. BondSystem models trust between the captain and the AI agents that run the ship.
- [**mud-engine**](https://github.com/SuperInstance/mud-engine) — NPCs in the MUD engine use BondSystem for relationship progression. The hermit crab finds its shell through hooks.
- [**cns-bridge**](https://github.com/SuperInstance/cns-bridge) — Bond tier changes propagate through the central nervous system bus as events.
- [**AI-Writings**](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — Narrative explorations of trust, relationship, and the moment someone stops counting.

### The Hermit Crab

In the fleet's operating fiction, the hermit crab finds shells. BondSystem is the shell-finding mechanic: the hook system leaves work unfinished, the player completes it, and the relationship deepens. The crab doesn't measure trust in points — it measures trust in the size of the shell it's willing to inhabit.

---

## License

[MIT](LICENSE) — free for personal and commercial use.

---

## Where to Next

- [**roblox-beatclock**](https://github.com/SuperInstance/roblox-beatclock) — The clock that times bond interactions
- [**roblox-filtergate**](https://github.com/SuperInstance/roblox-filtergate) — Keep bond dialogue safe
- [**vessel-agent-system**](https://github.com/SuperInstance/vessel-agent-system) — Where bonds meet the open ocean
- [**vibe-protocol**](https://github.com/SuperInstance/vibe-protocol) — Broadcasting bond states as vibes
- [**mud-engine**](https://github.com/SuperInstance/mud-engine) — NPCs with bonds in the room engine
