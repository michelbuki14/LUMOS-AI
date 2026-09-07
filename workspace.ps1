# LUMOS AI Workspace
param([string]$cmd = "dev")
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$env:Path += ";C:\src\flutter\bin;C:\Python314;C:\Python314\Scripts"
Write-Host "LUMOS AI cmd: $cmd root: $root" -ForegroundColor Cyan
if ($cmd -eq "up" -or $cmd -eq "dev" -or $cmd -eq "all") {
  Write-Host "-> docker compose up" -ForegroundColor Cyan
  Push-Location $root; docker compose up -d; docker compose ps; Pop-Location
}
if ($cmd -eq "dev" -or $cmd -eq "all") {
  Write-Host "-> flutter pub get" -ForegroundColor Cyan
  Push-Location "$root\apps\desktop"; flutter pub get; Pop-Location
  Push-Location "$root\packages\mcp"; flutter pub get; Pop-Location
  Push-Location "$root\packages\sdk"; flutter pub get; Pop-Location
  Write-Host "-> flutter analyze" -ForegroundColor Cyan
  Push-Location "$root\apps\desktop"; flutter analyze; Pop-Location
}
if ($cmd -eq "run") {
  Write-Host "-> flutter run" -ForegroundColor Cyan
  Push-Location "$root\apps\desktop"; flutter run -d windows; Pop-Location
}
if ($cmd -eq "clean") {
  Write-Host "-> clean" -ForegroundColor Cyan
  Push-Location $root; docker compose down -v --remove-orphans; Pop-Location
  Push-Location "$root\apps\desktop"; flutter clean; Pop-Location
}
if ($cmd -eq "check") {
  Write-Host "-> check" -ForegroundColor Cyan
  Push-Location $root; python -m ruff check .; python -m pytest -q; Pop-Location
}
Write-Host "[OK] done. Use: .\workspace.ps1 dev|run|up|clean|check" -ForegroundColor Green
