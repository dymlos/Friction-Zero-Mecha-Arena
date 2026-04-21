# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Validar el nuevo soporte post-muerte de Teams**
   - correr sesiones reales en `main.tscn` dejando caer a un jugador temprano para medir si la `PilotSupportShip` suma involucramiento sin tapar el combate principal.
   - medir si el nuevo loop perimetral + `gates` temporales ya se entiende con la camara compartida o si necesita mas variedad de rutas/obstaculos suaves para que la nave gane profundidad sin irse de foco.
   - medir si la mezcla `estabilizador + energia + movilidad + interferencia` sigue sintiendose discreta y si la nueva seleccion manual de objetivo recompensa realmente acercarse al borde en vez de spamearse por seguridad.
   - revisar si la combinacion `roster + StatusBeacon + SupportTargetIndicator + InterferenceRangeIndicator` ya alcanza como telemetria o si la nave todavia necesita otra pista diegética para espectador casual.
   - medir si la nueva pista `usa ... | objetivo ...` del roster y el anillo de rango de `interferencia` alcanzan para descubrir rapido el soporte post-muerte o si aun hace falta otra pista diegetica mas fuerte para espectador/jugador eliminado.
   - calibrar si `support_energy_surge_duration`, `support_mobility_boost_duration`, `support_interference_duration` y `support_interference_range` vuelven valiosas las cuatro cargas sin solaparse demasiado con los pickups de borde vivo o con `Baliza`.
   - confirmar por playtest que `FFA` realmente queda limpio y que compartir la escena base no introduce confusion por elementos post-muerte ocultos.

2. **Validar el nuevo roster de arquetipos**
   - usar `F2/F3/F4` para recorrer cruces reales entre `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla` en `main.tscn` y `main_ffa.tscn` sin editar escenas entre partidas.
   - correr sesiones reales con `Ariete`, `Grua`, `Cizalla` y `Patin` en `main.tscn`, y con `Aguja` + `Ancla` en `main_ffa.tscn`, para decidir si la mezcla actual de pasivas + primeras skills propias ya produce identidades claras.
   - medir si las pasivas/skills actuales se entienden por playtest sin otra capa de UI: `Ariete` aguantando empuje, `Grua` estabilizando rescates y usando `Iman`, `Cizalla` rematando partes tocadas y `Patin` explotando mejor los pickups de impulso.
   - medir si `Iman` realmente abre rescates/negaciones a media distancia o si el rango actual se siente demasiado corto, tramposo o poco legible cuando hay varias piezas sueltas.
   - medir si `Aguja` realmente introduce poke/skillshot legible ahora que `Pulso` ya tiene lectura diegetica sobre `CoreLight`, o si aun hace falta ajustar color/intensidad/ritmo del pulso para cámara compartida.
   - si se retocan `pulse_charge_spawn_distance`, velocidad o lifetime de `Pulso`, conservar la cobertura headless que hoy evita que el proyectil nazca solapado con su robot origen.
   - medir si `Ancla` realmente corta rutas/duelos con `Baliza` o si la supresion actual se siente demasiado sutil para justificar el rol de Control/Zona.
   - medir si el roster actual (`Player X / <Arquetipo>` + `[<Arquetipo>]` en marcador FFA + `skill Iman/Pulso/Baliza x/y` + estado `zona`) mas los nuevos acentos en mundo (`FacingMarker/CoreLight` por identidad) alcanzan como legibilidad de laboratorio o si conviene compactarlo mas.
   - decidir si el selector runtime actual ya alcanza como flujo de laboratorio o si el siguiente paso debe ser persistencia/presets por escena, mas claridad visual o reforzar con otra skill/regla al arquetipo que siga borroso.

