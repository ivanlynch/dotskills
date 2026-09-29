# Referencia operativa de ADB

Esta referencia reúne comandos para administrar y automatizar dispositivos
Android con Android Debug Bridge (ADB). Los comandos que cambian el dispositivo
pueden borrar datos, modificar la configuración, instalar software o reiniciar
el equipo. Confirma siempre el serial y la intención exacta antes de ejecutarlos.

Cuando hay varios dispositivos conectados, agrega `-s <serial>` inmediatamente
después de `adb`:

~~~bash
adb -s <serial> shell getprop ro.product.model
~~~

## Conexión del dispositivo

### USB y estado

~~~bash
# Comprobar los dispositivos conectados
adb devices
adb devices -l

# Reiniciar el servidor ADB si el estado quedó atascado
adb kill-server && adb start-server
~~~

Acepta la solicitud de autorización en el dispositivo. Un dispositivo que
aparece como `unauthorized` todavía no confía en este equipo.

### ADB inalámbrico

En Android 11 o posterior, obtén el código y los puertos desde **Opciones de
desarrollador → Depuración inalámbrica**:

~~~bash
# Emparejar por primera vez
adb pair <ip-del-dispositivo>:<puerto-de-emparejamiento> <codigo>

# Conectar después de emparejar
adb connect <ip-del-dispositivo>:<puerto-de-conexion>

# Desconectar
adb disconnect <ip-del-dispositivo>:<puerto>
~~~

## Gestión de aplicaciones

~~~bash
# Listar todos los paquetes
adb shell pm list packages

# Listar solo aplicaciones de terceros
adb shell pm list packages -3

# Buscar un paquete
adb shell pm list packages | grep -i "palabra-clave"

# Instalar un APK
adb install /ruta/a/la/app.apk

# Instalar con opciones
adb install -r app.apk          # Reemplazar la instalación existente
adb install -d app.apk          # Permitir una versión anterior
adb install -g app.apk          # Conceder todos los permisos solicitados

# Desinstalar una aplicación
adb uninstall com.example.app

# Desinstalar y conservar los datos
adb uninstall -k com.example.app

# Borrar los datos de una aplicación
adb shell pm clear com.example.app

# Forzar la detención
adb shell am force-stop com.example.app

# Consultar la información del paquete
adb shell dumpsys package com.example.app

# Obtener la ruta del APK
adb shell pm path com.example.app

# Extraer el APK del dispositivo
adb pull $(adb shell pm path com.example.app | cut -d: -f2) ./app.apk

# Deshabilitar o habilitar una aplicación
adb shell pm disable-user com.example.app
adb shell pm enable com.example.app

# Listar paquetes deshabilitados
adb shell pm list packages -d
~~~

Verifica el nombre del paquete antes de desinstalar, limpiar datos, deshabilitar
o conceder permisos. Si hay varios usuarios en el dispositivo, comprueba también
el usuario objetivo.

## Transferencia de archivos

~~~bash
# Copiar un archivo al dispositivo
adb push archivo_local.txt /sdcard/

# Copiar un directorio al dispositivo
adb push ./directorio_local /sdcard/

# Extraer un archivo
adb pull /sdcard/archivo.txt ./

# Extraer un directorio
adb pull /sdcard/DCIM ./fotos

# Listar archivos
adb shell ls -la /sdcard/

# Crear un directorio
adb shell mkdir -p /sdcard/MiCarpeta

# Borrar un archivo: confirma la ruta antes de ejecutarlo
adb shell rm /sdcard/archivo.txt

# Borrar un directorio y su contenido: operación destructiva
adb shell rm -rf /sdcard/MiCarpeta

# Consultar el espacio disponible
adb shell df -h

# Buscar archivos
adb shell find /sdcard -name "*.jpg" -type f
~~~

Prefiere una carpeta temporal específica y extrae solo los archivos necesarios.
No uses `rm -rf` si el usuario no pidió borrar exactamente esa ruta.

## Capturas y grabación de pantalla

~~~bash
# Guardar una captura en el dispositivo
adb shell screencap /sdcard/captura.png

# Guardar una captura directamente en el equipo local
adb exec-out screencap -p > captura.png

# Iniciar una grabación en el dispositivo
adb shell screenrecord /sdcard/video.mp4

