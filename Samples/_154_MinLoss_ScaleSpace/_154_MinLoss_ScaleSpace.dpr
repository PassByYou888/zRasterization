program _154_MinLoss_ScaleSpace;

uses
  System.StartUpCopy,
  FMX.Forms,
  _154_MinLoss_ScaleSpace_Frm in '_154_MinLoss_ScaleSpace_Frm.pas' {_154_MinLoss_ScaleSpace_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(T_154_MinLoss_ScaleSpace_Form, _154_MinLoss_ScaleSpace_Form);
  Application.Run;
end.
