# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Hacer visible y testeable el rescate/negacion**
   - mantener el bootstrap 2P y sumar una configuracion 2v2 simple o aliado activo
   - probar handoff real de partes entre aliados, no solo autoretorno
   - testear lanzamiento manual en duelo y en 2v2 para ajustar alcance, velocidad y ventanas de negación
   - ajustar pickup delay, radio de retorno y cleanup segun sensacion
   - validar que el ritmo de choque ajustado en `RobotBase` se mantiene legible en presencia de un aliado y sin spam accidental.

2. **Pulir la energia ahora que ya es jugable**
   - decidir si el foco debe quedar en presets por arquetipo o en redistribucion libre mas adelante
   - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
   - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida

3. **Mejorar validacion jugable**
   - escena o configuracion de prueba para dos jugadores activos y al menos un rescate aliado
   - ajuste fino de valores de aceleracion, damping, empuje y danio

4. **Preparar soporte Hard sin convertirlo en requisito**
   - torso superior separado
   - rotacion independiente opt-in
   - mantener Easy como modo plenamente jugable

5. **Empezar el cierre de ronda real**
   - decidir como puntuar ring-out vs destruccion total
   - registrar muerte por explosion o por vacio
   - enlazar HUD minimo con estado de ronda en vez de solo mensajes
