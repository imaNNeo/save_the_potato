#!/usr/bin/env bash
# Fails unless the release tag equals the version name in pubspec.yaml.
# Writes name (2.0.0) and full (2.0.0+20000) to $GITHUB_OUTPUT.
set -euo pipefail
tag="$1"
full=$(grep -E '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*//' | tr -d '[:space:]')
name="${full%%+*}"
if [ "$tag" != "$name" ]; then
  echo "::error::Tag '$tag' does not match pubspec.yaml version '$full'. Bump the version or fix the tag."
  exit 1
fi
echo "Building $full"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "name=$name" >> "$GITHUB_OUTPUT"
  echo "full=$full" >> "$GITHUB_OUTPUT"
fi
