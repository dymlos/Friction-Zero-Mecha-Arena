# PLAN_DESARROLLO.md - Friction Zero: Mecha Arena

Este plan ordena el desarrollo para validar primero la identidad real del juego: robots industriales que patinan con inercia, chocan con peso, se desarman por partes y obligan a leer el espacio antes de comprometerse. No propone un MVP generico: cada etapa debe dejar una version jugable que preserve la fantasia de "patinar y chocar con precision", aunque todavia falten capas avanzadas.

## Checkpoint actual - 2026-04-21

- Etapa 0 a 3: base jugable ya integrada en `main.tscn` con arena, camara compartida, empuje, caida al vacio y cierre de ronda simple por ultimo robot/equipo en pie.
- Bootstrap local mas claro: `main.gd` ahora alinea robots con los spawns del arena blockout, asigna slots de jugador y admite 4 jugadores de teclado/slot por defecto para laboratorio 2v2.
- Input local separado: `RobotBase` resuelve perfiles de teclado por slot y deja de leer joysticks "de todos" cuando el robot ya usa teclado.
- Etapa 2v2: laboratorio 2v2 preparado con 4 robots por escena y `local_player_count=4`, incluyendo equipos por parejas para validar rescate aliado.
- Validacion 2v2: el loop de rescate/negacion ya tiene cobertura headless en `main.tscn`, incluyendo indicador de carga visible y ventana de `throw_pickup_delay`.
- Scoreboard minimo: `MatchController` ya registra bajas por vacio o explosion, suma ronda al ultimo contendiente en pie y reinicia todos los robots juntos tras una pausa corta.
- Etapa 4: parcialmente implementada. El robot ya recibe danio modular por direccion de impacto, pierde brazos o piernas visualmente, desprende piezas y cambia su rendimiento segun las partes restantes.
- Etapa 2 y 3: el ritmo de choque del laboratorio 2P ya fue afinado en `RobotBase` para que los intercambios sean más fluidos sin perder el carácter de choque decisivo.
- Etapa 5: primer slice funcional implementado. Cada robot ahora puede redistribuir energia hacia una parte foco, alterar de forma real el empuje o la traccion y activar un overdrive corto con recuperacion/cooldown.
- Etapa 7: base funcional implementada. Las partes desprendidas ya conservan propietario, pueden recogerse por cercania, bloquear el ataque mientras se cargan y volver con vida parcial; si el portador cae al vacio, la parte se niega.
- Robot inutilizado: ahora entra en una cuenta regresiva corta, explota con empuje/danio radial y, si eso cierra la ronda, queda fuera hasta el reset comun.
- Lectura visual: sigue sobria y funcional. El prototipo usa desgaste por materiales, partes ocultas/desprendidas, mensajes breves, foco energetico visible en el core y un HUD compacto con marcador de ronda + roster por robot para leer estado/carga/energia sin HUD pesado.
- Negacion de partes: ahora existe negacion activa; un jugador con parte en mano puede lanzarla para cortar el rescate oportuno y crear decisiones de riesgo.
- Pendiente prioritario: playtestear rescate/negacion con presion real de ronda, decidir si ring-out y destruccion deben puntuar igual en match largo y preparar un cierre de partida mas alla del marcador infinito.

## Principios de orden

- Primero se valida sensacion fisica: movimiento, derrape, choque y lectura visual.
- Despues se agregan consecuencias: bordes letales, empuje, danio modular y perdida de partes.
- Luego se agregan decisiones tacticas: energia, overdrive, recuperacion, items y skills.
- Finalmente se consolidan modos, mapas, UI, postpartida y contenido.
- Cada etapa debe poder probarse en Godot con pocos elementos en pantalla y reglas claras.

## Etapa 0 - Base tecnica jugable

**Objetivo:** crear una base Godot simple, modular y facil de entender para iterar mecanicas sin rehacer escenas cada vez.

**Sistemas involucrados:**
- escena principal de arena
- escena de robot reusable
- entrada local para 2 a 4 jugadores iniciales
- camara compartida casi cenital
- capas de colision
- configuracion basica de debug

**Criterio de exito:**
- se puede iniciar una escena de prueba con al menos dos robots controlables
- cada robot usa una escena instanciable, no codigo duplicado
- la camara mantiene legibles a los jugadores
- el proyecto sigue siendo entendible para una persona con poca experiencia programando

