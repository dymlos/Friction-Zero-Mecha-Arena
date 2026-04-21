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
- partes desprendidas con propietario original, pickup por cercania y retorno parcial
- transporte de partes que bloquea el ataque prototipo
- negacion basica de partes si el portador cae al vacio
- robot inutilizado al perder las cuatro partes, empujable y con explosion diferida antes del respawn
- bootstrap local que deja dos robots humanos activos por defecto desde `main.tscn`
- perfiles de input separados por slot local para evitar compartir teclado/joypad por accidente
- HUD minimo con roster compacto para leer estado, energia y si un robot transporta una parte

## Lo completado en esta iteracion

- Se hizo explicito el bootstrap local del prototipo: `main.gd` ahora asigna slots, spawns y deja dos jugadores activos por defecto.
- Se separo ownership de input local con perfiles de teclado por jugador y fallback de joystick por slot, evitando que varios robots lean el mismo dispositivo.
- Se agrego un roster compacto en HUD para leer rapido quien sigue activo, cuantas partes conserva y si transporta una parte recuperable.
- La energia ahora deja de ser solo dato: el robot puede mover el foco con entradas discretas, alterar multiplicadores reales y usar overdrive con penalizacion corta.
- Se sumo validacion headless especifica para redistribucion y overdrive, cubriendo el slice tactico nuevo sin introducir infraestructura adicional.
- Se sumaron verificaciones headless para el bootstrap multijugador y la separacion de input, manteniendo ademas las pruebas previas del loop modular.

## Validacion realizada

- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_part_return_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_disabled_explosion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_energy_management_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/local_multiplayer_bootstrap_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_input_ownership_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit-after 30`

Resultado: las cinco verificaciones dedicadas pasan y el proyecto sigue iniciando sin errores de parseo ni referencias rotas en ejecucion headless.

## Limites actuales

- La validacion automatica confirma integridad tecnica, no sensacion de movimiento ni calidad del combate.
- Todavia no hay torso independiente Hard.
- La energia ya es jugable, pero sigue siendo una primera version discreta: no existe redistribucion libre por porcentajes ni sobrecalentamiento mas rico por parte.
- La escena principal ya permite duelo 1v1 humano real, pero todavia no demuestra rescates cooperativos reales porque no existe una configuracion 2v2 o aliado activo en vivo.
- El roster mejora la lectura del estado modular, pero sigue siendo un HUD textual de depuracion; aun no existe feedback diegetico fuerte para "parte cargada".
- No existe accion de lanzamiento manual para negar partes: la negacion actual solo se resuelve llevando el portador al vacio.
