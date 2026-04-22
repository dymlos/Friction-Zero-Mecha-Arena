# PLAN_DESARROLLO.md - Friction Zero: Mecha Arena

Este plan ordena el desarrollo para validar primero la identidad real del juego: robots industriales que patinan con inercia, chocan con peso, se desarman por partes y obligan a leer el espacio antes de comprometerse. No propone un MVP generico: cada etapa debe dejar una version jugable que preserve la fantasia de "patinar y chocar con precision", aunque todavia falten capas avanzadas.

## Checkpoint actual - 2026-04-22

- Los contratos de recap entre rondas ya quedan congelados tambien en escenas `base` y `validation` de `Teams/FFA`:
  - la revision estricta encontro otro hueco scene-level: el recap entre rondas seguia fijado solo en `main.tscn` para `Teams` y en `main_ffa.tscn` para el empate `FFA`, dejando drift posible en `main_teams_validation.tscn` y `main_ffa_validation.tscn`.
  - no hizo falta tocar produccion; la correccion vive en la red de regresion:
    - `scripts/tests/match_round_recap_test.gd` ahora recorre `main.tscn` y `main_teams_validation.tscn`.
    - `scripts/tests/match_round_draw_recap_test.gd` ahora recorre `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - hallazgo de setup: `main_teams_validation.tscn` no comparte el mismo `rounds_to_win` que `main.tscn`, asi que la fixture fuerza `match_config.rounds_to_win = 3` para validar recap intermedio y no un cierre final accidental.
  - decision operativa: tratar tambien el recap entre rondas como contrato compartido entre laboratorios `base/validation`, no como comportamiento representativo de una sola escena.
  - validacion focalizada: `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `match_round_draw_recap_test.gd` y `test_runner.gd`.

- Los contratos de cierre ya quedan congelados tambien en escenas `base` y `validation` de `Teams/FFA`:
  - la revision estricta encontro otro hueco scene-level: varias lecturas de cierre (`Partida cerrada`, `Objetivo | ...`, `Posiciones | ...`, `Puntos cierre | ...`, `Cierre decisivo | ...`) seguian fijas solo en `main.tscn` o `main_ffa.tscn`, dejando drift posible en `main_teams_validation.tscn` y `main_ffa_validation.tscn`.
  - no hizo falta tocar produccion; la correccion vive en la red de regresion:
    - `scripts/tests/match_completion_test.gd` ahora recorre `main.tscn` y `main_teams_validation.tscn`.
    - `scripts/tests/ffa_match_result_standings_test.gd` ahora recorre `main_ffa.tscn` y `main_ffa_validation.tscn`.
    - `scripts/tests/match_closing_cause_summary_test.gd` ahora congela el mismo perfil de cierre en las cuatro escenas jugables.
  - decision operativa: tratar recap/resultado final igual que openings y locks del borde, como contratos compartidos entre laboratorio `base/validation`, no como asserts de una sola escena representativa.
  - validacion focalizada: `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `ffa_match_result_standings_test.gd` y `match_closing_cause_summary_test.gd`.

- El contrato del intro de ronda ya queda congelado tambien en escenas `base` y `validation` de `Teams/FFA`:
  - la revision estricta encontro otro hueco de mantenimiento en el opening: `round_intro_countdown_test.gd` seguia validando bloqueo de input, telegraph diegetico y liberacion post-countdown solo sobre `main.tscn`, dejando drift posible en `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - no hizo falta tocar produccion; la correccion vive en la regresion, que ahora recorre las cuatro escenas y respeta la fuente real del intro (`MatchConfig` cuando existe, `round_intro_duration` como fallback).
  - decision operativa: tratar tambien el countdown/base de control bloqueado como contrato compartido entre laboratorios `base/validation`, no solo el HUD neutral, el telegraph `Teams` y el lock del borde.
  - validacion focalizada: `godot --headless --path . -s res://scripts/tests/round_intro_countdown_test.gd`.

- El lock de pickups de borde durante el intro ya queda congelado tambien en las escenas `base` y `validation` de `Teams/FFA`:
  - la revision estricta encontro otro hueco de mantenimiento en el opening: el contrato `pickup visible pero no cobrable + HUD Borde | ... | abre en Xs + desbloqueo al terminar el countdown` estaba cubierto solo en `main.tscn`, dejando drift posible en `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - no hizo falta tocar produccion; `Main` y los pickups ya estaban alineados. La correccion vive en `scripts/tests/edge_pickup_intro_lock_test.gd`, que ahora recorre las cuatro escenas y verifica el mismo seam scene-level.
  - decision operativa: tratar el opening del borde como otro contrato compartido entre laboratorios `base/validation`, igual que el HUD neutral y el telegraph de apertura.
  - validacion focalizada: `godot --headless --path . -s res://scripts/tests/edge_pickup_intro_lock_test.gd`.

- La apertura neutral ya queda congelada tambien en los laboratorios `base` y `validation` de ambos modos:
  - la revision estricta encontro un hueco de mantenimiento: varios contratos de opening/readability (`Marcador 0-0` oculto en `Teams`, opening neutral limpio en `FFA`, `OpeningTelegraph` oculto fuera de `Teams`) estaban fijados solo en una escena por modo, dejando espacio para drift entre `main*.tscn` y las escenas rapidas.
  - no hizo falta tocar produccion; la correccion vive en la red de regresion:
    - `scripts/tests/teams_live_scoreboard_opening_test.gd` ahora recorre `main.tscn` y `main_teams_validation.tscn`.
    - `scripts/tests/ffa_live_standings_hud_test.gd` ahora recorre `main_ffa.tscn` y `main_ffa_validation.tscn`.
    - `scripts/tests/teams_opening_intro_telegraph_test.gd` ahora tambien congela que `main_ffa_validation.tscn` mantenga oculto el telegraph de carriles.
  - decision operativa: seguir usando la pareja `base/validation` como una sola superficie contractual para openings/HUD inicial, no como escenas que puedan divergir en silencio.
  - validacion focalizada: `godot --headless --path . -s res://scripts/tests/teams_live_scoreboard_opening_test.gd`, `teams_opening_intro_telegraph_test.gd` y `ffa_live_standings_hud_test.gd`.

- La apertura ahora tambien bloquea pickups de borde hasta que termina el intro:
  - la revision estricta encontro un hueco jugable entre la documentacion y el prototipo: `Teams`/`FFA` ya telegraphiaban la apertura, pero los pedestales del borde seguian siendo recogibles desde el frame cero y aceleraban el primer contacto sin dar tiempo real a leer posicionamiento.
  - `Main` ahora sincroniza un lock de coleccion sobre `edge_pickups` mientras `MatchController.is_round_intro_active()` siga verdadero; los pedestales quedan visibles, pero no se consumen hasta que la ronda realmente abre.
  - el HUD del laboratorio deja esa ventana explicita con `Borde | ... | abre en Xs`, y los pickups ahora revisan overlaps al liberarse el intro para no exigir salir y volver a entrar al pedestal.
  - la nueva regresion `edge_pickup_intro_lock_test.gd` ya fija ese contrato en `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`: el pickup no debe recogerse durante el intro y vuelve a funcionar cuando termina.
  - validacion: `godot --headless --path . -s res://scripts/tests/edge_pickup_intro_lock_test.gd`, `edge_utility_pickup_test.gd`, `edge_mobility_pickup_test.gd`, `edge_energy_pickup_test.gd`, `edge_pulse_pickup_test.gd`, `edge_charge_pickup_scene_test.gd` y `test_runner.gd` (`Suite OK: 85 tests`).

- Validado otra vez el perfil actual de cierre por causa (`ring-out 2 / destruccion total 1 / explosion inestable 4`) sin tocar producción:
  - la revision estricta volvio a contrastar el perfil activo en `MatchConfig` (`default_match_config.tres`, `ffa_validation_match_config.tres`, `teams_validation_match_config.tres`) contra la red que ya lo congela en runtime y en superficies de cierre.
  - la evidencia mecanica sigue alineada: `match_elimination_victory_weights_test.gd` confirma que `Teams` y `FFA` suman `2` por `ring-out` y luego `+4` por `explosion inestable`; `match_closing_cause_summary_test.gd` y `match_completion_test.gd` mantienen visible el mismo perfil en recap/resultado final con `Puntos cierre | ...`, `Cierre ronda | ...` y `Cierre decisivo | ...`.
  - decision operativa: no reabrir el perfil `2/1/4` por intuicion o por otra iteracion de wording; el siguiente cambio de balance solo se justifica con evidencia runtime/manual nueva de que una ruta esta dominando demasiado.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El recap lateral del cierre final ahora repite tambien `Cierre | ...`, igual que el panel final:
  - la revision estricta detecto una asimetria residual en los dos paneles de cierre: `MatchResultPanel` ya reutilizaba la ultima baja decisiva, pero `RecapPanel` no la repetia aunque ambas superficies convivian al mismo tiempo.
  - `scripts/systems/match_controller.gd` ahora concentra esa linea en `_build_closing_elimination_line()` y la reutiliza tanto en `get_round_recap_panel_lines()` como en `get_match_result_lines()`.
  - `scripts/tests/match_elimination_readability_test.gd` fija la regresion minima sobre arrays + `RecapLabel`: el recap lateral del cierre final tambien debe decir `Cierre | Player X ... por Player Y`.
  - validacion: rojo inicial en `godot --headless --path . -s res://scripts/tests/match_elimination_readability_test.gd`; despues pasaron ese test, `match_completion_test.gd`, `match_highlight_moments_test.gd`, `ffa_match_result_standings_test.gd` y la suite completa `test_runner.gd` (`Suite OK: 84 tests`).

- La suite de targeting post-muerte ya no queda flaky por esperar el loop incorrecto:
  - la revision detecto que `team_post_death_support_targeting_test.gd` fallaba de forma intermitente aun sin tocar produccion; el soporte actualiza targeting en `_physics_process()`, pero la fixture esperaba solo `process_frame`.
  - la correccion minima vive en la propia regresion: `_wait_frames()` ahora espera primero `physics_frame` y luego `process_frame`, alineando el helper con el seam real de `PilotSupportShip`.
  - no hizo falta tocar `scripts/support/pilot_support_ship.gd`; el problema estaba en la observacion del test, no en el auto-target runtime.
  - validacion: `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` paso repetido, y `godot --headless --path . -s res://scripts/tests/test_runner.gd` volvio a `Suite OK: 84 tests`.

- El cierre final `Teams` ahora explicita que el score del match son puntos:
  - la revision estricta detecto otro hueco de lectura: aunque HUD, recap y panel final ya mostraban `Objetivo | Primero a N pts`, la decision principal seguia cerrando como `Equipo X gana la partida 2-0`, ambigua entre rondas y puntos.
  - `scripts/systems/match_controller.gd` ahora hace que `_build_match_victory_status_line()` publique `Equipo X gana la partida por A-B pts` solo en `Teams`; `FFA` conserva su lectura propia `con N punto(s)`.
  - `scripts/tests/match_completion_test.gd` fija la regresion minima: `round_status_line`, `RecapLabel` y `MatchResultLabel` ya no aceptan el cierre viejo sin unidad.
  - validacion: rojo inicial en `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`; despues pasaron ese test, `match_closing_cause_summary_test.gd` y `test_runner.gd`.

- Las rondas sin ganador ahora tambien se explican dentro del recap intermedio:
  - la revision estricta detecto un hueco real: cuando la ronda terminaba en empate, el panel mostraba `Decision | Ronda N sin ganador` y el marcador, pero no dejaba una linea propia que aclarara que no hubo causa de cierre ni puntos otorgados.
  - `scripts/systems/match_controller.gd` ahora persiste `_last_round_was_draw` y hace que `_build_round_closing_line()` publique `Cierre ronda | sin ganador (+0)` solo en cierres intermedios, sin ensuciar el HUD vivo ni el cierre final del match.
  - `scripts/tests/match_round_draw_recap_test.gd` agrega la regresion headless minima sobre `main_ffa.tscn`: al forzar `_finish_round_draw()`, el recap lateral y su label visible deben repetir esa lectura de cero puntos.
  - validacion: rojo inicial en `godot --headless --path . -s res://scripts/tests/match_round_draw_recap_test.gd`; despues pasaron ese test, `match_round_recap_test.gd`, `match_closing_cause_summary_test.gd` y `match_completion_test.gd`.

- El recap entre rondas ahora deja visible tambien el perfil activo de puntos por causa:
  - `MatchController` ya no reserva `Puntos cierre | ring-out N | destruccion total N | explosion inestable N` solo para `Partida cerrada`; la misma linea tambien aparece en `get_round_recap_panel_lines()` apenas una ronda termina.
  - la correccion mantiene el gating en superficies de cierre (`_round_active == false`), sin sumar ruido al HUD vivo mientras el combate sigue abierto.
  - `match_closing_cause_summary_test.gd` ahora congela el caso en `Teams` y `FFA`: tras la primera ronda por `ring-out`, el recap intermedio debe mostrar tanto `Cierre ronda | ...` como `Puntos cierre | ...`.
  - validacion: rojo inicial en `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`; despues pasaron ese test, `match_round_recap_test.gd`, `match_completion_test.gd` y `test_runner.gd` (`Suite OK: 83 tests`).

