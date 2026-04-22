# ADR 2026-04-22-01 - Base/validation parity for edge pickups

## Status

Accepted

## Context

Edge pickup coverage had been frozen only on the base scenes even though the validation scenes use the same gameplay contract.

## Decision

- Treat edge pickups as shared scene-level contracts across the playable lab pairs:
  - `main.tscn` and `main_teams_validation.tscn`
  - `main_ffa.tscn` and `main_ffa_validation.tscn`
- In scene-level tests, resolve the arena by `ArenaBase` type instead of a fixed child path such as `ArenaRoot/ArenaBlockout`.

## Why

- The validation scenes mount the arena with different child names.
- The first regression was a brittle fixture problem, not a production drift in pickups or HUD behavior.

## Ongoing consequence

- Any future scene-level pickup regression should touch the base/validation pair together.
- If a test turns red here first, inspect arena resolution helpers before changing arena, pickup, or HUD production code.
