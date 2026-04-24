# M7 - Smoke manual de primer corte completo

## Objetivo

Medir si el primer corte completo se siente como una sesion local cerrada y clara: entrar, configurar, jugar, pausar, practicar y cerrar sin huecos grandes.

Este checklist no reemplaza los tests automatizados. Captura lectura humana, ritmo, friccion de controles y comprension compartida en pantalla.

## Preparacion

- Resolucion principal: `1920x1080`.
- Resolucion secundaria si hay tiempo: `1280x720`.
- Jugadores minimos: `1P` y `2P`.
- Jugadores recomendados: `4P` para `FFA 4P` y `Teams 2v2`.
- Jugadores extendidos si hay controles: `FFA 6P/8P` y `Teams 4v4`.
- HUD competitivo: contextual por defecto.
- HUD practica: explicito por defecto.
- No usar laboratorio, escenas directas ni atajos de debug como ruta principal.

## Rutas obligatorias

### 1. Entrada y settings global

- [ ] Abrir `menu principal`.
- [ ] Confirmar que `Jugar` es la accion principal mas evidente.
- [ ] Entrar a `Settings` desde menu principal.
- [ ] Cambiar volumen master, musica y SFX; confirmar que se perciben y persisten al volver.
- [ ] Revisar video/HUD/referencia de controles sin buscar opciones escondidas.
- [ ] Volver al menu principal y confirmar foco/restauracion sin perder contexto.

Resultado esperado:
- El jugador entiende donde configurar lo basico sin leer documentacion externa.
- No aparecen prompts de laboratorio.
- La pantalla no se siente como una lista tecnica.

### 2. Setup local y dispositivos

- [ ] Entrar a `setup local`.
- [ ] Probar `1P Easy` con teclado.
- [ ] Probar `1P Hard` con teclado.
- [ ] Probar `2P mixto Easy/Hard`.
- [ ] Si hay joypad, reservarlo para un slot y confirmar que el slot lo comunica.
- [ ] Si hay joypad, desconectar/reconectar y anotar si la lectura del slot sigue siendo clara.
- [ ] Cambiar modo `Teams`/`FFA`.
- [ ] Confirmar que la variante default en `FFA` es `Score por causa`.
- [ ] Ciclar a `Ultimo vivo`, confirmar que se lee como variante de `FFA` y volver a `Score por causa` para el loop principal.
- [ ] Confirmar que la seleccion de robot vive por slot y no en `Characters`.
- [ ] Lanzar `Teams` desde setup.
- [ ] Volver al menu y lanzar `FFA` desde setup.

Resultado esperado:
- `Easy` se siente viable y `Hard` se entiende como opcion mas precisa.
- El setup no intenta editar settings amplios que pertenecen a `Settings`.
- `Ultimo vivo` se entiende como variante subordinada de `FFA`, no como modo principal.

### 3. Match competitivo

- [ ] En `Teams`, jugar hasta un cierre por `ring-out`.
- [ ] En `FFA`, jugar hasta un cierre por `ring-out`.
- [ ] Durante ambos matches, confirmar que el borde sigue siendo la ruta dominante.
- [ ] Confirmar que dano modular se lee como segunda via fuerte, no como condicion confusa.
- [ ] Confirmar que `Overdrive` se percibe tactico/ocasional, no permanente.
- [ ] Confirmar que HUD normal no tapa lectura de robots, borde ni pickups.
- [ ] Confirmar que no aparecen `Lab |`, `HUD | F1`, `Reinicio | F5` ni prompts de laboratorio.

Resultado esperado:
- El match se entiende por movimiento, choque, borde y estado corporal.
- La pantalla permite seguir causa de eliminacion sin explicar reglas en voz alta.

### 4. Pausa completa

- [ ] Abrir pausa con P1.
- [ ] Confirmar que solo P1 controla la pausa.
- [ ] Entrar a `Settings` desde pausa.
- [ ] Confirmar que pausa solo permite audio/HUD seguro, no video, slots, modo, mapa ni variante.
- [ ] Volver al overlay de pausa.
- [ ] Entrar a `How to Play` desde pausa.
- [ ] Volver al overlay de pausa.
- [ ] Entrar a `Characters` desde pausa.
- [ ] Volver al overlay de pausa.
- [ ] Reanudar.
- [ ] Abrir pausa y elegir `Volver al menu`.
- [ ] Confirmar que hay confirmacion simple y salida inmediata al aceptar.

Resultado esperado:
- Pausa ayuda sin convertirse en setup secundario.
- No reasigna slots ni cambia modo/mapa.
- La salida a menu se entiende y no requiere una secuencia ambigua.

### 5. Practica

- [ ] Lanzar `Practica` desde menu principal.
- [ ] Lanzar `Practica` desde `setup local`.
- [ ] Lanzar `Practica` desde CTA contextual de `How to Play`.
- [ ] Probar modulo `movimiento`.
- [ ] Probar modulo `impacto`.
- [ ] Probar modulo `energia`.
- [ ] Probar modulo `partes`.
- [ ] Probar modulo `recuperacion`.
- [ ] Probar modulo `sandbox`.
- [ ] Repetir `1P Easy`.
- [ ] Repetir `1P Hard`.
- [ ] Repetir `2P mixto Easy/Hard`.
- [ ] Confirmar que HUD explicito, prompts y tarjetas se leen a distancia shared-screen.
- [ ] Abrir pausa de practica, reanudar y volver al menu.

Resultado esperado:
- `Practica` se siente como experimentacion segura, no laboratorio ni tutorial largo.
- Las tarjetas son cortas y no duplican `How to Play`.
- La salida de practica no rompe la ruta de jugador.

### 6. Cierre post-partida baseline

- [ ] Leer en `Teams` decision, causa y resumen final en menos de 10 segundos.
- [ ] Leer en `FFA` posiciones/desempate/supervivencia en menos de 10 segundos.
- [ ] Confirmar que el cierre no autoreinicia.
- [ ] Confirmar que el cierre permite decidir salir o repetir sin prompts de laboratorio.
- [ ] Si aparece `Replay | ...`, anotarlo como cobertura M10 ya integrada, no como obligacion baseline de M7 viejo.

Resultado esperado:
- La derrota se entiende como "casi lo tenia" o "me ganaron bien".
- El resultado principal no queda enterrado bajo stats o texto largo.

## Registro de sesion

- Fecha:
- Build/commit:
- Resolucion:
- Jugadores:
- Controles disponibles:
- Rutas completadas:
- Rutas omitidas y motivo:
- Fricciones de setup/dispositivos:
- Fricciones de lectura en match:
- Fricciones de pausa/salida:
- Fricciones de practica:
- Tiempo aproximado hasta entender el cierre:
- Decision:
  - [ ] Verde: baseline M7 lista para seguir.
  - [ ] Amarillo: corregir fricciones concretas sin abrir scope.
  - [ ] Rojo: bloquear nuevas capas hasta corregir loop local.

## Reglas de interpretacion

- Un fallo de legibilidad humana pesa mas que un PASS automatizado.
- No convertir feedback de playtest en nuevas features sin separar milestone.
- Si el problema es `Practica`, revisar contra M8.
- Si el problema es settings/dispositivos, revisar contra M9.
- Si el problema es recap/replay, revisar contra M10.
- Si el problema es roster, aftermath, `FFA` grande o `Teams 4v4`, revisar contra M11.
