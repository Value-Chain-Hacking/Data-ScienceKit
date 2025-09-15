# Script: modules/Install-Scoop.ps1
# Purpose: Installs Scoop package manager for Windows

Write-Host "Starting Scoop package manager installation..." -ForegroundColor Yellow

# Function to test if Scoop is installed and working
function Test-ScoopInstallation {
    try {
        $scoopVersion = scoop --version 2>&1
        if ($scoopVersion -and $scoopVersion -notlike "*not recognized*") {
            Write-Host "Found Scoop: v$scoopVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        # Scoop not found or not working
    }
    return $false
}

# Function to refresh PATH for current session
function Update-SessionPath {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
    
    if ($userPath) {
        $env:PATH = "$systemPath;$userPath"
    } else {
        $env:PATH = $systemPath
    }
}

try {
    # Check if Scoop is already installed
    Write-Host "Checking for existing Scoop installation..." -ForegroundColor Cyan
    
    if (Test-ScoopInstallation) {
        Write-Host "Scoop is already installed and working." -ForegroundColor Green
        
        # Show Scoop info
        try {
            $scoopInfo = scoop info scoop 2>$null
            if ($scoopInfo) {
                Write-Host "Scoop installation details:" -ForegroundColor Cyan
                Write-Host "  Location: $env:USERPROFILE\scoop" -ForegroundColor Gray
            }
        } catch {
            # Info command failed, not critical
        }
        
        exit 0  # Already installed
    }
    
    Write-Host "Scoop not found. Proceeding with installation..." -ForegroundColor Yellow
    
    # Check prerequisites
    Write-Host "Checking installation prerequisites..." -ForegroundColor Cyan
    
    # Check PowerShell version (Scoop requires PS 5.0+)
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-Host "ERROR: Scoop requires PowerShell 5.0 or higher. Found: $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Red
        exit 1
    }
    
    # Check execution policy
    $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($executionPolicy -eq "Restricted") {
        Write-Host "Setting execution policy for current user..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "  + Execution policy updated" -ForegroundColor Green
        } catch {
            Write-Host "  - Could not update execution policy: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  Manual fix: Run 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'" -ForegroundColor Yellow
        }
    }
    
    # Install Scoop
    Write-Host "Installing Scoop package manager..." -ForegroundColor Cyan
    Write-Host "This may take a moment..." -ForegroundColor Gray
    
    try {
        # Ensure TLS 1.2 for secure download
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        
        # Use the official Scoop installation method
        Write-Host "Downloading and executing Scoop installer..." -ForegroundColor Gray
        
        # Method 1: Try the modern approach first
        try {
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-Host "Scoop installation script executed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Modern installation method failed, trying alternative..." -ForegroundColor Yellow
            
            # Method 2: Fallback to traditional method
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            Write-Host "Scoop installation script executed successfully (fallback method)." -ForegroundColor Green
        }
        
    } catch {
        Write-Host "ERROR: Failed to download or execute Scoop installer." -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual installation steps:" -ForegroundColor Yellow
        Write-Host "1. Open PowerShell and run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host "2. Run: irm get.scoop.sh | iex" -ForegroundColor Yellow
        Write-Host "3. Or visit: https://scoop.sh for detailed instructions" -ForegroundColor Yellow
        exit 1
    }
    
    # Refresh PATH to pick up Scoop
    Write-Host "Refreshing environment variables..." -ForegroundColor Cyan
    Update-SessionPath
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 2
    
    # Verify installation
    Write-Host "Verifying Scoop installation..." -ForegroundColor Cyan
    
    if (Test-ScoopInstallation) {
        Write-Host "Scoop installation verified successfully!" -ForegroundColor Green
        
        # Show installation details
        try {
            Write-Host "Scoop installation details:" -ForegroundColor Cyan
            $scoopVersion = scoop --version
            Write-Host "  Version: v$scoopVersion" -ForegroundColor Gray
            Write-Host "  Location: $env:USERPROFILE\scoop" -ForegroundColor Gray
            
            # Test basic functionality
            $scoopHelp = scoop help 2>$null
            if ($scoopHelp) {
                Write-Host "  Status: Fully functional" -ForegroundColor Gray
            }
            
        } catch {
            Write-Host "  Could not retrieve detailed information" -ForegroundColor Yellow
        }
        
        # Install useful buckets (optional)
        Write-Host "Setting up essential Scoop buckets..." -ForegroundColor Cyan
        try {
            # Add extras bucket for more applications
            scoop bucket add extras 2>$null
            Write-Host "  + Added 'extras' bucket" -ForegroundColor Green
        } catch {
            Write-Host "  - Could not add extras bucket (not critical)" -ForegroundColor Yellow
        }
        
        exit 0  # Success
        
    } else {
        Write-Host "WARNING: Scoop installation completed but verification failed." -ForegroundColor Yellow
        Write-Host "Scoop may not be immediately available in current session." -ForegroundColor Yellow
        Write-Host "Try opening a new PowerShell window or run: refreshenv" -ForegroundColor Yellow
        
        # Don't fail the installation - it might work in a new session
        exit 0
    }
    
} catch {
    Write-Host "ERROR: An unexpected error occurred during Scoop installation." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Scoop installation is optional. You can:" -ForegroundColor Yellow
    Write-Host "1. Continue with Chocolatey for package management" -ForegroundColor Yellow
    Write-Host "2. Install Scoop manually later from: https://scoop.sh" -ForegroundColor Yellow
    Write-Host "3. Use Windows Package Manager (winget) if available" -ForegroundColor Yellow
    
    # Don't fail the installation for optional package managers
    exit 0
}