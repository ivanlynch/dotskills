---
name: controlar-android-adb
description: Controla dispositivos Android mediante ADB: conexión USB o Wi-Fi, instalación y gestión de APK, transferencia de archivos, capturas, grabación, simulación de entradas, comandos shell, logcat, información del dispositivo y automatización con Termux. Usar cuando el usuario pida administrar, depurar o automatizar un teléfono o una tableta Android con adb, depuración inalámbrica o scrcpy.
compatibility: Requiere Android SDK Platform-Tools (adb) disponible en el entorno y un dispositivo Android autorizado o una conexión ADB inalámbrica; algunas operaciones dependen de la versión de Android y de los permisos del dispositivo.
---

# Controlar Android con ADB

Usa esta skill para operar un dispositivo Android desde una computadora o desde
otro dispositivo mediante Android Debug Bridge (ADB).

## Procedimiento

1. Confirma el dispositivo objetivo y el alcance de la operación. Si hay más de
   un dispositivo conectado, usa siempre `-s <serial>` en cada comando.
2. Comprueba que `adb` esté instalado y que el dispositivo esté autorizado:

   ~~~bash
   command -v adb
   adb version
   adb devices -l
   ~~~

3. Para una conexión USB, habilita la depuración USB y acepta la autorización
   en el dispositivo. Para una conexión Wi-Fi, empareja y conecta el dispositivo
   desde las opciones de depuración inalámbrica.
4. Consulta `references/operaciones-adb.md` para elegir el comando apropiado.
   Conserva la salida relevante y verifica el resultado después de cada paso.
5. Antes de instalar, desinstalar, borrar datos o archivos, cambiar ajustes,
   reiniciar, apagar, conceder o revocar permisos, o ejecutar shell arbitrario,
   confirma que la acción, el dispositivo y el destino exactos coinciden con lo
   que pidió el usuario. No conviertas una operación de lectura en una operación
   destructiva por iniciativa propia.
6. Si una operación falla, identifica si el problema es `offline`,
   `unauthorized`, falta de permisos, un dispositivo seleccionado incorrecto o
   una limitación de la versión de Android antes de reintentar.

## Conexión rápida

~~~bash
# USB
adb devices

# Android 11 o posterior: emparejar y conectar por Wi-Fi
adb pair <ip-del-dispositivo>:<puerto-de-emparejamiento> <codigo>
adb connect <ip-del-dispositivo>:<puerto-de-conexion>

# Seleccionar explícitamente un dispositivo
adb -s <serial> shell getprop ro.product.model
~~~

## Automatización

- Para una acción aislada, ejecuta el comando ADB mínimo que la resuelva.
- Para una secuencia repetible, describe los pasos, los tiempos de espera y los
  artefactos que deben guardarse antes de ejecutarla.
- Usa `uiautomator dump`, capturas y `logcat` para observar el estado en vez de
  adivinar coordenadas o asumir que una actividad se abrió.
- Si el dispositivo se comparte con otra persona, evita imprimir o guardar
  datos personales, tokens, mensajes o archivos extraídos que no sean necesarios.
- Los scripts de Termux y Python mencionados en la referencia pertenecen al
  proyecto original y no están incluidos en esta skill. Verifica que existan
  en el checkout correspondiente antes de invocarlos.

## Referencia

La guía completa de comandos, flujos de automatización, conexión inalámbrica,
Termux, códigos de teclas y resolución de problemas está en
`references/operaciones-adb.md`.

Esta adaptación se basa en el `SKILL.md` público de
[adb-android-control](https://github.com/hah23255/adb-android-control).
