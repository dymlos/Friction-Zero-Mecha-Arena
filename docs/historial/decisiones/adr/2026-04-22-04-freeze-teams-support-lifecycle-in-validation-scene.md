# ADR 2026-04-22-04 - Freeze `Teams` support lifecycle in the validation scene

## Status

Accepted

## Context

Reset-of-round and manual-restart cleanup for post-death support were covered in the base `Teams` scene but not in the fast validation scene.

## Decision

- Treat support lifecycle cleanup as a shared `Teams` scene contract over `main.tscn` and `main_teams_validation.tscn`.
- Keep the existing lifecycle fixture unless the seam itself changes:
  - `round_intro_duration_teams = 0.0`
  - reset-path score fixture `1/1/1`
  - `rounds_to_win = 2` for intermediate reset tests
  - `rounds_to_win = 1` for manual restart tests

## Why

- The scene wiring for `SupportRoot`, `support_state`, and the outer lane is shared.
- The missing piece was direct regression coverage on the sibling scene.

## Ongoing consequence

- Any change to support cleanup, support lane gating, or `MatchController` restart/reset flow should be verified on both `Teams` scenes.
