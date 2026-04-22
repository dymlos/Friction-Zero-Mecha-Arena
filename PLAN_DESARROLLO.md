# PLAN_DESARROLLO.md - Friction Zero: Mecha Arena

Este plan ordena el desarrollo para validar primero la identidad real del juego: robots industriales que patinan con inercia, chocan con peso, se desarman por partes y obligan a leer el espacio antes de comprometerse. No propone un MVP generico: cada etapa debe dejar una version jugable que preserve la fantasia de "patinar y chocar con precision", aunque todavia falten capas avanzadas.

## Checkpoint actual - 2026-04-21

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
- Etapa 7: base funcional implementada. Las partes desprendidas ya conservan propietario, pueden recogerse por cercania, bloquear el ataque mientras se cargan y volver con vida parcial; si el portador cae al vacio, la parte se niega.
- Rescate modular mas legible: cada parte desprendida ahora muestra un disco diegetico sobre el suelo que se achica segun su `cleanup_time`, haciendo visible la ventana de recuperacion sin abrir otra banda de HUD.
- Objetivo de retorno mas legible: el robot que todavia puede recibir una pieza propia ahora muestra `RecoveryTargetIndicator`, un disco sobrio sobre el chasis que aparece mientras exista al menos una parte recuperable asociada y se apaga cuando la pieza vuelve o se pierde.
- Transporte de partes mas legible: cuando una `DetachedPart` ya va en manos de otro robot, `CarryIndicator` sigue marcando el tipo de pieza y ahora suma `CarryOwnerIndicator`, un aro fino con el color del dueño original para no perder contexto de rescate/negacion durante el traslado.
- Retorno del transporte mas legible: ese mismo portador ahora tambien muestra `CarryReturnIndicator`, una aguja corta que apunta al robot dueño de la pieza para que el handoff se lea aun cuando ambos robots ya estan en movimiento.
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
- Pendiente prioritario: playtestear si `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y ahora `Ancla` ya se sienten realmente distintos con esta mezcla de tuning + pasivas + primeras skills propias, ahora que el selector runtime permite cruzarlos sin editar escenas; en paralelo medir si `F2/F3/F4` + la linea `Lab | ...` + `LabSelectionIndicator` alcanzan como flujo de laboratorio o si hace falta persistencia/presets, si la nueva lectura de daño modular realmente se entiende en cámara compartida sin agregar ruido, si el nuevo combo de identidad/arquetipo (`FacingMarker/CoreLight` + `ArchetypeAccent` + aro de pertenencia sobre piezas sueltas + `StatusEffectIndicator` para `estabilidad/zona`) alcanza para distinguir aliados/rivales/rol/propietario/estado de control sin ensuciar la pelea, si el HUD `explicito/contextual` limpia la pantalla sin esconder decisiones tacticas y cual deberia ser el default en `Equipos` y `FFA`, si la explicacion de bajas actual (`Ultima baja`, `Resumen | ...`, `Momento inicial/final`, `Fuera | vacio/explosion/explosion inestable`, `Inutilizado | explota/inestable`, `Stats | Equipo ...` con partes perdidas y estado final `N/4 partes | sin ...`, `RecapPanel` y `MatchResultPanel`) alcanza para cerrar ronda/partida sin otra pantalla, si la rotacion semialeatoria controlada de edge pickups vuelve los bordes más tácticos sin transformarlos en zonas seguras permanentes y si el nuevo pickup de `estabilidad` da contrajuego suficiente a `Baliza`/`interferencia` sin volverse un seguro defensivo demasiado dominante; en paralelo confirmar si el first-to-3 + reinicio automatico/manual con `F5` deja buen ritmo, si la explosion inestable vuelve el overdrive mas tenso sin volverse dominante y si el nuevo conflicto `parte vs item/skill` sigue siendo claro cuando los rounds ya importan de verdad.

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
- pendiente: decidir si el reinicio automatico debe seguir conviviendo con `F5` como fallback del laboratorio o si conviene migrar a un cierre manual-only mas adelante, y si la puntuacion debe distinguir vacio vs destruccion

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
- el soporte actual sigue siendo mayormente joypad-first, pero el perfil `WASD` ya tiene aim por teclado (`TFGX`) para habilitar al menos un slot Hard jugable sin joystick en laboratorio
- `Main` ya puede forzar slots concretos a Hard desde `hard_mode_player_slots`; el HUD deja visible el mapping activo por slot al inicio y el roster lo mantiene visible durante la ronda
- se decidio mantener el camino Hard por teclado acotado a `WASD + TFGX`; el resto de los slots Hard queda explicitamente joypad-first hasta que playtests reales justifiquen reabrir esa decision o sumar un selector runtime

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
