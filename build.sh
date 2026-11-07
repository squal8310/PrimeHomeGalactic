#!/usr/bin/env bash
# Compila la app Hello World. Regenera las propiedades de proxy de Gradle
# a partir del proxy de salida vigente en el entorno (su contrasena rota),
# asi que no se guarda ninguna credencial en archivos del proyecto.
set -e
cd "$(dirname "$0")"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
read PROXY_USER PROXY_PASS <<< $(python3 -c "import os,urllib.parse;u=urllib.parse.urlparse(os.environ['https_proxy']);print(u.username, u.password)")
./gradlew assembleDebug --no-daemon \
  -DsystemProp.http.proxyHost=hatch-egress-proxy -DsystemProp.http.proxyPort=3128 \
  -DsystemProp.http.proxyUser="$PROXY_USER" -DsystemProp.http.proxyPassword="$PROXY_PASS" \
  -DsystemProp.https.proxyHost=hatch-egress-proxy -DsystemProp.https.proxyPort=3128 \
  -DsystemProp.https.proxyUser="$PROXY_USER" -DsystemProp.https.proxyPassword="$PROXY_PASS" \
  -DsystemProp.http.nonProxyHosts="localhost|127.0.0.1" \
  -DsystemProp.https.nonProxyHosts="localhost|127.0.0.1"
