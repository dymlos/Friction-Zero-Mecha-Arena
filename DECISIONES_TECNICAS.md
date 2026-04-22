# DECISIONES_TECNICAS.md - Friction Zero: Mecha Arena

## Decisiones vigentes

1. **Volver manualmente al target default debe reactivar el modo auto del soporte**
 - `_cycle_selected_target()` ya no deja `_manual_target_override = true` por inercia cuando el jugador cicla de vuelta al mismo target que `_get_default_support_target(candidates)` elegiría en ese frame.
 - Si el target visible vuelve a coincidir con el default, la nave limpia el override manual y recupera el auto-retarget frente a cambios runtime de accionabilidad.
 - `team_post_death_support_targeting_test.gd` fija el bug real con `interferencia`: override manual al rival alternativo, vuelta al default y posterior resincronización cuando ese default gana `estabilidad`.
 - Motivo: mantener “manual” solo por historial de input dejaba un estado invisible para el jugador y bloqueaba resincronizaciones que sí eran coherentes con el target visible actual.

1. **El gating de no-ops del soporte queda aceptado para el laboratorio `Teams` actual**
 - `support_payload_actionability_test.gd` ahora cubre no solo el bloqueo de consumo sino también la recuperación operativa: selección manual redundante, warning `ya activo`, uso fallido sin gasto y corrección con un único ciclo hacia el aliado útil.
 - No hubo cambio de producción en `PilotSupportShip` en esta iteración; la medición pasó con el comportamiento actual.
 - Motivo: en el prototipo `Teams` vigente el soporte corrige una mala decisión en un solo input extra, así que sumar auto-rescates sobre override manual volvería a pelear contra la intención del jugador sin evidencia de fricción real. El seam solo debe reabrirse si el modo suma más aliados simultáneos o cambia el costo del ciclado.

1. **La ejecución del soporte debe respetar la misma accionabilidad que ya comunica el roster**
 - `_resolve_support_target_for_payload()` ahora reutiliza `_is_payload_actionable_on_target(target_robot)` y no deja llegar a `apply_energy_surge()` / `apply_mobility_boost()` cuando el target ya estaba en `ya activo`.
 - `support_payload_actionability_test.gd` fija el bug real: `surge` y `movilidad` antes se consumían aunque no agregaran ventana útil; ahora fallan limpio y la carga queda disponible.
 - Motivo: el slice ya habia alineado targeting, warnings y cues diegéticos, pero seguía existiendo drift entre “lo que dice el soporte” y “lo que realmente gasta” justo en los buffs. Resolverlo en el seam de resolución mantiene una sola definición de utilidad sin duplicar checks por payload.

1. **El auto-target del soporte debe seguir la utilidad real tambien cuando el estado cambia durante la ronda**
 - `PilotSupportShip` ahora distingue target default de override manual con `_manual_target_override`.
 - `_refresh_target_selection()` puede resincronizar al mejor default solo si el target actual seguia en auto-target y perdió accionabilidad mientras otro candidato sí la conserva.
 - `team_post_death_support_targeting_test.gd` ya cubre ambos caminos: resincronización del default envejecido y preservación del override manual aunque el target elegido se vuelva un no-op.
 - Motivo: el slice ya habia alineado targeting inicial, roster y cues diegéticos, pero todavía podía quedarse clavado en un no-op envejecido tras un cambio runtime como `estabilidad` sobre el rival auto-seleccionado. Resolverlo dentro del targeting mantiene gameplay y lectura compacta consistentes sin auto-castear sobre un objetivo distinto al visible.

1. **Los marcadores diegéticos del soporte deben degradarse con la misma regla de utilidad que ya usa el roster**
 - `PilotSupportShip` ahora centraliza `_is_payload_actionable_on_target(target_robot)` para decidir si el payload seleccionado tendría efecto real inmediato.
 - `SupportTargetIndicator`, `SupportTargetFloorIndicator` e `InterferenceRangeIndicator` siguen visibles mientras exista un target/carga relevante, pero bajan intensidad si el payload actual ya cae en `sin daño`, `ya activo`, `estable` o `fuera de rango`.
 - Motivo: el roster compacto ya habia dejado de fallar “mudo”, pero el mundo seguia sugiriendo un target valido salvo por rango y aun dejaba el anillo de alcance demasiado “listo” frente a inmunidad por `estabilidad`. Mantener los tres cues sobre la misma nocion de accionabilidad evita drift sin sumar UI nueva.

1. **`Interferencia` tambien debe explicar cuando el objetivo sigue inmune por `estabilidad`**
 - `PilotSupportShip.get_status_summary()` ahora agrega `estable` si la carga actual es `interferencia`, existe un target seleccionado y ese rival mantiene `stability_boost` activo.
 - `_get_interference_target_priority(...)` tambien penaliza esa inmunidad, asi que el target por defecto ya prioriza un rival afectable antes que otro protegido por utility.
 - Motivo: `EdgeUtilityPickup` ya existia como contrajuego directo contra `zona/interferencia`, pero el soporte seguia pudiendo parecer “listo” sobre un objetivo inmune. Mantener la regla en targeting + summary conserva HUD y gameplay alineados sin otra UI.

1. **`Surge` y `movilidad` tambien deben explicar cuando reutilizarlos seria un no-op**
 - `PilotSupportShip.get_status_summary()` ahora agrega `ya activo` si la carga actual es `surge` o `movilidad`, existe un target seleccionado y ese aliado ya conserva al menos toda la ventana útil que aportaría otra activación del mismo payload.
 - `surge` compara contra `support_energy_surge_duration`; `movilidad` usa la duración efectiva del target (`support_mobility_boost_duration * get_mobility_boost_duration_multiplier()`), para no falsear el warning en arquetipos con boosts más largos.
 - Motivo: el slice de soporte ya habia resuelto los fallos silenciosos de `stabilizer` e `interferencia`, pero los buffs seguian pudiendo verse “listos” aunque volver a usarlos no cambiara nada. Mantener la regla en el summary conserva HUD y mundo alineados sin sumar UI.

1. **El targeting por defecto de `surge` y `movilidad` debe usar la misma definición de redundancia**
 - `PilotSupportShip` ya no decide esos buffs solo por activo/inactivo; ahora calcula cuánta ventana útil agregaría realmente el payload.
 - Si dos aliados ya están buffeados, el target inicial prioriza al que todavía ganaría segundos reales antes que al que ya quedó saturado.
 - Motivo: dejar `ya activo` en el roster pero seguir autoapuntando al aliado redundante mantenía HUD y gameplay fuera de fase. La misma métrica debe gobernar ambos.

1. **`Stabilizer` tambien debe explicar cuando todavia no tiene nada que reparar**
 - `PilotSupportShip.get_status_summary()` ahora agrega `sin daño` cuando la carga actual es `stabilizer`, existe un target seleccionado y ese aliado no tiene ninguna parte activa averiada.
 - La disponibilidad se calcula reutilizando `_get_total_missing_active_part_health(...)`, asi que el warning desaparece en cuanto aparece una averia real sobre ese mismo target.
 - Motivo: el slice de soporte ya habia resuelto el fallo silencioso de `interferencia`, pero `stabilizer` todavia podia quedar “armado” sobre un aliado sano sin explicar por que usarlo no aportaba nada. Mantener la regla en el summary conserva HUD y mundo alineados sin otra UI.

1. **La interferencia del soporte debe decir cuando todavia esta fuera de rango**
 - `PilotSupportShip.get_status_summary()` ahora agrega `fuera de rango` si la carga actual es `interferencia`, hay un target seleccionado y ese rival aun no entra en `support_interference_range`.
 - Motivo: el support slice ya tenia telegraph diegetico de rango, pero el roster compacto seguia fallando “mudo” cuando el jugador intentaba usar la carga demasiado pronto. Resolverlo en el summary mantiene HUD y mundo alineados sin otra UI.

1. **La nave de apoyo debe nacer vacia y con una breve gracia antes de recoger pickups**
 - `PilotSupportShip` ahora expone `spawn_pickup_grace_duration`, arma `_pickup_collection_lock_time_left` en `configure()` y no ejecuta `_try_collect_support_pickup()` hasta que esa ventana termina.
 - `get_status_summary()` agrega `sin carga` cuando el soporte sigue activo pero todavia no lleva payload.
 - Motivo: el carril estaba dando un payload gratis por simple solape al spawnear, lo que falseaba `Apoyo activo`, highlights y stats de soporte. El grace mantiene el loop tactico sin tocar la logica de pickups.

1. **Los tests de lifecycle del soporte deben neutralizar score ponderado antes de afirmar round reset**
 - `support_lifecycle_cleanup_test.gd` fija `void_elimination_round_points`, `destruction_elimination_round_points` y `unstable_elimination_round_points` a `1` cuando el objetivo es validar cleanup entre rounds.
 - Motivo: en el prototipo actual una sola ronda por `ring_out` puede cerrar el match completo; si el test quiere cubrir `_reset_round()` o limpieza de `SupportRoot`, debe pinnear score lifecycle y no depender del balance vigente.

1. **`Apoyo activo` solo debe mostrar informacion accionable del soporte**
 - `MatchController._build_robot_status_line()` corta estados de combate del robot cuando este ya está eliminado o inutilizado: no deja `skill ...`, foco/resumen de energía, buffs, `item ...` ni `carga ...` de un cuerpo que ya no puede actuar.
 - Si existe `support_state`, ese bloque queda como única fuente de información dinámica del jugador eliminado (`usa ...`, `interferido`, `payload > objetivo`).
 - Motivo: en Teams, seguir mostrando el estado interno del robot caído mezclaba dos actores distintos en una sola línea y degradaba la legibilidad del soporte post-muerte.

1. **El roster explicito no debe mezclar controles del robot caido con los del soporte activo**
 - `MatchController._build_robot_status_line()` mantiene `robot.get_input_hint()` solo si el jugador sigue controlando su robot y no tiene `support_state` activo.
 - El hint valido del slice post-muerte sigue viniendo de `PilotSupportShip.get_status_summary()`, que entra al roster via `Main._sync_post_death_support_state()`.
 - Motivo: cuando una baja Teams sigue jugando desde la nave, repetir el hint base del robot ensucia la linea y contradice la accion disponible real. Resolverlo en el builder de roster mantiene claridad sin otra UI.

1. **El roster vivo Teams debe marcar `Apoyo activo` cuando una baja sigue influyendo con la nave**
 - `MatchController._build_robot_status_line()` ya no deja `Fuera | ...` para un robot eliminado que todavía tiene `support_state`; en ese caso publica `Apoyo activo | <causa>`.
 - `PilotSupportShip.get_status_summary()` devuelve un resumen compacto (`usa ...`, `interferido`, `payload > objetivo`) para que el roster conserve hints y target sin repetir `apoyo` varias veces.
 - Motivo: en el slice post-muerte Teams, un jugador eliminado sigue siendo actor táctico. Leerlo igual que una baja cerrada escondía valor real del carril y empeoraba claridad sin necesidad.

1. **El soporte decisivo debe quedar explicado en el cierre, no solo contado**
 - `Main._on_post_death_support_payload_used(...)` ahora pasa el `target_robot` real a `MatchController.record_support_payload_use(...)`.
 - `MatchController` conserva un solo highlight compacto por ronda/competidor (`Apoyo decisivo | <owner> <payload> > <objetivo>`) y lo expone solo en recap/resultado para el ganador Teams.
 - Motivo: `support_rounds_decided` ya medía impacto agregado, pero el cierre seguía sin responder qué apoyo concreto inclinó la ronda. Resolverlo en la misma capa de highlights mantiene legibilidad sin abrir HUD nuevo ni otra telemetría post-mortem.

1. **La presión final del arena debe avisar antes del shrink real**
 - `MatchController` mantiene la contracción real en `get_current_play_area_scale()`, pero ahora abre un warning separado con `space_reduction_warning_seconds`, `get_time_until_space_reduction()` y `get_space_reduction_warning_strength()`.
 - `Main` sigue siendo el cable fino entre match y arena: envía `set_play_area_scale(...)` para el shrink y `set_pressure_warning_strength(...)` para el preview.
 - `ArenaBase` reutiliza el mismo `PressureTelegraph` con alpha/emission más bajos durante el warning, sin achicar todavía el borde vivo.
 - Motivo: la versión anterior solo comunicaba la presión cuando ya estaba ocurriendo; este paso refuerza lectura y pacing sin sumar otro sistema ni ruido visual.

1. **El soporte post-muerte Teams prioriza utilidad del payload y no `scene-order` cuando hay varios objetivos vivos**
 - `PilotSupportShip` ahora calcula prioridad por payload y la usa tanto para el target inicial como para el orden de ciclado.
 - `stabilizer` mira vida faltante en partes activas; `surge`/`mobility` miden ventana útil real del buff; `interference` prefiere rivales en rango y no suprimidos antes de volver a distancia.
 - Motivo: el riesgo documental era que Teams dependiera demasiado de coordinacion perfecta. Esta capa reduce friccion sin sumar UI ni otra mecanica de soporte.