# Grabar durante un tiempo y con una resolución concreta
adb shell screenrecord --time-limit 30 --size 720x1280 --bit-rate 4000000 /sdcard/video.mp4

# Detener la grabación interactiva con Ctrl+C o esperar el límite

# Extraer la grabación
adb pull /sdcard/video.mp4 ./
~~~

La duración máxima habitual de `screenrecord` es 180 segundos. Comprueba el
espacio disponible antes de grabar y elimina el archivo del dispositivo solo
cuando ya no sea necesario.

Si está instalado `scrcpy`, úsalo para reflejar y controlar la pantalla en
tiempo real:

~~~bash
scrcpy
~~~

## Simulación de entradas

~~~bash
# Tocar las coordenadas (x, y)
adb shell input tap 500 1000

# Deslizar (x1, y1, x2, y2, duración en milisegundos)
adb shell input swipe 500 1500 500 500 300

# Desplazar hacia arriba
adb shell input swipe 500 1500 500 500 200

# Desplazar hacia abajo
adb shell input swipe 500 500 500 1500 200

# Desplazar hacia la izquierda
adb shell input swipe 800 1000 200 1000 200

# Desplazar hacia la derecha
adb shell input swipe 200 1000 800 1000 200

# Mantener presionado
adb shell input swipe 500 1000 500 1000 1000

# Escribir texto sin espacios
adb shell input text "HolaMundo"

# Escribir texto con espacios: usa %s
adb shell input text "Hola%sMundo"

# Eventos de teclas
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_MENU
adb shell input keyevent KEYCODE_POWER
adb shell input keyevent KEYCODE_VOLUME_UP
adb shell input keyevent KEYCODE_VOLUME_DOWN
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_DEL
adb shell input keyevent KEYCODE_TAB
adb shell input keyevent KEYCODE_ESCAPE

# Códigos numéricos frecuentes
adb shell input keyevent 3    # Inicio
adb shell input keyevent 4    # Atrás
adb shell input keyevent 26   # Encendido
adb shell input keyevent 24   # Subir volumen
adb shell input keyevent 25   # Bajar volumen
adb shell input keyevent 66   # Enter
adb shell input keyevent 67   # Retroceso
adb shell input keyevent 82   # Menú

# Activar o bloquear la pantalla
adb shell input keyevent KEYCODE_WAKEUP
adb shell input keyevent KEYCODE_SLEEP
adb shell input keyevent KEYCODE_POWER

# Abrir aplicaciones recientes
adb shell input keyevent KEYCODE_APP_SWITCH

# Solicitar una captura con una tecla
adb shell input keyevent KEYCODE_SYSRQ
~~~

Antes de tocar o escribir, verifica la resolución, orientación y estado de la
pantalla. Para flujos frágiles, combina las coordenadas con una captura o un
volcado de la jerarquía de la interfaz.

## Actividades e intents

~~~bash
# Iniciar una actividad concreta
adb shell am start -n com.package.name/.ActivityName

# Iniciar una actividad mediante una acción
adb shell am start -a android.intent.action.VIEW -d "https://google.com"

# Abrir una URL en el navegador
adb shell am start -a android.intent.action.VIEW -d "https://example.com"

# Abrir ajustes
adb shell am start -a android.settings.SETTINGS

# Abrir pantallas de ajustes específicas
adb shell am start -a android.settings.WIFI_SETTINGS
adb shell am start -a android.settings.BLUETOOTH_SETTINGS
adb shell am start -a android.settings.DISPLAY_SETTINGS
adb shell am start -a android.settings.SOUND_SETTINGS
adb shell am start -a android.settings.APPLICATION_SETTINGS

# Enviar un broadcast
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED

# Iniciar un servicio
adb shell am startservice -n com.package.name/.ServiceName

# Finalizar procesos en segundo plano
adb shell am kill-all
~~~

Confirma la actividad, el intent y los extras antes de enviarlos. Un broadcast
del sistema o un servicio puede producir efectos que no son reversibles.

## Información del dispositivo

~~~bash
# Modelo
adb shell getprop ro.product.model

# Versión de Android
adb shell getprop ro.build.version.release

# Versión del SDK
adb shell getprop ro.build.version.sdk

# Número de serie
adb shell getprop ro.serialno

# Todas las propiedades
adb shell getprop

