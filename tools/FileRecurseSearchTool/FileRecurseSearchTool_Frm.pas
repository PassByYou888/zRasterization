unit FileRecurseSearchTool_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  System.IOUtils, Vcl.FileCtrl,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status, ZR.TextDataEngine;

type
  TFileRecurseSearchTool_Form = class(TForm)
    RootDirectoryEdit: TLabeledEdit;
    BrowseRoorDirectoryButton: TButton;
    FileFilterEdit: TLabeledEdit;
    DoSearchButton: TButton;
    Memo: TMemo;
    LogInfoLabel: TLabel;
    CoreTimer: TTimer;
    procedure BrowseRoorDirectoryButtonClick(Sender: TObject);
    procedure CoreTimerTimer(Sender: TObject);
    procedure DoSearchButtonClick(Sender: TObject);
  private
    procedure backcall_DoStatus(Text_: SystemString; const ID: Integer);
    procedure Do_Search_Directory;
    procedure WriteConfig;
    procedure ReadConfig;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FileRecurseSearchTool_Form: TFileRecurseSearchTool_Form;

implementation

{$R *.dfm}


procedure TFileRecurseSearchTool_Form.BrowseRoorDirectoryButtonClick(Sender: TObject);
var
  s: string;
begin
  s := RootDirectoryEdit.Text;
  if not SelectDirectory('select root directory.', '', s, [sdNewUI, sdNewFolder]) then
      exit;
  RootDirectoryEdit.Text := s;
end;

procedure TFileRecurseSearchTool_Form.CoreTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

procedure TFileRecurseSearchTool_Form.DoSearchButtonClick(Sender: TObject);
begin
  TCompute.RunM_NP(Do_Search_Directory);
end;

procedure TFileRecurseSearchTool_Form.backcall_DoStatus(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
end;

procedure TFileRecurseSearchTool_Form.Do_Search_Directory;
  procedure Do_Search_Path(ph: U_String; lv: Integer);
  var
    f_arry: U_StringArray;
    d_arry: U_StringArray;
    s: U_SystemString;
    found_f: Integer;
  begin
    f_arry := umlGet_File_Array(ph);
    found_f := 0;
    for s in f_arry do
      if umlMultipleMatch(FileFilterEdit.Text, s) then
          inc(found_f);
    SetLength(f_arry, 0);
    if found_f > 0 then
        DoStatus(ph);

    d_arry := umlGet_Path_Full_Array(ph);
    for s in d_arry do
        Do_Search_Path(s, lv + 1);
    SetLength(d_arry, 0);
  end;

begin
  Memo.Lines.Clear;
  Do_Search_Path(RootDirectoryEdit.Text, 0);
  DoStatus('done.');
end;

procedure TFileRecurseSearchTool_Form.WriteConfig;
var
  fn: U_String;
  te: TTextDataEngine;
begin
  fn := umlCombineFileName(TPath.GetLibraryPath, 'FileRecurseSearchTool.conf');
  te := TTextDataEngine.Create;
  te.SetDefaultText('main', RootDirectoryEdit.Name, RootDirectoryEdit.Text);
  te.SetDefaultText('main', FileFilterEdit.Name, FileFilterEdit.Text);
  te.SaveToFile(fn);
  disposeObject(te);
end;

procedure TFileRecurseSearchTool_Form.ReadConfig;
var
  fn: U_String;
  te: TTextDataEngine;
begin
  fn := umlCombineFileName(TPath.GetLibraryPath, 'FileRecurseSearchTool.conf');
  if not umlFileExists(fn) then
      exit;
  te := TTextDataEngine.Create;
  te.LoadFromFile(fn);
  RootDirectoryEdit.Text := te.GetDefaultText('main', RootDirectoryEdit.Name, RootDirectoryEdit.Text);
  FileFilterEdit.Text := te.GetDefaultText('main', FileFilterEdit.Name, FileFilterEdit.Text);
  disposeObject(te);
end;

constructor TFileRecurseSearchTool_Form.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AddDoStatusHook(self, backcall_DoStatus);
  StatusThreadID := False;
  RootDirectoryEdit.Text := TPath.GetLibraryPath;
  FileFilterEdit.Text := '*';
  ReadConfig;
end;

destructor TFileRecurseSearchTool_Form.Destroy;
begin
  WriteConfig;
  RemoveDoStatusHook(self);
  inherited Destroy;
end;

end.