1. **La apertura base de Teams debe priorizar cercanía entre aliados antes que simetría en cruz**
 - `Main._get_bootstrap_spawn_transforms()` ya reutiliza el orden de `ArenaBase.get_spawn_points()` en Equipos, así que la fuente de verdad correcta para esa apertura es el layout del arena, no una capa extra de reasignación en runtime.
 - `arena_blockout.tscn` pasó de un layout en cruz a dos laterales por equipo; `teams_spawn_coordination_test.gd` fija que cada robot quede más cerca de su aliado que del rival más cercano en `main.tscn` y `main_teams_validation.tscn`.
 - Motivo: la identidad Teams pide coordinación/rescate desde el primer beat. Corregir el arena mantiene el sistema simple para un proyecto Godot principiante y evita abrir heurísticas extra de spawn assignment.

1. **Los tests de score deben leer `MatchConfig`; los tests de lifecycle deben fijar `1/1/1`**
 - `MatchController._finish_round_with_winner()` suma puntos via `get_round_victory_points_for_cause(...)`, así que cualquier test de HUD/standings/resultado que espere score real debe derivarlo desde `MatchConfig`.
 - Si el objetivo del test es el lifecycle entre rondas/partida y no el balance, debe pinnear `void/destruccion/inestable = 1` dentro del propio test para evitar falsos rojos cuando cambie el peso por causa.
 - Motivo: separar contrato de score de contrato de lifecycle evita que la calibración de cierre rompa regresiones que en realidad validan otra cosa.

1. **Los tests que necesiten un arranque sin intro deben tocar `MatchConfig.round_intro_duration_ffa/teams`**
 - Desde la separación por modo, `_resolve_round_intro_duration()` prioriza `match_config.get_round_intro_duration(...)`; dejar solo `MatchController.round_intro_duration = 0.0` ya no garantiza un laboratorio sin intro.
 - Motivo: los falsos rojos en presión de arena y soporte post-muerte salían de seguir anulando el seam viejo en vez de la config efectiva por modo.

1. **El laboratorio admite toggle directo de `Easy/Hard` por slot con las teclas `1-8`**
 - `Main._unhandled_input()` ahora traduce `KEY_1..KEY_8` a `player_slot` y delega en `toggle_lab_control_mode_for_player_slot()`, que reaprovecha `_apply_lab_runtime_loadout(...)` para cambiar modo sin reabrir escena.
 - `F2/F3/F4` siguen como selector fino, pero el flujo corto de playtest ya no depende de recorrer slots uno por uno solo para comparar controles.
 - Motivo: reducir fricción del laboratorio y validar mejor el soporte Hard sin meter otro menú ni persistencia prematura.

1. **La telemetría de soporte distingue rondas decisivas y se publica en el mismo bloque de cierre**
 - `MatchController.record_support_payload_use()` marca `_round_support_usage_by_competitor`; al cerrar la ronda, `_finish_round_with_winner()` incrementa `_match_decided_rounds`, `_match_decided_rounds_with_support` y `support_rounds_decided` del competidor ganador si hubo apoyo real en esa ronda.
 - `get_match_result_lines()` y `get_round_recap_panel_lines()` ahora incluyen `Aporte de apoyo | X/Y rondas ...` y extienden `Stats | ...` con `rondas decisivas por apoyo ...`.
 - Motivo: medir si el soporte Teams cambia cierres reales sin abrir otra telemetría separada ni inflar la UI post-partida.

1. **El tuning actual de arquetipos se trata como línea base de laboratorio, no como balance final**
 - Los recursos `ariete/grua/cizalla/patin/aguja/ancla_archetype.tres` reciben ajustes de multiplicadores sobre empuje, daño, movilidad, recuperación y timings de skill, pero sin crear sistemas nuevos.
 - Motivo: el siguiente paso es playtest corto con identidades más marcadas; documentarlo como baseline evita leer estos números como cierre definitivo de balance.

1. **Los tests de cierre deben distinguir score por causa vs lifecycle de match**
 - `MatchController._finish_round_with_winner()` suma score usando `MatchConfig.get_round_victory_points_for_cause(...)`, así que los tests ya no pueden asumir `+1` fijo por victoria.
 - `match_round_resolution_test.gd` valida el contrato real del score por causa; `match_completion_test.gd` fuerza `void/destruction/unstable = 1` porque su objetivo es validar el ciclo `first-to-X`.
 - Motivo: separar “balance de score” de “lifecycle de match” evita falsos rojos y permite seguir tuneando pesos por causa sin romper tests de reinicio/cierre.

1. **La sensibilidad base de `RobotBase` queda congelada hasta que falle una prueba de pacing o un playtest corto**
 - La nueva cobertura `robot_collision_pacing_test.gd` fija dos seams del núcleo: glide corto al soltar input y daño modular de choque solo cuando la velocidad de cierre supera `collision_damage_threshold`.
 - Motivo: la tarea abierta pedía revisar sensación de choque/control, pero la evidencia actual no justificó retocar `move_acceleration`, `glide_damping`, `passive_push_strength` ni `collision_damage_scale`; mover esos valores sin rojo reproducible habría sido tuning por intuición.

1. **La base de escena principal y sus variantes de laboratorio no muestran referencias rotas**
 - Estado al 2026-04-22: se verificó que `main.tscn`, `main_ffa.tscn`, `main_teams_validation.tscn` y `main_ffa_validation.tscn` tienen rutas de recursos coherentes y disponibles en disco.
 - Hallazgo residual: esta auditoría no sustituye un chequeo runtime completo; la validación de carga y sensación se realiza en la siguiente tarea de sensibilidad de combate de ambos modos de laboratorio.
 - Motivo: mantener estabilidad del loop antes de abrir más tuning, evitando tocar movimiento/choque sobre una base de escena que ya podía romperse por referencias.

1. **Las cuatro escenas principales quedan cubiertas por smoke runtime y todas cargan `MatchConfig`**
 - `scripts/tests/main_scene_runtime_smoke_test.gd` instancia `main.tscn`, `main_ffa.tscn`, `main_teams_validation.tscn` y `main_ffa_validation.tscn`, verificando `Main`, `MatchController`, `MatchHud`, arena válida, cuatro robots jugables, round boot real y wiring del selector runtime.
 - Hallazgo relevante: las escenas base no corren “sin config”; heredan `default_match_config.tres` desde `scenes/systems/match_controller.tscn`, mientras las variantes de validación sólo lo sobreescriben.
 - Motivo: convertir una auditoría de archivos en una garantía runtime mínima y fijar la fuente de verdad real del arranque de escenas para futuras iteraciones/tests.

1. **El target textual del soporte post-muerte reutiliza tambien el nombre de roster**
   - `PilotSupportShip._get_selected_target_label()` ahora devuelve `target_robot.get_roster_display_name()` y no `display_name`.
   - Motivo: despues de corregir roster vivo y cierres para conservar `Player / Arquetipo`, dejar `apoyo ... > Player X` en la nave Teams seguia abriendo otra fuga de identidad justo en una capa de lectura tactica. Reusar el mismo helper mantiene continuidad sin sumar otro formato textual.

1. **Cierre de la validación del soporte post-muerte Teams en laboratorio quedó en estado operativo estable**
   - Se prioriza `main_teams_validation.tscn` como escena de validación de soporte y se deja el ciclo actual de soporte como base estable: `respawn_delay` de pickups (`3.4`/`3.9`/`4.2`/`4.8`) en `arena_blockout.tscn`, nave externa con `move_speed = 8.5` y `support_lane_gates` con `closed_duration/open_duration = 0.9/1.75`.
   - Motivo: con la integración actual, el soporte aporta decisiones tácticas (selección de objetivo, pickups de apoyo y timing de gates) sin introducir aún una regla de intervención que opaque el combate principal; por ahora no se aplican cambios de balance hasta validar con sesiones tempranas de caída en `main.tscn/main_teams_validation.tscn`.
   - Seguimiento: si las sesiones muestran carril dominante o irrelevante, ajustar primero `PilotSupportShip.move_speed` y `pilot_support_pickup.respawn_delay` antes de añadir más complejidad de rutas/obstáculos.

1. **La decision final de FFA usa wording propio, no score tipo duelo**
   - `MatchController._finish_match_with_winner()` ahora delega en `_build_match_victory_status_line()`: en `FFA` devuelve `Player X gana la partida con N punto(s)` y en `Equipos` conserva `Equipo X gana la partida A-B`.
   - Motivo: el cierre FFA ya muestra `Marcador`, `Posiciones` y `Desempate`; repetir arriba un `X-Y` heredado de duelo confundia la lectura de un match con mas de dos competidores.

1. **El detalle compacto de cierre reutiliza tambien el nombre de roster**
   - `MatchController._build_robot_recap_panel_line()` ahora arma sus lineas con `robot.get_roster_display_name()` y no con `robot.display_name`.
   - Motivo: despues de volver legible el roster vivo con `Player / Arquetipo`, dejar recap y resultado final en `Player X` pelado seguia rompiendo continuidad justo en la pantalla que explica quien sobrevivio, cayo o quedo inutilizado. Reusar el mismo helper evita otra fuente de identidad paralela.

1. **Las stats del cierre reutilizan el mismo orden real del resultado**
   - `MatchController._build_match_stats_lines()` ya no itera `_competitor_order` crudo; ahora pasa por `_get_match_stats_ordered_competitors()`, que en `Teams` reutiliza `_compare_team_competitors_for_recap()` y en `FFA` `_compare_ffa_competitors_for_standings()`.
   - Motivo: despues de corregir `Marcador`, `Posiciones`, `Desempate` y el detalle por robot, dejar `Stats | ...` en scene-order seguia mezclando una telemetria correcta con un orden stale justo en el panel que explica el cierre. Reusar los mismos comparators mantiene una sola lectura del resultado sin inventar otra regla.

1. **El detalle por robot del cierre Teams tambien sigue el resultado real**
   - `_get_recap_ordered_robots()` ahora ordena `Teams` con `_compare_team_robots_for_recap()` en vez de devolver `registered_robots` crudo; el comparator prioriza al equipo que sigue en pie en la ronda cerrada, desempata por score de match y, dentro de cada equipo, deja primero sobrevivientes/robots aun no eliminados y luego las bajas en el orden real de `_round_elimination_order_by_robot_id`.
   - Motivo: despues de cerrar la incoherencia equivalente en `FFA`, dejar `Teams` en scene-order seguia mezclando la explicacion del cierre cuando ganaba el segundo equipo del laboratorio. Reusar un orden derivado del estado real mantiene el recap legible sin inventar otra UI ni tocar el sistema de score.

1. **El detalle por robot del cierre FFA reutiliza el mismo orden de standings**
   - `get_round_recap_panel_lines()` y `get_match_result_lines()` ahora iteran `_get_recap_ordered_robots()`; en `FFA`, ese helper ordena los robots con `_compare_ffa_competitors_for_standings()` en vez de respetar `registered_robots`.
   - Motivo: despues de ordenar `Marcador`, `Posiciones` y `Desempate`, dejar el breakdown final en scene-order seguia mezclando dos lecturas distintas del mismo cierre. Reusar el comparator existente mantiene consistencia sin inventar otra regla.

1. **La apertura neutral FFA oculta tambien el score vivo**
   - `MatchController._build_score_summary_line()` ahora reutiliza `_should_show_live_ffa_standings()` cuando el match corre en `FFA`, de modo que `Marcador | ...` desaparece junto con `Posiciones | ...` y `Desempate | ...` mientras todo sigue 0-0 y nadie fue eliminado.
   - Motivo: el criterio anterior ya habia limpiado standings/desempate, pero dejar el score 4-way empatado en pantalla seguia metiendo ruido en el momento mas limpio de la ronda. Reusar el mismo gate mantiene el HUD coherente sin abrir otra regla.

1. **El ranking vivo de FFA solo aparece cuando ya informa algo**
   - `MatchController` ahora deja `Posiciones | ...` y `Desempate | ...` fuera de `get_round_state_lines()` mientras la ronda sigue activa, nadie fue eliminado y todos los competidores continúan con el mismo score; en recap/resultado final se mantienen siempre, y durante la ronda reaparecen apenas hay score divergente o una baja que ya rompa la neutralidad.
   - Motivo: la lectura FFA en vivo era valiosa, pero imprimir una tabla 4-way empatada al arranque agregaba ruido justo en el momento mas limpio del match. El criterio nuevo preserva la informacion importante sin volver opaco el opening.

