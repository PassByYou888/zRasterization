unit DrawEngineFontEdgeMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  ZR.Core, ZR.UnicodeMixedLib, ZR.PascalStrings, ZR.Geometry2D, ZR.Geometry3D,
  ZR.MemoryRaster, ZR.ListEngine, ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TDrawEngineFontEdgeMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    dIntf: TDrawEngineInterface_FMX;
    bk: TMZR;
    ang: TGeoFloat;
  end;

var
  DrawEngineFontEdgeMainForm: TDrawEngineFontEdgeMainForm;
  TextRasterCache: THashObjectList;

function GetTextFont(text: string; siz: TGeoFloat; Color, EdgeColor: TDEColor; borderSiz: Integer): TMZR;

implementation

{$R *.fmx}


function GetTextFont(text: string; siz: TGeoFloat; Color, EdgeColor: TDEColor; borderSiz: Integer): TMZR;
var
  cacheToken: U_String;
  tmpDrawEng: TDrawEngine;
  text_siz: TVec2;
  tmpRaster: TMZR;
begin
  cacheToken := PFormat('%g:%s:%s:%d:%s', [siz, VecToStr(Color), VecToStr(EdgeColor), borderSiz, text]);
  Result := TMZR(TextRasterCache[cacheToken]);
  if Result = nil then
    begin
      Result := NewZR();
      tmpDrawEng := TDrawEngine.Create;
      tmpDrawEng.ViewOptions := [];
      // 高级图形技术：我们先将图像放大2倍，做一次高斯平滑，然后再缩回去，达到反锯齿效果
      text_siz := tmpDrawEng.GetTextSize(text, siz * 2);
      // 基于文字内容初始化光栅的尺寸和默认背景为0,0,0,$FF
      Result.SetSizeF(text_siz[0] + borderSiz + 50, text_siz[1] + borderSiz + 50, RColor(0, 0, 0));
      tmpDrawEng.ZR_.SetWorkMemory(Result);
      tmpDrawEng.SetSize;
      tmpDrawEng.DrawText(text, siz * 2, tmpDrawEng.ScreenRect, Color, True);
      tmpDrawEng.Flush;
      disposeObject(tmpDrawEng);

      // 填充边缘像素，将背景色为0,0,0,$FF的像素色，描绘出边缘
      tmpRaster := TMZR.Create;
      tmpRaster.SetSize(Result.Width, Result.Height, 0);
      Result.FillNoneBGColorAlphaBorder(True, RColor(0, 0, 0), RColor(EdgeColor), borderSiz, tmpRaster);
      tmpRaster.DrawTo(Result);
      disposeObject(tmpRaster);

      // 我们重构出来的光栅是RGB图，我们需要一次Alpha通道让它能够透明
      GrayscaleToAlpha(Result);

      // 缩回去达到反锯齿效果
      Result.SigmaGaussian(False, 1.5, 3);
      Result.Scale(0.5);

      // 将我们构建好的光栅字体写入到缓存中
      TextRasterCache.FastAdd(cacheToken, Result);
    end;
end;

procedure TDrawEngineFontEdgeMainForm.FormCreate(Sender: TObject);
begin
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewZR();
  bk.SetSize(512, 512);
  FillBlackGrayBackgroundTexture(bk, 64, RColor(0, 0, 0), RColorF(0.5, 0.5, 0.5), RColorF(0.3, 0.3, 0.3));
  ang := 0;
end;

procedure TDrawEngineFontEdgeMainForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  dstR: TRectV2;
  textRaster: TMZR;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  d.ViewOptions := [voEdge, voFPS];

  // 以tile方式画图片
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);

  // 使用缓存构建文本字体
  textRaster := GetTextFont('您好|color(0,1,0)|绿色||世界' + #13#10 + 'hello |color(0,1,0)|green|| world', 24, DEColor(1, 1, 1, 1), DEColor(0.5, 0.5, 1.0, 0.9), 5);
  // 计算屏幕中央坐标
  dstR[0] := Vec2Mul(Vec2Sub(d.SizeVec, textRaster.Size2D), 0.5);
  dstR[1] := Vec2Add(dstR[0], textRaster.Size2D);

  // 新版本的 BeginCaptureShadow 可以捕获高斯影子，这种影子有模糊效果，只对纹理有作用
  d.BeginCaptureShadow(vec2(20, 20), 1.0, 20, 5);
  // 画角标影子，TV2Rect4是另一种通用于几何系统的坐标，由4个顶点构成
  d.DrawCorner(TV2Rect4.Init(dstR, ang).Transform(20, 20), DEColor(0, 0, 0, 0.8), 20, 2);
  // 画角标，TV2Rect4是另一种通用于几何系统的坐标，由4个顶点构成
  d.DrawCorner(TV2Rect4.Init(dstR, ang), DEColor(1, 0.5, 0.5, 1.0), 20, 2);
  // TDE4V是DrawEngine用于表示通用平台纹理的坐标系，由left,right,top,bottom,angle，5个要素构成
  d.DrawPicture(textRaster, TDE4V.Init(textRaster.BoundsRectV2, 0), TDE4V.Init(dstR, ang), 1.0);
  d.EndCaptureShadow;

  d.Flush;

  // 归一化角度-180..180之间
  ang := NormalizeDegAngle(ang + d.LastDeltaTime * 40);
end;

procedure TDrawEngineFontEdgeMainForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress;
  Invalidate;
end;

initialization

TextRasterCache := THashObjectList.CustomCreate(True, 1024);

finalization

disposeObject(TextRasterCache);

end.
