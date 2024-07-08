program PascalCodeUnification;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  PascalCodeUnificationFrm in 'PascalCodeUnificationFrm.pas' {PascalCodeUnificationForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TPascalCodeUnificationForm, PascalCodeUnificationForm);
  Application.Run;
end.
