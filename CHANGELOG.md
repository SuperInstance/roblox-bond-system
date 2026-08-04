# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-04

### Added
- **5-tier progression system:** Stranger (0), Acquaintance (10), Companion (30), Trusted (70), Ally (150)
- **7 built-in bond events:** first_build_of_session, hook_completed, independent_build, modify_not_replace, argued_and_won, returned_next_day, deleted_without_inspection
- **14 behavior flags per tier:** uses_formal_address, references_previous_builds, asks_questions, argues, volunteers_work, uses_we, asks_player_to_build, refuses_work, remembers_conversation, confesses_pattern, delegates_to_player, leaves_things_unfinished, uses_nicknames, shares_opinions
- **Tier transition voice lines** — 3 randomized lines per tier, fired once on transition
- **Open hook system:** registerOpenHook, hasOpenHooks, getOpenHooks, checkHookProximity
- **Integration hooks:** onTierChanged, onBondEvent, onTransitionLine, persist, load
- **Custom event types:** registerEventType, fireEvent, addPoints
- **Customizable:** setTierNames, setTierDescriptions, setTransitionLines, setThresholds
- **Negative events floored** at current tier threshold (no demotion)
- **Session management:** PlayerAdded/PlayerRemoving lifecycle, return-after-absence detection
- **Admin tools:** setTier for debugging
- Engineering manual and user guide
- Two example scripts: companion AI, NPC friendship
- MIT license
