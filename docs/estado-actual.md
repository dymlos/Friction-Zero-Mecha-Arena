# Estado actual

El prototipo ya tiene un loop integrado revalidado desde shell hasta cierre de match en `Teams` y `FFA`. La ruta de jugador arranca en `menu principal`, pasa por `setup local`, `Characters` y `How to Play` cuando hace falta, y llega a un cierre estable de partida sin prompts de laboratorio ni reinicio automatico.

Las decisiones de producto tomadas en entrevista quedan consolidadas en `docs/decisiones-producto.md`. El estado actual de implementacion se resume aca; si una decision de producto todavia no existe en runtime, debe tratarse como direccion para futuras iteraciones y no como feature ya completada.

## Lo que ya existe

- Shell local jugable: `menu principal -> setup local -> characters/how to play -> match -> pausa -> volver al menu`.
- `menu principal` es la entrada unica a `Settings`; la pantalla persiste configuracion global de audio, video y HUD mediante `UserSettingsStore`.
- `setup local` es la autoridad de sesion antes del match: modo `Teams/FFA`, mapa, variantes de `FFA` (`Score por causa` default y `Ultimo vivo`), slots activos hasta `P8`, robot por slot, `Easy/Hard`, teclado/joypad, perfil de teclado y joypad reservado.
- `Ultimo vivo` suma rondas planas al ultimo robot en pie, sin puntos por causa, y mantiene resultados/standings FFA legibles.
- Prompts de controles usan labels por dispositivo detectado cuando Godot expone nombre de joypad, con fallback generico.
- Cierre integrado `player_shell` revalidado en `Teams` y `FFA` con recap + resultado final estables.
- Pantalla `Characters` de solo lectura accesible desde `menu principal` y `setup local`.
- Pantalla `How to Play` accesible desde `menu principal` y `setup local`, con reglas base del match y controles `Easy/Hard`.
- `Modo Practica` accesible desde `menu principal`, `setup local` y CTA contextual de `How to Play`.
- `PracticeSetup` dedicado con orden fijo de modulos, robot recomendado, temas relacionados y slots `P1/P2` usando el mismo contrato operativo de dispositivos que el setup local.
- Runtime `practice_mode` separado del laboratorio, con modulos `movimiento`, `impacto`, `energia`, `partes`, `recuperacion` y `sandbox`.
- `PracticeHud` con modulo, objetivo, progreso, controles, tarjeta contextual/callout corto y pausa, sin recap competitivo ni prompts de laboratorio.
- `Practica` queda contratada como sandbox guiado `1-2P`: todos los modulos soportan `P1/P2`, el runtime capea slots fuera del alcance y el HUD arranca explicito por defecto.
- El primer pase recomendado de practica prioriza `movimiento -> impacto -> partes -> sandbox`; `partes` usa `Cizalla/Corte` para ensenar skill aplicada sobre dano modular sin crear otro modulo.
- Pausa completa en match lanzado desde shell: acciones primarias, quick settings de `HUD/master/music/sfx`, resumen corto de dispositivos y superficies `Settings`, `How to Play` y `Characters` montadas sobre el match pausado, sin reasignar slots ni cambiar modo.
- `Settings` en pausa usa scope seguro `audio/HUD`; video, controles, slots, modo, mapa y variante quedan fuera del match congelado.
- Cierre post-partida M10: lectura compacta de decision, snippets event-driven `Replay | ...`, diferencia de enfasis `Teams/FFA` y secciones HUD dedicadas sin reemplazar el resultado principal.
- Fuente unica de copy del roster competitivo visible hoy en shell: `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla`.
- `Characters` ya distingue roster completo y foco inicial M4 (`Ariete`, `Patin`, `Cizalla`) sin convertir identidad en seleccion.
- Las fichas de roster muestran `rol`, `skill principal` y `botones` desde fuente central.
- `Cizalla` usa `Corte` como skill principal activa para abrir ventanas de desarme legibles.
- `FFA` tiene aftermath neutral propio: una recompensa temporal de baja para vivos, sin nave post-muerte ni control del eliminado.
- El delta tecnico M11 congela por tests que `Score por causa` es la variante principal de `FFA`, `Ultimo vivo` es alternativa subordinada, ambas variantes FFA usan aftermath neutral, y `PilotSupportShip`/eventos de apoyo quedan exclusivos de `Teams`.
- Rutas grandes de producto para `FFA` y `Teams` soportan hasta ocho slots; `Teams` usa asignacion inicial `P1/P3/P5/P7` vs `P2/P4/P6/P8`.
- Fuente unica de copy de onboarding general compartida entre shell, QA y tests.
- Movimiento con inercia y choques con peso.
- Dano modular por extremidad, energia y `Overdrive`.
- Partes desprendidas, recuperacion aliada, negacion rival y explosion diferida del cuerpo inutilizado.
- Primeros arquetipos, pickups de borde, presion progresiva y HUD contextual por defecto en match competitivo; HUD explicito sigue disponible desde opciones/pausa y arranca por defecto en `Practica`.
- Primer slice jugable de soporte post-muerte en `Teams`.
- Ruta de laboratorio separada de la ruta de jugador para QA y tuning.

