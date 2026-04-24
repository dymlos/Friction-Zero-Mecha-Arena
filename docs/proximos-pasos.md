# Proximos pasos

La siguiente iteracion recomendada debe tomar la expansion M11 como base cerrada: roster competitivo de seis, seleccion por slot, rutas grandes `FFA/Teams`, aftermath neutral FFA, HUD compacto 8P y cierre post-partida con `Oportunidad | ...` ya quedaron revalidados de forma automatizada. Lo siguiente no es ampliar configuracion ni replay, sino validar la UX con evidencia humana y corregir solo fricciones concretas.

Las decisiones de producto de la entrevista ya estan consolidadas en `docs/decisiones-producto.md`. En futuras sesiones, usar ese documento para resolver dudas de prioridad antes de abrir nuevas capas tecnicas.

## Prioridad inmediata

1. Repetir smoke manual M1 contra la matriz activa: `1P Easy`, `1P Hard`, `2P mixto Easy/Hard`, `FFA 4P`, `FFA 6P/8P` si hay controles suficientes, `Teams 4v4`, pausa owner-aware y salida confirmada.
2. Ejecutar smoke manual de shell operativa con foco en legibilidad, ritmo y descubrimiento real, usando `qa/manual/m7/product-cut-smoke.md` como checklist de primer corte completo:
   - `menu principal -> Settings -> volver`
   - persistencia de `audio/video/HUD`
   - `setup local` con `1P`, `2P` y mezcla teclado/joypad
   - joypad reservado desconectado/reconectado
   - lanzar `Teams`, `FFA` y `Practica`
   - abrir pausa y tocar `HUD/audio`
   - abrir desde pausa `Settings`, `How to Play` y `Characters`, volver al overlay y reanudar
   - confirmar que `Settings` en pausa solo muestra `audio/HUD`
   - probar `FFA -> Ultimo vivo`: confirmar que setup lo muestra como variante, la partida suma rondas, el resultado no menciona puntos por causa y `Score por causa` sigue siendo default
   - probar prompts con teclado y al menos un joypad: confirmar que `Settings`, setup, practica y pausa usan labels coherentes
   - `1P Easy`
   - `1P Hard`
   - `2P mixto Easy/Hard`
   - entrada desde `How to Play`
   - volver al menu desde pausa
3. Ejecutar smoke manual especifico de `Practica`:
   - Ejecutar smoke manual M8 delta: `1P Easy`, `1P Hard`, `2P mixto Easy/Hard`, ruta recomendada `movimiento -> impacto -> partes -> sandbox`, uso de `Corte` en `partes`, entrada desde `How to Play` y vuelta al menu desde pausa.
4. Ejecutar playtest M11 enfocado:
   - Usar `qa/manual/m11/competitive-modes-roster-playtest.md` como checklist especifico del delta competitivo.
   - `FFA 4P` con aftermath visible tras bajas tempranas.
   - `FFA 6P/8P` si hay suficientes controles, revisando roster compacto y standings `+N`.
   - `Teams 4v4`, revisando asignacion por slots y soporte post-muerte.
   - `FFA -> Ultimo vivo` como variante subordinada: confirmar que no desplaza `Score por causa`.
   - Confirmar que ningun jugador interpreta aftermath FFA como nave, cursor, target o control del eliminado.
   - seleccion de `Aguja` y `Ancla` desde setup local antes de lanzar match.
   - lectura de `Characters` con filtros `Impacto` y `Rango / zona`.
   - lectura de `Characters` usando `Foco inicial`: comprobar que jugadores entienden Ariete/Patin/Cizalla antes de pasar a Grua/Aguja/Ancla.
   - probar `Cizalla` en Easy y Hard: validar que `Corte` se lee como ventana activa y no como dano arbitrario.
   - cierre post-partida donde el ganador tome aftermath y aparezca `Oportunidad | ...`.
   - validar que `ring-out` siga siendo la ruta dominante y que la destruccion total se lea como segunda via fuerte.
   - validar que `Overdrive` se use como herramienta tactica ocasional y no como estado permanente.
5. Revalidar manualmente el cierre post-partida:
   - `Teams`: leer decision, `Replay | ...`, desgaste/apoyo y "como perdi" en menos de 10 segundos.
   - `FFA`: leer posiciones, desempate, supervivencia y replay sin ayuda externa.
   - repetir un cierre por explosion normal y uno con apoyo post-muerte antes del cierre.
6. Revalidar manualmente shell + practica en shared-screen con jugadores reales antes de abrir remapeo libre, video replay real o polish audiovisual.
7. Mantener ownership estricto: `setup local` = seleccion, `Characters` = identidad, `How to Play` = reglas base, `Practica` = experimentacion segura, `match` = decision tactica bajo presion.
8. Mantener la disciplina de paridad `base/validation` mientras se toque shell, practica, HUD o cierre post-partida.
9. Playtestear `Ultimo vivo` como variante de `FFA` con estructura `first-to`, sin post-muerte controlable y sin score por causa; vigilar si incentiva evasion excesiva.
10. Ejecutar playtest audiovisual M6 en `1080p`: confirmar que dano se lee desde robot, estados desde robot/arena/pickup, impactos y partes destruidas se oyen sobre musica, y la escalada final aumenta presion sin tapar SFX.

## Diferidos explicitos de este cierre parcial

- video replay real, ghost replay, captura frame-by-frame o timeline interactivo
- soporte post-muerte controlable en `FFA`
- remapeo libre tecla por tecla o editor completo de controles
- extensiones amplias de shell fuera del contrato operativo actual
- nuevos arquetipos fuera del roster competitivo actual de seis
- mas skills por personaje antes de cerrar bien la skill principal + acciones universales
- reglas custom amplias antes de validar la sesion local clara
- convertir `Ultimo vivo` en modo principal separado o darle post-muerte controlable en `FFA`
- soundtrack final, mezcla/mastering final o pipeline externo completo de audio
- postprocess visual global caro antes de nueva evidencia `1080p`

## Regla de sesion

- Si la sesion es documental, priorizar ownership de superficies y evitar duplicar copy entre `Characters`, `How to Play`, practica y match.
- Si la sesion es tecnica, no perder disciplina de paridad `base/validation` ni reintroducir metadata de laboratorio en la ruta de jugador.
- Si la sesion es de gameplay, no abrir polish audiovisual ni balance fino antes del smoke manual de practica y el siguiente bloque de playtests.

## Contexto adicional

- Para checkpoints anteriores, revisar `docs/historial/estado/` y `docs/historial/roadmap/`.
