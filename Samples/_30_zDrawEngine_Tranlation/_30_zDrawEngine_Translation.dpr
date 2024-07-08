program _30_zDrawEngine_Translation;

uses
  System.StartUpCopy,
  FMX.Forms,
  zDrawEngineFrm in 'zDrawEngineFrm.pas' {zDrawEngineForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TzDrawEngineForm, zDrawEngineForm);
  Application.Run;
end.
