#!/usr/bin/env bash
# Compilacion manual RELEASE de la app Hello World SIN Gradle.
# Basado en build-manual.sh; el build de Gradle esta bloqueado en esta VM
# (daemon incomunicado y descarga de AGP 8.5.2 falla por SSL a traves del proxy).
# Compila con kotlinc + aapt2 + d8 + zipalign + apksigner y firma con el
# keystore release propio (alias helloworld, CN=Texcjose, O=Texcjose, C=MX).
# La contrasena del keystore NO esta en este script: se lee en tiempo de
# compilacion de .release-keystore-password (permisos 0600).
# Uso: ./build-release.sh
# Salida: HelloWorld-release.apk
set -e
cd "$(dirname "$0")"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
SDK="$HOME/Android/Sdk"
BT="$SDK/build-tools/34.0.0"
KOTLINC="$HOME/workspace/android-tools/kotlinc/bin/kotlinc"
if [ ! -f release.keystore ]; then
  echo "ERROR: no existe release.keystore en $(pwd)" >&2
  exit 1
fi
if [ ! -f .release-keystore-password ]; then
  echo "ERROR: no existe .release-keystore-password en $(pwd)" >&2
  exit 1
fi
PASS="$(cat .release-keystore-password)"
W="$(mktemp -d /tmp/hello-release.XXXXXX)"
trap 'rm -rf "$W"; unset PASS' EXIT
mkdir -p "$W/classes" "$W/gen" "$W/dex"
# El manifest de Gradle no trae package (lo aporta el namespace); aapt2 si lo exige.
# Ademas se marca explicitamente android:debuggable="false" para el build release.
sed -e 's|<manifest |<manifest package="com.texcjose.helloworld" |' \
    -e 's|<application|<application android:debuggable="false"|' \
  app/src/main/AndroidManifest.xml > "$W/AndroidManifest.xml"
"$BT/aapt2" compile --dir app/src/main/res -o "$W/compiled.zip"
"$BT/aapt2" link -o "$W/app-unsigned.apk" --manifest "$W/AndroidManifest.xml" \
  -I "$SDK/platforms/android-34/android.jar" "$W/compiled.zip" \
  --min-sdk-version 24 --target-sdk-version 34 \
  --version-code 1 --version-name 1.0 --auto-add-overlay --java "$W/gen"
"$KOTLINC" app/src/main/java/com/texcjose/helloworld/MainActivity.kt \
  "$W/gen/com/texcjose/helloworld/R.java" \
  -cp "$SDK/platforms/android-34/android.jar" -d "$W/classes"
(cd "$W/classes" && jar cf "$W/classes.jar" .)
# d8 imprime muchos warnings de metadata de Kotlin 2.4 vs R8 8.2; son solo avisos.
"$BT/d8" --lib "$SDK/platforms/android-34/android.jar" --output "$W/dex" \
  "$W/classes.jar" "$HOME/workspace/android-tools/kotlinc/lib/kotlin-stdlib.jar" \
  > "$W/d8.log" 2>&1 || { cat "$W/d8.log"; exit 1; }
cp "$W/app-unsigned.apk" "$W/app-with-dex.apk"
(cd "$W/dex" && zip -j "$W/app-with-dex.apk" classes.dex >/dev/null)
"$BT/zipalign" -f 4 "$W/app-with-dex.apk" "$W/app-aligned.apk"
"$BT/apksigner" sign --ks release.keystore --ks-pass "pass:$PASS" \
  --key-pass "pass:$PASS" --ks-key-alias helloworld \
  --out HelloWorld-release.apk "$W/app-aligned.apk"
"$BT/apksigner" verify --print-certs HelloWorld-release.apk
"$BT/aapt2" dump badging HelloWorld-release.apk | head -n 6
ls -lh HelloWorld-release.apk
