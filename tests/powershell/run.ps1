Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$suites = @(Get-ChildItem -Path $PSScriptRoot -Filter '*.Tests.ps1' -File | Sort-Object Name)
if ($suites.Count -eq 0) {
    throw 'No PowerShell test suites found.'
}

foreach ($suite in $suites) {
    Write-Host "`nRunning $($suite.Name)"
    & $suite.FullName
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
