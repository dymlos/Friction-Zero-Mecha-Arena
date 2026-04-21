# DECISIONES_TECNICAS.md - Friction Zero: Mecha Arena

## Decisiones vigentes

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

8. **Bootstrap local desde `main` en vez de confiar en la escena armada a mano**
   - `main.gd` ahora asigna spawns y slots locales a los robots ya presentes en la escena.
   - Motivo: deja el prototipo mas facil de entender y evita escenas "correctas por casualidad" cuando se suman mas jugadores o se cambian spawns.

9. **Ownership de input por slot, no por dispositivo global**
   - Cada `RobotBase` usa un perfil de teclado concreto o un joystick resuelto por slot/dispositivo explicito.
   - Motivo: elimina el problema de varios robots leyendo las mismas teclas o todos los joysticks a la vez, que hacia engañosa cualquier prueba local de combate.

10. **HUD de roster compacto en vez de barra pesada**
   - El HUD nuevo lista estado de ronda, marcador compacto y estado/carga por robot, sin barras invasivas.
   - Motivo: mejora la lectura del loop modular y del cierre de ronda sin romper la prioridad del proyecto por claridad y pantalla compartida limpia.

11. **Redistribucion de energia discreta por foco de parte**
   - Cambiar el foco reasigna energia entre las cuatro partes usando presets simples en vez de sliders o menus.
   - Motivo: vuelve tactica la energia ya en este prototipo sin exigir una UI compleja ni microgestion poco legible.

12. **Energia aplicada como multiplicador real separado de la salud**
   - La salud sigue definiendo la degradacion base; la energia ahora suma o resta rendimiento sobre movilidad y empuje aunque la pieza siga sana.
   - Motivo: evita que la energia quede anulada por clamps internos y hace visible la decision antes del choque.

13. **Overdrive corto con recuperacion y cooldown**
   - El overdrive concentra energia en la parte foco durante una ventana breve y luego deja una penalizacion temporal antes de volver a estar disponible.
   - Motivo: respeta la idea de apuesta de alto riesgo/alta recompensa sin convertir la redistribucion en spam.

14. **Negacion de parte por lanzamiento**
   - Se añadió una acción dedicada para lanzar una parte transportada, permitiendo negar recuperaciones sin introducir un sistema de item adicional.
   - Motivo: conectar el bucle de rescate con decisiones de espacio/tiempo y mantener el control del estado legible.

15. **Ajuste de ritmo de duelo via parámetros exportados**
   - Se prefirió reajustar el duelo 2P ajustando `RobotBase` en lugar de agregar una mecánica nueva.
   - Motivo: el equilibrio de inercia, alcance/impulso y daño de choque define la sensación principal del prototipo sin comprometer la simplicidad técnica existente.

16. **2v2 de laboratorio con equipos y 4 slots locales**
  - Se habilitó `main.tscn` con 4 robots y `local_player_count=4`, usando `team_id` para aliar jugadores en parejas.
  - Motivo: validar rescate entre aliados en partidas 2v2 reales sin introducir todavía un mode manager completo de matchmaking.

17. **Indicador de carga de parte legible sin HUD pesado**
   - `RobotBase` muestra un indicador diegético sobre el robot cuando transporta una parte, con color por tipo de parte y pulso leve.
   - Motivo: mejora la legibilidad para aliados, rivales y espectadores sin añadir una interfaz pesada en pantalla compartida.

18. **Validación 2v2 sobre la escena real, no sobre un mock aislado**
   - El coverage nuevo de rescate/negación usa `scenes/main/main.tscn` y no solo robots sueltos.
   - Motivo: verifica a la vez equipos, bootstrap local, indicador de carga y retardos de pickup/lanzamiento en el contexto que realmente se prueba el laboratorio.

19. **Tests headless con salida confiable**
   - Los scripts de `scripts/tests/` ahora conservan un flag `_failed` y finalizan con `quit(1 if _failed else 0)`.
   - Motivo: evitar falsos verdes en automatización cuando una aserción registra error pero el script llega al `quit()` final.

20. **Scoring de ronda simple y simétrico para el prototipo**
   - Ring-out y destrucción total cuentan igual: eliminan al robot de la ronda y el último contendiente en pie suma un punto.
   - Motivo: cerrar el sandbox infinito con la menor cantidad de reglas nuevas, sin comprometer todavía el diseño final de puntuación por modo.

