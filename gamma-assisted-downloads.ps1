param(
    [string]$ModsFile = "C:\GAMMA\.Grok's Modpack Installer\mods.txt",
    [string]$DownloadsDir = "C:\GAMMA\downloads",
    [string]$BrowserDownloadsDir = "",
    [int]$Limit = 0,
    [int]$StartAt = 1,
    [switch]$UseModPage,
    [switch]$All,
    [switch]$NoHash,
    [switch]$DryRun,
    [int]$StableSeconds = 5
)

$ErrorActionPreference = "Stop"

function Get-Md5Lower {
    param([string]$Path)
    return (Get-FileHash -Algorithm MD5 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-DefaultDownloadsDir {
    $userShellFolders = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $downloadsGuid = "{374DE290-123F-4565-9164-39C4925E467B}"

    try {
        $configuredPath = (Get-ItemProperty -LiteralPath $userShellFolders -Name $downloadsGuid -ErrorAction Stop).$downloadsGuid
        if (-not [string]::IsNullOrWhiteSpace($configuredPath)) {
            return [Environment]::ExpandEnvironmentVariables($configuredPath)
        }
    } catch {
        # Fall back to the conventional Downloads folder below.
    }

    return Join-Path $env:USERPROFILE "Downloads"
}

function Get-DownloadState {
    param(
        [string]$Path,
        [string]$ExpectedHash,
        [bool]$CheckHash
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Exists = $false; Done = $false; HashOk = $null; Reason = "missing" }
    }

    $dir = Split-Path -Parent $Path
    $name = [IO.Path]::GetFileName($Path)
    $partials = @(
        "$Path.crdownload",
        "$Path.part",
        "$Path.tmp"
    ) + @(Get-ChildItem -LiteralPath $dir -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$name.*" -and ($_.Extension -in ".crdownload", ".part", ".tmp") } |
        ForEach-Object { $_.FullName })

    $partials = @($partials | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique)
    if ($partials.Count -gt 0) {
        return [pscustomobject]@{ Exists = $true; Done = $false; HashOk = $null; Reason = "partial" }
    }

    if ($CheckHash -and $ExpectedHash -match "^[a-fA-F0-9]{32}$") {
        $actual = Get-Md5Lower -Path $Path
        return [pscustomobject]@{
            Exists = $true
            Done = ($actual -eq $ExpectedHash.ToLowerInvariant())
            HashOk = ($actual -eq $ExpectedHash.ToLowerInvariant())
            Reason = if ($actual -eq $ExpectedHash.ToLowerInvariant()) { "ok" } else { "hash-mismatch" }
        }
    }

    return [pscustomobject]@{ Exists = $true; Done = $true; HashOk = $null; Reason = "present" }
}

function Test-PartialDownload {
    param([string]$Path)

    $dir = Split-Path -Parent $Path
    $name = [IO.Path]::GetFileName($Path)
    $partials = @(
        "$Path.crdownload",
        "$Path.part",
        "$Path.tmp"
    ) + @(Get-ChildItem -LiteralPath $dir -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$name.*" -and ($_.Extension -in ".crdownload", ".part", ".tmp") } |
        ForEach-Object { $_.FullName })

    return @($partials | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -Unique).Count -gt 0
}

function Wait-FileStable {
    param(
        [string]$Path,
        [int]$Seconds
    )

    if (-not (Test-Path -LiteralPath $Path)) { return $false }

    $lastLength = -1
    $stableSince = $null
    while ($true) {
        if (-not (Test-Path -LiteralPath $Path)) { return $false }
        if (Test-PartialDownload -Path $Path) { return $false }

        $length = (Get-Item -LiteralPath $Path).Length
        if ($length -eq $lastLength) {
            if ($null -eq $stableSince) { $stableSince = Get-Date }
            if (((Get-Date) - $stableSince).TotalSeconds -ge $Seconds) { return $true }
        } else {
            $lastLength = $length
            $stableSince = $null
        }

        Start-Sleep -Seconds 1
    }
}

function Move-BrowserDownload {
    param(
        [pscustomobject]$Mod,
        [string]$SourceDir,
        [string]$DestinationPath,
        [int]$StableSeconds
    )

    $sourcePath = Join-Path $SourceDir $Mod.File
    if (-not (Test-Path -LiteralPath $sourcePath)) { return $false }
    if (-not (Wait-FileStable -Path $sourcePath -Seconds $StableSeconds)) { return $false }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DestinationPath) | Out-Null
    if (Test-Path -LiteralPath $DestinationPath) {
        Remove-Item -LiteralPath $DestinationPath -Force
    }
    Move-Item -LiteralPath $sourcePath -Destination $DestinationPath -Force
    return $true
}

