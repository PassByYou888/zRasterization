program SysMemClean;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  SysMemCleanFrm in 'SysMemCleanFrm.pas' {SysMemCleanForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TSysMemCleanForm, SysMemCleanForm);
  Application.Run;
end.