**Riesgos tecnicos:**
- acoplar demasiado pronto escena, control y reglas de partida
- construir una arquitectura demasiado abstracta antes de saber que fisica funciona
- perder legibilidad si la camara o escala de robots se decide tarde

**Dependencias:** ninguna. Es la base para todo lo demas.

## Etapa 1 - Movimiento con inercia y control Easy

**Objetivo:** validar la sensacion principal: robot pesado al arrancar, mas libre al deslizar y orientado en la direccion de movimiento.

**Sistemas involucrados:**
- controlador de movimiento top-down
- aceleracion, freno, derrape e inercia
- orientacion automatica del cuerpo
- friccion o amortiguacion ajustable por superficie
- animacion/feedback minimo de velocidad y peso

**Criterio de exito:**
- mover el robot ya se siente como patinar, no como caminar
- hay diferencia clara entre arrancar, deslizar, corregir y frenar
- el control Easy funciona sin exigir punteria independiente
- un jugador puede perseguir, esquivar y preparar una embestida solo con movimiento

**Riesgos tecnicos:**
- que la fisica se sienta flotante en lugar de pesada
- que el control sea demasiado resbaloso para jugadores nuevos
- que las correcciones pequenas no sean lo bastante precisas para preparar choques

**Dependencias:** Etapa 0.

## Etapa 2 - Choques, empuje y lectura del impacto

**Objetivo:** hacer que el contacto entre robots sea especial, legible y decisivo cuando esta bien preparado.

**Sistemas involucrados:**
- deteccion de impactos entre robots
- calculo de impulso segun velocidad, masa y direccion
- reaccion fisica al choque
- feedback audiovisual sobrio para impactos fuertes
- debug de magnitud y direccion de impacto

**Criterio de exito:**
- una embestida preparada empuja de forma clara y satisfactoria
- contactos debiles no ensucian la partida ni parecen igual de importantes
- se entiende quien golpeo, desde donde y con que fuerza
- el loop "tanteo, reposicionamiento, choque decisivo" aparece aunque solo haya dos robots

**Riesgos tecnicos:**
- spam de colisiones si todos los contactos generan efectos fuertes
- empujes inconsistentes por resolucion de fisica
- robots trabados o girando sin control despues del impacto

**Dependencias:** Etapa 1.

## Etapa 3 - Arena flotante, bordes letales y cierre de ronda

**Objetivo:** convertir el movimiento y los choques en una condicion de eliminacion central: sacar rivales de la plataforma.

**Sistemas involucrados:**
- arena flotante con borde letal
- deteccion de salida del mapa
- reset o cierre de ronda
- spawn inicial equilibrado
- camara compartida adaptada a bordes

**Criterio de exito:**
- empujar al rival fuera de la arena es posible, claro y emocionante
- el centro sirve para reposicionarse, pero los bordes son tentadores y peligrosos
- una ronda corta de 2 a 4 jugadores ya produce momentos de lectura y castigo
- perder por caida se siente entendible, no arbitrario

**Riesgos tecnicos:**
- bordes demasiado letales que corten las partidas antes de que exista historia
- bordes demasiado seguros que reduzcan la tension
- camara que esconda el peligro o saque jugadores de foco

**Dependencias:** Etapas 1 y 2.

**Estado actual del prototipo:**
- el vacio ya elimina al robot de la ronda actual
- el ultimo robot/equipo en pie suma una ronda
- el HUD minimo ya muestra ronda y marcador, sin sumar barras pesadas
- pendiente: definir cierre de match (por ejemplo first-to-X) y si la puntuacion debe distinguir vacio vs destruccion

## Etapa 4 - Danio modular por brazos y piernas

**Objetivo:** agregar la segunda ruta de victoria: desarmar estrategicamente al robot rival sin quitarle toda posibilidad de remontada.

**Sistemas involucrados:**
- cuatro partes con vida propia: brazo izquierdo, brazo derecho, pierna izquierda, pierna derecha
- asignacion de danio segun lado del impacto y orientacion
- degradacion funcional por parte daniada
- visualizacion directa de danio en el robot
- estado de robot torpe pero todavia jugable

