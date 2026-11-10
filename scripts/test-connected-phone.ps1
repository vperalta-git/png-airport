param(
    [ValidatePattern('^[A-Za-z0-9_.:-]+$')]
    [string]$DeviceSerial = 'd381fffa0421'
)

$ErrorActionPreference = 'Stop'
$packageName = 'com.pngtransfer.png_transfer_client.connected'
$componentName = $packageName + '/com.pngtransfer.png_transfer_client.MainActivity'
$projectRoot = Split-Path -Parent $PSScriptRoot
$evidencePath = Join-Path $projectRoot '.local-tools\connected\device'
$accountsPath = Join-Path $projectRoot '.local-tools\demo\accounts.json'
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adbPath = Join-Path $sdkRoot 'platform-tools\adb.exe'
$remoteXml = '/data/local/tmp/aerotrans-connected-smoke.xml'
if (!(Test-Path -LiteralPath $adbPath)) { throw 'Android Debug Bridge is unavailable.' }
if (!(Test-Path -LiteralPath $accountsPath)) { throw 'Run the existing local demo setup before this phone smoke check.' }

# Credentials are read at runtime only. They are never printed, exported,
# embedded in an APK, or included in error messages/process command diagnostics.
try { $sheet = [IO.File]::ReadAllText($accountsPath) | ConvertFrom-Json }
catch { throw 'The ignored local fixture sheet could not be read. Run demo setup again; credential contents are withheld.' }
if ($sheet.projectId -ne 'demo-aerotrans-png2' -or $sheet.mode -ne 'ISOLATED DEMO') { throw 'The fixture sheet does not identify the isolated local demo.' }
$accounts = @($sheet.accounts)
$secrets = New-Object 'System.Collections.Generic.List[string]'
foreach ($account in $accounts) {
    if ($account.password) { $secrets.Add([string]$account.password) }
}
New-Item -ItemType Directory -Path $evidencePath -Force | Out-Null
$script:captureNumber = 0
$results = New-Object 'System.Collections.Generic.List[object]'
$startedAt = [DateTime]::UtcNow.ToString('o')

function Invoke-AdbCaptured([string[]]$CommandArguments, [string]$Operation, [int]$TimeoutMs = 20000) {
    # All variable shell input is restricted to a safe token alphabet before use.
    # No native output or argument list is emitted, even when a command fails.
    $process = New-Object Diagnostics.Process
    $process.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $adbPath
    $process.StartInfo.Arguments = '-s ' + $DeviceSerial + ' ' + ($CommandArguments -join ' ')
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    try {
        if (!$process.Start()) { throw 'ADB process did not start.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit($TimeoutMs)) { $process.Kill(); throw 'ADB timed out.' }
        $stdoutText = $stdoutTask.GetAwaiter().GetResult()
        $stderrText = $stderrTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw 'ADB returned an error.' }
        return [PSCustomObject]@{ Output = $stdoutText; ErrorOutput = $stderrText }
    } catch {
        throw ('Android operation failed: ' + $Operation + '. Check USB authorization and keep the phone unlocked. Command arguments and native errors are withheld to protect fixture credentials.')
    } finally { $process.Dispose() }
}

