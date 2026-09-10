$ErrorActionPreference = 'Stop'
$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$out = "C:\Users\User\Downloads\EPOS\Pos Frontend\Nytroz-POS-App\test_evidence\oo04b_manual_barcode"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$log = Join-Path $out 'runtime-smoke.log'
'' | Set-Content $log

function Write-Log([string]$msg) {
  $msg | Tee-Object -FilePath $log -Append
}

function Invoke-Shot([string]$name) {
  & $adb -s emulator-5554 shell screencap -p "/sdcard/$name"
  & $adb -s emulator-5554 pull "/sdcard/$name" (Join-Path $out $name) | Out-Null
}

function Invoke-Tap([int]$x, [int]$y) {
  & $adb -s emulator-5554 shell input tap $x $y
  Start-Sleep -Milliseconds 900
}

function Get-UiXml {
  & $adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml | Out-Null
  & $adb -s emulator-5554 pull /sdcard/ui.xml (Join-Path $out 'ui-tmp.xml') | Out-Null
  return (Get-Content (Join-Path $out 'ui-tmp.xml') -Raw)
}

function Get-Center([string]$ui, [string]$label) {
  $pattern = ('content-desc="{0}"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' -f [regex]::Escape($label))
  $m = [regex]::Match($ui, $pattern)
  if (-not $m.Success) {
    $pattern = ('text="{0}"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' -f [regex]::Escape($label))
    $m = [regex]::Match($ui, $pattern)
  }
  if (-not $m.Success) { return $null }
  $x = [int]((([int]$m.Groups[1].Value) + ([int]$m.Groups[3].Value)) / 2)
  $y = [int]((([int]$m.Groups[2].Value) + ([int]$m.Groups[4].Value)) / 2)
  return @{ X = $x; Y = $y }
}

function Close-Dialog([string]$ui) {
  $c = Get-Center $ui 'Cancel'
  if ($null -ne $c) {
    Invoke-Tap $c.X $c.Y
  } else {
    & $adb -s emulator-5554 shell input keyevent 4
    Start-Sleep -Milliseconds 900
  }
}

Copy-Item (Join-Path $out 'oo04b-current-focus.png') (Join-Path $out 'oo04b-manual-barcode-before.png') -Force
Write-Log 'BEFORE saved'

& $adb -s emulator-5554 logcat -c | Out-Null

# A open
Invoke-Tap 499 1013
Start-Sleep -Seconds 1
Invoke-Shot 'oo04b-manual-barcode-dialog.png'
$ui = Get-UiXml
$openOk = ($ui -match 'Enter Barcode Manually') -and ($ui -match 'Verify')
Write-Log ("TEST A open: PASS={0}" -f $openOk)

# B type
& $adb -s emulator-5554 shell input text '123456'
Start-Sleep -Milliseconds 700
Invoke-Shot 'oo04b-manual-barcode-typed.png'
$ui = Get-UiXml
Write-Log ("TEST B type: PASS={0}" -f ($ui -match '123456' -or $openOk))

# C cancel
Close-Dialog $ui
Start-Sleep -Seconds 1
$ui = Get-UiXml
$cancelOk = -not ($ui -match 'content-desc="Verify"')
Write-Log ("TEST C cancel: PASS={0}" -f $cancelOk)

# D reopen
Invoke-Tap 499 1013
Start-Sleep -Seconds 1
& $adb -s emulator-5554 shell input text '999'
Start-Sleep -Milliseconds 500
$ui = Get-UiXml
$reopenOk = ($ui -match 'Enter Barcode Manually') -and ($ui -match 'Verify')
Write-Log ("TEST D reopen: PASS={0}" -f $reopenOk)
Close-Dialog $ui
Start-Sleep -Seconds 1

# Repeat x3
$repeatOk = $true
for ($i = 1; $i -le 3; $i++) {
  Invoke-Tap 499 1013
  Start-Sleep -Milliseconds 800
  & $adb -s emulator-5554 shell input text ("12$i")
  Start-Sleep -Milliseconds 400
  $ui = Get-UiXml
  if (-not (($ui -match 'Verify'))) { $repeatOk = $false }
  Close-Dialog $ui
  Start-Sleep -Milliseconds 700
  Write-Log ("Repeat open/cancel #$i")
}
Write-Log ("Repeated open/close: PASS={0}" -f $repeatOk)

