#!/usr/bin/env bash
# Compilacion manual de la app Hello World SIN Gradle.
# Por que: el build de Gradle esta bloqueado en esta VM por dos motivos
# (2026-11-07): el daemon de Gradle no logra comunicarse con el cliente
# ("Could not receive a message from the daemon", type tag 109) y la
# descarga del plugin AGP 8.5.2 falla por SSL a traves del proxy
# ("Unsupported or unrecognized SSL message", ver /tmp/gradle-fail.log).
# Este script usa directamente kotlinc + aapt2 + d8 + zipalign + apksigner,
# todo ya instalado en la VM, y produce HelloWorld-debug.apk firmado
# con llave debug. Uso: ./build-manual.sh
set -e
cd "$(dirname "$0")"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
SDK="$HOME/Android/Sdk"
BT="$SDK/build-tools/34.0.0"
KOTLINC="$HOME/workspace/android-tools/kotlinc/bin/kotlinc"
W="$(mktemp -d /tmp/hello-manual.XXXXXX)"
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/classes" "$W/gen" "$W/dex"
# El manifest de Gradle no trae package (lo aporta el namespace); aapt2 si lo exige.
sed 's|<manifest |<manifest package="com.texcjose.helloworld" |' \
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
if [ ! -f debug.keystore ]; then
  keytool -genkeypair -keystore debug.keystore -alias androiddebugkey \
    -storepass android -keypass android \
    -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 \
    -validity 10000 -noprompt
fi
"$BT/apksigner" sign --ks debug.keystore --ks-pass pass:android \
  --key-pass pass:android --out HelloWorld-debug.apk "$W/app-aligned.apk"
"$BT/apksigner" verify HelloWorld-debug.apk
"$BT/aapt2" dump badging HelloWorld-debug.apk | head -n 6
ls -lh HelloWorld-debug.apk