## Lo que hoy esta mas validado

- Contrato de entrada `player_shell` vs `lab`, con metadata de laboratorio oculta en partidas lanzadas desde shell.
- `UserSettingsStore` como seam persistente de settings globales.
- `LocalSessionDraft` como seam editable de shell para slots/dispositivos.
- `LocalSessionBuilder` como seam comun para sanitizar specs y construir `LocalSession` en match y practica.
- `MatchLaunchConfig.local_slots` transporta specs completos de slot: `slot`, `control_mode`, `input_source`, `keyboard_profile`, `device_id`, `device_connected`.
- `MatchLaunchConfig.mode_variant_id` transporta `score_by_cause` o `last_alive` desde setup hasta runtime.
- `MatchLaunchConfig.local_slots` tambien transporta `roster_entry_id` y `archetype_path`; `LocalSession` aplica el arquetipo elegido al robot runtime.
- Navegacion shell entre `menu`, `setup`, `characters`, `how to play`, `match` y `pausa`, con retorno owner-aware y restauracion de foco.
- Loop integrado automatizado desde `game_shell` hasta cierre de match en:
  - `Teams` base
  - `FFA` base
  - `FFA -> Ultimo vivo`
- Cierre `player_shell` sin `Reinicio | F5`, sin autorestart y con panels de recap/resultado auditados en producto integrado.
- Contrato M7 de primer corte completo cubierto en automatizacion: entrada por shell, setup local, practica alcanzable, match competitivo, pausa completa y cierre estable siguen usando rutas de jugador sin metadata de laboratorio.
- Cierre `player_shell` con story/snippets post-match auditados: `player_shell_post_match_review_teams_1280` y `player_shell_post_match_review_ffa_1280`.
- HUD M11 compacta roster 8P y standings FFA grandes con `+N`; post-partida puede mostrar `Oportunidad | ...` cuando aftermath afecto el cierre.
- Contratos M11 delta cubiertos por tests focales: identidad de variantes, ausencia de post-muerte controlable en FFA, aftermath neutral en `score_by_cause`/`last_alive`, separacion post-partida `Oportunidad |` vs apoyo Teams y QA visual de setup/HUD/post-match.
- Matriz M1 de produccion base: `1080p` como referencia principal, `2-4` como tier pulido, `5-8` como escala soportada en validacion, y pausa owner-aware con salida confirmada.
- Delta M6 audiovisual revalidado: snapshots diegeticos de robot/arena, cues funcionales con perfiles, ducking simple de musica ante SFX clave y evidencia `1080p` especifica del pase.
- Fuente unica de identidad por personaje compartida entre shell, QA y tests.
- Contrato M4 de silueta/acento moderado, foco inicial y botones cubierto por tests scene-level y QA visual de `Characters`.
- Fuente unica de onboarding general compartida entre shell, QA y tests.
- Paridad del flujo de shell en tests scene-level y QA visual de `menu`, `setup`, `characters`, `how to play` y overlay de pausa.
- QA visual dedicada de pausa completa a `1280x720`: `main_pause_complete_settings_1280`, `main_pause_complete_how_to_play_1280` y `main_pause_complete_characters_1280`.
- Paridad contractual de `Practica` en tests scene-level, QA visual y rotacion de modulos.
- Contrato M8 delta cubierto por tests: alcance `1-2P`, HUD explicito por defecto, ruta recomendada de primer pase y estacion `partes` con skill + dano modular.
- QA integrada del loop completo a `1280x720`:
  - `player_shell_loop_teams_1280`
  - `player_shell_loop_ffa_1280`
  - `player_shell_last_alive_1280`
  - `player_shell_post_match_review_teams_1280`
  - `player_shell_post_match_review_ffa_1280`
