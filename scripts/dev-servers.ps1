<#
.SYNOPSIS
  開発サーバー（API・画面）を、必ず決められたポートで起動・停止・確認する。

.DESCRIPTION
  ポートが他のプロセスに使われていたら、その持ち主を停止してから起動する。
  別ポートで起動することはしない。
    バックエンド（Spring Boot） : 8080
    フロントエンド（Vite）      : 5173
  ポート番号を変えるときは、この表・application.properties・vite.config.ts・CLAUDE.md を一緒に直す。

  自動で停止しない持ち主（報告して終了する）：
    - Windows のシステム（PID 4 以下）
    - Docker・WSL 関連のプロセス（止めると Docker 全体が落ちるため）

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev-servers.ps1 -Action start
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev-servers.ps1 -Action stop
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev-servers.ps1 -Action status
#>
param(
  [ValidateSet('start', 'stop', 'status')][string]$Action = 'status',
  [ValidateSet('all', 'backend', 'frontend')][string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$NodeDir = 'C:\Program Files\nodejs'

$Servers = @(
  [pscustomobject]@{ Name = 'backend'; Port = 8080; Dir = (Join-Path $Root 'backend');  ReadyUrl = 'http://localhost:8080/hello'; TimeoutSec = 300 }
  [pscustomobject]@{ Name = 'frontend'; Port = 5173; Dir = (Join-Path $Root 'frontend'); ReadyUrl = 'http://localhost:5173/';      TimeoutSec = 90 }
)
if ($Target -ne 'all') { $Servers = @($Servers | Where-Object { $_.Name -eq $Target }) }

# 自動では停止しないプロセス名（Docker・WSL 関連）
$ProtectedNames = '^(com\.docker|docker|Docker Desktop|wslrelay|wslhost|wsl|vpnkit|vmmem|vmwp)'

function Get-PortOwners([int]$Port) {
  @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique)
}

function Stop-PortOwners([int]$Port) {
  $owners = Get-PortOwners $Port
  foreach ($ownerPid in $owners) {
    if ($ownerPid -le 4) {
      throw "ポート $Port はシステム（PID $ownerPid）が使用中です。自動では停止しません。ユーザーに確認してください。"
    }
    $proc = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
    $name = if ($proc) { $proc.ProcessName } else { '(不明)' }
    if ($name -match $ProtectedNames) {
      throw "ポート $Port は $name（PID $ownerPid）が使用中です。Docker・WSL 関連のため自動では停止しません。ユーザーに確認してください。"
    }
    Write-Host "[停止] ポート $Port を使用中の $name（PID $ownerPid）を停止します"
    & taskkill.exe /PID $ownerPid /T /F | Out-Null
  }
  # 解放されるまで待つ
  for ($i = 0; $i -lt 30; $i++) {
    if ((Get-PortOwners $Port).Count -eq 0) { return }
    Start-Sleep -Milliseconds 500
  }
  throw "ポート $Port を解放できませんでした。使用中のプロセスを確認してください。"
}

function Show-Status($Server) {
  $owners = Get-PortOwners $Server.Port
  if ($owners.Count -eq 0) {
    Write-Host ("[{0}] ポート {1}: 空き（停止中）" -f $Server.Name, $Server.Port)
  } else {
    foreach ($ownerPid in $owners) {
      $proc = Get-Process -Id $ownerPid -ErrorAction SilentlyContinue
      $name = if ($proc) { $proc.ProcessName } else { '(不明)' }
      Write-Host ("[{0}] ポート {1}: 使用中 {2}（PID {3}）" -f $Server.Name, $Server.Port, $name, $ownerPid)
    }
  }
}

function Start-Server($Server) {
  Stop-PortOwners $Server.Port   # 競合していれば、持ち主を停止して必ず空ける

  $log = Join-Path $env:TEMP ("taskboard-{0}.log" -f $Server.Name)
  $err = Join-Path $env:TEMP ("taskboard-{0}.err" -f $Server.Name)
  Remove-Item $log, $err -ErrorAction SilentlyContinue

  if (Test-Path $NodeDir) { $env:Path = "$NodeDir;$env:Path" }
  if ($Server.Name -eq 'backend') {
    $command = '"' + (Join-Path $Server.Dir 'gradlew.bat') + '" bootRun'
  } else {
    if (-not (Test-Path (Join-Path $Server.Dir 'node_modules'))) {
      Write-Host '[準備] npm install を実行します'
      Push-Location $Server.Dir
      try { & npm.cmd install | Out-Null } finally { Pop-Location }
    }
    $command = 'npm.cmd run dev'
  }

  # 呼び出し元の出力パイプを引き継がないよう、WMI で独立したプロセスとして起動する
  # （Start-Process だと、サーバーが終わるまで呼び出し側が待たされることがある）。
  # PATH は WMI 側に渡らないため、ラッパーの .cmd に明示する。
  $wrapper = Join-Path $env:TEMP ("taskboard-start-{0}.cmd" -f $Server.Name)
  $lines = @(
    '@echo off',
    ('set "PATH={0}"' -f $env:Path),
    ('cd /d "{0}"' -f $Server.Dir),
    ('{0} > "{1}" 2> "{2}"' -f $command, $log, $err)
  )
  [IO.File]::WriteAllLines($wrapper, $lines, [Text.Encoding]::Default)

  Write-Host ("[起動] {0}（ポート {1}）" -f $Server.Name, $Server.Port)
  $created = Invoke-CimMethod -ClassName Win32_Process -MethodName Create `
    -Arguments @{ CommandLine = ('cmd.exe /c "{0}"' -f $wrapper); CurrentDirectory = $Server.Dir }
  if ($created.ReturnValue -ne 0) { throw ("{0} の起動に失敗しました（WMI コード {1}）" -f $Server.Name, $created.ReturnValue) }
  $launcherPid = $created.ProcessId

  $deadline = (Get-Date).AddSeconds($Server.TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 3
    try {
      $res = Invoke-WebRequest $Server.ReadyUrl -UseBasicParsing -TimeoutSec 3
      if ($res.StatusCode -eq 200 -and (Get-PortOwners $Server.Port).Count -gt 0) {
        Write-Host ("[OK] {0} が http://localhost:{1} で起動しました" -f $Server.Name, $Server.Port)
        return
      }
    } catch { }
    if (-not (Get-Process -Id $launcherPid -ErrorAction SilentlyContinue)) { break }   # 起動に失敗して終了した
  }
  Write-Host "---- ログ（末尾）----"
  if (Test-Path $log) { Get-Content $log -Tail 20 }
  if (Test-Path $err) { Get-Content $err -Tail 20 }
  throw ("{0} がポート {1} で起動できませんでした。別ポートでの起動はしません。ログを確認してください。" -f $Server.Name, $Server.Port)
}

switch ($Action) {
  'status' { foreach ($s in $Servers) { Show-Status $s } }
  'stop'   { foreach ($s in $Servers) { Stop-PortOwners $s.Port; Write-Host ("[停止済み] {0}（ポート {1}）" -f $s.Name, $s.Port) } }
  'start'  { foreach ($s in $Servers) { Start-Server $s } }
}
