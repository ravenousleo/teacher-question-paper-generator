$ErrorActionPreference = 'Stop'
Write-Host 'Preparing Android and Chrome runners...' -ForegroundColor Cyan
flutter create . --platforms=android,web
if ($LASTEXITCODE -ne 0) { throw 'flutter create failed. Check that Flutter is installed and on PATH.' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed. Check the dependency output above.' }
Write-Host 'Setup complete. Run: flutter run -d chrome' -ForegroundColor Green
