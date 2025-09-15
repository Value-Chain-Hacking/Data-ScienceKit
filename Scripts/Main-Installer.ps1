# Main-Installer.ps1 - Part 1 (Revised for Multi-Installer Strategy)
# Orchestrates the installation of a comprehensive Data Science & Research Pipeline Environment.
# REQUIRES: Run this script in PowerShell as Administrator.

# --- Initial Setup & Welcome ---
Clear-Host
$Art = @"
===============================================================================
        __                                                                     
       /  \                                                                    
      |----|       L E C T O R A A T                                           
      |----|                                                                    
       \__/        S U P P L Y   C H A I N   F I N A N C E                     
        ||                                                                     
       /  \                                                                    
      |----|       Data Science & Research Pipeline Environment Setup          
      |----|                                                                    
       \__/                                                                     
===============================================================================
"@
Write-Host $Art -ForegroundColor Cyan
Write-Host ("-" * 79)
Write-Host "Welcome to the Comprehensive Data Science & Research Pipeline Environment Setup!" -ForegroundColor Yellow
Write-Host "This script will guide you through installing necessary tools and configuring your system."
Write-Host "It is CRITICAL to run this script with Administrator Privileges."
Write-Host "This installer will attempt to use Chocolatey, Scoop, and Winget for installations."
Write-Host ("-" * 79)
Write-Host ""

# --- Configuration & Global Variables ---
$Global:MainInstallerBaseDir = $PSScriptRoot 
if (-not $Global:MainInstallerBaseDir) {
    $Global:MainInstallerBaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if (-not $Global:MainInstallerBaseDir) { 
        $Global:MainInstallerBaseDir = Get-Location
        Write-Warning "Could not reliably determine script's own directory. Using current location: $($Global:MainInstallerBaseDir). Ensure 'modules' folder is a direct sub-directory here."
    }
}
$Global:ModulesDir = Join-Path -Path $Global:MainInstallerBaseDir -ChildPath "modules"
$Global:RequirementsDir = Join-Path -Path $Global:MainInstallerBaseDir -ChildPath "requirements" 

$Global:InstallationLog = [System.Collections.Generic.List[string]]::new()
$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Main Installer Script Started.")
$Global:InstallationLog.Add("Installer Base Directory: $($Global:MainInstallerBaseDir)")
$Global:InstallationLog.Add("Modules Directory: $($Global:ModulesDir)")
$Global:InstallationLog.Add("Requirements Directory: $($Global:RequirementsDir)")

$Global:OverallInstallationSuccess = $true 
$Global:CriticalFailureEncountered = $false 
$Global:SelectedProfile = "" 
$Global:ProfileSelectionMade = $false 

# --- User Profile Selection ---
if (-not $Global:ProfileSelectionMade) {
    Write-Host "`n--- Installation Profile Selection ---" -ForegroundColor Magenta
    Write-Host "Please select an installation profile:"
    Write-Host "[1] Minimal (Quarto Document Authoring & Basic Data Handling)"
    Write-Host "    (Quarto, LaTeX, Git, VS Code, Minimal R & Python for Quarto docs)"
    Write-Host "[2] VCS & Developer Essentials"
    Write-Host "    (Git, Windows Terminal, VS Code, 7-Zip, Draw.io)"
    Write-Host "[3] Comprehensive Data Science Environment (Python & R)"
    Write-Host "    (Profile [2] + Full Python & R core data science stacks, RStudio, DB Tools)"
    Write-Host "[4] AI & Machine Learning Stack"
    Write-Host "    (Profile [3] + Advanced Python AI/ML/LLM & R Stats/ML packages)"
    Write-Host "[5] Big Data Stack"
    Write-Host "    (Profile [3] + JDK, Apache Spark, PySpark)"
    Write-Host "[6] Full Installation (All of the above applicable)"
    Write-Host "[Q] Quit Installation"
    Write-Host ""

    $validChoices = "1", "2", "3", "4", "5", "6", "Q" 
    $choice = ""
    while (($choice -as [string]).ToUpper() -notin $validChoices) { 
        $choice = Read-Host -Prompt "Enter your choice (1-6, or Q to quit)"
        if (($choice -as [string]).ToUpper() -notin $validChoices) {
            Write-Warning "Invalid selection. Please enter a number between 1 and 6, or Q to quit."
        }
    }

    switch (($choice -as [string]).ToUpper()) { 
        "1" { $Global:SelectedProfile = "Minimal"; Write-Host "Minimal profile selected." -ForegroundColor Green }
        "2" { $Global:SelectedProfile = "VCS_Dev_Essentials"; Write-Host "VCS & Developer Essentials profile selected." -ForegroundColor Green }
        "3" { $Global:SelectedProfile = "Data_Science_Core"; Write-Host "Comprehensive Data Science Environment profile selected." -ForegroundColor Green }
        "4" { $Global:SelectedProfile = "AI_ML_Stack"; Write-Host "AI & Machine Learning Stack profile selected." -ForegroundColor Green }
        "5" { $Global:SelectedProfile = "Big_Data_Stack"; Write-Host "Big Data Stack profile selected." -ForegroundColor Green }
        "6" { $Global:SelectedProfile = "Full"; Write-Host "Full Installation profile selected." -ForegroundColor Green }
        "Q" { Write-Host "Exiting installer as per user request."; $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] User chose to exit at profile selection."); Out-File -FilePath (Join-Path $Global:MainInstallerBaseDir "Installation-Report.txt") -InputObject $Global:InstallationLog -Encoding utf8 -Append; exit 0 }
    }
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] User selected profile: $($Global:SelectedProfile)")
    $Global:ProfileSelectionMade = $true
    Write-Host ""
}


