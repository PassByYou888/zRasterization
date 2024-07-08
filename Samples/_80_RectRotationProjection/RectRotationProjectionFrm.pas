unit RectRotationProjectionFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  FMX.ScrollBox, FMX.Memo,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.MemoryRaster,
  ZR.MemoryStream, ZR.Status, ZR.DrawEngine, ZR.DrawEngine.FMX,
  FMX.Memo.Types;

type
  TRectRotationProjectionForm = class(TForm)
    Timer1: TTimer;
    PaintBox1: TPaintBox;
    PaintBox2: TPaintBox;
    Memo1: TMemo;
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBox2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBox2Paint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
  public
    dIntf: TDrawEngineInterface_FMX;
    destBox: TRectV2; // Ŀ��ͶӰ��
    a: TDEFloat;      // Ŀ��ͶӰ�����ת�Ƕ�
    destPt: TVec2;    // λ��Ŀ��ͶӰ���е�����
    constructor Create(AOwner: TComponent); override;
  end;

var
  RectRotationProjectionForm: TRectRotationProjectionForm;

implementation

{$R *.fmx}


procedure TRectRotationProjectionForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  // ��ͼ������ѭ��
  a := NormalizeDegAngle(a + EnginePool.Progress() * 5);
  Invalidate;
end;

constructor TRectRotationProjectionForm.Create(AOwner: TComponent);
begin
  inherited;
  dIntf := TDrawEngineInterface_FMX.Create;
  destBox := RectV2(0, 0, 100, 200);
  destPt := Vec2(250, 250);
  a := 15;
end;

procedure TRectRotationProjectionForm.PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  destPt := Vec2(X, Y);
end;

procedure TRectRotationProjectionForm.PaintBox1Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voEdge];
  d.FillBox();
  d.DrawPoint(destPt, DEColor(1, 0.5, 0, 5), 20, 2);
  d.DrawText('|color(0.5,1,0.5)|�ڴ˴��ƶ������ͶӰ', 14, d.ScreenRectV2, DEColor(1, 1, 1), False);
  d.Flush;
end;

procedure TRectRotationProjectionForm.PaintBox2MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  d: TDrawEngine;
  r: TRectV2;
  v: TVec2;
begin
  d := DrawPool(Sender);
  r := destBox;
  r := RectAdd(r, Vec2((d.width - RectWidth(r)) * 0.5, (d.Height - RectHeight(r)) * 0.5));

  v := Vec2(X, Y);
  with TV2R4.Init(r, a) do
    if not InHere(Vec2(X, Y)) then
        v := GetNear(v);
  // ��ͶӰ
  destPt := RectProjectionRotationSource(r, RectV2(0, 0, 500, 500), a, v);
end;

procedure TRectRotationProjectionForm.PaintBox2Paint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  r: TRectV2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voEdge];
  d.FillBox();
  // ��Ŀ��ͶӰ�򻭵�����λ��
  r := destBox;
  r := RectAdd(r, Vec2((d.width - RectWidth(r)) * 0.5, (d.Height - RectHeight(r)) * 0.5));
  d.DrawDotLineBox(r, RectCentre(r), a, DEColor(1, 1, 1), 2);
  // �������֣���ͶӰ�����ú��� RectProjectionRotationDest
  d.DrawPoint(RectProjectionRotationDest(RectV2(0, 0, 500, 500), r, a, destPt), DEColor(1, 0.5, 0, 5), 20, 2);
  // ��һ��ͨ�õ���ͶӰ�ĺ��� RectRotationProjection Ҳ�ܴﵽͬ����Ŀ��
  // d.DrawPoint(RectRotationProjection(RectV2(0, 0, 500, 500), r, 0, a, destPt), DEColor(1, 0.5, 0, 5), 20, 2);
  // ��ͶӰ�����ܻ��ϼǺ�
  with TV2R4.Init(r, a) do
    begin
      d.DrawText('����', 14, DEColor(0.5, 1, 0.5), LeftTop, a);
      d.DrawText('����', 14, DEColor(0.5, 1, 0.5), RightTop, a);
      d.DrawText('����', 14, DEColor(0.5, 1, 0.5), RightBottom, a);
      d.DrawText('����', 14, DEColor(0.5, 1, 0.5), LeftBottom, a);
    end;
  d.DrawText(
    '|color(0.5,1,0.5)|�ڴ˴��ƶ���귴ͶӰ||' + #13#10 +
    '�ϸ񻮷֣�ͶӰ��ͼ�����򣬶����ڿռ䵽�ռ�֮���ת��' + #13#10 +
    '����ͶӰ�ǽ�ԭ�������갴�߶Ⱥ���תͶӰ��Ŀ�����' + #13#10 +
    '���ǿ���ע�⵽Ŀ���������ת��Ŀ�����߶Ⱥ�ԭ���岢����ͬ' + #13#10 +
    'ͶӰ�ļ����ʹ�ã���Ҫ����������У����ǹ�ʽ���㣬��������' + #13#10 +
    '��ͶӰ����: |color(0.5,1.0,0.5)|RectProjectionRotationDest||' + #13#10 +
    '��ͶӰ����: |color(0.5,1.0,0.5)|RectProjectionRotationSource||' + #13#10 +
    '����ͨ��ͶӰ����: |color(0.5,1.0,0.5)|RectRotationProjection||' + #13#10 +
    '��DemoͶӰ���㲻ʹ�öԳƾ����������Ը�ֱ�۵����ͶӰ', 14, d.ScreenRectV2, DEColor(1, 1, 1), False);
  d.Flush;
end;

end.
