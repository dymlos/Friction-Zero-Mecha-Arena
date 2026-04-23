# M10 - Cierre de match, replay y lectura post-partida

## Objetivo

Expandir el cierre del match mas alla del baseline actual:
- replay snippets
- resultados y recap mas explicativos
- mejor lectura de "como perdi" o "como ganamos"
- superficies post-partida que refuercen replayability sin saturar el loop

## Por que existe

Hoy el juego ya tiene recap y resultado final legibles, pero el cierre todavia es una version minima. El proyecto quiere que la derrota se sienta como:
- "casi lo tenia"
- "me ganaron bien"

Para eso hace falta una capa post-partida que explique mejor:
- la causa del cierre
- los momentos decisivos
- el peso del desgaste modular, pushes, rescates o errores de posicionamiento

## Grupos de trabajo

- `Recap y resultados`
  - profundizar resultados sin convertirlos en una tabla ruidosa
  - reforzar explicaciones de derrota, cierre y desempate segun modo
  - decidir que estadisticas realmente ayudan a entender el match
- `Replay snippets`
  - definir el primer formato viable de highlight o repeticion corta
  - elegir que eventos merecen snippet: baja decisiva, ring-out, explosion, clutch de rescate
  - fijar costos y limites para no comprometer claridad ni performance
- `Lectura post-partida`
  - conectar recap, resultado y futuras repeticiones en una sola historia
  - reforzar identidad distinta de `Teams` y `FFA` en el cierre
  - decidir cuanto explica texto, cuanto explica orden visual y cuanto explican clips

## Dependencias

- Depende de `M7` porque parte del loop integrado y del cierre ya estable.
- Debe respetar los contratos de presentacion de `M6`, sin convertir el cierre en un pase audiovisual descontrolado.
- Conviene apoyarse en `M9` si el cierre necesita nuevas superficies de shell o settings de visualizacion.

## Riesgos y preguntas abiertas

- Un exceso de stats o highlights puede empeorar legibilidad y ritmo de revancha.
- Los replay snippets pueden ser costosos o complejos si se intentan resolver demasiado pronto o con demasiados casos.
- El cierre puede sobredisenarse para espectador y perder utilidad inmediata para el jugador local.
- `Teams` y `FFA` probablemente necesiten enfasis distintos para explicar bien el final del match.

## Criterio de salida

- Existe una propuesta clara de cierre post-partida mas rica que el baseline de `M7`.
- El roadmap explicita que momentos, stats o snippets valen la pena y cuales no.
- La lectura de derrota o victoria mejora sin romper rapidez, claridad ni replayability.
- Replay y resultados quedan alineados con el fantasy central y con la identidad de cada modo.
