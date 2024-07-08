program _147_Draw_Anchor_Text;

uses
  System.StartUpCopy,
  FMX.Forms,
  _147_Draw_Anchor_Text_Frm in '_147_Draw_Anchor_Text_Frm.pas' {_147_Draw_Anchor_Text_Form};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(T_147_Draw_Anchor_Text_Form, _147_Draw_Anchor_Text_Form);
  Application.Run;
end.
