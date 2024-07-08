unit ZDBPerfTestFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,

  System.IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.Status, ZR.UnicodeMixedLib, ZR.MemoryStream, ZR.Cipher,
  ZR.Expression, ZR.ZDB2, ZR.ZDB2.Thread.Queue, ZR.IOThread, Vcl.Mask;

type
  TZDBPerfTestForm = class(TForm)
    FileEdit: TLabeledEdit;
    PhySpaceEdit: TLabeledEdit;
    BlockSizeEdit: TLabeledEdit;
    NewFileButton: TButton;
    Memo: TMemo;
    checkTimer: TTimer;
    CloseDBButton: TButton;
    ProgressBar: TProgressBar;
    FillDBButton: TButton;
    StateLabel: TLabel;
    stateTimer: TTimer;
    AppendSpaceButton: TButton;
    TraversalButton: TButton;
    procedure AppendSpaceButtonClick(Sender: TObject);
    procedure CloseDBButtonClick(Sender: TObject);
    procedure NewFileButtonClick(Sender: TObject);
    procedure checkTimerTimer(Sender: TObject);
    procedure FillDBButtonClick(Sender: TObject);
    procedure TraversalButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure stateTimerTimer(Sender: TObject);
  private
    procedure DoStatus_Bcakcall(Text_: SystemString; const ID: Integer);
    procedure ZDBCoreProgress(Total_, current_: Integer);
  public
    ZDB: TZDB2_Th_Queue;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ZDBPerfTestForm: TZDBPerfTestForm;

implementation

{$R *.dfm}


procedure TZDBPerfTestForm.AppendSpaceButtonClick(Sender: TObject);
begin
  if ZDB = nil then
      exit;

  TCompute.RunP_NP(procedure
    begin
      ZDB.Sync_Append_Custom_Space(
        EStrToInt64(PhySpaceEdit.Text, 1024 * 1024 * 512),
        EStrToInt64(BlockSizeEdit.Text, $FFFF),
        ZDBCoreProgress
        );
    end);
end;

procedure TZDBPerfTestForm.CloseDBButtonClick(Sender: TObject);
begin
  DisposeObjectAndNIl(ZDB);
end;

procedure TZDBPerfTestForm.NewFileButtonClick(Sender: TObject);
begin
  DisposeObjectAndNIl(ZDB);
  Enabled := false;
  TCompute.RunP_NP(procedure
    begin
      ZDB := TZDB2_Th_Queue.Create(
        TZDB2_SpaceMode.smBigData, // ʹ��no cache��дģʽ
        64 * 1024 * 1024, // cache
        TFileStream.Create(FileEdit.Text, fmCreate), // ���ݿ��ļ���
        True, // �Զ��ͷ�stream
        false, // ֻ��
        EStrToInt64(PhySpaceEdit.Text, 1024 * 1024 * 512), // �Զ����ݲ����ߴ�
        EStrToInt64(BlockSizeEdit.Text, $FFFF), // ���ݿ�ߴ磬���ܳ���$FFFF
        nil // ���ݱ��������������
        );
      ZDB.Sync_Format_Custom_Space(
        EStrToInt64(PhySpaceEdit.Text, 1024 * 1024 * 512),
        EStrToInt64(BlockSizeEdit.Text, $FFFF),
        ZDBCoreProgress
        );
      TCompute.Sync(procedure
        begin
          Enabled := True;
        end);
      DoStatus('�������ݿ����: �ļ�Ĭ��IO������0���');
      DoStatus('��Ԫ����:%d', [ZDB.CoreSpace_BlockCount]);
    end);
end;

procedure TZDBPerfTestForm.checkTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

