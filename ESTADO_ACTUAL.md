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
- partes desprendidas con propietario original, pickup por cercania y retorno parcial
- transporte de partes que bloquea el ataque prototipo
- negacion basica de partes si el portador cae al vacio
- robot inutilizado al perder las cuatro partes, empujable y con explosion diferida antes del respawn

## Lo completado en esta iteracion

- Se agrego recuperacion modular basica con propietario, retorno parcial y bloqueo de ataque al cargar una parte.
- Se implemento negacion basica de partes mediante caida al vacio del portador.
- Se agrego explosion diferida para robots inutilizados, con danio/empuje radial y respawn posterior.
- Se sumaron verificaciones headless especificas para retorno de partes y explosion del cuerpo averiado.

## Validacion realizada

- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_part_return_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --script res://scripts/tests/robot_disabled_explosion_test.gd`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit-after 30`

Resultado: los dos loops nuevos pasan en verificaciones dedicadas y el proyecto sigue iniciando sin errores de parseo ni referencias rotas en ejecucion headless.

## Limites actuales

- La validacion automatica confirma integridad tecnica, no sensacion de movimiento ni calidad del combate.
- Todavia no hay torso independiente Hard.
- La energia existe como dato y multiplicador futuro, pero no hay redistribucion jugable ni UI asociada.
- La escena principal todavia no demuestra rescates cooperativos reales porque solo un robot esta controlado por jugador.
- Aun no hay feedback visual dedicado para "parte cargada" mas alla del propio mesh transportado y el mensaje breve de HUD.
- No existe accion de lanzamiento manual para negar partes: la negacion actual solo se resuelve llevando el portador al vacio.
