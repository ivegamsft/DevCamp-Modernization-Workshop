#Requires -Version 5.1
<#
.SYNOPSIS
  One-time bootstrap: Azure app registration, OIDC federated credential, RBAC, GitHub secrets.

.DESCRIPTION
  Prepares GitHub Actions to deploy infra/ and modern/dotnet/DevCamp.Api without client secrets.
  Requires Azure CLI (az) and GitHub CLI (gh). Run from a machine where you are Owner or
  User Access Administrator on the subscription/resource group.

.PARAMETER ConfigPath
  Path to bootstrap.config.json (copy from bootstrap.config.example.json).

.PARAMETER DryRun
  Print planned actions without creating or updating Azure/GitHub resources.

.EXAMPLE
  cd scripts\bootstrap
  Copy-Item bootstrap.config.example.json bootstrap.config.json
  # Edit bootstrap.config.json
  .\Bootstrap-AzureGitHub.ps1 -ConfigPath .\bootstrap.config.json
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string] $ConfigPath,

    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step([string] $Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Invoke-Checked {
    param([scriptblock] $Block, [string] $Label)
    if ($DryRun) {
        Write-Host "[DryRun] $Label" -ForegroundColor Yellow
        return
    }
    & $Block
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Label"
    }
}

function Get-AzCliJson([string[]] $AzArguments) {
    # Build argument list; always request JSON on stdout (never merge stderr into JSON text).
    $cmdArgs = [System.Collections.Generic.List[string]]::new()
    foreach ($a in $AzArguments) { [void]$cmdArgs.Add($a) }
    if ($AzArguments -notcontains '-o' -and $AzArguments -notcontains '--output') {
        [void]$cmdArgs.Add('-o')
        [void]$cmdArgs.Add('json')
    }

    $stdout = & az @cmdArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        $detail = (& az @cmdArgs 2>&1 | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "az $($cmdArgs -join ' ') failed: $detail"
    }

    if ($null -eq $stdout) { return $null }

    $jsonText = if ($stdout -is [string]) {
        $stdout
    } else {
        ($stdout | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.ToString() } }) -join [Environment]::NewLine
    }
    $jsonText = $jsonText.Trim()
    if ([string]::IsNullOrWhiteSpace($jsonText)) { return $null }

    return $jsonText | ConvertFrom-Json
}

# --- Load config ---
if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath. Copy bootstrap.config.example.json to bootstrap.config.json and edit."
}
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$subscriptionId = $config.subscriptionId
$resourceGroupName = $config.resourceGroupName
$location = $config.location
$githubOwner = $config.githubOwner
$githubRepo = $config.githubRepo
$githubBranch = $config.githubBranch
$githubEnvironment = $config.githubEnvironment
$appDisplayName = $config.appRegistrationDisplayName
$federatedName = $config.federatedCredentialName
$createRg = [bool]$config.createResourceGroup
$assignRgRoles = [bool]$config.assignResourceGroupRoles
$setGhSecrets = [bool]$config.setGitHubSecrets

if ([string]::IsNullOrWhiteSpace($subscriptionId)) {
    throw 'subscriptionId is required in config.'
}

# --- Tooling ---
Write-Step 'Checking Azure CLI and GitHub CLI'
Invoke-Checked { az version | Out-Null } 'az version'
if ($setGhSecrets) {
    Invoke-Checked { gh auth status | Out-Null } 'gh auth status'
}

Write-Step 'Azure login and subscription'
$account = Get-AzCliJson @('account', 'show')
if (-not $account) {
    throw 'Not logged in. Run: az login'
}
if ([string]::IsNullOrWhiteSpace($config.tenantId)) {
    $tenantId = $account.tenantId
} else {
    $tenantId = $config.tenantId
}
Invoke-Checked { az account set --subscription $subscriptionId | Out-Null } "az account set --subscription $subscriptionId"

$rgScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

