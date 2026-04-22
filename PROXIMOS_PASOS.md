# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

## Prioridad inmediata tras la revision estricta (2026-04-22)

1. Mantener el slice `Apoyo activo` en modo mantenimiento con las nuevas fixtures estabilizadas: si aparece otro rojo scene-level, comprobar primero si es drift real de `Main/PilotSupportShip` o contaminacion de pacing en `main_teams_validation.tscn`.
2. Medir en playtest corto si `OpeningTelegraph + lock de pickups de borde + Borde | ... | abre en Xs` realmente limpia el primer choque o si la espera se siente demasiado larga/corta en `main.tscn` y `main_teams_validation.tscn`.
   - La sonda runtime nueva ya dejo baseline:
     - `Teams base`: `choque_post_unlock=1.787s`
     - `Teams rapido`: `choque_post_unlock=2.961s`
     - `FFA base`: `sin_dato`
     - `FFA rapido`: `0.641s`
   - El seam tecnico esta sano (`deriva_intro=0`, `pickup_post_unlock<=0.021s`); la siguiente sesion deberia decidir si hace falta tocar spawns/layout/pacing en `Teams rapido` y `FFA base`, no reabrir el lock del borde por intuicion.
3. Validar con sesiones reales si el perfil `2/1/4` necesita retoque por dominancia jugable; no reabrir configs ni HUD de cierre mientras la evidencia automatizada siga alineada.
4. Revisar si queda algun seam scene-level de `Teams/FFA` todavia atado a una sola escena antes de volver a tocar produccion.

0. **No volver a dejar el soporte post-muerte `Teams` congelado solo en `main.tscn`**
 - `team_post_death_support_test.gd`, `team_post_death_support_targeting_test.gd`, `support_payload_actionability_test.gd` y `support_payload_availability_readability_test.gd` ya recorren `main.tscn` + `main_teams_validation.tscn`; `team_post_death_support_test.gd` tambien cubre `main_ffa.tscn` + `main_ffa_validation.tscn` para confirmar soporte desactivado.
 - La fixture del soporte ya neutraliza `intro + pressure drift` (`round_intro_duration_teams = 0`, `progressive_space_reduction = false`, `round_time_seconds >= 120`); no volver a medir targeting/lifecycle en la escena rapida con su pacing corto si el objetivo del test no es justamente ese pacing.
 - En cleanup, el contrato minimo es “desaparece la nave del jugador eliminado”; `SupportRoot` puede seguir no vacio si el rival entro legitimo en `Apoyo activo` dentro de la misma ronda.
 - Reabrir solo si una escena pierde spawn, targeting, warnings o no-op gating del soporte, o si se cambia deliberadamente el lifecycle post-muerte entre laboratorio base y rapido.

0. **No volver a dejar drift entre escenas `base` y `validation` del roster vivo, el marcador FFA o los stats/cierres de apoyo**
 - `ffa_live_scoreboard_order_test.gd` ya congela el marcador FFA ordenado por lider en `main_ffa.tscn` y `main_ffa_validation.tscn`.
 - `live_roster_order_test.gd` ya congela el roster vivo `FFA` en `main_ffa.tscn` + `main_ffa_validation.tscn` y el roster `Teams` con `Apoyo activo` en `main.tscn` + `main_teams_validation.tscn`.
 - `support_match_stats_test.gd` ya congela `Aporte de apoyo | ...` y `Stats | Equipo 1 | apoyo ...` en recap lateral y resultado final de las dos escenas `Teams`.
 - Si se retocan HUD vivo, `RecapPanel`, `MatchResultPanel` o wiring del soporte post-muerte, tocar siempre la pareja `base/validation` como una misma superficie contractual y mantener estas tres regresiones.

0. **No volver a dejar drift entre `main_ffa.tscn` y `main_ffa_validation.tscn` en resolucion de ronda FFA**
 - `ffa_round_resolution_test.gd` ya congela en ambas escenas FFA el seam minimo `queda un robot vivo -> gana Player X -> score individual -> reset de ronda`.
 - No volver a asumir que ambos laboratorios comparten el mismo target de match: la fixture ya fija `match_config.rounds_to_win = 3` porque `ffa_validation_match_config.tres` usa `1`.
 - Si se retocan `MatchController`, el wording del ganador FFA o el lifecycle `round_reset_delay`, tocar siempre `main_ffa.tscn` y `main_ffa_validation.tscn` como una misma superficie contractual y mantener esta regresion.
 - Reabrir solo si se decide separar deliberadamente el lifecycle FFA entre laboratorio base y rapido.

0. **No volver a dejar drift entre `main.tscn` y `main_teams_validation.tscn` en resolucion de ronda, reset de atribucion o explosion inestable**
 - `match_round_resolution_test.gd`, `match_elimination_source_reset_test.gd` y `match_unstable_explosion_readability_test.gd` ya congelan esos tres seams sobre las dos escenas `Teams`.
 - Si se retocan `MatchController`, `RecapPanel`, el lifecycle `round_reset_delay` o el wording de `explosion inestable`, tocar siempre `main.tscn` y `main_teams_validation.tscn` como una misma superficie contractual y mantener estas tres regresiones.
 - No volver a asumir que ambas escenas comparten el mismo target de match: la fixture de resolucion ya fija `match_config.rounds_to_win = 3` porque `teams_validation_match_config.tres` usa `1`.
 - Reabrir solo si se decide separar deliberadamente ese lifecycle/readability entre laboratorio base y rapido.

0. **No volver a dejar drift entre `main.tscn` y `main_teams_validation.tscn` en los highlights/detalle final de `Teams`**
 - `match_highlight_moments_test.gd`, `support_decisive_highlight_test.gd` y `team_match_result_detail_order_test.gd` ya congelan `Resumen | ...`, `Momento inicial/final`, `Apoyo decisivo` y el orden real de stats/detalle en las dos escenas `Teams`.
 - Si se retocan `RecapPanel`, `MatchResultPanel`, `_build_round_highlight_lines()`, `record_support_payload_use(...)` o el orden del detalle final, tocar siempre `main.tscn` y `main_teams_validation.tscn` como una misma superficie contractual y mantener estas tres regresiones.
 - Reabrir solo si se decide separar deliberadamente los cierres `Teams` entre laboratorio base y rapido.

0. **No volver a dejar drift entre `main.tscn` y `main_teams_validation.tscn` en atribucion de bajas o condicion final por robot**
 - `match_elimination_readability_test.gd` y `match_robot_final_condition_summary_test.gd` ya congelan en ambas escenas `Teams` la atribucion `explosion/vacio por Player X`, la linea `Cierre | ...` y el detalle final por robot con arquetipo, partes restantes y extremidades faltantes.
 - Si se retocan `RecapPanel`, `MatchResultPanel`, `_build_closing_elimination_line()`, `_build_robot_summary_line()` o el wording de bajas por robot, tocar siempre `main.tscn` y `main_teams_validation.tscn` como una misma superficie contractual y mantener estas dos regresiones.
 - Reabrir solo si se decide separar deliberadamente esos cierres entre laboratorio base y rapido.

0. **No volver a dejar drift entre escenas `base` y `validation` del recap entre rondas**
 - `match_round_recap_test.gd` ya congela el recap `Teams` en `main.tscn` y `main_teams_validation.tscn`; `match_round_draw_recap_test.gd` hace lo mismo con el empate `FFA` en `main_ffa.tscn` y `main_ffa_validation.tscn`.
 - Si se retocan `RecapPanel`, `RecapLabel`, wording `Cierre de ronda`, objetivo del match o limpieza post-reset, tocar siempre la pareja `base/validation` como una misma superficie contractual y mantener estas dos regresiones.
 - No volver a asumir que ambas escenas `Teams` comparten el mismo `rounds_to_win`: la fixture ya fuerza `match_config.rounds_to_win = 3` para validar recap intermedio real.
 - Reabrir solo si se decide separar deliberadamente el recap entre laboratorios o si cambia la fuente de verdad del cierre entre rondas.

