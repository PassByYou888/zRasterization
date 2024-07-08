program _73_DrawEngine4FMXBitmap;

{$APPTYPE CONSOLE}


uses
  System.StartUpCopy,
  System.IOUtils,
  FMX.Graphics,
  ZR.Core,
  ZR.PascalStrings,
  ZR.UnicodeMixedLib,
  ZR.Status,
  ZR.Geometry2D,
  ZR.MemoryRaster,
  ZR.DrawEngine,
  ZR.DrawEngine.SlowFMX;

{$R *.res}


// dorender��softRenderer demo�еķ���������ֱ�ӽ���ճ������ʹ��
procedure DoRender(Draw: TDrawEngine);
begin
  if not Draw.ReadyOK then
      Exit;
  Draw.ViewOptions := [voEdge];
  Draw.SetSize;
  Draw.FillBox(Draw.ScreenRect, DEColor(0.5, 0.5, 0.5, 1));

  Draw.FillBox(RectV2(100, 100, 250, 250), -180, DEColor(1, 1, 1, 0.2));
  Draw.DrawBox(RectV2(49, 100, 151, 151), -15, DEColor(1, 0.5, 0.5, 0.9), 2);
  Draw.FillEllipse(DERect(50, 100, 300, 250), DEColor(1, 1, 1, 0.5));

  Draw.BeginCaptureShadow(Vec2(4, 4), 0.9);
  Draw.DrawText('|s:10,color(1,1,1,1)|Hello|color(1,1,1,1)| world' + #13#10 +
    '||' + #13#10 + 'default text |s:22,color(0,1,0,1)| big green' + #13#10 + 'big green line 2' + #13#10 + 'big green line 3',
    18, Draw.ScreenRect, DEColor(1, 0, 0, 0.8), True, DEVec(0.5, 0.5), -22);
  Draw.EndCaptureShadow;

  Draw.Flush;
end;

procedure RenderToFMXBitmap;
var
  bmp: FMX.Graphics.TBitmap;
  dIntf: TDrawEngineInterface_FMX;
  d: TDrawEngine;
begin
  bmp := FMX.Graphics.TBitmap.Create;
  bmp.SetSize(512, 512);

  // TDrawEngineInterface_FMX��DrawEngine��ͼ�м�㣬���ǽ��������ָ��Ϊһ��fmx���õ�bmpλͼ
  dIntf := TDrawEngineInterface_FMX.Create;
  dIntf.SetSurface(bmp.Canvas, bmp);

  // drawEngine��ʼ��
  d := TDrawEngine.Create;
  d.DrawInterface := dIntf;
  d.SetSize;

  // ��ͼ
  // FMX��windowsƽ̨��Bitmap��Ĭ��ʹ��d2d��ͼapi������֧�ַ���ݣ����Ҿ߱�Ӳ�����ٹ���
  // bmp��Ӳ��������ָ��ͼ���̼��٣�����ͼ��ɣ�ϵͳ�Ὣgpu�Դ��е���������copy��bmp�Ĺ�դ�У�copy��һ�����Ǻ�����
  DoRender(d);

  // �ͷŽӿ�
  disposeObject(dIntf);
  disposeObject(d);

  // ��bmp���������������ǹۿ�
  bmp.SaveToFile(umlCombineFileName(TPath.GetLibraryPath, 'fmx_bitmap_demo_output.bmp'));
  DoStatus('FMX bitmap file ' + umlCombineFileName(TPath.GetLibraryPath, 'fmx_bitmap_demo_output.bmp'));
  disposeObject(bmp);
end;

begin
  RenderToFMXBitmap;
  DoStatus('press any key to exit.');
  readln;

end.
