program FileRecurseSearchTool;

uses
  Vcl.Forms,
  FileRecurseSearchTool_Frm in 'FileRecurseSearchTool_Frm.pas' {FileRecurseSearchTool_Form},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TFileRecurseSearchTool_Form, FileRecurseSearchTool_Form);
  Application.Run;
end.