- QA integrada de practica a `1280x720`:
  - `shell_settings_layout_1280`
  - `shell_local_setup_layout_1280`
  - `shell_practice_setup_layout_1280`
  - `practice_mode_layout_1280`
  - `practice_mode_module_rotation_1280`
- `layout audit` verde a `1280x720` y `1920x1080` para:
  - `scenes/qa/player_shell_loop_teams_validation.tscn`
  - `scenes/qa/player_shell_loop_ffa_validation.tscn`
  - `scenes/main/main.tscn`
  - `scenes/main/main_ffa.tscn`
  - `scenes/qa/shell_practice_setup_validation.tscn`
  - `scenes/qa/practice_mode_validation.tscn`
- Checklist manual pendiente de repetir sobre practica construida:
  - lanzar `Practica` desde menu principal, setup local y CTA de `How to Play`
  - probar `movimiento`, `impacto`, `energia`, `partes`, `recuperacion` y `sandbox`
  - `menu principal -> settings -> volver`
  - `setup local` con `1P`, `2P` y mezcla teclado/joypad
  - desconectar/reconectar joypad reservado
  - `1P Easy`
  - `1P Hard`
  - `2P mixto Easy/Hard`
  - lanzar `Teams`, `FFA` y `Practica`
  - abrir pausa y tocar `HUD/audio`
  - abrir `Settings`, `How to Play` y `Characters` desde pausa y volver al overlay
  - entrada desde `How to Play`
  - volver al menu desde pausa
- Paridad contractual entre escenas `base` y `validation`.
- Apertura del match, presion del arena, recap, cierre y resolucion de ronda.
- Lectura superior del HUD y framing del helper post-muerte.

## Riesgos activos

- El siguiente gap ya no es construir shell operativa, sino validar manualmente legibilidad de settings, slots/dispositivos y pausa con jugadores reales.
- La vara M7 de sesion local cerrada y clara todavia depende de smoke manual con jugadores reales; los tests prueban costuras, no ritmo humano ni descubrimiento bajo shared-screen.
- La shell extendida y practica todavia necesitan evidencia humana con mas jugadores reales; este slice cerro la baseline automatizada, no el playtest humano.
- M1 queda automatizado, pero la paridad percibida de `5-8` sigue dependiendo de playtest humano; no tratarla como experiencia igual de pulida que `2-4`.
- M11 necesita playtest humano especifico de legibilidad en `FFA 4P`, `FFA 6P/8P` y `Teams 4v4`, especialmente alrededor de aftermath, roster compacto y seleccion de `Aguja`/`Ancla`.
- El checklist manual M11 delta vive en `qa/manual/m11/competitive-modes-roster-playtest.md` y debe confirmar que nadie interpreta aftermath FFA como control del eliminado.
- El pacing fino del opening sigue siendo pregunta de tuning.
- La paridad `base/validation` sigue siendo el riesgo tecnico mas sensible cuando se tocan escenas o HUD.
- El soporte post-muerte `Teams` necesita mas validacion manual de legibilidad e impacto real.
- Aftermath FFA puede volverse demasiado valioso si cada baja fuerza una carrera automatica; los valores actuales son bajos y requieren playtest.
- `Ultimo vivo` necesita playtest humano para confirmar si el ritmo de rondas y aftermath FFA no incentivan juego excesivamente evasivo.
- La lectura post-partida M10 esta validada por tests/QA, pero todavia necesita playtest humano de ritmo de revancha y comprension en menos de 10 segundos.
- No aparecio un problema nuevo de `1080p` en este slice; la resolucion sigue siendo el checkpoint sensible para shell y practica.
- M6 queda cubierto por contratos automatizados, pero la mezcla final y la lectura audiovisual real siguen necesitando playtest humano en shared-screen con varios jugadores.

## Contexto adicional

- Para detalle historico, revisar `docs/historial/estado/`.
