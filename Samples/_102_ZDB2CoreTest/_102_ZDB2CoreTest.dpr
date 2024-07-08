program _102_ZDB2CoreTest;

uses
  System.StartUpCopy,
  FMX.Forms,
  ZDB2CoreTestFrm in 'ZDB2CoreTestFrm.pas' {ZDB2CoreTestForm};

{$R *.res}


begin
  System.ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TZDB2CoreTestForm, ZDB2CoreTestForm);
  Application.Run;

end.
