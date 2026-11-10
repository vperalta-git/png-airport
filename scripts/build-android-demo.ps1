$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$delivery=Join-Path $projectRoot '.local-tools\demo\apks'
New-Item -ItemType Directory -Path $delivery -Force | Out-Null
$appNames=@{passenger_web='customer';control_room_web='control-room';driver_mobile='driver';admin_web='supervisor'}
# Fingerprint source explicitly: Windows Gradle incremental builds can miss edits
# in a path dependency outside the app directory. Changed source gets a new key.
$sourceFolders=@((Join-Path $projectRoot 'packages\png_transfer_flutter_core\lib'))
foreach($appName in $appNames.Keys){$sourceFolders+=Join-Path $projectRoot ('apps\'+$appName+'\lib')}
$sourceFiles=foreach($folder in $sourceFolders){Get-ChildItem -LiteralPath $folder -Recurse -File -Filter '*.dart'}
$sourceRows=foreach($file in ($sourceFiles | Sort-Object FullName)){ $file.FullName.Substring($projectRoot.Length)+(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
$sha=[Security.Cryptography.SHA256]::Create()
try{$fingerprint=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($sourceRows -join "`n"))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
foreach($appName in @('passenger_web','control_room_web','driver_mobile','admin_web')){
 & (Join-Path $PSScriptRoot 'prepare-android.ps1') -AppPath (Join-Path $projectRoot ('apps\'+$appName))
 Push-Location -LiteralPath (Join-Path $projectRoot ('apps\'+$appName))
 try{
 flutter build apk --debug --no-pub --target-platform android-arm,android-arm64 --dart-define=EMULATOR_HOST=127.0.0.1 --dart-define=DEMO_SOURCE_REVISION=$fingerprint
 if($LASTEXITCODE -ne 0){throw ('Android build failed: '+$appName)}
 Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-debug.apk' -Destination (Join-Path $delivery ('aerotrans-'+$appNames[$appName]+'-demo.apk'))
 }finally{Pop-Location}
}
$artifacts=Get-ChildItem -LiteralPath $delivery -Filter '*.apk' | ForEach-Object { @{name=$_.Name;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()} }
@{sourceRevision=$fingerprint;mode='ISOLATED USB DEMO';apks=@($artifacts)} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $delivery 'manifest.json') -Encoding UTF8
Get-ChildItem -LiteralPath $delivery -Filter '*.apk' | Select-Object Name,Length
