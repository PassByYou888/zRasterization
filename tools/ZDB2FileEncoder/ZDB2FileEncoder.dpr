program ZDB2FileEncoder;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  ZDB2FileEncoderFrm in 'ZDB2FileEncoderFrm.pas' {ZDB2FileEncoderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TZDB2FileEncoderForm, ZDB2FileEncoderForm);
  Application.Run;
end.
