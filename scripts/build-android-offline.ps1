$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$delivery=Join-Path $projectRoot '.local-tools\offline\apks'
$visibleDelivery=Join-Path $projectRoot 'Android APKs\Offline'
New-Item -ItemType Directory -Path $delivery -Force | Out-Null
New-Item -ItemType Directory -Path $visibleDelivery -Force | Out-Null
$appNames=@{passenger_web='customer';control_room_web='control-room';driver_mobile='driver';admin_web='supervisor'}
$packageNames=@{passenger_web='com.pngtransfer.png_transfer_client.offline';control_room_web='com.pngtransfer.png_transfer_control_room.offline';driver_mobile='com.pngtransfer.png_transfer_driver.offline';admin_web='com.pngtransfer.png_transfer_supervisor.offline'}
$sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$buildTools=Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory | Sort-Object Name -Descending | Select-Object -First 1
$aapt=Join-Path $buildTools.FullName 'aapt.exe'
$apksigner=Join-Path $buildTools.FullName 'apksigner.bat'
$sourceFolders=@((Join-Path $projectRoot 'packages\png_transfer_flutter_core\lib'))
foreach($appName in $appNames.Keys){$sourceFolders+=Join-Path $projectRoot ('apps\'+$appName+'\lib')}
$sourceFiles=foreach($folder in $sourceFolders){Get-ChildItem -LiteralPath $folder -Recurse -File -Filter '*.dart'}
$sourceRows=foreach($file in ($sourceFiles | Sort-Object FullName)){ $file.FullName.Substring($projectRoot.Length)+(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
$sha=[Security.Cryptography.SHA256]::Create()
try{$fingerprint=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceRows -join [Environment]::NewLine))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
foreach($appName in @('passenger_web','control_room_web','driver_mobile','admin_web')){
 & (Join-Path $PSScriptRoot 'prepare-android.ps1') -AppPath (Join-Path $projectRoot ('apps\'+$appName))
 Push-Location -LiteralPath (Join-Path $projectRoot ('apps\'+$appName))
 try{
  flutter build apk --release --no-pub --target lib/main_offline.dart --target-platform android-arm,android-arm64 --dart-define=AEROTRANS_OFFLINE_DEMO=true --dart-define=DEMO_SOURCE_REVISION=$fingerprint
  if($LASTEXITCODE -ne 0){throw ('Offline Android build failed: '+$appName)}
  $sourceApk=(Resolve-Path -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk').Path
  $badging=(& $aapt dump badging $sourceApk) -join [Environment]::NewLine
  if($LASTEXITCODE -ne 0 -or !$badging.Contains("package: name='"+$packageNames[$appName]+"'")){throw ('Unexpected offline package identity: '+$appName)}
  $manifest=(& $aapt dump xmltree $sourceApk AndroidManifest.xml) -join [Environment]::NewLine
  if($LASTEXITCODE -ne 0 -or $manifest -match 'android.permission.INTERNET|android.permission.ACCESS_NETWORK_STATE|FirebaseInitProvider'){throw ('Offline APK contains network access or automatic Firebase initialization: '+$appName)}
  & $apksigner verify $sourceApk
  if($LASTEXITCODE -ne 0){throw ('Offline APK signature verification failed: '+$appName)}
  $name='aerotrans-'+$appNames[$appName]+'-offline.apk'
  Copy-Item -LiteralPath $sourceApk -Destination (Join-Path $delivery $name) -Force
  Copy-Item -LiteralPath (Join-Path $delivery $name) -Destination (Join-Path $visibleDelivery $name) -Force
  'PASS offline identity, signature and no network permission: '+$name
 }finally{Pop-Location}
}
$artifacts=Get-ChildItem -LiteralPath $delivery -Filter '*.apk' | ForEach-Object { @{name=$_.Name;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()} }
@{sourceRevision=$fingerprint;mode='OFFLINE PRACTICE ONLY';networkRequired=$false;backendRequired=$false;dataSynchronizes=$false;apks=@($artifacts)} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $delivery 'manifest.json') -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $delivery 'manifest.json') -Destination (Join-Path $visibleDelivery 'manifest.json') -Force
Get-ChildItem -LiteralPath $visibleDelivery -Filter '*.apk' | Select-Object Name,Length
