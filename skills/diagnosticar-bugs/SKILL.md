---
name: diagnosticar-bugs
description: Bucle de diagnóstico para bugs difíciles y regresiones de rendimiento. Usar cuando el usuario pida diagnosticar o depurar algo, o informe que algo está roto, lanza errores, falla o funciona lentamente.
license: MIT (c) Matt Pocock — ver LICENSE en este directorio
metadata:
  source: https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnosing-bugs
  adaptation: traducción al español
---

# Diagnosticar bugs

Una disciplina para bugs difíciles. Omití fases únicamente cuando exista una justificación explícita.

Al explorar el código, leé `CONTEXT.md` (si existe) para construir un modelo mental claro de los módulos relevantes y revisá los ADR del área que estás modificando.

## Redactar secretos

Este skill requiere mostrar comandos, salidas y artefactos capturados. **Redactá primero todos los secretos**: reemplazalos por `<REDACTED>`. Construí los bucles usando variables de entorno, para que la credencial permanezca en el entorno y no aparezca en lo que mostrás. Los artefactos capturados pueden contener encabezados de autenticación: citá únicamente las líneas que contienen la señal relevante.

Si la salida redactada no alcanza para diagnosticar el bug, decilo y pedile información al usuario.

## Fases

Recorré las fases en orden, leyendo las instrucciones de cada una en su archivo separado y siguiendo su flujo tal cual. No te saltees una fase sin justificación explícita, y no avances a la siguiente hasta cumplir el criterio de cierre de la actual.

| Fase | Instrucciones |
| --- | --- |
| 1. Construir bucle de feedback | `fases/construir-bucle/INSTRUCCIONES.md` |
| 2. Reproducir y minimizar | `fases/reproducir-minimizar/INSTRUCCIONES.md` |
| 3. Formular hipótesis | `fases/formular-hipotesis/INSTRUCCIONES.md` |
| 4. Instrumentar | `fases/instrumentar/INSTRUCCIONES.md` |
| 5. Corregir y agregar el test de regresión | `fases/corregir-testear/INSTRUCCIONES.md` |
| 6. Limpiar | `fases/limpiar/INSTRUCCIONES.md` |
