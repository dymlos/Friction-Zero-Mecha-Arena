# ESTADO_ACTUAL.md - Friction Zero: Mecha Arena

## Estado del prototipo

## Los contratos scene-level de pickups de borde ya quedan congelados tambien en `Teams/FFA base/validation` (2026-04-22)

- Estado: los seams scene-level de pickups `repair`, `energy`, `mobility`, `utility` y `charge` ya no dependen solo de las escenas base; la red ahora tambien cubre `main_teams_validation.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: arenas, pickups, HUD y roster ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/edge_repair_pickup_test.gd`, `edge_energy_pickup_test.gd`, `edge_mobility_pickup_test.gd`, `edge_utility_pickup_test.gd` y `edge_charge_pickup_scene_test.gd` ahora validan tambien las escenas `validation`.
  - hallazgo de fixture: las escenas `validation` no usan el hijo `ArenaBlockout`; los tests ahora resuelven `ArenaBase` por tipo para no confundir naming distinto con drift real.
- Resultado:
  - `Teams/FFA base/validation` deja de tener un punto ciego en pickups cercanos al borde, layouts activos de borde y lectura corta de adquisicion en HUD/roster.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` vuelve a pasar con `Suite OK: 86 tests`.

## La presion de arena / reduccion progresiva ya queda congelada tambien en `Teams/FFA base/validation` (2026-04-22)

- Estado: el seam scene-level `warning -> contraccion -> reset del arena` ya no depende solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController`, `Main` y `ArenaBase` ya respetaban el mismo loop de presion; el gap real era de cobertura scene-level.
  - `scripts/tests/progressive_space_reduction_test.gd` ahora valida las cuatro escenas jugables, resolviendo el `arena_path` segun el laboratorio activo.
  - la fixture ahora fija `match_controller.match_config.rounds_to_win = 3` para evitar cierres finales accidentales en escenas `validation`.
  - hallazgo de fixture: en `FFA` no alcanza con tirar dos robots al vacio; para observar el reset del arena hay que dejar un unico superviviente (`N-1` bajas), mientras `Teams` sigue cerrando con dos bajas.
- Resultado:
  - `Teams/FFA base/validation` deja de tener un punto ciego en warning de contraccion, shrink real del area segura y restauracion del arena tras reset comun de ronda.
  - `godot --headless --path . -s res://scripts/tests/progressive_space_reduction_test.gd` pasa en las cuatro escenas y la suite completa sigue en `Suite OK: 86 tests`.

## Los stats scene-level de desgaste modular y negacion de partes ya quedan congelados tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: dos seams de stats/cierre `Teams` ya no dependen solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController`, `RobotBase` y `DetachedPart` ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/match_modular_loss_stats_test.gd` ahora valida en `main.tscn` + `main_teams_validation.tscn` la lectura `Stats | ... partes perdidas ...` tanto en resultado final como en recap.
  - `scripts/tests/match_part_denial_stats_test.gd` ahora valida en `main.tscn` + `main_teams_validation.tscn` la lectura `Stats | ... negaciones ...` tanto en resultado final como en recap.
- Resultado:
  - `Teams base/validation` deja de tener otro punto ciego en telemetria de desgaste modular y negacion de partes; si una escena hermana pierde ese detalle en `RecapPanel` o `MatchResultPanel`, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/match_modular_loss_stats_test.gd`, `match_part_denial_stats_test.gd` y `test_runner.gd` pasan; la suite completa sigue en `Suite OK: 86 tests`.

## El cleanup/lifecycle scene-level del soporte post-muerte `Teams` ya queda congelado tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: el lifecycle de soporte `spawn -> ronda reseteada -> cleanup` y `spawn -> match cerrado -> F5 -> cleanup` ya no depende solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `Main`, `PilotSupportShip`, `SupportLaneGate` y `MatchController` ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/support_lifecycle_cleanup_test.gd` ahora valida reset de ronda y restart manual sobre `main.tscn` + `main_teams_validation.tscn`.
  - la fixture existente sigue siendo suficiente para este seam: `round_intro_duration_teams = 0.0`, score `1/1/1` en el reset intermedio y `rounds_to_win` separado para distinguir reset de ronda vs reinicio manual.
- Resultado:
  - `Teams base/validation` deja de tener otro punto ciego en limpieza de soporte post-muerte; si una escena hermana deja una `PilotSupportShip` stale, arrastra `support_state` al match nuevo o mantiene el carril externo activo despues del cleanup, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/support_lifecycle_cleanup_test.gd` pasa en ambas escenas y la suite completa vuelve a `Suite OK: 86 tests`.

## Los contratos scene-level del soporte post-muerte `Teams` ya quedan congelados tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: el slice de soporte post-muerte `Teams` ya no depende solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`, y `FFA` confirma que tanto `main_ffa.tscn` como `main_ffa_validation.tscn` siguen sin naves de apoyo.
- Correccion aplicada:
  - no hubo cambio de produccion: `Main`, `PilotSupportShip` y `MatchController` ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/team_post_death_support_test.gd`, `team_post_death_support_targeting_test.gd`, `support_payload_actionability_test.gd` y `support_payload_availability_readability_test.gd` ahora recorren `main.tscn` + `main_teams_validation.tscn`.
  - la fixture del soporte ahora neutraliza ruido que no pertenece al seam validado (`round_intro_duration_teams = 0`, `progressive_space_reduction = false`, `round_time_seconds >= 120`) para que la escena rapida no introduzca bajas laterales por pacing de ronda.
  - hallazgo de contrato: en la escena rapida puede aparecer soporte legitimo del equipo rival dentro de la misma ronda, asi que el cleanup correcto es “desaparece la nave del jugador eliminado” y no “`SupportRoot` queda globalmente vacio”.
- Resultado:
  - el soporte post-muerte deja de tener otro punto ciego entre laboratorio base y rapido; si la escena rapida pierde spawn, targeting, warnings o bloqueo de no-ops, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 86 tests`.

## El opening ya tiene medicion runtime dedicada de deriva, borde y primer choque post-intro (2026-04-22)

- Estado: el paquete `intro + OpeningTelegraph + lock de pickups de borde` ya no depende solo de contracts headless scene-level; ahora tambien tiene una sonda runtime que mide el comportamiento real del opening sobre las cuatro escenas jugables.
- Correccion aplicada:
  - `scripts/tests/opening_pacing_runtime_test.gd` ejecuta `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - la fixture deja un robot dañado solapando un `edge_repair_pickup` desde el frame cero y empuja a los otros robots hacia el centro para observar el opening vivo.
  - la regresion fija solo el seam estable:
    - `deriva_intro = 0`
    - `pickup_post_unlock` rapido sin reingreso
    - HUD `Borde | ... | abre en Xs` mientras el intro sigue activo y limpio al liberar la ronda
  - el timing del primer choque significativo queda impreso como metrica de runtime y no como assert duro, porque la medicion mostro diferencias reales entre escenas.
- Resultado:
  - ultima corrida verde de la sonda:
    - `Teams base`: `choque_post_unlock=1.787s`
    - `Teams rapido`: `choque_post_unlock=2.961s`
    - `FFA base`: `choque_post_unlock=sin_dato`
    - `FFA rapido`: `choque_post_unlock=0.641s`
  - en las cuatro escenas el opening siguio bloqueando deriva y liberando el borde correctamente (`pickup_post_unlock<=0.021s`, `ring_out_antes_dano=no`).
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 86 tests`.

## Los contratos FFA de resolucion de ronda ya quedan congelados tambien en `main_ffa_validation.tscn` (2026-04-22)

- Estado: el lifecycle FFA de “queda un solo robot vivo -> gana `Player X` -> score individual -> reset de ronda” ya no depende solo de `main_ffa.tscn`; la red ahora tambien cubre `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` y el laboratorio rapido FFA ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/ffa_round_resolution_test.gd` ahora valida la misma resolucion de ronda en `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - la fixture ahora fuerza `match_controller.match_config.rounds_to_win = 3` porque `ffa_validation_match_config.tres` usa `1` y si no el assert valida cierre final en vez de reset intermedio.
- Resultado:
  - FFA base/validation deja de tener otro punto ciego en cierre intermedio y marcador por robot; si una escena hermana pierde el reset de ronda o vuelve a etiquetar al ganador como equipo, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 85 tests`.

## Los contratos scene-level de `roster` vivo, marcador FFA y stats/cierre de apoyo ya quedan congelados tambien en escenas `base` y `validation` (2026-04-22)

- Estado: tres seams de HUD/cierre ya no dependen de una sola escena representativa por modo; la red ahora cubre tambien `main_ffa_validation.tscn` y `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController`, `Main` y las escenas de validacion ya respetaban los mismos contratos; el gap real era de cobertura scene-level.
  - `scripts/tests/ffa_live_scoreboard_order_test.gd` ahora valida el marcador FFA ordenado por score real en `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - `scripts/tests/live_roster_order_test.gd` ahora valida roster vivo `FFA` sobre `main_ffa.tscn` + `main_ffa_validation.tscn` y roster vivo `Teams` sobre `main.tscn` + `main_teams_validation.tscn`, incluyendo `Apoyo activo`, hints del soporte y limpieza de estado stale del robot caido.
  - `scripts/tests/support_match_stats_test.gd` ahora valida en `main.tscn` y `main_teams_validation.tscn` el mismo cierre `Aporte de apoyo | ...` y `Stats | Equipo 1 | apoyo ...` dentro del recap lateral y del resultado final.
- Resultado:
  - los laboratorios `base/validation` dejan de tener otro punto ciego en HUD vivo y cierre de soporte; si una escena hermana pierde orden de roster, score FFA o stats de apoyo, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 85 tests`.

## Los contratos Teams de resolucion de ronda, reset de atribucion y explosion inestable ya quedan congelados tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: tres seams `Teams` que seguian atados solo a `main.tscn` ahora tambien quedan cubiertos en el laboratorio rapido `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` y la escena de validacion ya respetaban los mismos contratos; el gap real era de cobertura scene-level.
  - `scripts/tests/match_round_resolution_test.gd` ahora valida resolucion y reset de ronda en `main.tscn` y `main_teams_validation.tscn`; la fixture fija `match_config.rounds_to_win = 3` porque la config de validacion usa `1` y si no el test cierra el match en la primera ronda.
  - `scripts/tests/match_elimination_source_reset_test.gd` ahora valida en ambas escenas que la atribucion `vacio por Player X` no sobreviva stale al pasar de una ronda a otra.
  - `scripts/tests/match_unstable_explosion_readability_test.gd` ahora valida en ambas escenas la lectura `Inutilizado/inestable`, la salida del combate principal y `Ultima baja | Player 3 exploto en sobrecarga`.
- Resultado:
  - `Teams base/validation` deja de tener otro punto ciego en lifecycle de ronda y legibilidad de bajas; si una escena hermana pierde reset intermedio o lectura de explosion inestable, la suite lo detecta antes de runtime.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 85 tests`.

## Los contratos Teams de atribucion de bajas y condicion final por robot ya quedan congelados tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: dos lecturas de cierre `Teams` ya no dependen solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` y la escena de validacion ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/match_elimination_readability_test.gd` ahora valida en `main.tscn` y `main_teams_validation.tscn` la atribucion visible de `explosion/vacio por Player X` y `Cierre | ...` en roster, recap y resultado final.
  - `scripts/tests/match_robot_final_condition_summary_test.gd` ahora valida en `main.tscn` y `main_teams_validation.tscn` el detalle final por robot con arquetipo, partes restantes y extremidades faltantes.
- Resultado:
  - el cierre `Teams` deja de tener otro punto ciego entre laboratorio base y rapido; si una escena hermana pierde atribucion de bajas o resumen final por robot, la suite lo detecta antes de runtime.

## Los highlights/detalle final de `Teams` ya quedan congelados tambien en `main_teams_validation.tscn` (2026-04-22)

- Estado: varios seams de cierre `Teams` ya no dependen solo de `main.tscn`; la red ahora tambien cubre `main_teams_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` y la escena de validacion ya respetaban el mismo contrato; el gap real era de cobertura scene-level.
  - `scripts/tests/match_highlight_moments_test.gd` ahora valida `Resumen | ...` y `Momento inicial/final` en `main.tscn` y `main_teams_validation.tscn`.
  - `scripts/tests/support_decisive_highlight_test.gd` ahora valida `Apoyo decisivo | ...` en `main.tscn` y `main_teams_validation.tscn`.
  - `scripts/tests/team_match_result_detail_order_test.gd` ahora valida el orden de stats/detalle por resultado real tambien en `main_teams_validation.tscn`.
- Resultado:
  - el cierre `Teams` deja de tener otro punto ciego entre laboratorio base y rapido; si una escena hermana pierde highlights, apoyo decisivo o orden del detalle final, la suite lo detecta antes de runtime.

## Los contratos de recap entre rondas ya quedan congelados tambien en escenas `base` y `validation` de `Teams/FFA` (2026-04-22)

- Estado: el recap intermedio ya no depende solo de `main.tscn` o `main_ffa.tscn`; la red ahora tambien cubre `main_teams_validation.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` ya respetaba el contrato tambien en validacion; el gap real era de cobertura scene-level.
  - `scripts/tests/match_round_recap_test.gd` ahora valida el recap `Teams` en `main.tscn` y `main_teams_validation.tscn`.
  - `scripts/tests/match_round_draw_recap_test.gd` ahora valida el recap de empate `FFA` en `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - la fixture `Teams` ahora fuerza `match_config.rounds_to_win = 3` para no confundir el recap de ronda con un cierre final cuando la escena de validacion usa otro target de match.
- Resultado:
  - el recap entre rondas deja de tener otro punto ciego entre laboratorio base y rapido; si una escena pierde `Cierre de ronda`, `Objetivo | ...`, el detalle de bajas o `sin ganador (+0)`, la suite lo detecta antes de runtime.

## Los contratos de cierre ya quedan congelados tambien en escenas `base` y `validation` de `Teams/FFA` (2026-04-22)

- Estado: las superficies de cierre (`RecapPanel`, `MatchResultPanel`, score final, objetivo, posiciones y perfil de puntos por causa) ya no dependen solo de `main.tscn` o `main_ffa.tscn`; la red ahora tambien cubre `main_teams_validation.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `MatchController` y las escenas ya respetaban el contrato tambien en validacion; el gap real era de cobertura scene-level.
  - `scripts/tests/match_completion_test.gd` ahora valida el cierre `Teams` en `main.tscn` y `main_teams_validation.tscn`.
  - `scripts/tests/ffa_match_result_standings_test.gd` ahora valida el cierre/ranking `FFA` en `main_ffa.tscn` y `main_ffa_validation.tscn`.
  - `scripts/tests/match_closing_cause_summary_test.gd` ahora congela `Cierres | ...`, `Puntos cierre | ...` y `Cierre decisivo | ...` en las cuatro escenas jugables.
- Resultado:
  - recap y resultado final dejan de tener otro punto ciego entre laboratorio base y rapido; si una escena hermana pierde objetivo, posiciones o perfil de cierre, la suite lo detecta antes de runtime.

## El contrato del intro de ronda ya esta congelado tambien en `base` y `validation` de ambos modos (2026-04-22)

- Estado: el countdown de apertura ya no depende solo de `main.tscn`; ahora la red tambien cubre `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `scripts/tests/round_intro_countdown_test.gd` ahora recorre las cuatro escenas jugables y valida el mismo seam scene-level.
  - la fixture deja explicito que el intro se configura desde `MatchConfig` cuando existe y usa `round_intro_duration` solo como fallback, evitando falsos verdes por asumir que el override del nodo mandaba siempre.
  - el contrato congelado es el mismo en las cuatro escenas: input bloqueado durante el intro, `RoundIntroIndicator` visible, wording de apertura correcto por modo (`carriles` en `Teams`, neutral en `FFA`) y liberacion real de movimiento/cue al terminar el countdown.
- Resultado:
  - el intro deja de tener otro punto ciego entre laboratorios base y rapidos; si una escena pierde el countdown, el lock de control o el telegraph diegetico, la suite lo detecta antes de runtime.

## El lock del borde durante el intro ya esta congelado tambien en `base` y `validation` de ambos modos (2026-04-22)

- Estado: el contrato `pickup visible pero bloqueado + HUD Borde | ... | abre en Xs + desbloqueo al terminar el countdown` ya no depende solo de `main.tscn`; ahora queda cubierto tambien en `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
- Correccion aplicada:
  - no hubo cambio de produccion: `scripts/main/main.gd` y los pickups de borde ya sincronizaban bien el intro desde `MatchController.is_round_intro_active()`.
  - `scripts/tests/edge_pickup_intro_lock_test.gd` ahora recorre las cuatro escenas jugables y verifica el mismo seam scene-level con un pickup de reparacion activo: bloqueo durante el intro, linea `Borde | ... | abre en Xs` visible y coleccion restaurada apenas termina el countdown.
- Resultado:
  - la apertura del borde deja de tener otro punto ciego entre laboratorio base y rapido; si una variante pierde el lock o el wording del HUD, la red lo detecta antes de llegar a runtime.

## La apertura neutra ya queda congelada tambien en escenas `base` y `validation` (2026-04-22)

- Estado: los contratos de opening/readability mas sensibles ya no dependen de una sola escena por modo; `Teams` y `FFA` ahora tienen la misma red de regresion tanto en laboratorio base como en laboratorio rapido.
- Correccion aplicada:
  - `scripts/tests/teams_live_scoreboard_opening_test.gd` valida el marcador neutro oculto en `main.tscn` y `main_teams_validation.tscn`.
  - `scripts/tests/ffa_live_standings_hud_test.gd` valida el opening neutral sin `Marcador |`, `Posiciones |` ni `Desempate |` en `main_ffa.tscn` y `main_ffa_validation.tscn`, y comprueba que ambas escenas vuelvan a mostrar score/posiciones cuando la ronda ya aporta informacion real.
  - `scripts/tests/teams_opening_intro_telegraph_test.gd` sigue fijando `OpeningTelegraph` visible en `Teams` y ahora tambien congela que `main_ffa_validation.tscn` lo mantenga oculto igual que `main_ffa.tscn`.