0. **No volver a dejar drift entre escenas `base` y `validation` del cierre final**
 - `match_completion_test.gd` ya congela el cierre `Teams` en `main.tscn` y `main_teams_validation.tscn`; `ffa_match_result_standings_test.gd` hace lo mismo con `main_ffa.tscn` y `main_ffa_validation.tscn`; `match_closing_cause_summary_test.gd` fija el perfil `Cierres | ...`, `Puntos cierre | ...` y `Cierre decisivo | ...` sobre las cuatro escenas jugables.
 - Si se retocan `RecapPanel`, `MatchResultPanel`, wording de victoria, objetivo o score por causa, tocar siempre la pareja `base/validation` como una misma superficie contractual y mantener estas tres regresiones.
 - Reabrir solo si se decide separar deliberadamente el cierre entre laboratorio base y rapido o si cambia la fuente de verdad de recap/resultado final.

0. **No volver a dejar drift entre escenas `base` y `validation` del opening neutral**
 - `teams_live_scoreboard_opening_test.gd` ya congela el marcador neutro oculto en `main.tscn` y `main_teams_validation.tscn`; `ffa_live_standings_hud_test.gd` hace lo mismo con `Marcador |`, `Posiciones |` y `Desempate |` en `main_ffa.tscn` y `main_ffa_validation.tscn`.
 - `teams_opening_intro_telegraph_test.gd` ahora tambien fija que `main_ffa_validation.tscn` no herede `OpeningTelegraph` ni wording de `carriles`.
 - Si se retocan openings, HUD inicial o escenas de laboratorio, tocar siempre la pareja `base/validation` como una misma superficie contractual y mantener estas tres regresiones.
 - Reabrir solo si se decide separar deliberadamente el comportamiento de opening entre laboratorio base y rapido.

