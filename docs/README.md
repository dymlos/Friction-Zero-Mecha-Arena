# Docs

Esta es la capa documental activa del proyecto. Debe mantenerse corta, revisable y util para un videojuego que todavia evoluciona con playtests, tuning y validacion real.

## Regla de idioma

- La documentacion activa se escribe en espanol.
- `docs/historial/` puede conservar documentos en ingles, mixtos o en su idioma original por tratarse de archivo historico.

## Leer primero

1. [AGENTS.md](../AGENTS.md)
2. [diseno.md](./diseno.md)
3. [estado-actual.md](./estado-actual.md)
4. [proximos-pasos.md](./proximos-pasos.md)
5. [decisiones.md](./decisiones.md)
6. [decisiones-producto.md](./decisiones-producto.md)
7. [milestones/README.md](./milestones/README.md)

## Capa activa

- [diseno.md](./diseno.md): resumen vivo del fantasy, pilares, loop, modos y criterios de claridad.
- [estado-actual.md](./estado-actual.md): snapshot corto del prototipo y sus riesgos activos.
- [proximos-pasos.md](./proximos-pasos.md): siguiente iteracion recomendada.
- [decisiones.md](./decisiones.md): reglas y restricciones que hoy siguen condicionando cambios.
- [decisiones-producto.md](./decisiones-producto.md): decisiones de producto tomadas en entrevista, separadas del estado tecnico actual.
- [milestones/README.md](./milestones/README.md): roadmap vivo por milestone.

## Archivo historico

- [historial/README.md](./historial/README.md): indice del material archivado.

## QA y validacion

- `godot-qa` ya esta listo para chequeos livianos de runtime y escenarios comprometidos del repo. Conviene usarlo primero cuando el cambio toque HUD, overlays, prompts, layout de `Control` o smoke visual de escenas.
- El entrypoint corto para agentes es: `godot-qa --project . doctor`, `godot-qa --project . scenario list` y luego un `godot-qa --project . scenario run <scenario>` enfocado.
- Las pruebas scene-level en GDScript siguen siendo la mejor referencia para contratos de mundo y camara que `godot-qa` todavia no expresa bien.
- Los escenarios en `qa/scenarios/` siguen siendo la mejor superficie para contratos de HUD y overlays que ya entran en `assert.inside_viewport` y `assert.no_overlap`.

## Regla de mantenimiento

- Mantener la capa activa corta y en espanol.
- Mover detalle viejo, snapshots largos y estructura intermedia anterior a `docs/historial/`.
- Tratar roadmap y decisiones como guias vivas, no como texto cerrado salvo cuando un contrato tecnico ya este realmente congelado.
