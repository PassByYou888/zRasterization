unit ZDB2FileDecoderFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,

  Vcl.FileCtrl, System.IOUtils,

{$IFDEF FPC}
  ZR.FPC.GenericList,
{$ENDIF FPC}
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status, ZR.MemoryStream,
  ZR.ZDB2.FileEncoder, ZR.ZDB2, ZR.Expression;

type
  TZDB2FileDecoderForm = class(TForm)
    Timer: TTimer;
    DirectoryEdit: TLabeledEdit;
    DirBrowseButton: TButton;
    SourceZDBFileEdit: TLabeledEdit;
    fileBrowseButton: TButton;
    ExtractButton: TButton;
    Memo: TMemo;
    ProgressBar: TProgressBar;
    Button_Abort: TButton;
    OpenDialog: TFileOpenDialog;
    InfoLabel: TLabel;
    procedure TimerTimer(Sender: TObject);
    procedure fileBrowseButtonClick(Sender: TObject);
    procedure ExtractButtonClick(Sender: TObject);
    procedure Button_AbortClick(Sender: TObject);
    procedure DirBrowseButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    Finfo: SystemString;
    FDecoder: TZDB2_File_Decoder;
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
    procedure ZDB2_File_OnProgress(State_: SystemString; Total, Current1, Current2: Int64);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ZDB2FileDecoderForm: TZDB2FileDecoderForm;

implementation

{$R *.dfm}


procedure TZDB2FileDecoderForm.TimerTimer(Sender: TObject);
begin
  CheckThreadSynchronize;
end;

procedure TZDB2FileDecoderForm.fileBrowseButtonClick(Sender: TObject);
begin
  OpenDialog.FileName := SourceZDBFileEdit.Text;
  if OpenDialog.Execute then
      SourceZDBFileEdit.Text := OpenDialog.FileName;
end;

procedure TZDB2FileDecoderForm.ExtractButtonClick(Sender: TObject);
begin
  if umlTrimSpace(DirectoryEdit.Text).L = 0 then
    begin
      exit;
    end;
  if not umlDirectoryExists(DirectoryEdit.Text) then
    begin
      if MessageDlg(Format('no exists' + #13#10 + '%s' + #13#10 + 'do you create this directory??', [DirectoryEdit.Text]),
        mtWarning, [mbYes, mbNo], 0) <> mrYes then
          exit;
      umlCreateDirectory(DirectoryEdit.Text);
    end;
  if not umlFileExists(SourceZDBFileEdit.Text) then
    begin
      MessageDlg(Format('file no exists' + #13#10 + '%s', [SourceZDBFileEdit.Text]), mtError, [mbYes], 0);
      exit;
    end;
  if not TZDB2_File_Decoder.CheckFile(SourceZDBFileEdit.Text) then
    begin
      MessageDlg(Format('file no supported' + #13#10 + '%s', [SourceZDBFileEdit.Text]), mtError, [mbYes], 0);
      exit;
    end;

  TCompute.RunP_NP(procedure
    var
      i: Integer;
    begin
      TCompute.Sync(procedure
        begin
          SourceZDBFileEdit.Enabled := False;
          fileBrowseButton.Enabled := False;
          ExtractButton.Enabled := False;
          Button_Abort.Enabled := True;
          DirectoryEdit.Enabled := False;
          DirBrowseButton.Enabled := False;
        end);

      FDecoder := TZDB2_File_Decoder.CreateFile(SourceZDBFileEdit.Text, CpuCount);
      FDecoder.OnProgress := ZDB2_File_OnProgress;
      try
        if FDecoder.Files.Num > 0 then
          with FDecoder.Files.Repeat_ do
            repeat
                FDecoder.DecodeToDirectory(Queue^.Data, DirectoryEdit.Text);
            until (FDecoder.Aborted) or (not Next);
        disposeObjectAndNil(FDecoder);
        ZDB2_File_OnProgress('finish.', 0, 0, 0);
        DoStatus('finish.');
      except
      end;

      TCompute.Sync(procedure
        begin
          SourceZDBFileEdit.Enabled := True;
          fileBrowseButton.Enabled := True;
          ExtractButton.Enabled := True;
          Button_Abort.Enabled := False;
          DirectoryEdit.Enabled := True;
          DirBrowseButton.Enabled := True;
        end);
    end);
end;

procedure TZDB2FileDecoderForm.Button_AbortClick(Sender: TObject);
begin
  if (FDecoder <> nil) then
      FDecoder.Aborted := True;
end;

procedure TZDB2FileDecoderForm.DirBrowseButtonClick(Sender: TObject);
var
  dir_: String;
begin
  dir_ := DirectoryEdit.Text;
  if SelectDirectory('extract dest directory.', '/', dir_, [sdNewFolder, sdShowShares, sdNewUI]) then
      DirectoryEdit.Text := dir_;
end;

procedure TZDB2FileDecoderForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FDecoder = nil;
end;

procedure TZDB2FileDecoderForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

procedure TZDB2FileDecoderForm.ZDB2_File_OnProgress(State_: SystemString; Total, Current1, Current2: Int64);
begin
  TCompute.Sync(procedure
    begin
      ProgressBar.Max := 100;
      ProgressBar.Position := umlPercentageToInt64(Total, Current1);
      InfoLabel.Caption := State_;
    end);
end;

constructor TZDB2FileDecoderForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, DoStatus_Backcall);
  StatusThreadID := False;

  Finfo := '';
  FDecoder := nil;

  SourceZDBFileEdit.Enabled := True;
  fileBrowseButton.Enabled := True;
  ExtractButton.Enabled := True;
  Button_Abort.Enabled := False;
  DirectoryEdit.Enabled := True;
  DirBrowseButton.Enabled := True;
end;

destructor TZDB2FileDecoderForm.Destroy;
begin
  DeleteDoStatusHook(self);
  inherited Destroy;
end;

end.