- Resultado:
  - la pareja `base/validation` deja de ser un punto ciego para drift de opening; si una escena rapida pierde el contrato neutral del HUD o hereda cues de `Teams` en `FFA`, la suite lo marca antes de que llegue a runtime.

## La apertura ya bloquea los pickups de borde hasta que la ronda realmente abre (2026-04-22)

- Estado: los pedestales del borde siguen visibles durante el intro, pero ya no pueden recogerse hasta que `MatchController` libera la ronda; el HUD del laboratorio ahora lo explicita con `Borde | ... | abre en Xs`.
- Correccion aplicada:
  - `scripts/main/main.gd` sincroniza `set_collection_enabled(false)` sobre `edge_pickups` mientras `is_round_intro_active()` siga activo y vuelve a habilitarlos apenas termina el countdown.
  - los pickups de borde (`repair/mobility/energy/pulse/charge/utility`) ahora separan visibilidad de disponibilidad: mantienen silhouette/pedestal visibles, bloquean consumo durante el intro y revisan overlaps cuando vuelven a quedar habilitados.
  - `scripts/tests/edge_pickup_intro_lock_test.gd` fija la regresion principal en `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`; las fixtures scene-level de pickups siguen esperando a que termine el intro antes de validar coleccion real.
- Resultado:
  - el opening queda mas alineado con `inicio parejo -> analisis -> escalada`: los items del borde siguen prometiendo valor, pero ya no saltan por contacto gratis antes del primer beat jugable.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 85 tests`.

## El perfil actual de score por causa sigue validado y no requiere retoque sin evidencia nueva (2026-04-22)

- Estado: el prototipo sigue usando `ring-out 2 / destruccion total 1 / explosion inestable 4` en `MatchConfig`, y la red actual vuelve a confirmar que ese perfil se refleja igual en `Teams`, `FFA`, recap y cierre final.
- Validacion rehecha:
  - `scripts/tests/match_elimination_victory_weights_test.gd` mantiene el contrato mecanico `2 + 4 = 6` en ambos modos.
  - `scripts/tests/match_closing_cause_summary_test.gd` vuelve a fijar `Puntos cierre | ...`, `Cierre ronda | ...` y `Cierre decisivo | ...` en recap/resultados.
  - `scripts/tests/match_completion_test.gd` conserva el cierre visible de `Teams` alineado con puntos, no rondas ambiguas.
- Decision:
  - no hubo cambio de produccion ni de config; la revision solo confirma que el perfil vigente sigue siendo consistente con la lectura del prototipo.
  - el siguiente ajuste de balance sobre `2/1/4` queda bloqueado hasta tener evidencia runtime/manual nueva de dominancia real, no otra correccion cosmética de HUD.

## El recap lateral del cierre final ya repite tambien la ultima baja decisiva (2026-04-22)

- Estado: cuando el match termina, `RecapPanel` ya no queda un paso atras del `MatchResultPanel`; ahora tambien incluye `Cierre | <ultima baja>` con la misma atribucion del rival responsable.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` extrae `_build_closing_elimination_line()` desde `_last_elimination_summary`.
  - la misma linea se reutiliza en `get_round_recap_panel_lines()` y `get_match_result_lines()`, sin tocar HUD vivo ni recaps intermedios.
  - `scripts/tests/match_elimination_readability_test.gd` fija la regresion minima en dos superficies del recap final: array de lineas y `RecapLabel` visible.
- Resultado:
  - los dos paneles de cierre final quedan simetricos y autosuficientes para reconstruir que baja concreto clincheo el match.
  - `godot --headless --path . -s res://scripts/tests/match_elimination_readability_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_highlight_moments_test.gd`, `godot --headless --path . -s res://scripts/tests/ffa_match_result_standings_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## El targeting post-muerte de soporte ya tiene regresion estable sobre el loop fisico real (2026-04-22)

- Estado: `team_post_death_support_targeting_test.gd` ya no cae de forma intermitente al validar `interferencia` y el regreso desde override manual al modo auto.
- Correccion aplicada:
  - la investigacion confirmo que `PilotSupportShip` actualiza seleccion en `_physics_process()`, mientras el helper local `_wait_frames()` esperaba solo `process_frame`.
  - `scripts/tests/team_post_death_support_targeting_test.gd` ahora espera `physics_frame` y luego `process_frame` por paso, sin tocar logica de produccion.
- Resultado:
  - el test deja de observar estados a mitad de tick fisico y vuelve a ser una red fiable para auto-targeting / override manual.
  - `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` pasa de forma repetida y `godot --headless --path . -s res://scripts/tests/test_runner.gd` vuelve a `Suite OK: 84 tests`.

## El cierre final `Teams` ya nombra explicitamente los puntos del match (2026-04-22)

- Estado: la decision principal del match en `Teams` ya no cierra como un `2-0` ambiguo; ahora publica `Equipo X gana la partida por A-B pts`, alineada con el resto del HUD que ya explicita `Objetivo | Primero a N pts`.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` ajusta `_build_match_victory_status_line()` solo para `Teams`, sin tocar el wording propio de `FFA`.
  - `scripts/tests/match_completion_test.gd` fija la regresion minima en tres superficies: `round_status_line`, `RecapLabel` y `MatchResultLabel`.
- Resultado:
  - el cierre final deja de parecer un conteo de rondas justo cuando el prototipo ya usa score ponderado por causa de cierre.
  - `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## El recap entre rondas ahora explica tambien las rondas sin ganador (2026-04-22)

- Estado: cuando una ronda termina en empate, el recap intermedio ya no deja solo `Decision | Ronda N sin ganador`; ahora agrega una linea propia `Cierre ronda | sin ganador (+0)` para dejar claro que no hubo causa premiada ni puntos sumados.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` agrega `_last_round_was_draw` como estado minimo del cierre y hace que `_build_round_closing_line()` publique el wording de cero puntos solo cuando la ronda termino sin ganador y el match sigue abierto.
  - `scripts/tests/match_round_draw_recap_test.gd` fija la regresion minima en `FFA`, validando tanto `get_round_recap_panel_lines()` como el texto visible del `RecapLabel`.
- Resultado:
  - el recap entre rondas queda autosuficiente tambien en el caso empate, alineado con la decision previa de explicar `Cierre ronda | <causa> (+N)` cuando si hubo ganador.
  - `godot --headless --path . -s res://scripts/tests/match_round_draw_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd` y `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` pasan.

## El recap entre rondas ahora muestra tambien `Puntos cierre | ...` antes del final del match (2026-04-22)

- Estado: el playtest corto ya no necesita esperar a `Partida cerrada` para leer el perfil activo `ring-out / destruccion total / explosion inestable`; el recap entre rondas ahora publica tambien `Puntos cierre | ...`.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` cambia `_build_closing_points_profile_line()` para que se oculte solo durante la ronda activa, no durante todo el match abierto.
  - `scripts/tests/match_closing_cause_summary_test.gd` agrega la regresion minima en `Teams` y `FFA`: despues de la primera ronda por `ring-out`, el recap debe incluir `Puntos cierre | ...` junto a `Cierre ronda | ...`.
- Resultado:
  - cada cierre intermedio ya deja visible no solo que causa dio `+N`, sino tambien el perfil completo vigente del match, alineando mejor el laboratorio con el siguiente paso de balancear pesos por causa.
  - `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## El recap lateral y el panel final ahora dejan visible tambien el objetivo del match (2026-04-22)

- Estado: los paneles de cierre ya no quedan autosuficientes solo para score/causa/resumen; ahora tambien exponen `Objetivo | Primero a N pts`, evitando que el puntaje visible pierda contexto fuera del HUD principal.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` extrae `_build_target_score_line()` y reutiliza la misma linea en `get_round_state_lines()`, `get_round_recap_panel_lines()` y `get_match_result_lines()`.
  - `scripts/tests/match_round_recap_test.gd` fija la regresion del recap intermedio y `scripts/tests/match_completion_test.gd` la del cierre final, validando arrays + labels visibles.
- Resultado:
  - el recap de ronda ya deja claro si el score actual esta lejos o cerca del cierre del match, y el panel final conserva el mismo contexto de objetivo sin depender de otra zona de HUD.
  - `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_highlight_moments_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## Recap y resultado final ahora incluyen tambien el `Resumen | ...` compacto (2026-04-22)

- Estado: `RecapPanel` y `MatchResultPanel` ya no dependen del bloque principal del HUD para explicar de un vistazo la secuencia de bajas que cerro la ronda/partida.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` reutiliza `get_round_recap_line()` dentro de `get_round_recap_panel_lines()` y `get_match_result_lines()`, manteniendo una sola fuente de verdad para la cadena `Resumen | ...`.
  - `scripts/tests/match_highlight_moments_test.gd` ahora exige esa linea en el recap lateral, en el texto visible del recap y en el panel final, junto a `Momento inicial/final`.
- Resultado:
  - el cierre ya combina resumen compacto + snippets de momentos + detalle por robot dentro de cada panel, sin obligar a mirar otra zona del HUD para reconstruir la ronda.
  - `godot --headless --path . -s res://scripts/tests/match_highlight_moments_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## El HUD explicito ya aclara que el objetivo del match son puntos (2026-04-22)

- Estado: la linea fija `Objetivo | ...` ya no queda ambigua frente al score ponderado por causa; ahora explicita `Primero a N pts`.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` cambia el wording del objetivo solo en HUD explicito, sin sumar otra linea ni ruido nuevo al flujo contextual.
  - `scripts/tests/match_completion_test.gd` congela el string exacto para evitar que futuras iteraciones vuelvan a presentar el target como si fueran rondas.
- Resultado:
  - el laboratorio ya deja mas claro que `rounds_to_win` hoy funciona como puntaje objetivo del match, alineado con `Cierre ronda | ... (+N)` y `Puntos cierre | ...`.
  - `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## El recap de ronda ya dice que causa la cerro y cuantos puntos dio (2026-04-22)

- Estado: el score ponderado por causa ya no queda explicado solo en `Partida cerrada`; cada ronda decidida ahora publica `Cierre ronda | <causa> (+N)` mientras el match sigue abierto.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` agrega `_build_round_closing_line()` y la inyecta en `get_round_recap_panel_lines()` solo cuando la ronda termino, no hubo empate y la partida todavia no cerro.
  - la lectura reutiliza `_last_round_closing_cause` y `get_round_victory_points_for_cause(...)`, manteniendo un solo seam de verdad para `ring-out`, `destruccion total` y `explosion inestable`.
  - `scripts/tests/match_closing_cause_summary_test.gd` ahora exige esa linea tras la primera ronda en `Teams` y `FFA`, antes del reset y antes del cierre final.
- Resultado:
  - el playtest corto ya puede leer la recompensa real de cada ronda en el momento en que sucede, en vez de inferirla desde el marcador o esperar al panel final.
  - `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## La apertura `Teams` ahora telegraphia sus dos carriles durante el intro (2026-04-22)

- Estado: la lectura del primer beat en `Teams` ya no depende solo del facing inward; mientras dura el intro aparece una pista diegética temporal en la arena y el estado de ronda explicita que la apertura arranca por carriles.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` cambia el wording del intro `Teams` a `Ronda N | carriles listos | arranca en ...`; `FFA` conserva el texto neutral.
  - `scripts/arenas/arena_base.gd` crea en runtime `OpeningTelegraph` con `LaneA/LaneB`, ajustadas al tamano actual del arena y apagadas fuera del intro.
  - `scripts/main/main.gd` deriva las filas vivas por `team_id` desde las posiciones reales de los robots y las empuja al arena con `_sync_opening_telegraph()`, reutilizando el lifecycle ya existente del intro.
  - `scripts/tests/teams_opening_intro_telegraph_test.gd` congela el contrato completo en `main.tscn`, `main_teams_validation.tscn` y `main_ffa.tscn`.
- Resultado:
  - el setup `Teams` ahora explica mejor el emparejamiento inicial sin abrir otra banda permanente de HUD ni duplicar datos de spawn en escenas.
  - `godot --headless --path . -s res://scripts/tests/teams_opening_intro_telegraph_test.gd`, `godot --headless --path . -s res://scripts/tests/round_intro_countdown_test.gd`, `godot --headless --path . -s res://scripts/tests/teams_spawn_coordination_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 83 tests`).

## El cierre final ya explicita la causa decisiva y sus puntos (2026-04-22)

- Estado: recap y panel `Partida cerrada` ya no dejan al playtest inferir cual fue la causa exacta que clincheo el match; ahora publican `Cierre decisivo | <causa> (+N)` junto a `Cierres | ...` y `Puntos cierre | ...`.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` persiste `_last_round_closing_cause` al cerrar la ronda ganadora y expone `_build_decisive_closing_line()`.
  - la nueva linea solo aparece con `_match_over`, reutilizada por `get_round_recap_panel_lines()` y `get_match_result_lines()` para no ensuciar HUD vivo ni recap intermedio.
  - `scripts/tests/match_closing_cause_summary_test.gd` amplia la regresion de `Teams` y `FFA`: ahora exige la combinacion completa `Cierres | ...` + `Puntos cierre | ...` + `Cierre decisivo | ...`.
- Resultado:
  - el playtest corto de score/cierre ya puede leer dentro del propio prototipo no solo que causas cerraron el match y cuanto vale cada una, sino tambien cual ruta otorgo los puntos decisivos de la ronda final.
  - `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## Apertura `Teams` ahora mira hacia el carril central (2026-04-22)

- Estado: el bootstrap `Teams` ya no deja a los robots arrancar con la misma orientacion heredada del marker o de la escena; ambos equipos inician mirando hacia dentro desde su mitad del arena.
- Correccion aplicada:
  - `scripts/main/main.gd` ahora recompone los `spawn_transforms` de `Teams` con `_build_team_spawn_transform(...)`.
  - el helper conserva la posicion original del marker, pero sustituye su base por una orientacion simple hacia `+X` o `-X` local del arena segun el lado en que aparezca el robot.
  - `scripts/tests/teams_spawn_coordination_test.gd` amplia la regresion existente: ademas de exigir pares coordinados, ahora exige que cada robot mire hacia el carril central en `main.tscn` y `main_teams_validation.tscn`.
- Resultado:
  - la apertura de `Teams` gana lectura inmediata de emparejamiento/lane sin tocar spawns, HUD ni escenas duplicadas.
  - `godot --headless --path . -s res://scripts/tests/teams_spawn_coordination_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd`, `godot --headless --path . -s res://scripts/tests/teams_validation_lab_scene_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## Revision estricta del baseline cerrada (2026-04-22)

- Estado: la base actual del prototipo sigue consistente despues de releer documentacion, revisar escenas/sistemas clave y correr la suite headless completa.
- Evidencia:
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 82 tests`.
  - la revision no encontro un defecto nuevo de produccion en `MatchController`, `Main`, `PilotSupportShip`, HUD ni escenas principales que justificara reabrir el slice reciente de laboratorio/soporte.
- Decision:
  - congelar el slice `selector runtime + Apoyo activo + HUD` en modo mantenimiento.
  - mover la siguiente iteracion a validacion jugable corta de score por causa, apertura de `Teams` y ritmo de cierre, que hoy prometen mas retorno sobre la fantasia central que otra ronda de microajustes de laboratorio.

## Cierre final ya expone el perfil runtime de score por causa (2026-04-22)

- Estado: el recap final y el panel `Partida cerrada` ya muestran tambien `Puntos cierre | ring-out N | destruccion total N | explosion inestable N`, usando los valores activos del `MatchConfig` cargado en esa escena.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` agrega `_build_closing_points_profile_line()` y lo publica en `get_round_recap_panel_lines()` y `get_match_result_lines()` solo cuando el match ya termino.
  - la nueva linea se construye desde `match_config.void_elimination_round_points`, `destruction_elimination_round_points` y `unstable_elimination_round_points`, evitando que el cierre dependa de recordar el perfil `2/1/4` por fuera del prototipo.
  - `scripts/tests/match_closing_cause_summary_test.gd` amplia la regresion existente en `Teams` y `FFA`: ademas de `Cierres | ...`, ahora exige que recap y resultado final repitan el perfil runtime de puntos por causa.
- Resultado:
  - el siguiente playtest corto de score/cierre ya puede leer dentro del propio prototipo tanto la mezcla real de cierres (`Cierres | ...`) como el peso activo de cada ruta (`Puntos cierre | ...`) sin abrir configs ni notas auxiliares.
  - `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## `F2` ya cubre el salto entre robot vivo y `Apoyo activo` (2026-04-22)

- Estado: el selector runtime del laboratorio ya tiene regresión headless para el caso donde el slot seleccionado sale de una nave post-muerte con `F2`, cae sobre un robot vivo, y luego vuelve a ese mismo slot ya en `Apoyo activo`.
- Cobertura aplicada:
  - `scripts/tests/lab_runtime_selector_test.gd` ahora recorre `P1 Apoyo activo -> F2 -> P2 vivo -> wrap F2 -> P1 Apoyo activo`.
  - al salir del soporte exige que `Lab | ...` vuelva a describir el robot vivo, que `Control P2 | ...` reemplace la chuleta del soporte, que desaparezca `Apoyo P1 | ...` y que la pista diegética migre al robot seleccionado.
  - al volver al slot caído exige recuperar `Lab | P1 Apoyo activo`, controles de soporte, `Apoyo P1 | sin carga` y la marca runtime sobre `PilotSupportShip`.
  - la revisión confirmó que no hacía falta tocar producción: `Main.cycle_lab_selector_slot()` ya delegaba correctamente en `_sync_lab_selector_visuals()` y `_refresh_hud()`.
- Resultado:
  - queda congelado el seam que faltaba entre selector por slot y soporte post-muerte, evitando reabrir el problema solo porque hasta ahora la cobertura se centraba en “el slot seleccionado cae” y no en “el selector aterriza sobre un slot ya caído”.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` pasa.

## HUD explícito `Teams` prioriza la acción de `Apoyo activo` (2026-04-22)

- Estado: cuando un jugador eliminado sigue influyendo desde `PilotSupportShip`, el roster explícito ya no muestra primero la causa de baja y recién después el hint/payload del soporte.
- Corrección aplicada:
  - `scripts/systems/match_controller.gd` ahora arma el caso `has_active_support` como `Apoyo activo | <support_state> | baja <causa>`; conserva la causa visible, pero la deja como dato secundario.
  - `support_state` deja de agregarse una segunda vez al final de la línea en ese camino.
  - `scripts/tests/live_roster_order_test.gd` fija el orden mínimo `Apoyo activo -> hint accionable -> vacio`.
- Resultado:
  - el HUD explícito sigue explicando cómo cayó el jugador, pero ya prioriza la acción vigente del slice post-muerte, alineado con la regla de legibilidad del proyecto.
  - `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## Reset runtime `F3/F4` limpia `Apoyo activo` en el mismo frame (2026-04-22)

