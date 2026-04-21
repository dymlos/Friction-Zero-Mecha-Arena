# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Hacer visible y testeable el rescate/negacion**
   - usar el coverage headless 2v2 actual como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

2. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si `WASD + TFGH` alcanza como camino Hard/local de laboratorio o si sigue resultando demasiado exigente/confuso para pantalla compartida.
   - decidir si `hard_mode_player_slots` alcanza como configuracion de laboratorio o si conviene un selector runtime por jugador.
   - resolver si vale la pena extender aim por teclado a otro perfil local o si conviene dejar el resto de los slots Hard explicitamente joypad-first.
   - revisar si la leyenda inicial del HUD alcanza o si hace falta una referencia mas persistente/compacta de controles activos.
   - playtestear si la nueva lectura torso/chasis mejora el combate o si todavia se siente demasiado sutil para pantalla compartida.

3. **Pulir el cierre de match que ya existe**
   - playtestear si `rounds_to_win=3` y `match_restart_delay` dejan leer bien la victoria o si el resultado pasa demasiado rápido.
   - decidir si el reinicio automático debe seguir siendo la solución del laboratorio o si conviene pasar a una espera corta con confirmación/manual restart más adelante.
   - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.

4. **Afinar la nueva presion de arena**
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - decidir si conviene sumar feedback visual sobrio extra en el piso, no solo en edge markers + HUD.

5. **Pulir la energia ahora que ya es jugable**
   - decidir si el foco debe quedar en presets por arquetipo o en redistribucion libre mas adelante
   - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
   - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida

6. **Mejorar validacion jugable**
   - sumar una escena/configuración de prueba pensada para reproducir rescates, negaciones y cierres de ronda/contraccion más rápido que en el match completo
   - ajuste fino de valores de aceleracion, damping, empuje y danio
   - medir si el reset corto de ronda y el reinicio de match dejan suficiente tiempo de lectura o si necesitan delays algo mayores

7. **Profundizar el soporte Hard sin convertirlo en requisito**
   - direccionar mejor ataques/skills futuros usando la nueva referencia de torso
   - decidir si el daño modular debe ponderar tambien frente/espalda del chasis inferior y no solo del torso
   - mantener Easy como modo plenamente jugable y legible

8. **Agregar un primer incentivo real en bordes del mapa**
   - evaluar si el siguiente slice deberia ser un pickup universal simple, una cobertura blockout o ambos en pequeño para que los bordes ofrezcan algo mas que riesgo.
   - mantener el centro limpio y legible, evitando saturar la arena con demasiados objetos.
   - validar que cualquier incentivo nuevo siga sirviendo a la fantasia principal de patinar, leer y chocar con precision.
