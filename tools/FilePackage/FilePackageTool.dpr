program FilePackageTool;

uses
  FastMM5 in '..\Common\FastMM5.pas',
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  FilePackageWithZDBMainFrm in 'FilePackageWithZDBMainFrm.pas' {FilePackageWithZDBMainForm} ,
  ObjectDataManagerFrameUnit in 'ObjectDataManagerFrameUnit.pas' {ObjectDataManagerFrame: TFrame} ,
  ObjectDataTreeFrameUnit in 'ObjectDataTreeFrameUnit.pas' {ObjectDataTreeFrame: TFrame} ,
  BuildIndexPackageOptFrm in 'BuildIndexPackageOptFrm.pas' {BuildIndexPackageOptForm} ,
  NewDBOptFrm in 'NewDBOptFrm.pas' {NewDBOptForm};

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TFilePackageWithZDBMainForm, FilePackageWithZDBMainForm);
  Application.CreateForm(TBuildIndexPackageOptForm, BuildIndexPackageOptForm);
  Application.CreateForm(TNewDBOptForm, NewDBOptForm);
  if ParamCount = 1 then
      FilePackageWithZDBMainForm.OpenFile(ParamStr(1));
  Application.Run;

end.
