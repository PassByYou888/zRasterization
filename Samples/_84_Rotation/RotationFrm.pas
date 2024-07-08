unit RotationFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.Layouts,

  IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.Geometry3D,
  ZR.MemoryRaster, ZR.MemoryStream, ZR.Status, ZR.DrawEngine,
  ZR.Expression,
  ZR.DrawEngine.FMX,
  FMX.Memo.Types;

type
  TApproximatePolygonForm = class(TForm)
    pb1: TPaintBox;
    pb2: TPaintBox;
    Memo1: TMemo;
    Timer1: TTimer;
    Layout1: TLayout;
    Label1: TLabel;
    sRotateEdit: TEdit;
    Layout2: TLayout;
    Label2: TLabel;
    sOffsetEdit: TEdit;
    Layout3: TLayout;
    Label3: TLabel;
    sScaleEdit: TEdit;
    Layout4: TLayout;
    Label4: TLabel;
    sAxisEdit: TEdit;
    Layout5: TLayout;
    Label5: TLabel;
    dRotateEdit: TEdit;
    Layout6: TLayout;
    Label6: TLabel;
    dOffsetEdit: TEdit;
    Layout7: TLayout;
    Label7: TLabel;
    dScaleEdit: TEdit;
    Layout8: TLayout;
    Label8: TLabel;
    dAxisEdit: TEdit;
    projButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure pb1Paint(Sender: TObject; Canvas: TCanvas);
    procedure pb2Paint(Sender: TObject; Canvas: TCanvas);
    procedure projButtonClick(Sender: TObject);
    procedure sourceOptChange(Sender: TObject);
    procedure TargetOptChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    bk, sour, dest: TMZR;
    sour_rect, dest_rect: TV2R4;
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    // raster����դ
    // angle����ת�Ƕȣ�0..360��-180-180
    // scale������������0..1֮��ĸ���
    // axis����ת�����꣬�������ó߶������壬��0..1֮��ĸ��㣬��������������ԭ��
    // offset��ƫ�������������ó߶������壬��0..1֮��ĸ��㣬��������������ԭ��
    function RebuildRect(raster: TMZR; Angle_, scale_: TGeoFloat; rotate_axis_, offset_: TVec2): TV2R4;
    procedure DoProjection;
  end;

var
  ApproximatePolygonForm: TApproximatePolygonForm;

implementation

{$R *.fmx}


procedure TApproximatePolygonForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 32, RColor(0, 0, 0), RColorF(0.5, 0.5, 0.5), RColorF(0.4, 0.4, 0.4));

  sour := NewZRFromFile(TPath.GetLibraryPath+'lena.bmp');
  dest := NewZR();
  dest.SetSizeR(sour.BoundsRectV2);

  sourceOptChange(nil);
  TargetOptChange(nil);
  DoProjection();
end;