21. **Cierre de match first-to-X desde `MatchConfig`**
   - El objetivo de rondas vive en `rounds_to_win`; cuando un competidor lo alcanza, `MatchController` anuncia ganador de partida y detiene la ronda actual.
   - Motivo: el prototipo necesitaba una condición de victoria real, configurable y fácil de leer sin meter un mode flow más pesado todavía.

22. **Reinicio automático tras victoria de match**
   - Tras una pausa corta (`match_restart_delay`), el laboratorio reinicia el match completo y vuelve a ronda 1 con score limpio.
   - Motivo: mantener la escena siempre jugable en playtests locales y evitar volver al estado de sandbox infinito o exigir UI/menu extra en esta etapa.

23. **Robots eliminados quedan fuera hasta el reset común**
   - `RobotBase` ahora puede quedar retenido para el reset de ronda en vez de auto-respawnear inmediatamente tras vacío o explosión.
   - Motivo: preservar lectura del resultado, evitar que una baja decisiva se “deshaga” sola y mantener el cierre de ronda legible.

24. **Cierre de ronda validado sobre la escena real**
   - `match_round_resolution_test.gd` usa `main.tscn` para comprobar victorias por vacío y destrucción total, marcador y reset conjunto.
   - Motivo: la lógica de ronda depende de `Main`, `MatchController`, HUD y lifecycle de `RobotBase`; probar piezas aisladas dejaría huecos importantes.

25. **Cierre de match validado con la escena real**
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

37. **Camino Hard por teclado acotado al perfil `WASD`**
   - `RobotBase` ahora crea acciones `aim_left/right/forward/back` y el perfil `WASD_SPACE` las resuelve con `TFGX`; ademas suma `throw_part` en `C`.
   - Motivo: cerrar la brecha mas evidente del laboratorio local con el minimo cambio posible, sin intentar resolver de golpe un esquema Hard perfecto para 4 teclados compartidos.

38. **Leyenda de controles visible desde el arranque**
   - `Main` construye el mensaje inicial del HUD leyendo `robot.get_input_hint()` por slot local.
   - Motivo: que los playtests Easy/Hard no dependan de recordar mappings fuera del juego y dejar explicito cuando un slot Hard sigue necesitando aim por stick derecho.

39. **Politica Hard/local cerrada a favor de claridad**
   - Se mantiene `WASD + TFGX` como unico camino Hard/local totalmente por teclado; el resto de los perfiles Hard queda explicitamente joypad-first y esa advertencia sigue visible al arrancar, ademas de persistir en el roster cuando el HUD esta en modo `explicito`.
   - Motivo: evitar nuevos solapes de teclas y UX confusa en teclado compartido hasta tener evidencia de playtests que justifique reabrir mappings o sumar selector runtime.

40. **Incentivo de borde via pickup de reparacion instantanea**
   - El primer objetivo real de borde se resolvio con `EdgeRepairPickup`: un pickup universal simple, fijo y visible que cura la parte activa mas dañada al tocarlo; en cooldown mantiene el pedestal y apaga solo el nucleo.
   - Motivo: volver los flancos tentadores ya en el laboratorio sin introducir todavía inventario, rareza o una capa de items que opaque el nucleo de patinar/chocar.

41. **La reparacion de borde no revive piezas destruidas**
   - `RobotBase` expone `repair_most_damaged_part(...)` y solo repara partes que sigan activas; los miembros destruidos siguen dependiendo del loop de partes desprendidas.
   - Motivo: sumar sustain tactico y comeback parcial sin invalidar rescate aliado, negacion enemiga ni el peso de perder una pierna o un brazo.

42. **Legibilidad modular reforzada sobre la propia pieza**
   - `RobotBase` crea marcadores runtime `DamageFeedback/Smoke` y `DamageFeedback/Spark` sobre cada extremidad, escalando solo cuando esa parte realmente está dañada o crítica.
   - Motivo: acercar la lectura a “humo/chispas sobre el robot” que piden los docs sin sumar HUD nuevo, assets externos ni un sistema de partículas difícil de mantener en este prototipo.