0. **No volver a dejar el countdown del intro congelado solo en `main.tscn`**
 - `round_intro_countdown_test.gd` ya recorre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`, fijando el mismo contrato `input bloqueado + RoundIntroIndicator visible + wording correcto por modo + liberacion del control`.
 - La fixture ya ajusta `MatchConfig.round_intro_duration_teams/_ffa` cuando existe; si se retoca otra vez este test o el wiring del intro, no volver a asumir que `round_intro_duration` del nodo pisa configs activas por si solo.
 - Reabrir solo si se decide separar deliberadamente el intro entre escenas `base/validation` o si `MatchController` cambia la precedencia entre config y fallback runtime.

0. **No volver a dejar los pickups de borde recogibles durante el intro**
 - `Main` ya sincroniza `set_collection_enabled(false)` sobre `edge_pickups` mientras `MatchController.is_round_intro_active()` siga activo, y el HUD del laboratorio ahora deja explicita esa ventana como `Borde | ... | abre en Xs`.
 - `edge_pickup_intro_lock_test.gd` congela el contrato minimo en `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`: un pickup de reparacion activo no debe recogerse durante el intro y debe volver a funcionar cuando termina el countdown.
 - Las fixtures scene-level de pickups (`edge_utility/mobility/energy/pulse/charge`) ahora esperan a que termine el intro antes de validar coleccion real; si se toca otra vez el opening, conservar esa separacion entre apertura telegraphiada y borde activado.
 - Reabrir solo si un playtest real demuestra que el opening sigue yendose demasiado rapido o si el lock vuelve opaco/antinatural el valor del borde.

0. **No reabrir `ring-out 2 / destruccion total 1 / explosion inestable 4` por intuicion**
 - La revision estricta ya volvio a pasar `match_elimination_victory_weights_test.gd`, `match_closing_cause_summary_test.gd`, `match_completion_test.gd` y la suite completa sin tocar produccion ni configs.
 - `Puntos cierre | ...`, `Cierre ronda | ...` y `Cierre decisivo | ...` ya dejan visible el mismo perfil dentro del prototipo; el siguiente cambio solo se justifica con evidencia runtime/manual nueva de que una ruta esta cerrando demasiado facil o demasiado poco.
 - Archivos objetivo si reaparece evidencia real: `data/config/default_match_config.tres`, `data/config/ffa_validation_match_config.tres`, `data/config/teams_validation_match_config.tres`, `scripts/tests/match_elimination_victory_weights_test.gd`.

0. **No volver a dejar que solo uno de los dos paneles de cierre explique la ultima baja decisiva**
 - `MatchController` ya reutiliza `_build_closing_elimination_line()` tanto en `get_round_recap_panel_lines()` como en `get_match_result_lines()`; si se retocan recap o resultado final, mantener esa fuente de verdad compartida.
 - `match_elimination_readability_test.gd` ahora fija el contrato minimo sobre el recap lateral final: el array del panel y `RecapLabel` visible deben repetir `Cierre | <ultima baja>`, igual que `MatchResultPanel`.
 - Reabrir solo si el cierre final deja de mostrar esa linea en ambas superficies o si una sola capa visible reemplaza explicitamente a la otra.

0. **No volver a esperar solo `process_frame` en regresiones del soporte que dependen de `_physics_process()`**
 - `team_post_death_support_targeting_test.gd` ya fija `_wait_frames()` sobre `physics_frame + process_frame`; si se agregan asserts nuevos para targeting/override/input del soporte, reutilizar ese helper y no volver a leer estados a mitad del tick fisico.
 - Reabrir solo si `PilotSupportShip` deja de resolver targeting en `_physics_process()` o si el harness de tests cambia a otro loop compartido.

0. **No volver a cerrar `Teams` con un `A-B` ambiguo cuando el match usa puntos**
 - `MatchController._build_match_victory_status_line()` ya publica `Equipo X gana la partida por A-B pts`; si se retoca el cierre final, mantener esa unidad mientras el score siga siendo ponderado por causa.
 - `match_completion_test.gd` ahora fija el contrato en `round_status_line`, `RecapLabel` y `MatchResultLabel`; no alcanza con dejar visible `Objetivo | Primero a N pts` en lineas secundarias si la decision principal vuelve a ser ambigua.
 - Reabrir solo si `Teams` abandona score por puntos o si otra lectura igual de visible reemplaza explicitamente ese cierre.

0. **No volver a dejar mudo el recap de una ronda sin ganador**
 - `MatchController` ya publica `Cierre ronda | sin ganador (+0)` cuando `_finish_round_draw()` cerro la ronda y el match sigue abierto; la fuente de verdad sigue siendo `_build_round_closing_line()`, no otra rama de HUD.
 - Si se retocan `_finish_round_draw()`, `_reset_round()`, `_build_round_closing_line()` o el recap lateral, mantener `match_round_draw_recap_test.gd`; esa regresion ahora fija tanto el array del recap como el `RecapLabel` visible en `FFA`.
 - Reabrir solo si el prototipo cambia la semantica del empate o si otra capa igual de visible reemplaza explicitamente esa lectura de `+0`.

0. **No volver a dejar que recap/resultados pierdan el objetivo del match**
 - `MatchController` ya reutiliza `_build_target_score_line()` en HUD vivo, `get_round_recap_panel_lines()` y `get_match_result_lines()`; si se retocan esos builders, mantener una sola fuente de verdad para `Objetivo | Primero a N pts`.
 - `match_round_recap_test.gd` fija el recap intermedio y `match_completion_test.gd` el cierre final; ambos esperan la linea tanto en los arrays como en el texto visible de `RecapLabel` / `MatchResultLabel`.
 - Reabrir solo si el prototipo abandona score por puntos o si otra capa igual de visible reemplaza explicitamente esa lectura contextual.

0. **No volver a dejar `Resumen | ...` fuera de `RecapPanel` y `MatchResultPanel`**
 - `MatchController` ya reutiliza `get_round_recap_line()` dentro de `get_round_recap_panel_lines()` y `get_match_result_lines()`; si se retocan esos builders, mantener una sola fuente de verdad para la cadena compacta del cierre.
 - `match_highlight_moments_test.gd` ahora congela que el resumen aparezca en el array del recap y en los labels visibles del recap lateral y del panel final.
 - Reabrir solo si el cierre abandona esos paneles o si otra capa igual de visible reemplaza explicitamente al resumen compacto.

0. **No volver a dejar ambiguo que el objetivo del match son puntos**
 - `MatchController.get_round_state_lines()` ya publica `Objetivo | Primero a N pts`; mantener esa unidad mientras el match siga usando puntaje ponderado por causa.
 - `match_completion_test.gd` fija el wording exacto dentro del HUD explicito; si se retocan `get_round_state_lines()` o la terminologia del target, conservar esa fixture.
 - Reabrir solo si el laboratorio abandona score por puntos y vuelve a una semantica real de rondas iguales.

0. **No volver a esconder la causa y los puntos del cierre de ronda intermedio**
 - `MatchController.get_round_recap_panel_lines()` ya publica `Cierre ronda | <causa> (+N)` cuando la ronda termino pero el match sigue abierto; la linea reutiliza `_last_round_closing_cause` y el score activo del `MatchConfig`.
 - Si se retocan `get_round_recap_panel_lines()`, `_finish_round_with_winner(...)`, `_build_round_closing_line()` o el wording del recap, mantener `match_closing_cause_summary_test.gd`; ahora cubre `Teams` y `FFA` antes del reset de la primera ronda.
 - Reabrir solo si el score por causa deja de leerse entre rondas o si otra capa igual de visible reemplaza explicitamente esa explicacion.

0. **No reabrir la apertura `Teams` quitando el telegraph diegético o dejandolo persistente fuera del intro**
 - `Main._sync_opening_telegraph()` ya usa las filas reales por `team_id` y el mismo lifecycle del intro; no sumar otro timer ni otra fuente de datos mientras esa ruta siga vigente.
 - `ArenaBase.set_opening_lane_rows(...)` / `_update_opening_telegraph(...)` son el unico seam visual: si se retocan `safe_play_area_size`, bootstrap `Teams` o el intro, mantener `OpeningTelegraph`, `LaneA`, `LaneB` y su apagado automatico al liberar la ronda.
 - `teams_opening_intro_telegraph_test.gd` ahora congela tres contratos: `Teams` visible + alineado, `FFA` oculto, wording `carriles` solo mientras el intro siga activo.

0. **No volver a dejar que `Teams` herede una orientacion de spawn arbitraria**
 - `Main._get_bootstrap_spawn_transforms()` ya recompone la base de `Teams` con `_build_team_spawn_transform(...)`: mantiene la posicion del marker y fuerza que la mitad izquierda mire hacia `+X` local y la derecha hacia `-X`.
 - `teams_spawn_coordination_test.gd` ahora congela dos contratos en las escenas `Teams`: aliado mas cerca que rival y apertura mirando hacia el carril central.
 - Si se retocan el bootstrap por modo, `ArenaBase.get_spawn_points()` o el layout de `main.tscn` / `main_teams_validation.tscn`, conservar esa fixture antes de volver a tocar HUD o escena.

0. **No reabrir el `F2` del selector runtime al saltar entre un robot vivo y un slot ya en `Apoyo activo`**
 - `lab_runtime_selector_test.gd` ahora cubre el flujo `P1 Apoyo activo -> F2 -> P2 vivo -> wrap F2 -> P1 Apoyo activo`; el contrato es que `Lab | ...`, `Control Pn | ...`, `Apoyo Pn | ...` y la pista diegética cambien juntos en ambos sentidos.
 - Si se retocan `cycle_lab_selector_slot()`, `get_lab_selector_summary_line()`, `get_lab_selected_controls_summary_line()`, `get_lab_selected_support_summary_line()` o `_sync_lab_selector_visuals()`, mantener esa fixture.
 - Reabrir solo si el laboratorio deja de usar un selector por slot persistente o si la identidad jugable post-muerte deja de representarse como `Apoyo activo`.

0. **No volver a dejar que la causa de baja corte primero la linea explícita de `Apoyo activo`**
 - `MatchController._build_robot_status_line()` ya ordena el caso `has_active_support` como `Apoyo activo | <support_state> | baja <causa>`; si se retocan `support_state`, el roster vivo o el wording de causas, mantener esa prioridad accionable.
 - `live_roster_order_test.gd` ahora fija el orden mínimo `Apoyo activo -> get_support_input_hint() -> vacio`; `hud_detail_mode_test.gd` sigue cubriendo que en contextual la causa directamente no reaparezca.
 - Reabrir solo si el soporte post-muerte deja de usar el roster vivo como referencia principal o si aparece otra capa UI que vuelva redundante esa lectura.

0. **No volver a dejar soporte stale durante el reset runtime `F3/F4`**
 - `Main._clear_post_death_support()` ya remueve las naves de `SupportRoot` antes de `queue_free()`, porque `_apply_lab_runtime_loadout()` recompone el laboratorio en la misma llamada y no puede seguir viendo `PilotSupportShip` transitorias.
 - Si se retocan `_clear_post_death_support()`, `_apply_lab_runtime_loadout()`, `_find_post_death_support_ship()` o `_sync_lab_selector_visuals()`, mantener `lab_runtime_selector_test.gd`: ahora congela `P1 Grua Hard -> Apoyo activo -> F3/F4` y exige retorno inmediato al robot, desaparición de `Apoyo P1 | ...` y `SupportRoot` vacío sin esperar otro frame.
 - Reabrir solo si el laboratorio deja de resetearse dentro de la misma llamada de loadout o si cambia explícitamente la fuente de verdad del selector runtime.

0. **No reabrir el reset automático del selector runtime cuando el slot viene de `Apoyo activo`**
 - `lab_runtime_selector_test.gd` ahora cubre el flujo `P1 Grua Hard -> Apoyo activo -> ronda cerrada -> Ronda 2`; el contrato es que tras el reset automático vuelvan `Lab | P1 Grua Hard`, los controles de robot, la pista diegética sobre el robot y desaparezca `Apoyo P1 | ...`.
 - Si se retocan `_on_round_started()`, `_clear_post_death_support()`, `_sync_post_death_support_state()`, `_sync_lab_selector_visuals()` o el lifecycle del soporte post-muerte, mantener esa fixture.
 - Reabrir solo si el laboratorio deja de usar el selector runtime/round-state como referencia persistente del slot seleccionado o si cambia explícitamente el actor jugable post-muerte.

0. **No volver a dejar `LabSelectionIndicator` pegado al robot cuando el slot entra en `Apoyo activo`**
 - `PilotSupportShip` ya expone `set_lab_selected()/is_lab_selected()` y crea su propio `LabSelectionIndicator`; `Main._sync_lab_selector_visuals()` ahora apaga la marca del robot seleccionado si ya existe soporte activo para ese owner y la pasa a la nave.
 - Si se retocan `_sync_lab_selector_visuals()`, `_sync_post_death_support_state()`, el lifecycle de `PilotSupportShip` o la visual runtime del selector, mantener `lab_runtime_selector_test.gd`: ahora fija robot marcado antes de la baja y nave marcada después de `Apoyo activo`.
 - Reabrir solo si el laboratorio abandona esta pista diegética, cambia el actor controlable post-muerte o aparece otra capa visual que reemplace explícitamente al anillo runtime.

0. **No reabrir el salto `F6` desde `Apoyo activo` al tocar selector runtime o persistencia entre laboratorios**
 - `lab_scene_selector_test.gd` ahora cubre el flujo `P1 Grua Hard -> Apoyo activo -> F6 -> Equipos rapido`; el contrato es que la escena nueva recupere `Lab | P1 Grua Hard ...`, controles de robot Hard y no arrastre `Apoyo P1 | ...`.
 - Si se retocan `cycle_lab_scene_variant()`, `_store_lab_runtime_session_state()`, `_restore_lab_runtime_session_settings()`, `_apply_restored_lab_runtime_loadouts()` o el lifecycle del soporte post-muerte, mantener esa fixture.
 - Reabrir solo si el cambio de escena deja de reconstruir una partida limpia por laboratorio o si se decide explícitamente persistir también estados transitorios de match entre escenas.

0. **No reabrir el restart manual `F5` del selector runtime sobre una reproduccion invalida**
 - `lab_runtime_selector_test.gd` ahora cubre el camino real `slot seleccionado -> Apoyo activo -> cierre de match -> F5`; si se toca el restart manual, el soporte post-muerte o el round-state del laboratorio, mantener ese flujo y no sustituirlo por un `F5` a mitad de ronda, porque `MatchController.request_match_restart()` solo vale con `_match_over`.
 - El contrato actual es: tras `F5`, el selector runtime vuelve a `Lab | P1 Grua Hard ...`, la línea `Control P1 | ...` retoma los controles del robot y desaparece `Apoyo P1 | ...`.
 - Archivos objetivo: `scripts/tests/lab_runtime_selector_test.gd`, `scripts/tests/match_manual_restart_test.gd`, `scripts/main/main.gd`, `scripts/systems/match_controller.gd`.

0. **No perder la linea `Apoyo Pn | ...` al tocar el soporte seleccionado del laboratorio**
 - `Main` ya expone `get_lab_selected_support_summary_line()` y la suma al round-state solo cuando `_find_post_death_support_ship(robot)` existe para el slot seleccionado.
 - `PilotSupportShip.get_actionable_status_summary()` es ahora la fuente de verdad de esa linea; si cambian warnings, payload labels o target summaries del soporte, actualizar ese helper y no duplicar string-building en `Main`.
 - Mantener `lab_runtime_selector_test.gd`: ahora cubre que la linea no exista antes de la baja y que aparezca como `Apoyo P1 | sin carga` apenas el slot seleccionado pasa a la nave post-muerte.
 - Reabrir solo si el laboratorio deja de usar el round-state como capa persistente para el slot seleccionado o si el slice post-muerte cambia de formato de lectura.

0. **No volver a dejar stale el resumen `Lab | ...` cuando el slot entra en `Apoyo activo`**
 - `Main._get_lab_robot_brief()` ya prioriza `_find_post_death_support_ship(robot)` y cambia de `Pn Ariete Easy/Hard` a `Pn Apoyo activo` cuando el slot seleccionado ya no controla su robot sino la nave post-muerte en `Teams`.
 - Si se retocan `get_lab_selector_summary_line()`, `_get_lab_robot_brief()`, el lifecycle del soporte o el round-state del laboratorio, mantener `lab_runtime_selector_test.gd`: ahora cubre en el mismo flujo la transicion real `Lab | P1 Ariete Easy ...` -> `Lab | P1 Apoyo activo ...`.
 - Reabrir solo si el selector runtime deja de usar una sola línea compacta para describir el slot seleccionado o si el soporte post-muerte cambia de identidad/wording en HUD.

0. **No volver a dejar stale la línea `Control Pn | ...` cuando el slot entra en `Apoyo activo`**
 - `Main.get_lab_selected_controls_summary_line()` ya consulta `_find_post_death_support_ship(robot)` y cambia de `robot.get_control_reference_hint()` a `robot.get_support_input_hint()` cuando el slot seleccionado cayó y sigue jugando desde la nave de apoyo.
 - Si se retoca el selector runtime, el lifecycle del soporte o el round-state del laboratorio, mantener `lab_runtime_selector_test.gd`: ahora cubre el cambio real `controles de robot -> controles de soporte` para `P1` sin depender solo del roster.
 - Reabrir solo si el laboratorio deja de usar una sola línea persistente para controles o si el soporte post-muerte cambia de botones/flujo.

0. **No perder la linea `HUD | ... | F1 cambia` al tocar el HUD dual o el ciclo de escenas**
 - `Main` ya expone `get_lab_hud_mode_summary_line()` y la suma al round-state del laboratorio; la fuente de verdad sigue siendo `MatchController.get_hud_detail_mode_label()`.
 - Si se retocan `_build_round_state_lines()`, `cycle_hud_detail_mode()`, `apply_runtime_hud_detail_mode()` o el salto `F6`, mantener `lab_scene_selector_test.gd`: ahora cubre arranque `explicito`, cambio a `contextual` y persistencia de la misma linea tras recargar otra escena.
 - Reabrir solo si el laboratorio deja de usar el round-state como referencia runtime principal del HUD o si aparece una pantalla pre-match que vuelva redundante esta linea.

0. **No reabrir el marcador neutro de `Teams` al tocar el HUD vivo**
 - `MatchController` ya oculta `Marcador | ...` mientras el match `Teams` sigue en la apertura sin rondas decididas; recap y resultado final no usan ese gating.
 - Si se retocan `_build_score_summary_line()`, `_should_show_live_score_summary()` o el lifecycle de `_match_decided_rounds`, mantener `teams_live_scoreboard_opening_test.gd`; esa regresión ahora fija opening limpio + score visible otra vez tras cerrar una ronda.
 - Reabrir solo si el HUD `Teams` cambia de layout o si se decide explícitamente que el score inicial también debe vivir en otra línea/contexto.
 - Archivos objetivo: `scripts/systems/match_controller.gd`, `scripts/tests/teams_live_scoreboard_opening_test.gd`.

0. **No perder la linea `Control Pn | ...` al tocar selector runtime o perfiles locales**
 - `Main` ya expone `get_lab_selected_controls_summary_line()` y la suma al round-state del laboratorio; `RobotBase.get_control_reference_hint()` concentra los labels por perfil y por `Easy/Hard`.
 - Si se retocan `_build_round_state_lines()`, `get_lab_selector_summary_line()`, `toggle_lab_control_mode_for_player_slot()` o los perfiles locales de `RobotBase`, mantener `lab_runtime_selector_test.gd`: ahora cubre que el HUD arranque con la chuleta de `P1`, sume `aim TFGX` al pasar a `Hard` y migre al perfil flechas al cambiar a `P2`.
 - Reabrir solo si cambia de verdad el layout del HUD del laboratorio o si aparece una referencia previa al match que vuelva redundante esta linea.

0. **No perder el resumen final `Cierres | ...` al tocar score o wording del cierre**
 - `MatchController` ya resume en recap/resultado final que rutas cerraron rondas a lo largo del match (`ring-out`, `destruccion total`, `explosion inestable`) usando `_match_closing_cause_counts`.
 - Si se retocan `_finish_round_with_winner(...)`, `get_round_recap_panel_lines()`, `get_match_result_lines()` o el wording del cierre, mantener `match_closing_cause_summary_test.gd`; esa regresion ahora cubre `Teams` y `FFA` con un match mixto `ring-out + explosion inestable`.
 - Usar esa linea como lectura base para futuros playtests del score ponderado antes de sumar otra telemetria o panel nuevo.

0. **No perder la linea `Puntos cierre | ...` al tocar score o cierre final**
 - `MatchController` ya publica en el recap entre rondas y en el cierre final el perfil runtime de score por causa (`ring-out`, `destruccion total`, `explosion inestable`) leyendo los valores activos desde `MatchConfig`.
 - Si se retocan `_build_closing_points_profile_line()`, `get_round_recap_panel_lines()`, `get_match_result_lines()` o los campos de score en `MatchConfig`, mantener `match_closing_cause_summary_test.gd`; ahora la misma fixture fija `Puntos cierre | ...` antes y despues de cerrar el match en `Teams` y `FFA`.
 - Reabrir solo si el score por causa deja de ser visible en recap/cierre o si se mueve explicitamente a otra capa de lectura igual de accesible para playtest corto.

0. **No volver a esconder que causa dio los puntos decisivos del match**
 - `MatchController` ya persiste `_last_round_closing_cause` y publica `Cierre decisivo | <causa> (+N)` solo cuando `_match_over`; esa linea acompaña a `Cierres | ...` y `Puntos cierre | ...`, no los reemplaza.
 - Si se retocan `_finish_round_with_winner(...)`, `_build_decisive_closing_line()`, `get_round_recap_panel_lines()` o `get_match_result_lines()`, mantener `match_closing_cause_summary_test.gd`; la fixture actual exige esa lectura tanto en `Teams` como en `FFA`.
 - Reabrir solo si el cierre deja de ponderarse por causa o si la lectura decisiva se mueve a otra capa igual de visible para playtest corto.

0. **No volver a dejar que `MatchConfig.new()` derive del recurso base**
 - `scripts/tests/match_config_defaults_test.gd` ya fija que los defaults runtime de `scripts/systems/match_config.gd` coincidan con `data/config/default_match_config.tres` en `local_player_count`, intros por modo y score por causa.
 - Si cambia el perfil base del laboratorio, actualizar `match_config.gd` y `default_match_config.tres` en el mismo cambio; no aceptar que uno quede viejo “solo para tests”.
 - Archivos objetivo: `scripts/systems/match_config.gd`, `data/config/default_match_config.tres`, `scripts/tests/match_config_defaults_test.gd`.

0. **No reabrir el estado manual del soporte cuando el target visible ya coincide con el default**
 - `PilotSupportShip` ya limpia `_manual_target_override` si el jugador cicla manualmente de vuelta al mismo target que `_get_default_support_target(candidates)` habría elegido en ese frame.
 - Si se retoca `_cycle_selected_target()`, conservar `team_post_death_support_targeting_test.gd`: ahora también cubre el caso “override manual -> vuelta al default -> target default se vuelve inmune -> resincronización automática”.
 - Reabrir solo si cambia el criterio de default por payload o aparece un modo con más candidatos simultáneos que haga ambiguo cuándo un target visible realmente coincide con el auto-target.
 - Archivos objetivo: `scripts/support/pilot_support_ship.gd`, `scripts/tests/team_post_death_support_targeting_test.gd`.

0. **No reabrir el gating de no-ops salvo cambio real de escala en `Teams`**
 - La medición corta ya quedó cerrada: en el laboratorio `Teams` actual, una mala selección manual de `surge` o `movilidad` no gasta la carga y se corrige con un solo ciclo de target hacia el aliado útil.
 - Si se retoca este seam, mantener `support_payload_actionability_test.gd` junto con `support_payload_availability_readability_test.gd`: ahora una cubre bloqueo + redirección manual y la otra que la misma lectura `ya activo` siga gobernando roster/cues.
 - Reabrir solo si `Teams` suma más aliados vivos simultáneos, cambia el costo del ciclado manual o aparece fricción real en sesión con más de dos candidatos aliados.
 - Archivos objetivo: `scripts/support/pilot_support_ship.gd`, `scripts/tests/support_payload_actionability_test.gd`, `scripts/tests/support_payload_availability_readability_test.gd`, `scripts/tests/team_post_death_support_targeting_test.gd`.

0. **Validar legibilidad del nuevo estado `Apoyo activo`**
 - El roster vivo `Teams` ya distingue a la baja que sigue influyendo desde la nave de soporte, el HUD explicito ya no mezcla los controles del robot caido con los de la nave, la línea `Apoyo activo` ya no arrastra `skill`, energía ni `item` del robot muerto y el HUD contextual ahora tampoco repite la causa de baja cuando el jugador ya tiene una acción nueva más relevante. `interferencia` explicita `fuera de rango` y también `estable`, `stabilizer` marca `sin daño`, `surge/movilidad` publican `ya activo` cuando el buff seleccionado sería redundante, los tres cues diegéticos (`SupportTargetIndicator`, `SupportTargetFloorIndicator`, `InterferenceRangeIndicator`) se atenúan cuando el payload sería un no-op real, el auto-target ya vuelve solo al mejor objetivo útil si el default envejece durante la ronda y el override manual ya tiene regresión propia para no volver a pelear contra el jugador. La siguiente sesión corta debe confirmar si ese paquete compacto alcanza por sí solo o si todavía hace falta ajustar orden/contraste antes de sumar otra UI.
 - Mantener `hud_detail_mode_test.gd`, `live_roster_order_test.gd`, `team_post_death_support_test.gd`, `team_post_death_support_targeting_test.gd` y `support_payload_availability_readability_test.gd` como red mínima si se retoca `support_state`, `get_status_summary()`, el builder de roster o la lectura diegética del target; ahora cubren warnings de disponibilidad, defaults útiles, resincronización runtime, preservación del override manual, limpieza contextual de `Apoyo activo` y también la atenuación visual sobre objetivos inmunes/no-op.
 - Archivos objetivo: `scripts/systems/match_controller.gd`, `scripts/support/pilot_support_ship.gd`, `scripts/tests/hud_detail_mode_test.gd`, `scripts/tests/live_roster_order_test.gd`, `scripts/tests/team_post_death_support_test.gd`, `scripts/tests/team_post_death_support_targeting_test.gd`, `scripts/tests/support_payload_availability_readability_test.gd`.

0. **Validación runtime de choque cerrada (2026-04-22)**
 - Decisión operativa: congelar el tuning reciente de `RobotBase` y mover el siguiente playtest a capas de cierre/legibilidad, no a otro ajuste de empuje por intuición.
 - Evidencia nueva:
   - `xvfb-run -a godot --path . -s res://scripts/tests/robot_collision_pacing_test.gd` ejecutó 3 rondas reales por escena sobre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn`.
   - En las 12 rondas apareció `PACING | ... | choque_significativo=si` y en ninguna se registró `ring_out_antes_dano=si`.
   - No hizo falta tocar `passive_push_strength`, `collision_damage_threshold`, `collision_damage_scale` ni `glide_damping` después de esa corrida.
 - Siguiente criterio de continuidad:
   - si vuelve a abrirse tuning de choque, debe partir de una nueva corrida runtime equivalente o de playtest manual claro; no volver a una prueba sintética aislada.
   - el próximo foco ya puede pasar a pesos de cierre por causa, soporte post-muerte o legibilidad en sesiones cortas.

