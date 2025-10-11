#!/usr/bin/env pwsh
<#
.SYNOPSIS
    CwAI (Code with AI) Installation Script for PowerShell

.DESCRIPTION
    Interactive installer that helps you set up Code with AI prompts and assets
    for your preferred AI client. Compatible with PowerShell 5.1+

.PARAMETER Help
    Show this help message

.EXAMPLE
    .\install.ps1
    Run the interactive installation

.EXAMPLE
    .\install.ps1 -Help
    Display help information

.NOTES
    Script must be run from the code-with-ai project root directory
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Help
)

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script constants
$script:ScriptName = $MyInvocation.MyCommand.Name
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Color constants for output formatting (using Write-Host colors)
$script:ColorInfo = "Cyan"
$script:ColorWarn = "Yellow"
$script:ColorError = "Red"
$script:ColorSuccess = "Green"
$script:ColorLogo = "Blue"

# Global variables
$script:SelectedAIClient = ""
$script:InstallType = ""
$script:TargetPath = ""
$script:CwaiSourceDir = Join-Path $script:ScriptDir ".cwai"

#region Logging Functions

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor $script:ColorInfo -NoNewline
    Write-Host $Message
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[WARN] " -ForegroundColor $script:ColorWarn -NoNewline
    Write-Host $Message
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor $script:ColorError -NoNewline
    Write-Host $Message
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor $script:ColorSuccess -NoNewline
    Write-Host $Message
}

#endregion

#region Display Functions

function Show-Logo {
    Write-Host @"
   _____                _____
  / ____|           _  |_   _|
 | |     __      _ / \   | |
 | |     \ \ /\ / / / \  | |
 | |____  \ V  V / ____\_| |_
  \_____|  \_/\_/_/    \_____/

            C w A I
          Code with AI

"@ -ForegroundColor $script:ColorLogo
}

function Show-Usage {
    Write-Host @"
Code with AI (CwAI) Installation Script

Usage: $script:ScriptName [options]

Options:
  -Help           Show this help message

This interactive installer will guide you through:
1. Selecting your AI client
2. Choosing installation type (local/global)
3. Setting installation path
4. Handling existing installations
5. Installing CwAI prompts and assets
"@
}

#endregion

#region System Validation Functions

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    if ($version.Major -lt 5) {
        Write-LogError "PowerShell 5.0 or newer is required. Current version: $version"
        exit 1
    }
    Write-LogInfo "PowerShell version $version detected - OK"
}

function Test-CommandExists {
    param([string]$CommandName)
    
    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if (-not $command) {
        Write-LogError "Required command '$CommandName' not found"
        exit 1
    }
}

function Test-Dependencies {
    Write-LogInfo "Checking system dependencies..."
    # PowerShell has built-in cmdlets for file operations, so no external dependencies needed
    Write-LogInfo "All dependencies satisfied"
}

#endregion

#region Path Functions

function Get-AbsolutePath {
    param([string]$Path)
    
    # Expand environment variables
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
    
    # Handle ~ for home directory
    if ($expandedPath -like "~*") {
        $expandedPath = $expandedPath -replace "^~", $env:USERPROFILE
    }
    
    # Convert to absolute path
    if (Test-Path $expandedPath) {
        return (Resolve-Path $expandedPath).Path
    }
    elseif ([System.IO.Path]::IsPathRooted($expandedPath)) {
        return $expandedPath
    }
    else {
        return Join-Path (Get-Location).Path $expandedPath
    }
}

function Test-PathExists {
    param(
        [string]$Path,
        [string]$PathType
    )
    
    if (-not (Test-Path $Path)) {
        Write-LogError "$PathType path does not exist: $Path"
        return $false
    }
    
    if (-not (Test-Path $Path -PathType Container)) {
        Write-LogError "$PathType path is not a directory: $Path"
        return $false
    }
    
    return $true
}

#endregion

#region AI Client Selection Functions

