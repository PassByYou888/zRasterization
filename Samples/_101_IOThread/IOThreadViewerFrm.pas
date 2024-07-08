unit IOThreadViewerFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Status,
  ZR.IOThread,
  ZR.Geometry2D, ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TIOThreadViewerForm = class(TForm)
    Timer1: TTimer;
    pb: TPaintBox;
    IOThreadButton: TButton;
    ThreadPoolButton: TButton;
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure ThreadPoolButtonClick(Sender: TObject);
    procedure IOThreadButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TState = record
    done: Boolean;
    busy: Boolean;
    picked: Boolean;
  end;

  PState = ^TState;

  TStateArry = array of TState;

var
  IOThreadViewerForm: TIOThreadViewerForm;
  StateArry: TStateArry;

implementation

{$R *.fmx}


procedure TIOThreadViewerForm.pbPaint(Sender: TObject; Canvas: TCanvas);
const
  c_Metric = 20; // 呈现器度量单位
  c_Edge = 1;    // 呈现器边缘尺度
var
  d: TDrawEngine;
  f, i, j, num: Integer;
  x, y: TGeoFloat;
  box, r: TRectV2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  d.FillBox;

  // 将并行处理数据画出来
  f := round(sqrt(length(StateArry))); // 以平方根方式切割预览数据
  num := 0;
  x := 0;
  y := 0;
  box := RectV2(x, y, x, y); // 预置包围盒
  for j := 0 to f do
    begin
      for i := 0 to f do
        begin
          r := RectV2(x, y, x + c_Metric, y + c_Metric);
          if num < length(StateArry) then
            with StateArry[num] do
              begin
                if picked then
                    d.FillBoxInScene(r, DEColor(1, 1, 1, 1))
                else if busy then
                    d.FillBoxInScene(r, DEColor(1, 0.5, 0.5, 1))
                else if done then
                    d.FillBoxInScene(r, DEColor(0.5, 1, 0.5, 1))
                else
                    d.FillBoxInScene(r, DEColor(0, 1, 0, 0.5));
              end;

          x := x + c_Metric + c_Edge;
          inc(num);
          box := BoundRect(box, r);
        end;
      y := y + c_Metric + c_Edge;
      x := 0;
    end;

  d.CameraR := RectEdge(box, 200);

  d.DrawText(TCompute.State, 16, d.ScreenRect, DEColor(0, 1, 0, 1), False);
  d.Flush;
end;

procedure TIOThreadViewerForm.ThreadPoolButtonClick(Sender: TObject);
begin
  pb.Enabled := False;
  DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
    begin
      with StateArry[pass] do
        begin
          done := False;
          busy := False;
          picked := False;
        end;
    end);
  TCompute.RunP_NP(procedure
    var
      PostPool: TThread_Pool;
      InputDone: TAtomBool;
    begin
      // 在pool创建10个执行线程
      PostPool := TThread_Pool.Create(10);

      // 构建一个子线程来输入
      InputDone := TAtomBool.Create(False);
      TCompute.RunP_NP(procedure
        var
          i: Integer;
        begin
          for i := 0 to length(StateArry) - 1 do
            begin
              while PostPool.MinLoad_Thread.Post.Count > 10 do
                  TCompute.Sleep(1);
              PostPool.MinLoad_Thread.PostP2(@StateArry[i], procedure(Data1: Pointer)
                var
                  p: PState;
                begin
                  MT19937Randomize();
                  p := Data1;
                  p^.busy := True;
                  // 模拟计算延迟
                  TCompute.Sleep(umlRandomRange(10, 100));
                  p^.done := True;
                  p^.busy := False;
                end);
            end;
          InputDone.v := True;
        end);

      // 等输入线程结束
      while not InputDone.v do
          TCompute.Sleep(1);
      InputDone.Free;

      // 等post到pool的线程全部结束
      PostPool.Wait();

      // 释放IO线程
      PostPool.Free;

      TCompute.Sync(procedure
        begin
          pb.Enabled := True;
        end);
    end);
end;

procedure TIOThreadViewerForm.IOThreadButtonClick(Sender: TObject);
begin
  pb.Enabled := False;
  DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
    begin
      with StateArry[pass] do
        begin
          done := False;
          busy := False;
          picked := False;
        end;
    end);
  TCompute.RunP_NP(procedure
    var
      IOThread: TIO_Thread;
      InputDone: Boolean;
      ioData_: TIO_Thread_Data;
    begin
      // IOThread构建:启动50条IO线程,这些线程在启动以后会处于Sleep状态,不会消耗cpu
      IOThread := TIO_Thread.Create(50);

      // 构建一个子线程来输入
      InputDone := False;
      TCompute.RunP_NP(procedure
        var
          i: Integer;
        begin
          for i := 0 to length(StateArry) - 1 do
            begin
              // 将数据编入IO线程的处理队列
              // IOThread编队机制是多线程安全的
              IOThread.Enqueue_P(TIO_Thread_Data.Create, @StateArry[i],
                procedure(thSender: TIO_Thread_Data)
                var
                  p: PState;
                begin
                  MT19937Randomize();
                  // 执行IO子线程
                  p := thSender.Data;
                  p^.busy := True;
                  // 模拟计算延迟
                  TCompute.Sleep(umlRandomRange(10, 100));
                  p^.done := True;
                  p^.busy := False;
                end);
            end;
          InputDone := True;
        end);

      // 等输入线程结束
      while not InputDone do
          TCompute.Sleep(1);

      // 现在，按照严格顺序提取IO队列
      // IOThread拾取队列机制是多线程安全的
      while IOThread.Count > 0 do
        begin
          ioData_ := IOThread.Dequeue();
          if ioData_ <> nil then
            begin
              PState(ioData_.Data)^.picked := True;
              ioData_.Free;
            end;
        end;

      // 释放IO线程
      IOThread.Free;

      TCompute.Sync(procedure
        begin
          pb.Enabled := True;
        end);
    end);
end;

procedure TIOThreadViewerForm.Timer1Timer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThreadSynchronize;
  Invalidate;
end;

constructor TIOThreadViewerForm.Create(AOwner: TComponent);
var
  i: Integer;
begin
  inherited Create(AOwner);
  dIntf := TDrawEngineInterface_FMX.Create;

  // 预处理呈现器数据
  SetLength(StateArry, 50 * 50);
  for i := 0 to length(StateArry) - 1 do
    with StateArry[i] do
      begin
        done := False;
        busy := False;
      end;

  WorkInParallelCore.v := True;

  DrawPool(pb).PostScrollText(60 * 60 * 1000, '输入输出线程面向未知序列的流水线工作，并行程序则是面向已知序列工作', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '简单来说，输入输出线程不需要序列数据也可以多线程工作，而并行程序必须有完整序列，也就是标注好的循环长度', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '例如：输入3个数据分别123，输出的数据队列也会是123，而处理队列则是多线程无序化分别处理3个输入数据123', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '输入输出线程叫IOThread,程序库:Z.IOThread.pas', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '演示程序读起来或许比较复杂，以最简单的方式理解IOThread：', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'EnQueue：编入队列，数据会自动化进入多线程处理', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'DeQueue：取出队列，数据会按EnQueue顺序依次取出，如果后台线程还在计算中，DeQueue则会等待', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'IOThread是多线程安全的,本身它就是设计给线程使用,在HPC服务器,它将发挥非常重要作用', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'IOThread核心设计思路取材于STL的线程支持容器', 18, DEColor(1, 1, 1, 1));
end;

destructor TIOThreadViewerForm.Destroy;
begin
  inherited Destroy;
end;

end.
