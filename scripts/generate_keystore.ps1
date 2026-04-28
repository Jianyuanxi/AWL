# AWL Release Keystore Generator
# Run this script ONCE locally to generate your signing key.
# Then follow the printed instructions to upload secrets to GitHub.
#
# Usage: .\scripts\generate_keystore.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AWL Android Release Keystore Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$keystoreDir = "android\app"
$keystoreFile = "$keystoreDir\upload.keystore"

if (Test-Path $keystoreFile) {
    Write-Host "[!] $keystoreFile already exists." -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (y/N)"
    if ($overwrite -ne "y") {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
}

# Collect keystore info
Write-Host ""
Write-Host "Enter the following keystore details:" -ForegroundColor White
Write-Host "----------------------------------------"

$alias = Read-Host "Key alias (e.g. awl-release)"
if ([string]::IsNullOrWhiteSpace($alias)) { $alias = "awl-release" }

$validity = Read-Host "Validity in days (default: 10000)"
if ([string]::IsNullOrWhiteSpace($validity)) { $validity = "10000" }

Write-Host ""
Write-Host "IMPORTANT: Keep these passwords safe! You will need them for GitHub Secrets." -ForegroundColor Yellow
Write-Host ""

$storePass = Read-Host "Keystore password" -AsSecureString
if ($storePass.Length -eq 0) {
    Write-Host "Password cannot be empty." -ForegroundColor Red
    exit 1
}

$keyPass = Read-Host "Key password (Enter to reuse keystore password)" -AsSecureString
if ($keyPass.Length -eq 0) {
    $keyPass = $storePass
}

# Convert SecureString to plain text (needed for keytool)
$storePassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass)
)
$keyPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass)
)

# Generate keystore using keytool
Write-Host ""
Write-Host "[*] Generating keystore ..." -ForegroundColor Cyan

$dname = "CN=AWL, OU=Dev, O=AWL, L=Unknown, ST=Unknown, C=CN"
$keytoolArgs = @(
    "-genkey", "-v",
    "-keystore", $keystoreFile,
    "-alias", $alias,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", $validity,
    "-storepass", $storePassPlain,
    "-keypass", $keyPassPlain,
    "-dname", $dname
)

$result = & keytool @keytoolArgs 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "keytool failed: $result" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Keystore created: $keystoreFile" -ForegroundColor Green

# Encode to base64 for GitHub Secret
Write-Host "[*] Encoding to base64 ..." -ForegroundColor Cyan
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $keystoreFile)))

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Secrets Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Go to: https://github.com/Jianyuanxi/AWL/settings/secrets/actions" -ForegroundColor White
Write-Host ""
Write-Host "Click 'New repository secret' and add the following 4 secrets:" -ForegroundColor White
Write-Host ""
Write-Host "  ┌─────────────────────┬──────────────────────────────────────────────┐"
Write-Host "  │ Secret Name          │ Value                                        │"
Write-Host "  ├─────────────────────┼──────────────────────────────────────────────┤"
Write-Host "  │ KEYSTORE_BASE64      │ (see below — the long base64 string)        │"
Write-Host "  │ KEYSTORE_PASSWORD    │ $storePassPlain                             │"
Write-Host "  │ KEY_ALIAS            │ $alias                                      │"
Write-Host "  │ KEY_PASSWORD         │ $keyPassPlain                                │"
Write-Host "  └─────────────────────┴──────────────────────────────────────────────┘"
Write-Host ""
Write-Host "--- KEYSTORE_BASE64 (copy everything below this line) ---" -ForegroundColor Yellow
Write-Host $base64
Write-Host "--- end ---" -ForegroundColor Yellow
Write-Host ""
Write-Host "[+] Done! After adding the secrets, push a tag like 'v1.0.0' to trigger a release." -ForegroundColor Green

# Clean up plain text passwords
$storePassPlain = $null
$keyPassPlain = $null
[GC]::Collect()
