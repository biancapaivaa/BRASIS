$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (!(Test-Path config.json)) { Copy-Item config.example.json config.json }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependências. Envie a mensagem completa.' }
Write-Host 'Edite config.json, execute supabase/schema.sql e use: flutter run -d chrome --web-port=3000 --dart-define-from-file=config.json'
