Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:TestPassed = 0
$script:TestFailed = 0

function Initialize-TestSuite {
    param([string]$Name)
    $script:TestSuiteName = $Name
    Write-Host "Running $Name"
}

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    try {
        & $ScriptBlock
        $script:TestPassed++
        Write-Host "PASS: $Name"
    }
    catch {
        $script:TestFailed++
        Write-Host "FAIL: $Name" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message)
    if ($Expected -ne $Actual) {
        throw "$Message. Expected: '$Expected'. Actual: '$Actual'."
    }
}

function Assert-Contains {
    param([string]$Expected, [string]$Actual, [string]$Message)
    if ($Actual -notlike "*$Expected*") {
        throw "$Message. Expected to find: '$Expected'."
    }
}

function Complete-TestSuite {
    Write-Host "$($script:TestPassed) passed, $($script:TestFailed) failed"
    if ($script:TestFailed -gt 0) {
        exit 1
    }
}
