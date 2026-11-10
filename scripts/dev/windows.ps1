<#
.SYNOPSIS
    Windows dev entry point for `npm run dev` on this fork.

.DESCRIPTION
    Validates Node.js version, creates the data directory if missing, copies
    `.env.example` to `.env` when `.env` does not exist yet, and then launches
    `npm run dev` with port-conflict detection.

    Usage:
        & "./scripts/dev/windows.ps1"
        & "./scripts/dev/windows.ps1" -DryRun        # validate only, do not start
        & "./scripts/dev/windows.ps1" -NoEnv         # skip .env seeding
        & "./scripts/dev/windows.ps1" -SkipPortCheck # skip port-conflict check

    Exit code:
        0   success (or -DryRun OK)
        1   validation failed / port busy / npm not found

.NOTES
    Typical personal workflow:
        git clone <this fork> %USERPROFILE%\code\omniroute-fork
        cd %USERPROFILE%\code\omniroute-fork
        npm install --legacy-peer-deps --no-audit --no-fund
        & "./scripts/dev/windows.ps1"
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoEnv,
    [switch]$SkipPortCheck
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step([string]$message) {
    Write-Host "[dev] $message"
}

function Write-Ok([string]$message) {
    Write-Host "[dev] OK   $message" -ForegroundColor Green
}

function Write-Warn([string]$message) {
    Write-Host "[dev] WARN $message" -ForegroundColor Yellow
}

function Write-Fail([string]$message) {
    Write-Host "[dev] FAIL $message" -ForegroundColor Red
}

# --- 1. Node.js version check ----------------------------------------------
try {
    $nodeVersionRaw = (& node --version).Trim()
} catch {
    Write-Fail "'node' was not found on PATH. Install Node.js >= 24 and retry."
    exit 1
}

if ($nodeVersionRaw -notmatch '^v(\d+)\.(\d+)\.(\d+)') {
    Write-Fail "Unable to parse 'node --version' output: $nodeVersionRaw"
    exit 1
}

$nodeMajor = [int]$Matches[1]
if ($nodeMajor -lt 24 -or $nodeMajor -ge 27) {
    Write-Fail "Node.js $nodeVersionRaw is outside the supported range (>=24.0.0 <27)."
    exit 1
}
Write-Ok "Node.js $nodeVersionRaw"

# --- 2. Resolve project root (parent of this script's folder) ---------------
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptRoot (Join-Path '..' '..'))).Path

if (-not (Test-Path (Join-Path $projectRoot 'package.json'))) {
    Write-Fail "Could not locate package.json at $projectRoot - run this script from within the fork."
    exit 1
}
Set-Location $projectRoot
Write-Ok "Project root: $projectRoot"

# --- 3. Seed .env from .env.example -----------------------------------------
$envFile = Join-Path $projectRoot '.env'
$envExample = Join-Path $projectRoot '.env.example'

if ((-not $NoEnv) -and (-not (Test-Path $envFile))) {
    if (-not (Test-Path $envExample)) {
        Write-Fail ".env.example is missing - cannot seed an initial .env."
        exit 1
    }
    Copy-Item $envExample $envFile
    Write-Ok "Copied .env.example to .env (you can edit ports/keys later)"
} elseif (Test-Path $envFile) {
    Write-Ok ".env already present - leaving it as-is"
}

# --- 4. Resolve and create DATA_DIR -----------------------------------------
$dataDirResolved = $null

if ($env:DATA_DIR) {
    $dataDirResolved = $env:DATA_DIR
} elseif (Test-Path $envFile) {
    $envText = Get-Content $envFile -Raw -ErrorAction SilentlyContinue
    $m = [regex]::Match($envText, '(?m)^DATA_DIR=(.+)$')
    if ($m.Success) { $dataDirResolved = $m.Groups[1].Value.Trim() }
}

if ($dataDirResolved) {
    $dataDirResolved = [Environment]::ExpandEnvironmentVariables($dataDirResolved)
    if ($dataDirResolved.StartsWith('~')) {
        $dataDirResolved = Join-Path $HOME $dataDirResolved.TrimStart('~', '/')
    }
} else {
    # Upstream default (per src/lib/dataPaths.ts): ~/.omniroute
    $dataDirResolved = Join-Path $HOME '.omniroute'
}

if (-not (Test-Path $dataDirResolved)) {
    New-Item -ItemType Directory -Path $dataDirResolved -Force | Out-Null
    Write-Ok "Created DATA_DIR: $dataDirResolved"
} else {
    Write-Ok "DATA_DIR ready: $dataDirResolved"
}

# --- 5. Resolve the dashboard port ------------------------------------------
$port = 20128
if ($env:DASHBOARD_PORT) {
    $port = [int]$env:DASHBOARD_PORT
} elseif (Test-Path $envFile) {
    $envText = Get-Content $envFile -Raw -ErrorAction SilentlyContinue
    $m = [regex]::Match($envText, '(?m)^DASHBOARD_PORT=(\d+)$')
    if ($m.Success) { $port = [int]$m.Groups[1].Value }
    elseif ([regex]::IsMatch($envText, '(?m)^PORT=(\d+)$')) {
        $m2 = [regex]::Match($envText, '(?m)^PORT=(\d+)$')
        $port = [int]$m2.Groups[1].Value
    }
}
Write-Ok "Dashboard port: $port"

# --- 6. Port-conflict detection ----------------------------------------------
if (-not $SkipPortCheck) {
    $listeners = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($listeners) {
        $portOwner = $null
        foreach ($conn in $listeners) {
            try {
                $proc = Get-Process -Id $conn.OwningProcess -ErrorAction Stop
                $portOwner = "$($proc.Name) (pid $($proc.Id))"
                break
            } catch {
                # Process may have exited; try next listener
            }
        }

        Write-Fail "Port $port is already in use by $portOwner."
        Write-Host ""
        Write-Host "Pick one of these fixes:" -ForegroundColor Yellow
        Write-Host "  1. Stop that process:" -ForegroundColor Yellow
        if ($listeners[0].OwningProcess) {
            Write-Host "       Stop-Process -Id $($listeners[0].OwningProcess)" -ForegroundColor Yellow
        }
        Write-Host "  2. Pick a different port by adding to .env:" -ForegroundColor Yellow
        Write-Host "       DASHBOARD_PORT=20129" -ForegroundColor Yellow
        Write-Host "  3. Or run with -SkipPortCheck to skip this validation." -ForegroundColor Yellow
        exit 1
    }
    Write-Ok "Port $port is free"
} else {
    Write-Warn "Skipping port-conflict check"
}

# --- 7. Launch npm run dev ---------------------------------------------------
if ($DryRun) {
    Write-Ok "Dry run - validation passed, not launching dev server"
    exit 0
}

Write-Step "Launching: npm run dev"
Write-Host ""
& npm.cmd run dev
exit $LASTEXITCODE
