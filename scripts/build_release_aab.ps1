# Build release AAB with diagnostic logging (debug session 19a9a0)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$logPath = Join-Path $projectRoot "debug-19a9a0.log"
$sessionId = "19a9a0"

function Write-DebugLog {
    param([string]$hypothesisId, [string]$location, [string]$message, [hashtable]$data)
    $entry = @{
        sessionId = $sessionId
        runId = "build-aab"
        hypothesisId = $hypothesisId
        location = $location
        message = $message
        data = $data
        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    } | ConvertTo-Json -Compress
    Add-Content -Path $logPath -Value $entry -Encoding UTF8
}

$keyProps = Join-Path $projectRoot "android\key.properties"
$keystore = Join-Path $projectRoot "android\app\upload-keystore.jks"
$aabOut = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"

Write-DebugLog "A" "build_release_aab.ps1:start" "pre-build checks" @{
    keyPropertiesExists = (Test-Path $keyProps)
    keystoreExists = (Test-Path $keystore)
}

if (-not (Test-Path $keyProps)) {
    Write-DebugLog "A" "build_release_aab.ps1:missing-keyprops" "CONFIRMED: no key.properties" @{}
    Write-Host "ECHEC: android/key.properties manquant. Lancez scripts/create_android_keystore.ps1"
    exit 1
}
if (-not (Test-Path $keystore)) {
    Write-DebugLog "B" "build_release_aab.ps1:missing-keystore" "CONFIRMED: no upload-keystore.jks" @{}
    Write-Host "ECHEC: android/app/upload-keystore.jks manquant. Lancez scripts/create_android_keystore.ps1"
    exit 1
}

Write-DebugLog "A" "build_release_aab.ps1:signing-ready" "release signing files present" @{}

Push-Location $projectRoot
try {
    flutter build appbundle --release 2>&1 | Tee-Object -Variable buildOut
    $exitCode = $LASTEXITCODE
    Write-DebugLog "C" "build_release_aab.ps1:flutter-exit" "flutter build finished" @{
        exitCode = $exitCode
        lastLines = ($buildOut | Select-Object -Last 5) -join " | "
    }
    if ($exitCode -ne 0) { exit $exitCode }
} finally {
    Pop-Location
}

if (-not (Test-Path $aabOut)) {
    Write-DebugLog "C" "build_release_aab.ps1:no-aab" "CONFIRMED: AAB file not produced" @{}
    Write-Host "ECHEC: fichier AAB introuvable apres le build"
    exit 1
}

$jarsigner = "C:\Program Files\Java\jdk-21.0.10\bin\jarsigner.exe"
if (Test-Path $jarsigner) {
    $verify = & $jarsigner -verify -verbose -certs $aabOut 2>&1 | Out-String
    $isDebug = $verify -match "CN=Android Debug"
    Write-DebugLog "D" "build_release_aab.ps1:signature-check" "AAB signature analyzed" @{
        aabSizeMb = [math]::Round((Get-Item $aabOut).Length / 1MB, 2)
        appearsDebugSigned = $isDebug
        certSnippet = if ($verify.Length -gt 200) { $verify.Substring(0, 200) } else { $verify }
    }
    if ($isDebug) {
        Write-Host "ECHEC: AAB encore signe en DEBUG (Play Console le refusera)"
        exit 1
    }
}

Write-DebugLog "D" "build_release_aab.ps1:success" "release AAB ready" @{ path = $aabOut }
Write-Host "OK: $aabOut"
