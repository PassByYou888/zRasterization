unit MorphologySegmentationMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls,
  FMX.Controls.Presentation,

  System.IOUtils, System.Threading,

  ZR.Core, ZR.UnicodeMixedLib, ZR.PascalStrings, ZR.Geometry2D, ZR.MemoryRaster, ZR.MemoryStream,
  ZR.Status,
  ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TMorphologySegmentationMainForm = class(TForm)
    segListPB: TPaintBox;
    segPB: TPaintBox;
    Timer1: TTimer;
    Splitter1: TSplitter;
    openButton: TButton;
    OpenDialog1: TOpenDialog;
    ViewGeometryCheckBox: TCheckBox;
    ViewEdgeLinesCheckBox: TCheckBox;
    EdgeLinesCrossCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure openButtonClick(Sender: TObject);
    procedure segListPBPaint(Sender: TObject; Canvas: TCanvas);
    procedure segPBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure segPBPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
    procedure ViewGeometryCheckBoxClick(Sender: TObject);
  private
    drawIntf: TDrawEngineInterface_FMX;
  public
    tex: TMZR;
    tex_box: TRectV2;
    pickColor: TRColor;
    SegImgList: TMemoryZRList;
    LastSegBox: TArrayRectV2;

    // ����ķָ�������ɫ����ID
    procedure GetPixelSegClassify(X, Y: Integer; Color: TRColor; var Classify: TMorphologyClassify);

    // �����ָ�
    procedure BuildSeg;
  end;

var
  MorphologySegmentationMainForm: TMorphologySegmentationMainForm;

implementation

{$R *.fmx}


procedure TMorphologySegmentationMainForm.FormCreate(Sender: TObject);
begin
  drawIntf := TDrawEngineInterface_FMX.Create;
  tex := NewZRFromFile(umlCombineFileName(TPath.GetLibraryPath, 'ColorSeg1.bmp'));
  SegImgList := TMemoryZRList.Create;
  SetLength(LastSegBox, 0);
end;

procedure TMorphologySegmentationMainForm.segListPBPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  r: TRectV2;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voEdge];

  d.FillBox(d.ScreenRect, DEColor(0.1, 0.1, 0.1));

  LockObject(SegImgList);
  d.CameraR := d.DrawPicturePackingInScene(SegImgList, 10, Vec2(0, 0), 1.0, True);
  UnLockObject(SegImgList);

  d.DrawText('���طָ��', 16, d.ScreenRect, DEColor(0.5, 1.0, 0.5), False);
  d.Flush;
end;

procedure TMorphologySegmentationMainForm.segPBMouseUp(Sender: TObject; Button:
  TMouseButton; Shift: TShiftState; X, Y: Single);
var
  pt: TVec2;
  i: Integer;
  c: TRColorEntry;
begin
  LockObject(SegImgList);
  for i := 0 to SegImgList.count - 1 do
      DisposeObject(SegImgList[i]);
  SegImgList.Clear;
  UnLockObject(SegImgList);

  pt := RectProjection(tex_box, tex.BoundsRectV2, Vec2(X, Y));
  if PointInRect(pt, tex.BoundsRectV2) then
    begin
      pickColor := tex.PixelVec[pt];

      // if RColorDistance(pickColor, RColor(0, 0, 0)) < color_threshold then
      // begin
      // DrawPool(segPB).PostScrollText(5, '����ʰȡ��ɫ', 24, DEColor(1, 0, 0));
      // exit;
      // end;

      c.BGRA := pickColor;

      DrawPool(segPB).PostScrollText(5, Format('���ڷָ���ɫ|color(%d,%d,%d)|(%d,%d,%d)||' + #13#10, [c.r, c.G, c.B, c.r, c.G, c.B]),
        24, DEColor(1.0, 1.0, 1.0));

      BuildSeg;
    end;
end;

procedure TMorphologySegmentationMainForm.segPBPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  n: U_String;
  i: Integer;
  c: TRColorEntry;
begin
  drawIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, drawIntf);
  d.ViewOptions := [voEdge];

  d.FillBox(d.ScreenRect, DEColor(0.5, 0.5, 0.5));

  tex_box := d.FitDrawPicture(tex, tex.BoundsRectV2, RectEdge(d.ScreenRect, -20), 1.0);

  for i := 0 to length(LastSegBox) - 1 do
      d.DrawBox(RectTransform(tex.BoundsRectV2, tex_box, LastSegBox[i]), DEColor(1, 0.5, 0.5, 1), 2);

  d.DrawDotLineBox(tex_box, Vec2(0.5, 0.5), 0, DEColor(0.8, 0.1, 0.4), 3);

  d.Flush;
end;

procedure TMorphologySegmentationMainForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  DoStatus;
  DrawPool.Progress;
  Invalidate;
end;

procedure TMorphologySegmentationMainForm.GetPixelSegClassify(X, Y: Integer; Color: TRColor; var Classify: TMorphologyClassify);
var
  i: Integer;
  ID: WORD;
begin
  // ����ķָ�������ɫ����ID
  // Classify�� 0 ��ʾ�����ɫ���طָ�������0�Ļ����ָ����ᰴClassify���з���
  Classify := 0;

  if RColorDistance(pickColor, RColor(0, 0, 0)) < 0.1 then
      exit;

  if RColorDistance(pickColor, Color) < 0.01 then
      Classify := pickColor;
end;

