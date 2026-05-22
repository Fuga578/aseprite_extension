# Packages AseCLI into dist/AseCLI.aseprite-extension (a ZIP archive).
# Usage: powershell -ExecutionPolicy Bypass -File scripts/build.ps1
#
# NOTE: This script is intentionally ASCII-only. Windows PowerShell 5.1 reads a
# -File script that has no BOM using the system ANSI codepage; non-ASCII bytes
# then get mis-decoded and can silently break execution. Keep this file ASCII.

$root = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "src"
$distDir = Join-Path $root "dist"
$tempZip = Join-Path $distDir "AseCLI.zip"
$output = Join-Path $distDir "AseCLI.aseprite-extension"

if (-not (Test-Path $srcDir)) {
  Write-Error "src directory not found: $srcDir"
  exit 1
}

if (-not (Test-Path $distDir)) {
  New-Item -ItemType Directory -Path $distDir | Out-Null
}

# Remove previous build artifacts.
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
if (Test-Path $output) { Remove-Item $output -Force }

# Archive the contents of src/ so that package.json sits at the archive root.
# The pipeline form passes item objects directly and is the most reliable.
Get-ChildItem -Path $srcDir | Compress-Archive -DestinationPath $tempZip -Force

if (-not (Test-Path $tempZip)) {
  Write-Error "Compress-Archive failed to create $tempZip"
  exit 1
}

# A .aseprite-extension file is just a ZIP; change the extension.
Rename-Item -Path $tempZip -NewName "AseCLI.aseprite-extension"

if (-not (Test-Path $output)) {
  Write-Error "Failed to produce $output"
  exit 1
}

Write-Host "Built: $output"
