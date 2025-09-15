# Script: modules/Install-RBasicPackages.ps1
# Purpose: Installs essential R packages for data science and statistical analysis

Write-Host "Installing essential R packages..." -ForegroundColor Yellow

# Function to test if R is available
function Test-RAvailable {
    try {
        $rVersion = R --version 2>&1
        if ($rVersion -match "R version") {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Function to install R packages with error handling
function Install-RPackage {
    param(
        [string]$PackageName,
        [string]$DisplayName = $PackageName
    )
    
    try {
        Write-Host "  Installing $DisplayName..." -ForegroundColor Cyan
        
        # Create R command to install package
        $rCommand = "if (!require('$PackageName', quietly = TRUE)) { install.packages('$PackageName', repos = 'https://cran.rstudio.com/', dependencies = TRUE, quiet = TRUE) }"
        
        # Execute R command
        $result = R --slave -e $rCommand 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    + $DisplayName installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    - $DisplayName installation failed" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "    - $DisplayName installation error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

try {
    # Check if R is available
    if (-not (Test-RAvailable)) {
        Write-Host "ERROR: R is not available. Cannot install packages." -ForegroundColor Red
        Write-Host "Please ensure R is installed and in PATH." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "R is available. Proceeding with package installation..." -ForegroundColor Green
    
    # Get R version info
    try {
        $rVersionInfo = R --slave -e "cat(R.version.string)" 2>$null
        Write-Host "R Version: $rVersionInfo" -ForegroundColor Gray
    } catch {
        Write-Host "R Version: Could not determine" -ForegroundColor Gray
    }
    
    # Define essential R packages
    $essentialPackages = @(
        @{ Package = "tidyverse"; Display = "tidyverse (Data manipulation & visualization)" },
        @{ Package = "ggplot2"; Display = "ggplot2 (Graphics)" },
        @{ Package = "dplyr"; Display = "dplyr (Data manipulation)" },
        @{ Package = "readr"; Display = "readr (Data import)" },
        @{ Package = "knitr"; Display = "knitr (Dynamic reports)" },
        @{ Package = "rmarkdown"; Display = "rmarkdown (R Markdown)" },
        @{ Package = "readxl"; Display = "readxl (Excel files)" },
        @{ Package = "openxlsx"; Display = "openxlsx (Excel writing)" },
        @{ Package = "DBI"; Display = "DBI (Database interface)" },
        @{ Package = "RSQLite"; Display = "RSQLite (SQLite driver)" },
        @{ Package = "here"; Display = "here (File paths)" },
        @{ Package = "lubridate"; Display = "lubridate (Date/time)" }
    )
    
    # Track installation results
    $successCount = 0
    $failureCount = 0
    $totalPackages = $essentialPackages.Count
    
    Write-Host "Installing $totalPackages essential R packages..." -ForegroundColor Yellow
    Write-Host "This may take several minutes as R compiles packages..." -ForegroundColor Gray
    Write-Host ""
    
    # Set CRAN mirror and install packages
    Write-Host "Setting CRAN mirror..." -ForegroundColor Cyan
    R --slave -e "options(repos = c(CRAN = 'https://cran.rstudio.com/'))" 2>$null
    
    # Install each package
    foreach ($pkg in $essentialPackages) {
        if (Install-RPackage -PackageName $pkg.Package -DisplayName $pkg.Display) {
            $successCount++
        } else {
            $failureCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "R BASIC PACKAGES INSTALLATION SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
    
    Write-Host "Total packages: $totalPackages" -ForegroundColor Gray
    Write-Host "Successfully installed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })
    
    # Test key packages
    Write-Host ""
    Write-Host "Testing key package loading..." -ForegroundColor Cyan
    
    $testPackages = @("ggplot2", "dplyr", "readr", "knitr")
    $loadSuccesses = 0
    
    foreach ($testPkg in $testPackages) {
        try {
            $loadTest = R --slave -e "cat(ifelse(require('$testPkg', quietly=TRUE), '$testPkg OK', '$testPkg FAILED'))" 2>$null
            if ($loadTest -like "*OK*") {
                Write-Host "  + $testPkg loads successfully" -ForegroundColor Green
                $loadSuccesses++
            } else {
                Write-Host "  - $testPkg failed to load" -ForegroundColor Red
            }
        } catch {
            Write-Host "  - $testPkg load test error" -ForegroundColor Red
        }
    }
    
    # Check if tidyverse meta-package worked
    Write-Host ""
    Write-Host "Checking tidyverse meta-package..." -ForegroundColor Cyan
    try {
        $tidyverseTest = R --slave -e "cat(ifelse(require('tidyverse', quietly=TRUE), 'tidyverse OK', 'tidyverse FAILED'))" 2>$null
        if ($tidyverseTest -like "*OK*") {
            Write-Host "  + tidyverse meta-package working" -ForegroundColor Green
        } else {
            Write-Host "  - tidyverse meta-package not working" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  - tidyverse test error" -ForegroundColor Red
    }
    
    # Final status
    if ($successCount -eq $totalPackages -and $loadSuccesses -eq $testPackages.Count) {
        Write-Host ""
        Write-Host "All essential R packages installed and working!" -ForegroundColor Green
        exit 0
    } elseif ($successCount -gt ($totalPackages * 0.7)) {
        Write-Host ""
        Write-Host "Most essential R packages installed successfully." -ForegroundColor Yellow
        Write-Host "Some packages failed but core R functionality should work." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host ""
        Write-Host "Multiple R package installations failed." -ForegroundColor Red
        Write-Host "R environment may not be fully functional." -ForegroundColor Red
        
        Write-Host ""
        Write-Host "Common solutions:" -ForegroundColor Yellow
        Write-Host "1. Install Rtools if on Windows" -ForegroundColor Yellow
        Write-Host "2. Update R to latest version" -ForegroundColor Yellow
        Write-Host "3. Try installing packages manually in R console" -ForegroundColor Yellow
        
        # Don't fail completely - some packages might still work
        exit 0
    }
    
} catch {
    Write-Host "ERROR: Unexpected error during R package installation." -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try installing packages manually in R:" -ForegroundColor Yellow
    Write-Host 'install.packages(c("tidyverse", "knitr", "rmarkdown", "readxl"))' -ForegroundColor Cyan
    exit 1
}