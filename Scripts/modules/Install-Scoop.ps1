# modules/Install-Scoop.ps1
# Purpose: Install Scoop package manager (module-safe: no 'exit', sets $LASTEXITCODE)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$LASTEXITCODE = 1

function Log([string]$msg,[string]$level='INFO'){
  if (Get-Command Write-Log -ErrorAction SilentlyContinue) { Write-Log -Message $msg -Level $level }
  else {
    $c = @{INFO='Gray';SUCCESS='Green';WARNING='Yellow';ERROR='Red'}[$level]; if(-not $c){$c='Gray'}
    Write-Host "[$level] $msg" -ForegroundColor $c
  }
}

function Test-IsAdmin {
  $id=[Security.Principal.WindowsIdentity]::GetCurrent()
  ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Update-SessionPath {
  $user  = [Environment]::GetEnvironmentVariable("PATH",'User')
  $mach  = [Environment]::GetEnvironmentVariable("PATH",'Machine')
  $env:PATH = @($mach,$user) -join ';'
}

function Test-Scoop {
  try {
    $v = (& scoop --version) 2>$null
    return ($LASTEXITCODE -eq 0 -and $v -ne $null -and $v -notlike '*not recognized*')
  } catch { return $false }
}

try {
  Log "Starting Scoop package manager installation..." 'INFO'
  if (Test-Scoop) {
    Log ("Scoop already present: {0}" -f ((scoop --version) -split '\r?\n')[0]) 'SUCCESS'
    $LASTEXITCODE = 0
    return
  }

  # Ensure TLS 1.2
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

  $isAdmin = Test-IsAdmin
  if ($isAdmin) {
    Log "Elevated shell detected → using advanced installer with -RunAsAdmin." 'WARNING'
    $installer = Join-Path $env:TEMP 'install-scoop.ps1'
    Invoke-RestMethod -Uri https://get.scoop.sh -OutFile $installer

    # Process-scoped policy bypass (does not persist)
    $orig = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    try {
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
      & $installer -RunAsAdmin
    } finally {
      if ($orig) { Set-ExecutionPolicy -Scope Process -ExecutionPolicy $orig -Force -ErrorAction SilentlyContinue }
    }
  } else {
    Log "Non-admin shell → using standard per-user installer." 'INFO'
    # Process-scoped policy bypass (does not persist)
    $orig = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    try {
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
      Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    } finally {
      if ($orig) { Set-ExecutionPolicy -Scope Process -ExecutionPolicy $orig -Force -ErrorAction SilentlyContinue }
    }
  }

  Update-SessionPath
  Start-Sleep -Seconds 2

  if (Test-Scoop) {
    Log "Scoop installation verified." 'SUCCESS'
    try {
      scoop bucket add extras 2>$null | Out-Null
      Log "Added 'extras' bucket." 'INFO'
    } catch { Log "Could not add 'extras' bucket (non-critical)." 'WARNING' }
    $LASTEXITCODE = 0
    return
  } else {
    Log "Scoop installer ran, but verification failed. Try a new PowerShell session." 'WARNING'
    # still non-fatal if your pipeline treats Scoop as optional
    $LASTEXITCODE = 0
    return
  }

} catch {
  Log "Scoop install error: $($_.Exception.Message)" 'ERROR'
  # Keep non-fatal to not block the rest of your toolchain; set to 1 if you want hard-fail.
  $LASTEXITCODE = 0
  return
}