procedure TMorphologySegmentationMainForm.BuildSeg;
begin
  TComputeThread.RunP(nil, nil, procedure(ThSender: TComputeThread)
    var
      s, test: TMorphologySegmentation;
      first_total: Integer;
      stream: TMS64;
    begin
      test := TMorphologySegmentation.Create;
      // �ָ�������ɫ����ӿ�
      test.OnGetPixelSegClassify := GetPixelSegClassify;
      // ��̬�ָ�������������ʱ�ǿɱ�̵ķ�������������漰����������ͳ��ѧ֪ʶ�����������ݶȣ��ֲ����������ʶ
      // ��̬�ָ�������ѡ����̬���طָ��̬��ѧ�ָ��ֵ���ָһ�����ַָ�ģ��
      // ʹ����̬�ָ��������������ھ�������������Ԥ�����Ժ������ʶ��Ĳ���
      // ��һ�������Զ�������Ҫ��̻�����֧�֣����ݽṹҪ�������ͨ���
      test.BuildSegmentation(tex);
      test.RemoveNoise(50);

      // TMorphologySegmentation�ָ���֧��Stream����
      // ���г�����ʾ��ʹ��Stream����TMorphologySegmentation�ָ����еĸ�������
      stream := TMS64.Create;
      test.SaveToStream(stream);
      DisposeObject(test);
      stream.Position := 0;
      test := TMorphologySegmentation.Create;
      test.LoadFromStream(stream);
      DisposeObject(stream);

      // TMorphologySegmentation�ָ����е����ݶ���ָ�룬����ռ�úܴ��ڴ棬�����໥����
      // TMorphologySegmentation�ָ�����������������ĸ�������
      s := TMorphologySegmentation.Create;
      s.Assign(test);
      DisposeObject(test);

      // ��¼һ���״ηָ�����
      first_total := s.count;

      // �����ָ��Ժ������������������ǽ������Ƴ�
      // ��ֵ50��ʾ�ָ���Ƭ�������ܺ��������20��
      // s.RemoveNoise(20);

      SetLength(LastSegBox, s.count);

      DelphiParallelFor(0, s.count - 1, procedure(pass: Integer)
        var
          j, k: Integer;
          sp: TMorphologyPool;
          nm: TMZR;
          geo: T2DPolygonGraph;
          LL: TLinesList;
          L: TLines;
          c: TRColor;
        begin
          sp := s[pass];
          // ���ָ�ͼ�ι�����T2DPolygonGraph��T2DPolygonGraph�ɰ�Χ����κ����ݶ���ι�ͬ���
          geo := sp.BuildConvolutionGeometry(1.0);
          // geo := sp.BuildGeometry(0.0);
          // ���ָ�߽繹���ɶ����Ǳպ���
          LL := sp.BuildLines(1.0);
          LastSegBox[pass] := sp.BoundsRectV2;
          // BuildDatamap�����Ὣ�ָ�����ͶӰ��һ���¹�դ��
          nm := sp.BuildClipDatamap(RColor(0, 0, 0, 0), ZRAlphaColor(pickColor, $7F));

          nm.OpenAgg;
          nm.Agg.LineWidth := 1;
          if geo <> nil then
            begin
              geo.Transform(-sp.Left, -sp.Top);
              // ���任��Ķ���ΰ�������
              if ViewGeometryCheckBox.IsChecked then
                  nm.DrawPolygon(geo, RColorF(1, 1, 1), RColorF(0.8, 1.0, 0.8));
              // ������
              if ViewGeometryCheckBox.IsChecked and EdgeLinesCrossCheckBox.IsChecked then
                  nm.DrawPolygonCross(geo, 5, RColorF(1.0, 0, 0), RColorF(1.0, 0.5, 0.5));
              DisposeObject(geo);
            end;

          for j := 0 to LL.count - 1 do
            begin
              L := LL[j];
              // �任����,ʹ����BuildClipDatamap������ͼ���Ǻ�
              L.Transform(-sp.Left, -sp.Top);
              c := RColor(umlRandomRange($7F, $FF), umlRandomRange($7F, $FF), umlRandomRange($7F, $FF), $FF);
              // �ѷָ�߽�ķǱպ��߻�����
              if ViewEdgeLinesCheckBox.IsChecked then
                  nm.DrawPolygonLine(L, c, False);
              // ������
              if ViewEdgeLinesCheckBox.IsChecked and EdgeLinesCrossCheckBox.IsChecked then
                  nm.DrawCrossF(L, 5, c);
              DisposeObject(L);
            end;
          DisposeObject(LL);
          nm.CloseAgg;

          LockObject(SegImgList);
          SegImgList.Add(nm);
          UnLockObject(SegImgList);
        end);

      DrawPool(segPB).PostScrollText(5,
        Format('�ָ��:��⵽ |s:16,color(1,0,0)|%d|| ������ͼ��(����������Ƭͼ��),��ʵ����Чֻ�� |s:16,color(1,0,0)|%d|| ��ͼ��', [first_total, SegImgList.count]),
        20, DEColor(1, 1, 1));
      DisposeObject(s);
    end);
end;

procedure TMorphologySegmentationMainForm.openButtonClick(Sender: TObject);
var
  i: Integer;
begin
  OpenDialog1.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenDialog1.Execute then
      exit;

  DisposeObject(tex);
  tex := NewZRFromFile(OpenDialog1.FileName);
  SetLength(LastSegBox, 0);
end;

procedure TMorphologySegmentationMainForm.ViewGeometryCheckBoxClick(Sender: TObject);
var
  i: Integer;
begin
  LockObject(SegImgList);
  for i := 0 to SegImgList.count - 1 do
      DisposeObject(SegImgList[i]);
  SegImgList.Clear;
  UnLockObject(SegImgList);

  BuildSeg;
end;

end.
