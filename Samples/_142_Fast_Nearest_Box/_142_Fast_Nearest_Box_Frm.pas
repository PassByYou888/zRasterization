unit _142_Fast_Nearest_Box_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Objects, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts, FMX.ExtCtrls, FMX.Memo.Types,

  FMX.DialogService, System.IOUtils,

  ZR.Core,
  ZR.DrawEngine.SlowFMX, ZR.DrawEngine, ZR.Geometry2D, ZR.MemoryRaster,
  ZR.MemoryStream, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Status,
  ZR.HashList.Templet, ZR.ListEngine;

type
  T_142_Fast_Nearest_Box_Form = class(TForm)
    Button1: TButton;
    ui_Timer: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure ui_TimerTimer(Sender: TObject);
  private
  public
    dIntf: TDrawEngineInterface_FMX;
    Box_Buff: TZR_BL<TRectV2>;
    Nearest_Box_Tool: TNearest_Box_Tool;
    Downed: Boolean;
    Down_Pt, Move_Pt, Up_Pt: TVec2;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  _142_Fast_Nearest_Box_Form: T_142_Fast_Nearest_Box_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

constructor T_142_Fast_Nearest_Box_Form.Create(AOwner: TComponent);
begin
  inherited;
  dIntf := TDrawEngineInterface_FMX.Create;
  Box_Buff := TZR_BL<TRectV2>.Create;
  Nearest_Box_Tool := TNearest_Box_Tool.Create;
  Down_Pt := NullVec2;
  Move_Pt := NullVec2;
  Up_Pt := NullVec2;
end;

destructor T_142_Fast_Nearest_Box_Form.Destroy;
begin
  dIntf.Free;
  Nearest_Box_Tool.Free;
  Box_Buff.Free;
  inherited;
end;

procedure T_142_Fast_Nearest_Box_Form.Button1Click(Sender: TObject);
begin
  Nearest_Box_Tool.Clear;
  if Box_Buff.Num > 0 then
    with Box_Buff.Repeat_ do
      repeat
          Nearest_Box_Tool.Add_Box(@queue^.Data);
      until not Next;
  Nearest_Box_Tool.Compute_Nearest_Box(0, 2);
end;

procedure T_142_Fast_Nearest_Box_Form.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    begin
      Downed := True;
      Down_Pt := vec2(X, Y);
      Move_Pt := Down_Pt;
      Up_Pt := Down_Pt;
    end;
end;

procedure T_142_Fast_Nearest_Box_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  Move_Pt := vec2(X, Y);
  Up_Pt := Move_Pt;
end;

procedure T_142_Fast_Nearest_Box_Form.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbLeft then
    begin
      Up_Pt := vec2(X, Y);
      Downed := false;
      Box_Buff.Add(ForwardRect(RectV2(Down_Pt, Up_Pt)));
    end;
end;

procedure T_142_Fast_Nearest_Box_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  d := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  if Downed then
    begin
      d.DrawDotLineBox(RectV2(Down_Pt, Move_Pt), DEColor(0.5, 1, 0.5), 2);
    end;

  if Box_Buff.Num > 0 then
    with Box_Buff.Repeat_ do
      repeat
          d.DrawBox(queue^.Data, DEColor(1, 1, 1), 2);
      until not Next;

  if Nearest_Box_Tool.Num > 0 then
    begin
      with Nearest_Box_Tool.Repeat_ do
        repeat
            d.Draw_BK_Text(PFormat('%d', [queue^.Data.ID]), 14, queue^.Data.R^, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9), True);
        until not Next;

      if Nearest_Box_Tool.IoU_Tool.Num > 0 then
        with Nearest_Box_Tool.IoU_Tool.Repeat_ do
          repeat
            d.DrawBox(queue^.Data.Intersect_Box, DEColor(1, 0.5, 0.5), 2);
            d.Draw_BK_Text(PFormat('IoU %f', [queue^.Data.IoU]), 11, queue^.Data.Intersect_Box, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9), True);
          until not Next;

      with Nearest_Box_Tool.Nearest_Group.Repeat_ do
        repeat
          if queue^.Data^.Data.Second.Num > 1 then
              d.DrawPolygon(queue^.Data^.Data.Second.Convex_Hull.BuildArray, DEColor(1, 0, 0), 1);
        until not Next;
    end;

  d.Flush;
end;

procedure T_142_Fast_Nearest_Box_Form.ui_TimerTimer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
end;

end.
