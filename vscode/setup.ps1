# VSCode settings symlink setup script for Windows
# Requires: Administrator privileges for creating symlinks

param(
    [switch]$Clean,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Determine VSCode settings directory based on OS
$VScodeSettingDir = "$env:APPDATA\Code\User"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Files to symlink
$FilesToLink = @(
    "settings.json",
    "keybindings.json"
)

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-Symlinks {
    Write-Host "Cleaning up symlinks..." -ForegroundColor Yellow

    foreach ($file in $FilesToLink) {
        $targetPath = Join-Path $VScodeSettingDir $file

        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath
            if ($item.LinkType -eq "SymbolicLink") {
                Write-Host "  Removing symlink: $targetPath" -ForegroundColor Cyan
                Remove-Item $targetPath -Force
            } else {
                Write-Host "  Skipping (not a symlink): $targetPath" -ForegroundColor Gray
            }
        }
    }

    Write-Host "Cleanup completed!" -ForegroundColor Green
}

function Install-Symlinks {
    Write-Host "Setting up VSCode symlinks..." -ForegroundColor Yellow
    Write-Host "  Script directory: $ScriptDir" -ForegroundColor Gray
    Write-Host "  VSCode User directory: $VScodeSettingDir" -ForegroundColor Gray
    Write-Host ""

    # Create VSCode settings directory if it doesn't exist
    if (-not (Test-Path $VScodeSettingDir)) {
        Write-Host "Creating VSCode settings directory..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $VScodeSettingDir -Force | Out-Null
    }

    foreach ($file in $FilesToLink) {
        $sourcePath = Join-Path $ScriptDir $file
        $targetPath = Join-Path $VScodeSettingDir $file

        # Check if source file exists
        if (-not (Test-Path $sourcePath)) {
            Write-Host "  Warning: Source file not found: $sourcePath" -ForegroundColor Red
            continue
        }

        # Handle existing target
        if (Test-Path $targetPath) {
            $item = Get-Item $targetPath
            if ($item.LinkType -eq "SymbolicLink") {
                if ($Force) {
                    Write-Host "  Removing existing symlink: $targetPath" -ForegroundColor Yellow
                    Remove-Item $targetPath -Force
                } else {
                    Write-Host "  Symlink already exists: $targetPath (use -Force to overwrite)" -ForegroundColor Gray
                    continue
                }
            } else {
                Write-Host "  Warning: File exists but is not a symlink: $targetPath" -ForegroundColor Red
                Write-Host "          Please backup and remove it manually, or use -Force" -ForegroundColor Red
                continue
            }
        }

        # Create symlink
        try {
            Write-Host "  Creating symlink: $file" -ForegroundColor Cyan
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            Write-Host "    -> $sourcePath" -ForegroundColor Green
        } catch {
            Write-Host "  Error creating symlink for $file" -ForegroundColor Red
            Write-Host "    $_" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Symlink setup completed!" -ForegroundColor Green
}

function Install-Extensions {
    Write-Host ""
    Write-Host "Installing VSCode extensions..." -ForegroundColor Yellow

    $extensionsFile = Join-Path $ScriptDir "extensions"

    if (-not (Test-Path $extensionsFile)) {
        Write-Host "  Extensions file not found: $extensionsFile" -ForegroundColor Red
        return
    }

    # Check if code command is available
    try {
        $null = Get-Command code -ErrorAction Stop
    } catch {
        Write-Host "  'code' command not found. Please add VSCode to your PATH." -ForegroundColor Red
        return
    }

    Get-Content $extensionsFile | ForEach-Object {
        $extension = $_.Trim()
        if ($extension -and -not $extension.StartsWith("#")) {
            Write-Host "  Installing: $extension" -ForegroundColor Cyan
            code --force --install-extension $extension
        }
    }

    Write-Host ""
    Write-Host "Updating extensions list..." -ForegroundColor Yellow
    code --list-extensions | Out-File -FilePath $extensionsFile -Encoding UTF8
    Write-Host "Extensions installation completed!" -ForegroundColor Green
}

# Main execution
Write-Host "=== VSCode Settings Setup for Windows ===" -ForegroundColor Magenta
Write-Host ""

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Host "Warning: This script is not running with Administrator privileges." -ForegroundColor Yellow
    Write-Host "Symlink creation may fail. Please run PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

if ($Clean) {
    Remove-Symlinks
} else {
    Install-Symlinks

    # Ask if user wants to install extensions
    Write-Host ""
    $installExt = Read-Host "Install VSCode extensions? (Y/n)"
    if ($installExt -ne "n" -and $installExt -ne "N") {
        Install-Extensions
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
