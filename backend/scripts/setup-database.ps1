# Creates food_delivery user/database, then runs Prisma push + seed
param(
  [Parameter(Mandatory = $true)]
  [string]$PostgresPassword
)

$psql = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psql)) {
  $psql = (Get-ChildItem "C:\Program Files\PostgreSQL\*\bin\psql.exe" | Select-Object -First 1).FullName
}

$env:PGPASSWORD = $PostgresPassword
$sql = Join-Path $PSScriptRoot "setup-database.sql"

Write-Host "Creating user and database..."
& $psql -U postgres -h localhost -d postgres -f $sql
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Set-Location (Join-Path $PSScriptRoot "..")
Write-Host "Pushing Prisma schema..."
npx prisma db push
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Seeding..."
npm run db:seed
Write-Host "Done. Start API with: npm run start:dev"
