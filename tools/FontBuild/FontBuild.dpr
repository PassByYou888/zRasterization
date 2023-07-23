program FontBuild;

uses
  FastMM5 in '..\Common\FastMM5.pas',
  Vcl.Forms,
  FontBuildFrm in 'FontBuildFrm.pas' {FontBuildForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.Title := 'Font Builder.';
  Application.CreateForm(TFontBuildForm, FontBuildForm);
  Application.Run;
end.
