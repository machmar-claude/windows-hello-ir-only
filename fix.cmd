@echo off
rem Double-click to make Windows Hello face sign-in use the IR camera only. Asks for admin rights.
set "SCRIPT=%~dp0hello-ir-only.ps1"
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -NoExit -File \"' + $env:SCRIPT + '\"')"
