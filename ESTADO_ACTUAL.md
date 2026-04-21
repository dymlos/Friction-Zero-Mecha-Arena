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
- robot inutilizado al perder las cuatro partes, pero todavia empujable

## Lo completado en esta iteracion

- Se implemento danio modular por direccion de impacto.
- Se agrego una escena reutilizable para partes desprendidas.
- Se conectaron eventos de perdida de parte e inutilizacion al HUD de prototipo.
- Se corrigio la resolucion de tipos de GDScript con `preload()` para que el proyecto parsee bien fuera del cache del editor.

## Validacion realizada

- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit`
- `godot --headless --path /home/user/repo/Friction-Zero-Mecha-Arena --quit-after 30`

Resultado: el proyecto inicia sin errores de parseo ni referencias rotas en ejecucion headless.

## Limites actuales

- La validacion automatica confirma integridad tecnica, no sensacion de movimiento ni calidad del combate.
- Todavia no hay torso independiente Hard.
- La energia existe como dato y multiplicador futuro, pero no hay redistribucion jugable ni UI asociada.
- Las partes desprendidas aun no se pueden recuperar, negar ni devolver.
- No hay explosion diferida del cuerpo inutilizado ni cierre real de ronda por destruccion total.
