Hello World - Android (Kotlin)
================================
Proyecto: com.texcjose.helloworld
Un solo Activity (MainActivity), una sola pantalla con "Hello World", sin menu.

COMO ABRIRLO EN ANDROID STUDIO
1. Descomprime este zip.
2. En Android Studio: File > Open > elige la carpeta del proyecto.
3. Deja que Gradle sincronice (necesita internet la primera vez).
4. Conecta tu telefono por WiFi debug o USB y dale Run.

COMO CORRERLO POR WIFI DEBUG (ADB inalambrico)
1. Telefono y computadora en el mismo WiFi.
2. En el telefono: Ajustes > Opciones de desarrollador > Depuracion inalambrica (activar).
3. En Android Studio: Device Manager > Pair devices using Wi-Fi, o en terminal: adb pair IP:PUERTO y luego adb connect IP:PUERTO.
4. Elige tu telefono como dispositivo y dale Run.

ARCHIVOS
- app/src/main/java/com/texcjose/helloworld/MainActivity.kt
- app/src/main/res/layout/activity_main.xml
- app/src/main/AndroidManifest.xml
- build-manual.sh / build-release.sh: scripts que use en mi VM (rutas de mi SDK), no son necesarios en Android Studio.

NOTA DE SEGURIDAD
Este zip NO incluye release.keystore ni su contrasena, a proposito.
Si quieres hacer un APK release en tu compu, genera tu propio keystore en Android Studio: Build > Generate Signed App Bundle / APK.
