program NumTrans;

uses
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  NumTransFrm in 'NumTransFrm.pas' {NumTransForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.Title := 'Number transform.';
  Application.CreateForm(TNumTransForm, NumTransForm);
  Application.Run;
end. 
