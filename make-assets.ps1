Add-Type -AssemblyName System.Drawing
$root = Join-Path $PSScriptRoot 'assets/432x514-amazfit-bip-max'
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
$source = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot 'background-source.png'))
$background = New-Object System.Drawing.Bitmap(432,514)
$g = [System.Drawing.Graphics]::FromImage($background)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Black)
# Read only the four 106px corner areas of the supplied outline reference.
$sample = [System.Drawing.Bitmap]::FromFile((Join-Path $PSScriptRoot 'sample corners.png'))
if($sample.Width -ne 432 -or $sample.Height -ne 514) { throw 'Corner reference must be 432 x 514' }
$leftEdge = @();$rightEdge = @()
for($y=0;$y -lt 514;$y++) {
  $left = 0;$right = 431
  if($y -lt 106 -or $y -ge 408) {
    for($x=0;$x -le 106;$x++) {
      $pixel = $sample.GetPixel($x,$y)
      if([math]::Max($pixel.R,[math]::Max($pixel.G,$pixel.B)) -gt 24) { $left=$x;break }
    }
    for($x=431;$x -ge 325;$x--) {
      $pixel = $sample.GetPixel($x,$y)
      if([math]::Max($pixel.R,[math]::Max($pixel.G,$pixel.B)) -gt 24) { $right=$x;break }
    }
  }
  $leftEdge += $left;$rightEdge += $right
}
$sample.Dispose()
$points = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
for($y=0;$y -lt 514;$y++) {$points.Add([System.Drawing.PointF]::new($leftEdge[$y],$y))}
for($y=513;$y -ge 0;$y--) {$points.Add([System.Drawing.PointF]::new($rightEdge[$y],$y))}
$shape = New-Object System.Drawing.Drawing2D.GraphicsPath
$shape.AddPolygon($points.ToArray())
$shape.CloseFigure()
$g.SetClip($shape)
$g.DrawImage($source,[System.Drawing.Rectangle]::new(0,0,432,514),0,0,1120,1329,[System.Drawing.GraphicsUnit]::Pixel)
# Fit the charge panel inside the lower curve; keep a single continuous top rim.
$g.DrawImage($source,[System.Drawing.Rectangle]::new(0,436,432,64),0,1127,1120,202,[System.Drawing.GraphicsUnit]::Pixel)
$edgeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#dec7a0'))
$g.FillRectangle($edgeBrush,0,500,432,14)
$edgeBrush.Dispose()
# A continuous rim follows the sampled outline, without copying the sample's contents.
$rim = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120,91,59),5)
$g.DrawPath($rim,$shape)
$rim.Dispose()
$g.ResetClip()
$aodSource = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot 'aod-background-source.png'))
$aodBackground = New-Object System.Drawing.Bitmap(432,514)
$ag = [System.Drawing.Graphics]::FromImage($aodBackground)
$ag.Clear([System.Drawing.Color]::Black)
$ag.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$ag.SetClip($shape)
$ag.DrawImage($aodSource,0,0,432,514)
$aodRim = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(94,85,68),4)
$ag.DrawPath($aodRim,$shape)
$aodBackground.Save((Join-Path $root 'aod-background.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$aodRim.Dispose();$ag.Dispose();$aodBackground.Dispose();$aodSource.Dispose()
# An opaque corner overlay also clips live widgets to the same geometry.
$corner = New-Object System.Drawing.Bitmap(432,514)
$cg = [System.Drawing.Graphics]::FromImage($corner)
$outside = New-Object System.Drawing.Region([System.Drawing.Rectangle]::new(0,0,432,514))
$outside.Exclude($shape)
$cg.FillRegion([System.Drawing.Brushes]::Black,$outside)
$corner.Save((Join-Path $root 'rounded-corners.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$outside.Dispose();$cg.Dispose();$corner.Dispose();$shape.Dispose()
$background.Save((Join-Path $root 'background.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $source.Dispose(); $background.Dispose()
foreach ($digit in 0..9) {
  $bmp = New-Object System.Drawing.Bitmap(44,74)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $family = New-Object System.Drawing.FontFamily('Impact')
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $format.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
  $path.AddString([string]$digit,$family,0,68,[System.Drawing.RectangleF]::new(0,0,44,74),$format)
  $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160,160,160),2)
  $g.DrawPath($pen,$path)
  $bmp.Save((Join-Path $root ('aod-'+$digit+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
  $pen.Dispose();$path.Dispose();$format.Dispose();$family.Dispose();$g.Dispose();$bmp.Dispose()
  Save-Text ('aod-small-'+$digit+'.png') ([string]$digit) 13 24 22 '#999999'
}
Save-Text 'aod-colon.png' ':' 20 74 58 '#a0a0a0'
Save-Text 'aod-steps.png' 'STEPS' 54 24 18 '#888888'
Save-Text 'aod-battery.png' 'BAT' 45 24 18 '#888888'
Save-Text 'aod-percent.png' '%' 19 24 20 '#999999'
foreach ($digit in 0..9) {
  Save-Text ('aod-clock-'+$digit+'.png') ([string]$digit) 62 126 118 '#c1b69e'
  # The same flip-card seam as the reference, crossing each live digit.
  $clockPath = Join-Path $root ('aod-clock-'+$digit+'.png')
  $clockImage = [System.Drawing.Image]::FromFile($clockPath)
  $clock = New-Object System.Drawing.Bitmap($clockImage)
  $clockImage.Dispose()
  $clockG = [System.Drawing.Graphics]::FromImage($clock)
  $seam = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200,20,19,16),1)
  $clockG.DrawLine($seam,0,62,61,62)
  $clock.Save($clockPath,[System.Drawing.Imaging.ImageFormat]::Png)
  $seam.Dispose();$clockG.Dispose();$clock.Dispose()
  Save-Text ('aod-date-'+$digit+'.png') ([string]$digit) 38 60 57 '#b7ad99'
  Save-Text ('aod-activity-'+$digit+'.png') ([string]$digit) 23 45 42 '#b7ad99'
  Save-Text ('aod-distance-'+$digit+'.png') ([string]$digit) 18 45 35 '#b7ad99'
  Save-Text ('aod-bat-'+$digit+'.png') ([string]$digit) 12 30 27 '#b7ad99'
}
Save-Text 'aod-dot.png' '.' 7 45 35 '#b7ad99'
Save-Text 'aod-km.png' 'KM' 34 45 19 '#b7ad99'
Save-Text 'aod-mi.png' 'MI' 34 45 19 '#b7ad99'
Save-Text 'aod-bat-percent.png' '%' 19 30 25 '#b7ad99'
Save-Text 'aod-steps-label.png' 'STEPS' 91 22 22 '#b7ad99'
Save-Text 'aod-distance-label.png' 'DISTANCE' 114 22 22 '#b7ad99'
Save-Text 'aod-charge-label.png' 'CHARGE' 88 24 23 '#b7ad99'
Save-Text 'aod-zero-percent.png' '0%' 37 30 22 '#b7ad99'
$aodWeek = @('MON','TUE','WED','THU','FRI','SAT','SUN')
for ($i=0;$i -lt 7;$i++) { Save-Text ('aod-week-'+$i+'.png') $aodWeek[$i] 49 24 22 '#999999' }
for ($i=0;$i -lt 7;$i++) { Save-Text ('aod-large-week-'+$i+'.png') $aodWeek[$i] 112 60 57 '#b7ad99' }
# Transparent native button images preserve the underlying artwork and live numbers.
$tapSizes = @(@(132,77),@(135,77),@(133,77),@(161,132),@(133,132),@(106,132),@(104,86),@(96,86),@(200,83),@(400,62))
foreach ($dims in $tapSizes) {
  $bmp = New-Object System.Drawing.Bitmap($dims[0],$dims[1])
  $bmp.Save((Join-Path $root ('tap-'+$dims[0]+'x'+$dims[1]+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}
$colors = @{red='#ed3232';blue='#2079d7';orange='#f06423';cream='#d9c397';amber='#e8a717';green='#0aa45e'}
foreach($dims in $tapSizes) {
  foreach($name in $colors.Keys) {
    $bmp=New-Object System.Drawing.Bitmap($dims[0],$dims[1])
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rgb=[System.Drawing.ColorTranslator]::FromHtml($colors[$name])
    $fillAlpha=if($name -eq 'blue' -and $dims[0] -eq 104 -and $dims[1] -eq 86){72}else{36}
    $brush=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($fillAlpha,$rgb))
    $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(175,$rgb),2)
    $path=New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(3,3,14,14,180,90)
    $path.AddArc(($dims[0]-17),3,14,14,270,90)
    $path.AddArc(($dims[0]-17),($dims[1]-17),14,14,0,90)
    $path.AddArc(3,($dims[1]-17),14,14,90,90)
    $path.CloseFigure()
    $g.FillPath($brush,$path);$g.DrawPath($pen,$path)
    $bmp.Save((Join-Path $root ('press-'+$name+'-'+$dims[0]+'x'+$dims[1]+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
    $path.Dispose();$pen.Dispose();$brush.Dispose();$g.Dispose();$bmp.Dispose()
  }
}
$sets = @(
  @{Name='time';W=44;H=74;Size=72;Color='#efdfbd'},
  @{Name='seconds';W=29;H=64;Size=60;Color='#efdfbd'},
  @{Name='health';W=23;H=44;Size=42;Color='#070706'},
  @{Name='cal';W=19;H=44;Size=40;Color='#070706'},
  @{Name='activity';W=24;H=42;Size=40;Color='#070706'},
  @{Name='distance';W=18;H=42;Size=34;Color='#070706'},
  @{Name='small';W=12;H=27;Size=25;Color='#070706'},
  @{Name='temp';W=18;H=35;Size=33;Color='#070706'},
  @{Name='battery';W=11;H=25;Size=23;Color='#070706'}
)
foreach ($set in $sets) {
  foreach ($digit in 0..9) { Save-Text ($set.Name+'-'+$digit+'.png') ([string]$digit) $set.W $set.H $set.Size $set.Color }
}
Save-Text 'dot.png' '.' 8 42 40 '#070706'
Save-Text 'colon.png' ':' 6 27 25 '#070706'
Save-Text 'minus.png' '-' 12 35 30 '#070706'
Save-Text 'degree.png' ([string][char]176) 11 35 30 '#070706'
Save-Text 'km.png' 'KM' 31 42 19 '#070706'
Save-Text 'mi.png' 'MI' 31 42 19 '#070706'
Save-Text 'percent.png' '%' 14 25 22 '#070706'
$week = @('MON','TUE','WED','THU','FRI','SAT','SUN')
for ($i=0;$i -lt 7;$i++) { Save-Text ('week-'+$i+'.png') $week[$i] 49 27 24 '#070706' }
for ($i=0;$i -le 100;$i++) {
  $barColor=if($i -lt 20){[System.Drawing.Color]::FromArgb(237,50,50)}elseif($i -le 50){[System.Drawing.Color]::FromArgb(232,167,23)}else{[System.Drawing.Color]::MediumSeaGreen}
  $bmp = New-Object System.Drawing.Bitmap(259,16)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  if ($i -gt 0) {
    $brush=New-Object System.Drawing.SolidBrush($barColor)
    $g.FillRectangle($brush,0,0,[int](259*$i/100),16)
    $brush.Dispose()
  }
  $bmp.Save((Join-Path $root ('battery-level-'+$i+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  $bmp = New-Object System.Drawing.Bitmap(248,22)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  if ($i -gt 0) {
    $aodColor=if($i -gt 50){[System.Drawing.Color]::FromArgb(70,139,91)}else{$barColor}
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(130,$aodColor))
    $g.FillRectangle($brush,0,0,[int](248*$i/100),22)
    $brush.Dispose()
  }
  $bmp.Save((Join-Path $root ('aod-battery-level-'+$i+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose();$bmp.Dispose()
}

# Apply the corner-only refinement after generating the original artwork.
& (Join-Path $PSScriptRoot 'fix-corners.ps1')
if(Test-Path (Join-Path $PSScriptRoot 'rustic-generated.png')) {
  & (Join-Path $PSScriptRoot 'prepare-rustic.ps1')
  Copy-Item (Join-Path $PSScriptRoot 'rustic-background.png') (Join-Path $root 'background.png')
}
& (Join-Path $PSScriptRoot 'match-sample-corners.ps1')
& (Join-Path $PSScriptRoot 'adjust-health-icons.ps1')
