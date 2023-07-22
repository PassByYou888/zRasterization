program ParticleRender;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  ParticleRenderFrm in 'ParticleRenderFrm.pas' {ParticleRenderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TParticleRenderForm, ParticleRenderForm);
  Application.Run;
end.
