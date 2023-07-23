unit ShowImageFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.ExtCtrls,

  ZR.Core, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MemoryRaster, ZR.Geometry2D,
  ZR.DrawEngine.PictureViewer, FMX.Objects;

type
  TShowImageForm = class(TForm)
    bkTimer: TTimer;
    pb: TPaintBox;
    procedure bkTimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
  public
    dIntf: TDrawEngineInterface_FMX;
    Viewer: TPictureViewerInterface;
    d: TDrawEngine;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ShowImageForm: TShowImageForm;

procedure ShowImage(img: TMZR); overload;
procedure ShowImage2(img: TMZR; title: string); overload;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure ShowImage(img: TMZR);
begin
  ShowImageForm.Viewer.InputPicture(img, '', False, False);
  ShowImageForm.Show;
end;

procedure ShowImage2(img: TMZR; title: string);
begin
  ShowImageForm.Viewer.InputPicture(img, title, False, False);
  ShowImageForm.Show;
end;

procedure TShowImageForm.bkTimerTimer(Sender: TObject);
begin
  if visible then
    begin
      d.Progress();
      Invalidate;
    end;
end;

procedure TShowImageForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Viewer.Clear;
  Action := TCloseAction.caHide;
end;

procedure TShowImageForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = VKESCAPE then
      close;
end;

procedure TShowImageForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapDown(vec2(X, Y));
end;

procedure TShowImageForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapMove(vec2(X, Y));
end;

procedure TShowImageForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapUp(vec2(X, Y));
end;

procedure TShowImageForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      Viewer.ScaleCamera(1.1)
  else
      Viewer.ScaleCamera(0.9);
end;

procedure TShowImageForm.pbPaint(Sender: TObject; Canvas: TCanvas);
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;
  Viewer.DrawEng := d;
  Viewer.Render;
end;

constructor TShowImageForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  dIntf := TDrawEngineInterface_FMX.Create;
  d := TDrawEngine.Create;
  d.DrawInterface := dIntf;
  d.ViewOptions := [voEdge];
  Viewer := TPictureViewerInterface.Create(d);
  Viewer.ShowHistogramInfo := True;
  Viewer.ShowPixelInfo := True;
end;

destructor TShowImageForm.Destroy;
begin
  disposeObjectAndNil(dIntf);
  disposeObjectAndNil(d);
  disposeObjectAndNil(Viewer);
  inherited Destroy;
end;

end.
