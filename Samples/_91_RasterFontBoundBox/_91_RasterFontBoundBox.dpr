program _91_RasterFontBoundBox;

uses
  System.StartUpCopy,
  FMX.Forms,
  RasterFontBoundBoxFrm in 'RasterFontBoundBoxFrm.pas' {RasterFontBoundBoxForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TRasterFontBoundBoxForm, RasterFontBoundBoxForm);
  Application.Run;
end.
