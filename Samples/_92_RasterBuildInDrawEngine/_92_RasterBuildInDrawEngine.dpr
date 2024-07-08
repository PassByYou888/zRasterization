program _92_RasterBuildInDrawEngine;

uses
  System.StartUpCopy,
  FMX.Forms,
  RasterBuildInDrawEngineFrm in 'RasterBuildInDrawEngineFrm.pas' {RasterBuildInDrawEngineForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TRasterBuildInDrawEngineForm, RasterBuildInDrawEngineForm);
  Application.Run;
end.
