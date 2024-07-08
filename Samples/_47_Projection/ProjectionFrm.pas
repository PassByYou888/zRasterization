unit ProjectionFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects,

  System.IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib,
  ZR.Geometry2D,
  ZR.DrawEngine, ZR.MemoryRaster, ZR.DrawEngine.SlowFMX, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox;

type
  TProjectionForm = class(TForm)
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    s_LeftTop: TCircle;
    s_RightTop: TCircle;
    s_LeftBottom: TCircle;
    s_RightBottom: TCircle;
    d_RightTop: TCircle;
    d_LeftTop: TCircle;
    d_LeftBottom: TCircle;
    d_RightBottom: TCircle;
    s_Image: TImage;
    d_Image: TImage;
    TriangleCheckBox: TCheckBox;
    ModeComboBox: TComboBox;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure cMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure cMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure cMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure cPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure ModeComboBoxChange(Sender: TObject);
    procedure TriangleCheckBoxChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    ori, sour, dest: TMZR;

    downObj: TCircle;
    lastPt: TPointf;

    procedure RunProj;
  end;

var
  ProjectionForm: TProjectionForm;

implementation

{$R *.fmx}


procedure TProjectionForm.FormCreate(Sender: TObject);
begin
  ori := NewZRFromFile(umlCombineFileName(TPath.GetLibraryPath, 'canglaoshi.bmp'));
  ori.Black();

  sour := NewZR();
  sour.Assign(ori);

  s_Image.SetBounds(0, 0, sour.Width, sour.Height);
  MemoryBitmapToBitmap(sour, s_Image.Bitmap);

  dest := NewZR();
  dest.SetSize(round(d_Image.Width), round(d_Image.Height), ZRColor(0, 0, 0));
  MemoryBitmapToBitmap(dest, d_Image.Bitmap);

  downObj := nil;
  lastPt := Pointf(0, 0);
  RunProj();
end;

procedure TProjectionForm.cMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  downObj := TCircle(Sender);
  lastPt := TControl(downObj.Parent).AbsoluteToLocal(downObj.LocalToAbsolute(Pointf(X, Y)));
end;

procedure TProjectionForm.cMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  pt: TPointf;
begin
  if downObj <> Sender then
      exit;

  pt := TControl(downObj.Parent).AbsoluteToLocal(downObj.LocalToAbsolute(Pointf(X, Y)));

  downObj.Position.Point := downObj.Position.Point + (pt - lastPt);
  lastPt := pt;
end;

procedure TProjectionForm.cMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  downObj := nil;
  RunProj();
end;

procedure TProjectionForm.cPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  n: U_String;
begin
  Canvas.Fill.Color := TAlphaColorRec.Red;
  n := TComponent(Sender).Name;
  n.DeleteFirst;
  n.DeleteFirst;
  Canvas.FillText(ARect, n, False, 1.0, [], TTextAlign.Leading);
end;

procedure TProjectionForm.ModeComboBoxChange(Sender: TObject);
begin
  RunProj();

end;

procedure TProjectionForm.RunProj;
var
  ps, pd: TV2Rect4;
  tmpMorph: TMMath;
  tmpBin: TMBin;
begin
  ps.LeftTop := Vec2(s_LeftTop.BoundsRect.CenterPoint);
  ps.RightTop := Vec2(s_RightTop.BoundsRect.CenterPoint);
  ps.RightBottom := Vec2(s_RightBottom.BoundsRect.CenterPoint);
  ps.LeftBottom := Vec2(s_LeftBottom.BoundsRect.CenterPoint);

  pd.LeftTop := Vec2(d_LeftTop.BoundsRect.CenterPoint);
  pd.RightTop := Vec2(d_RightTop.BoundsRect.CenterPoint);
  pd.RightBottom := Vec2(d_RightBottom.BoundsRect.CenterPoint);
  pd.LeftBottom := Vec2(d_LeftBottom.BoundsRect.CenterPoint);

  sour.Assign(ori);

  dest.SetSize(round(d_Image.Width), round(d_Image.Height));
  FillBlackGrayBackgroundTexture(dest, 32);

  // ProjectionTo�ǻ��ڿ���ͶӰ��ԭ�ӷ���(���ײ��������vertex)
  // ԭ����4�����ԭ��ͶӰ��Ŀ��4�����Ŀ��
  // MemoryRasterͶӰʹ����4���������������������(TV2Rect4)��TRect���������������ȱ߿���
  // TV2Rect4ӵ�м������ţ�������ת������ƽ�ƣ���Χ������ȵȻ������ܣ���MemoryRasterӵ�����ػ�Ϲ��ܣ����߽�Ͼ���2dͶӰ�������
  // MemoryRasterͶӰʹ��˫����ƴ�ӳɲ�������壬���ڲ����������΢��ͶӰ����ͬ�����ǳ��õ��ǶԳƾ���ͶӰ������ͶӰ�Ǹ��Ӽ���ͶӰ�ĵػ�֧��
  // ��zAI��ͼ�����У�ͶӰ������Ӧ���ڶ��룬���գ��߶ȿռ䣬������MemoryRaster���ֶ���ͶӰ
  // ͶӰ�����ض��ǰ�alpha��ϵ��ӵģ����Ǹ���
  // �����ֿ�ͶӰ��Draw�ĸ��ͶӰ�����������draw�ǵ�һ�����

  if TriangleCheckBox.IsChecked then
    begin
      dest.OpenAgg;
      dest.Agg.LineWidth := 4;
      TZRVertex.DebugTriangle := True;
      TZRVertex.DebugTriangleColor := RColorF(1.0, 0.5, 0.5, 1);
    end
  else
    begin
      dest.CloseAgg;
      TZRVertex.DebugTriangle := False;
    end;

  case ModeComboBox.ItemIndex of
    0: sour.ProjectionTo(dest, ps, pd, True, 1.0);
    1:
      begin
        // ����ĳ�����Ҫ���˽��°汾����̬ѧ֧��ϵͳ
        tmpMorph := dest.BuildMorphomatics(TMPix.mpGrayscale);
        with sour.BuildMorphomatics(TMPix.mpA) do
          begin
            ProjectionTo(TMPix.mpGrayscale, TMPix.mpGrayscale, tmpMorph, ps, pd, True, 1.0);
            free;
          end;
        tmpMorph.DrawTo(TMPix.mpGrayscale, dest);
        disposeObject(tmpMorph);
      end;
    2:
      begin
        // ����ĳ�����Ҫ���˽��°汾����̬ѧ֧��ϵͳ
        with dest.BuildMorphomatics(TMPix.mpGrayscale) do
          begin
            tmpBin := Binarization_OTSU;
            free;
          end;
        with sour.BuildMorphomatics(TMPix.mpA) do
          begin
            with Binarization_OTSU do
              begin
                ProjectionTo(TMPix.mpGrayscale, TMPix.mpGrayscale, tmpBin, ps, pd, True, 1.0);
                free;
              end;
            free;
          end;
        tmpBin.DrawTo(TMPix.mpGrayscale, dest);
        disposeObject(tmpBin);
      end;
  end;

  MemoryBitmapToBitmap(dest, d_Image.Bitmap);

  sour.Agg.LineWidth := 5;
  sour.DrawRect(ps, ZRColorF(1, 0.5, 0.5));
  MemoryBitmapToBitmap(sour, s_Image.Bitmap);
end;

procedure TProjectionForm.TriangleCheckBoxChange(Sender: TObject);
begin
  RunProj();

end;

end.
