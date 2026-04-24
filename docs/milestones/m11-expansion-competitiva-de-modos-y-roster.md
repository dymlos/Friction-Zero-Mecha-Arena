# M11 - Expansion competitiva de modos y roster

## Objetivo

Abrir la siguiente capa de crecimiento competitivo del proyecto sin perder legibilidad:
- resolver la expansion futura de `FFA` sin sumar post-muerte controlable
- ampliar roster y comunicacion de personajes
- sostener identidad clara por modo y por arquetipo mientras crece el contenido

## Por que existe

Despues de `M7`, el roadmap ya dejo diferidos dos frentes grandes:
- crecimiento propio de `FFA` sin copiar soporte post-muerte de `Teams`
- expansion futura de roster

Ademas, los milestones anteriores solo cerraron un primer slice de shell, comunicacion e identidad. Antes de sumar mas personajes o reglas por modo, hace falta decidir como crecer sin:
- copiar la solucion de `Teams` dentro de `FFA`
- diluir la lectura del roster
- inflar `Characters`, shell y resultados con informacion imposible de sostener

## Grupos de trabajo

- `Expansion de modos`
  - mantener `FFA` sin nave ni post-muerte controlable
  - presentar `Ultimo vivo` como variante alternativa dentro de `FFA`
  - preservar supervivencia, oportunismo y third-party como identidad del modo
  - revisar como impacta cualquier expansion en pacing, cierre y lectura del shared-screen
- `Expansion de roster`
  - definir cuando y como entran personajes nuevos a superficies jugables reales
  - reforzar reglas de familia visual comun y diferenciacion por arquetipo
  - evitar que el roster crezca mas rapido que su comunicacion y lectura in-match
- `Comunicacion futura`
  - ampliar `Characters` y otras superficies sin reescribir copy en paralelo
  - decidir cuando hacen falta clips, iconografia o comparaciones adicionales
  - mantener consistencia entre shell, match y post-partida para roster y modos expandidos

## Dependencias

- Depende de `M2` y `M7` porque cualquier expansion debe respetar escala jugable, claridad integrada y baseline de producto.
- Conviene apoyarse en `M8`, `M9` y `M10` para no sumar contenido nuevo sobre una capa de aprendizaje, shell o cierre todavia incompleta.
- Debe preservar las identidades activas:
  - `FFA` = supervivencia, oportunismo y third-party
  - `Teams` = coordinacion, rescates y presion tactica

## Riesgos y preguntas abiertas

- Copiar soporte post-muerte de `Teams` a `FFA` puede romper la identidad del modo y su lectura.
- `Ultimo vivo` debe seguir subordinado al modo principal por puntos, no desplazarlo.
- Un roster mas grande puede exigir nuevas reglas de presentacion, orden y seleccion antes de ser honesto para la shell.
- Mas personajes o sistemas por modo pueden degradar shared-screen, onboarding y claridad visual.
- La comunicacion puede quedarse demasiado textual si el roster y los cierres crecen sin una estrategia comun.

## Criterio de salida

- Cumplido: `FFA` crece con aftermath neutral de baja, sin nave post-muerte controlable ni control ofensivo del eliminado.
- Cumplido: el roster competitivo visible queda en seis arquetipos (`Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja`, `Ancla`) con `RosterCatalog` como fuente unica.
- Cumplido: `setup local` selecciona robot por slot y transporta `roster_entry_id`/`archetype_path` hasta match y practica.
- Cumplido: existen rutas grandes de producto para `FFA` y `Teams` 8P, separadas de escenas `_validation`.
- Cumplido: `Characters`, HUD y post-partida comunican roster/aftermath con lineas breves y sin duplicar onboarding.
- Cumplido: tests scene-level y escenarios `godot-qa` de cierre M11 pasaron en la implementacion.
- Pendiente humano: playtest de legibilidad real en `FFA 4P`, `FFA 6P/8P` y `Teams 4v4`.