- Estado: reconfigurar el slot seleccionado del laboratorio con `F3` o `F4` mientras ese jugador estaba en `Apoyo activo` ya no deja una `PilotSupportShip` stale visible hasta el frame siguiente.
- Corrección aplicada:
  - `scripts/main/main.gd` ahora hace que `_clear_post_death_support()` quite cada nave de `SupportRoot` antes de `queue_free()`.
  - con eso, el reset interno que dispara `_apply_lab_runtime_loadout()` deja de encontrar soporte transitorio cuando recompone `Lab | ...`, `Control Pn | ...`, `Apoyo Pn | ...` y `LabSelectionIndicator`.
  - `scripts/tests/lab_runtime_selector_test.gd` agrega la regresión `P1 Grua Hard -> Apoyo activo -> F3/F4`, exigiendo retorno inmediato a `P1 Cizalla Hard/Easy`, desaparición instantánea de `Apoyo P1 | ...`, `SupportRoot` vacío y selector de vuelta en el robot.
- Resultado:
  - queda cerrado el último seam de reset runtime del selector cuando el slot seleccionado venía desde soporte post-muerte: `F3`, `F4`, `F5`, `F6` y reset automático de ronda ya tienen red explícita.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## Reset automático del selector runtime tras `Apoyo activo` cubierto (2026-04-22)

- Estado: el laboratorio ya tiene regresión headless también para el camino normal `slot seleccionado -> Apoyo activo -> cierre de ronda -> nueva ronda`; no solo para `F5` y `F6`.
- Cobertura aplicada:
  - `scripts/tests/lab_runtime_selector_test.gd` ahora recorre el flujo `P1 Grua Hard -> P1 Apoyo activo -> ronda cerrada -> Ronda 2`.
  - antes del reset exige `Lab | P1 Apoyo activo`, `Control P1 | usa C | objetivo Q/E` y `Apoyo P1 | sin carga`.
  - tras el reset automático exige que el selector runtime vuelva a `P1 Grua Hard`, que la referencia compacta retome los controles del robot, que desaparezca `Apoyo P1 | ...`, que no quede una `PilotSupportShip` stale y que la pista diegética vuelva al robot.
  - la revisión confirmó que no hacía falta tocar producción: `Main._on_round_started()` ya limpiaba soporte post-muerte y `Main._sync_lab_selector_visuals()` ya reaplicaba bien el actor jugable real.
- Resultado:
  - queda congelado el seam entre lifecycle normal de ronda y selector runtime del laboratorio para evitar que futuras iteraciones arreglen solo `F5`/`F6` y dejen sin cobertura el reset común.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## Pista diegética del selector runtime alineada con `Apoyo activo` (2026-04-22)

- Estado: cuando el slot seleccionado del laboratorio cae en `Teams` y pasa a `Apoyo activo`, la pista diegética `LabSelectionIndicator` ya no queda pegada al robot caído; ahora migra a la nave `PilotSupportShip`, alineada con `Lab | P1 Apoyo activo`, `Control P1 | usa C | objetivo Q/E` y `Apoyo P1 | ...`.
- Corrección aplicada:
  - `scripts/support/pilot_support_ship.gd` ahora expone `set_lab_selected()/is_lab_selected()` y crea un `LabSelectionIndicator` runtime con el mismo lenguaje visual sobrio del laboratorio.
  - `scripts/main/main.gd` hace que `_sync_lab_selector_visuals()` apague la marca del robot seleccionado cuando `_find_post_death_support_ship(robot)` devuelve una nave activa, y la pase a esa `PilotSupportShip`.
  - `_sync_post_death_support_state()` vuelve a sincronizar la pista diegética en cada cambio de lifecycle del soporte para que el anillo aparezca/desaparezca sin depender de otro input de selector.
  - `scripts/tests/lab_runtime_selector_test.gd` fija la regresión completa: anillo visible en el robot antes de la baja; anillo apagado en el robot y visible en la nave tras `fall_into_void()`.
- Resultado:
  - el laboratorio ya no contradice en mundo al round-state cuando el jugador seleccionado deja de controlar el robot y pasa al carril post-muerte.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## Cambio de laboratorio `F6` desde `Apoyo activo` cubierto (2026-04-22)

- Estado: el selector runtime ya tiene cobertura headless para el caso donde el slot seleccionado cae en `Teams`, pasa a `Apoyo activo` y luego salta de laboratorio con `F6`.
- Cobertura aplicada:
  - `scripts/tests/lab_scene_selector_test.gd` ahora recorre el flujo `P1 Grua Hard -> P1 Apoyo activo -> F6`.
  - antes del cambio de escena exige `Lab | P1 Apoyo activo`, `Control P1 | usa C | objetivo Q/E` y `Apoyo P1 | sin carga`.
  - tras cargar `main_teams_validation.tscn`, exige que el selector runtime vuelva a `P1 Grua Hard`, que la referencia compacta retome los controles del robot Hard y que desaparezca `Apoyo P1 | ...`.
  - la revisión confirmó que no hacía falta tocar producción: `_store_lab_runtime_session_state()` persiste solo slot/loadout/HUD y la escena nueva se recompone sin soporte post-muerte stale.
- Resultado:
  - queda congelado el seam entre selector runtime, persistencia `F6` y cleanup del soporte post-muerte.
  - `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## Reinicio manual `F5` con selector runtime tras `Apoyo activo` cubierto (2026-04-22)

- Estado: el laboratorio ya tiene cobertura headless para el caso donde el slot seleccionado entra en `Apoyo activo`, el match se cierra y luego se reinicia manualmente con `F5`.
- Cobertura aplicada:
  - `scripts/tests/lab_runtime_selector_test.gd` ahora recorre el flujo real `P1 Grua Hard -> P1 Apoyo activo -> derrota de equipo -> F5`.
  - tras el reinicio manual exige que el selector runtime vuelva a `Lab | P1 Grua Hard ...`, que la referencia `Control P1 | ...` retome los controles del robot y que desaparezca `Apoyo P1 | ...`.
  - la investigación confirmó que no hacía falta tocar producción: `MatchController.request_match_restart()` solo acepta `F5` con match cerrado y, en ese camino real, `Main._on_round_started()` + `_clear_post_death_support()` ya limpian correctamente el soporte post-muerte.
- Resultado:
  - queda congelado el seam entre reinicio manual y selector runtime del laboratorio para evitar futuros falsos fixes o regresiones alrededor de `Apoyo activo`.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/match_manual_restart_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## Estado accionable persistente del soporte en el round-state del laboratorio (2026-04-22)

- Estado: cuando el slot seleccionado del laboratorio ya paso a `Apoyo activo` en `Teams`, el round-state ahora deja visible tambien la capa accionable del soporte y no obliga a mirar solo el roster para saber si la nave esta `sin carga`, `interferida` o que payload/target tiene listo.
- Correccion aplicada:
  - `scripts/support/pilot_support_ship.gd` ahora separa `get_actionable_status_summary()` de `get_status_summary()`.
  - `get_status_summary()` sigue siendo la fuente completa para el roster (`hint de input + estado accionable`).
  - `scripts/main/main.gd` agrega `get_lab_selected_support_summary_line()` y `_build_round_state_lines()` publica `Apoyo Pn | ...` solo cuando el slot seleccionado realmente ya tiene una `PilotSupportShip` activa.
  - `scripts/tests/lab_runtime_selector_test.gd` fija la regresion: antes de la baja no debe existir `Apoyo P1 | ...`; despues de la caida del slot seleccionado debe aparecer `Apoyo P1 | sin carga`.
- Resultado:
  - el round-state del laboratorio ya deja juntas las tres piezas minimas del slice post-muerte seleccionado: identidad (`Lab | P1 Apoyo activo`), controles (`Control P1 | usa C | objetivo Q/E`) y estado accionable (`Apoyo P1 | ...`).
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 82 tests`).

## Resumen `Lab | ...` alineado con `Apoyo activo` (2026-04-22)

- Estado: el resumen persistente del selector runtime ya no sigue anunciando `P1 Ariete Easy/Hard` cuando ese slot seleccionado cae en `Teams` y pasa a jugar desde la nave de soporte.
- Corrección aplicada:
  - `scripts/main/main.gd` ahora hace que `_get_lab_robot_brief(robot)` consulte `_find_post_death_support_ship(robot)` antes de resumir arquetipo/modo.
  - si el slot sigue controlando su robot, la línea mantiene `P1 Ariete Easy/Hard` como antes.
  - si el jugador ya tiene una `PilotSupportShip` activa, la línea cambia a `P1 Apoyo activo`, alineada con la jugabilidad real del frame.
  - `scripts/tests/lab_runtime_selector_test.gd` fija la regresión: primero exige el resumen normal del robot y, tras la baja, exige `Apoyo activo` y la ausencia del texto stale `Ariete Easy`.
- Resultado:
  - el round-state del laboratorio deja dos líneas consistentes entre sí durante el slice post-muerte `Teams`: `Lab | P1 Apoyo activo ...` y `Control P1 | usa C | objetivo Q/E`.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan.

## Referencia compacta de controles alineada con `Apoyo activo` (2026-04-22)

- Estado: la línea persistente `Control Pn | ...` del laboratorio ya no queda stale cuando el slot seleccionado pasa de robot activo a nave de soporte en `Teams`.
- Corrección aplicada:
  - `scripts/main/main.gd` ahora hace que `get_lab_selected_controls_summary_line()` consulte `_find_post_death_support_ship(robot)` antes de armar la chuleta.
  - si el jugador seleccionado sigue en combate, la línea conserva `robot.get_control_reference_hint()`.
  - si ya existe `PilotSupportShip` para ese owner, la línea cambia a `robot.get_support_input_hint()` y publica `usa ... | objetivo ...`.
  - `scripts/tests/lab_runtime_selector_test.gd` fija la regresión: `P1` arranca con controles normales, cae al vacío y la misma línea persistente migra a los controles reales del soporte sin conservar `mueve WASD`.
- Resultado:
  - el selector runtime del laboratorio sigue siendo una referencia fiel de lo que el jugador seleccionado puede hacer en ese frame, también durante el slice post-muerte de `Teams`.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd` y `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` pasan.

## Referencia persistente del modo HUD en el laboratorio (2026-04-22)

- Estado: el laboratorio ya no depende solo del `StatusLabel` temporal para recordar si el HUD quedo en modo explicito o contextual; el propio round-state deja visible `HUD | explicito/contextual | F1 cambia`.
- Correccion aplicada:
  - `scripts/main/main.gd` agrega `get_lab_hud_mode_summary_line()` y la suma dentro de `_build_round_state_lines()`.
  - la linea deriva directamente de `MatchController.get_hud_detail_mode_label()`, asi que sigue el override real de `F1` y tambien sobrevive al salto `F6` entre laboratorios sin otro estado paralelo.
  - `scripts/tests/lab_scene_selector_test.gd` fija la regresion: arranque explicito, cambio a contextual y persistencia de la misma lectura tras cambiar de escena.
- Resultado:
  - el flujo de laboratorio queda mas autoexplicativo para depurar/validar HUD dual en pantalla compartida.
  - `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` pasa.

## HUD vivo Teams sin marcador neutro en la apertura (2026-04-22)

- Estado: la apertura del laboratorio `Teams` ya no arranca con una línea de score 0-0 que todavía no explica nada del match.
- Corrección aplicada:
  - `scripts/systems/match_controller.gd` suma `_should_show_live_score_summary()`.
  - `FFA` sigue usando `_should_show_live_ffa_standings()` como antes.
  - `Teams` ahora muestra `Marcador | ...` solo cuando la ronda activa ya viene después de al menos una ronda decidida; recap y resultado final siguen mostrando score siempre que corresponde.
  - `scripts/tests/teams_live_scoreboard_opening_test.gd` fija la regresión: opening sin `Marcador | ...`, cierre de ronda con score visible otra vez.
- Resultado:
  - el inicio del round queda más limpio y cercano al beat documentado de análisis/lectura antes de que el match tenga información competitiva real.
  - `godot --headless --path . -s res://scripts/tests/teams_live_scoreboard_opening_test.gd`, `godot --headless --path . -s res://scripts/tests/ffa_live_standings_hud_test.gd`, `godot --headless --path . -s res://scripts/tests/match_round_recap_test.gd` y `godot --headless --path . -s res://scripts/tests/match_completion_test.gd` pasan.

## Referencia compacta de controles para el slot seleccionado (2026-04-22)

- Estado: el laboratorio ya no obliga a mirar solo el roster o el `StatusLabel` para recordar que hace el slot actualmente seleccionado; el propio HUD round-state deja una chuleta compacta y persistente de sus bindings reales.
- Correccion aplicada:
  - `scripts/main/main.gd` agrega `get_lab_selected_controls_summary_line()` y publica `Control Pn | ...` dentro de `_build_round_state_lines()` junto con `Escena | ...` y `Lab | ...`.
  - `scripts/robots/robot_base.gd` centraliza el texto en `get_control_reference_hint()`, reutilizando el perfil local real para `mueve`, `aim` si corresponde, `ataca`, `energia`, `overdrive` y `suelta`.
  - `scripts/tests/lab_runtime_selector_test.gd` fija la regresion concreta en tres pasos: linea presente al iniciar, `aim TFGX` visible al pasar `P1` a `Hard`, y migracion del resumen a `P2/flechas` al cambiar de slot.
- Resultado:
  - el selector runtime queda mas autoexplicativo en pantalla compartida, especialmente cuando el HUD esta en modo contextual y los jugadores alternan `Easy/Hard` sin salir de la escena.
  - `godot --headless --path . -s res://scripts/tests/lab_runtime_selector_test.gd`, `godot --headless --path . -s res://scripts/tests/hard_mode_bootstrap_test.gd`, `godot --headless --path . -s res://scripts/tests/lab_scene_selector_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 81 tests`).

## Resumen acumulado de cierres por causa en el final de match (2026-04-22)

- Estado: el recap lateral y el resultado final ya no muestran solo la causa del ultimo knockout; ahora tambien resumen la mezcla de rutas que cerraron rondas a lo largo de toda la partida.
- Correccion aplicada:
  - `scripts/systems/match_controller.gd` suma `_match_closing_cause_counts` y lo actualiza en `_finish_round_with_winner(...)` con la causa que dio los puntos de esa ronda.
  - `get_round_recap_panel_lines()` y `get_match_result_lines()` agregan `Cierres | ...` solo cuando `_match_over`, manteniendo `Causa bajas | ...` como lectura de la ronda final y separando ambas capas.
  - `scripts/tests/match_closing_cause_summary_test.gd` fija la regresion real en `Teams` y `FFA`: una ronda por `ring-out` y otra por `explosion inestable` deben terminar en `Cierres | ring-out 1 | explosion inestable 1`.
- Resultado:
  - el propio HUD final ya explica mejor el perfil de riesgo/recompensa del score ponderado por causa, sin abrir otro panel ni depender de notas externas.
  - `godot --headless --path . -s res://scripts/tests/match_closing_cause_summary_test.gd`, `godot --headless --path . -s res://scripts/tests/match_completion_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 81 tests`).

## Defaults runtime de `MatchConfig` alineados con el prototipo base (2026-04-22)

- Estado: crear `MatchConfig.new()` ya no produce un perfil runtime distinto al de `default_match_config.tres`.
- Corrección aplicada:
  - `scripts/systems/match_config.gd` ahora replica en sus defaults exportados los valores base que ya usaban las escenas del prototipo:
    - `local_player_count = 4`
    - `round_intro_duration_ffa = 1.0`
    - `round_intro_duration_teams = 0.6`
    - `void/destruccion/inestable = 2/1/4`
  - `scripts/tests/match_config_defaults_test.gd` agrega la regresión explícita y compara `MatchConfig.new()` contra `res://data/config/default_match_config.tres` en esos campos gameplay-facing.
- Resultado:
  - los tests o helpers que crean configs en memoria ya no quedan con timings/score viejos por accidente.
  - `godot --headless --path . -s res://scripts/tests/match_config_defaults_test.gd`, `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/match_elimination_victory_weights_test.gd`, `godot --headless --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 80 tests`).

## Volver al target default ya reactiva el auto-target del soporte (2026-04-22)

- Estado: la nave de apoyo `Teams` ya no arrastra un override manual stale si el jugador cicla de vuelta al mismo target que el auto-target ya habría elegido por defecto.
- Corrección aplicada:
  - `_cycle_selected_target()` ahora compara el target manual nuevo con `_get_default_support_target(candidates)`.
  - si ambos coinciden, la nave limpia `_manual_target_override` y recupera el comportamiento de resincronización automática cuando ese default envejece o se vuelve inmune.
  - `team_post_death_support_targeting_test.gd` suma la regresión concreta con `interferencia`: default útil -> ciclo manual al alternativo -> vuelta manual al default -> `estabilidad` sobre el default -> salto automático al alternativo útil.
- Resultado:
  - la distinción entre “override manual” y “modo auto” ahora depende del target realmente visible, no del historial del input.
  - `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_actionability_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 79 tests`).

## Redirección manual de buffs validada en `Teams` (2026-04-22)

- Estado: en el setup real `Teams` del prototipo actual, bloquear no-ops de `surge`/`movilidad` no deja a la nave de apoyo “clavada” sobre una mala selección manual.
- Medición aplicada:
  - `support_payload_actionability_test.gd` ahora reproduce una sesión corta con 3 robots vivos: el target por defecto arranca sobre el aliado útil, el jugador cicla a mano hacia el aliado saturado, el roster sigue marcando `ya activo`, el uso falla sin consumir y un único ciclo manual devuelve la carga al aliado útil.
  - no hubo cambio de gameplay en `PilotSupportShip`; la corrección previa ya era suficiente para el laboratorio `Teams` actual.
