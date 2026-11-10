param(
    [switch]$Hosted,
    [switch]$Install,
    [ValidatePattern('^[A-Za-z0-9_.:-]+$')]
    [string]$DeviceSerial
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$appPath = Join-Path $projectRoot 'apps\passenger_web'
$deliveryPath = Join-Path $projectRoot $(if ($Hosted) { '.local-tools\hosted-test\apks' } else { '.local-tools\connected\apks' })
$visibleDeliveryPath = Join-Path $projectRoot 'Android APKs'
$apkName = if ($Hosted) { 'aerotrans-all-roles-online.apk' } else { 'aerotrans-all-roles-connected.apk' }
$expectedPackage = 'com.pngtransfer.png_transfer_client.connected'
$activityComponent = $expectedPackage + '/com.pngtransfer.png_transfer_client.MainActivity'
$localProject = 'demo-aerotrans-png2'
$guidePath = Join-Path $projectRoot $(if ($Hosted) { 'docs\online-android.md' } else { 'docs\connected-review.md' })
$versionCode = if ($Hosted) { 4 } else { 3 }
$versionName = if ($Hosted) { '1.2.0' } else { '1.1.0' }
$runtimeProject = if ($Hosted) { 'aerotrans-png-test-7d7128' } else { $localProject }
$backendOrigin = if ($Hosted) { 'https://aerotrans-png-test-api-7d7128.vercel.app' } else { 'http://127.0.0.1:8080' }
$definesPath = Join-Path $projectRoot '.local-tools\hosted-test\android-defines.json'

function Assert-HostedServicesReady {
    $request = [Net.HttpWebRequest]::Create($backendOrigin + '/api/v1/health')
    $request.AllowAutoRedirect = $false
    $request.Timeout = 20000
    $response = $null
    $reader = $null
    try {
        $response = $request.GetResponse()
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        $health = $reader.ReadToEnd() | ConvertFrom-Json
        if ([int]$response.StatusCode -ne 200 -or $health.success -ne $true -or $health.schemaVersion -ne '1' -or $health.data.status -ne 'UP' -or $health.data.environment -ne 'staging' -or $health.data.projectId -ne $runtimeProject -or $health.data.operationalWorkflowsEnabled -ne $true) { throw 'Unexpected hosted backend identity.' }
    } finally { if ($null -ne $reader) { $reader.Dispose() }; if ($null -ne $response) { $response.Dispose() } }
    Write-Output 'PASS hosted HTTPS backend identity matches the approved isolated test project.'
}

if ($Hosted) {
    Assert-HostedServicesReady
    & node (Join-Path $PSScriptRoot 'prepare-android-config.mjs') (Join-Path $projectRoot '.local-tools\hosted-test\firebase-android.json') $definesPath
    if ($LASTEXITCODE -ne 0) { throw 'Native Android Firebase test configuration is missing or invalid.' }
}

function Assert-LocalServicesReady {
    # Numeric loopback, no proxy and no redirects: readiness checks cannot leave
    # this computer or silently follow an external backend URL.
    $response = $null
    $reader = $null
    try {
        $request = [Net.HttpWebRequest]::Create('http://127.0.0.1:8080/api/v1/health')
        $request.Method = 'GET'
        $request.AllowAutoRedirect = $false
        $request.Proxy = $null
        $request.Timeout = 4000
        $request.ReadWriteTimeout = 4000
        $response = $request.GetResponse()
        if ([int]$response.StatusCode -ne 200) { throw 'Unexpected backend health status.' }
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        $health = $reader.ReadToEnd() | ConvertFrom-Json
        if ($health.success -ne $true -or $health.schemaVersion -ne '1' -or
            $health.data.status -ne 'UP' -or $health.data.environment -ne 'local' -or
            $health.data.projectId -ne $localProject -or
            $health.data.operationalWorkflowsEnabled -ne $true) {
            throw 'Backend health does not identify the isolated operational runtime.'
        }
    } catch {
        throw 'Connected install requires the isolated NestJS backend at http://127.0.0.1:8080 using demo-aerotrans-png2. Start the existing local services and retry; no external backend was contacted.'
    } finally {
        if ($null -ne $reader) { $reader.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
    }
    foreach ($port in @(9099, 8085, 9000, 9199)) {
        $socket = New-Object Net.Sockets.TcpClient
        $pending = $null
        try {
            $pending = $socket.BeginConnect('127.0.0.1', $port, $null, $null)
            if (!$pending.AsyncWaitHandle.WaitOne(3000)) { throw 'Local emulator connection timed out.' }
            $socket.EndConnect($pending)
            if (!$socket.Connected) { throw 'Local emulator is unavailable.' }
        } catch {
            throw ('Required local Firebase emulator is unavailable on 127.0.0.1:' + $port + '. Start npm run emulators and retry.')
        } finally {
            if ($null -ne $pending) { $pending.AsyncWaitHandle.Close() }
            $socket.Close()
        }
    }
    Write-Output 'PASS isolated backend identity and four loopback emulator readiness checks.'
}

& (Join-Path $PSScriptRoot 'prepare-android.ps1') -AppPath $appPath
$registrantPath = Join-Path $appPath 'android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java'
if (![IO.File]::ReadAllText($registrantPath).Contains('io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin')) {
    throw 'Generated Android registrant does not include Firebase Auth. Connected build stopped.'
}

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
if ($Hosted) { $sourceRows += 'native-test-defines:' + (Get-FileHash -LiteralPath $definesPath -Algorithm SHA256).Hash }
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $fingerprint = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceRows -join [Environment]::NewLine))))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }

