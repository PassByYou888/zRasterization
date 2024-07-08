unit _147_Draw_Anchor_Text_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib,
  ZR.Geometry2D, ZR.Geometry3D, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MemoryRaster;

type
  T_147_Draw_Anchor_Text_Form = class(TForm)
    fpsTimer: TTimer;
    rendererTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure rendererTimerTimer(Sender: TObject);
  private
  public
    b1, b2: Boolean;
    a1, a2: TGeoFloat;
  end;

var
  _147_Draw_Anchor_Text_Form: T_147_Draw_Anchor_Text_Form;

implementation

{$R *.fmx}


procedure T_147_Draw_Anchor_Text_Form.FormCreate(Sender: TObject);
begin
  b1 := False;
  b2 := False;
  a1 := 0;
  a2 := 0;
end;

procedure T_147_Draw_Anchor_Text_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  n: U_String;
  r1, r2: TRectV2;
begin
  d := TDIntf.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, self);
  d.FillBox(d.ScreenRectV2, DEColor(0.2, 0.2, 0.2));

  r1 := d.ScreenRectV2;
  r1[1, 0] := r1[0, 0] + RectWidth(r1) * 0.5; // 对切
  r2 := d.ScreenRectV2;
  r2[0, 0] := r1[1, 0]; // 对切

  n :=
    '|s:s+8|文本锚是定位文字靠左或靠右|| 排列均匀会更加美观 |s:s+6|API以后缀区分||' + #13#10 +
    '|color(1,0,0,1),s:s+4|调用API时|| 锚位置根据渲染目标而定 |color(0,1,0,1),s:s+10|锚无法自动API||' + #13#10 +
    '|bk(0,0,0,0.8),s(s+7)|最佳的做法是渲染流程控制锚坐标|color(1,0.5,0.5)|如果在文本写太多脚本可能导致计算卡顿||' + #13#10 +
    '|color(0,1,0)|提示:|bk(0,0.5,0,1),color(1,1,1),s(s+4)|DrawEngine中的文本锚可以直接站在光栅引擎画||' + #13#10 +
    '|color(0,1,0)|提示:|bk(0.5,0,0,1),color(1,1,1),s(s+8)|文本锚支持fpc||,在fpc是内存光栅' + #13#10 +
    '|bk(0.8,0,0,1),color(1,1,1),s:s+8|debug方式运行是软渲染器||  |s:s+15|必须非debug才是硬件渲染||';

  a1 := BounceFloat(a1, 2 * d.LastDeltaTime, -5, 5, b1); // 反弹器
  a2 := BounceFloat(a2, 2 * d.LastDeltaTime, 5, -5, b2); // 反弹器
  d.DrawText_L(n, 14, r1, DEColor(1, 1, 1), True, Vec2(0.5, 0.5), a1); // 左锚
  d.DrawText_R(n, 14, r2, DEColor(1, 1, 1), True, Vec2(0.5, 0.5), a2); // 右锚
  d.Flush;
end;

procedure T_147_Draw_Anchor_Text_Form.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThread;
end;

procedure T_147_Draw_Anchor_Text_Form.rendererTimerTimer(Sender: TObject);
begin
  Invalidate;
end;

end.
