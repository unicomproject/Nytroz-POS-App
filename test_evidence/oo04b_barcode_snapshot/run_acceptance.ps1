$ErrorActionPreference = 'Stop'
$adb = "C:\Users\User\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$out = "C:\Users\User\Downloads\EPOS\Pos Frontend\Nytroz-POS-App\test_evidence\oo04b_barcode_snapshot"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$log = Join-Path $out 'runtime-acceptance.log'
'' | Set-Content $log

function Write-Log([string]$msg) { $msg | Tee-Object -FilePath $log -Append }

function Invoke-Shot([string]$name) {
  & $adb -s emulator-5554 shell screencap -p "/sdcard/$name"
  & $adb -s emulator-5554 pull "/sdcard/$name" (Join-Path $out $name) | Out-Null
}

function Invoke-Tap([int]$x, [int]$y) {
  & $adb -s emulator-5554 shell input tap $x $y
  Start-Sleep -Milliseconds 1100
}

function Get-UiXml {
  & $adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml | Out-Null
  & $adb -s emulator-5554 pull /sdcard/ui.xml (Join-Path $out 'ui-tmp.xml') | Out-Null
  return (Get-Content (Join-Path $out 'ui-tmp.xml') -Raw)
}

function Get-Center([string]$ui, [string]$label) {
  $escaped = [regex]::Escape($label)
  foreach ($attr in @('content-desc', 'text')) {
    $pattern = ('{0}="{1}"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' -f $attr, $escaped)
    $m = [regex]::Match($ui, $pattern)
    if (-not $m.Success) {
      $pattern = ('{0}="[^"]*{1}[^"]*"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' -f $attr, $escaped)
      $m = [regex]::Match($ui, $pattern)
    }
    if ($m.Success) {
      $x = [int]((([int]$m.Groups[1].Value) + ([int]$m.Groups[3].Value)) / 2)
      $y = [int]((([int]$m.Groups[2].Value) + ([int]$m.Groups[4].Value)) / 2)
      return @{ X = $x; Y = $y }
    }
  }
  return $null
}

function Wait-For([string]$needle, [int]$seconds = 10) {
  for ($i = 0; $i -lt $seconds; $i++) {
    $ui = Get-UiXml
    if ($ui -match [regex]::Escape($needle)) { return $ui }
    Start-Sleep -Seconds 1
  }
  return (Get-UiXml)
}

