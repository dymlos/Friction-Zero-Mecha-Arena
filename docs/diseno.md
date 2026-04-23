# Diseno

Este documento resume la direccion activa del juego. Es una referencia viva de alto nivel: ayuda a tomar decisiones de prototipo y produccion, pero no reemplaza playtests ni congela el diseno para siempre.

## Fantasy y pilares

- La sensacion principal debe seguir siendo patinar y chocar con precision.
- El combate debe sentirse pesado, industrial y legible.
- La claridad visual es obligatoria: si una idea mejora espectaculo pero empeora lectura, pierde prioridad.
- La profundidad estrategica debe convivir con accesibilidad de party game.

## Loop jugable

- Inicio con lectura, posicionamiento y primer cruce serio.
- Midgame de desgaste, redistribucion de energia, danos por partes y decisiones de riesgo.
- Cierre con menos espacio, mas presion y colisiones mas decisivas.

## Sistemas clave

- Movimiento con arranque pesado y mejor libertad al deslizar.
- Choques con peso real y espacio para lectura del rival.
- Energia por extremidad, con redistribucion significativa pero no spammeable.
- Dano modular en brazos y piernas, con impacto real pero sin matar el comeback demasiado pronto.
- Recuperacion y negacion de partes como capa secundaria importante, siempre por detras del posicionamiento y las colisiones.

## Modos y lectura

- `FFA` debe premiar supervivencia, oportunismo y third-party sin depender de reglas pensadas para equipos.
- `Teams` debe reforzar rescates, coordinacion y presion tactica.
- La UI y el cuerpo de los robots deben explicar el estado del match con la menor cantidad posible de ruido.

## Shell y comunicacion

- `Characters` comunica identidad por personaje: rol corto, fantasy, fortaleza, riesgo, skill o pasiva clave, lectura corporal y referencia `Easy/Hard`.
- `Characters` debe reutilizar una sola fuente de verdad de copy para shell, QA y tests; no reescribir cada ficha en superficies paralelas.
- `How to Play` vive en la shell y cubre reglas generales del juego: victoria, dano modular, energia, `Overdrive`, recuperacion/negacion de partes y diferencia `Easy/Hard`.
- `How to Play` debe seguir siendo corto y escaneable: lista de temas + detalle breve, sin competir con `Characters` ni convertirse en tutorial largo.
- `HUD`, `pausa` y `resultados` solo deben reforzar recordatorios contextuales; no son la superficie principal de onboarding.
- `Modo Practica` queda como capa posterior para experimentar sistemas sin la presion del match, no como reemplazo de la ayuda base.

## Regla practica

- Cuando haya dudas, priorizar lo que preserve el fantasy central, la legibilidad y la posibilidad de validar feel rapido.
- Si hace falta mas contexto historico, revisar `docs/historial/diseno/`.
