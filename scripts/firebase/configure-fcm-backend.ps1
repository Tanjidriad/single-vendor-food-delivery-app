# Writes FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY into backend/.env
# from a Firebase service-account JSON key (Project settings > Service accounts).
#
# Usage:
#   .\scripts\firebase\configure-fcm-backend.ps1 -ServiceAccountJson C:\path\wasabi-delivery-e7bf2-firebase-adminsdk.json

param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceAccountJson
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$EnvPath = Join-Path $RepoRoot 'backend\.env'

if (-not (Test-Path $ServiceAccountJson)) {
    throw "Service account file not found: $ServiceAccountJson"
}

$sa = Get-Content $ServiceAccountJson -Raw | ConvertFrom-Json
$projectId = $sa.project_id
$clientEmail = $sa.client_email
$privateKey = $sa.private_key -replace "`n", '\n'

if (-not (Test-Path $EnvPath)) {
    Copy-Item (Join-Path $RepoRoot 'backend\.env.example') $EnvPath
    Write-Host "Created backend/.env from .env.example"
}

$lines = Get-Content $EnvPath
$updates = @{
    'FCM_PROJECT_ID'   = $projectId
    'FCM_CLIENT_EMAIL' = $clientEmail
    'FCM_PRIVATE_KEY'  = "`"$privateKey`""
}

$keysWritten = @{}
$out = foreach ($line in $lines) {
    $matched = $false
    foreach ($key in $updates.Keys) {
        if ($line -match "^$key=") {
            $keysWritten[$key] = $true
            "$key=$($updates[$key])"
            $matched = $true
            break
        }
    }
    if (-not $matched) { $line }
}

foreach ($key in $updates.Keys) {
    if (-not $keysWritten[$key]) {
        $out += "$key=$($updates[$key])"
    }
}

Set-Content -Path $EnvPath -Value $out -Encoding utf8
Write-Host "Updated backend/.env with FCM credentials for project: $projectId" -ForegroundColor Green
Write-Host "Restart the API after deploying."
