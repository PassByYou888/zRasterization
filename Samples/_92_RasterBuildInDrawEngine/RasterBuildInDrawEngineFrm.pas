unit RasterBuildInDrawEngineFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib,
  ZR.ZDB, ZR.MemoryStream, ZR.TextDataEngine, ZR.ListEngine, ZR.ZDB.HashItem_LIB,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.Geometry2D, ZR.DrawEngine.PictureViewer;

type
  TRasterBuildInDrawEngineForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    d: TDrawEngine;
    dIntf: TDrawEngineInterface_FMX;
    viewIntf: TPictureViewerInterface;
    angle: TGeoFloat;
  end;

var
  RasterBuildInDrawEngineForm: TRasterBuildInDrawEngineForm;

function BuildDemoPicture(var angle: TGeoFloat; deltaTime: Double): TZR;

implementation

{$R *.fmx}


function BuildDemoPicture(var angle: TGeoFloat; deltaTime: Double): TZR;
var
  n: U_String;
  i: Integer;
begin
  Result := NewZR();
  Result.SetSize(800, 800, RColorF(0, 0, 0, 0.5));
  n := '|size:24|24字号的大字|| |s:16|16字号的小字' + #13#10 + '|color(1,0,0,1),size:24|24字号的红色字|| 默认文字 |color(0,1,0,1),size:50|特大字体';
  angle := NormalizeDegAngle(angle + 15 * deltaTime);
  Result.DrawEngine.BeginCaptureShadow(Vec2(5, 5), 0.9);
  Result.DrawEngine.DrawText(n, 20, Result.DrawEngine.ScreenRect, DEColor(1, 1, 1, 1), True, Vec2(0.5, 0.5), angle);
  Result.DrawEngine.EndCaptureShadow;
  Result.DrawEngine.Flush;

  // 画包物理围盒,这种方法只能在软光栅使用,即TFontRaster的物理包围盒支持
  with Result.DrawEngine do
    begin
      for i := 0 to ZR_.TextCoordinate.Count - 1 do
        begin
          DrawBox(ZR_.TextCoordinate[i].BoundBox, DEColor(1, 0, 0), 1);
          DrawBox(ZR_.TextCoordinate[i].BoundBox.BoundRect, DEColor(1, 1, 1), 1);
        end;
      Flush;
    end;
end;

procedure TRasterBuildInDrawEngineForm.FormCreate(Sender: TObject);
begin
  dIntf := TDrawEngineInterface_FMX.Create;
  dIntf.SetSurface(Canvas, Self);
  d := TDrawEngine.Create;
  d.DrawInterface := dIntf;
  viewIntf := TPictureViewerInterface.Create(d);
  FillBlackGrayBackgroundTexture(viewIntf.BackgroundTex, 32);
  angle := 0;
  viewIntf.InputPicture(BuildDemoPicture(angle, 0), '该demo演示了在TMemoryRaster中使用TDrawEngine绘图(软渲)', True, True, True);
end;

procedure TRasterBuildInDrawEngineForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(Vec2(X, Y));
end;

procedure TRasterBuildInDrawEngineForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(Vec2(X, Y));
end;

procedure TRasterBuildInDrawEngineForm.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(Vec2(X, Y));
end;

procedure TRasterBuildInDrawEngineForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TRasterBuildInDrawEngineForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;
  d.ViewOptions := [];
  viewIntf.DrawEng := d;
  viewIntf.Render;
end;

procedure TRasterBuildInDrawEngineForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
  d.Progress();
  with BuildDemoPicture(angle, d.LastDeltaTime) do
    begin
      SwapInstance(viewIntf.First.Raster);
      viewIntf.First.Raster.NoUsage;
    end;
end;

end.
