#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -f config.json ]; then cp config.example.json config.json; fi
flutter pub get
echo 'Edite config.json, execute supabase/schema.sql e use: flutter run -d chrome --web-port=3000 --dart-define-from-file=config.json'
