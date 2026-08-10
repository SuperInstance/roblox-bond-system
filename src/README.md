# src/ — BondSystem Source

The entire module is a single file: [`BondSystem.lua`](./BondSystem.lua).

~700 lines of Luau. Zero external dependencies.

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

← Back to [BondSystem](../README.md)
