unit _150_MultiThread_DrawEngine_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib,
  ZR.Geometry2D, ZR.Geometry3D, ZR.Notify,
  ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.MemoryRaster,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TAtom_Texture = TAtomVar<TZR>;

  TRTT_Inst = class
  public
    // 在FMX体系,所有的TBitmap都实用独立的Canvas实例
    // RTT的实现思路是在线程中使用 TBitmap.canvas
    Texture: TAtom_Texture;
    Activted: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Do_Render_Thread();
  end;

  T_150_MultiThread_DrawEngine_Form = class(TForm)
    fpsTimer: TTimer;
    rendererTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure rendererTimerTimer(Sender: TObject);
  private
  public
    RTT_3X3: TBox_Instance_Tool<TRTT_Inst>;
  end;

var
  bk: TZR;
  RTT_Inst_Num: TAtomInteger;
  _150_MultiThread_DrawEngine_Form: T_150_MultiThread_DrawEngine_Form;

implementation

{$R *.fmx}


constructor TRTT_Inst.Create;
begin
  inherited Create;
  Texture := TAtom_Texture.Create(NewZR);
  Activted := True;
  RTT_Inst_Num.UnLock(RTT_Inst_Num.LockP^ + 1);
  TCompute.RunM_NP(Do_Render_Thread);
end;

destructor TRTT_Inst.Destroy;
begin
  DisposeObject(Texture.V);
  DisposeObject(Texture);
  RTT_Inst_Num.UnLock(RTT_Inst_Num.LockP^ - 1);
  inherited Destroy;
end;

procedure TRTT_Inst.Do_Render_Thread;
var
  d: TDrawEngine;
  // 渲染流程用
  b1: Boolean;
  a1: TGeoFloat;
  n: U_String;
begin
  d := TDrawEngine.Create; // 在线程实例必须手动创建TDrawEngine,不可以直接使用DrawPool
  d.ViewOptions := [];

  // 渲染流程用
  b1 := False;
  a1 := 0;

  while Activted do
    begin
      d.Progress();
      d.ZR_.Memory.SetSize(300, 150, RColor(0, 0, 0, 0));
      d.SetSize;

      // 渲染流程
      n := 'hello world' + #13#10 + '|s:8,color(0,1,0),box(1,1,1)|' + d.LastDrawInfo + #13#10 + '|s:14,bk(0.5,0.5,0.5,0.5)|thread:' + umlIntToStr(TCompute.CurrentThread.ThreadID);
      a1 := BounceFloat(a1, 12 * d.LastDeltaTime, -5, 5, b1); // 反弹器
      d.DrawText(n, 18, d.ScreenRectV2, DEColor(1, 1, 1), True, vec2(0.5, 0.5), a1);
      d.Flush;

      // 更新输出光栅
      Texture.Lock;
      Texture.P^.SwapInstance(d.ZR_.Memory);
      Texture.P^.Update;
      Texture.UnLock;
    end;

  DisposeObject(d);
  DelayFreeObj(1, Self);
end;

procedure T_150_MultiThread_DrawEngine_Form.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 32);

  DrawPool(Self).PostScrollText(1, 'RTT是计算机图形学的一种分支技术,主要作用是用于分担主线程的压力.', 16, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;
  DrawPool(Self).PostScrollText(1, 'RTT(渲染到纹理)是一种硬件加速技术,但是在FMX无法使用RTT硬件加速.', 14, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;
  DrawPool(Self).PostScrollText(1, 'd2d,d3d,metal,gles,这些api支持线程RTT,共享句柄就行,而FMX的底层接口只可以支持单线程中的RTT分离,无法线程.', 14, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;
  DrawPool(Self).PostScrollText(1, '|color(1,0.5,0.5)|这里的RTT使用光栅引擎内存自绘,再以光栅用FMX输出,这套体系是软件RTT||,并不是硬件RTT.', 20, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;
  DrawPool(Self).PostScrollText(1, '软RTT体系可以解决轻量绘图任务,适用于在子线程|color(0.5,1,0.5),s:s+5|小图合成+字符渲染||.', 18, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;
  DrawPool(Self).PostScrollText(1, 'RTT流程比较复杂,会涉及许多数据化体系,总体思路就是让渲染流程分支化.', 16, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.8)).Forever := True;

  RTT_3X3 := TBox_Instance_Tool<TRTT_Inst>.Create(3, 3);
  RTT_Inst_Num := TAtomInteger.Create(0);

  for i := 0 to length(RTT_3X3.Buffer) - 1 do
      RTT_3X3.Buffer[i]^.Instance := TRTT_Inst.Create;
end;

procedure T_150_MultiThread_DrawEngine_Form.FormDestroy(Sender: TObject);
var
  x, y: Integer;
begin
  for y := 0 to RTT_3X3.YBox - 1 do
    for x := 0 to RTT_3X3.XBox - 1 do
        RTT_3X3.Matrix[y, x].Instance.Activted := False;
  while RTT_Inst_Num.V > 0 do
      Check_Soft_Thread_Synchronize(100, True);

  DisposeObject(bk);
  DisposeObject(RTT_3X3);
  DisposeObject(RTT_Inst_Num);
end;

procedure T_150_MultiThread_DrawEngine_Form.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
  Hide;
end;

procedure T_150_MultiThread_DrawEngine_Form.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
  i: Integer;
  rtt: TRTT_Inst;
begin
  Canvas.Font.Family := 'Consolas';
  Canvas.Font.Style := [TFontStyle.fsBold];
  d := TDrawEngineInterface_FMX.DrawEngine_Interface.SetSurfaceAndGetDrawPool(Canvas, Sender);
  d.ViewOptions := [voFPS, voEdge];
  d.DrawTile(bk);
  RTT_3X3.Resize(d.width, d.height);

  for i := 0 to length(RTT_3X3.Buffer) - 1 do
    begin
      rtt := RTT_3X3.Buffer[i]^.Instance;
      rtt.Texture.Lock;
      if rtt.Texture.P^ <> nil then
          d.DrawPicture(rtt.Texture.P^, rtt.Texture.P^.BoundsRectV20, RTT_3X3.Buffer[i]^.box, 1.0);
    end;
  for i := 0 to length(RTT_3X3.Buffer) - 1 do
      d.DrawBox(RTT_3X3.Buffer[i]^.box, DEColor(1, 0, 0, 0.5), 1);

  d.Flush;

  for i := 0 to length(RTT_3X3.Buffer) - 1 do
      RTT_3X3.Buffer[i]^.Instance.Texture.UnLock;
end;

procedure T_150_MultiThread_DrawEngine_Form.fpsTimerTimer(Sender: TObject);
begin
  DrawPool.Progress;
  Check_Soft_Thread_Synchronize;
end;

procedure T_150_MultiThread_DrawEngine_Form.rendererTimerTimer(Sender: TObject);
begin
  Invalidate;
end;

end.