function Dump-Labels([string]$ui, [string]$file) {
  [regex]::Matches($ui, 'content-desc="([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_.Trim().Length -gt 0 } |
    Select-Object -Unique |
    Out-File (Join-Path $out $file)
}

Write-Log '=== NAV: Home -> Online Orders -> Accepted-002 ==='
# Home tab
Invoke-Tap 256 1468
Start-Sleep -Seconds 1
$ui = Wait-For 'Online Orders' 6
$online = Get-Center $ui 'Online Orders'
if ($null -eq $online) { Dump-Labels $ui 'home-fail-labels.txt'; throw 'Online Orders tile missing' }
Invoke-Tap $online.X $online.Y
Start-Sleep -Seconds 2
$ui = Wait-For 'ECOMM-SEED' 8
Invoke-Shot 'nav-online-orders.png'
Write-Log ("Online Orders list has ECOMM-SEED: {0}" -f ($ui -match 'ECOMM-SEED'))

$target = Get-Center $ui 'ECOMM-SEED-ACCEPTED-002'
if ($null -eq $target) {
  & $adb -s emulator-5554 shell input swipe 1280 1200 1280 500 350
  Start-Sleep -Seconds 1
  $ui = Get-UiXml
  $target = Get-Center $ui 'ECOMM-SEED-ACCEPTED-002'
}
if ($null -eq $target) { Dump-Labels $ui 'queue-labels.txt'; throw 'Accepted-002 missing in queue' }
Invoke-Tap $target.X $target.Y
Start-Sleep -Seconds 2
$ui = Wait-For 'ECOMM-SEED-ACCEPTED-002' 6
Invoke-Shot 'nav-order-detail.png'

$ctaLabels = @(
  'Continue Fulfilment','Continue Fulfillment','Start Fulfilment','Start Fulfillment',
  'Continue Picking','Resume Picking','Start Picking','Continue'
)
$cta = $null
foreach ($label in $ctaLabels) {
  $cta = Get-Center $ui $label
  if ($null -ne $cta) { Write-Log ("CTA found: $label"); break }
}
if ($null -eq $cta) { Dump-Labels $ui 'detail-labels.txt'; throw 'Fulfilment CTA missing' }
Invoke-Tap $cta.X $cta.Y
Start-Sleep -Seconds 2
$ui = Get-UiXml
$confirm = Get-Center $ui 'Confirm'
if ($null -ne $confirm) { Invoke-Tap $confirm.X $confirm.Y; Start-Sleep -Seconds 2 }

$ui = Wait-For 'Training Basketball' 8
if (-not ($ui -match 'Training Basketball') -and -not ($ui -match 'MER-012')) {
  Dump-Labels $ui 'picking-labels.txt'
  throw 'Picking overview missing Training Basketball'
}
$item = Get-Center $ui 'Training Basketball'
if ($null -eq $item) { $item = Get-Center $ui 'MER-012-SKU' }
Invoke-Tap $item.X $item.Y
Start-Sleep -Seconds 2
$ui = Wait-For 'Enter Barcode Manually' 8
if (-not ($ui -match 'ECOMM-SEED-ACCEPTED-002')) { throw 'OO-04B wrong order' }
if (-not ($ui -match 'Enter Barcode Manually')) { throw 'OO-04B not opened' }
Write-Log 'OO-04B opened for Accepted-002'
Invoke-Shot 'before.png'
Write-Log ("before progress 0/1 visible: {0}" -f ($ui -match '0 / 1'))

Write-Log '=== CORRECT BARCODE 2000000001210 ==='
$manual = Get-Center $ui 'Enter Barcode Manually'
Invoke-Tap $manual.X $manual.Y
Start-Sleep -Seconds 1
$ui = Wait-For 'Verify' 5
& $adb -s emulator-5554 shell input text '2000000001210'
Start-Sleep -Milliseconds 800
Invoke-Shot 'correct-barcode-dialog.png'
$ui = Get-UiXml
$v = Get-Center $ui 'Verify'
if ($null -eq $v) { throw 'Verify missing' }
Invoke-Tap $v.X $v.Y
Start-Sleep -Seconds 2
$ui = Get-UiXml
$bad = ($ui -match 'does not match') -or ($ui -match 'verification is unavailable')
Write-Log ("correct barcode rejected: {0}" -f $bad)
if ($bad) { Invoke-Shot 'correct-fail.png'; throw 'Correct barcode rejected' }

$mark = Get-Center $ui 'Mark as Picked'
if ($null -eq $mark) { Dump-Labels $ui 'after-verify-labels.txt'; throw 'Mark as Picked missing' }
Invoke-Tap $mark.X $mark.Y
Start-Sleep -Seconds 3
$ui = Get-UiXml
Invoke-Shot 'after-success.png'
Write-Log ("after UI still Accepted-002: {0}" -f ($ui -match 'ECOMM-SEED-ACCEPTED-002'))
Write-Log ("after progress 1/1 or can pack cues: {0}" -f (($ui -match '1 / 1') -or ($ui -match 'Review') -or ($ui -match 'Pack')))

Write-Log '=== WRONG BARCODE on Accepted-001 ==='
# Navigate to Accepted-001 for verification-only wrong barcode
Invoke-Tap 256 1468
Start-Sleep -Seconds 1
$ui = Wait-For 'Online Orders' 5
$online = Get-Center $ui 'Online Orders'
Invoke-Tap $online.X $online.Y
Start-Sleep -Seconds 2
$ui = Wait-For 'ECOMM-SEED-ACCEPTED-001' 8
$a1 = Get-Center $ui 'ECOMM-SEED-ACCEPTED-001'
if ($null -eq $a1) { throw 'Accepted-001 missing for wrong barcode' }
Invoke-Tap $a1.X $a1.Y
Start-Sleep -Seconds 2
$ui = Get-UiXml
$cta = $null
foreach ($label in $ctaLabels) {
  $cta = Get-Center $ui $label
  if ($null -ne $cta) { break }
}
if ($null -ne $cta) { Invoke-Tap $cta.X $cta.Y; Start-Sleep -Seconds 2 }
$ui = Get-UiXml
$confirm = Get-Center $ui 'Confirm'
if ($null -ne $confirm) { Invoke-Tap $confirm.X $confirm.Y; Start-Sleep -Seconds 2 }
$ui = Wait-For 'Enter Barcode Manually' 3
if (-not ($ui -match 'Enter Barcode Manually')) {
  $item = Get-Center $ui 'Match Shorts'
  if ($null -eq $item) { $item = Get-Center $ui 'MER-003-SKU' }
  if ($null -ne $item) { Invoke-Tap $item.X $item.Y; Start-Sleep -Seconds 2 }
  $ui = Wait-For 'Enter Barcode Manually' 6
}
Write-Log ("Accepted-001 OO-04B open: {0}" -f ($ui -match 'Enter Barcode Manually'))

# Capture version/picked baseline via UI text markers
$wrongBeforeUi = $ui
$manual = Get-Center $ui 'Enter Barcode Manually'
Invoke-Tap $manual.X $manual.Y
Start-Sleep -Seconds 1
& $adb -s emulator-5554 shell input text 'WRONGBARCODE999'
Start-Sleep -Milliseconds 700
$ui = Get-UiXml
$v = Get-Center $ui 'Verify'
Invoke-Tap $v.X $v.Y
Start-Sleep -Seconds 2
Invoke-Shot 'wrong-barcode.png'
$ui = Get-UiXml
$wrongOk = ($ui -match 'does not match the selected item') -or ($ui -match 'Barcode does not match')
Write-Log ("wrong barcode UI rejection: {0}" -f $wrongOk)
if (-not $wrongOk) { Dump-Labels $ui 'wrong-fail-labels.txt'; throw 'Wrong barcode not rejected' }

Write-Log 'RUNTIME FLOW COMPLETE'
Get-Content $log