1. **Afinar el perfil de cierre por causa con playtest corto**
  - Definir el ajuste final del peso de cierre por causa con base en sesiones reales:
    - `ring_out`, `destruccion total`, `explosion inestable`.
    - objetivo: mantener riesgo/recompensa sin hacer dominante ninguna ruta de victoria.
  - usar ahora la trilogia del cierre (`Cierres | ...`, `Puntos cierre | ...`, `Cierre decisivo | ...`) para distinguir entre mezcla acumulada del match, perfil configurado y la ruta exacta que clincheo cada partida.
  - Mantener la validación técnica en `match_elimination_victory_weights_test.gd` y reforzar cobertura por modo (Teams/FFA) tras cualquier cambio.
  - Archivos objetivo: `data/config/default_match_config.tres`, `data/config/ffa_validation_match_config.tres`, `data/config/teams_validation_match_config.tres`, `scripts/tests/match_elimination_victory_weights_test.gd`.

2. **Cerrar soporte post-muerte con datos reales**
  - El targeting base ya quedo corregido: cuando haya varios objetivos vivos, `PilotSupportShip` ahora prioriza utilidad del payload en vez de `scene-order`. No reabrir ese punto salvo rojo nuevo en `team_post_death_support_targeting_test.gd`.
  - El auto-target ya no debe quedar clavado en defaults envejecidos: si se toca `_refresh_target_selection()`, `_cycle_selected_target()` o la prioridad de payloads, conservar también la distinción entre auto-target y override manual para no volver a pelear contra el jugador ni reabrir no-ops silenciosos.
  - `interferencia` ya evita por defecto rivales protegidos por `estabilidad`; si se toca `apply_stability_boost()`, `apply_control_zone_suppression()` o `_get_interference_target_priority(...)`, mantener tambien la advertencia compacta `estable` para no reabrir fallos silenciosos entre utility y soporte.
  - La nave ya no debe aparecer armada: si se toca `PilotSupportShip.configure()`, `_try_collect_support_pickup()` o el layout del carril, conservar `spawn_pickup_grace_duration` o una regla equivalente para evitar pickups gratis al respawn.
  - El cierre ya explica tambien el ultimo payload decisivo del ganador (`Apoyo decisivo | ...`). No volver a esconder ese dato en agregado si se retoca `record_support_payload_use(...)` o `_build_round_highlight_lines()`.
  - El cleanup basico ya quedo cubierto: si se toca `_clear_post_death_support()`, `_on_round_started()`, `start_match()` o el carril externo, mantener tambien `support_lifecycle_cleanup_test.gd` para que no reaparezcan naves/hints/pickups stale entre rounds o tras `F5`.
  - Partir de `support_use_total`, `support_payload_use_*` y `support_rounds_decided` ya registrados en `MatchStats` para guiar ajustes.
  - Ajustar `PilotSupportShip` y gates de carril solo con evidencia de sesiones cortas de Teams; evitar cambios sin efecto en rondas decisivas.
  - El siguiente foco de este slice ya no es “a quien apunta por defecto”, sino validar si el valor tactico real del carril justifica `stabilizer/surge/mobility/interference` en 2v2 y escenas futuras con mas aliados.
  - Si se vuelve a tocar `_should_resync_to_default_target(...)` o `_refresh_target_selection()`, conservar tambien la nueva regresion de `stabilizer` que fuerza un cambio de prioridad aliado en runtime sin override manual; ese carril ya no debe volver a quedarse clavado en un target solo “todavia util”.
  - Si se retoca otra vez la fixture de `team_post_death_support_targeting_test.gd`, mantener candidatos congelados (`is_player_controlled = false`, velocidad/impulso en cero) o una regla equivalente: esta suite vuelve a ponerse flaky cuando los robots teletransportados siguen leyendo input o arrastran movimiento residual.
  - Mantener la telemetría compacta si comunica valor; si no mejora `support_rounds_decided`, priorizar estabilidad de loops antes que tuning.
  - Archivos objetivo: `scripts/support/pilot_support_ship.gd`, `scripts/systems/match_controller.gd`, `scenes/main/main.tscn`, `scenes/main/main_teams_validation.tscn`, `data/config/teams_validation_match_config.tres`.

