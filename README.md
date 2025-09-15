# Data Science Kit - Comprehensive Windows Environment Installer

**Automated setup for Data Science, AI/ML, and Research workflows on Windows**

## Overview

The Data Science Kit is a robust, modular PowerShell installer that automates the setup of a comprehensive environment for data science, AI/ML development, and automated research on Windows. Whether you're setting up for basic document authoring, advanced machine learning, or specific projects like ResilienceScan, this installer provides tailored installation profiles to get you productive quickly.

## Quick Start

### Prerequisites
- Windows 10/11 (64-bit recommended)
- Administrator privileges
- Internet connection

### Installation

1. **Clone or download this repository**
   ```powershell
   git clone https://github.com/your-org/Data-ScienceKit.git
   cd Data-ScienceKit/Scripts
   ```

2. **Set execution policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

3. **Run the installer**
   ```powershell
   .\Main-Installer.ps1
   ```

4. **Select your profile** when prompted, or specify directly:
   ```powershell
   .\Main-Installer.ps1 -Profile "RecilienceScan"
   ```

## Installation Profiles

Choose the profile that best matches your needs:

### 🎯 **RecilienceScan**
*Minimal setup for RecilienceScan report automation pipeline*
- Git, Python 3.11+, Quarto CLI, TinyTeX
- Perfect for automated report generation and email delivery

### 🔧 **Essential** 
*Basic tools for coding and version control*
- Git, VS Code, Windows Terminal, Package Managers
- Ideal for general development work

### 📝 **Minimal**
*Document authoring with Python/R basics*
- Essential tools + Python, R, Quarto, basic packages
- Great for academic writing and basic analysis

### 📊 **DataScience**
*Complete data science environment*
- Full Python & R stack, RStudio, Jupyter, visualization tools
- Comprehensive setup for data analysis and research

### 🤖 **AI_ML**
*Advanced AI/ML stack with deep learning frameworks*
- DataScience + TensorFlow, PyTorch, Transformers, NLP tools
- Ready for machine learning and AI development

### 🗄️ **BigData**
*Big data processing with distributed computing*
- AI_ML + Apache Spark, Hadoop, Java JDK, cloud tools
- Handles large-scale data processing

### 🌟 **Full**
*Complete installation with all available components*
- Everything included: all tools, packages, fonts, utilities
- Maximum capability installation

## Architecture

### Modular Design
The installer uses a modular architecture with 50+ specialized PowerShell modules in the `modules/` directory. Each module handles a specific installation task and can run independently.

### Key Components
- **Main-Installer.ps1** - Orchestrates the entire installation process
- **modules/** - Individual installation modules for specific tools
- **requirements/** - Package requirement files for Python/R
- **assets/** - Custom fonts, configurations, and resources

### Installation Process
1. **System Prerequisites** - Admin verification, execution policy, internet check
2. **Package Managers** - Chocolatey, Scoop, Winget availability
3. **Core Tools** - Git, Python, R, development environments
4. **Specialized Packages** - Data science, AI/ML, visualization libraries
5. **Publishing Stack** - Quarto, LaTeX, documentation tools
6. **Verification** - Environment testing and comprehensive reporting

## Tool Coverage (Current vs Planned)

### Currently Implemented
- **Package Managers**: Chocolatey, Scoop detection, Winget checking
- **Version Control**: Git with automated installation
- **Programming Languages**: Python 3.11+ with automated setup  
- **Publishing**: Quarto CLI, TinyTeX for PDF generation
- **Development**: VS Code (basic installation)
- **System Tools**: Windows Terminal, 7-Zip (modules exist)

### Planned for Future Releases
- **R Environment**: R language, RStudio, comprehensive R packages
- **Data Science Stack**: pandas, numpy, scipy, scikit-learn, visualization libraries
- **AI & Machine Learning**: TensorFlow, PyTorch, Transformers, NLP tools
- **Database Tools**: SQLite tools, DBeaver, database connectors  
- **Big Data**: Apache Spark, Hadoop, distributed computing
- **Advanced Publishing**: Custom fonts, advanced Quarto features
- **Productivity Tools**: FFmpeg, Draw.io, additional utilities

*See the comprehensive planning document for the full intended scope*

## Project Structure

```
Data-ScienceKit/
├── Scripts/
│   ├── Main-Installer.ps1              # Main installation orchestrator
│   ├── modules/                        # Individual installation modules
│   │   ├── Install-Git.ps1
│   │   ├── Install-PythonCore.ps1
│   │   ├── Install-QuartoCLI.ps1
│   │   ├── Test-SystemRequirements.ps1
│   │   └── ... (50+ modules)
│   ├── requirements/
│   │   ├── requirements.txt            # Python packages
│   │   └── r-packages.txt              # R packages
│   └── assets/                         # Fonts, configs, resources
├── README.md                           # This file
└── LICENSE
```

## Features

### 🛡️ **Robust Error Handling**
- Continues installation even if non-critical components fail
- Detailed logging and error reporting
- Comprehensive final installation report

### 📊 **Progress Tracking**
- Real-time progress indicators
- Phase-by-phase installation status
- Clear success/failure feedback

### 🔄 **Smart Detection**
- Skips already-installed components
- Validates existing installations
- Refreshes environment variables automatically

### 📋 **Comprehensive Reporting**
- Detailed installation logs
- JSON-formatted results for automation
- Environment verification reports

## Troubleshooting

### Common Issues

**PowerShell Execution Policy Error**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

**"Module file not found" errors**
- Ensure you're running from the `Scripts/` directory
- Check that all required module files exist in `modules/`

**Package manager not found (choco/scoop)**
- The installer handles package manager installation automatically
- Restart PowerShell session if PATH refresh doesn't work

**Python/R packages fail to install**
- Check internet connectivity
- Verify Python/R are properly installed first
- Some packages may require manual installation

### Getting Help

1. Check the installation log file for detailed error information
2. Run individual modules to isolate issues:
   ```powershell
   cd modules
   .\Install-PythonCore.ps1
   ```
3. Use the verification modules to test your environment:
   ```powershell
   .\Test-SystemRequirements.ps1
   ```

## Advanced Usage

### Custom Profiles
You can modify the profile definitions in `Main-Installer.ps1` to create custom installation combinations.

### Individual Module Execution
All modules can be run independently for testing or custom installations:
```powershell
cd modules
.\Install-Git.ps1
.\Install-PythonCore.ps1
```

### Force Reinstallation
```powershell
.\Main-Installer.ps1 -ForceReinstall -Profile "DataScience"
```

### Skip Confirmation Prompts
```powershell
.\Main-Installer.ps1 -SkipChecks -Profile "Essential"
```

## Contributing

Contributions are welcome! The modular architecture makes it easy to:
- Add new installation modules
- Enhance existing modules
- Create new installation profiles
- Improve error handling and reporting

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Built for the Lectoraat Supply Chain Finance at Windesheim University of Applied Sciences, supporting data science education and research automation.

---

**Need a specific tool setup?** Create an issue or contribute a new module to help the community!