# --- Helper Function to Invoke Module Scripts ---
Function Invoke-ModuleScript {
    param(
        [string]$ModuleName, 
        [string]$ModuleDescription,
        [switch]$IsCritical = $false, 
        [switch]$HaltOnFailure = $false,
        [string[]]$RelevantProfiles = @() # Profiles for which this module is relevant
    )

    # Determine if this module should run based on the selected profile
    $shouldRun = $false
    if ($RelevantProfiles.Count -eq 0) { # Runs for all profiles if none specified
        $shouldRun = $true
    } elseif ($Global:SelectedProfile -eq "Full") {
        $shouldRun = $true
    } else {
        # Check against specific profile flags that will be set based on $Global:SelectedProfile
        # This logic will be expanded as we define profile flags more concretely
        if ($Global:SelectedProfile -in $RelevantProfiles) {
            $shouldRun = $true
        }
        # Add more complex dependency logic here if needed, e.g., "AI_ML_Stack" implies "Data_Science_Core"
        # For now, simple direct match or "Full".
        # Example for hierarchical:
        if ($Global:SelectedProfile -eq "AI_ML_Stack" -and "Data_Science_Core" -in $RelevantProfiles) { $shouldRun = $true }
        if ($Global:SelectedProfile -eq "Big_Data_Stack" -and "Data_Science_Core" -in $RelevantProfiles) { $shouldRun = $true }
         if ($Global:SelectedProfile -eq "Data_Science_Core" -and "VCS_Dev_Essentials" -in $RelevantProfiles) { $shouldRun = $true }
         if ($Global:SelectedProfile -eq "Minimal" -and "Minimal" -in $RelevantProfiles) { $shouldRun = $true } # Explicit Minimal
    }
    
    # Refined check considering the logic in the profile selection switch statement for implied profiles
    if ($Global:SelectedProfile -eq "Full") { $shouldRun = $true }
    elseif ($Global:SelectedProfile -eq "Minimal" -and "Minimal" -in $RelevantProfiles) { $shouldRun = $true }
    elseif ($Global:SelectedProfile -eq "VCS_Dev_Essentials" -and ("VCS_Dev_Essentials" -in $RelevantProfiles)) { $shouldRun = $true }
    elseif ($Global:SelectedProfile -eq "Data_Science_Core" -and ("Data_Science_Core" -in $RelevantProfiles -or "VCS_Dev_Essentials" -in $RelevantProfiles -or "Minimal" -in $RelevantProfiles)) { $shouldRun = $true }
    elseif ($Global:SelectedProfile -eq "AI_ML_Stack" -and ("AI_ML_Stack" -in $RelevantProfiles -or "Data_Science_Core" -in $RelevantProfiles -or "VCS_Dev_Essentials" -in $RelevantProfiles -or "Minimal" -in $RelevantProfiles)) { $shouldRun = $true }
    elseif ($Global:SelectedProfile -eq "Big_Data_Stack" -and ("Big_Data_Stack" -in $RelevantProfiles -or "Data_Science_Core" -in $RelevantProfiles -or "VCS_Dev_Essentials" -in $RelevantProfiles -or "Minimal" -in $RelevantProfiles)) { $shouldRun = $true }
    elseif ($RelevantProfiles.Count -eq 0) { $shouldRun = $true } # No profile restriction means run for all.
    else { $shouldRun = $false } # Default to false if no specific match


    if (-not $shouldRun) {
        Write-Host "Skipping module '$ModuleDescription' ($ModuleName) as it is not included in the selected profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - SKIPPED (Not relevant for profile '$($Global:SelectedProfile)')")
        return $true 
    }

    if ($Global:CriticalFailureEncountered -and $IsCritical) {
        Write-Warning "Skipping critical module '$ModuleDescription' ($ModuleName) due to a previous critical failure."
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - SKIPPED (Previous critical failure)")
        return $false 
    }

    Write-Host "`nAttempting: $ModuleDescription (`"$ModuleName`")..." -ForegroundColor Cyan 
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Attempting: $ModuleDescription ($ModuleName)")
    
    $ModulePath = Join-Path -Path $Global:ModulesDir -ChildPath $ModuleName
    if (-not (Test-Path $ModulePath -PathType Leaf)) {
        Write-Error "Module script not found: $ModulePath"
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - FAILED (Script file not found at $ModulePath)")
        if ($IsCritical) { $Global:CriticalFailureEncountered = $true }
        if ($HaltOnFailure) { 
            Write-Error "Halting due to failure of critical module: $ModuleDescription"
            Out-File -FilePath (Join-Path $Global:MainInstallerBaseDir "Installation-Report.txt") -InputObject $Global:InstallationLog -Encoding utf8 -Append
            exit 1
        }
        $Global:OverallInstallationSuccess = $false
        return $false
    }

    $moduleSuccess = $true 
    try {
        $originalLocation = Get-Location
        Push-Location $Global:ModulesDir 
        
        & $ModulePath 
        
        Pop-Location 
        Set-Location $originalLocation 

        if ($LASTEXITCODE -ne 0) {
            Write-Error "$ModuleDescription ($ModuleName) reported a failure. Exit Code from module: $LASTEXITCODE"
            $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - FAILED (Module Exit Code: $LASTEXITCODE)")
            if ($IsCritical) { $Global:CriticalFailureEncountered = $true }
            if ($HaltOnFailure) { 
                Write-Error "Halting due to failure of critical module: $ModuleDescription"
                Out-File -FilePath (Join-Path $Global:MainInstallerBaseDir "Installation-Report.txt") -InputObject $Global:InstallationLog -Encoding utf8 -Append
                exit 1
            }
            $Global:OverallInstallationSuccess = $false
            $moduleSuccess = $false
        } else {
            Write-Host "$ModuleDescription ($ModuleName) completed successfully." -ForegroundColor Green
            $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - SUCCEEDED")
        }
    } catch {
        Write-Error "A PowerShell exception occurred while executing module $ModuleName for $ModuleDescription $($_.Exception.Message)"
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: $ModuleDescription ($ModuleName) - FAILED (PowerShell Exception: $($_.Exception.Message))")
        if ($IsCritical) { $Global:CriticalFailureEncountered = $true }
        if ($HaltOnFailure) { 
            Write-Error "Halting due to failure of critical module: $ModuleDescription"
            Out-File -FilePath (Join-Path $Global:MainInstallerBaseDir "Installation-Report.txt") -InputObject $Global:InstallationLog -Encoding utf8 -Append
            exit 1
        }
        $Global:OverallInstallationSuccess = $false
        $moduleSuccess = $false
    }
    return $moduleSuccess
}

# --- Part 1: System Prerequisites & Initial Setup (Actual Start of Parts) ---
$TotalParts = 12 
$CurrentPart = 0 

$CurrentPart++
$PartDescription = "System Prerequisites & Initial Setup"
Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

Invoke-ModuleScript -ModuleName "Verify-AdminPrivileges.ps1" -ModuleDescription "Administrator Privileges Check" -IsCritical $true -HaltOnFailure $true
Invoke-ModuleScript -ModuleName "Set-ExecutionPolicyForProcess.ps1" -ModuleDescription "Setting PowerShell Execution Policy" -IsCritical $true -HaltOnFailure $true
Invoke-ModuleScript -ModuleName "Test-InternetConnection.ps1" -ModuleDescription "Internet Connectivity Check" -IsCritical $false 

$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
# End of Part 1
# Main-Installer.ps1 - Part 2
# Continues from Part 1. Focuses on Core Package Managers.

# --- Part 2: Core Package Managers (Chocolatey, Scoop, Winget Check) ---
# This part runs for all profiles as package managers are foundational.
# Proceed only if Pre-flight checks (Part 1) were successful (i.e., no HaltOnFailure triggered).
if (-not $Global:CriticalFailureEncountered) {
    $CurrentPart++
    $PartDescription = "Core Package Managers Setup"
    Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
    Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

    # Install Chocolatey - Attempt first, critical if it's the primary method for many tools.
    # HaltOnFailure is false here to allow attempting Scoop if Choco fails.
    # If Choco module itself determines it CANNOT proceed (e.g. TLS issues), it might exit.
    Invoke-ModuleScript -ModuleName "Install-Chocolatey.ps1" -ModuleDescription "Chocolatey Package Manager" -IsCritical $true -HaltOnFailure $false 
    
    # Refresh PATH immediately after Chocolatey install attempt as it modifies PATH.
    # This specific Refresh-Path is tied to Chocolatey's potential installation.
    if ($LASTEXITCODE -eq 0 -or ($Global:InstallationLog[-1] -match "SUCCEEDED" -or $Global:InstallationLog[-1] -match "already installed")) { 
        Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Chocolatey Attempt" -IsCritical $false 
    }

    # Install Scoop - Can serve as a fallback or primary for some tools.
    # Marked non-critical for the overall script, as some modules might rely solely on Chocolatey or Winget.
    Invoke-ModuleScript -ModuleName "Install-Scoop.ps1" -ModuleDescription "Scoop Command-Line Installer" -IsCritical $false 

    # Refresh PATH after Scoop install attempt.
    if ($LASTEXITCODE -eq 0 -or ($Global:InstallationLog[-1] -match "SUCCEEDED" -or $Global:InstallationLog[-1] -match "already installed")) {
        Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Scoop Attempt" -IsCritical $false
    }
    
    # Check for Winget (Windows Package Manager)
    # This module doesn't install Winget (it's OS-integrated) but checks for its availability.
    Invoke-ModuleScript -ModuleName "Test-WingetAvailability.ps1" -ModuleDescription "Windows Package Manager (Winget) Check" -IsCritical $false

    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
} else {
    Write-Warning "Skipping Part 2 (Core Package Managers) due to critical failure in Part 1."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 2: Core Package Managers (due to previous critical failure) ===")
}
# End of Part 2
# Main-Installer.ps1 - Part 3
# Continues from Part 2. Focuses on Essential Developer Tools.

# --- Part 3: Essential Developer Tools (Git, Terminal, Editor, Utilities) ---
# Proceed only if previous critical steps (like Chocolatey/Scoop setup if they were marked critical and failed) were successful.
if (-not $Global:CriticalFailureEncountered) {
    $CurrentPart++
    $PartDescription = "Essential Developer Tools"
    Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
    Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

    # Git is essential for all profiles that involve code or document versioning.
    Invoke-ModuleScript -ModuleName "Install-Git.ps1" -ModuleDescription "Git (Version Control)" -IsCritical $true -HaltOnFailure $false -RelevantProfiles @("Minimal", "VCS_Dev_Essentials", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")

    # Windows Terminal - Relevant for most development-focused profiles.
    if ($Global:SelectedProfile -in @("VCS_Dev_Essentials", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        Invoke-ModuleScript -ModuleName "Install-WindowsTerminal.ps1" -ModuleDescription "Windows Terminal" -IsCritical $false
    }

    # VS Code - Relevant for Minimal, VCS, and all Data Science/AI/Big Data profiles.
    if ($Global:SelectedProfile -in @("Minimal", "VCS_Dev_Essentials", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        Invoke-ModuleScript -ModuleName "Install-VSCode.ps1" -ModuleDescription "Visual Studio Code (Editor)" -IsCritical $false
    }
    
    # 7-Zip - General utility, relevant for development and data handling tasks.
    if ($Global:SelectedProfile -in @("VCS_Dev_Essentials", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        Invoke-ModuleScript -ModuleName "Install-7Zip.ps1" -ModuleDescription "7-Zip Archiver" -IsCritical $false
    }

    # Draw.io - Useful for diagramming in research/development.
    if ($Global:SelectedProfile -in @("VCS_Dev_Essentials", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        Invoke-ModuleScript -ModuleName "Install-DrawIO.ps1" -ModuleDescription "draw.io Desktop (Diagramming)" -IsCritical $false
    }
        
    Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Essential Developer Tools" -IsCritical $false 

    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
} else {
    Write-Warning "Skipping Part 3 (Essential Developer Tools) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 3: Essential Developer Tools (due to previous critical failure) ===")
}
# End of Part 3
# Main-Installer.ps1 - Part 4
# Continues from Part 3. Focuses on Python Core Environment setup.

# --- Part 4: Python Core Environment Setup ---
# This part runs if profiles "Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", or "Full" are selected.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "Python Core Environment Setup"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Install Python interpreter, ensure pip is available, handle PATH and Windows stubs.
        # This module is critical if any Python packages are to be installed.
        Invoke-ModuleScript -ModuleName "Install-PythonCore.ps1" -ModuleDescription "Python Interpreter & Pip Setup" -IsCritical $true -HaltOnFailure $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack") 
        
        # Refresh PATH after Python installation as it's crucial for finding 'python' and 'pip'.
        # Only run if the Python install module itself didn't halt the script.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Python Core Installation" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        }

        # Install foundational Python packages based on the selected profile.
        # The Install-PythonSelectedPackages.ps1 module will contain logic to determine
        # which requirements*.txt file(s) to use based on $Global:SelectedProfile.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Install-PythonSelectedPackages.ps1" -ModuleDescription "Selected Python Packages based on Profile" -IsCritical $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        } else {
             Write-Warning "Skipping Python Package installation due to failure in Python Core setup."
             $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: Python Selected Packages - SKIPPED (Python Core setup failed)")
        }

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for Python Core Environment as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for Python Core Environment (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 4 (Python Core Environment Setup) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 4: Python Core Environment Setup (due to previous critical failure) ===")
}
# End of Part 4

# Main-Installer.ps1 - Part 5
# Continues from Part 4. Focuses on R Core Environment setup.

# --- Part 5: R Core Environment Setup ---
# This part runs if profiles "Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", or "Full" are selected.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "R Core Environment Setup"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Install R interpreter and Rscript, handle PATH.
        # This module is critical if any R packages are to be installed.
        Invoke-ModuleScript -ModuleName "Install-RCore.ps1" -ModuleDescription "R Programming Language & Rscript Setup" -IsCritical $true -HaltOnFailure $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        
        # Refresh PATH after R installation.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after R Core Installation" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        }

        # Install Rtools (for compiling R packages from source).
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Install-RTools.ps1" -ModuleDescription "Rtools (for R package compilation)" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
            # Refresh PATH again if Rtools installation modifies it.
            if ($LASTEXITCODE -eq 0 -or ($Global:InstallationLog[-1] -match "SUCCEEDED" -or $Global:InstallationLog[-1] -match "already installed")) { 
                 Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Rtools Installation" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
            }
        }
        
        # Install foundational R packages based on the selected profile.
        # The Install-RSelectedPackages.ps1 module will contain logic to determine
        # which sets of R packages to install based on $Global:SelectedProfile.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Install-RSelectedPackages.ps1" -ModuleDescription "Selected R Packages based on Profile" -IsCritical $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        } else {
             Write-Warning "Skipping R Package installation due to failure in R Core or Rtools setup."
             $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: R Selected Packages - SKIPPED (R Core/Rtools setup failed)")
        }

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for R Core Environment as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for R Core Environment (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 5 (R Core Environment Setup) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 5: R Core Environment Setup (due to previous critical failure) ===")
}
# End of Part 5
# Main-Installer.ps1 - Part 6
# Continues from Part 5. Focuses on Key IDEs (RStudio).
# VS Code installation was moved to Part 3 (Essential Developer Tools) as it's more broadly applicable.

# --- Part 6: Key IDEs (RStudio) ---
# This part installs RStudio if profiles "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", or "Full" are selected,
# and assumes R (Part 5) was successfully set up.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "Key IDEs (RStudio)"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Install RStudio IDE
        # Assumes R itself was installed successfully in Part 5.
        # RStudio is highly recommended for R users but not strictly critical for other installations to proceed
        # if the user prefers another R editor or primarily uses Python.
        Invoke-ModuleScript -ModuleName "Install-RStudio.ps1" -ModuleDescription "RStudio IDE (for R development)" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")

        # PATH refresh is typically not needed for RStudio GUI itself, but good practice if its installer might add any CLI utilities.
        # However, RStudio usually doesn't add significant CLI tools to PATH that other scripts depend on immediately.
        # Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after RStudio Installation" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for RStudio IDE as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for RStudio IDE (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 6 (Key IDEs - RStudio) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 6: Key IDEs - RStudio (due to previous critical failure) ===")
}
# End of Part 6
# Main-Installer.ps1 - Part 7
# Continues from Part 6. Focuses on Quarto Publishing Stack & Customization.

# --- Part 7: Quarto Publishing Stack & Customization ---
# This part installs Quarto, TinyTeX, and custom fonts if profiles 
# "Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", or "Full" are selected.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "Quarto Publishing Stack & Customization"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Install Quarto CLI
        # Quarto CLI is critical for the primary purpose of the reports for these profiles.
        Invoke-ModuleScript -ModuleName "Install-QuartoCLI.ps1" -ModuleDescription "Quarto CLI (Publishing System)" -IsCritical $true -HaltOnFailure $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        
        # Refresh PATH after Quarto installation, as it adds 'quarto' to the PATH.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Quarto CLI Installation" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        }

        # Install TinyTeX if Quarto setup was successful
        # TinyTeX is critical if PDF output from Quarto is a primary requirement.
        if (-not $Global:CriticalFailureEncountered) { 
            Invoke-ModuleScript -ModuleName "Install-TinyTeX.ps1" -ModuleDescription "TinyTeX (LaTeX for PDF output via Quarto)" -IsCritical $true -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        } else {
            Write-Warning "Skipping TinyTeX installation due to failure in Quarto CLI setup."
            $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: TinyTeX - SKIPPED (Quarto CLI setup failed)")
        }
        
        # Install Custom Fonts (often used in LaTeX/PDF documents produced by Quarto)
        if (-not $Global:CriticalFailureEncountered) {
             Invoke-ModuleScript -ModuleName "Install-CustomFonts.ps1" -ModuleDescription "Custom Fonts Installation" -IsCritical $false -RelevantProfiles @("Minimal", "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        }

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for Quarto Publishing Stack as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for Quarto Publishing Stack (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 7 (Quarto Publishing Stack & Customization) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 7: Quarto Publishing Stack & Customization (due to previous critical failure) ===")
}
# End of Part 7

# Main-Installer.ps1 - Part 8
# Continues from Part 7. Focuses on Python Advanced AI/ML & LLM Stack.

# --- Part 8: Python Advanced AI/ML & LLM Stack ---
# This part runs if profiles "AI_ML_Stack", "Big_Data_Stack" (if AI is implied), or "Full" are selected.
# It assumes Python Core (Part 4) was successfully set up.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("AI_ML_Stack", "Big_Data_Stack", "Full")) { # Big_Data_Stack often implies AI/ML capabilities too
        $CurrentPart++
        $PartDescription = "Python Advanced AI/ML & LLM Stack"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # This module will use "requirements-ai-ml.txt" or similar.
        # These packages can be large and have complex dependencies.
        # Marked non-critical for the overall installer to proceed if this specific stack isn't vital for other chosen profiles.
        Invoke-ModuleScript -ModuleName "Install-PythonAIMLPackages.ps1" -ModuleDescription "Python AI/Machine Learning Packages" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Big_Data_Stack") 

        # This module will use "requirements-llm.txt" or similar.
        Invoke-ModuleScript -ModuleName "Install-PythonLLMPackages.ps1" -ModuleDescription "Python LLM Interaction Packages" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Big_Data_Stack")

        # This module will use "requirements-nlp.txt" or similar, and handle model downloads.
        Invoke-ModuleScript -ModuleName "Install-PythonNLPSpecialized.ps1" -ModuleDescription "Python Natural Language Processing (NLP) Specialized Packages & Models" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Big_Data_Stack")

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for Python Advanced AI/ML & LLM Stack as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for Python Advanced AI/ML & LLM Stack (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 8 (Python Advanced AI/ML & LLM Stack) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 8: Python Advanced AI/ML & LLM Stack (due to previous critical failure) ===")
}
# End of Part 8

# Main-Installer.ps1 - Part 9
# Continues from Part 8. Focuses on R Advanced Stacks (Stats/ML, Visualization, Text).

# --- Part 9: R Advanced Stacks (Stats/ML, Visualization, Text) ---
# This part runs if profiles "AI_ML_Stack", "Big_Data_Stack" (if R advanced stats are relevant), or "Full" are selected.
# It assumes R Core (Part 5) was successfully set up.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("AI_ML_Stack", "Big_Data_Stack", "Full")) { # Big_Data_Stack might utilize advanced R for analysis
        $CurrentPart++
        $PartDescription = "R Advanced Stacks (Stats/ML, Visualization, Text)"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Module for R Advanced Statistical & Machine Learning Packages
        Invoke-ModuleScript -ModuleName "Install-RAdvancedStatsMLPackages.ps1" -ModuleDescription "R Advanced Statistics & Machine Learning Packages" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Big_Data_Stack")

        # Module for R Advanced Visualization & Spatial Packages
        # Note: Some basic viz (ggplot2) would be in RCoreReportingPackages.ps1 (Part 5)
        # This module is for more specialized/interactive viz libraries.
        Invoke-ModuleScript -ModuleName "Install-RVisualizationPackages.ps1" -ModuleDescription "R Advanced Visualization & Spatial Packages" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Big_Data_Stack", "Data_Science_Core") # Data_Science_Core might also want these

        # Module for R Text & Qualitative Analysis Packages
        Invoke-ModuleScript -ModuleName "Install-RTextQualitativePackages.ps1" -ModuleDescription "R Text & Qualitative Analysis Packages" -IsCritical $false -RelevantProfiles @("AI_ML_Stack", "Data_Science_Core") # Relevant for Data Science Core too

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for R Advanced Stacks as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for R Advanced Stacks (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 9 (R Advanced Stacks) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 9: R Advanced Stacks (due to previous critical failure) ===")
}
# End of Part 9

# Main-Installer.ps1 - Part 10
# Continues from Part 9. Focuses on Specialized Data Tools & Database GUIs.

# --- Part 10: Specialized Data Tools & Database GUIs ---
# This part runs if profiles "Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", or "Full" are selected.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "Specialized Data Tools & Database GUIs"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Python Specialized Database Connectors (if not covered adequately in CoreDataPackages)
        # This module could handle specific connectors based on a requirements-db-connectors.txt
        # Invoke-ModuleScript -ModuleName "Install-PythonSpecializedDataConnectors.ps1" -ModuleDescription "Python Specialized Database Connectors" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        # For now, assuming core connectors are handled within Install-PythonSelectedPackages.ps1 based on profile.

        # R Specialized Database Connectors (if not covered adequately in RCoreReportingPackages)
        # Invoke-ModuleScript -ModuleName "Install-RSpecializedDataConnectors.ps1" -ModuleDescription "R Specialized Database Connector Packages" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")
        # For now, assuming core connectors are handled within Install-RSelectedPackages.ps1 based on profile.

        # DBeaver - Universal Database Tool
        Invoke-ModuleScript -ModuleName "Install-DBeaver.ps1" -ModuleDescription "DBeaver (Universal Database Tool)" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack")

        # SQLiteBrowser - GUI for SQLite
        Invoke-ModuleScript -ModuleName "Install-SQLiteBrowser.ps1" -ModuleDescription "DB Browser for SQLite (GUI)" -IsCritical $false -RelevantProfiles @("Data_Science_Core", "AI_ML_Stack", "Big_Data_Stack", "Minimal") # Minimal might need it for basic data handling

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for Specialized Data Tools & Database GUIs as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for Specialized Data Tools & Database GUIs (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 10 (Specialized Data Tools & Database GUIs) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 10: Specialized Data Tools & Database GUIs (due to previous critical failure) ===")
}
# End of Part 10

# Main-Installer.ps1 - Part 11
# Continues from Part 10. Focuses on the Big Data Stack (Java, Spark, PySpark).

# --- Part 11: Big Data Stack (Spark & Prerequisites) ---
# This part runs if profiles "Big_Data_Stack" or "Full" are selected.
# Proceed only if previous critical steps were successful.
if (-not $Global:CriticalFailureEncountered) {
    if ($Global:SelectedProfile -in @("Big_Data_Stack", "Full")) {
        $CurrentPart++
        $PartDescription = "Big Data Stack (Java, Spark, PySpark)"
        Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
        Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

        # Install Java Development Kit (JDK) - Prerequisite for Spark
        # Marked as critical for this part, as Spark cannot run without it.
        Invoke-ModuleScript -ModuleName "Install-JavaJDK.ps1" -ModuleDescription "Java Development Kit (JDK)" -IsCritical $true -HaltOnFailure $true -RelevantProfiles @("Big_Data_Stack")
        
        # Refresh PATH after Java JDK installation, especially if JAVA_HOME was set.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Java JDK Installation" -IsCritical $false -RelevantProfiles @("Big_Data_Stack")
        }

        # Install Apache Spark & Hadoop Winutils (Complex Module)
        # This module must verify that Java (and JAVA_HOME) is correctly set up.
        # Marked as critical for this part.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Install-SparkAndWinutils.ps1" -ModuleDescription "Apache Spark & Hadoop Winutils Setup" -IsCritical $true -HaltOnFailure $true -RelevantProfiles @("Big_Data_Stack")
        } else {
             Write-Warning "Skipping Apache Spark setup due to failure in Java JDK installation."
             $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: Apache Spark & Winutils - SKIPPED (Java JDK setup failed)")
        }
        
        # Refresh PATH after Spark installation (SPARK_HOME, HADOOP_HOME, and their bin folders to PATH).
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Refresh-PathAndEnvironment.ps1" -ModuleDescription "Path Refresh after Spark Setup" -IsCritical $false -RelevantProfiles @("Big_Data_Stack")
        }

        # Install PySpark Python Package
        # This module must verify Python is installed and SPARK_HOME is set.
        # Marked as critical for this part to ensure the Python interface to Spark works.
        if (-not $Global:CriticalFailureEncountered) {
            Invoke-ModuleScript -ModuleName "Install-PySparkViaPip.ps1" -ModuleDescription "PySpark Python Package (for Spark)" -IsCritical $true -RelevantProfiles @("Big_Data_Stack")
        } else {
             Write-Warning "Skipping PySpark Python package installation due to failure in Spark setup."
             $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Module: PySpark Python Package - SKIPPED (Spark setup failed)")
        }

        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")
    } else {
        Write-Host "`nSkipping Part for Big Data Stack as it's not required for profile '$($Global:SelectedProfile)'." -ForegroundColor DarkGray
        $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part for Big Data Stack (Not relevant for profile '$($Global:SelectedProfile)') ===")
    }
} else {
    Write-Warning "Skipping Part 11 (Big Data Stack) due to previous critical failure."
    $Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === SKIPPING Part 11: Big Data Stack (due to previous critical failure) ===")
}
# End of Part 11