procedure TZDBPerfTestForm.FillDBButtonClick(Sender: TObject);
begin
  if ZDB = nil then
      exit;

  TCompute.RunP_NP(procedure
    var
      siz: Word;
      mem: TZDB2_Mem;
      i: Integer;
    begin
      siz := EStrToInt64(BlockSizeEdit.Text, $FFFF);
      for i := 0 to ZDB.CoreSpace_Free_Space_Size div siz - 2 do
        begin
          mem := TZDB2_Mem.Create;
          mem.Size := siz;
          TMT19937.Rand32(MaxInt, mem.Memory, siz div 4);
          if i mod 1000 = 0 then
            begin
              ZDB.Async_Append_P(mem, True, procedure(var Sender: TZDB2_Th_CMD_ID_And_State)
                begin
                  TCompute.Sync(procedure
                    begin
                      ProgressBar.Max := 100;
                      ProgressBar.Position := umlPercentageToInt64(ZDB.CoreSpace_Physics_Size, ZDB.CoreSpace_Size);
                    end);
                end);
            end
          else
              ZDB.Async_Append(mem, True);

          while ZDB.QueueNum > 1000 do
              TCompute.Sleep(1);
        end;
      ZDB.Async_Flush;
      ZDB.Wait_Queue;
      TCompute.Sync(procedure
        begin
          ProgressBar.Max := 100;
          ProgressBar.Position := umlPercentageToInt64(ZDB.CoreSpace_Physics_Size, ZDB.CoreSpace_Size);
        end);
    end);
end;

procedure TZDBPerfTestForm.TraversalButtonClick(Sender: TObject);
begin
  if ZDB = nil then
      exit;

  TCompute.RunP_NP(procedure
    var
      hnd: TZDB2_BlockHandle;
      i: Integer;
      phy, siz: Int64;
    begin
      siz := 0;
      phy := ZDB.CoreSpace_Physics_Size;
      TCompute.Sync(procedure
        begin
          ProgressBar.Max := 100;
        end);

      ZDB.Sync_Rebuild_And_Get_Sequence_Table(hnd);
      for i in hnd do
          ZDB.Async_GetData_AsMem64_P(i, TMem64.Create, procedure(var Sender_: TZDB2_Th_CMD_Mem64_And_State)
          begin
            AtomInc(siz, Sender_.Mem64.Size);
            Sender_.Mem64.Free;
            TCompute.Sync(procedure
              begin
                ProgressBar.Position := umlPercentageToInt64(phy, siz);
              end);
          end);
    end);
end;

procedure TZDBPerfTestForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  DisposeObjectAndNIl(ZDB);
end;

procedure TZDBPerfTestForm.stateTimerTimer(Sender: TObject);
begin
  if not Enabled then
      exit;
  if ZDB <> nil then
    begin
      with ZDB do
          StateLabel.Caption := Format('����ռ�:%s ���ɿռ�:%s ������Ŀ:%d',
          [umlSizeToStr(CoreSpace_Physics_Size).Text,
          umlSizeToStr(CoreSpace_Free_Space_Size).Text,
          CoreSpace_BlockCount]);
    end
  else
    begin
      StateLabel.Caption := '����ռ�:�ѹر� ���ɿռ�:�ѹر� ������Ŀ:�ѹر�';
    end;
end;

procedure TZDBPerfTestForm.DoStatus_Bcakcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

procedure TZDBPerfTestForm.ZDBCoreProgress(Total_, current_: Integer);
begin
  if current_ mod 1000 = 0 then
    begin
      TCompute.Sync(procedure
        begin
          ProgressBar.Max := Total_;
          ProgressBar.Position := current_;
        end);
    end;
end;

constructor TZDBPerfTestForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  WorkInParallelCore.V := True;
  AddDoStatusHook(Self, DoStatus_Bcakcall);
  ZDB := nil;
  FileEdit.Text := umlCombineFileName(TPath.GetTempPath, 'ZDB2Test.dat');
  PhySpaceEdit.Text := '1024*1024*1024*20';
  BlockSizeEdit.Text := '$FFFF';
end;

destructor TZDBPerfTestForm.Destroy;
begin
  DeleteDoStatusHook(Self);
  inherited Destroy;
end;

end.
