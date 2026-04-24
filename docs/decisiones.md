# Decisiones

Estas son las reglas activas que hoy siguen condicionando cambios. No intentan capturar toda la historia del proyecto; solo lo que todavia bloquea o orienta trabajo actual.

## Reglas vigentes

- Tratar escenas hermanas `base/validation` como contratos compartidos cuando representan el mismo slice jugable.
- Endurecer fixtures y contexto de laboratorio antes de diagnosticar drift real de gameplay.
- Mantener cleanup owner-aware en el soporte post-muerte de `Teams`.
- No convertir el tuning del opening en una bateria de asserts globales; hoy el contrato tecnico es `lock -> unlock`.
- No reabrir el score por causa `2/1/4` sin evidencia nueva de playtest o medicion.
- `Characters` comunica identidad por personaje; `How to Play` comunica reglas generales del juego.
- La copy activa de roster debe salir de una sola fuente de verdad compartida entre shell, QA y tests.
- La copy activa de onboarding general debe salir de una sola fuente de verdad compartida entre shell, QA y tests.
- `Modo Practica` ya es una ruta de jugador propia y debe seguir separada del laboratorio.
- `Practica` valida sistemas reales con modulos guiados cortos + `sandbox`; no duplica copy larga que ya vive en `How to Play` o `Characters`.
- Los control hints de practica deben salir de un seam comun (`RobotBase.get_control_reference_hint()` o equivalente central), no de prompts por modulo.
- El aprendizaje aplicado no se resuelve con overlays largos: shell, practica, HUD y pausa solo agregan recordatorios breves y contextuales.
- `HUD`, `pausa` y `resultados` solo deben reforzar recordatorios contextuales, no absorber onboarding completo.
- El cierre de partida lanzado desde `player_shell` debe quedar estable: sin prompts de laboratorio y sin autorestart.
- `GameShell` y `MatchLaunchConfig` son la costura comun para armar loops integrados y QA del producto real; evitar ramas paralelas que instancien `main*.tscn` directo por fuera de ese contrato.

## Regla documental

- La capa activa vive en `docs/` raiz y debe mantenerse corta.
- El detalle historico, ADRs anteriores y estructuras intermedias quedan archivados en `docs/historial/`.

## Contexto adicional

- Para el detalle anterior de ADRs y decisiones largas, revisar `docs/historial/decisiones/`.
