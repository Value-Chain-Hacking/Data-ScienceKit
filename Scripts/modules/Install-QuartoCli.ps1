# modules/Install-QuartoCLI.ps1
# Install Quarto CLI (module-safe: no 'exit', sets $LASTEXITCODE, uses Write-Log if available)

$ErrorActionPreference = 'Stop'
$LASTEXITCODE = 1
$moduleLog = $null

# --- Logger shim (use Main-Installer Write-Log if available) -----------------
function _log {
    param([string]$Message,[string]$Level = "INFO")
    if (Get-Command -Name Write-Log -ErrorAction SilentlyContinue) {
        Write-Log -Message $Message -Level $Level
    } else {
        $fc = switch ($Level) { "SUCCESS" { "Green" } "WARNING" { "Yellow" } "ERROR" { "Red" } default { "Gray" } }
        Write-Host "[$Level] $Message" -ForegroundColor $fc
    }
}

# --- Small helpers -----------------------------------------------------------
function Update-SessionPath {
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", 'Machine')
    $userPath   = [Environment]::GetEnvironmentVariable("PATH", 'User')
    $candidates = @($systemPath, $userPath) -join ';'
    $common = @(
        "$env:ProgramFiles\Quarto\bin",
        "$env:LOCALAPPDATA\Programs\Quarto\bin",
        "$env:USERPROFILE\scoop\apps\quarto\current\bin",
        "C:\ProgramData\chocolatey\lib\quarto\tools\quarto\bin"
    ) | Where-Object { Test-Path $_ }
    $env:PATH = @($candidates; $common) -join ';'
}

function Test-QuartoWorking {
    try {
        Update-SessionPath
        $v = (& quarto --version) 2>$null
        if ($LASTEXITCODE -eq 0 -and $v -match '\d+\.\d+(\.\d+)?') {
            _log "Found working Quarto: $v" "SUCCESS"
            return ,@($true, $v)
        }
    } catch {}
    return ,@($false, $null)
}

function With-PolicyBypass([scriptblock]$Script) {
    $orig = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    try {
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
        & $Script
    } finally {
        if ($orig) { Set-ExecutionPolicy -Scope Process -ExecutionPolicy $orig -Force -ErrorAction SilentlyContinue }
    }
}

function Start-ModuleTranscript {
    try {
        $dir = Join-Path $env:TEMP "quarto-install"
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        $script:moduleLog = Join-Path $dir ("module-quarto-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
        Start-Transcript -Path $script:moduleLog -Force | Out-Null
    } catch {}
}

function Stop-ModuleTranscript { try { Stop-Transcript | Out-Null } catch {} }

# --- Install methods ---------------------------------------------------------
function Install-QuartoViaScoop {
    _log "Method 1: Scoop (GitHub Actions pattern)..." "INFO"
    $ok = $false; $method = $null
    With-PolicyBypass {
        if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
            _log "Installing Scoop..." "INFO"
            Invoke-RestMethod -UseBasicParsing get.scoop.sh | Invoke-Expression
            Update-SessionPath
            Start-Sleep 2
        }
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop bucket add main 2>$null | Out-Null
            scoop update | Out-Null
            _log "Installing Quarto via Scoop..." "INFO"
            scoop install quarto | Out-Null
            $ok,$ver = Test-QuartoWorking
            if ($ok) { $method = "Scoop"; return ,@($ok,$method,$ver) }
        }
    }
    return ,@($false,$null,$null)
}

function Repair-ChocolateyQuarto {
    _log "Fixing known Chocolatey Quarto issues..." "INFO"
    try {
        Get-Process | Where-Object {$_.ProcessName -like "*choco*"} | Stop-Process -Force -ErrorAction SilentlyContinue
        $paths = @(
            "C:\ProgramData\chocolatey\lib\ee6bce875b9b8971dd4aa65ea780cfa34a6f2e1e",
            "C:\ProgramData\chocolatey\lib\quarto*",
            "C:\ProgramData\chocolatey\lib-bad"
        )
        foreach ($p in $paths) { Get-ChildItem $p -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
        choco cache clear --force 2>&1 | Out-Null
        _log "Chocolatey cache cleaned" "INFO"
    } catch {}
}

function Install-QuartoViaWinget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return ,@($false,$null,$null) }
    _log "Method 2: Winget..." "INFO"
    try {
        winget source update 2>$null | Out-Null
        winget install Posit.Quarto --silent --accept-package-agreements --accept-source-agreements
        $ok,$ver = Test-QuartoWorking
        if ($ok) { return ,@($true,"Winget",$ver) }
    } catch { _log "Winget installation failed: $($_.Exception.Message)" "WARNING" }
    return ,@($false,$null,$null)
}