- Resultado:
  - el gating de no-ops mejora consistencia entre lectura y ejecución sin sumar fricción extra relevante en 2v2 con un único aliado alternativo.
  - `godot --headless --path . -s res://scripts/tests/support_payload_actionability_test.gd` y `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` pasan con el nuevo escenario de recuperación manual.

## `Surge` / `movilidad` ya no se consumen sobre targets redundantes (2026-04-22)

- Estado: la nave de apoyo `Teams` ya no quema una carga de buff sobre el mismo target que su roster ya marcaba como `ya activo`.
- Corrección aplicada:
  - `_resolve_support_target_for_payload()` ahora reutiliza `_is_payload_actionable_on_target(...)` en vez de dejar que `surge`/`movilidad` lleguen al `apply_*` aunque no fueran a agregar ventana real.
  - la regla no agrega otra capa de disponibilidad: reaprovecha exactamente la misma noción de accionabilidad que ya gobernaba el warning `ya activo` y la atenuación diegética del target.
  - nuevo `support_payload_actionability_test.gd` fija que ambas cargas fallen limpio y permanezcan disponibles cuando el objetivo ya conserva toda la ventana útil del buff.
- Resultado:
  - la lectura compacta y la ejecución del payload vuelven a coincidir; si el soporte dice `ya activo`, gastar la carga deja de ser posible hasta reorientarla hacia un aliado útil.
  - `godot --headless --path . -s res://scripts/tests/support_payload_actionability_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 79 tests`).

## Auto-target del soporte resincronizado en runtime (2026-04-22)

- Estado: la nave de apoyo `Teams` ya no queda clavada en un target default envejecido cuando ese objetivo pierde utilidad durante la ronda.
- Corrección aplicada:
  - `PilotSupportShip` ahora guarda si el target actual proviene del default automático o de un ciclo manual del jugador.
  - `_refresh_target_selection()` resincroniza al nuevo mejor target solo cuando el actual sigue en modo automático y dejó de ser accionable mientras otro candidato sí lo es.
  - el ciclo manual sigue mandando: `_cycle_selected_target()` marca override manual para que la nave no “corrija” una elección hecha a propósito por el jugador.
  - `team_post_death_support_targeting_test.gd` fija las dos caras del contrato con `interferencia`: target útil inicial + salto automático al siguiente rival afectable cuando el default envejece, y permanencia en el rival elegido por el jugador cuando la selección ya era manual.
- Resultado:
  - el support slice ya no queda alineado con utilidad real solo al recoger payloads; también se mantiene coherente cuando el estado de los robots cambia en vivo.
  - `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 79 tests`).

## HUD contextual limpia la causa vieja durante `Apoyo activo` (2026-04-22)

- Estado: si un jugador eliminado sigue aportando desde `PilotSupportShip`, el roster contextual ya no repite `vacio` u otra causa de baja dentro de la misma linea.
- Detalles:
  - `MatchController._build_robot_status_line()` mantiene `Apoyo activo` como estado, pero en HUD contextual omite `state_detail` cuando el soporte sigue vivo; el hint y el payload del support siguen entrando por `support_state`.
  - el HUD explicito conserva la causa de baja como hasta ahora, asi que el recorte solo limpia ruido en la variante contextual.
  - `hud_detail_mode_test.gd` suma la regresion concreta: la linea contextual del jugador eliminado debe incluir `Apoyo activo`, `get_support_input_hint()` y `sin carga`, pero no `vacio`.
- Validación:
  - `godot --headless --path . -s res://scripts/tests/hud_detail_mode_test.gd`, `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` y `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` pasan.

## Marcadores diegéticos del soporte alineados con payloads útiles (2026-04-22)

- Estado: la nave de apoyo `Teams` ya no deja el marcador superior ni la marca de piso en modo “listo” cuando el payload seleccionado no tendría efecto real.
- Corrección aplicada:
  - `PilotSupportShip` suma `_is_payload_actionable_on_target(...)` y reutiliza la utilidad real del payload para `stabilizer`, `surge`, `movilidad` e `interferencia`.
  - `SupportTargetIndicator` y `SupportTargetFloorIndicator` siguen visibles mientras hay target, pero ahora bajan intensidad cuando el caso ya cae en `sin daño`, `ya activo` o `estable`, igual que antes hacían para `fuera de rango`.
  - `InterferenceRangeIndicator` también dejó de tratar `en rango` como sinónimo de “útil”: ahora solo entra en estado brillante si el target además es accionable.
  - `support_payload_availability_readability_test.gd` fija el caso de `interferencia` con dos rivales en rango: default sobre el rival afectable y atenuación clara al ciclar al rival inmune por `estabilidad` en los tres cues diegéticos.
- Resultado:
  - el carril ya no contradice al jugador entre HUD y mundo; la explicación compacta y la lectura diegética del objetivo usan la misma noción de “payload útil ahora”.
  - `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 78 tests`).

## Interferencia inmune por `estabilidad` visible en roster (2026-04-22)

- Estado: el soporte post-muerte `Teams` ya no sugiere presión útil de `interferencia` sobre un rival que sigue protegido por `estabilidad`.
- Correccion aplicada:
  - `PilotSupportShip.get_status_summary()` ahora agrega `estable` si la carga actual es `interferencia` y el target seleccionado mantiene `stability_boost` activo.
  - el targeting por defecto de `interferencia` ahora tambien penaliza rivales inmunes, igual que ya evitaba reciclar targets no óptimos por rango o supresión.
  - `support_payload_availability_readability_test.gd` fija la advertencia textual y `team_post_death_support_targeting_test.gd` fija que, con dos rivales válidos, se priorice al que sí puede ser afectado.
- Resultado:
  - el carril ya no deja otra versión de fallo silencioso en el contrajuego `utility` vs soporte; el roster explica por qué el payload no entraría y el target inicial sigue mejor la utilidad real.
  - `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd` pasan.

## `Surge` / `movilidad` redundantes visibles en roster (2026-04-22)

- Estado: la nave de apoyo `Teams` ya explica cuando una carga de `surge` o `movilidad` no aportaria nada inmediato porque el aliado seleccionado ya conserva toda la ventana útil de ese buff.
- Correccion aplicada:
  - `PilotSupportShip.get_status_summary()` ahora agrega `ya activo` para `surge` y `movilidad` solo cuando reutilizar ese payload seria un no-op real sobre el target actual.
  - `surge` compara `get_energy_surge_time_left()` contra `support_energy_surge_duration`.
  - `movilidad` compara `get_mobility_boost_time_left()` contra la duración efectiva del target (`support_mobility_boost_duration * get_mobility_boost_duration_multiplier()`).
  - `support_payload_availability_readability_test.gd` fija ambos contratos y tambien cubre que la advertencia desaparezca sola cuando la ventana restante ya queda por debajo del valor real del payload.
- Resultado:
  - el carril ya no comunica “carga lista” cuando `surge` o `movilidad` serian redundantes sobre el objetivo seleccionado.
  - `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 78 tests`).

## Targeting de `surge` / `movilidad` alineado con ventana útil real (2026-04-22)

- Estado: la nave de apoyo `Teams` ya no deja el target inicial sobre el primer aliado buffeado si ese objetivo ya está completamente saturado.
- Correccion aplicada:
  - `PilotSupportShip` ahora puntúa `surge` y `movilidad` por la ventana útil que realmente agregaría el payload, no solo por el estado binario activo/inactivo.
  - la misma métrica gobierna tanto el warning `ya activo` como el targeting por defecto, evitando drift entre roster y gameplay.
  - `team_post_death_support_targeting_test.gd` ahora fija dos regresiones nuevas: multi-aliado saturado para `surge` y multi-aliado saturado para `movilidad`.
- Resultado:
  - si existe otro aliado que todavía ganaría segundos reales de buff, el soporte ya lo prioriza sin obligar al jugador a corregir el target manualmente en el primer frame.
  - `godot --headless --path . -s res://scripts/tests/team_post_death_support_targeting_test.gd`, `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd`, `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd`, `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 78 tests`).

## `Stabilizer` sin daño visible en roster (2026-04-22)

- Estado: la nave de apoyo `Teams` ya explica cuando una carga `estabilizador` todavia no puede reparar nada porque su aliado objetivo sigue completamente sano.
- Correccion aplicada:
  - `PilotSupportShip.get_status_summary()` ahora agrega `sin daño` para `stabilizer` si el target seleccionado no tiene ninguna parte activa averiada.
  - la regla reutiliza `_get_total_missing_active_part_health(...)`, asi que el warning se limpia solo cuando aparece una averia real y no abre otra UI.
  - nuevo `support_payload_availability_readability_test.gd` fija el contrato completo: warning presente con aliado sano y ausente apenas ese mismo aliado recibe daño modular.
- Resultado:
  - el roster ya no deja un segundo caso de fallo silencioso dentro del carril post-muerte; ahora `interferencia` y `stabilizer` explican por que su payload aun no aporta valor real.
  - `godot --headless --path . -s res://scripts/tests/support_payload_availability_readability_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 78 tests`).

## Interferencia fuera de rango visible en roster (2026-04-22)

- Estado: cuando `PilotSupportShip` lleva `interferencia` pero el rival seleccionado todavia no entra en `support_interference_range`, el HUD compacto ya explica por que el uso falla.
- Correccion aplicada:
  - `get_status_summary()` ahora agrega `fuera de rango` solo para ese caso puntual.
  - la regla vive en `PilotSupportShip`, asi que el roster y cualquier snapshot de `support_state` reutilizan el mismo texto sin abrir otra UI.
  - `team_post_death_support_test.gd` fija el contrato en dos pasos: advertencia presente mientras no hay rango real y advertencia ausente apenas el target entra en radio.
- Resultado:
  - la lectura de `interferencia` ya no depende solo del telegraph diegetico; el roster tambien explica el fallo de uso.
  - `godot --headless --path . -s res://scripts/tests/team_post_death_support_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 77 tests`).

## Nave de apoyo sin pickup gratis al aparecer (2026-04-22)

- Estado: en `Teams`, `PilotSupportShip` ya no arranca con un payload inmediato por aparecer encima de un pickup del carril.
- Correccion aplicada:
  - `PilotSupportShip` suma `spawn_pickup_grace_duration` y bloquea `_try_collect_support_pickup()` durante esa ventana inicial.
  - `get_status_summary()` ahora publica `sin carga` cuando la nave sigue activa pero todavia no lleva payload.
  - `live_roster_order_test.gd` fija que `Apoyo activo` no nazca ya armado; `team_post_death_support_test.gd`, `support_match_stats_test.gd` y `support_decisive_highlight_test.gd` esperan explicitamente el grace antes de recoger el primer pickup.
- Resultado:
  - el carril vuelve a exigir una decision/movimiento real antes del primer apoyo.
  - el roster distingue mejor soporte activo vacio vs soporte activo con payload listo.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa (`Suite OK: 77 tests`).

## Cleanup del soporte post-muerte cubierto en reset/restart (2026-04-22)

- Estado: el soporte post-muerte Teams ya tiene regresión explícita para evitar restos stale entre rounds o tras `F5`.
- Cobertura aplicada:
  - `support_lifecycle_cleanup_test.gd` valida dos caminos reales:
    - cierre de ronda no final -> `_reset_round()` -> ronda 2 sin nave, sin `support_state` y con carril externo apagado.
    - cierre de match -> `F5` -> `start_match()` limpio desde ronda 1, también sin restos del soporte previo.
  - el rojo inicial no reveló un bug de juego sino un falso supuesto del test: para lifecycle hubo que fijar `void_elimination_round_points`, `destruction_elimination_round_points` y `unstable_elimination_round_points` a `1`, porque el score ponderado actual puede cerrar el match en una sola ronda.
- Resultado:
  - el seam de cleanup del soporte ya no depende de revisión manual ni del test genérico de restart.
  - `godot --headless --path . -s res://scripts/tests/support_lifecycle_cleanup_test.gd` y `godot --headless --path . -s res://scripts/tests/match_manual_restart_test.gd` pasan.

## Roster `Apoyo activo` sin estado stale del robot caído (2026-04-22)

- Estado: en `Teams`, la línea de un jugador en `Apoyo activo` ya no conserva datos de combate del robot que acaba de quedar fuera.
- Corrección aplicada:
  - `MatchController._build_robot_status_line()` ahora corta `skill ...`, foco/resumen de energía, buffs temporales, `item ...` y otras banderas de combate cuando el robot está eliminado o inutilizado.
  - si el jugador sigue aportando desde `PilotSupportShip`, la línea conserva solo `Apoyo activo | <causa>` y el `support_state` vigente (`usa ...`, `interferido`, `payload > objetivo`).
  - `live_roster_order_test.gd` fija la regresión creando adrede un robot caído con `pulse_charge`, `energy surge` y `core skill` todavía activos para asegurar que esos segmentos no vuelvan al roster.
- Resultado:
  - el roster vivo ya no mezcla “qué podía hacer el robot muerto” con “qué puede hacer la nave ahora”, reforzando lectura táctica sin otra UI.
  - `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 76 tests`).

## Controles del soporte en roster explicito (2026-04-22)

- Estado: en `Teams`, una baja con `PilotSupportShip` ya no deja dos hints de control contradictorios en la misma linea del roster explicito.
- Correccion aplicada:
  - `MatchController._build_robot_status_line()` deja de anexar `robot.get_input_hint()` cuando `has_active_support` es verdadero.
  - el hint valido sigue entrando por `support_state`, armado desde `PilotSupportShip.get_status_summary()`.
  - `live_roster_order_test.gd` ahora fija tambien que la linea del jugador eliminado conserve `get_support_input_hint()` y no vuelva a mostrar `get_input_hint()`.
- Resultado:
  - el roster explicito ya no mezcla “como manejaba el robot” con “como usa la nave de apoyo”, reforzando legibilidad sin abrir HUD nuevo.
  - `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` y `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasan (`Suite OK: 76 tests`).

## Roster vivo de apoyo activo (2026-04-22)

- Estado: en `Teams`, un jugador eliminado que sigue influyendo con `PilotSupportShip` ya no se lee como una baja completamente cerrada en el roster vivo.
- Corrección aplicada:
  - `MatchController._build_robot_status_line()` ahora publica `Apoyo activo | <causa>` cuando el robot ya cayó pero todavía tiene `support_state`.
  - `PilotSupportShip.get_status_summary()` compacta el texto del roster a hints útiles (`usa ...`, `interferido`, `payload > objetivo`) sin repetir el prefijo `apoyo`.
  - `live_roster_order_test.gd` y `team_post_death_support_test.gd` fijan el contrato nuevo en HUD vivo y en el slice post-muerte Teams.
- Resultado:
  - el jugador muerto sigue siendo legible como actor relevante del round, no como una línea más de eliminados.
  - `godot --headless --path . -s res://scripts/tests/live_roster_order_test.gd` pasa.

## Highlight de apoyo decisivo en el cierre (2026-04-22)

- Estado: el soporte post-muerte Teams ya no queda solo como telemetría agregada; el cierre ahora explica qué acción concreta acompañó la ronda decisiva.
- Corrección aplicada:
  - `Main._on_post_death_support_payload_used(...)` ahora reenvía también el `target_robot` real hacia `MatchController`.
  - `MatchController.record_support_payload_use(...)` conserva un highlight compacto por competidor y por ronda con formato `Apoyo decisivo | <owner> <payload> > <objetivo>`.
  - `get_round_recap_panel_lines()` y `get_match_result_lines()` muestran ese highlight solo para el ganador de la ronda en `Teams`, sin añadirlo al HUD vivo.
  - `support_decisive_highlight_test.gd` fija la regresión nueva y `support_match_stats_test.gd` / `match_highlight_moments_test.gd` siguen verdes con el contrato extendido.
- Resultado:
  - el cierre ya no dice solo “hubo apoyo”; también deja visible si la jugada decisiva fue, por ejemplo, `energia` o `estabilizador`, y sobre quién cayó.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 76 tests`.

## Warning previo de contracción (2026-04-22)

- Estado: la presión final del arena ahora se lee también antes de que el borde vivo empiece a cerrarse.
- Corrección aplicada:
  - `MatchController` suma `space_reduction_warning_seconds`, calcula `get_time_until_space_reduction()` / `get_space_reduction_warning_strength()` y publica `Arena se cierra en Xs` mientras la contracción todavía no arrancó.
  - `Main._apply_match_pressure_to_arena()` ahora cablea tanto la escala real del área segura como la intensidad del warning.
  - `ArenaBase` agrega `set_pressure_warning_strength()` y reutiliza `PressureTelegraph` con intensidad baja para preview, sin mover todavía el borde vivo.
  - `progressive_space_reduction_test.gd` y `arena_pressure_telegraph_test.gd` fijan el contrato nuevo en HUD + telegraph diegético.
- Resultado:
  - el cierre acompaña mejor el beat documentado de análisis -> escalada -> final explosivo.
  - `godot --headless --path . -s res://scripts/tests/test_runner.gd` pasa con `Suite OK: 75 tests`.

## Targeting util del soporte post-muerte Teams (2026-04-22)

- Estado: la nave de apoyo ya no fija por defecto el primer aliado/rival valido cuando hay varios candidatos vivos.
- Correccion aplicada:
  - `PilotSupportShip` ahora ordena candidatos por prioridad segun payload y reutiliza ese mismo orden para la seleccion por defecto y el ciclado manual.
  - `stabilizer` prioriza el aliado con mayor vida faltante en partes activas.
  - `surge` y `mobility` ahora miden ventana útil real del buff, asi que tambien evitan defaults redundantes cuando existe otro aliado mas util.
  - `interference` prioriza rivales en rango y no suprimidos antes de volver a distancia/player order.
  - `team_post_death_support_targeting_test.gd` fija cuatro regresiones concretas: multi-aliado para `stabilizer`, multi-rival para `interference` y multi-aliado saturado para `surge/movilidad`.
- Resultado:
  - el loop Teams reduce dependencia de coordinacion perfecta cuando el soporte tenga mas de un objetivo vivo.
  - `team_post_death_support_test.gd`, `support_match_stats_test.gd` y el nuevo test de targeting pasan con el contrato actualizado.

## Apertura Teams coordinada (2026-04-22)

