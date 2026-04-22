# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

0. **Sincronizacion documental aplicada (2026-04-22)**
 - Decisión operativa: mantener el estado alineado y pasar directamente a validar sensibilidad de núcleo de combate en `main.tscn` y `main_teams_validation.tscn` antes de cambios de balance.
 - Criterio de continuidad: el falso rojo de cierre ya quedó resuelto a nivel headless; ahora sí priorizar 3 partidas 2v2 y 3 partidas FFA cortas, buscando choques claros, sin spam de contacto y sin que skills dominen el primer impacto.

1. **Afinar el perfil de cierre por causa con playtest corto**
  - Definir el ajuste final del peso de cierre por causa con base en sesiones reales:
    - `ring_out`, `destruccion total`, `explosion inestable`.
    - objetivo: mantener riesgo/recompensa sin hacer dominante ninguna ruta de victoria.
  - Mantener la validación técnica en `match_elimination_victory_weights_test.gd` y reforzar cobertura por modo (Teams/FFA) tras cualquier cambio.
  - Archivos objetivo: `data/config/default_match_config.tres`, `data/config/ffa_validation_match_config.tres`, `data/config/teams_validation_match_config.tres`, `scripts/tests/match_elimination_victory_weights_test.gd`.

2. **Cerrar soporte post-muerte con datos reales**
  - Partir de `support_use_total`, `support_payload_use_*` y `support_rounds_decided` ya registrados en `MatchStats` para guiar ajustes.
  - Ajustar `PilotSupportShip` y gates de carril solo con evidencia de sesiones cortas de Teams; evitar cambios sin efecto en rondas decisivas.
  - Mantener la telemetría compacta si comunica valor; si no mejora `support_rounds_decided`, priorizar estabilidad de loops antes que tuning.
  - Archivos objetivo: `scripts/systems/match_controller.gd`, `scenes/main/main.tscn`, `scenes/main/main_teams_validation.tscn`, `data/config/teams_validation_match_config.tres`.

3. **Cerrar el ciclo documental de causa y ranking**
  - Consolidar wording idéntico en `PLAN_DESARROLLO.md`, `ESTADO_ACTUAL.md`, `PROXIMOS_PASOS.md` y `DECISIONES_TECNICAS.md` para `cierre por causa`, `desempate`, `1-8 modo` y `Stats | ...`.
  - Mantener el ajuste de `support_rounds_decided` y el bloque de apoyo dentro de `Stats` como único resumen de soporte hasta necesitar más capa de post-mortem.
  - Archivos objetivo: `PLAN_DESARROLLO.md`, `ESTADO_ACTUAL.md`, `DECISIONES_TECNICAS.md`, `PROXIMOS_PASOS.md`.

4. **Validar el nuevo roster de arquetipos**
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
   - decidir si el selector runtime actual ya alcanza como flujo de laboratorio o si el siguiente paso debe ser persistencia/presets por escena, mas claridad visual o reforzar con otra skill/regla al arquetipo que siga borroso.

5. **Validar el nuevo HUD dual y la nueva lectura de daño modular**
   - correr sesiones con `hud_detail_mode=EXPLICIT` y `hud_detail_mode=CONTEXTUAL` usando tambien el toggle `F1` para decidir que variante debe quedar por defecto en `Equipos` y en `FFA`.
   - revisar si el modo contextual realmente limpia sin esconder decisiones tacticas como `Foco`, `item`, `carga`, `impulso`, `energia` o `3/4 partes`.
   - confirmar por playtest que el roster vivo ahora acompana bien al resto de la lectura competitiva: lider primero en FFA y aliados supervivientes antes que caidos en Teams, sin perder claridad de ownership en pantalla compartida.
   - decidir si el toggle runtime actual alcanza para laboratorio o si la siguiente capa necesita persistencia/preset mas visible por modo, ademas del `MatchConfig`.
   - medir si `RecapPanel` lateral + `MatchResultPanel` centrado + `Stats | ...` (incluyendo `partes perdidas`) + los nuevos `Momento inicial/final` + el detalle repetido `Player X / <Arquetipo> | baja N | causa | N/4 partes | sin ...` explican suficientemente bien `Decision + Marcador + como perdi` sin necesitar otra escena/post-ronda.
   - playtestear si `damage_feedback_threshold`, `critical_damage_feedback_threshold` y la nueva pose floja de brazos/piernas se leen bien con cuatro robots y arena en contracción.
   - decidir si el feedback geométrico actual ya alcanza o si conviene migrarlo a humo/chispas más ricos sin ensuciar pantalla compartida.
   - ajustar posición/escala de marcadores y amplitud de la pose de desgaste antes de sumar más VFX o UI.

