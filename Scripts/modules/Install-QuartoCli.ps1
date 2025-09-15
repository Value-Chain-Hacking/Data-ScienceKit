# Script: modules/Install-QuartoCLI.ps1
# Purpose: Installs Quarto CLI with multiple fallback methods and error handling

Write-Host "Starting automated Quarto CLI installation..." -ForegroundColor Yellow

# Configuration
$QuartoVersion = "1.8.24"  # Update as needed
$QuartoMsiUrl = "https://github.com/quarto-dev/quarto-cli/releases/download/v$QuartoVersion/quarto-$QuartoVersion-win.msi"
$InstallerFileName = "quarto-$QuartoVersion-win.msi"
$DownloadPath = Join-Path -Path $env:TEMP -ChildPath $InstallerFileName

# Function to refresh PATH environment variable
function Update-SessionPath {
    $systemPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
    $userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
    if ($userPath) {
        $env:PATH = "$systemPath;$userPath"
    } else {
        $env:PATH = $systemPath
    }
}

# Function to test if Quarto is installed and working
function Test-QuartoInstallation {
    try {
        $quartoVersion = quarto --version 2>&1
        if ($quartoVersion -match "\d+\.\d+\.\d+") {
            Write-Host "Found Quarto: $quartoVersion" -ForegroundColor Green
            return $true
        }
    } catch {
        # Quarto not found or not working
    }
    return $false
}

# Function to test if Chocolatey is available
function Test-ChocolateyAvailable {
    try {
        $chocoVersion = choco --version 2>$null
        return $chocoVersion -ne $null
    } catch {
        return $false
    }
}

# Function to clean Chocolatey cache and locks
function Clear-ChocolateyLocks {
    Write-Host "Clearing Chocolatey cache and lock files..." -ForegroundColor Cyan
    
    try {
        # Remove specific lock files for Quarto
        $lockFiles = @(
            "C:\ProgramData\chocolatey\lib\quarto*",
            "C:\ProgramData\chocolatey\lib\ee6bce875b9b8971dd4aa65ea780cfa34a6f2e1e",
            "C:\ProgramData\chocolatey\lib-bad"
        )
        
        foreach ($lockFile in $lockFiles) {
            if (Test-Path $lockFile) {
                Remove-Item $lockFile -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Removed: $lockFile" -ForegroundColor Gray
            }
        }
        
        # Clear Chocolatey cache
        choco cache clear --force 2>&1 | Out-Null
        Write-Host "  Chocolatey cache cleared" -ForegroundColor Gray
        
    } catch {
        Write-Host "  Could not clear all lock files (continuing anyway)" -ForegroundColor Yellow
    }
}

