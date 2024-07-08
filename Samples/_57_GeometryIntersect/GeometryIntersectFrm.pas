unit GeometryIntersectFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  Threading, SyncObjs,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.MemoryRaster,
  ZR.MemoryStream, ZR.Status, ZR.DrawEngine, ZR.DrawEngine.FMX;

type
  TGeometryIntersectForm = class(TForm)
    Timer1: TTimer;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
  public
    dIntf: TDrawEngineInterface_FMX;
    {
      TDeflectionPolygon��һ���������ϵ�ļ������ݼ�,���������þ���ֵ����������λ��
      TDeflectionPolygonÿ��������angle+distance,�Ƕ�+��������������
      ��Demo����TDeflectionPolygon����ϵ��ͼʱ,ʹ����TDeflectionPolygon.Points�������������ϵת�����˾�������ϵ(ֻ�о�������ϵ�������ⲿ��ͼapi��ӿ�,����d2d,opengl)
      ��TMemoryRaster�л��ı����ڳ��õĹ�դ����,���������ת,����,���εȵ��ڴ���,��û��ʹ�öԳƾ���,���е��ı�������ϵ��ʹ����TDeflectionPolygon���б任
      ��ͼ������ָ�(�ָ�ṹ�Ǽ��νṹ),����ʶ����Ű�(����ϵ���Ű�������Ǽ��νṹ)
      �������ϵ��ͬ�����TDeflectionPolygon��������˼·�ĺ���

      TVec2List����洢�ļ����������Ǿ�������ֵ

      ��ʹ��ʱ����Ҫע������TVec2List��TDeflectionPolygon������ϵ,
      �ڶ��������,TVec2List������漸���εĳ���,ͼ������ֵ
      TDeflectionPolygon�����������ʱ�仯�ĳ������ݺ�ͼ������
    }
    geoBuff: TGenericsList<TDeflectionPolygon>;
    ColorBuff: TGenericsList<TPolyDrawOption>;

    constructor Create(AOwner: TComponent); override;
    procedure compute_LineInt(pt1, pt2: TVec2; poly: TDeflectionPolygon; output: TV2L);
    function ComputeIntersectVec: TV2L;
    procedure RebuildGeoBuff;
  end;

var
  GeometryIntersectForm: TGeometryIntersectForm;

implementation

{$R *.fmx}


procedure TGeometryIntersectForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  i: Integer;
  intersectVecList: TV2L;
begin
  dIntf.SetSurface(Canvas, Self);
  d := DrawPool(Self, dIntf);

  d.DrawOptions := [voFPS, voEdge];
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  // ��poly������
  for i := 0 to geoBuff.Count - 1 do
      d.DrawPolyInScene(geoBuff[i], True, ColorBuff[i]);

  // ʵʱ���㽻�漸�����ཻ
  intersectVecList := ComputeIntersectVec();

  // ���ཻ���껭����Ļ��
  for i := 0 to intersectVecList.Count - 1 do
      d.DrawPoint(intersectVecList[i]^, DEColor(1.0, 1.0, 1.0, 0.5), 5, 1);

  DisposeObject(intersectVecList);

  d.Flush;
end;

procedure TGeometryIntersectForm.Timer1Timer(Sender: TObject);
var
  d: Double;
  i: Integer;
begin
  CheckThread;
  // ��internal����ʱ��ת�����뵥λ�ĸ���ʱ��
  // ����ת�����߼�ת��,����ʱ���ǹ̶���,����������ʱ��
  // ���Ҫʹ������ʱ�����delta,��Ҫ����cadencer��api�ӿ�,��ο�ʹ����cadencer��api���demo
  d := Interval2Delta(Timer1.Interval);
  // ��ͼ������ѭ��
  EnginePool.Progress(d);

  // ��poly������ת��
  // polyʹ�õ����������ϵ,���ǿ���ֱ�Ӹ���poly��angle,��ͬ��TVec2List�ع���һ�μ���,��Poly����ϵ��,��0����ʵ�ּ��α���,��Ϊpolyʹ���������ϵ
  // ��ÿ��45�ȵ��ٶȽ�����ת����,Ȼ���һ����Բ��
  // ��һ������degAngle�ǽ�180����Ϊһ����һ�������д���,Խ��180��-0..-180�ȿ�ʼ����,�ص�������ͬ��360��
  for i := 0 to geoBuff.Count - 1 do
      geoBuff[i].Angle := NormalizeDegAngle(geoBuff[i].Angle + 15 * d);

  Invalidate;
end;

procedure TGeometryIntersectForm.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  // ��������������,�ؽ����νṹ
  RebuildGeoBuff;
end;

constructor TGeometryIntersectForm.Create(AOwner: TComponent);
begin
  inherited;
  dIntf := TDrawEngineInterface_FMX.Create;
  geoBuff := TGenericsList<TDeflectionPolygon>.Create;
  ColorBuff := TGenericsList<TPolyDrawOption>.Create;
  RebuildGeoBuff;
end;

procedure TGeometryIntersectForm.compute_LineInt(pt1, pt2: TVec2; poly: TDeflectionPolygon; output: TV2L);
var
  i: Integer;
  dpt1, dpt2: TVec2;
  v: TVec2;
