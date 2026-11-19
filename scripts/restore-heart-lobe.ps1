param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = 'assets/432x514-amazfit-bip-max'
$baseline = Join-Path $BaselineProject $assets
$original = [Drawing.Bitmap]::new((Join-Path $baseline 'background.png'))
$contour = [Drawing.Bitmap]::new((Join-Path $baseline 'rounded-corners.png'))
$background = $original.Clone([Drawing.Rectangle]::new(0,0,$original.Width,$original.Height),$original.PixelFormat)

function Test-HeartRed($pixel) {
  return $pixel.R -ge 165 -and ($pixel.R-$pixel.G) -ge 69 -and $pixel.B -ge ($pixel.G-33)
}

# Complete the left lobe using pixels from the intact right lobe.
# Preserve the existing red pixels, the notch, and the lower point.
foreach ($y in 56..73) {
  foreach ($x in 27..45) {
    $left = $original.GetPixel($x,$y)
    $right = $original.GetPixel((91-$x),$y)
    if (!(Test-HeartRed $right) -or (Test-HeartRed $left)) { continue }
    if ($contour.GetPixel($x-3,$y).A -gt 0) { throw "Heart crosses the display contour at $x,$y" }
    $background.SetPixel($x,$y,$right)
  }
}

$background.Save((Join-Path (Join-Path $Project $assets) 'background.png'),[Drawing.Imaging.ImageFormat]::Png)
$background.Dispose()
$contour.Dispose()
$original.Dispose()
