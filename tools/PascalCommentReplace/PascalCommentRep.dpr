program PascalCommentRep;

uses
  FastMM5 in '..\Common\FastMM5.pas',
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  PascalCommentRepFrm in 'PascalCommentRepFrm.pas' {PascalCommentRepForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TPascalCommentRepForm, PascalCommentRepForm);
  Application.Run;
end.
