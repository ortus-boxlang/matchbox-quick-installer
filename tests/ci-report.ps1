[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [string]$LogPath,

    [Parameter(Mandatory)]
    [int]$ExitCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $LogPath)) {
    throw "Test log was not created: $LogPath"
}

$summaryPath = $env:GITHUB_STEP_SUMMARY
if ($summaryPath) {
    $result = if ($ExitCode -eq 0) { 'Passed' } else { 'Failed' }
    Add-Content -Path $summaryPath -Value "## $Name"
    Add-Content -Path $summaryPath -Value ''
    Add-Content -Path $summaryPath -Value "Result: **$result**"
    Add-Content -Path $summaryPath -Value ''
    Add-Content -Path $summaryPath -Value 'Full output: uploaded test log artifact.'
    Add-Content -Path $summaryPath -Value ''
}

if ($ExitCode -ne 0) {
    Write-Output "::error title=$Name failed::See the uploaded test log for details."
    exit $ExitCode
}
