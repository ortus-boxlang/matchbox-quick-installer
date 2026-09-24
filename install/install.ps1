$ErrorActionPreference = "Stop"
$repository = "ortus-boxlang/matchbox-quick-installer"
$mvmHome = if ($env:MVM_HOME) { $env:MVM_HOME } else { Join-Path $HOME ".mvm" }
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()

if ($architecture -notin @("X64", "Arm64")) {
    throw "Unsupported Windows architecture: $architecture"
}
$assetArchitecture = if ($architecture -eq "Arm64") { "arm64" } else { "x64" }
$installDir = Join-Path $mvmHome "bin"
$binary = Join-Path $installDir "mvm.exe"
$tempBinary = Join-Path $installDir "mvm.exe.download"
$releaseVersion = if ($env:MVM_VERSION) { $env:MVM_VERSION } else { "latest" }
if ($releaseVersion -eq "latest") {
    $url = "https://github.com/$repository/releases/latest/download/mvm-windows-$assetArchitecture.exe"
} else {
    if ($releaseVersion.StartsWith("v")) { $releaseVersion = $releaseVersion.Substring(1) }
    if ($releaseVersion -notmatch '^\d+\.\d+\.\d+(-[A-Za-z0-9.-]+)?(\+[A-Za-z0-9.-]+)?$') {
        throw "Invalid MVM version: $releaseVersion"
    }
    $url = "https://github.com/$repository/releases/download/v$releaseVersion/mvm-windows-$assetArchitecture.exe"
}

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
try {
    Invoke-WebRequest -Uri $url -OutFile $tempBinary -UseBasicParsing
    Move-Item -Path $tempBinary -Destination $binary -Force
} finally {
    if (Test-Path $tempBinary) { Remove-Item $tempBinary -Force }
}

[Environment]::SetEnvironmentVariable("MVM_HOME", $mvmHome, "User")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { $_ })
if ($pathEntries -notcontains $installDir) {
    $userPath = (@($pathEntries) + $installDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
}
$env:MVM_HOME = $mvmHome
if (($env:Path -split ";") -notcontains $installDir) { $env:Path = "$installDir;$env:Path" }

if ($PROFILE) {
    $profileDir = Split-Path -Parent $PROFILE
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    if (-not (Test-Path $PROFILE) -or -not (Select-String -Path $PROFILE -SimpleMatch "# MVM" -Quiet)) {
        $homeLiteral = "'" + $mvmHome.Replace("'", "''") + "'"
        $binLiteral = "'" + $installDir.Replace("'", "''") + "'"
        @"
# MVM
`$env:MVM_HOME = $homeLiteral
if (`$env:Path -notlike (`$binLiteral + ';*')) { `$env:Path = `$binLiteral + ';' + `$env:Path }
"@ | Add-Content -Path $PROFILE
    }
}

Write-Host "MVM installed at $binary"
Write-Host "Restart PowerShell to use mvm in new terminals."