- Los paneles de cierre ahora tambien dejan visible el objetivo del match:
  - `MatchController` extrae `Objetivo | Primero a N pts` a `_build_target_score_line()` y la reutiliza en HUD vivo explicito, `get_round_recap_panel_lines()` y `get_match_result_lines()`.
  - el recap intermedio y el cierre final ya no dependen del bloque principal del HUD para entender si un `1-0`, `2-0` o `3 pts` estan cerca de match point o ya cierran la partida.
  - `match_round_recap_test.gd` y `match_completion_test.gd` ahora congelan la presencia de esa linea tanto en arrays como en `RecapLabel` / `MatchResultLabel`.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_highlight_moments_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` (`Suite OK: 83 tests`).

- El recap lateral y el panel final ahora son autosuficientes para leer el cierre:
  - `MatchController` ya no deja la cadena compacta `Resumen | ...` solo en el bloque principal del HUD; `get_round_recap_panel_lines()` y `get_match_result_lines()` la reutilizan tambien dentro de `RecapPanel` y `MatchResultPanel`.
  - la correccion se resolvio sin duplicar string-building: ambos cierres consumen `get_round_recap_line()` como unica fuente de verdad del recap textual.
  - `match_highlight_moments_test.gd` ahora fija que el resumen compacto aparezca en el array del recap, en `RecapLabel` y en `MatchResultLabel`.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_highlight_moments_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- Objetivo del match mas claro dentro del HUD explicito:
  - `MatchController` ya no rotula el target del match como `Primero a N` a secas; ahora publica `Objetivo | Primero a N pts`.
  - el cambio alinea la lectura fija del laboratorio con el score ponderado por causa (`ring-out/destruccion total/explosion inestable`) que ya vive en recap y cierre final.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` (`Suite OK: 83 tests`).

- El recap de cada ronda decidida ya expone tambien la causa del cierre y sus puntos:
  - `MatchController` ahora agrega `Cierre ronda | <causa> (+N)` en `get_round_recap_panel_lines()` cuando la ronda termino pero la partida sigue abierta.
  - la linea reutiliza `_last_round_closing_cause` y el perfil activo de `MatchConfig`, evitando que el score ponderado solo se entienda al final del match.
  - `match_closing_cause_summary_test.gd` amplia la regresion en `Teams` y `FFA`: tras la primera ronda por `ring-out` exige ese recap antes del reset.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- Apertura `Teams` reforzada durante el intro sin sumar HUD permanente:
  - `MatchController` ahora explicita `Ronda N | carriles listos | arranca en ...` solo en `Teams`.
  - `ArenaBase` crea un `OpeningTelegraph` runtime con dos bandas horizontales que siguen las filas reales por equipo y se apagan al liberar la ronda.
  - `Main` alimenta ese cue desde el mismo seam del round intro (`_sync_round_intro_locks()` / `_sync_opening_telegraph()`), sin timers paralelos ni datos duplicados en escenas.
  - validacion: `godot --headless --path . -s res://scripts/tests/teams_opening_intro_telegraph_test.gd`, `godot --headless --path . -s res://scripts/tests/round_intro_countdown_test.gd`, `godot --headless --path . -s res://scripts/tests/teams_spawn_coordination_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` (`Suite OK: 83 tests`).

- Cierre decisivo legible dentro del propio prototipo:
  - recap y `Partida cerrada` ahora publican `Cierre decisivo | <causa> (+N)` ademas de `Cierres | ...` y `Puntos cierre | ...`.
  - `MatchController` persiste la causa que clinchea la ronda final en `_last_round_closing_cause` y la reutiliza solo en el cierre final, sin sumar ruido al HUD vivo.
  - validacion: `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- Apertura `Teams` mas legible sin tocar layout:
  - `Main._get_bootstrap_spawn_transforms()` ya no hereda la base arbitraria de los markers en `Teams`; ahora conserva las posiciones del arena y recompone la orientacion de spawn para que cada lado mire hacia su carril central.
  - el ajuste se resolvio en runtime, no duplicando datos en escenas, para mantener un solo seam de bootstrap entre `main.tscn` y `main_teams_validation.tscn`.
  - `teams_spawn_coordination_test.gd` dejo de validar solo "aliado mas cerca que rival" y ahora tambien congela que los cuatro robots arranquen mirando hacia dentro desde su mitad.
  - validacion: `godot --headless --path . -s res://scripts/tests/teams_spawn_coordination_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd`, `godot --headless --path . -s res://scripts/tests/teams_validation_lab_scene_test.gd`, `godot --headless --path . -s res://scripts/tests/test_runner.gd` (`Suite OK: 82 tests`).

- Revision estricta de baseline cerrada:
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` vuelve a pasar completo con `Suite OK: 82 tests`.
  - no aparecio ningun rojo nuevo en soporte post-muerte, selector runtime, HUD dual, bootstrap de escenas ni pacing base de choque.
  - decision operativa: no seguir abriendo microajustes del slice `laboratorio + Apoyo activo` sin un fallo headless nuevo o evidencia runtime clara; la red actual ya cubre los seams recientes y el mayor retorno ahora esta en playtest corto de score/ritmo/cierre.
- Siguiente foco recomendado tras esta revision:
  - validar pesos de cierre por causa con sesiones cortas en `main.tscn` / `main_ffa.tscn`, usando ahora tambien `Cierre ronda | ...` para leer la recompensa de cada ronda antes del final del match;
  - medir la apertura coordinada de `Teams` antes de volver a tocar HUD o selector;
  - mantener el soporte post-muerte en modo mantenimiento, no en expansion, salvo evidencia nueva.

- El selector runtime del laboratorio ya tiene regresión explícita también para el seam `F2` cuando el slot seleccionado sale de `Apoyo activo` hacia otro robot vivo y luego vuelve a aterrizar sobre la misma nave post-muerte.
- La revisión confirmó que la producción ya estaba alineada: `cycle_lab_selector_slot()` solo cambia `_lab_selected_player_slot`, y tanto `Lab | ...` como `Control Pn | ...`, `Apoyo Pn | ...` y `LabSelectionIndicator` se reconstruyen correctamente desde `_find_post_death_support_ship(...)`.
- `lab_runtime_selector_test.gd` ahora congela el flujo completo `P1 Apoyo activo -> F2 -> P2 vivo -> wrap F2 -> P1 Apoyo activo`, exigiendo que el resumen, la referencia compacta, la línea de soporte y la marca diegética migren en ambos sentidos sin arrastrar estado stale.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`.

- El roster explícito `Teams` ahora prioriza la acción vigente del soporte post-muerte: cuando un jugador pasa a `Apoyo activo`, la línea deja de intercalar la causa de baja antes del hint/payload accionable y pasa a ordenar `Apoyo activo | <support_state> | baja <causa>`.
- La corrección vive en `MatchController._build_robot_status_line()`, sin abrir HUD nuevo ni esconder la causa; solo la degrada a dato secundario para que el soporte real se lea primero.
- `live_roster_order_test.gd` suma la regresión mínima del orden de segmentos en HUD explícito (`Apoyo activo` -> `get_support_input_hint()` -> `vacio`), mientras `hud_detail_mode_test.gd`, `team_post_death_support_test.gd` y la suite completa siguen verdes.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El reset runtime del laboratorio (`F3/F4`) ya no deja una `PilotSupportShip` stale viva durante el mismo frame cuando el slot seleccionado venía de `Apoyo activo`: el selector, la chuleta `Control P1 | ...`, la línea `Apoyo P1 | ...` y la pista diegética vuelven inmediatamente al robot reconfigurado.
- La corrección vive en `Main._clear_post_death_support()`, que ahora saca las naves de `SupportRoot` antes de `queue_free()`. Así `_find_post_death_support_ship(...)` deja de ver soporte transitorio cuando `_apply_lab_runtime_loadout()` reinicia la ronda dentro de la misma llamada.
- `lab_runtime_selector_test.gd` suma la regresión concreta `P1 Grua Hard -> Apoyo activo -> F3/F4`, exigiendo en ambos caminos retorno inmediato a `P1 Cizalla Hard/Easy`, desaparición instantánea de `Apoyo P1 | ...` y `SupportRoot` vacío sin esperar otro frame.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El reset automático de ronda del laboratorio ahora también queda congelado explícitamente cuando el slot seleccionado venía de `Apoyo activo`: no solo `F5` y `F6`, también el path normal `cierre de ronda -> nueva ronda` devuelve el selector runtime al robot/loadout real.
- La revisión confirmó que la producción ya estaba bien resuelta entre `Main._on_round_started()`, `_clear_post_death_support()` y `_sync_lab_selector_visuals()`; el trabajo de esta iteración fue agregar la red headless que faltaba.
- `lab_runtime_selector_test.gd` ahora fija el flujo `P1 Grua Hard -> Apoyo activo -> ronda cerrada -> Ronda 2`, exigiendo antes del reset `Lab | P1 Apoyo activo`, `Control P1 | usa C | objetivo Q/E`, `Apoyo P1 | sin carga`, y después del reset `Lab | P1 Grua Hard`, controles de robot, ausencia de `Apoyo P1 | ...`, sin `PilotSupportShip` stale y `LabSelectionIndicator` de vuelta en el robot.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- La pista diegética `LabSelectionIndicator` del laboratorio ya sigue también al actor jugable real cuando el slot seleccionado cae en `Teams` y pasa a `Apoyo activo`: el anillo deja de quedarse pegado al robot caído y migra a `PilotSupportShip`.
- La corrección se resolvió sin abrir otra UI: `PilotSupportShip` ahora expone `set_lab_selected()/is_lab_selected()` y crea su propio anillo runtime, mientras `Main._sync_lab_selector_visuals()` apaga la marca del robot si existe soporte activo para ese owner y la reaplica a la nave.
- `lab_runtime_selector_test.gd` fija el seam completo: antes de la baja exige anillo visible en el robot seleccionado; después de `fall_into_void()` exige anillo apagado en el robot, `is_lab_selected()` verdadero en la nave y `LabSelectionIndicator` visible en `PilotSupportShip`.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El salto runtime `F6` entre laboratorios ya tiene regresión explícita también cuando el slot seleccionado venía de `Apoyo activo`: el cambio de escena debe limpiar la nave post-muerte, restaurar el robot del slot con su loadout runtime (`Grua Hard` en la fixture) y borrar la línea `Apoyo P1 | ...` en la escena nueva.
- La decisión fue congelar el seam en cobertura, no tocar producción: `cycle_lab_scene_variant()` ya persistía solo slot/loadout/HUD en `_lab_runtime_session_state`, y la escena recargada rearmaba un laboratorio limpio sin arrastrar soporte stale.
- `lab_scene_selector_test.gd` ahora cubre el flujo completo `P1 Grua Hard -> Apoyo activo -> F6 -> Equipos rapido`: antes del salto exige `Lab | P1 Apoyo activo`, `Control P1 | usa C | objetivo Q/E` y `Apoyo P1 | sin carga`; después del salto exige `Lab | P1 Grua Hard`, controles de robot Hard y ausencia de `Apoyo P1 | ...`.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El laboratorio ya tiene regresión explícita para el camino completo `robot seleccionado -> Apoyo activo -> cierre de match -> F5`: si `P1` cae, pasa a la nave post-muerte y luego su equipo pierde la ronda/partida, el reinicio manual vuelve a mostrar el robot seleccionado (`Lab | P1 Grua Hard ...`, `Control P1 | mueve ...`) y limpia la línea `Apoyo P1 | ...`.
- La iteración no necesitó tocar producción: el path real ya quedaba bien resuelto entre `MatchController.request_match_restart()`, `Main._on_round_started()` y `_clear_post_death_support()`. El hueco era de cobertura, no de lógica.
- `lab_runtime_selector_test.gd` ahora fija el seam real con match cerrado: primero convierte `P1` en `Apoyo activo`, luego cierra el match eliminando también a `P2`, dispara `F5` y exige que el selector runtime recupere el loadout runtime (`Grua Hard`) sin arrastrar soporte stale.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/match_manual_restart_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El round-state del laboratorio ahora deja visible tambien el estado accionable del slot seleccionado cuando ese jugador ya paso a `Apoyo activo` en `Teams`: junto a `Lab | P1 Apoyo activo` y `Control P1 | usa C | objetivo Q/E`, aparece `Apoyo P1 | ...` con la carga/target real del soporte (`sin carga`, `interferencia > ...`, warnings como `fuera de rango`, etc.).
- La implementacion se repartio en un seam chico para no duplicar reglas: `PilotSupportShip.get_status_summary()` sigue armando la linea completa del roster y ahora delega la parte accionable en `get_actionable_status_summary()`, mientras `Main.get_lab_selected_support_summary_line()` reutiliza ese helper y publica la nueva linea solo cuando el slot seleccionado realmente tiene nave post-muerte.
- `lab_runtime_selector_test.gd` fija el seam en dos pasos: antes de la baja no debe aparecer ninguna linea `Apoyo P1 | ...`; despues de la caida del slot seleccionado, el round-state debe mostrar `Apoyo P1 | sin carga`.
- Validacion focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- El resumen `Lab | ...` del slot seleccionado ya no queda stale cuando ese jugador pasa a `Apoyo activo` en `Teams`: la misma línea que antes seguía anunciando `P1 Ariete Easy/Hard` ahora cambia a `P1 Apoyo activo`, alineada con los controles reales del soporte post-muerte.
- La corrección vive en `Main._get_lab_robot_brief()`: antes de resumir arquetipo/modo consulta `_find_post_death_support_ship(robot)` y, si la nave existe, prioriza el estado jugable actual del slot en vez del loadout del robot caído.
- `lab_runtime_selector_test.gd` fija el seam junto al hint de controles: arranca con `Lab | P1 Ariete Easy ...`, tras la baja del slot seleccionado exige `Apoyo activo` dentro del resumen runtime y también verifica que desaparezca el texto stale `Ariete Easy`.
- Validacion focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd`.

- La referencia persistente `Control Pn | ...` del laboratorio ya sigue tambien el soporte post-muerte en `Teams`: cuando el slot seleccionado cae y pasa a `Apoyo activo`, la linea deja de mostrar los controles del robot caido y migra a `usa ... | objetivo ...`, alineada con la nave real.
- La correccion vive en `Main.get_lab_selected_controls_summary_line()`: el selector runtime sigue usando `RobotBase.get_control_reference_hint()` para robots activos, pero consulta `_find_post_death_support_ship(robot)` antes de publicar la chuleta y, si el soporte existe, reutiliza `robot.get_support_input_hint()` en vez del hint de combate.
- `lab_runtime_selector_test.gd` fija este seam dentro del mismo flujo de laboratorio: `P1` arranca con `mueve/ataca/energia/...`, cae al vacio en `Teams` y la referencia persistente pasa a `Control P1 | usa C | objetivo Q/E` sin arrastrar `mueve WASD`.
- Validacion focalizada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` pasan.