# Batería
adb shell dumpsys battery

# Memoria
adb shell dumpsys meminfo

# Uso de CPU
adb shell dumpsys cpuinfo

# Información de pantalla
adb shell dumpsys display | grep -i "mBaseDisplayInfo"

# Resolución
adb shell wm size

# Densidad
adb shell wm density

# Información de Wi-Fi
adb shell dumpsys wifi | grep -i "mWifiInfo"

# Dirección IP
adb shell ip addr show wlan0

# Estadísticas de red
adb shell dumpsys netstats

# Procesos activos
adb shell ps -A

# Procesos con más consumo
adb shell top -n 1

# Espacio de almacenamiento
adb shell df -h
~~~

Trata el número de serie, el identificador de Android, las direcciones IP y los
volcados del sistema como datos potencialmente sensibles.

## Logcat y registros del sistema

~~~bash
# Ver registros en tiempo real
adb logcat

# Vaciar el búfer
adb logcat -c

# Volcar y terminar
adb logcat -d

# Filtrar por etiqueta
adb logcat -s "MiEtiqueta:*"

# Filtrar por prioridad: V, D, I, W, E o F
adb logcat "*:E"
adb logcat "*:W"

# Filtrar por el proceso de una aplicación
adb logcat --pid=$(adb shell pidof -s com.example.app)

# Guardar registros
adb logcat -d > logs.txt

# Incluir marcas de tiempo
adb logcat -v time

# Incluir información de hilos
adb logcat -v threadtime

# Elegir un búfer
adb logcat -b crash
adb logcat -b events
adb logcat -b main
adb logcat -b system
~~~

Filtra por proceso o etiqueta cuando sea posible y evita guardar registros que
contengan datos personales innecesarios. Para depurar un fallo, conserva el
comando usado, el intervalo de tiempo y el filtro aplicado.

## Ajustes del sistema

~~~bash
# Leer un ajuste
adb shell settings get system screen_brightness
adb shell settings get global airplane_mode_on
adb shell settings get secure android_id

# Cambiar un ajuste del sistema
adb shell settings put system screen_brightness 128

# Cambiar un ajuste global
adb shell settings put global airplane_mode_on 1

# Listar ajustes
adb shell settings list system
adb shell settings list global
adb shell settings list secure

# Brillo, entre 0 y 255
adb shell settings put system screen_brightness 200

# Tiempo de espera de pantalla, en milisegundos
adb shell settings put system screen_off_timeout 60000

# Desactivar animaciones
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0
~~~

Lee el valor actual antes de modificar un ajuste y registra el valor anterior si
el cambio debe poder revertirse. La capacidad de cambiar ajustes depende de la
versión de Android, del fabricante y del usuario activo.

## Red y conectividad

~~~bash
# Activar o desactivar Wi-Fi
adb shell svc wifi enable
adb shell svc wifi disable

# Activar o desactivar datos móviles
adb shell svc data enable
adb shell svc data disable

# Activar el modo avión
adb shell settings put global airplane_mode_on 1
adb shell am broadcast -a android.intent.action.AIRPLANE_MODE

# Consultar redes Wi-Fi
adb shell dumpsys wifi | grep "SSID"

# Reenviar un puerto del equipo al dispositivo
adb forward tcp:8080 tcp:8080

# Reenviar un puerto del dispositivo al equipo
adb reverse tcp:8080 tcp:8080

# Quitar un reenvío
adb forward --remove tcp:8080

# Listar reenvíos
adb forward --list
~~~

No desactives conectividad ni expongas puertos sin confirmar el impacto. Libera
los reenvíos creados por una prueba cuando ya no sean necesarios.

## Energía y reinicio

~~~bash
# Reiniciar normalmente
adb reboot

# Reiniciar en recuperación
adb reboot recovery

# Reiniciar en el gestor de arranque
adb reboot bootloader

# Apagar: normalmente requiere root
adb shell reboot -p

# Mantener el dispositivo despierto mientras está conectado por USB
adb shell svc power stayon usb

# Desactivar la opción de permanecer despierto
adb shell svc power stayon false

# Nivel de batería
adb shell dumpsys battery | grep level

# Estado de carga
adb shell dumpsys battery | grep status
~~~

