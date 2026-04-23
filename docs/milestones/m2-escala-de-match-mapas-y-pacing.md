# M2 - Escala de match, mapas y pacing

## Objetivo

Redefinir la escala jugable del match para que mapas mas grandes agreguen decisiones tacticas, no solo tiempo muerto.

## Por que existe

`Hacer mapas casi el doble` no sirve como objetivo aislado. En este proyecto la escala afecta:
- camara y legibilidad
- tiempo al primer engagement
- valor del borde y de los pickups
- rescates y recuperacion de partes
- timing de presion final
- densidad de match para `FFA` y `Teams`

## Grupos de trabajo

- `Espacio jugable`
  - revisar tamano, traversal time y footprint de combate juntos
  - redefinir rutas, flanqueo, escondites y cobertura
  - validar valor del borde y variedad de rutas
- `Pacing`
  - ajustar spacing inicial, opening y safe-area reduction a la nueva escala
  - preservar apertura balanceada, lectura, escalada y cierre explosivo
- `Necesidades por modo`
  - garantizar oportunismo y third-party en `FFA`
  - preservar rescates, pushes coordinados y recuperacion en `Teams`
  - revisar si el soporte post-muerte sigue funcionando con el nuevo tamano

## Dependencias

- Depende de M1 porque la nueva escala debe respetar restricciones reales de performance, input y shared-screen.

## Riesgos y preguntas abiertas

- El mapa grande puede debilitar la fantasia de colision si el viaje domina al combate.
- Mas cobertura puede romper legibilidad o generar micro-fortalezas.
- `8` jugadores puede requerir variantes de mapa y no una unica receta universal.

## Criterio de salida

- Hay guias documentadas de escala jugable.
- Existe al menos un target claro de mapa grande para `Teams` y otro para `FFA`.
- Las implicancias de pacing quedaron claras antes del polish visual.
