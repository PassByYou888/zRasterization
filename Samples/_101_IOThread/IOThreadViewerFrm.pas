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
  c_Metric = 20; // ������������λ
  c_Edge = 1;    // ��������Ե�߶�
var
  d: TDrawEngine;
  f, i, j, num: Integer;
  x, y: TGeoFloat;
  box, r: TRectV2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  d.FillBox;

  // �����д������ݻ�����
  f := round(sqrt(length(StateArry))); // ��ƽ������ʽ�и�Ԥ������
  num := 0;
  x := 0;
  y := 0;
  box := RectV2(x, y, x, y); // Ԥ�ð�Χ��
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
      // ��pool����10��ִ���߳�
      PostPool := TThread_Pool.Create(10);

      // ����һ�����߳�������
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
                  // ģ������ӳ�
                  TCompute.Sleep(umlRandomRange(10, 100));
                  p^.done := True;
                  p^.busy := False;
                end);
            end;
          InputDone.v := True;
        end);

      // �������߳̽���
      while not InputDone.v do
          TCompute.Sleep(1);
      InputDone.Free;

      // ��post��pool���߳�ȫ������
      PostPool.Wait();

      // �ͷ�IO�߳�
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
      // IOThread����:����50��IO�߳�,��Щ�߳��������Ժ�ᴦ��Sleep״̬,��������cpu
      IOThread := TIO_Thread.Create(50);

      // ����һ�����߳�������
      InputDone := False;
      TCompute.RunP_NP(procedure
        var
          i: Integer;
        begin
          for i := 0 to length(StateArry) - 1 do
            begin
              // �����ݱ���IO�̵߳Ĵ������
              // IOThread��ӻ����Ƕ��̰߳�ȫ��
              IOThread.Enqueue_P(TIO_Thread_Data.Create, @StateArry[i],
                procedure(thSender: TIO_Thread_Data)
                var
                  p: PState;
                begin
                  MT19937Randomize();
                  // ִ��IO���߳�
                  p := thSender.Data;
                  p^.busy := True;
                  // ģ������ӳ�
                  TCompute.Sleep(umlRandomRange(10, 100));
                  p^.done := True;
                  p^.busy := False;
                end);
            end;
          InputDone := True;
        end);

      // �������߳̽���
      while not InputDone do
          TCompute.Sleep(1);

      // ���ڣ������ϸ�˳����ȡIO����
      // IOThreadʰȡ���л����Ƕ��̰߳�ȫ��
      while IOThread.Count > 0 do
        begin
          ioData_ := IOThread.Dequeue();
          if ioData_ <> nil then
            begin
              PState(ioData_.Data)^.picked := True;
              ioData_.Free;
            end;
        end;

      // �ͷ�IO�߳�
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

  // Ԥ�������������
  SetLength(StateArry, 50 * 50);
  for i := 0 to length(StateArry) - 1 do
    with StateArry[i] do
      begin
        done := False;
        busy := False;
      end;

  WorkInParallelCore.v := True;

  DrawPool(pb).PostScrollText(60 * 60 * 1000, '��������߳�����δ֪���е���ˮ�߹��������г�������������֪���й���', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '����˵����������̲߳���Ҫ��������Ҳ���Զ��̹߳����������г���������������У�Ҳ���Ǳ�ע�õ�ѭ������', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '���磺����3�����ݷֱ�123����������ݶ���Ҳ����123��������������Ƕ��߳����򻯷ֱ���3����������123', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '��������߳̽�IOThread,�����:Z.IOThread.pas', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '��ʾ�������������Ƚϸ��ӣ�����򵥵ķ�ʽ���IOThread��', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'EnQueue��������У����ݻ��Զ���������̴߳���', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'DeQueue��ȡ�����У����ݻᰴEnQueue˳������ȡ���������̨�̻߳��ڼ����У�DeQueue���ȴ�', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'IOThread�Ƕ��̰߳�ȫ��,������������Ƹ��߳�ʹ��,��HPC������,�������ӷǳ���Ҫ����', 18, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'IOThread�������˼·ȡ����STL���߳�֧������', 18, DEColor(1, 1, 1, 1));
end;

destructor TIOThreadViewerForm.Destroy;
begin
  inherited Destroy;
end;

end.
