#Requires -Version 5.1
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create New Feature Script for CwAI

.DESCRIPTION
    Creates and updates feature branches, issues, and specification documents.
    Automates the workflow of setting up new features or updating existing ones
    with proper issue tracking and documentation templates.

.PARAMETER Requirement
    Feature requirement description (mandatory)

.PARAMETER Json
    Output results as JSON instead of key=value format

.PARAMETER Title
    Explicit title for the feature (auto-generated if not provided)

.PARAMETER Template
    Template(s) to copy (can be specified multiple times)

.PARAMETER Labels
    Label(s) to add to issue (can be specified multiple times, comma-separated)

.PARAMETER Help
    Display usage information

.EXAMPLE
    .\create-feature.ps1 "Users need to login securely" -Template "high-level-design" -Labels "authentication","security"

.EXAMPLE
    .\create-feature.ps1 "00012-user-authentication Add MFA support" -Template "low-level-design" -Labels "-development" -Json

.EXAMPLE
    .\create-feature.ps1 "Add user dashboard" -Title "User Dashboard Feature" -Template "prd","game-design"

.NOTES
    Requires PowerShell 5.1+
    Must be run from within a Git repository
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Requirement,
    
    [Parameter()]
    [switch]$Json,
    
    [Parameter()]
    [string]$Title = "",
    
    [Parameter()]
    [Alias("t")]
    [string[]]$Template = @(),
    
    [Parameter()]
    [Alias("l")]
    [string[]]$Labels = @(),
    
    [Parameter()]
    [switch]$Help
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Script Configuration

$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RepoRoot = Resolve-Path (Join-Path $script:ScriptDir "../..")
$script:TemplatesDir = Join-Path $script:RepoRoot ".cwai/templates/outline"

#endregion

#region Load Common Utilities

. (Join-Path $script:ScriptDir "common.ps1")
Load-Environment $script:RepoRoot.Path

if (-not $env:CWAI_SPECS_FOLDER) {
    Write-LogError "Environment variable CWAI_SPECS_FOLDER is required"
}
if (-not $env:CWAI_ISSUE_MANAGER) {
    Write-LogError "Environment variable CWAI_ISSUE_MANAGER is required"
}

#endregion

#region Functions

function Show-Usage {
    <#
    .SYNOPSIS
        Displays usage information
    #>
    
    $scriptName = Split-Path -Leaf $MyInvocation.ScriptName
    Write-Host @"
Usage: $scriptName <requirement> [OPTIONS]

Required arguments:
    <requirement>           Feature requirement description

Optional arguments:
  -Json                   Output data as JSON instead of text
  -Title <title>          Explicit title for the feature (auto-generated from requirement if not provided)
  -Template <name>        Template to copy (can be used multiple times)
  -t <name>               Short form of -Template
                          Available: product-requirement-document (prd), high-level-design (hld), 
                                    low-level-design (lld), game-design (game)
  -Labels <label>         Label to add to issue (comma separated, can be used multiple times)
  -l <label>              Short form of -Labels
                          Use -<label> to remove a label (e.g., -development)
  -Help                   Show this help message

Examples:
    $scriptName "Users need to login securely" -Template high-level-design -Labels authentication,security
    $scriptName "00012-user-authentication Add MFA support" -Template low-level-design -Labels -development -Json
    $scriptName "Add user dashboard" -Title "User Dashboard Feature" -Template product-requirement-document,game-design
"@
}

function Copy-Templates {
    <#
    .SYNOPSIS
        Copies template files to feature directory
    #>
    param(
        [string]$FeatureDir,
        [string[]]$RequestedTemplates
    )
    
    $copiedFiles = @()
    
    if ($RequestedTemplates.Count -eq 0) {
        Write-LogInfo "ℹ️  No templates specified. Only creating directory structure."
        return ""
    }
    
    foreach ($template in $RequestedTemplates) {
        $trimmedTemplate = $template.Trim()
        if (-not $trimmedTemplate) {
            continue
        }
        
        $sourcePath = Join-Path $script:TemplatesDir $trimmedTemplate
        if (-not (Test-Path $sourcePath) -and -not $trimmedTemplate.EndsWith('.md')) {
            $sourcePath = Join-Path $script:TemplatesDir "$trimmedTemplate.md"
        }
        
        if (-not (Test-Path $sourcePath)) {
            Write-LogWarn "Template '$trimmedTemplate' not found in $script:TemplatesDir"
            continue
        }
        
        New-Item -Path $FeatureDir -ItemType Directory -Force | Out-Null
        $destination = Join-Path $FeatureDir (Split-Path -Leaf $sourcePath)
        
        if (Test-Path $destination) {
            Write-LogWarn "Template '$(Split-Path -Leaf $destination)' already exists in ${FeatureDir}; skipping"
            continue
        }
        
        try {
            Copy-Item -Path $sourcePath -Destination $destination -Force
            $copiedFiles += (Split-Path -Leaf $sourcePath)
            Write-LogInfo "📄 Copied template: $(Split-Path -Leaf $sourcePath)"
        }
        catch {
            Write-LogWarn "Failed to copy template '$trimmedTemplate'"
        }
    }
    
    if ($copiedFiles.Count -eq 0) {
        return ""
    }
    
    return ($copiedFiles -join ',')
}

