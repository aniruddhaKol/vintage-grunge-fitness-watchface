param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = Join-Path $Project 'assets/432x514-amazfit-bip-max'
$baselineAssets = Join-Path $BaselineProject 'assets/432x514-amazfit-bip-max'

function Restore-Parchment($original, $background, $region, $sourceY) {
  for ($y = $region.Top; $y -lt $region.Bottom; $y++) {
    for ($x = $region.Left; $x -lt $region.Right; $x++) {
      $inset = [Math]::Min([Math]::Min($x-$region.Left, $region.Right-1-$x),
                          [Math]::Min($y-$region.Top, $region.Bottom-1-$y))
      $weight = [Math]::Min(1, $inset / 3.0)
      $old = $original.GetPixel($x, $y)
      $texture = $original.GetPixel($x, (& $sourceY $y))
      $background.SetPixel($x, $y, [Drawing.Color]::FromArgb(
        [int]($old.R + ($texture.R-$old.R)*$weight),
        [int]($old.G + ($texture.G-$old.G)*$weight),
        [int]($old.B + ($texture.B-$old.B)*$weight)))
    }
  }
}

function New-Capsule($x, $y, $width, $height) {
  $path = [Drawing.Drawing2D.GraphicsPath]::new()
  $path.AddArc($x, $y, $height, $height, 90, 180)
  $path.AddArc(($x+$width-$height), $y, $height, $height, 270, 180)
  $path.CloseFigure()
  return $path
}

function Save-Asset($bitmap, $name) {
  $bitmap.Save((Join-Path $assets $name), [Drawing.Imaging.ImageFormat]::Png)
}

$backgroundPath = Join-Path $baselineAssets 'background.png'
$original = [Drawing.Bitmap]::new($backgroundPath)
$background = [Drawing.Bitmap]::new($original)

# The prior heart translation left a flat tan silhouette and a pale edge.
$shadowSeeds = @(foreach ($y in 40..64) {
  foreach ($x in 33..52) {
    $pixel = $original.GetPixel($x,$y)
    if ($pixel.R -eq 211 -and $pixel.G -eq 174 -and $pixel.B -eq 126) {
      [Drawing.Point]::new($x,$y)
    }
  }
})
$shadowWeights = @{}
foreach ($seed in $shadowSeeds) {
  foreach ($dy in -2..2) {
    foreach ($dx in -2..2) {
      $x = $seed.X + $dx
      $y = $seed.Y + $dy
      $key = $y * 432 + $x
      $weight = if ([Math]::Max([Math]::Abs($dx),[Math]::Abs($dy)) -le 1) { 1.0 } else { 0.65 }
      $shadowWeights[$key] = [Math]::Max([double]$shadowWeights[$key],$weight)
    }
  }
}
foreach ($key in $shadowWeights.Keys) {
  $y = [int][Math]::Floor($key / 432)
  $x = $key % 432
  $pixel = $original.GetPixel($x,$y)
  # Protect the metal rim and the red pixels of the current heart.
  if ($pixel.R -lt 155 -or ($pixel.G -lt 130 -and $pixel.R -gt 1.4 * $pixel.G)) { continue }
  $texture = $original.GetPixel($x+14,$y+28)
  $weight = $shadowWeights[$key]
  $background.SetPixel($x,$y,[Drawing.Color]::FromArgb(
    [int]($pixel.R + ($texture.R-$pixel.R)*$weight),
    [int]($pixel.G + ($texture.G-$pixel.G)*$weight),
    [int]($pixel.B + ($texture.B-$pixel.B)*$weight)))
}

# Move the existing blue lettering eight pixels left to the section midpoint.
Restore-Parchment $original $background ([Drawing.Rectangle]::FromLTRB(193,29,253,52)) { param($y) $y+25 }
foreach ($y in 31..50) {
  foreach ($x in 200..247) {
    $pixel = $original.GetPixel($x,$y)
    if ($pixel.B -gt ($pixel.R+8)) { $background.SetPixel($x-8,$y,$pixel) }
  }
}

Restore-Parchment $original $background ([Drawing.Rectangle]::FromLTRB(49,309,90,328)) { param($y) $y-40 }
Restore-Parchment $original $background ([Drawing.Rectangle]::FromLTRB(47,438,351,481)) {
  param($y)
  477 + [Math]::Min(($y-438)%20, 20-($y-438)%20)
}
$original.Dispose()

