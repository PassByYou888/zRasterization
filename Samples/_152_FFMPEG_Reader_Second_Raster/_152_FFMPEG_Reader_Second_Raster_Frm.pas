unit _152_FFMPEG_Reader_Second_Raster_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls,

  IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.Geometry3D,
  ZR.Status, ZR.Notify, ZR.DFE,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX,
  ZR.DrawEngine.PictureViewer,
  ZR.FFMPEG, ZR.FFMPEG.Reader;

type
  T_152_FFMPEG_Reader_Second_Raster_Form = class(TForm)
    fpsTimer: TTimer;
    ThreadTimer: TTimer;
    primary_CheckBox: TCheckBox;
    second_CheckBox: TCheckBox;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure ThreadTimerTimer(Sender: TObject);
  private
    procedure DoStatus_backcall(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    viewer: TPictureViewerInterface;
    Play_Activted, Play_Running: Boolean;
    Critical: TCritical;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Do_Play;
  end;

var
  _152_FFMPEG_Reader_Second_Raster_Form: T_152_FFMPEG_Reader_Second_Raster_Form;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewer.TapDown(vec2(X, Y));
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewer.TapMove(vec2(X, Y));
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewer.TapUp(vec2(X, Y));
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  viewer.ScaleCameraFromWheelDelta(WheelDelta);
  Handled := True;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  viewer.DrawEng := dIntf.SetSurfaceAndGetDrawPool(Canvas, Sender);
  viewer.DrawEng.ViewOptions := [voFPS, voEdge];
  Critical.Lock;
  viewer.Render(True, True);
  Critical.UnLock;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  Invalidate;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.ThreadTimerTimer(Sender: TObject);
begin
  Check_Soft_Thread_Synchronize;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.DoStatus_backcall(Text_: SystemString; const ID: Integer);
begin
  DrawPool(self).PostScrollText(15, TDrawEngine.RebuildNumColor(Text_, '|color(1,0,0),box(0,1,0)|', '||'), 12, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.5));
end;

constructor T_152_FFMPEG_Reader_Second_Raster_Form.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, DoStatus_backcall);
  ZR.FFMPEG.Load_ffmpeg;
  dIntf := TDrawEngineInterface_FMX.Create;
  viewer := TPictureViewerInterface.Create(DrawPool(self));
  viewer.ShowBackground := True;
  viewer.DrawEng.Scroll_Text_Direction := stdLB;
  viewer.PictureViewerStyle := pvsLeft2Right;
  viewer.AutoFit := True;
  viewer.InputPicture(New_Custom_Raster(500, 500, RColor(0, 0, 0, $FF)), True);
  viewer.InputPicture(New_Custom_Raster(200, 200, RColor(0, 0, 0, $FF)), True);

  Play_Activted := True;
  Play_Running := False;
  Critical := TCritical.Create;

  TCompute.RunM_NP(Do_Play, @Play_Running, nil);

  DrawPool(self).PostScrollText(1, '预览是重要的运行时支持,例如监视工具,它要求:极少占用算力资源,极快传递copy,极快渲染', 20, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9)).Forever := True;
  DrawPool(self).PostScrollText(1, '预览光栅的渲染开销低于画一个字符,传递开销约等于10个字符串copy,解码开销为primary的1/100', 20, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9)).Forever := True;
  DrawPool(self).PostScrollText(1, '主从光栅是一种底层的硬件加速技术,它能加速解码双尺度光栅,线性计算能力远超TRaster(粗略提速约2000%)', 18, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9)).Forever := True;
  DrawPool(self).PostScrollText(1, '主从光栅可以被大规模应用于预览,primary光栅走数据流程,second光栅走预览流程', 22, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9)).Forever := True;
end;

destructor T_152_FFMPEG_Reader_Second_Raster_Form.Destroy;
begin
  Play_Activted := False;
  while Play_Running do
      TCompute.Sleep(100);
  RemoveDoStatusHook(self);
  DisposeObject(viewer);
  DisposeObject(Critical);
  inherited Destroy;
end;

procedure T_152_FFMPEG_Reader_Second_Raster_Form.Do_Play;
var
  r: TFFMPEG_Reader;
  primary, second: TMZR;
begin
  primary := TMZR.Create;
  second := TMZR.Create;
  while Play_Activted do
    begin
      r := TFFMPEG_Reader.Create(TPath.GetLibraryPath+'lady.mp4');
      r.ResetFit(viewer.First.Raster.Width, viewer.First.Raster.Height);
      r.Reset_Fit_Second_Raster(viewer.Last.Raster.Width, viewer.Last.Raster.Height);
      while Play_Activted and r.ReadFrame(
        TIF<TMZR>.Do_(primary_CheckBox.IsChecked, primary, nil),
        TIF<TMZR>.Do_(second_CheckBox.IsChecked, second, nil), True) do
        begin
          Critical.Lock;
          if primary_CheckBox.IsChecked then
            begin
              viewer.First.Raster.SwapInstance(primary);
              viewer.First.Raster.Update;
            end;
          if second_CheckBox.IsChecked then
            begin
              viewer.Last.Raster.SwapInstance(second);
              viewer.Last.Raster.Update;
            end;
          Critical.UnLock;
          TCompute.Sleep(20);
        end;
    end;
  DisposeObject(primary);
  DisposeObject(second);
end;

end.
