# Creates a self-signed code-signing certificate for the Taskline MSIX.
#
# Outputs:
#   scripts/taskline.pfx   (private key + cert, used by msix:create to sign;
#                           never committed; password "taskline")
#   scripts/taskline.cer   (public cert only; committed; users install this
#                           to Local Machine > Trusted People before installing
#                           the signed MSIX)
#
# Re-run this only if you need to rotate the cert. The certificate is valid
# for 3 years.

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pfxPath = Join-Path $repoRoot 'scripts\taskline.pfx'
$cerPath = Join-Path $repoRoot 'scripts\taskline.cer'
$password = 'taskline'

# Must exactly match the `publisher` in pubspec.yaml's msix_config.
$subject = 'CN=Taskline'

Write-Output "Generating self-signed code-signing certificate for $subject..."

$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $subject `
    -KeyUsage DigitalSignature `
    -FriendlyName 'Taskline Self-Signed' `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -NotAfter (Get-Date).AddYears(3) `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}')

Write-Output "Created cert with thumbprint: $($cert.Thumbprint)"

$securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText

Export-PfxCertificate `
    -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" `
    -FilePath $pfxPath `
    -Password $securePassword | Out-Null

Export-Certificate `
    -Cert "Cert:\CurrentUser\My\$($cert.Thumbprint)" `
    -FilePath $cerPath `
    -Type CERT | Out-Null

# Optional cleanup: remove from the user's personal cert store, since the
# .pfx file on disk is what msix:create reads. Keeping it in the store can
# cause "multiple certs" confusion later.
Remove-Item -Path "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force

Write-Output "Wrote $pfxPath (KEEP PRIVATE)"
Write-Output "Wrote $cerPath (safe to commit / distribute)"
Write-Output ""
Write-Output "Next:"
Write-Output "  1. Build a signed MSIX:  scripts/build-release.ps1"
Write-Output "  2. Hand out the .msix + scripts/taskline.cer to users"
