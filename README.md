Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Comprehensive Data Science & Research Pipeline Installer

## Project Goal

To create a robust, modular PowerShell script (`Main-Installer.ps1`) that automates the setup of a comprehensive environment for data science and automated research (surveys, interviews, AI-supported analysis) on Windows. The installer will prioritize user experience with clear progress indication, graceful error handling (allowing continuation on non-critical failures), and a final summary report.

## Core Principles

1.  **Modularity:** The main installer will orchestrate calls to numerous smaller, focused PowerShell module scripts (located in a `.\modules\` subdirectory). This allows for easier development, testing, debugging, and maintenance of individual component installations.
2.  **User Experience:**
    *   The main installer will provide clear visual feedback, including an overall progress bar tracking major installation phases.
    *   Status messages for each attempted installation (success, failure, skipped, warnings) will be displayed.
3.  **Resilience:** The installer will aim to continue processing subsequent modules even if a non-critical module fails, logging the outcome.
4.  **Reporting:** A summary text file (`Installation-Report.txt`) will be generated at the end, detailing the status of each attempted installation, any errors encountered, and versions of key software detected.
5.  **Prerequisites:** The script will require and check for Administrator privileges and an active internet connection.
6.  **Automation Focus:** Primary installation method for tools will be Chocolatey where appropriate, and `pip`/`Rscript` for language-specific packages.

## Planned Installation Structure (~10 Logical Parts)

The `Main-Installer.ps1` will orchestrate the installation through the following logical parts, each potentially comprising multiple module scripts:

**Part 1: System Prerequisites & Initial Setup**
*   **Objective:** Prepare the system for subsequent installations.
*   **Key Modules (Conceptual - in `.\modules\`):**
    *   `Verify-AdminPrivileges.ps1`
    *   `Set-ExecutionPolicyForProcess.ps1`
    *   `Test-InternetConnection.ps1`
    *   `Install-Chocolatey.ps1`
    *   `Refresh-PathAndEnvironment.ps1` (to be called strategically)

**Part 2: Essential Developer & System Utilities**
*   **Objective:** Install fundamental command-line tools and utilities.
*   **Key Modules:**
    *   `Install-Git.ps1`
    *   `Install-WindowsTerminal.ps1`
    *   `Install-7Zip.ps1`
    *   `(Optional) Install-NotepadPlusPlus.ps1`
    *   `(Optional) Install-SumatraPDF.ps1`

**Part 3: Python Core Environment & Foundational Packages**
*   **Objective:** Set up a functional Python environment with core data science libraries.
*   **Key Modules:**
    *   `Install-PythonCore.ps1` (Python interpreter, pip, PATH, stub handling)
    *   `Install-PythonCoreDataPackages.ps1` (using `requirements-core-data.txt` for pandas, numpy, scipy, openpyxl, pyarrow, duckdb, requests, beautifulsoup4, jupyterlab, etc.)

**Part 4: R Core Environment & Foundational Packages**
*   **Objective:** Set up a functional R environment with core statistical and reporting libraries.
*   **Key Modules:**
    *   `Install-RCore.ps1` (R, Rscript, PATH)
    *   `Install-RTools.ps1`
    *   `Install-RCoreReportingPackages.ps1` (knitr, rmarkdown, yaml, jsonlite, htmltools, tidyverse suite, lubridate, here, fs, devtools, readxl, openxlsx, DBI, RSQLite, arrow, etc.)

**Part 5: Key Integrated Development Environments (IDEs)**
*   **Objective:** Install primary IDEs for Python and R development.
*   **Key Modules:**
    *   `Install-VSCode.ps1` (with prompts/suggestions for key extensions)
    *   `Install-RStudio.ps1`

**Part 6: Quarto Publishing Stack & Customization**
*   **Objective:** Set up the Quarto publishing system and related components.
*   **Key Modules:**
    *   `Install-QuartoCLI.ps1`
    *   `Install-TinyTeX.ps1`
    *   `Install-CustomFonts.ps1` (if applicable for report templates)

**Part 7: Python Advanced AI/ML & LLM Stack**
*   **Objective:** Install specialized Python libraries for advanced AI, Machine Learning, and Large Language Model interaction.
*   **Key Modules:**
    *   `Install-PythonAIMLPackages.ps1` (using `requirements-ai-ml.txt` for scikit-learn, tensorflow, keras, pytorch, transformers, spacy, nltk, etc.)
    *   `Install-PythonLLMPackages.ps1` (using `requirements-llm.txt` for openai, anthropic, langchain, llamaindex, etc.)

**Part 8: R Advanced Statistical/ML, Visualization & Specialized Packages**
*   **Objective:** Install specialized R libraries for advanced analysis, machine learning, and rich visualizations.
*   **Key Modules:**
    *   `Install-RVisualizationPackages.ps1` (DT, kableExtra, patchwork, ggrepel, plotly (R), leaflet, sf, tmap, viridis, RColorBrewer, ggthemes, etc.)
    *   `Install-RAdvancedStatsMLPackages.ps1` (caret, tidymodels, ranger, xgboost, prophet, forecast, etc.)
    *   `Install-RTextQualitativePackages.ps1` (tm, quanteda, tidytext, SnowballC, etc.)
    *   `Install-RDatabaseConnectorPackages.ps1` (specific R database drivers beyond RSQLite if needed)

**Part 9: Specialized Frameworks & Tools (e.g., Big Data, Database GUIs)**
*   **Objective:** Install more advanced or specialized tools.
*   **Key Modules:**
    *   `Install-JavaJDK.ps1` (Prerequisite for Spark)
    *   `Install-SparkAndWinutils.ps1` (Complex module for local Spark setup)
    *   `Install-PySparkViaPip.ps1` (To be called after Python and Spark setup)
    *   `Install-GeneralUtilities.ps1` (DBeaver, SQLiteBrowser, DrawIO, etc.)
    *   `(Optional) Install-FFmpeg.ps1`
    *   `(Optional) Install-Audacity.ps1`
    *   `(Optional) Install-DockerDesktop.ps1` (with clear warnings about system requirements)

**Part 10: Final System Checks & Reporting**
*   **Objective:** Verify key installations and provide a summary of the setup process.
*   **Key Modules:**
    *   `Run-FinalSystemChecks.ps1` (e.g., run `quarto check`, verify key Python/R package importability and versions)
    *   `Generate-InstallationSummaryReport.ps1` (creates `Installation-Report.txt`)

## Module Script Design

Each module script in the `.\modules\` directory will:
*   Be a standalone PowerShell (`.ps1`) script.
*   Perform a specific task (e.g., install one tool or a closely related group of packages).
*   Include its own logging/Write-Host messages for its actions.
*   Attempt to detect if the tool/package is already installed to avoid redundant work.
*   Exit with code `0` on success.
*   Exit with a non-zero code (e.g., `1`) on failure, or if a critical prerequisite is missing.
*   Use `try...catch` blocks for robust error handling.

## Main Installer (`Main-Installer.ps1`) Features

*   **Welcome & Pre-flight Checks:** Admin rights, OS version, PowerShell version, Internet.
*   **Overall Progress Bar:** Using `Write-Progress` for the ~10 main parts.
*   **Modular Invocation:** A helper function (e.g., `Invoke-ModuleScript`) to call sub-scripts, capture their success/failure, and log details.
*   **Status Collection:** Maintain an array or list of results for each module.
*   **Continuation on Failure:** Option to continue with subsequent parts/modules if a non-critical one fails.
*   **Final Report Generation:** Create `Installation-Report.txt`.
*   **Clear Console Summary:** Display key successes, failures, and point to the report file.

## Requirements Files (Examples)

*   `requirements-core-data.txt` (for Python)
*   `requirements-ai-ml.txt` (for Python)
*   `requirements-llm.txt` (for Python)
*   (R packages will likely be listed directly in their respective `Install-R*.ps1` scripts or a PowerShell array, then installed iteratively using `Rscript.exe` or `R.exe CMD R`)

This plan provides a structured approach to building the comprehensive installer.



# Comprehensive Research Pipeline Environment Setup: Tools & Status




This table outlines software, packages, and tools considered for an automated research pipeline focused on surveys, interviews, and AI-supported analysis. It indicates the current inclusion status within the `Main-Installer.ps1` script and its modules.

| Category                          | Tool / Package Name                 | Incl? | Primary Usage in Research Pipeline                                    | Typical Windows Install Method (for Script)             |
|-----------------------------------|-------------------------------------|:-----:|-----------------------------------------------------------------------|---------------------------------------------------------|
| **I. Foundational Infrastructure**  |                                     |       |                                                                       |                                                         |
|                                   | Chocolatey                          |  [x]  | Windows Package Manager                                               | Custom Script (`Install-Chocolatey.ps1`)                |
|                                   | Git                                 |  [x]  | Version Control (code, scripts, documents, data versioning with DVC)  | `choco install git`                                     |
|                                   | Python 3.x                          |  [x]  | Scripting, data processing, API interaction, AI/ML                      | `choco install python` / User Guided                    |
|                                   | Pip (Python Package Installer)      |  [x]  | Python Package Management                                             | Bundled with Python / `ensurepip`                       |
|                                   | R                                   |  [x]  | Statistical analysis, visualization, text mining, reporting             | `choco install r.project` / Custom Script               |
|                                   | Rscript                             |  [x]  | Command-line execution of R scripts for automation                    | Bundled with R                                          |
|                                   | Quarto CLI                          |  [x]  | Reproducible research reporting, publishing (articles, websites, books)| `choco install quarto-cli` / MSI                        |
|                                   | Pandoc                              |  [x]  | Document Conversion (core Quarto dependency)                          | Bundled with Quarto                                     |
|                                   | TinyTeX                             |  [x]  | Lightweight LaTeX distribution for PDF report generation              | `quarto install tool tinytex`                           |
|                                   | JDK (e.g., OpenJDK 11/17)         |  [x]  | Java Development Kit (Prerequisite for Spark, some NLP/ML tools)      | `choco install openjdk11` (or `openjdk17`)              |
| **II. Development Environments**  |                                     |       |                                                                       |                                                         |
|                                   | Visual Studio Code (VS Code)        |  [x]  | General code editor (Python, R, Quarto, Markdown, text data)          | `choco install vscode`                                  |
|                                   | RStudio                             |  [x]  | Specialized IDE for R development, analysis, and Quarto authoring     | `choco install rstudio`                                 |
|                                   | JupyterLab / Jupyter Notebook       |  [x]  | Interactive data exploration, AI model prototyping, coding narratives | `pip install jupyterlab notebook`                       |
| **III. Shells & Terminals**       |                                     |       |                                                                       |                                                         |
|                                   | Windows Terminal                    |  [x]  | Modern multi-tabbed terminal for Windows                              | `choco install microsoft-windows-terminal`              |
|                                   | PowerShell Core (7+)                |  [ ]  | Advanced cross-platform scripting and automation                      | `choco install powershell-core`                         |
|                                   | Git Bash                            |  [x]  | Bash emulation on Windows                                             | Bundled with Git for Windows                            |
| **IV. Data Collection & APIs**    |                                     |       |                                                                       |                                                         |
|                                   | `requests` (Python)                 |  [x]  | HTTP requests for accessing web APIs and online resources               | `pip install requests` (likely via requirements.txt)  |
|                                   | `BeautifulSoup4`, `Scrapy` (Py)     |  [x]  | Web scraping for unstructured data collection                         | `pip install beautifulsoup4 scrapy` (via reqs)        |
|                                   | `rtweet` (R), `tweepy` (Python)     |  [ ]  | Accessing Twitter/X API for social media research                     | `Install-RPackages.ps1`, `pip install tweepy`           |
|                                   | Survey Platform SDKs (e.g., Qualtrics)|  [ ]  | Automating survey data retrieval and management                       | Python/R SDKs via pip/CRAN, custom API scripts        |
|                                   | `httr` (R)                          |  [x]  | Tools for working with HTTP in R (API interaction)                    | `Install-RPackages.ps1`                                 |
| **V. Data Storage & Management**  |                                     |       |                                                                       |                                                         |
|                                   | SQLite (CLI & DB Browser)           |  [x]  | Lightweight local relational database                                 | `choco install sqlite sqlitebrowser`                    |
|                                   | DBeaver                             |  [x]  | Universal Database GUI Tool (SQL/NoSQL)                               | `choco install dbeaver`                                 |
|                                   | `duckdb` (Python/R package)         |  [ ]  | In-process analytical database, efficient for local CSV/Parquet       | `pip install duckdb`, `Install-RPackages.ps1`           |
|                                   | MinIO (Local S3)                    |  [ ]  | Self-hosted S3-compatible object storage (for larger datasets)        | `choco install minio` (requires server setup)         |
|                                   | Apache Parquet tools/libs           |  [x]  | Columnar storage format (via `pyarrow` in Python, `arrow` in R)       | `pip install pyarrow`, `Install-RPackages.ps1`          |
|                                   | `readxl` (R)                        |  [x]  | Reading Excel files (.xls, .xlsx) into R                              | `Install-RPackages.ps1`                                 |
|                                   | `writexl` (R)                       |  [x]  | Writing R data frames to Excel files                                  | `Install-RPackages.ps1`                                 |
|                                   | `openxlsx` (R)                      |  [x]  | More advanced Excel reading/writing/formatting in R                   | `Install-RPackages.ps1`                                 |
|                                   | `haven` (R)                         |  [x]  | Reading SPSS, Stata, and SAS files in R                               | `Install-RPackages.ps1`                                 |
|                                   | `DBI` (R)                           |  [x]  | Database Interface API for R                                          | `Install-RPackages.ps1`                                 |
|                                   | `RSQLite` (R)                       |  [x]  | SQLite driver for R using DBI                                         | `Install-RPackages.ps1`                                 |
|                                   | `RPostgres` (R)                     |  [x]  | PostgreSQL driver for R using DBI                                     | `Install-RPackages.ps1`                                 |
|                                   | `feather` (R)                       |  [x]  | Fast, lightweight binary format for R data frames                     | `Install-RPackages.ps1` (often via `arrow`)           |
|                                   | `fst` (R)                           |  [x]  | Fast data frame storage format for R                                  | `Install-RPackages.ps1`                                 |
|                                   | `arrow` (R)                         |  [x]  | Apache Arrow for R (efficient large data, Parquet, Feather)         | `Install-RPackages.ps1`                                 |
| **VI. Qualitative Data Analysis** |                                     |       |                                                                       |                                                         |
|                                   | `nltk` (Python)                     |  [x]  | Natural Language Toolkit (tokenization, stemming, tagging, corpora)   | `pip install nltk` (+ download data)                    |
|                                   | `spaCy` (Python)                    |  [x]  | Industrial-strength NLP (NER, dependency parsing, word vectors)       | `pip install spacy` (+ download models)                 |
|                                   | `tm` (R)                            |  [x]  | Text Mining framework in R                                            | `Install-RPackages.ps1`                                 |
|                                   | `quanteda` (R)                      |  [x]  | Quantitative analysis of textual data in R                            | `Install-RPackages.ps1`                                 |
|                                   | `tidytext` (R)                      |  [x]  | Text mining using tidy data principles in R                           | `Install-RPackages.ps1`                                 |
|                                   | `SnowballC` (R)                     |  [x]  | Stemming library for R (often a dependency for text mining)           | `Install-RPackages.ps1`                                 |
|                                   | FFmpeg                              |  [ ]  | Audio/video processing (transcoding, for interview recordings)        | `choco install ffmpeg`                                  |
|                                   | Audacity                            |  [ ]  | Audio editing software (manual editing of interview recordings)       | `choco install audacity`                                |
| **VII. AI & Machine Learning**    |                                     |       |                                                                       |                                                         |
|                                   | `scikit-learn` (Python)             |  [x]  | General ML: classification, regression, clustering, preprocessing   | `pip install scikit-learn`                              |
|                                   | `tensorflow`, `keras` (Python)      |  [x]  | Deep Learning frameworks (neural networks, computer vision, NLP)      | `pip install tensorflow keras`                          |
|                                   | `pytorch` (Python)                  |  [x]  | Deep Learning framework (popular alternative to TensorFlow)           | `pip install torch torchvision torchaudio`              |
|                                   | `transformers` (Hugging Face Py)    |  [x]  | Access to SOTA pre-trained models (BERT, GPT, etc.) for NLP tasks   | `pip install transformers sentencepiece sacremoses`   |
|                                   | OpenAI API Client (Python/R)        |  [ ]  | Interacting with GPT models for text generation, summarization, Q&A | `pip install openai`; R via `httr2` or specific pkg |
|                                   | Anthropic API Client (Py/R)         |  [ ]  | Interacting with Claude models                                        | `pip install anthropic`; R via `httr2`                  |
|                                   | LangChain / LlamaIndex (Python)     |  [ ]  | Frameworks for building LLM-powered applications (RAG, agents)      | `pip install langchain llama-index`                     |
|                                   | `SpeechRecognition` (Python)      |  [ ]  | Python library for various speech-to-text engines/APIs              | `pip install SpeechRecognition`                         |
|                                   | AssemblyAI / Google Speech API etc. |  [ ]  | Cloud-based Speech-to-Text services (require SDKs/API keys)         | Python SDKs, API interaction                            |
|                                   | Apache Spark (Local Mode)           |  [x]  | Distributed processing for large-scale ML or text data                | Manual/Scripted download & config (`Install-Spark.ps1`)|
|                                   | Hadoop `winutils.exe`               |  [x]  | Hadoop binaries for Windows (Needed by Spark)                         | Manual/Scripted with Spark setup                        |
|                                   | `pyspark` (Python package)          |  [x]  | Python API for Apache Spark                                           | `pip install pyspark`                                   |
|                                   | `caret` (R)                         |  [x]  | Classification And REgression Training (ML meta-package)              | `Install-RPackages.ps1`                                 |
|                                   | `tidymodels` (R)                    |  [x]  | Tidyverse-aligned ML meta-package                                     | `Install-RPackages.ps1`                                 |
|                                   | `ranger` (R)                        |  [x]  | Fast Random Forest implementation in R                                | `Install-RPackages.ps1`                                 |
|                                   | `xgboost` (R)                       |  [x]  | Extreme Gradient Boosting for R                                       | `Install-RPackages.ps1`                                 |
|                                   | `glmnet` (R)                        |  [x]  | Regularized Generalized Linear Models in R                            | `Install-RPackages.ps1`                                 |
|                                   | `randomForest` (R)                  |  [x]  | Classic Random Forest for R                                           | `Install-RPackages.ps1`                                 |
|                                   | `rpart` (R)                         |  [x]  | Recursive Partitioning and Regression Trees for R                     | `Install-RPackages.ps1`                                 |
|                                   | `prophet` (R)                       |  [x]  | Time series forecasting by Facebook for R                             | `Install-RPackages.ps1`                                 |
|                                   | `forecast` (R)                      |  [x]  | Comprehensive time series forecasting tools for R                     | `Install-RPackages.ps1`                                 |
|                                   | `tsibble` (R)                       |  [x]  | Tidy data structures for time series in R                             | `Install-RPackages.ps1`                                 |
|                                   | `fable` (R)                         |  [x]  | Tidy time series forecasting models for R                             | `Install-RPackages.ps1`                                 |
| **VIII. Data Visualization**      |                                     |       | (R packages largely covered in VII and Install-RPackages.ps1)       |                                                         |
|                                   | `ggrepel` (R)                       |  [x]  | For preventing text label overlap in ggplot2                          | `Install-RPackages.ps1`                                 |
|                                   | `patchwork` (R)                     |  [x]  | For combining ggplot2 plots easily                                    | `Install-RPackages.ps1`                                 |
|                                   | `plotly` (R)                        |  [x]  | For interactive D3.js-based plots from R                            | `Install-RPackages.ps1`                                 |
|                                   | `highcharter` (R)                   |  [x]  | Interactive charts for R based on Highcharts JS                       | `Install-RPackages.ps1`                                 |
|                                   | `leaflet` (R)                       |  [x]  | For interactive maps in R                                             | `Install-RPackages.ps1`                                 |
|                                   | `sf` (R)                            |  [x]  | For working with spatial vector data (Simple Features) in R           | `Install-RPackages.ps1`                                 |
|                                   | `tmap` (R)                          |  [x]  | For thematic maps in R                                                | `Install-RPackages.ps1`                                 |
|                                   | `gganimate` (R)                     |  [x]  | For creating animations with ggplot2                                  | `Install-RPackages.ps1`                                 |
|                                   | `viridis` (R)                       |  [x]  | Colorblind-friendly color palettes for R                              | `Install-RPackages.ps1`                                 |
|                                   | `RColorBrewer` (R)                  |  [x]  | Palettes for cartography and data visualization in R                  | `Install-RPackages.ps1`                                 |
|                                   | `ggthemes` (R)                      |  [x]  | Additional themes for ggplot2                                         | `Install-RPackages.ps1`                                 |
|                                   | `cowplot` (R)                       |  [x]  | Helpers for ggplot2, arranging plots                                  | `Install-RPackages.ps1`                                 |
| **IX. Workflow & Automation**   |                                     |       |                                                                       |                                                         |
|                                   | Task Scheduler (Windows)            |  [N/A] | Scheduling automated scripts locally                                  | OS built-in (configure manually/programmatically)     |
|                                   | `dvc` (Data Version Control)        |  [ ]  | Version control for large datasets and ML models, complements Git     | `pip install dvc[all]`                                  |
|                                   | Apache Airflow / Prefect / Dagster  |  [ ]  | Workflow orchestration (for complex, scheduled research pipelines)    | `pip install ...` (advanced setup)                    |
| **X. Utility & Convenience**    |                                     |       |                                                                       |                                                         |
|                                   | 7-Zip                               |  [x]  | File archiver and compressor                                          | `choco install 7zip`                                    |
|                                   | draw.io Desktop (diagrams.net)      |  [x]  | Diagramming tool for workflows, conceptual models                     | `choco install drawio`                                  |
|                                   | `here` (R)                          |  [x]  | Robust path management in R scripts for portability                   | `Install-RPackages.ps1`                                 |
|                                   | `pathlib` (Python)                  |  [x]  | Object-oriented filesystem paths (Python built-in)                    | Python Standard Library                                 |
|                                   | `fs` (R)                            |  [x]  | File system operations for R                                          | `Install-RPackages.ps1`                                 |
|                                   | Notepad++                           |  [ ]  | Advanced lightweight text editor                                      | `choco install notepadplusplus`                         |
|                                   | SumatraPDF / Adobe Reader           |  [ ]  | PDF viewing                                                           | `choco install sumatrapdf` / `adobereader`              |
|                                   | `devtools` (R)                      |  [x]  | Tools for R package development (useful for GitHub installs)        | `Install-RPackages.ps1`                                 |
|                                   | `summarytools` (R)                  |  [x]  | Quick and comprehensive summary statistics in R                       | `Install-RPackages.ps1`                                 |
|                                   | `janitor` (R)                       |  [x]  | Simple data cleaning functions for R                                  | `Install-RPackages.ps1`                                 |

|                                   | `skimr` (R)                         |  [x]  | Compact and flexible summaries of data in R                           | `Install-RPackages.ps1`                                 |