43. **Cobertura de borde acompasada con la contracción del arena**
   - `arena_blockout.tscn` suma dos bloques estáticos simples bajo `CoverBlocks`, y `ArenaBase` reubica esas coberturas según el tamaño actual del área segura.
   - Motivo: validar duelo/cobertura en bordes sin romper la presión de endgame ni dejar geometría desfasada cuando el mapa se achica.

44. **Pickups de borde acompasados con la contracción del arena**
   - `ArenaBase` ahora cachea la posicion local original de los nodos del grupo `edge_repair_pickups` y los reubica con la misma escala X/Z que el area segura.
   - Motivo: si el pickup quedaba fijo mientras la arena se cerraba, el incentivo de borde se salia del espacio jugable y rompia el duelo riesgo/recompensa del endgame.

45. **FFA expuesto como escena heredada del laboratorio principal**
   - `scenes/main/main_ffa.tscn` hereda `main.tscn`, fija `MatchMode.FFA` y reutiliza la misma arena, HUD y bootstrap local.
   - Motivo: volver FFA una opcion testeable ya mismo sin duplicar escenas grandes ni abrir una segunda rama de codigo para el laboratorio.

46. **Neutralizacion de `team_id` cuando el bootstrap corre en FFA**
   - `Main` pone `team_id = 0` en los robots si `MatchController` arranca en `FFA`, antes de registrarlos.
   - Motivo: el layout 2v2 conserva parejas en escena para `main.tscn`; sin neutralizar eso en FFA, `is_ally_of` permitia rescates/devoluciones falsas entre rivales.

47. **El HUD explicito deja visible el modo de match**
   - En `EXPLICIT`, `MatchController.get_round_state_lines()` agrega `Modo | FFA` o `Modo | Equipos` antes del objetivo y el marcador; en `CONTEXTUAL` esas lineas fijas se ocultan para priorizar el estado cambiante.
   - Motivo: mantener la claridad de laboratorio cuando hace falta depurar/configurar el setup, pero permitir una variante mas limpia que no repita informacion estable durante toda la ronda.

48. **La explicación de bajas vive en el HUD compacto existente**
   - `MatchController.get_robot_status_lines()` ahora usa el mismo roster para mostrar `Inutilizado | explota Xs` y `Fuera | vacio/explosion`, mientras `get_round_state_lines()` agrega `Ultima baja | ...`.
   - Motivo: mejora la lectura de derrota y amenaza inminente en pantalla compartida sin introducir una capa nueva de UI ni romper la prioridad por claridad.

49. **Segundo incentivo de borde via pickup universal de movilidad**
   - `EdgeMobilityPickup` activa una ventana breve de traccion/control reforzados sobre `RobotBase` y reaparece tras cooldown, sin tocar el sistema de energia ni abrir una capa nueva de inventario.
   - Motivo: sumar un item universal que refuerce la fantasia principal de patinar/reposicionarse, manteniendo la lectura limpia y el riesgo atado al borde.

50. **Seguimiento generico para pickups de borde**
   - `ArenaBase` ya no recoloca solo `edge_repair_pickups`; ahora sigue cualquier nodo del grupo `edge_pickups`, incluyendo reparacion e impulso.
   - Motivo: permitir variedad minima de incentivos en los bordes sin duplicar logica de contraccion ni dejar nuevos pickups desfasados respecto del borde vivo.

51. **Tercer incentivo de borde via pickup universal de energia**
   - `EdgeEnergyPickup` activa una recarga breve sobre el par energetico seleccionado y reaparece tras cooldown, reutilizando el mismo contrato visible de pedestal + nucleo que reparacion e impulso.
   - Motivo: completar el trio minimo de incentivos prioritarios del documento (`reparacion`, `movilidad`, `energia`) sin abrir todavia inventario, rareza ni items de una sola carga.

52. **La recarga de energia estabiliza, no reemplaza el overdrive**
   - Al recoger energia, `RobotBase` corta la recuperacion post-overdrive, reaplica el foco actual y suma una ventana corta de rendimiento extra sobre ese mismo par; no reactiva overdrive ni elimina todo el cooldown restante.
   - Motivo: volver valioso el pickup de energia sin volverlo spam ni borrar la identidad de riesgo/recompensa del overdrive.

