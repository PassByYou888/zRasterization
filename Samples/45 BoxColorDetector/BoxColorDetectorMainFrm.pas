unit BoxColorDetectorMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  ZR.Core,
  ZR.PascalStrings,
  ZR.UnicodeMixedLib,
  ZR.Status,
  ZR.Geometry2D,
  ZR.MemoryRaster, ZR.MemoryRaster.MorphologyExpression,
  ZR.DrawEngine,
  ZR.DrawEngine.SlowFMX;

type
  TBoxColorDetectorMainForm = class(TForm)
    oriImage: TImage;
    outImage: TImage;
    detButton: TButton;
    segmentLineDetButton: TButton;
    SegDetButton: TButton;
    LineDetButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure oriImageClick(Sender: TObject);
    procedure detButtonClick(Sender: TObject);
    procedure SegDetButtonClick(Sender: TObject);
    procedure LineDetButtonClick(Sender: TObject);
    procedure segmentLineDetButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    bk: TMZR;
    raster: TMZR;
  end;

var
  BoxColorDetectorMainForm: TBoxColorDetectorMainForm;

implementation

{$R *.fmx}


procedure TBoxColorDetectorMainForm.FormCreate(Sender: TObject);
var
  r: TRect;
  i: Integer;
  x: Integer;
begin
  raster := NewZR;
  bk := NewZR;
  BitmapToMemoryBitmap(oriImage.Bitmap, raster);
  bk.Assign(raster);

  ZR.Core.SetMT19937Seed(1);
  for i := 1 to 5 do
    begin
      repeat
        r.Left := umlRandomRange(5, raster.Width - 6);
        r.Right := umlRandomRange(5, raster.Width - 6);
        r.Top := umlRandomRange(5, raster.Height - 6);
        r.Bottom := umlRandomRange(5, raster.Height - 6);
      until (r.Width > 20) and (r.Height > 20);
      raster.DrawRect(RectV2(r), RColorF(1, 1, 1, 1));
    end;
  MemoryBitmapToBitmap(raster, oriImage.Bitmap);
end;

procedure TBoxColorDetectorMainForm.oriImageClick(Sender: TObject);
var
  r: TRect;
  i: Integer;
  x: Integer;
begin
  raster.Assign(bk);
  for i := 1 to 5 do
    begin
      repeat
        r.Left := umlRandomRange(5, raster.Width - 6);
        r.Right := umlRandomRange(5, raster.Width - 6);
        r.Top := umlRandomRange(5, raster.Height - 6);
        r.Bottom := umlRandomRange(5, raster.Height - 6);
      until (r.Width > 20) and (r.Height > 20);
      raster.DrawRect(RectV2(r), RColorF(1, 1, 1, 1));
    end;
  MemoryBitmapToBitmap(raster, oriImage.Bitmap);
end;

procedure TBoxColorDetectorMainForm.detButtonClick(Sender: TObject);
var
  d: TDrawEngine;
  n: U_String;
  dcol: TDEColor;
  MorphMath: TMorphomatics;
  MorphBin: TMorphologyBinaryzation;
  RCLines: TMorphologyRCLines;
  rl: TRectV2List;
  i: Integer;
  r: TRectV2;
begin
  {
    ��������⣺���������ָ�����4���ǵ㶼��ƽ������
  }
  d := TDrawEngine.Create;
  d.ZR_.Memory.SetSize(raster.Width, raster.Height, RColor(0, 0, 0));
  d.ZR_.UsedAgg := True;
  d.SetSize;
  d.ViewOptions := [];

  // ��̬ѧ�������Ƚ�YIQɫ����̬��Y�ռ���������ѧ��̬
  MorphMath := raster.BuildMorphomatics(TMorphologyPixel.mpYIQ_Y);

  // ʹ����ֵ������ѧ��̬�����ɶ�ֵ����̬
  // Binarization����򵥵�һ�ֶ�ֵ��������0.99���ж�ƫ���׵�YIQ.Yֵ�Ƿ��ͬ
  MorphBin := MorphMath.Binarization(0.99);

  // ���ڶ�ֵ����̬����ƽ���ߵļ��͹���
  RCLines := TMorphologyRCLines.BuildLines(MorphBin, 10);
  // ���ݹ���õ�ƽ�������ݣ�����������
  rl := RCLines.BuildFormulaBox();

  // �Ѽ����������
  d.DrawText(Format('total box:%d', [rl.Count]), 12, d.ScreenRect, DEColor(1, 1, 1, 1), False);
  for i := 0 to rl.Count - 1 do
    begin
      r := rl[i];
      dcol := RColor2DColor(RandomRColor($7F));
      d.DrawBox(r, dcol, 1);
      n := Format('%d*%d', [RoundWidth(r), RoundHeight(r)]);
      d.DrawLabelBox(n, 16, DEColor(1, 1, 1, 1), r, dcol, 2);
    end;
  d.Flush;

  disposeObject(MorphMath);
  disposeObject(MorphBin);
  disposeObject(rl);
  disposeObject(RCLines);
  MemoryBitmapToBitmap(d.ZR_.Memory, outImage.Bitmap);
  disposeObject(d);
end;

procedure TBoxColorDetectorMainForm.SegDetButtonClick(Sender: TObject);
var
  d: TDrawEngine;
  n: U_String;
  dcol: TDEColor;
  MorphMath: TMorphomatics;
  MorphBin: TMorphologyBinaryzation;
  RCLines: TMorphologyRCLines;
  rl: TRectV2List;
  i: Integer;
  r: TRectV2;