- El laboratorio ahora deja tambien una referencia persistente del modo HUD activo dentro del round-state (`HUD | explicito/contextual | F1 cambia`), evitando que el override runtime de `F1` quede visible solo en el `StatusLabel` temporal.
- La implementacion vive en `Main`: `get_lab_hud_mode_summary_line()` deriva el label real desde `MatchController.get_hud_detail_mode_label()` y `_build_round_state_lines()` la publica junto a `Escena | ...`, `Lab | ...` y `Control Pn | ...`, por lo que tambien sobrevive al salto `F6` entre laboratorios sin otra persistencia manual.
- `lab_scene_selector_test.gd` fija el seam completo: el laboratorio arranca con `HUD | explicito | F1 cambia`, cambia a `HUD | contextual | F1 cambia` al alternar `F1` y conserva esa misma linea tras recargar la siguiente escena con `F6`.
- Validacion focalizada: `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` pasa.

- El HUD vivo `Teams` ya no gasta una línea completa en `Marcador | Equipo 1 0 | Equipo 2 0` durante la apertura totalmente neutra del primer round; el score vuelve solo cuando una ronda decidida ya aporta contexto competitivo real.
- La corrección vive en `MatchController._should_show_live_score_summary()`: `FFA` conserva su gating propio de standings, mientras `Teams` oculta el marcador solo durante el match activo sin rondas decididas (`_match_decided_rounds == 0`), manteniendo recap y resultado final intactos.
- `teams_live_scoreboard_opening_test.gd` fija el seam completo: el opening `Teams` no debe mostrar `Marcador | ...`, pero tras cerrar una ronda por vacío la línea vuelve a aparecer en el HUD vivo.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/teams_live_scoreboard_opening_test.gd`, `godot --headless --path . -s res://scripts/tests/ffa_live_standings_hud_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd` y `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` pasan.

- El laboratorio ahora deja una referencia compacta de controles para el slot seleccionado dentro del propio round-state (`Control Pn | mueve ... | aim ... | ataca ... | energia ... | overdrive ... | suelta ...`), de modo que el selector runtime ya no depende solo del roster o del `StatusLabel` para leer `Easy/Hard` en pantalla compartida.
- La implementacion vive repartida en un seam chico y legible: `Main.get_lab_selected_controls_summary_line()` publica la linea en `_build_round_state_lines()`, mientras `RobotBase.get_control_reference_hint()` centraliza los labels por perfil (`WASD`, `flechas`, `numpad`, `IJKL`) y suma `aim ...` solo cuando el slot realmente esta en `Hard`.
- `lab_runtime_selector_test.gd` fija la regresion completa: la linea existe al iniciar en `P1/Easy`, agrega `aim TFGX` al alternar el slot seleccionado a `Hard` y migra a `P2` con el perfil flechas al cambiar de slot.
- Validacion cerrada: `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/hard_mode_bootstrap_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 81 tests`).

- El cierre del match ahora resume tambien la mezcla acumulada de rutas que decidieron rondas (`Cierres | ring-out N | destruccion total N | explosion inestable N`) para que el peso por causa se lea dentro del propio prototipo y no solo en notas o tests aislados.
- La implementacion vive en `MatchController`: `_finish_round_with_winner(...)` registra la causa que cerro cada ronda ganada en `_match_closing_cause_counts`, y `get_round_recap_panel_lines()` / `get_match_result_lines()` publican esa lectura solo cuando la partida ya termino.
- `match_closing_cause_summary_test.gd` fija el seam en `Teams` y `FFA`: una ronda cerrada por vacio y otra por explosion inestable deben terminar mostrando `Cierres | ring-out 1 | explosion inestable 1` tanto en recap como en resultado final.
- Validacion cerrada: `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

- El cierre de partida ahora deja visible tambien el perfil runtime de score por causa (`Puntos cierre | ring-out N | destruccion total N | explosion inestable N`) para que el playtest corto pueda leer el peso vigente sin abrir configs ni tests.
- La correccion vive en `MatchController`: `get_round_recap_panel_lines()` y `get_match_result_lines()` reutilizan `_build_closing_points_profile_line()`, que deriva los valores activos directamente desde `MatchConfig`.
- `match_closing_cause_summary_test.gd` amplia el contrato en `Teams` y `FFA`: el recap final y el panel `Partida cerrada` deben mostrar esa linea con los valores runtime del config cargado, no un string fijo desacoplado.
- Validacion cerrada: `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

- `MatchConfig.new()` ya no cae en un perfil runtime distinto al prototipo jugable cuando un test o un laboratorio crea configs en memoria en vez de cargar un `.tres`.
- La correccion vive en `scripts/systems/match_config.gd`: los defaults exportados ahora coinciden con `default_match_config.tres` en los campos que afectan el comportamiento base del laboratorio (`local_player_count=4`, intro `FFA=1.0` / `Teams=0.6`, score por causa `vacio=2`, `destruccion=1`, `inestable=4`).
- `match_config_defaults_test.gd` fija explicitamente ese seam y compara `MatchConfig.new()` contra `res://data/config/default_match_config.tres` para evitar que futuras iteraciones reintroduzcan drift silencioso entre runtime in-memory y escenas base.
- Validacion cerrada: `godot --headless --path . -s res://scripts/tests/match_config_defaults_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 80 tests`).

- El soporte aliado post-muerte ya no se queda clavado en un auto-target simplemente “todavia util” cuando aparece otro aliado claramente mas urgente durante la misma ronda.
- La correccion vive en `PilotSupportShip._should_resync_to_default_target(...)`: para `estabilizador`, `energia` y `movilidad`, si no hubo override manual y el target default sube de prioridad real, la nave resincroniza al mejor aliado; `interferencia` conserva el criterio previo de no rebotar salvo que el target actual deje de ser accionable.
- `_refresh_target_selection()` tambien limpia overrides manuales stale si el estado runtime ya convergio otra vez al mismo target default, evitando que ese flag bloquee resincronizaciones posteriores sin aportar una intencion real del jugador.
- `team_post_death_support_targeting_test.gd` suma la regresion concreta: empezar sobre el aliado levemente dañado, herir mas fuerte a otro aliado en runtime y comprobar que `stabilizer` salta al nuevo objetivo prioritario sin input manual. La fixture ahora congela candidatos teletransportados (`is_player_controlled = false`, velocidad/impulso en cero) y la nueva prueba fuerza `_refresh_target_selection()` para no depender del timing global de la suite.
- Validacion cerrada: `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_actionability_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 79 tests`).

- El HUD contextual ya no arrastra la causa de baja dentro de `Apoyo activo`: cuando un jugador eliminado sigue activo desde `PilotSupportShip`, el roster limpio conserva `Apoyo activo` + hint/payload de soporte, pero deja la causa (`vacio`, etc.) para el HUD explicito y el cierre.
- La poda vive solo en `MatchController._build_robot_status_line(...)`: si `contextual_hud` y `has_active_support` son verdaderos, `state_detail` deja de repetir la causa de eliminacion porque ya no es la informacion mas accionable de ese estado.
- `hud_detail_mode_test.gd` ahora cubre explicitamente ese caso: en HUD contextual, una baja con soporte activo debe seguir mostrando `Apoyo activo`, `get_support_input_hint()` y `sin carga`, pero no la causa de baja.
- Validación focalizada: `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` y `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` pasan.

