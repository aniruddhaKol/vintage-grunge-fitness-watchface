param([string]$Generated='artwork/rustic-generated.png')
$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class RusticAsset {
 public static void Apply(string baseline,string generated,string output) {
  using(var old=new Bitmap(baseline))using(var input=new Bitmap(generated))using(var texture=new Bitmap(432,514))using(var result=new Bitmap(old)) {
   using(var g=Graphics.FromImage(texture)){g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(input,0,0,432,514);}
   for(int y=0;y<514;y++)for(int x=0;x<432;x++) {
    Color p=old.GetPixel(x,y),q=texture.GetPixel(x,y);
    bool beige=p.R>125 && p.G>105 && p.B>65 && p.R-p.G<65 && p.G-p.B<85;
    bool newBeige=q.R>100 && q.G>80 && q.B>45 && q.R-q.G<70;
    if(beige && newBeige) result.SetPixel(x,y,q);
   }
   // Keep all original red glyphs, relocating only this label inward.
   for(int y=33;y<=52;y++)for(int x=326;x<=408;x++) {
    Color p=old.GetPixel(x,y);
    if(p.R>p.G*1.45 && p.R>p.B*1.45) {
     Color q=texture.GetPixel(330+(x%7),55+(y%4));
     result.SetPixel(x,y,q.R>120&&q.G>90?q:Color.FromArgb(215,192,151));
    }
   }
   for(int y=33;y<=52;y++)for(int x=326;x<=408;x++) {
    Color p=old.GetPixel(x,y);
    if(p.R>p.G*1.45 && p.R>p.B*1.45)result.SetPixel(x-8,y,p);
   }
   result.Save(output,ImageFormat.Png);
  }
 }
}
"@
[RusticAsset]::Apply((Join-Path $projectRoot 'assets/432x514-amazfit-bip-max/background.png'),(Join-Path $projectRoot $Generated),(Join-Path $projectRoot 'artwork/rustic-background.png'))

