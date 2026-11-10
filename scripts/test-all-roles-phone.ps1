param(
    [ValidatePattern('^[A-Za-z0-9_.:-]+$')]
    [string]$DeviceSerial = 'd381fffa0421'
)

$ErrorActionPreference = 'Stop'
$packageName = 'com.pngtransfer.png_transfer_client.offline.allroles'
$componentName = $packageName + '/com.pngtransfer.png_transfer_client.MainActivity'
$projectRoot = Split-Path -Parent $PSScriptRoot
$evidencePath = Join-Path $projectRoot '.local-tools\offline\combined\device'
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (!(Test-Path -LiteralPath $adbPath)) { throw ('ADB not found: ' + $adbPath) }
New-Item -ItemType Directory -Path $evidencePath -Force | Out-Null
$script:captureNumber = 0
$steps = New-Object 'System.Collections.Generic.List[object]'
$startedAt = [DateTime]::UtcNow.ToString('o')

function Invoke-DeviceCommand([string[]]$CommandArguments) {
    $commandOutput = & $adbPath -s $DeviceSerial @CommandArguments
    if ($LASTEXITCODE -ne 0) { throw ('ADB command failed: ' + ($CommandArguments -join ' ')) }
    return ($commandOutput -join [Environment]::NewLine)
}

function Invoke-UiDump {
    # Capture both native streams explicitly. MIUI can emit an irrelevant theme
    # stack trace on stderr even when uiautomator writes the XML successfully.
    # Keep separate adb shell arguments; remote redirection is unreliable here.
    $process = New-Object Diagnostics.Process
    $process.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $adbPath
    $process.StartInfo.Arguments = '-s ' + $DeviceSerial + ' shell uiautomator dump /sdcard/aerotrans-all-roles-smoke.xml'
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    try {
        if (!$process.Start()) { throw 'Could not start Android UI dump.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(30000)) { $process.Kill(); throw 'Android UI dump timed out. Keep AeroTrans Demo visible and retry.' }
        $dumpOutput = $stdoutTask.GetAwaiter().GetResult() + [Environment]::NewLine + $stderrTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0 -or $dumpOutput -notmatch 'dumped to:') {
            throw ('Android UI dump was not confirmed (ADB exit ' + $process.ExitCode + '). Keep the phone unlocked with AeroTrans Demo visible and retry.')
        }
    } finally { $process.Dispose() }
}

function Read-AppScreen([string]$Label = 'screen') {
    $script:captureNumber++
    $xmlPath = Join-Path $evidencePath ($script:captureNumber.ToString('000') + '-' + $Label + '.xml')
    Invoke-UiDump
    Invoke-DeviceCommand -CommandArguments @('pull', '/sdcard/aerotrans-all-roles-smoke.xml', $xmlPath) | Out-Null
    [xml]$xml = [IO.File]::ReadAllText($xmlPath)
    $nodes = @($xml.SelectNodes("//node[@package='$packageName']"))
    if ($nodes.Count -eq 0) {
        # Discard our newly pulled snapshot if the user has moved to another app.
        # Do not retain unrelated app/launcher contents as test evidence.
        [IO.File]::Delete($xmlPath)
        throw 'The all-roles app is not visible. Unlock the phone, dismiss any installation prompt, reopen AeroTrans Demo, and retry. No controls outside this app were tapped.'
    }
    foreach ($node in $nodes) {
        if (($node.GetAttribute('text') + ' ' + $node.GetAttribute('content-desc')) -match 'STORAGE_PLUGIN_UNAVAILABLE|OFFLINE_STORAGE_ERROR|Saved offline practice data could not be opened') {
            throw ('Offline storage startup failed. Evidence: ' + $xmlPath)
        }
    }
    return [PSCustomObject]@{ Xml = $xml; Nodes = $nodes; Path = $xmlPath }
}

function Get-NodeBounds($Node) {
    if ($Node.GetAttribute('package') -ne $packageName -or $Node.GetAttribute('bounds') -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') {
        throw 'Refusing to interact with a control outside the target app or without valid bounds.'
    }
    return [PSCustomObject]@{ Left = [int]$Matches[1]; Top = [int]$Matches[2]; Right = [int]$Matches[3]; Bottom = [int]$Matches[4] }
}

