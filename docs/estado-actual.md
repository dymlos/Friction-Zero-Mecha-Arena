# Estado actual

El prototipo ya tiene un loop integrado revalidado desde shell hasta cierre de match en `Teams` y `FFA`. La ruta de jugador arranca en `menu principal`, pasa por `setup local`, `Characters` y `How to Play` cuando hace falta, y llega a un cierre estable de partida sin prompts de laboratorio ni reinicio automatico.

## Lo que ya existe

- Shell local jugable: `menu principal -> setup local -> characters/how to play -> match -> pausa -> volver al menu`.
- Cierre integrado `player_shell` revalidado en `Teams` y `FFA` con recap + resultado final estables.
- Pantalla `Characters` de solo lectura accesible desde `menu principal` y `setup local`.
- Pantalla `How to Play` accesible desde `menu principal` y `setup local`, con reglas base del match y controles `Easy/Hard`.
- `Modo Practica` accesible desde `menu principal`, `setup local` y CTA contextual de `How to Play`.
- `PracticeSetup` dedicado con orden fijo de modulos, robot recomendado, temas relacionados y slots `P1/P2` con `Easy/Hard`.
- Runtime `practice_mode` separado del laboratorio, con modulos `movimiento`, `impacto`, `energia`, `partes`, `recuperacion` y `sandbox`.
- `PracticeHud` con modulo, objetivo, progreso, controles, callout corto y pausa, sin recap competitivo ni prompts de laboratorio.
- Fuente unica de copy del roster base visible hoy en shell: `Ariete`, `Grua`, `Cizalla` y `Patin`.
- Fuente unica de copy de onboarding general compartida entre shell, QA y tests.
- Movimiento con inercia y choques con peso.
- Dano modular por extremidad, energia y `Overdrive`.
- Partes desprendidas, recuperacion aliada, negacion rival y explosion diferida del cuerpo inutilizado.
- Primeros arquetipos, pickups de borde, presion progresiva y HUD explicito/contextual.
- Primer slice jugable de soporte post-muerte en `Teams`.
- Ruta de laboratorio separada de la ruta de jugador para QA y tuning.

## Lo que hoy esta mas validado

- Contrato de entrada `player_shell` vs `lab`, con metadata de laboratorio oculta en partidas lanzadas desde shell.
- Navegacion shell entre `menu`, `setup`, `characters`, `how to play`, `match` y `pausa`, con retorno owner-aware y restauracion de foco.
- Loop integrado automatizado desde `game_shell` hasta cierre de match en:
  - `Teams` base
  - `FFA` base
- Cierre `player_shell` sin `Reinicio | F5`, sin autorestart y con panels de recap/resultado auditados en producto integrado.
- Fuente unica de identidad por personaje compartida entre shell, QA y tests.
- Fuente unica de onboarding general compartida entre shell, QA y tests.
- Paridad del flujo de shell en tests scene-level y QA visual de `menu`, `setup`, `characters`, `how to play` y overlay de pausa.
- Paridad contractual de `Practica` en tests scene-level, QA visual y rotacion de modulos.
- QA integrada del loop completo a `1280x720`:
  - `player_shell_loop_teams_1280`
  - `player_shell_loop_ffa_1280`
- QA integrada de practica a `1280x720`:
  - `shell_practice_setup_layout_1280`
  - `practice_mode_layout_1280`
  - `practice_mode_module_rotation_1280`
- `layout audit` verde a `1280x720` y `1920x1080` para:
  - `scenes/qa/player_shell_loop_teams_validation.tscn`
  - `scenes/qa/player_shell_loop_ffa_validation.tscn`
  - `scenes/main/main.tscn`
  - `scenes/main/main_ffa.tscn`
  - `scenes/qa/shell_practice_setup_validation.tscn`
  - `scenes/qa/practice_mode_validation.tscn`
- Checklist manual pendiente de repetir sobre practica construida:
  - `1P Easy`
  - `1P Hard`
  - `2P mixto Easy/Hard`
  - entrada desde `How to Play`
  - volver al menu desde pausa
- Paridad contractual entre escenas `base` y `validation`.
- Apertura del match, presion del arena, recap, cierre y resolucion de ronda.
- Lectura superior del HUD y framing del helper post-muerte.

## Riesgos activos

- El siguiente gap ya no es construir `Modo Practica`, sino validar manualmente su legibilidad y ritmo con jugadores reales.
- La shell minima y practica todavia necesitan evidencia humana con mas jugadores reales; este slice cerro la baseline automatizada, no el playtest humano.
- El pacing fino del opening sigue siendo pregunta de tuning.
- La paridad `base/validation` sigue siendo el riesgo tecnico mas sensible cuando se tocan escenas o HUD.
- El soporte post-muerte `Teams` necesita mas validacion manual de legibilidad e impacto real.
- No aparecio un problema nuevo de `1080p` en este slice; la resolucion sigue siendo el checkpoint sensible para shell y practica.

## Contexto adicional

- Para detalle historico, revisar `docs/historial/estado/`.