**Criterio de exito:**
- romper una pierna cambia el movimiento de forma notoria pero no termina automaticamente la pelea
- romper un brazo reduce dominio ofensivo o fuerza de empuje
- el jugador entiende que parte esta daniada mirando al robot, no solo al HUD
- aparece la jugada de "romper una parte y luego rematar"

**Riesgos tecnicos:**
- que el danio por impacto sea dificil de atribuir de forma justa
- que perder partes genere una espiral sin vuelta
- que los indicadores visuales no sean claros en pantalla compartida

**Dependencias:** Etapas 1 y 2. Funciona mejor despues de Etapa 3, pero puede prototiparse en una arena cerrada.

## Etapa 5 - Energia, redistribucion y Overdrive

**Objetivo:** sumar decisiones tacticas antes del choque: invertir energia en brazos, piernas o una apuesta riesgosa de Overdrive.

**Sistemas involucrados:**
- reserva total de energia del robot
- distribucion por cuatro partes
- modificadores para piernas: velocidad, control de deslizamiento, inercia
- modificadores para brazos: empuje y dominio cercano
- interfaz de redistribucion legible
- Overdrive por parte con penalizacion o sobrecalentamiento

**Criterio de exito:**
- redistribuir energia cambia una pelea de manera perceptible
- no conviene spamear redistribucion
- Overdrive crea una ventana fuerte, riesgosa y reconocible
- el sistema funciona en Easy sin exigir control avanzado

**Riesgos tecnicos:**
- demasiados parametros simultaneos para balancear
- UI invasiva o dificil de leer durante el combate
- Overdrive dominante que convierta todo en burst sin lectura previa

**Dependencias:** Etapas 1, 2 y 4.

## Etapa 6 - Control Hard y torso independiente

**Objetivo:** habilitar profundidad tecnica sin hacer que el juego dependa de ella.

**Sistemas involucrados:**
- stick izquierdo para movimiento
- stick derecho para torso superior
- orientacion independiente de torso
- relacion entre torso, direccion de ataque y parte impactada
- alternancia de modo Easy/Hard por jugador

**Criterio de exito:**
- Hard permite apuntar mejor ataques, defensas y skillshots
- Easy sigue siendo competitivo y legible
- la orientacion del torso ayuda a leer intencion sin confundir la direccion de movimiento
- el sistema no rompe la atribucion de danio modular

**Riesgos tecnicos:**
- que Hard sea tan superior que Easy parezca modo de castigo
- que el cuerpo del robot sea dificil de leer en camara cenital
- que los controles se vuelvan confusos en partidas locales con varios jugadores

**Dependencias:** Etapas 1, 2 y 4. Conviene hacerlo despues de que Easy ya sea divertido.

## Etapa 7 - Partes desprendidas, recuperacion y cuerpo averiado

**Objetivo:** convertir la destruccion modular en juego de posicionamiento, rescate y negacion.

**Sistemas involucrados:**
- partes destruidas como objetos fisicos en la arena
- pickup simple por contacto o cercania
- transporte de partes
- bloqueo de skills al cargar una parte
- devolucion a robot original con vida parcial
- negacion enemiga arrojando partes al vacio
- robot inutilizado al perder las cuatro partes
- explosion diferida del cuerpo averiado

**Criterio de exito:**
- recuperar una parte aliada se siente valioso y posible
- negar una parte enemiga crea presion sin reemplazar el combate principal
- el cuerpo averiado explosivo genera momentos especiales, no ruido constante
- la partida conserva claridad aunque haya partes sueltas

**Riesgos tecnicos:**
- acumulacion de cuerpos y partes que ensucie fisica y pantalla
- rescates demasiado faciles o demasiado imposibles
- explosion demasiado frecuente o demasiado fuerte
- reglas de pertenencia de partes confusas

**Dependencias:** Etapas 3 y 4. La explosion tambien depende de Etapa 2 para empuje radial.

**Estado actual del prototipo:**
- partes desprendidas con propietario original y retorno parcial
- pickup por cercania sin input extra
- transporte que bloquea el ataque prototipo
- negacion basica si el portador cae al vacio o lanza la parte fuera del contexto inmediato
- cuerpo inutilizado con explosion diferida; si la explosion cierra la ronda, el robot espera el reset comun
- feedback visual de transporte implementado con indicador diegetico en `RobotBase`
- pendiente: rescate cooperativo mas visible en sesiones activas y ajuste fino de radio de retorno/timer de negación en 2v2 con la nueva presión de ronda

