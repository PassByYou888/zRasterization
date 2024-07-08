unit _154_MinLoss_ScaleSpace_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib,
  ZR.Geometry2D, ZR.Geometry3D, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MemoryRaster;

type
  T_154_MinLoss_ScaleSpace_Form = class(TForm)
    fpsTimer: TTimer;
    rendererTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure rendererTimerTimer(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
  public
    bk: TZR;
    Box_: TRectV2;
    ScaleSiz_: TVec2;
    procedure GenBox;
  end;

var
  _154_MinLoss_ScaleSpace_Form: T_154_MinLoss_ScaleSpace_Form;

implementation

{$R *.fmx}


procedure T_154_MinLoss_ScaleSpace_Form.FormCreate(Sender: TObject);
begin
  bk := NewZR;
  bk.SetSize($FF, $FF);
  FillBlackGrayBackgroundTexture(bk, 32);
  DrawPool(self).PostScrollText(1, '最小走样尺度是一种智能尺度矫正方法', 14, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, '红框为实体,黄框为最小拟合走样', 14, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, 'Fit方法是尺度向内重构,MinLoss可以向内也可以向外,走最小损失路线', 12, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, 'MinLoss主要用于矫正标注框尺度,尽最大努力保证标注目标完整性', 12, DEColor(1, 1, 1)).Forever := True;
  DrawPool(self).PostScrollText(1, '鼠标点任意位置进行变换', 12, DEColor(1, 1, 1)).Forever := True;
  GenBox;
end;

procedure T_154_MinLoss_ScaleSpace_Form.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThread;
end;

procedure T_154_MinLoss_ScaleSpace_Form.rendererTimerTimer(Sender: TObject);
begin
  Invalidate;
end;

procedure T_154_MinLoss_ScaleSpace_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  GenBox;
end;

procedure T_154_MinLoss_ScaleSpace_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  r: TRectV2;
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  d := TDIntf.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, self);
  d.ViewOptions := [voFPS];
  d.DrawTile(bk);
  d.DrawBox(Box_, DEColor(1, 0, 0), 3);
  r := MinLoss_RectScaleSpace(Box_, ScaleSiz_[0], ScaleSiz_[1]);
  d.DrawDotLineBox(r, DEColor(1, 1, 0), 3);
  d.Draw_BK_Text(
    PFormat('尺度 %s' + #13#10 + '归1尺度 %s' + #13#10 + '无走样归1尺度 %s',
      [VecToStr(ScaleSiz_), VecToStr(Vec2Normalize(ScaleSiz_)), VecToStr(NoLoss_Vec2Normalize(ScaleSiz_))]),
    11, r, DEColor(1, 1, 1), DEColor(0, 0, 0), True);
  d.Flush;
end;

procedure T_154_MinLoss_ScaleSpace_Form.GenBox;
begin
  Box_ := RectV2(Vec2(Width * 0.5, Height * 0.5), umlRRS(50, 200), umlRRS(50, 200));
  ScaleSiz_ := Vec2(umlRRS(5, 10), umlRRS(5, 10));
end;

end.
