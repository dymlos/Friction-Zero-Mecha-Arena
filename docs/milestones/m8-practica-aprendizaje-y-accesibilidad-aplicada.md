# M8 - Practica, aprendizaje y accesibilidad aplicada

## Objetivo

Cerrar la capa de aprendizaje y experimentacion que todavia falta despues de `m7`:
- `Modo Practica`
- validacion segura de sistemas
- learnability aplicada fuera del match competitivo
- accesibilidad minima util para jugar y entender mejor el prototipo

## Por que existe

La shell actual ya explica identidad y reglas base, pero el juego todavia no ofrece un espacio propio para probar:
- movimiento y choques sin presion de cierre
- energia y `Overdrive`
- dano modular, recuperacion y negacion de partes
- diferencias entre `Easy` y `Hard`

Sin esa capa, el onboarding depende demasiado de leer antes de jugar o de aprender directamente en un match competitivo.

## Grupos de trabajo

- `Modo Practica`
  - definir el primer alcance real: sandbox libre, drills o combinacion de ambos
  - decidir si arranca solo o tambien con soporte local para mas de un jugador
  - elegir que sistemas se validan primero sin competir con el loop principal
- `Aprendizaje aplicado`
  - conectar `Characters`, `How to Play` y practica sin duplicar copy
  - decidir que recordatorios viven en shell, practica y match real
  - reforzar explicaciones de `Easy/Hard`, partes, energia y recuperacion con contexto jugable
- `Accesibilidad minima`
  - fijar minimos visibles de legibilidad, contraste y dependencia de color
  - definir ayudas cortas para lectura compartida y descubrimiento de controles
  - documentar tolerancias de ruido visual y de texto en superficies de aprendizaje

## Dependencias

- Depende de `M7` porque toma como base la shell integrada, `Characters`, `How to Play` y el loop jugable ya cerrado.
- Debe preservar el ownership activo:
  - `Characters` = identidad por personaje
  - `How to Play` = reglas base
  - `Practica` = experimentacion segura y validacion de sistemas

## Riesgos y preguntas abiertas

- `Modo Practica` puede crecer demasiado si intenta resolver sandbox, tutorial, drills y multiplayer al mismo tiempo.
- Una ayuda demasiado guiada puede ir contra la fantasia de lectura, precision y decision tactica.
- Si practica duplica texto o prompts de shell, se rompe la arquitectura de informacion ya cerrada.
- La accesibilidad debe mejorar comprension y accionabilidad, no abrir una lista abstracta imposible de sostener.

## Criterio de salida

- El primer alcance de `Modo Practica` queda explicitado y justificado.
- Existe una capa de aprendizaje jugable que complementa a la shell sin reemplazar al match real.
- Los minimos de accesibilidad y learnability quedan documentados sobre superficies concretas.
- Queda claro que ensena cada capa: shell, practica y match competitivo.
