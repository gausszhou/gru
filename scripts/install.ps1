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
$ArchiveName = "gru-windows-$Arch.tar.gz"
$Url = "https://github.com/$Repo/releases/download/$Version/$ArchiveName"
$ArchivePath = Join-Path $env:TEMP "gru.tar.gz"

Write-Host "Downloading $Url..."
Invoke-WebRequest -Uri $Url -OutFile $ArchivePath

Write-Host "Extracting..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
tar xzf $ArchivePath -C $InstallDir gru.exe
Remove-Item $ArchivePath

Write-Host "Installed gru $Version to $(Join-Path $InstallDir gru.exe)"

# Add to PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    Write-Host "Added gru to user PATH (restart terminal or run: refreshenv)"
}