Push-Location -LiteralPath $appPath
try {
    $flutterArguments = @('build','apk','--release','--no-pub','--target','lib/main_connected.dart','--target-platform','android-arm,android-arm64',"--build-name=$versionName", "--build-number=$versionCode",'--dart-define=AEROTRANS_CONNECTED_REVIEW=true',"--dart-define=DEMO_SOURCE_REVISION=$fingerprint")
    if ($Hosted) { $flutterArguments += "--dart-define-from-file=$definesPath" } else { $flutterArguments += @('--dart-define=AEROTRANS_ENV=local','--dart-define=EMULATOR_HOST=127.0.0.1') }
    & flutter @flutterArguments
    if ($LASTEXITCODE -ne 0) { throw 'Connected all-roles Android build failed.' }
    $sourceApk = (Resolve-Path -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk').Path
} finally { Pop-Location }

$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$buildTools = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $buildTools) { throw ('Android SDK build tools not found under ' + $sdkRoot) }
$aaptPath = Join-Path $buildTools.FullName 'aapt.exe'
$apksignerPath = Join-Path $buildTools.FullName 'apksigner.bat'
$badging = (& $aaptPath dump badging $sourceApk) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -or !$badging.Contains("package: name='" + $expectedPackage + "'") -or
    !$badging.Contains("versionCode='" + $versionCode + "'") -or !$badging.Contains("versionName='" + $versionName + "'") -or
    !$badging.Contains("application-label:'AeroTrans Connected'")) {
    throw 'Connected APK identity, launcher label or version did not match the isolated build. Nothing was exported.'
}
if (!$badging.Contains("'armeabi-v7a'") -or !$badging.Contains("'arm64-v8a'")) { throw 'Connected APK is missing an Android ARM target.' }
$androidManifest = (& $aaptPath dump xmltree $sourceApk AndroidManifest.xml) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -or $androidManifest -notmatch 'android.permission.INTERNET' -or
    $androidManifest -match 'FirebaseInitProvider' -or $androidManifest -notmatch 'networkSecurityConfig') {
    throw 'Connected APK lacks required networking/isolation settings or contains Firebase auto-initialization. Nothing was exported.'
}
$resourceTable = (& $aaptPath dump --values resources $sourceApk) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect connected APK resources.' }
# Android release packaging may shorten res/xml names. Resolve the policy from
# its resource table and require the manifest to reference that same resource.
$policyName = if ($Hosted) { 'hosted_network_security_config' } else { 'connected_network_security_config' }
$policyResource = [regex]::Match($resourceTable, ('resource\s+(0x[0-9a-fA-F]+)\s+\S+:xml/' + $policyName + ':[^\r\n]*\r?\n\s+\(string8\)\s+"([^"]+)"'))
if (!$policyResource.Success -or $androidManifest -notmatch ('networkSecurityConfig[^\r\n]*@' + [regex]::Escape($policyResource.Groups[1].Value))) {
    throw 'The connected manifest does not reference the expected network policy.'
}
$networkConfig = (& $aaptPath dump xmltree $sourceApk $policyResource.Groups[2].Value) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0 -or $networkConfig -notmatch 'base-config' -or
    $networkConfig -notmatch 'cleartextTrafficPermitted.*0x0') {
    throw 'Connected APK is missing its secure base network policy.'
}
if ($Hosted -and $networkConfig -match 'domain-config') { throw 'Hosted APK must not allow any cleartext exceptions.' }
if (!$Hosted -and $networkConfig -notmatch '127\.0\.0\.1') { throw 'Local connected APK is missing its loopback policy.' }
if ($resourceTable -match 'string/(google_api_key|google_app_id|gcm_defaultSenderId|firebase_database_url|google_storage_bucket|default_web_client_id)\b') {
    throw 'Cached Google Services configuration was found in the connected APK. Clean this app build and retry; isolated explicit Firebase options are required.'
}
& $apksignerPath verify $sourceApk
if ($LASTEXITCODE -ne 0) { throw 'Connected APK signature verification failed.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($sourceApk)
$hasRegistrant = $false
$hasStorage = $false
$hasAuth = $false
try {
    foreach ($entry in $archive.Entries | Where-Object { $_.FullName -match '^classes[0-9]*\.dex$' }) {
        $stream = $entry.Open()
        $memory = New-Object IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            $dexText = [Text.Encoding]::ASCII.GetString($memory.ToArray())
            $hasRegistrant = $hasRegistrant -or $dexText.Contains('Lio/flutter/plugins/GeneratedPluginRegistrant;')
            $hasStorage = $hasStorage -or $dexText.Contains('Lio/flutter/plugins/sharedpreferences/SharedPreferencesPlugin;')
            $hasAuth = $hasAuth -or $dexText.Contains('Lio/flutter/plugins/firebase/auth/FlutterFirebaseAuthPlugin;')
        } finally { $memory.Dispose(); $stream.Dispose() }
    }
} finally { $archive.Dispose() }
if (!$hasRegistrant -or !$hasStorage -or !$hasAuth) { throw 'Connected APK is missing packaged native registration, Firebase Auth or SharedPreferences.' }
if (!(Test-Path -LiteralPath $guidePath)) { throw ('Build checks passed, but the connected tester guide is missing: ' + $guidePath) }

