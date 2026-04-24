# M4 - Identidad de roster y comunicacion

## Objetivo

Hacer que cada personaje se reconozca rapido, se sienta distinto y siga perteneciendo a la misma familia industrial.

## Por que existe

La diferenciacion visual, la identidad jugable y la forma de explicar personajes no pueden evolucionar por separado. Si cada superficie cuenta algo distinto, el roster se vuelve mas dificil de aprender y de leer en match.

## Grupos de trabajo

- `Identidad visual`
  - definir silueta, acentos, color y marcadores de lectura por arquetipo
  - conservar una familia robotica coherente
  - usar diferenciacion de silueta/acento moderado como primer objetivo
- `Legibilidad jugable`
  - alinear el look con fortalezas, riesgos y rol del personaje
  - priorizar lectura desde el cuerpo y no solo desde el HUD
  - cerrar primero `Pusher/Tank`, `Mobility/Reposition` y `Dismantler` como arquetipos mas ensenables
- `Comunicacion al jugador`
  - definir la estructura de `Characters`
  - decidir que se comunica con texto, iconos, prompts contextuales y futuros clips
  - fijar como se explica mapping de joystick, fortalezas y acciones unicas
  - mostrar como minimo rol, skill y botones

## Dependencias

- Depende de M3 porque necesita una shell clara donde vivir.
- Conviene evaluarlo sobre la escala de mapa definida en M2.

## Riesgos y preguntas abiertas

- Demasiada variacion puede romper la fantasia de familia comun.
- Muy poca variacion puede volver ilegibles los matches de muchos jugadores.
- Si el roster cambia mucho, una documentacion excesivamente textual se vuelve costosa de mantener.
- Mas skills por personaje quedan diferidas; la primera capa usa una skill principal + acciones universales.

## Criterio de salida

- Las reglas de identidad del roster quedaron documentadas.
- Quedo resuelto como se comunica cada personaje al jugador.
- Las decisiones entre texto, iconografia y refuerzo in-game son explicitas.
