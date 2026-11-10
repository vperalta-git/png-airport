param(
    [switch]$Install,
    [string]$DeviceSerial
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$appPath = Join-Path $projectRoot 'apps\passenger_web'
$deliveryPath = Join-Path $projectRoot '.local-tools\offline\combined'
$visibleDeliveryPath = Join-Path $projectRoot 'Android APKs'
$apkName = 'aerotrans-all-roles-offline.apk'
$expectedPackage = 'com.pngtransfer.png_transfer_client.offline.allroles'
$activityComponent = $expectedPackage + '/com.pngtransfer.png_transfer_client.MainActivity'
$guidePath = Join-Path $projectRoot 'docs\all-roles-offline-demo.md'

& (Join-Path $PSScriptRoot 'prepare-android.ps1') -AppPath $appPath

# A fingerprint also invalidates Flutter's AOT cache when shared Dart code changes
# outside the application's own directory. Include native sources/configuration.
$sourceFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'packages\png_transfer_flutter_core\lib') -Recurse -File -Filter '*.dart'
    Get-ChildItem -LiteralPath (Join-Path $appPath 'lib') -Recurse -File -Filter '*.dart'
    Get-ChildItem -LiteralPath (Join-Path $appPath 'android\app\src') -Recurse -File | Where-Object { $_.Extension -in @('.xml', '.kt', '.java') }
    Get-Item -LiteralPath (Join-Path $appPath 'android\app\build.gradle.kts')
    Get-Item -LiteralPath (Join-Path $appPath 'pubspec.yaml')
    Get-Item -LiteralPath (Join-Path $appPath 'pubspec.lock')
    Get-Item -LiteralPath (Join-Path $projectRoot 'packages\png_transfer_flutter_core\pubspec.yaml')
)
$sourceRows = foreach ($file in ($sourceFiles | Sort-Object FullName -Unique)) {
    $file.FullName.Substring($projectRoot.Length) + (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
}
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $fingerprint = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceRows -join [Environment]::NewLine))))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }

Push-Location -LiteralPath $appPath
try {
    flutter build apk --release --no-pub --target lib/main_offline_all_roles.dart --target-platform android-arm,android-arm64 --build-name=1.0.1 --build-number=2 --dart-define=AEROTRANS_OFFLINE_DEMO=true --dart-define=AEROTRANS_ALL_ROLES_DEMO=true --dart-define=DEMO_SOURCE_REVISION=$fingerprint
    if ($LASTEXITCODE -ne 0) { throw 'All-roles offline Android build failed.' }
    $sourceApk = (Resolve-Path -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk').Path
} finally { Pop-Location }

$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$buildTools = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $buildTools) { throw ('Android SDK build tools were not found under ' + $sdkRoot) }
$aaptPath = Join-Path $buildTools.FullName 'aapt.exe'
$apksignerPath = Join-Path $buildTools.FullName 'apksigner.bat'
$badging = (& $aaptPath dump badging $sourceApk) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -or !$badging.Contains("package: name='" + $expectedPackage + "'") -or !$badging.Contains("versionCode='2'")) {
    throw 'All-roles APK has an unexpected package identity/version. No APK was exported.'
}
if (!$badging.Contains("'armeabi-v7a'") -or !$badging.Contains("'arm64-v8a'")) {
    throw 'All-roles APK is missing a required Android ARM architecture.'
}
$androidManifest = (& $aaptPath dump xmltree $sourceApk AndroidManifest.xml) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -or $androidManifest -match 'android.permission.INTERNET|android.permission.ACCESS_NETWORK_STATE|FirebaseInitProvider') {
    throw 'All-roles offline APK contains network access or automatic Firebase initialization. No APK was exported.'
}
& $apksignerPath verify $sourceApk
if ($LASTEXITCODE -ne 0) { throw 'All-roles APK signature verification failed.' }

# Checking only Java source is insufficient: the runtime registrant must be in
# the actual exported dex, otherwise storage calls fail on a physical phone.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($sourceApk)
$hasRegistrant = $false
$hasStoragePlugin = $false
try {
    foreach ($entry in $archive.Entries | Where-Object { $_.FullName -match '^classes[0-9]*\.dex$' }) {
        $stream = $entry.Open()
        $memory = New-Object IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            $dexText = [Text.Encoding]::ASCII.GetString($memory.ToArray())
            $hasRegistrant = $hasRegistrant -or $dexText.Contains('Lio/flutter/plugins/GeneratedPluginRegistrant;')
            $hasStoragePlugin = $hasStoragePlugin -or $dexText.Contains('Lio/flutter/plugins/sharedpreferences/SharedPreferencesPlugin;')
        } finally { $memory.Dispose(); $stream.Dispose() }
    }
} finally { $archive.Dispose() }
if (!$hasRegistrant -or !$hasStoragePlugin) {
    throw 'All-roles APK is missing native storage registration in dex. No APK was exported.'
}
if (!(Test-Path -LiteralPath $guidePath)) {
    throw ('Tester guide is missing: ' + $guidePath + '. Build validation passed, but delivery is incomplete.')
}