3. **Validar la nueva apertura coordinada de Teams en playtest corto**
  - usar `main.tscn` y `main_teams_validation.tscn` para confirmar que el cambio de spawn mejora lectura de parejas, rescate temprano y primera colisión sin volver demasiado segura la apertura lateral.
  - si el arranque sigue sintiéndose frío o muy espejo, ajustar primero offsets de `SpawnPlayer` en `arena_blockout.tscn` / `arena_teams_validation.tscn`; no abrir todavía un sistema runtime de reasignación por equipo.
  - mantener `teams_spawn_coordination_test.gd` si cambia el layout: el contrato mínimo sigue siendo “aliado más cerca que rival” al iniciar.
  - Archivos objetivo: `scenes/arenas/arena_blockout.tscn`, `scenes/arenas/arena_teams_validation.tscn`, `scripts/tests/teams_spawn_coordination_test.gd`.

4. **Cerrar el ciclo documental de causa y ranking**
  - Consolidar wording idéntico en `PLAN_DESARROLLO.md`, `ESTADO_ACTUAL.md`, `PROXIMOS_PASOS.md` y `DECISIONES_TECNICAS.md` para `cierre por causa`, `desempate`, `1-8 modo` y `Stats | ...`.
  - Mantener el ajuste de `support_rounds_decided` y el bloque de apoyo dentro de `Stats` como único resumen de soporte hasta necesitar más capa de post-mortem.
  - Archivos objetivo: `PLAN_DESARROLLO.md`, `ESTADO_ACTUAL.md`, `DECISIONES_TECNICAS.md`, `PROXIMOS_PASOS.md`.