# Main-Installer.ps1 - Part 12
# Continues from Part 11. Focuses on Final System Checks & Generating the Installation Report.

# --- Part 12: Final System Checks & Reporting ---
# This part runs for all profiles to provide a summary and perform final checks.
# It should run even if some non-critical previous parts were skipped or had issues,
# unless a -HaltOnFailure critical module stopped the script earlier.

$CurrentPart++ # Increment even if previous parts were skipped, as this is the final mandated part.
$PartDescription = "Final System Checks & Reporting"
Write-Progress -Activity "Main Installation Progress" -Status "Part $CurrentPart/$TotalParts $PartDescription" -PercentComplete (($CurrentPart / $TotalParts) * 100) -Id 1
Write-Host "`n=== PART $CurrentPart/$TotalParts $PartDescription ===" -ForegroundColor Yellow
$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Starting Part $CurrentPart/$TotalParts $PartDescription ===")

# Module to run final system checks (e.g., quarto check, verify key tool versions)
# This module should log its findings to $Global:InstallationLog
Invoke-ModuleScript -ModuleName "Run-FinalSystemChecks.ps1" -ModuleDescription "Final System & Tool Verification Checks" -IsCritical $false 

# Module to generate the final installation summary report from $Global:InstallationLog
# This is marked critical as generating the report is a key output of the installer.
Invoke-ModuleScript -ModuleName "Generate-InstallationSummaryReport.ps1" -ModuleDescription "Generating Installation Summary Report" -IsCritical $true -HaltOnFailure $false # Don't halt, just try to report

