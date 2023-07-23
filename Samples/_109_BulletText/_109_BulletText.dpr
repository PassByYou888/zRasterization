program _109_BulletText;

{$R *.dres}

uses
  FastMM5 in '..\..\Tools\Common\FastMM5.pas',
  System.StartUpCopy,
  FMX.Forms,
  BulletTextFrm in 'BulletTextFrm.pas' {BulletTextForm},
  StyleModuleUnit in '..\..\Tools\Common\StyleModuleUnit.pas' {StyleDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBulletTextForm, BulletTextForm);
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.Run;
end.
