param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$relative = 'assets/432x514-amazfit-bip-max/background.png'
$original = [Drawing.Bitmap]::new((Join-Path $BaselineProject $relative))
$background = $original.Clone([Drawing.Rectangle]::new(0,0,$original.Width,$original.Height),$original.PixelFormat)

function Test-HeartRed($pixel) {
  return $pixel.R -ge 165 -and ($pixel.R-$pixel.G) -ge 69 -and $pixel.B -ge ($pixel.G-33)
}

# Extend the taper by two pixels. Keep both lobes and the horizontal bounds.
$taperTop = 72
$oldTip = 88
$newTip = 90
for ($y = $taperTop + 1; $y -le $newTip; $y++) {
  $sampleY = $taperTop + [int][Math]::Round(($y-$taperTop)*($oldTip-$taperTop)/($newTip-$taperTop))
  for ($x = 28; $x -le 63; $x++) {
    $sample = $original.GetPixel($x,$sampleY)
    if ((Test-HeartRed $sample) -and !(Test-HeartRed ($original.GetPixel($x,$y)))) {
      $background.SetPixel($x,$y,$sample)
    }
  }
}

$background.Save((Join-Path $Project $relative),[Drawing.Imaging.ImageFormat]::Png)
$background.Dispose()
$original.Dispose()
