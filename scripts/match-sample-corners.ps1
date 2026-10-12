$projectRoot = Split-Path -Parent $PSScriptRoot
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class CopySampleBorder {
 public static void Apply(string baseline,string samplePath,string target,string overlayPath,bool aod) {
  using(var old=new Bitmap(baseline))using(var sample=new Bitmap(samplePath))using(var result=new Bitmap(old))using(var overlay=new Bitmap(432,514)) {
   bool[,] inside=new bool[432,514];
   for(int y=0;y<514;y++) {
    int left=0,right=431;
    if(y<106||y>=408) {
     for(int x=0;x<=106;x++){Color p=sample.GetPixel(x,y);if(p.A>24&&Math.Max(p.R,Math.Max(p.G,p.B))>24){left=x;break;}}
     for(int x=431;x>=325;x--){Color p=sample.GetPixel(x,y);if(p.A>24&&Math.Max(p.R,Math.Max(p.G,p.B))>24){right=x;break;}}
    }
    for(int x=left;x<=right;x++)inside[x,y]=true;
   }
   int copied=0;
   for(int y=0;y<514;y++)for(int x=0;x<432;x++) {
    if(!inside[x,y]) {result.SetPixel(x,y,Color.Black);overlay.SetPixel(x,y,Color.Black);continue;}
    double distance=Math.Min(Math.Min(x+1,432-x),Math.Min(y+1,514-y));
    if((x<118||x>=314)&&(y<118||y>=396)) {
     for(int yy=Math.Max(0,y-11);yy<=Math.Min(513,y+11);yy++)for(int xx=Math.Max(0,x-11);xx<=Math.Min(431,x+11);xx++)
      if(!inside[xx,yy])distance=Math.Min(distance,Math.Sqrt((x-xx)*(x-xx)+(y-yy)*(y-yy)));
    }
    // Literal source pixels, no scaling, recoloring or approximation.
    if(!aod&&distance<=11){result.SetPixel(x,y,sample.GetPixel(x,y));copied++;}
   }
   // Prove everything beyond the sampled edge band remains unchanged.
   for(int y=118;y<396;y++)for(int x=12;x<420;x++)
    if(result.GetPixel(x,y).ToArgb()!=old.GetPixel(x,y).ToArgb())throw new Exception("Interior changed");
   result.Save(target,ImageFormat.Png);overlay.Save(overlayPath,ImageFormat.Png);
   Console.WriteLine(System.IO.Path.GetFileName(target)+": "+copied+" exact sample border pixels copied; canvas remains 432x514.");
  }
 }
}
"@
$root=Join-Path $projectRoot 'assets/432x514-amazfit-bip-max'
foreach($name in @('background.png','aod-background.png')) {
 [CopySampleBorder]::Apply((Join-Path $projectRoot "references/border-baseline-v1.3.9/$name"),(Join-Path $projectRoot 'artwork/sample corners.png'),(Join-Path $root $name),(Join-Path $root 'rounded-corners.png'),($name -eq 'aod-background.png'))
}
