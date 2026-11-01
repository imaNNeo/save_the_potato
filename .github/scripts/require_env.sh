#!/usr/bin/env bash
# Fails with one clear message listing every named variable that is empty.
set -euo pipefail
missing=()
for name in "$@"; do
  if [ -z "${!name:-}" ]; then missing+=("$name"); fi
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "::error::Missing repository secrets: ${missing[*]}. See docs/RELEASE_GUIDE.md."
  exit 1
fi
echo "All ${#@} secrets are set."