New-Item -ItemType Directory -Path $deliveryPath -Force | Out-Null
New-Item -ItemType Directory -Path $visibleDeliveryPath -Force | Out-Null
$canonicalApk = Join-Path $deliveryPath $apkName
$visibleApk = Join-Path $visibleDeliveryPath $apkName
Copy-Item -LiteralPath $sourceApk -Destination $canonicalApk -Force
Copy-Item -LiteralPath $canonicalApk -Destination $visibleApk -Force
$apkFile = Get-Item -LiteralPath $visibleApk
$artifact = @{
    name = $apkName
    bytes = $apkFile.Length
    sha256 = (Get-FileHash -LiteralPath $visibleApk -Algorithm SHA256).Hash.ToLowerInvariant()
}
$deliveryManifest = @{
    sourceRevision = $fingerprint
    mode = 'ALL-ROLES OFFLINE PRACTICE ONLY'
    packageId = $expectedPackage
    versionCode = 2
    backendRequired = $false
    networkRequired = $false
    dataSynchronizes = $false
    roles = @('PASSENGER', 'DISPATCHER', 'DRIVER', 'SUPERVISOR')
    nativeStorageRegistrationVerified = $true
    apks = @($artifact)
}
$manifestPath = Join-Path $deliveryPath 'manifest.json'
$deliveryManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $visibleDeliveryPath 'aerotrans-all-roles-offline.manifest.json') -Force
Copy-Item -LiteralPath $guidePath -Destination (Join-Path $deliveryPath 'TESTER-README.txt') -Force
Copy-Item -LiteralPath $guidePath -Destination (Join-Path $visibleDeliveryPath 'AeroTrans-All-Roles-TESTER-README.txt') -Force
Write-Output 'PASS: identity, signature, ARM targets, network isolation and packaged native storage registration.'
$apkFile | Select-Object FullName, Length

if ($Install) {
    $adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
    if (!(Test-Path -LiteralPath $adbPath)) { throw ('Android Debug Bridge was not found: ' + $adbPath) }
    $deviceOutput = & $adbPath devices
    if ($LASTEXITCODE -ne 0) { throw 'ADB could not list attached devices.' }
    $devices = @(foreach ($line in $deviceOutput) {
        if ($line -match '^(\S+)\s+(device|unauthorized|offline)\b') {
            [PSCustomObject]@{ Serial = $Matches[1]; State = $Matches[2] }
        }
    })
    if ($DeviceSerial) {
        $selected = @($devices | Where-Object { $_.Serial -eq $DeviceSerial })
        if ($selected.Count -ne 1) { throw ('Requested Android device is not connected: ' + $DeviceSerial) }
    } else {
        if ($devices.Count -eq 0) { throw 'No Android device connected. Connect USB and enable USB debugging, then retry with -Install.' }
        if ($devices.Count -ne 1) { throw 'Multiple Android devices are attached. Select the target using -DeviceSerial.' }
        $selected = @($devices[0])
    }
    if ($selected[0].State -eq 'unauthorized') { throw 'Android device is unauthorized. Unlock the phone and approve the USB debugging prompt, then retry.' }
    if ($selected[0].State -ne 'device') { throw 'Android device is offline. Reconnect USB and retry.' }
    $selectedSerial = $selected[0].Serial
    & $adbPath -s $selectedSerial install -r $visibleApk
    if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Keep the phone unlocked, enable Install via USB if required, and accept the phone installation prompt. Existing data was not cleared.' }
    $launchOutput = & $adbPath -s $selectedSerial shell am start -W --user 0 -n $activityComponent
    $launchExitCode = $LASTEXITCODE
    $launchOutput
    if ($launchExitCode -ne 0 -or ($launchOutput -join [Environment]::NewLine) -notmatch 'Status: ok') {
        throw 'APK installed, but Android did not confirm the explicit launcher activity started.'
    }
    Write-Output 'Installed and launched the all-roles offline APK. This launcher check does not establish full workflow acceptance.'
}
