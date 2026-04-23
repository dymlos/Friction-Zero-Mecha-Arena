# docs/README.md - Friction Zero: Mecha Arena

This folder keeps the long-form project history that no longer needs to live in the root docs.

## What to read first

1. `AGENTS.md`
2. `Documentación/01_concepto-general.md` through `Documentación/10_pendientes-riesgos-y-criterios-para-codex.md`
3. `ESTADO_ACTUAL.md`
4. `PROXIMOS_PASOS.md`
5. `DECISIONES_TECNICAS.md` only when touching scene contracts, fixtures, HUD/cierre parity, or score rules

## Canonical design reference

- `Documentación/01-10` remains the gameplay/design source of truth.
- Those files stay topic-based on purpose and should only be split later if a single file grows enough to become hard to load on its own.

## Active root docs

- `ESTADO_ACTUAL.md`: short snapshot of the playable prototype, recent validated seams, active risks, and latest suite status.
- `DECISIONES_TECNICAS.md`: active decisions index with links to ADR-style decision files.
- `PLAN_DESARROLLO.md`: concise roadmap and current milestone view.
- `PROXIMOS_PASOS.md`: immediate next checks only.

## Archived detail

- `docs/status/`
  - Dated or checkpoint-based state logs that used to live in `ESTADO_ACTUAL.md`.
- `docs/decisions/`
  - Small ADR-style files for decisions that still constrain ongoing work.
- `docs/decisions/archive/`
  - Full historical decision logs kept for traceability.
- `docs/roadmap-history/`
  - Previous long-form roadmap and next-step documents.
- `qa/scenarios/`
  - Committed `godot-qa` smoke scenarios that complement the native `scripts/tests/test_runner.gd` suite.
  - `main_smoke.json`: minimal runtime smoke for the main scene.
  - `match_hud_overlay_layout_1280.json`: HUD readability contract for overlay containment/overlap with the current `godot-qa` assertion surface.

## Current archive entrypoints

- `docs/status/2026-04-22-status-log.md`
- `docs/decisions/archive/2026-04-22-decision-log.md`
- `docs/roadmap-history/2026-04-22-full-roadmap.md`
- `docs/roadmap-history/2026-04-22-next-steps-detail.md`
- `docs/roadmap-history/2026-04-23-production-milestones.md`

## Maintenance rule

- Keep root docs small enough to load independently.
- Move dated narrative detail into `docs/`.
- Keep active rules duplicated in the root summaries when they still constrain day-to-day work; archives should preserve detail, not hide requirements.

## Validation split

- Native GDScript scene tests remain the right place for world/camera contracts that current `godot-qa` still cannot express, such as keeping a post-death support ship inside the shared camera frame.
- `godot-qa` scenarios remain the right place for Control/HUD contracts that can already be expressed through `assert.inside_viewport` and `assert.no_overlap`.
