unit MorphGalaxiesDetectionFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.Layouts,

  IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.Geometry3D,
  ZR.MemoryRaster, ZR.MemoryStream, ZR.Status, ZR.DrawEngine,
  ZR.Expression, ZR.DrawEngine.FMX, ZR.DrawEngine.PictureViewer,
  FMX.Memo.Types;

type
  TMorphGalaxiesDetectionForm = class(TForm)
    Memo1: TMemo;
    pb: TPaintBox;
    Timer1: TTimer;
    Button1: TButton;
    Layout1: TLayout;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    viewIntf: TPictureViewerInterface;
    DetectedList: TRectV2List;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
    procedure RunDetection;
  public
  end;

var
  MorphGalaxiesDetectionForm: TMorphGalaxiesDetectionForm;

implementation

{$R *.fmx}


procedure TMorphGalaxiesDetectionForm.Button1Click(Sender: TObject);
begin
  RunDetection;
end;

procedure TMorphGalaxiesDetectionForm.Button2Click(Sender: TObject);
begin
  DetectedList.Clear;
end;

procedure TMorphGalaxiesDetectionForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  viewIntf := TPictureViewerInterface.Create(DrawPool(pb));
  viewIntf.ShowHistogramInfo := False;
  viewIntf.ShowPixelInfo := False;
  viewIntf.ShowPictureInfo := False;
  viewIntf.ShowBackground := True;
  viewIntf.PictureViewerStyle := pvsLeft2Right;
  viewIntf.InputPicture(NewZRFromFile(TPath.GetLibraryPath+'galaxies.jpg'), 'ԭʼͼƬ', True);
  DetectedList := TRectV2List.Create;
end;

procedure TMorphGalaxiesDetectionForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapDown(vec2(X, Y));
end;

procedure TMorphGalaxiesDetectionForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapMove(vec2(X, Y));
end;

procedure TMorphGalaxiesDetectionForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  viewIntf.TapUp(vec2(X, Y));
end;

procedure TMorphGalaxiesDetectionForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      viewIntf.ScaleCamera(1.1)
  else
      viewIntf.ScaleCamera(0.9);
end;

procedure TMorphGalaxiesDetectionForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  box: TRectV2;
  i: Integer;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  viewIntf.DrawEng := d;
  viewIntf.Render;

  if DetectedList.Count > 0 then
    begin
      box := d.SceneToScreen(viewIntf.First.DrawBox);
      for i := 0 to DetectedList.Count - 1 do
          d.DrawBox(RectProjection(viewIntf.First.Raster.BoundsRectV2, box, DetectedList[i]), DEColor(1, 0.5, 0.5), 2);
      d.BeginCaptureShadow(vec2(2, 2), 0.9);
      d.DrawText(Format('��⵽ %d ������Ŀ��', [DetectedList.Count]), 18, d.ScreenRect, DEColor(1, 1, 0), False);
      d.EndCaptureShadow;
    end
  else
    begin
      d.BeginCaptureShadow(vec2(2, 2), 0.9);
      d.DrawText('�Ӿ�����֧������϶��Լ���������.', 18, d.ScreenRect, DEColor(1, 1, 0), False);
      d.EndCaptureShadow;
    end;
  d.Flush;
end;

procedure TMorphGalaxiesDetectionForm.RunDetection;
begin
  DetectedList.Clear;
  TCompute.RunP_NP(procedure
    var
      seg: TMSeg;
      i: Integer;
      r: TRectV2;
      TK: TTimeTick;
    begin
      // ���ȳ߶���ͼ
      with viewIntf.First.Raster.FitScaleAsNew(1024, 1024) do
        begin
          // ��ȡYIQ�е�YֵΪ��̬���ݣ���ͬ�ڻҶ�ͼ��Y���(R+G+B)/3����ϸ�ڸ���
          with BuildMorphomatics(TMPix.mpYIQ_Y) do
            begin
              DoStatus('��ȡ�ɻҶ�ͼ');
              with Binarization(0.3) do
                begin
                  DoStatus('�����ױ��Ŀ��');
                  OpeningAndClosing(3, 3);
                  DoStatus('��ʼ�ָ�');
                  TK := GetTimeTick();
                  seg := BuildMorphologySegmentation;
                  DoStatus('�ָ��ʱ ' + umlTimeTickToStr(GetTimeTick - TK) + ' ��');
                  Free;
                end;
              Free;
            end;
          Free;
        end;

      DoStatus('������Χ��');
      for i := 0 to seg.PoolCount - 1 do
        begin
          // ͶӰ���������ȳ߶���С���ķָ�����ͶӰ��ԭʼ�ߴ���
          r := RectProjection(seg.BoundsRectV2, viewIntf.First.Raster.BoundsRectV2, seg[i].BoundsRectV2());
          TCompute.Sync(procedure
            begin
              DetectedList.Add(r);
            end);
        end;
      DoStatus('�ͷ���ʱ�ڴ�');
      disposeObject(seg);
      DoStatus('�ָ����');
    end);
end;

procedure TMorphGalaxiesDetectionForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
  EnginePool.Progress();
  Invalidate;
end;

procedure TMorphGalaxiesDetectionForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

end.
