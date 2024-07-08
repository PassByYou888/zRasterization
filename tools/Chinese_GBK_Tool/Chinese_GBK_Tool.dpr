program Chinese_GBK_Tool;

uses
  Vcl.Forms,
  Chinese_GBK_Tool_Frm in 'Chinese_GBK_Tool_Frm.pas' {Chinese_GBK_Tool_Form},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TChinese_GBK_Tool_Form, Chinese_GBK_Tool_Form);
  Application.Run;
end.
