# SNAPSTUDY — run app without stuck Flutter lock / ADB issues.
$ErrorActionPreference = "Continue"

Get-Process dart -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Pub\Cache\lockfile" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\src\flutter\bin\cache\lockfile" -Force -ErrorAction SilentlyContinue

$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$env:ANDROID_HOME\platform-tools;$env:Path"

Set-Location $PSScriptRoot\..

Write-Host "Stopping Gradle daemons..."
Push-Location android
& .\gradlew.bat --stop 2>$null
Pop-Location

$device = & "$env:ANDROID_HOME\platform-tools\adb.exe" devices 2>$null |
  Select-String "device$" |
  ForEach-Object { ($_ -split "\s+")[0] } |
  Select-Object -First 1

if ($device) {
  Write-Host "Running on $device"
  flutter run -d $device
} else {
  Write-Host "No device — flutter run (pick target)"
  flutter run
}
