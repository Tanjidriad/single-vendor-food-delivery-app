# Registers all Android apps in the shared Firebase project, merges google-services.json,
# and copies the canonical file into each Flutter app.
#
# Prerequisites:
#   - firebase CLI logged in as a user with Editor/Owner on the Firebase project
#     firebase login
#   - Node.js (for merge script)
#
# Usage (from repo root):
#   .\scripts\firebase\setup-android-fcm.ps1
#   .\scripts\firebase\setup-android-fcm.ps1 -SyncOnly    # skip registration, just copy
#   .\scripts\firebase\setup-android-fcm.ps1 -RegisterOnly

param(
    [switch]$SyncOnly,
    [switch]$RegisterOnly
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ConfigPath = Join-Path $RepoRoot 'infra\firebase\apps.config.json'
$CanonicalPath = Join-Path $RepoRoot 'infra\firebase\google-services.json'
$MergeScript = Join-Path $RepoRoot 'scripts\firebase\merge-google-services.mjs'
$TempDir = Join-Path $RepoRoot 'infra\firebase\.tmp'

$config = Get-Content $ConfigPath | ConvertFrom-Json
$projectId = $config.projectId

function Test-PackageInConfig {
    param([string]$PackageName, [object]$Json)
    foreach ($client in $Json.client) {
        if ($client.client_info.android_client_info.package_name -eq $PackageName) {
            return $true
        }
    }
    return $false
}

function Sync-GoogleServices {
    if (-not (Test-Path $CanonicalPath)) {
        throw "Missing canonical file: $CanonicalPath"
    }

    $canonical = Get-Content $CanonicalPath -Raw | ConvertFrom-Json
    $missing = @()

    foreach ($app in $config.androidApps) {
        $pkg = $app.packageName
        if (-not (Test-PackageInConfig -PackageName $pkg -Json $canonical)) {
            $missing += $pkg
            continue
        }

        $target = Join-Path $RepoRoot $app.target
        $targetDir = Split-Path $target -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item $CanonicalPath $target -Force
        Write-Host "Synced -> $($app.target)" -ForegroundColor Green
    }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "WARNING: These package names are not in $CanonicalPath yet:" -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        Write-Host "Run without -SyncOnly to register them, or add them in Firebase Console and re-download." -ForegroundColor Yellow
    }
}

function Register-AndroidApps {
    Write-Host "Using Firebase project: $projectId" -ForegroundColor Cyan

    $appsJson = & firebase apps:list --project $projectId --json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $appsJson) {
        throw @"
Firebase CLI could not access project '$projectId'.
Log in with the Google account that owns the project:
  firebase login
Or add your account as Editor in Firebase Console > Project settings > Users and permissions.
"@
    }

    $apps = $appsJson | ConvertFrom-Json

    $existing = @{}
    foreach ($result in $apps.result) {
        if ($result.platform -eq 'ANDROID' -and $result.namespace) {
            $existing[$result.namespace] = $result.appId
        }
    }

    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }

    $sdkFiles = @($CanonicalPath)

    foreach ($app in $config.androidApps) {
        $pkg = $app.packageName
        $appId = $existing[$pkg]

        if (-not $appId) {
            Write-Host "Creating Android app: $($app.displayName) ($pkg)" -ForegroundColor Cyan
            $createJson = firebase apps:create ANDROID $app.displayName `
                --package-name $pkg `
                --project $projectId `
                --json | ConvertFrom-Json

            if ($createJson.status -ne 'success') {
                throw "Failed to create Android app for $pkg"
            }
            $appId = $createJson.result.appId
            Write-Host "  Created appId: $appId" -ForegroundColor Green
        } else {
            Write-Host "Already registered: $pkg ($appId)" -ForegroundColor DarkGray
        }

        $outFile = Join-Path $TempDir "$pkg.json"
        firebase apps:sdkconfig ANDROID $appId --project $projectId --out $outFile | Out-Null
        $sdkFiles += $outFile
    }

    $uniqueSdkFiles = $sdkFiles | Select-Object -Unique
    & node $MergeScript --write $CanonicalPath @uniqueSdkFiles
    Write-Host "Updated canonical config: $CanonicalPath" -ForegroundColor Green
}

Write-Host "=== Firebase Android FCM setup ===" -ForegroundColor Cyan
Write-Host "Project: $projectId`n"

if (-not $SyncOnly) {
    Register-AndroidApps
}

if (-not $RegisterOnly) {
    Sync-GoogleServices
}

Write-Host ""
Write-Host "Next: set backend FCM credentials (one service account for all apps):" -ForegroundColor Cyan
Write-Host "  .\scripts\firebase\configure-fcm-backend.ps1 -ServiceAccountJson path\to\service-account.json"
Write-Host ""
Write-Host "Rebuild apps after sync:" -ForegroundColor Cyan
Write-Host "  cd apps/kitchen_app && flutter build apk --release --dart-define=API_BASE_URL=... --dart-define=SOCKET_BASE_URL=..."
