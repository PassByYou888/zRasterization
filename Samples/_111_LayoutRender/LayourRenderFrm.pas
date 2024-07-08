unit LayourRenderFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts,

  ZR.Core, ZR.Geometry2D,
  ZR.MemoryRaster, ZR.DrawEngine,
  ZR.DrawEngine.SlowFMX;

type
  TLayourRenderForm = class(TForm)
    Layout1: TLayout;
    Layout2: TLayout;
    Layout3: TLayout;
    fpsTimer: TTimer;
    procedure fpsTimerTimer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Layout1Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Layout2Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
  private
  public
    dIntf: TDrawEngineInterface_FMX;
    bk: TZR;
    constructor Create(AOwner: TComponent); override;
  end;

var
  LayourRenderForm: TLayourRenderForm;

implementation

{$R *.fmx}

procedure TLayourRenderForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThreadSynchronize;
  DrawPool.Progress;
  Invalidate;
end;

procedure TLayourRenderForm.FormResize(Sender: TObject);
begin
  Rescale(Layout1, self);
end;

procedure TLayourRenderForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  with DrawPool(Sender, dIntf) do
    begin
      DrawTile(bk, bk.BoundsRectV2, 1.0);
      Flush;
    end;
end;

procedure TLayourRenderForm.Layout1Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  with DrawPool(Sender, dIntf) do
    begin
      DrawDotLineBox(DERect(ARect), DEColor(1, 0, 0), 2);
      Flush;
    end;
end;

procedure TLayourRenderForm.Layout2Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  with DrawPool(Sender, dIntf) do
    begin
      DrawCorner(DERect(ARect), DEColor(1, 0.5, 0.5), 20, 2);
      Flush;
    end;
end;

constructor TLayourRenderForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewZR();
  bk.SetSize(256, 256);
  FillBlackGrayBackgroundTexture(bk, 64);
end;

end.