## Etapa 8 - Primeros arquetipos jugables

**Objetivo:** demostrar que los sistemas soportan identidades distintas sin borrar el nucleo de choques.

**Sistemas involucrados:**
- seleccion simple de robot
- parametros por arquetipo
- una skill o regla distintiva por robot inicial
- recursos de skill: cargas, ammo o energia segun corresponda
- balance basico para FFA y Team vs Team

**Contenido recomendado inicial:**
- Empujador/Tanque para probar masa, brazos y control del borde
- Movilidad/Reposition para probar derrape, escapes y rutas
- Desarmador para probar danio modular intencional
- Asistencia/Recuperacion para probar rescates y utilidad en equipos sin quedar inutil en FFA

**Criterio de exito:**
- cada robot se reconoce por lo que intenta hacer en pelea
- ninguno depende exclusivamente de coordinacion perfecta para ser divertido
- las skills no tapan el combate cuerpo a cuerpo
- el Pusher gana por impacto, el Desarmador por desgaste y el Movilidad por posicionamiento

**Riesgos tecnicos:**
- arquetipos borrosos si todos comparten demasiados valores
- skills mas fuertes que el choque
- roles de soporte inutiles en FFA
- balance prematuro sobre valores que todavia estan cambiando

**Dependencias:** Etapas 1 a 7. Puede empezar con 3 arquetipos si el costo de contenido frena la iteracion.

## Etapa 9 - Items, skills universales y economia de recursos

**Objetivo:** agregar oportunidades tacticas de mapa sin romper la claridad ni transformar el juego en spam de efectos.

**Sistemas involucrados:**
- inventario de un solo item
- spawns semialeatorios
- items de municion/carga, movilidad, reparacion, energia y utilidad
- telegraph visual claro
- reglas de rareza y valor cerca de bordes
- limpieza de items y partes viejas

**Criterio de exito:**
- los items son pocos, importantes y faciles de reconocer
- los bordes se vuelven mas tentadores sin volverse zonas dominadas permanentemente
- una skill bien usada puede definir una jugada, pero no reemplaza una embestida bien ejecutada
- cargar una parte y cargar un item generan decisiones incompatibles interesantes

**Riesgos tecnicos:**
- ruido visual por demasiados pickups o efectos
- ventaja aleatoria excesiva
- items de movilidad que rompan bordes letales
- reparacion que alargue partidas sin tension

**Dependencias:** Etapas 3, 5, 7 y 8.

## Etapa 10 - Mapas, ritmo de partida y presion final

**Objetivo:** pasar de una arena de prueba a mapas con lectura, rutas, bordes valiosos y final explosivo.

**Sistemas involucrados:**
- layout de centro abierto
- bordes con valor y riesgo
- coberturas
- rutas de reposicionamiento
- trampas opcionales por mapa
- reduccion progresiva de espacio jugable
- reglas de spawn por modo

**Criterio de exito:**
- el centro sirve para escapar, leer y reposicionarse
- los bordes generan duelos tensos y jugadas de castigo
- las coberturas permiten pausa, emboscada y recuperacion sin frenar la partida
- el cierre progresivo evita finales estancados

**Riesgos tecnicos:**
- mapas que favorezcan demasiado a un arquetipo
- reduccion de espacio poco legible
- trampas que compitan con los choques como fuente principal de eliminacion
- problemas de camara al achicarse el escenario

**Dependencias:** Etapas 3, 8 y 9. La presion final requiere que la eliminacion por borde ya sea buena.

## Etapa 11 - Modos FFA y Team vs Team

**Objetivo:** formalizar dos modos igual de importantes, no una variante menor del otro.

**Sistemas involucrados:**
- reglas de victoria por modo
- equipos, colores y spawn
- FFA con supervivencia, oportunismo y terceros
- Team vs Team con rescates, coordinacion y presion tactica
- condiciones de final de ronda y match
- balance de asistencia y recuperacion

**Criterio de exito:**
- FFA funciona sin depender de roles de equipo
- Team vs Team premia rescatar partes tanto como coordinar ataques
- las condiciones de victoria son claras para jugadores y espectadores
- los dos modos producen historias distintas usando el mismo nucleo

