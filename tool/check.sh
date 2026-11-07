#!/usr/bin/env bash
# Runs pub get, analyze and test in every package and in the sample.
set -euo pipefail
cd "$(dirname "$0")/.."
for dir in packages/flocon packages/flocon_crash_reporter packages/flocon_dio packages/flocon_qr_scanner packages/flocon_files packages/flocon_http packages/flocon_shared_preferences sample; do
  echo "== $dir"
  (cd "$dir" && flutter pub get >/dev/null && flutter analyze && { [ ! -d test ] || flutter test; })
done