function Read-AppScreen([string]$Label) {
    $dump = Invoke-AdbCaptured -CommandArguments @('shell', 'uiautomator', 'dump', $remoteXml) -Operation 'capture app hierarchy' -TimeoutMs 30000
    if (($dump.Output + $dump.ErrorOutput) -notmatch 'dumped to:') { throw 'Android did not confirm a UI dump. Keep AeroTrans Connected visible and retry.' }
    try {
        $content = Invoke-AdbCaptured -CommandArguments @('exec-out', 'cat', $remoteXml) -Operation 'read app hierarchy'
        [xml]$xml = $content.Output
    } finally {
        try { $null = Invoke-AdbCaptured -CommandArguments @('shell', 'rm', '-f', $remoteXml) -Operation 'remove temporary hierarchy' } catch { }
    }
    $nodes = @($xml.SelectNodes("//node[@package='$packageName']"))
    if ($nodes.Count -eq 0) { throw 'AeroTrans Connected is not visible. Unlock the phone and dismiss any system prompt. No control outside the target app was tapped or saved.' }

    # Preserve only sanitized app evidence; raw input values remain in memory.
    [xml]$sanitized = $xml.CloneNode($true)
    foreach ($node in @($sanitized.SelectNodes("//node[@package!='' and @package!='$packageName']"))) {
        if ($null -ne $node.ParentNode) { $node.ParentNode.RemoveChild($node) | Out-Null }
    }
    foreach ($node in $sanitized.SelectNodes("//node[@password='true' or @class='android.widget.EditText']")) {
        $node.SetAttribute('text', '[INPUT REDACTED]')
        if ($node.GetAttribute('password') -eq 'true') {
            $node.SetAttribute('content-desc', 'Password [REDACTED]')
            $node.SetAttribute('hint', '[REDACTED]')
        }
    }
    $safeText = $sanitized.OuterXml
    foreach ($secret in $secrets) { $safeText = $safeText.Replace($secret, '[REDACTED]') }
    $script:captureNumber++
    $xmlPath = Join-Path $evidencePath ($script:captureNumber.ToString('000') + '-' + $Label + '.xml')
    [IO.File]::WriteAllText($xmlPath, $safeText, (New-Object Text.UTF8Encoding($false)))
    return [PSCustomObject]@{ Xml = $xml; Nodes = $nodes; Path = $xmlPath }
}

function Node-Bounds($Node) {
    if ($Node.GetAttribute('package') -ne $packageName -or $Node.GetAttribute('bounds') -notmatch '^\[(\d+),(\d+)\]\[(\d+),(\d+)\]$') { throw 'Refusing to interact outside the target app or without valid bounds.' }
    return [PSCustomObject]@{ Left = [int]$Matches[1]; Top = [int]$Matches[2]; Right = [int]$Matches[3]; Bottom = [int]$Matches[4] }
}

function Match-Node($Screen, [string]$Pattern, [switch]$Field) {
    foreach ($node in $Screen.Nodes) {
        if ($node.GetAttribute('enabled') -eq 'false') { continue }
        if ($Field -and $node.GetAttribute('class') -ne 'android.widget.EditText') { continue }
        if ($node.GetAttribute('text').Trim() -match $Pattern -or $node.GetAttribute('content-desc').Trim() -match $Pattern) {
            $bounds = Node-Bounds $node
            if ($bounds.Right -gt $bounds.Left -and $bounds.Bottom -gt $bounds.Top) { return $node }
        }
    }
    return $null
}

function Scroll-App($Screen, [bool]$TowardEnd) {
    $node = $Screen.Nodes | Where-Object { $_.GetAttribute('scrollable') -eq 'true' } | Select-Object -First 1
    if ($null -eq $node) { return $false }
    $bounds = Node-Bounds $node
    $x = [int](($bounds.Left + $bounds.Right) / 2)
    $upper = [int]($bounds.Top + ($bounds.Bottom - $bounds.Top) * 0.2)
    $lower = [int]($bounds.Top + ($bounds.Bottom - $bounds.Top) * 0.8)
    if ($bounds.Bottom -le $bounds.Top -or $bounds.Right -le $bounds.Left) { return $false }
    $from = if ($TowardEnd) { $lower } else { $upper }
    $to = if ($TowardEnd) { $upper } else { $lower }
    $null = Invoke-AdbCaptured -CommandArguments @('shell', 'input', 'swipe', "$x", "$from", "$x", "$to", '300') -Operation 'scroll app'
    Start-Sleep -Milliseconds 250
    return $true
}

function Find-Control([string]$Pattern, [string]$Label, [switch]$Field) {
    foreach ($direction in @($false, $true)) {
        for ($attempt = 0; $attempt -lt 5; $attempt++) {
            $screen = Read-AppScreen $Label
            $node = Match-Node $screen $Pattern -Field:$Field
            if ($null -ne $node) { return $node }
            if (!(Scroll-App $screen $direction)) { break }
        }
    }
    throw ('No enabled target-app control matched: ' + $Label + '. Review the sanitized evidence or phone screen.')
}

function Tap-Control([string]$Pattern, [string]$Label) {
    $node = Find-Control $Pattern $Label
    $bounds = Node-Bounds $node
    $x = [int](($bounds.Left + $bounds.Right) / 2)
    $y = [int](($bounds.Top + $bounds.Bottom) / 2)
    $null = Invoke-AdbCaptured -CommandArguments @('shell', 'input', 'tap', "$x", "$y") -Operation $Label
    Start-Sleep -Milliseconds 400
}

