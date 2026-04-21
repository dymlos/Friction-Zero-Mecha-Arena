# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Validar el nuevo roster de arquetipos**
   - usar `F2/F3/F4` para recorrer cruces reales entre `Ariete`, `Grua`, `Cizalla`, `Patin`, `Aguja` y `Ancla` en `main.tscn` y `main_ffa.tscn` sin editar escenas entre partidas.
   - correr sesiones reales con `Ariete`, `Grua`, `Cizalla` y `Patin` en `main.tscn`, y con `Aguja` + `Ancla` en `main_ffa.tscn`, para decidir si la mezcla actual de pasivas + primeras skills propias ya produce identidades claras.
   - medir si las pasivas actuales se entienden por playtest sin otra capa de UI: `Ariete` aguantando empuje, `Grua` estabilizando rescates, `Cizalla` rematando partes tocadas y `Patin` explotando mejor los pickups de impulso.
   - medir si `Aguja` realmente introduce poke/skillshot legible o si `Pulso` todavia se siente demasiado parecido al item universal del borde.
   - medir si `Ancla` realmente corta rutas/duelos con `Baliza` o si la supresion actual se siente demasiado sutil para justificar el rol de Control/Zona.
   - medir si el roster actual (`Player X / <Arquetipo>` + `[<Arquetipo>]` en marcador FFA + `skill Pulso/Baliza x/y` + estado `zona`) alcanza como legibilidad de laboratorio o si conviene compactarlo mas.
   - decidir si el selector runtime actual ya alcanza como flujo de laboratorio o si el siguiente paso debe ser persistencia/presets por escena, mas claridad visual o reforzar con otra skill/regla al arquetipo que siga borroso.

2. **Validar el nuevo HUD dual y la nueva lectura de daño modular**
   - correr sesiones con `hud_detail_mode=EXPLICIT` y `hud_detail_mode=CONTEXTUAL` usando tambien el toggle `F1` para decidir que variante debe quedar por defecto en `Equipos` y en `FFA`.
   - revisar si el modo contextual realmente limpia sin esconder decisiones tacticas como `Foco`, `item`, `carga`, `impulso`, `energia` o `3/4 partes`.
   - decidir si el toggle runtime actual alcanza para laboratorio o si la siguiente capa necesita persistencia/preset mas visible por modo, ademas del `MatchConfig`.
   - medir si `RecapPanel` lateral + `MatchResultPanel` centrado + `Stats | ...` explican suficientemente bien `Decision + Marcador + baja N | causa` sin necesitar otra escena/post-ronda.
   - playtestear si `damage_feedback_threshold` y `critical_damage_feedback_threshold` se leen bien con cuatro robots y arena en contracción.
   - decidir si el feedback geométrico actual ya alcanza o si conviene migrarlo a humo/chispas más ricos sin ensuciar pantalla compartida.
   - ajustar posición/escala de marcadores antes de sumar más VFX o UI.

3. **Hacer visible y testeable el rescate/negacion**
   - usar el coverage headless 2v2 actual como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir si el nuevo disco de recuperacion sobre las piezas realmente alcanza para leer urgencia/ownership en 2v2 y FFA o si todavia hace falta una pista compacta adicional.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

4. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si `WASD + TFGX` alcanza como unico camino Hard/local de teclado o si la sesion real justifica reabrir esa decision.
   - medir si `F4` sobre el selector runtime + roster persistente alcanzan como claridad de laboratorio o si aparece una necesidad real de un flujo pre-match/persistente por jugador.
   - revisar si la referencia persistente de controles activos ya alcanza o si sigue faltando una ayuda mas compacta para pantalla compartida.
   - playtestear si la nueva lectura torso/chasis mejora el combate o si todavia se siente demasiado sutil para pantalla compartida.

5. **Validar la identidad del nuevo laboratorio FFA**
   - correr sesiones reales en `scenes/main/main_ffa.tscn` para comprobar si el mismo layout 4P ya genera supervivencia, oportunismo y third-party legibles ahora que el roster libre incluye a `Aguja` y `Ancla`.
   - medir si el rescate/negacion sigue siendo entendible cuando nadie tiene aliados y decidir si FFA necesita valores o spawns propios, no solo otra bandera de match.
   - revisar si `Baliza` vuelve algunas diagonales/coberturas demasiado seguras o si realmente empuja rotacion y lectura espacial.
   - revisar si el marcador first-to-3 y la contraccion actual producen buen ritmo en FFA o si ese modo necesita objetivo/duracion distintos.

