$ErrorActionPreference = "Stop"

$PROXY_IP = "80.190.74.38"
$PROXY_PORT = "3128"
$CERT_URL = "http://${PROXY_IP}/ca.crt"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

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
Write-Host "   Discord Proxy Bypass - Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "ERROR: Run as Administrator!"
    Write-Info "   Right-click PowerShell and select 'Run as Administrator'"
    pause
    exit 1
}

Write-Success "Running as Administrator"
Write-Host ""

# ============================================================
# 1. Download CA certificate
# ============================================================

Write-Info "[1/4] Downloading CA certificate..."

$CertFile = "$env:TEMP\discord-proxy-ca.crt"

try {
    # Tenta com WebClient primeiro (mais confiável, bypassa proxy existente)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.Proxy = $null
    $WebClient.DownloadFile($CERT_URL, $CertFile)
    Write-Success "  Certificate downloaded"
}
catch {
    # Fallback para Invoke-WebRequest
    try {
        Write-Info "  Trying alternative method..."
        Invoke-WebRequest -Uri $CERT_URL -OutFile $CertFile -UseBasicParsing -Proxy $null -ErrorAction Stop
        Write-Success "  Certificate downloaded"
    }
    catch {
        Write-Error "  Failed to download certificate"
        Write-Warning "  Check your internet connection or firewall"
        Write-Info "  URL: $CERT_URL"
        Write-Info "  Manual: Open URL in browser and save as ca.crt"
        pause
        exit 1
    }
}

# ============================================================
# 2. Install certificate to Trusted Root
# ============================================================

Write-Info "[2/4] Installing certificate..."

try {
    Import-Certificate `
        -FilePath $CertFile `
        -CertStoreLocation Cert:\LocalMachine\Root `
        -ErrorAction Stop | Out-Null

    Write-Success "  Certificate installed"
}
catch {
    Write-Error "  Failed to install certificate"
    Write-Warning "  Make sure you are running as Administrator"
    pause
    exit 1
}

# ============================================================
# 3. Configure system proxy
# ============================================================

Write-Info "[3/4] Configuring system proxy..."

$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

try {
    # Enable proxy
    Set-ItemProperty -Path $RegistryPath -Name "ProxyEnable" -Type DWord -Value 1

    # Set address:port
    Set-ItemProperty -Path $RegistryPath -Name "ProxyServer" -Type String -Value "${PROXY_IP}:${PROXY_PORT}"

    # Don't use proxy for local addresses
    Set-ItemProperty -Path $RegistryPath -Name "ProxyOverride" -Type String -Value "<local>"

    # Remove PAC if exists
    Remove-ItemProperty -Path $RegistryPath -Name "AutoConfigURL" -ErrorAction SilentlyContinue

    # Notify Windows about the change
    $NativeMethods = @'
using System;
using System.Runtime.InteropServices;

public static class WinInet
{
    [DllImport("wininet.dll", SetLastError = true)]
    public static extern bool InternetSetOption(
        IntPtr hInternet,
        int dwOption,
        IntPtr lpBuffer,
        int dwBufferLength
    );
}
'@

    if (-not ("WinInet" -as [type])) {
        Add-Type -TypeDefinition $NativeMethods
    }

    [WinInet]::InternetSetOption([IntPtr]::Zero, 39, [IntPtr]::Zero, 0) | Out-Null
    [WinInet]::InternetSetOption([IntPtr]::Zero, 37, [IntPtr]::Zero, 0) | Out-Null

    Write-Success "  Proxy configured"
}
catch {
    Write-Error "  Failed to configure proxy"
    Write-Warning "  $_"
    pause
    exit 1
}

# ============================================================
# 4. Test connection
# ============================================================

Write-Info "[4/4] Testing connection..."

try {
    $TestUrl = "http://example.com"
    $Response = Invoke-WebRequest -Uri $TestUrl -Proxy "http://${PROXY_IP}:${PROXY_PORT}" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop

    if ($Response.StatusCode -eq 200) {
        Write-Success "  Connection working!"
    }
}
catch {
    Write-Warning "  Warning: Could not test connection"
    Write-Warning "  This may be normal if proxy is not active yet"
    Write-Info "  Try opening Discord and see if it works"
}

# ============================================================
# Summary
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "         INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Write-Success "Proxy configured:"
Write-Host "  Server: ${PROXY_IP}:${PROXY_PORT}"
Write-Host ""

Write-Info "Next steps:"
Write-Host "  1. Open Discord (app or web)"
Write-Host "  2. Should work normally!"
Write-Host ""

Write-Warning "To uninstall:"
Write-Host "  Run: .\uninstall-windows.ps1"
Write-Host ""

Write-Info "Issues?"
Write-Host "  Read the README.md or open an issue on GitHub"
Write-Host ""

# Ask if want to open Discord
$OpenDiscord = Read-Host "Open Discord now? (Y/N)"
if ($OpenDiscord -eq "Y" -or $OpenDiscord -eq "y") {
    Start-Process "discord://"
    Write-Success "Discord opened! Wait for loading..."
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
