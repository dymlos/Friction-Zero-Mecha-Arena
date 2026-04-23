# M7 - Integracion, optimizacion y cierre

## Objetivo

Cerrar el primer slice realista de integracion: `menu principal -> setup local -> match -> pausa -> recap/resultados` en `Teams` y `FFA`, con baseline visual auditada y diferidos explicitados.

## Por que existe

La coherencia final solo puede validarse cuando shell, mapas, roster, onboarding y presentacion ya existen juntos. Este milestone convierte piezas sueltas en un producto consistente.

## Slice cerrado en esta iteracion

- Validacion end-to-end desde `game_shell` hasta cierre de match en `Teams` base y `FFA` base.
- Cierre `player_shell` estable: recap + resultado final sin `F5` ni autorestart.
- QA integrada a `1280x720` para los dos loops completos.
- `layout audit` verde a `1280x720` y `1920x1080` para las dos escenas QA integradas y para `main.tscn` / `main_ffa.tscn`.

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

- Si no se explicita lo diferido, el roadmap vuelve a abrir scope creep.
- `1080p` no abrio un rojo nuevo en este slice; el riesgo siguiente pasa por playtests manuales y por futuras capas nuevas, no por la baseline actual.
- La validacion automatizada no reemplaza sesiones reales con varios jugadores locales.

## Diferidos explicitos

- `Modo Practica`
- replay snippets
- post-muerte `FFA`
- settings amplios
- expansion futura de roster

## Criterio de salida

- El loop integrado minimo esta documentado como coherente.
- La baseline visual integrada queda revisada a `720p/1080p`.
- Los temas diferidos quedan claros y no como promesas implicitas.