- Estado: `main.tscn` ya no arranca con un layout en cruz que separaba a aliados más de lo que acercaba a rivales.
- Corrección aplicada:
  - `scenes/arenas/arena_blockout.tscn` reubicó los cuatro `SpawnPlayer` en dos laterales (`Team 1` a la izquierda, `Team 2` a la derecha).
  - `scenes/main/main.tscn` quedó alineada con esos mismos offsets para que el editor y el runtime muestren la misma apertura.
  - `teams_spawn_coordination_test.gd` fija el contrato jugable: en escenas Teams, cada robot debe abrir más cerca de su aliado que del rival más cercano.
- Resultado:
  - `godot --headless --path . -s res://scripts/tests/teams_spawn_coordination_test.gd` pasa.
  - `main_scene_runtime_smoke_test.gd` y `teams_validation_lab_scene_test.gd` siguen verdes tras el cambio.

## Alineación de suite headless (2026-04-22)

- Estado: la suite completa `scripts/tests/*.gd` volvió a verde tras corregir falsos rojos de tests que seguían asumiendo contratos viejos de score/intro.
- Hallazgos principales:
  - varios tests FFA seguían hardcodeando `1` punto por cierre de ronda, aunque `MatchController` ya puntúa via `MatchConfig.get_round_victory_points_for_cause(...)`.
  - algunos tests de timing seguían anulando `MatchController.round_intro_duration`, pero el intro real ahora sale de `MatchConfig.round_intro_duration_ffa/teams`.
- Corrección aplicada:
  - `ffa_round_resolution_test.gd`, `ffa_live_scoreboard_order_test.gd`, `ffa_live_standings_hud_test.gd` y `ffa_match_result_standings_test.gd` ahora derivan score esperado desde `MatchConfig`.
  - `match_elimination_source_reset_test.gd` fija score `1/1/1` para seguir validando lifecycle entre rondas, no balance por causa.
  - `progressive_space_reduction_test.gd` y `team_post_death_support_test.gd` anulan `round_intro_duration_teams` en la config efectiva para no quedar presos del intro por modo.
- Resultado: `godot --headless --path . -s res://scripts/tests/test_runner.gd` vuelve a pasar con `Suite OK: 72 tests`.

## Smoke runtime de escenas principales (2026-04-22)

- Estado: las cuatro escenas jugables (`main.tscn`, `main_ffa.tscn`, `main_teams_validation.tscn`, `main_ffa_validation.tscn`) ahora tienen cobertura headless real de carga/instanciación vía `main_scene_runtime_smoke_test.gd`.
- Contratos fijados:
  - todas instancian `Main`, montan `MatchController`, `MatchHud`, un `ArenaBase` válido y exactamente cuatro robots jugables.
  - todas arrancan ronda real al bootear y siguen exponiendo el selector runtime de laboratorio (`Lab | ...`, `Escena | ...`).
  - `Teams` conserva parejas 2v2; `FFA` neutraliza `team_id` para no heredar alianzas falsas.
  - las escenas base también cargan `MatchConfig` en runtime porque `scenes/systems/match_controller.tscn` ya referencia `default_match_config.tres`; las escenas de validación sólo sobreescriben ese recurso.
- Resultado: la consistencia de escenas ya no depende sólo de revisar `ext_resource` en disco; hay una prueba de humo que captura wiring roto antes de llegar al editor o a playtests manuales.

## Validación de sensibilidad de combate (2026-04-22)

- Estado: el ajuste mínimo reciente de `RobotBase` quedó validado también en runtime; no hizo falta una segunda pasada de tuning.
- Hallazgo principal: `match_round_resolution_test.gd` y `match_completion_test.gd` estaban desalineados con el contrato actual de score por causa (`ring_out=2`, `destruccion=1`, `inestable=4`) y por eso daban falso rojo al validar cierre de ronda/partida.
- Corrección aplicada:
  - `match_round_resolution_test.gd` ahora deriva los puntos esperados desde `MatchConfig`.
  - `match_completion_test.gd` fija explícitamente los puntos de ronda a `1` para seguir validando lifecycle `first-to-X` y no balance por causa.
  - `robot_collision_pacing_test.gd` ahora cubre dos capas:
    - glide corto + umbral de daño por choque en `RobotBase`;
    - corrida runtime por 4 escenas con input programático real, log `PACING | ... | choque_significativo=...` y detección de `ring_out_antes_dano`.
  - el settle del glide corto se ajustó de `24` a `26` pasos de `0.1s` para seguir validando el mismo contrato con `glide_damping = 2.9`.
- Resultado:
  - `xvfb-run -a godot --path . -s res://scripts/tests/robot_collision_pacing_test.gd` pasa.
  - `xvfb-run -a godot --path . -s res://scripts/tests/main_scene_runtime_smoke_test.gd` pasa.
  - las 12 rondas runtime registradas dieron `choque_significativo=si` y `ring_out_antes_dano=no`, así que no quedó evidencia para retocar más el núcleo de choque.

## Mini-check documental (2026-04-22)

- Estado: revisión rápida contra `Documentación/01-10` sin contradicción crítica activa.
- Gaps todavía deliberados:
  - `FFA` sigue sin post-muerte definitivo; esto coincide con `Documentación/05_modos-de-juego.md`, donde esa regla permanece abierta.
  - el laboratorio sigue optimizado para 4 jugadores locales aunque la visión final contemple hasta 8; se mantiene así para proteger claridad y velocidad de iteración del núcleo de choque/rescate.

El proyecto ya tiene una base jugable en Godot 4.6 con:

- selector rápido de modo por slot dentro del laboratorio: `Main` ahora acepta `1-8` para alternar `Easy/Hard` del jugador correspondiente sin pasar antes por `F2`, y el estado del HUD cambia a `Lab: Pn ...` para confirmar el slot activo tras cada toggle
- score de apoyo mejor aterrizado en cierre: recap y resultado final ahora incluyen una línea global `Aporte de apoyo | X/Y rondas ...` y, dentro de `Stats | Equipo ...`, el segmento `rondas decisivas por apoyo ...` además del desglose por payload
- nueva línea base de tuning de arquetipos en recursos: `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla` ajustan multiplicadores base de empuje/daño/movilidad/recuperación para que el próximo playtest corto mida identidad con menos ruido de balance viejo
- soporte post-muerte Teams tambien consistente en identidad textual: la `PilotSupportShip` ya no vuelve a `Player X` pelado cuando resume el objetivo seleccionado; `apoyo ... > <objetivo>` reutiliza el mismo `Player / Arquetipo` del roster vivo para aliados y rivales
- cierre de ronda/partida con pesos por causa validado para 2 modos:
  - `MatchController` suma puntos de ronda por causa (`ring_out`, `destruccion total`, `explosion inestable`) y `match_elimination_victory_weights_test.gd` valida ese contrato en sesiones cortas de `Teams` y `FFA`.
  - el desempate interno y la frase final por modo siguen alineados con ranking real, por lo que la diferencia de puntuación de cierre solo hace más fuerte el riesgo/recompensa sin romper lectura.
- métricas de soporte post-muerte ya disponibles en cierre:
  - el resumen `Stats | ...` y las métricas por competidor ahora incluyen `support_use_total`, `support_payload_use_*` y `support_rounds_decided`.
  - esto habilita evaluar si el soporte cambia el ritmo real del cierre, y si ajustar `move_speed`, `respawn_delay` o `support gate timing` en lugar de tocar el núcleo de combate.
- roster compacto vivo mas coherente con el resto del match: `MatchController` ya no deja que las lineas por robot queden clavadas al scene-order mientras `Marcador`, `Posiciones`, recap y resultado final usan el orden competitivo real; ahora el roster reutiliza esos mismos comparators para mostrar antes al lider FFA o al aliado que sigue en pie dentro de Teams
- recap y resultado final tambien preservan mejor la identidad de roster: el detalle compacto por robot ya no vuelve a `Player X` pelado al cerrar ronda/partida, sino que conserva `Player X / <Arquetipo>` usando el mismo helper de nombre que el HUD vivo; asi el cierre explica quien sobrevivio, cayo o quedo inutilizado sin perder la lectura de rol
- stats de cierre mas claros: la linea `Stats | ...` del recap/resultado final ahora deja explicito `bajas sufridas N (...)` cuando resume eliminaciones acumuladas por causa, evitando que ese dato se lea como bajas infligidas cuando en realidad describe derrotas recibidas por el competidor
- cierre Teams mas coherente tambien en el detalle fino: `MatchController` ya no deja que el bloque por robot de recap/resultado final siga el orden fijo de la escena cuando gana el segundo equipo; ahora agrupa primero al equipo que sigue en pie, deja luego al derrotado y conserva el orden real de bajas dentro de ese equipo para que el cierre no contradiga la decision del match
- cierre FFA mas coherente tambien en la frase de victoria: cuando libre para todos cierra la partida, `MatchController` ya no recicla el wording `X-Y` de `Equipos`; ahora anuncia `Player X gana la partida con N punto(s)` y deja que `Marcador` / `Posiciones` expliquen el resto del ranking
- cierre FFA mas coherente tambien en el detalle fino: `MatchController` ya no deja que el bloque por robot de recap/resultado final siga el orden fijo de la escena; ahora reutiliza el mismo orden real de posiciones/desempate del match para que ganador, empates y primer eliminado queden alineados con `Marcador`, `Posiciones` y `Desempate`
- cierre FFA mas coherente tambien en la telemetria compacta: la linea `Stats | ...` del recap/resultado final ya no queda en el orden fijo de registro; ahora sigue el mismo ranking real del cierre para que ganador, empates y derrotados no mezclen standings correctos con stats stale
- apertura de ronda mas legible y menos brusca: `MatchController` ahora usa `MatchConfig` para resolver `round_intro_duration` por modo (`round_intro_duration_ffa` y `round_intro_duration_teams`) y muestra `Ronda N | arranca en ...`, congela el conteo real de ronda y mantiene el arena sin contraccion hasta liberar el control; `Main` baja ese estado a `RobotBase`, que bloquea movimiento, aim, ataque, overdrive y skill/throw solo durante ese beat inicial y lo acompaña con `RoundIntroIndicator`, un aro sobrio a ras del piso visible mientras el control sigue bloqueado para acercar el laboratorio al ritmo documentado de “inicio parejo -> analisis -> escalada”
- FFA abre con menos ruido en el HUD vivo: mientras toda la ronda sigue empatada y nadie fue eliminado, `MatchController` ya no imprime `Marcador | ...`, `Posiciones | ...` ni `Desempate | ...`; las tres lineas reaparecen juntas apenas el score o una baja vuelven esa lectura realmente util
- cierre de ronda/partida mas confiable a nivel explicacion: `MatchController` ya limpia la atribucion per-round de agresores cuando reinicia una ronda, asi que `RecapPanel` y `MatchResultPanel` no arrastran un `por Player X` stale si ese mismo robot cae sin agresor en la ronda siguiente
- desempate FFA mas explicito: `MatchController` ahora nombra el score empatado y el orden real dentro de cada empate (`Desempate | 0 pts: Player 3 > Player 2 > Player 1`) en HUD vivo, recap y resultado final, evitando que las posiciones empatadas parezcan arbitrarias
- defaults de HUD por modo ahora configurables desde `MatchConfig`: `hud_detail_mode_ffa` y `hud_detail_mode_teams` definen el estado inicial de HUD por modo en `MatchController` sin tocar el toggle runtime de `F1`, permitiendo que `Equipos` y `FFA` arranquen con ruido ajustado desde cada laboratorio.
- entrypoint comun de validacion restaurado: `scripts/tests/test_runner.gd` ahora corre la suite headless completa descubriendo todos los `*_test.gd` del proyecto y omitiendose a si mismo; `test_suite_runner_test.gd` deja cubierto el contrato minimo de discovery para que la automatizacion no vuelva a romperse en silencio.
- cleanup mas robusto del warning diegetico de explosion diferida: al salir del estado inutilizado, `RobotBase` vuelve a sincronizar en `_process()` la visibilidad de `DisabledWarningIndicator` con el estado gameplay real para que no quede `visible` stale durante el respawn.
- arena flotante legible con bordes visibles y caida al vacio
- camara compartida ortografica con seguimiento de los robots visibles
- un robot controlable placeholder con movimiento pesado al arrancar y mas libre al deslizar
- empuje pasivo por colision y embestida frontal simple
- estructura modular de 4 partes con vida propia
- destruccion de brazos y piernas con desprendimiento visual en escena
- penalizaciones funcionales:
  - piernas menos sanas reducen velocidad y control
  - brazos menos sanos reducen empuje y embestida
- redistribucion de energia discreta por foco de parte
  - foco en piernas mejora traccion/control y debilita brazos
  - foco en brazos mejora empuje/embestida y debilita movilidad
  - overdrive breve con recuperacion y cooldown no spameable
  - esa redistribucion ahora tambien se lee sobre el propio robot: `RobotBase` monta `EnergyFocusIndicator` sobre la pareja activa, deja la parte exacta del foco mas intensa y vuelve mas caliente la lectura cuando entra en `Overdrive`
- si un robot pierde su ultima parte con `Overdrive` activo, su explosion diferida pasa a una variante inestable con mayor radio/empuje/daño
- el cuerpo inutilizado ahora tambien deja un anillo diegetico sobre la arena con el radio real de su explosion pendiente; si nace desde `Overdrive`, ese mismo telegraph crece con la variante `inestable`
- soporte base de control Hard
  - el torso superior puede separarse del chasis con `UpperBodyPivot`
  - la orientacion de combate e impactos modulares en Hard usa esa referencia
  - el soporte actual sigue siendo mayormente joypad-first, pero el perfil `WASD` ya tiene aim por teclado (`TFGX`) y accion dedicada de lanzamiento (`C`) para que exista al menos un slot Hard/local totalmente jugable en laboratorio
  - `Main` puede asignar slots concretos a Hard y el HUD deja visible el mapping activo por slot en el estado inicial; el roster mantiene esa referencia durante la ronda
- selector runtime de laboratorio para comparar loadouts sin editar escenas
  - `Main` ahora deja ciclar slot/arquetipo/modo con `F2/F3/F4`, reinicia el match completo tras cada cambio y mantiene sincronizados roster, marcador FFA y la linea persistente `Lab | ...`
  - el slot elegido por ese selector ahora tambien prende `LabSelectionIndicator`, un anillo diegético sobrio a nivel piso sobre el robot activo, para que la referencia no dependa solo del texto del HUD
  - `RobotBase` ya puede reaplicar un `RobotArchetypeConfig` en runtime recuperando primero sus valores base, para que el cambio de arquetipo no acumule multiplicadores stale
  - `MatchController.start_match()` ahora invalida resets/restarts pendientes antes de recomenzar, evitando que el selector runtime deje timers viejos disparando sobre el laboratorio nuevo
