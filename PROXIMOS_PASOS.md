# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Hacer visible y testeable el rescate/negacion**
   - usar el coverage headless 2v2 actual como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

2. **Definir cierre de match encima del nuevo cierre de ronda**
   - decidir si el prototipo debe jugarse a first-to-X rondas, por tiempo o por score acumulado.
   - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.
   - enlazar el HUD minimo con victoria de match, no solo con marcador de ronda.

3. **Afinar la nueva presion de arena**
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - decidir si conviene sumar feedback visual sobrio extra en el piso, no solo en edge markers + HUD.

4. **Pulir la energia ahora que ya es jugable**
   - decidir si el foco debe quedar en presets por arquetipo o en redistribucion libre mas adelante
   - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
   - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida

5. **Mejorar validacion jugable**
   - sumar una escena/configuración de prueba pensada para reproducir rescates, negaciones y cierres de ronda/contraccion más rápido que en el match completo
   - ajuste fino de valores de aceleracion, damping, empuje y danio
   - medir si el reset corto de ronda deja suficiente tiempo de lectura o si necesita un delay algo mayor

6. **Preparar soporte Hard sin convertirlo en requisito**
   - torso superior separado
   - rotacion independiente opt-in
   - mantener Easy como modo plenamente jugable
