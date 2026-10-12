$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing
$matrix = Get-Content (Join-Path $projectRoot 'previews/zepp-qr-matrix.json') -Raw | ConvertFrom-Json
$scale = 12
$quiet = 4
$side = ($matrix.Count+2*$quiet)*$scale
$bmp = New-Object System.Drawing.Bitmap($side,$side)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::White)
for ($y=0;$y -lt $matrix.Count;$y++) {
  for ($x=0;$x -lt $matrix.Count;$x++) {
    if($matrix[$y][$x]) { $g.FillRectangle([System.Drawing.Brushes]::Black,($x+$quiet)*$scale,($y+$quiet)*$scale,$scale,$scale) }
  }
}
$bmp.Save((Join-Path $projectRoot 'previews/Zepp-Install-QR.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose();$bmp.Dispose()
