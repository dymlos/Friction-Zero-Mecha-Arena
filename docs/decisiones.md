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
- `Modo Practica` queda como slice posterior de experimentacion segura; no debe mezclarse con la ayuda base ya resuelta en shell.
- `HUD`, `pausa` y `resultados` solo deben reforzar recordatorios contextuales, no absorber onboarding completo.

## Regla documental

- La capa activa vive en `docs/` raiz y debe mantenerse corta.
- El detalle historico, ADRs anteriores y estructuras intermedias quedan archivados en `docs/historial/`.

## Contexto adicional

- Para el detalle anterior de ADRs y decisiones largas, revisar `docs/historial/decisiones/`.