1. **El desempate FFA nombra a quienes van arriba dentro del empate**
   - `MatchController._build_ffa_tiebreaker_line()` ahora agrupa por score empatado y publica segmentos concretos como `0 pts: Player 3 > Player 2 > Player 1`, reutilizando el mismo comparator de standings para HUD vivo, recap y resultado final.
   - Motivo: la nota generica `score igual -> mejor cierre de la ronda final` dejaba claro que habia desempate, pero no explicaba quien lo estaba ganando. Nombrar el orden real cierra mejor el “por que voy segundo/cuarto” sin abrir otra UI ni otro criterio paralelo.

1. **El arranque legible de ronda vive en `MatchController`, no en otra UI o escena**
  - `MatchController` ahora expone `round_intro_duration`, mantiene `_round_intro_remaining`, publica `Ronda N | arranca en ...` y no deja avanzar tiempo/contraccion mientras sigue ese beat inicial; `Main` solo sincroniza el lock hacia `RobotBase`, que lo vuelve visible en mundo mediante `RoundIntroIndicator`.
  - Motivo: el hueco contra `Documentación/07` era de ritmo, no de presentación. Resolverlo en el lifecycle de ronda preserva el laboratorio existente, evita duplicar escenas/countdowns y deja el “inicio parejo -> análisis -> escalada” como comportamiento real del match, mientras el aro diegético evita depender solo del HUD en cámara compartida.

1. **El intro de ronda ahora puede diferir entre FFA y Equipos por configuración**
  - `MatchConfig` expone `round_intro_duration_ffa` y `round_intro_duration_teams`; `MatchController._resolve_round_intro_duration()` usa el valor del modo activo al iniciar ronda y al hacer reset.
  - Motivo: permite ajustar el tempo de apertura de combates de forma explícita por modo sin tocar escenas, manteniendo el loop de match estable y la sensación de control compartido.

1. **El fallback de escena sobrevive a `match_config` nulo para laboratorios que heredan `match_controller.tscn`**
  - `MatchController._resolve_round_intro_duration()` usa `match_controller.round_intro_duration` cuando `match_config == null`, y el campo queda documentado como override de escena para casos donde una escena hereda el controller sin recurso de config.
  - Motivo: evita ambigüedad entre el override local y los valores por modo: si una escena de laboratorio omite `MatchConfig`, el ritmo de apertura seguirá funcionando desde nodos propios sin romper startup.

1. **La atribucion de bajas vive estrictamente por ronda**
   - `MatchController._reset_round()` ahora limpia `_round_elimination_source_robot_ids` junto con recap/orden/cierre.
   - Motivo: `Ultima baja` usa el agresor del evento actual, pero `RecapPanel` y `MatchResultPanel` reconstruyen `por Player X` leyendo ese mapa; si no se limpiaba al reset, una baja sin agresor en la ronda nueva heredaba autoria vieja y rompia la explicacion de derrota.

1. **Daño modular por direccion en vez de hitboxes complejos**
   - Se calcula la parte afectada segun la direccion del golpe respecto al robot impactado.
   - Motivo: valida rapido la fantasia de brazos al frente y piernas atras sin introducir una malla fisica dificil de mantener.

2. **Partes desprendidas como escena separada y simple**
   - `DetachedPart` clona los meshes visibles de la parte destruida y usa una colision aproximada por tipo.
   - Motivo: deja el sistema listo para futura recuperacion/negacion sin rehacer el robot base.

3. **Penalizaciones funcionales derivadas del estado modular**
   - Piernas afectan movilidad/control; brazos afectan empuje/ataque.
   - Motivo: cumple el objetivo de que perder partes cambie la pelea inmediatamente y de forma legible.

4. **Recuperacion modular sin input extra**
   - Las partes se recogen por cercania; el robot original puede recuperarlas directamente y un aliado puede cargarlas hasta devolverlas.
   - Motivo: validar rescate/negacion rapido sin sumar botones ni una UI compleja antes de probar si el loop espacial funciona.

5. **Negacion basica via riesgo espacial**
   - El portador puede negar una parte si cae al vacio mientras la lleva, o si la lanza para crear una ventana de riesgo adicional.
   - Motivo: mantiene la negación legible y posicionada, y obliga a tomar decisiones tácticas en lugar de intercambios instantáneos.

6. **Cuerpo inutilizado con explosion corta y respawn**
   - Al perder las cuatro partes, el robot queda inactivo, cuenta unos segundos, explota con empuje/danio radial y luego vuelve al spawn.
   - Motivo: cierra la segunda ruta de eliminacion sin dejar cuerpos permanentes ni romper el ritmo de prueba del match.

7. **Verificacion headless por scripts dedicados**
   - Se agregaron `scripts/tests/robot_part_return_test.gd` y `scripts/tests/robot_disabled_explosion_test.gd`.
   - Motivo: verificar el loop modular nuevo con algo mas fuerte que un simple arranque del proyecto, sin introducir una infraestructura de tests mas pesada de la necesaria.

8. **Las skills de proyectil se validan tambien en su frame de spawn**
   - `robot_core_skill_test.gd` ahora inspecciona el grupo `temporary_projectiles` tras disparar `Pulso` y comprueba que el proyectil no nazca solapado con el robot origen.
   - Motivo: cubrir un contrato fisico fino del arquetipo Poke/Skillshot sin depender de warnings del engine ni de inspeccion manual en playtests.

9. **`PulseBolt` apaga su hitbox antes de liberarse**
   - Al impactar o agotar lifetime, `PulseBolt` entra primero en un estado corto de despawn: deja de procesar, oculta el visual, desactiva `monitoring`/`CollisionShape3D` y solo despues hace `queue_free()`.
   - Motivo: evitar eventos stale de `Area3D` durante el teardown del proyectil y dejar el contrato del skillshot mas robusto para tests y runtime.

10. **La suite headless vive en un runner Godot del propio repo**
   - `scripts/tests/test_runner.gd` descubre cualquier `*_test.gd` bajo `scripts/tests`, se excluye a si mismo y ejecuta cada script como subproceso del mismo binario Godot con `--headless --path ... -s ...`; `test_suite_runner_test.gd` protege ese discovery.
   - Motivo: el proyecto ya dependia de “suite completa `scripts/tests/*.gd`” como verificacion recurrente, pero habia perdido el entrypoint comun; reinstalarlo dentro del mismo repo deja la validacion repetible para futuras iteraciones sin shell ad-hoc ni conocimiento oculto.

10. **Bootstrap local desde `main` en vez de confiar en la escena armada a mano**
   - `main.gd` ahora asigna spawns y slots locales a los robots ya presentes en la escena.
   - Motivo: deja el prototipo mas facil de entender y evita escenas "correctas por casualidad" cuando se suman mas jugadores o se cambian spawns.

10. **Ownership de input por slot, no por dispositivo global**
   - Cada `RobotBase` usa un perfil de teclado concreto o un joystick resuelto por slot/dispositivo explicito.
   - Motivo: elimina el problema de varios robots leyendo las mismas teclas o todos los joysticks a la vez, que hacia engañosa cualquier prueba local de combate.

11. **HUD de roster compacto en vez de barra pesada**
   - El HUD nuevo lista estado de ronda, marcador compacto y estado/carga por robot, sin barras invasivas.
   - Motivo: mejora la lectura del loop modular y del cierre de ronda sin romper la prioridad del proyecto por claridad y pantalla compartida limpia.

12. **Redistribucion de energia discreta por foco de parte**
   - Cambiar el foco reasigna energia entre las cuatro partes usando presets simples en vez de sliders o menus.
   - Motivo: vuelve tactica la energia ya en este prototipo sin exigir una UI compleja ni microgestion poco legible.

13. **Energia aplicada como multiplicador real separado de la salud**
   - La salud sigue definiendo la degradacion base; la energia ahora suma o resta rendimiento sobre movilidad y empuje aunque la pieza siga sana.
   - Motivo: evita que la energia quede anulada por clamps internos y hace visible la decision antes del choque.

14. **Overdrive corto con recuperacion y cooldown**
   - El overdrive concentra energia en la parte foco durante una ventana breve y luego deja una penalizacion temporal antes de volver a estar disponible.
   - Motivo: respeta la idea de apuesta de alto riesgo/alta recompensa sin convertir la redistribucion en spam.

15. **Negacion de parte por lanzamiento**
   - Se añadió una acción dedicada para lanzar una parte transportada, permitiendo negar recuperaciones sin introducir un sistema de item adicional.
   - Motivo: conectar el bucle de rescate con decisiones de espacio/tiempo y mantener el control del estado legible.

16. **Los indicadores diegeticos dependientes de timers se resincronizan tambien desde `_process()`**
   - `RobotBase` vuelve a ejecutar `_refresh_disabled_warning_indicator()` cada frame antes de animar el warning de explosion diferida.
   - Motivo: el teardown del cuerpo inutilizado podia dejar `DisabledWarningIndicator.visible` stale aunque el robot ya hubiera explotado/ocultado; resincronizar desde el loop visual mantiene el flag local alineado con `_is_disabled`, `_is_respawning` y `time_left` sin abrir otro estado paralelo.

82. **La negacion modular se acredita desde `recovery_lost`, no con otro tracker paralelo**
   - `DetachedPart` conserva el ultimo portador solo para el momento de perderse al vacio; `Main` usa ese dato para convertir `recovery_lost = "void"` en `negaciones N` unicamente si quien la niega no es aliado del dueño original.
   - Motivo: el loop rescate/negacion ya tenia el evento correcto; reaprovecharlo mantiene la regla simple, evita duplicar estado en runtime y vuelve el cierre de partida mas explicativo sin otra UI.

83. **Los “replay snippets” del prototipo viven como momentos textuales dentro del cierre existente**
   - `MatchController` conserva tambien el primer y el ultimo resumen completo de eliminacion de cada ronda para exponer `Momento inicial | ...` y `Momento final | ...` en `RecapPanel` y `MatchResultPanel`; si solo hubo una baja relevante, colapsa a `Momento clave | ...`.
   - Motivo: el documento pedia una pista de jugadas importantes al final, pero grabar replay real todavia seria demasiado costoso; reusar la telemetria de bajas da un cierre mas memorable sin otra escena, sin buffers de input/video y sin romper la claridad del HUD.

84. **El panel final reutiliza tambien el recap compacto por robot**
   - `MatchController.get_match_result_lines()` ahora agrega el mismo `_build_robot_recap_panel_line(robot)` que usa el recap lateral, de modo que `MatchResultPanel` repite `Player X | baja N | causa` o `sigue en pie` sin mantener otra estructura paralela.
   - Motivo: la vista centrada de cierre es la mas visible y antes dependia del recap lateral para responder “como perdi”; reutilizar la misma linea compacta mejora esa explicacion sin abrir UI nueva ni duplicar telemetria.

85. **La condicion final de extremidades vive dentro de la misma linea compacta por robot**
   - `_build_robot_recap_panel_line(robot)` ahora tambien agrega `N/4 partes` y, cuando corresponde, `sin brazo/pierna ...` usando el estado modular real de `RobotBase`.
   - Motivo: la causa de baja por si sola no explicaba en que estado quedo cada robot; sumar el snapshot modular final refuerza el “como perdi” y el “como sobrevivi” reutilizando el mismo contrato de recap/resultado, sin otra UI ni otra telemetria.

86. **`Ariete` resuelve su skill propia como una ventana de buff corta, no con otra escena**
   - `RobotArchetypeConfig` suma `CoreSkillType.RAM_BOOST` y cuatro hooks simples (`duration`, `drive`, `arm_power`, `received_impulse`); `RobotBase.use_core_skill()` lo traduce a `Embestida`, una ventana corta que amplifica movimiento/impacto/estabilidad reutilizando multiplicadores ya existentes.
   - Motivo: el hueco mas claro del roster era que `Ariete` seguia leyendo solo como tuning pasivo. Reusar seams de drive/push/impulse refuerza la fantasia de choque pesado, mantiene el proyecto legible para Godot principiante y evita abrir proyectiles, otra escena o una capa nueva de HUD.

87. **La lectura activa de `Embestida` vive en cuerpo + roster**
   - Mientras `is_ram_skill_active()` dura, `RobotBase._refresh_core_visuals()` calienta el core hacia naranja y `MatchController._build_robot_status_line()` agrega `embestida` al roster compacto, conservando aparte `skill Embestida x/y` como estado de cargas.
   - Motivo: el buff necesitaba verse en pantalla compartida, pero no justificaba otro widget; repetir el mismo patron de “estado temporal corto dentro del roster existente + refuerzo diegetico en el robot” mantiene claridad sin inflar la UI.

