# CwAI (Code with AI) Installation Guide

## Overview

The CwAI installation script is an interactive installer that helps you set up Code with AI prompts and assets for your preferred AI client. The script guides you through a series of questions to customize the installation to your needs.

## What the Script Does

### 1. Initial Setup and Validation

The script begins by:

- Displaying the CwAI logo in ASCII art:

  ```text
     _____                _____
    / ____|           _  |_   _|
   | |     __      _ / \   | |
   | |     \ \ /\ / / / \  | |
   | |____  \ V  V / ____\_| |_
    \_____|  \_/\_/_/    \_____/

              C w A I
            Code with AI
  ```

- Checking that your system meets the minimum requirements
- Verifying that required system commands are available
- Confirming that the source `.cwai` directory exists in the project root

### 2. AI Client Selection

The script asks you which AI client you want to install CwAI for:

1. **VSCode Copilot**
2. **Claude**
3. **Gemini**

You enter a number between 1 and 3 to make your selection. The script will repeat the prompt until you provide a valid choice.

### 3. Installation Type Selection

Depending on your chosen AI client, the script asks how you want to install CwAI:

1. **Locally (in project)** - Installs CwAI in a specific project directory
2. **Globally** - Installs CwAI system-wide for the AI client

All three supported clients (VSCode Copilot, Claude, and Gemini) support both local and global installation.

### 4. Target Path Determination

#### For Local Installation

- The script prompts you to provide the path to your project
- It validates that the path exists and is a directory
- It converts the path to an absolute path (expanding `~` and relative paths)
- It keeps asking until you provide a valid directory path

#### For Global Installation

The script automatically determines the global install path based on your AI client and operating system. Each AI client has a standard configuration directory where global settings and prompts are stored.

### 5. Handling Existing Installations

If the script detects an existing CwAI installation at the target path, it asks how to proceed:

1. **Copy Over Existing** - Merges new files with existing ones (overwrites files with same names)
2. **Remove folders and copy again** - Completely removes existing installation directories before copying new files

The script checks for these client-specific paths:

- **VSCode Copilot**: `.github/prompts` directory
- **Claude**: `prompts` directory
- **Gemini**: `templates` directory
- All clients: `.cwai` folder

If you choose option 2, the script will remove all detected existing paths before proceeding.

### 6. Installing Prompts

The script installs prompt files from `.cwai/prompts` according to each AI client's requirements:

#### VSCode Copilot

- Creates a `.github/prompts` directory in the target path
- Copies each `.md` file from source prompts and renames them to `.prompt.md` format
- Example: `implement.md` becomes `implement.prompt.md`

#### Claude

- Creates a `prompts` directory in the target path
- Copies all `.md` files from source prompts directly (no renaming)

#### Gemini

- Creates a `templates` directory in the target path
- Copies all `.md` files from source prompts as templates

### 7. Installing CwAI Assets

The script copies the entire `.cwai` folder to the target path for reference, creating the target directory structure if it doesn't exist.

### 8. Installation Complete

Once finished, the script displays a success message with a summary showing:

- The AI client you selected
- The installation type (local or global)
- The target path where files were installed
- The location of CwAI assets
- The location of prompts/templates specific to your AI client

## Usage

### Basic Usage

Run the installation script from the code-with-ai project root directory.

### Getting Help

To see usage information, run the script with the `--help` or `-h` flag.

## Requirements

- A compatible shell environment for running the installation script
- Standard file system commands for copying and creating directories
- The `.cwai` source directory must exist in the project root

## Error Handling

The script handles errors gracefully and will:

- Exit with an error if system requirements are not met
- Exit if required system commands are missing
- Exit if the source `.cwai` directory is not found
- Validate all user inputs and prompt again for invalid choices
- Show clear error messages with suggestions on how to fix issues

## Color-Coded Output

The script uses color-coded messages for better readability:

- **Cyan** - Informational messages
- **Yellow** - Warning messages
- **Red** - Error messages
- **Green** - Success messages
- **Blue** - Logo and decorative elements

## Example Installation Flow

1. Script displays the CwAI logo
2. Script checks system requirements and dependencies
3. You select "VSCode Copilot" (option 1)
4. You select "Locally (in project)" (option 1)
5. You provide the path to your project directory
6. Script validates the path exists
7. Script detects no existing installation
8. Script creates `.github/prompts` directory
9. Script copies and renames prompt files to `.prompt.md` format
10. Script copies `.cwai` folder to project root
11. Script displays success summary with all installation paths

## Notes

- The script must be run from the code-with-ai project root directory
- All paths are converted to absolute paths internally
- The script uses safe practices to catch errors early and exit cleanly
- User inputs are validated before proceeding to the next step
- The installation process is idempotent - you can run it multiple times safely
