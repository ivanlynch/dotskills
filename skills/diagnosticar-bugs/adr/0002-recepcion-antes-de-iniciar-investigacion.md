# 0002. Fase "Recepción" antes de "Iniciar investigación"

## Estado

Superada por ADR 0005. Se mantiene el nombre y el orden de las fases
("Recepción" antes de "Iniciar investigación"), pero Recepción ya no
lista ni compara contra investigaciones abiertas — ver ADR 0005 para el
razonamiento actual.

## Contexto

La Fase 0 ("Preparación") hace hoy una sola cosa: `estado.sh init` genera
un `<id>` nuevo (`INV001`, `INV002`... — ver ADR 0001) y crea su carpeta.
Desde el ADR 0001, `init` **siempre crea una investigación nueva**: nunca
decide si el bug que describe el usuario ya corresponde a una
investigación abierta.

Esa decisión ("¿esto que me describen ya lo tengo abierto, o es nuevo?")
no vive en ningún lado del flujo actual. Depende de que la IA se acuerde
de revisarlo por su cuenta antes de llegar a la Fase 0 — el mismo patrón
de riesgo ya identificado en la capa semántica de la Fase 1 (paso 3 de
`fases/construir-bucle/INSTRUCCIONES.md`): una responsabilidad real, sin
dueño explícito en el flujo, sostenida solo por la buena memoria del
agente.

Como consecuencia, "Preparación" tenía un nombre que no describía bien lo
que hacía (no prepara nada — inicializa un caso, punto) y cargaba
implícitamente con una responsabilidad que nunca ejerció (detectar
duplicados).

## Decisión

Separar en dos fases con responsabilidad única cada una, en este orden:

1. **Fase 0: Recepción.** Recibe la descripción del bug y decide si ya
   existe una investigación abierta para este proyecto que corresponda a
   ese mismo síntoma.
   - **Parte mecánica** (nueva, no existe todavía): listar las
     investigaciones abiertas del proyecto — recorrer
     `$DIAGNOSTICOS_ROOT/<slug-proyecto>/INV*/` y extraer el
     `SINTOMA_USUARIO`/cabecera de cada `DIAGNOSTICO.md`. Sin esto,
     Recepción no tiene sobre qué decidir.
   - **Parte semántica** (manual, explícita a propósito — mismo criterio
     que la capa semántica de la Fase 1): comparar la descripción actual
     contra esa lista y decidir si hay match. No se mecaniza a un
     `grep`/similaridad automática: el costo de un falso positivo (mezclar
     dos bugs distintos bajo el mismo `<id>`) es alto, y construirla mal
     es peor que dejarla manual.
   - Si hay match, la investigación se retoma con su `<id>` existente y
     **no se pasa por la fase siguiente**. Si no hay match, se continúa.

2. **Fase 1: Iniciar investigación** (antes "Preparación", `fases/
   preparacion/` pasa a `fases/iniciar-investigacion/`). Responsabilidad
   única: crear la investigación nueva (`estado.sh init`) — exactamente
   lo que hace hoy, sin cambios de comportamiento. Solo se llega acá
   cuando Recepción ya confirmó que no hay una abierta, así que esta fase
   **siempre crea, nunca actualiza** — de ahí se descarta el nombre
   alternativo "Actualizar investigación": esa responsabilidad, si hiciera
   falta, es de Recepción al retomar un match, no de esta fase.

Las fases existentes 2 a 6 se renumeran a 3 a 7 en `SKILL.md`, sin cambios
de contenido.

## Consecuencias

- El flujo pasa de 7 a 8 fases: Recepción, Iniciar investigación,
  Construir bucle de feedback, Reproducir y minimizar, Formular
  hipótesis, Instrumentar, Corregir y testear, Limpiar.
- Requiere un comando nuevo y mecánico de listado (ej. `estado.sh
  listar`), que hoy no existe — dependencia directa para que Recepción
  tenga datos sobre los que decidir.
- La detección de duplicados dentro de un mismo proyecto deja de depender
  de que la IA se acuerde por su cuenta: pasa a ser un paso explícito del
  flujo, aunque su núcleo de decisión siga siendo semántico y manual (no
  eliminamos el riesgo de que la IA se equivoque comparando síntomas,
  pero lo hacemos visible y auditable en vez de implícito).
- `estado.sh init` no cambia de comportamiento — solo cambia dónde vive
  documentado (`fases/iniciar-investigacion/` en vez de `fases/
  preparacion/`) y qué fase lo antecede.