function Enter-Field([string]$Label, [string]$Value, [bool]$Secret) {
    if ($Secret) {
        if ($Value -notmatch '^[A-Za-z0-9_!.-]+$') { throw 'Fixture password cannot safely use Android shell text input. No credential was printed; enter it manually or use a dedicated input adapter.' }
    } elseif ($Value -notmatch '^[A-Za-z0-9._@+-]+$') { throw 'Fixture email cannot safely use Android shell text input.' }
    $node = Find-Control ('^' + [regex]::Escape($Label) + '(\r?\n|$)') ('focus-' + $Label.ToLowerInvariant()) -Field
    if ($node.GetAttribute('text') -notin @('', $Label)) { throw ('The ' + $Label + ' field is not empty. Return to workspace selection and retry to avoid appending to existing input.') }
    $bounds = Node-Bounds $node
    $x = [int](($bounds.Left + $bounds.Right) / 2)
    $y = [int](($bounds.Top + $bounds.Bottom) / 2)
    $null = Invoke-AdbCaptured -CommandArguments @('shell', 'input', 'tap', "$x", "$y") -Operation ('focus ' + $Label)
    $null = Invoke-AdbCaptured -CommandArguments @('shell', 'input', 'text', $Value) -Operation ('enter ' + $Label)
    Start-Sleep -Milliseconds 250
}

function Wait-ForScreen([string]$Pattern, [string]$Label, [switch]$Dashboard) {
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        $screen = Read-AppScreen $Label
        foreach ($node in $screen.Nodes) {
            if (($node.GetAttribute('text') + ' ' + $node.GetAttribute('content-desc')) -match 'Connection needs attention|review server is unavailable|Email or password is incorrect|This account is suspended|Cannot verify your account|Sign-out could not be completed') { throw ('The app reported a connection/authentication error during ' + $Label + '. Check the phone screen; credentials are not logged.') }
        }
        if ($null -ne (Match-Node $screen $Pattern) -and (!$Dashboard -or $null -ne (Match-Node $screen '^Switch account$'))) { return $screen }
        Start-Sleep -Milliseconds 350
    }
    throw ('Expected app state was not reached: ' + $Label + '. Only sanitized target-app evidence was saved.')
}

function Save-Dashboard([string]$Label, [string]$Header) {
    $screen = Wait-ForScreen ('^' + [regex]::Escape($Header) + '$') $Label -Dashboard
    if (@($screen.Nodes | Where-Object { $_.GetAttribute('password') -eq 'true' -or $_.GetAttribute('class') -eq 'android.widget.EditText' }).Count -ne 0) { throw 'Refusing a screenshot while any input field is present.' }
    $process = New-Object Diagnostics.Process
    $process.StartInfo = New-Object Diagnostics.ProcessStartInfo
    $process.StartInfo.FileName = $adbPath
    $process.StartInfo.Arguments = '-s ' + $DeviceSerial + ' exec-out screencap -p'
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $file = [IO.File]::Create((Join-Path $evidencePath ($Label + '.png')))
    try {
        if (!$process.Start()) { throw 'Screenshot capture failed.' }
        $copy = $process.StandardOutput.BaseStream.CopyToAsync($file)
        $stderr = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(15000)) { $process.Kill(); throw 'Screenshot timed out.' }
        $copy.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw 'Screenshot capture failed.' }
    } finally { $file.Dispose(); $process.Dispose() }
}

function Start-ConnectedApp {
    $launch = Invoke-AdbCaptured -CommandArguments @('shell', 'am', 'start', '-W', '--user', '0', '-n', $componentName) -Operation 'launch connected app'
    if ($launch.Output -notmatch 'Status: ok') { throw 'Android did not confirm the connected launcher.' }
    Start-Sleep -Milliseconds 800
}