Advierte que un reinicio interrumpe procesos y puede cerrar cambios no guardados.
No uses el gestor de arranque ni el apagado salvo que el usuario lo pida de forma
explícita.

## Operaciones avanzadas

~~~bash
# Abrir una shell interactiva
adb shell

# Ejecutar como un usuario concreto de una aplicación
adb shell run-as com.example.app

# Actividad actual
adb shell dumpsys activity activities | grep "mResumedActivity"

# Ventana actual
adb shell dumpsys window windows | grep -E "mCurrentFocus|mFocusedApp"

# Volcar la jerarquía de la interfaz
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ./

# Volcar la jerarquía directamente
adb exec-out uiautomator dump /dev/tty

# Generar eventos aleatorios para una aplicación
adb shell monkey -p com.example.app -v 500

# Conceder o revocar un permiso
adb shell pm grant com.example.app android.permission.CAMERA
adb shell pm revoke com.example.app android.permission.CAMERA

# Listar permisos
adb shell pm list permissions -g

# Comprobar permisos de un paquete
adb shell dumpsys package com.example.app | grep "permission"

# Copia de seguridad de aplicaciones
adb backup -apk -shared -all -f backup.ab

# Restaurar una copia
adb restore backup.ab
~~~

Una shell interactiva, `run-as`, `monkey`, las copias y los permisos pueden
exponer o cambiar datos. Usa el paquete y los permisos exactos, y guarda las
copias en una ubicación protegida.

## Flujos de automatización

Estos ejemplos son plantillas. Sustituye el paquete, la ruta y las coordenadas
por valores verificados para el dispositivo objetivo.

### Prueba automatizada de una aplicación

~~~bash
#!/bin/bash
# Flujo automatizado de prueba

APP_PACKAGE="com.example.app"
APK_PATH="./app.apk"

echo "Instalando la aplicación..."
adb install -r "$APK_PATH"

echo "Abriendo la aplicación..."
adb shell am start -n "$APP_PACKAGE/.MainActivity"
sleep 3

echo "Tomando la captura inicial..."
adb exec-out screencap -p > screenshot_initial.png

echo "Ejecutando acciones..."
adb shell input tap 540 960
sleep 1
adb shell input swipe 540 1500 540 500 300
sleep 1
adb shell input tap 540 500

echo "Tomando la captura final..."
adb exec-out screencap -p > screenshot_final.png

echo "Recolectando registros..."
adb logcat -d --pid=$(adb shell pidof -s "$APP_PACKAGE") > app_logs.txt

echo "Prueba terminada."
~~~

### Comprobación de salud del dispositivo

~~~bash
#!/bin/bash
# Comprobación de salud

echo "=== COMPROBACIÓN DEL DISPOSITIVO ==="
echo ""

echo "Información:"
echo "  Modelo: $(adb shell getprop ro.product.model)"
echo "  Android: $(adb shell getprop ro.build.version.release)"
echo "  SDK: $(adb shell getprop ro.build.version.sdk)"
echo ""

echo "Batería:"
adb shell dumpsys battery | grep -E "level|status|temperature"
echo ""

echo "Almacenamiento:"
adb shell df -h /data | tail -1
echo ""

echo "Memoria:"
adb shell cat /proc/meminfo | head -3
echo ""

echo "Aplicaciones en ejecución:"
adb shell ps -A | wc -l
echo ""

echo "=== FIN DE LA COMPROBACIÓN ==="
~~~

### Capturas periódicas

~~~bash
#!/bin/bash
# Tomar varias capturas con una pausa entre ellas

COUNT=${1:-5}
DELAY=${2:-2}
OUTPUT_DIR="./screenshots_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$OUTPUT_DIR"

for i in $(seq 1 "$COUNT"); do
    echo "Tomando captura $i de $COUNT..."
    adb exec-out screencap -p > "$OUTPUT_DIR/screen_$i.png"
    sleep "$DELAY"
done

echo "Capturas guardadas en $OUTPUT_DIR"
~~~

### Extracción de datos de una aplicación

~~~bash
#!/bin/bash
# Extraer datos de una aplicación

PACKAGE="$1"
OUTPUT_DIR="./app_data_$(date +%Y%m%d_%H%M%S)"

if [ -z "$PACKAGE" ]; then
    echo "Uso: $0 <nombre_del_paquete>" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Obteniendo el APK..."