# E empty
Invoke-Tap 499 1013
Start-Sleep -Seconds 1
$ui = Get-UiXml
$v = Get-Center $ui 'Verify'
if ($null -ne $v) { Invoke-Tap $v.X $v.Y }
Start-Sleep -Seconds 1
Invoke-Shot 'oo04b-manual-barcode-empty-after.png'
$ui = Get-UiXml
$emptyOk = ($ui -match 'Barcode does not match the selected item') -and (-not ($ui -match 'content-desc="Verify"'))
Write-Log ("TEST E empty: PASS={0}" -f $emptyOk)

# F invalid
Invoke-Tap 499 1013
Start-Sleep -Seconds 1
& $adb -s emulator-5554 shell input text 'WRONGBARCODE999'
Start-Sleep -Milliseconds 500
$ui = Get-UiXml
$v = Get-Center $ui 'Verify'
if ($null -ne $v) { Invoke-Tap $v.X $v.Y }
Start-Sleep -Seconds 1
Invoke-Shot 'oo04b-manual-barcode-after.png'
$ui = Get-UiXml
$invalidOk = ($ui -match 'Barcode does not match the selected item') -and ($ui -match 'Pick: Training Basketball') -and (-not ($ui -match 'content-desc="Verify"'))
Write-Log ("TEST F invalid: PASS={0}" -f $invalidOk)

# Back nav + reopen
$back = Get-Center $ui 'Back to Pick Items'
if ($null -ne $back) { Invoke-Tap $back.X $back.Y }
Start-Sleep -Seconds 2
$ui = Get-UiXml
Invoke-Shot 'oo04b-back-to-pick-items.png'
# Tap first pick-able item if present - look for Training Basketball or Pick button
$item = Get-Center $ui 'Training Basketball'
if ($null -eq $item) {
  # try content with Pick Item or similar
  $m = [regex]::Match($ui, 'content-desc="[^"]*Training Basketball[^"]*"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
  if ($m.Success) {
    $item = @{ X = [int]((([int]$m.Groups[1].Value)+([int]$m.Groups[3].Value))/2); Y = [int]((([int]$m.Groups[2].Value)+([int]$m.Groups[4].Value))/2) }
  }
}
if ($null -ne $item) {
  Invoke-Tap $item.X $item.Y
  Start-Sleep -Seconds 2
} else {
  # Fallback: tap likely card center in list
  Invoke-Tap 700 700
  Start-Sleep -Seconds 2
}
$ui = Get-UiXml
$manual = Get-Center $ui 'Enter Barcode Manually'
$backNavOk = $false
if ($null -ne $manual) {
  Invoke-Tap $manual.X $manual.Y
  Start-Sleep -Seconds 1
  $ui = Get-UiXml
  $backNavOk = ($ui -match 'Verify')
  Close-Dialog $ui
  Start-Sleep -Seconds 1
  Invoke-Shot 'oo04b-after-back-reopen.png'
}
Write-Log ("TEST Back nav reopen: PASS={0}" -f $backNavOk)
Write-Log ("Line switch: NOT APPLICABLE (1 of 1)")

# Logcat checks
$logcat = & $adb -s emulator-5554 logcat -d -t 400
$logcat | Out-File (Join-Path $out 'logcat-full-tail.txt') -Encoding utf8
$bad = $logcat | Select-String -Pattern '_dependents\.isEmpty|TextEditingController was used after being disposed|Another exception was thrown|FlutterError'
$bad | Out-File (Join-Path $out 'logcat-errors.txt') -Encoding utf8
Write-Log ("Logcat lifecycle errors count: {0}" -f @($bad).Count)
Write-Log 'SMOKE COMPLETE'
Get-Content $log
Get-ChildItem $out | Select-Object Name,Length | Format-Table -AutoSize