5. **Validar el nuevo roster de arquetipos**
   - usar `1-8` junto con `F2/F3/F4` para recorrer cruces reales entre `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla` en `main.tscn` y `main_ffa.tscn` sin editar escenas entre partidas, validando tambien si el nuevo `LabSelectionIndicator` evita errores de slot en pantalla compartida.
   - correr sesiones reales con `Ariete`, `Grua`, `Cizalla` y `Patin` en `main.tscn`, y con `Aguja` + `Ancla` en `main_ffa.tscn`, para decidir si la mezcla actual de pasivas + skills propias ya produce identidades claras.
   - medir si las pasivas/skills actuales se entienden por playtest sin otra capa de UI: `Ariete` activando `Embestida` para comprometer choques, `Grua` estabilizando rescates y usando `Iman`, `Cizalla` rematando partes tocadas con el nuevo combo `corte` + pulso corporal + `DismantleCue` sobre la pieza enemiga castigada y `Patin` activando `Derrape` para reposicionarse sin perder legibilidad.
   - calibrar si `Derrape` necesita mas/menos impulso inicial, duracion o control extra para sentirse como una decision de posicionamiento y no como otro `impulso` de mapa disfrazado.
   - calibrar si `Embestida` necesita un impulso inicial muy chico o si la ventana actual de drive/impacto/estabilidad ya alcanza para sentirse inmediata sin robar protagonismo al melee base.
   - medir si `Iman` realmente abre rescates/negaciones a media distancia o si el rango actual se siente demasiado corto, tramposo o poco legible cuando hay varias piezas sueltas.
   - medir si `Aguja` realmente introduce poke/skillshot legible ahora que `Pulso` ya tiene lectura diegetica sobre `CoreLight` y `ArchetypeAccent`, o si aun hace falta ajustar color/intensidad/ritmo del pulso para cámara compartida.
   - si se retocan `pulse_charge_spawn_distance`, velocidad o lifetime de `Pulso`, conservar la cobertura headless que hoy evita que el proyectil nazca solapado con su robot origen.
   - medir si `Ancla` realmente corta rutas/duelos con `Baliza` o si la supresion actual se siente demasiado sutil para justificar el rol de Control/Zona.
   - medir si el roster actual (`Player X / <Arquetipo>` + `[<Arquetipo>]` en marcador FFA + `skill Embestida/Iman/Derrape/Pulso/Baliza x/y` + estados `embestida/derrape/zona`) mas los nuevos acentos en mundo (`FacingMarker/CoreLight` por identidad + `ArchetypeAccent` por rol/skill + `StatusEffectIndicator` para `estabilidad/zona`) alcanzan como legibilidad de laboratorio o si conviene compactarlo mas.
   - decidir si el selector runtime actual ya alcanza como flujo de laboratorio ahora que `F6` conserva slot/arquetipos/modos, o si el siguiente paso debe ser presets visibles/limpieza manual de setup, mas claridad visual o reforzar con otra skill/regla al arquetipo que siga borroso.

