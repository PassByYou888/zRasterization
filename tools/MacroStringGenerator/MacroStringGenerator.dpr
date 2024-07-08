program MacroStringGenerator;

uses
  FastMM5,
  Vcl.Forms,
  MacroStringGenerator_Frm in 'MacroStringGenerator_Frm.pas' {MacroStringGenerator_Form},
  Vcl.Themes,
  Vcl.Styles;

{$R MacroStringGenerator.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TMacroStringGenerator_Form, MacroStringGenerator_Form);
  Application.Run;
end.
