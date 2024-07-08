program FileCheck;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  FileCheckFrm in 'FileCheckFrm.pas' {FileCheckForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TFileCheckForm, FileCheckForm);
  Application.Run;
end.
