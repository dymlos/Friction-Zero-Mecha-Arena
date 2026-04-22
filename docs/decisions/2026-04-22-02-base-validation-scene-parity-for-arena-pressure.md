# ADR 2026-04-22-02 - Base/validation parity for arena pressure

## Status

Accepted

## Context

Arena pressure and safe-area reset had been validated mainly through one scene even though the same contract exists across both `Teams` and `FFA` base/validation labs.

## Decision

- Treat `warning -> contraction -> arena reset` as a shared scene-level contract across all four playable labs.
- Stabilize fixtures with:
  - `match_config.rounds_to_win = 3` when the test needs an intermediate round reset
  - mode-aware forced endings:
    - `Teams`: two eliminations
    - `FFA`: `N-1` eliminations

## Why

- Validation configs use shorter match targets than the base scenes.
- `FFA` does not reset the round until a single robot remains, so old fixtures could fail without any real production issue.

## Ongoing consequence

- If arena pressure tests regress, verify the fixture and match target first.
- Do not infer a reset bug from a scene that still has more than one legal survivor in `FFA`.
