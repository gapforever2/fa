param(
  [Alias('Host')] [Parameter(Mandatory=$true)] [string]$Server,
  [Alias('User')] [Parameter(Mandatory=$true)] [string]$SshUser,
  [string]$KeyPath,
  [string]$Password,
  [int]$Port = 22,
  [string]$PuttyDir,
  [string]$SevenZipPath,
  [ValidateSet('Optimal','Store')] [string]$Compression = 'Optimal',
  [string]$WinRarPath,
  [switch]$UseWinRar,
  [Parameter(Mandatory=$true)] [string]$RemoteScriptBase,
  [string]$RemoteStagingDir = "/tmp/gf_nx_staging",
  [ValidateSet('nx2','nx3','nx4')] [string]$Kind = 'nx4',
  [ValidateSet('faf','fafbeta','murderparty')] [string]$Channel = 'fafbeta',
  [Alias('Only')] [string[]]$Archives = @('effects','env','etc','loc','lua','meshes','mods','projectiles','textures','units'),
  [Alias('ExePath','ForgedAlliancePath')] [string]$ExecutablePath,
  [switch]$SkipBuild,
  [switch]$SkipInit,
  [switch]$DryRun,
  [switch]$CleanStaging
)

$ErrorActionPreference = 'Stop'

function Test-CommandExists {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

if (-not $KeyPath -and -not $Password) { throw 'Provide either -KeyPath (OpenSSH private key) or -Password.' }

function Find-ToolPath {
  param(
    [string]$Name,
    [string]$HintDir
  )
  if ($HintDir) {
    $hintPath = Join-Path $HintDir $Name
    if (Test-Path $hintPath) { return $hintPath }
  }
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  $candidates = @(
    "C:\\Program Files\\PuTTY\\$Name",
    "C:\\Program Files (x86)\\PuTTY\\$Name",
    "D:\\Program Files\\PuTTY\\$Name",
    "D:\\Program Files (x86)\\PuTTY\\$Name"
  )
  foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
  return $null
}

function Find-SevenZip {
  if ($SevenZipPath -and (Test-Path $SevenZipPath)) { return $SevenZipPath }
  $cmd = Get-Command '7z.exe' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  $candidates = @(
    "C:\\Program Files\\7-Zip\\7z.exe",
    "C:\\Program Files (x86)\\7-Zip\\7z.exe",
    "D:\\Program Files\\7-Zip\\7z.exe",
    "D:\\Program Files (x86)\\7-Zip\\7z.exe"
  )
  foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
  return $null
}

function Find-WinRAR {
  if ($WinRarPath -and (Test-Path $WinRarPath)) { return $WinRarPath }
  # Prefer console rar.exe first
  $cmd = Get-Command 'rar.exe' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  $cmd = Get-Command 'winrar.exe' -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  $candidates = @(
    "C:\\Program Files\\WinRAR\\rar.exe",
    "C:\\Program Files (x86)\\WinRAR\\rar.exe",
    "C:\\Program Files\\WinRAR\\winrar.exe",
    "C:\\Program Files (x86)\\WinRAR\\winrar.exe",
    "D:\\Program Files\\WinRAR\\rar.exe",
    "D:\\Program Files (x86)\\WinRAR\\rar.exe",
    "D:\\Program Files\\WinRAR\\winrar.exe",
    "D:\\Program Files (x86)\\WinRAR\\winrar.exe"
  )
  foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
  return $null
}

$UsePutty = $false
if ($Password) { $UsePutty = $true }

if (-not $UsePutty) {
  if (-not (Test-CommandExists 'ssh')) { throw 'ssh is not available. Install OpenSSH Client on Windows.' }
  if (-not (Test-CommandExists 'scp')) { throw 'scp is not available. Install OpenSSH Client on Windows.' }
} else {
  $PlinkPath = Find-ToolPath -Name 'plink.exe' -HintDir $PuttyDir
  $PscpPath  = Find-ToolPath -Name 'pscp.exe'  -HintDir $PuttyDir
  if (-not $PlinkPath -or -not $PscpPath) {
    throw 'Password mode requires PuTTY tools: plink.exe and pscp.exe (install PuTTY).'
  }
}

function Invoke-ScpWrapper {
  param([string]$LocalPath, [string]$RemoteDestDir)
  if (-not $UsePutty) {
    $args = @()
    if ($KeyPath) { $args += @('-i', $KeyPath) }
    if ($Port) { $args += @('-P', $Port) }
    $args += @('-q', $LocalPath, "${SshUser}@${Server}:${RemoteDestDir}/")
    & scp @args
    if ($LASTEXITCODE -ne 0) { throw "scp failed with exit code ${LASTEXITCODE}: $LocalPath" }
  } else {
    & $PscpPath -batch -q -P $Port -pw $Password $LocalPath "${SshUser}@${Server}:${RemoteDestDir}/"
    if ($LASTEXITCODE -ne 0) { throw "pscp failed with exit code ${LASTEXITCODE}: $LocalPath" }
  }
}

function Invoke-SshWrapper {
  param([string]$Command)
  if (-not $UsePutty) {
    $args = @()
    if ($KeyPath) { $args += @('-i', $KeyPath) }
    if ($Port) { $args += @('-p', $Port) }
    $args += @("${SshUser}@${Server}", $Command)
    & ssh @args
    if ($LASTEXITCODE -ne 0) { throw "ssh failed with exit code ${LASTEXITCODE}: $Command" }
  } else {
    & $PlinkPath -batch -T -P $Port -pw $Password "${SshUser}@${Server}" $Command
    if ($LASTEXITCODE -ne 0) { throw "plink failed with exit code ${LASTEXITCODE}: $Command" }
  }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir '..') | Select-Object -ExpandProperty Path

$StagingDir = Join-Path $ProjectRoot (Join-Path 'dist' ("nx_staging-$Kind"))
New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null

# Upload a Linux-compatible LF copy of the remote ingest script. The repository
# files may use CRLF on Windows, which makes bash reject `case` and `set` lines.
$ingestSourcePath = Join-Path $ProjectRoot 'scripts\server\ingest_nx_files.sh'
$ingestUploadPath = Join-Path $StagingDir 'ingest_nx_files.sh'
$ingestContent = [System.IO.File]::ReadAllText($ingestSourcePath)
$ingestContent = $ingestContent.Replace("`r`n", "`n").Replace("`r", "`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ingestUploadPath, $ingestContent, $utf8NoBom)

$InitFileName = switch ($Channel) {
  'faf' { 'init_faf.lua' }
  'fafbeta' { 'init_fafbeta.lua' }
  default { $null }
}
$InitStagingPath = $null
$ExecutableStagingPath = $null

if (-not $SkipInit -and $InitFileName) {
  $initSourcePath = Join-Path $ProjectRoot $InitFileName
  if (-not (Test-Path -LiteralPath $initSourcePath -PathType Leaf)) {
    throw "Init file for channel '$Channel' was not found: $initSourcePath"
  }

  $InitStagingPath = Join-Path $StagingDir $InitFileName
  Copy-Item -LiteralPath $initSourcePath -Destination $InitStagingPath -Force
  Write-Host "Prepared init: $InitStagingPath"
} elseif (-not $SkipInit) {
  Write-Warning "No init file mapping exists for channel '$Channel'; only archives will be published."
}

if ($ExecutablePath) {
  $executableCandidates = @($ExecutablePath)
  if (-not [System.IO.Path]::IsPathRooted($ExecutablePath)) {
    $executableCandidates += Join-Path $ProjectRoot $ExecutablePath
  }

  $executableSourcePath = $null
  foreach ($candidate in ($executableCandidates | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      $executableSourcePath = (Resolve-Path -LiteralPath $candidate).Path
      break
    }
  }
  if (-not $executableSourcePath) {
    throw "Executable was not found: $ExecutablePath"
  }
  if ([System.IO.Path]::GetFileName($executableSourcePath) -ine 'ForgedAlliance.exe') {
    throw "Executable must be named ForgedAlliance.exe: $executableSourcePath"
  }

  $ExecutableStagingPath = Join-Path $StagingDir 'ForgedAlliance.exe'
  Copy-Item -LiteralPath $executableSourcePath -Destination $ExecutableStagingPath -Force
  Write-Host "Prepared executable: $ExecutableStagingPath"
}

# Normalize Archives: support comma-separated values like "lua,units,loc"
$Archives = $Archives |
  ForEach-Object { ($_ -split ',') } |
  ForEach-Object { $_.Trim() } |
  Where-Object { $_ -ne '' } |
  Select-Object -Unique

function Build-Archive {
  param([string]$Name)

  $src = Join-Path $ProjectRoot $Name
  if (-not (Test-Path $src)) {
    Write-Warning "Source folder not found, skipping: $Name"
    return
  }
  $zipPath = Join-Path $StagingDir ("$Name.zip")
  $nxPath = Join-Path $StagingDir ("$Name.$Kind")
  if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
  if (Test-Path $nxPath) { Remove-Item $nxPath -Force }

  $winrar = $null
  if ($UseWinRar) { $winrar = Find-WinRAR }
  if ($winrar) {
    # Build via WinRAR to match manual packaging: ZIP, best compression, keep folder as root
    Push-Location $ProjectRoot
    try {
      $m = '5'  # m5 = best
      # Include the folder itself as root in archive
      Write-Host ('[WinRAR] {0} a -afzip -r -m{1} -idq "{2}" "{3}"' -f $winrar, $m, $zipPath, $Name)
      $args = @('a','-afzip','-r',("-m{0}" -f $m),'-idq',"$zipPath", "$Name")
      $proc = Start-Process -FilePath $winrar -ArgumentList $args -NoNewWindow -Wait -PassThru
      $exit = $proc.ExitCode
    } finally {
      Pop-Location
    }
    if (-not (Test-Path $zipPath)) { throw "WinRAR did not create archive: $zipPath. ExitCode=$exit" }
    Move-Item -Path $zipPath -Destination $nxPath -Force
  } elseif ($seven = Find-SevenZip) {
    Push-Location $ProjectRoot
    try {
      $mx = if ($Compression -eq 'Store') { '0' } else { '9' }
      # Exclude common dev artifacts; keep only content
      & $seven a -tzip -mx=$mx `
        -x!".git" -x!".git/**" -x!".github" -x!".github/**" `
        -x!"**/*.md" -x!"**/*.ps1" -x!"**/*.psm1" -x!"**/*.sh" -x!"**/*.bat" -x!"**/*.txt" `
        -- "$zipPath" "$Name\"
    } finally {
      Pop-Location
    }
    Move-Item -Path $zipPath -Destination $nxPath -Force
  } else {
    # Fallback to Compress-Archive
    $level = if ($Compression -eq 'Store') { 'NoCompression' } else { 'Optimal' }
    Compress-Archive -Path $src -DestinationPath $zipPath -CompressionLevel $level -Force
    Move-Item -Path $zipPath -Destination $nxPath -Force
  }

  Write-Host "Built: $nxPath"
}

if (-not $SkipBuild) {
  foreach ($name in $Archives) { Build-Archive -Name $name }
} else {
  Write-Host "SkipBuild set; using existing files in $StagingDir"
}

$localFiles = @(Get-ChildItem -Path $StagingDir -Filter "*.$Kind" -File |
  Where-Object { $Archives -contains ([System.IO.Path]::GetFileNameWithoutExtension($_.Name)) } |
  Select-Object -ExpandProperty FullName)
if (-not $localFiles -or $localFiles.Count -eq 0) { throw "No selected *.$Kind files found in $StagingDir" }

# Export from the ACTUAL archive being published (also when -SkipBuild is used),
# not from a potentially different working-tree GameColors.lua.
$PaletteStagingPath = $null
$PaletteExporterPath = Join-Path $ProjectRoot 'scripts\export_game_colors.py'
if ($Archives -contains 'lua') {
  if (-not (Test-CommandExists 'python')) { throw 'Python is required to validate/export the game color palette.' }
  $PaletteStagingPath = Join-Path $StagingDir "game-colors-$Channel.json"
  & python $PaletteExporterPath (Join-Path $StagingDir "lua.$Kind") --output $PaletteStagingPath
  if ($LASTEXITCODE -ne 0) { throw 'Palette export failed; no files have been published.' }
}

# Upload remote ingest script
$remoteIngestPath = "/tmp/ingest_nx_files.sh"
Invoke-ScpWrapper -LocalPath $ingestUploadPath -RemoteDestDir "/tmp"
$remotePrep = 'mkdir -p {0} && bash -n {1} && chmod +x {1}' -f $RemoteStagingDir, $remoteIngestPath
Invoke-SshWrapper -Command "bash -lc '$remotePrep'"

if ($CleanStaging) {
  Invoke-SshWrapper -Command ("bash -lc 'rm -f {0}/*.{1} || true'" -f $RemoteStagingDir, $Kind)
  if ($InitStagingPath) {
    Invoke-SshWrapper -Command ("bash -lc 'rm -f {0}/{1} || true'" -f $RemoteStagingDir, $InitFileName)
  }
  if ($ExecutableStagingPath) {
    Invoke-SshWrapper -Command ("bash -lc 'rm -f {0}/ForgedAlliance.exe || true'" -f $RemoteStagingDir)
  }
}

# Upload archives and the channel init file.
foreach ($f in $localFiles) {
  Invoke-ScpWrapper -LocalPath $f -RemoteDestDir $RemoteStagingDir
}
if ($PaletteStagingPath) {
  Invoke-ScpWrapper -LocalPath $PaletteStagingPath -RemoteDestDir $RemoteStagingDir
  Invoke-ScpWrapper -LocalPath $PaletteExporterPath -RemoteDestDir $RemoteStagingDir
}
if ($InitStagingPath) {
  Invoke-ScpWrapper -LocalPath $InitStagingPath -RemoteDestDir $RemoteStagingDir
}
if ($ExecutableStagingPath) {
  Invoke-ScpWrapper -LocalPath $ExecutableStagingPath -RemoteDestDir $RemoteStagingDir
}

# Run ingest remotely (auto-bumps versions and updates DB)
# Note: invoke via `bash <script>` instead of executing the file directly.
# Running it directly right after upload can fail with
# "/usr/bin/env: bad interpreter: Text file busy" (ETXTBSY) because the
# freshly-uploaded file may still be held open for writing.
$remoteCmd = "bash $remoteIngestPath --script-base $RemoteScriptBase --staging $RemoteStagingDir --channel $Channel --kind $Kind"
if ($DryRun) { $remoteCmd = "$remoteCmd --dry-run" }
if ($Archives -and $Archives.Count -gt 0) {
  $onlyArg = ($Archives -join ',')
  $remoteCmd = "$remoteCmd --only $onlyArg"
}
if ($InitStagingPath) {
  $remoteCmd = "$remoteCmd --init $InitFileName"
}
if ($ExecutableStagingPath) {
  $remoteCmd = "$remoteCmd --exe ForgedAlliance.exe"
}
if ($PaletteStagingPath) {
  $remoteCmd = "$remoteCmd --palette game-colors-$Channel.json"
}
Invoke-SshWrapper -Command "bash -lc '$remoteCmd'"

if ($DryRun) {
  Write-Host "DRY-RUN complete. No changes made."
} else {
  $initSummary = if ($InitStagingPath) { " and $InitFileName" } else { '' }
  $exeSummary = if ($ExecutableStagingPath) { ' and ForgedAlliance.exe' } else { '' }
  Write-Host "Done. Published archives$initSummary$exeSummary for channel=$Channel kind=$Kind from $StagingDir"
}
