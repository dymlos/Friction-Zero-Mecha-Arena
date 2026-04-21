# ESTADO_ACTUAL.md - Friction Zero: Mecha Arena

## Estado del prototipo

El proyecto ya tiene una base jugable en Godot 4.6 con:

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
- soporte base de control Hard
  - el torso superior puede separarse del chasis con `UpperBodyPivot`
  - la orientacion de combate e impactos modulares en Hard usa esa referencia
  - el soporte actual es joypad-first; sin input de aim dedicado el robot no rompe el loop Easy actual
- partes desprendidas con propietario original, pickup por cercania y retorno parcial
- transporte de partes que bloquea el ataque prototipo
- negacion basica de partes si el portador cae al vacio
- robot inutilizado al perder las cuatro partes, empujable y con explosion diferida antes de quedar fuera de ronda o reiniciar
- bootstrap local que deja cuatro robots humanos activos por defecto desde `main.tscn`
- perfiles de input separados por slot local para evitar compartir teclado/joypad por accidente
- escenario base 2v2 en `main.tscn` con dos equipos (pares por `team_id`) y 4 slots locales activos para validar rescate aliado y handoff en campo.
- cierre de ronda simple: el ultimo robot/equipo en pie suma una ronda y todos los robots vuelven juntos tras un delay corto
- cierre de match simple: el laboratorio juega a `first-to-3`; cuando un equipo alcanza el objetivo, el HUD anuncia al ganador de la partida y el match se reinicia limpio tras una pausa corta
- presion final de arena: el piso y sus edge markers se contraen de forma progresiva segun el tiempo de ronda, y el HUD agrega una linea corta cuando empieza el cierre
- HUD minimo con estado de ronda + objetivo del match + marcador compacto y roster por robot para leer estado, energia y si un robot transporta una parte
- negacion por lanzamiento: un jugador que lleva una parte puede lanzarla para negarla sin esperar una caída al vacio
- ritmo de duelo 2P ajustado: movimiento más estable al corregir, empuje/presión de impacto más claros para favorecer el ciclo de tanteo->choque->castigo sin spam de contactos frágiles.
- indicador de carga visible en mundo: un estado de "parte en mano" se muestra con indicador pulso-orbital por parte.
- validacion 2v2 automatizada del loop de rescate/negacion: `main.tscn` ya se cubre con un test que comprueba pickup aliado, color/visibilidad del indicador y bloqueo temporal tras lanzamiento.
- validacion automatizada del cierre de ronda: `main.tscn` ya comprueba victorias por vacio y por destruccion total con reset de ronda y scoreboard.

## Lo completado en esta iteracion

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
- Se activo la primera presion de endgame que faltaba en mapas:
  - `MatchController` ahora mide tiempo de ronda y expone un factor de contraccion del arena
  - `Main` aplica ese factor sobre `ArenaBase` sin mezclar logica de match y geometria
  - el `arena_blockout` reduce piso util y edge markers reales, y vuelve a tamano completo al reset de ronda
  - `default_match_config.tres` baja la ronda base a 60 segundos para que la contraccion aparezca en playtests normales
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
- Se agrego un test dedicado `two_vs_two_carry_validation_test.gd` sobre la escena principal 2v2 y se corrigio `robot_part_return_test.gd` para respetar el `pickup_delay` real.
- Se corrigio una advertencia de tipado en `_refresh_carry_indicator_color()` que rompía la compilación headless al tratarse como error.
- Se endurecio la salida de los tests headless actuales: ahora conservan estado de fallo y terminan con codigo distinto de cero cuando una asercion falla.
- Se sumo validacion headless especifica para redistribucion y overdrive, cubriendo el slice tactico nuevo sin introducir infraestructura adicional.
- Se sumaron verificaciones headless para el bootstrap multijugador y la separacion de input, manteniendo ademas las pruebas previas del loop modular.
- Se agrego `match_round_resolution_test.gd` para cubrir dos rutas de victoria reales en el laboratorio 2v2:
  - doble ring-out rival
  - doble destruccion total rival con explosion diferida
  - verificacion de marcador, ronda visible y reset comun

## Validacion realizada

- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_part_return_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_disabled_explosion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_energy_management_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/local_multiplayer_bootstrap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_completion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_input_ownership_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/two_vs_two_carry_validation_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/match_round_resolution_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/progressive_space_reduction_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_hard_control_mode_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit-after 30`

Resultado: las diez verificaciones dedicadas pasan y el proyecto sigue iniciando sin errores de parseo ni referencias rotas en ejecucion headless.

## Limites actuales

- La validacion automatica confirma integridad tecnica, no sensacion de movimiento ni calidad del combate.
- El soporte Hard ya existe, pero sigue siendo una primera base: no hay seleccion visible de modo por jugador ni mapping dedicado de teclado para aim independiente en partidas locales.
- La energia ya es jugable, pero sigue siendo una primera version discreta: no existe redistribucion libre por porcentajes ni sobrecalentamiento mas rico por parte.
- Ring-out y destruccion total hoy puntuan igual a nivel de ronda y match; sigue pendiente decidir si algun modo deberia diferenciarlos en scoring o feedback.
- El roster sigue siendo texto de estado; el indicador diegetico cubre la parte crítica de “carga visible” y reduce ambigüedad.
- La validacion automatica ya cubre el caso 2v2 base y el cierre de ronda; sigue faltando prueba manual de sensación para decidir si `pickup_delay` y `throw_pickup_delay` son demasiado severos o permisivos bajo presión real de ronda.
- El cierre de match ya existe, pero sigue siendo intencionalmente sobrio: no hay post-partida con stats, replay ni explicación explícita de por qué perdió cada jugador.
