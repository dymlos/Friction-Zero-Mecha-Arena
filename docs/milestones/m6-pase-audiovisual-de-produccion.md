# M6 - Pase audiovisual de produccion

## Objetivo

Subir la calidad de presentacion sin romper peso, feedback ni legibilidad.

## Por que existe

`Graficos`, `sonido` y `musica` comparten la percepcion final del juego. Conviene tratarlos como un pase coordinado que refuerce gameplay y UX en vez de empujar polish aislado.

## Grupos de trabajo

- `Visual`
  - mejorar presentacion de arenas, menus y robots
  - reforzar legibilidad de dano, materiales y efectos
- `Audio`
  - definir feedback para colisiones, dano modular, pickups, recuperacion, negacion y cambios de estado
- `Musica`
  - definir comportamiento musical para menu, match, presion final, pausa y resultados

## Dependencias

- Depende de M2 a M5 porque debe reforzar pacing, shell, onboarding y lectura ya acordados.
- No debe arrancar como gran pase hasta entender la baseline de `1080p` fijada en M1.

## Riesgos y preguntas abiertas

- El polish visual puede dañar la legibilidad en shared-screen con muchos jugadores.
- La capa de audio puede crecer mas rapido que el modelo real de eventos del juego.
- La direccion musical debe seguir pacing comprobado, no pacing imaginado.

## Criterio de salida

- El plan audiovisual esta conectado a superficies concretas de gameplay y UX.
- La legibilidad sigue siendo la regla principal durante el polish.
