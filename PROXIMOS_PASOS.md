# PROXIMOS_PASOS.md - Friction Zero: Mecha Arena

## Siguiente iteracion recomendada

1. **Validar la nueva lectura de daño modular**
   - playtestear si `damage_feedback_threshold` y `critical_damage_feedback_threshold` se leen bien con cuatro robots y arena en contracción.
   - decidir si el feedback geométrico actual ya alcanza o si conviene migrarlo a humo/chispas más ricos sin ensuciar pantalla compartida.
   - ajustar posición/escala de marcadores antes de sumar más VFX o UI.

2. **Hacer visible y testeable el rescate/negacion**
   - usar el coverage headless 2v2 actual como red de seguridad mientras se hacen sesiones reales con la contraccion de arena ya activa.
   - medir en partida si `throw_pickup_delay`/`pickup_delay` se sienten justos o demasiado punitivos ahora que perder una ronda sí importa y el espacio se va cerrando.
   - ajustar si hace falta radio de retorno, cleanup y ritmo de choque con un aliado en escena, sin reabrir spam accidental.

3. **Convertir el soporte Hard en una opcion realmente jugable**
   - playtestear si `WASD + TFGX` alcanza como unico camino Hard/local de teclado o si la sesion real justifica reabrir esa decision.
   - medir si `hard_mode_player_slots` + roster persistente alcanzan como claridad de laboratorio o si aparece una necesidad real de selector runtime por jugador.
   - revisar si la referencia persistente de controles activos ya alcanza o si sigue faltando una ayuda mas compacta para pantalla compartida.
   - playtestear si la nueva lectura torso/chasis mejora el combate o si todavia se siente demasiado sutil para pantalla compartida.

4. **Validar la identidad del nuevo laboratorio FFA**
   - correr sesiones reales en `scenes/main/main_ffa.tscn` para comprobar si el mismo layout 4P ya genera supervivencia, oportunismo y third-party legibles.
   - medir si el rescate/negacion sigue siendo entendible cuando nadie tiene aliados y decidir si FFA necesita valores o spawns propios, no solo otra bandera de match.
   - revisar si el marcador first-to-3 y la contraccion actual producen buen ritmo en FFA o si ese modo necesita objetivo/duracion distintos.

5. **Pulir el cierre de match que ya existe**
   - playtestear si `rounds_to_win=3` y `match_restart_delay` dejan leer bien la victoria o si el resultado pasa demasiado rápido.
   - decidir si el reinicio automático debe seguir siendo la solución del laboratorio o si conviene pasar a una espera corta con confirmación/manual restart más adelante.
   - definir si ring-out y destruccion total siguen puntuando igual o si alguno merece bonus/feedback diferencial.
   - medir si `Ultima baja | ...` + `Fuera | vacio/explosion` + `Inutilizado | explota` ya explican suficientemente bien la derrota inmediata o si la siguiente capa debe ser un resumen corto de post-ronda.

6. **Afinar la nueva presion de arena**
   - playtestear si el inicio del cierre (`space_reduction_start_ratio`) llega demasiado tarde o demasiado pronto.
   - revisar si el minimo de contraccion deja espacio suficiente para un cierre legible en 2v2 y FFA.
   - decidir si conviene sumar feedback visual sobrio extra en el piso, no solo en edge markers + HUD.

7. **Pulir la energia ahora que ya es jugable**
   - decidir si el foco debe quedar en presets por arquetipo o en redistribucion libre mas adelante
   - ligar mejor la lectura diegetica del foco/overdrive con materiales o VFX sobrios
   - revisar valores de multiplicadores, duracion y recuperacion contra sensacion real en partida
   - medir si `energy_pickup_pair_multiplier` y `surge_duration` hacen que la recarga de borde valga la pena sin comerse la identidad del overdrive

8. **Mejorar validacion jugable**
   - sumar una escena/configuración de prueba pensada para reproducir rescates, negaciones y cierres de ronda/contraccion más rápido que en el match completo
   - ajuste fino de valores de aceleracion, damping, empuje y danio
   - medir si el reset corto de ronda y el reinicio de match dejan suficiente tiempo de lectura o si necesitan delays algo mayores

9. **Profundizar el soporte Hard sin convertirlo en requisito**
   - direccionar mejor ataques/skills futuros usando la nueva referencia de torso
   - decidir si el daño modular debe ponderar tambien frente/espalda del chasis inferior y no solo del torso
   - mantener Easy como modo plenamente jugable y legible

10. **Validar y tensionar el nuevo incentivo de borde**
   - playtestear si `repair_amount`, `boost_duration`, `surge_duration`, el nuevo `pulse_charge` y sus `respawn_delay` vuelven los bordes realmente tentadores o si alguno de los cuatro incentivos domina demasiado.
   - medir si las nuevas coberturas blockout, la reparacion lateral, el impulso norte/sur, la energia diagonal y el pulso repulsor ya generan duelos más tácticos o si empiezan a volver algunos flancos demasiado seguros.
   - decidir si el siguiente paso de items debe ser variacion semialeatoria sobre `edge_pickups`, más items de una sola carga o una capa mínima de inventario explícito.
   - mantener el centro limpio y legible, evitando saturar la arena con demasiados objetos.

11. **Validar el primer item de una carga en mano**
   - medir si compartir slot entre `pulse_charge` y `DetachedPart` genera la decisión correcta o si frustra demasiado rescates importantes.
   - revisar si el pulso usando el mismo botón de ataque se entiende al instante o si necesita una pista diegética/visual adicional sobre el robot.
   - ajustar `pulse_charge_projectile_speed`, `pulse_charge_impulse` y `pulse_charge_damage` para que el item reposicione sin eclipsar la embestida base.
