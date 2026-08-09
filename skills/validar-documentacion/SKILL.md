---
name: validar-documentacion
description: Audita documentación técnica terminada mediante fuentes, evidencia, consistencia y adecuación al cuadrante de Diátaxis. Úsala después de redactar; devuelve hallazgos y nunca corrige el documento.
---

# Validar documentación

Actúa como auditor independiente. No redactes, no corrijas y no rellenes datos faltantes. Comprueba el documento frente al contexto, las fuentes declaradas y el cuadrante elegido.

## Entradas

Recibe, cuando estén disponibles:

```yaml
documento: texto o ruta
cuadrante: tutorial | guia-practica | referencia | explicacion
contexto: proyecto, branch, versiones y restricciones
fuentes: fuentes visibles y evidencia de trabajo
decisiones_usuario: decisiones explícitas
```

## Auditoría

1. Identifica cada afirmación factual relevante.
2. Comprueba que tiene una fuente rastreable.
3. Prioriza, para proyectos y tareas, código, configuración, pruebas, branch e historial local.
4. Para información externa, comprueba fuentes oficiales o primarias aprobadas.
5. Verifica comandos, rutas, APIs, versiones, enlaces, ejemplos y resultados.
6. Comprueba que hechos, decisiones e inferencias estén diferenciados.
7. Comprueba exactitud, completitud, consistencia, utilidad, precisión y ausencia de ambigüedad.
8. Comprueba el propósito dominante y las reglas del cuadrante.
9. Evalúa el flujo, la anticipación de necesidades y la experiencia del lector.

No trates la ausencia de una fuente como una invitación a investigar sin autorización. Declara la evidencia faltante o solicita que `documentar` obtenga aprobación para una fuente externa.

## Severidad y salida

- **Bloqueante:** afirmación sin respaldo, contradicción con el contexto, comando no comprobable o defecto que impide cumplir el propósito.
- **Importante:** evidencia incompleta, ambigüedad relevante, paso sin comprobación o mezcla significativa de cuadrantes.
- **Menor:** mejora editorial, formato, terminología o enlace que no afecta la validez.

Devuelve:

```yaml
estado: aprobado | requiere-cambios | bloqueado
hallazgos:
  - severidad: bloqueante | importante | menor
    ubicacion: "seccion o linea"
    problema: "..."
    evidencia: "..."
    recomendacion: "..."
fuentes_validadas: []
fuentes_faltantes: []
cuadrante_validado: true | false
```

Usa `aprobado` solo cuando no existan hallazgos bloqueantes ni importantes. Usa `bloqueado` cuando falte una fuente, decisión o dato que solo pueda aportar el usuario.
