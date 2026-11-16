param([string]$Jdk = '', [string]$Sdk = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $Jdk) {
    $Jdk = (Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools\android') -Directory -Filter 'jdk-*' | Select-Object -First 1).FullName
}
if (-not $Sdk) { $Sdk = Join-Path $projectRoot 'tools\android\sdk' }
if (-not (Test-Path -LiteralPath (Join-Path $Jdk 'bin\javac.exe'))) { throw 'JDK not found. Supply -Jdk.' }
$env:JAVA_HOME = $Jdk
$env:ANDROID_USER_HOME = Join-Path $projectRoot 'tools\android\user'
$androidJar = Join-Path $Sdk 'platforms\android-35\android.jar'
$buildTools = Join-Path $Sdk 'build-tools\35.0.1'
if (-not (Test-Path -LiteralPath $androidJar)) { throw 'Install Android SDK platform 35 and build-tools 35.0.1, or supply -Sdk.' }
$buildDir = Join-Path $PSScriptRoot 'build'
$distDir = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force -Path $buildDir, "$buildDir\classes", "$buildDir\dex", "$buildDir\generated", $distDir, (Join-Path $projectRoot 'tools\android') | Out-Null
function Run([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program failed with exit code $LASTEXITCODE" }
}
Run "$buildTools\aapt2.exe" @('compile', '--dir', "$PSScriptRoot\res", '-o', "$buildDir\resources.zip")
Run "$buildTools\aapt2.exe" @('link', '-I', $androidJar, '--manifest', "$PSScriptRoot\AndroidManifest.xml", '--java', "$buildDir\generated", '-o', "$buildDir\unsigned.apk", "$buildDir\resources.zip")
$sources = @(Get-ChildItem -LiteralPath "$PSScriptRoot\src" -Filter '*.java' -Recurse | ForEach-Object FullName)
Run "$Jdk\bin\javac.exe" (@('-encoding', 'UTF-8', '-source', '8', '-target', '8', '-classpath', $androidJar, '-d', "$buildDir\classes") + $sources)
$classes = @(Get-ChildItem -LiteralPath "$buildDir\classes" -Filter '*.class' -Recurse | ForEach-Object FullName)
Run "$buildTools\d8.bat" (@('--lib', $androidJar, '--min-api', '23', '--output', "$buildDir\dex") + $classes)
Run "$Jdk\bin\jar.exe" @('uf', "$buildDir\unsigned.apk", '-C', "$buildDir\dex", 'classes.dex')
Run "$buildTools\zipalign.exe" @('-f', '-p', '4', "$buildDir\unsigned.apk", "$buildDir\aligned.apk")
$keystore = Join-Path $projectRoot 'tools\android\controller-local.jks'
if (-not (Test-Path -LiteralPath $keystore)) {
    Run "$Jdk\bin\keytool.exe" @('-genkeypair', '-keystore', $keystore, '-storepass', 'android', '-keypass', 'android', '-alias', 'vector-controller', '-keyalg', 'RSA', '-keysize', '2048', '-validity', '10000', '-dname', 'CN=Vector Controller Local Build', '-storetype', 'JKS')
}
Run "$buildTools\apksigner.bat" @('sign', '--ks', $keystore, '--ks-key-alias', 'vector-controller', '--ks-pass', 'pass:android', '--key-pass', 'pass:android', '--out', "$distDir\VectorController.apk", "$buildDir\aligned.apk")
Run "$buildTools\apksigner.bat" @('verify', '--verbose', '--print-certs', "$distDir\VectorController.apk")
Run "$buildTools\aapt.exe" @('dump', 'badging', "$distDir\VectorController.apk")
$hash = (Get-FileHash -LiteralPath "$distDir\VectorController.apk" -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$distDir\VectorController.apk.sha256" -Value "$hash  VectorController.apk" -Encoding ascii
Write-Output "APK ready: $distDir\VectorController.apk"
