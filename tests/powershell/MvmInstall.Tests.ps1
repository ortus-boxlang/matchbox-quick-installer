. (Join-Path $PSScriptRoot 'TestFramework.ps1')

Initialize-TestSuite 'MVM Windows installer'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$hostExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $hostExe)) {
    $hostExe = Join-Path $PSHOME 'pwsh.exe'
}
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ('mvm-ps-test-' + [guid]::NewGuid().ToString('N'))
$saved = @{
    MvmHome = [Environment]::GetEnvironmentVariable('MVM_HOME', [EnvironmentVariableTarget]::User)
    MatchboxHome = [Environment]::GetEnvironmentVariable('MATCHBOX_HOME', [EnvironmentVariableTarget]::User)
    Path = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)
    ProcessMvmHome = $env:MVM_HOME
    ProcessMatchboxHome = $env:MATCHBOX_HOME
    ProcessMvmBin = $env:MVM_BIN
    ProcessPath = $env:Path
}
$profilePath = $PROFILE
$profileExisted = Test-Path -LiteralPath $profilePath
$profileContents = if ($profileExisted) { Get-Content -LiteralPath $profilePath -Raw } else { $null }

try {
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $mvmHome = Join-Path $sandbox 'mvm'
    $env:MVM_HOME = $mvmHome
    Remove-Item Env:MATCHBOX_HOME -ErrorAction SilentlyContinue
    $localBinary = Join-Path $repo 'build/mvm.exe'
    if (Test-Path -LiteralPath $localBinary) {
        $env:MVM_BIN = $localBinary
    } else {
        Remove-Item Env:MVM_BIN -ErrorAction SilentlyContinue
    }

    Invoke-Test 'install.ps1 persists both home variables and initializes MATCHBOX_HOME' {
        & $hostExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'install/install.ps1')
        Assert-Equal 0 $LASTEXITCODE 'install.ps1 exit code'

        $installDir = Join-Path $mvmHome 'bin'
        Assert-Equal $mvmHome ([Environment]::GetEnvironmentVariable('MVM_HOME', [EnvironmentVariableTarget]::User)) 'User MVM_HOME'
        Assert-Equal (Join-Path $HOME '.matchbox') ([Environment]::GetEnvironmentVariable('MATCHBOX_HOME', [EnvironmentVariableTarget]::User)) 'User MATCHBOX_HOME default'
        Assert-Contains $installDir ([Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::User)) 'User PATH contains MVM bin'

        $init = Join-Path $mvmHome 'scripts/mvm-init.ps1'
        if (-not (Test-Path -LiteralPath $init)) { throw "Generated init script is missing: $init" }
        $initContents = Get-Content -LiteralPath $init -Raw
        Assert-Contains '$env:MATCHBOX_HOME' $initContents 'init sets MATCHBOX_HOME'
        Assert-Contains '$matchboxBin' $initContents 'init adds MATCHBOX_HOME/bin'
    }

    Invoke-Test 'generated PowerShell init preserves an explicit MATCHBOX_HOME' {
        $customHome = Join-Path $sandbox 'custom-matchbox'
        $env:MATCHBOX_HOME = $customHome
        $env:Path = "$(Join-Path $mvmHome 'bin');$env:Path"
        & (Join-Path $mvmHome 'bin/mvm.exe') doctor --fix
        Assert-Equal 0 $LASTEXITCODE 'doctor --fix exit code'

        $init = Join-Path $mvmHome 'scripts/mvm-init.ps1'
        $command = ". '{0}'; Write-Output `$env:MATCHBOX_HOME" -f $init.Replace("'", "''")
        $output = & $hostExe -NoProfile -Command $command
        Assert-Equal $customHome ($output | Select-Object -Last 1).Trim() 'preserved MATCHBOX_HOME'
    }
}
catch {
    $script:TestFailed++
    Write-Host "FAIL: Windows installer test setup" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    foreach ($entry in @(
        @{ Name = 'MVM_HOME'; Value = $saved.MvmHome },
        @{ Name = 'MATCHBOX_HOME'; Value = $saved.MatchboxHome },
        @{ Name = 'Path'; Value = $saved.Path }
    )) {
        [Environment]::SetEnvironmentVariable($entry.Name, $entry.Value, [EnvironmentVariableTarget]::User)
    }

    if ($null -eq $saved.ProcessMvmHome) { Remove-Item Env:MVM_HOME -ErrorAction SilentlyContinue } else { $env:MVM_HOME = $saved.ProcessMvmHome }
    if ($null -eq $saved.ProcessMatchboxHome) { Remove-Item Env:MATCHBOX_HOME -ErrorAction SilentlyContinue } else { $env:MATCHBOX_HOME = $saved.ProcessMatchboxHome }
    if ($null -eq $saved.ProcessMvmBin) { Remove-Item Env:MVM_BIN -ErrorAction SilentlyContinue } else { $env:MVM_BIN = $saved.ProcessMvmBin }
    $env:Path = $saved.ProcessPath

    if ($profileExisted) {
        Set-Content -LiteralPath $profilePath -Value $profileContents -NoNewline
    } elseif (Test-Path -LiteralPath $profilePath) {
        Remove-Item -LiteralPath $profilePath -Force
    }
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}

Complete-TestSuite
