# src/ — BondSystem Source

> *The relationship engine. One file, ~700 lines, zero dependencies.*

## Files

| File | Description |
|------|-------------|
| [`BondSystem.lua`](BondSystem.lua) | Complete module — tiers, behaviors, hooks, triggers, customization |

## Module Structure

```
BondSystem.lua
├── Configuration (thresholds, names, descriptions, events, behaviors)
├── State Management (playerData, openHooks)
├── Tier Transition Handling
├── Public API
│   ├── Lifecycle (init, onPlayerJoin)
│   ├── Behavior Triggers (recordBuild, recordHookCompleted, etc.)
│   ├── Hook Management (registerOpenHook, checkHookProximity)
│   ├── Queries (getTier, getBehaviors, getProgress)
│   ├── Behavioral Queries (shouldUseWe, argumentsUnlocked, etc.)
│   └── Customization (setTierNames, registerEventType, etc.)
└── return BondSystem
```

## Design Principles

1. **Behavior, not numbers.** The player never sees a progress bar.
2. **Hooks over coupling.** Wire up your own persistence, dialogue, and notifications.
3. **Floor, not ceiling.** Negative events cannot drop below current tier floor.
4. **Discrete events.** Bond points come from specific, meaningful behaviors.

See the [Engineering Manual](../docs/engineering-manual.md) for full architecture.

---

[← Back to BondSystem](../README.md)