$failure = $null
try {
    $device = Invoke-AdbCaptured -CommandArguments @('get-state') -Operation 'verify device'
    if ($device.Output.Trim() -ne 'device') { throw 'The selected phone is unavailable or unauthorized.' }
    Start-ConnectedApp
    $initial = Wait-ForScreen '^Choose your workspace$|^Switch account$|^Back to accounts$' 'initial-state'
    if ($null -ne (Match-Node $initial '^Switch account$')) {
        Tap-Control '^Switch account$' 'initial-switch-account'
    } elseif ($null -ne (Match-Node $initial '^Back to accounts$')) {
        Tap-Control '^Back to accounts$' 'initial-back-to-accounts'
    }
    Wait-ForScreen '^Choose your workspace$' 'workspace-selection' | Out-Null
    foreach ($target in @(
        @{ Role = 'PASSENGER'; Card = 'Customer'; Header = 'AeroTrans Customer'; Label = 'customer' },
        @{ Role = 'DISPATCHER'; Card = 'Control Room'; Header = 'AeroTrans Control Room'; Label = 'control-room' },
        @{ Role = 'DRIVER'; Card = 'Driver'; Header = 'AeroTrans Driver'; Label = 'driver' },
        @{ Role = 'SUPERVISOR'; Card = 'Manager / Supervisor'; Header = 'AeroTrans Supervisor'; Label = 'supervisor' }
    )) {
        $fixture = @($accounts | Where-Object { $_.role -eq $target.Role })
        if ($fixture.Count -ne 1 -or !$fixture[0].uid -or !$fixture[0].email -or !$fixture[0].password) { throw ('Expected exactly one owned local fixture for role ' + $target.Role) }
        if ($fixture[0].uid -ne ('demo-' + $target.Role.ToLowerInvariant()) -or $fixture[0].email -ne ($target.Role.ToLowerInvariant() + '@aerotrans-demo.invalid')) { throw 'Fixture identity is not owned by the established local demo setup.' }
        Tap-Control ('^' + [regex]::Escape($target.Card) + '(\r?\n|$)') ('choose-' + $target.Label)
        Wait-ForScreen '^Sign in to ' ('sign-in-' + $target.Label) | Out-Null
        Enter-Field 'Email' ([string]$fixture[0].email) $false
        Enter-Field 'Password' ([string]$fixture[0].password) $true
        Tap-Control '^Sign in$' ('submit-' + $target.Label)
        Save-Dashboard ($target.Label + '-dashboard') $target.Header
        $results.Add([PSCustomObject]@{
            role = $target.Role
            expectedFixtureUid = [string]$fixture[0].uid
            observedDashboard = $target.Header
            passed = $true
            uidReadDirectlyByScript = $false
            authority = 'Real Firebase UI sign-in; app controller requires active matching-UID backend /auth/me profile. Script verifies resulting role dashboard.'
        })
        Write-Host ('PASS real connected UI sign-in: ' + $target.Role)
        if ($target.Role -ne 'SUPERVISOR') {
            Tap-Control '^Switch account$' ('switch-after-' + $target.Label)
            Wait-ForScreen '^Choose your workspace$' ('signed-out-' + $target.Label) | Out-Null
        }
    }
    $null = Invoke-AdbCaptured -CommandArguments @('shell', 'am', 'force-stop', $packageName) -Operation 'restart connected review app'
    Start-ConnectedApp
    Save-Dashboard 'supervisor-restored' 'AeroTrans Supervisor'
    Write-Host 'PASS Supervisor session restored after restart; Supervisor left signed in.'
} catch {
    # All custom diagnostics are credential-free. Redact defensively before any
    # error is persisted or propagated to the calling terminal.
    $failure = $_.Exception.Message
    foreach ($secret in $secrets) { $failure = $failure.Replace($secret, '[REDACTED]') }
} finally {
    @{
        startedAt = $startedAt
        completedAt = [DateTime]::UtcNow.ToString('o')
        packageId = $packageName
        deviceSerial = $DeviceSerial
        passed = ($null -eq $failure)
        failure = $failure
        results = @($results.ToArray())
        scope = 'Real native UI authentication, backend-authorized role dashboards, safe account switching and Supervisor session restore. No booking creation, backend reset, production access or provider acceptance.'
    } | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $evidencePath 'connected-smoke-results.json') -Encoding UTF8
    foreach ($account in $accounts) { $account.password = $null }
    $secrets.Clear()
    $sheet = $null
}
if ($null -ne $failure) { throw $failure }
