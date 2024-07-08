unit SysMemCleanFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  ZR.PascalStrings, ZR.UPascalStrings, ZR.Core, ZR.DFE, ZR.UnicodeMixedLib, ZR.ListEngine, ZR.Status, ZR.Expression;

type
  TSysMemCleanForm = class(TForm)
    SizeEdit: TLabeledEdit;
    CleanButton: TButton;
    Memo: TMemo;
    fpsTimer: TTimer;
    thInfoLabel: TLabel;
    infoTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure infoTimerTimer(Sender: TObject);
    procedure CleanButtonClick(Sender: TObject);
  private
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
  public
  end;

var
  SysMemCleanForm: TSysMemCleanForm;

implementation

{$R *.dfm}


procedure TSysMemCleanForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatus_Backcall);
end;

procedure TSysMemCleanForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := TCompute.TotalTask <= 0;
  if not CanClose then
      MessageDlg('thread Busy...', mtError, [mbYes], 0);
end;

procedure TSysMemCleanForm.FormDestroy(Sender: TObject);
begin
  RemoveDoStatusHook(self);
end;

procedure TSysMemCleanForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

procedure TSysMemCleanForm.infoTimerTimer(Sender: TObject);
begin
  thInfoLabel.Caption := TCompute.State;
end;

procedure TSysMemCleanForm.CleanButtonClick(Sender: TObject);
begin
  TCompute.RunP_NP(procedure
    var
      siz: Int64;
      p: Pointer;
    begin
      siz := EStrToInt64(SizeEdit.Text, 0);
      DoStatus('prepare alloc memory: %s ', [umlSizeToStr(siz).Text]);
      p := System.GetMemory(siz);
      if p <> nil then
        begin
          DoStatus('done alloc memory: %s ', [umlSizeToStr(siz).Text]);
          DoStatus('prepare fill memory: %s ', [IntToHex(UInt64(p), 16)]);
          FillPtrByte(p, siz, 0);
          DoStatus('Done fill memory: %s ', [IntToHex(UInt64(p), 16)]);
          System.FreeMemory(p);
        end
      else
        begin
          DoStatus('error alloc memory: %s ', [umlSizeToStr(siz).Text]);
        end;
    end);
end;

procedure TSysMemCleanForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

end.
