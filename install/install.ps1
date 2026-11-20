$ErrorActionPreference = "Stop"
$repository = "ortus-boxlang/matchbox-quick-installer"
$productUrl = "https://matchbox.boxlang.io/"
$mvmHome = if ($env:MVM_HOME) { $env:MVM_HOME } else { Join-Path $HOME ".mvm" }
$matchboxHome = if ($env:MATCHBOX_HOME) { $env:MATCHBOX_HOME } else { Join-Path $HOME ".matchbox" }

$NON_INTERACTIVE = $env:MVM_NON_INTERACTIVE -in @("1", "true", "True", "TRUE")
foreach ($argument in $args) {
    switch ($argument) {
        "-y" { $NON_INTERACTIVE = $true }
        "--yes" { $NON_INTERACTIVE = $true }
        "--non-interactive" { $NON_INTERACTIVE = $true }
        "-h" {
            Write-Host "Usage: install.ps1 [--yes]"
            Write-Host ""
            Write-Host "  --yes, -y, --non-interactive  Install with the recommended defaults without prompts."
            exit 0
        }
        "--help" {
            Write-Host "Usage: install.ps1 [--yes]"
            Write-Host ""
            Write-Host "  --yes, -y, --non-interactive  Install with the recommended defaults without prompts."
            exit 0
        }
        default { throw "Unknown option: $argument" }
    }
}

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

$COLOR_RESET = ""; $COLOR_BOLD = ""; $COLOR_DIM = ""; $COLOR_ACCENT = ""; $COLOR_SUCCESS = ""; $COLOR_WARNING = ""; $COLOR_ERROR = ""
if (-not $env:NO_COLOR -and $Host.Name -eq "ConsoleHost") {
    $COLOR_BOLD = [char]27 + "[1m"
    $COLOR_DIM = [char]27 + "[2m"
    $COLOR_ACCENT = [char]27 + "[36m"
    $COLOR_SUCCESS = [char]27 + "[32m"
    $COLOR_WARNING = [char]27 + "[33m"
    $COLOR_ERROR = [char]27 + "[31m"
    $COLOR_RESET = [char]27 + "[0m"
}
$interactive = -not $NON_INTERACTIVE -and [Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected

$logo = @(
    '  ▄██████████████████████▄'
    '▄██▀▀          ▄▄      ▀▀██▄'
    '██▀          ▄███        ███'
    '██          ▄█████▄       ██'
    '██     ▄▄   ████████▄     ██'
    '██    ▄███▄ █████████▄    ██'
    '██    ████████  ██████    ██'
    '██    █████▀██   ▀████    ██'
    '██     ████       ███▀    ██'
    '██▄     ▀██▄▄   ▄██▀     ███'
    '▀██▄▄     ▀▀▀▀▀▀▀▀     ▄▄██▀'
    '  ▀██████████████████████▀'
)
$logoColors = @(
    "38;2;0;255;120", "38;2;0;247;140", "38;2;0;238;158", "38;2;0;229;177",
    "38;2;0;220;195", "38;2;0;211;213", "38;2;0;201;230", "38;2;0;192;247",
    "38;2;0;183;255", "38;2;0;174;255", "38;2;0;165;255", "38;2;0;155;255"
)

function Show-Banner {
    Write-Host ""
    for ($i = 0; $i -lt $logo.Count; $i++) {
        if ($COLOR_RESET) {
            Write-Host ("$([char]27)[$($logoColors[$i])m$($logo[$i])$COLOR_RESET")
        } else {
            Write-Host $logo[$i]
        }
    }
    Write-Host ""
    Write-Host "  ${COLOR_BOLD}${COLOR_ACCENT}MATCHBOX VERSION MANAGER${COLOR_RESET}"
    Write-Host "  The Rust runtime for BoxLang"
    Write-Host "  ${COLOR_DIM}${productUrl}${COLOR_RESET}"
    if ($interactive) { Write-Host "`n  Interactive installer" }
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "  ${COLOR_ACCENT}${COLOR_BOLD}${Text}${COLOR_RESET}"
    Write-Host ""
}

function Write-Info {
    param([string]$Text)
    Write-Host "  ${COLOR_SUCCESS}✓${COLOR_RESET}  $Text"
}

function Show-Plan {
    Write-Section "Installation plan"
    Write-Host "  Install to $mvmHome"
    Write-Host ""
    Write-Host "  ${COLOR_ACCENT}+${COLOR_RESET}  MVM version manager and launchers"
    Write-Host "  ${COLOR_ACCENT}+${COLOR_RESET}  Shell integration for PowerShell"
    Write-Host "  ${COLOR_ACCENT}+${COLOR_RESET}  MATCHBOX_HOME at $matchboxHome"
    Write-Host "  ${COLOR_ACCENT}+${COLOR_RESET}  Add MVM and MatchBox bin directories to PATH"
}

function Write-Note {
    param([string]$Text)
    Write-Host "  ${COLOR_WARNING}!${COLOR_RESET}  $Text"
}

function Invoke-Step {
    param([string]$Label, [scriptblock]$Command)
    $output = & $Command 2>&1 | Out-String
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        if ($output.Trim()) { Write-Host $output }
        throw "$Label failed"
    }
    Write-Info $Label
}

