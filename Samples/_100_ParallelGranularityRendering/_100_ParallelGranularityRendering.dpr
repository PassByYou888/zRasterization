program _100_ParallelGranularityRendering;

uses
  System.StartUpCopy,
  FMX.Forms,
  ParallelGranularityRenderingFrm in 'ParallelGranularityRenderingFrm.pas' {ParallelGranularityRenderingForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TParallelGranularityRenderingForm, ParallelGranularityRenderingForm);
  Application.Run;
end.