6. **Validar el nuevo HUD dual y la nueva lectura de daño modular**
   - correr sesiones con `hud_detail_mode=EXPLICIT` y `hud_detail_mode=CONTEXTUAL` usando tambien el toggle `F1` para decidir que variante debe quedar por defecto en `Equipos` y en `FFA`.
   - revisar si el modo contextual realmente limpia sin esconder decisiones tacticas como `Foco`, `item`, `carga`, `impulso`, `energia` o `3/4 partes`.
   - confirmar por playtest que el roster vivo ahora acompana bien al resto de la lectura competitiva: lider primero en FFA y aliados supervivientes antes que caidos en Teams, sin perder claridad de ownership en pantalla compartida.
   - decidir si el toggle runtime actual alcanza para laboratorio ahora que `F1` tambien sobrevive al salto `F6`, o si la siguiente capa necesita un preset/indicador mas visible por modo ademas del `MatchConfig`.
   - medir si `RecapPanel` lateral + `MatchResultPanel` centrado + `Stats | ...` (incluyendo `partes perdidas`) + los nuevos `Momento inicial/final` + el detalle repetido `Player X / <Arquetipo> | baja N | causa | N/4 partes | sin ...` explican suficientemente bien `Decision + Marcador + como perdi` sin necesitar otra escena/post-ronda.
   - playtestear si `damage_feedback_threshold`, `critical_damage_feedback_threshold` y la nueva pose floja de brazos/piernas se leen bien con cuatro robots y arena en contracción.
   - decidir si el feedback geométrico actual ya alcanza o si conviene migrarlo a humo/chispas más ricos sin ensuciar pantalla compartida.
   - ajustar posición/escala de marcadores y amplitud de la pose de desgaste antes de sumar más VFX o UI.

7. **Hacer visible y testeable el rescate/negacion**
   - usar `scenes/main/main_teams_validation.tscn` como escena corta de referencia y el coverage headless 2v2/validacion como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir si el nuevo combo `disco de recuperacion + aro de pertenencia + RecoveryTargetIndicator + RecoveryTargetFloorIndicator + CarryOwnerIndicator + CarryReturnIndicator`, ahora con refuerzo extra cuando la devolucion ya esta lista, realmente alcanza para leer urgencia/ownership/objetivo/handoff tambien durante el transporte en 2v2 y FFA o si todavia hace falta compactar escala/contraste/ritmo de esos cues.
   - comprobar en playtest si la nueva linea `negaciones N` realmente explica bien cuando el rival mando una pieza al vacio o si el cierre final todavia necesita distinguir mejor entre negacion enemiga y auto-error aliado.
   - confirmar por playtest si pausar la ventana de `DetachedPart` mientras viaja en mano mantiene bien la tension de rescate/negacion o si el proximo ajuste debe venir por `cleanup_time`/`throw_pickup_delay`, no por volver a resets implícitos.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

7. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si los tres caminos Hard/local ya expuestos (`WASD + TFGX`, `flechas + Ins/Del/PgUp/PgDn`, `numpad + KP7/KP9/KP//KP*`) alcanzan para sesiones cortas o si aun hace falta otro flujo local/persistente.
   - medir si `F4` sobre el selector runtime + roster persistente + `LabSelectionIndicator` alcanzan como claridad de laboratorio o si aparece una necesidad real de un flujo pre-match/persistente por jugador.
   - revisar si la referencia persistente de controles activos ya alcanza o si sigue faltando una ayuda mas compacta para pantalla compartida.
   - playtestear si la nueva lectura torso/chasis mejora el combate o si todavia se siente demasiado sutil para pantalla compartida.

8. **Validar la identidad del nuevo laboratorio FFA**
   - correr primero sesiones cortas en `scenes/main/main_ffa_validation.tscn` para calibrar oportunismo, third-party, cierres de ronda y rotacion de borde sin la duracion del laboratorio libre base.
   - usar despues `scenes/main/main_ffa.tscn` para comprobar si esa lectura compacta sigue sosteniendose en el laboratorio libre mas largo, ahora que el roster incluye a `Aguja` y `Ancla`.
   - medir si el combo vivo `Marcador | ...` + `Posiciones | ...` + `Desempate | N pts: Player X > ...`, ahora oculto por completo durante la apertura neutral, mas el detalle final ya ordenado por posicion real, alcanza para explicar score y empates en FFA o si aun hace falta compactar/mejorar esa lectura cuando la ronda esta cargada.
   - medir si el rescate/negacion sigue siendo entendible cuando nadie tiene aliados y decidir si FFA necesita valores o spawns propios, no solo otra bandera de match.
   - revisar si `Baliza` vuelve algunas diagonales/coberturas demasiado seguras o si realmente empuja rotacion y lectura espacial.
   - revisar si el marcador first-to-3 y la contraccion actual producen buen ritmo en FFA o si ese modo necesita objetivo/duracion distintos.

9. **Pulir el cierre de match que ya existe**
  - playtestear si `rounds_to_win=3`, `match_restart_delay`, el panel `Partida cerrada` y el atajo `F5` dejan leer bien la victoria o si el resultado sigue pasando demasiado rápido.
  - decidir si el reinicio automático debe seguir siendo el fallback del laboratorio o si conviene pasar a una solución manual-only más adelante.
  - definir si conviene mantener el perfil actual (`ring-out=2`, `destruccion total=1`, `explosion inestable=4`) o retocar pesos/feedback por modo tras playtests cortos.
  - si vuelve a tocarse la linea `Stats | ...`, conservar la semantica actual: `_competitor_match_stats.eliminations` mide derrotas recibidas, asi que el cierre debe seguir rotulandolas como `bajas sufridas`, no como bajas infligidas.
  - si vuelve a tocarse el orden del bloque `Stats | ...`, conservar `ffa_match_result_standings_test.gd`, `team_match_result_detail_order_test.gd` y `match_completion_test.gd`: ahora tambien cierran el riesgo de mezclar ranking/resultado correctos con telemetria final en scene-order.
  - si vuelve a tocarse el wording superior del cierre, conservar la separacion por modo: `Equipos` puede resumirse como `A-B`, pero `FFA` ya necesita una frase tipo `Player X gana la partida con N punto(s)` porque el detalle multi-competidor vive debajo en `Marcador` / `Posiciones`.
  - si vuelve a tocarse el orden del detalle de cierre, conservar `team_match_result_detail_order_test.gd` y `ffa_match_result_standings_test.gd`: ambos cierran el mismo riesgo de volver a scene-order en `RecapPanel`/`MatchResultPanel`.
  - si vuelve a tocarse la atribucion `por Player X`, conservar `match_elimination_source_reset_test.gd` dentro del chequeo minimo: el stale reciente no vivia en `RobotBase`, sino en el mapa per-round de `MatchController` que alimenta recap/resultado final.
  - si vuelve a tocarse el orden del roster vivo, conservar `live_roster_order_test.gd`: cierra la regresion donde el HUD por robot seguia en scene-order aunque `Marcador`, `Posiciones` y recap ya usaban el orden competitivo real.
  - medir si `Resumen | ...` + `Ultima baja | ...` + `Momento inicial/final` + `Fuera | vacio/explosion/explosion inestable` + `Inutilizado | explota/inestable` + atribucion `por Player X` + `DisabledWarningIndicator` + `Stats | ...` con `partes perdidas` + `RecapPanel` + `MatchResultPanel` + detalle `Player X / <Arquetipo> | baja N | causa | N/4 partes | sin ...` ya explican suficientemente bien la derrota inmediata o si la siguiente capa debe ser una pantalla post-ronda/post-partida más fuerte.

