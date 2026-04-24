# M1 - Produccion base y escalabilidad

## Objetivo

Cerrar los contratos tecnicos y de UX que condicionan todo lo demas:
- targets de jugadores
- ownership de controles
- reglas de pausa
- presupuesto de performance
- supuestos reales de shared-screen

## Matriz activa

- [M1 - Matriz de produccion base](./m1-matriz-produccion-base.md) fija la referencia `1080p`, los tiers `2-4` vs `5-8`, la politica de input/pausa y la evidencia minima para cerrar el milestone.

## Por que existe

Si estos contratos siguen abiertos, el resto del roadmap corre sobre intuicion:
- mapas mas grandes pueden nacer ya fuera de presupuesto
- menus y pausa pueden romperse con varios controles
- onboarding y prompts pueden ensear reglas equivocadas
- el polish audiovisual puede agravar cuellos de botella no diagnosticados

## Grupos de trabajo

- `Performance`
  - perfilar `720p` vs `1080p`
  - fijar baseline de hardware y frame budget
  - detectar cuellos de botella principales antes del polish
- `Multiplayer local`
  - formalizar hasta `8` jugadores locales y `4v4`
  - definir slot assignment, hot-plug y desconexion
  - priorizar primero una experiencia pulida en `2-4` antes de exigir la misma calidad a `5-8`
- `Contratos de input`
  - fijar creacion y persistencia de slots entre menus y match
  - definir ownership de pausa, reanudar y salida
  - definir estrategia de prompts por dispositivo
  - mantener `Easy` viable y `Hard` como opcion mas precisa por slot
- `Shared-screen`
  - documentar limites practicos de legibilidad para 4, 6 y 8 jugadores
  - fijar metricas de ocupacion para trabajo posterior de mapas y HUD

## Dependencias

- Ninguna como milestone de produccion.
- Debe preservar la paridad actual de escenas `base/validation`.

## Riesgos y preguntas abiertas

- `8` jugadores sigue siendo una meta de producto, no una escala ya validada.
- La legibilidad puede exigir defaults distintos para sesiones de 4 y de 8 jugadores.
- La politica de pausa queda definida por producto: controla quien pauso, salida con confirmacion simple e inmediata, sin reasignar slots ni cambiar modo.

## Criterio de salida

- Existe una matriz documentada de performance y hardware objetivo.
- Las reglas de ownership de controles y pausa quedaron explicitas.
- El trabajo de mapas puede arrancar contra objetivos reales de ocupacion y legibilidad.
- `1080p` queda como referencia principal de fluidez y estabilidad.
