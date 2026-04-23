# ADR 2026-04-22-05 - Freeze `Teams` modular-loss and denial stats in the validation scene

## Status

Accepted

## Context

`Teams` recap and final-result stats for modular loss and part denial lived on shared surfaces but were only frozen on the base scene.

## Decision

- Treat the following lines as shared `Teams` scene-level contracts over `main.tscn` and `main_teams_validation.tscn`:
  - `Stats | ... partes perdidas ...`
  - `Stats | ... negaciones ...`

## Why

- The stats builders and result surfaces are shared between the two scenes.
- The gap was coverage drift, not a difference in intended behavior.

## Ongoing consequence

- Any change to recap/result stats builders should preserve parity between the base and validation `Teams` labs.
