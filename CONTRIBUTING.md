# Contributing to BondSystem

Thanks for your interest in improving BondSystem!

## Getting Started

1. **Fork & clone** the repo
2. Install [Rojo](https://rojo.space) for Studio sync
3. Run `rojo serve` to test in Studio

## Development Workflow

```bash
rojo serve
```

### Running Tests

Tests live in `spec/` and use [TestEZ](https://github.com/Roblox/testez) format.

### Code Style

- **Luau type annotations** on all public functions
- **Doc comments** on all exported APIs
- **camelCase** for functions
- **`--!strict`** mode at the top of the module
- All tier behavior tables must list every behavior key (no sparse tables)

## Design Principles

### No Visible Progress Bar

BondSystem deliberately hides the point values from the player. Progression is felt through behavior changes, not numbers. Never add a UI that shows "47/70 to Companion."

### Negative Events Are Floored

Negative bond events (e.g. `deleted_without_inspection`) can never drop a player below their current tier's threshold floor. Trust, once earned, isn't erased by a bad day. The `applyBondEvent` function enforces this.

### Tier Transitions Are One-Way

Tiers can only increase. There is no tier demotion. This is a deliberate design choice — once a relationship milestone is crossed, the NPC's behavior permanently shifts.

## Adding Bond Event Types

1. Add the event name and point value to `BOND_EVENTS`
2. Create a `recordXxx` method in the Public API section
3. Test that negative events floor at the tier threshold
4. Test that positive events trigger tier transitions correctly
5. Document the event in the README

## Submitting Changes

1. Feature branch: `git checkout -b feat/your-feature`
2. Test tier transitions, negative floored events, and custom event types
3. Open a PR

## Reporting Bugs

Include:
- Player's current tier and bond points
- The event type triggered
- Expected vs. actual tier after the event
- Whether `addPoints` or a specific `recordXxx` was used

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
