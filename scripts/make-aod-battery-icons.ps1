param([Parameter(Mandatory)][string]$Project)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = Join-Path $Project 'assets/432x514-amazfit-bip-max'
$levels = [ordered]@{ red=19; amber=35; green=75 }
[Drawing.Point[]]$body = @(
  [Drawing.Point]::new(5,0), [Drawing.Point]::new(15,0),
  [Drawing.Point]::new(15,4), [Drawing.Point]::new(18,4),
  [Drawing.Point]::new(20,6), [Drawing.Point]::new(20,37),
  [Drawing.Point]::new(18,39), [Drawing.Point]::new(2,39),
  [Drawing.Point]::new(0,37), [Drawing.Point]::new(0,6),
  [Drawing.Point]::new(2,4), [Drawing.Point]::new(5,4))
[Drawing.Point[]]$bolt = @(
  [Drawing.Point]::new(13,6), [Drawing.Point]::new(2,24),
  [Drawing.Point]::new(8,24), [Drawing.Point]::new(6,37),
  [Drawing.Point]::new(18,18), [Drawing.Point]::new(11,18))

foreach ($level in $levels.GetEnumerator()) {
  $bar = [Drawing.Bitmap]::new((Join-Path $assets "aod-battery-level-$($level.Value).png"))
  $color = $bar.GetPixel(12,10)
  $bar.Dispose()
  $fill = [Drawing.SolidBrush]::new($color)
  $image = [Drawing.Bitmap]::new(20,39)
  $g = [Drawing.Graphics]::FromImage($image)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
  $g.FillPolygon($fill,$body)
  $g.Dispose()
  $fill.Dispose()
  $mask = [Drawing.Bitmap]::new($image.Width,$image.Height)
  $g = [Drawing.Graphics]::FromImage($mask)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.FillPolygon([Drawing.Brushes]::Ivory,$bolt)
  $g.Dispose()
  $light = [Drawing.Color]::Ivory
  for ($y = 0; $y -lt $image.Height; $y++) {
    for ($x = 0; $x -lt $image.Width; $x++) {
      $coverage = $mask.GetPixel($x,$y).A / 255.0
      if ($coverage -eq 0) { continue }
      $paint = $image.GetPixel($x,$y)
      if ($paint.A -eq 0) { throw "The lightning bolt extends past the battery body at $x,$y." }
      $image.SetPixel($x,$y,[Drawing.Color]::FromArgb(
        $paint.A,
        [int]($paint.R+($light.R-$paint.R)*$coverage),
        [int]($paint.G+($light.G-$paint.G)*$coverage),
        [int]($paint.B+($light.B-$paint.B)*$coverage)))
    }
  }
  $mask.Dispose()
  $image.Save((Join-Path $assets "aod-battery-icon-$($level.Key).png"),[Drawing.Imaging.ImageFormat]::Png)
  $image.Dispose()
}
