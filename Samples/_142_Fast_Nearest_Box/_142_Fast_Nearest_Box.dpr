program _142_Fast_Nearest_Box;

uses
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule} ,
  _142_Fast_Nearest_Box_Frm in '_142_Fast_Nearest_Box_Frm.pas' {_142_Fast_Nearest_Box_Form};

{$R *.res}


begin
  System.ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_142_Fast_Nearest_Box_Form, _142_Fast_Nearest_Box_Form);
  Application.Run;

end.