10. **Afinar la nueva presion de arena**
  - playtestear si `round_intro_duration_ffa` (actualmente 1.0) y `round_intro_duration_teams` (actualmente 0.6) dejan el beat correcto entre respawn y primer choque.
  - validar por playtest si `space_reduction_warning_seconds = 3.5` avisa con tiempo suficiente sin volverse ruido constante en rondas largas; si cambia, mantener `progressive_space_reduction_test.gd` como red de seguridad del warning.
  - revisar si la intensidad baja actual del `PressureTelegraph` previo alcanza en camara compartida o si todavia necesita otro ajuste fino de alpha/emission antes de tocar contrastes mas grandes.
   - medir si la combinacion `Ronda N | arranca en ...` + `RoundIntroIndicator` ya alcanza como telegraph de apertura o si el cue de piso todavia necesita ajuste fino de tamano/contraste/ritmo en camara compartida.
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - medir si las nuevas bandas de piso alcanzan para anunciar la contraccion en camara compartida o si su contraste/inset todavia necesita ajuste fino.

11. **Pulir la energia ahora que ya es jugable**
  - decidir si el foco debe seguir compartido por todos o si algun arquetipo necesita un preset/base distinto mas adelante
  - playtestear si los nuevos `EnergyFocusIndicator` sobre brazos/piernas alcanzan para leer foco/overdrive en pantalla compartida o si todavia hace falta ajustar tamano/contraste/ritmo antes de sumar VFX mas ricos
  - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida
  - medir si `energy_pickup_pair_multiplier` y `surge_duration` hacen que la recarga de borde valga la pena sin comerse la identidad del overdrive
  - medir si `unstable_disabled_explosion_radius_multiplier`, `unstable_disabled_explosion_impulse_multiplier` y `unstable_disabled_explosion_damage_multiplier` vuelven especial la sobrecarga sin transformar el overdrive en una ruta dominante de remate

12. **Mejorar validacion jugable**
   - usar tambien `F6` para saltar en runtime entre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn` antes de volver al editor; si cambia el set de laboratorios, mantener sincronizados `LAB_SCENE_VARIANTS`, la linea `Escena | ...` y la persistencia de loadout + HUD cubierta en `lab_scene_selector_test.gd`.
   - si cambia el wiring base de cualquiera de esas cuatro escenas, mantener tambien `main_scene_runtime_smoke_test.gd`: ahora es la red minima que fija carga runtime real, `MatchConfig`, HUD, arena y bootstrap por modo.
   - usar `godot --headless --path . -s res://scripts/tests/test_runner.gd` como entrypoint comun antes de caer en loops shell manuales; si cambia el layout de `scripts/tests`, mantener tambien `test_suite_runner_test.gd` para no perder discovery en silencio.
   - si un test depende de score real, derivar el valor esperado desde `MatchConfig`; si depende de lifecycle puro entre rondas, fijar `void/destruccion/inestable = 1` dentro del test.
   - si un test necesita arrancar sin intro, anular `round_intro_duration_ffa/teams` en `MatchConfig`; no confiar solo en `MatchController.round_intro_duration`.
   - usar `main_teams_validation.tscn` y `main_ffa_validation.tscn` como rutas rapidas base antes de tocar `main.tscn` o `main_ffa.tscn`.
   - ajuste fino de valores de aceleracion, damping, empuje y danio usando esas escenas cortas para iterar mas rapido antes de tocar los laboratorios largos.
   - medir si el reset corto de ronda y el reinicio de match dejan suficiente tiempo de lectura o si necesitan delays algo mayores
   - mantener una corrida completa `scripts/tests/*.gd` como chequeo de regresion rapida cuando se toque soporte Teams o teardown de escenas, porque el bug reciente del `SupportTargetFloorIndicator` solo aparecia en suite completa y no en ejecuciones aisladas.
   - conservar tambien `robot_disabled_warning_indicator_test.gd` dentro de los chequeos minimos cada vez que se toque lifecycle de `RobotBase`, porque el stale del warning aparecia justo en la transicion explosion -> respawn y no se veia mirando solo `is_visible_in_tree`.

13. **Profundizar el soporte Hard sin convertirlo en requisito**
   - direccionar mejor ataques/skills futuros usando la nueva referencia de torso
   - decidir si el daño modular debe ponderar tambien frente/espalda del chasis inferior y no solo del torso
   - mantener Easy como modo plenamente jugable y legible

14. **Validar y tensionar el nuevo incentivo de borde**
   - playtestear si `repair_amount`, `boost_duration`, `surge_duration`, `charge_amount`, `stability_duration`, `stability_pickup_received_impulse_multiplier`, el nuevo `pulse_charge` y sus `respawn_delay` vuelven los bordes realmente tentadores o si alguno de los seis incentivos domina demasiado.
   - medir si las nuevas coberturas blockout, la rotacion semialeatoria por ronda y el nuevo split `Equipos=2 pares / FFA=3 tipos` ya generan duelos más tácticos o si algunos layouts siguen volviendo flancos demasiado seguros.
   - ajustar si el mazo actual necesita pesos finos por modo/mapa, otra seed por arena o más presencia de `pulso`/`municion`/`energia`/`estabilidad` antes de abrir más tipos de item.
   - revisar si la línea `Borde | ...` alcanza como lectura de laboratorio o si conviene una telemetría/playtest scene mejor antes de sumar más variedad.
   - confirmar por playtest si las nuevas siluetas runtime de `repair/mobility/energy/pulse/charge/utility` alcanzan para distinguir pickups de borde en cámara compartida o si alguna todavía necesita contraste/forma más marcada.
   - decidir si el siguiente paso de items debe ser variar el contenido del mazo, sumar más items de una sola carga o pasar a una capa mínima de inventario explícito.
   - mantener el centro limpio y legible, evitando saturar la arena con demasiados objetos.
   - validar si el gating actual de `municion` por roster alcanza o si algun modo necesita reglas propias mas explicitas para no dejar valor muerto o ventaja injusta.
   - medir si `estabilidad` realmente da contrajuego sano a `Baliza`/`interferencia` o si termina neutralizando demasiado la presion de control en FFA o post-muerte Teams.
   - ajustar por playtest si el color/tamano del nuevo `StatusEffectIndicator` alcanza para leerse en camara compartida o si necesita mas contraste antes de sumar VFX distintos.

15. **Validar el primer item de una carga en mano**
  - medir si compartir slot entre `pulse_charge` y `DetachedPart` genera la decisión correcta o si frustra demasiado rescates importantes.
  - revisar en playtest si la distincion nueva entre `pulse_charge` (CarryIndicator dorado) y `Pulso` de `Aguja` (`CoreLight` + `ArchetypeAccent` pulsando) se entiende al instante o si aun hace falta afinar contraste/ritmo.
  - ajustar `pulse_charge_projectile_speed`, `pulse_charge_impulse` y `pulse_charge_damage` para que el item reposicione sin eclipsar la embestida base.

16. **Mantener la compatibilidad documental sin abrir scope nuevo**
  - conservar explícitamente que `FFA` siga sin sistema post-muerte definitivo hasta que exista una decisión de diseño cerrada.
  - no escalar todavía a 6-8 jugadores ni 4v4 real mientras el núcleo de choque, rescate y legibilidad siga calibrándose en laboratorios de 4 jugadores.
  - si una iteración futura toca cualquiera de esos dos puntos, actualizar primero `Documentación/05_modos-de-juego.md`, `PLAN_DESARROLLO.md` y `ESTADO_ACTUAL.md` en el mismo cambio.
