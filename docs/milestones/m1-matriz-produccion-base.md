# M1 - Matriz de produccion base

Esta matriz cierra los contratos de produccion base que condicionan mapas, HUD, shell y pase audiovisual. Es activa, corta y debe actualizarse solo cuando haya nueva evidencia de QA o playtest.

## Referencia de performance

| Resolucion | Rol | Target | Presupuesto | Uso |
| --- | --- | --- | --- | --- |
| `1920x1080` | referencia principal | `60 fps` | `16.7 ms/frame`, warning sobre `20 ms` | decidir fluidez y estabilidad |
| `1280x720` | comparacion secundaria | `60 fps` | `16.7 ms/frame`, warning sobre `20 ms` | detectar regresiones simples y layouts chicos |

`1080p` manda sobre `720p` cuando haya conflicto de prioridad. El probe headless sirve como alarma reproducible; la decision final de fluidez necesita una corrida visible en hardware objetivo.

## Escala local

| Jugadores | Estado de producto | Contrato |
| --- | --- | --- |
| `1-2` | practica y smoke operativo | debe ser claro, estable y rapido de leer |
| `2-4` | experiencia pulida prioritaria | setup, pausa, HUD y cierre no deben requerir explicacion externa |
| `5-8` | escala soportada en validacion | puede usar HUD compacto y defaults distintos; requiere playtest humano antes de prometer paridad |
| `Teams 4v4` | meta soportada | asignacion por slots impares vs pares, lectura de coordinacion y soporte post-muerte |

## Input y pausa

- `setup local` es la unica superficie que edita modo, slots, `Easy/Hard`, teclado/joypad, perfil de teclado y joypad reservado.
- `Easy` debe ser viable por slot; `Hard` agrega precision, no es requisito para jugar bien.
- Si un joypad se desconecta, el slot queda reservado y no se reasigna automaticamente.
- La pausa la controla quien la abrio.
- No-owner no reanuda, no reinicia, no cambia quick settings y no confirma salida.
- Salir desde pausa usa confirmacion simple y vuelve inmediatamente al menu principal.
- Pausa no reasigna slots, no cambia `Teams/FFA` y no toca video.

## Legibilidad shared-screen

| Caso | HUD | Standings | Riesgo |
| --- | --- | --- | --- |
| `FFA/Teams 2-4` | puede mostrar mas detalle contextual o explicito | visible sin compactar agresivamente | lectura de estado durante colision |
| `FFA/Teams 5-8` | roster compacto, lineas cortas, device summary solo en pausa | compactar resto con `+N` | demasiados actores simultaneos y edge value |

## Evidencia requerida para cerrar M1

- Tests M1 de escala, `Easy/Hard`, pausa owner/salida y perf probe en verde.
- `godot-qa` verde en shell/setup/pausa y loops `2-4` a `1280x720` y `1920x1080`.
- `godot-qa` verde en loops `8P` a `1280x720` y `1920x1080`, con nota de que es soporte en validacion.
- Matriz de performance generada para `Teams/FFA 4P` y `Teams/FFA 8P` a `1080p`.
- Smoke manual con jugadores reales para `1P Easy`, `1P Hard`, `2P mixto`, `FFA 4P`, `FFA 6P/8P` y `Teams 4v4`.
