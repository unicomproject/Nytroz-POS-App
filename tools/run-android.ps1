param(
    [string]$Device,
    [ValidateSet('debug','profile')][string]$Mode = 'debug',
    [string]$ApiBaseUrl
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
if (!(Test-Path -LiteralPath $adb)) { throw 'Android SDK adb was not found.' }
if (!$Device) {
    $connected = @(& $adb devices | ForEach-Object {
        if ($_ -match '^(\S+)\s+device$') { $Matches[1] }
    })
    $unlocked = @($connected | Where-Object {
        $candidate = $_
        $userId = ((& $adb -s $candidate shell am get-current-user) -join '').Trim()
        $userStates = (& $adb -s $candidate shell dumpsys user) -join "`n"
        $userId -match '^\d+$' -and
            $userStates -match ('\b' + [regex]::Escape($userId) + '=RUNNING_UNLOCKED\b')
    })
    if ($unlocked.Count -eq 0) {
        throw 'No unlocked Android device found. Start and unlock an emulator, then retry.'
    }
    if ($unlocked.Count -gt 1) {
        throw "Multiple unlocked devices found: $($unlocked -join ', '). Specify -Device <id>."
    }
    $Device = $unlocked[0]
    Write-Output "Using unlocked Android device: $Device"
}
$connection = & $adb -s $Device get-state 2>$null
if ($LASTEXITCODE -ne 0 -or $connection -ne 'device') {
    throw 'Start and connect the Android device first. Run flutter devices to check its ID.'
}
$currentUser = (& $adb -s $Device shell am get-current-user).Trim()
if ($LASTEXITCODE -ne 0 -or $currentUser -notmatch '^\d+$') { throw 'Unable to identify the Android user.' }
$users = (& $adb -s $Device shell dumpsys user) -join "`n"
if ($users -notmatch ('\b' + [regex]::Escape($currentUser) + '=RUNNING_UNLOCKED\b')) {
    Write-Output 'Android is locked. Enter the Android screen-lock password/PIN in the emulator, then rerun this command.'
    Write-Output 'This is not your ONEVERZ password. No build, reinstall, or data reset was performed.'
    exit 2
}
$flutter = Get-Command flutter -ErrorAction Stop
$arguments = @('run', ('--' + $Mode), '-d', $Device)
if ($ApiBaseUrl) { $arguments += "--dart-define=API_BASE_URL=$ApiBaseUrl" }
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $flutter.Source @arguments
    $result = $LASTEXITCODE
} finally { Pop-Location }
exit $result