- El soporte post-muerte `Teams` ahora vuelve solo al modo auto si el jugador cicla manualmente de regreso al mismo target que el default actual; desde ahi, si ese target envejece o se vuelve inmune, la nave puede resincronizar otra vez hacia el mejor objetivo útil.
- La corrección vive en `_cycle_selected_target()`: al aterrizar sobre el mismo target que `_get_default_support_target(candidates)` ya elegiría, `PilotSupportShip` limpia `_manual_target_override` en vez de arrastrar un override stale.
- `team_post_death_support_targeting_test.gd` ahora fija ese seam completo para `interferencia`: auto-target -> override manual al rival alternativo -> vuelta manual al default -> `estabilidad` sobre ese default -> salto automático de nuevo al rival útil.
- Validación cerrada: `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_actionability_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 79 tests`).
- Medición corta cerrada para el gating de no-ops del soporte `Teams`: en el setup real 2v2/3-robots-vivos, una mala selección manual de `surge` o `movilidad` no gasta la carga, sigue mostrando `ya activo` y se corrige con un solo ciclo de target hacia el aliado útil.
- `support_payload_actionability_test.gd` ahora fija también esa recuperación operativa: forzar target manual redundante, bloquear el no-op y confirmar redirección inmediata al aliado útil sin tocar `PilotSupportShip`.
- Decisión operativa: no reabrir este seam por sensación en el laboratorio actual; solo volver a medir si `Teams` escala a más aliados vivos simultáneos o si cambia el orden/costo del ciclado manual.
- La nave de apoyo `Teams` ya no puede gastar `surge` o `movilidad` sobre un target que su propia lectura compacta ya marca como `ya activo`; `_resolve_support_target_for_payload()` ahora reutiliza `_is_payload_actionable_on_target(...)`, así que la carga queda disponible para redirigirla a un aliado realmente útil.
- `support_payload_actionability_test.gd` fija ambas regresiones reales: `surge` y `movilidad` sobre aliados con toda la ventana útil ya cubierta.
- El soporte post-muerte ya no deja envejecerse el default en runtime: si el target auto-seleccionado deja de ser accionable durante la ronda y existe otro objetivo útil, `PilotSupportShip` resincroniza solo hacia ese nuevo mejor target sin obligar a corregirlo manualmente.
- La regla no pisa la intención del jugador: `PilotSupportShip` distingue ahora entre selección automática y ciclo manual, así que solo auto-retargetea defaults; si el jugador eligió otro target a propósito, la nave conserva esa selección.
- `team_post_death_support_targeting_test.gd` suma una regresión runtime concreta para `interferencia`: arranca sobre el rival útil, ese rival gana `estabilidad`, y la nave debe saltar sola al siguiente rival afectable.
- Esa misma suite ahora blinda también el límite de esa lógica: si el jugador cicla manualmente hacia otro rival y ese target luego gana `estabilidad`, la nave no debe auto-corregir la selección por detrás del input humano.
- Los marcadores diegéticos del soporte post-muerte ya no contradicen al roster compacto: `SupportTargetIndicator` y `SupportTargetFloorIndicator` ahora también bajan intensidad cuando el payload seleccionado sería un no-op real (`sin daño`, `ya activo`, `estable`), en lugar de reservar ese feedback tenue solo para `interferencia` fuera de rango.
- El anillo de alcance de `interferencia` ya no queda como excepción visual: `InterferenceRangeIndicator` ahora también usa la misma noción de accionabilidad real, así que un rival en rango pero inmune por `estabilidad` deja de verse “listo” en mundo.
- `PilotSupportShip` centraliza esa lectura en `_is_payload_actionable_on_target(...)`, así que la misma noción de utilidad inmediata gobierna tanto los warnings del roster como la fuerza visual del objetivo seleccionado en mundo.
- `support_payload_availability_readability_test.gd` ahora cubre además un caso diegético completo: con `interferencia`, dos rivales en rango y uno inmune por `estabilidad`, el target inicial sigue sobre el rival útil y, al ciclar al inmune, el marcador superior, la marca de piso y el anillo de rango bajan `emission_energy_multiplier`.
- El soporte post-muerte ya no queda “armado en falso” contra rivales con `estabilidad`: `PilotSupportShip` ahora prioriza para `interferencia` a enemigos que no esten protegidos por utility y, si el jugador cicla igual a uno inmune, el roster compacta el bloqueo como `estable`.
- `support_payload_availability_readability_test.gd` y `team_post_death_support_targeting_test.gd` ahora cubren ese contrajuego entre `interferencia` y `estabilidad`, de modo que el carril no vuelva a ofrecer presión aparente sobre un target que gameplay ya vuelve inmune.
- El soporte post-muerte ya no deja `surge` o `movilidad` como cargas aparentemente listas cuando el aliado seleccionado ya tiene toda la ventana útil del buff: `PilotSupportShip.get_status_summary()` ahora agrega `ya activo` solo si volver a usar esa carga sería un no-op real en ese target.
- La regla se calcula con la duración efectiva del payload en el objetivo (`support_energy_surge_duration` o `support_mobility_boost_duration * target.get_mobility_boost_duration_multiplier()`), así que el warning desaparece solo cuando la ventana restante ya cayó por debajo del valor que aportaría una nueva activación.
- El targeting por defecto de `surge` y `movilidad` también quedó alineado con esa misma métrica: si varios aliados ya tienen el buff activo, `PilotSupportShip` ahora prioriza al que todavía ganaría ventana real antes que reciclar al más saturado.
- `support_payload_availability_readability_test.gd` ahora cubre cuatro casos de disponibilidad del carril (`stabilizer`, `interferencia`, `surge`, `movilidad`) para que la legibilidad compacta no vuelva a degradarse payload por payload.
- `team_post_death_support_targeting_test.gd` ahora cubre también esa regresión de multi-aliado para `surge` y `movilidad`, no solo `stabilizer` e `interference`.
- El soporte post-muerte ya no falla “mudo” cuando recoge `estabilizador` sobre un aliado completamente sano: `PilotSupportShip.get_status_summary()` ahora agrega `sin daño` hasta que exista una pieza activa realmente dañada, y el roster limpia esa advertencia en cuanto aparece una avería real.
- La nave de apoyo ahora explicita `fuera de rango` cuando lleva `interferencia` pero el rival seleccionado todavia no entra en el radio real; el roster ya no falla “en silencio” mientras el telegraph de piso sigue apagado o tenue.
- El soporte post-muerte Teams ya no nace “armado gratis” por solaparse con pickups del carril: `PilotSupportShip` arranca con una ventana corta `spawn_pickup_grace_duration`, el roster marca `sin carga` mientras sigue vacio y la primera recogida exige una pasada real por el carril.
- El cleanup del soporte post-muerte ya tiene red de regresión propia: `support_lifecycle_cleanup_test.gd` cubre tanto el reset de ronda no final como el reinicio manual `F5`, y fija además que `SupportRoot`, `support_state` y el carril externo vuelven limpios antes de la ronda siguiente.
- El roster vivo `Teams` ya no arrastra estados de combate del robot caído cuando ese jugador sigue en `Apoyo activo`: `MatchController` deja fuera `skill ...`, foco/estado de energía, buffs y `item ...` del cuerpo eliminado y conserva solo la información todavía accionable desde `PilotSupportShip`.
- El roster explicito `Teams` ya no mezcla controles viejos del robot con controles de la nave cuando una baja sigue activa por soporte post-muerte: `MatchController` oculta `robot.get_input_hint()` en ese estado y deja solo el hint valido de `PilotSupportShip` dentro de `support_state`.
- El roster vivo `Teams` ahora deja claro cuando un jugador eliminado sigue aportando desde la nave de apoyo: `MatchController` muestra `Apoyo activo | <causa>` en vez de mezclarlo con una baja ya cerrada, y `PilotSupportShip` compacta su resumen a hints/payload/objetivo sin repetir `apoyo` en cada segmento.
- El cierre Teams ya no deja el soporte solo en agregado: `Main` reenvía el `target_robot` real de cada payload usado y `MatchController` ahora publica `Apoyo decisivo | <owner> <payload> > <objetivo>` dentro de recap/resultado final cuando esa ayuda acompañó la ronda ganadora.
- La presión final del arena ya no aparece “de golpe”: `MatchController` suma `space_reduction_warning_seconds` y publica `Arena se cierra en Xs` antes de pasar a `Arena cerrandose | N%`.
- `Main` sigue siendo el puente mínimo entre match y arena, pero ahora además de la escala real envía una intensidad previa al `PressureTelegraph`; `ArenaBase` reutiliza esas bandas de piso con alpha/emission más bajos para avisar el cierre sin achicar todavía el borde vivo.
- El soporte post-muerte Teams ya no depende de `scene-order` cuando hay varios candidatos vivos: `PilotSupportShip` ahora prioriza objetivos segun utilidad del payload (`estabilizador` al aliado mas dañado, `surge`/`movilidad` evitando buffs redundantes, `interferencia` sobre rivales no suprimidos y en rango antes que reciclar el mismo objetivo).
- La apertura base de `Equipos` ya no depende de un layout en cruz: `arena_blockout.tscn` ahora agrupa a cada pareja en su mismo lateral, de modo que `main.tscn` arranca con aliados más cerca entre sí que del rival más cercano y la escena larga conserva mejor el beat de coordinación/rescate del laboratorio rápido.
- La base de escenas jugables ya tiene smoke runtime real: `main_scene_runtime_smoke_test.gd` instancia `main`, `main_ffa`, `main_teams_validation` y `main_ffa_validation`, comprueba arena/HUD/robots/MatchController y fija además que las escenas base también cargan `default_match_config.tres` vía `match_controller.tscn`.
- El laboratorio ahora permite alternar modo de control por jugador sin tocar la escena: `Main` acepta `1-8` para alternar `Easy/Hard` directamente sobre el slot indicado, mantiene `F2/F3/F4` para selector fino y deja el HUD en estado `Lab: Pn ...` tras cada cambio para que la sesión corta no dependa del editor.
- La telemetría de soporte post-muerte ahora distingue también si el apoyo estuvo presente en rondas realmente decisivas: `MatchController` agrega `Aporte de apoyo | X/Y rondas ...` y `rondas decisivas por apoyo ...` dentro de `Stats | ...`, dejando el carry real del soporte visible sin abrir otra capa de post-partida.
- Los seis recursos `data/config/robots/*_archetype.tres` recibieron una nueva línea base de tuning liviano para reforzar identidad antes del próximo playtest corto; no cambia el sistema de habilidades, sólo el punto de partida de multiplicadores para `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla`.
- Validación de sensibilidad de combate cerrada sin retocar `RobotBase`: el rojo de `match_round_resolution_test.gd` y `match_completion_test.gd` venía de supuestos viejos de score fijo (`+1`) y no de una regresión en movimiento/choque. La cobertura nueva `robot_collision_pacing_test.gd` fija glide corto tras soltar input y daño de choque solo por encima de `collision_damage_threshold`.
- Mini-check documental cerrado: no apareció una contradicción crítica entre `Documentación/` y el prototipo actual. Los gaps más visibles siguen siendo deliberados de etapa temprana (`FFA` sin sistema post-muerte definitivo y laboratorios todavía concentrados en 4 jugadores locales para preservar claridad del núcleo).
- Auditoría de consistencia de escenas completada: se revisaron `main.tscn`, `main_ffa.tscn`, `main_teams_validation.tscn` y `main_ffa_validation.tscn` sin hallazgos de referencias rotas; el siguiente paso sigue siendo validar el comportamiento de combate en sesiones cortas (2v2 y FFA) antes de ajustar `RobotBase`.
- `MatchConfig` y `MatchController` ahora separan la duración del intro de ronda por modo: `round_intro_duration_ffa` y `round_intro_duration_teams` permiten ajustar el ritmo inicial de `Equipos` y `FFA` sin tocar escenas ni bloquear cambios de combate.

- Cierre por causa y telemetría de soporte finalizado para soporte de decisión:
  - El sistema de cierre por ronda ahora pondera causa (`ring_out`, `destruccion total`, `explosion inestable`) via `MatchConfig`; el test principal valida perfiles de peso en Teams y FFA en un mismo ciclo controlado.
  - `MatchStats` ahora incluye soporte por rondas decisivas (`support_rounds_decided`) y desglose de `support_payload_use_*` para medir impacto real del soporte post-muerte en Teams sin tocar loops de combate.
  - El estado/documentación se alinea con el contrato vigente: texto de cierre y recap explicitan causa, desempate real y contribución de soporte.

