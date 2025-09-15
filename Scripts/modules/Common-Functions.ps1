# Script: modules/Common-Functions.ps1
# Purpose: Shared utility functions for all installer modules

# Function to refresh PATH environment variable
function Update-SessionPath {
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
    $userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    
    if ($userPath) {
        $env:PATH = "$systemPath;$userPath"
    } else {
        $env:PATH = $systemPath
    }
    Write-Verbose "PATH updated with latest system and user paths"
}

# Function to test if a command is available
function Test-CommandAvailable {
    param([string]$CommandName)
    try {
        $null = Get-Command $CommandName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to wait for installation to settle
function Wait-ForInstallation {
    param([int]$Seconds = 3)
    Write-Host "Waiting for installation to complete..." -ForegroundColor Gray
    Start-Sleep -Seconds $Seconds
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue
        return $response
    } catch {
        return $false
    }
}

# Function for consistent error handling
function Write-ModuleError {
    param(
        [string]$Message,
        [string]$Suggestion = ""
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red
    if ($Suggestion) {
        Write-Host "SUGGESTION: $Suggestion" -ForegroundColor Yellow
    }
}

# Function for consistent success messages
function Write-ModuleSuccess {
    param([string]$Message)
    Write-Host "SUCCESS: $Message" -ForegroundColor Green
}

# Export functions for module use
Export-ModuleMember -Function Update-SessionPath, Test-CommandAvailable, Wait-ForInstallation, Test-InternetConnection, Write-ModuleError, Write-ModuleSuccess