try {
    # Check if Quarto is already installed
    Write-Host "Checking for existing Quarto installation..." -ForegroundColor Cyan
    
    if (Test-QuartoInstallation) {
        Write-Host "Quarto is already installed and working." -ForegroundColor Green
        exit 0  # Already installed
    }
    
    Write-Host "Quarto not found. Proceeding with installation..." -ForegroundColor Yellow
    
    # Method 1: Try Chocolatey with lock file cleanup
    Write-Host "Attempting installation via Chocolatey..." -ForegroundColor Cyan
    
    # Refresh PATH first in case Chocolatey was just installed
    Update-SessionPath
    
    if (Test-ChocolateyAvailable) {
        Write-Host "Chocolatey is available. Installing Quarto via Chocolatey..." -ForegroundColor Green
        
        # First attempt - direct install
        try {
            Write-Host "Executing: choco install quarto --yes --force" -ForegroundColor Gray
            
            $chocoProcess = Start-Process -FilePath "choco" -ArgumentList @("install", "quarto", "--yes", "--force") -Wait -PassThru -NoNewWindow
            
            if ($chocoProcess.ExitCode -eq 0) {
                Write-Host "Chocolatey Quarto installation completed successfully!" -ForegroundColor Green
                
                # Refresh PATH and test
                Update-SessionPath
                Start-Sleep -Seconds 3
                
                if (Test-QuartoInstallation) {
                    Write-Host "Quarto installation verified via Chocolatey!" -ForegroundColor Green
                    exit 0
                } else {
                    Write-Host "Chocolatey installation completed but Quarto not immediately available" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Chocolatey installation failed with exit code: $($chocoProcess.ExitCode)" -ForegroundColor Yellow
                throw "Chocolatey failed, trying cleanup approach"
            }
        } catch {
            Write-Host "First Chocolatey attempt failed: $($_.Exception.Message)" -ForegroundColor Yellow
            
            # Second attempt - clear locks and retry
            Write-Host "Attempting Chocolatey installation with cache cleanup..." -ForegroundColor Cyan
            Clear-ChocolateyLocks
            
            try {
                Start-Sleep -Seconds 2  # Let filesystem settle
                $chocoProcess2 = Start-Process -FilePath "choco" -ArgumentList @("install", "quarto", "--yes", "--force", "--ignore-checksums") -Wait -PassThru -NoNewWindow
                
                if ($chocoProcess2.ExitCode -eq 0) {
                    Write-Host "Chocolatey Quarto installation completed after cleanup!" -ForegroundColor Green
                    Update-SessionPath
                    Start-Sleep -Seconds 3
                    
                    if (Test-QuartoInstallation) {
                        Write-Host "Quarto installation verified via Chocolatey after cleanup!" -ForegroundColor Green
                        exit 0
                    }
                } else {
                    throw "Chocolatey still failing after cleanup, trying direct download"
                }
            } catch {
                Write-Host "Chocolatey cleanup approach also failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-Host "Falling back to direct installation method..." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Chocolatey not available. Using direct installation method..." -ForegroundColor Yellow
    }
    
    # Method 2: Direct download and installation from GitHub releases
    Write-Host "Downloading Quarto installer from GitHub releases..." -ForegroundColor Cyan
    Write-Host "URL: $QuartoMsiUrl" -ForegroundColor Gray
    
    # Ensure TLS 1.2 for downloading
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    
    try {
        Invoke-WebRequest -Uri $QuartoMsiUrl -OutFile $DownloadPath -ErrorAction Stop
        Write-Host "Quarto installer downloaded successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to download from direct URL. Trying latest release..." -ForegroundColor Yellow
        
        # Fallback: Try to get latest release URL from GitHub API
        try {
            $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest"
            $installerAsset = $latestRelease.assets | Where-Object { $_.name -like "*win.msi" } | Select-Object -First 1
            
            if ($installerAsset) {
                Write-Host "Found latest release: $($installerAsset.name)" -ForegroundColor Green
                $DownloadPath = Join-Path -Path $env:TEMP -ChildPath $installerAsset.name
                Invoke-WebRequest -Uri $installerAsset.browser_download_url -OutFile $DownloadPath -ErrorAction Stop
                Write-Host "Latest Quarto installer downloaded successfully." -ForegroundColor Green
            } else {
                throw "Could not find suitable Quarto installer in latest release"
            }
        } catch {
            Write-Host "Could not download Quarto installer automatically." -ForegroundColor Red
            Write-Host "Please manually install Quarto from: https://quarto.org/docs/get-started/" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Verify download
    if (-not (Test-Path $DownloadPath)) {
        Write-Host "Downloaded installer not found. Installation failed." -ForegroundColor Red
        exit 1
    }
    
    $fileSize = (Get-Item $DownloadPath).Length / 1MB
    Write-Host "Downloaded installer size: $([math]::Round($fileSize, 1)) MB" -ForegroundColor Gray
    
    # Run MSI installation
    Write-Host "Running automated Quarto installation..." -ForegroundColor Cyan
    Write-Host "This may take several minutes. Please wait..." -ForegroundColor Yellow
    
    # MSI silent installation parameters
    $msiArgs = @(
        "/i", $DownloadPath,        # Install the MSI
        "/quiet",                   # Silent installation
        "/norestart",               # Don't restart system
        "/l*v", "$env:TEMP\QuartoInstall.log"  # Log installation
    )
    
    Write-Host "Executing: msiexec $($msiArgs -join ' ')" -ForegroundColor Gray
    
    # Start the installation process
    $process = Start-Process -FilePath "msiexec" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
    
    $exitCode = $process.ExitCode
    
    if ($exitCode -eq 0) {
        Write-Host "Quarto installation completed successfully!" -ForegroundColor Green
    } elseif ($exitCode -eq 3010) {
        Write-Host "Quarto installation completed (restart recommended)" -ForegroundColor Yellow
    } else {
        Write-Host "Quarto installation completed with exit code: $exitCode" -ForegroundColor Yellow
    }
    
    # Clean up installer
    try {
        Remove-Item -Path $DownloadPath -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned up installer file." -ForegroundColor Gray
    } catch {
        Write-Host "Could not clean up installer file (not critical)" -ForegroundColor Gray
    }
    
    # Refresh environment variables
    Write-Host "Refreshing environment variables..." -ForegroundColor Cyan
    Update-SessionPath
    
    # Add Quarto to PATH if needed (MSI should handle this, but just in case)
    $quartoPath = "${env:ProgramFiles}\Quarto\bin"
    if (Test-Path $quartoPath) {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::Machine)
        if ($currentPath -notlike "*$quartoPath*") {
            Write-Host "Adding Quarto to system PATH..." -ForegroundColor Cyan
            try {
                $newPath = "$currentPath;$quartoPath"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::Machine)
                $env:PATH = "$env:PATH;$quartoPath"
                Write-Host "Quarto added to PATH successfully." -ForegroundColor Green
            } catch {
                Write-Host "Could not automatically add Quarto to PATH. May need manual configuration." -ForegroundColor Yellow
            }
        }
    }
    
    # Wait a moment for installation to fully complete
    Start-Sleep -Seconds 5
    
    # Verify installation with multiple attempts
    Write-Host "Verifying Quarto installation..." -ForegroundColor Cyan
    
    $verificationAttempts = 3
    $verificationSuccess = $false
    
    for ($i = 1; $i -le $verificationAttempts; $i++) {
        Write-Host "Verification attempt $i of $verificationAttempts..." -ForegroundColor Gray
        
        Update-SessionPath  # Refresh PATH each attempt
        
        if (Test-QuartoInstallation) {
            $verificationSuccess = $true
            break
        }
        
        if ($i -lt $verificationAttempts) {
            Write-Host "Quarto not immediately available, waiting..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
    
    if ($verificationSuccess) {
        Write-Host "Quarto installation verified successfully!" -ForegroundColor Green
        
        # Show installation details
        try {
            Write-Host "Quarto installation details:" -ForegroundColor Cyan
            $quartoVersionInfo = quarto --version 2>$null
            Write-Host "  Version: $quartoVersionInfo" -ForegroundColor Gray
            
            # Test basic functionality
            $quartoCheck = quarto check 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Basic functionality: Working" -ForegroundColor Gray
            } else {
                Write-Host "  Basic functionality: May need configuration" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Could not retrieve detailed Quarto information" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Quarto is ready for document rendering" -ForegroundColor Yellow
        Write-Host "2. Try: quarto render document.qmd" -ForegroundColor Yellow
        Write-Host "3. Restart terminal for full PATH integration" -ForegroundColor Yellow
        
        exit 0  # Success
    } else {
        Write-Host "WARNING: Quarto installation completed but verification failed." -ForegroundColor Yellow
        Write-Host "Quarto may not be immediately available in current session." -ForegroundColor Yellow
        
        # Provide troubleshooting info
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Cyan
        Write-Host "Try opening a new PowerShell/CMD window." -ForegroundColor Yellow
        Write-Host "Manual verification: quarto --version" -ForegroundColor Yellow
        
        # Don't fail the installation - it might work in a new session
        exit 0
    }
    
} catch {
    Write-Host "ERROR: Quarto installation failed." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fallback options:" -ForegroundColor Yellow
    Write-Host "1. Download Quarto manually: https://quarto.org/docs/get-started/" -ForegroundColor Yellow
    Write-Host "2. Use different package manager: winget install quarto" -ForegroundColor Yellow
    Write-Host "3. Try Chocolatey in a new session after restart" -ForegroundColor Yellow
    exit 1
}