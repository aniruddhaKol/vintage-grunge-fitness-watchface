$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing
$root = Join-Path $projectRoot 'assets/432x514-amazfit-bip-max'
function Save-Text($name, $value, $width, $height, $size, $color) {
  $bmp = New-Object System.Drawing.Bitmap($width, $height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $font = New-Object System.Drawing.Font('Impact', $size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
  # Fit every weekday before drawing: DrawString can otherwise truncate WED.
  if ($name -match 'week-\d+\.png$') {
    $format.Trimming = [System.Drawing.StringTrimming]::None
    while ($g.MeasureString($value, $font).Width -gt ($width - 2) -and $font.Size -gt 8) {
      $nextSize = $font.Size - 0.5
      $font.Dispose()
      $font = [System.Drawing.Font]::new('Impact', $nextSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    }
  }
  $g.DrawString($value, $font, $brush, [System.Drawing.RectangleF]::new(0,0,$width,$height), $format)
  $bmp.Save((Join-Path $root $name), [System.Drawing.Imaging.ImageFormat]::Png)
  $format.Dispose(); $brush.Dispose(); $font.Dispose(); $g.Dispose(); $bmp.Dispose()
}
$days = @('MON','TUE','WED','THU','FRI','SAT','SUN')
for($i=0;$i -lt 7;$i++) {
 Save-Text "week-$i.png" $days[$i] 49 27 24 '#070706'
 Save-Text "aod-week-$i.png" $days[$i] 49 24 22 '#999999'
 Save-Text "aod-large-week-$i.png" $days[$i] 112 60 57 '#b7ad99'
}
$canvas=[Drawing.Bitmap]::new(360,440)
$graphics=[Drawing.Graphics]::FromImage($canvas)
$graphics.Clear([Drawing.Color]::FromArgb(225,208,176))
for($i=0;$i -lt 7;$i++) {
 foreach($item in @(@("week-$i.png",15,15),@("aod-large-week-$i.png",100,0))) {
  $img=[Drawing.Image]::FromFile((Join-Path $root $item[0]))
  $graphics.DrawImageUnscaled($img,[int]$item[1],[int]($i*62+$item[2]))
  $img.Dispose()
 }
}
$canvas.Save((Join-Path $projectRoot 'artwork/weekday-validation.png'))
$graphics.Dispose();$canvas.Dispose()
