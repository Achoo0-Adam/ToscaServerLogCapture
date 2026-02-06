###############################################################################
# Tosca Server Log Capture Script V4.7 - Adam Lucey (a.lucey@tricentis.com) if you have any questions or suggestions for improvement please reach out.
#
# PURPOSE:
# Collect Tosca Server service logs and optional support logs for a selected. (May need to include the APPDATA logs or appsettings.json differs from the default configuration)
# date range and bundle them into a single ZIP file for support analysis. (Considered adding a ticket number to the filename but its ultimately easier this way)
#
# BEHAVIOUR:
# - Primary logs: %PROGRAMDATA%\TRICENTIS\ToscaServer\Logs
# - Support logs: %PROGRAMDATA%\TRICENTIS\Logs
# - Prompts for ToscaServer log path if not found in ProgramData (e.g. D:\TRICENTIS\ToscaServer\Logs)
# - Allows selection of date range and which service folders to include
# - Only files modified within the selected range are collected
# - Output ZIP is created in C:\Temp with date and time (no seconds)
#
# CHANGES / ENHANCEMENTS:
# - Added clear prompts with yyyy/MM/dd format examples
# - Output ZIP filename updated: ToscaLogCapture_yyyyMMdd_HHmm.zip
# - Added "Press ENTER to close" before exiting (prevents accidental closure OR Error messages from disappearing before user can read them)
# - Structured service selection with "Server only" and "Server + Support"
# - Display detected log sources at the start for clarity
# - Overall code cleanup and comments for maintainability
# - Made it look pretty in the console with colors and separators (because why not?)
# COMPATIBILITY:
# - Windows PowerShell 5.1+ (should work on older versions but not tested, give it a go if you want to try it out and let me know if you find any issues)
###############################################################################

Write-Host "Tosca Server Log Capture Starting..." -ForegroundColor Green

###############################################################################
# 0. DETECT LOG ROOTS
# - Determine locations of server and support logs to search for files. 
# - Server logs are primary; prompts user if default location missing
# - Support logs are optional, always included if present
###############################################################################

$serverRoots  = @()  # Array to hold server log paths
$supportRoots = @()  # Array to hold support log paths

# --- Support logs (always attempted) ---
$supportPath = Join-Path $env:PROGRAMDATA "TRICENTIS\Logs"
if (Test-Path $supportPath) {
    $supportRoots += $supportPath
}

# --- Server logs (preferred) ---
$defaultServerPath = Join-Path $env:PROGRAMDATA "TRICENTIS\ToscaServer\Logs"
if (Test-Path $defaultServerPath) {
    $serverRoots += $defaultServerPath
}
else {
    # Ask user for custom server logs path if default not found
    do {
        $customServerPath = Read-Host "Enter ToscaServer Logs path (e.g. D:\PROGRAMDATA\TRICENTIS\ToscaServer\Logs)"
    } until (Test-Path $customServerPath)

    $serverRoots += $customServerPath
}

# Exit if no logs found
if ($serverRoots.Count -eq 0 -and $supportRoots.Count -eq 0) {
    Write-Host "No log locations found. Exiting." -ForegroundColor Red
    Read-Host "Press ENTER to close"
    exit
}

###############################################################################
# 1. DISPLAY LOG SOURCES
# - Show detected log locations before further processing
###############################################################################

Write-Host ""
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host " LOG SOURCES" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor DarkGray

$serverRoots  | ForEach-Object { Write-Host "[SERVER ] $_" }
$supportRoots | ForEach-Object { Write-Host "[SUPPORT] $_" }

###############################################################################
# 2. DATE RANGE SELECTION
# - User selects today, today+yesterday, or custom range
# - Prompts include clear yyyy/MM/dd format examples
###############################################################################

Write-Host ""
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host " DATE RANGE SELECTION" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor DarkGray

Write-Host " 1) Today only"
Write-Host " 2) Today and yesterday"
Write-Host " 3) Custom dates"
$choice = Read-Host "Your choice"