88. **`Patin` resuelve su skill propia como una rafaga corta dentro del mismo movimiento**
   - `RobotArchetypeConfig` ahora soporta `CoreSkillType.MOBILITY_BURST` y un `core_skill_control_multiplier`; `patin_archetype.tres` lo expone como `Derrape`, y `RobotBase._use_mobility_burst()` reaprovecha `_planar_velocity`, `external_impulse` y los multiplicadores de piernas para meter desplazamiento inmediato + una ventana breve de drive/control reforzados.
   - Motivo: el hueco restante del roster era que `Patin` seguia leyendo mas como tuning que como rol activo. Reusar el pipeline de movimiento preserva la fantasia principal de patinar/reposicionarse, evita otro proyectil o hazard y mantiene el proyecto legible para Godot principiante.

89. **La lectura activa de `Derrape` tambien vive en cuerpo + roster**
   - Mientras `is_mobility_skill_active()` dura, `RobotBase` sube el blend turquesa de core/accent y `MatchController._build_robot_status_line()` agrega `derrape` junto a `skill Derrape x/y`.
   - Motivo: la skill de movilidad necesitaba verse en pantalla compartida sin abrir HUD nuevo; repetir el mismo patron de estado temporal corto evita ruido y deja claro cuando el reposition viene del propio arquetipo y no solo de un pickup de `impulso`.

90. **El castigo de `Cizalla` tambien marca la pieza victima, no solo al atacante**
   - Cuando `apply_damage_to_part()` cobra el bonus contra una extremidad ya dañada, el robot impactado abre un `DamageFeedback/DismantleCue` corto en esa misma pieza; el cue usa el anchor runtime ya existente para humo/chispa y se apaga con la misma ventana `damaged_part_bonus_highlight_duration`.
   - Motivo: el cue `corte` + pulso de `ArchetypeAccent` volvia legible al atacante, pero seguia faltando decir “que pieza del rival acaban de castigar”; colgar ese dato del mismo feedback por parte mantiene la lectura diegetica y evita otro HUD o escena paralela.

16. **Ajuste de ritmo de duelo via parámetros exportados**
   - Se prefirió reajustar el duelo 2P ajustando `RobotBase` en lugar de agregar una mecánica nueva.
   - Motivo: el equilibrio de inercia, alcance/impulso y daño de choque define la sensación principal del prototipo sin comprometer la simplicidad técnica existente.

17. **2v2 de laboratorio con equipos y 4 slots locales**
  - Se habilitó `main.tscn` con 4 robots y `local_player_count=4`, usando `team_id` para aliar jugadores en parejas.
  - Motivo: validar rescate entre aliados en partidas 2v2 reales sin introducir todavía un mode manager completo de matchmaking.

18. **Indicador de carga de parte legible sin HUD pesado**
   - `RobotBase` muestra un indicador diegético sobre el robot cuando transporta una parte, con color por tipo de parte y pulso leve.
   - Motivo: mejora la legibilidad para aliados, rivales y espectadores sin añadir una interfaz pesada en pantalla compartida.

19. **Validación 2v2 sobre la escena real, no sobre un mock aislado**
   - El coverage nuevo de rescate/negación usa `scenes/main/main.tscn` y no solo robots sueltos.
   - Motivo: verifica a la vez equipos, bootstrap local, indicador de carga y retardos de pickup/lanzamiento en el contexto que realmente se prueba el laboratorio.

20. **Tests headless con salida confiable**
   - Los scripts de `scripts/tests/` ahora conservan un flag `_failed` y finalizan con `quit(1 if _failed else 0)`.
   - Motivo: evitar falsos verdes en automatización cuando una aserción registra error pero el script llega al `quit()` final.

21. **Scoring de ronda simple y simétrico para el prototipo**
  - Ring-out y destrucción total cuentan igual: eliminan al robot de la ronda y el último contendiente en pie suma un punto.
  - Motivo: cerrar el sandbox infinito con la menor cantidad de reglas nuevas, sin comprometer todavía el diseño final de puntuación por modo.

22. **La puntuación por causa ya tiene telemetría de impacto de soporte en cierre**
  - `MatchController` usa `MatchConfig.get_round_victory_points_for_cause` para sumar la puntuación correcta antes de comparar `rounds_to_win`, y eso ya está validado en `TEAMS` y `FFA`.
  - Para sesiones de ajuste, cada cierre de ronda registra si el ganador usó soporte post-muerte en esa ronda; el acumulado queda en `support_rounds_decided` dentro de `MatchStats`.
  - `_build_support_stats_segment(stats)` ahora incluye `rondas decisivas por apoyo X/Y (%)` y `match_elimination_victory_weights_test.gd` corre ambos modos con el mismo contrato.

22. **Cierre de match first-to-X desde `MatchConfig`**
  - El objetivo de rondas vive en `rounds_to_win`; cuando un competidor lo alcanza, `MatchController` anuncia ganador de partida y detiene la ronda actual.
  - Motivo: el prototipo necesitaba una condición de victoria real, configurable y fácil de leer sin meter un mode flow más pesado todavía.

23. **Reinicio automático tras victoria de match**
   - Tras una pausa corta (`match_restart_delay`), el laboratorio reinicia el match completo y vuelve a ronda 1 con score limpio.
   - Motivo: mantener la escena siempre jugable en playtests locales y evitar volver al estado de sandbox infinito o exigir UI/menu extra en esta etapa.

24. **Robots eliminados quedan fuera hasta el reset común**
   - `RobotBase` ahora puede quedar retenido para el reset de ronda en vez de auto-respawnear inmediatamente tras vacío o explosión.
   - Motivo: preservar lectura del resultado, evitar que una baja decisiva se “deshaga” sola y mantener el cierre de ronda legible.

25. **Cierre de ronda validado sobre la escena real**
   - `match_round_resolution_test.gd` usa `main.tscn` para comprobar victorias por vacío y destrucción total, marcador y reset conjunto.
   - Motivo: la lógica de ronda depende de `Main`, `MatchController`, HUD y lifecycle de `RobotBase`; probar piezas aisladas dejaría huecos importantes.

26. **Cierre de match validado con la escena real**
   - `match_completion_test.gd` también usa `main.tscn` para verificar objetivo first-to-X, anuncio de ganador y reinicio limpio del match.
   - Motivo: la victoria de match depende del mismo wiring real entre `Main`, `MatchController`, HUD, timers y robots eliminados; un mock aislado dejaría fuera el lifecycle crítico.

26. **Control Hard como capa separada del loop Easy**
   - `RobotBase` mantiene `ControlMode.EASY` como default y solo activa torso independiente cuando el robot entra en `ControlMode.HARD`.
   - Motivo: preservar la accesibilidad del prototipo base y evitar que la profundidad tecnica invada el loop principal antes de probarla.

27. **Torso independiente via `UpperBodyPivot`**
   - El torso/cabina rota sobre un pivot visual propio, sin cambiar automaticamente la orientacion del chasis.
   - Motivo: obtener lectura visual real del modo Hard y una base clara para futuras mejoras sin rearmar toda la escena del robot.

28. **Orientacion de combate reutilizada para ataque y daño modular**
   - En Hard, ataques, fallback de empuje y seleccion de parte impactada leen la direccion del torso en vez del `basis` completo del robot.
   - Motivo: que el modo Hard no sea solo cosmetico y que la fantasia de “torso apunta / chasis patina” empiece a afectar el combate real.

29. **Soporte Hard actual prioriza joypad**
   - El aim independiente se toma del stick derecho; si no existe input dedicado, el torso conserva/alinea orientacion sin romper el robot.
   - Motivo: sumar la estructura base con el menor ruido posible en el laboratorio actual, que sigue muy apoyado en teclado compartido y Easy mode.

30. **Exposicion de Hard por slot en `Main`**
   - `Main` define `hard_mode_player_slots` y asigna `ControlMode.HARD` o `EASY` durante el bootstrap local.
   - Motivo: volver el soporte Hard realmente testeable en el laboratorio sin introducir todavía menús, perfiles persistentes ni un selector previo a partida.

31. **El roster compacto puede operar en modo explicito o contextual**
   - `MatchController` filtra las mismas lineas del roster segun `MatchConfig.hud_detail_mode`: `EXPLICIT` deja visible modo de control, hints y estado completo; `CONTEXTUAL` oculta lo estable y reexpone solo lo tacticamente relevante.
   - Motivo: cumplir el documento de HUD configurable sin duplicar escenas ni fijar el laboratorio a un unico nivel de ruido visual.

32. **Control Hard validado con test de impacto dirigido**
   - `robot_hard_control_mode_test.gd` comprueba que el mismo vector de golpe pasa de castigar pierna trasera a castigar un brazo cuando el torso gira en Hard.
   - Motivo: cubrir el contrato importante del slice sin depender de input real ni de una escena de match completa.

33. **Bootstrap Hard validado en la escena principal**
   - `hard_mode_bootstrap_test.gd` usa `main.tscn` para verificar asignacion por slot y visibilidad del modo en el roster.
   - Motivo: el valor del slice esta en exponer el soporte dentro del laboratorio real; probar solo el robot aislado no cubria ese wiring.

34. **Contraccion del arena como presion fisica real**
   - `MatchController` calcula un factor de cierre segun `round_time_seconds` y `ArenaBase` reduce el tamano real del piso/edge markers.
   - Motivo: cumplir la presion de endgame documentada sin agregar dano abstracto ni hazards nuevos que ensucien la lectura.

35. **`Main` solo cablea presion entre match y arena**
   - La escena principal pregunta el factor al `MatchController` y se lo aplica al `ArenaBase`; no resuelve timers ni geometria por si misma.
   - Motivo: mantener responsabilidades claras y el proyecto legible para iteraciones futuras.

36. **Timer de ronda base reducido a 60 segundos**
   - La configuracion por defecto deja de usar 180s para que la contraccion aparezca en sesiones reales de laboratorio.
   - Motivo: un sistema de presion que casi nunca se activa no aporta feedback util al prototipo.

37. **Camino Hard por teclado ampliado a tres perfiles locales**
   - `RobotBase` ahora crea acciones `aim_left/right/forward/back` para `WASD_SPACE`, `ARROWS_ENTER` y `NUMPAD`, con `TFGX`, `Ins/Del/PgUp/PgDn` y `KP7/KP9/KP//KP*` respectivamente; `throw_part` sigue dedicado por perfil.
   - Motivo: el laboratorio local ya tenia selector runtime por slot y escenas cortas para comparar control; limitar el aim Hard a un solo teclado dejaba la validacion demasiado sesgada hacia P1.

38. **Leyenda de controles visible desde el arranque**
   - `Main` construye el mensaje inicial del HUD leyendo `robot.get_input_hint()` por slot local.
   - Motivo: que los playtests Easy/Hard no dependan de recordar mappings fuera del juego y dejar explicito cuando un slot Hard sigue necesitando aim por stick derecho.

39. **Politica Hard/local cerrada a favor de claridad**
   - `WASD`, `flechas` y `numpad` ya pueden jugar Hard sin joystick; `IJKL` sigue explicitamente joypad-first y esa advertencia sigue visible al arrancar, ademas de persistir en el roster cuando el HUD esta en modo `explicito`.
   - Motivo: ampliar cobertura de laboratorio sin forzar un cuarto mapping de teclado que probablemente se solape peor o degrade la legibilidad del setup compartido.

40. **Los laboratorios principales se ciclan runtime desde `Main`, no desde menues o el editor**
   - `Main` ahora mantiene `LAB_SCENE_VARIANTS`, expone `cycle_lab_scene_variant()` / `get_lab_scene_variant_summary_line()` y cambia escena con `F6` entre `main`, `main_teams_validation`, `main_ffa` y `main_ffa_validation`.
   - Motivo: el proyecto ya tenia cuatro rutas utiles de playtest pero seguir saltando desde el editor hacia lenta la iteracion; resolverlo dentro del mismo runtime conserva el prototipo beginner-friendly, mejora la comparacion Teams/FFA y reutiliza escenas ya mantenidas sin agregar otra UI o bootstrap paralelo.

41. **Incentivo de borde via pickup de reparacion instantanea**
   - El primer objetivo real de borde se resolvio con `EdgeRepairPickup`: un pickup universal simple, fijo y visible que cura la parte activa mas dañada al tocarlo; en cooldown mantiene el pedestal y apaga solo el nucleo.
   - Motivo: volver los flancos tentadores ya en el laboratorio sin introducir todavía inventario, rareza o una capa de items que opaque el nucleo de patinar/chocar.

42. **La reparacion de borde no revive piezas destruidas**
   - `RobotBase` expone `repair_most_damaged_part(...)` y solo repara partes que sigan activas; los miembros destruidos siguen dependiendo del loop de partes desprendidas.
   - Motivo: sumar sustain tactico y comeback parcial sin invalidar rescate aliado, negacion enemiga ni el peso de perder una pierna o un brazo.

