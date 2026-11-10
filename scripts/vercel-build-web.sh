#!/usr/bin/env bash
set -euo pipefail

# Vercel imports the entire repository, including Flutter path dependencies.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_root="$repo_root/apps/passenger_web"
flutter_version="3.35.4"
sdk_path="${FLUTTER_SDK_PATH:-$repo_root/.vercel/cache/flutter-$flutter_version}"

export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
# This build targets web; it must not depend on desktop plugin symlink privileges.
export FLUTTER_WINDOWS=false
export FLUTTER_LINUX=false

if [[ ! -x "$sdk_path/bin/flutter" ]]; then
  if [[ -e "$sdk_path" ]]; then
    printf 'Incomplete Flutter SDK cache at %s. Clear the build cache and retry.\n' "$sdk_path" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$sdk_path")"
  git clone --depth 1 --branch "$flutter_version" \
    https://github.com/flutter/flutter.git "$sdk_path"
fi

sdk_version="$(git -C "$sdk_path" describe --tags --exact-match 2>/dev/null || true)"
if [[ "$sdk_version" != "$flutter_version" ]]; then
  printf 'Expected Flutter %s; the supplied SDK has tag %s.\n' "$flutter_version" "$sdk_version" >&2
  exit 1
fi

export PATH="$sdk_path/bin:$PATH"
cd "$app_root"
flutter pub get
flutter build web --release --no-pub \
  --target lib/main_connected.dart \
  --dart-define=AEROTRANS_CONNECTED_REVIEW=true \
  --no-web-resources-cdn

test -s "$app_root/build/web/index.html"
test -s "$app_root/build/web/flutter_bootstrap.js"
printf 'Flutter website generated at apps/passenger_web/build/web.\n'
printf 'Connected login/bookings still require the separately configured hosted backend and Firebase test environment.\n'
