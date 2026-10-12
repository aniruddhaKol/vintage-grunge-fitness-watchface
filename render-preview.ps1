param([switch]$Aod)
Add-Type -AssemblyName System.Drawing
$root = Join-Path $PSScriptRoot 'assets/432x514-amazfit-bip-max'
$bmp = New-Object System.Drawing.Bitmap(432,514)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Black)
foreach ($item in (Get-Content (Join-Path $PSScriptRoot 'preview-layout.json') -Raw | ConvertFrom-Json)) {
  $img = [System.Drawing.Image]::FromFile((Join-Path $root $item.src))
  $g.DrawImageUnscaled($img,[int]$item.x,[int]$item.y)
  $img.Dispose()
}
$previewName = if ($Aod) {'watchface-aod-preview.png'} else {'watchface-preview.png'}
$bmp.Save((Join-Path $PSScriptRoot $previewName),[System.Drawing.Imaging.ImageFormat]::Png)
if ($Aod) {
  $lit = 0
  for($y=0;$y -lt 514;$y++) { for($x=0;$x -lt 432;$x++) { if($bmp.GetPixel($x,$y).ToArgb() -ne [System.Drawing.Color]::Black.ToArgb()) { $lit++ } } }
  $coverage = [math]::Round(100*$lit/(432*514),2)
  Write-Output "AOD illuminated area: $coverage percent"
  # This release intentionally uses the user's full industrial AOD design.
  $g.Dispose();$bmp.Dispose()
  exit 0
}
$small = New-Object System.Drawing.Bitmap(294,350)
$sg = [System.Drawing.Graphics]::FromImage($small)
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sg.DrawImage($bmp,0,0,294,350)
$small.Save((Join-Path $root 'preview.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$sg.Dispose();$small.Dispose();$g.Dispose();$bmp.Dispose()
exit 0
