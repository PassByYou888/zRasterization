program _28_RasterizationFormatDemo;

uses
  FastMM5,
  System.StartUpCopy,
  FMX.Forms,
  RasterizationFormatFrm in 'RasterizationFormatFrm.pas' {RasterizationFormatForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TRasterizationFormatForm, RasterizationFormatForm);
  Application.Run;
end.
