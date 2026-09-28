# Formato del informe

Traducir los encabezados y el texto explicativo al idioma elegido para el
informe. Conservar comandos, identificadores, citas y salidas técnicas en su
idioma original.

## Contexto fijado

Incluir:

- número, URL y estado de la PR;
- rama y SHA de base;
- rama y SHA de cabeza;
- merge-base usado como punto fijo;
- ticket o fuente de especificación;
- cantidad de archivos y líneas del diff;
- commits incluidos.

## Estándares

Presentar, en este orden:

1. Hallazgos verificados.
2. Observaciones.
3. Verificaciones inconclusas.

Para cada hallazgo verificado usar esta estructura:

```text
<Título factual>
Ubicación: <archivo y línea o fragmento>
Condición inicial: <datos y estado necesarios>
Reproducción: <comando o pasos exactos>
Resultado esperado: <resultado objetivo y su fuente>
Ejecuciones en HEAD: <resultado 1> / <resultado 2>
Comparación con merge-base: <resultado 1> / <resultado 2> / <no aplica y motivo>
Causa demostrada: <relación concreta con el diff>
Impacto: <comportamiento específico que falla o deja de funcionar>
Dirección de corrección: <propuesta todavía no implementada ni validada>
```

Para cada observación usar:

```text
<Nombre de la regla o code smell>
Ubicación: <archivo y fragmento>
Evidencia: <condición estática exacta>
Regla: <archivo y regla documentada, o nombre del code smell>
Dirección de mejora: <cambio sugerido sin afirmar impacto>
```

Para cada verificación inconclusa usar:

```text
<Comportamiento investigado>
Evidencia obtenida: <hechos observados>
Falta comprobar: <causa, repetibilidad o dato pendiente>
Motivo del bloqueo: <si aplica>
```

Si una categoría no contiene elementos, escribir «Ninguno» en el idioma del
informe. No agregar texto positivo para compensar una sección vacía.

## Especificación

Usar las mismas tres categorías y formatos. Cada hallazgo u observación debe
citar además el requisito exacto. Si el eje fue omitido con autorización,
indicarlo aquí junto con el motivo.

## Validaciones ejecutadas

Enumerar los comandos ejecutados, worktree correspondiente y resultado. Agrupar
las dos ejecuciones idénticas sin ocultar que fueron dos. No copiar salidas
extensas; incluir el fragmento mínimo que demuestra el resultado.

## Limitaciones y omisiones

Registrar:

- validaciones bloqueadas;
- validaciones que el usuario autorizó omitir;
- recursos o servicios no disponibles;
- partes del cambio que no pudieron verificarse;
- redacciones realizadas para proteger datos sensibles.

## Resumen por eje

Cerrar con una línea independiente para Estándares y otra para Especificación.
Cada línea indica la cantidad de hallazgos verificados, observaciones y
verificaciones inconclusas. No elegir un problema ganador entre ejes y no emitir
un veredicto global.
