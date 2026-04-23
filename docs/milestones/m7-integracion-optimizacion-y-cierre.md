# M7 - Integracion, optimizacion y cierre

## Objetivo

Cerrar el loop completo desde menu principal hasta final de match bajo condiciones reales de multiplayer local.

## Por que existe

La coherencia final solo puede validarse cuando shell, mapas, roster, onboarding y presentacion ya existen juntos. Este milestone convierte piezas sueltas en un producto consistente.

## Grupos de trabajo

- `Optimizacion y estabilidad`
  - revalidar `1080p`, multiplayer local y cuellos de botella con todas las capas integradas
- `Consistency pass`
  - verificar que prompts, menus, settings, HUD, `How to Play` y `Characters` cuenten la misma historia
- `Cierre de produccion`
  - dejar explicitamente diferido lo que sigue abierto, como post-muerte FFA, replay snippets y futura expansion de roster

## Dependencias

- Depende de todos los milestones anteriores.

## Riesgos y preguntas abiertas

- Si se deja toda la optimizacion para el final, puede reaparecer tarde el riesgo de `1080p`.
- Si no se explicita lo diferido, el roadmap vuelve a abrir scope creep.

## Criterio de salida

- El loop completo esta documentado como coherente.
- Los riesgos de performance y escalabilidad se revisaron con el producto mas cargado.
- Los temas diferidos quedaron claros y no como promesas implicitas.
