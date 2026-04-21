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

21. **Robots eliminados quedan fuera hasta el reset común**
   - `RobotBase` ahora puede quedar retenido para el reset de ronda en vez de auto-respawnear inmediatamente tras vacío o explosión.
   - Motivo: preservar lectura del resultado, evitar que una baja decisiva se “deshaga” sola y mantener el cierre de ronda legible.

22. **Cierre de ronda validado sobre la escena real**
   - `match_round_resolution_test.gd` usa `main.tscn` para comprobar victorias por vacío y destrucción total, marcador y reset conjunto.
   - Motivo: la lógica de ronda depende de `Main`, `MatchController`, HUD y lifecycle de `RobotBase`; probar piezas aisladas dejaría huecos importantes.

## Criterios mantenidos

- Priorizar sensacion de movimiento y choque antes que sistemas avanzados.
- Mantener escenas y scripts chicos, faciles de leer para una persona con poca experiencia en Godot.
- Evitar UI pesada: el robot comunica estado primero por el propio cuerpo.
