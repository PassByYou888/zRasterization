program MPEGFileSplit;

uses
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  MPEGFileSplitMainFrm in 'MPEGFileSplitMainFrm.pas' {MPEGFileSplitMainForm} ;

{$R *.res}


begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'MPEG Split Tool';
  TStyleManager.TrySetStyle('Windows10 Dark');
  Application.CreateForm(TMPEGFileSplitMainForm, MPEGFileSplitMainForm);
  if ParamCount = 1 then
      MPEGFileSplitMainForm.MpegFileEdit.Text := ParamStr(1);
  Application.Run;

end.
