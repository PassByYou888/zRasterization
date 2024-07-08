unit _149_Seg_Text_Expression_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib,
  ZR.Geometry2D, ZR.Geometry3D, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MemoryRaster;

type
  T_149_Seg_Text_Expression_Form = class(TForm)
    fpsTimer: TTimer;
    rendererTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure rendererTimerTimer(Sender: TObject);
  private
  public
    bk: TZR;
    b1, b2: Boolean;
    a1, a2: TGeoFloat;
    seg1, seg2: TDSegmentionText_Draw_Info;
    mouse_pt: TVec2;
  end;

var
  _149_Seg_Text_Expression_Form: T_149_Seg_Text_Expression_Form;

implementation

{$R *.fmx}


procedure T_149_Seg_Text_Expression_Form.FormCreate(Sender: TObject);
begin
  bk := NewZR;
  bk.SetSize($FF, $FF);
  FillBlackGrayBackgroundTexture(bk, 64);
  b1 := False;
  b2 := False;
  a1 := 0;
  a2 := 0;
  seg1 := TDSegmentionText_Draw_Info.Create;
  seg2 := TDSegmentionText_Draw_Info.Create;
  mouse_pt := vec2(0, 0);
  DrawPool(self).PostScrollText(1, '硬件图形加速默认会开满线程,导致调试器受限,默认关闭硬件渲染,必须使用非Debug方式运行才会有硬件图形加速效果',
    24, DEColor(1, 1, 1)).Forever := True;
end;

procedure T_149_Seg_Text_Expression_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  mouse_pt := vec2(X, Y);
end;

procedure T_149_Seg_Text_Expression_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if seg1.Num > 0 then
    with seg1.Repeat_ do
      repeat
        if queue^.Data.R4.InHere(vec2(X, Y)) and (queue^.Data.ID > 0) then
            DrawPool(self).PostScrollText(5, Format('点击ID:%d 点击文本:%s', [queue^.Data.ID, queue^.Data.Text]), 16, DEColor(1, 1, 1));
      until not Next;

  if seg2.Num > 0 then
    with seg2.Repeat_ do
      repeat
        if queue^.Data.R4.InHere(vec2(X, Y)) and (queue^.Data.ID > 0) then
            DrawPool(self).PostScrollText(5, Format('点击ID:%d 点击文本:%s', [queue^.Data.ID, queue^.Data.Text]), 16, DEColor(1, 1, 1));
      until not Next;
end;

procedure T_149_Seg_Text_Expression_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  n: U_String;
  r1, r2: TRectV2;
  L: TDSegmentionText_Draw_Info;
begin
  Canvas.Font.Family := 'Consolas';
  Canvas.Font.Style := [TFontStyle.fsBold];
  d := TDIntf.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, self);
  d.ViewOptions := [voFPS];
  d.DrawTile(bk);

  r1 := d.ScreenRectV2;
  r1[1, 0] := r1[0, 0] + RectWidth(r1) * 0.5; // 对切
  r2 := d.ScreenRectV2;
  r2[0, 0] := r1[1, 0]; // 对切

  n := '|s:12|带框框的可以点击||' + #13#10 +
    '|color(1,1,0)|文本表达式是|| |box(1,0.5,1),l:1,id=100,s:40|DrawEngine|| |color(0.5,0.5,0.5),bk(1,1,1)|的文本渲染语言||' + #13#10 +
    '|s:20|文本表达式|color(1,1,1),s:28|支持|color(0.5,0.5,1),s:35|前后|bk(1,1,1),color(1,0,0),s:30|颜色||+|box(0.5,1,0.5),id:99,l:1.5,s:30|分段区域||+|box(1,1,1),id:111,s:15|分段AABB||' + #13#10 +
    '|s:36|自动|s:26|' + TDrawEngine.RebuildNumColor('构建数字表达式: 123 3.14 11 22 99', '|s:30,id:3,l:0.5,box(0.5,1,0.5)|', '||');

  a1 := BounceFloat(a1, 12 * d.LastDeltaTime, -5, 5, b1); // 反弹器
  a2 := BounceFloat(a2, 12 * d.LastDeltaTime, 5, -5, b2); // 反弹器

  seg1.Clear;
  d.DrawText_L(n, 18, r1, DEColor(1, 1, 1), True, vec2(0.5, 0.5), a1, seg1); // 左锚
  seg2.Clear;
  d.DrawText_R(n, 18, r2, DEColor(1, 1, 1), True, vec2(0.5, 0.5), a2, seg2); // 右锚

  if seg1.Num > 0 then
    with seg1.Repeat_ do
      repeat
        if queue^.Data.R4.InHere(mouse_pt) and (queue^.Data.ID > 0) then
            d.DrawBox(queue^.Data.R4, DEColor(1, 0, 0), 3);
      until not Next;

  if seg2.Num > 0 then
    with seg2.Repeat_ do
      repeat
        if queue^.Data.R4.InHere(mouse_pt) and (queue^.Data.ID > 0) then
            d.DrawBox(queue^.Data.R4, DEColor(0, 1, 0), 3);
      until not Next;

  d.Flush;
end;

procedure T_149_Seg_Text_Expression_Form.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThread;
end;

procedure T_149_Seg_Text_Expression_Form.rendererTimerTimer(Sender: TObject);
begin
  Invalidate;
end;

end.
