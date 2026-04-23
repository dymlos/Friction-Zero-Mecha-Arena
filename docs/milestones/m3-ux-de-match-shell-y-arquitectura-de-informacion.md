# M3 - UX de match, shell y arquitectura de informacion

## Objetivo

Convertir el vertical slice actual en una shell jugable coherente:
- menu principal
- setup de partida
- HUD
- pausa
- configuraciones
- superficies informativas

## Por que existe

Pausa, `How to Play`, prompts, HUD y settings comparten lenguaje y navegacion. Separarlos produce duplicacion, prompts inconsistentes y reglas de visibilidad contradictorias.

## Grupos de trabajo

- `Menu y shell`
  - definir flujo desde menu principal hasta salida de match
  - ubicar `How to Play` y settings en superficies coherentes
- `Pausa`
  - congelado real del match
  - opciones de resume, leave y confirmacion
  - decidir si pausa expone tambien settings, controls y ayuda
- `HUD e informacion`
  - auditar claridad para mas jugadores
  - definir que es siempre visible y que es contextual
  - unificar wording entre HUD, pausa, menus y resultados
- `Configuracion`
  - separar opciones pre-match de opciones accesibles en pausa
  - definir superficies para audio, video, gameplay y controles

## Dependencias

- Depende de M1 por contratos de input, prompts y ownership de pausa.
- Debe apoyarse en la escala definida en M2 para no disenar HUD o shell para mapas ya obsoletos.

## Riesgos y preguntas abiertas

- `Interfaz clara en todo momento` necesita reglas concretas para no volverse un pedido vacio.
- El HUD explicito/contextual ya existe como concepto y debe refinarse, no descartarse.
- La shell puede crecer demasiado si absorbe features futuras sin criterio.

## Criterio de salida

- El flujo completo de shell esta documentado de punta a punta.
- La pausa tiene reglas claras y consistentes.
- Quedo definido que vive en menu principal, setup, HUD, pausa y resultados.