43. **Legibilidad modular reforzada sobre la propia pieza**
   - `RobotBase` crea marcadores runtime `DamageFeedback/Smoke` y `DamageFeedback/Spark` sobre cada extremidad, escalando solo cuando esa parte realmente está dañada o crítica.
   - Motivo: acercar la lectura a “humo/chispas sobre el robot” que piden los docs sin sumar HUD nuevo, assets externos ni un sistema de partículas difícil de mantener en este prototipo.

44. **Cobertura de borde acompasada con la contracción del arena**
   - `arena_blockout.tscn` suma dos bloques estáticos simples bajo `CoverBlocks`, y `ArenaBase` reubica esas coberturas según el tamaño actual del área segura.
   - Motivo: validar duelo/cobertura en bordes sin romper la presión de endgame ni dejar geometría desfasada cuando el mapa se achica.

45. **Pickups de borde acompasados con la contracción del arena**
   - `ArenaBase` ahora cachea la posicion local original de los nodos del grupo `edge_repair_pickups` y los reubica con la misma escala X/Z que el area segura.
   - Motivo: si el pickup quedaba fijo mientras la arena se cerraba, el incentivo de borde se salia del espacio jugable y rompia el duelo riesgo/recompensa del endgame.

46. **Bootstrap FFA con layout radial en `Main`, no con markers duplicados**
   - Cuando `MatchController` arranca en `FFA`, `Main` ya no consume los `SpawnPlayerX` cardinales del arena blockout; genera un set radial/diagonal mirando al centro mediante `ffa_spawn_radius` y `ffa_spawn_angle_offset_degrees`.
   - Motivo: separar la identidad espacial del free-for-all del laboratorio 2v2 sin duplicar la escena de arena ni abrir otra capa de config/map loading prematura.

45. **FFA expuesto como escena heredada del laboratorio principal**
   - `scenes/main/main_ffa.tscn` hereda `main.tscn`, fija `MatchMode.FFA` y reutiliza la misma arena, HUD y bootstrap local.
   - Motivo: volver FFA una opcion testeable ya mismo sin duplicar escenas grandes ni abrir una segunda rama de codigo para el laboratorio.

46. **Neutralizacion de `team_id` cuando el bootstrap corre en FFA**
   - `Main` pone `team_id = 0` en los robots si `MatchController` arranca en `FFA`, antes de registrarlos.
   - Motivo: el layout 2v2 conserva parejas en escena para `main.tscn`; sin neutralizar eso en FFA, `is_ally_of` permitia rescates/devoluciones falsas entre rivales.

47. **El HUD explicito deja visible el modo de match**
   - En `EXPLICIT`, `MatchController.get_round_state_lines()` agrega `Modo | FFA` o `Modo | Equipos` antes del objetivo y el marcador; en `CONTEXTUAL` esas lineas fijas se ocultan para priorizar el estado cambiante.
   - Motivo: mantener la claridad de laboratorio cuando hace falta depurar/configurar el setup, pero permitir una variante mas limpia que no repita informacion estable durante toda la ronda.

48. **FFA reutiliza el mismo contrato de standings tanto vivo como en el cierre**
   - `MatchController.get_round_state_lines()` ahora agrega `Posiciones | ...` y `Desempate | ...` llamando a `_build_ffa_standings_line()` y `_build_ffa_tiebreaker_line()`, los mismos helpers ya usados por recap y resultado final.
   - Motivo: el gap real no era de calculo sino de visibilidad durante la ronda activa. Reutilizar el mismo builder evita dos criterios paralelos entre HUD vivo y cierre, y mantiene explicito el desempate mientras el combate sigue abierto.

48. **La explicación de bajas vive en el HUD compacto existente**
   - `MatchController.get_robot_status_lines()` ahora usa el mismo roster para mostrar `Inutilizado | explota Xs` y `Fuera | vacio/explosion`, mientras `get_round_state_lines()` agrega `Ultima baja | ...`.
   - Motivo: mejora la lectura de derrota y amenaza inminente en pantalla compartida sin introducir una capa nueva de UI ni romper la prioridad por claridad.

49. **La autoria de la baja se deriva de una ventana corta de agresor reciente**
   - `RobotBase` conserva durante unos segundos el ultimo rival que aplico empuje/daño relevante; `Main` reutiliza ese seam al registrar bajas por `void` o `explosion`, y `MatchController` extiende la misma telemetria existente con `por Player X` en `Ultima baja`, `Resumen | ...`, recap y resultado final.
   - Motivo: el prototipo ya explicaba la causa (`vacio`, `explosion`, `inestable`), pero no quien la habia forzado; una ventana corta mantiene la atribucion legible sin inventar un feed de combate persistente ni trackers mas pesados.

49. **Segundo incentivo de borde via pickup universal de movilidad**
   - `EdgeMobilityPickup` activa una ventana breve de traccion/control reforzados sobre `RobotBase` y reaparece tras cooldown, sin tocar el sistema de energia ni abrir una capa nueva de inventario.
   - Motivo: sumar un item universal que refuerce la fantasia principal de patinar/reposicionarse, manteniendo la lectura limpia y el riesgo atado al borde.

50. **Seguimiento generico para pickups de borde**
   - `ArenaBase` ya no recoloca solo `edge_repair_pickups`; ahora sigue cualquier nodo del grupo `edge_pickups`, incluyendo reparacion e impulso.
   - Motivo: permitir variedad minima de incentivos en los bordes sin duplicar logica de contraccion ni dejar nuevos pickups desfasados respecto del borde vivo.

51. **Tercer incentivo de borde via pickup universal de energia**
   - `EdgeEnergyPickup` activa una recarga breve sobre el par energetico seleccionado y reaparece tras cooldown, reutilizando el mismo contrato visible de pedestal + nucleo que reparacion e impulso.
   - Motivo: completar el trio minimo de incentivos prioritarios del documento (`reparacion`, `movilidad`, `energia`) sin abrir todavia inventario, rareza ni items de una sola carga.

52. **La nave post-muerte vive solo mientras exista un aliado vivo real**
   - `Main` poda `PilotSupportShip` durante `_sync_post_death_support_state()` cuando su owner deja de tener un aliado vivo o deja de estar retenido para el reset de ronda.
   - Motivo: el soporte Teams esta pensado como ayuda al equipo superviviente; mantener nave, roster y pickups activos despues de perder el ultimo aliado dejaba un estado stale y confundia la lectura del final de ronda.

52. **Pickups del soporte Teams con respawn corto y cue local**
   - `PilotSupportPickup` ya no desaparece por toda la ronda al primer uso: entra en cooldown corto, deja el pedestal visible, apaga el nucleo y muestra `RespawnVisual` hasta volver.
   - Motivo: el carril post-muerte necesita seguir ofreciendo timing/routing despues de una primera pasada y tambien escalar mejor a futuros equipos mas grandes, sin abrir HUD nuevo ni una economia separada de soporte.

52. **La recarga de energia estabiliza, no reemplaza el overdrive**
   - Al recoger energia, `RobotBase` corta la recuperacion post-overdrive, reaplica el foco actual y suma una ventana corta de rendimiento extra sobre ese mismo par; no reactiva overdrive ni elimina todo el cooldown restante.
   - Motivo: volver valioso el pickup de energia sin volverlo spam ni borrar la identidad de riesgo/recompensa del overdrive.

53. **La validacion rapida vive en una escena heredada, no en flags temporales del laboratorio base**
   - `scenes/main/main_teams_validation.tscn` y `arena_teams_validation.tscn` encapsulan el setup corto (`first-to-1`, 28s, arena mas compacta, reinicios breves) sin tocar `main.tscn` ni el blockout principal.
   - Motivo: acelerar playtests de rescate/negacion/contraccion sin confundir el laboratorio principal con tuning de debug ni abrir condicionales extras en `Main`.

53. **Primer item cargable comparte slot con las partes transportadas**
   - `RobotBase` ahora usa un unico slot/logica de payload visible: puede llevar una `DetachedPart` o una `pulse_charge`, pero no ambos a la vez.
   - Motivo: mantener legible la pantalla compartida, evitar estados superpuestos y volver real la decision entre rescate/negacion y utilidad ofensiva.

54. **El primer skillshot entra como item de borde, no como kit base**
   - `EdgePulsePickup` entrega una sola carga de `pulse_charge`; al usarla, `RobotBase` consume el item y dispara `PulseBolt`, un proyectil corto que empuja y daña al primer objetivo o cobertura física que encuentra.
   - Motivo: validar la tensión “choque vs influencia a distancia” sin abrir todavía un sistema completo de habilidades, munición por personaje ni HUD nuevo.

55. **La ventana de recuperacion de `DetachedPart` ahora vive en script y se pausa al cargarla**
   - `DetachedPart` ya no usa `LifetimeTimer.time_left` como fuente de verdad; `_cleanup_time_left` se reduce solo mientras la pieza sigue en el piso, y `throw_from()` reanuda el tiempo restante en vez de reiniciarlo.
   - Motivo: el timer de pared podia agotarse durante frames de setup/headless y ademas contradecia el contrato esperado de “timer pausado mientras se transporta la pieza”.

55. **Los edge pickups rotan por ronda en un mazo seedado de pares espejados**
   - `ArenaBase` define cuatro cruces base (`repair + mobility`, `repair + pulse`, `energy + mobility`, `energy + pulse`) y `activate_edge_pickup_layout_for_round(round_number)` deja activos solo dos pares espejados por ronda.
   - Motivo: cumplir el criterio de “pocos items, importantes y semialeatorios” sin romper justicia espacial, sin duplicar escenas y sin abrir todavía pesos complejos por mapa o respawns con cambio de tipo.

56. **La rotación de pickups se cuelga del inicio de ronda, no del cooldown individual**
   - `MatchController` emite `round_started`, `Main` aplica el layout al `ArenaBase` activo y cada pickup expone `set_spawn_enabled()` para apagarse completo cuando no forma parte del layout actual.
   - Motivo: mantener responsabilidades claras, evitar un director extra de mapa y conservar el telegraph local de pedestal/cooldown dentro de los pickups ya existentes.

57. **Los layouts de edge pickups cambian segun el modo de match**
   - `ArenaBase` ahora usa un perfil `teams` con dos pares espejados por ronda y un perfil `ffa` con layouts `3-de-4`, ambos seedados y reutilizando el mismo contrato `activate_edge_pickup_layout_for_round(round_number)`.
   - Motivo: Team vs Team necesita preservar claridad para rescate/choque, mientras FFA gana mas oportunismo y presencia de utilidad sin volver a ocho pickups activos ni romper justicia espacial.

58. **El cierre FFA usa una linea compacta de posiciones dentro del HUD existente**
   - `MatchController` ahora agrega `Posiciones | 1. ...` al `RecapPanel` y al `MatchResultPanel` solo cuando el match corre en `FFA`, ordenando por score del match y usando el orden real de eliminacion de la ronda final como desempate.
   - Motivo: FFA necesitaba explicar mejor supervivencia y oportunismo al terminar una ronda/partida, pero abrir otra pantalla de podio o standings hubiera roto la prioridad actual de claridad y simplicidad del laboratorio.

58. **El soporte post-muerte suma stats dentro del recap existente**
   - `PilotSupportShip` emite eventos de pickup/uso y `Main` los delega a `MatchController`, que agrega `support_pickups` y `support_uses` por competidor dentro de la misma linea `Stats | ...`.
   - Motivo: el nuevo soporte Teams ya afectaba la ronda pero quedaba invisible en el cierre; registrar `apoyo N (M usos: estabilizador 1, energia 1, ...)` preserva legibilidad post-match sin abrir otra UI o duplicar ownership de estado.

58. **El HUD compacto resume el layout activo del borde**
   - `Main` agrega `Borde | ...` a las lineas de ronda usando `ArenaBase.get_active_edge_pickup_layout_summary()`.
   - Motivo: hacer medible y legible la rotación semialeatoria durante playtests sin sumar otro panel de UI ni depender de memoria externa.

59. **Overdrive conecta con una explosion diferida inestable**
   - Si `RobotBase` pierde su ultima parte mientras `Overdrive` sigue activo, el cuerpo inutilizado conserva una bandera `inestable`; esa variante escala `radio/empuje/daño`, calienta mas el core del robot y `Main/MatchController` la exponen como `inestable` / `explosion inestable` en HUD y resumenes.
   - Motivo: cerrar la apuesta riesgo/recompensa del overdrive con una consecuencia espacial rara pero legible, reutilizando el loop de cuerpo inutilizado ya existente en vez de abrir otro hazard o una regla aparte.

