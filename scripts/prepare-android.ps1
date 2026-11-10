param(
    [Parameter(Mandatory = $true)]
    [string]$AppPath
)

$ErrorActionPreference = 'Stop'
$resolvedAppPath = (Resolve-Path -LiteralPath $AppPath).Path
if (!(Test-Path -LiteralPath (Join-Path $resolvedAppPath 'pubspec.yaml'))) {
    throw ('Flutter application pubspec not found: ' + $resolvedAppPath)
}

# Flutter 3.35 generates desktop plugin symlinks before the Android registrant.
# An unavailable Windows symlink privilege must not leave a build with missing
# native channels. Disable desktop tooling only for this preparation process;
# no global Flutter settings or platform folders are changed.
$previousWindows = [Environment]::GetEnvironmentVariable('FLUTTER_WINDOWS', 'Process')
$previousLinux = [Environment]::GetEnvironmentVariable('FLUTTER_LINUX', 'Process')
Push-Location -LiteralPath $resolvedAppPath
try {
    $env:FLUTTER_WINDOWS = 'false'
    $env:FLUTTER_LINUX = 'false'
    flutter pub get --offline
    if ($LASTEXITCODE -ne 0) {
        throw ('Android plugin preparation failed: ' + $resolvedAppPath + '. Resolve the dependency/tooling error before using --no-pub.')
    }

    $registrantPath = Join-Path $resolvedAppPath 'android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java'
    if (!(Test-Path -LiteralPath $registrantPath)) {
        throw ('Flutter did not generate the Android native plugin registrant: ' + $registrantPath)
    }
    $registrant = [IO.File]::ReadAllText($registrantPath)
    if (!$registrant.Contains('io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin')) {
        throw ('Android native registrant is missing SharedPreferencesPlugin: ' + $registrantPath)
    }
    Write-Output ('Android native storage registration prepared: ' + (Split-Path -Leaf $resolvedAppPath))
} finally {
    [Environment]::SetEnvironmentVariable('FLUTTER_WINDOWS', $previousWindows, 'Process')
    [Environment]::SetEnvironmentVariable('FLUTTER_LINUX', $previousLinux, 'Process')
    Pop-Location
}
