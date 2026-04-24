# Decisiones

Estas son las reglas activas que hoy siguen condicionando cambios. No intentan capturar toda la historia del proyecto; solo lo que todavia bloquea o orienta trabajo actual.

## Reglas vigentes

- El modo principal del producto es score por causa; `Ultimo vivo` es variante alternativa de `FFA` pero no se expone en `setup local` hasta tener gameplay completo.
- `Ultimo vivo` debe presentarse dentro de `FFA` y usar estructura `best-of / first-to`.
- Tratar escenas hermanas `base/validation` como contratos compartidos cuando representan el mismo slice jugable.
- Endurecer fixtures y contexto de laboratorio antes de diagnosticar drift real de gameplay.
- Mantener cleanup owner-aware en el soporte post-muerte de `Teams`.
- No convertir el tuning del opening en una bateria de asserts globales; hoy el contrato tecnico es `lock -> unlock`.
- No reabrir el score por causa `2/1/4` sin evidencia nueva de playtest o medicion.
- `Ring-out` debe seguir siendo la ruta dominante; destruccion total es una via fuerte secundaria.
- `Overdrive` debe seguir siendo tactico y ocasional, no un estado permanente.
- `Easy` debe ser viable y `Hard` mas preciso; la eleccion vive por slot en `setup local`.
- `Characters` comunica identidad por personaje; `How to Play` comunica reglas generales del juego.
- `Characters` muestra rol, skill y botones como minimo; no absorbe reglas generales ni onboarding largo.
- La copy activa de roster debe salir de una sola fuente de verdad compartida entre shell, QA y tests.
- La copy activa de onboarding general debe salir de una sola fuente de verdad compartida entre shell, QA y tests.
- `Modo Practica` ya es una ruta de jugador propia y debe seguir separada del laboratorio.
- `Practica` valida sistemas reales con modulos guiados cortos + `sandbox`; no duplica copy larga que ya vive en `How to Play` o `Characters`.
- `Practica` debe usar HUD explicito por defecto y soportar `1-2` jugadores locales como primer alcance.
- Los control hints de practica deben salir de un seam comun (`RobotBase.get_control_reference_hint()` o equivalente central), no de prompts por modulo.
- El aprendizaje aplicado no se resuelve con overlays largos: shell, practica, HUD y pausa solo agregan recordatorios breves y contextuales.
- `HUD`, `pausa` y `resultados` solo deben reforzar recordatorios contextuales, no absorber onboarding completo.
- El HUD competitivo normal es contextual por defecto; el HUD explicito debe quedar disponible desde opciones y sigue siendo el default de `Practica`.
- El cierre de partida lanzado desde `player_shell` debe quedar estable: sin prompts de laboratorio y sin autorestart.
- El primer replay viable de `M10` es event-driven: snippets `Replay | tiempo/ronda/zona/causa/competidor`, no grabacion frame-by-frame ni playback fisico.
- Resultados y recap pueden explicar la decision, pero no absorben onboarding largo ni tablas completas.
- El cierre post-partida muestra como maximo tres snippets visibles y prioriza cierre de match, apoyo decisivo y primer/ultimo error de posicionamiento.
- `Teams` debe leer coordinacion, apoyo, rescates/negaciones y desgaste; `FFA` debe leer supervivencia, posiciones y desempate aunque exista fuente de baja.
- `Teams` conserva soporte post-muerte controlable como identidad propia de coordinacion y rescate.
- `FFA` no copia ese soporte: usa aftermath neutral de baja, temporal y sin control del eliminado.
- `RosterCatalog` es la fuente unica del roster competitivo visible de seis arquetipos y de su copy player-facing.
- `LocalSession` transporta por slot el `roster_entry_id` visible y el `archetype_path` runtime hasta match y practica.
- `GameShell` y `MatchLaunchConfig` son la costura comun para armar loops integrados y QA del producto real; evitar ramas paralelas que instancien `main*.tscn` directo por fuera de ese contrato.
- `Settings` global vive en `menu principal` y cubre configuracion persistente: audio, video, HUD y referencia corta de controles.
- `Settings` en pausa solo muestra y aplica opciones seguras de runtime: volumenes y HUD. Video, ventana/vsync, controles, slots, modo, mapa y variante quedan fuera de pausa.
- `setup local` vive antes del match y es la unica superficie para editar modo, mapa, variante visible, slots activos, `Easy/Hard`, teclado/joypad, perfil de teclado y joypad reservado.
- La variante visible de `setup local` queda transportada por `MatchLaunchConfig`; por ahora solo existe `Score por causa`.
- La pausa solo toca acciones seguras de runtime: reanudar, reiniciar, volver al menu cuando aplica, HUD y volumenes. No reasigna slots, no cambia `Teams/FFA`, no cambia mapa/variante y no toca video.
- La direccion de producto para pausa completa suma acceso a `Settings`, `How to Play` y `Characters` sin convertir pausa en resumen detallado de match.
- La pausa la controla quien la abrio; salir usa confirmacion simple y salida inmediata.
- El menu principal prioriza `Jugar primero`; el setup inicial solo agrega variante de modo sobre `modo + mapa + jugadores`.
- Los mapas se agrupan por rango `2-4` y `5-8`; para `5-8`, el primer objetivo es un mapa fuerte por modo.
- Los mapas grandes priorizan rutas y zonas utiles antes que distancia vacia.
- La direccion audiovisual prioriza peso industrial, feedback funcional fuerte y `1080p` fluido.
- `M9` no abre remapeo libre completo; solo referencia visible de controles, perfiles de teclado fijos y joypads con `device_id` legible.
- `LocalSessionDraft` pertenece a shell; `LocalSessionBuilder` es la unica costura para convertir specs de slots en `LocalSession` tanto en match como en practica.

## Regla documental

- La capa activa vive en `docs/` raiz y debe mantenerse corta.
- Las decisiones de producto tomadas en entrevista viven en `docs/decisiones-producto.md`.
- El detalle historico, ADRs anteriores y estructuras intermedias quedan archivados en `docs/historial/`.

## Contexto adicional

- Para el detalle anterior de ADRs y decisiones largas, revisar `docs/historial/decisiones/`.
