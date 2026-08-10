# tests/ — BondSystem Test Suite

Tests run outside of Roblox Studio using the custom [TestKit](../testkit/init.lua) framework, which mocks `game:GetService("Players")`, `typeof()`, `Vector3`, and `task.spawn`.

> *Those 63 playtests clearly fine-tuned this rhythm, smoothing out any awkward jumps between formal NPC small talk and intimate disclosures.*
>
> — Seed Mini

## Files

| File | Focus | Key Tests |
|------|-------|-----------|
| [`bondsystem_test.lua`](./bondsystem_test.lua) | Module structure, init, tier progression, behaviors, tier names, hook system | Init doesn't crash, tier 0 start, build adds points, tier doesn't decrease on negative events, hook registration |
| [`bondsystem_extended_test.lua`](./bondsystem_extended_test.lua) | Tier thresholds per tier, all 14 behavior flags at tiers 0/2/4, behavioral queries, bond event point values, tier progression through events, hooks CRUD, proximity, progress, addPoints, tier names, confession system, custom events, setTier admin, integration hooks, event log, API completeness (41 functions) | Full behavioral matrix verification, confession one-time delivery, negative points floor at threshold, custom event registration |

## Coverage

63 tests total across both files, plus a TestEZ-format spec. Coverage includes:

- ✅ All five tier thresholds (exact point values)
- ✅ All 14 behavior flags at tiers 0, 2, and 4
- ✅ All 11 behavioral query functions
- ✅ All 7 standard bond events (exact point values)
- ✅ Tier progression via accumulated events
- ✅ Hook system: register, query, complete, multi-hook, partial completion
- ✅ Negative events floored at tier threshold
- ✅ Confession system (one-time delivery at tier 4)
- ✅ Custom event types and raw addPoints
- ✅ Admin setTier (clamping, flooring, threshold-setting)
- ✅ Integration hooks (onTierChanged, onBondEvent)
- ✅ Event log (capped at 20 entries)
- ✅ API completeness audit (41 exported functions)

---

## Fleet Testing Connections

- [roblox-beatclock](https://github.com/SuperInstance/roblox-beatclock/tests) — 55 tests, the same TestKit philosophy
- [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) — 90 Lua tests, the fleet's most thoroughly tested Roblox module
- [cns-bridge](https://github.com/SuperInstance/cns-bridge) — 270 Python tests, the gold standard
- [voxel-logic](https://github.com/SuperInstance/voxel-logic) — 99.7% test coverage
- [mud-engine](https://github.com/SuperInstance/mud-engine) — 285 files, thoroughly tested room engine

---

← Back to [BondSystem](../README.md)
