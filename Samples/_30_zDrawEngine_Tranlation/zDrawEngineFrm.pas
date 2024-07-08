unit zDrawEngineFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  System.IOUtils,

  ZR.Core, ZR.UnicodeMixedLib,
  ZR.Geometry2D, ZR.DrawEngine, ZR.MemoryRaster, ZR.DrawEngine.SlowFMX;

type
  TzDrawEngineForm = class(TForm)
    fpsTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fpsTimerTimer(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
    { Private declarations }
  public
    { Public declarations }
    drawIntf: TDrawEngineInterface_FMX;
    background, raster: TMZR;
    x_: TGeoFloat;
  end;

var
  zDrawEngineForm: TzDrawEngineForm;

implementation

{$R *.fmx}


procedure TzDrawEngineForm.FormCreate(Sender: TObject);
begin
  drawIntf := TDrawEngineInterface_FMX.Create;
  background := NewZR();
  background.SetSize(128, 128, RColor(0, 0, 0));
  FillBlackGrayBackgroundTexture(background, 16);
  raster := NewZRFromFile(umlCombineFileName(TPath.GetLibraryPath, 'lena.bmp'));
  x_ := 0;
end;

procedure TzDrawEngineForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  EnginePool.Clear;
  DisposeObject([drawIntf, background, raster]);
end;

procedure TzDrawEngineForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress();
  Invalidate;
end;

procedure TzDrawEngineForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  dr: TRectV2;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voFPS, voEdge];
  d.DrawTile(background, background.BoundsRectV2, 1.0);

  x_ := x_ + 1;
  dr[0] := Vec2(x_, 0);
  dr[1] := Vec2Add(dr[0], raster.Size2D);
  if not d.ScreenRectInScreen(dr) then
    begin
      x_ := -raster.Width;
      dr[0] := Vec2(x_, 0);
      dr[1] := Vec2Add(dr[0], raster.Size2D);
    end;

  d.DrawPicture(raster, raster.BoundsRectV2, dr, 1.0);

  d.Flush;
end;

end.
