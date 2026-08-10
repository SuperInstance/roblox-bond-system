# examples/ — BondSystem Working Scripts

> *Drop them in Studio. Watch relationships grow.*

## Examples

| File | What It Does |
|------|-------------|
| [`npc-friendship.lua`](npc-friendship.lua) | Blacksmith NPC that warms up through repeated positive interactions. Custom tier names and transition lines. |
| [`companion-ai.lua`](companion-ai.lua) | AI companion whose combat behavior, dialogue, and autonomy change with bond level. Follow distance, proactive combat, tactical communication, and banter all scale with tier. |
| [`bond_progression.lua`](bond_progression.lua) | Quest giver who only offers high-stakes quests to trusted players (tier 3+). |
| [`tier_gating.lua`](tier_gating.lua) | Faction reputation system using compound keys for multi-faction tracking. |

## Patterns Demonstrated

- **Custom tier names:** `BondSystem.setTierNames({...})`
- **Custom transition lines:** `BondSystem.setTransitionLines(tier, {...})`
- **Hook wiring:** `onTierChanged`, `onTransitionLine`, `persist`, `load`
- **Tier gating:** `BondSystem.hasTier(playerId, minTier)`
- **Behavioral branching:** `BondSystem.getBehaviors(playerId)` for NPC AI
- **Multi-faction:** Compound keys (`"faction:player"`) for separate relationship tracks

---

[← Back to BondSystem](../README.md)
