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
- El modo principal usa score por causa; `ring-out` debe ser la ruta dominante y la destruccion modular total funciona como segunda via fuerte.
- `Ultimo vivo` existe como direccion de variante alternativa de `FFA`, con estructura `best-of / first-to` y sin score por causa; no debe exponerse en la shell hasta tener gameplay completo.

## Sistemas clave

- Movimiento con arranque pesado y mejor libertad al deslizar.
- Choques con peso real y espacio para lectura del rival.
- Energia por extremidad, con redistribucion significativa pero no spammeable.
- `Overdrive` debe ser una herramienta tactica ocasional, fuerte y riesgosa, no una capa permanente.
- Dano modular en brazos y piernas, con impacto real pero sin matar el comeback demasiado pronto.
- Recuperacion y negacion de partes como capa secundaria importante, siempre por detras del posicionamiento y las colisiones.
- Cada personaje arranca con una skill principal y acciones universales. Mas skills por personaje quedan para una etapa posterior.

## Modos y lectura

- `FFA` debe premiar supervivencia, oportunismo y third-party sin depender de reglas pensadas para equipos.
- `FFA` no usa nave post-muerte controlable. Su capa propia de post-baja es aftermath neutral: una recompensa temporal cerca de la baja que solo pueden tomar robots vivos y que refuerza oportunismo sin devolver control ofensivo al eliminado.
- `Teams` debe reforzar rescates, coordinacion y presion tactica.
- La UI y el cuerpo de los robots deben explicar el estado del match con la menor cantidad posible de ruido.
- Los mapas se organizan por rangos `2-4` y `5-8`; la experiencia mas pulida se valida primero en `2-4`.
- Los mapas mas grandes deben priorizar rutas y zonas utiles antes que distancia vacia.
- La filosofia espacial activa es borde fuerte y peligroso con centro de transicion.
- `FFA` y `Teams` comparten familia de mapa con variantes: `FFA` prioriza rotacion/third-party y `Teams` rescate/coordinacion lateral.

## Shell y comunicacion

- `Characters` comunica identidad por personaje: rol corto, fantasy, fortaleza, riesgo, skill o pasiva clave, lectura corporal y referencia `Easy/Hard`.
- En la primera version de producto, `Characters` debe mostrar como minimo rol, skill y botones.
- `Characters` debe reutilizar una sola fuente de verdad de copy para shell, QA y tests; no reescribir cada ficha en superficies paralelas.
- El roster competitivo visible son seis arquetipos: `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla`.
- El primer foco de cierre y ensenanza del roster es `Pusher/Tank`, `Mobility/Reposition` y `Dismantler`.
- La diferenciacion visual debe ser de silueta/acento moderado: suficiente para leer rapido sin romper la familia industrial comun.
- La seleccion de robot vive en `setup local` por slot; `Characters` mantiene ownership de identidad y lectura, no de seleccion.
- `How to Play` vive en la shell y cubre reglas generales del juego: victoria, dano modular, energia, `Overdrive`, recuperacion/negacion de partes y diferencia `Easy/Hard`.
- `How to Play` debe seguir siendo corto y escaneable: lista de temas + detalle breve, sin competir con `Characters` ni convertirse en tutorial largo.
- `How to Play` prioriza movimiento, victoria y combate; la practica refuerza esa base con estaciones.
- `Modo Practica` es la capa de experimentacion segura y validacion de sistemas: conecta `How to Play` con juego real sin duplicar parrafos ni reemplazar al match.
- `Practica` debe ensenar "como se siente" cada sistema con estaciones, tarjetas contextuales y `sandbox`; las reglas base siguen viviendo en `How to Play`.
- La primera version de practica soporta `1-2` jugadores locales y usa HUD explicito por defecto.
- El match competitivo sigue siendo la capa de lectura bajo presion, decision tactica y consecuencias reales.
- `HUD`, `pausa` y `resultados` solo deben reforzar recordatorios contextuales; no son la superficie principal de onboarding.
- El HUD normal del juego es contextual por defecto; el HUD explicito debe poder activarse desde opciones.

## Shell, presentacion y corte completo

- El menu principal prioriza entrar a jugar.
- `setup local` cubre modo, mapa, jugadores y variante de modo. Hoy expone `Score por causa`; `Ultimo vivo` solo se presentara como variante dentro de `FFA` cuando tenga reglas completas.
- `Settings` cubre video, audio y controles como minimo.
- La pausa completa debe incluir `Settings`, `How to Play` y `Characters`, controlada por quien la abrio, sin reasignar slots ni cambiar modo.
- La salida desde pausa usa confirmacion simple y salida inmediata.
- La post-partida del primer corte completo debe ser resumen claro + stats simples.
- La vara del primer corte completo es una sesion local cerrada y clara: entrar, configurar, jugar, pausar, practicar y cerrar sin huecos grandes.
- La direccion audiovisual prioriza peso industrial, feedback funcional fuerte y musica que acompana sin tapar.
- `1080p` es la referencia principal de fluidez y estabilidad.

## Regla practica

- Cuando haya dudas, priorizar lo que preserve el fantasy central, la legibilidad y la posibilidad de validar feel rapido.
- Si hace falta mas contexto historico, revisar `docs/historial/diseno/`.
