unit ParallelGranularityRenderingFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Status,
  ZR.Geometry2D, ZR.DrawEngine, ZR.DrawEngine.SlowFMX;

type
  TParallelGranularityRenderingForm = class(TForm)
    Timer1: TTimer;
    pb: TPaintBox;
    FoldButton: TButton;
    BlockButton: TButton;
    AntButton: TButton;
    procedure AntButtonClick(Sender: TObject);
    procedure BlockButtonClick(Sender: TObject);
    procedure FoldButtonClick(Sender: TObject);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
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
  end;

  TStateArry = array of TState;

var
  ParallelGranularityRenderingForm: TParallelGranularityRenderingForm;
  StateArry: TStateArry;

implementation

{$R *.fmx}


procedure TParallelGranularityRenderingForm.AntButtonClick(Sender: TObject);
begin
  pb.Enabled := False;
  DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
    begin
      with StateArry[pass] do
        begin
          done := False;
          busy := False;
        end;
    end);
  TCompute.RunP_NP(procedure
    begin
      DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
        begin
          SetMT19937Seed(pass);
          with StateArry[pass] do
            begin
              busy := True;
              if umlRandomRange(0, 100) mod 10 = 0 then
                  TCompute.Sleep(1);
              done := True;
              busy := False;
            end;
        end);
      TCompute.Sync(procedure
        begin
          pb.Enabled := True;
        end);
    end);
end;

procedure TParallelGranularityRenderingForm.BlockButtonClick(Sender: TObject);
begin
  pb.Enabled := False;
  DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
    begin
      with StateArry[pass] do
        begin
          done := False;
          busy := False;
        end;
    end);
  TCompute.RunP_NP(procedure
    begin
      DelphiParallelFor_Block(True, 0, length(StateArry) - 1, procedure(pass: Integer)
        begin
          SetMT19937Seed(pass);
          with StateArry[pass] do
            begin
              busy := True;
              TCompute.Sleep(umlRandomRange(10, 50));
              done := True;
              busy := False;
            end;
        end);
      TCompute.Sync(procedure
        begin
          pb.Enabled := True;
        end);
    end);
end;

procedure TParallelGranularityRenderingForm.FoldButtonClick(Sender: TObject);
begin
  pb.Enabled := False;
  DelphiParallelFor(False, 0, length(StateArry) - 1, procedure(pass: Integer)
    begin
      with StateArry[pass] do
        begin
          done := False;
          busy := False;
        end;
    end);
  TCompute.RunP_NP(procedure
    begin
      DelphiParallelFor_Fold(True, 0, length(StateArry) - 1, procedure(pass: Integer)
        begin
          SetMT19937Seed(pass);
          with StateArry[pass] do
            begin
              busy := True;
              TCompute.Sleep(umlRandomRange(10, 100));
              done := True;
              busy := False;
            end;
        end);
      TCompute.Sync(procedure
        begin
          pb.Enabled := True;
        end);
    end);
end;

procedure TParallelGranularityRenderingForm.pbPaint(Sender: TObject; Canvas: TCanvas);
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
  d.ViewOptions := [voFPS];
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
                if busy then
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

  d.FPS_Addional_Info := TCompute.State;
  d.Flush;
end;

procedure TParallelGranularityRenderingForm.Timer1Timer(Sender: TObject);
begin
  DrawPool.Progress;
  CheckThreadSynchronize;
  Invalidate;
end;

constructor TParallelGranularityRenderingForm.Create(AOwner: TComponent);
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

  WorkInParallelCore.V := True;

  DrawPool(pb).PostScrollText(60 * 60 * 1000, '本Demo以呈现方式演示了并行程序不同的工作模式', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'cpu的核心越多,并行任务的|color(1,0,0)|红点||就会越多', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '均匀并行模式也是块模式,它会将任务均匀分配给并行线程,在对付恒定时间的计算时,可以使用它.|color(1,0,0)|否则,它效率很低.||', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '折叠模式也是gpu线程主要采用的并行模式,在对付不确定的计算时间中,它可以最大化发挥硬件潜力', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '|color(1,0.5,0.5)|zAI默认的并行任务都是|||color(1,0,0),s:20|折叠模式||', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '蚂蚁呈现也是我们常用for语句,它以线性步进.', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '|color(0,1,0)|by.qq600585||', 16, DEColor(1, 1, 1, 1));
end;

destructor TParallelGranularityRenderingForm.Destroy;
begin
  inherited Destroy;
end;

end.