function Select-AIClient {
    Write-Host ""
    Write-Host "What AI Client do you want to install CwAI for?"
    Write-Host "  1) VSCode Copilot"
    Write-Host "  2) Claude"
    Write-Host "  3) Gemini"
    
    while ($true) {
        $choice = Read-Host "Enter your choice (1-3)"
        
        switch ($choice) {
            "1" {
                $script:SelectedAIClient = "VSCode Copilot"
                break
            }
            "2" {
                $script:SelectedAIClient = "Claude"
                break
            }
            "3" {
                $script:SelectedAIClient = "Gemini"
                break
            }
            default {
                Write-LogWarn "Invalid choice. Please enter 1, 2, or 3."
                continue
            }
        }
        break
    }
    
    Write-LogInfo "Selected AI Client: $script:SelectedAIClient"
}

function Test-AIClientSupportsMultiplePaths {
    param([string]$Client)
    
    return $Client -in @("VSCode Copilot", "Claude", "Gemini")
}

function Select-InstallType {
    param([string]$Client)
    
    if (Test-AIClientSupportsMultiplePaths $Client) {
        Write-Host ""
        Write-Host "How do you want to install CwAI?"
        Write-Host "  1) Locally (in project)"
        Write-Host "  2) Globally"
        
        while ($true) {
            $choice = Read-Host "Enter your choice (1-2)"
            
            switch ($choice) {
                "1" {
                    $script:InstallType = "local"
                    break
                }
                "2" {
                    $script:InstallType = "global"
                    break
                }
                default {
                    Write-LogWarn "Invalid choice. Please enter 1 or 2."
                    continue
                }
            }
            break
        }
    }
    else {
        $script:InstallType = "global"
        Write-LogInfo "Install type set to: $script:InstallType (only option for $Client)"
    }
}

#endregion

#region Path Determination Functions

function Get-ProjectPath {
    while ($true) {
        Write-Host ""
        $projectPath = Read-Host "Please provide the path to the project"
        
        if ([string]::IsNullOrWhiteSpace($projectPath)) {
            Write-LogWarn "Path cannot be empty. Please try again."
            continue
        }
        
        $projectPath = Get-AbsolutePath $projectPath
        
        if (Test-PathExists $projectPath "Project") {
            $script:TargetPath = $projectPath
            Write-LogInfo "Project path: $script:TargetPath"
            break
        }
        
        Write-LogWarn "Please provide a valid existing directory path."
    }
}

function Get-GlobalInstallPath {
    param([string]$Client)
    
    $installPath = ""
    
    switch ($Client) {
        "VSCode Copilot" {
            if ($IsWindows -or $env:OS -match "Windows") {
                $installPath = Join-Path $env:APPDATA "Code\User\globalStorage\github.copilot"
            }
            elseif ($IsMacOS) {
                $installPath = Join-Path $env:HOME "Library/Application Support/Code/User/globalStorage/github.copilot"
            }
            else {
                $installPath = Join-Path $env:HOME ".vscode/extensions/github.copilot"
            }
        }
        "Claude" {
            if ($IsWindows -or $env:OS -match "Windows") {
                $installPath = Join-Path $env:APPDATA "claude"
            }
            else {
                $installPath = Join-Path $env:HOME ".config/claude"
            }
        }
        "Gemini" {
            if ($IsWindows -or $env:OS -match "Windows") {
                $installPath = Join-Path $env:APPDATA "gemini"
            }
            else {
                $installPath = Join-Path $env:HOME ".config/gemini"
            }
        }
        default {
            Write-LogError "Unknown AI client: $Client"
            exit 1
        }
    }
    
    $script:TargetPath = $installPath
    Write-LogInfo "Global install path: $script:TargetPath"
}

#endregion

#region Installation Functions

