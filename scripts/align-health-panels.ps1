param(
  [Parameter(Mandatory)][string]$BaselineProject,
  [Parameter(Mandatory)][string]$Project
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$relative = 'assets/432x514-amazfit-bip-max/background.png'
$original = [Drawing.Bitmap]::new((Join-Path $BaselineProject $relative))
$background = [Drawing.Bitmap]::new($original)

# Keep the original painted glyphs. Sample only the heart, BPM, flame, and
# CALORIES, leaving the middle panel, frame, and dividers out of the edit.
$elements = @(
  @{ Left=39; Right=76; Top=32; Bottom=67; DX=-12; DY=23; Kind='heart' }
  @{ Left=77; Right=113; Top=31; Bottom=49; DX=-13; DY=0; Kind='bpm' }
  @{ Left=292; Right=331; Top=38; Bottom=92; DX=0; DY=10; Kind='flame' }
  @{ Left=321; Right=392; Top=31; Bottom=49; DX=-7; DY=0; Kind='calories' }
)
$art = [System.Collections.Generic.List[object]]::new()
$erase = @{}
foreach ($element in $elements) {
  for ($y = $element.Top; $y -le $element.Bottom; $y++) {
    for ($x = $element.Left; $x -le $element.Right; $x++) {
      if ($element.Kind -eq 'flame' -and $x -ge 321 -and $y -le 49) { continue }
      $color = $original.GetPixel($x,$y)
      $isRed = $color.R -ge 165 -and ($color.R-$color.G) -ge 69 -and $color.B -ge ($color.G-33)
      if (!$isRed) { continue }
      $art.Add(@{ X=$x+$element.DX; Y=$y+$element.DY; Color=$color })
      foreach ($dy in -3..3) {
        foreach ($dx in -3..3) {
          $key = ($y+$dy)*432 + ($x+$dx)
          $distance = [Math]::Max([Math]::Abs($dx),[Math]::Abs($dy))
          $weight = if ($distance -le 2) { 1.0 } else { 0.55 }
          if (!$erase.ContainsKey($key) -or $erase[$key].Weight -lt $weight) {
            $erase[$key] = @{ Weight=$weight; Kind=$element.Kind }
          }
        }
      }
    }
  }
}

foreach ($key in $erase.Keys) {
  $y = [int][Math]::Floor($key/432)
  $x = $key%432
  $edit = $erase[$key]
  $old = $original.GetPixel($x,$y)
  if ($old.R -lt 145) { continue }
  $texture = switch ($edit.Kind) {
    'heart'    { $original.GetPixel($x,$y+36) }
    'bpm'      { $original.GetPixel($x,$y+30) }
    'flame'    { $original.GetPixel($x+38,[Math]::Max(55,$y)) }
    'calories' { $original.GetPixel([Math]::Max(336,$x),$y+27) }
  }
  $weight = $edit.Weight
  $background.SetPixel($x,$y,[Drawing.Color]::FromArgb(
    [int]($old.R+($texture.R-$old.R)*$weight),
    [int]($old.G+($texture.G-$old.G)*$weight),
    [int]($old.B+($texture.B-$old.B)*$weight)))
}
foreach ($pixel in $art) {
  $background.SetPixel($pixel.X,$pixel.Y,$pixel.Color)
}

$background.Save((Join-Path $Project $relative),[Drawing.Imaging.ImageFormat]::Png)
$background.Dispose()
$original.Dispose()