- El soporte post-muerte Teams ya no rompe identidad al nombrar objetivos: `PilotSupportShip.get_status_summary()` ahora reutiliza `RobotBase.get_roster_display_name()` para el aliado/rival seleccionado, de modo que `apoyo estabilizador > Player X / Ariete` e `interferencia > Player Y / Ancla` mantengan la misma continuidad `Player / Arquetipo` que el roster vivo y el cierre. `team_post_death_support_test.gd` fija esa regresion.
- El handoff de rescate ya tambien avisa cuando la devolucion esta realmente lista: `RobotBase` ahora expone `is_carried_part_return_ready()`, intensifica `CarryReturnIndicator` cuando el portador entra en radio real del dueño y hace que `RecoveryTargetFloorIndicator` tambien suba de intensidad si un aliado ya puede completar el retorno. `carried_part_return_readiness_test.gd` fija ese contrato junto con `detached_part_return_target_test.gd`, `robot_part_return_test.gd`, `two_vs_two_carry_validation_test.gd` y `teams_validation_lab_scene_test.gd`.
- El cierre por robot ahora conserva tambien la identidad de arquetipo: `MatchController._build_robot_recap_panel_line()` ya no cae a `display_name`, sino que reutiliza `RobotBase.get_roster_display_name()` para que `RecapPanel` y `MatchResultPanel` mantengan `Player / Arquetipo` tambien cuando muestran `sigue en pie`, `baja N | causa` o `inutilizado`. `match_robot_final_condition_summary_test.gd`, `match_completion_test.gd`, `ffa_match_result_standings_test.gd`, `match_elimination_source_reset_test.gd`, `match_elimination_readability_test.gd` y `match_round_recap_test.gd` fijan la regresion.
- Stats de cierre mas claros: `MatchController` ya no deja `Stats | ... | bajas N (...)` para telemetria que en realidad mide eliminaciones sufridas; ahora publica `bajas sufridas N (...)` tanto en recap como en resultado final, manteniendo el dato igual y corrigiendo solo la semantica del cierre. `match_modular_loss_stats_test.gd`, `match_completion_test.gd`, `match_part_denial_stats_test.gd` y `support_match_stats_test.gd` fijan el contrato.
- El bloque `Stats | ...` del cierre ahora tambien sigue el resultado real: `MatchController` ya no deja la telemetria final en scene-order/registro cuando el ranking FFA cambia; recap y panel final ordenan stats con el mismo comparator del resultado (`_compare_ffa_competitors_for_standings`, y el equivalente Teams) para que ganador, empates y derrotados queden alineados con `Marcador`, `Posiciones`, `Desempate` y el detalle por robot. `ffa_match_result_standings_test.gd`, `team_match_result_detail_order_test.gd` y `match_completion_test.gd` fijan ese contrato.
- Cierre Teams ahora tambien mantiene un orden de detalle coherente con el resultado real: `MatchController` ya no deja que `RecapPanel` y `MatchResultPanel` enumeren robots segun scene-order cuando gana el equipo del segundo par; ahora prioriza al equipo que sigue en pie y conserva el orden real de bajas dentro del derrotado. `team_match_result_detail_order_test.gd` fija esa regresion.
- La decision final de FFA ya no usa wording de duelo: cuando el match cierra en libre para todos, `MatchController` ahora anuncia `Player X gana la partida con N punto(s)` y deja el score completo a `Marcador` / `Posiciones`, evitando que un cierre de 4 competidores suene como un `X-Y`; `ffa_match_result_standings_test.gd` cubre `round_status_line`, recap y panel final.
- Cierre FFA ahora mantiene un solo orden legible de principio a fin: el detalle por robot de `RecapPanel` y `MatchResultPanel` ya no sale en scene-order, sino que sigue las posiciones finales reales (ganador primero y empates en el mismo orden del desempate), reutilizando el comparator existente de standings; `ffa_match_result_standings_test.gd` cubre la regresion.
- Apertura FFA todavia mas limpia: `MatchController` ahora tambien oculta `Marcador | ...` mientras la ronda sigue 100% neutral (sin score divergente ni bajas), de modo que score, posiciones y desempate reaparecen juntos solo cuando ya aportan lectura real; `ffa_live_standings_hud_test.gd` y `ffa_live_scoreboard_order_test.gd` fijan ese contrato.
- Desempate FFA mas explicito: `MatchController` ya no deja `Desempate | ...` como nota generica; ahora nombra el score empatado y el orden real dentro de cada empate (`0 pts: Player 3 > Player 2 > Player 1`) tanto en HUD vivo como en recap/resultado final, para que las posiciones no parezcan arbitrarias; `ffa_live_standings_hud_test.gd` y `ffa_match_result_standings_test.gd` fijan ese contrato.
- HUD vivo FFA mas contextual: `MatchController` ahora oculta `Posiciones | ...` y `Desempate | ...` mientras la ronda activa todavia sigue en estado neutral (sin bajas y con score totalmente empatado), y vuelve a mostrarlos apenas hay score divergente o una baja real que aporte ranking; `ffa_live_standings_hud_test.gd` cubre el opening limpio y la reaparicion del ranking cuando ya informa algo.
- Lectura FFA reforzada tambien en el HUD vivo: `MatchController.get_round_state_lines()` ahora publica `Posiciones | ...` y `Desempate | ...` usando los mismos builders del recap/resultado final, de modo que el score actual y el criterio de desempate no quedan ocultos hasta que termina la ronda; `ffa_live_standings_hud_test.gd` fija ese contrato sobre `main_ffa.tscn`.
- Atribucion de bajas entre rondas corregida: `MatchController` ahora limpia el mapa per-round de agresores al resetear ronda, evitando que `RecapPanel` y `MatchResultPanel` hereden un `por Player X` viejo cuando la baja nueva ocurre sin agresor valido; `match_elimination_source_reset_test.gd` deja cubierto ese lifecycle en `main.tscn`.
- Ritmo de apertura reforzado dentro del loop real: `MatchController` ahora inicia cada ronda con un intro corto visible (`Ronda N | arranca en ...`) y no deja avanzar el reloj ni la contraccion hasta que termina; `Main` sincroniza ese estado a `RobotBase`, que bloquea solo movimiento/aim/ataque/skills durante ese beat inicial y ahora lo telegraphia tambien con `RoundIntroIndicator` a ras del piso para acercar el laboratorio al ritmo documentado de `inicio parejo -> analisis -> escalada` sin depender solo del HUD.
- Suite headless restaurada con entrypoint comun: `scripts/tests/test_runner.gd` vuelve a descubrir `*_test.gd` bajo `scripts/tests`, excluye su propio script y ejecuta la bateria completa usando el mismo binario Godot; `test_suite_runner_test.gd` cubre ese contrato para que futuras iteraciones no dependan de loops shell improvisados ni de recordar paths manualmente.
- Teardown del cuerpo inutilizado endurecido: `RobotBase._process()` ahora resincroniza cada frame la visibilidad del `DisabledWarningIndicator` contra el estado real (`_is_disabled/_is_respawning/time_left`), cerrando un stale local que dejaba el mesh marcado como `visible` aunque el robot ya hubiera explotado y quedado oculto para respawn.
- Etapa 0 a 3: base jugable ya integrada en `main.tscn` con arena, camara compartida, empuje, caida al vacio y cierre de ronda simple por ultimo robot/equipo en pie.
- Bootstrap local mas claro: `main.gd` ahora alinea robots con los spawns del arena blockout, asigna slots de jugador y admite 4 jugadores de teclado/slot por defecto para laboratorio 2v2.
- Input local separado: `RobotBase` resuelve perfiles de teclado por slot y deja de leer joysticks "de todos" cuando el robot ya usa teclado.
- Paridad/local Hard mas util: el perfil `WASD` ahora cubre lanzamiento de partes y tambien un camino Hard por teclado (`TFGX` para aim); el HUD expone los controles activos por slot al arranque y el roster los mantiene visibles durante la ronda para no depender de memoria externa en playtests.
- Etapa 2v2: laboratorio 2v2 preparado con 4 robots por escena y `local_player_count=4`, incluyendo equipos por parejas para validar rescate aliado.
- Lectura del retorno modular reforzada y bug scene-level corregido: `RobotBase` ahora suma `RecoveryTargetFloorIndicator` junto al marker alto del dueño, y `_spawn_detached_part()` configura la `DetachedPart` antes de meterla al tree para que el registro de pieza recuperable no se pierda en `main.tscn` durante pickup/throw aliado.
- Primer slice de post-muerte Teams: cuando un robot cae en `Equipos` y aun sobrevive un aliado, `Main` ahora crea una `PilotSupportShip` discreta en el carril externo del arena; usa el input del jugador eliminado, recorre un loop perimetral continuo ligado al borde vivo, esquiva `gates` ligeros que abren/cerran por ventana, recoge pickups `estabilizador` / `energia` / `movilidad` / `interferencia` solo visibles en ese estado y puede estabilizar la parte activa mas dañada, disparar una `energy surge` corta, dar un impulso breve de movilidad sobre el aliado vivo o aplicar una supresion corta a un rival cercano al carril sin activarse en `FFA`.
- Legibilidad del soporte Teams reforzada: la nave post-muerte ahora carga un `StatusBeacon` sobrio sobre el casco; el aro queda siempre visible, y un pulso/acento cambia con `payload` o `interferido` para que el carril externo se lea tambien en mundo y no solo desde el roster compacto.
- Agencia/lectura del soporte Teams reforzadas: la `PilotSupportShip` ahora tambien selecciona objetivo con los mismos inputs secundarios del jugador eliminado (`energy_prev/next`), resume `apoyo <payload> > <objetivo>` en el roster y crea un `SupportTargetIndicator` diegetico sobre el robot apuntado, ahora reforzado por `SupportTargetFloorIndicator` a nivel piso; asi `interferencia` deja de ser una auto-eleccion opaca y el soporte aliado ya tiene un seam claro hacia futuros 3v3/4v4.
- Sincronizacion de cues del soporte endurecida: gastar o cambiar payload/objetivo en `PilotSupportShip` ahora refresca en el acto `SupportTargetIndicator`, `SupportTargetFloorIndicator` e `InterferenceRangeIndicator`, evitando un tick stale entre estado logico y lectura en mundo durante suite headless o reinicios cortos.
- Ciclo de vida del soporte Teams endurecido: `Main` ahora poda la `PilotSupportShip` en cuanto su owner ya no tiene ningun aliado vivo (o deja de estar retenido para reset), limpiando en el mismo frame roster/carril para que el apoyo no quede flotando hasta el reset comun.
- `Interferencia` del soporte Teams ahora telegraphia su radio real con un anillo sobrio sobre el piso, visible solo mientras esa carga esta equipada; reutiliza `support_interference_range` y baja intensidad cuando el objetivo seleccionado aun queda fuera de alcance.
- El roster compacto ahora tambien recuerda los controles de la nave post-muerte (`usa ... | objetivo ...`) usando el perfil real del jugador eliminado; asi el soporte Teams deja de depender de memoria externa durante laboratorio compartido.
- Los `support_lane_gates` ahora tambien anticipan su propio timing con un `TimingVisual` diegetico sobre la compuerta; el fill se vacia segun el tiempo real que falta para abrir/cerrar, evitando que la nave lea la ventana solo por prueba/error o por roster.
- Los pickups del carril post-muerte ya no se agotan para toda la ronda: `PilotSupportPickup` mantiene el pedestal visible, apaga el nucleo al consumirse y repone la carga tras un cooldown corto con `RespawnVisual` diegetico, para que el soporte siga teniendo routing/timing real despues de la primera pasada.
- Los payloads del carril post-muerte ahora tambien se distinguen por silueta en mundo y no solo por color: `PilotSupportPickup` suma `PayloadAccentVisual` runtime con perfiles sobrios por carga (`estabilizador`, `energia`, `movilidad`, `interferencia`) para que jugador eliminado y espectador lean el pickup desde la escena compartida.
- El cierre de partida ya tambien reconoce el aporte del soporte post-muerte Teams dentro de la misma linea `Stats | ...`: pickups/usos de la `PilotSupportShip` se agregan por competidor y ahora desglosan payloads realmente gastados (`apoyo N (M usos: estabilizador 1, energia 1)`), sin sumar otra UI aparte.
- El loop de rescate/negacion ya tambien cierra mejor a nivel telemetria: cuando una `DetachedPart` ajena termina en el vacio por culpa del rival, `MatchController` acredita `negaciones N` en recap/resultado final usando el mismo contrato `recovery_lost`, sin abrir otro panel ni sumar reglas nuevas.
- Laboratorio FFA expuesto: `scenes/main/main_ffa.tscn` ahora hereda el laboratorio principal pero arranca con `MatchMode.FFA`; `Main` neutraliza los `team_id` del layout 2v2 cuando corresponde para que rescate/negacion y scoring traten a cada robot como competidor individual.
- Laboratorio rapido FFA expuesto: `scenes/main/main_ffa_validation.tscn` ahora monta una arena compacta (`arena_ffa_validation.tscn`) con `first-to-1`, rondas de 26s y reinicios cortos, para iterar third-party, oportunismo y pickups de borde sin depender del laboratorio libre mas largo.
- Bootstrap espacial FFA ya diferenciado: ese mismo `Main` ahora reemplaza en `FFA` los spawns cardinales del 2v2 por un layout radial/diagonal mirando al centro, compartido tambien por el path programatico `main.tscn -> match_mode=FFA`, para que el free-for-all no arranque desde lanes de equipo recicladas.
- Roster FFA ahora mas util para oportunismo: `main_ffa.tscn` ya reemplaza los slots de `Grua` y `Cizalla` por `Aguja` y `Ancla`, abriendo poke + control/zona sin romper el laboratorio 2v2 enfocado en rescate aliado.
- Validacion 2v2: el loop de rescate/negacion ya tiene cobertura headless en `main.tscn`, incluyendo indicador de carga visible y ventana de `throw_pickup_delay`.
- Laboratorio rapido de Teams expuesto: `scenes/main/main_teams_validation.tscn` reutiliza el mismo bootstrap, HUD y roster 2v2 pero monta `arena_teams_validation.tscn` mas compacta y `teams_validation_match_config.tres` con `first-to-1`, rondas de 28s y delays cortos, para reproducir rescates, negaciones y cierres con contraccion mas rapido que en el match base.
- Validacion FFA: el prototipo ya cubre headless tanto el bootstrap libre sobre `main.tscn` como la escena dedicada `main_ffa.tscn`, incluyendo neutralizacion de alianzas, layout radial propio, cierre de ronda individual y una linea de estado que deja visible si el laboratorio actual corre en `FFA` o `Equipos`.
- Scoreboard minimo: `MatchController` ya registra bajas por vacio, explosion o `explosion inestable`, suma ronda al ultimo contendiente en pie y reinicia todos los robots juntos tras una pausa corta.
- Cierre de match base: el laboratorio ya juega a first-to-3 por defecto; cuando un equipo alcanza el objetivo, `MatchController` anuncia ganador de partida, congela la ronda y reinicia el match completo tras una pausa corta.
- Resumen compacto de cierre: cuando la ronda termina, `MatchController` conserva `Resumen | ...` con el orden real de bajas hasta que arranca la siguiente, reforzando el “como perdi” sin abrir una pantalla de post-ronda aparte.
- Presion de endgame: el `arena_blockout` ahora reduce progresivamente su tamano durante la ronda, empujando el cierre hacia el centro sin agregar hazards extra.
- Telegraph diegetico de cierre: esa misma contraccion ahora deja cuatro bandas sobrias sobre el piso, pegadas al borde vivo y visibles solo mientras la arena se achica, para anunciar la presion espacial sin cargar mas el HUD ni ensuciar el centro.
- Bordes con incentivo real: el laboratorio ahora suma pickups de reparacion instantanea en los flancos del arena; curan la parte activa mas dañada sin revivir piezas perdidas, fuerzan a exponerse cerca del vacio y ahora se recolocan con la misma escala del area segura para no quedar fuera del borde vivo durante la contraccion.
- Incentivo universal de movilidad: el mismo arena ahora suma pickups de impulso en norte/sur; activan una ventana corta de traccion/control reforzados, se leen con glow turquesa sobre el robot y se recolocan con la misma logica de borde vivo para no convertirse en “premios muertos” durante la contraccion.
- Incentivo universal de energia: el arena ahora suma pickups de recarga en diagonales; cortan la recuperacion post-overdrive, refuerzan por una ventana corta el par energetico seleccionado y reutilizan el mismo contrato de pedestal/cooldown visible + seguimiento del borde vivo.
- Incentivo universal de utility: el arena ahora suma pickups de `estabilidad`; limpian `zona`/`interferencia`, bloquean nuevas supresiones por una ventana corta y reducen un poco el impulso externo recibido para que el borde tenga tambien una respuesta anti-control sin meter otra capa ofensiva.
- Lectura diegética del contrajuego de control reforzada: `RobotBase` ahora monta un `StatusEffectIndicator` chico sobre el torso; se enciende en verde agua durante `estabilidad` y en naranja cuando `Baliza/interferencia` realmente suprimen al robot, evitando depender solo del roster para leer ese intercambio.
- Primer item de una carga en mano: el arena ahora suma pickups de pulso en las diagonales restantes; guardan una carga visible en el robot, comparten slot con las partes cargadas y convierten el siguiente ataque en un disparo repulsor corto y legible.
- Primer pickup de municion/carga real: el arena ahora tambien puede habilitar celdas de municion de skill que recargan una carga propia sobre `Aguja`, `Ancla` o `Grua`; el laboratorio 2v2 base las mantiene apagadas mientras solo un equipo tenga skills propias y el laboratorio FFA las habilita cuando ya hay suficiente disputa real por ese recurso.
- Skill propia de rescate en 2v2: `Grua` ahora usa `Iman`, una captura magnetica de partes listas dentro de un rango medio que prioriza piezas propias/aliadas, reutiliza el mismo slot de carga y deja `skill Iman x/y` visible en el roster sin abrir otra UI.
- Skill propia de impacto para tanque/pusher: `Ariete` ahora usa `Embestida`, una ventana corta de drive/impacto/estabilidad que se activa desde `throw_part`, reutiliza los mismos multiplicadores del robot y deja `skill Embestida x/y` + estado `embestida` visibles en el roster sin proyectiles nuevos.
- Skill propia de movilidad para reposition: `Patin` ahora usa `Derrape`, una rafaga corta de reposicion que reaprovecha el mismo pipeline de movimiento del robot, mete desplazamiento inmediato en la direccion actual y deja `skill Derrape x/y` + estado `derrape` visibles en el roster sin abrir otra capa visual.
- Pasiva de `Cizalla` ahora tambien se lee cuando conecta de verdad: al castigar una pieza ya tocada, `RobotBase` dispara un cue corto `corte` en roster y sube un pulso breve sobre `ArchetypeAccent`, para que el rol dismantler no dependa solo de numeros invisibles.
- Esa misma lectura de `Cizalla` ahora tambien aterriza sobre la victima: la extremidad castigada abre un `DismantleCue` corto dentro del mismo `DamageFeedback`, dejando claro en cuerpo cual fue la pieza realmente castigada sin sumar HUD nuevo.
- Primera skill propia por arquetipo: `Aguja` ya reutiliza `PulseBolt` como `Pulso` con 2 cargas recargables, activadas desde la accion de utilidad (`throw_part`) cuando no lleva una parte; el roster la deja visible como `skill Pulso x/y`.
- La cobertura headless de `Pulso` ahora tambien comprueba que el proyectil temporal exista y no nazca solapado con el robot origen, reforzando el contrato fisico minimo del arquetipo Poke/Skillshot.
- Sexto arquetipo base integrado: `Ancla` ya expone `Baliza`, una skill propia de Control/Zona que despliega una sola baliza activa por robot, ralentiza rivales dentro del area y deja el estado `zona` visible en el roster sin abrir otra UI.
- Rotacion semialeatoria controlada de edge pickups: el laboratorio ya no deja todos los incentivos activos a la vez; `ArenaBase` ahora usa perfiles por modo, manteniendo en `Equipos` un mazo seedado de cruces entre `repair/energy` y `mobility/pulse/utility/charge`, mientras `FFA` puede abrir layouts `3-de-6` con `pulso`, `estabilidad` y `municion` cuando el laboratorio libre ya tiene varias skills propias compitiendo por esos recursos.
- Cobertura de borde minima: el `arena_blockout` ya suma dos slabs estaticos simples junto a los pickups de reparacion; se desplazan con la contraccion del mapa para mantener duel zones legibles y no dejar geometria “flotando” fuera del area viva.
- Etapa 4: parcialmente implementada. El robot ya recibe danio modular por direccion de impacto, pierde brazos o piernas visualmente, desprende piezas y cambia su rendimiento segun las partes restantes.
- Legibilidad modular reforzada: las partes dañadas ahora levantan marcadores sobrios sobre el propio robot (`Smoke` en daño relevante, `Spark` en daño critico) y tambien aflojan su pose (`brazo caido`, `pierna arrastrando`) para que el desgaste se lea en el cuerpo antes que en el HUD; todo se limpia al reparar o desprender la pieza.
- Etapa 2 y 3: el ritmo de choque del laboratorio 2P ya fue afinado en `RobotBase` para que los intercambios sean más fluidos sin perder el carácter de choque decisivo.
- Etapa 5: primer slice funcional implementado. Cada robot ahora puede redistribuir energia hacia una parte foco, alterar de forma real el empuje o la traccion y activar un overdrive corto con recuperacion/cooldown.
- Lectura diegética de energía reforzada: `RobotBase` ahora monta `EnergyFocusIndicator` sobre la pareja activa (`brazos` o `piernas`), deja la parte exacta del foco mas intensa y vuelve mas caliente la lectura si entra en `Overdrive`, para que la decision tactica tambien se vea sobre el cuerpo.
- Riesgo/recompensa de overdrive mas cerrada: si un robot pierde su ultima parte mientras el `Overdrive` sigue activo, su cuerpo inutilizado conserva esa condicion y la explosion diferida escala `radio/empuje/daño`, con lectura `inestable` en roster + resumen de baja.
- Lectura del cuerpo inutilizado reforzada: ademas del roster, `RobotBase` ahora dibuja un anillo diegetico sobre la arena con el radio real de la explosion pendiente; la variante `inestable` crece con el mismo multiplicador del gameplay para que la amenaza se lea en mundo antes del estallido.
- Etapa 6: soporte base implementado. `RobotBase` ya puede separar torso y chasis con `UpperBodyPivot`, usando esa orientacion para lectura de impactos y ataque en `ControlMode.HARD`; el soporte actual es joypad-first y no reemplaza el loop Easy por defecto.
- Laboratorio Hard expuesto: `Main` ya puede asignar `ControlMode.HARD` por slot local mediante `hard_mode_player_slots`, y el roster deja visible si cada robot juega en Easy o Hard junto al hint real de input.
- Selector runtime de laboratorio listo: `Main` ahora deja ciclar slot/arquetipo/modo con `F2/F3/F4`, reaplica el `RobotArchetypeConfig` sobre el robot activo, reinicia el match completo y mantiene sincronizados el roster, la linea `Lab | ...`, el marcador FFA y un `LabSelectionIndicator` diegético sobre el robot elegido sin editar escenas.
- Navegacion runtime entre laboratorios expuesta: ese mismo `Main` ahora tambien cicla con `F6` entre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`, dejando `Escena | ...` visible en el HUD para no depender del editor al saltar entre Teams/FFA o entre laboratorios base/rapidos.
- El selector runtime ya no se pierde al usar `F6`: `Main` ahora guarda en sesion el slot elegido, los overrides `Easy/Hard`, el `RobotArchetypeConfig` activo por jugador y tambien el HUD activo (`explicito/contextual`) antes del cambio de escena, y lo reaplica al boot del siguiente laboratorio para comparar Teams/FFA o base/rapido sin rearmar manualmente el setup.
- Etapa 7: base funcional implementada. Las partes desprendidas ya conservan propietario, pueden recogerse por cercania, bloquear el ataque mientras se cargan y volver con vida parcial; si el portador cae al vacio, la parte se niega.
- Rescate modular mas legible: cada parte desprendida ahora muestra un disco diegetico sobre el suelo que se achica segun su `cleanup_time`, haciendo visible la ventana de recuperacion sin abrir otra banda de HUD.
- Objetivo de retorno mas legible: el robot que todavia puede recibir una pieza propia ahora muestra `RecoveryTargetIndicator`, un disco sobrio sobre el chasis que aparece mientras exista al menos una parte recuperable asociada y se apaga cuando la pieza vuelve o se pierde.
- Transporte de partes mas legible: cuando una `DetachedPart` ya va en manos de otro robot, `CarryIndicator` sigue marcando el tipo de pieza y ahora suma `CarryOwnerIndicator`, un aro fino con el color del dueño original para no perder contexto de rescate/negacion durante el traslado.
- Retorno del transporte mas legible: ese mismo portador ahora tambien muestra `CarryReturnIndicator`, una aguja corta que apunta al robot dueño de la pieza para que el handoff se lea aun cuando ambos robots ya estan en movimiento.
- Entrega de rescate ahora telegraphiada: cuando el portador entra al radio real de retorno, `CarryReturnIndicator` se intensifica y el `RecoveryTargetFloorIndicator` del dueño tambien responde, para que el momento de handoff deje de depender solo de estimar distancia.
- Robot inutilizado: ahora entra en una cuenta regresiva corta, explota con empuje/danio radial y, si eso cierra la ronda, queda fuera hasta el reset comun; la variante nacida desde `Overdrive` queda marcada como explosion `inestable`.
- Etapa 8: ya existe una mezcla mas honesta entre pasivas y primeras skills propias. `RobotArchetypeConfig` sigue reutilizando hooks legibles para `Cizalla`, y ahora tambien puede declarar `core_skill_type/label/cargas/recarga` + una ventana activa corta para skills de buff; `Ariete` suma `Embestida` como refuerzo de impacto/estabilidad en el laboratorio 2v2, `Grua` suma `Iman` como captura de recuperacion, `Patin` suma `Derrape` como reposicion corta dentro del mismo sistema de movimiento, `Aguja` abre el arquetipo Poke/Skillshot con `Pulso` recargable y `Ancla` suma Control/Zona con `Baliza` persistente dentro del laboratorio FFA sin duplicar la escena del robot.
- Lectura de skill propia reforzada: las `CoreLight` del robot ahora laten suavemente mientras queden cargas de skill; en `Aguja` esa pista corporal separa `Pulso` listo del `pulse_charge` de borde, que sigue usando solo el `CarryIndicator` dorado.
- Lectura de skill propia reforzada tambien sobre el rol: `ArchetypeAccent` ahora acompaña esa misma disponibilidad con un pulso/emision sutil segun la skill propia del arquetipo, y sube un escalon extra durante ventanas activas como `Embestida`, para que la lectura no dependa solo del core.
- Lectura visual: sigue sobria y funcional. El prototipo usa desgaste por materiales, partes ocultas/desprendidas, marcadores de humo/chispa por parte dañada, poses flojas por extremidad castigada, mensajes breves, foco energetico visible en core + extremidades activas y un HUD compacto con marcador de ronda + roster por robot para leer estado/carga/energia sin HUD pesado.
- Identidad visual en mundo reforzada: cada robot ahora reutiliza `FacingMarker` + `CoreLight` como acento ligero por equipo/jugador, y las partes desprendidas suman un aro fino de pertenencia ademas del disco de recuperacion; asi rescate/negacion y lectura FFA ganan contexto sin otra capa de HUD.
- Lectura de arquetipo reforzada en el propio cuerpo: `RobotArchetypeConfig` ahora tambien define `accent_style/accent_color`, y `RobotBase` monta un `ArchetypeAccent` runtime sobre `UpperBodyPivot` con siluetas chicas por rol (`Ariete` bumper, `Grua` mastil, `Cizalla` cuchillas, `Patin` aleta, `Aguja` pua, `Ancla` halo) para que el laboratorio no dependa solo del roster al distinguir funciones.
- HUD dual base: `MatchConfig` ya deja alternar entre un modo `explicito` (mantiene `Modo`, `Objetivo`, hints de control, `4/4 partes` y `Eq` siempre visibles) y un modo `contextual` que oculta esa informacion estable y solo vuelve a exponer daño, foco energetico, buffs, items y cargas cuando realmente importan.
- Toggle runtime del HUD listo: `Main` ya puede ciclar ese mismo HUD dual con `F1` durante playtests locales usando un override de sesion en `MatchController`, sin mutar el `MatchConfig` compartido ni alterar el default de escenas nuevas.
- Lectura de borde reforzada: el mismo HUD compacto ahora añade `Borde | ...` con los tipos activos de pickup de la ronda para que el layout semialeatorio sea legible en playtests sin abrir otra capa de UI.
- Lectura en mundo de pickups de borde reforzada: los seis `edge pickups` ahora tambien cargan un `Accent` propio en la escena (`repair`, `mobility`, `energy`, `pulse`, `charge`, `utility`) para que la rotacion semialeatoria no dependa solo del color del nucleo y siga leyendose aun durante cooldown.
- Lectura de eliminacion reforzada: el roster ahora deja visible `Inutilizado | explota Xs` y tambien `Inutilizado | inestable | explota Xs` cuando la baja viene de overdrive; tras la explosion conserva `Fuera | vacio/explosion/explosion inestable`, el bloque superior mantiene `Ultima baja | ...` y, cuando la ronda ya cerro, añade `Resumen | ...` con el orden de bajas para explicar por que se perdio una pieza clave sin sumar otra capa de UI.
- Atribucion de bajas reforzada sobre la misma telemetria: `RobotBase` ahora recuerda por una ventana corta quien aplico el ultimo empuje/daño relevante, y `Main` + `MatchController` lo traducen en texto `... por Player X` dentro de `Ultima baja`, `Resumen | ...`, `RecapPanel` y `MatchResultPanel`, evitando otro panel o feed de combate separado.
- Snippets compactos de cierre ya integrados: ese mismo `MatchController` ahora reutiliza el primer y ultimo resumen completo de eliminacion para exponer `Momento inicial | ...` / `Momento final | ...` en `RecapPanel` y `MatchResultPanel`, acercando el cierre a los “replay snippets” documentados sin grabar replay real ni abrir otra UI.
- Recap de cierre mas explicito: cuando la ronda o partida ya cerraron, `MatchHud` ahora abre un `RecapPanel` lateral con `Decision`, `Marcador` y un estado final por robot (`sigue en pie` o `baja N | causa`), ocultandose otra vez al iniciar la siguiente ronda para no contaminar el combate activo.
- Cierre de partida mas legible: cuando el match termina, el HUD ahora suma un `MatchResultPanel` centrado con `Partida cerrada`, ganador, marcador final, `Stats | Equipo ...` (rescates, borde, partes perdidas por tipo y bajas sufridas por causa) y `Reinicio | F5 ahora o Xs`; el `RecapPanel` lateral queda como detalle secundario y el laboratorio puede reiniciarse de inmediato sin esperar todo el countdown.
- El panel final centrado ya tambien sostiene mejor el “como perdi”: `MatchResultPanel` ahora repite el detalle compacto por robot (`Player X | baja N | causa`) reutilizando la misma linea del recap lateral, para que la vista mas visible del cierre no dependa de leer dos paneles a la vez.
- Ese mismo detalle por robot ahora tambien resume el estado final de extremidades (`3/4 partes | sin brazo izquierdo`, etc.) tanto en `RecapPanel` como en `MatchResultPanel`, para explicar mejor en que condicion sobrevivio o cayo cada competidor sin abrir otro panel.
- Cierre FFA mejor explicado: ese mismo recap/resultado final ahora agrega `Posiciones | 1. ...` solo en `FFA`, ordenando por score del match y desempate por el orden real de salida de la ronda final para que supervivencia y oportunismo cierren con un ranking legible sin otra pantalla; cuando el score queda empatado, suma una linea `Desempate | ...` para explicitar ese criterio sin abrir otra UI.
- Lectura competitiva FFA reforzada tambien durante la ronda activa: `MatchController._build_score_summary_line()` ya no deja el `Marcador | ...` en el orden fijo de la escena; en `FFA` reutiliza el mismo comparator de standings para subir primero al lider real y dejar que score/desempate se lean mientras la partida sigue viva, no solo en el recap final.
- Negacion de partes: ahora existe negacion activa; un jugador con parte en mano puede lanzarla para cortar el rescate oportuno y crear decisiones de riesgo.
- Pendiente prioritario: playtestear si `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y ahora `Ancla` ya se sienten realmente distintos con esta mezcla de tuning + pasivas + primeras skills propias, ahora que el selector runtime permite cruzarlos sin editar escenas ni rearmar el setup al saltar con `F6`; en paralelo medir si `F2/F3/F4` + la linea `Lab | ...` + `LabSelectionIndicator` alcanzan como flujo de laboratorio o si la siguiente capa debe ser presets visibles/limpieza manual de setup, si la nueva lectura de daño modular realmente se entiende en cámara compartida sin agregar ruido, si el nuevo combo de identidad/arquetipo (`FacingMarker/CoreLight` + `ArchetypeAccent` + aro de pertenencia sobre piezas sueltas + `StatusEffectIndicator` para `estabilidad/zona`) alcanza para distinguir aliados/rivales/rol/propietario/estado de control sin ensuciar la pelea, si el HUD `explicito/contextual` limpia la pantalla sin esconder decisiones tacticas y cual deberia ser el default en `Equipos` y `FFA`, si la explicacion de bajas actual (`Ultima baja`, `Resumen | ...`, `Momento inicial/final`, `Fuera | vacio/explosion/explosion inestable`, `Inutilizado | explota/inestable`, `Stats | Equipo ...` con partes perdidas y estado final `N/4 partes | sin ...`, `RecapPanel` y `MatchResultPanel`) alcanza para cerrar ronda/partida sin otra pantalla, si la rotacion semialeatoria controlada de edge pickups vuelve los bordes más tácticos sin transformarlos en zonas seguras permanentes y si el nuevo pickup de `estabilidad` da contrajuego suficiente a `Baliza`/`interferencia` sin volverse un seguro defensivo demasiado dominante; en paralelo confirmar si el first-to-3 + reinicio automatico/manual con `F5` deja buen ritmo, si la explosion inestable vuelve el overdrive mas tenso sin volverse dominante y si el nuevo conflicto `parte vs item/skill` sigue siendo claro cuando los rounds ya importan de verdad.

