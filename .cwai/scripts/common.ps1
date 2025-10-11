#Requires -Version 5.1
<#
.SYNOPSIS
    Common utilities for CwAI (Code with AI) project

.DESCRIPTION
    Provides logging, string manipulation, array operations, Git integration,
    and issue management utilities for both local filesystem and GitHub.

.NOTES
    This script is designed to be dot-sourced by other PowerShell scripts.
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Prevent multiple sourcing
if ($Global:_COMMON_SOURCED) {
    return
}
$Global:_COMMON_SOURCED = $true

#region Environment Variables

$script:CWAI_SPECS_FOLDER = if ($env:CWAI_SPECS_FOLDER) { $env:CWAI_SPECS_FOLDER } else { "specs" }
$script:CWAI_ISSUE_MANAGER = if ($env:CWAI_ISSUE_MANAGER) { $env:CWAI_ISSUE_MANAGER } else { "localfs" }

#endregion

#region Logging Constants

$script:LOG_COLOR_BLUE = "Blue"
$script:LOG_COLOR_RED = "Red"
$script:LOG_COLOR_GREEN = "Green"
$script:LOG_COLOR_YELLOW = "Yellow"
$script:LOG_PREFIX = "λ"

#endregion

#region Environment Management

function Load-Environment {
    <#
    .SYNOPSIS
        Loads environment variables from .env and .env.local files
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )
    
    if ($Global:_ENV_LOADED) {
        return
    }
    $Global:_ENV_LOADED = $true
    
    if (-not $RepoRoot) {
        Write-LogError "Repository root path is required"
    }
    
    $envFiles = @(
        (Join-Path $RepoRoot ".env"),
        (Join-Path $RepoRoot ".env.local")
    )
    
    foreach ($envFile in $envFiles) {
        if (Test-Path $envFile) {
            Write-LogInfo "Loading environment from: $envFile"
            Get-Content $envFile | ForEach-Object {
                $line = $_.Trim()
                if ($line -and -not $line.StartsWith('#')) {
                    if ($line -match '^([^=]+)=(.*)$') {
                        $name = $matches[1].Trim()
                        $value = $matches[2].Trim()
                        # Remove quotes if present
                        $value = $value -replace '^["'']|["'']$', ''
                        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
                    }
                }
            }
        }
    }
}

#endregion

#region Logging Functions

function Write-LogDebug {
    <#
    .SYNOPSIS
        Logs debug messages (only when DEBUG is set)
    #>
    param([string]$Message)
    
    if ($env:DEBUG) {
        Write-Host "$script:LOG_PREFIX DEBUG " -ForegroundColor $script:LOG_COLOR_BLUE -NoNewline
        Write-Host $Message
    }
}

function Write-LogInfo {
    <#
    .SYNOPSIS
        Logs informational messages
    #>
    param([string]$Message)
    
    Write-Host "$script:LOG_PREFIX INFO " -ForegroundColor $script:LOG_COLOR_GREEN -NoNewline
    Write-Host $Message
}

function Write-LogWarn {
    <#
    .SYNOPSIS
        Logs warning messages
    #>
    param([string]$Message)
    
    Write-Host "$script:LOG_PREFIX WARN " -ForegroundColor $script:LOG_COLOR_YELLOW -NoNewline
    Write-Host $Message
}

function Write-LogError {
    <#
    .SYNOPSIS
        Logs error messages and exits
    #>
    param(
        [string]$Message,
        [int]$ExitCode = 1
    )
    
    Write-Host "$script:LOG_PREFIX ERROR " -ForegroundColor $script:LOG_COLOR_RED -NoNewline
    Write-Host $Message
    exit $ExitCode
}

#endregion

#region Array Utilities

function Join-ByComma {
    <#
    .SYNOPSIS
        Joins array elements with commas
    #>
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Items
    )
    
    return ($Items -join ',')
}

function ConvertTo-Array {
    <#
    .SYNOPSIS
        Splits a comma-separated string into an array
    #>
    param([string]$Input)
    
    if ([string]::IsNullOrWhiteSpace($Input)) {
        return @()
    }
    
    return $Input.Split(',') | Where-Object { $_ }
}

