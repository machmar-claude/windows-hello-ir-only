# Windows Hello IR-only: makes face sign-in work in the dark again.
# Some camera drivers put the colour and IR cameras into one sensor group, and since the
# April 2025 update Windows Hello then needs the colour camera to see your face too.
# This removes that group, so Hello uses the IR camera on its own. The webcam keeps working.
#
# Normally started by fix.cmd / undo.cmd. Manually, in an Administrator PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\hello-ir-only.ps1          # apply
#   powershell -ExecutionPolicy Bypass -File .\hello-ir-only.ps1 -Undo    # restore backups
param([switch]$Undo)
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$backupDir   = Join-Path $PSScriptRoot 'backup'
$groupValues = 'FSSensorGroupID', 'FSSensorGroupName', 'UVC-FSSensorGroupID', 'UVC-FSSensorGroupName'

function Get-InstanceId([string]$symLink) {
  # \\?\USB#VID_13D3&PID_56EB&MI_00#6&5308fd4&0&0000#{guid}\GLOBAL  ->  USB\VID_13D3&PID_56EB&MI_00\6&5308fd4&0&0000
  $p = ($symLink -replace '^\\\\\?\\', '') -split '#'
  "$($p[0])\$($p[1])\$($p[2])"
}

function Get-GroupedFaceCameras($root = 'HKLM:\SOFTWARE\Microsoft\Windows Media Foundation\FrameServer\SensorGroups') {
  # Sensor groups Windows has published that combine several cameras AND have a face sign-in stream.
  foreach ($g in Get-ChildItem $root -ErrorAction SilentlyContinue) {
    $p = Get-ItemProperty $g.PSPath
    $devs = @($p.PSObject.Properties | Where-Object Name -match '^Device\d+$' | ForEach-Object Value)
    if ($devs.Count -ge 2 -and $p.FaceAuthInfo -match 'face_auth_streamid=\d') {
      [pscustomobject]@{ Name = $p.SensorGroupFriendlyName; Devices = @($devs | ForEach-Object { Get-InstanceId $_ }) }
    }
  }
}

function Get-CameraKeys([string]$instanceId) {
  # The group is stored on the camera's device key and on each of its device-interface keys.
  "HKLM\SYSTEM\CurrentControlSet\Enum\$instanceId\Device Parameters"
  $prefix = '##?#' + ($instanceId -replace '\\', '#') + '#'
  foreach ($cls in Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceClasses') {
    foreach ($i in Get-ChildItem $cls.PSPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName.StartsWith($prefix, 'OrdinalIgnoreCase') }) {
      $k = Join-Path $i.PSPath '#GLOBAL\Device Parameters'
      if (Test-Path $k) { (Get-Item $k).Name -replace '^HKEY_LOCAL_MACHINE', 'HKLM' }
    }
  }
}

function Restart-Cameras {
  Stop-Service FrameServer, FrameServerMonitor -Force -ErrorAction SilentlyContinue
  Get-PnpDevice -PresentOnly -Class Camera, Image -ErrorAction SilentlyContinue |
    Where-Object InstanceId -like 'USB\*' | ForEach-Object { pnputil /restart-device "$($_.InstanceId)" | Out-Null }
  Start-Service WbioSrvc
}

if ($Undo) {
  $files = @(Get-ChildItem $backupDir -Filter *.reg -ErrorAction SilentlyContinue)
  if (-not $files) { throw "No backups in $backupDir, so there is nothing to undo." }
  Stop-Service WbioSrvc -Force
  foreach ($f in $files) { reg.exe import $f.FullName 2>$null | Out-Null; "restored $($f.Name)" }
  Restart-Cameras
  'Original camera settings restored.'
} else {
  $groups = @(Get-GroupedFaceCameras)
  if (-not $groups) { 'No combined colour+IR face sign-in camera group found. Nothing to change.'; return }
  New-Item -ItemType Directory -Force $backupDir | Out-Null
  Stop-Service WbioSrvc -Force
  foreach ($g in $groups) {
    "Breaking up camera group '$($g.Name)'"
    foreach ($k in $g.Devices | ForEach-Object { Get-CameraKeys $_ }) {
      $present = @((Get-Item "Registry::$k" -ErrorAction SilentlyContinue).Property | Where-Object { $_ -in $groupValues })
      if (-not $present) { continue }
      $hash = [BitConverter]::ToString([Security.Cryptography.SHA1]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($k.ToLower()))) -replace '-'
      $file = Join-Path $backupDir "$($hash.Substring(0, 12)).reg"
      if (-not (Test-Path $file)) { reg.exe export $k $file /y | Out-Null }   # never overwrite an older backup
      Remove-ItemProperty -Path "Registry::$k" -Name $present
      "  removed $($present -join ', ') from $k"
    }
  }
  Restart-Cameras
  'Done.'
}
''
'Now reboot, then in Settings > Accounts > Sign-in options > Facial recognition'
'remove your face and set it up again.'
