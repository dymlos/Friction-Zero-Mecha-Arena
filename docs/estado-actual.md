# Estado actual

El prototipo ya tiene una base jugable fuerte en `Teams` y `FFA`, arranca desde una shell minima de jugador y ahora tambien ofrece una primera superficie real de comunicacion del roster con `Characters`.

## Lo que ya existe

- Shell local jugable: `menu principal -> setup local -> characters -> match -> pausa -> volver al menu`.
- Pantalla `Characters` de solo lectura accesible desde `menu principal` y `setup local`.
- Fuente unica de copy del roster base visible hoy en shell: `Ariete`, `Grua`, `Cizalla` y `Patin`.
- Movimiento con inercia y choques con peso.
- Dano modular por extremidad, energia y `Overdrive`.
- Partes desprendidas, recuperacion aliada, negacion rival y explosion diferida del cuerpo inutilizado.
- Primeros arquetipos, pickups de borde, presion progresiva y HUD explicito/contextual.
- Primer slice jugable de soporte post-muerte en `Teams`.
- Ruta de laboratorio separada de la ruta de jugador para QA y tuning.

## Lo que hoy esta mas validado

- Contrato de entrada `player_shell` vs `lab`, con metadata de laboratorio oculta en partidas lanzadas desde shell.
- Navegacion shell entre `menu`, `setup`, `characters`, `match` y `pausa`, con retorno owner-aware y restauracion de foco en `Characters`.
- Fuente unica de identidad por personaje compartida entre shell, QA y tests.
- Paridad del flujo de shell en tests scene-level y QA visual de `menu`, `setup`, `characters` y overlay de pausa.
- Paridad contractual entre escenas `base` y `validation`.
- Apertura del match, presion del arena, recap, cierre y resolucion de ronda.
- Lectura superior del HUD y framing del helper post-muerte.

## Riesgos activos

- La shell todavia necesita una superficie clara de ayuda general (`How to Play` o practica) sin duplicar la copy que ya pertenece a `Characters`.
- La shell minima todavia necesita validacion manual de legibilidad y navegacion con mas jugadores reales, no solo coverage automatizada.
- El pacing fino del opening sigue siendo pregunta de tuning.
- La paridad `base/validation` sigue siendo el riesgo tecnico mas sensible cuando se tocan escenas o HUD.
- El soporte post-muerte `Teams` necesita mas validacion manual de legibilidad e impacto real.

## Contexto adicional

- Para detalle historico, revisar `docs/historial/estado/`.