function Find-MatchingNode($Screen, [string]$Pattern, [switch]$EnabledOnly) {
    foreach ($node in $Screen.Nodes) {
        if ($EnabledOnly -and $node.GetAttribute('enabled') -eq 'false') { continue }
        $text = $node.GetAttribute('text').Trim()
        $description = $node.GetAttribute('content-desc').Trim()
        if ($text -match $Pattern -or $description -match $Pattern) {
            $bounds = Get-NodeBounds $node
            if ($bounds.Right -gt $bounds.Left -and $bounds.Bottom -gt $bounds.Top) { return $node }
        }
    }
    return $null
}

function Scroll-App($Screen, [bool]$TowardEnd) {
    $scrollNode = $Screen.Nodes | Where-Object { $_.GetAttribute('scrollable') -eq 'true' } | Select-Object -First 1
    if ($null -eq $scrollNode) { return $false }
    $bounds = Get-NodeBounds $scrollNode
    if ($bounds.Right -le $bounds.Left -or $bounds.Bottom -le $bounds.Top) { return $false }
    $x = [int](($bounds.Left + $bounds.Right) / 2)
    $upper = [int]($bounds.Top + ($bounds.Bottom - $bounds.Top) * 0.2)
    $lower = [int]($bounds.Top + ($bounds.Bottom - $bounds.Top) * 0.8)
    $fromY = if ($TowardEnd) { $lower } else { $upper }
    $toY = if ($TowardEnd) { $upper } else { $lower }
    Invoke-DeviceCommand -CommandArguments @('shell', 'input', 'swipe', "$x", "$fromY", "$x", "$toY", '300') | Out-Null
    Start-Sleep -Milliseconds 250
    return $true
}

function Tap-AppLabel([string]$Pattern, [string]$Label) {
    # Search both ways through this app's own scroll view. Coordinates always
    # come from a fresh accessibility tree, never a device-specific pixel map.
    foreach ($direction in @($false, $true)) {
        for ($attempt = 0; $attempt -lt 5; $attempt++) {
            $screen = Read-AppScreen $Label
            $node = Find-MatchingNode $screen $Pattern -EnabledOnly
            if ($null -ne $node) {
                $bounds = Get-NodeBounds $node
                $x = [int](($bounds.Left + $bounds.Right) / 2)
                $y = [int](($bounds.Top + $bounds.Bottom) / 2)
                Invoke-DeviceCommand -CommandArguments @('shell', 'input', 'tap', "$x", "$y") | Out-Null
                Start-Sleep -Milliseconds 400
                return
            }
            if (!(Scroll-App $screen $direction)) { break }
        }
    }
    throw ('No visible enabled AeroTrans control matched: ' + $Label)
}

function Assert-AppLabel([string]$Pattern, [string]$Label) {
    for ($attempt = 0; $attempt -lt 6; $attempt++) {
        $screen = Read-AppScreen $Label
        if ($null -ne (Find-MatchingNode $screen $Pattern)) { return $screen }
        Start-Sleep -Milliseconds 350
    }
    throw ('Expected AeroTrans screen was not found: ' + $Label + '. Evidence: ' + $screen.Path)
}

function Save-AppScreenshot([string]$Label) {
    Read-AppScreen $Label | Out-Null
    $screenshotPath = Join-Path $evidencePath ($Label + '.png')
    $process = New-Object Diagnostics.Process
    $process.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $adbPath
    $process.StartInfo.Arguments = '-s ' + $DeviceSerial + ' exec-out screencap -p'
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $file = [IO.File]::Create($screenshotPath)
    try {
        if (!$process.Start()) { throw 'Could not start screenshot capture.' }
        $copy = $process.StandardOutput.BaseStream.CopyToAsync($file)
        $stderr = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(15000)) { $process.Kill(); throw 'Android screenshot timed out.' }
        $copy.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw ('Android screenshot failed: ' + $stderr.GetAwaiter().GetResult()) }
    } finally { $file.Dispose(); $process.Dispose() }
}

function Record-Step([string]$Name) {
    $steps.Add([PSCustomObject]@{ step = $Name; passed = $true; at = [DateTime]::UtcNow.ToString('o') })
    Write-Host ('PASS ' + $Name)
}

function Assert-Chooser([string]$Label) {
    Assert-AppLabel '^Choose a demo role$' $Label | Out-Null
    $pending = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($role in @('Customer', 'Control Room', 'Driver', 'Manager / Supervisor')) { $pending.Add('Open ' + $role + ' demo') | Out-Null }
    for ($attempt = 0; $attempt -lt 6 -and $pending.Count -gt 0; $attempt++) {
        $screen = Read-AppScreen $Label
        foreach ($button in @($pending)) {
            if ($null -ne (Find-MatchingNode $screen ('^' + [regex]::Escape($button) + '$') -EnabledOnly)) { $pending.Remove($button) | Out-Null }
        }
        if ($pending.Count -gt 0 -and !(Scroll-App $screen $true)) { break }
    }
    if ($pending.Count -gt 0) { throw ('Missing role chooser buttons: ' + ($pending -join ', ')) }
    Record-Step $Label
    Save-AppScreenshot $Label
}