## Principios de orden

- Primero se valida sensacion fisica: movimiento, derrape, choque y lectura visual.
- Despues se agregan consecuencias: bordes letales, empuje, danio modular y perdida de partes.
- Luego se agregan decisiones tacticas: energia, overdrive, recuperacion, items y skills.
- Finalmente se consolidan modos, mapas, UI, postpartida y contenido.
- Cada etapa debe poder probarse en Godot con pocos elementos en pantalla y reglas claras.

## Etapa 0 - Base tecnica jugable

**Objetivo:** crear una base Godot simple, modular y facil de entender para iterar mecanicas sin rehacer escenas cada vez.

**Sistemas involucrados:**
- escena principal de arena
- escena de robot reusable
- entrada local para 2 a 4 jugadores iniciales
- camara compartida casi cenital
- capas de colision
- configuracion basica de debug

**Criterio de exito:**
- se puede iniciar una escena de prueba con al menos dos robots controlables
- cada robot usa una escena instanciable, no codigo duplicado
- la camara mantiene legibles a los jugadores
- el proyecto sigue siendo entendible para una persona con poca experiencia programando

**Riesgos tecnicos:**
- acoplar demasiado pronto escena, control y reglas de partida
- construir una arquitectura demasiado abstracta antes de saber que fisica funciona
- perder legibilidad si la camara o escala de robots se decide tarde