begin
  {
    �߶ηָ��Ŀ����⣺��һ��ƽ���߱���һ��ƽ�����ཻ������ƽ���߾ͻᱻ���������ߣ�ͬʱ��Ҳ��ʾ4���ǵ�
    ����˵��ͼ�������п��ܵĹ�����嶼�ᱻ�������������ص��Ŀ���
    ��Ϊ�����Ŀ���ǳ��࣬����������Ҫ���б�ɶԼ���������˴���
    ����㲻̫��дͼ����򣬿���ֱ��ʹ�ù��������
    ���п��ܳ��ֵĿ��壬�����ܼ�����
  }
  d := TDrawEngine.Create;
  d.ZR_.Memory.SetSize(raster.Width, raster.Height, RColor(0, 0, 0));
  d.ZR_.UsedAgg := False;
  d.SetSize;
  d.ViewOptions := [];

  // ��̬ѧ�������Ƚ�YIQɫ����̬��Y�ռ���������ѧ��̬
  MorphMath := raster.BuildMorphomatics(TMorphologyPixel.mpYIQ_Y);

  // ʹ����ֵ������ѧ��̬�����ɶ�ֵ����̬
  // Binarization����򵥵�һ�ֶ�ֵ��������0.99���ж�ƫ���׵�YIQ.Yֵ�Ƿ��ͬ
  MorphBin := MorphMath.Binarization(0.99);

  // ���ڶ�ֵ����̬���зָ��߼��͹���
  RCLines := TMorphologyRCLines.BuildIntersectSegment(MorphBin, 10);

  // ���ݹ���õķָ������ݣ�����������
  rl := RCLines.BuildFormulaBox();

  // �Ѽ����������
  d.DrawText(Format('total box:%d', [rl.Count]), 12, d.ScreenRect, DEColor(1, 1, 1, 1), False);
  for i := 0 to rl.Count - 1 do
    begin
      r := rl[i];
      dcol := RColor2DColor(RandomRColor($7F));
      n := Format('%d*%d', [RoundWidth(r), RoundHeight(r)]);
      d.DrawLabelBox(n, 16, DEColor(1, 1, 1, 1), r, dcol, 2);
    end;
  d.Flush;

  disposeObject(MorphMath);
  disposeObject(MorphBin);
  disposeObject(rl);
  disposeObject(RCLines);
  MemoryBitmapToBitmap(d.ZR_.Memory, outImage.Bitmap);
  disposeObject(d);
end;

procedure TBoxColorDetectorMainForm.LineDetButtonClick(Sender: TObject);
var
  n: TMZR;
  MorphMath: TMorphomatics;
  MorphBin: TMorphologyBinaryzation;
  RCLines: TMorphologyRCLines;
  p: PMorphologyRCLine;
  i: Integer;
begin
  {
    RC����ָ��Row+column�ߣ����Ǻ��ߺ�����
    ������嶼���ɺ���+�������
  }

  // ��̬ѧ�������Ƚ�YIQɫ����̬��Y�ռ���������ѧ��̬
  MorphMath := raster.BuildMorphomatics(TMorphologyPixel.mpYIQ_Y);

  // ʹ����ֵ������ѧ��̬�����ɶ�ֵ����̬
  // Binarization����򵥵�һ�ֶ�ֵ��������0.99���ж�ƫ���׵�YIQ.Yֵ�Ƿ��ͬ
  MorphBin := MorphMath.Binarization(0.99);

  // ���ڶ�ֵ����̬����RC�߼��͹���
  RCLines := TMorphologyRCLines.BuildLines(MorphBin, 10);

  // ����⵽��RC�߻�����
  n := NewZR();
  n.SetSize(raster.Width, raster.Height, RColor(0, 0, 0));
  for i := 0 to RCLines.Count - 1 do
    begin
      p := RCLines[i];
      n.LineF(Vec2(p^.Bp), Vec2(p^.ep), RandomRColor, True);
    end;

  disposeObject(MorphMath);
  disposeObject(MorphBin);
  disposeObject(RCLines);
  MemoryBitmapToBitmap(n, outImage.Bitmap);
  disposeObject(n);
end;

procedure TBoxColorDetectorMainForm.segmentLineDetButtonClick(Sender: TObject);
var
  n: TMZR;
  MorphMath: TMorphomatics;
  MorphBin: TMorphologyBinaryzation;
  RCLines: TMorphologyRCLines;
  p: PMorphologyRCLine;
  i: Integer;
begin
  {
    RC����ָ��Row+column�ߣ����Ǻ��ߺ�����
    ������嶼���ɺ���+�������
  }

  // ��̬ѧ�������Ƚ�YIQɫ����̬��Y�ռ���������ѧ��̬
  MorphMath := raster.BuildMorphomatics(TMorphologyPixel.mpYIQ_Y);

  // ʹ����ֵ������ѧ��̬�����ɶ�ֵ����̬
  // Binarization����򵥵�һ�ֶ�ֵ��������0.99���ж�ƫ���׵�YIQ.Yֵ�Ƿ��ͬ
  MorphBin := MorphMath.Binarization(0.99);

  // ���ڶ�ֵ����̬����RC�߼��͹���
  RCLines := TMorphologyRCLines.BuildIntersectSegment(MorphBin, 10);

  // ����⵽��RC�߻�����
  n := NewZR();
  n.SetSize(raster.Width, raster.Height, RColor(0, 0, 0));
  for i := 0 to RCLines.Count - 1 do
    begin
      p := RCLines[i];
      n.LineF(Vec2(p^.Bp), Vec2(p^.ep), RandomRColor, True);
    end;

  disposeObject(MorphMath);
  disposeObject(MorphBin);
  disposeObject(RCLines);
  MemoryBitmapToBitmap(n, outImage.Bitmap);
  disposeObject(n);
end;

end.
