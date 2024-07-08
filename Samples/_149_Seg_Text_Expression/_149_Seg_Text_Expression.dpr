program _149_Seg_Text_Expression;

uses
  System.StartUpCopy,
  FMX.Forms,
  _149_Seg_Text_Expression_Frm in '_149_Seg_Text_Expression_Frm.pas' {_149_Seg_Text_Expression_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(T_149_Seg_Text_Expression_Form, _149_Seg_Text_Expression_Form);
  Application.Run;
end.
