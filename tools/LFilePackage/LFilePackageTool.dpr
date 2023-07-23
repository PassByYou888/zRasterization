program LFilePackageTool;

uses
  FastMM5 in '..\Common\FastMM5.pas',
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  LFilePackageWithZDBMainFrm in 'LFilePackageWithZDBMainFrm.pas' {LFilePackageWithZDBMainForm} ,
  ObjectDataManagerFrameUnit in 'ObjectDataManagerFrameUnit.pas' {ObjectDataManagerFrame: TFrame} ,
  ObjectDataTreeFrameUnit in 'ObjectDataTreeFrameUnit.pas' {ObjectDataTreeFrame: TFrame} ,
  NewDBOptFrm in 'NewDBOptFrm.pas' {NewDBOptForm};

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TLFilePackageWithZDBMainForm, LFilePackageWithZDBMainForm);
  Application.CreateForm(TNewDBOptForm, NewDBOptForm);
  if ParamCount = 1 then
      LFilePackageWithZDBMainForm.OpenFile(ParamStr(1));
  Application.Run;

end.