53. **Primer item cargable comparte slot con las partes transportadas**
   - `RobotBase` ahora usa un unico slot/logica de payload visible: puede llevar una `DetachedPart` o una `pulse_charge`, pero no ambos a la vez.
   - Motivo: mantener legible la pantalla compartida, evitar estados superpuestos y volver real la decision entre rescate/negacion y utilidad ofensiva.

54. **El primer skillshot entra como item de borde, no como kit base**
   - `EdgePulsePickup` entrega una sola carga de `pulse_charge`; al usarla, `RobotBase` consume el item y dispara `PulseBolt`, un proyectil corto que empuja y daña al primer objetivo o cobertura física que encuentra.
   - Motivo: validar la tensión “choque vs influencia a distancia” sin abrir todavía un sistema completo de habilidades, munición por personaje ni HUD nuevo.

55. **Los edge pickups rotan por ronda en un mazo seedado de pares espejados**
   - `ArenaBase` define cuatro cruces base (`repair + mobility`, `repair + pulse`, `energy + mobility`, `energy + pulse`) y `activate_edge_pickup_layout_for_round(round_number)` deja activos solo dos pares espejados por ronda.
   - Motivo: cumplir el criterio de “pocos items, importantes y semialeatorios” sin romper justicia espacial, sin duplicar escenas y sin abrir todavía pesos complejos por mapa o respawns con cambio de tipo.

56. **La rotación de pickups se cuelga del inicio de ronda, no del cooldown individual**
   - `MatchController` emite `round_started`, `Main` aplica el layout al `ArenaBase` activo y cada pickup expone `set_spawn_enabled()` para apagarse completo cuando no forma parte del layout actual.
   - Motivo: mantener responsabilidades claras, evitar un director extra de mapa y conservar el telegraph local de pedestal/cooldown dentro de los pickups ya existentes.

57. **Los layouts de edge pickups cambian segun el modo de match**
   - `ArenaBase` ahora usa un perfil `teams` con dos pares espejados por ronda y un perfil `ffa` con layouts `3-de-4`, ambos seedados y reutilizando el mismo contrato `activate_edge_pickup_layout_for_round(round_number)`.
   - Motivo: Team vs Team necesita preservar claridad para rescate/choque, mientras FFA gana mas oportunismo y presencia de utilidad sin volver a ocho pickups activos ni romper justicia espacial.

58. **El HUD compacto resume el layout activo del borde**
   - `Main` agrega `Borde | ...` a las lineas de ronda usando `ArenaBase.get_active_edge_pickup_layout_summary()`.
   - Motivo: hacer medible y legible la rotación semialeatoria durante playtests sin sumar otro panel de UI ni depender de memoria externa.

59. **Overdrive conecta con una explosion diferida inestable**
   - Si `RobotBase` pierde su ultima parte mientras `Overdrive` sigue activo, el cuerpo inutilizado conserva una bandera `inestable`; esa variante escala `radio/empuje/daño`, calienta mas el core del robot y `Main/MatchController` la exponen como `inestable` / `explosion inestable` en HUD y resumenes.
   - Motivo: cerrar la apuesta riesgo/recompensa del overdrive con una consecuencia espacial rara pero legible, reutilizando el loop de cuerpo inutilizado ya existente en vez de abrir otro hazard o una regla aparte.

60. **El cierre de ronda se resume en la misma banda textual del HUD**
   - `MatchController` ahora guarda el orden de bajas de la ronda y solo lo expone como `Resumen | ...` cuando la ronda ya termino; al iniciar la siguiente, ese recap se limpia.
   - Motivo: reforzar la explicacion de “como termino esta ronda” sin abrir otra capa de post-ronda, sin esconder el combate activo bajo texto extra y reutilizando el contrato compacto ya establecido en `get_round_state_lines()`.

61. **El detalle del HUD se controla desde `MatchConfig`, no con otra escena**
   - `MatchConfig.hud_detail_mode` alterna entre `EXPLICIT` y `CONTEXTUAL`, `RobotBase` expone `is_energy_balanced()` para que el filtro sepa cuando volver a mostrar energia, y `Main` sigue refrescando el mismo `MatchHud` sin branching adicional de escenas.
   - Motivo: sumar la configuracion pedida por el documento de UI con el menor cambio posible, manteniendo el codigo testeable por headless y sin duplicar layouts.