60. **La contraccion del arena se telegraphia desde el propio piso**
   - `ArenaBase` ahora enciende cuatro bandas sobrias junto al borde vivo solo cuando el area segura baja de escala 1.0, y ajusta posicion/intensidad con la misma geometria runtime que usa para piso, markers y pickups.
   - Motivo: reforzar la presion de endgame en mundo, sin otra capa de HUD, sin dano abstracto y sin ensuciar el centro del mapa.

61. **La nave post-muerte enseña sus controles desde el roster existente**
   - `PilotSupportShip.get_status_summary()` ahora agrega `usa ... | objetivo ...` usando un helper de `RobotBase` derivado del perfil real del jugador eliminado.
   - Motivo: el soporte Teams ya tenia objetivo manual y payloads tacticos, pero esa capa era demasiado facil de perder en laboratorio compartido si dependia solo de memoria externa; reforzarla en el roster compacto conserva claridad sin abrir otra UI.

60. **La explosion diferida se telegraphia en mundo con el mismo radio real**
   - `RobotBase` ahora crea `DisabledWarningIndicator`, un anillo pegado al piso que solo aparece mientras el cuerpo sigue inutilizado; usa `disabled_explosion_radius` como escala base y reaplica el multiplicador `inestable` cuando corresponde.
   - Motivo: el roster ya avisaba que el casco iba a explotar, pero faltaba mostrar sobre la arena la amenaza espacial real para sostener claridad en pantalla compartida sin otra UI.

61. **FFA rapido vive en una escena dedicada, no ajustando el laboratorio libre base**
   - `scenes/main/main_ffa_validation.tscn`, `arena_ffa_validation.tscn` y `ffa_validation_match_config.tres` encapsulan el setup corto (`first-to-1`, 26s, arena compacta, reinicios breves) sin tocar `main_ffa.tscn`.
   - Motivo: FFA necesitaba una ruta rapida de iteracion comparable a Teams, pero sin perder el laboratorio libre mas representativo ni ramificar `Main` con flags de debug.

62. **La compacidad FFA se resuelve desde datos de escena, no con logica condicional nueva**
   - El nuevo laboratorio ajusta `safe_play_area_size`, pickups/coberturas, `round_reset_delay`, `match_restart_delay` y tambien `ffa_spawn_radius`/`ffa_spawn_angle_offset_degrees` directamente en la escena.
   - Motivo: el primer intento mostro que el bootstrap global de `Main` seguia imponiendo el radio FFA por defecto; fijarlo en la propia escena mantiene el contrato claro y evita ensuciar scripts por un laboratorio especifico.

61. **El cierre de ronda se resume en la misma banda textual del HUD**
   - `MatchController` ahora guarda el orden de bajas de la ronda y solo lo expone como `Resumen | ...` cuando la ronda ya termino; al iniciar la siguiente, ese recap se limpia.
   - Motivo: reforzar la explicacion de “como termino esta ronda” sin abrir otra capa de post-ronda, sin esconder el combate activo bajo texto extra y reutilizando el contrato compacto ya establecido en `get_round_state_lines()`.

62. **El detalle del HUD se controla desde `MatchConfig`, no con otra escena**
   - `MatchConfig.hud_detail_mode` alterna entre `EXPLICIT` y `CONTEXTUAL`, `RobotBase` expone `is_energy_balanced()` para que el filtro sepa cuando volver a mostrar energia, y `Main` sigue refrescando el mismo `MatchHud` sin branching adicional de escenas.
   - Motivo: sumar la configuracion pedida por el documento de UI con el menor cambio posible, manteniendo el codigo testeable por headless y sin duplicar layouts.

63. **Primeros arquetipos como recursos de tuning, no como ramas de código separadas**
   - `RobotArchetypeConfig` encapsula multiplicadores simples y `RobotBase` los aplica al arrancar; el laboratorio usa `Ariete`, `Grua`, `Cizalla` y `Patin` sobre la misma escena base.
   - Motivo: cerrar la brecha de identidad del roster con el menor costo técnico posible, manteniendo el proyecto entendible para un principiante y dejando la puerta abierta a skills/pasivas propias solo si el tuning no alcanza.

64. **El toggle runtime del HUD vive como override local, no en el recurso compartido**
   - `MatchController` conserva `MatchConfig.hud_detail_mode` como default de arranque, pero permite ciclar una sobreescritura de sesion; `Main` expone ese cambio con `F1` para playtests locales.
   - Motivo: comparar `explicito/contextual` dentro del mismo laboratorio sin ensuciar escenas nuevas ni mutar el `.tres` compartido entre instancias/tests.

65. **La segunda capa de arquetipos reutiliza hooks ya existentes**
   - `RobotArchetypeConfig` ahora agrega pasivas chicas sin escenas ni botones nuevos: `Ariete` baja el impulso externo recibido, `Grua` estabiliza otra pieza dañada al devolver una parte, `Cizalla` castiga mas una pieza ya tocada y `Patin` estira la duracion de los boosts de movilidad.
   - `RobotBase` las resuelve dentro de `apply_impulse`, `restore_part`, `receive_attack_hit_from_robot` / `receive_collision_hit_from_robot` y `apply_mobility_boost`, mientras `PulseBolt` tambien pasa el atacante para no romper la identidad de `Cizalla` fuera del melee.
   - Motivo: profundizar la identidad del roster con el menor costo tecnico posible; estas pasivas siguen vigentes incluso ahora que `Patin` ya gano `Derrape`, porque siguen diferenciando el valor de los pickups de movilidad respecto de su skill propia.

65. **La identidad de jugador/equipo vive primero en el mundo, no en otro HUD**
   - `RobotBase` ahora expone `get_identity_color()` y reutiliza `FacingMarker` + `Left/RightCoreLight` como acentos ligeros por equipo en `Teams` y por jugador en `FFA`, sin tocar el cuerpo principal ni competir con la lectura de energia/daño.
   - `DetachedPart` suma un `OwnershipIndicator` fino que reutiliza ese mismo color sobre la pieza caída, separado del disco de recuperación temporal.
   - Motivo: el laboratorio ya tenía urgencia de rescate (`RecoveryIndicator`) y labels en roster, pero seguía faltando distinguir rápido “quién es quién” y “de quién es esta pieza” en pantalla compartida; reutilizar acentos existentes + un aro mínimo conserva claridad y evita abrir otra capa de UI.

66. **El objetivo de retorno tambien se marca en mundo**
   - `DetachedPart` ahora registra/desregistra su disponibilidad contra `RobotBase`, y el robot dueño crea un `RecoveryTargetIndicator` runtime sobre el chasis mientras exista al menos una pieza propia recuperable.
   - Motivo: el disco de urgencia y el aro de pertenencia ya explicaban “esta pieza importa” y “de quién es”, pero seguía faltando leer rápido adónde devolverla en cámara compartida; un marcador chico sobre el robot dueño completa el triángulo pieza-dueno-portador sin abrir otra UI.

67. **La primera skill propia reutiliza `PulseBolt` y la accion de utilidad ya existente**
   - `RobotArchetypeConfig` ahora puede declarar `core_skill_type/label/cargas/recarga`, y `RobotBase` consume esa info para disparar una skill desde `throw_part` cuando no lleva una pieza.
   - Motivo: abrir un primer arquetipo Poke/Skillshot sin sumar botones nuevos, manteniendo la regla importante de que cargar una parte bloquea otras habilidades activas.

68. **`Aguja` se expone primero en FFA, no en el laboratorio 2v2**
   - `main_ffa.tscn` reemplaza el slot de `Grua` por `Aguja`, mientras `main.tscn` conserva `Ariete/Grua/Cizalla/Patin` para seguir priorizando rescate aliado en equipos.
   - Motivo: FFA gana oportunismo y poke legible sin debilitar el laboratorio 2v2 que hoy valida mejor asistencia/recuperacion.

69. **La skill propia lista se lee en el cuerpo; el item cargado sigue arriba del robot**
   - `RobotBase` ahora usa un pulso cian sobrio sobre `LeftCoreLight/RightCoreLight` cuando quedan cargas de skill propia, y apaga ese extra al vaciarse; el `CarryIndicator` dorado sigue reservado para `pulse_charge` o partes cargadas.
   - Motivo: `Aguja` ya tenía roster `skill Pulso x/y`, pero en cámara compartida seguía faltando distinguir rápido “tiene su skill lista” de “levantó un item universal de pulso”; reutilizar las luces del core preserva legibilidad sin abrir otro marcador flotante.

70. **El acento de arquetipo tambien acompaña readiness/actividad de skill propia**
   - `RobotBase._refresh_archetype_accent_visuals()` ahora mezcla un color de skill propia sobre `ArchetypeAccent` cuando quedan cargas y agrega un boost extra durante estados activos persistentes como `Embestida` (o una `Baliza` viva), sin crear nodos nuevos ni otra capa de HUD.
   - `robot_archetype_readability_test.gd` valida en rojo-verde que `Aguja` baje la emision del acento al quedarse sin cargas y que `Ariete` la intensifique mientras dura `Embestida`.
   - Motivo: `CoreLight` solo ya resolvía “hay skill”, pero seguía siendo una pista chica para cámara compartida; hacer que el propio `ArchetypeAccent` respire con esa disponibilidad reutiliza una silueta ya establecida y mejora lectura sin sumar ruido.

70. **`Ancla` completa Control/Zona con una baliza persistente corta**
   - `RobotArchetypeConfig.CoreSkillType` ahora tambien puede ser `CONTROL_BEACON`, y `RobotBase` lo resuelve desplegando `ControlBeacon`, una zona breve que ralentiza drive/control de rivales dentro del area.
   - Motivo: cerrar el sexto arquetipo documentado con el cambio mas chico posible, reutilizando la misma accion de utilidad y manteniendo el efecto claramente subordinado al combate de choque.

71. **Solo una baliza activa por robot para proteger la claridad**
   - Al redeplegar `Baliza`, `RobotBase` libera la anterior antes de crear la nueva; `main_ffa.tscn` expone `Ancla` en lugar de `Cizalla`, manteniendo el 2v2 base intacto.
   - Motivo: evitar stack de hazards, mantener la lectura limpia en pantalla compartida y abrir el sexto rol principalmente donde FFA gana mas con control y oportunismo.

69. **La lectura de zona vive en el roster existente**
   - `MatchController.get_robot_status_lines()` agrega `zona` cuando `RobotBase` esta bajo supresion de `Baliza`, y `robot_control_skill_test.gd` valida recurso, despliegue, reemplazo y presencia en roster FFA.
   - Motivo: hacer visible el nuevo estado tactico sin abrir otra capa de HUD ni obligar al jugador a interpretar solo el mesh de la baliza.

70. **El selector runtime vive en `Main`, no en otra escena de menu**
   - `Main` ahora mantiene un slot de laboratorio seleccionado, cicla arquetipos con `F3`, alterna `Easy/Hard` con `F4` y deja la referencia persistente en `Lab | ...` dentro del mismo HUD compacto.
   - Motivo: volver realmente testeables los seis arquetipos y el soporte Hard sin abrir otro flujo de UI, sin duplicar escenas y sin bloquear la iteracion con un pre-match menu prematuro.

71. **Reaplicar arquetipos en runtime restaura primero la base del robot**
   - `RobotBase` cachea sus valores base, restaura esos campos antes de volver a aplicar `RobotArchetypeConfig` y luego `Main` reinicia todo el match con `start_match()`.
   - Motivo: evitar stacking accidental de multiplicadores, mantener sincronizados roster/marcador FFA y permitir que el selector runtime cambie loadouts varias veces en la misma sesion sin drift de stats ni timers stale.

73. **El selector runtime se apoya en una pista diegética, no en más HUD**
   - `RobotBase` ahora crea `LabSelectionIndicator`, un anillo sobrio a nivel piso; `Main._sync_lab_selector_visuals()` lo mueve al slot elegido por `F2/F3/F4`.
   - Motivo: el laboratorio ya tenia la informacion en `Lab | ...`, pero faltaba descubrir rapido sobre que robot actuan esos atajos en pantalla compartida; un cue en mundo resuelve eso sin abrir otro panel.

72. **La lectura de arquetipo vive en el cuerpo, no solo en el roster**
   - `RobotArchetypeConfig` ahora tambien define `accent_style/accent_color`, y `RobotBase` construye un `ArchetypeAccent` runtime sobre `UpperBodyPivot` con siluetas chicas por rol (`Ariete` bumper, `Grua` mastil, `Cizalla` cuchillas, `Patin` aleta, `Aguja` pua, `Ancla` halo).
   - `apply_runtime_loadout()` reconstruye ese acento cuando cambia el loadout, y `robot_archetype_readability_test.gd` cubre que exista, cambie por arquetipo y no quede stale tras usar `F3`.
   - Motivo: los seis arquetipos ya tenian texto en roster y algunas luces/skills propias, pero en pantalla compartida seguia faltando una pista corporal minima para leer roles sin abrir otro HUD ni depender de memoria externa.

