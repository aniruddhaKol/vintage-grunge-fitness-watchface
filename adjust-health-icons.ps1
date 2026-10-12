$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class TinyPositionEdit {
 static bool Red(Color p){return p.R>100&&p.R>p.G*1.35&&p.R>p.B*1.35;}
 static int Part(int x,int y) {
  if(x>=30&&x<=68&&y>=33&&y<=68)return 1;
  if(x>=326&&x<=400&&y>=33&&y<=52)return 2;
  if(x>=293&&x<=332&&y>=35&&y<=95)return 3;
  return 0;
 }
 public static void Apply(string baseline,string generated,string target) {
  using(var old=new Bitmap(baseline))using(var input=new Bitmap(generated))using(var fill=new Bitmap(432,514))using(var result=new Bitmap(432,514))using(var flame=new Bitmap(40,61)) {
   for(int py=0;py<514;py++)for(int px=0;px<432;px++)result.SetPixel(px,py,old.GetPixel(px,py));
   using(var g=Graphics.FromImage(fill)){g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(input,0,0,432,514);}
   for(int y=0;y<514;y++)for(int x=0;x<432;x++) {
    int part=Part(x,y);Color p=old.GetPixel(x,y);
    if(part==0||!Red(p))continue;
    Color q=fill.GetPixel(x,y);
    if(Red(q)||q.R<130||q.G<110)q=old.GetPixel(part==1?74:338,part==1?57:56+(y%4));
    result.SetPixel(x,y,q);
    if(part==3)flame.SetPixel(x-293,y-35,p);
   }
   using(var scaled=new Bitmap(36,55)){using(var g=Graphics.FromImage(scaled)){g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.DrawImage(flame,0,0,36,55);}for(int v=0;v<55;v++)for(int u=0;u<36;u++){Color p=scaled.GetPixel(u,v);if(p.A==0)continue;Color b=result.GetPixel(295+u,38+v);double a=p.A/255.0;result.SetPixel(295+u,38+v,Color.FromArgb(b.A,(int)(b.R*(1-a)+p.R*a),(int)(b.G*(1-a)+p.G*a),(int)(b.B*(1-a)+p.B*a)));}}
   for(int y=33;y<=68;y++)for(int x=30;x<=400;x++) {
    int part=Part(x,y);Color p=old.GetPixel(x,y);
    if(Red(p)&&part==1)result.SetPixel(x+9,y,p);
    if(Red(p)&&part==2)result.SetPixel(x-3,y,p);
   }
   for(int y=0;y<514;y++)for(int x=0;x<432;x++) {
    bool allowed=(x>=30&&x<=77&&y>=33&&y<=68)||(x>=293&&x<=400&&y>=33&&y<=95);
    if(!allowed&&old.GetPixel(x,y).ToArgb()!=result.GetPixel(x,y).ToArgb())throw new Exception("Unrelated pixel changed at "+x+","+y);
   }
   result.Save(target,ImageFormat.Png);
   Console.WriteLine("Heart +9px, CALORIES -3px, flame 90%; all pixels outside these three areas identical.");
  }
 }
}
"@
[TinyPositionEdit]::Apply((Join-Path $PSScriptRoot 'revision-baseline-v1.4.0/background.png'),(Join-Path $PSScriptRoot 'tiny-edit-generated.png'),(Join-Path $PSScriptRoot 'assets/432x514-amazfit-bip-max/background.png'))