62. **Primeros arquetipos como recursos de tuning, no como ramas de código separadas**
   - `RobotArchetypeConfig` encapsula multiplicadores simples y `RobotBase` los aplica al arrancar; el laboratorio usa `Ariete`, `Grua`, `Cizalla` y `Patin` sobre la misma escena base.
   - Motivo: cerrar la brecha de identidad del roster con el menor costo técnico posible, manteniendo el proyecto entendible para un principiante y dejando la puerta abierta a skills/pasivas propias solo si el tuning no alcanza.

63. **El toggle runtime del HUD vive como override local, no en el recurso compartido**
   - `MatchController` conserva `MatchConfig.hud_detail_mode` como default de arranque, pero permite ciclar una sobreescritura de sesion; `Main` expone ese cambio con `F1` para playtests locales.
   - Motivo: comparar `explicito/contextual` dentro del mismo laboratorio sin ensuciar escenas nuevas ni mutar el `.tres` compartido entre instancias/tests.

64. **La segunda capa de arquetipos reutiliza hooks ya existentes**
   - `RobotArchetypeConfig` ahora agrega pasivas chicas sin escenas ni botones nuevos: `Ariete` baja el impulso externo recibido, `Grua` estabiliza otra pieza dañada al devolver una parte, `Cizalla` castiga mas una pieza ya tocada y `Patin` estira la duracion de los boosts de movilidad.
   - `RobotBase` las resuelve dentro de `apply_impulse`, `restore_part`, `receive_attack_hit_from_robot` / `receive_collision_hit_from_robot` y `apply_mobility_boost`, mientras `PulseBolt` tambien pasa el atacante para no romper la identidad de `Cizalla` fuera del melee.
   - Motivo: profundizar la identidad del roster sin abrir todavia skills activas, UI nueva ni ramas de codigo por robot; se apoya en sistemas que ya eran jugables y legibles en el laboratorio actual.

65. **La primera skill propia reutiliza `PulseBolt` y la accion de utilidad ya existente**
   - `RobotArchetypeConfig` ahora puede declarar `core_skill_type/label/cargas/recarga`, y `RobotBase` consume esa info para disparar una skill desde `throw_part` cuando no lleva una pieza.
   - Motivo: abrir un primer arquetipo Poke/Skillshot sin sumar botones nuevos, manteniendo la regla importante de que cargar una parte bloquea otras habilidades activas.

66. **`Aguja` se expone primero en FFA, no en el laboratorio 2v2**
   - `main_ffa.tscn` reemplaza el slot de `Grua` por `Aguja`, mientras `main.tscn` conserva `Ariete/Grua/Cizalla/Patin` para seguir priorizando rescate aliado en equipos.
   - Motivo: FFA gana oportunismo y poke legible sin debilitar el laboratorio 2v2 que hoy valida mejor asistencia/recuperacion.

67. **`Ancla` completa Control/Zona con una baliza persistente corta**
   - `RobotArchetypeConfig.CoreSkillType` ahora tambien puede ser `CONTROL_BEACON`, y `RobotBase` lo resuelve desplegando `ControlBeacon`, una zona breve que ralentiza drive/control de rivales dentro del area.
   - Motivo: cerrar el sexto arquetipo documentado con el cambio mas chico posible, reutilizando la misma accion de utilidad y manteniendo el efecto claramente subordinado al combate de choque.

68. **Solo una baliza activa por robot para proteger la claridad**
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
   - `Main` reenvia a `MatchController` los eventos ya cableados de rescate (`part_restored`) y pickups de borde (`edge_*_pickup_collected`); `record_robot_elimination()` completa la telemetria con causas finales de baja.
   - `MatchController` agrega solo durante ronda activa y expone lineas compactas `Stats | Competidor | rescates N | borde N | bajas N (...)` tanto en `RecapPanel` como en `MatchResultPanel`.
   - Motivo: cumplir el pedido de “stats simples de fin de partida” sin abrir otra escena, sin duplicar estado en `Main` y sin permitir padding accidental durante el tiempo muerto posterior al cierre.

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

## Criterios mantenidos

- Priorizar sensacion de movimiento y choque antes que sistemas avanzados.
- Mantener escenas y scripts chicos, faciles de leer para una persona con poca experiencia en Godot.
- Evitar UI pesada: el robot comunica estado primero por el propio cuerpo.
