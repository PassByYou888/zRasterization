program _115_SqeurnceAni;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  SqeurnceAniFrm in 'SqeurnceAniFrm.pas' {SqeurnceAniForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSqeurnceAniForm, SqeurnceAniForm);
  Application.Run;
end.
