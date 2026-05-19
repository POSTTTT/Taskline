# Generates the Windows app icon (.ico) from a source PNG.
#
# Input:
#   taskline/windows/runner/resources/taskline_logo.png  (square, >=256, ideally 1024)
#
# Output:
#   taskline/windows/runner/resources/app_icon.ico       (multi-resolution .ico)
#
# Re-run this whenever the PNG changes.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$resourcesDir = Join-Path $repoRoot 'taskline\windows\runner\resources'
$sourcePath = Join-Path $resourcesDir 'taskline_logo.png'
$icoPath = Join-Path $resourcesDir 'app_icon.ico'

if (-not (Test-Path $sourcePath)) {
    Write-Error "Source PNG not found at $sourcePath. Drop a square PNG there and re-run."
    exit 1
}

$source = [System.Drawing.Image]::FromFile($sourcePath)
$srcW = $source.Width
$srcH = $source.Height
Write-Output "Source $sourcePath is ${srcW}x${srcH}"

if ($srcW -ne $srcH) {
    Write-Warning "Source is not square (${srcW}x${srcH}); icon will be stretched."
}

function Resize-Bitmap([System.Drawing.Image]$src, [int]$size) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode =
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode =
        [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality =
        [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose()
    return $bitmap
}

# Build the multi-resolution .ico. Modern Windows reads embedded PNG at any
# size, so we PNG-encode every entry for simplicity.
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngBlobs = @()
foreach ($s in $sizes) {
    $bmp = Resize-Bitmap $source $s
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBlobs += ,$ms.ToArray()
    $ms.Dispose()
    $bmp.Dispose()
}
$source.Dispose()

$out = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($out)

# ICONDIR header
$writer.Write([UInt16]0)         # reserved
$writer.Write([UInt16]1)         # type = icon
$writer.Write([UInt16]$sizes.Length)

# ICONDIRENTRY for each size
$offset = 6 + (16 * $sizes.Length)
for ($i = 0; $i -lt $sizes.Length; $i++) {
    $s = $sizes[$i]
    $blob = $pngBlobs[$i]
    $byteSize = if ($s -ge 256) { [byte]0 } else { [byte]$s }
    $writer.Write([byte]$byteSize)   # width  (0 = 256)
    $writer.Write([byte]$byteSize)   # height (0 = 256)
    $writer.Write([byte]0)           # color count
    $writer.Write([byte]0)           # reserved
    $writer.Write([UInt16]1)         # color planes
    $writer.Write([UInt16]32)        # bits per pixel
    $writer.Write([UInt32]$blob.Length)
    $writer.Write([UInt32]$offset)
    $offset += $blob.Length
}

# PNG image data, concatenated
foreach ($blob in $pngBlobs) { $writer.Write($blob) }

$writer.Flush()
[System.IO.File]::WriteAllBytes($icoPath, $out.ToArray())
$writer.Dispose()
$out.Dispose()

$sizesJoined = $sizes -join ','
Write-Output "Wrote $icoPath with sizes $sizesJoined"
