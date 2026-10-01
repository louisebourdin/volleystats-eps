#!/usr/bin/env bash
# Build de l'appli web, utilisé par Cloudflare Pages (voir README > Déploiement).
# Flutter n'étant pas préinstallé sur Cloudflare Pages, on clone le SDK stable
# avant de builder.
set -euo pipefail

rm -rf _flutter_sdk
git clone -b stable --depth 1 https://github.com/flutter/flutter.git _flutter_sdk
export PATH="$PWD/_flutter_sdk/bin:$PATH"

flutter config --no-analytics
flutter pub get
flutter build web --release