function Merge-Arrays {
    <#
    .SYNOPSIS
        Merges two comma-separated arrays with deduplication and removal support
    #>
    param(
        [string]$Array1String,
        [string]$Array2String
    )
    
    $removeSet = @{}
    $seenSet = @{}
    $outList = @()
    
    $array1 = ConvertTo-Array $Array1String
    $array2 = ConvertTo-Array $Array2String
    
    # Build removal set
    foreach ($item in $array2) {
        if ($item.StartsWith('-') -and $item.Length -gt 1) {
            $removeSet[$item.Substring(1)] = $true
        }
    }
    
    # Process array1
    foreach ($item in $array1) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            continue
        }
        if ($removeSet.ContainsKey($item) -or $seenSet.ContainsKey($item)) {
            continue
        }
        $seenSet[$item] = $true
        $outList += $item
    }
    
    # Process array2 (additions only)
    foreach ($item in $array2) {
        if ([string]::IsNullOrWhiteSpace($item) -or $item.StartsWith('-')) {
            continue
        }
        if ($removeSet.ContainsKey($item) -or $seenSet.ContainsKey($item)) {
            continue
        }
        $seenSet[$item] = $true
        $outList += $item
    }
    
    if ($outList.Count -eq 0) {
        return ""
    }
    
    return ($outList -join ',')
}

#endregion

#region String Utilities

function ConvertTo-Title {
    <#
    .SYNOPSIS
        Converts requirement to title (first 5 words)
    #>
    param([string]$Requirement)
    
    $cleaned = $Requirement -replace '[^A-Za-z0-9_\-]', ' '
    $words = $cleaned -split '\s+' | Where-Object { $_ } | Select-Object -First 5
    return ($words -join ' ')
}

function ConvertTo-Slug {
    <#
    .SYNOPSIS
        Converts title to URL-friendly slug
    #>
    param([string]$Title)
    
    $slug = $Title.ToLower() -replace '[^a-z0-9]', '-'
    $slug = $slug -replace '-{2,}', '-'
    $slug = $slug -replace '^-|-$', ''
    return $slug
}

function Format-FeatureId {
    <#
    .SYNOPSIS
        Pads feature ID to 5 digits
    #>
    param([int]$Id)
    
    return "{0:D5}" -f $Id
}

function Find-FeatureName {
    <#
    .SYNOPSIS
        Detects feature branch pattern in text
    #>
    param([string]$Text)
    
    if ($Text -match '(\d{5}-[a-z0-9][a-z0-9\-]*)') {
        $featureName = $matches[1]
        if (Test-GitBranchExists $featureName) {
            return $featureName
        }
    }
    
    return ""
}

function Get-FeatureId {
    <#
    .SYNOPSIS
        Extracts feature ID from feature name
    #>
    param([string]$FeatureName)
    
    if ($FeatureName -match '^(\d{5})') {
        $id = [int]$matches[1]
        return $id
    }
    
    return 0
}