# --- Resource group (optional) ---
if ($createRg) {
    Write-Step "Resource group: $resourceGroupName ($location)"
    if ($PSCmdlet.ShouldProcess($resourceGroupName, 'Create resource group')) {
        Invoke-Checked {
            az group create --name $resourceGroupName --location $location --output none
        } "az group create $resourceGroupName"
    }
} else {
    Write-Step "Skipping resource group creation (createResourceGroup=false)"
}

# --- App registration ---
Write-Step "App registration: $appDisplayName"
$existingApps = Get-AzCliJson @(
    'ad', 'app', 'list',
    '--display-name', $appDisplayName,
    '--query', "[?displayName=='$appDisplayName']",
    '-o', 'json'
)
$app = $null
if ($null -ne $existingApps) {
    $appList = @($existingApps)
    if ($appList.Count -gt 0) {
        $app = $appList[0]
        Write-Host "Using existing app registration appId=$($app.appId)"
    }
}
if (-not $app -and -not $DryRun) {
    if ($PSCmdlet.ShouldProcess($appDisplayName, 'Create app registration')) {
        $app = Get-AzCliJson @('ad', 'app', 'create', '--display-name', $appDisplayName, '-o', 'json')
        Write-Host "Created app registration appId=$($app.appId)"
    }
} elseif (-not $app -and $DryRun) {
    Write-Host "[DryRun] Would create app registration: $appDisplayName"
}

if (-not $app) {
    if ($DryRun) {
        $clientId = '00000000-0000-0000-0000-000000000000'
        $appObjectId = '00000000-0000-0000-0000-000000000000'
    } else {
        throw 'App registration could not be resolved.'
    }
} else {
    $clientId = $app.appId
    $appObjectId = $app.id
}

# --- Service principal ---
Write-Step 'Service principal'
$sp = Get-AzCliJson @('ad', 'sp', 'list', '--filter', "appId eq '$clientId'", '-o', 'json')
if (-not $DryRun) {
    if (-not $sp -or @($sp).Count -eq 0) {
        if ($PSCmdlet.ShouldProcess($clientId, 'Create service principal')) {
            Invoke-Checked { az ad sp create --id $clientId --output none } 'az ad sp create'
        }
    }
    $spObjectId = (az ad sp show --id $clientId --query id -o tsv)
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve service principal object id.' }
} else {
    $spObjectId = '00000000-0000-0000-0000-000000000000'
    Write-Host '[DryRun] Skipping service principal resolution'
}