switch ($choice) {
    "1" {
        $startDate = (Get-Date).Date  # Today from 00:00
        $endDate   = Get-Date         # Now
    }
    "2" {
        $startDate = (Get-Date).AddDays(-1).Date  # Yesterday 00:00
        $endDate   = Get-Date                     # Now
    }
    "3" {
        # Custom dates with examples
        Write-Host ""
        Write-Host "Accepted date formats:" -ForegroundColor Cyan
        Write-Host " yyyy/mm/dd" # Can add Hour:minutes if you want. Kinda meh though > Write-Host " yyyy/MM/dd HH:mm"
        
        $startDate = Get-Date (Read-Host "START date")
        $endDate   = Get-Date (Read-Host "END date")
    }
    default {
        Write-Host "Invalid choice. Defaulting to Today only." -ForegroundColor Yellow
        $startDate = (Get-Date).Date
        $endDate   = Get-Date
    }
}

Write-Host ""
Write-Host "Date range selected:" -ForegroundColor Cyan
Write-Host " From: $startDate"
Write-Host " To:   $endDate"

###############################################################################
# 3. BUILD SERVICE LISTS
# - Search directories under server and support roots (might need to be adjusted if logs are stored further down or custom appsettings.json are used)
# - Create objects storing Type, Path, and Name
###############################################################################

$serverServices  = @()
$supportServices = @()

foreach ($root in $serverRoots) {
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $serverServices += [PSCustomObject]@{
            Type = "SERVER"
            Path = $_.FullName
            Name = $_.Name
        }
    }
}

foreach ($root in $supportRoots) {
    Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $supportServices += [PSCustomObject]@{
            Type = "SUPPORT"
            Path = $_.FullName
            Name = $_.Name
        }
    }
}

###############################################################################
# 4. SERVICE SELECTION
# - Allows user to choose "Server only", "Server + Support", or individual folders
# - Ensures users know which type each service is
###############################################################################

Write-Host ""
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host " SERVICE SELECTION" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor DarkGray

Write-Host " 1) Server services only (recommended)"
Write-Host " 2) Server + Support logs"

$i   = 3
$map = @{}

foreach ($svc in ($serverServices + $supportServices)) {
    Write-Host " $i) [$($svc.Type)] $($svc.Name)"
    $map[$i] = $svc
    $i++
}

$sel = Read-Host "Your choice (e.g. 1 or 2,4,5)"

if ($sel -eq "1") {
    $selected = $serverServices
}
elseif ($sel -eq "2") {
    $selected = $serverServices + $supportServices
}
else {
    $selected = $sel -split "," | ForEach-Object {
        $map[[int]$_.Trim()]
    }
}

###############################################################################
# 5. PREPARE TEMP WORKING AREA
# - Cleans previous temp directory
# - Sets ZIP filename with date & time (no seconds)
###############################################################################

$tempRoot = "C:\Temp\LogCapture"
$zipPath  = "C:\Temp\ToscaLogCapture_$(Get-Date -Format yyyyMMdd_HHmm).zip"

Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item $tempRoot -ItemType Directory | Out-Null

$totalFiles = 0

###############################################################################
# 6. COPY LOG FILES
# - Collects files modified in the selected date range
# - Copies into structured temp folder by Type/ServiceName
###############################################################################

foreach ($svc in $selected) {
    Get-ChildItem $svc.Path -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.LastWriteTime -ge $startDate -and
        $_.LastWriteTime -le $endDate
    } |
    ForEach-Object {
        $dest = Join-Path $tempRoot "$($svc.Type)\$($svc.Name)"
        New-Item $dest -ItemType Directory -Force | Out-Null
        Copy-Item $_.FullName $dest -Force
        $totalFiles++
    }
}

###############################################################################
# 7. ZIP AND CLEAN UP
# - If no files found, exit gracefully
# - Compresses temp folder into final ZIP
# - Deletes temp folder after zipping
###############################################################################

if ($totalFiles -eq 0) {
    Write-Host "No files found in selected range." -ForegroundColor Yellow
    Read-Host "Press ENTER to close"
    exit
}

Compress-Archive "$tempRoot\*" $zipPath -Force
Remove-Item $tempRoot -Recurse -Force

###############################################################################
# 8. SUMMARY AND EXIT
# - Displays number of files and ZIP path (Looks pretty cool with the structured folders in the ZIP)
# - Waits for ENTER before closing (prevents accidental closure or missing error messages)
###############################################################################

Write-Host ""
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host " LOG CAPTURE COMPLETE" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor DarkGray
Write-Host "Files collected: $totalFiles"
Write-Host "ZIP created at:"
Write-Host " $zipPath"

Read-Host "`nPress ENTER to close"
