#!/usr/bin/env bash
# Prints the store release notes for a version from assets/texts/release_notes.json:
# the shared lines plus the platform's own lines, one bullet each.
# Usage: release_notes.sh <version> <android|ios>
set -euo pipefail
version="$1"
platform="$2"
notes=$(jq -r --arg v "$version" --arg p "${platform}_specific" '
  map(select(.version == $v)) | first // empty
  | ((.shared // []) + (.[$p] // [])) | map("• " + .) | join("\n")
' assets/texts/release_notes.json)
if [ -z "$notes" ]; then
  echo "::error::No release notes for $version in assets/texts/release_notes.json." >&2
  exit 1
fi
if [ "$(printf '%s' "$notes" | wc -m)" -gt 500 ]; then
  echo "::error::Release notes for $version are over Play's 500 character limit." >&2
  exit 1
fi
printf '%s\n' "$notes"