APK_PATH=$(adb shell pm path "$PACKAGE" | cut -d: -f2 | tr -d '\r')
adb pull "$APK_PATH" "$OUTPUT_DIR/app.apk"

echo "Volcando información del paquete..."
adb shell dumpsys package "$PACKAGE" > "$OUTPUT_DIR/package_info.txt"

echo "Volcando permisos..."
adb shell dumpsys package "$PACKAGE" | grep "permission" > "$OUTPUT_DIR/permissions.txt"

echo "Listo. Datos guardados en $OUTPUT_DIR"
~~~

## Conexión automática y monitoreo desde Termux

El proyecto original incluye una integración opcional para mantener conexiones
ADB desde Termux. Esta skill no incluye esos archivos ni los instala. Usa esta
sección solo si tienes el checkout correspondiente y verificaste sus rutas.

### Configuración rápida

~~~bash
cd <checkout-del-proyecto-original>/termux
./setup.sh ZFOLD7 <IP_DEL_DISPOSITIVO>:<PUERTO_ADB>
~~~

La configuración original instala:

- un servicio de conexión automática que reintenta cada 30 segundos;
- un script de arranque para Termux;
- un monitor de conexión que detecta cambios de puerto;
- el comando de control `adb-control`.

### Comando adb-control

~~~bash
adb-control status   # Estado de la conexión, servicios y señal
adb-control start    # Iniciar todos los servicios y el monitor
adb-control stop     # Detener todos los servicios
adb-control restart  # Reiniciar todo
adb-control scan     # Buscar un nuevo puerto ADB
adb-control log 50   # Ver las últimas 50 líneas
adb-control monitor  # Ejecutar el monitor en primer plano
~~~

### Archivos de configuración

`~/.adb_devices` contiene direcciones de dispositivos:

~~~text
# Formato: NOMBRE=IP:PUERTO
ZFOLD7=<IP_DEL_DISPOSITIVO>:33467
PIXEL=192.168.1.104:5555
~~~

`device.env` contiene especificaciones y configuración de varias redes:

~~~bash
DEVICE_SERIAL="<SERIAL_DEL_DISPOSITIVO>"
DEVICE_ANDROID_ID="<ANDROID_ID>"
ADB_HOME_IP="<IP_DEL_DISPOSITIVO>"
ADB_RECONNECT_INTERVAL="30"
~~~

### Búsqueda automática de puertos

La depuración inalámbrica de Android puede cambiar de puerto cuando:

- se desconecta o reconecta el Wi-Fi;
- se bloquea o desbloquea la pantalla;
- se activa o desactiva la depuración inalámbrica.

La integración original:

1. detecta el fallo de conexión;
2. comprueba que la IP responde;
3. busca un puerto ADB entre 30000 y 50000;
4. actualiza la configuración;
5. vuelve a conectar automáticamente.

Búsqueda manual:

~~~bash
python3 scripts/adb_port_scan.py <IP_DEL_DISPOSITIVO> 30000 50000
~~~

### Monitor de conexión

~~~bash
# Consultar el estado actual
python3 scripts/connection_monitor.py status

# Comprobar una vez si hubo cambios
python3 scripts/connection_monitor.py check

# Monitorear continuamente cada 30 segundos
python3 scripts/connection_monitor.py run 30
~~~

Detecta:

- pérdidas de conexión;
- cambios de puerto;
- cambios de red;
- cambios de señal superiores a 10 dB.

Puede:

- actualizar la configuración si cambia el puerto;
- enviar una notificación de Termux para eventos importantes;
- registrar eventos en `~/.adb_monitor.log`.

### Escáner de radios

~~~bash
python3 scripts/radio_scan.py             # Toda la información
python3 scripts/radio_scan.py wifi        # Solo Wi-Fi
python3 scripts/radio_scan.py bluetooth   # Solo Bluetooth
python3 scripts/radio_scan.py caps        # Capacidades de radio
~~~

La salida puede incluir SSID, BSSID, RSSI, frecuencia, canal, velocidad del
enlace, estándar Wi-Fi, compatibilidad con MIMO y 6 GHz, estado de Bluetooth y
dispositivos conectados.

### Detección de dispositivos USB

~~~bash
# Listar dispositivos USB
termux-usb -l

