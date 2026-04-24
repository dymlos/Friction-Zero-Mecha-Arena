# Decisiones de producto

Este documento consolida las decisiones tomadas en entrevista de diseno. Sirve como referencia activa para producto, UX y roadmap. Cuando choque con implementacion actual, tratarlo como direccion de producto y revisar `estado-actual.md` para saber que ya existe.

## Modos y victoria

- El modo principal usa `puntos por causa`.
- El perfil vigente de score por causa sigue siendo `ring-out = 2`, `destruccion total = 1` y `explosion inestable = 4` hasta que un playtest justifique cambiarlo.
- `Ring-out` debe ser la ruta dominante en la practica: el borde sigue siendo el corazon emocional del juego.
- La destruccion modular total es una segunda via fuerte, importante y legible, pero menos frecuente que expulsar por borde.
- `Ultimo vivo` existe como variante alternativa dentro de `FFA`, no como modo principal separado.
- La primera version de `Ultimo vivo` debe usar estructura `best-of / first-to`, sin score por causa.
- `FFA` no usa post-muerte controlable. Si existe aftermath, debe ser neutral, temporal y solo para robots vivos; no devuelve control ofensivo al eliminado.
- `Teams` conserva soporte post-muerte controlable como identidad propia de coordinacion, rescate y comeback.

## Combate y sistemas

- El nucleo ensenable del combate es `movimiento + choque + skill principal + dano modular`.
- La siguiente capa tactica prioritaria es `energia y Overdrive`.
- `Overdrive` debe ser una herramienta tactica ocasional: importante cuando aparece, pero no permanente ni siempre correcta.
- Rescate, partes e items son sistemas valiosos, pero no deben desplazar al posicionamiento, al choque ni al borde como lectura principal.
- Cada personaje empieza con `una skill principal + acciones universales`.
- Mas skills por personaje quedan diferidas para una etapa posterior.

## Controles y jugadores

- `Easy` debe ser viable.
- `Hard` debe ser mas preciso, no una condicion obligatoria para jugar bien.
- `Easy/Hard` se elige por jugador en `setup local` antes de la partida.
- El objetivo de producto soporta hasta `8` jugadores locales y `4v4`.
- La experiencia mas pulida debe cerrarse primero en el rango `2-4` jugadores antes de exigir el mismo nivel en `5-8`.
- Los prompts deben responder al dispositivo detectado por slot siempre que sea posible.

## Mapas y escala

- Los mapas se agrupan por rango de jugadores: `2-4` y `5-8`.
- La prioridad de mapas mas grandes es agregar mas rutas y zonas utiles.
- La distancia mayor es secundaria: deseable solo si no introduce tiempo muerto.
- La filosofia espacial prioriza bordes fuertes con centro de transicion.
- La primera familia de mapas mas pulida debe reforzar borde valioso y peligroso.
- `FFA` y `Teams` comparten familia visual/espacial con variantes por modo.
- Para `5-8`, el primer objetivo de contenido es `1 mapa fuerte por modo`.
- El primer mapa grande de `FFA` debe priorizar rotacion y third-party.
- El primer mapa grande de `Teams` debe priorizar rescate y coordinacion lateral.

## Roster y personajes

- El roster base de producto se organiza alrededor de `6 arquetipos`.
- Los seis arquetipos visibles actuales son `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla`.
- El primer foco de cierre y ensenanza debe ser `Pusher/Tank`, `Mobility/Reposition` y `Dismantler`.
- La diferenciacion visual debe ser de silueta/acento moderado: legible en match, pero todavia parte de la misma familia industrial.
- `Characters` muestra como minimo `rol + skill + botones`.
- `Characters` no debe convertirse en wiki ni reemplazar a `How to Play`.

## Shell, setup y pausa

- El menu principal debe priorizar `Jugar primero`.
- El setup pre-partida inicial debe cubrir `modo + mapa + jugadores` y, como regla adicional, solo `variante de modo`.
- `Ultimo vivo` se presenta como variante dentro de `FFA`.
- La presentacion fuera del combate debe ser clara y funcional con identidad industrial.
- La pausa debe ser controlada por quien la abrio.
- La salida desde pausa usa confirmacion simple y salida inmediata.
- La direccion de producto para pausa completa incluye `Settings + How to Play + Characters`.
- La pausa no debe reasignar slots ni cambiar modo de juego.
- La pausa no necesita resumen de partida en curso en la primera version completa.

## HUD, How to Play y practica

- El HUD normal es contextual por defecto.
- El HUD explicito debe poder activarse desde opciones.
- En `Modo Practica`, el HUD explicito es el default.
- `How to Play` usa tarjetas cortas, iconos y ejemplos.
- `How to Play` prioriza `movimiento + victoria + combate`.
- `How to Play` cubre sistemas y reglas generales; `Characters` cubre identidad por personaje.
- `Modo Practica` es `sandbox guiado`.
- `Modo Practica` sirve para jugadores y para testeo interno.
- La primera version de practica debe soportar `1-2 jugadores` locales.
- La guia de practica usa estaciones + tarjetas contextuales.
- El primer corte de practica prioriza `movimiento/choque + skill + dano modular`.
- Despues del nucleo, la siguiente capa ensenable en practica es `energia y Overdrive`.
- El onboarding base vive en `How to Play` y se refuerza en `Practica`.
- La prioridad de accesibilidad inicial es legibilidad visual y prompts.

## Presentacion, audio y performance

- `1080p` es la referencia principal de fluidez y estabilidad.
- La identidad audiovisual dominante es peso industrial.
- El dano y deterioro se leen primero en el robot.
- Los estados como `Overdrive`, buffs y debuffs se comunican diegeticamente primero.
- El sonido debe dar feedback funcional fuerte para impactos, dano, estados y eventos importantes.
- La musica debe tener base de match y escalada al final, acompaniando sin tapar SFX clave.
- En combate, la identidad de personajes debe ser legible pero sobria.
- En shell, la identidad audiovisual debe estar presente pero controlada.

## Primer corte completo

- El primer corte que ya debe sentirse como juego apunta a core completo y pulido.
- La vara de exito es una sesion local cerrada y clara: entrar, configurar, jugar, pausar, practicar y cerrar sin huecos grandes.
- La post-partida de ese corte debe ser resumen claro + stats simples.
- Quedan fuera del primer corte completo:
  - video replay real o replay frame-by-frame
  - post-muerte avanzado/controlable en `FFA`
  - expansion extra de roster
  - capas amplias de reglas custom
  - remapeo libre completo si todavia complica la UX
