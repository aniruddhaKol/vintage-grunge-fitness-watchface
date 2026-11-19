param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$relative = 'assets/432x514-amazfit-bip-max/background.png'
$original = [Drawing.Bitmap]::new((Join-Path $BaselineProject $relative))
$background = $original.Clone([Drawing.Rectangle]::new(0,0,$original.Width,$original.Height),$original.PixelFormat)

# TEMP lettering is painted into the background. Extract just its dark glyphs.
$ink = @(foreach ($y in 317..329) {
  foreach ($x in 355..391) {
    $pixel = $original.GetPixel($x,$y)
    if ($pixel.R -lt 195) {
      [pscustomobject]@{ X=$x; Y=$y; Color=$pixel }
    }
  }
})
if (!$ink.Count) { throw 'TEMP lettering was not found in the source artwork.' }
$horizontal = $ink | Measure-Object -Property X -Minimum -Maximum
$vertical = $ink | Measure-Object -Property Y -Maximum
$offsetX = [int][Math]::Round(363 - ($horizontal.Minimum+$horizontal.Maximum)/2)
$offsetY = 333 - $vertical.Maximum

$patch = @{}
foreach ($pixel in $ink) {
  foreach ($dy in -2..2) {
    foreach ($dx in -2..2) {
      $key = ($pixel.Y+$dy)*432 + ($pixel.X+$dx)
      $weight = if ([Math]::Max([Math]::Abs($dx),[Math]::Abs($dy)) -le 1) { 1.0 } else { 0.55 }
      $patch[$key] = [Math]::Max([double]$patch[$key],$weight)
    }
  }
}
foreach ($key in $patch.Keys) {
  $y = [int][Math]::Floor($key/432)
  $x = $key%432
  $old = $original.GetPixel($x,$y)
  $texture = $original.GetPixel($x,$y-30)
  $weight = $patch[$key]
  $background.SetPixel($x,$y,[Drawing.Color]::FromArgb(
    $old.A,
    [int]($old.R+($texture.R-$old.R)*$weight),
    [int]($old.G+($texture.G-$old.G)*$weight),
    [int]($old.B+($texture.B-$old.B)*$weight)))
}
foreach ($pixel in $ink) {
  $background.SetPixel(($pixel.X+$offsetX),($pixel.Y+$offsetY),$pixel.Color)
}

$background.Save((Join-Path $Project $relative),[Drawing.Imaging.ImageFormat]::Png)
$background.Dispose()
$original.Dispose()
