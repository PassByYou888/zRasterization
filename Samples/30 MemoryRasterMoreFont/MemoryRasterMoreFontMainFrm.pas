unit MemoryRasterMoreFontMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, System.IOUtils,

  ZR.Core, ZR.UnicodeMixedLib, ZR.PascalStrings, ZR.Geometry2D, ZR.MemoryRaster,
  ZR.DrawEngine, ZR.DrawEngine.SlowFMX, FMX.Layouts, FMX.ExtCtrls;

type
  TMemoryRasterMoreFontMainForm = class(TForm)
    ImageViewer1: TImageViewer;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MemoryRasterMoreFontMainForm: TMemoryRasterMoreFontMainForm;

implementation

{$R *.fmx}


procedure TMemoryRasterMoreFontMainForm.FormCreate(Sender: TObject);

  procedure d(raster: TMZR; f: TFontZR; var y: Integer);
  var
    siz: TVec2;
    n: string;
  begin
    raster.Font := f;
    n := 'ABC abc 123 (456+xyz) !@#$%^&*()-=';
    siz := raster.TextSize(n, f.FontSize);
    raster.DrawText(n, 10, y, Vec2(0.5, 0.5), 5, 1.0, f.FontSize, RColorF(1, 1, 1));
    inc(y, round(siz[1]) + 10);
  end;

var
  rfont1, rfont2, rfont3, rfont4, rfont5, rfont6: TFontZR;
  raster: TMZR;
  y, h: Integer;
  f: TFontZR;
begin
  rfont1 := TFontZR.Create;
  rfont2 := TFontZR.Create;
  rfont3 := TFontZR.Create;
  rfont4 := TFontZR.Create;
  rfont5 := TFontZR.Create;
  rfont6 := TFontZR.Create;

  // zFont�ļ�ʹ��FontBuild���ߴ���
  // zFont��ŵ��������դ���ݣ�����ǿ���ͨ���ԣ����κ�ƽ̨ͨ��
  // demoʹ�õ�zfont���������Ĺ�դ��ֻ������0-255�ַ�
  rfont1.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_1.zfont'));
  rfont2.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_2.zfont'));
  rfont3.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_3.zfont'));
  rfont4.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_4.zfont'));
  rfont5.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_5.zfont'));
  rfont6.LoadFromFile(umlCombineFileName(TPath.GetLibraryPath, 'font_demo_6.zfont'));

  raster := NewZR;

  // ��ʼ����դ�ߴ�ͱ���
  raster.SetSize(1024, 512, RColor(0, 0, 0));

  // ��y����10��ʼ��
  y := 50;

  // �Ѳ�ͬfont������դȥ
  // �������ʹ�դ����windows���������Բ��ƽ��
  d(raster, rfont1, y);
  d(raster, rfont2, y);
  d(raster, rfont3, y);
  d(raster, rfont4, y);
  d(raster, rfont5, y);
  d(raster, rfont6, y);

  // ��MemoryRaster��դת����FMX��դ
  MemoryBitmapToBitmap(raster, ImageViewer1.Bitmap);

  // �ͷ�
  disposeObject(raster);
  disposeObject([rfont1, rfont2, rfont3, rfont4, rfont5, rfont6]);
end;

end.
