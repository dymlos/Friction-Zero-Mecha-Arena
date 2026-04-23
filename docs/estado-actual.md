# Estado actual

El prototipo ya tiene una base jugable fuerte en `Teams` y `FFA` con pantalla compartida, y ahora arranca desde una shell minima de jugador en vez de entrar directo al laboratorio.

## Lo que ya existe

- Shell local jugable: `menu principal -> setup local -> match -> pausa -> volver al menu`.
- Movimiento con inercia y choques con peso.
- Dano modular por extremidad, energia y `Overdrive`.
- Partes desprendidas, recuperacion aliada, negacion rival y explosion diferida del cuerpo inutilizado.
- Primeros arquetipos, pickups de borde, presion progresiva y HUD explicito/contextual.
- Primer slice jugable de soporte post-muerte en `Teams`.
- Ruta de laboratorio separada de la ruta de jugador para QA y tuning.

## Lo que hoy esta mas validado

- Contrato de entrada `player_shell` vs `lab`, con metadata de laboratorio oculta en partidas lanzadas desde shell.
- Pausa minima accionable con owner claro, reinicio y salida segura al menu principal.
- Paridad del flujo de shell en tests scene-level y QA visual de menu, setup y overlay de pausa.
- Paridad contractual entre escenas `base` y `validation`.
- Apertura del match, presion del arena, recap, cierre y resolucion de ronda.
- Lectura superior del HUD y framing del helper post-muerte.

## Riesgos activos

- M3 sigue incompleto fuera de este slice: faltan definir superficies coherentes para settings, ayuda y resultados dentro de la arquitectura de informacion.
- La shell minima todavia necesita validacion manual de legibilidad y navegacion con mas jugadores reales, no solo coverage automatizada.
- El pacing fino del opening sigue siendo pregunta de tuning.
- La paridad `base/validation` sigue siendo el riesgo tecnico mas sensible cuando se tocan escenas o HUD.
- El soporte post-muerte `Teams` necesita mas validacion manual de legibilidad e impacto real.

## Contexto adicional

- Para detalle historico, revisar `docs/historial/estado/`.