# Identificar uno, concediendo el permiso cuando se solicite
termux-usb -r -e scripts/usb_identify.py /dev/bus/usb/001/002
~~~

### Registros y servicios

| Archivo | Contenido |
| --- | --- |
| `~/.adb_connect.log` | Eventos de conexión y cambios de puerto |
| `~/.adb_monitor.log` | Eventos del monitor y cambios de señal |
| `~/.adb_state.json` | Último estado de conexión conocido |
| `~/.adb_devices` | Configuración de dispositivos |

~~~bash
# Servicios de Termux
sv status adb-autoconnect
sv restart adb-autoconnect
sv down adb-autoconnect

# Proceso del monitor
cat ~/.adb_monitor.pid
kill $(cat ~/.adb_monitor.pid)
~~~

Secuencia de arranque original:

1. adquirir el wakelock;
2. cargar la configuración del dispositivo;
3. intentar conectar usando el puerto guardado;
4. buscar otro puerto si falla;
5. iniciar el servicio de conexión automática;
6. iniciar el monitor;
7. enviar una notificación de dispositivo listo.

## Scripts Python del proyecto original

Los siguientes nombres describen scripts del proyecto fuente; no forman parte
de esta skill. No los invoques como si fueran recursos locales sin comprobar
primero que el proyecto esté disponible:

| Script | Propósito |
| --- | --- |
| `adb_controller.py` | Operaciones ADB con manejo de errores |
| `adb_automation.py` | Automatización de interfaz y pruebas |
| `adb_monitor.py` | Streaming de logcat y métricas |
| `connection_monitor.py` | Monitor del estado ADB/Wi-Fi |
| `adb_port_scan.py` | Búsqueda de puertos ADB inalámbricos |
| `radio_scan.py` | Escáner de Wi-Fi y Bluetooth |
| `usb_identify.py` | Identificación de dispositivos USB |
| `adb-control.sh` | Interfaz de control unificada |

## Códigos de eventos de teclas frecuentes

| Tecla | Código | Nombre |
| --- | ---: | --- |
| Inicio | 3 | `KEYCODE_HOME` |
| Atrás | 4 | `KEYCODE_BACK` |
| Llamar | 5 | `KEYCODE_CALL` |
| Finalizar llamada | 6 | `KEYCODE_ENDCALL` |
| Subir volumen | 24 | `KEYCODE_VOLUME_UP` |
| Bajar volumen | 25 | `KEYCODE_VOLUME_DOWN` |
| Encendido | 26 | `KEYCODE_POWER` |
| Cámara | 27 | `KEYCODE_CAMERA` |
| Menú | 82 | `KEYCODE_MENU` |
| Enter | 66 | `KEYCODE_ENTER` |
| Retroceso | 67 | `KEYCODE_DEL` |
| Tabulador | 61 | `KEYCODE_TAB` |
| Espacio | 62 | `KEYCODE_SPACE` |
| Escape | 111 | `KEYCODE_ESCAPE` |
| Aplicaciones recientes | 187 | `KEYCODE_APP_SWITCH` |
| Silenciar | 164 | `KEYCODE_VOLUME_MUTE` |

## Resolución de problemas

### No se encuentra el dispositivo

~~~bash
adb kill-server && adb start-server
adb devices
~~~

### El dispositivo está offline

~~~bash
adb disconnect <ip-del-dispositivo>:<puerto>
adb connect <ip-del-dispositivo>:<puerto>
~~~

En una conexión USB, desconecta y vuelve a conectar el cable, y revisa la
autorización en la pantalla.

### Falta de permisos

Algunas operaciones requieren root:

~~~bash
adb root
~~~

Solo funciona si el dispositivo admite un servidor ADB con root.

### Conexión rechazada

Vuelve a emparejar el dispositivo:

~~~bash
adb pair <ip-del-dispositivo>:<puerto> <codigo-de-emparejamiento>
~~~

### Estado de un dispositivo concreto

~~~bash
adb -s <ip-del-dispositivo>:<puerto> shell getprop ro.product.model
~~~

Antes de concluir que la conexión falló, comprueba que el puerto sea el de
conexión y no el puerto de emparejamiento.

---

Adaptación al español del `SKILL.md` público de
[adb-android-control](https://github.com/hah23255/adb-android-control).