73. **La pasiva de `Cizalla` se telegraphia solo cuando realmente cobra valor**
   - Cuando `RobotBase.apply_damage_to_part()` aplica el multiplicador extra sobre una pieza ya dañada, el atacante con `damaged_part_bonus_damage_multiplier > 1.0` abre una ventana corta `_damaged_part_bonus_remaining`; `get_passive_status_summary()` la expone como `corte` y `MatchController` la reusa en el roster compacto igual que `derrape` o `embestida`.
   - Ese mismo estado tambien sube por un instante la emision del `ArchetypeAccent`, sin crear otro mesh/HUD nuevo ni depender de mirar números de daño.
   - Motivo: `Cizalla` ya hacia más daño modular, pero era una identidad invisible frente al resto del roster; ligar el cue al momento exacto en que castiga una parte tocada lo vuelve legible sin convertir la pasiva en otro modo permanente.

72. **El recap de cierre vive en el mismo HUD, pero solo entre rondas**
   - `MatchController` ahora deriva un recap estructurado (`Decision`, `Marcador` y un estado final por robot con `sigue en pie` o `baja N | causa`) a partir de la misma telemetria de eliminacion ya existente, y `MatchHud` lo muestra en un `RecapPanel` lateral oculto durante la ronda activa.
   - Motivo: reforzar el “como perdi” y el cierre de match sin abrir otra escena/post-partida prematura ni sumar texto que tape el combate mientras la ronda sigue viva.

73. **El cierre final de match usa una capa dedicada, pero sigue dentro del HUD actual**
   - Cuando `_match_over` es verdadero, `MatchController` expone `Partida cerrada`, marcador final y `Reinicio | F5 ahora o Xs`; `MatchHud` lo renderiza en un `MatchResultPanel` centrado mientras el `RecapPanel` lateral conserva el detalle por robot.
   - Motivo: dar peso a la victoria/derrota y volver legible el reinicio del laboratorio sin abrir una escena post-partida separada ni perder la trazabilidad de “quien cayo y por que”.

74. **Los resets diferidos ya no dependen de `SceneTreeTimer` sueltos**
   - `MatchController` ahora usa un `TransitionTimer` propio y `RobotBase` un `RespawnTimer` propio; ambos se pueden detener cuando `start_match()`, `reset_to_spawn()` o el reinicio manual invalidan la espera anterior.
   - Motivo: evitar callbacks stale, fugas en tests y reinicios dobles cuando el laboratorio cambia loadout o reinicia la partida antes de que venza una espera anterior.

75. **Las stats de post-partida se agregan desde hooks ya existentes**
   - `Main` reenvia a `MatchController` los eventos ya cableados de rescate (`part_restored`), destruccion de partes (`part_destroyed`) y pickups de borde (`edge_*_pickup_collected`); `record_robot_elimination()` completa la telemetria con causas finales de baja.
   - `MatchController` agrega solo durante ronda activa y expone lineas compactas `Stats | Competidor | rescates N | borde N | partes perdidas N (brazos/piernas) | bajas sufridas N (...)` tanto en `RecapPanel` como en `MatchResultPanel`.
   - Motivo: cumplir el pedido de “stats simples de fin de partida” y reforzar el “como perdi” con desgaste modular real, sin abrir otra escena, sin duplicar estado en `Main` y sin permitir padding accidental durante el tiempo muerto posterior al cierre.

76. **La ventana de recuperacion vive sobre la pieza, no en otra banda del HUD**
   - `DetachedPart` ahora crea un `RecoveryIndicator` runtime `top_level`, expone `get_cleanup_time_left()/get_cleanup_progress_ratio()` y emite `recovery_lost` con `timeout` o `void` cuando la recuperacion ya no es posible.
   - Motivo: Team vs Team necesitaba volver mas legible la urgencia del rescate sin cargar el roster/HUD con otra linea persistente; un telegraph diegetico sobre la propia pieza conserva claridad, funciona tambien en FFA y deja un hook chico para futuras lecturas compactas si hicieran falta.

77. **La lectura de “pieza floja” vive en la pose modular existente**
   - `RobotBase` ahora cachea la transform base de cada mesh modular y, cuando la vida baja del umbral de lectura, aplica offsets/rotaciones pequeñas a brazos y piernas (`caido` para brazos, `arrastrando` para piernas) antes de volver a la pose original al reparar o desprender.
   - Motivo: los docs piden desgaste y piezas flojas visibles sobre el propio robot; resolverlo en la pose de las mallas ya existentes refuerza claridad sin otro HUD, sin partículas nuevas y sin volver la escena difícil de mantener.

78. **`Grua` refuerza rescate/negacion con un agarre magnetico, no con otro sistema**
   - `RobotArchetypeConfig` ahora soporta `RECOVERY_GRAB`; `grua_archetype.tres` lo expone como `Iman`, `DetachedPart` publica `is_pickup_ready()` y `RobotBase` usa `recovery_skill_pickup_range` para buscar la pieza lista mas conveniente, priorizando propias/aliadas sobre enemigas antes de reaprovechar `try_pick_up(self)`.
   - Motivo: Team vs Team necesitaba una herramienta activa de asistencia/recuperacion, pero el prototipo ya tenia un loop claro de carga/retorno/negacion. Capturar una pieza lista a media distancia fortalece el rol de `Grua`, respeta `pickup_delay/throw_pickup_delay`, sigue bloqueada por el mismo slot de carga y tambien deja una utilidad viable en FFA para negar piezas enemigas.

79. **La municion/carga de skill se resuelve como pickup de borde inmediato**
   - `EdgeChargePickup` llama a `RobotBase.restore_core_skill_charges()` y restaura una carga faltante sin abrir otro inventario ni otro boton; si el robot no tiene skill propia o ya esta al maximo, el pickup no se consume.
   - Motivo: el documento pide una capa de `municion/carga`, pero el prototipo ya tenia charges en `Grua/Aguja/Ancla`. Reusar ese contrato vuelve el pickup legible, chico y valioso sin inventar una economia paralela.

80. **La municion solo entra al mazo cuando el roster actual puede disputarla**
   - `Main` calcula los tipos de pickup permitidos por ronda: en `FFA` exige al menos dos robots con skill propia; en `Equipos` exige que cada competidor tenga al menos una skill propia antes de habilitar layouts con `charge`.
   - Motivo: evitar que el laboratorio 2v2 base regale valor gratis a un solo bando y mantener el borde tactico sin crear pickups muertos para la configuracion principal.

81. **La primera utility universal de borde es `estabilidad`, no otro daño**
   - `EdgeUtilityPickup` llama a `RobotBase.apply_stability_boost()`: limpia `zona/interferencia`, bloquea nuevas supresiones por una ventana corta y baja un poco el impulso externo recibido; `MatchController` la resume como `estabilidad` en el roster.
   - Motivo: el documento seguia pidiendo un tipo `utility`, pero abrir otro proyectil/hazard habria competido con el choque principal. Una respuesta anti-control reutiliza seams existentes, agrega contrajuego a `Baliza`/`interferencia` y sigue siendo legible en pantalla compartida.

88. **`estabilidad` y `zona` comparten un solo cue diegético sobre el torso**
   - `RobotBase` ahora crea `StatusEffectIndicator` bajo `UpperBodyPivot`: se enciende en verde agua mientras `apply_stability_boost()` siga activo y en naranja cuando `apply_control_zone_suppression()` logra entrar; el mismo indicador se refresca al aplicar, expirar o limpiar cada estado.
   - Motivo: el contrajuego entre `utility` y control ya existia en gameplay y roster, pero no en mundo. Reusar un solo anillo corporal mantiene la lectura clara para pantalla compartida y evita abrir otra capa de HUD o sumar efectos distintos para cada estado.

81. **El primer post-muerte real vive solo en `Teams` y reutiliza el input del eliminado**
   - `Main` ahora reserva `SupportRoot`, crea una `PilotSupportShip` cuando `record_robot_elimination()` deja a un aliado vivo en `Teams` y la limpia en cada `round_started`; `FFA` comparte la estructura base de escena pero no activa ese flujo.
   - Motivo: empezar a diferenciar Team vs Team sin romper la claridad del laboratorio libre ni abrir una segunda capa de reglas en el modo que todavia depende mas de supervivencia/oportunismo que de rescate coordinado.

81b. **El contrato FFA en `Main` queda explícito: sin soporte post-muerte por diseño de esta fase**
   - El ciclo de partida en FFA ahora queda fijado en `sin soporte`:
     - `Main._spawn_post_death_support_if_needed()` sale temprano si `match_mode != MatchMode.TEAMS`.
     - `_sync_post_death_support_state()` sólo activa carril/pickups cuando `match_mode == TEAMS`.
     - `main_ffa.tscn` hereda el laboratorio base y fuerza `match_mode = 0` (`FFA`) con equipos neutrales para evitar rescates/alianzas accidentales.
   - Escenario de rescate/negación: como no hay naves post-muerte en FFA, la ventaja post-baja queda exclusivamente en la mecánica base (choque, recuperación de piezas, negación manual y presión de borde), manteniendo el modo fiel a supervivencia/oportunismo.
   - Escenario de estabilidad de score: el cierre de partida y el scoreboard de FFA no incorporan puntos extras por utilidad post-muerte; la lectura de ranking queda más estable para comparar rutas de victoria básicas (ring-out, destrucción total, explosión inestable) sin una capa de comeback no comprobada.
   - Motivo: en la fase de prototipo, esto preserva la diferencia entre modos y evita introducir una economía de apoyo en FFA antes de validar su identidad en sesiones reales.

82. **La capa post-muerte arranca desde apoyo aliado y suma una interferencia de corto alcance**
   - `PilotSupportShip` se mantiene en un carril externo derivado de `ArenaBase.get_support_lane_spawn_position_near()`, recoge `PilotSupportPickup` ocultos hasta que exista soporte activo y, al gastar `throw_part`, puede entregar `estabilizador`, `energia`, `movilidad` o `interferencia`; el roster agrega `apoyo ...` segun la carga.
   - Motivo: Team vs Team ya tenia comeback/rescate resuelto con hooks aliados; la siguiente mejora util era una presion tactica acotada, pero sin abrir otra capa de proyectiles ni sacar a la nave de su rol discreto.

83. **La segunda ayuda post-muerte reutiliza `energy surge`, no un boost nuevo**
   - Los pickups laterales del carril externo ahora pueden cargar `energia`; al gastarla, `PilotSupportShip` llama a `RobotBase.apply_energy_surge()` sobre el aliado vivo y hereda la misma lectura compacta (`energia`) que ya existe para el pickup de borde.
   - Motivo: sumar una segunda decision real al soporte de `Teams` sin abrir otra regla de buffs, otro VFX o una logica nueva de targeting; `energy surge` ya existe, es tactica, y deja claro que la nave sigue reforzando al aliado en vez de disputar el choque ella misma.

84. **La tercera ayuda post-muerte reutiliza el boost de movilidad ya existente**
   - `PilotSupportPickup` ahora tambien soporta `movilidad`; `PilotSupportShip` la consume llamando a `RobotBase.apply_mobility_boost()`, mientras el carril externo suma pickups extra sobre norte/sur y el roster reutiliza la misma lectura compacta `movilidad`/`impulso` que ya existia para los boosts de desplazamiento.
   - Motivo: la capa post-muerte necesitaba una tercera decision pro-aliado antes de abrir presion rival. Reusar el estado de movilidad del robot mantiene el sistema chico, legible y alineado con la fantasia principal de reposicionarse para el siguiente choque.

85. **La interferencia de la nave reutiliza la supresion de `Baliza` y exige proximidad espacial**
   - `PilotSupportPickup` ahora tambien soporta `interference`; `PilotSupportShip` solo puede gastarla si encuentra al rival vivo mas cercano dentro de `support_interference_range`, aplicandole `RobotBase.apply_control_zone_suppression(...)` con multiplicadores/duracion propios en vez de crear otro estado.
   - Motivo: la tension correcta era obligar a la nave a asomarse al borde peligroso para molestar una jugada rival, no regalar un hechizo global ni sumar otra telemetria. Reusar `zona` mantiene el HUD compacto y el contrato legible.

86. **El carril post-muerte paso a ser un loop continuo, no “lado mas cercano”**
   - `ArenaBase` ahora expone progreso/tangente/avance del support lane (`get_support_lane_progress_near()`, `get_support_lane_position_from_progress()`, `get_support_lane_tangent_from_progress()`, `advance_support_lane_progress()`), y `PilotSupportShip` guarda `_lane_progress` para moverse sobre ese recorrido continuo en vez de reproyectarse cada frame al borde mas cercano.
   - Motivo: el snap por lado mas cercano dejaba una nave funcional pero con poca sensacion de ruta externa; el loop perimetral mantiene la capa chica, acompaña la contraccion del arena y vuelve legible la decision de rodear esquinas sin meter todavia colisiones ni obstaculos propios.