3. **Validar el nuevo HUD dual y la nueva lectura de daño modular**
   - correr sesiones con `hud_detail_mode=EXPLICIT` y `hud_detail_mode=CONTEXTUAL` usando tambien el toggle `F1` para decidir que variante debe quedar por defecto en `Equipos` y en `FFA`.
   - revisar si el modo contextual realmente limpia sin esconder decisiones tacticas como `Foco`, `item`, `carga`, `impulso`, `energia` o `3/4 partes`.
   - decidir si el toggle runtime actual alcanza para laboratorio o si la siguiente capa necesita persistencia/preset mas visible por modo, ademas del `MatchConfig`.
   - medir si `RecapPanel` lateral + `MatchResultPanel` centrado + `Stats | ...` (incluyendo `partes perdidas`) explican suficientemente bien `Decision + Marcador + baja N | causa` sin necesitar otra escena/post-ronda.
   - playtestear si `damage_feedback_threshold`, `critical_damage_feedback_threshold` y la nueva pose floja de brazos/piernas se leen bien con cuatro robots y arena en contracción.
   - decidir si el feedback geométrico actual ya alcanza o si conviene migrarlo a humo/chispas más ricos sin ensuciar pantalla compartida.
   - ajustar posición/escala de marcadores y amplitud de la pose de desgaste antes de sumar más VFX o UI.

4. **Hacer visible y testeable el rescate/negacion**
   - usar `scenes/main/main_teams_validation.tscn` como escena corta de referencia y el coverage headless 2v2/validacion como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir si el nuevo combo `disco de recuperacion + aro de pertenencia + RecoveryTargetIndicator + CarryOwnerIndicator + CarryReturnIndicator` realmente alcanza para leer urgencia/ownership/objetivo de retorno tambien durante el transporte en 2v2 y FFA o si todavia hace falta compactar escala/contraste/ritmo de esos cues.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

5. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si `WASD + TFGX` alcanza como unico camino Hard/local de teclado o si la sesion real justifica reabrir esa decision.
   - medir si `F4` sobre el selector runtime + roster persistente alcanzan como claridad de laboratorio o si aparece una necesidad real de un flujo pre-match/persistente por jugador.
   - revisar si la referencia persistente de controles activos ya alcanza o si sigue faltando una ayuda mas compacta para pantalla compartida.
   - playtestear si la nueva lectura torso/chasis mejora el combate o si todavia se siente demasiado sutil para pantalla compartida.

6. **Validar la identidad del nuevo laboratorio FFA**
   - correr primero sesiones cortas en `scenes/main/main_ffa_validation.tscn` para calibrar oportunismo, third-party, cierres de ronda y rotacion de borde sin la duracion del laboratorio libre base.
   - usar despues `scenes/main/main_ffa.tscn` para comprobar si esa lectura compacta sigue sosteniendose en el laboratorio libre mas largo, ahora que el roster incluye a `Aguja` y `Ancla`.
   - medir si el rescate/negacion sigue siendo entendible cuando nadie tiene aliados y decidir si FFA necesita valores o spawns propios, no solo otra bandera de match.
   - revisar si `Baliza` vuelve algunas diagonales/coberturas demasiado seguras o si realmente empuja rotacion y lectura espacial.
   - revisar si el marcador first-to-3 y la contraccion actual producen buen ritmo en FFA o si ese modo necesita objetivo/duracion distintos.

7. **Pulir el cierre de match que ya existe**
  - playtestear si `rounds_to_win=3`, `match_restart_delay`, el panel `Partida cerrada` y el atajo `F5` dejan leer bien la victoria o si el resultado sigue pasando demasiado rápido.
  - decidir si el reinicio automático debe seguir siendo el fallback del laboratorio o si conviene pasar a una solución manual-only más adelante.
  - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.
  - medir si `Resumen | ...` + `Ultima baja | ...` + `Fuera | vacio/explosion/explosion inestable` + `Inutilizado | explota/inestable` + `DisabledWarningIndicator` + `Stats | ...` con `partes perdidas` + `RecapPanel` + `MatchResultPanel` ya explican suficientemente bien la derrota inmediata o si la siguiente capa debe ser una pantalla post-ronda/post-partida más fuerte.

