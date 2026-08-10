# tests/ — BondSystem Test Suite

> *Sea trials. 63 tests. Every tier boundary stress-tested.*

## Test Files

| File | Lines | Framework | Coverage |
|------|-------|-----------|----------|
| [`bondsystem_test.lua`](bondsystem_test.lua) | 164 | [TestKit](../testkit/init.lua) | Module structure, init, tier computation, point awards, tier transitions, negative event flooring |
| [`bondsystem_extended_test.lua`](bondsystem_extended_test.lua) | 623 | [TestKit](../testkit/init.lua) | All behavior triggers, hook management, proximity detection, behavioral queries, customization API, persistence hooks, multi-faction, edge cases, API completeness |

## Running Tests

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/bondsystem_test.lua
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/bondsystem_extended_test.lua
```

See also: [`spec/BondSystem_spec.lua`](../spec/BondSystem_spec.lua) — 759-line TestEZ-format spec.

---

[← Back to BondSystem](../README.md)
