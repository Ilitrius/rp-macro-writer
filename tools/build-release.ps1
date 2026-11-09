# Baut das Release-ZIP fuer CurseForge: .release\rp-macro-writer-<Version>.zip
# Inhalt: ein Ordner "rp-macro-writer" mit TOC, den in der TOC gelisteten Lua-Dateien, Icon und Changelog.
# Aufruf:  pwsh tools\build-release.ps1
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$name = 'rp-macro-writer'
$toc = Join-Path $root "$name.toc"

$version = (Select-String -LiteralPath $toc -Pattern '^## Version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()

# Alle Dateien, die die TOC laedt (Zeilen ohne "#"), plus feste Beigaben
$loaded = Get-Content -LiteralPath $toc | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
$files = @("$name.toc") + $loaded + @('icon.tga', 'CHANGELOG.md')

foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $f))) { throw "Datei fehlt: $f" }
}

$outDir = Join-Path $root '.release'
New-Item -ItemType Directory -Force $outDir | Out-Null
$zip = Join-Path $outDir "$name-$version.zip"
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Confirm:$false }

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    foreach ($f in $files) {
        # Eintragsnamen mit "/" – so erwarten es CurseForge und die Addon-Manager
        $entry = "$name/" + ($f -replace '\\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $root $f), $entry) | Out-Null
    }
} finally {
    $archive.Dispose()
}

"Erstellt: $zip"
[System.IO.Compression.ZipFile]::OpenRead($zip).Entries | ForEach-Object { '  {0,-34} {1,7} Bytes' -f $_.FullName, $_.Length }
