program Text_Format_Tool;

uses
  FastMM5,
  Vcl.Forms,
  Text_Format_Tool_Frm in 'Text_Format_Tool_Frm.pas' {Text_Format_Tool_Form},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TText_Format_Tool_Form, Text_Format_Tool_Form);
  Application.Run;
end.