function Write-FeatureResults {
    <#
    .SYNOPSIS
        Formats and outputs feature results
    #>
    param(
        [string]$FeatureName,
        [string]$FeatureDir,
        [string]$CurrentBranch,
        [int]$FeatureId,
        [string]$Title,
        [string]$RequirementText,
        [bool]$OutputJson,
        [string]$CopiedFilesCsv
    )
    
    $copiedArray = if ($CopiedFilesCsv) {
        $CopiedFilesCsv.Split(',') | Where-Object { $_ }
    }
    else {
        @()
    }
    
    $result = @{
        BRANCH_NAME      = $CurrentBranch
        FEATURE_FOLDER   = $FeatureDir
        feature_id       = $FeatureId.ToString()
        TITLE            = $Title
        REQUIREMENT      = $RequirementText
        COPIED_TEMPLATES = $copiedArray
    }
    
    $jsonOutput = $result | ConvertTo-Json -Compress
    ConvertTo-Output $jsonOutput $OutputJson
}

function New-Feature {
    <#
    .SYNOPSIS
        Creates a new feature
    #>
    param(
        [string]$FeatureLabels,
        [string]$ExplicitTitle,
        [string]$FeatureBody
    )
    
    if (-not $FeatureBody) {
        $FeatureBody = "Unknown task requirement"
    }
    
    $featureTitle = if ($ExplicitTitle) {
        $ExplicitTitle
    }
    else {
        ConvertTo-Title $FeatureBody
    }
    
    $featureSlug = ConvertTo-Slug $featureTitle
    $featureParentDir = Join-Path $script:RepoRoot.Path $env:CWAI_SPECS_FOLDER
    New-Item -Path $featureParentDir -ItemType Directory -Force | Out-Null
    
    # Call issue manager dynamically
    $createFunction = "$($env:CWAI_ISSUE_MANAGER)_create_issue"
    if ($env:CWAI_ISSUE_MANAGER -eq "localfs") {
        $featureId = New-LocalIssue $featureSlug $featureTitle $featureParentDir $FeatureLabels $FeatureBody
    }
    elseif ($env:CWAI_ISSUE_MANAGER -eq "github") {
        $featureId = New-GitHubIssue $featureSlug $featureTitle $featureParentDir $FeatureLabels $FeatureBody
    }
    else {
        Write-LogError "Unknown issue manager: $($env:CWAI_ISSUE_MANAGER)"
    }
    
    $featurePaddedId = Format-FeatureId $featureId
    $featureName = "$featurePaddedId-$featureSlug"
    $featureDir = Join-Path $featureParentDir $featureName
    Write-LogInfo "🚀 Created feature: $featureName"
    
    # Create branch
    $gitOutput = git checkout -b $featureName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Failed to create branch $featureName"
    }
    Write-LogInfo "Created new branch: $featureName"
    
    # Copy templates
    $copiedFilesCsv = Copy-Templates $featureDir $Template
    
    # Output results
    Write-FeatureResults $featureName $featureDir $featureName $featureId `
        $featureTitle $FeatureBody $Json $copiedFilesCsv
}

function Update-Feature {
    <#
    .SYNOPSIS
        Updates an existing feature
    #>
    param(
        [string]$FeatureLabels,
        [string]$FeatureName,
        [string]$FeatureComment
    )
    
    if (-not $FeatureComment) {
        $FeatureComment = ""
    }
    
    $featureId = Get-FeatureId $FeatureName
    $featurePaddedId = Format-FeatureId $featureId
    $featureParentDir = Join-Path $script:RepoRoot.Path $env:CWAI_SPECS_FOLDER
    $featureDir = Join-Path $featureParentDir $FeatureName
    
    if (-not (Test-Path $featureDir)) {
        Write-LogError "Feature directory '$featureDir' not found"
    }
    
    # Checkout branch
    $gitOutput = git checkout $FeatureName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-LogError "Failed to switch to branch $FeatureName"
    }
    
    if (-not $featureId -or $featureId -eq 0) {
        Write-LogError "Could not determine issue from branch '$FeatureName'"
    }
    
    # Call issue manager dynamically
    if ($env:CWAI_ISSUE_MANAGER -eq "localfs") {
        Update-LocalIssue $featureId $FeatureName $featureDir $FeatureLabels $FeatureComment
    }
    elseif ($env:CWAI_ISSUE_MANAGER -eq "github") {
        Update-GitHubIssue $featureId $FeatureName $featureDir $FeatureLabels $FeatureComment
    }
    else {
        Write-LogError "Unknown issue manager: $($env:CWAI_ISSUE_MANAGER)"
    }
    
    # Copy templates
    $copiedFilesCsv = Copy-Templates $featureDir $Template
    
    # Get title from issue.json
    $featureTitle = ""
    $issueFile = Join-Path $featureDir "issue.json"
    if (Test-Path $issueFile) {
        $issue = Get-Content $issueFile -Raw | ConvertFrom-Json
        $featureTitle = $issue.title
    }
    if (-not $featureTitle) {
        $featureTitle = $FeatureName
    }
    
    # Output results
    Write-FeatureResults $FeatureName $featureDir $FeatureName $featureId `
        $featureTitle $FeatureComment $Json $copiedFilesCsv
}

#endregion

#region Main Execution

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Parse requirement
$requirementText = if ($Requirement) {
    $Requirement -join ' '
}
else {
    ""
}

if (-not $requirementText) {
    Write-LogError "Requirement is required. Provide the requirement as arguments."
}

# Parse labels (handle both comma-separated and multiple parameters)
$labelEntries = @()
foreach ($label in $Labels) {
    if ($label.Contains(',')) {
        $labelEntries += $label.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    else {
        $labelEntries += $label.Trim()
    }
}
$labelsCsv = if ($labelEntries.Count -gt 0) {
    $labelEntries -join ','
}
else {
    ""
}

# Detect existing feature or create new
$featureName = Find-FeatureName $requirementText

if ($featureName) {
    Write-LogInfo "Detected existing feature reference: $featureName"
    Update-Feature $labelsCsv $featureName $requirementText
}
else {
    Write-LogInfo "No existing feature reference found; creating new feature"
    New-Feature $labelsCsv $Title $requirementText
}

#endregion