if ([string]::IsNullOrWhiteSpace($BrowserDownloadsDir)) {
    $BrowserDownloadsDir = Get-DefaultDownloadsDir
}

if (-not (Test-Path -LiteralPath $ModsFile)) {
    throw "mods.txt not found: $ModsFile"
}

New-Item -ItemType Directory -Force -Path $DownloadsDir | Out-Null
New-Item -ItemType Directory -Force -Path $BrowserDownloadsDir | Out-Null

$mods = Get-Content -LiteralPath $ModsFile |
    Where-Object { $_ -match "^https?://" } |
    ForEach-Object {
        $p = $_ -split "`t"
        if ($p.Count -lt 7) { return }
        [pscustomobject]@{
            Url = $p[0].Trim()
            InstallFolder = $p[1].Trim()
            Author = $p[2].Trim()
            Name = $p[3].Trim()
            Page = $p[4].Trim()
            File = $p[5].Trim()
            Hash = $p[6].Trim()
            Path = Join-Path $DownloadsDir $p[5].Trim()
        }
    }

$checkHash = -not $NoHash.IsPresent
$queue = @($mods | ForEach-Object {
    $state = Get-DownloadState -Path $_.Path -ExpectedHash $_.Hash -CheckHash $checkHash
    $_ | Add-Member -NotePropertyName State -NotePropertyValue $state -Force
    $_
} | Where-Object { $All -or -not $_.State.Done })

if ($StartAt -gt 1) {
    $queue = @($queue | Select-Object -Skip ($StartAt - 1))
}
if ($Limit -gt 0) {
    $queue = @($queue | Select-Object -First $Limit)
}

Write-Host "Mods listed: $($mods.Count)"
Write-Host "Queued: $($queue.Count)"
Write-Host "Downloads dir: $DownloadsDir"
Write-Host "Browser downloads dir: $BrowserDownloadsDir"
Write-Host ""

if ($DryRun) {
    $queue | Select-Object Name, File, Url, Page | Format-Table -AutoSize
    return
}

$index = 0
foreach ($mod in $queue) {
    $index++
    $targetUrl = if ($UseModPage) { $mod.Page } else { $mod.Url }

    Write-Host "[$index/$($queue.Count)] $($mod.Name)"
    Write-Host "Expected: $($mod.File)"
    Write-Host "Opening:  $targetUrl"
    Start-Process $targetUrl

    $lastLength = -1
    $stableSince = $null

    while ($true) {
        Start-Sleep -Seconds 2

        $moved = Move-BrowserDownload -Mod $mod -SourceDir $BrowserDownloadsDir -DestinationPath $mod.Path -StableSeconds $StableSeconds
        if ($moved) {
            Write-Host "Moved to GAMMA downloads: $($mod.File)"
        }

        $state = Get-DownloadState -Path $mod.Path -ExpectedHash $mod.Hash -CheckHash $checkHash

        if ($state.Done) {
            Write-Host "OK: $($mod.File)"
            Write-Host ""
            break
        }

        if ($state.Reason -eq "hash-mismatch") {
            Write-Warning "Downloaded file exists but MD5 does not match: $($mod.File)"
            Write-Host "Press Enter to continue anyway, R to reopen, S to skip, Q to quit."
            $answer = Read-Host
            if ($answer -match "^[Qq]$") { return }
            if ($answer -match "^[Rr]$") { Start-Process $targetUrl; continue }
            if ($answer -match "^[Ss]$") { break }
            Write-Host ""
            break
        }

        if (Test-Path -LiteralPath $mod.Path) {
            $length = (Get-Item -LiteralPath $mod.Path).Length
            if ($length -eq $lastLength) {
                if ($null -eq $stableSince) { $stableSince = Get-Date }
                $elapsed = ((Get-Date) - $stableSince).TotalSeconds
                if ($elapsed -ge $StableSeconds -and -not $checkHash) {
                    Write-Host "Present and stable: $($mod.File)"
                    Write-Host ""
                    break
                }
            } else {
                $lastLength = $length
                $stableSince = $null
            }
        }

        Write-Host "Waiting for $($mod.File). Press Enter to keep waiting, R reopen, P open mod page, S skip, Q quit."
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).Key
            switch ($key) {
                "R" { Start-Process $targetUrl }
                "P" { Start-Process $mod.Page }
                "S" { Write-Host "Skipped."; Write-Host ""; break }
                "Q" { return }
                default { }
            }
            if ($key -eq "S") { break }
        }
    }
}

Write-Host "Done."
