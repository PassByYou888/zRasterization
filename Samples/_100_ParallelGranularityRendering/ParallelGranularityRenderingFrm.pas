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
  d.ViewOptions := [voFPS];
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

  // Ԥ�������������
  SetLength(StateArry, 50 * 50);
  for i := 0 to length(StateArry) - 1 do
    with StateArry[i] do
      begin
        done := False;
        busy := False;
      end;

  WorkInParallelCore.V := True;

  DrawPool(pb).PostScrollText(60 * 60 * 1000, '��Demo�Գ��ַ�ʽ��ʾ�˲��г���ͬ�Ĺ���ģʽ', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, 'cpu�ĺ���Խ��,���������|color(1,0,0)|���||�ͻ�Խ��', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '���Ȳ���ģʽҲ�ǿ�ģʽ,���Ὣ������ȷ���������߳�,�ڶԸ��㶨ʱ��ļ���ʱ,����ʹ����.|color(1,0,0)|����,��Ч�ʺܵ�.||', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '�۵�ģʽҲ��gpu�߳���Ҫ���õĲ���ģʽ,�ڶԸ���ȷ���ļ���ʱ����,��������󻯷���Ӳ��Ǳ��', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '|color(1,0.5,0.5)|zAIĬ�ϵĲ���������|||color(1,0,0),s:20|�۵�ģʽ||', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '���ϳ���Ҳ�����ǳ���for���,�������Բ���.', 16, DEColor(1, 1, 1, 1));
  DrawPool(pb).PostScrollText(60 * 60 * 1000, '|color(0,1,0)|by.qq600585||', 16, DEColor(1, 1, 1, 1));
end;

destructor TParallelGranularityRenderingForm.Destroy;
begin
  inherited Destroy;
end;

end.