function ConvertTo-Output {
    <#
    .SYNOPSIS
        Formats output as JSON or key=value
    #>
    param(
        [string]$JsonResult,
        [bool]$OutputJson
    )
    
    if ($OutputJson) {
        Write-Output $JsonResult
        return
    }
    
    $obj = $JsonResult | ConvertFrom-Json
    foreach ($prop in $obj.PSObject.Properties) {
        $value = $prop.Value
        if ($value -is [array]) {
            $value = $value -join ','
        }
        elseif ($value -is [PSCustomObject]) {
            $value = $value | ConvertTo-Json -Compress
        }
        Write-Output "$($prop.Name)=`"$value`""
    }
}

function New-HexColor {
    <#
    .SYNOPSIS
        Generates random 6-character hex color
    #>
    
    $bytes = New-Object byte[] 3
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $rng.GetBytes($bytes)
    $rng.Dispose()
    
    return ($bytes | ForEach-Object { $_.ToString("X2") }) -join ''
}

#endregion

#region Git Functions

function Test-GitBranchExists {
    <#
    .SYNOPSIS
        Checks if Git branch exists
    #>
    param([string]$Branch)
    
    $localExists = git rev-parse --verify --quiet "refs/heads/$Branch" 2>$null
    if ($LASTEXITCODE -eq 0) {
        return $true
    }
    
    $remoteExists = git rev-parse --verify --quiet "refs/remotes/origin/$Branch" 2>$null
    if ($LASTEXITCODE -eq 0) {
        return $true
    }
    
    return $false
}

function Get-GitAuthor {
    <#
    .SYNOPSIS
        Gets Git author name and email
    #>
    
    $name = git config --get user.name
    $email = git config --get user.email
    return "$name <$email>"
}

#endregion

#region Local Filesystem Issue Manager

function New-LocalIssue {
    <#
    .SYNOPSIS
        Creates a new local filesystem issue
    #>
    param(
        [string]$FeatureSlug,
        [string]$FeatureTitle,
        [string]$FeatureParentDir,
        [string]$FeatureLabels,
        [string]$FeatureBody
    )
    
    $featureId = if ($env:LOCALFS_FEATURE_ID) {
        [int]$env:LOCALFS_FEATURE_ID
    }
    else {
        $existingDirs = @()
        if (Test-Path $env:CWAI_SPECS_FOLDER) {
            $existingDirs = Get-ChildItem -Path $env:CWAI_SPECS_FOLDER -Directory
        }
        $existingDirs.Count + 1
    }
    
    $featurePaddedId = Format-FeatureId $featureId
    $featureDir = Join-Path $FeatureParentDir "$featurePaddedId-$FeatureSlug"
    New-Item -Path $featureDir -ItemType Directory -Force | Out-Null
    
    $now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
    $author = Get-GitAuthor
    $labelsArray = if ($FeatureLabels) {
        ConvertTo-Array $FeatureLabels
    }
    else {
        @()
    }
    
    $issue = @{
        author      = $author
        id          = $featureId
        title       = $FeatureTitle
        description = $FeatureBody
        labels      = $labelsArray
        created_at  = $now
        updated_at  = $now
        comments    = @()
    }
    
    $issueJson = $issue | ConvertTo-Json -Depth 10
    $issueJson | Out-File -FilePath (Join-Path $featureDir "issue.json") -Encoding UTF8
    
    if (-not $featureId -or $featureId -eq 0) {
        Write-LogError "Failed to create issue."
    }
    
    Write-LogInfo "✅ Created Local issue (#$featureId) $FeatureTitle"
    return $featureId
}

function Update-LocalIssue {
    <#
    .SYNOPSIS
        Updates an existing local filesystem issue
    #>
    param(
        [int]$FeatureId,
        [string]$FeatureName,
        [string]$FeatureDir,
        [string]$FeatureLabels,
        [string]$FeatureComment
    )
    
    $issueFile = Join-Path $FeatureDir "issue.json"
    $issue = Get-Content $issueFile -Raw | ConvertFrom-Json
    
    $now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC
    $author = Get-GitAuthor
    $sanitizedComment = $FeatureComment -replace [regex]::Escape($FeatureName), ''
    
    $comment = @{
        author     = $author
        comment    = $sanitizedComment
        created_at = $now
    }
    
    # Merge labels
    $existingLabels = if ($issue.labels) { ($issue.labels -join ',') } else { "" }
    $updatedLabels = Merge-Arrays $existingLabels $FeatureLabels
    
    # Update issue
    $issue.comments = @($issue.comments) + $comment
    $issue.labels = if ($updatedLabels) { ConvertTo-Array $updatedLabels } else { @() }
    $issue.updated_at = $now
    
    $issue | ConvertTo-Json -Depth 10 | Out-File -FilePath $issueFile -Encoding UTF8
    
    Write-LogInfo "💬 Updated Local issue (#$FeatureId) $FeatureName"
}

#endregion

#region GitHub Issue Manager

function New-GitHubLabel {
    <#
    .SYNOPSIS
        Creates a GitHub label if it doesn't exist
    #>
    param(
        [string]$LabelName,
        [string]$LabelColor = "",
        [string]$LabelDescription = ""
    )
    
    if (-not $LabelColor) {
        $LabelColor = New-HexColor
    }
    
    $existingLabels = gh label list --json name --jq '.[].name' 2>$null
    if ($existingLabels -contains $LabelName) {
        return
    }
    
    Write-LogInfo "🏷️ Creating label: $LabelName"
    if ($LabelDescription) {
        gh label create $LabelName --color $LabelColor --description $LabelDescription 2>$null | Out-Null
    }
    else {
        gh label create $LabelName --color $LabelColor 2>$null | Out-Null
    }
}

function New-GitHubIssue {
    <#
    .SYNOPSIS
        Creates a GitHub issue and local issue
    #>
    param(
        [string]$FeatureSlug,
        [string]$FeatureTitle,
        [string]$FeatureParentDir,
        [string]$FeatureLabels,
        [string]$FeatureBody
    )
    
    # Ensure default labels
    New-GitHubLabel "task" "0e8a16" "Task item"
    New-GitHubLabel "auto-generated" "bfd4f2" "Automatically generated by script"
    
    $labelArgs = @("--label", "task", "--label", "auto-generated")
    
    if ($FeatureLabels) {
        $extraLabels = ConvertTo-Array $FeatureLabels
        foreach ($label in $extraLabels) {
            if ($label) {
                New-GitHubLabel $label
                $labelArgs += @("--label", $label)
            }
        }
    }
    
    $issueUrl = gh issue create --title $FeatureTitle --body $FeatureBody @labelArgs
    Write-LogInfo "🏷️ Created Github issue: $issueUrl"
    
    $featureId = [int]($issueUrl -split '/')[-1]
    $env:LOCALFS_FEATURE_ID = $featureId
    $localId = New-LocalIssue $FeatureSlug $FeatureTitle $FeatureParentDir $FeatureLabels $FeatureBody
    Remove-Item Env:\LOCALFS_FEATURE_ID -ErrorAction SilentlyContinue
    
    return $featureId
}

function Update-GitHubIssue {
    <#
    .SYNOPSIS
        Updates a GitHub issue and local issue
    #>
    param(
        [int]$FeatureId,
        [string]$FeatureName,
        [string]$FeatureDir,
        [string]$FeatureLabels,
        [string]$FeatureComment
    )
    
    $addLabels = @()
    $removeLabels = @()
    
    if ($FeatureLabels) {
        $labels = ConvertTo-Array $FeatureLabels
        foreach ($label in $labels) {
            if (-not $label) {
                continue
            }
            if ($label.StartsWith('-')) {
                $removeLabels += $label.Substring(1)
            }
            else {
                $addLabels += $label
                New-GitHubLabel $label
            }
        }
    }
    
    if ($addLabels.Count -gt 0) {
        $addLabelsCsv = $addLabels -join ','
        gh issue edit $FeatureId --add-label $addLabelsCsv 2>&1 | Out-Null
        Write-LogInfo "🏷️ Added labels to issue #${FeatureId}: $($addLabels -join ', ')"
    }
    
    if ($removeLabels.Count -gt 0) {
        $removeLabelsCsv = $removeLabels -join ','
        gh issue edit $FeatureId --remove-label $removeLabelsCsv 2>&1 | Out-Null
        Write-LogInfo "🏷️ Removed labels from issue #${FeatureId}: $($removeLabels -join ', ')"
    }
    
    gh issue comment $FeatureId --body $FeatureComment 2>$null | Out-Null
    Write-LogInfo "💬 Added comment to Github issue #$FeatureId"
    
    Update-LocalIssue $FeatureId $FeatureName $FeatureDir $FeatureLabels $FeatureComment
}

#endregion

# Export functions (PowerShell doesn't need explicit exports, but this documents what's available)
Export-ModuleMember -Function *
