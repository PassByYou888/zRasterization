unit BuildInPictureDriverFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects,

  ZR.Core, ZR.PascalStrings,
  ZR.ZDB, ZR.MemoryStream, ZR.TextDataEngine, ZR.ListEngine, ZR.ZDB.HashItem_LIB,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MediaCenter,
  ZR.Geometry2D,
  ZR.DrawEngine.PictureViewer;

type
  TBuildInPictureDriverForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure Timer1Timer(Sender: TObject);
  private
    d: TDrawEngine;
    dIntf: TDrawEngineInterface_FMX;
    viewIntf: TPictureViewerInterface;
  public
  end;

var
  BuildInPictureDriverForm: TBuildInPictureDriverForm;

implementation

{$R *.fmx}


procedure TBuildInPictureDriverForm.FormCreate(Sender: TObject);
var
  l: TCore_List;
  i: Integer;
  p: PHashItemData;
begin
  dIntf := TDrawEngineInterface_FMX.Create;
  dIntf.SetSurface(Canvas, Self);
  d := TDrawEngine.Create;
  d.DrawInterface := dIntf;
  viewIntf := TPictureViewerInterface.Create(d);
  InitGlobalMedia([gmtArt]);

  l := TCore_List.Create;
  ArtLibrary.ROOT.GetList(l);
  for i := 0 to l.count - 1 do
    begin
      p := l[i];
      viewIntf.InputPicture(NewZRFromStream(p^.stream), p^.OriginName, True, False, True);
    end;
  disposeObject(l);
end;

procedure TBuildInPictureDriverForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;
  d.ViewOptions := [];

  viewIntf.DrawEng := d;
  viewIntf.Render;
end;

procedure TBuildInPictureDriverForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(vec2(X, Y));
end;

procedure TBuildInPictureDriverForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(vec2(X, Y));
end;

procedure TBuildInPictureDriverForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(vec2(X, Y));
end;

procedure TBuildInPictureDriverForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TBuildInPictureDriverForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  Invalidate;
end;

end.
