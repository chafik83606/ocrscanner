# Crée le keystore de signature release (une seule fois).
# Conservez le mot de passe : sans lui, vous ne pourrez plus publier de mises à jour.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$keystorePath = Join-Path $projectRoot "android\app\upload-keystore.jks"
$keyPropsPath = Join-Path $projectRoot "android\key.properties"

if (Test-Path $keystorePath) {
    Write-Host "Le keystore existe déjà : $keystorePath"
    exit 0
}

$password = Read-Host "Mot de passe du keystore (min. 6 caractères)" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    $javaHome = $env:JAVA_HOME
    if ($javaHome) {
        $keytool = Join-Path $javaHome "bin\keytool.exe"
    }
}
if (-not (Test-Path $keytool)) {
    Write-Error "keytool introuvable. Installez le JDK ou définissez JAVA_HOME."
}

& $keytool -genkeypair -v `
    -storetype JKS `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias upload `
    -keystore $keystorePath `
    -storepass $passwordPlain `
    -keypass $passwordPlain `
    -dname "CN=OCR Scanner, OU=Mobile, O=ctre2, C=FR"

$propsContent = @"
storePassword=$passwordPlain
keyPassword=$passwordPlain
keyAlias=upload
storeFile=app/upload-keystore.jks
"@
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($keyPropsPath, $propsContent.TrimEnd() + "`n", $utf8)

Write-Host "Keystore créé : $keystorePath"
Write-Host "key.properties créé : $keyPropsPath"
Write-Host "Sauvegardez le mot de passe dans un endroit sûr (gestionnaire de mots de passe)."
