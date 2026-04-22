# ADR 2026-04-22-03 - Stabilize `Teams` post-death support fixtures

## Status

Accepted

## Context

The fast `Teams` validation scene can legitimately spawn rival support during the same round, which makes naive cleanup assertions flaky.

## Decision

- Freeze post-death support on both `main.tscn` and `main_teams_validation.tscn`.
- Use stabilized fixtures when the goal is support behavior rather than round pacing:
  - `round_intro_duration_teams = 0.0`
  - `progressive_space_reduction = false`
  - `round_time_seconds >= 120.0`
- Cleanup must be owner-aware:
  - the eliminated player's support ship must disappear
  - `SupportRoot` does not need to be globally empty if a rival support ship is legitimately active

## Why

- The scene parity issue was in coverage, not in production support logic.
- Global-empty cleanup assertions confuse "another valid support ship exists" with "stale ship leaked".

## Ongoing consequence

- Keep support targeting, warnings, and no-op gating validated on both `Teams` scenes.
- When cleanup fails, inspect ownership before assuming stale support state.
