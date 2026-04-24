# M8 - Practica, aprendizaje y accesibilidad aplicada

## Objetivo

Cerrar la capa de aprendizaje y experimentacion aplicada que faltaba despues de `m7`:
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

## Alcance aterrizado

- `Practica` entra desde `menu principal`, `setup local` y `How to Play`.
- La primera version de producto de `Practica` se entiende como sandbox guiado para `1-2` jugadores locales.
- La shell conserva ownership claro:
  - `Characters` = identidad
  - `How to Play` = reglas base
  - `Practica` = experimentacion segura y validacion de sistemas
  - `match competitivo` = lectura, riesgo y decision bajo presion
- El runtime jugable vive en `practice_mode`, separado de `main*.tscn` y del laboratorio.
- Los modulos activos del milestone son:
  - `movimiento`
  - `impacto`
  - `energia`
  - `partes`
  - `recuperacion`
  - `sandbox`
- El HUD de practica mantiene visibles solo capas cortas y persistentes:
  - modulo
  - objetivo actual
  - progreso corto
  - controles por jugador
  - callout breve
  - pausa/contexto
  - modo explicito por defecto

## Grupos de trabajo

- `Modo Practica`
  - definir el primer alcance real: sandbox libre, drills o combinacion de ambos
  - decidir si arranca solo o tambien con soporte local para mas de un jugador
  - elegir que sistemas se validan primero sin competir con el loop principal
  - priorizar estaciones de movimiento/choque, skill y dano modular antes de capas mas amplias
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

- Evitar que practica derive otra vez en laboratorio disfrazado o reexponga metadata de QA.
- Evitar texto largo en HUD/callouts que compita con `How to Play`.
- Mantener legible la shared-screen a `1280x720` y `1920x1080`.
- Validar con playtest humano que el ritmo de modulos cortos realmente ensena sin volver la capa demasiado guiada.

## Criterio de salida

- `Modo Practica` existe como ruta real de jugador y ya no como pendiente abstracta.
- Hay runtime propio con modulos guiados + `sandbox`, sin prompts de laboratorio ni recap competitivo.
- `How to Play` y practica quedan conectados por CTA/contexto sin duplicar copy.
- Los minimos de learnability/accesibilidad quedan visibles en shell y practica, con QA automatizada.
- Queda pendiente solo el smoke manual del slice:
  - `1P Easy`
  - `1P Hard`
  - `2P mixto Easy/Hard`
  - entrada desde `How to Play`
  - volver al menu desde pausa