function Test-ExistingInstallation {
    $existingPaths = @()
    
    # Check for client-specific installation paths
    switch ($script:SelectedAIClient) {
        "VSCode Copilot" {
            $promptsPath = Join-Path $script:TargetPath ".github\prompts"
            if (Test-Path $promptsPath) {
                $existingPaths += $promptsPath
            }
        }
        "Claude" {
            $promptsPath = Join-Path $script:TargetPath "prompts"
            if (Test-Path $promptsPath) {
                $existingPaths += $promptsPath
            }
        }
        "Gemini" {
            $templatesPath = Join-Path $script:TargetPath "templates"
            if (Test-Path $templatesPath) {
                $existingPaths += $templatesPath
            }
        }
    }
    
    # Also check for .cwai folder
    $cwaiPath = Join-Path $script:TargetPath ".cwai"
    if (Test-Path $cwaiPath) {
        $existingPaths += $cwaiPath
    }
    
    if ($existingPaths.Count -gt 0) {
        Write-Host ""
        Write-Host "Existing CwAI installation detected at:"
        foreach ($path in $existingPaths) {
            Write-Host "  - $path"
        }
        Write-Host "How should we proceed?"
        Write-Host "  1) Copy Over Existing"
        Write-Host "  2) Remove folders and copy again"
        
        while ($true) {
            $choice = Read-Host "Enter your choice (1-2)"
            
            switch ($choice) {
                "1" {
                    Write-LogInfo "Will copy over existing installation"
                    return
                }
                "2" {
                    Write-LogInfo "Will remove existing installation and copy again"
                    foreach ($path in $existingPaths) {
                        try {
                            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                            Write-LogInfo "Removed: $path"
                        }
                        catch {
                            Write-LogError "Failed to remove existing directory: $path"
                            Write-LogError $_.Exception.Message
                            exit 1
                        }
                    }
                    return
                }
                default {
                    Write-LogWarn "Invalid choice. Please enter 1 or 2."
                    continue
                }
            }
        }
    }
}

function Install-Prompts {
    $srcPrompts = Join-Path $script:CwaiSourceDir "prompts"
    
    if (-not (Test-Path $srcPrompts)) {
        Write-LogError "Source prompts directory not found: $srcPrompts"
        exit 1
    }
    
    switch ($script:SelectedAIClient) {
        "VSCode Copilot" {
            Install-VSCodePrompts $srcPrompts
        }
        "Claude" {
            Install-ClaudePrompts $srcPrompts
        }
        "Gemini" {
            Install-GeminiPrompts $srcPrompts
        }
        default {
            Write-LogError "Unknown AI client: $script:SelectedAIClient"
            exit 1
        }
    }
    
    Write-LogSuccess "Prompts installed successfully for $script:SelectedAIClient"
}

function Install-VSCodePrompts {
    param([string]$SrcPrompts)
    
    $destDir = Join-Path $script:TargetPath ".github\prompts"
    
    Write-LogInfo "Installing VSCode Copilot prompts to $destDir"
    
    # Create destination directory
    try {
        New-Item -Path $destDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-LogError "Failed to create VSCode prompts directory: $destDir"
        Write-LogError $_.Exception.Message
        exit 1
    }
    
    # Convert and copy each prompt file to .prompt.md format
    Get-ChildItem -Path $srcPrompts -Filter "*.md" -File | ForEach-Object {
        $baseName = $_.BaseName
        $destFile = Join-Path $destDir "$baseName.prompt.md"
        
        try {
            Copy-Item -Path $_.FullName -Destination $destFile -Force -ErrorAction Stop
            Write-LogInfo "Installed: $baseName.prompt.md"
        }
        catch {
            Write-LogError "Failed to copy prompt: $($_.FullName)"
            Write-LogError $_.Exception.Message
            exit 1
        }
    }
}

function Install-ClaudePrompts {
    param([string]$SrcPrompts)
    
    $destDir = Join-Path $script:TargetPath "prompts"
    
    Write-LogInfo "Installing Claude prompts to $destDir"
    
    # Create destination directory
    try {
        New-Item -Path $destDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-LogError "Failed to create Claude prompts directory: $destDir"
        Write-LogError $_.Exception.Message
        exit 1
    }
    
    # Copy prompt files
    Get-ChildItem -Path $srcPrompts -Filter "*.md" -File | ForEach-Object {
        $destFile = Join-Path $destDir $_.Name
        
        try {
            Copy-Item -Path $_.FullName -Destination $destFile -Force -ErrorAction Stop
            Write-LogInfo "Installed: $($_.Name)"
        }
        catch {
            Write-LogError "Failed to copy prompt: $($_.FullName)"
            Write-LogError $_.Exception.Message
            exit 1
        }
    }
}

