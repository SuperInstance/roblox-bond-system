# src/ — BondSystem Source

The entire module is a single file: [`BondSystem.lua`](./BondSystem.lua).

~700 lines of Luau. Zero external dependencies.

> *It feels like a marlinspike — sharp enough to pry open stubborn knots in someone else's rope, yet heavy and reassuring in the hand, its weight a constant promise that every splice you make together holds tighter than the last.*
>
> — DeepSeek V4-Flash

## Architecture

```
BondSystem.lua
├── Configuration (thresholds, names, descriptions, events, behaviors)
├── State Management (playerData, openHooks)
├── Tier Transition Handling
├── Public API
│   ├── Lifecycle (init, onPlayerJoin)
│   ├── Behavior Triggers (recordBuild, recordHookCompleted, ...)
│   ├── Hook Management (registerOpenHook, checkHookProximity, ...)
│   ├── Queries (getTier, getBehaviors, getProgress, ...)
│   ├── Behavioral Queries (shouldUseWe, argumentsUnlocked, ...)
│   └── Customization (setTierNames, registerEventType, ...)
└── return BondSystem
```

## Key Invariants

1. **Monotonic tiers** — tier only increases; negative events floor at the current tier threshold
2. **Behavior flags are cumulative** — each tier enables everything from prior tiers plus new behaviors
3. **Hooks are the integration boundary** — all external systems wire up through the `hooks` table, never through direct coupling
4. **Threshold monotonicity** — `TIER_THRESHOLDS` must be strictly increasing; `init()` asserts this

## The Tier Math

The thresholds partition the non-negative reals into five intervals:

```
[0, 10)    → Tier 0 (Stranger)
[10, 30)   → Tier 1 (Acquaintance)
[30, 70)   → Tier 2 (Companion)
[70, 150)  → Tier 3 (Trusted)
[150, ∞)   → Tier 4 (Ally)
```

`calculateTier()` does a reverse scan from MAX_TIER down. O(5) = O(1). The behavior flags are a lookup table indexed by tier. Every query is a table access.

---

## Fleet Connections

- [roblox-beatclock](https://github.com/SuperInstance/roblox-beatclock/src) — Bonds have rhythm; BeatClock provides the grid they pulse on
- [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) — Bond dialogue passes through the filter gate
- [mud-engine](https://github.com/SuperInstance/mud-engine) — NPCs with bonds in the room engine; the hermit crab finds its shell through hooks
- [vibe-protocol](https://github.com/SuperInstance/vibe-protocol) — Bond changes broadcast as vibes to the fleet
- [vessel-agent-system](https://github.com/SuperInstance/vessel-agent-system) — Crew relationships on the real boat
- [cns-bridge](https://github.com/SuperInstance/cns-bridge) — Bond events can flow through the nervous system
- [platos-shell](https://github.com/SuperInstance/platos-shell) — The shell pattern; BondSystem is how agents find them
- [AI-Writings: Hermit Crab Thread](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — Stories about trust, shells, and hooks

---

← Back to [BondSystem](../README.md)
