#!/usr/bin/env bash
set -euo pipefail

# Vercel imports the entire repository, including Flutter path dependencies.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_root="$repo_root/apps/passenger_web"
flutter_version="3.35.4"
# Keep SDK Git metadata outside Vercel's restored build cache: that cache can
# retain SDK files with incomplete Git metadata pointing at the app checkout.
sdk_path="${FLUTTER_SDK_PATH:-$repo_root/.vercel/flutter-$flutter_version}"

export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
# This build targets web; it must not depend on desktop plugin symlink privileges.
export FLUTTER_WINDOWS=false
export FLUTTER_LINUX=false
# Flutter invokes Git inside its own SDK; repository variables inherited from CI
# must not redirect those commands into the application checkout.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES

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
build_defines=(--dart-define=AEROTRANS_CONNECTED_REVIEW=true)
if [[ -n "${AEROTRANS_PUBLIC_CONFIG:-}" ]]; then
  config_path="$repo_root/.vercel/cache/public-web-defines.json"
  node "$repo_root/scripts/prepare-web-config.mjs" "$config_path"
  build_defines+=(--dart-define-from-file="$config_path")
fi
cd "$app_root"
flutter pub get
flutter build web --release --no-pub \
  --target lib/main_connected.dart \
  "${build_defines[@]}" \
  --no-web-resources-cdn

test -s "$app_root/build/web/index.html"
test -s "$app_root/build/web/flutter_bootstrap.js"
printf 'Flutter website generated at apps/passenger_web/build/web.\n'
if [[ -n "${AEROTRANS_PUBLIC_CONFIG:-}" ]]; then
  printf 'Hosted test configuration included; the browser will verify the matching API before sign-in.\n'
else
  printf 'Public preview mode: sign-in awaits hosted test configuration.\n'
fi