function Start-App {
    $launch = Invoke-DeviceCommand -CommandArguments @('shell', 'am', 'start', '-W', '--user', '0', '-n', $componentName)
    if ($launch -notmatch 'Status: ok') { throw ('Android launcher did not confirm startup: ' + $launch) }
    Start-Sleep -Milliseconds 800
}

function Reset-PracticeData {
    Tap-AppLabel '^Reset offline demo$' 'open-demo-reset'
    Assert-AppLabel '^Reset offline practice data\?$' 'reset-confirmation' | Out-Null
    Tap-AppLabel '^Reset practice data$' 'confirm-demo-reset'
}

$failureMessage = $null
try {
    if ((Invoke-DeviceCommand -CommandArguments @('get-state')).Trim() -ne 'device') { throw 'The selected Android device is unavailable or unauthorized.' }
    if ((Invoke-DeviceCommand -CommandArguments @('shell', 'pm', 'path', $packageName)) -notmatch 'package:') { throw 'The combined AeroTrans APK is not installed.' }
    Start-App
    $initialScreen = Assert-AppLabel '^(Choose a demo role|AeroTrans (Customer|Control Room|Driver|Supervisor))$' 'initial-ready'
    if ($null -eq (Find-MatchingNode $initialScreen '^Choose a demo role$')) {
        # A previous smoke run leaves Customer open. Reset only this new
        # combined practice installation through its own confirmation dialog.
        Reset-PracticeData
    }
    Assert-Chooser 'initial-four-role-chooser'
    Tap-AppLabel '^Open Customer demo$' 'open-customer'
    Assert-AppLabel '^AeroTrans Customer$' 'customer-dashboard' | Out-Null
    Save-AppScreenshot 'customer-dashboard'
    Record-Step 'Customer opens'

    $currentPersona = 'Customer - Demo Customer'
    foreach ($target in @(
        @{ Persona = 'Control Room - Demo Control Room'; Header = 'AeroTrans Control Room'; Label = 'control-room' },
        @{ Persona = 'Driver - Demo Driver'; Header = 'AeroTrans Driver'; Label = 'driver' },
        @{ Persona = 'Supervisor - Demo Supervisor'; Header = 'AeroTrans Supervisor'; Label = 'supervisor' }
    )) {
        Tap-AppLabel ('^' + [regex]::Escape($currentPersona) + '$') 'open-role-switcher'
        Assert-AppLabel '^Switch demo role$' 'role-switcher' | Out-Null
        Tap-AppLabel ('^' + [regex]::Escape($target.Persona) + '$') ('select-' + $target.Label)
        Assert-AppLabel ('^' + [regex]::Escape($target.Header) + '$') ($target.Label + '-dashboard') | Out-Null
        Save-AppScreenshot ($target.Label + '-dashboard')
        Record-Step ($target.Label + ' opens')
        $currentPersona = $target.Persona
    }

    Invoke-DeviceCommand -CommandArguments @('shell', 'am', 'force-stop', $packageName) | Out-Null
    Start-App
    Assert-AppLabel '^AeroTrans Supervisor$' 'persisted-supervisor' | Out-Null
    Save-AppScreenshot 'persisted-supervisor'
    Record-Step 'Supervisor selection persists after force-stop and reopen'
    Reset-PracticeData
    Assert-Chooser 'reset-restores-four-role-chooser'
    Tap-AppLabel '^Open Customer demo$' 'final-open-customer'
    Assert-AppLabel '^AeroTrans Customer$' 'final-customer-dashboard' | Out-Null
    Save-AppScreenshot 'final-customer-dashboard'
    Record-Step 'Customer left open after successful local reset'
} catch {
    $failureMessage = $_.Exception.Message
    throw
} finally {
    @{
        startedAt = $startedAt
        completedAt = [DateTime]::UtcNow.ToString('o')
        deviceSerial = $DeviceSerial
        packageId = $packageName
        passed = ($null -eq $failureMessage)
        failure = $failureMessage
        steps = @($steps.ToArray())
        scope = 'Physical startup, role navigation, selected-persona persistence and UI reset only. No connectivity changes or full booking/provider acceptance.'
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidencePath 'smoke-results.json') -Encoding UTF8
}