- selector runtime de escena/laboratorio para acelerar playtests
  - `Main` ahora deja ciclar con `F6` entre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`, sin pasar por el editor de Godot
  - el HUD suma `Escena | ... | F6 cambia`, asi el laboratorio activo sigue legible mientras se compara Teams/FFA o base/rapido en pantalla compartida
  - ese cambio de escena ahora tambien preserva el estado activo del laboratorio (`slot` elegido, overrides `Easy/Hard`, `RobotArchetypeConfig` por jugador y HUD `explicito/contextual`) para no rearmar manualmente el setup al saltar entre variantes
  - `lab_scene_selector_test.gd` cubre el cambio real de escena, el wrap del ciclo completo y que loadout + HUD runtime sobrevivan al salto junto con la pista de HUD
- partes desprendidas con propietario original, pickup por cercania y retorno parcial
- transporte de partes que bloquea el ataque prototipo
- negacion basica de partes si el portador cae al vacio
- lectura diegetica de recuperacion modular: cada parte desprendida ahora muestra un disco de recuperacion sobre el suelo que se achica segun `cleanup_time`; el prototipo tambien expone `recovery_lost` para distinguir timeout/vacio sin acoplar todavia otra UI
- el robot dueño de una pieza recuperable ahora refuerza ese retorno con dos cues diegeticos complementarios: `RecoveryTargetIndicator` sobre chasis y `RecoveryTargetFloorIndicator` a nivel piso; ademas, `RobotBase` corrige el order-of-operations al spawnear `DetachedPart` para que ese tracking tambien quede vivo en `main.tscn` mientras un aliado transporta o relanza la pieza
- las negaciones exitosas al vacio ya tambien quedan acreditadas en el cierre: `DetachedPart` conserva el ultimo portador al perderse por `void`, `Main` lo traduce a `negaciones N` solo si quien la niega es rival del dueño original y `MatchController` reutiliza ese dato tanto en `RecapPanel` como en `MatchResultPanel`
- robot inutilizado al perder las cuatro partes, empujable y con explosion diferida antes de quedar fuera de ronda o reiniciar
- bootstrap local que deja cuatro robots humanos activos por defecto desde `main.tscn`
- perfiles de input separados por slot local para evitar compartir teclado/joypad por accidente
- escenario base 2v2 en `main.tscn` con dos equipos (pares por `team_id`) y 4 slots locales activos para validar rescate aliado y handoff en campo.
- laboratorio rapido de Teams en `scenes/main/main_teams_validation.tscn`, con la misma estructura 2v2 pero arena compacta (`arena_teams_validation.tscn`), `first-to-1`, rondas de 28s y reinicios cortos para reproducir rescates, negaciones y endgame sin esperar un match completo.
- primer slice de post-muerte para `Teams`:
  - cuando un robot queda fuera y aun sobrevive un aliado, `Main` crea una `PilotSupportShip` discreta bajo `SupportRoot`; usa el mismo input del jugador eliminado, avanza sobre un loop perimetral continuo ligado al tamaño vivo del arena y no participa del tracking de la camara
  - esa nave puede recoger pickups `estabilizador`, `energia`, `movilidad` o `interferencia` ocultos hasta que exista soporte activo; el payload queda visible en el roster como `apoyo ...` y al gastar la accion de utilidad repara la parte activa mas dañada, dispara una `energy surge` corta, aplica un impulso breve de movilidad sobre el aliado vivo o suprime por una ventana corta al rival elegido en el carril
  - el carril externo ya suma `gates` discretos que abren/cerran por ventana; si la nave intenta cruzar uno cerrado, queda `interferida` por un instante, el roster lo hace visible y el soporte gana una primera decision real de timing/ruta sin entrar en combate directo
  - esos `gates` ahora tambien muestran un `TimingVisual` diegetico sobre la propia compuerta; el fill se vacia segun el tiempo real que falta para abrir/cerrar, asi la nave ya no descubre el timing solo por prueba/error
  - los pickups del carril tambien reaparecen dentro de la misma ronda: el pedestal queda visible, el nucleo se apaga al consumirse y un `RespawnVisual` corto marca cuanto falta para que vuelva la carga, evitando que la capa post-muerte se quede sin decisiones tras una sola pasada
  - esos mismos pickups ahora tambien diferencian cada payload por silueta runtime (`PayloadAccentVisual`) y no solo por color: cilindro para `estabilizador`, barra para `energia`, barra inclinada para `movilidad` y esfera para `interferencia`, manteniendo el cue visible incluso durante cooldown
  - la nave ahora suma un `StatusBeacon` diegetico sobre el casco; mantiene un aro visible en idle y enciende un pulso/acento al cargar `payload` o quedar `interferida`, reforzando la lectura del carril sin HUD nuevo
  - cuando lleva payload, la nave ahora tambien puede ciclar objetivo con `energy_prev/next`; el roster expone `apoyo <payload> > <objetivo>`, un `SupportTargetIndicator` sobrio marca sobre el robot apuntado y `SupportTargetFloorIndicator` refuerza ese mismo target a nivel piso para que siga leyendose en pantalla compartida
  - cuando la carga equipada es `interferencia`, la nave tambien dibuja `InterferenceRangeIndicator`: un anillo sobrio sobre el piso, centrado en el ship y escalado con `support_interference_range`, que baja intensidad si el objetivo seleccionado aun queda fuera del radio real
  - esos tres cues (`SupportTargetIndicator`, `SupportTargetFloorIndicator`, `InterferenceRangeIndicator`) ahora tambien se sincronizan inmediatamente al guardar/gastar payload o al cambiar target, evitando un frame stale donde el mundo seguia mostrando una ayuda ya consumida
  - ese mismo roster ahora tambien recuerda el mapping real del soporte (`usa ... | objetivo ...`) segun el perfil del jugador eliminado, para que la nave siga siendo descubrible sin abrir otro panel
  - si el owner de la nave ya no tiene ningun aliado vivo al que asistir, `Main` poda esa `PilotSupportShip` en el acto y apaga el carril externo en el mismo sync, evitando apoyo/telegraphs stale hasta el reset de ronda
- el cierre de partida/recap lateral ya tambien acredita ese aporte en `Stats | ...`: el equipo suma `apoyo N (M usos: estabilizador 1, energia 1, ...)` segun cuantas cargas tomo y gasto su `PilotSupportShip`, sin abrir otra capa de post-match
- esa misma telemetria de cierre ahora ya no deja muda la negacion modular: un equipo rival que manda una pieza ajena al vacio suma `negaciones N`, haciendo mas legible el valor real del loop rescate/negacion sin otra pantalla
  - `FFA` mantiene la misma estructura base pero nunca instancia naves ni activa esos pickups, para no contaminar su identidad de supervivencia/oportunismo
- laboratorio FFA dedicado en `scenes/main/main_ffa.tscn`, reutilizando la misma arena/shared screen pero con `match_mode=FFA` y bootstrap que neutraliza las alianzas del layout 2v2 para que cada robot compita por su cuenta; ese mismo laboratorio ahora reemplaza los slots de `Grua` y `Cizalla` por `Aguja` y `Ancla` para probar poke + control/zona sin romper el 2v2 base
- el bootstrap FFA ya tambien diferencia el espacio inicial: en cuanto `match_mode=FFA`, `Main` genera spawns diagonales sobre un radio comun y hace mirar a cada robot hacia el centro, evitando que el laboratorio libre herede las lineas cardinales del 2v2
- laboratorio rapido FFA en `scenes/main/main_ffa_validation.tscn`, con `arena_ffa_validation.tscn`, `ffa_validation_match_config.tres`, `first-to-1`, rondas de 26s, reinicios cortos y radio de spawn FFA mas cerrado para reproducir third-party, rotacion de borde y cierres de ronda sin esperar el laboratorio libre base
- primera capa de identidad de arquetipos apoyada sobre sistemas ya existentes, mas cinco skills propias repartidas entre 2v2 y FFA:
  - `Ariete`: mas vida/empuje, mas resistencia al impulso externo y ahora `Embestida`, una ventana corta de drive/impacto/estabilidad que refuerza pusher/tank sin proyectiles
  - `Grua`: mejor retorno de partes, estabiliza otra pieza dañada al completar un rescate y ahora convierte `throw_part` en `Iman` cuando no lleva carga, capturando piezas listas a distancia media para validar asistencia/recuperacion activa
  - `Cizalla`: mas daño/pressure modular y bonus extra contra piezas ya tocadas para validar dismantle; ese castigo ahora tambien deja un cue corto `corte` en el roster, un pulso breve sobre `ArchetypeAccent` y un `DismantleCue` corto sobre la extremidad enemiga castigada cuando realmente conecta sobre una parte herida
  - `Patin`: mas velocidad/menos damping, ventanas de impulso mas largas y ahora `Derrape`, una rafaga corta de reposicion que empuja al robot en su direccion actual y abre una ventana breve de drive/control reforzados sin sumar proyectiles
  - `Aguja`: convierte la accion `throw_part` en `Pulso` cuando no lleva una parte, con 2 cargas recargables y el mismo `PulseBolt` repulsor como base para validar poke/skillshot limpio
  - `Ancla`: convierte esa misma accion en `Baliza`, una zona persistente corta que ralentiza drive/control rivales, evita apilar varias balizas por robot y deja `zona` visible en el roster cuando afecta a alguien
  - `RobotArchetypeConfig` vive en recursos `.tres`, `RobotBase` lo aplica al arrancar y tambien lo consulta al resolver `apply_impulse`, retornos, daño modular y boosts temporales, sin abrir otra UI
- cierre de ronda simple: el ultimo robot/equipo en pie suma una ronda y todos los robots vuelven juntos tras un delay corto
- cierre de match simple: el laboratorio juega a `first-to-3`; cuando un equipo alcanza el objetivo, el HUD anuncia al ganador de la partida y el match se reinicia limpio tras una pausa corta
- cierre FFA mas legible: cuando una ronda/partida libre termina, `MatchController` ahora agrega `Posiciones | 1. ...` al `RecapPanel` y al `MatchResultPanel`, usando score acumulado y el orden real de eliminacion de la ronda final para explicar mejor quien quedo segundo/tercero sin abrir otra pantalla; si hay score empatado, suma `Desempate | score igual -> mejor cierre de la ronda final` para que el ranking no parezca arbitrario
- esa misma lectura FFA ahora tambien vive en el HUD activo: la linea `Marcador | ...` ya no respeta el orden fijo de slots/escena, sino que ordena a los competidores segun score actual y desempate vigente, de modo que el lider real aparece primero mientras la ronda sigue abierta
- el HUD vivo FFA ya no obliga a esperar al recap para entender el ranking, pero tampoco ensucia la apertura: `MatchController.get_round_state_lines()` ahora repite `Posiciones | ...` y `Desempate | ...` solo cuando la ronda activa ya aporta ranking real (score divergente o alguna baja), reutilizando exactamente el mismo criterio de standings del cierre final y dejando el opening limpio mientras todos siguen empatados
- el `MatchResultPanel` centrado ahora tambien repite el detalle compacto por robot (`Player X | baja N | causa`) que antes solo vivia en el recap lateral, de modo que la vista principal de cierre ya explica por si sola como termino cada competidor en Teams y FFA
- ese mismo detalle compacto por robot ahora tambien agrega el estado final de extremidades (`N/4 partes | sin ...`) en recap y resultado final, reforzando el “como perdi”/“como sobrevivi” sin sumar otra capa de UI
- presion final de arena: el piso y sus edge markers se contraen de forma progresiva segun el tiempo de ronda, y el HUD agrega una linea corta cuando empieza el cierre
- lectura de presion reforzada: el `arena_blockout` ahora suma cuatro bandas sobrias sobre el piso, pegadas al borde vivo y visibles solo durante la contraccion para anunciar el cierre sin sumar otra capa de HUD
- incentivo real de borde: el arena blockout ahora tiene pickups de reparacion instantanea en los flancos; curan la parte activa mas dañada, obligan a exponerse cerca del vacio para estabilizarse y siguen el borde vivo cuando la arena se contrae
- segundo incentivo de borde: el mismo arena ahora suma pickups de movilidad en norte/sur; activan una ventana corta de traccion/control reforzados, exponen al robot en bordes sin cobertura y siguen el borde vivo cuando la arena se contrae
- tercer incentivo de borde: el mismo arena ahora suma pickups de energia en diagonales; cortan la recuperacion posterior al overdrive, refuerzan temporalmente el par energetico seleccionado y tambien siguen el borde vivo cuando la arena se contrae
- cuarto incentivo universal de borde: el mismo arena ahora suma pickups de `estabilidad`; limpian supresiones activas de `zona/interferencia`, bloquean nuevas durante una ventana corta, reducen algo el impulso externo recibido y tambien siguen el borde vivo cuando la arena se contrae
- ese intercambio `estabilidad` vs `zona/interferencia` ahora tambien se lee sobre el propio robot: `RobotBase` suma `StatusEffectIndicator` sobre `UpperBodyPivot`, con cue agua para resistencia activa y naranja para supresion vigente, en vez de depender solo del roster compacto
- primer item de una sola carga en mano: el mismo arena ahora suma pickups de pulso en las diagonales restantes; cargan un `pulso` visible en el robot, comparten slot con las partes transportadas y convierten el siguiente ataque en un disparo repulsor corto
- pickup de municion/carga de skill: el mismo arena ahora tambien puede habilitar pickups de `municion` que restauran una carga propia sobre `Grua`, `Aguja` o `Ancla`; `RobotBase` expone `restore_core_skill_charges()` para eso y el HUD publica `recargo municion...` cuando alguien lo disputa en borde
- skill propia de recuperacion: `RobotBase` ahora tambien puede resolver `Iman` desde `throw_part`; `Grua` captura la parte desprendida lista mas prioritaria dentro de `recovery_skill_pickup_range`, reusa el mismo slot de carga y deja `skill Iman x/y` visible en el roster del laboratorio 2v2
- primera skill propia por cargas: `RobotBase` ahora puede leer `core_skill_type/label/cargas/recarga` desde `RobotArchetypeConfig`; `Aguja` usa `Pulso` sobre la accion de utilidad cuando no lleva una parte, gasta una carga, recarga en segundo plano y deja `skill Pulso x/y` visible en el roster
- skill propia de impacto para `Ariete`: `RobotBase` ahora tambien resuelve `RAM_BOOST`; `Embestida` crea una ventana corta de drive + fuerza de impacto + resistencia al empuje externo, usa la misma accion de utilidad y deja `skill Embestida x/y` visible en el roster del laboratorio Teams
- lectura diegetica de skill propia reforzada: cuando un robot todavia tiene cargas de skill, `RobotBase` ahora pulsa sutilmente `Left/RightCoreLight`; en `Aguja` esto separa la skill `Pulso` lista del `pulse_charge` de borde, que sigue viviendo solo en el `CarryIndicator` dorado
- lectura diegetica de skill propia reforzada tambien sobre el arquetipo: `ArchetypeAccent` ahora hereda un pulso/emision del color de cada skill propia cuando quedan cargas, y sube otro escalon durante ventanas activas como `Embestida`; asi `Pulso/Iman/Baliza` no dependen solo del core y `Ariete` se compromete mejor en pantalla compartida
- lectura diegetica de `Embestida`: mientras dura la ventana activa, `RobotBase` calienta el core hacia naranja y `MatchController` agrega `embestida` al roster para que el commit de Ariete se lea sin otra UI
- lectura diegetica de arquetipo reforzada: `RobotArchetypeConfig` ahora declara `accent_style/accent_color` y `RobotBase` monta un `ArchetypeAccent` runtime sobre `UpperBodyPivot`; cada rol queda con una silueta chica propia (`bumper`, `mastil`, `cuchillas`, `aleta`, `pua`, `halo`) para que la identidad no dependa solo del roster.
- lectura diegetica de energia reforzada: la energia ya no depende solo de `CoreLight` + roster; `RobotBase` ahora agrega acentos chicos sobre brazos o piernas segun la pareja activa, con la extremidad exacta del foco/overdrive mas intensa para que movilidad vs empuje se lea tambien en mundo
- segunda skill propia por zona: `RobotBase` ahora tambien puede desplegar `Baliza` desde `throw_part`; `Ancla` deja una sola `ControlBeacon` activa por robot, aplica supresion temporal de drive/control y reutiliza el mismo roster compacto para mostrar `skill Baliza x/y` y el estado `zona`
- la ruta visual de control quedo endurecida: aplicar o limpiar `zona/interferencia` ahora refresca de inmediato ese `StatusEffectIndicator`, evitando que la supresion ya afecte gameplay/HUD pero siga muda en el cuerpo del rival
- rotacion semialeatoria controlada de borde: esos doce pedestales ya no quedan todos activos a la vez; `ArenaBase` usa un perfil `Equipos` de dos pares espejados por ronda y un perfil `FFA` de tres tipos activos por ronda, pero `Main` solo agrega `municion` al mazo cuando el roster actual realmente tiene varias skills propias compitiendo por ese recurso
- cobertura blockout de borde: el mismo arena ahora suma dos slabs simples junto a esos pickups; ayudan a preparar duelos y siguen el nuevo borde util cuando la arena se contrae
- HUD dual base configurable desde `MatchConfig`:
  - modo `explicito`: mantiene `Modo`, `Objetivo`, hints de control, `4/4 partes` y energia `Eq` siempre visibles en la misma UI compacta
  - modo `contextual`: oculta esa informacion estable y solo vuelve a exponer dano, redistribucion, buffs, items/cargas y partes perdidas cuando se vuelven tacticamente relevantes
  - `Main` ya puede alternar ambos modos en runtime con `F1`, usando un override local de sesion para playtests sin mutar el recurso compartido
  - ambos modos siguen reutilizando el mismo HUD compacto de ronda/roster y tambien resumen `Borde | ...` con los tipos activos de pickup de la ronda, incluyendo `municion` cuando entra al mazo actual
- lectura de eliminacion compacta en el mismo HUD:
  - robots inutilizados muestran cuenta atras breve de explosion en el roster
  - si la baja vino desde `Overdrive`, el mismo roster marca `inestable` antes de explotar
  - robots fuera conservan causa corta (`vacio`, `explosion` o `explosion inestable`)
  - el bloque superior recuerda la ultima baja con `Ultima baja | ...`
  - cuando la ronda ya cerro, el mismo bloque superior conserva `Resumen | ...` con el orden de bajas hasta el siguiente reset
- lectura del cuerpo inutilizado mas completa:
  - `RobotBase` suma `DisabledWarningIndicator`, un anillo pegado al piso que aparece solo mientras el robot sigue inutilizado
  - su radio coincide con `disabled_explosion_radius` y escala tambien en `inestable`, para alinear lectura y gameplay
  - el pulso vive en el propio marcador y se limpia al restaurar partes, explotar o respawnear
- recap de cierre visible solo fuera del combate:
  - `MatchController` ahora expone un recap estructurado (`Decision`, `Marcador` y estado final por robot) para la ronda o partida cerrada
  - ese mismo cierre ahora reutiliza la primera y la ultima baja completas como `Momento inicial | ...` / `Momento final | ...`, ofreciendo snippets textuales de jugadas importantes sin un sistema de replay aparte
  - `MatchHud` lo dibuja en un `RecapPanel` lateral oculto durante la ronda activa, de modo que la pelea sigue limpia y el detalle aparece solo cuando ya importa entender por que se perdio
- cierre de partida reforzado sin salir del laboratorio:
  - cuando el match termina, `MatchHud` ahora suma un `MatchResultPanel` centrado con `Partida cerrada`, ganador, marcador final, lineas `Stats | Equipo ...` y `Reinicio | F5 ahora o Xs`
  - `MatchController` agrega esa telemetria simple por competidor usando los hooks ya existentes de rescate, pickups de borde, destruccion de partes y causas finales de baja (`vacio`, `explosion`, `explosion inestable`)
  - esa linea ahora tambien distingue desgaste modular acumulado con `partes perdidas N (brazos/piernas)` para explicar mejor por que un equipo llego roto al cierre
  - `Main` permite reiniciar el laboratorio de inmediato con `F5` solo durante `_match_over`, manteniendo el recap lateral como detalle secundario en vez de abrir otra escena de post-partida
- timers de reinicio/respawn ahora son propios y cancelables:
  - `MatchController` usa un `TransitionTimer` interno para reset de ronda y reinicio de match, en vez de `SceneTreeTimer` efimeros
  - `RobotBase` usa un `RespawnTimer` propio para vacio/cuerpo inutilizado, de modo que un reinicio manual o cambio de laboratorio no deja callbacks stale ni leaks
- negacion por lanzamiento: un jugador que lleva una parte puede lanzarla para negarla sin esperar una caída al vacio
- ritmo de duelo 2P ajustado: movimiento más estable al corregir, empuje/presión de impacto más claros para favorecer el ciclo de tanteo->choque->castigo sin spam de contactos frágiles.
- indicador de carga visible en mundo: un estado de "parte en mano" se muestra con indicador pulso-orbital por parte.
- lectura diegética de daño modular: cada extremidad ya puede mostrar `Smoke` cuando está dañada y `Spark` cuando entra en estado crítico; además, brazos y piernas dañados aflojan su propia pose (`caen` o `arrastran`) para reforzar “pieza floja” sobre el robot mismo. Todo vive sobre la pieza, no en el HUD, y desaparece al repararla o perderla.
- lectura diegética de ventana de rescate: las partes desprendidas ahora también usan un disco plano sobre el piso que reduce su escala y calienta su color conforme se consume la recuperación posible.
- lectura diegética de identidad en pantalla compartida: cada robot ahora reutiliza `FacingMarker` + `CoreLight` como acento visual ligero por equipo/jugador, y las partes desprendidas agregan un aro fino de pertenencia con ese mismo color para que rescate/negacion y oportunismo FFA se entiendan sin otro HUD.
- lectura diegética del objetivo de retorno: `RobotBase` ahora crea un `RecoveryTargetIndicator` runtime sobre el chasis y `DetachedPart` registra su ciclo de vida contra el robot dueño, de modo que el objetivo de devolución queda visible mientras exista una pieza recuperable y se apaga al devolverla o negarla.
- lectura diegética del portador reforzada: cuando un robot transporta una `DetachedPart`, `CarryIndicator` sigue marcando el tipo de pieza y ahora suma `CarryOwnerIndicator`, un aro fino con el color del dueño original para conservar el contexto de rescate/negación también durante el traslado.
- lectura diegética del retorno durante el carry: ese mismo portador ahora suma `CarryReturnIndicator`, una aguja corta teñida con el color del dueño que apunta hacia el robot original mientras la pieza sigue en mano, para que el rescate siga leyéndose incluso en movimiento.
- lectura diegética del handoff lista: cuando el portador entra al radio real de retorno, `CarryReturnIndicator` sube intensidad y el `RecoveryTargetFloorIndicator` del dueño tambien se enciende mas fuerte, para que devolver la pieza deje de depender de calcular distancia “a ojo”.
- validacion 2v2 automatizada del loop de rescate/negacion: `main.tscn` ya se cubre con un test que comprueba pickup aliado, color/visibilidad del indicador y bloqueo temporal tras lanzamiento.
- validacion automatizada del laboratorio rapido de Teams: `teams_validation_lab_scene_test.gd` comprueba que `main_teams_validation.tscn` preserve modo Equipos, `MatchConfig` corto, arena compacta, spawns mas cercanos al conflicto y la lectura `Borde | ...` en el HUD.
- validacion automatizada del cierre de ronda: `main.tscn` ya comprueba victorias por vacio y por destruccion total con reset de ronda, scoreboard y ahora tambien un resumen compacto del orden de bajas.
- validacion automatizada del nuevo beat de apertura: `round_intro_countdown_test.gd` comprueba sobre `main.tscn` que el HUD anuncie el countdown, que cada robot exponga `RoundIntroIndicator` mientras dura el lock, que el input siga bloqueado durante ese intro y que el cue desaparezca apenas vuelve el control; los tests que fuerzan gameplay en frame cero (`team_post_death_support_test.gd`, `support_match_stats_test.gd`, `progressive_space_reduction_test.gd`) anulan ese intro dentro del propio test para seguir midiendo su sistema real
- validacion automatizada del cierre de partida reforzado: `match_completion_test.gd` ahora cubre tambien el panel final + stats simples + desgaste modular acumulado + linea `Reinicio | F5...`, `match_modular_loss_stats_test.gd` fuerza brazos/piernas perdidos por equipo para validar el nuevo resumen, y `match_manual_restart_test.gd` verifica reinicio manual inmediato con score limpio sobre `main.tscn`.
- validacion automatizada FFA: `ffa_mode_bootstrap_test.gd`, `ffa_lab_scene_test.gd` y `ffa_round_resolution_test.gd` comprueban que el laboratorio libre no hereda alianzas falsas del setup 2v2, mantiene el marcador individual y resuelve una ronda completa con ganador por robot
- validacion automatizada del cierre FFA: `ffa_match_result_standings_test.gd` comprueba sobre `main_ffa.tscn` que recap y resultado final publiquen la linea `Posiciones | ...` con winner, runner-up y resto del orden final, y que el mismo cierre explicite tambien el orden real dentro de cada empate
- validacion automatizada del detalle Teams: `team_match_result_detail_order_test.gd` fuerza una victoria de `Equipo 2` para comprobar que recap y resultado final ya no dependan del scene-order y mantengan primero al ganador, luego al perdedor en su orden real de bajas
- validacion automatizada del marcador vivo FFA: `ffa_live_scoreboard_order_test.gd` fuerza una primera victoria de un robot que no ocupa el primer slot para comprobar que `Marcador | ...` lo suba al frente del HUD en vez de conservar el orden fijo de la escena
- validacion automatizada de standings vivos FFA: `ffa_live_standings_hud_test.gd` comprueba sobre `main_ffa.tscn` que `get_round_state_lines()` publique `Posiciones | ...` y un `Desempate | ...` ya aterrizado con nombres/orden reales durante la ronda, sin depender solo del recap o del panel final
- validacion automatizada del laboratorio rapido FFA: `ffa_validation_lab_scene_test.gd` comprueba que `main_ffa_validation.tscn` preserve modo FFA, `MatchConfig` corto, arena compacta, spawns diagonales mas cercanos al conflicto y la lectura `Modo | FFA` + `Borde | ...` en el HUD
- validacion automatizada de explosion inestable: `robot_unstable_explosion_test.gd` compara la variante base contra la version nacida en `Overdrive`, y `match_unstable_explosion_readability_test.gd` verifica su lectura compacta en `main.tscn`
- validacion automatizada del telegraph de explosion: `robot_disabled_warning_indicator_test.gd` comprueba que el anillo nace oculto, aparece al inutilizarse, refleja radio estable/inestable y desaparece al salir de ese estado
- validacion automatizada de limpieza proactiva de partes: `main_detached_part_cleanup_test.gd` valida `detached_part_cleanup_limit` en `main.tscn`, incluyendo reintento entre rondas y preservación de partes en mano durante la limpieza de piso.

## Lo completado en esta iteracion

- Se volvio realmente testeable el HUD dual dentro del laboratorio:
  - `MatchController` ahora admite un override local del detalle HUD y mantiene `MatchConfig` como default de arranque, en vez de mutar el recurso compartido
  - `Main` expone `cycle_hud_detail_mode()` y lo cablea a `F1` para comparar `explicito/contextual` durante una partida real sin salir de la escena
  - `hud_runtime_toggle_test.gd` cubre el cambio live del HUD y valida que una escena nueva siga arrancando en `EXPLICIT`
- Se agregó la primera capa reusable de arquetipos sin abrir un sistema nuevo de selección:
  - existe un recurso nuevo `RobotArchetypeConfig` con multiplicadores simples de movimiento, aguante, empuje, daño y rescate
  - `RobotBase` ahora puede exportar un `archetype_config`, aplicarlo al arrancar y exponer `get_archetype_label()` / `get_roster_display_name()` para HUD/tests
  - `main.tscn` asigna `Ariete`, `Grua`, `Cizalla` y `Patin` a los cuatro slots del laboratorio base; `main_ffa.tscn` reutiliza esa base pero ya puede sobrescribir slots concretos del roster
- Se abrió una primera tanda de skills propias sin romper el laboratorio 2v2:
  - `RobotArchetypeConfig` ahora tambien puede declarar `core_skill_type`, `core_skill_label`, `core_skill_max_charges`, `core_skill_recharge_seconds` y multiplicadores del proyectil
  - `RobotBase` expone `has_core_skill()`, `use_core_skill()` y `get_core_skill_status_summary()`, y reaprovecha `throw_part` cuando el robot no carga una pieza para no abrir botones nuevos
  - `Grua` vive en `data/config/robots/grua_archetype.tres` y usa `Iman`, una captura magnetica de piezas listas que prioriza propias/aliadas y refuerza el rescate aliado del laboratorio 2v2 sin abrir otra escena o inventario
  - `Aguja` vive en `data/config/robots/aguja_archetype.tres` y se expone primero en `main_ffa.tscn`, de modo que el laboratorio libre gane poke/skillshot mientras `main.tscn` conserva `Grua` como rol de rescate activo
  - `robot_core_skill_test.gd` cubre recurso, gasto/recarga de cargas, empuje/daño del disparo, que `Pulso` no nazca solapado con su robot origen y lectura del roster FFA
- Se completó el sexto arquetipo documentado sin abrir otro sistema de habilidades:
  - `Ancla` vive en `data/config/robots/ancla_archetype.tres` y usa `Baliza`, una `ControlBeacon` persistente corta que ralentiza drive/control rivales dentro del area
  - `RobotBase` limita `Baliza` a una sola instancia activa por robot y la vuelve a desplegar desde `throw_part`, manteniendo el mismo contrato de input/cargas que ya usabamos para `Aguja`
  - `MatchController` solo agrega `zona` al roster cuando el efecto esta activo, evitando otra capa de HUD
  - `robot_control_skill_test.gd` cubre recurso, despliegue/reemplazo de baliza, supresion sobre rival y lectura del roster FFA
- Se profundizó esa identidad del roster sin abrir skills activas ni escenas nuevas:
  - `RobotArchetypeConfig` ahora tambien define hooks livianos de pasiva (`received_impulse_multiplier`, `return_support_repair_ratio`, `damaged_part_bonus_damage_multiplier`, `mobility_boost_duration_multiplier`)
  - `RobotBase` los consume en `apply_impulse`, `restore_part`, `receive_attack_hit_from_robot` / `receive_collision_hit_from_robot` y `apply_mobility_boost`, reutilizando sistemas ya legibles en el laboratorio
  - `robot_archetype_passive_test.gd` cubre que `Ariete`, `Grua`, `Cizalla` y `Patin` ya no dependen solo de multiplicadores base para diferenciarse
  - `robot_ram_skill_test.gd` cubre recurso, ventana de buff, expiracion limpia y lectura del roster Teams para `Embestida`
- Se hizo visible esa identidad de roster sin tocar la capa de UI:
  - el roster compacto ahora muestra `Player X / <Arquetipo>`
  - el marcador FFA conserva `Player X` pero agrega `[<Arquetipo>]` para que score y round flow sigan legibles sin romper los textos de eliminación ya existentes
  - `robot_archetype_roster_test.gd` cubre recursos, wiring de escena, diferencias de stats y visibilidad en HUD/marcador
- Se volvio configurable el nivel de detalle del HUD sin abrir otra escena/UI:
  - `MatchConfig` ahora expone `hud_detail_mode` para alternar entre `EXPLICIT` y `CONTEXTUAL`
  - `MatchController` filtra las mismas lineas de ronda/roster en vez de duplicar widgets; `Main` solo refresca el HUD existente
  - `hud_detail_mode_test.gd` cubre el contrato completo sobre `main.tscn`: default explicito, ocultamiento de ruido estable en contextual y reaparicion contextual de foco/item/partes perdidas

- Se agrego un resumen compacto del cierre de ronda sobre el mismo HUD:
  - `MatchController` ahora conserva `Resumen | ...` con el orden de bajas solo cuando la ronda ya termino, sin ensuciar el estado activo del combate
  - el dato se limpia al iniciar la siguiente ronda para no arrastrar contexto stale
  - `match_round_recap_test.gd` cubre la presencia del resumen durante el reset y su limpieza al volver a `Ronda N en juego`
- Se cerro la ruta de alto riesgo del overdrive sin agregar un sistema nuevo:
  - `RobotBase` ahora recuerda si el cuerpo inutilizado nacio con `Overdrive` activo y, en ese caso, escala `radio/empuje/daño` de la explosion diferida
  - la propia lectura del robot se calienta visualmente durante esa cuenta regresiva para que el estado sea visible aun sin mirar solo el texto
- Se integró esa variante al flujo real de match:
  - `Main` ya distingue `explosion` vs `explosion inestable` al registrar la baja
  - `MatchController` refleja `inestable` mientras el casco espera explotar y conserva la causa corta correcta en roster + `Ultima baja`
- Se cubrio la nueva ruta con tests dedicados:
  - `robot_unstable_explosion_test.gd` comprueba que la version inestable supera a la explosion base a igual distancia
  - `match_unstable_explosion_readability_test.gd` verifica la lectura compacta completa sobre `main.tscn`
- Se diferenció la rotación de pickups de borde por modo y se volvió visible en el HUD existente:
  - `ArenaBase` ahora conserva `Equipos` con dos pares espejados por ronda, pero en `FFA` rota layouts `3-de-4` para dejar seis pickups activos / tres tipos por ronda
  - `Main` configura ese perfil según `MatchController.match_mode` antes de arrancar el match y agrega `Borde | ...` al bloque compacto de estado
  - `edge_pickup_layout_rotation_test.gd` ahora cubre tanto la escena principal `main.tscn` como `main_ffa.tscn`, verificando densidad FFA, presencia de `pulso` y avance del layout entre rondas
- Se convirtió el borde fijo en una rotación semialeatoria controlada:
  - `ArenaBase` ahora arma un mazo seedado con los cuatro cruces base (`repair/energy` x `mobility/pulse`) y activa solo dos pares espejados por ronda
  - `MatchController` emite `round_started` y `Main` reaplica ese layout al inicio de cada ronda real, sin meter un director de match nuevo
  - los pickups de borde ahora exponen `is_spawn_enabled()` / `set_spawn_enabled()` para apagarse completos cuando su pedestal no forma parte del layout actual, manteniendo el telegraph base+núcleo cuando sí están activos
- Se ajustó la validación existente al nuevo contrato de mapa:
  - `edge_pickup_layout_rotation_test.gd` cubre arena aislada + `main.tscn`, verificando 4 pickups activos por ronda, pares espejados y avance de layout tras reset
  - los tests de movilidad, energía y pulso sobre `main.tscn` ya buscan un pickup realmente activo antes de validar roster/HUD
- Se reforzó la lectura en mundo del borde sin abrir otro HUD:
  - los seis `edge pickups` ahora suman un `Visuals/Accent` propio en la escena, con firma sobria por tipo para que `repair`, `mobility`, `energy`, `pulse`, `charge` y `utility` no dependan solo del color del núcleo
  - ese acento queda visible también durante cooldown porque vive en el mismo pedestal persistente del pickup
  - `edge_pickup_silhouette_test.gd` fija el contrato de siluetas distintas + material emisivo por pickup
- Se agregó el primer item universal de una sola carga en mano:
  - existe una escena nueva `edge_pulse_pickup.tscn` con pedestal persistente, cooldown visible y contrato de pickup equivalente al resto de incentivos de borde
  - al tocarla, `RobotBase` guarda `pulse_charge`, reaprovecha `CarryIndicator`, muestra `item pulso` en el roster y no permite mezclar la carga con una `DetachedPart`
  - al usar el mismo botón de ataque, el robot consume la carga y dispara `PulseBolt`, un proyectil corto que empuja y daña al primer robot/cobertura que encuentra
- Se integró ese item al laboratorio real sin abrir todavía un sistema completo de skills:
  - `arena_blockout.tscn` suma dos pickups de pulso en las diagonales libres para complementar reparación lateral + impulso norte/sur + energía diagonal
  - `Main` publica una línea breve cuando alguien asegura el item y `MatchController` mantiene el estado visible mientras la carga sigue guardada
  - `edge_pulse_pickup_test.gd` cubre API del robot, telegraph de cooldown, disparo repulsor, integración en `main.tscn` y reposicionamiento con contracción
- Se agrego el pickup universal de energia que faltaba en el mapa:
  - existe una escena nueva `edge_energy_pickup.tscn` con pedestal persistente, cooldown visible y contrato de activacion equivalente al resto de pickups de borde
  - al tocarla, `RobotBase` corta la recuperacion post-overdrive, reaplica el foco energetico actual y activa una recarga breve sobre ese mismo par
  - el roster compacto agrega `energia` mientras dura la ventana y `Main` publica una linea corta cuando alguien recarga en borde
- Se integró esa recarga al laboratorio real sin abrir otra rama de items:
  - `arena_blockout.tscn` suma dos pickups de energia en diagonales expuestas para complementar reparacion lateral + impulso norte/sur
  - `ArenaBase` no necesitó código extra porque la escena nueva usa el mismo grupo `edge_pickups` y hereda el seguimiento con contracción ya existente
  - `edge_energy_pickup_test.gd` cubre API del robot, telegraph de cooldown, integración en `main.tscn` y reposicionamiento con contracción
- Se hizo visible el modo activo del laboratorio en el HUD de ronda:
  - `MatchController.get_round_state_lines()` ahora agrega `Modo | FFA` o `Modo | Equipos`
  - esto deja claro que `main_ffa.tscn` no es solo “la misma escena con otros scores”, sino un laboratorio libre ya legible desde el estado principal
- Se reforzo la lectura de bajas sin sumar HUD nuevo:
  - `MatchController.get_robot_status_lines()` ahora deja visible `Inutilizado | explota Xs` mientras un robot espera su explosion diferida
  - al quedar fuera, el roster conserva la causa corta (`vacio` o `explosion`) y el bloque superior agrega `Ultima baja | ...`
  - esto cubre mejor la necesidad de “entender por que perdi” con la misma capa compacta que ya usaba el laboratorio
- la atribucion del rival responsable ya tambien se conserva dentro de esa misma capa:
  - `RobotBase` recuerda por una ventana corta el ultimo rival que aplico empuje/daño relevante, incluyendo choque, ataque, proyectil y explosion diferida
  - `Main` pasa ese dato a `MatchController` cuando una baja termina en `void` o `explosion`, y el HUD extiende `Ultima baja | ...`, `Resumen | ...`, `RecapPanel` y `MatchResultPanel` con `por Player X` cuando la autoria sigue siendo confiable
- Se cubrió el cierre real de ronda FFA en la escena dedicada:
  - `ffa_round_resolution_test.gd` elimina tres robots en `main_ffa.tscn`
  - valida ganador individual, marcador por robot y persistencia de la línea `Modo | FFA`
  - además drena los timers de ring-out antes del teardown para no dejar warnings/leaks engañosos
- Se expuso un laboratorio FFA real sin duplicar logica de bootstrap:
  - `scenes/main/main_ffa.tscn` hereda el laboratorio principal y solo fija `MatchController.MatchMode.FFA`
  - `Main` ahora neutraliza `team_id` de los robots cuando el match arranca en FFA, evitando que el rescate/negacion trate a rivales como aliados por reutilizar el layout 2v2
  - el scoreboard y el roster siguen leyendo a cada robot como competidor individual
- Se agrego el primer cierre de ronda real del prototipo:
  - `MatchController` deja de ser solo registro pasivo y ahora detecta al ultimo robot/equipo en pie
  - una baja por vacio o por explosion saca al robot de la ronda actual
  - el ganador suma un punto y la escena reinicia todos los robots juntos tras una pausa breve
  - `main.tscn` pasa a usar modo Teams por defecto para el laboratorio 2v2
- Se completo el cierre de match minimo que faltaba:
  - `MatchConfig` ahora define `rounds_to_win`
  - `MatchController` corta la partida cuando un competidor alcanza ese objetivo
  - el estado visible cambia de "gana la ronda" a "gana la partida X-Y"
  - el laboratorio espera una pausa corta y reinicia el match completo para mantener la escena jugable sin intervención extra
- Se agrego la primera base real de Control Hard:
  - `robot_base.tscn` ahora separa torso/cabina en `UpperBodyPivot`
  - `RobotBase` mantiene un heading de combate propio para Hard
  - ataques, fallback de empuje y lectura de parte impactada pueden usar el torso independiente
  - se agrego un test robot-level para asegurar que el mismo impacto cambia de pierna a brazo cuando el torso gira
- Se expuso Hard en el laboratorio principal sin meter un menu nuevo:
  - `Main` ahora acepta `hard_mode_player_slots`
  - el bootstrap asigna `ControlMode.HARD` o `EASY` por slot local
  - el roster agrega la etiqueta `Easy/Hard` por robot y ahora mantiene visible el hint real de input para que el setup quede legible durante playtests
- Se cerro la brecha mas obvia del input local/Hard:
  - el perfil `WASD` ahora tiene `throw_part` dedicado (`C`) para no dejar a P1 sin negacion manual
  - `RobotBase` crea acciones `aim_*` y ahora deja tres caminos Hard por teclado sin joystick: `WASD + TFGX`, `flechas + Ins/Del/PgUp/PgDn` y `numpad + KP7/KP9/KP//KP*`
  - `main.gd` resume en el estado inicial del HUD que mapping real esta usando cada slot, y `MatchController` mantiene ese hint en el roster para que el playtest no dependa de recordar controles fuera de pantalla
  - `IJKL` sigue explicitamente joypad-first en Hard para no forzar un cuarto mapping de teclado compartido todavia mas solapado