function Install-GeminiPrompts {
    param([string]$SrcPrompts)
    
    $destDir = Join-Path $script:TargetPath "templates"
    
    Write-LogInfo "Installing Gemini prompts to $destDir"
    
    # Create destination directory
    try {
        New-Item -Path $destDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-LogError "Failed to create Gemini templates directory: $destDir"
        Write-LogError $_.Exception.Message
        exit 1
    }
    
    # Copy prompt files as templates
    Get-ChildItem -Path $srcPrompts -Filter "*.md" -File | ForEach-Object {
        $destFile = Join-Path $destDir $_.Name
        
        try {
            Copy-Item -Path $_.FullName -Destination $destFile -Force -ErrorAction Stop
            Write-LogInfo "Installed: $($_.Name)"
        }
        catch {
            Write-LogError "Failed to copy prompt: $($_.FullName)"
            Write-LogError $_.Exception.Message
            exit 1
        }
    }
}

function Install-CwaiFolder {
    $srcCwai = $script:CwaiSourceDir
    $destCwai = Join-Path $script:TargetPath ".cwai"
    
    if (-not (Test-Path $srcCwai)) {
        Write-LogError "Source .cwai directory not found: $srcCwai"
        exit 1
    }
    
    Write-LogInfo "Installing .cwai folder from $srcCwai to $destCwai"
    
    # Create target directory if it doesn't exist
    try {
        New-Item -Path $script:TargetPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-LogError "Failed to create target directory: $script:TargetPath"
        Write-LogError $_.Exception.Message
        exit 1
    }
    
    # Copy .cwai folder
    try {
        Copy-Item -Path $srcCwai -Destination $destCwai -Recurse -Force -ErrorAction Stop
        Write-LogSuccess ".cwai folder installed successfully"
    }
    catch {
        Write-LogError "Failed to copy .cwai folder"
        Write-LogError $_.Exception.Message
        exit 1
    }
}

#endregion

#region Main Function

function Invoke-Main {
    # Show help if requested
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Print the project logo using ASCII
    Show-Logo
    
    # Check PowerShell version
    Test-PowerShellVersion
    
    # Check system dependencies
    Test-Dependencies
    
    # Validate that source .cwai directory exists
    if (-not (Test-Path $script:CwaiSourceDir)) {
        Write-LogError "Source .cwai directory not found: $script:CwaiSourceDir"
        Write-LogError "Please run this script from the code-with-ai project root directory."
        exit 1
    }
    
    # Ask what AI Client the user wants to install CwAI for
    Select-AIClient
    
    # Ask user how they want to install CwAI if multiple paths supported
    Select-InstallType $script:SelectedAIClient
    
    # Get the target path based on install type
    if ($script:InstallType -eq "local") {
        # Ask user to provide the path to the project and validate it exists
        Get-ProjectPath
    }
    else {
        # Determine the global install path for the picked AI Client
        Get-GlobalInstallPath $script:SelectedAIClient
    }
    
    # Check if folders already exist and ask how to proceed
    Test-ExistingInstallation
    
    # Install prompts from .cwai/prompts as required for AI Client
    Install-Prompts
    
    # Copy .cwai folder to the target path for reference
    Install-CwaiFolder
    
    # Installation complete
    Write-Host ""
    Write-LogSuccess "CwAI installation completed successfully!"
    Write-Host ""
    Write-Host "Installation Summary:"
    Write-Host "  AI Client: $script:SelectedAIClient"
    Write-Host "  Install Type: $script:InstallType"
    Write-Host "  Target Path: $script:TargetPath"
    Write-Host "  CwAI Assets: $script:TargetPath\.cwai"
    
    # Show client-specific installation paths
    switch ($script:SelectedAIClient) {
        "VSCode Copilot" {
            Write-Host "  Prompts: $script:TargetPath\.github\prompts\*.prompt.md"
        }
        "Claude" {
            Write-Host "  Prompts: $script:TargetPath\prompts\*.md"
        }
        "Gemini" {
            Write-Host "  Templates: $script:TargetPath\templates\*.md"
        }
    }
    
    Write-Host ""
    Write-Host "You can now start using CwAI with your $script:SelectedAIClient!"
}

#endregion

# Execute main function
try {
    Invoke-Main
}
catch {
    Write-LogError "An unexpected error occurred: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    exit 1
}
