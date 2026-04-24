# Proximos pasos

La siguiente iteracion recomendada debe tomar la expansion M11 como base cerrada: roster competitivo de seis, seleccion por slot, rutas grandes `FFA/Teams`, aftermath neutral FFA, HUD compacto 8P y cierre post-partida con `Oportunidad | ...` ya quedaron revalidados de forma automatizada. Lo siguiente no es ampliar configuracion ni replay, sino validar la UX con evidencia humana y corregir solo fricciones concretas.

Las decisiones de producto de la entrevista ya estan consolidadas en `docs/decisiones-producto.md`. En futuras sesiones, usar ese documento para resolver dudas de prioridad antes de abrir nuevas capas tecnicas.

## Prioridad inmediata

1. Repetir smoke manual M1 contra la matriz activa: `1P Easy`, `1P Hard`, `2P mixto Easy/Hard`, `FFA 4P`, `FFA 6P/8P` si hay controles suficientes, `Teams 4v4`, pausa owner-aware y salida confirmada.
2. Ejecutar smoke manual de shell operativa con foco en legibilidad, ritmo y descubrimiento real:
   - `menu principal -> Settings -> volver`
   - persistencia de `audio/video/HUD`
   - `setup local` con `1P`, `2P` y mezcla teclado/joypad
   - joypad reservado desconectado/reconectado
   - lanzar `Teams`, `FFA` y `Practica`
   - abrir pausa y tocar `HUD/audio`
   - `1P Easy`
   - `1P Hard`
   - `2P mixto Easy/Hard`
   - entrada desde `How to Play`
   - volver al menu desde pausa
3. Ejecutar playtest M11 enfocado:
   - `FFA 4P` con aftermath visible tras bajas tempranas.
   - `FFA 6P/8P` si hay suficientes controles, revisando roster compacto y standings `+N`.
   - `Teams 4v4`, revisando asignacion por slots y soporte post-muerte.
   - seleccion de `Aguja` y `Ancla` desde setup local antes de lanzar match.
   - lectura de `Characters` con filtros `Impacto` y `Rango / zona`.
   - cierre post-partida donde el ganador tome aftermath y aparezca `Oportunidad | ...`.
   - validar que `ring-out` siga siendo la ruta dominante y que la destruccion total se lea como segunda via fuerte.
   - validar que `Overdrive` se use como herramienta tactica ocasional y no como estado permanente.
4. Revalidar manualmente el cierre post-partida:
   - `Teams`: leer decision, `Replay | ...`, desgaste/apoyo y "como perdi" en menos de 10 segundos.
   - `FFA`: leer posiciones, desempate, supervivencia y replay sin ayuda externa.
   - repetir un cierre por explosion normal y uno con apoyo post-muerte antes del cierre.
5. Revalidar manualmente shell + practica en shared-screen con jugadores reales antes de abrir remapeo libre, video replay real o polish audiovisual.
6. Mantener ownership estricto: `setup local` = seleccion, `Characters` = identidad, `How to Play` = reglas base, `Practica` = experimentacion segura, `match` = decision tactica bajo presion.
7. Mantener la disciplina de paridad `base/validation` mientras se toque shell, practica, HUD o cierre post-partida.
8. Si se trabaja sobre `Ultimo vivo`, tratarlo como variante de `FFA` con estructura `best-of / first-to`, sin post-muerte controlable y sin score por causa.

## Diferidos explicitos de este cierre parcial

- video replay real, ghost replay, captura frame-by-frame o timeline interactivo
- soporte post-muerte controlable en `FFA`
- remapeo libre tecla por tecla o editor completo de controles
- extensiones amplias de shell fuera del contrato operativo actual
- nuevos arquetipos fuera del roster competitivo actual de seis
- mas skills por personaje antes de cerrar bien la skill principal + acciones universales
- reglas custom amplias antes de validar la sesion local clara

## Regla de sesion

- Si la sesion es documental, priorizar ownership de superficies y evitar duplicar copy entre `Characters`, `How to Play`, practica y match.
- Si la sesion es tecnica, no perder disciplina de paridad `base/validation` ni reintroducir metadata de laboratorio en la ruta de jugador.
- Si la sesion es de gameplay, no abrir polish audiovisual ni balance fino antes del smoke manual de practica y el siguiente bloque de playtests.

## Contexto adicional

- Para checkpoints anteriores, revisar `docs/historial/estado/` y `docs/historial/roadmap/`.
