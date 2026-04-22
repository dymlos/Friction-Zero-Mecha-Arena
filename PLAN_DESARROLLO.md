# PLAN_DESARROLLO.md - Friction Zero: Mecha Arena

This file is the concise roadmap. The previous long roadmap lives in `docs/roadmap-history/`.

## Archivo relacionado

- Roadmap completo archivado: `docs/roadmap-history/2026-04-22-full-roadmap.md`
- Proximos pasos historicos: `docs/roadmap-history/2026-04-22-next-steps-detail.md`
- Indice documental: `docs/README.md`

## Checkpoint actual

- El proyecto ya tiene un vertical slice jugable que cubre el nucleo del fantasy:
  - patinar con peso
  - chocar con precision
  - sacar rivales por borde
  - desgastar y desarmar por partes
- Ya existen los laboratorios principales de `Teams` y `FFA`.
- Ya existe una primera capa funcional de:
  - energia y `Overdrive`
  - pickups de borde
  - presion progresiva del arena
  - HUD dual
  - post-muerte `Teams`
  - recap/cierre de match

## Objetivo del roadmap corto

- Proteger el slice jugable actual.
- Reducir drift entre escenas hermanas.
- Tomar las siguientes decisiones de tuning con evidencia y no con intuicion documental.

## Milestones vigentes

### 1. Mantener la base jugable estable

- Seguir tratando `base/validation` como pares contractuales.
- Priorizar arreglos de coverage/fixture antes de tocar produccion cuando el problema es scene-level.
- Mantener el repo facil de cargar para una sesion nueva:
  - docs activas cortas
  - historia en `docs/`

### 2. Validar el opening con playtest corto

- Comprobar si `OpeningTelegraph + lock del borde + unlock` produce una apertura clara.
- Medir si `Teams rapido` y `FFA base` necesitan tuning de spawn/layout/pacing.
- No reabrir el lock del borde mientras el seam tecnico siga sano.

### 3. Validar el valor real del soporte post-muerte `Teams`

- Revisar si ya aporta coordinacion y comeback sin ensuciar la lectura del combate principal.
- Medir si payloads, warnings y cues actuales alcanzan sin sumar otra capa de UI.

### 4. Reabrir balance solo con evidencia

- Score por causa `2/1/4`
- peso real de las rutas de cierre
- utilidad relativa de pickups del borde
- diferencia tactica entre laboratorios `base` y `validation`

### 5. Agregar contenido solo despues de mantener legibilidad

- Nuevas capas de contenido deben preservar:
  - claridad visual
  - lectura de dano/estado
  - centralidad del choque y posicionamiento
- Si un agregado amenaza legibilidad, bajar complejidad antes de expandir contenido.

## Dependencias que siguen importando

1. Movimiento e impacto siguen siendo la base de todo tuning posterior.
2. Dano modular y energia sostienen rescate, negacion y arquetipos.
3. Pickups, mapas y presion del arena solo funcionan bien si el nucleo de duelo sigue legible.
4. Post-muerte, recap y cierre solo tienen valor si explican bien lo que ya paso en combate.

## Regla de mantenimiento

- Mantener este archivo como roadmap vivo y corto.
- Mover checklist historico, detalles fechados y narrativas largas a `docs/roadmap-history/`.