- Se activo la primera presion de endgame que faltaba en mapas:
  - `MatchController` ahora mide tiempo de ronda y expone un factor de contraccion del arena
  - `Main` aplica ese factor sobre `ArenaBase` sin mezclar logica de match y geometria
  - el `arena_blockout` reduce piso util y edge markers reales, y vuelve a tamano completo al reset de ronda
  - el propio `ArenaBase` ahora enciende cuatro bandas sobrias sobre el piso mientras el borde vivo se achica, reutilizando la misma geometria runtime y apagandolas al volver a escala completa
  - `default_match_config.tres` baja la ronda base a 60 segundos para que la contraccion aparezca en playtests normales
- Se agrego el primer incentivo real de borde:
  - `EdgeRepairPickup` aparece en los flancos del `arena_blockout` como pickup universal simple y visible
  - al tocarlo, el robot repara solo la parte activa mas castigada; no revive partes destruidas ni reemplaza el loop de rescate aliado
  - durante cooldown, el pedestal sigue visible y solo se apaga el nucleo de carga para que el punto de interes del borde no desaparezca
  - `Main` publica una linea breve en HUD cuando alguien logra estabilizarse en el borde, sin sumar una UI nueva
- Se agrego la primera cobertura de mapa ligada a esos incentivos de borde:
  - `arena_blockout.tscn` suma dos bloques estaticos simples bajo `CoverBlocks`, uno por flanco
  - `ArenaBase` ahora cachea su posicion original y los desplaza con la misma escala del area segura
  - el objetivo es reforzar “duelo estable pero riesgoso” en bordes sin llenar el centro de obstaculos ni dejar cover fuera de fase cuando empieza la contraccion
