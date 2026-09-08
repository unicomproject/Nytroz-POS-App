param(
    [string]$Device = 'emulator-5554',
    [ValidateSet('debug','profile')][string]$Mode = 'debug',
    [string]$ApiBaseUrl
)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
if (!(Test-Path -LiteralPath $adb)) { throw 'Android SDK adb was not found.' }
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
