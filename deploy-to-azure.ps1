#Requires -Version 5.0
<#
.SYNOPSIS
    Deploys agent-inbox to Azure Static Web Apps using GitHub integration.

.PARAMETER SubscriptionId
    Azure subscription ID.

.PARAMETER SubscriptionName
    Azure subscription name.

.PARAMETER ResourceGroupName
    Resource group name. Default: 'agent-inbox-rg'

.PARAMETER StaticWebAppName
    Static Web App name. Default: 'agent-inbox-swa'

.PARAMETER Location
    Azure region. Default: 'eastus2'

.PARAMETER GitHubRepo
    GitHub repository URL (required)

.PARAMETER GitHubBranch
    Branch to deploy. Default: 'main'

.EXAMPLE
    .\deploy-to-azure.ps1 -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"
#>

param(
    [string]$SubscriptionId,
    [string]$SubscriptionName,
    [string]$ResourceGroupName = "agent-inbox-rg",
    [string]$StaticWebAppName = "agent-inbox-swa",
    [string]$Location = "eastus2",
    [Parameter(Mandatory)]
    [string]$GitHubRepo,
    [string]$GitHubBranch = "main",
    [string]$AppBuildFolder = "out",
    [string]$AppLocation = ".",
    [switch]$SkipPrerequisiteCheck
)

$Colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
}

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )
    $color = $Colors[$Level]
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline
    Write-Host $Message -ForegroundColor $color
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level Info

    try {
        $null = az --version 2>$null
        Write-Log "Azure CLI: OK" -Level Success
    }
    catch {
        Write-Log "Azure CLI not found. Install from: https://learn.microsoft.com/cli/azure/" -Level Error
        exit 1
    }

    try {
        $null = gh --version 2>$null
        Write-Log "GitHub CLI: OK" -Level Success
    }
    catch {
        Write-Log "GitHub CLI not found. Install from: https://cli.github.com/" -Level Error
        exit 1
    }

    try {
        $null = gh auth status 2>&1
        Write-Log "GitHub authentication: OK" -Level Success
    }
    catch {
        Write-Log "GitHub CLI not authenticated. Run: gh auth login" -Level Error
        exit 1
    }

    try {
        $account = az account show 2>$null | ConvertFrom-Json
        Write-Log "Azure authentication: OK (Logged in as: $($account.user.name))" -Level Success
    }
    catch {
        Write-Log "Not logged into Azure. Run: az login" -Level Error
        exit 1
    }
}

function Set-Subscription {
    if ($SubscriptionId) {
        Write-Log "Setting subscription by ID: $SubscriptionId" -Level Info
        az account set --subscription $SubscriptionId
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to set subscription by ID" -Level Error
            exit 1
        }
    }
    elseif ($SubscriptionName) {
        Write-Log "Setting subscription by name: $SubscriptionName" -Level Info
        az account set --subscription $SubscriptionName
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to set subscription by name" -Level Error
            exit 1
        }
    }
    else {
        $current = az account show 2>$null | ConvertFrom-Json
        Write-Log "Using current subscription: $($current.name)" -Level Info
    }
}

function New-ResourceGroup {
    param([string]$RgName, [string]$Loc)

    Write-Log "Checking resource group: $RgName" -Level Info

    $rg = az group exists --name $RgName

    if ($rg -eq "true") {
        Write-Log "Resource group already exists" -Level Success
    }
    else {
        Write-Log "Creating resource group: $RgName in $Loc" -Level Info
        az group create --name $RgName --location $Loc | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create resource group" -Level Error
            exit 1
        }
        Write-Log "Resource group created successfully" -Level Success
    }
}

function Get-GitHubToken {
    Write-Log "Retrieving GitHub token..." -Level Info

    try {
        $token = gh auth token 2>$null
        if (-not $token) {
            Write-Log "Failed to retrieve GitHub token" -Level Error
            exit 1
        }
        Write-Log "GitHub token retrieved successfully" -Level Success
        return $token
    }
    catch {
        Write-Log "Error retrieving GitHub token: $_" -Level Error
        exit 1
    }
}

function Parse-GitHubRepo {
    param([string]$Url)

    $url = $url -replace "\.git$", ""

    if ($url -match "github\.com[:/]([^/]+)/(.+)$") {
        return @{
            Owner = $matches[1]
            Name = $matches[2]
        }
    }
    else {
        Write-Log "Invalid GitHub repository URL: $url" -Level Error
        exit 1
    }
}

function New-StaticWebApp {
    param(
        [string]$RgName,
        [string]$SwaName,
        [string]$Loc,
        [string]$RepoUrl,
        [string]$Branch,
        [string]$Token,
        [string]$BuildFolder,
        [string]$AppLoc
    )

    Write-Log "Checking if Static Web App exists: $SwaName" -Level Info

    $swa = az staticwebapp show --name $SwaName --resource-group $RgName 2>$null

    if ($swa) {
        Write-Log "Static Web App already exists" -Level Success
        $repoInfo = Parse-GitHubRepo -Url $RepoUrl
        Write-Log "Repository: $($repoInfo.Owner)/$($repoInfo.Name) on branch '$Branch'" -Level Info
        return
    }

    Write-Log "Creating Static Web App: $SwaName" -Level Info
    $repoInfo = Parse-GitHubRepo -Url $RepoUrl

    $cmd = @(
        "staticwebapp", "create",
        "--name", $SwaName,
        "--resource-group", $RgName,
        "--location", $Loc,
        "--source", "https://github.com/$($repoInfo.Owner)/$($repoInfo.Name)",
        "--branch", $Branch,
        "--token", $Token,
        "--app-location", $AppLoc,
        "--output-location", $BuildFolder
    )

    az @cmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Failed to create Static Web App" -Level Error
        exit 1
    }

    Write-Log "Static Web App created successfully" -Level Success
}

function Show-DeploymentInfo {
    param([string]$RgName, [string]$SwaName)

    Write-Log "Retrieving deployment information..." -Level Info

    $swa = az staticwebapp show --name $SwaName --resource-group $RgName 2>$null | ConvertFrom-Json

    if ($swa) {
        Write-Log "=================================" -Level Info
        Write-Log "Deployment Complete!" -Level Success
        Write-Log "=================================" -Level Info
        Write-Log "Static Web App Name: $($swa.name)" -Level Info
        Write-Log "URL: $($swa.defaultHostname)" -Level Info
        Write-Log "Repository: $($swa.repositoryUrl)" -Level Info
        Write-Log "Branch: $($swa.branch)" -Level Info
        Write-Log "=================================" -Level Info
        Write-Log "Your app will be built and deployed automatically on push" -Level Success
    }
}

try {
    Write-Log "Starting Azure Static Web Apps deployment..." -Level Info
    Write-Log "=================================" -Level Info

    if (-not $SkipPrerequisiteCheck) {
        Test-Prerequisites
    }

    Set-Subscription
    New-ResourceGroup -RgName $ResourceGroupName -Loc $Location

    $token = Get-GitHubToken
    New-StaticWebApp -RgName $ResourceGroupName -SwaName $StaticWebAppName -Loc $Location `
        -RepoUrl $GitHubRepo -Branch $GitHubBranch -Token $token `
        -BuildFolder $AppBuildFolder -AppLoc $AppLocation

    Show-DeploymentInfo -RgName $ResourceGroupName -SwaName $StaticWebAppName

    Write-Log "Setup complete! Azure will now monitor your repository for changes." -Level Success
}
catch {
    Write-Log "Deployment failed: $_" -Level Error
    exit 1
}
