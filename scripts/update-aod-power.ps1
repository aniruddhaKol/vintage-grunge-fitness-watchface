param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assetDirectory = 'assets/432x514-amazfit-bip-max'
$baseline = Join-Path $BaselineProject $assetDirectory
$target = Join-Path $Project $assetDirectory
$original = [Drawing.Bitmap]::new((Join-Path $baseline 'aod-background.png'))
$background = $original.Clone([Drawing.Rectangle]::new(0,0,$original.Width,$original.Height),$original.PixelFormat)

# Replace the old ticks with dark texture sampled within the power panel.
# The original rounded track, screws, and surrounding trim are retained.
foreach ($y in 424..440) {
  $textureY = 476 + [Math]::Min($y-424,440-$y)
  foreach ($x in 122..326) {
    $weight = [Math]::Min(1,[Math]::Min([Math]::Min($y-424,440-$y),[Math]::Min($x-122,326-$x))/2.0)
    $old = $original.GetPixel($x,$y)
    $texture = $original.GetPixel($x,$textureY)
    $background.SetPixel($x,$y,[Drawing.Color]::FromArgb(
      $old.A,
      [int]($old.R+($texture.R-$old.R)*$weight),
      [int]($old.G+($texture.G-$old.G)*$weight),
      [int]($old.B+($texture.B-$old.B)*$weight)))
  }
}
$graphics = [Drawing.Graphics]::FromImage($background)
$tick = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#a79883'),2)
foreach ($decile in 0..10) {
  $x = 85 + 25*$decile
  $graphics.DrawLine($tick,$x,429,$x,437)
}
$tick.Dispose()
$graphics.Dispose()
$background.Save((Join-Path $target 'aod-background.png'),[Drawing.Imaging.ImageFormat]::Png)
$background.Dispose()
$original.Dispose()

# Use the awake shapes and palette with the same opacity for the AOD icon and fill.
$dim = [Drawing.Imaging.ColorMatrix]::new()
$dim.Matrix33 = 0.62
$attributes = [Drawing.Imaging.ImageAttributes]::new()
$attributes.SetColorMatrix($dim)
$names = @((0..100 | ForEach-Object { "battery-level-$_.png" })) +
         @('battery-icon-red.png','battery-icon-amber.png','battery-icon-green.png')
foreach ($name in $names) {
  $source = [Drawing.Bitmap]::new((Join-Path $baseline $name))
  $image = [Drawing.Bitmap]::new($source.Width,$source.Height)
  $graphics = [Drawing.Graphics]::FromImage($image)
  $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
  $bounds = [Drawing.Rectangle]::new(0,0,$source.Width,$source.Height)
  $graphics.DrawImage($source,$bounds,0,0,$source.Width,$source.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)
  $graphics.Dispose()
  $image.Save((Join-Path $target "aod-$name"),[Drawing.Imaging.ImageFormat]::Png)
  $image.Dispose()
  $source.Dispose()
}
$attributes.Dispose()
