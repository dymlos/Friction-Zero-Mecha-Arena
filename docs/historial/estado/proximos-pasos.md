# Proximos pasos

Esta pagina se mantiene corta a proposito. El roadmap vivo ahora vive en `docs/roadmap/`.

## Archivo relacionado

- Roadmap vigente: `docs/roadmap/README.md`
- Milestones: `docs/roadmap/milestones/README.md`
- Estado actual: `docs/estado/actual.md`
- Decisiones vigentes: `docs/decisiones/README.md`

## Siguiente iteracion recomendada

1. Cerrar el brief de escalabilidad:
   - target de FPS
   - target hardware
   - objetivo real para `720p` y `1080p`
   - cantidad de joysticks soportados
2. Cerrar el contrato de input local:
   - ownership de slot
   - hot-plug esperado
   - que pasa si un control se desconecta
   - prompts por dispositivo
3. Cerrar el contrato de pausa:
   - quien puede pausar
   - quien puede reanudar
   - quien confirma salida de partida
4. Definir el primer target de escala de match:
   - `Teams`
   - `FFA`
   - referencia de ocupacion para mapas mas grandes
5. Definir el alcance inicial de `Modo Practica`:
   - sandbox libre
   - sandbox con objetos/sistemas
   - drills o no

## Criterio para la proxima sesion

- Si la sesion es documental, priorizar estas definiciones de producto antes de abrir mas features.
- Si la sesion es tecnica, no perder la disciplina actual de paridad `base/validation`.
- Si la sesion es de gameplay, no reabrir balance fino ni capas audiovisuales antes de fijar escalabilidad y escala de match.
