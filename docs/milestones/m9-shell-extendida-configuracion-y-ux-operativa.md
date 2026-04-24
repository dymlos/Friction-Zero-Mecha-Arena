# M9 - Shell extendida, configuracion y UX operativa

## Objetivo

Completar la profundidad pendiente de la shell despues del primer loop integrado:
- configuraciones amplias
- reglas claras de que vive en `setup`, `pausa` y `menu principal`
- UX de dispositivos y controles visible para jugadores reales
- consistencia operativa entre sesion local, match y retorno a shell

## Por que existe

`M7` cerro una shell minima jugable, pero todavia quedan abiertos varios contratos de producto:
- settings amplios
- visibilidad de remapeo o referencias de control
- UX de slots, hot-plug y dispositivos fuera del laboratorio
- criterio de que opciones se tocan antes del match y cuales durante pausa

Sin ese trabajo, la ruta de jugador sigue siendo funcional pero no suficientemente completa para sesiones locales largas o repetidas.

## Grupos de trabajo

- `Configuracion`
  - separar opciones pre-match de opciones accesibles en pausa
  - decidir superficies para audio, video, gameplay y controles
  - fijar que ajustes son globales y cuales son por sesion local
- `UX de controles y dispositivos`
  - hacer visible el estado de slots, perfiles y dispositivos sin contaminar el HUD
  - definir como se comunica hot-plug, desconexion y reconexion en la ruta de jugador
  - decidir el alcance minimo de remapeo visible o referencia de controles
- `Consistencia operativa`
  - unificar wording, foco y ownership entre shell, setup, pausa y salida segura
  - evitar que vuelvan prompts o metadata de laboratorio a superficies de jugador
  - sostener la paridad `base/validation` mientras crece la shell

## Dependencias

- Depende de `M1` por ownership local, pausa y contratos de dispositivos.
- Depende de `M7` porque extiende la shell jugable ya integrada en vez de reabrirla desde cero.
- Conviene apoyarse en el alcance de `M8` para no mezclar aprendizaje con settings operativos.

## Riesgos y preguntas abiertas

- La shell puede crecer sin criterio y terminar absorbiendo ayudas o sistemas que deberian vivir en practica.
- Un remapeo completo puede abrir mas complejidad de la que el prototipo necesita en esta etapa.
- La UX de dispositivos puede quedarse corta si comunica poco, o ensuciarse si intenta mostrar demasiado todo el tiempo.
- Cada nueva superficie de shell vuelve sensible la coherencia de foco, retorno y ownership de pausa.

## Criterio de salida

- Queda implementado y documentado que vive en `menu principal`, `Settings`, `setup local` y `pausa`.
- El jugador puede ajustar opciones operativas minimas sin depender del laboratorio:
  - `Settings`: audio, video, HUD default y referencia corta de controles.
  - `setup local`: `Teams/FFA`, slots activos, `Easy/Hard`, teclado/joypad, perfil de teclado y joypad reservado.
  - `pausa`: reanudar, reiniciar, volver al menu cuando aplica, HUD runtime y volumenes.
- `MatchLaunchConfig.local_slots` transporta specs completos y `LocalSessionBuilder` los consume tanto en match como en practica.
- La shell crece sin romper claridad, ownership de copy ni la ruta integrada cerrada en `M7`.

## Estado de implementacion

`M9` queda cubierto en automatizacion. Queda pendiente smoke manual con jugadores reales para confirmar legibilidad de settings, slots/dispositivos, hot-plug y pausa operacional.
