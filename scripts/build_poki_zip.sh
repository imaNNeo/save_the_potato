#!/bin/bash
# Builds a self-contained web zip for uploading to Poki (poki.com).
# Everything is bundled locally; the only external request is Poki's SDK.
set -e

if [[ ! -f "pubspec.yaml" ]]; then
  echo "Run this from the project root." >&2
  exit 1
fi

OUT_DIR="build/poki"
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')
ZIP="build/save_the_potato_poki_${VERSION}.zip"
# Rive loads its wasm from jsDelivr by default; bundle it instead.
flutter pub get >/dev/null
RIVE_NATIVE_DIR=$(sed -n 's#.*"rootUri": "file://\(.*rive_native-[^"]*\)".*#\1#p' .dart_tool/package_config.json)
RIVE_WASM_VERSION=$(sed -n "s/const wasmVersion = '\(.*\)';/\1/p" "$RIVE_NATIVE_DIR/lib/src/wasm_version.dart")

rm -rf "$OUT_DIR" "$ZIP"
flutter build web --release \
  --dart-define=RIVE_NATIVE_WASM_HOST=rive/ \
  --no-web-resources-cdn \
  --pwa-strategy=none \
  --no-wasm-dry-run \
  -o "$OUT_DIR"

# Rive runtime wasm
TMP=$(mktemp -d)
(cd "$TMP" && npm pack -q "@rive-app/flutter-native-wasm@${RIVE_WASM_VERSION}" >/dev/null && tar xzf ./*.tgz)
mkdir -p "$OUT_DIR/rive"
cp -r "$TMP/package/wasm" "$TMP/package/wasm_compatibility" "$OUT_DIR/rive/"
rm -rf "$TMP"

# Poki page: no <base href>, Poki SDK glue, no page scrolling
cp web_poki/index.html "$OUT_DIR/index.html"

# Drop what the canvaskit/dart2js build never loads
rm -rf "$OUT_DIR"/canvaskit/skwasm* "$OUT_DIR"/canvaskit/wimp* \
  "$OUT_DIR"/canvaskit/webparagraph "$OUT_DIR/manifest.json" "$OUT_DIR/icons"
find "$OUT_DIR" -name '*.symbols' -delete
rm -f "$OUT_DIR"/assets/packages/flutter_soloud/web/*_mt.*

(cd "$OUT_DIR" && zip -qr -9 "../$(basename "$ZIP")" .)
echo "Created $ZIP ($(du -h "$ZIP" | cut -f1))"
