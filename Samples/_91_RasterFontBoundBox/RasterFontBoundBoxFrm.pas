unit RasterFontBoundBoxFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib,
  ZR.ZDB, ZR.MemoryStream, ZR.TextDataEngine, ZR.ListEngine, ZR.ZDB.HashItem_LIB,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.Geometry2D, ZR.DrawEngine.PictureViewer,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts;

type
  TRasterFontBoundBoxForm = class(TForm)
    Timer1: TTimer;
    Layout1: TLayout;
    Label1: TLabel;
    xSpecTrackBar: TTrackBar;
    Layout2: TLayout;
    Label2: TLabel;
    ySpecTrackBar: TTrackBar;
    procedure SpecTrackBarChange(Sender: TObject);
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

    TextSource: U_String;
    DrawCoordinate, BoundBoxCoordinate: TArrayV2R4;

  end;

var
  RasterFontBoundBoxForm: TRasterFontBoundBoxForm;

function BuildDemoText1(spec: TPoint; var TextSource: U_String; var DrawCoordinate, BoundBoxCoordinate: TArrayV2R4): TZR;

implementation

{$R *.fmx}


function BuildDemoText1(spec: TPoint; var TextSource: U_String; var DrawCoordinate, BoundBoxCoordinate: TArrayV2R4): TZR;
var
  i: Integer;
  r: TRectV2;
begin
  // 我们创建一个临时光栅,并输入到viewIntf
  Result := NewZR();
  Result.SetSize(800, 800, RColorF(0, 0, 0, 0.5));
  Result.OpenAgg;

  Result.Font.X_Spacing := spec.X;
  Result.Font.Y_Spacing := spec.Y;

  TextSource := '你好世界.' + #13#10 + '光栅字体物理包围盒.' + #13#10 + 'hello world.' + #13#10 + '1234567890';

  // 计算文字包围盒
  // DrawCoordinate输出的渲染坐标,即投影的目标坐标
  // BoundBoxCoordinate输出的渲染到目标的物理坐标
  // ComputeDrawTextCoordinate对于包围盒的计算采用了形态学方法,计算方式是一次性的,这里我们重复计算1000次,瞬间完成.
  for i := 1 to 1000 do
      Result.ComputeDrawTextCoordinate(TextSource, 100, 50, Vec2(0, 0), 15, 30, DrawCoordinate, BoundBoxCoordinate);

  // 画文字
  Result.DrawText(TextSource, 104, 54, Vec2(0, 0), 15, 1.0, 30, RColorF(0, 0, 0));
  Result.DrawText(TextSource, 100, 50, Vec2(0, 0), 15, 1.0, 30, RColorF(1, 1, 1));

  // 用绿线把字体物理包围盒画出来
  Result.Agg.LineWidth := 1;
  for i := 0 to length(BoundBoxCoordinate) - 1 do
    if BoundBoxCoordinate[i].Area > 16 then
        Result.DrawRect(BoundBoxCoordinate[i], RColorF(0.5, 1, 0.5, 1));

  Result.DrawEngine.Flush;

  // 计算物理包围盒
  r := ArrayBoundRect(BoundBoxCoordinate);
  // 画物理包围盒
  Result.DrawEngine.DrawLabelBox(Format('物理包围盒 |color(0.5,0,0),s:14|%d * %d |color(0,0.5,0),s:14|绿线||是物理像素包围盒', [round(RectWidth(r)), round(Rectheight(r))]), 12, DEColor(0, 0, 0), r, DEColor(1, 1, 1), 2);
  Result.DrawEngine.Flush;
end;

procedure TRasterFontBoundBoxForm.SpecTrackBarChange(Sender: TObject);
var
  raster: TMZR;
begin
  raster := BuildDemoText1(Point(round(xSpecTrackBar.Value), round(ySpecTrackBar.Value)), TextSource, DrawCoordinate, BoundBoxCoordinate);
  viewIntf.First.raster.SwapInstance(raster);
  viewIntf.First.raster.NoUsage;
  disposeObject(raster);
end;

procedure TRasterFontBoundBoxForm.FormCreate(Sender: TObject);
begin
  dIntf := TDrawEngineInterface_FMX.Create;
  dIntf.SetSurface(Canvas, Self);
  d := TDrawEngine.Create;
  d.DrawInterface := dIntf;
  viewIntf := TPictureViewerInterface.Create(d);
  FillBlackGrayBackgroundTexture(viewIntf.BackgroundTex, 32);

  viewIntf.InputPicture(BuildDemoText1(Point(0, 0), TextSource, DrawCoordinate, BoundBoxCoordinate), '请将鼠标移动到包围盒上', true, true, true);
end;

procedure TRasterFontBoundBoxForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(Vec2(X, Y));
end;

procedure TRasterFontBoundBoxForm.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(Vec2(X, Y));
end;

procedure TRasterFontBoundBoxForm.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(Vec2(X, Y));
end;

procedure TRasterFontBoundBoxForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := true;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TRasterFontBoundBoxForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  p: TPictureViewerData;
  pt: TPoint;
  i: Integer;
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;
  d.ViewOptions := [];

  viewIntf.DrawEng := d;
  viewIntf.Render;

  p := viewIntf.AtPicture(viewIntf.MoveScreenPT);
  if p <> nil then
    begin
      p.texInfo := '请将鼠标移动到包围盒上';
      pt := viewIntf.AtPictureOffset(p, viewIntf.MoveScreenPT);
      for i := 0 to high(DrawCoordinate) do
        if DrawCoordinate[i].InHere(Vec2(pt)) then
          begin
            d.DrawBox(d.SceneToScreen(DrawCoordinate[i].Projection(p.raster.BoundsRectV20, p.DrawBox)), DEColor(1, 0.5, 0.5), 4);
            p.texInfo := '请将鼠标所处位置不是物理光栅';
          end;

      for i := 0 to high(BoundBoxCoordinate) do
        if BoundBoxCoordinate[i].InHere(Vec2(pt)) then
          begin
            d.DrawBox(d.SceneToScreen(BoundBoxCoordinate[i].Projection(p.raster.BoundsRectV20, p.DrawBox)), DEColor(0, 1, 0), 4);
            p.texInfo := Format('当前指向字符:%s', [TextSource.buff[i]]);
          end;

      d.Flush;
    end;
end;

procedure TRasterFontBoundBoxForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
  d.Progress();
end;

end.
