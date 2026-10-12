$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class ReferenceCorners {
  public static bool Inside(int x,int y) {
    double u=Math.Min(x,431-x),v=Math.Min(y,513-y);
    const double rx=64,ry=74;
    if(u>=rx || v>=ry) return true;
    return Math.Pow((u-rx)/rx,2)+Math.Pow((v-ry)/ry,2)<=1;
  }
  public static void Apply(string baseline,string source,string target,bool aod) {
    using(var old=new Bitmap(baseline)) using(var original=new Bitmap(source))
    using(var canvas=new Bitmap(432,514)) using(var result=new Bitmap(old)) {
      using(var g=Graphics.FromImage(canvas)) {
        g.Clear(Color.Black);g.InterpolationMode=InterpolationMode.HighQualityBicubic;
        if(aod) g.DrawImage(original,0,0,432,514);
        else {
          g.DrawImage(original,new Rectangle(0,0,432,514),0,0,1120,1329,GraphicsUnit.Pixel);
          g.DrawImage(original,new Rectangle(0,436,432,64),0,1127,1120,202,GraphicsUnit.Pixel);
          using(var b=new SolidBrush(ColorTranslator.FromHtml("#dec7a0")))g.FillRectangle(b,0,500,432,14);
        }
      }
      int changed=0;
      for(int y=0;y<514;y++)for(int x=0;x<432;x++) {
        bool corner=(x<106||x>=326)&&(y<106||y>=408);
        if(!corner)continue;
        Color p=Inside(x,y)?canvas.GetPixel(x,y):Color.Black;
        // Thin outer edge; no inset curve crossing labels or lower panel.
        if(Inside(x,y) && (!Inside(Math.Max(0,x-2),y)||!Inside(Math.Min(431,x+2),y)||!Inside(x,Math.Max(0,y-2))||!Inside(x,Math.Min(513,y+2))))
          p=aod?Color.FromArgb(94,85,68):Color.FromArgb(120,91,59);
        result.SetPixel(x,y,p);
        if(old.GetPixel(x,y).ToArgb()!=p.ToArgb())changed++;
      }
      if(!aod) {
        // Round only the existing top and bottom panel border joins.
        // Restore texture across the former straight corner strokes first.
        for(int side=0;side<2;side++) {
          for(int u=14;u<38;u++)for(int y=22;y<65;y++) {
            int x=side==0?u:431-u;
            Color p=result.GetPixel(x,y);
            if(Inside(x,y)&&p.R<155&&p.G<125)result.SetPixel(x,y,canvas.GetPixel(110,20));
          }
          for(int u=15;u<=58;u++) for(int y=22;y<=27;y++) {
            int x=side==0?u:431-u;
            if(Inside(x,y))result.SetPixel(x,y,canvas.GetPixel(110,20));
          }
          for(int u=14;u<=20;u++)for(int y=28;y<=64;y++) {
            int x=side==0?u:431-u;
            if(Inside(x,y))result.SetPixel(x,y,canvas.GetPixel(110,y<100?20:480));
          }
          for(int u=15;u<=58;u++)for(int y=487;y<=493;y++) {
            int x=side==0?u:431-u;
            if(Inside(x,y))result.SetPixel(x,y,canvas.GetPixel(110,480));
          }
          for(int u=14;u<=20;u++)for(int y=450;y<=486;y++) {
            int x=side==0?u:431-u;
            if(Inside(x,y))result.SetPixel(x,y,canvas.GetPixel(110,y<100?20:480));
          }
        }
        using(var g=Graphics.FromImage(result))using(var pen=new Pen(Color.FromArgb(74,61,42),2)) {
          g.SmoothingMode=SmoothingMode.AntiAlias;
          g.DrawArc(pen,17,24,80,80,180,90);
          g.DrawArc(pen,334,24,80,80,270,90);
          g.DrawArc(pen,17,410,80,80,90,90);
          g.DrawArc(pen,334,410,80,80,0,90);
        }
        // Rounded outline remains the final clip after drawing border arcs.
        for(int y=0;y<514;y++)for(int x=0;x<432;x++)if(!Inside(x,y))result.SetPixel(x,y,Color.Black);
      }
      for(int y=0;y<514;y++)for(int x=0;x<432;x++)
        if(!((x<106||x>=326)&&(y<106||y>=408))&&old.GetPixel(x,y).ToArgb()!=result.GetPixel(x,y).ToArgb())throw new Exception("Non-corner changed");
      result.Save(target,ImageFormat.Png);
      Console.WriteLine(System.IO.Path.GetFileName(target)+": "+changed+" corner pixels changed; every non-corner pixel identical.");
    }
  }
  public static void Overlay(string target) {
    using(var b=new Bitmap(432,514)) {
      for(int y=0;y<514;y++)for(int x=0;x<432;x++)if(!Inside(x,y))b.SetPixel(x,y,Color.Black);
      b.Save(target,ImageFormat.Png);
    }
  }
}
"@
$root=Join-Path $projectRoot 'assets/432x514-amazfit-bip-max'
[ReferenceCorners]::Apply((Join-Path $projectRoot 'references/corner-baseline-v1.3.4/background.png'),(Join-Path $projectRoot 'artwork/background-source.png'),(Join-Path $root 'background.png'),$false)
[ReferenceCorners]::Apply((Join-Path $projectRoot 'references/corner-baseline-v1.3.4/aod-background.png'),(Join-Path $projectRoot 'artwork/aod-background-source.png'),(Join-Path $root 'aod-background.png'),$true)
[ReferenceCorners]::Overlay((Join-Path $root 'rounded-corners.png'))


