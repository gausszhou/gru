#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

$Repo = "gausszhou/gru"
$InstallDir = if ($env:GRU_INSTALL) { $env:GRU_INSTALL } else { Join-Path $env:LOCALAPPDATA "gru" }

# Detect architecture
$Arch = switch ($env:PROCESSOR_ARCHITECTURE) {
    "AMD64" { "amd64" }
    "ARM64" { "arm64" }
    default { throw "Unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
}

Write-Host "Checking latest version..."
$ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
$Release = Invoke-RestMethod -Uri $ApiUrl -Headers @{ "User-Agent" = "gru-installer" }
$Version = $Release.tag_name
Write-Host "Found gru $Version"

# Download and extract
$ArchiveName = "gru-windows-$Arch.zip"
$Url = "https://github.com/$Repo/releases/download/$Version/$ArchiveName"
$ZipPath = Join-Path $env:TEMP "gru.zip"
$ExePath = Join-Path $InstallDir "gru.exe"

Write-Host "Downloading $Url..."
Invoke-WebRequest -Uri $Url -OutFile $ZipPath

Write-Host "Extracting..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
Remove-Item $ZipPath

Write-Host "Installed gru $Version to $ExePath"

# Check PATH
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -and $UserPath.Contains($InstallDir)) {
    Write-Host "Already in PATH"
} else {
    Write-Host ""
    Write-Host "NOTE: $InstallDir is not in your PATH."
    Write-Host "Add it with:"
    Write-Host "  [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$InstallDir', 'User')"
    Write-Host "Then restart your terminal."
}