6. **Hacer visible y testeable el rescate/negacion**
   - usar `scenes/main/main_teams_validation.tscn` como escena corta de referencia y el coverage headless 2v2/validacion como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir si el nuevo combo `disco de recuperacion + aro de pertenencia + RecoveryTargetIndicator + RecoveryTargetFloorIndicator + CarryOwnerIndicator + CarryReturnIndicator`, ahora con refuerzo extra cuando la devolucion ya esta lista, realmente alcanza para leer urgencia/ownership/objetivo/handoff tambien durante el transporte en 2v2 y FFA o si todavia hace falta compactar escala/contraste/ritmo de esos cues.
   - comprobar en playtest si la nueva linea `negaciones N` realmente explica bien cuando el rival mando una pieza al vacio o si el cierre final todavia necesita distinguir mejor entre negacion enemiga y auto-error aliado.
   - confirmar por playtest si pausar la ventana de `DetachedPart` mientras viaja en mano mantiene bien la tension de rescate/negacion o si el proximo ajuste debe venir por `cleanup_time`/`throw_pickup_delay`, no por volver a resets implícitos.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

7. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si `WASD + TFGX` alcanza como unico camino Hard/local de teclado o si la sesion real justifica reabrir esa decision.
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
  - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.
  - si vuelve a tocarse la linea `Stats | ...`, conservar la semantica actual: `_competitor_match_stats.eliminations` mide derrotas recibidas, asi que el cierre debe seguir rotulandolas como `bajas sufridas`, no como bajas infligidas.
  - si vuelve a tocarse el orden del bloque `Stats | ...`, conservar `ffa_match_result_standings_test.gd`, `team_match_result_detail_order_test.gd` y `match_completion_test.gd`: ahora tambien cierran el riesgo de mezclar ranking/resultado correctos con telemetria final en scene-order.
  - si vuelve a tocarse el wording superior del cierre, conservar la separacion por modo: `Equipos` puede resumirse como `A-B`, pero `FFA` ya necesita una frase tipo `Player X gana la partida con N punto(s)` porque el detalle multi-competidor vive debajo en `Marcador` / `Posiciones`.
  - si vuelve a tocarse el orden del detalle de cierre, conservar `team_match_result_detail_order_test.gd` y `ffa_match_result_standings_test.gd`: ambos cierran el mismo riesgo de volver a scene-order en `RecapPanel`/`MatchResultPanel`.
  - si vuelve a tocarse la atribucion `por Player X`, conservar `match_elimination_source_reset_test.gd` dentro del chequeo minimo: el stale reciente no vivia en `RobotBase`, sino en el mapa per-round de `MatchController` que alimenta recap/resultado final.
  - si vuelve a tocarse el orden del roster vivo, conservar `live_roster_order_test.gd`: cierra la regresion donde el HUD por robot seguia en scene-order aunque `Marcador`, `Posiciones` y recap ya usaban el orden competitivo real.
  - medir si `Resumen | ...` + `Ultima baja | ...` + `Momento inicial/final` + `Fuera | vacio/explosion/explosion inestable` + `Inutilizado | explota/inestable` + atribucion `por Player X` + `DisabledWarningIndicator` + `Stats | ...` con `partes perdidas` + `RecapPanel` + `MatchResultPanel` + detalle `Player X / <Arquetipo> | baja N | causa | N/4 partes | sin ...` ya explican suficientemente bien la derrota inmediata o si la siguiente capa debe ser una pantalla post-ronda/post-partida más fuerte.

10. **Afinar la nueva presion de arena**
  - playtestear si `round_intro_duration_ffa` (actualmente 1.0) y `round_intro_duration_teams` (actualmente 0.6) dejan el beat correcto entre respawn y primer choque.
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
   - usar tambien `F6` para saltar en runtime entre `main.tscn`, `main_teams_validation.tscn`, `main_ffa.tscn` y `main_ffa_validation.tscn` antes de volver al editor; si cambia el set de laboratorios, mantener sincronizados `LAB_SCENE_VARIANTS`, la linea `Escena | ...` y `lab_scene_selector_test.gd`.
   - usar `godot --headless --path . -s res://scripts/tests/test_runner.gd` como entrypoint comun antes de caer en loops shell manuales; si cambia el layout de `scripts/tests`, mantener tambien `test_suite_runner_test.gd` para no perder discovery en silencio.
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
