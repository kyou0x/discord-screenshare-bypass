$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "#     __                                   ____            " -ForegroundColor Cyan
Write-Host "#    [  |  _                             .'    '.          " -ForegroundColor Cyan
Write-Host "#     | | / ]   _   __   .--.   __   _  |  .--.  | _   __  " -ForegroundColor Cyan
Write-Host "#     | '' <   [ \ [  ]/ .'``\ \[  | | | | |    | |[ \ [  ] " -ForegroundColor Cyan
Write-Host "#     | |``\ \   \ '/ / | \__. | | \_/ |,|  ``--'  | > '  <  " -ForegroundColor Cyan
Write-Host "#    [__|  \_][\_:  /   '.__.'  '.__.'_/ '.____.' [__]``\_] " -ForegroundColor Cyan
Write-Host "#              \__.'                                        " -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Discord Proxy Bypass - Uninstaller" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/2] Disabling proxy..." -ForegroundColor Cyan

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

Set-ItemProperty -Path $RegistryPath -Name "ProxyEnable" -Type DWord -Value 0
Remove-ItemProperty -Path $RegistryPath -Name "ProxyServer" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $RegistryPath -Name "ProxyOverride" -ErrorAction SilentlyContinue

$NativeMethods = @'
using System;
using System.Runtime.InteropServices;
public static class WinInet {
    [DllImport("wininet.dll")]
    public static extern bool InternetSetOption(IntPtr h, int o, IntPtr b, int l);
}
'@
if (-not ("WinInet" -as [type])) { Add-Type -TypeDefinition $NativeMethods }
[WinInet]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
[WinInet]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

Write-Host "  Proxy disabled" -ForegroundColor Green

Write-Host "[2/2] Remove CA certificate?" -ForegroundColor Cyan
$RemoveCert = Read-Host "Remove certificate? (Y/N)"

if ($RemoveCert -eq "Y" -or $RemoveCert -eq "y") {
    try {
        Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*mitmproxy*" } | Remove-Item -ErrorAction SilentlyContinue
        Write-Host "  Certificate removed" -ForegroundColor Green
    }
    catch {
        Write-Host "  Warning: Error removing certificate (may need admin permissions)" -ForegroundColor Yellow
        Write-Host "  Remove manually: Win+R -> certmgr.msc -> Trusted Root -> mitmproxy" -ForegroundColor Cyan
    }
}
else {
    Write-Host "  Certificate kept" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Uninstallation complete!" -ForegroundColor Green
Write-Host ""
pause