$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] === Completed Part $CurrentPart/$TotalParts $PartDescription ===")


# --- Final Summary & Exit ---
Write-Progress -Activity "Main Installation Progress" -Completed -Id 1 # Close the progress bar
Write-Host "`n" + ("-" * 79)
Write-Host "Installation Process Attempted." -ForegroundColor Yellow

if ($Global:OverallInstallationSuccess) {
    Write-Host "All essential modules for the selected profile ('$($Global:SelectedProfile)') reported success or were already complete." -ForegroundColor Green
    if ($Global:InstallationLog -match "WARNING|SKIPPED") { # Check the log content for these keywords
        Write-Warning "Some non-critical modules may have warnings or were skipped. Please review the report."
    }
} else {
    Write-Error "One or more modules reported failures during the installation process for profile '$($Global:SelectedProfile)'."
    if ($Global:CriticalFailureEncountered) {
        Write-Error "A critical module failure occurred, which may have prevented subsequent critical installations."
    }
    Write-Warning "The environment setup may be incomplete. Please review the detailed report."
}

$ReportFilePath = Join-Path $Global:MainInstallerBaseDir "Installation-Report.txt"
Write-Host "A detailed installation log has been saved to: $ReportFilePath" -ForegroundColor Cyan
Write-Host ("-" * 79)
Write-Host "IMPORTANT NOTES (Review Carefully):" -ForegroundColor Yellow
Write-Host " - PATH Environment Variable: Newly installed command-line tools (Python, Pip, R, Rscript, Git, Quarto, etc.)"
Write-Host "   might not be immediately available in THIS PowerShell session, even after refresh attempts."
Write-Host "   If you encounter 'command not found' errors when trying to use them after this script,"
Write-Host "   CLOSE THIS POWERSHELL WINDOW AND OPEN A NEW ADMINISTRATOR POWERSHELL WINDOW."
Write-Host "   This usually resolves PATH-related issues for new installations."
Write-Host " - Python App Execution Aliases (Stubs): If warnings about 'Windows Store stub' for Python appeared"
Write-Host "   during the Python Core setup (Part 4), it is CRITICAL to manually disable these in Windows Settings"
Write-Host "   ('Manage app execution aliases') and then potentially re-run relevant Python package installations."
Write-Host " - Chocolatey/Scoop Pending Reboots: If any package manager indicated a pending system reboot is required,"
Write-Host "   some installations or PATH changes might not be fully stable or effective until the system is restarted."
Write-Host " - Custom Fonts: If custom fonts were installed, a system REBOOT or LOGOFF/LOGON might be necessary for"
Write-Host "   all applications to recognize and use them correctly."
Write-Host " - Review Installation Report: Please carefully review '$ReportFilePath' for details on each step,"
Write-Host "   especially for any FAILED, SKIPPED, or WARNING messages."
Write-Host ""
$Global:InstallationLog.Add("[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] Main Installer Script Finished.")

# Final attempt to write the log, in case the Generate-InstallationSummaryReport module had issues
try {
    Out-File -FilePath $ReportFilePath -InputObject $Global:InstallationLog -Encoding utf8 -Append -Force
} catch {
    Write-Warning "Could not write final log to $ReportFilePath. Error: $($_.Exception.Message)"
}

Read-Host -Prompt "Setup script finished. Press Enter to exit."
# End of Main-Installer.ps1