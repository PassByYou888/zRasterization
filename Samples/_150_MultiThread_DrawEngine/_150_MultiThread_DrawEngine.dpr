program _150_MultiThread_DrawEngine;

uses
  System.StartUpCopy,
  FMX.Forms,
  _150_MultiThread_DrawEngine_Frm in '_150_MultiThread_DrawEngine_Frm.pas' {_150_MultiThread_DrawEngine_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(T_150_MultiThread_DrawEngine_Form, _150_MultiThread_DrawEngine_Form);
  Application.Run;
end.