$g = [Drawing.Graphics]::FromImage($background)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$outline = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#312a21'))
$track = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#998770'))
$tick = [Drawing.Pen]::new($outline, 2)
$shell = New-Capsule 85 453 258 26
$channel = New-Capsule 89 456 250 20
$g.FillPath($outline, $shell)
$g.FillPath($track, $channel)
foreach ($decile in 0..10) {
  $x = 89 + 25 * $decile
  $g.DrawLine($tick, $x, 442, $x, 449)
}

$g.Dispose()
$shell.Dispose()
$channel.Dispose()
$tick.Dispose()
$track.Dispose()
Save-Asset $background 'background.png'
$background.Dispose()

$fillShape = New-Capsule 0 0 250 20
$red = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#ed3232'))
$amber = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#e8a717'))
$green = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#3cb371'))

$iconColors = [ordered]@{ red = $red; amber = $amber; green = $green }
[Drawing.Point[]]$bolt = @(
  [Drawing.Point]::new(12,10), [Drawing.Point]::new(4,23),
  [Drawing.Point]::new(9,23), [Drawing.Point]::new(7,33),
  [Drawing.Point]::new(16,19), [Drawing.Point]::new(11,19))
foreach ($entry in $iconColors.GetEnumerator()) {
  $image = [Drawing.Bitmap]::new(20,39)
  $g = [Drawing.Graphics]::FromImage($image)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.FillRectangle($outline, 5, 0, 10, 4)
  $g.FillRectangle($outline, 0, 4, 20, 35)
  $g.FillRectangle($entry.Value, 3, 7, 14, 29)
  $g.FillPolygon([Drawing.Brushes]::Ivory, $bolt)
  Save-Asset $image "battery-icon-$($entry.Key).png"
  $g.Dispose()
  $image.Dispose()
}
$outline.Dispose()

foreach ($level in 0..100) {
  $image = [Drawing.Bitmap]::new(250,20)
  $g = [Drawing.Graphics]::FromImage($image)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $color = if ($level -lt 20) { $red } elseif ($level -le 50) { $amber } else { $green }
  $g.FillPath($color, $fillShape)
  $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
  $width = [int][Math]::Floor(250 * $level / 100)
  $g.FillRectangle([Drawing.Brushes]::Transparent, $width, 0, (250-$width), 20)
  Save-Asset $image "battery-level-$level.png"
  $g.Dispose()
  $image.Dispose()
}
$fillShape.Dispose()
$red.Dispose()
$amber.Dispose()
$green.Dispose()

foreach ($name in @((0..9 | ForEach-Object { "battery-$_" })) + @('percent')) {
  $source = [Drawing.Bitmap]::new((Join-Path $baselineAssets "$name.png"))
  $width = [int][Math]::Round($source.Width * 29 / 25)
  $image = [Drawing.Bitmap]::new($width, 29)
  $g = [Drawing.Graphics]::FromImage($image)
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($source, 0, 0, $width, 29)
  $source.Dispose()
  Save-Asset $image "$name.png"
  $g.Dispose()
  $image.Dispose()
}

$months = @('JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC')
$font = [Drawing.Font]::new('Impact', 25, [Drawing.GraphicsUnit]::Pixel)
$monthInk = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#002798'))
$format = [Drawing.StringFormat]::new()
$format.Alignment = $format.LineAlignment = [Drawing.StringAlignment]::Center
$format.FormatFlags = [Drawing.StringFormatFlags]::NoWrap
$format.Trimming = [Drawing.StringTrimming]::None
for ($i = 0; $i -lt $months.Length; $i++) {
  $image = [Drawing.Bitmap]::new(66,29)
  $g = [Drawing.Graphics]::FromImage($image)
  $g.TextRenderingHint = [Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  if ($g.MeasureString($months[$i], $font).Width -gt 64) { throw "Month text does not fit: $($months[$i])" }
  $g.DrawString($months[$i], $font, $monthInk, [Drawing.RectangleF]::new(0,0,66,29), $format)
  Save-Asset $image "month-$i.png"
  $g.Dispose()
  $image.Dispose()
}
$format.Dispose()
$font.Dispose()
$monthInk.Dispose()