# --- RBAC on resource group ---
if ($assignRgRoles) {
    Write-Step "Role assignments on $resourceGroupName"
    $roles = @(
        @{ Name = 'Contributor'; Id = 'b24988ac-6180-42a0-ab88-20f7382dd24c' }
        @{ Name = 'User Access Administrator'; Id = '18d7d88d-d35e-4fb5-a5c3-7773c20c72c9' }
    )
    foreach ($role in $roles) {
        $exists = az role assignment list --assignee $spObjectId --scope $rgScope --role $role.Id --query "[0].id" -o tsv 2>$null
        if ($exists) {
            Write-Host "Already assigned: $($role.Name)"
            continue
        }
        if ($PSCmdlet.ShouldProcess($spObjectId, "Assign $($role.Name) on RG")) {
            Invoke-Checked {
                az role assignment create `
                    --assignee-object-id $spObjectId `
                    --assignee-principal-type ServicePrincipal `
                    --role $role.Id `
                    --scope $rgScope `
                    --output none
            } "role assignment $($role.Name)"
        }
    }
} else {
    Write-Host 'Skipping RG role assignments (assignResourceGroupRoles=false).'
}

# --- Federated credential (OIDC) ---
if ([string]::IsNullOrWhiteSpace($githubEnvironment)) {
    $federatedSubject = "repo:${githubOwner}/${githubRepo}:ref:refs/heads/${githubBranch}"
} else {
    $federatedSubject = "repo:${githubOwner}/${githubRepo}:environment:${githubEnvironment}"
}

Write-Step "Federated credential: $federatedName"
Write-Host "Subject: $federatedSubject"

$credBody = @{
    name        = $federatedName
    issuer      = 'https://token.actions.githubusercontent.com'
    subject     = $federatedSubject
    description = "GitHub Actions OIDC for $githubOwner/$githubRepo"
    audiences   = @('api://AzureADTokenExchange')
} | ConvertTo-Json -Compress

$existingCred = $null
if (-not $DryRun) {
    $creds = Get-AzCliJson @('ad', 'app', 'federated-credential', 'list', '--id', $appObjectId, '-o', 'json')
    if ($creds) {
        $existingCred = $creds | Where-Object { $_.subject -eq $federatedSubject -or $_.name -eq $federatedName } | Select-Object -First 1
    }
}

if ($existingCred) {
    Write-Host "Federated credential already exists: $($existingCred.name)"
} else {
    $credFile = Join-Path $env:TEMP "devcamp-federated-credential.json"
    [System.IO.File]::WriteAllText($credFile, $credBody)
    try {
        if ($PSCmdlet.ShouldProcess($federatedSubject, 'Create federated credential')) {
            Invoke-Checked {
                az ad app federated-credential create --id $appObjectId --parameters $credFile --output none
            } 'az ad app federated-credential create'
        }
    } finally {
        Remove-Item $credFile -Force -ErrorAction SilentlyContinue
    }
}

# --- GitHub secrets ---
if ($setGhSecrets) {
    Write-Step 'Setting GitHub repository secrets (requires gh repo admin)'
    $repoSlug = "$githubOwner/$githubRepo"
    if ($PSCmdlet.ShouldProcess($repoSlug, 'Set AZURE_* secrets')) {
        if ($DryRun) {
            Write-Host "[DryRun] gh secret set AZURE_CLIENT_ID / TENANT_ID / SUBSCRIPTION_ID on $repoSlug"
        } else {
            $clientId | gh secret set AZURE_CLIENT_ID --repo $repoSlug
            $tenantId | gh secret set AZURE_TENANT_ID --repo $repoSlug
            $subscriptionId | gh secret set AZURE_SUBSCRIPTION_ID --repo $repoSlug
            Write-Host 'Secrets set: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID'
        }
    }
} else {
    Write-Host 'Skipping GitHub secrets (setGitHubSecrets=false).'
}

# --- Summary ---
Write-Step 'Bootstrap complete'
$summary = [ordered]@{
    subscriptionId      = $subscriptionId
    tenantId            = $tenantId
    resourceGroupName   = $resourceGroupName
    location            = $location
    azureClientId       = $clientId
    servicePrincipalId  = $spObjectId
    federatedSubject    = $federatedSubject
    githubRepo          = "$githubOwner/$githubRepo"
    nextSteps           = @(
        'GitHub: Actions - Deploy infrastructure (workflow_dispatch)'
        'Note Bicep outputs: webAppName, webAppHostName, cosmosEndpoint'
        'GitHub: Actions - Deploy API with web_app_name and resource_group'
        'Local: az login; assign Cosmos DB Built-in Data Contributor to your user; set CosmosDb__Endpoint'
    )
}

$outFile = Join-Path (Split-Path $ConfigPath -Parent) 'bootstrap-output.json'
if (-not $DryRun) {
    $summary | ConvertTo-Json -Depth 5 | Set-Content $outFile -Encoding utf8
    Write-Host "Wrote $outFile (no secrets beyond public IDs)."
}

$summary | Format-List
Write-Host "`nManual secret values (if not using gh):" -ForegroundColor Green
Write-Host "  AZURE_CLIENT_ID       = $clientId"
Write-Host "  AZURE_TENANT_ID       = $tenantId"
Write-Host "  AZURE_SUBSCRIPTION_ID = $subscriptionId"
