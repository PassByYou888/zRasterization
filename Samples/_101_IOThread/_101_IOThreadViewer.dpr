program _101_IOThreadViewer;

uses
  System.StartUpCopy,
  FMX.Forms,
  IOThreadViewerFrm in 'IOThreadViewerFrm.pas' {IOThreadViewerForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TIOThreadViewerForm, IOThreadViewerForm);
  Application.Run;
end.
