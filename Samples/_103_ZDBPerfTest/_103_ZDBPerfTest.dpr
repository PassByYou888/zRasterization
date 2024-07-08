program _103_ZDBPerfTest;

uses
  FastMM5,
  Vcl.Forms,
  ZDBPerfTestFrm in 'ZDBPerfTestFrm.pas' {ZDBPerfTestForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TZDBPerfTestForm, ZDBPerfTestForm);
  Application.Run;
end.