function Select-YesNo {
    param([string]$Question, [string]$YesLabel, [string]$NoLabel)

    $labels = @($YesLabel, $NoLabel)
    $active = 0
    Write-Host ""
    $origin = $Host.UI.RawUI.CursorPosition

    function Draw-Prompt {
        $Host.UI.RawUI.CursorPosition = $origin
        $lines = @(
            "  ${COLOR_BOLD}${COLOR_ACCENT}${Question}${COLOR_RESET}"
            ""
        )
        for ($i = 0; $i -lt $labels.Count; $i++) {
            $marker = " "
            $color = $COLOR_RESET
            if ($i -eq $active) {
                $marker = "›"
                $color = "$COLOR_ACCENT$COLOR_BOLD"
            }
            $lines += ("  {0}{1}  {2}{3}" -f $color, $marker, $labels[$i], $COLOR_RESET)
        }
        $lines += ""
        $lines += "  ${COLOR_DIM}↑/↓ choose · Enter continue · Esc skip${COLOR_RESET}"
        foreach ($line in $lines) { Write-Host $line.PadRight(72) }
    }

    Draw-Prompt
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { $active = 0; Draw-Prompt } # Up
            40 { $active = 1; Draw-Prompt } # Down
            13 { Draw-Prompt; return $active -eq 0 } # Enter
            27 { Draw-Prompt; return $false }        # Esc
        }
    }
}

function Install-Runtime {
    Write-Section "Installing MatchBox"
    Write-Progress -Activity "Installing MatchBox" -Status "Downloading latest release" -PercentComplete 0
    Invoke-Step "Downloaded and installed the latest MatchBox" { & $binary install latest }
    Write-Progress -Activity "Installing MatchBox" -Status "Activating release" -PercentComplete 85
    Invoke-Step "Activated the latest MatchBox" { & $binary use latest }
    Write-Progress -Activity "Installing MatchBox" -Completed
    Write-Host "`n  MatchBox is ready."
}

function Show-Summary {
    Write-Section "MVM is ready"
    Write-Info "MVM installed at $binary"
    Write-Host "`n  To use MVM in this terminal:"
    Write-Host "    . `$PROFILE"
    Write-Host "`n  ${COLOR_BOLD}Quick start:${COLOR_RESET}"
    Write-Host "    mvm install latest"
    Write-Host "    mvm use latest"
    Write-Host "    matchbox --version"
    Write-Host "`n  ${COLOR_DIM}Learn more: ${productUrl}${COLOR_RESET}`n"
}

Show-Banner
Write-Host "  ${COLOR_DIM}Windows · windows-$assetArchitecture${COLOR_RESET}"

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
try {
    $localBinary = if ($env:MVM_BIN) { $env:MVM_BIN } else { "" }
    if ($localBinary -and (Test-Path -LiteralPath $localBinary)) {
        Copy-Item -LiteralPath $localBinary -Destination $tempBinary -Force
    } else {
        Invoke-WebRequest -Uri $url -OutFile $tempBinary -UseBasicParsing
    }
    Move-Item -Path $tempBinary -Destination $binary -Force
} finally {
    if (Test-Path $tempBinary) { Remove-Item $tempBinary -Force }
}

[Environment]::SetEnvironmentVariable("MVM_HOME", $mvmHome, "User")
[Environment]::SetEnvironmentVariable("MATCHBOX_HOME", $matchboxHome, "User")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { $_ })
if ($pathEntries -notcontains $installDir) {
    $userPath = (@($pathEntries) + $installDir) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
}
$env:MVM_HOME = $mvmHome
$env:MATCHBOX_HOME = $matchboxHome
if (($env:Path -split ";") -notcontains $installDir) { $env:Path = "$installDir;$env:Path" }

Show-Plan
Write-Section "Installing MVM"
Write-Info "Detected windows-$assetArchitecture"
Write-Info "Downloaded MVM $releaseVersion"
Write-Info "Installed MVM to $binary"
Invoke-Step "Configured shell integration" { & $binary doctor --fix }

if ($NON_INTERACTIVE) {
    Install-Runtime
} elseif ($interactive) {
    if (Select-YesNo "Install the latest MatchBox runtime now?" "Yes, install and use it" "No, maybe later") {
        Install-Runtime
    } else {
        Write-Host "`n  MatchBox install skipped. Install it later with:"
        Write-Host "    mvm install latest"
        Write-Host "    mvm use latest"
        Write-Host "`n  ${COLOR_DIM}Learn more: ${productUrl}${COLOR_RESET}`n"
        exit 0
    }
}

Show-Summary