8. **Afinar la nueva presion de arena**
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - medir si las nuevas bandas de piso alcanzan para anunciar la contraccion en camara compartida o si su contraste/inset todavia necesita ajuste fino.

9. **Pulir la energia ahora que ya es jugable**
  - decidir si el foco debe seguir compartido por todos o si algun arquetipo necesita un preset/base distinto mas adelante
  - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
  - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida
  - medir si `energy_pickup_pair_multiplier` y `surge_duration` hacen que la recarga de borde valga la pena sin comerse la identidad del overdrive
  - medir si `unstable_disabled_explosion_radius_multiplier`, `unstable_disabled_explosion_impulse_multiplier` y `unstable_disabled_explosion_damage_multiplier` vuelven especial la sobrecarga sin transformar el overdrive en una ruta dominante de remate

10. **Mejorar validacion jugable**
   - usar `main_teams_validation.tscn` y `main_ffa_validation.tscn` como rutas rapidas base antes de tocar `main.tscn` o `main_ffa.tscn`.
   - ajuste fino de valores de aceleracion, damping, empuje y danio usando esas escenas cortas para iterar mas rapido antes de tocar los laboratorios largos.
   - medir si el reset corto de ronda y el reinicio de match dejan suficiente tiempo de lectura o si necesitan delays algo mayores
   - aislar los warnings Jolt que todavia aparecen en `scripts/tests/edge_charge_pickup_test.gd`; `PulseBolt` ya apaga hitbox antes del free, asi que el ruido restante probablemente vive en otro teardown de `Area3D`.

11. **Profundizar el soporte Hard sin convertirlo en requisito**
   - direccionar mejor ataques/skills futuros usando la nueva referencia de torso
   - decidir si el daño modular debe ponderar tambien frente/espalda del chasis inferior y no solo del torso
   - mantener Easy como modo plenamente jugable y legible

12. **Validar y tensionar el nuevo incentivo de borde**
   - playtestear si `repair_amount`, `boost_duration`, `surge_duration`, `charge_amount`, `stability_duration`, `stability_pickup_received_impulse_multiplier`, el nuevo `pulse_charge` y sus `respawn_delay` vuelven los bordes realmente tentadores o si alguno de los seis incentivos domina demasiado.
   - medir si las nuevas coberturas blockout, la rotacion semialeatoria por ronda y el nuevo split `Equipos=2 pares / FFA=3 tipos` ya generan duelos más tácticos o si algunos layouts siguen volviendo flancos demasiado seguros.
   - ajustar si el mazo actual necesita pesos finos por modo/mapa, otra seed por arena o más presencia de `pulso`/`municion`/`energia`/`estabilidad` antes de abrir más tipos de item.
   - revisar si la línea `Borde | ...` alcanza como lectura de laboratorio o si conviene una telemetría/playtest scene mejor antes de sumar más variedad.
   - decidir si el siguiente paso de items debe ser variar el contenido del mazo, sumar más items de una sola carga o pasar a una capa mínima de inventario explícito.
   - mantener el centro limpio y legible, evitando saturar la arena con demasiados objetos.
   - validar si el gating actual de `municion` por roster alcanza o si algun modo necesita reglas propias mas explicitas para no dejar valor muerto o ventaja injusta.
   - medir si `estabilidad` realmente da contrajuego sano a `Baliza`/`interferencia` o si termina neutralizando demasiado la presion de control en FFA o post-muerte Teams.

13. **Validar el primer item de una carga en mano**
   - medir si compartir slot entre `pulse_charge` y `DetachedPart` genera la decisión correcta o si frustra demasiado rescates importantes.
   - revisar en playtest si la distincion nueva entre `pulse_charge` (CarryIndicator dorado) y `Pulso` de `Aguja` (`CoreLight` pulsando) se entiende al instante o si aun hace falta afinar contraste/ritmo.
   - ajustar `pulse_charge_projectile_speed`, `pulse_charge_impulse` y `pulse_charge_damage` para que el item reposicione sin eclipsar la embestida base.
