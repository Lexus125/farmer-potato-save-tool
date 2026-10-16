param(
    [string]$SaveDir  = "$env:USERPROFILE\AppData\LocalLow\Oni Gaming\Farmer Against Potatoes Idle",
    [string]$FileName = "fapi-save.txt",
    [string]$Salt     = "A Potato has more Chromosomes than a Human being",
    [double]$Value    = 99999999,
    [string[]]$Fields = @("FreeSoul","TotalSoul"),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$savePath = Join-Path $SaveDir $FileName
if (-not (Test-Path $savePath)) {
    Write-Host "Файл не найден: $savePath" -ForegroundColor Red
    return
}

$bytes = [System.IO.File]::ReadAllBytes($savePath)
if ($bytes.Length -lt 10 -or $bytes[0] -ne 0x1F -or $bytes[1] -ne 0x8B) {
    Write-Host "Это не gzip-файл. Первые байты: $((($bytes[0..3]) | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Red
    return
}

$msIn  = New-Object System.IO.MemoryStream(,$bytes)
$gzIn  = New-Object System.IO.Compression.GZipStream($msIn,[System.IO.Compression.CompressionMode]::Decompress)
$msOut = New-Object System.IO.MemoryStream
try { $gzIn.CopyTo($msOut) } finally { $gzIn.Dispose(); $msIn.Dispose() }
$raw = [System.Text.Encoding]::UTF8.GetString($msOut.ToArray())

Write-Host "Распаковано: $($raw.Length) символов" -ForegroundColor Cyan

$sigMatch = [regex]::Match($raw, '([A-Za-z0-9+/]{43}=)\s*$')
if (-not $sigMatch.Success) {
    Write-Host "Не нашли Base64-подпись в конце." -ForegroundColor Red
    return
}
$oldSig = $sigMatch.Groups[1].Value
$body   = $raw.Substring(0, $sigMatch.Index)

$firstBrace = $body.IndexOf('{')
$lastBrace  = $body.LastIndexOf('}')
$json = $body.Substring($firstBrace, $lastBrace - $firstBrace + 1)

Write-Host "Старая подпись: $oldSig" -ForegroundColor DarkGray

$enc       = [System.Text.Encoding]::UTF8
$saltBytes = $enc.GetBytes($Salt)

function Get-Sig([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $h = $sha.ComputeHash($saltBytes + $enc.GetBytes($text)) } finally { $sha.Dispose() }
    return [Convert]::ToBase64String($h)
}

$checkSig = Get-Sig $json
if ($checkSig -ne $oldSig) {
    Write-Host "ВНИМАНИЕ: подпись оригинала не совпала. Продолжаем всё равно." -ForegroundColor Yellow
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$newJson = $json

foreach ($field in $Fields) {
    $pat = '"' + [regex]::Escape($field) + '":(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)'
    $re  = [regex]::new($pat)
    $m   = $re.Match($newJson)
    if (-not $m.Success) {
        Write-Host "  [$field] не найдено в JSON — пропускаем" -ForegroundColor Yellow
        continue
    }

    $oldValStr = $m.Groups[1].Value
    $oldVal    = [double]::Parse($oldValStr, $inv)
    $newValNum = $oldVal + $Value

    if ($oldValStr -match '[.\eE]') {
        $newValStr = $newValNum.ToString("R", $inv)
        if ($newValStr -notmatch '[.\eE]') { $newValStr += ".0" }
    } else {
        $newValStr = [long]$newValNum
    }

    $newJson = $newJson.Substring(0, $m.Index) + '"' + $field + '":' + $newValStr + $newJson.Substring($m.Index + $m.Length)
    Write-Host ("  [{0}] {1} + {2} -> {3}" -f $field, $oldValStr, $Value, $newValStr) -ForegroundColor Green
}

if ($newJson -eq $json) {
    Write-Host "Ничего не изменилось." -ForegroundColor Yellow
    return
}

$newSig = Get-Sig $newJson
Write-Host "Новая подпись : $newSig" -ForegroundColor Green

$plain = $newJson + $newSig
$plainBytes = $enc.GetBytes($plain)

$msGz  = New-Object System.IO.MemoryStream
$gzOut = New-Object System.IO.Compression.GZipStream($msGz, [System.IO.Compression.CompressionLevel]::Optimal)
try { $gzOut.Write($plainBytes, 0, $plainBytes.Length) } finally { $gzOut.Dispose() }
$gzBytes = $msGz.ToArray()

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY RUN: файл НЕ записан. Размер нового gzip: $($gzBytes.Length) байт" -ForegroundColor Yellow
    return
}

$backup = $savePath + ".bak"
Copy-Item -LiteralPath $savePath -Destination $backup -Force
[System.IO.File]::WriteAllBytes($savePath, $gzBytes)

Write-Host ""
Write-Host "Готово." -ForegroundColor Green
Write-Host "  Файл:   $savePath" -ForegroundColor Green
Write-Host "  Размер: $($gzBytes.Length) байт (было $($bytes.Length))" -ForegroundColor Green
Write-Host "  Бэкап:  $backup" -ForegroundColor Green
