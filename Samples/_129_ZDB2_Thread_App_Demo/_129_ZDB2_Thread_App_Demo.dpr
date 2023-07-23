program _129_ZDB2_Thread_App_Demo;

uses
  FastMM5 in '..\..\Tools\Common\FastMM5.pas',
  Vcl.Forms,
  _129_ZDB2_Thread_App_DemoFrm in '_129_ZDB2_Thread_App_DemoFrm.pas' {_129_ZDB2_Thread_App_DemoForm};

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(T_129_ZDB2_Thread_App_DemoForm, _129_ZDB2_Thread_App_DemoForm);
  Application.Run;

end.
