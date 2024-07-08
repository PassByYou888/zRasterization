unit DrawEngineFontEdgeMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.Layouts, FMX.ExtCtrls,

  System.IOUtils,

  ZR.Core, ZR.UnicodeMixedLib, ZR.PascalStrings, ZR.Geometry2D, ZR.Geometry3D,
  ZR.MemoryRaster, ZR.ListEngine, ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TDrawEngineFontEdgeMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    dIntf: TDrawEngineInterface_FMX;
    bk: TMZR;
    ang: TGeoFloat;
  end;

var
  DrawEngineFontEdgeMainForm: TDrawEngineFontEdgeMainForm;
  TextRasterCache: THashObjectList;

function GetTextFont(text: string; siz: TGeoFloat; Color, EdgeColor: TDEColor; borderSiz: Integer): TMZR;

implementation

{$R *.fmx}


function GetTextFont(text: string; siz: TGeoFloat; Color, EdgeColor: TDEColor; borderSiz: Integer): TMZR;
var
  cacheToken: U_String;
  tmpDrawEng: TDrawEngine;
  text_siz: TVec2;
  tmpRaster: TMZR;
begin
  cacheToken := PFormat('%g:%s:%s:%d:%s', [siz, VecToStr(Color), VecToStr(EdgeColor), borderSiz, text]);
  Result := TMZR(TextRasterCache[cacheToken]);
  if Result = nil then
    begin
      Result := NewZR();
      tmpDrawEng := TDrawEngine.Create;
      tmpDrawEng.ViewOptions := [];
      // �߼�ͼ�μ����������Ƚ�ͼ��Ŵ�2������һ�θ�˹ƽ����Ȼ��������ȥ���ﵽ�����Ч��
      text_siz := tmpDrawEng.GetTextSize(text, siz * 2);
      // �����������ݳ�ʼ����դ�ĳߴ��Ĭ�ϱ���Ϊ0,0,0,$FF
      Result.SetSizeF(text_siz[0] + borderSiz + 50, text_siz[1] + borderSiz + 50, RColor(0, 0, 0));
      tmpDrawEng.ZR_.SetWorkMemory(Result);
      tmpDrawEng.SetSize;
      tmpDrawEng.DrawText(text, siz * 2, tmpDrawEng.ScreenRect, Color, True);
      tmpDrawEng.Flush;
      disposeObject(tmpDrawEng);

      // ����Ե���أ�������ɫΪ0,0,0,$FF������ɫ��������Ե
      tmpRaster := TMZR.Create;
      tmpRaster.SetSize(Result.Width, Result.Height, 0);
      Result.FillNoneBGColorAlphaBorder(True, RColor(0, 0, 0), RColor(EdgeColor), borderSiz, tmpRaster);
      tmpRaster.DrawTo(Result);
      disposeObject(tmpRaster);

      // �����ع������Ĺ�դ��RGBͼ��������Ҫһ��Alphaͨ�������ܹ�͸��
      GrayscaleToAlpha(Result);

      // ����ȥ�ﵽ�����Ч��
      Result.SigmaGaussian(False, 1.5, 3);
      Result.Scale(0.5);

      // �����ǹ����õĹ�դ����д�뵽������
      TextRasterCache.FastAdd(cacheToken, Result);
    end;
end;

procedure TDrawEngineFontEdgeMainForm.FormCreate(Sender: TObject);
begin
  dIntf := TDrawEngineInterface_FMX.Create;
  bk := NewZR();
  bk.SetSize(512, 512);
  FillBlackGrayBackgroundTexture(bk, 64, RColor(0, 0, 0), RColorF(0.5, 0.5, 0.5), RColorF(0.3, 0.3, 0.3));
  ang := 0;
end;

procedure TDrawEngineFontEdgeMainForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  dstR: TRectV2;
  textRaster: TMZR;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  d.ViewOptions := [voEdge, voFPS];

  // ��tile��ʽ��ͼƬ
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);

  // ʹ�û��湹���ı�����
  textRaster := GetTextFont('����|color(0,1,0)|��ɫ||����' + #13#10 + 'hello |color(0,1,0)|green|| world', 24, DEColor(1, 1, 1, 1), DEColor(0.5, 0.5, 1.0, 0.9), 5);
  // ������Ļ��������
  dstR[0] := Vec2Mul(Vec2Sub(d.SizeVec, textRaster.Size2D), 0.5);
  dstR[1] := Vec2Add(dstR[0], textRaster.Size2D);

  // �°汾�� BeginCaptureShadow ���Բ����˹Ӱ�ӣ�����Ӱ����ģ��Ч����ֻ������������
  d.BeginCaptureShadow(vec2(20, 20), 1.0, 20, 5);
  // ���Ǳ�Ӱ�ӣ�TV2Rect4����һ��ͨ���ڼ���ϵͳ�����꣬��4�����㹹��
  d.DrawCorner(TV2Rect4.Init(dstR, ang).Transform(20, 20), DEColor(0, 0, 0, 0.8), 20, 2);
  // ���Ǳ꣬TV2Rect4����һ��ͨ���ڼ���ϵͳ�����꣬��4�����㹹��
  d.DrawCorner(TV2Rect4.Init(dstR, ang), DEColor(1, 0.5, 0.5, 1.0), 20, 2);
  // TDE4V��DrawEngine���ڱ�ʾͨ��ƽ̨���������ϵ����left,right,top,bottom,angle��5��Ҫ�ع���
  d.DrawPicture(textRaster, TDE4V.Init(textRaster.BoundsRectV2, 0), TDE4V.Init(dstR, ang), 1.0);
  d.EndCaptureShadow;

  d.Flush;

  // ��һ���Ƕ�-180..180֮��
  ang := NormalizeDegAngle(ang + d.LastDeltaTime * 40);
end;

procedure TDrawEngineFontEdgeMainForm.Timer1Timer(Sender: TObject);
begin
  CheckThread;
  EnginePool.Progress;
  Invalidate;
end;

initialization

TextRasterCache := THashObjectList.CustomCreate(True, 1024);

finalization

disposeObject(TextRasterCache);

end.
