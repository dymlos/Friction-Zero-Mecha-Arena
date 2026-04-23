# PLAN_DESARROLLO.md - Friction Zero: Mecha Arena

This file is the concise active roadmap. The detailed production proposal lives in `docs/roadmap-history/`.

## Archivo relacionado

- Roadmap completo anterior: `docs/roadmap-history/2026-04-22-full-roadmap.md`
- Nueva propuesta detallada: `docs/roadmap-history/2026-04-23-production-milestones.md`
- Proximos pasos activos: `PROXIMOS_PASOS.md`
- Indice documental: `docs/README.md`

## Checkpoint actual

- El proyecto sigue teniendo una base jugable fuerte:
  - movimiento con inercia
  - choque con peso
  - dano modular
  - energia y `Overdrive`
  - recuperacion/negacion de partes
  - `Teams` y `FFA`
  - HUD dual
  - recap/cierre de match
- El riesgo principal ya no es solo "agregar otra mecanica".
- El nuevo foco es pasar de vertical slice validado a juego local mas completo y consistente.

## Objetivo del roadmap corto

- Ordenar el trabajo como roadmap de produccion.
- Resolver primero las decisiones que bloquean muchas capas futuras.
- Mantener la disciplina actual de legibilidad, scene parity y evidencia antes de tuning.

## Milestones vigentes

### 1. Produccion base y escalabilidad

- Definir targets reales para:
  - `720p` y `1080p`
  - hasta `8` jugadores locales
  - `4v4`
  - multiples joysticks
  - shared-screen legible
- Cerrar contratos de:
  - ownership de input
  - pausa
  - prompts de control
  - presupuesto de performance

### 2. Escala de match, mapas y pacing espacial

- Revisar tamano de mapas como problema integral:
  - escala jugable
  - tiempo a engagement
  - flanqueo
  - esquiva
  - escondites
  - rutas
  - valor del borde
  - presion final
- No tratar "mapas mas grandes" como cambio aislado de geometria.

### 3. UX de match, shell y arquitectura de informacion

- Definir flujo completo:
  - menu principal
  - setup de partida
  - HUD
  - pausa
  - salida segura
  - superficies informativas
- Integrar aqui:
  - `How to Play`
  - pausa
  - configuraciones
  - reglas de visibilidad del HUD

### 4. Identidad de roster y comunicacion de personajes

- Hacer que cada personaje se vea distinto sin romper la familia visual comun.
- Alinear identidad visual, identidad jugable y forma de explicarlo al jugador.

### 5. Practica, onboarding y accesibilidad

- Definir el primer alcance de `Modo Practica`.
- Separar:
  - informacion base del juego
  - informacion por personaje
  - refuerzos contextuales dentro del juego
- Establecer expectativas minimas de accesibilidad.

### 6. Pase audiovisual de produccion

- Integrar graficos, sonido y musica como capas coordinadas con gameplay y UX.
- Mantener legibilidad por encima del espectaculo.

### 7. Integracion, optimizacion y cierre

- Revalidar performance y consistencia con todas las capas nuevas integradas.
- Dejar explicitamente diferido lo que todavia no convenga cerrar:
  - post-muerte FFA
  - replay snippets
  - expansion extra de roster

## Dependencias centrales

1. Escalabilidad, input y performance condicionan mapas, pausa, menus y practica.
2. La nueva escala de mapas condiciona HUD, onboarding y lectura de personajes.
3. La shell y la arquitectura de informacion condicionan `How to Play`, `Characters` y `Practice Mode`.
4. El pase audiovisual debe reforzar, no redefinir, la lectura ya acordada.

## Prioridad sugerida

1. Milestone 1
2. Milestone 2
3. Milestone 3
4. Milestones 4 y 5
5. Milestones 6 y 7

## Regla de mantenimiento

- Mantener este archivo corto y activo.
- Guardar el detalle largo en `docs/roadmap-history/`.