6. **Pulir el cierre de match que ya existe**
  - playtestear si `rounds_to_win=3`, `match_restart_delay`, el panel `Partida cerrada` y el atajo `F5` dejan leer bien la victoria o si el resultado sigue pasando demasiado rápido.
  - decidir si el reinicio automático debe seguir siendo el fallback del laboratorio o si conviene pasar a una solución manual-only más adelante.
  - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.
  - medir si `Resumen | ...` + `Ultima baja | ...` + `Fuera | vacio/explosion/explosion inestable` + `Inutilizado | explota/inestable` + `Stats | ...` + `RecapPanel` + `MatchResultPanel` ya explican suficientemente bien la derrota inmediata o si la siguiente capa debe ser una pantalla post-ronda/post-partida más fuerte.

7. **Afinar la nueva presion de arena**
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - decidir si conviene sumar feedback visual sobrio extra en el piso, no solo en edge markers + HUD.

8. **Pulir la energia ahora que ya es jugable**
  - decidir si el foco debe seguir compartido por todos o si algun arquetipo necesita un preset/base distinto mas adelante
  - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
  - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida
  - medir si `energy_pickup_pair_multiplier` y `surge_duration` hacen que la recarga de borde valga la pena sin comerse la identidad del overdrive
  - medir si `unstable_disabled_explosion_radius_multiplier`, `unstable_disabled_explosion_impulse_multiplier` y `unstable_disabled_explosion_damage_multiplier` vuelven especial la sobrecarga sin transformar el overdrive en una ruta dominante de remate

9. **Mejorar validacion jugable**
   - sumar una escena/configuración de prueba pensada para reproducir rescates, negaciones y cierres de ronda/contraccion más rápido que en el match completo
   - ajuste fino de valores de aceleracion, damping, empuje y danio
   - medir si el reset corto de ronda y el reinicio de match dejan suficiente tiempo de lectura o si necesitan delays algo mayores

10. **Profundizar el soporte Hard sin convertirlo en requisito**
   - direccionar mejor ataques/skills futuros usando la nueva referencia de torso
   - decidir si el daño modular debe ponderar tambien frente/espalda del chasis inferior y no solo del torso
   - mantener Easy como modo plenamente jugable y legible

11. **Validar y tensionar el nuevo incentivo de borde**
   - playtestear si `repair_amount`, `boost_duration`, `surge_duration`, el nuevo `pulse_charge` y sus `respawn_delay` vuelven los bordes realmente tentadores o si alguno de los cuatro incentivos domina demasiado.
   - medir si las nuevas coberturas blockout, la rotacion semialeatoria por ronda y el nuevo split `Equipos=2 pares / FFA=3 tipos` ya generan duelos más tácticos o si algunos layouts siguen volviendo flancos demasiado seguros.
   - ajustar si el mazo actual necesita pesos finos por modo/mapa, otra seed por arena o más presencia de `pulso`/`energia` antes de abrir más tipos de item.
   - revisar si la línea `Borde | ...` alcanza como lectura de laboratorio o si conviene una telemetría/playtest scene mejor antes de sumar más variedad.
   - decidir si el siguiente paso de items debe ser variar el contenido del mazo, sumar más items de una sola carga o pasar a una capa mínima de inventario explícito.
   - mantener el centro limpio y legible, evitando saturar la arena con demasiados objetos.

12. **Validar el primer item de una carga en mano**
   - medir si compartir slot entre `pulse_charge` y `DetachedPart` genera la decisión correcta o si frustra demasiado rescates importantes.
   - revisar si la distincion entre el item `pulse_charge` (ataque) y la skill `Pulso` de `Aguja` (utilidad) se entiende al instante o si necesita una pista diegética/visual adicional sobre el robot.
   - ajustar `pulse_charge_projectile_speed`, `pulse_charge_impulse` y `pulse_charge_damage` para que el item reposicione sin eclipsar la embestida base.
