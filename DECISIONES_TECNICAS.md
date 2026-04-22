# DECISIONES_TECNICAS.md - Friction Zero: Mecha Arena

This file is the active decisions index. Full dated logs now live in `docs/decisions/`.

## Archivo relacionado

- Archivo historico completo: `docs/decisions/archive/2026-04-22-decision-log.md`
- Indice documental: `docs/README.md`

## ADRs activas

1. `ADR 2026-04-22-01`
   `docs/decisions/2026-04-22-01-base-validation-scene-parity-for-edge-pickups.md`
   Regla: pickups de borde y helper de arena deben respetar paridad `base/validation`.
2. `ADR 2026-04-22-02`
   `docs/decisions/2026-04-22-02-base-validation-scene-parity-for-arena-pressure.md`
   Regla: presion de arena y reset de ronda se validan con fixture dependiente del modo.
3. `ADR 2026-04-22-03`
   `docs/decisions/2026-04-22-03-stabilize-teams-post-death-support-fixtures.md`
   Regla: el soporte post-muerte `Teams` necesita fixtures estabilizadas y cleanup por owner.
4. `ADR 2026-04-22-04`
   `docs/decisions/2026-04-22-04-freeze-teams-support-lifecycle-in-validation-scene.md`
   Regla: reset/restart del soporte se congela en ambas escenas `Teams`.
5. `ADR 2026-04-22-05`
   `docs/decisions/2026-04-22-05-freeze-teams-stats-in-validation-scene.md`
   Regla: stats `Teams` de desgaste modular y negacion viven en ambas escenas `Teams`.
6. `ADR 2026-04-22-06`
   `docs/decisions/2026-04-22-06-opening-lock-unlock-is-the-contract-first-collision-is-telemetry.md`
   Regla: el opening se valida por `lock/unlock`; el primer choque sigue siendo metrica.

## Decisiones vigentes que siguen bloqueando cambios

### 1. Tratar escenas hermanas como contratos compartidos

- Si `main` y su escena `validation` comparten el mismo slice jugable, no asumir que una sola escena representa al modo.
- Esto aplica especialmente a:
  - opening
  - pickups de borde
  - presion de arena
  - resolucion de ronda
  - recap y cierre
  - soporte post-muerte `Teams`

### 2. Endurecer fixtures antes de tocar produccion

- Si un rojo aparece en una escena `validation`, comprobar primero:
  - target de match del recurso de esa escena
  - condicion real de cierre del modo
  - helper de arena correcto
  - pacing extra del laboratorio rapido
- No tratar un gap de fixture como drift de gameplay sin evidencia.

### 3. Mantener owner-aware cleanup en soporte post-muerte

- La pregunta correcta no es "quedo `SupportRoot` vacio?".
- La pregunta correcta es "desaparecio la nave del jugador eliminado y quedo limpio su estado?".

### 4. No convertir tuning de opening en assert global

- El seam tecnico ya congelado es:
  - input bloqueado
  - pickups del borde visibles pero cerrados
  - HUD de apertura
  - unlock limpio
- El tiempo al primer choque se usa para medir escenas, no para aprobar o rechazar builds.

### 5. No reabrir el score por causa `2/1/4` sin evidencia nueva

- Perfil vigente:
  - `ring-out = 2`
  - `destruccion total = 1`
  - `explosion inestable = 4`
- El siguiente cambio de balance debe venir de playtest o medicion nueva, no de intuicion documental.

### 6. Mantener las root docs como entrypoints y no como diarios append-only

- `ESTADO_ACTUAL.md`, `DECISIONES_TECNICAS.md`, `PLAN_DESARROLLO.md` y `PROXIMOS_PASOS.md` deben resumir solo lo activo.
- La historia fechada se preserva en `docs/`.

## Cuando ampliar este archivo

- Agregar una nueva ADR si una decision tecnica sigue condicionando trabajo futuro.
- Si una decision es solo cronologia o debugging historico, archivarla en `docs/decisions/` o en el log historico, no en este indice.
