# ESTADO_ACTUAL.md - Friction Zero: Mecha Arena

This file is the short current snapshot. Long dated history now lives in `docs/status/`.

## Archivo relacionado

- Estado detallado archivado: `docs/status/2026-04-22-status-log.md`
- Indice documental: `docs/README.md`

## Estado jugable actual

- El prototipo ya es jugable en laboratorios `Teams` y `FFA` con pantalla compartida.
- Ya existe el nucleo del combate:
  - movimiento con inercia
  - choques con peso
  - borde letal
  - dano modular por extremidad
  - energia con redistribucion y `Overdrive`
- Ya existe el loop de desgaste secundario:
  - partes desprendidas
  - rescate aliado
  - negacion rival
  - explosion diferida del cuerpo inutilizado
- Ya existe una primera capa de variedad y legibilidad:
  - arquetipos base
  - pickups de borde
  - presion progresiva del arena
  - HUD `explicito/contextual`
  - recap de ronda y cierre final
- `Teams` ya tiene un primer slice jugable de soporte post-muerte.

## Ultimo checkpoint integrado

- Fecha de referencia del checkpoint documental: `2026-04-22`
- El foco reciente no fue agregar otro sistema grande, sino cerrar drift entre escenas `base` y `validation`.
- La suite reciente congela mejor:
  - pickups de borde
  - presion del arena
  - intro/countdown y lock del borde
  - resolucion de ronda `Teams` y `FFA`
  - roster vivo, marcador y cierres
  - soporte post-muerte `Teams`

## Seams validados mas importantes

- Las escenas hermanas `base/validation` deben tratarse como la misma superficie contractual cuando comparten gameplay.
- Los laboratorios `FFA` y `Teams` ya tienen cobertura scene-level para opening, recap, cierre y resolucion de ronda.
- El soporte post-muerte `Teams` ya tiene cobertura de:
  - spawn
  - targeting
  - lifecycle/cleanup
  - stats/cierre
  - lectura accionable en HUD/roster
- El opening ya tiene dos capas de confianza:
  - regresion tecnica para `lock -> unlock`
  - sonda runtime para medir deriva, borde y primer choque

## Riesgos activos

- El pacing del opening no es identico entre escenas; hoy es una pregunta de tuning, no de correctness.
- La paridad `base/validation` sigue siendo el riesgo tecnico principal cuando se tocan escenas, fixtures o HUD/cierres scene-level.
- El perfil de score por causa `2/1/4` sigue bloqueado a evidencia nueva; no conviene retocarlo por intuicion.
- El soporte post-muerte `Teams` ya es funcional, pero aun necesita validacion manual de legibilidad e impacto real en match.

## Estado actual de la suite

- Verificacion fresca: `godot --headless --path . -s res://scripts/tests/test_runner.gd`
- Resultado verificado al actualizar este archivo: `Suite OK: 86 tests`.
- Ese numero pasa a ser la referencia actual del checkpoint hasta una nueva corrida completa.

## Regla de mantenimiento

- Si un hallazgo es historico o fechado, moverlo a `docs/status/`.
- Si un dato sigue cambiando el trabajo diario, mantener un resumen aqui y enlazar el detalle mas profundo.