87. **La primera profundidad extra del carril externo entra como `gates` temporales**
   - `arena_blockout.tscn` ahora suma tres `SupportLaneGate` discretos sobre el loop perimetral; `Main` los activa solo cuando existe soporte post-muerte y `ArenaBase.get_support_lane_blocking_gate_progress()` deja que `PilotSupportShip` detecte si el tramo que intenta recorrer cruza un gate cerrado.
   - Motivo: Team vs Team necesitaba una primera decision de timing/ruta en la capa externa, pero meter colisiones fisicas, hazards ofensivos o pathfinding habria sobrecomplicado demasiado pronto el slice. Un gate binario, pequeño y legible agrega friccion real sin sacar a la nave del rol de apoyo.

88. **La interferencia del carril se comunica en el mismo roster de apoyo**
   - Si `PilotSupportShip` intenta cruzar un gate cerrado, entra en una ventana corta `interferido`; el glow vira a naranja y `get_status_summary()` agrega esa palabra al mismo estado compacto `apoyo ...`.

89. **El timing de cada gate se comunica sobre la propia compuerta**
   - `SupportLaneGate` ahora expone `get_time_until_state_change()` y `get_transition_progress_ratio()`, y crea un `TimingVisual` runtime cuyo fill se vacia segun la ventana abierta/cerrada real.
   - Motivo: los `gates` ya explicaban “bloqueado ahora”, pero no “cuanto falta”. Pegar esa lectura al obstaculo evita prueba/error, no suma HUD y reutiliza el mismo ciclo real del gameplay.

90. **La nave post-muerte suma un beacon diegético en vez de otra capa de HUD**
   - `PilotSupportShip` ahora expone `StatusBeacon/RingVisual/PulseVisual` por encima del casco; el aro queda siempre visible con color de identidad y el pulso solo se enciende cuando la nave carga un `payload` o queda `interferida`.
   - Motivo: el slice Teams ya tenia profundidad mecanica, pero dependia demasiado del roster para entenderse en partida. Un beacon chico, ligado al propio actor y reutilizando el mismo acento cromatico refuerza lectura para jugador/espectador sin abrir UI nueva ni volver ruidosa la capa externa.
   - Motivo: preservar la legibilidad de pantalla compartida sin abrir otra UI. El propio carril telegraphia el bloqueo y el roster confirma por que la ayuda se demoro.

91. **La lectura de rescate se mantiene tambien sobre el portador**
   - `RobotBase` conserva `CarryIndicator` para mostrar que tipo de payload lleva, pero cuando la carga es una `DetachedPart` tambien crea/mantiene `CarryOwnerIndicator`, un aro fino con el color de identidad del dueño original.
   - Motivo: la pieza tirada y el robot dueño ya explicaban urgencia/pertenencia/objetivo, pero al levantar la pieza se perdia la pista de “de quien es”. Duplicar esa pista sobre el portador mantiene claridad en 2v2 y FFA sin sumar otra linea persistente al HUD.

92. **El portador tambien debe insinuar hacia donde devolver la pieza**
   - `RobotBase` ahora suma `CarryReturnIndicator`, una aguja corta junto al marker de carga que se tiñe con el color del dueño original y rota hacia ese robot mientras la `DetachedPart` sigue en mano.
   - Motivo: aun con `CarryOwnerIndicator`, en movimiento rapido seguia faltando una lectura inmediata de “adonde va esto”. Resolverlo dentro del mismo paquete visual del portador mantiene el rescate legible sin abrir HUD ni lineas tether ruidosas entre robots.

93. **El soporte post-muerte selecciona objetivo sobre el mismo input secundario, no por auto-pick opaco**
   - `PilotSupportShip` ahora usa `RobotBase.is_player_support_prev_just_pressed()/next_just_pressed()` para ciclar aliados o rivales validos segun el payload cargado, resume `apoyo <payload> > <objetivo>` en el roster y crea un `SupportTargetIndicator` diegetico sobre el robot apuntado; `interferencia` solo se consume si ese objetivo seleccionado entra en rango.
   - Motivo: la capa externa ya tenia cargas y rutas, pero seguia faltando una decision tactica explicita y legible. Reusar `energy_prev/next` evita abrir otra UI o mas botones, mientras el indicador en mundo aclara adonde va a caer el apoyo sin volver ruidosa la pantalla compartida.

94. **`Interferencia` telegraphia su radio real desde la propia nave**
   - `PilotSupportShip` ahora crea `InterferenceRangeIndicator` runtime: un cilindro fino orientado sobre el piso, visible solo cuando el payload cargado es `interference`, escalado con `support_interference_range * 2` y atenuado cuando el objetivo seleccionado aun queda fuera del radio real.
   - Motivo: con solo el `SupportTargetIndicator` atenuado, el gating espacial de `interferencia` seguia siendo facil de perder en pantalla compartida. Un anillo sobrio pegado a la nave explica el alcance real sin agregar otro panel ni ruido persistente cuando la carga no aplica.

95. **El objetivo del soporte queda marcado tambien a nivel piso**
   - `PilotSupportShip` ahora crea `SupportTargetFloorIndicator` runtime: un anillo fino y top-level que sigue al robot seleccionado, reaprovecha el color del payload y tambien se atenúa cuando `interferencia` sigue fuera de rango.
   - Motivo: el marcador flotante resolvia “quien” pero no siempre “donde” en caos de pantalla compartida. Una marca sobria pegada al piso mantiene el target legible sin HUD extra ni tether entre nave y robot.

96. **Los cues de soporte se refrescan al cambiar estado, no solo por tick fisico**
   - `PilotSupportShip` ahora centraliza `_refresh_support_target_visuals()` y lo invoca al configurar la nave, guardar/gastar payload y cambiar target seleccionado.
   - Motivo: el estado logico del soporte podia quedar un frame por delante de `SupportTargetIndicator`, `SupportTargetFloorIndicator` e `InterferenceRangeIndicator`, dejando telegraphs stale en tests headless y reinicios cortos. Sincronizarlos en el mismo punto donde cambia el estado corrige la causa real sin sumar timers ni waits artificiales.

97. **Los pickups del soporte distinguen payload por silueta, no solo por color**
   - `PilotSupportPickup` ahora crea `PayloadAccentVisual` runtime con material propio y una firma sobria por carga: cilindro vertical para `estabilizador`, barra horizontal para `energia`, barra inclinada para `movilidad` y esfera compacta para `interferencia`.
   - Motivo: en pantalla compartida el respawn/pedestal ya explicaban “aca hay pickup”, pero el tipo seguia dependiendo demasiado del color. Separar la silueta mantiene la lectura diegetica del carril para jugador eliminado y espectador sin abrir otro HUD ni texto flotante.

98. **La redistribución de energía se comunica sobre las extremidades activas**
   - `RobotBase` ahora crea `EnergyReadability` runtime y monta `EnergyFocusIndicator` sobre brazos y piernas; solo la pareja activa se muestra, la parte exacta del foco destaca más y `Overdrive` empuja esa lectura hacia un color más caliente.
   - Motivo: la energía ya alteraba movilidad/empuje y se resumía en el roster, pero faltaba ownership espacial para leer rápido “qué parte está potenciada” en pantalla compartida. Resolverlo sobre el propio cuerpo conserva claridad y evita otra capa fija de HUD.

99. **El cierre FFA explicita el desempate solo cuando hace falta**
   - `MatchController` agrega `Desempate | score igual -> mejor cierre de la ronda final` junto a `Posiciones | ...` en recap/resultado final, pero solo si detecta al menos dos competidores con el mismo score acumulado.
   - Motivo: el ranking FFA ya usaba supervivencia de la ronda final como criterio secundario, pero el HUD no lo decía y los empates parecían arbitrarios. Explicitarlo solo en ese caso aclara el cierre sin meter otra pantalla ni ruido permanente.

100. **El marcador vivo FFA reutiliza el orden de standings, no el orden fijo de la escena**
   - `_build_score_summary_line()` ahora duplica `_competitor_order` y, solo en `MatchMode.FFA`, lo ordena con `_compare_ffa_competitors_for_standings()` antes de armar `Marcador | ...`.
   - Motivo: en shared-screen el cierre ya explicaba primero/segundo/tercero, pero durante la ronda el lider podia quedar escondido en medio de la linea por respetar el orden original de slots. Reusar el mismo comparator del recap refuerza supervivencia/oportunismo sin sumar otra UI ni otro criterio paralelo.

101. **Las `DetachedPart` deben configurarse antes de entrar al tree**
   - `RobotBase._spawn_detached_part()` ahora llama `configure_from_visuals(...)` antes de `add_child(...)`, y el dueño refuerza el retorno con `RecoveryTargetFloorIndicator` ademas del marker alto ya existente.
   - Motivo: en el flujo real de `main.tscn`, `_ready()` de `DetachedPart` podia correr con `original_robot == null`, perdiendo el registro como pieza recuperable y apagando la lectura del objetivo de retorno justo cuando un aliado la cargaba o relanzaba. Corregir el orden arregla el hook real y permite sostener la nueva marca de piso sin trackers paralelos.

102. **Los edge pickups diferencian tipo por silueta persistente, no solo por color**
   - `edge_repair_pickup.tscn`, `edge_mobility_pickup.tscn`, `edge_energy_pickup.tscn`, `edge_pulse_pickup.tscn`, `edge_charge_pickup.tscn` y `edge_utility_pickup.tscn` ahora suman `Visuals/Accent`, un mesh liviano con material propio/emisivo y firma sobria por pickup que sigue visible sobre el mismo pedestal incluso cuando el núcleo entra en cooldown.
   - Motivo: el resumen `Borde | ...` ya aclaraba el layout activo y el pedestal persistente marcaba el punto de interés, pero en pantalla compartida todavía faltaba distinguir rápido “qué pickup es éste” sin depender del color del núcleo ni del HUD. Colgar esa lectura del propio pickup mantiene la claridad del borde y preserva el centro limpio.

103. **El roster vivo reutiliza el mismo orden competitivo del resto del match**
   - `MatchController.get_robot_status_lines()` ya no itera `registered_robots` en scene-order; ahora delega en un helper compartido que aplica los comparators ya usados por recap/resultado final.
   - Motivo: despues de corregir `Marcador`, `Posiciones`, detalle de cierre y `Stats | ...`, quedaba una fuga lateral donde el roster activo seguia mostrando primero al slot original en vez del lider FFA o del aliado que todavia seguia en pie en Teams. Reusar la misma ruta de orden mantiene una sola lectura competitiva sin agregar reglas nuevas.

104. **El rescate ahora dice tambien cuando el handoff ya esta listo**
   - `RobotBase` expone `is_carried_part_return_ready()` y reutiliza ese estado para intensificar `CarryReturnIndicator` cuando el portador entra en el radio real de retorno; `RecoveryTargetFloorIndicator` del dueño tambien refuerza brillo/pulso si un aliado ya puede completar la devolucion.
   - Motivo: pieza en suelo, dueño y portador ya explicaban urgencia/pertenencia/destino, pero seguia faltando el “ya” tactico. Reusar los mismos cues del rescate evita otro HUD y vuelve mas legible el momento exacto de devolver la parte en pantalla compartida.

105. **Configurar HUD por modo desde MatchConfig para el arranque del modo de detalle**
  - `MatchConfig` ahora separa defaults de HUD en `hud_detail_mode_ffa` y `hud_detail_mode_teams`; `MatchController.get_hud_detail_mode()` usa el modo activo del match para resolver el estado inicial por partida.
  - Motivo: algunos modos se benefician de defaults distintos sin cambiar la acción manual de `F1`; mantener esta separación en recursos facilita playtest y presets por laboratorio sin inflar la capa UI.

106. **La limpieza de partes desprendidas ahora tiene validación automática del ciclo entre rondas**
  - `scripts/tests/main_detached_part_cleanup_test.gd` valida que `Main` respete `detached_part_cleanup_limit` en `main.tscn`, incluyendo `round_started` y el ciclo completo de limpieza entre rondas.
  - También valida que una parte en mano no se destruya por limpieza de piso, conservando la garantía de rescate/negación cuando existe portador.
  - Motivo: la presión de arena y limpieza automática no debe introducir pérdida oculta de partida en un sistema de rescate que depende de lectura de ventana espacial; el test evita regresiones de mantenibilidad sin añadir controles nuevos.

## Criterios mantenidos

- Priorizar sensacion de movimiento y choque antes que sistemas avanzados.
- Mantener escenas y scripts chicos, faciles de leer para una persona con poca experiencia en Godot.
- Evitar UI pesada: el robot comunica estado primero por el propio cuerpo.