begin
  // �ཻ�㼼���ǳ���,��ÿ��nM/s����Line����Ϊ��λ
  // ��Demo���ཻ�����cpu��������Ϊ0
  dpt1 := poly.Points[0];
  for i := 1 to poly.Count - 1 do
    begin
      // poly.Points�ǽ�poly���������ϵ�Ծ�������ȡ����
      // poly�л���Expands����,��ʾ͹�Գ�,�����ڱ�ʾ���οռ�ļ��㴦��
      // ������ʽ���ε����㷨��,expands�����ڹ�������εİ�͹���Ŀռ�,���ǵ�������ĺ����㷨�ػ�
      dpt2 := poly.Points[i];
      // Intersect�Ǹ�ԭ��api,���������Ծ������������������ཻ��
      // ��Poly�����ֳɵ��ཻ����api,�����������ص�ʹ��ԭ��api��������Ϊ�˸���˵���ཻ�������ȷ����
      if Intersect(pt1, pt2, dpt1, dpt2, v) then
          output.Add(v);
      dpt1 := dpt2;
    end;
  // �պ��߹���
  // �ڽ�βʱ,�ó����߼�����һ�������ıպϲ���
  dpt2 := poly.Points[0];
  // Intersect�Ǹ�ԭ��api,���������Ծ������������������ཻ��
  // ��Poly�����ֳɵ��ཻ����api,�����������ص�ʹ��ԭ��api��������Ϊ�˸���˵���ཻ�������ȷ����
  if Intersect(pt1, pt2, dpt1, dpt2, v) then
      output.Add(v);
end;

function TGeometryIntersectForm.ComputeIntersectVec: TV2L;
var
  tmp: TGenericsList<TDeflectionPolygon>;
  poly: TDeflectionPolygon;
  i, j: Integer;
  pt1, pt2: TVec2;
begin
  // ���ٱ���GeoBuff���м������ཻ�㷶ʽ
  Result := TV2L.Create;
  tmp := TGenericsList<TDeflectionPolygon>.Create;

  // �ȴ���һ����������
  for i := 0 to geoBuff.Count - 1 do
      tmp.Add(geoBuff[i]);

  // ����������ʹ�öԳ��ų�������
  while tmp.Count > 0 do
    begin
      poly := tmp.First;
      for i := 1 to tmp.Count - 1 do
        begin
          pt1 := poly.Points[0];
          for j := 1 to poly.Count - 1 do
            begin
              pt2 := poly.Points[j];
              compute_LineInt(pt1, pt2, tmp[i], Result);
              pt1 := pt2;
            end;
          pt2 := poly.Points[0];
          compute_LineInt(pt1, pt2, tmp[i], Result);
        end;
      tmp.Delete(0);
    end;
  DisposeObject(tmp);
end;

procedure TGeometryIntersectForm.RebuildGeoBuff;
const
  edge = 50;
var
  i, j: Integer;
  vl: TV2L;
  v: TVec2;
  poly: TDeflectionPolygon;
  pdo: TPolyDrawOption;
begin
  for i := 0 to geoBuff.Count - 1 do
      DisposeObject(geoBuff[i]);
  geoBuff.Clear;
  ColorBuff.Clear;

  // �������������
  for j := 1 to 5 do
    begin
      vl := TV2L.Create;
      for i := 1 to 5 do
          vl.Add(umlRandomRange(edge, round(width) - edge), umlRandomRange(edge, round(height) - edge));

      // �Ѹ��Ӽ���ת����͹��,����鿴
      //vl.ConvexHull();

      poly := TDeflectionPolygon.Create;
      poly.Rebuild(vl, True);
      geoBuff.Add(poly);

      // ������ɫ,������ȵȻ�ͼ����
      pdo.LineWidth := 2;
      pdo.PointScreenRadius := 3;
      pdo.LineColor := DEColor(umlRandomRange(1, 9) * 0.1, umlRandomRange(1, 9) * 0.1, umlRandomRange(1, 9) * 0.1, 0.5);
      pdo.PointColor := DEColor(0.5, 0.5, 0.5, 0.5);
      ColorBuff.Add(pdo);

      DisposeObject(vl);
    end;

  // ��������
  for j := 1 to 20 do
    begin
      vl := TV2L.Create;
      for i := 1 to 2 do
          vl.Add(umlRandomRange(edge, round(width) - edge), umlRandomRange(edge, round(height) - edge));

      poly := TDeflectionPolygon.Create;
      poly.Rebuild(vl, True);
      geoBuff.Add(poly);

      // ������ɫ,������ȵȻ�ͼ����
      pdo.LineWidth := 2;
      pdo.PointScreenRadius := 3;
      pdo.LineColor := DEColor(umlRandomRange(1, 9) * 0.1, umlRandomRange(1, 9) * 0.1, umlRandomRange(1, 9) * 0.1, 1);
      pdo.PointColor := DEColor(0.5, 0.5, 0.5, 0.5);
      ColorBuff.Add(pdo);

      DisposeObject(vl);
    end;
end;

end.
