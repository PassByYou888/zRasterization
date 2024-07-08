program ZDB2FileDecoder;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  ZDB2FileDecoderFrm in 'ZDB2FileDecoderFrm.pas' {ZDB2FileDecoderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TZDB2FileDecoderForm, ZDB2FileDecoderForm);
  Application.Run;
end.