**Dependencias:** ninguna. Es la base para todo lo demas.

## Etapa 1 - Movimiento con inercia y control Easy

**Objetivo:** validar la sensacion principal: robot pesado al arrancar, mas libre al deslizar y orientado en la direccion de movimiento.

**Sistemas involucrados:**
- controlador de movimiento top-down
- aceleracion, freno, derrape e inercia
- orientacion automatica del cuerpo
- friccion o amortiguacion ajustable por superficie
- animacion/feedback minimo de velocidad y peso

**Criterio de exito:**
- mover el robot ya se siente como patinar, no como caminar
- hay diferencia clara entre arrancar, deslizar, corregir y frenar
- el control Easy funciona sin exigir punteria independiente
- un jugador puede perseguir, esquivar y preparar una embestida solo con movimiento

**Riesgos tecnicos:**
- que la fisica se sienta flotante en lugar de pesada
- que el control sea demasiado resbaloso para jugadores nuevos
- que las correcciones pequenas no sean lo bastante precisas para preparar choques

**Dependencias:** Etapa 0.

## Etapa 2 - Choques, empuje y lectura del impacto

**Objetivo:** hacer que el contacto entre robots sea especial, legible y decisivo cuando esta bien preparado.

**Sistemas involucrados:**
- deteccion de impactos entre robots
- calculo de impulso segun velocidad, masa y direccion
- reaccion fisica al choque
- feedback audiovisual sobrio para impactos fuertes
- debug de magnitud y direccion de impacto

**Criterio de exito:**
- una embestida preparada empuja de forma clara y satisfactoria
- contactos debiles no ensucian la partida ni parecen igual de importantes
- se entiende quien golpeo, desde donde y con que fuerza
- el loop "tanteo, reposicionamiento, choque decisivo" aparece aunque solo haya dos robots

**Riesgos tecnicos:**
- spam de colisiones si todos los contactos generan efectos fuertes
- empujes inconsistentes por resolucion de fisica
- robots trabados o girando sin control despues del impacto

**Dependencias:** Etapa 1.

## Etapa 3 - Arena flotante, bordes letales y cierre de ronda

**Objetivo:** convertir el movimiento y los choques en una condicion de eliminacion central: sacar rivales de la plataforma.

**Sistemas involucrados:**
- arena flotante con borde letal
- deteccion de salida del mapa
- reset o cierre de ronda
- spawn inicial equilibrado
- camara compartida adaptada a bordes

**Criterio de exito:**
- empujar al rival fuera de la arena es posible, claro y emocionante
- el centro sirve para reposicionarse, pero los bordes son tentadores y peligrosos
- una ronda corta de 2 a 4 jugadores ya produce momentos de lectura y castigo
- perder por caida se siente entendible, no arbitrario

**Riesgos tecnicos:**
- bordes demasiado letales que corten las partidas antes de que exista historia
- bordes demasiado seguros que reduzcan la tension
- camara que esconda el peligro o saque jugadores de foco

**Dependencias:** Etapas 1 y 2.

**Estado actual del prototipo:**
- el vacio ya elimina al robot de la ronda actual
- el ultimo robot/equipo en pie suma una ronda
- el HUD minimo ya muestra ronda y marcador, sin sumar barras pesadas
- en modo explicito, el HUD tambien deja visible el objetivo del match (`Primero a X`) y el loop ya cierra la partida al alcanzarlo
- el arena ahora se contrae progresivamente en el tramo final de la ronda y vuelve a escala completa al reset
- el piso ahora acompaña esa contraccion con bandas sobrias sobre los cuatro bordes vivos; se apagan fuera del cierre y se reescalan con el area segura para mantener el centro limpio
- el arena blockout ahora ofrece ocho pedestales de borde, pero solo activa dos pares espejados por ronda mediante una rotacion semialeatoria controlada entre reparacion, movilidad, energia y pulso
- pendiente: decidir si el reinicio automatico debe seguir conviviendo con `F5` como fallback del laboratorio o si conviene migrar a un cierre manual-only mas adelante, y si el perfil actual de score por causa (`ring_out=2`, `destruccion total=1`, `explosion inestable=4`) necesita retocarse por modo o solo mejor feedback

## Etapa 4 - Danio modular por brazos y piernas

**Objetivo:** agregar la segunda ruta de victoria: desarmar estrategicamente al robot rival sin quitarle toda posibilidad de remontada.

**Sistemas involucrados:**
- cuatro partes con vida propia: brazo izquierdo, brazo derecho, pierna izquierda, pierna derecha
- asignacion de danio segun lado del impacto y orientacion
- degradacion funcional por parte daniada
- visualizacion directa de danio en el robot
- estado de robot torpe pero todavia jugable

**Criterio de exito:**
- romper una pierna cambia el movimiento de forma notoria pero no termina automaticamente la pelea
- romper un brazo reduce dominio ofensivo o fuerza de empuje
- el jugador entiende que parte esta daniada mirando al robot, no solo al HUD
- aparece la jugada de "romper una parte y luego rematar"

**Riesgos tecnicos:**
- que el danio por impacto sea dificil de atribuir de forma justa
- que perder partes genere una espiral sin vuelta
- que los indicadores visuales no sean claros en pantalla compartida

**Dependencias:** Etapas 1 y 2. Funciona mejor despues de Etapa 3, pero puede prototiparse en una arena cerrada.

## Etapa 5 - Energia, redistribucion y Overdrive

**Objetivo:** sumar decisiones tacticas antes del choque: invertir energia en brazos, piernas o una apuesta riesgosa de Overdrive.

**Sistemas involucrados:**
- reserva total de energia del robot
- distribucion por cuatro partes
- modificadores para piernas: velocidad, control de deslizamiento, inercia
- modificadores para brazos: empuje y dominio cercano
- interfaz de redistribucion legible
- Overdrive por parte con penalizacion o sobrecalentamiento

**Criterio de exito:**
- redistribuir energia cambia una pelea de manera perceptible
- no conviene spamear redistribucion
- Overdrive crea una ventana fuerte, riesgosa y reconocible
- el sistema funciona en Easy sin exigir control avanzado

**Riesgos tecnicos:**
- demasiados parametros simultaneos para balancear
- UI invasiva o dificil de leer durante el combate
- Overdrive dominante que convierta todo en burst sin lectura previa

**Dependencias:** Etapas 1, 2 y 4.

## Etapa 6 - Control Hard y torso independiente

**Objetivo:** habilitar profundidad tecnica sin hacer que el juego dependa de ella.

**Sistemas involucrados:**
- stick izquierdo para movimiento
- stick derecho para torso superior
- orientacion independiente de torso
- relacion entre torso, direccion de ataque y parte impactada
- alternancia de modo Easy/Hard por jugador

**Criterio de exito:**
- Hard permite apuntar mejor ataques, defensas y skillshots
- Easy sigue siendo competitivo y legible
- la orientacion del torso ayuda a leer intencion sin confundir la direccion de movimiento
- el sistema no rompe la atribucion de danio modular

**Riesgos tecnicos:**
- que Hard sea tan superior que Easy parezca modo de castigo
- que el cuerpo del robot sea dificil de leer en camara cenital
- que los controles se vuelvan confusos en partidas locales con varios jugadores

**Dependencias:** Etapas 1, 2 y 4. Conviene hacerlo despues de que Easy ya sea divertido.

**Estado actual del prototipo:**
- el torso superior ya puede orientarse por separado del chasis usando `UpperBodyPivot`
- la direccion de combate/impacto modular en Hard ya se lee desde ese torso, no desde el chasis completo
- el soporte actual sigue siendo mayormente joypad-first, pero `RobotBase` ya ofrece tres caminos Hard por teclado en laboratorio: `WASD + TFGX`, `flechas + Ins/Del/PgUp/PgDn` y `numpad + KP7/KP9/KP//KP*`
- `Main` ya puede forzar slots concretos a Hard desde `hard_mode_player_slots`; el HUD deja visible el mapping activo por slot al inicio y el roster lo mantiene visible durante la ronda
- `IJKL` sigue explicitamente joypad-first hasta que playtests reales justifiquen reabrir un cuarto mapping o sumar un flujo local mas guiado

## Etapa 7 - Partes desprendidas, recuperacion y cuerpo averiado

**Objetivo:** convertir la destruccion modular en juego de posicionamiento, rescate y negacion.

**Sistemas involucrados:**
- partes destruidas como objetos fisicos en la arena
- pickup simple por contacto o cercania
- transporte de partes
- bloqueo de skills al cargar una parte
- devolucion a robot original con vida parcial
- negacion enemiga arrojando partes al vacio
- robot inutilizado al perder las cuatro partes
- explosion diferida del cuerpo averiado

**Criterio de exito:**
- recuperar una parte aliada se siente valioso y posible
- negar una parte enemiga crea presion sin reemplazar el combate principal
- el cuerpo averiado explosivo genera momentos especiales, no ruido constante
- la partida conserva claridad aunque haya partes sueltas

**Riesgos tecnicos:**
- acumulacion de cuerpos y partes que ensucie fisica y pantalla
- rescates demasiado faciles o demasiado imposibles
- explosion demasiado frecuente o demasiado fuerte
- reglas de pertenencia de partes confusas

**Dependencias:** Etapas 3 y 4. La explosion tambien depende de Etapa 2 para empuje radial.

**Estado actual del prototipo:**
- partes desprendidas con propietario original y retorno parcial
- pickup por cercania sin input extra
- transporte que bloquea el ataque prototipo
- negacion basica si el portador cae al vacio o lanza la parte fuera del contexto inmediato
- cuerpo inutilizado con explosion diferida; si la explosion cierra la ronda, el robot espera el reset comun
- feedback visual de transporte implementado con indicador diegetico en `RobotBase`
- las partes tiradas ahora muestran una ventana de recuperacion diegetica sobre el suelo y exponen un hook `recovery_lost` para futuras lecturas compactas si hace falta
- la ventana de `DetachedPart` ahora se drena en script mientras la pieza sigue en el piso, se pausa al cargarla y se reanuda al volver a lanzarla, evitando que frames de setup o un lift-and-drop regalen/consuman tiempo de recuperacion por fuera del gameplay
- pendiente: validar por playtest si el combo `disco de recuperacion + aro de pertenencia + RecoveryTargetIndicator + CarryOwnerIndicator + CarryReturnIndicator` ya alcanza para rescate cooperativo en sesiones activas o si todavia falta reforzar radio de retorno/timer de negación en 2v2 con la nueva presión de ronda

