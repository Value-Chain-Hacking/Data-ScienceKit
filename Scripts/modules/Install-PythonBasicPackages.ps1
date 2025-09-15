# Script: modules/Install-PythonBasicPackages.ps1
# Purpose: Installs essential Python packages for data science and general development

Write-Host "Installing essential Python packages..." -ForegroundColor Yellow

# Function to test if Python is available
function Test-PythonAvailable {
    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python") {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Function to install packages with error handling
function Install-PythonPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName
    )
    
    try {
        Write-Host "  Installing $DisplayName..." -ForegroundColor Cyan
        python -m pip install $PackageName --quiet --no-warn-script-location
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    + $DisplayName installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    - $DisplayName installation failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "    - $DisplayName installation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

try {
    # Check if Python is available
    if (-not (Test-PythonAvailable)) {
        Write-Host "ERROR: Python is not available. Cannot install packages." -ForegroundColor Red
        Write-Host "Please ensure Python is installed and in PATH." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Python is available. Proceeding with package installation..." -ForegroundColor Green
    
    # Upgrade pip first
    Write-Host "Upgrading pip to latest version..." -ForegroundColor Cyan
    python -m pip install --upgrade pip --quiet
    
    # Define essential packages
    $essentialPackages = @(
        @{ Package = "pandas>=1.5.0"; Display = "pandas (Data manipulation)" },
        @{ Package = "numpy>=1.23.0"; Display = "numpy (Numerical computing)" },
        @{ Package = "matplotlib>=3.6.0"; Display = "matplotlib (Basic plotting)" },
        @{ Package = "requests>=2.28.0"; Display = "requests (HTTP library)" },
        @{ Package = "openpyxl>=3.0.0"; Display = "openpyxl (Excel files)" },
        @{ Package = "python-dotenv>=0.20.0"; Display = "python-dotenv (Environment variables)" },
        @{ Package = "tqdm>=4.64.0"; Display = "tqdm (Progress bars)" },
        @{ Package = "jupyter>=1.0.0"; Display = "jupyter (Interactive notebooks)" },
        @{ Package = "ipykernel>=6.0.0"; Display = "ipykernel (Jupyter kernel)" }
    )
    
    # Track installation results
    $successCount = 0
    $failureCount = 0
    $totalPackages = $essentialPackages.Count
    
    Write-Host "Installing $totalPackages essential packages..." -ForegroundColor Yellow
    Write-Host ""
    
    # Install each package
    foreach ($pkg in $essentialPackages) {
        if (Install-PythonPackage -PackageName $pkg.Package -DisplayName $pkg.Display) {
            $successCount++
        } else {
            $failureCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "PYTHON BASIC PACKAGES INSTALLATION SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    Write-Host "Total packages: $totalPackages" -ForegroundColor Gray
    Write-Host "Successfully installed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })
    
    # Test key packages
    Write-Host ""
    Write-Host "Testing key package imports..." -ForegroundColor Cyan
    
    $testPackages = @("pandas", "numpy", "matplotlib", "requests")
    $importSuccesses = 0
    
    foreach ($testPkg in $testPackages) {
        try {
            $importTest = python -c "import $testPkg; print('$testPkg OK')" 2>$null
            if ($importTest -like "*OK*") {
                Write-Host "  + $testPkg imports successfully" -ForegroundColor Green
                $importSuccesses++
            } else {
                Write-Host "  - $testPkg import failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "  - $testPkg import test error" -ForegroundColor Red
        }
    }
    
    # Final status
    if ($successCount -eq $totalPackages -and $importSuccesses -eq $testPackages.Count) {
        Write-Host ""
        Write-Host "All essential Python packages installed and working!" -ForegroundColor Green
        exit 0
    } elseif ($successCount -gt ($totalPackages * 0.8)) {
        Write-Host ""
        Write-Host "Most essential packages installed successfully." -ForegroundColor Yellow
        Write-Host "Some packages failed but core functionality should work." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host ""
        Write-Host "Multiple package installations failed." -ForegroundColor Red
        Write-Host "Python environment may not be fully functional." -ForegroundColor Red
        
        # Don't fail completely - some packages might still work
        exit 0
    }
    
} catch {
    Write-Host "ERROR: Unexpected error during Python package installation." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try installing packages manually:" -ForegroundColor Yellow
    Write-Host "pip install pandas numpy matplotlib requests openpyxl jupyter" -ForegroundColor Cyan
    exit 1
}