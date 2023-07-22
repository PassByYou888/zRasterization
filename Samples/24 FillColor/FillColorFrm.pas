unit FillColorFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  Threading, SyncObjs,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.MemoryRaster,
  ZR.MemoryStream, ZR.Status, ZR.DrawEngine, ZR.DrawEngine.FMX;

type
  TFillColorForm = class(TForm)
    Timer1: TTimer;
    Timer2: TTimer;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    dIntf: TDrawEngineInterface_FMX;
    tex: TDETexture;

    constructor Create(AOwner: TComponent); override;

    procedure BuildGeometry(w, h, steps: Integer; output: TMZR);
  end;

var
  FillColorForm: TFillColorForm;

implementation

{$R *.fmx}


procedure TFillColorForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Self);
  d := DrawPool(Self, dIntf);

  d.DrawOptions := [voFPS, voEdge];
  d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  d.FitDrawPicture(tex, tex.BoundsRectV2, d.ScreenRect, 1.0);
  d.Flush;
end;

procedure TFillColorForm.Timer1Timer(Sender: TObject);
begin
  EnginePool.Progress(Interval2Delta(Timer1.Interval));
  Invalidate;
end;

procedure TFillColorForm.Timer2Timer(Sender: TObject);
begin
  TComputeThread.RunP(nil, tex, procedure(thSender: TComputeThread)
    var
      n: TDETexture;
    begin
      n := TDrawEngine.NewTexture;
      BuildGeometry(Round(Width), Round(Height), 15, n);
      TThread.Synchronize(thSender, procedure
        begin
          DisposeObject(tex);
          tex := n;
        end);
    end);
end;

constructor TFillColorForm.Create(AOwner: TComponent);
begin
  inherited;
  dIntf := TDrawEngineInterface_FMX.Create;
  tex := TDrawEngine.NewTexture;
  BuildGeometry(Round(Width), Round(Height), 15, tex);
end;

procedure TFillColorForm.BuildGeometry(w, h, steps: Integer; output: TMZR);
const
  edge = 30;
var
  j: Integer;
  vl: TVec2List;
  v: TVec2;
begin
  output.SetSize(w, h, ZRColorF(0, 0, 0, 1));
  MT19937Randomize();

  vl := TVec2List.Create;
  // ����stepsϵ������ԭʼ����ϵ
  for j := 0 to steps - 1 do
      vl.Add(umlRandomRange(edge, w - edge), umlRandomRange(edge, h - edge));
  // ���㼸�ε㼯͹��
  vl.ConvexHull;

  // ���л����͹��
  // ���л��������Ч�ʻ����������� ����:�㷨���Ż�������ڳ����Ӳ�����Ż�
  // ע��:���л�������֧�ְ�͹�����
  // ע��:�������ֻ��͹�����
  // ��ͼ������ָ����,�����������Ϊ��Ҫ���������Դ,������似��������Ӧ��
  DelphiParallelFor(0, h - 1, procedure(pass: Integer)
    var
      i: Integer;
    begin
      // ����ĳ���ģʽ������shader�ɱ�̹���
      for i := 0 to w - 1 do
        if vl.InHere(Vec2(i, pass)) then
            output.Pixel[i, pass] := ZRColorF(0.5, 0, 0, 1);
    end);
  // ������䣬���ַ��������õģ�������ֱ�ӻ�ͼ
  // output.Vertex.FillPoly(vl, RasterColorF(0, 1, 0, 0.5));

  // ����Χ�ߣ���䷨ֻ����ָ������ɫ��Ե������
  output.FillNoneBGColorBorder(ZRColorF(0, 0, 0, 1), RColorF(1, 1, 1, 1), 4);

  // ��������
  output.DrawCrossF(vl.Centroid, 10, ZRColorF(1, 1, 1, 1));

  DisposeObject(vl);
end;

end.