procedure TApproximatePolygonForm.pb1Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  box: TV2R4;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voEdge];
  d.EdgeColor := DEColor(1, 0, 0);

  // ������
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);

  // �ȳ߶Ȼ��ƺ�ȡ������Ŀ����Ļ�Ŀ��壬����sour_rectͶӰ��box
  box := sour_rect.Projection(sour.BoundsRectV20, d.FitDrawPicture(sour, sour.BoundsRectV20, RectEdge(d.ScreenRectV2, -20), 1.0));

  // ��box������
  d.DrawDotLineBox(box, DEColor(1, 1, 1, 1), 2);
  with box do
    begin
      d.DrawCross(LeftTop, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(RightTop, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(RightBottom, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(LeftBottom, DEColor(0.5, 0.5, 1.0), 10, 3);
    end;

  d.BeginCaptureShadow(Vec2(2, 2), 1);
  d.DrawText('ԭͼ�� |color(1,0,0)|��������ͶӰ���� ||X��4����������', 14, DEColor(1, 1, 1), Vec2(5, 5));
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TApproximatePolygonForm.pb2Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  oriBox: TRectV2;
  box: TV2R4;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voEdge];
  d.EdgeColor := DEColor(1, 0, 0);

  // ������
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);

  // �ȳ߶Ȼ��ƺ�ȡ������Ŀ����Ļ�Ŀ��壬����sour_rectͶӰ��box
  oriBox := d.FitDrawPicture(dest, dest.BoundsRectV20, RectEdge(d.ScreenRectV2, -20), 1.0);
  box := dest_rect.Projection(dest.BoundsRectV20, oriBox);

  // ��box������
  d.DrawDotLineBox(box, DEColor(0.5, 0.5, 1, 1), 2);
  with box do
    begin
      d.DrawCross(LeftTop, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(RightTop, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(RightBottom, DEColor(0.5, 0.5, 1.0), 10, 3);
      d.DrawCross(LeftBottom, DEColor(0.5, 0.5, 1.0), 10, 3);
    end;

  // ��ԭʼͼƬ�Ŀ򻭳���
  d.DrawBox(oriBox, DEColor(1, 1, 0, 1), 2);

  d.BeginCaptureShadow(Vec2(2, 2), 1);
  d.DrawText('��ת���ͼ�� |color(1,1,0)|Ŀ��ͼƬΪ�ƿ�(Ŀ�����alpha) ||����ΪͶӰ��դ����', 14, DEColor(1, 1, 1), Vec2(5, 5));
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TApproximatePolygonForm.sourceOptChange(Sender: TObject);
begin
  sour_rect := RebuildRect(sour,
    EStrToFloat(sRotateEdit.Text, 0),
    EStrToFloat(sScaleEdit.Text, 1.0),
    StrToVec2(sAxisEdit.Text),
    StrToVec2(sOffsetEdit.Text));
end;

procedure TApproximatePolygonForm.TargetOptChange(Sender: TObject);
begin
  dest_rect := RebuildRect(dest,
    EStrToFloat(dRotateEdit.Text, 0),
    EStrToFloat(dScaleEdit.Text, 1.0),
    StrToVec2(dAxisEdit.Text),
    StrToVec2(dOffsetEdit.Text));
end;

procedure TApproximatePolygonForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
  EnginePool.Progress();
  Invalidate;
end;

procedure TApproximatePolygonForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  Memo1.Lines.Add(Text_);
  Memo1.GoToTextEnd;
end;

function TApproximatePolygonForm.RebuildRect(raster: TMZR; Angle_, scale_: TGeoFloat; rotate_axis_, offset_: TVec2): TV2R4;
begin
  // TV2R4=TV2Rect4�����ݽṹ��4��2D Vector������������4������ɵĲ��������
  // TV2R4.Init��ͬ�ڹ�������
  // TV2R4�Ļ����Ⱦ������
  // TV2R4���ײ��������ھ��󣬲�����=�ɲ���ԣ��ɷ�����

  // raster����դ
  // angle����ת�Ƕȣ�0..360��-180-180
  // scale��size����������0..1֮��ĸ���
  // axis����ת�����꣬�������ó߶������壬��0..1֮��ĸ��㣬��������������ԭ��
  // offset��ƫ�������������ó߶������壬��0..1֮��ĸ��㣬��������������ԭ��
  Result := TV2R4.Init(
    RectMul(RectAdd(raster.BoundsRectV2, Vec2Mul(offset_, raster.Size2D)), scale_), // rect
    Vec2Mul(raster.Size2D, rotate_axis_),                                           // rotation axis
    Angle_                                                                          // rotation angle
    );
end;

procedure TApproximatePolygonForm.DoProjection;
begin
  // ����Ŀ���դ
  dest.Clear(RColor(0, 0, 0, 0));

  // ͶӰ����һ������
  // ��դͶӰ�ļ����ں�ʹ��������䣬�����������ν�һ�����������ÿ�����
  // ���������dest.Vertex��ʵ�֣�������ʹ��debug׷
  // ���������Զ�֧�ֲ��У�������ģ�ǳ��󣬸���1000�ֱ���ʱ��Vertex������Զ����������������
  // ʵ�⣺��8000*8000�ֱ��ʵ�ͼƬ���ʱ�����м����������ٸߴ�4-8�������������̲�����ֵ��ڴ�������ͷ�
  sour.ProjectionTo(dest, sour_rect, dest_rect, True, 1.0);

  // ��������ʹ��������fmx�и���
  dest.NoUsage;
end;

procedure TApproximatePolygonForm.projButtonClick(Sender: TObject);
begin
  DoProjection;
end;

end.
