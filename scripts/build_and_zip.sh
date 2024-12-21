#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define variables
BUILD_DIR="build/web"
OUTPUT="output.zip"

# Ensure the script is run from the root directory of the project
if [[ ! -f "pubspec.yaml" ]]; then
    echo "Error: This script must be run from the root directory of your Flutter project."
    exit 1
fi

# Clean up previous builds and outputs
echo "Cleaning up previous builds and output files..."
rm -rf "$BUILD_DIR"
rm -f "$OUTPUT" "$OUTPUT_NO_WASM"

# Build the Flutter web app
echo "Building Flutter web app..."
flutter build web --release --web-renderer canvaskit --no-web-resources-cdn --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/

# Create a zip file with all files from the build directory
echo "Creating ${OUTPUT}..."
zip -r "${OUTPUT}" "${BUILD_DIR}"/*

echo "Done! Created:"
echo " - ${OUTPUT}"