**Riesgos tecnicos:**
- FFA injusto para robots de soporte
- Team vs Team demasiado dependiente de comunicacion perfecta
- reglas de victoria ambiguas cuando hay caidas, desarme y explosiones a la vez
- exceso de indicadores de equipo en pantalla compartida

**Dependencias:** Etapas 3, 4, 7, 8 y 10.

## Etapa 12 - Post-muerte de Team vs Team y reglas abiertas de FFA

**Objetivo:** mantener involucrados a jugadores eliminados sin confundir la pelea principal.

**Sistemas involucrados:**
- mini nave del piloto para Team vs Team
- capa externa de movimiento
- obstaculos o rutas externas
- items temporales de soporte
- intervenciones tacticas livianas
- acciones fuertes raras y telegrafiadas
- decision final sobre post-muerte en FFA

**Criterio de exito:**
- un eliminado en Team vs Team sigue teniendo algo util que hacer
- la nave no parece otro robot ni roba atencion del combate principal
- las intervenciones ayudan a remontar, pero no anulan el resultado de un buen choque
- FFA conserva identidad de supervivencia y oportunismo

**Riesgos tecnicos:**
- ruido visual por una segunda capa de juego
- frustracion si jugadores vivos sienten que los eliminados deciden demasiado
- FFA con reingreso mal balanceado
- complejidad de inputs y camara para entidades fuera de arena

**Dependencias:** Etapas 11 y 9. No conviene implementarla antes de que Team vs Team sea divertido sin post-muerte.

## Etapa 13 - UI, legibilidad y postpartida

**Objetivo:** reforzar lectura de estado y explicar por que se gano o perdio sin convertir la pantalla en una planilla.

**Sistemas involucrados:**
- HUD explicito con energia y vida visibles
- HUD limpio con informacion contextual
- indicadores sobre el robot: humo, chispas, piezas flojas, desgaste
- avisos de redistribucion, Overdrive y danio critico
- stats simples de fin de partida
- explicacion de causa de muerte
- replays o snippets de jugadas importantes como sistema futuro

**Criterio de exito:**
- un espectador casual entiende quien esta en peligro y por que
- el HUD ayuda sin tapar la lectura del cuerpo del robot
- perder se siente como "casi lo tenia" o "me la hicieron bien"
- la postpartida motiva otra ronda

**Riesgos tecnicos:**
- exceso de numeros en pantalla compartida
- indicadores visuales demasiado sutiles para ser utiles
- replay costoso si se intenta demasiado pronto
- causa de muerte dificil de explicar si los eventos no se registran bien

**Dependencias:** Etapas 4, 5, 7 y 11. Los replays dependen de registrar eventos desde etapas anteriores.

## Dependencias resumidas

1. La base tecnica habilita movimiento.
2. El movimiento habilita choques.
3. Los choques habilitan bordes letales y danio modular.
4. El danio modular habilita energia significativa, partes desprendidas y recuperacion.
5. Energia, partes y recuperacion habilitan arquetipos con identidad.
6. Arquetipos, items y mapas habilitan modos completos.
7. Modos completos habilitan post-muerte y postpartida con sentido.

## Que conviene prototipar primero en Godot

Lo primero deberia ser una escena de "laboratorio de choque" con dos robots, una plataforma simple y borde letal opcional.

**Contenido del prototipo inicial:**
- dos robots controlables en Easy
- movimiento con aceleracion, derrape y freno ajustables
- orientacion automatica hacia direccion de movimiento
- colision robot contra robot con empuje segun velocidad y direccion
- una arena rectangular o circular con borde letal
- debug visual de velocidad, direccion de impulso y fuerza del ultimo choque
- reinicio rapido de ronda

**Por que primero esto:**
- valida la fantasia principal antes de gastar tiempo en items, UI o muchos personajes
- permite ajustar "peso industrial" con variables visibles
- revela temprano si la fisica elegida en Godot sirve para empujes justos
- deja probar el ritmo base de tanteo, reposicionamiento y choque decisivo
- mantiene el proyecto jugable despues del primer avance real

Cuando ese laboratorio sea divertido sin danio, el siguiente prototipo inmediato deberia agregar cuatro partes con vida, aunque sea con visuales temporales. Si el choque no se siente bien antes de eso, todo lo demas va a disfrazar un problema central.
