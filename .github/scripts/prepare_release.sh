#!/usr/bin/env bash
# Usage: prepare_release.sh <version> <generated-notes-file>
# Aligns every package on <version>: pubspec version, flocon dependency, CHANGELOG section.
# - '## Unreleased' in a CHANGELOG is renamed to '## <version>' (hand-written notes win).
# - otherwise flocon gets the generated notes, the plugins a 'version aligned' line.
set -euo pipefail

version="$1"
notes="$2"
flocon_range="^${version%%[-+]*}"

for dir in packages/*/; do
  package="$(basename "$dir")"
  sed -i.bak -E "s/^version: .*/version: ${version}/; s/^  flocon: \^.*/  flocon: ${flocon_range}/" "${dir}pubspec.yaml"
  rm "${dir}pubspec.yaml.bak"

  changelog="${dir}CHANGELOG.md"
  if grep -q '^## Unreleased$' "$changelog"; then
    sed -i.bak "s/^## Unreleased\$/## ${version}/" "$changelog"
    rm "${changelog}.bak"
  else
    if [ "$package" = flocon ] && [ -s "$notes" ]; then
      body="$(cat "$notes")"
    elif [ "$package" = flocon ]; then
      body="- No user-facing change."
    else
      body="- Version aligned with flocon ${version}."
    fi
    { printf '## %s\n%s\n\n' "$version" "$body"; cat "$changelog"; } > "${changelog}.new"
    mv "${changelog}.new" "$changelog"
  fi
done
