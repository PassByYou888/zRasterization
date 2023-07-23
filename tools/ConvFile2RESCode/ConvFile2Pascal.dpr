program ConvFile2Pascal;

uses
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  ConvFileFrm in 'ConvFileFrm.pas' {ConvFileForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.Title := 'Convert File to Pascal Code';
  Application.CreateForm(TConvFileForm, ConvFileForm);
  Application.Run;
end.
