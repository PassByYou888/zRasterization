unit LFilePackageWithZDBMainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  ObjectDataManagerFrameUnit, ZR.MemoryStream, ZR.ZDB.HashField_LIB, ZR.ZDB,
  ZR.UnicodeMixedLib, ZR.Core, ZR.Status, ZR.PascalStrings, ZR.UPascalStrings, ZR.ZDB.FileIndexPackage_LIB;

type
  TLFilePackageWithZDBMainForm = class(TForm)
    TopPanel: TPanel;
    NewButton: TButton;
    OpenButton: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    Memo: TMemo;
    Splitter1: TSplitter;
    Bevel4: TBevel;
    NewCustomButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure NewButtonClick(Sender: TObject);
    procedure NewCustomButtonClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
  private
    FDBEng: TObjectDataManager;
    FDBManFrame: TObjectDataManagerFrame;
    procedure DoStatusNear(AText: SystemString; const ID: Integer);
  public
    procedure OpenFile(fileName: SystemString);
  end;

var
  LFilePackageWithZDBMainForm: TLFilePackageWithZDBMainForm;

implementation

{$R *.dfm}


uses NewDBOptFrm;

procedure TLFilePackageWithZDBMainForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusNear);

  FDBEng := nil;

  FDBManFrame := TObjectDataManagerFrame.Create(Self);
  FDBManFrame.Parent := Self;
  FDBManFrame.Align := alClient;
  FDBManFrame.ResourceData := nil;

  FDBEng := TObjectDataManager.CreateAsStream(TMS64.CustomCreate(1024 * 1024), '', ObjectDataMarshal.ID, False, True, True);

  DoStatus('step 1: need to "New" or "open".');
end;

procedure TLFilePackageWithZDBMainForm.FormDestroy(Sender: TObject);
begin
  DeleteDoStatusHook(Self);
  disposeObject(FDBManFrame);
  disposeObject(FDBEng);
end;

procedure TLFilePackageWithZDBMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
end;

procedure TLFilePackageWithZDBMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TLFilePackageWithZDBMainForm.NewButtonClick(Sender: TObject);
begin
  if not SaveDialog.Execute() then
      exit;

  FDBManFrame.ResourceData := nil;
  disposeObject(FDBEng);
  FDBEng := TObjectDataManagerOfCache.CreateAsStream(TCore_FileStream.Create(SaveDialog.fileName, fmCreate), '', ObjectDataMarshal.ID, False, True, True);
  FDBManFrame.ResourceData := FDBEng;

  FDBEng.UpdateIO;
  FDBEng.StreamEngine.Position := 0;
  DoStatus('new DB %s [fixed string size: %d]', [SaveDialog.fileName, FDBEng.Handle^.FixedStringL]);
  DoStatus('Safe Backup: %s', [if_(FDBEng.Is_BACKUP_Mode, 'ON', 'OFF')]);
  DoStatus('Safe Flush: %s', [if_(FDBEng.Is_Flush_Mode, 'ON', 'OFF')]);

  Caption := PFormat('Package: %s', [umlGetFileName(SaveDialog.fileName).Text]);
  Application.Title := PFormat('Package: %s', [umlGetFileName(SaveDialog.fileName).Text]);
end;

procedure TLFilePackageWithZDBMainForm.NewCustomButtonClick(Sender: TObject);
var
  l: Integer;
begin
  if NewDBOptForm.ShowModal <> mrOk then
      exit;
  l := umlClamp(umlStrToInt(NewDBOptForm.FixedStringEdit.Text, 65), 10, $FF);
  if not SaveDialog.Execute() then
      exit;

  FDBManFrame.ResourceData := nil;
  disposeObject(FDBEng);
  FDBEng := TObjectDataManagerOfCache.CreateAsStream(l, TCore_FileStream.Create(SaveDialog.fileName, fmCreate), '', ObjectDataMarshal.ID, False, True, True);
  FDBManFrame.ResourceData := FDBEng;

  FDBEng.UpdateIO;
  FDBEng.StreamEngine.Position := 0;
  DoStatus('new DB %s [fixed string size: %d]', [SaveDialog.fileName, FDBEng.Handle^.FixedStringL]);
  DoStatus('Safe Backup: %s', [if_(FDBEng.Is_BACKUP_Mode, 'ON', 'OFF')]);
  DoStatus('Safe Flush: %s', [if_(FDBEng.Is_Flush_Mode, 'ON', 'OFF')]);

  Caption := PFormat('Package: %s', [umlGetFileName(SaveDialog.fileName).Text]);
  Application.Title := PFormat('Package: %s', [umlGetFileName(SaveDialog.fileName).Text]);
end;

procedure TLFilePackageWithZDBMainForm.OpenButtonClick(Sender: TObject);
begin
  if not OpenDialog.Execute then
      exit;

  OpenFile(OpenDialog.fileName);
end;

procedure TLFilePackageWithZDBMainForm.DoStatusNear(AText: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(AText);
end;

procedure TLFilePackageWithZDBMainForm.OpenFile(fileName: SystemString);
var
  stream: TCore_FileStream;
begin
  if not umlMultipleMatch(['*.OX', '*.ImgMat'], fileName) then
      exit;

  FDBManFrame.ResourceData := nil;
  disposeObject(FDBEng);
  stream := TCore_FileStream.Create(fileName, fmOpenReadWrite);

  stream.Position := 0;
  FDBEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', ObjectDataMarshal.ID, False, False, True);
  FDBManFrame.ResourceData := FDBEng;

  DoStatus('open %s [fixed string size: %d]', [fileName, FDBEng.Handle^.FixedStringL]);
  DoStatus('Safe Backup: %s', [if_(FDBEng.Is_BACKUP_Mode, 'ON', 'OFF')]);
  DoStatus('Safe Flush: %s', [if_(FDBEng.Is_Flush_Mode, 'ON', 'OFF')]);

  Caption := PFormat('Package: %s', [umlGetFileName(fileName).Text]);
  Application.Title := PFormat('Package: %s', [umlGetFileName(fileName).Text]);
end;

end.
