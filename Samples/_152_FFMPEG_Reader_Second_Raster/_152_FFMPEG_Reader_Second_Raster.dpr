program _152_FFMPEG_Reader_Second_Raster;

uses
  System.StartUpCopy,
  FMX.Forms,
  StyleModuleUnit in '..\_88_DNN_Dog\StyleModuleUnit.pas' {StyleDataModule: TDataModule},
  _152_FFMPEG_Reader_Second_Raster_Frm in '_152_FFMPEG_Reader_Second_Raster_Frm.pas' {_152_FFMPEG_Reader_Second_Raster_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TStyleDataModule, StyleDataModule);
  Application.CreateForm(T_152_FFMPEG_Reader_Second_Raster_Form, _152_FFMPEG_Reader_Second_Raster_Form);
  Application.Run;
end.
