# M10 - Cierre de match, replay y lectura post-partida

## Objetivo

Expandir el cierre del match mas alla del baseline actual:
- replay snippets
- resultados y recap mas explicativos
- mejor lectura de "como perdi" o "como ganamos"
- superficies post-partida que refuercen replayability sin saturar el loop
- sostener como base de producto un resumen claro + stats simples

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
  - implementado: resultado y recap agregan `Lectura | ...`, `Como perdiste | ...` y conservan stats existentes sin tabla nueva
  - implementado: `Teams` prioriza equipo/cierre/desgaste/apoyo; `FFA` prioriza supervivencia, posiciones y desempate
  - limite activo: el resultado base de cuatro jugadores no debe superar el presupuesto visual de 22 lineas
- `Replay snippets`
  - implementado: primer formato viable event-driven, no video
  - valen la pena: cierre de match, baja decisiva, ring-out, destruccion total, explosion inestable, apoyo decisivo y errores de posicionamiento temprano/final
  - descartado para este milestone: grabacion frame-by-frame, timeline interactivo, guardado entre sesiones y metricas largas
- `Lectura post-partida`
  - implementado: `MatchController` captura eventos y `PostMatchReview` arma historia/snippets sin decidir reglas de match
  - implementado: `MatchHud` expone story/snippets/hint con QA ids dedicados y mantiene `MatchResultLabel`
  - pendiente humano: confirmar que jugadores entienden "como perdi" y si quieren revancha sin friccion

## Dependencias

- Depende de `M7` porque parte del loop integrado y del cierre ya estable.
- Debe respetar los contratos de presentacion de `M6`, sin convertir el cierre en un pase audiovisual descontrolado.
- Conviene apoyarse en `M9` si el cierre necesita nuevas superficies de shell o settings de visualizacion.

## Riesgos y preguntas abiertas

- Un exceso de stats o highlights sigue siendo riesgo; por eso M10 limita snippets y poda ruido antes que agregar mas metricas.
- Video replay real queda como investigacion futura, no como gap de M10.
- Falta playtest humano para medir comprension y ritmo de revancha.
- `Teams` y `FFA` ya tienen enfasis distintos en texto; falta validar si esos enfasis se leen igual de bien en shared-screen.
- La post-partida no debe reemplazar `How to Play`, ni transformarse en tabla extensa.

## Criterio de salida

- Cumplido: existe cierre post-partida mas rico que el baseline de `M7`, con lectura compacta, snippets event-driven y secciones HUD auditadas.
- Cumplido: el roadmap explicita que momentos valen la pena y deja video replay/timeline fuera de M10.
- Cumplido en automatizacion: tests scene-level y QA visual cubren resultado, recap, snippets, causa, ruido y `player_shell`.
- Pendiente de producto: playtest humano de lectura y ritmo de revancha.
