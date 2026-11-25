@echo off
rem Double-click to undo fix.cmd (restores the backed-up camera settings). Asks for admin rights.
set "SCRIPT=%~dp0hello-ir-only.ps1"
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -File \"' + $env:SCRIPT + '\" -Undo')"
