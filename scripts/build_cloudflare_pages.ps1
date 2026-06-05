param(
  [string]$OutputDir = "cloudflare-pages"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root $OutputDir
$toolsOut = Join-Path $out "tools"

if (Test-Path -LiteralPath $out) {
  Remove-Item -LiteralPath $out -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $toolsOut | Out-Null

Copy-Item -LiteralPath (Join-Path $root "index.html") -Destination (Join-Path $out "index.html")
Copy-Item -LiteralPath (Join-Path $root "tools\index.html") -Destination (Join-Path $toolsOut "index.html")
Copy-Item -LiteralPath (Join-Path $root "tools\pe_price_slider.html") -Destination (Join-Path $toolsOut "pe_price_slider.html")

$headers = @'
/*
  X-Content-Type-Options: nosniff

/index.html
  Cache-Control: no-store

/tools/index.html
  Cache-Control: no-store

/tools/pe_price_slider.html
  Cache-Control: no-store
'@

Set-Content -LiteralPath (Join-Path $out "_headers") -Value $headers -Encoding UTF8

Write-Host "Cloudflare Pages output ready: $out"