New-Item -ItemType Directory -Path $deliveryPath -Force | Out-Null
New-Item -ItemType Directory -Path $visibleDeliveryPath -Force | Out-Null
$canonicalApk = Join-Path $deliveryPath $apkName
$visibleApk = Join-Path $visibleDeliveryPath $apkName
Copy-Item -LiteralPath $sourceApk -Destination $canonicalApk -Force
Copy-Item -LiteralPath $canonicalApk -Destination $visibleApk -Force
$apkFile = Get-Item -LiteralPath $visibleApk
$deliveryManifest = @{
    sourceRevision = $fingerprint
    mode = if ($Hosted) { 'ISOLATED HOSTED ALL-ROLES TEST' } else { 'ISOLATED CONNECTED ALL-ROLES REVIEW' }
    packageId = $expectedPackage
    versionCode = $versionCode
    versionName = $versionName
    projectId = $runtimeProject
    backendOrigin = $backendOrigin
    backendRequired = $true
    usbReverseRequired = !$Hosted
    localComputerRequired = !$Hosted
    firebasePlatform = if ($Hosted) { 'android' } else { 'local emulators' }
    workflows = @('ARRIVALS', 'DEPARTURES')
    firebaseAutoInitialization = $false
    nativeRegistrationPackaged = $true
    roles = @('PASSENGER', 'DISPATCHER', 'DRIVER', 'SUPERVISOR')
    apks = @(@{
        name = $apkName
        bytes = $apkFile.Length
        sha256 = (Get-FileHash -LiteralPath $visibleApk -Algorithm SHA256).Hash.ToLowerInvariant()
    })
}
$manifestPath = Join-Path $deliveryPath 'manifest.json'
$deliveryManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $visibleDeliveryPath ([IO.Path]::GetFileNameWithoutExtension($apkName) + '.manifest.json')) -Force
Copy-Item -LiteralPath $guidePath -Destination (Join-Path $deliveryPath 'TESTER-README.txt') -Force
Copy-Item -LiteralPath $guidePath -Destination (Join-Path $visibleDeliveryPath $(if ($Hosted) { 'AeroTrans-Online-TESTER-README.txt' } else { 'AeroTrans-Connected-TESTER-README.txt' })) -Force
Write-Output 'PASS connected identity, signature, native registration, explicit Firebase setup and restricted cleartext networking.'
$apkFile | Select-Object FullName, Length

