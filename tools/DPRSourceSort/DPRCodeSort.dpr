program DPRCodeSort;

uses
  FastMM5 in '..\Common\FastMM5.pas',
  System.StartUpCopy,
  FMX.Forms,
  DPRCodeSortFrm in 'DPRCodeSortFrm.pas' {DPRCodeSortForm},
  StyleModuleUnit in '..\Common\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDPRCodeSortForm, DPRCodeSortForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;
end.
