# Dumps the Supabase Postgres database to a dated .sql file and keeps the last 14.
# Needs pg_dump on PATH and DATABASE_URL set to the connection string from
# Supabase > Project Settings > Database. Photos in Storage are not included.
param([string]$OutDir = "$PSScriptRoot\..\backups")

if (-not $env:DATABASE_URL) { throw "Set DATABASE_URL first." }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$file = Join-Path $OutDir ("mysun-{0:yyyyMMdd-HHmm}.sql" -f (Get-Date))
pg_dump --no-owner --no-privileges --file $file $env:DATABASE_URL
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed" }
Get-ChildItem $OutDir -Filter "mysun-*.sql" | Sort-Object LastWriteTime -Descending |
  Select-Object -Skip 14 | Remove-Item
Write-Output "Wrote $file"
