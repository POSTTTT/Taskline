# Produces a signed Taskline MSIX release.
#
# Prerequisites:
#   - scripts/taskline.pfx exists (run scripts/create-signing-cert.ps1 once)
#
# Output:
#   taskline/build/windows/x64/runner/Release/taskline.msix
#
# The MSIX inside is signed with the self-signed cert in scripts/taskline.pfx.
# Recipients must install scripts/taskline.cer to "Local Machine > Trusted
# People" once before they can install the .msix. See README "Install" section.

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pfxPath = Join-Path $repoRoot 'scripts\taskline.pfx'
$tasklineDir = Join-Path $repoRoot 'taskline'

if (-not (Test-Path $pfxPath)) {
    Write-Error "Signing cert not found at $pfxPath. Run scripts/create-signing-cert.ps1 first."
    exit 1
}

Push-Location $tasklineDir
try {
    Write-Output "==> flutter build windows --release"
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build failed" }

    Write-Output ""
    Write-Output "==> dart run msix:create (signed)"
    & dart run msix:create `
        --certificate-path $pfxPath `
        --certificate-password 'taskline'
    if ($LASTEXITCODE -ne 0) { throw "msix:create failed" }

    $msix = Join-Path $tasklineDir 'build\windows\x64\runner\Release\taskline.msix'
    if (Test-Path $msix) {
        $size = [math]::Round((Get-Item $msix).Length / 1MB, 2)
        Write-Output ""
        Write-Output "Signed MSIX produced: $msix (${size} MB)"
    } else {
        throw "Expected MSIX not found at $msix"
    }
} finally {
    Pop-Location
}
