# ADR 2026-04-22-06 - Opening lock/unlock is the contract; first collision is telemetry

## Status

Accepted

## Context

The opening slice now has both scene-level checks and a runtime probe, but the first meaningful collision happens at different times across the four playable labs.

## Decision

- Treat the technical opening contract as:
  - intro lock prevents early drift
  - edge pickups remain visible but blocked during intro
  - HUD communicates border availability during the countdown
  - unlock restores movement and pickup collection cleanly
- Keep the first significant post-intro collision as runtime telemetry, not as a pass/fail gate.

## Why

- The scenes showed real pacing differences even while the opening contract itself stayed stable.
- A global timing assert would make the suite flaky and would mix tuning questions with correctness checks.

## Ongoing consequence

- Use runtime/manual evidence to retune spawn/layout/opening pace.
- Do not turn the first-collision timing into a shared binary assertion unless pacing is intentionally standardized across scenes.
