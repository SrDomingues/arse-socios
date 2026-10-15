# Reconstruye index.html a partir de la página del artefacto y su snapshot.json.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 <page.html> <snapshot.json>
# Equivale a build.py para equipos sin Python. La lista de cotizadas sale de data\universe.json.
param([Parameter(Mandatory)][string]$Page, [Parameter(Mandatory)][string]$Snapshot)
$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)
$root = $PSScriptRoot
$h = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Page), $enc).Replace("`r`n", "`n")
$s = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Snapshot), $enc)
$u = [IO.File]::ReadAllText((Join-Path $root 'data\universe.json'), $enc)

$snap = $s | ConvertFrom-Json
$n = ($snap.companies.PSObject.Properties | Measure-Object).Count
$na = ($snap.analyses.PSObject.Properties | Measure-Object).Count
if ($n -lt 100 -or $na -lt 100) { throw "snapshot incompleto: $n empresas, $na análisis" }

$reps = @(
  @('const r = await fetch("universe.json"); const j = await r.json();', 'const j = JSON.parse(document.getElementById("data-universe").textContent);'),
  @('fetch("snapshot.json").then(r => r.json()).then(j => {', 'Promise.resolve().then(() => JSON.parse(document.getElementById("data-snapshot").textContent)).then(j => {'),
  @('; se refrescan tres veces cada día laborable (hacia las 9:40, 18:40 y 23:40, hora de Madrid)', '; se refrescan tres veces cada día laborable'),
  @('<title>Círculo de Competencia</title>', '<title>Círculo de Competencia · ARSE Socios</title>')
)
foreach ($r in $reps) { if (-not $h.Contains($r[0])) { throw "No encontrado en la página: $($r[0])" }; $h = $h.Replace($r[0], $r[1]) }

$anchor = "`n<script>`n(() => {"
$i = $h.IndexOf($anchor)
if ($i -lt 0) { throw 'No se encontró el script principal' }
$data = "`n<script type=`"application/json`" id=`"data-universe`">" + $u.Trim().Replace('<', '<') + "</script>" +
        "`n<script type=`"application/json`" id=`"data-snapshot`">" + $s.Trim().Replace('<', '<') + "</script>"
$h = $h.Insert($i, $data)
[IO.File]::WriteAllText((Join-Path $root 'index.html'), $h, $enc)
"index.html: $n empresas, asOf $($snap.asOf)"
