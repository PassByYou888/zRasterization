program _116_RealtimeDataFrameEncoder;

uses
  FastMM5 in '..\..\Tools\Common\FastMM5.pas',
  Vcl.Forms,
  RealtimeDataFrameEncoderFrm in 'RealtimeDataFrameEncoderFrm.pas' {RealtimeDataFrameEncoderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TRealtimeDataFrameEncoderForm, RealtimeDataFrameEncoderForm);
  Application.Run;
end.
