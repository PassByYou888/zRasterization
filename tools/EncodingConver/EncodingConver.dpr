program EncodingConver;

uses
  FastMM5,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  EncodingConverFrm in 'EncodingConverFrm.pas' {EncodingConverForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'UTF8 Text Signed tool';
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TEncodingConverForm, EncodingConverForm);
  Application.Run;
end.
