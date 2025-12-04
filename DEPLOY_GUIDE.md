# Azure Static Web Apps Deployment Guide

This guide helps you deploy agent-inbox to Azure Static Web Apps using the provided PowerShell script.

## Prerequisites

1. **Azure CLI** - Install from https://learn.microsoft.com/cli/azure/
2. **GitHub CLI** - Install from https://cli.github.com/
3. **PowerShell** - Version 5.0 or higher (Windows PowerShell or PowerShell Core)
4. **Azure Account** - With an active subscription
5. **GitHub Authentication** - Logged in via `gh auth login`

## Setup

### 1. Login to Azure
```powershell
az login
```

### 2. Login to GitHub (if not already)
```powershell
gh auth login
```

### 3. List Available Subscriptions (optional)
```powershell
az account list --output table
```

## Usage

### Basic Deployment (uses defaults)
```powershell
.\deploy-to-azure.ps1 -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"
```

This will create:
- Resource group: `agent-inbox-rg`
- Static Web App: `agent-inbox-swa`
- Region: `eastus`
- Auto-deploy from: `main` branch

### Custom Resource Group and App Names
```powershell
.\deploy-to-azure.ps1 `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox" `
  -ResourceGroupName "my-projects-rg" `
  -StaticWebAppName "my-inbox-app"
```

### Custom Region and Branch
```powershell
.\deploy-to-azure.ps1 `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox" `
  -Location "westeurope" `
  -GitHubBranch "staging"
```

### Specific Subscription
```powershell
.\deploy-to-azure.ps1 `
  -SubscriptionName "My Subscription" `
  -ResourceGroupName "prod-rg" `
  -StaticWebAppName "agent-inbox-prod" `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"
```

Or by subscription ID:
```powershell
.\deploy-to-azure.ps1 `
  -SubscriptionId "00000000-0000-0000-0000-000000000000" `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"
```

## Available Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `GitHubRepo` | *Required* | GitHub repository URL |
| `SubscriptionId` | Current | Azure subscription ID |
| `SubscriptionName` | Current | Azure subscription name |
| `ResourceGroupName` | `agent-inbox-rg` | Resource group name |
| `StaticWebAppName` | `agent-inbox-swa` | Static Web App name |
| `Location` | `eastus` | Azure region |
| `GitHubBranch` | `main` | Branch to deploy from |
| `AppLocation` | `.` | App folder during build |
| `AppBuildFolder` | `out` | Build output folder |
| `SkipPrerequisiteCheck` | False | Skip checking for tools |

## What the Script Does

1. **Checks Prerequisites** - Verifies Azure CLI, GitHub CLI, and authentication
2. **Sets Subscription** - Switches to specified subscription if provided
3. **Creates Resource Group** - Creates or verifies resource group exists
4. **Gets GitHub Token** - Retrieves token from `gh` CLI for private repos
5. **Creates Static Web App** - Sets up Static Web App with GitHub integration
6. **Configures Auto-Deploy** - Enables automatic builds on push to the branch

## After Deployment

Your Static Web App will:
- Automatically build when you push to the specified branch
- Deploy to a free-tier instance
- Get a public URL (shown after deployment)
- Include custom GitHub Actions workflow in your repo

### View Your App

```powershell
az staticwebapp show --name agent-inbox-swa --resource-group agent-inbox-rg
```

### Check Deployment Status

```powershell
az staticwebapp show --name agent-inbox-swa --resource-group agent-inbox-rg --query defaultHostname
```

## Supported Regions for Free Tier

Common regions (check [Azure docs](https://learn.microsoft.com/en-us/azure/static-web-apps/plans) for latest):
- `eastus`
- `westeurope`
- `westus2`
- `centralus`
- `southcentralus`

## Troubleshooting

### "Not logged into Azure"
```powershell
az login
```

### "GitHub CLI not authenticated"
```powershell
gh auth login
```

### "Failed to create Static Web App"
- Check resource group name is valid (lowercase, alphanumeric, hyphens)
- Check app name is valid (3-24 characters, lowercase)
- Verify GitHub token has `admin:repo_hook` and `repo` scopes
- Check region is available for Static Web Apps

### Rerun with Prerequisites Check Skipped
If you already verified tools are installed:
```powershell
.\deploy-to-azure.ps1 -GitHubRepo "..." -SkipPrerequisiteCheck
```

## Running Multiple Deployments

You can deploy multiple instances:
```powershell
# Staging environment
.\deploy-to-azure.ps1 `
  -ResourceGroupName "inbox-staging-rg" `
  -StaticWebAppName "inbox-staging" `
  -GitHubBranch "staging" `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"

# Production environment
.\deploy-to-azure.ps1 `
  -ResourceGroupName "inbox-prod-rg" `
  -StaticWebAppName "inbox-prod" `
  -GitHubBranch "main" `
  -GitHubRepo "https://github.com/gpi-renezander/agent-inbox"
```

## Script Features

✅ **Private Repository Support** - Uses authenticated GitHub token
✅ **Idempotent** - Safe to run multiple times
✅ **Colored Output** - Easy to read status messages
✅ **Error Handling** - Clear error messages with solutions
✅ **Free Tier** - Automatically uses free tier configuration
✅ **Auto-Deploy** - Continuous deployment from GitHub
✅ **Next.js Support** - Pre-configured for Next.js builds