if ($Install) {
    if ($Hosted) { Assert-HostedServicesReady } else { Assert-LocalServicesReady }
    $adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
    if (!(Test-Path -LiteralPath $adbPath)) { throw ('ADB not found: ' + $adbPath) }
    $deviceOutput = & $adbPath devices
    if ($LASTEXITCODE -ne 0) { throw 'ADB could not list connected devices.' }
    $devices = @(foreach ($line in $deviceOutput) {
        if ($line -match '^(\S+)\s+(device|unauthorized|offline)\b') { [PSCustomObject]@{ Serial = $Matches[1]; State = $Matches[2] } }
    })
    if ($DeviceSerial) {
        $selected = @($devices | Where-Object { $_.Serial -eq $DeviceSerial })
        if ($selected.Count -ne 1) { throw ('Requested phone is not connected: ' + $DeviceSerial) }
    } else {
        if ($devices.Count -eq 0) { throw 'No Android device connected. Enable USB debugging, connect the phone and retry.' }
        if ($devices.Count -ne 1) { throw 'Multiple devices connected. Select the phone with -DeviceSerial.' }
        $selected = @($devices[0])
    }
    if ($selected[0].State -eq 'unauthorized') { throw 'Phone is unauthorized. Unlock it and approve the USB debugging prompt.' }
    if ($selected[0].State -ne 'device') { throw 'Phone is offline. Reconnect USB and retry.' }
    $selectedSerial = $selected[0].Serial
    foreach ($port in $(if ($Hosted) { @() } else { @(8080, 9099, 8085, 9000, 9199) })) {
        & $adbPath -s $selectedSerial reverse ('tcp:' + $port) ('tcp:' + $port)
        if ($LASTEXITCODE -ne 0) { throw ('Could not reverse local development port ' + $port + ' to the phone.') }
    }
    & $adbPath -s $selectedSerial install -r $visibleApk
    if ($LASTEXITCODE -ne 0) { throw 'Connected APK installation failed. Keep the phone unlocked, enable Install via USB if required and approve the installation prompt. No app data was cleared.' }
    $launchOutput = & $adbPath -s $selectedSerial shell am start -W --user 0 -n $activityComponent
    $launchExitCode = $LASTEXITCODE
    $launchOutput
    if ($launchExitCode -ne 0 -or ($launchOutput -join [Environment]::NewLine) -notmatch 'Status: ok') { throw 'Connected APK installed, but Android did not confirm launcher startup.' }
    Write-Output $(if ($Hosted) { 'Online APK installed and launched. Internet is required; USB forwarding and local services are not required.' } else { 'Connected APK installed and native activity launched. Keep USB and the local services running. Offline APKs/data were not modified.' })
}