function Install-QuartoViaChocolatey {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { return ,@($false,$null,$null) }
    _log "Method 3: Chocolatey..." "INFO"
    Repair-ChocolateyQuarto
    try {
        choco install quarto --yes --force --no-progress
        $ok,$ver = Test-QuartoWorking
        if ($ok) { return ,@($true,"Chocolatey",$ver) }
    } catch { _log "Chocolatey installation failed: $($_.Exception.Message)" "WARNING" }
    return ,@($false,$null,$null)
}

function Install-QuartoViaMSI {
    _log "Method 4: Official MSI (silent)..." "INFO"
    # x64 vs ARM64
    $arch = if ([Environment]::Is64BitOperatingSystem) {
        if ((Get-CimInstance Win32_Processor).Name -match 'ARM') {'arm64'} else {'x64'}
    } else {'x86'}
    $base = "https://quarto.org/download/latest"
    $msi  = if ($arch -eq 'arm64') { "$base/quarto-win-arm64.msi" } else { "$base/quarto-win.msi" }
    $dir  = Join-Path $env:TEMP "quarto-install"
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $path = Join-Path $dir ("quarto-latest-{0}.msi" -f $arch)
    try {
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $msi -Destination $path -RetryInterval 2 -ErrorAction Stop
        } else {
            Invoke-WebRequest -Uri $msi -OutFile $path -UseBasicParsing -ErrorAction Stop
        }
        $args = "/i `"$path`" /qn /norestart ALLUSERS=1"
        $p = Start-Process msiexec.exe -ArgumentList $args -Wait -PassThru
        if ($p.ExitCode -eq 0) {
            $ok,$ver = Test-QuartoWorking
            if ($ok) { return ,@($true,"MSI",$ver) }
            _log "MSI exit code 0 but Quarto not found on PATH yet (PATH refresh may be pending)" "WARNING"
        } else {
            _log "MSI install returned exit code $($p.ExitCode)" "WARNING"
        }
    } catch { _log "MSI installation failed: $($_.Exception.Message)" "WARNING" }
    return ,@($false,$null,$null)
}

# --- Main (module-safe) ------------------------------------------------------
Start-ModuleTranscript
try {
    _log "Checking for existing Quarto..." "INFO"
    $ok,$ver = Test-QuartoWorking
    if ($ok -and -not $Global:ForceReinstallFlag) {
        _log "Quarto already installed ($ver). Skipping (use -ForceReinstall to override)." "SUCCESS"
        $Global:QuartoInstall = [pscustomobject]@{ Success=$true; Method="Existing"; Version=$ver; Log=$moduleLog }
        $LASTEXITCODE = 0
        return
    }

    if ($Global:ForceReinstallFlag) {
        _log "ForceReinstall requested — proceeding to reinstall Quarto." "WARNING"
    }

    foreach ($fn in @('Install-QuartoViaScoop','Install-QuartoViaWinget','Install-QuartoViaChocolatey','Install-QuartoViaMSI')) {
        try {
            $res = & $fn
            $success,$method,$version = $res
            if ($success) {
                _log "Quarto installed successfully via $method ($version)" "SUCCESS"
                $Global:QuartoInstall = [pscustomobject]@{ Success=$true; Method=$method; Version=$version; Log=$moduleLog }
                $LASTEXITCODE = 0
                return
            } else {
                _log "$fn did not succeed; trying next method..." "INFO"
            }
        } catch {
            _log "$fn threw: $($_.Exception.Message)" "WARNING"
        }
    }

    _log "All automated methods failed. Manual fallback: https://quarto.org/docs/get-started/" "ERROR"
    $Global:QuartoInstall = [pscustomobject]@{ Success=$false; Method=$null; Version=$null; Log=$moduleLog }
    $LASTEXITCODE = 1
    return

} catch {
    _log "Unexpected error: $($_.Exception.Message)" "ERROR"
    $Global:QuartoInstall = [pscustomobject]@{ Success=$false; Method="Exception"; Version=$null; Log=$moduleLog }
    $LASTEXITCODE = 1
    return
} finally {
    Stop-ModuleTranscript
    if ($moduleLog) { _log "Module log: $moduleLog" "INFO" }
}
