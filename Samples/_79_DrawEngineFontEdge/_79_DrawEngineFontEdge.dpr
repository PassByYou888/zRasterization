program _79_DrawEngineFontEdge;

uses
  System.StartUpCopy,
  FMX.Forms,
  DrawEngineFontEdgeMainFrm in 'DrawEngineFontEdgeMainFrm.pas' {DrawEngineFontEdgeMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDrawEngineFontEdgeMainForm, DrawEngineFontEdgeMainForm);
  Application.Run;
end.
