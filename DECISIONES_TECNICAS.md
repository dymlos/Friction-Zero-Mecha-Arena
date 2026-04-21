# DECISIONES_TECNICAS.md - Friction Zero: Mecha Arena

## Decisiones vigentes

1. **Daño modular por direccion en vez de hitboxes complejos**
   - Se calcula la parte afectada segun la direccion del golpe respecto al robot impactado.
   - Motivo: valida rapido la fantasia de brazos al frente y piernas atras sin introducir una malla fisica dificil de mantener.

2. **Partes desprendidas como escena separada y simple**
   - `DetachedPart` clona los meshes visibles de la parte destruida y usa una colision aproximada por tipo.
   - Motivo: deja el sistema listo para futura recuperacion/negacion sin rehacer el robot base.

3. **Penalizaciones funcionales derivadas del estado modular**
   - Piernas afectan movilidad/control; brazos afectan empuje/ataque.
   - Motivo: cumple el objetivo de que perder partes cambie la pelea inmediatamente y de forma legible.

4. **Robot inutilizado sin explosion todavia**
   - Al perder las cuatro partes, el robot deja de actuar pero permanece fisico.
   - Motivo: preservar claridad y mantener el slice pequeno; la explosion diferida es la siguiente capa natural.

5. **Referencias de tipos con `preload()`**
   - Los scripts principales ahora precargan clases usadas en anotaciones.
   - Motivo: evitar dependencia del cache global del editor y asegurar arranque correcto en CLI/headless.

## Criterios mantenidos

- Priorizar sensacion de movimiento y choque antes que sistemas avanzados.
- Mantener escenas y scripts chicos, faciles de leer para una persona con poca experiencia en Godot.
- Evitar UI pesada: el robot comunica estado primero por el propio cuerpo.