- Se corrigio el contrato espacial de los pickups de borde:
  - `ArenaBase` ahora tambien cachea la posicion local original de los `edge_repair_pickups`
  - cuando la arena se contrae, pickups y coberturas usan la misma escala X/Z y siguen dentro del area viva
  - se agrego coverage dedicado para asegurar que el pickup se mueve hacia adentro pero sigue cargado al nuevo borde, en vez de quedarse flotando fuera del duelo de endgame
- Se hizo explicito el bootstrap local del prototipo: `main.gd` ahora asigna slots, spawns y deja cuatro jugadores activos por defecto.
- Se separo ownership de input local con perfiles de teclado por jugador y fallback de joystick por slot, evitando que varios robots lean el mismo dispositivo.
- Se agrego un HUD compacto de ronda:
  - linea superior para ronda actual + marcador
  - roster por robot con estado `Activo`, `Inutilizado` o `Fuera`
  - se evita ensuciar el reset de ronda con mensajes de respawn por robot
- Se incorporó configuración 2v2 de laboratorio: `main.tscn` ahora trae 4 robots con `team_id` por dupla, `main.gd` asigna perfiles de teclado adicionales (`NUMPAD` y `IJKL`) y `default_match_config.tres` deja 4 jugadores locales.
- La energia ahora deja de ser solo dato: el robot puede mover el foco con entradas discretas, alterar multiplicadores reales y usar overdrive con penalizacion corta.
- Se ajustó el ritmo de choque del prototipo base 2P tocando los valores exportados de `RobotBase`:
  - movimiento con menos frenado base (`glide_damping`)
  - empuje y alcance de impacto (`passive_push_strength`, `attack_range`, `attack_impulse_strength`)
  - ventana de daño por choque (`collision_damage_threshold`, `collision_damage_scale`, `collision_damage_cooldown`)
- Se completo el indicador diegetico de parte en mano y se ajustaron timers de captura/negación:
  - indicador orbitante y animado en `RobotBase` para lectura rápida
  - `pickup_delay` y `throw_pickup_delay` en `DetachedPart` para evitar recuperaciones instantáneas tras negación.
- Se reforzó la lectura de daño modular sobre el propio robot:
  - `RobotBase` genera marcadores runtime por parte (`DamageFeedback/Smoke` y `DamageFeedback/Spark`) sin depender de assets nuevos ni HUD adicional
  - el mismo `RobotBase` ahora cachea la pose base de cada mesh modular y aplica una pose de desgaste simple a brazos/piernas dañados, haciendo visible “pieza floja” con el mismo contrato de reset al reparar o desprender
  - el feedback entra recién cuando la pieza sale del estado sano, escala a señal crítica con poca vida y se limpia al reparar o desprender la parte
- Se sumó `robot_damage_feedback_test.gd` para cubrir ese contrato de legibilidad:
  - humo visible con daño moderado
  - chispa visible en estado crítico
  - limpieza correcta al reparar o destruir la pieza
- Se sumó `robot_part_wear_pose_test.gd` para cubrir la nueva pose de desgaste:
  - brazo dañado cae sin contaminar el brazo sano
  - pierna dañada arrastra tambien su thruster
  - reparar devuelve la pose original
- Se sumó `robot_identity_readability_test.gd` para cubrir el nuevo contrato de identidad:
  - robots de distinta identidad resuelven colores distintos
  - `FacingMarker` y `CoreLight` ya no quedan neutros para todos
  - la lectura sigue viviendo en mundo, no en otra banda de HUD
- `detached_part_recovery_readability_test.gd` ahora también cubre la pertenencia de piezas:
  - la parte expone `OwnershipIndicator`
  - reutiliza el mismo color de identidad del robot dueño
  - sigue viéndose mientras la pieza permanece disponible en el piso
- Se agrego un test dedicado `two_vs_two_carry_validation_test.gd` sobre la escena principal 2v2 y se corrigio `robot_part_return_test.gd` para respetar el `pickup_delay` real.
- Se agrego `main_detached_part_cleanup_test.gd` para validar limpieza por `detached_part_cleanup_limit` y que una parte en mano no se pierda al pasar de ronda en `main.tscn`.
- Se corrigio una advertencia de tipado en `_refresh_carry_indicator_color()` que rompía la compilación headless al tratarse como error.
- Se endurecio la salida de los tests headless actuales: ahora conservan estado de fallo y terminan con codigo distinto de cero cuando una asercion falla.
- Se sumo validacion headless especifica para redistribucion y overdrive, cubriendo el slice tactico nuevo sin introducir infraestructura adicional.
- Se sumaron verificaciones headless para el bootstrap multijugador y la separacion de input, manteniendo ademas las pruebas previas del loop modular.
- Se agrego `match_round_resolution_test.gd` para cubrir dos rutas de victoria reales en el laboratorio 2v2:
  - doble ring-out rival
  - doble destruccion total rival con explosion diferida
  - verificacion de marcador, ronda visible y reset comun

## Validacion realizada

- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/arena_edge_cover_layout_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/edge_pickup_layout_rotation_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/edge_pulse_pickup_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/edge_repair_pickup_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/ffa_mode_bootstrap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/ffa_lab_scene_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/ffa_round_resolution_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/hud_detail_mode_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/hud_runtime_toggle_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_part_return_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_disabled_explosion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_disabled_warning_indicator_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/detached_part_recovery_readability_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/detached_part_return_target_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/main_detached_part_cleanup_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_part_return_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/two_vs_two_carry_validation_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/teams_validation_lab_scene_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_unstable_explosion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_damage_feedback_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/detached_part_recovery_readability_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_energy_management_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_archetype_roster_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_archetype_passive_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_control_skill_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_core_skill_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/lab_runtime_selector_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/local_multiplayer_bootstrap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_completion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_elimination_readability_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_round_recap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_unstable_explosion_readability_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_input_ownership_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/two_vs_two_carry_validation_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_round_resolution_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/progressive_space_reduction_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/hard_mode_bootstrap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_hard_keyboard_aim_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_hard_control_mode_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/team_post_death_support_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit-after 5`
- `git diff --check`

Resultado: la suite headless actual pasa y el proyecto sigue iniciando sin errores de parseo ni referencias rotas en ejecucion headless.

## Limites actuales

- La validacion automatica confirma integridad tecnica, no sensacion de movimiento ni calidad del combate.
- El nuevo sistema de items sigue siendo deliberadamente simple: hoy existen reparacion instantanea, impulso corto, recarga breve, `estabilidad`, municion/carga de skill y un solo item de una carga en mano (`pulse_charge`); la semialeatoriedad actual ya diferencia `Equipos` (2 pares) y `FFA` (3 tipos), pero todavia no hay inventario completo ni pesos finos por modo/mapa.
- El laboratorio FFA ya existe y ya evita alianzas accidentales, pero todavia falta playtestear si realmente transmite supervivencia, oportunismo y third-party sin sentirse demasiado caotico en teclado compartido.
- Los nuevos arquetipos siguen siendo una capa deliberadamente liviana:
  - hoy combinan tuning + pasivas chicas, una silueta diegetica minima por rol y `Ariete/Grua/Aguja/Ancla` como primera tanda real de skills propias; todavia no hay selección runtime ni una segunda capa mas profunda de reglas por arquetipo
  - si `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla` siguen sintiéndose demasiado parecidos en playtest, el siguiente paso debera reforzar lectura/rango/ritmo de `Embestida/Iman/Pulso/Baliza` o sumar otra regla visible por rol, no solo más multiplicadores
- El soporte Hard ya existe y ya puede asignarse por slot en `Main`, pero sigue siendo una primera base: no hay selección/UI de modo por jugador en runtime y `IJKL` sigue intencionalmente joypad-first; aun falta decidir por playtest si esos tres perfiles de teclado (`WASD`, `flechas`, `numpad`) alcanzan o si conviene otro flujo local.
- El nuevo post-muerte de `Teams` ya existe como slice jugable, pero sigue siendo deliberadamente minimo: hoy expone una `PilotSupportShip` discreta con tres payloads pro-aliado (`estabilizador`, `energia` y `movilidad`) y una `interferencia` ligera de corto alcance, ademas de un loop perimetral continuo, una primera capa de `gates` temporales con `TimingVisual`, un `StatusBeacon` diegetico, seleccion manual de objetivo con marcador alto + marca de piso sobre el target y un anillo de alcance para `interferencia`; todavia falta decidir por playtest si esa mezcla ya aporta comeback/tension suficiente sin robar lectura al combate principal y si conviene sumar mas variedad externa.
- La energia ya es jugable y ahora tambien se lee mejor en mundo, pero sigue siendo una primera version discreta: no existe redistribucion libre por porcentajes ni sobrecalentamiento mas rico por parte.
- La explosion inestable ya conecta overdrive con la ruta de destruccion total, pero todavia falta playtestear si sus multiplicadores vuelven especial esa apuesta sin convertirla en el cierre dominante del match.
- El cierre hoy ya usa score ponderado por causa (`ring_out=2`, `destruccion total=1`, `explosion inestable=4`) en el loop real y en la suite headless; sigue pendiente decidir via playtest si algun modo debe retocar esos pesos o sumar feedback diferencial.
- El incentivo de borde ya no es monotono, pero sigue siendo deliberadamente minimo: hoy hay seis tipos de pickup, con `Equipos` usando dos pares y `FFA` tres tipos activos por ronda; `municion` solo entra cuando el roster del laboratorio tiene suficiente disputa real por skills propias y `estabilidad` cubre el primer contrajuego directo contra `Baliza/interferencia`. Todavia faltan pesos finos por modo/mapa y decidir si hace falta una capa explicita de inventario en vez de seguir con cargas puntuales.
- La nueva cobertura de arena sigue siendo un primer paso: solo existen dos slabs fijos y dos pickups de reparacion ligados al borde vivo; faltan variacion de layout, rutas mas ricas y verificar por playtest que no se vuelvan “micro-fortalezas”.
- El roster sigue siendo texto de estado; el indicador diegetico cubre la parte crítica de “carga visible” y reduce ambigüedad.
- La nueva lectura de rescate tambien sigue siendo deliberadamente minima: ahora combina disco de urgencia + aro de pertenencia sobre la pieza + `RecoveryTargetIndicator/RecoveryTargetFloorIndicator` sobre el robot dueño + `CarryOwnerIndicator/CarryReturnIndicator` sobre el portador, incluyendo un refuerzo extra cuando la devolucion ya esta lista; sigue faltando validar por playtest si ese paquete alcanza con cuatro robots y arena contrayendose.
- Se corrigio un regression en la ventana de recuperacion de `DetachedPart`:
  - el countdown ya no depende de `LifetimeTimer.time_left`, que podia consumirse entero durante frames de setup/headless
  - la ventana ahora se drena en script mientras la pieza esta en el piso, se pausa al cargarla y se reanuda al volver a lanzarla
  - el contrato visual (`RecoveryIndicator` + `OwnershipIndicator`) vuelve a arrancar casi completo al spawn y ya no regala una ventana nueva solo por levantar y tirar la pieza
- El HUD dual ya existe y ahora puede alternarse en runtime con `F1` sobre un override local que tambien sobrevive al salto `F6` entre laboratorios; sigue pendiente decidir por playtest que modo conviene dejar por defecto en `Equipos` y `FFA`, y si hace falta algo mas visible que el toggle/persistencia actual.
- La nueva lectura de daño es deliberadamente simple: combina marcadores geométricos sobrios (`Smoke`/`Spark`) con poses flojas por extremidad, no partículas finales ni VFX de producción. Falta playtestear si alcanza o si conviene enriquecer humo/chispas sin perder claridad.
- La validacion automatica ya cubre el caso 2v2 base y el cierre de ronda; sigue faltando prueba manual de sensación para decidir si `pickup_delay` y `throw_pickup_delay` son demasiado severos o permisivos bajo presión real de ronda.
- El cierre de match ya no es solo “ganador + reinicio”: ahora suma stats simples por competidor (`rescates`, `borde`, `partes perdidas` por tipo y `bajas` por causa) dentro del mismo HUD; sigue faltando decidir por playtest si esa telemetria ya basta o si la version final pide otra capa de post-partida.
- La nueva lectura de bajas ya suma `Resumen | ...`, `Momento inicial/final`, `RecapPanel`, `MatchResultPanel`, estado final `N/4 partes | sin ...` por robot y `Stats | ...` con desgaste modular; todavía falta validar en playtest si ese contrato ya alcanza o si la versión final necesita una pantalla/post-partida más fuerte o un replay corto.
- La regression reciente del soporte Teams ya quedo cerrada:
  - el gasto de payload ya no depende de esperar al siguiente `_physics_process()` para apagar marca alta, marca de piso o radio de `interferencia`
  - la suite completa vuelve a pasar en una sola corrida headless, lo que deja el slice post-muerte mas confiable para futuras iteraciones
- El auto-target aliado del soporte Teams tambien ya corrige prioridades runtime sin pedir otro input:
  - `stabilizer`, `surge` y `movilidad` vuelven a seguir al aliado mas util cuando ese mejor objetivo cambia durante la ronda y el jugador nunca tomo control manual del target
  - `interferencia` mantiene el contrato previo: no rebota entre rivales por prioridad fina, solo se resincroniza cuando el target actual deja de ser accionable
  - la fixture headless de targeting ahora congela candidatos teletransportados y la regresion nueva fuerza el refresh de target explicitamente para no depender del orden/timing de la suite
- Se agregó el primer pickup universal de movilidad:
  - existe una escena nueva `edge_mobility_pickup.tscn` con pedestal persistente y cooldown visible
  - al tocarla, `RobotBase` activa una ventana breve de movilidad reforzada (`traccion + control`) sin tocar el sistema de energía ni agregar UI pesada
  - la propia lectura del robot se refuerza con glow turquesa en el core y el roster compacto agrega `impulso` mientras el efecto sigue activo
- Se amplió la lógica de pickups de borde para no acoplarla solo a reparación:
  - `ArenaBase` ahora sigue cualquier nodo del grupo `edge_pickups`, no solo `edge_repair_pickups`
  - el laboratorio principal suma dos pickups nuevos en norte/sur y los mueve junto al borde vivo durante la contracción
  - `Main` también reporta la activación del impulso en la misma línea breve de estado
- Se completó el tercer tipo de pickup universal prioritario del documento:
  - `EdgeEnergyPickup` reutiliza el mismo contrato de `edge_pickups`, pero su efecto cae sobre el sistema de energia ya existente en `RobotBase`
  - la recarga no reemplaza el overdrive: solo corta la recuperacion, reaplica el foco actual y suma una ventana corta de par reforzado
  - el coverage dedicado confirma que el nuevo incentivo no rompe roster, contracción ni la escena principal
