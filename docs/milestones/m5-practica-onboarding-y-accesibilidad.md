# M5 - Practica, onboarding y accesibilidad

## Objetivo

Hacer el juego mas aprendible y experimentable sin depender de la presion competitiva del match.

## Por que existe

`Modo Practica`, `How to Play` y accesibilidad forman una sola superficie de aprendizaje. Si se diseñan por separado, el juego termina explicandose de formas distintas en menu, laboratorio y match real.

## Grupos de trabajo

- `Modo Practica`
  - definir alcance inicial: sandbox, pruebas de sistemas, objetos, recuperacion y negacion
  - decidir si la primera version es solo solitaria o tambien local-multiplayer
  - decidir si incluye solo experimentacion libre o tambien drills
  - usar sandbox guiado con estaciones + tarjetas contextuales
  - soportar `1-2` jugadores locales como primer alcance
  - usar HUD explicito por defecto
- `How to Play`
  - separar reglas base del juego de conocimiento por personaje
  - minimizar bloques largos de texto cuando un esquema o callout ensena mejor
  - priorizar movimiento, victoria y combate
- `Accesibilidad y learnability`
  - fijar minimos de remapeo visible, legibilidad de texto, dependencia de color y tolerancia a ruido visual
  - documentar que ensena la shell, que ensena practica y que ensena el match
  - priorizar legibilidad visual y prompts

## Dependencias

- Depende de M3 y M4 porque necesita arquitectura de informacion e identidad de personajes mas estables.
- Debe reflejar la escala de match ya redefinida en M2.

## Riesgos y preguntas abiertas

- El alcance de practica queda orientado a jugadores + testeo interno; el riesgo ahora es no sobrecargar estaciones o callouts.
- Una ayuda demasiado textual iria contra la meta de legibilidad del juego.

## Criterio de salida

- El alcance inicial de practica queda explicitado.
- Onboarding queda dividido en capas reutilizables.
- Las expectativas minimas de accesibilidad quedan documentadas.
