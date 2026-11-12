#!/usr/bin/env bash
# Bumps every package to <version>: pubspec version, the flocon dependency of
# the plugins, and a new '## <version>' section at the top of each CHANGELOG.md.
# Usage: tool/bump_version.sh 0.0.2 "Short description of the changes"
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -eq 2 ] || { echo "Usage: $0 <version> <changelog line>"; exit 1; }
version="$1"
note="$2"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $version"; exit 1; }

for dir in packages/*/; do
  sed -i '' -E "s/^version: .*/version: ${version}/" "${dir}pubspec.yaml"
  sed -i '' -E "s/^  flocon: \^.*/  flocon: ^${version}/" "${dir}pubspec.yaml"
  { printf '## %s\n- %s\n\n' "$version" "$note"; cat "${dir}CHANGELOG.md"; } > "${dir}CHANGELOG.md.tmp"
  mv "${dir}CHANGELOG.md.tmp" "${dir}CHANGELOG.md"
done

echo "Bumped to ${version}. Review with git diff, then merge and run:"
echo "  git tag flocon-v${version} && git push origin flocon-v${version}"
