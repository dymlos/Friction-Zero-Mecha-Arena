# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Hacer visible y testeable el rescate/negacion**
   - usar el coverage headless 2v2 actual como red de seguridad mientras se hacen sesiones reales de laboratorio.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

2. **Pulir la energia ahora que ya es jugable**
   - decidir si el foco debe quedar en presets por arquetipo o en redistribucion libre mas adelante
   - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
   - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida

3. **Mejorar validacion jugable**
   - sumar una escena/configuración de prueba pensada para reproducir rescates y negaciones más rápido que en el match completo
   - ajuste fino de valores de aceleracion, damping, empuje y danio

4. **Preparar soporte Hard sin convertirlo en requisito**
   - torso superior separado
   - rotacion independiente opt-in
   - mantener Easy como modo plenamente jugable

5. **Empezar el cierre de ronda real**
   - decidir como puntuar ring-out vs destruccion total
   - registrar muerte por explosion o por vacio
   - enlazar HUD minimo con estado de ronda en vez de solo mensajes
