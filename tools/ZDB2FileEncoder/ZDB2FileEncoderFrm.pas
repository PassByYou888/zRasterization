unit ZDB2FileEncoderFrm;

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
  TZDB2FileEncoderForm = class(TForm)
    Timer: TTimer;
    DirectoryEdit: TLabeledEdit;
    DirBrowseButton: TButton;
    DestZDBFileEdit: TLabeledEdit;
    fileBrowseButton: TButton;
    buildButton: TButton;
    ThNumEdit: TLabeledEdit;
    ChunkEdit: TLabeledEdit;
    BlockEdit: TLabeledEdit;
    Memo: TMemo;
    InfoLabel: TLabel;
    CheckBox_IncludeSub: TCheckBox;
    ProgressBar: TProgressBar;
    Button_Abort: TButton;
    SaveDialog: TFileSaveDialog;
    procedure TimerTimer(Sender: TObject);
    procedure DirBrowseButtonClick(Sender: TObject);
    procedure fileBrowseButtonClick(Sender: TObject);
    procedure buildButtonClick(Sender: TObject);
    procedure Button_AbortClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FInfo: U_String;
    FFileStream_: TFileStream;
    FEncoder: TZDB2_File_Encoder;
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
    procedure ZDB2_File_OnProgress(State_: SystemString; Total, Current1, Current2: Int64);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ZDB2FileEncoderForm: TZDB2FileEncoderForm;

implementation

{$R *.dfm}


procedure TZDB2FileEncoderForm.TimerTimer(Sender: TObject);
begin
  CheckThreadSynchronize;
  InfoLabel.Caption := FInfo;
end;

procedure TZDB2FileEncoderForm.DirBrowseButtonClick(Sender: TObject);
var
  dir_: String;
begin
  dir_ := DirectoryEdit.Text;
  if SelectDirectory('select source directory.', '/', dir_, [sdNewFolder, sdShowShares, sdNewUI]) then
      DirectoryEdit.Text := dir_;
end;

procedure TZDB2FileEncoderForm.fileBrowseButtonClick(Sender: TObject);
begin
  SaveDialog.FileName := DestZDBFileEdit.Text;
  if SaveDialog.Execute then
      DestZDBFileEdit.Text := SaveDialog.FileName;
end;

procedure TZDB2FileEncoderForm.buildButtonClick(Sender: TObject);
begin
  if not umlDirectoryExists(DirectoryEdit.Text) then
    begin
      MessageDlg(Format('no exists directory' + #13#10 + '%s', [DirectoryEdit.Text]), mtError, [mbYes], 0);
      exit;
    end;
  if umlTrimSpace(DestZDBFileEdit.Text).L = 0 then
    begin
      MessageDlg(Format('need ZDB2.0 Package File.', []), mtError, [mbYes], 0);
      exit;
    end;
  if umlFileExists(DestZDBFileEdit.Text) then
    begin
      if MessageDlg(Format('file exists' + #13#10 + '%s' + #13#10 + 'do you overwrite??', [DestZDBFileEdit.Text]), mtWarning, [mbYes, mbNo], 0) <> mrYes then
          exit;
    end;
  if not umlDirectoryExists(umlGetFilePath(DestZDBFileEdit.Text)) then
    begin
      if MessageDlg(Format('path no exists from' + #13#10 + '%s' + #13#10 + 'do you create this directory??', [umlGetFilePath(DestZDBFileEdit.Text).Text]),
        mtWarning, [mbYes, mbNo], 0) <> mrYes then
          exit;
      umlCreateDirectory(umlGetFilePath(DestZDBFileEdit.Text));
    end;

  TCompute.RunP_NP(procedure
    begin
      TCompute.Sync(procedure
        begin
          DirectoryEdit.Enabled := False;
          DirBrowseButton.Enabled := False;
          CheckBox_IncludeSub.Enabled := False;
          DestZDBFileEdit.Enabled := False;
          fileBrowseButton.Enabled := False;
          buildButton.Enabled := False;
          ThNumEdit.Enabled := False;
          ChunkEdit.Enabled := False;
          BlockEdit.Enabled := False;
          Button_Abort.Enabled := True;
        end);

      try
        umlCreateDirectory(umlGetFilePath(DestZDBFileEdit.Text));
        FFileStream_ := TFileStream.Create(DestZDBFileEdit.Text, fmCreate);
        FEncoder := TZDB2_File_Encoder.Create(FFileStream_, EStrToInt(ThNumEdit.Text, CpuCount));
        FEncoder.OnProgress := ZDB2_File_OnProgress;

        FEncoder.EncodeFromDirectory(
          DirectoryEdit.Text,
          CheckBox_IncludeSub.Checked,
          '',
          EStrToInt(ChunkEdit.Text, 1024 * 1024),
          TSelectCompressionMethod.scmZLIB_Max,
          EStrToInt(BlockEdit.Text, 4 * 1024));

        FEncoder.Flush;
        if not FEncoder.Aborted then
          begin
            ZDB2_File_OnProgress(Format('finish %s -> %s', [FFileStream_.FileName, umlSizeToStr(FFileStream_.Size).Text]), 100, 0, 0);
            DoStatus('finish %s -> %s', [FFileStream_.FileName, umlSizeToStr(FFileStream_.Size).Text]);
          end;
        disposeObjectAndNil(FEncoder);
      except
      end;
      disposeObjectAndNil(FFileStream_);

      TCompute.Sync(procedure
        begin
          DirectoryEdit.Enabled := True;
          DirBrowseButton.Enabled := True;
          CheckBox_IncludeSub.Enabled := True;
          DestZDBFileEdit.Enabled := True;
          fileBrowseButton.Enabled := True;
          buildButton.Enabled := True;
          ThNumEdit.Enabled := True;
          ChunkEdit.Enabled := True;
          BlockEdit.Enabled := True;
          Button_Abort.Enabled := False;
        end);
    end);
end;

procedure TZDB2FileEncoderForm.Button_AbortClick(Sender: TObject);
begin
  if FEncoder <> nil then
      FEncoder.Aborted := True;
end;

procedure TZDB2FileEncoderForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FEncoder = nil;
end;

procedure TZDB2FileEncoderForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

procedure TZDB2FileEncoderForm.ZDB2_File_OnProgress(State_: SystemString; Total, Current1, Current2: Int64);
begin
  TCompute.Sync(procedure
    begin
      ProgressBar.Max := 100;
      ProgressBar.Position := umlPercentageToInt64(Total, Current1);
      FInfo := State_;
    end);
end;

constructor TZDB2FileEncoderForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, DoStatus_Backcall);
  StatusThreadID := False;
  ThNumEdit.Text := IntToStr(CpuCount);
  ChunkEdit.Text := '1024*1024';
  BlockEdit.Text := '16*1024';
  FInfo := '...';
  FFileStream_ := nil;
  FEncoder := nil;

  DirectoryEdit.Enabled := True;
  DirBrowseButton.Enabled := True;
  CheckBox_IncludeSub.Enabled := True;
  DestZDBFileEdit.Enabled := True;
  fileBrowseButton.Enabled := True;
  buildButton.Enabled := True;
  ThNumEdit.Enabled := True;
  ChunkEdit.Enabled := True;
  BlockEdit.Enabled := True;
  Button_Abort.Enabled := False;
end;

destructor TZDB2FileEncoderForm.Destroy;
begin
  DeleteDoStatusHook(self);
  inherited Destroy;
end;

end.