## Etapa 8 - Primeros arquetipos jugables

**Objetivo:** demostrar que los sistemas soportan identidades distintas sin borrar el nucleo de choques.

**Sistemas involucrados:**
- seleccion simple de robot
- parametros por arquetipo
- una skill o regla distintiva por robot inicial
- recursos de skill: cargas, ammo o energia segun corresponda
- balance basico para FFA y Team vs Team

**Contenido recomendado inicial:**
- Empujador/Tanque para probar masa, brazos y control del borde
- Movilidad/Reposition para probar derrape, escapes y rutas
- Desarmador para probar danio modular intencional
- Asistencia/Recuperacion para probar rescates y utilidad en equipos sin quedar inutil en FFA

**Criterio de exito:**
- cada robot se reconoce por lo que intenta hacer en pelea
- ninguno depende exclusivamente de coordinacion perfecta para ser divertido
- las skills no tapan el combate cuerpo a cuerpo
- el Pusher gana por impacto, el Desarmador por desgaste y el Movilidad por posicionamiento

**Riesgos tecnicos:**
- arquetipos borrosos si todos comparten demasiados valores
- skills mas fuertes que el choque
- roles de soporte inutiles en FFA
- balance prematuro sobre valores que todavia estan cambiando

**Dependencias:** Etapas 1 a 7. Puede empezar con 3 arquetipos si el costo de contenido frena la iteracion.

**Estado actual del prototipo:**
- el laboratorio 4P ya arranca con cuatro identidades legibles construidas sobre tuning existente + pasivas chicas:
  - `Ariete`: mas aguante/empuje y tambien mas resistencia al impulso externo
  - `Grua`: mejor rescate/retorno de partes, estabiliza otra pieza dañada cuando completa un retorno y ahora usa `Iman` para capturar una parte lista fuera del pickup normal sin sumar otro boton
  - `Cizalla`: mas daño directo/modular y bonus adicional contra piezas ya tocadas
  - `Patin`: mas velocidad/derrape y ahora `Derrape`, una rafaga corta de reposicion que aprovecha la direccion actual del robot sin meter otro proyectil o hazard
- el laboratorio FFA ya abre un quinto sabor sin tocar el 2v2 base:
  - `Aguja`: usa `Pulso` con 2 cargas recargables sobre la accion `throw_part` cuando no lleva partes, reutilizando `PulseBolt` para validar poke/skillshot legible y de baja saturacion
- el laboratorio FFA ya abre un sexto sabor sin tocar el 2v2 base:
  - `Ancla`: usa `Baliza` para desplegar una sola zona persistente por robot, ralentiza drive/control de rivales dentro del area y deja `zona` visible en el roster cuando alguien queda atrapado
- `RobotArchetypeConfig` deja esos presets en recursos `.tres`, y `RobotBase` los aplica antes de resetear salud/energia o al resolver `apply_impulse`, retornos, daño modular y boosts temporales para mantener el setup editable por un principiante sin duplicar escenas
- el roster compacto ya usa `Player X / <Arquetipo>` y ahora tambien puede sumar `skill Embestida/Iman/Derrape/Pulso/Baliza x/y`, mientras el marcador FFA sigue agregando `[<Arquetipo>]` sin romper la UI actual
- pendiente: decidir via playtest si la combinacion actual (`Embestida` para `Ariete`, `Iman` para `Grua`, pasiva fuerte para `Cizalla`, `Derrape` para `Patin`, `Pulso` para `Aguja`, `Baliza` para `Ancla`) ya alcanza o si la siguiente diferenciacion debe venir por selector runtime, mas reglas visibles por arquetipo o una economia de ammo mas expresiva

## Etapa 9 - Items, skills universales y economia de recursos

**Objetivo:** agregar oportunidades tacticas de mapa sin romper la claridad ni transformar el juego en spam de efectos.

**Sistemas involucrados:**
- inventario de un solo item
- spawns semialeatorios
- items de municion/carga, movilidad, reparacion, energia y utilidad
- telegraph visual claro
- reglas de rareza y valor cerca de bordes
- limpieza de items y partes viejas

**Criterio de exito:**
- los items son pocos, importantes y faciles de reconocer
- los bordes se vuelven mas tentadores sin volverse zonas dominadas permanentemente
- una skill bien usada puede definir una jugada, pero no reemplaza una embestida bien ejecutada
- cargar una parte y cargar un item generan decisiones incompatibles interesantes

**Riesgos tecnicos:**
- ruido visual por demasiados pickups o efectos
- ventaja aleatoria excesiva
- items de movilidad que rompan bordes letales
- reparacion que alargue partidas sin tension

**Estado actual del prototipo:**
- existe un primer slice previo al sistema completo de items: ocho pedestales simetricos en el `arena_blockout`, con rotacion semialeatoria controlada para dejar solo dos pares activos por ronda
- ya existe un primer item de una sola carga en mano: `pulse_charge`, que vive en pickups de borde, comparte slot visual/logico con las partes cargadas y convierte el siguiente ataque en un pulso repulsor corto
- reparacion cura solo la parte activa mas dañada y no reemplaza la devolucion de partes destruidas
- movilidad refuerza traccion/control por una ventana corta; energia corta recuperacion post-overdrive y refuerza temporalmente el par energetico seleccionado
- todavia no hay inventario completo, rareza ni pesos por modo/mapa; la semialeatoriedad actual vive en un mazo controlado por seed y queda pendiente medir si la incompatibilidad `parte vs pulso` alcanza o si hace falta una capa de inventario mas explicita

**Dependencias:** Etapas 3, 5, 7 y 8.

## Etapa 10 - Mapas, ritmo de partida y presion final

**Objetivo:** pasar de una arena de prueba a mapas con lectura, rutas, bordes valiosos y final explosivo.

**Sistemas involucrados:**
- layout de centro abierto
- bordes con valor y riesgo
- coberturas
- rutas de reposicionamiento
- trampas opcionales por mapa
- reduccion progresiva de espacio jugable
- reglas de spawn por modo

**Criterio de exito:**
- el centro sirve para escapar, leer y reposicionarse
- los bordes generan duelos tensos y jugadas de castigo
- las coberturas permiten pausa, emboscada y recuperacion sin frenar la partida
- el cierre progresivo evita finales estancados

**Riesgos tecnicos:**
- mapas que favorezcan demasiado a un arquetipo
- reduccion de espacio poco legible
- trampas que compitan con los choques como fuente principal de eliminacion
- problemas de camara al achicarse el escenario

**Dependencias:** Etapas 3, 8 y 9. La presion final requiere que la eliminacion por borde ya sea buena.

## Etapa 11 - Modos FFA y Team vs Team

**Objetivo:** formalizar dos modos igual de importantes, no una variante menor del otro.

**Sistemas involucrados:**
- reglas de victoria por modo
- equipos, colores y spawn
- FFA con supervivencia, oportunismo y terceros
- Team vs Team con rescates, coordinacion y presion tactica
- condiciones de final de ronda y match
- balance de asistencia y recuperacion

**Criterio de exito:**
- FFA funciona sin depender de roles de equipo
- Team vs Team premia rescatar partes tanto como coordinar ataques
- las condiciones de victoria son claras para jugadores y espectadores
- los dos modos producen historias distintas usando el mismo nucleo

**Riesgos tecnicos:**
- FFA injusto para robots de soporte
- Team vs Team demasiado dependiente de comunicacion perfecta
- reglas de victoria ambiguas cuando hay caidas, desarme y explosiones a la vez
- exceso de indicadores de equipo en pantalla compartida

**Dependencias:** Etapas 3, 4, 7, 8 y 10.

## Etapa 12 - Post-muerte de Team vs Team y reglas abiertas de FFA

**Objetivo:** mantener involucrados a jugadores eliminados sin confundir la pelea principal.

**Sistemas involucrados:**
- mini nave del piloto para Team vs Team
- capa externa de movimiento
- obstaculos o rutas externas
- items temporales de soporte
- intervenciones tacticas livianas
- acciones fuertes raras y telegrafiadas
- decision final sobre post-muerte en FFA

**Criterio de exito:**
- un eliminado en Team vs Team sigue teniendo algo util que hacer
- la nave no parece otro robot ni roba atencion del combate principal
- las intervenciones ayudan a remontar, pero no anulan el resultado de un buen choque
- FFA conserva identidad de supervivencia y oportunismo

**Riesgos tecnicos:**
- ruido visual por una segunda capa de juego
- frustracion si jugadores vivos sienten que los eliminados deciden demasiado
- FFA con reingreso mal balanceado
- complejidad de inputs y camara para entidades fuera de arena

**Dependencias:** Etapas 11 y 9. No conviene implementarla antes de que Team vs Team sea divertido sin post-muerte.

**Estado actual del prototipo:**
- ya existe un primer corte funcional y deliberadamente liviano: la `PilotSupportShip` aparece solo en `Teams`, se mueve por un loop perimetral continuo pegado al borde vivo, reutiliza el input del jugador eliminado y no entra al set de objetivos de la camara compartida
- la capa externa ya mezcla tres ayudas pro-aliado y una interferencia ligera: pickups discretos, ocultos hasta que exista al menos una nave activa, cargan `estabilizador`, `energia`, `movilidad` o `interferencia`, dejan `apoyo ...` visible en el roster y permiten reparar la parte activa mas dañada, activar una `energy surge` corta, reforzar un impulso breve de movilidad sobre el aliado vivo o suprimir por una ventana corta al rival mas cercano al carril
- `FFA` mantiene identidad propia: comparte la estructura base del laboratorio pero no crea naves ni activa esos pickups post-muerte
- pendiente: decidir por playtest si la mezcla `estabilizador + energia + movilidad + interferencia`, los `gates` temporales con `TimingVisual`, el `StatusBeacon`, la dupla `SupportTargetIndicator + SupportTargetFloorIndicator` y el anillo de alcance de `interferencia` ya alcanzan como fundamento legible o si la siguiente iteracion debe sumar mas variedad de rutas/obstaculos, sin volver la capa post-muerte demasiado ruidosa.

## Etapa 13 - UI, legibilidad y postpartida

**Objetivo:** reforzar lectura de estado y explicar por que se gano o perdio sin convertir la pantalla en una planilla.

**Sistemas involucrados:**
- HUD explicito con energia y vida visibles
- HUD limpio con informacion contextual
- indicadores sobre el robot: humo, chispas, piezas flojas, desgaste
- avisos de redistribucion, Overdrive y danio critico
- stats simples de fin de partida
- explicacion de causa de muerte
- replays o snippets de jugadas importantes como sistema futuro

**Criterio de exito:**
- un espectador casual entiende quien esta en peligro y por que
- el HUD ayuda sin tapar la lectura del cuerpo del robot
- perder se siente como "casi lo tenia" o "me la hicieron bien"
- la postpartida motiva otra ronda

**Riesgos tecnicos:**
- exceso de numeros en pantalla compartida
- indicadores visuales demasiado sutiles para ser utiles
- replay costoso si se intenta demasiado pronto
- causa de muerte dificil de explicar si los eventos no se registran bien

**Dependencias:** Etapas 4, 5, 7 y 11. Los replays dependen de registrar eventos desde etapas anteriores.

**Estado actual del prototipo:**
- ya existe un primer slice de HUD dual configurable desde `MatchConfig`, sin duplicar escenas ni abrir otra capa de UI
- el modo `explicito` deja visibles `Modo`, `Objetivo`, hints de control y estado completo del roster; el modo `contextual` conserva marcador/estado base y solo reexpone dano, energia, buffs, items y cargas cuando cambian
- ese mismo roster vivo ya no depende del orden fijo de la escena: `MatchController` reutiliza los comparators competitivos de FFA/Teams para que la lectura por robot acompañe al `Marcador` y al recap en vez de contradecirlos
- sigue pendiente decidir por playtest si el toggle runtime actual (`F1`) alcanza para laboratorio o si conviene sumar persistencia/preset por modo ademas del default por recurso

## Dependencias resumidas

1. La base tecnica habilita movimiento.
2. El movimiento habilita choques.
3. Los choques habilitan bordes letales y danio modular.
4. El danio modular habilita energia significativa, partes desprendidas y recuperacion.
5. Energia, partes y recuperacion habilitan arquetipos con identidad.
6. Arquetipos, items y mapas habilitan modos completos.
7. Modos completos habilitan post-muerte y postpartida con sentido.

## Que conviene prototipar primero en Godot

Lo primero deberia ser una escena de "laboratorio de choque" con dos robots, una plataforma simple y borde letal opcional.

**Contenido del prototipo inicial:**
- dos robots controlables en Easy
- movimiento con aceleracion, derrape y freno ajustables
- orientacion automatica hacia direccion de movimiento
- colision robot contra robot con empuje segun velocidad y direccion
- una arena rectangular o circular con borde letal
- debug visual de velocidad, direccion de impulso y fuerza del ultimo choque
- reinicio rapido de ronda

**Por que primero esto:**
- valida la fantasia principal antes de gastar tiempo en items, UI o muchos personajes
- permite ajustar "peso industrial" con variables visibles
- revela temprano si la fisica elegida en Godot sirve para empujes justos
- deja probar el ritmo base de tanteo, reposicionamiento y choque decisivo
- mantiene el proyecto jugable despues del primer avance real

Cuando ese laboratorio sea divertido sin danio, el siguiente prototipo inmediato deberia agregar cuatro partes con vida, aunque sea con visuales temporales. Si el choque no se siente bien antes de eso, todo lo demas va a disfrazar un problema central.
