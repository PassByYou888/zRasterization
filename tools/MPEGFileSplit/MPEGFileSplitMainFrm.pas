unit MPEGFileSplitMainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  System.DateUtils, System.IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.MemoryStream, ZR.MemoryRaster, ZR.Status,
  ZR.FFMPEG.Reader, ZR.FFMPEG.Writer, Vcl.Mask;

type
  TMPEGFileSplitMainForm = class(TForm)
    MpegFileEdit: TLabeledEdit;
    SplitTimeEdit: TLabeledEdit;
    BrowseButton: TButton;
    OpenDialog: TOpenDialog;
    RunButton: TButton;
    Memo: TMemo;
    Timer1: TTimer;
    StopButton: TButton;
    CudaCheckBox: TCheckBox;
    FastCopyCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure BrowseButtonClick(Sender: TObject);
    procedure RunButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatusMethod(Text_: SystemString; const ID: Integer);
  public
    IsStop: TAtomBool;
  end;

var
  MPEGFileSplitMainForm: TMPEGFileSplitMainForm;

function WaitShellExecute(sCMD, sWorkPath: string; ShowStatus: Boolean): DWord;

implementation

{$R *.dfm}


procedure TMPEGFileSplitMainForm.FormCreate(Sender: TObject);
var
  nCMD, InFile: U_String;
begin
  AddDoStatusHook(Self, DoStatusMethod);
  StatusThreadID := False;
  IsStop := TAtomBool.Create(False);

  InFile := 'source.mp4';

  DoStatus('do conversion before using MPEG split tool, this command line demo');
  nCMD := Format('%s -y -hwaccel cuvid -i "%s" -vcodec h264_nvenc -preset slow "%s"',
    ['FFMPEG.EXE', InFile.Text, 'target.mp4']);
  DoStatus('used cuvid: ' + nCMD);
  nCMD := Format('%s -y -i "%s" -f h264 -vcodec libx264 "%s"', ['FFMPEG.EXE', InFile.Text, 'target.mp4']);
  DoStatus('used cpu: ' + nCMD);
  DoStatus('');

  DoStatus('command line example of split MP4 file:');
  nCMD := Format('%s -hwaccel cuvid -ss 00:00:00 -t 00:00:15 -y -hwaccel cuvid -i "%s" -vcodec h264_nvenc -preset slow "%s"',
    ['FFMPEG.EXE', InFile.Text, 'target.mp4']);
  DoStatus('used cuvid: ' + nCMD);
  nCMD := Format('%s -ss 00:00:00 -t 00:00:15 -y -i "%s" -f h264 -vcodec libx264 "%s"', ['FFMPEG.EXE', InFile.Text, 'target.mp4']);
  DoStatus('used cpu: ' + nCMD);
  DoStatus('');
end;

procedure TMPEGFileSplitMainForm.BrowseButtonClick(Sender: TObject);
begin
  if umlFileExists(MpegFileEdit.Text) then
      OpenDialog.FileName := MpegFileEdit.Text;
  if not OpenDialog.Execute() then
      exit;
  MpegFileEdit.Text := OpenDialog.FileName;
end;

procedure TMPEGFileSplitMainForm.DoStatusMethod(Text_: SystemString; const ID: Integer);
begin
  if (Memo.Lines.Count > 0) and (length(Text_) < 200) and (TPascalString(Text_).SmithWaterman(Memo.Lines[Memo.Lines.Count - 1]) > 0.6) then
      Memo.Lines[Memo.Lines.Count - 1] := Text_
  else
      Memo.Lines.Add(Text_);
end;

function WaitShellExecute(sCMD, sWorkPath: string; ShowStatus: Boolean): DWord;
const
  BuffSize = $FFFF;
var
  ExecCode: DWord;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  pi: TProcessInformation;
  WasOK: Boolean;

  buffer: array [0 .. BuffSize] of Byte;
  BytesRead: Cardinal;
  line, n: TPascalString;
begin
  with SA do
    begin
      nLength := SizeOf(SA);
      bInheritHandle := True;
      lpSecurityDescriptor := nil;
    end;

  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);

  with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      CB := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE);
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;

  WasOK := CreateProcess(nil, PWideChar(sCMD), nil, nil, True, 0, nil, PWideChar(sWorkPath), SI, pi);
  CloseHandle(StdOutPipeWrite);

  if WasOK then
    begin
      repeat
        Sleep(10);
        WasOK := ReadFile(StdOutPipeRead, buffer, BuffSize, BytesRead, nil);
        if (WasOK) and (BytesRead > 0) then
          begin
            buffer[BytesRead] := 0;
            OemToAnsi(@buffer, @buffer);
            line.Append(strPas(PAnsiChar(@buffer)));
            while line.Exists([#10, #13]) do
              begin
                n := umlGetFirstStr_Discontinuity(line, #10#13);
                line := umlDeleteFirstStr_Discontinuity(line, #10#13);
                if ShowStatus then
                    DoStatus(n);
              end;
          end;
      until (not WasOK) or (BytesRead = 0);
      try
        WaitForSingleObject(pi.hProcess, Infinite);
        GetExitCodeProcess(pi.hProcess, Result);
      finally
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(StdOutPipeRead);
      end;
    end
  else
    begin
      ExecCode := 0;
    end;
end;

procedure TMPEGFileSplitMainForm.RunButtonClick(Sender: TObject);
begin
  IsStop.V := False;
  TCompute.RunP_NP(procedure
    var
      reader: TFFMPEG_Reader;
      writer: TFFMPEG_Writer;
      InFile, tmpFile: U_String;
      total_sec: Integer;
      Hour, Min, Sec, MSec: Word;
      stepSec: Integer;
      nt: Integer;
      bt: TTime;
      nCMD: U_String;
      ph, preFix, postFix: U_String;
      ordNo: Integer;
    begin
      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          InFile := MpegFileEdit.Text;
          MpegFileEdit.Enabled := False;
          SplitTimeEdit.Enabled := False;
          BrowseButton.Enabled := False;
          RunButton.Enabled := False;
        end);

      if not umlMultipleMatch(['*.mp4', '*.mkv'], umlGetFileName(InFile)) then
        begin
          if FastCopyCheckBox.Checked then
              nCMD := '%s -y -i "%s" -vcodec copy -f mp4 "%s"'
          else
            begin
              if CudaCheckBox.Checked then
                  nCMD := '%s -y -i "%s" -vcodec h264_nvenc -f mp4 "%s"'
              else
                  nCMD := '%s -y -i "%s" -vcodec h264 -f mp4 "%s"';
            end;
          nCMD := Format(nCMD, [TPath.GetLibraryPath+'FFMPEG.EXE', InFile.Text, umlChangeFileExt(InFile, '.mp4').Text]);
          DoStatus(nCMD);
          WaitShellExecute(nCMD, umlGetFilePath(TPath.GetLibraryPath+'FFMPEG.EXE'), True);
          InFile := umlChangeFileExt(InFile, '.mp4');
        end;

      try
        reader := TFFMPEG_Reader.Create(InFile);
        total_sec := round(reader.Total);
        disposeObject(reader);

        if total_sec <= 0 then
          begin
            MpegFileEdit.Enabled := True;
            SplitTimeEdit.Enabled := True;
            BrowseButton.Enabled := True;
            RunButton.Enabled := True;
            exit;
          end;

        DecodeTime(StrToTime(SplitTimeEdit.Text), Hour, Min, Sec, MSec);
        stepSec := Hour * 60 * 60 + Min * 60 + Sec;

        ordNo := 1;
        nt := 0;
        bt := StrToTime('00:00:00');
        ph := umlGetFilePath(InFile);
        if ph.Last <> '\' then
            ph.Append('\');
        preFix := umlChangeFileExt(umlGetFileName(InFile), '');
        postFix := umlGetFileExt(InFile);

        while nt + stepSec < total_sec do
          begin
            nt := nt + stepSec;

            if FastCopyCheckBox.Checked then
                nCMD := '%s -ss %s -t %s -y -i "%s" -vcodec copy -f mp4 "%s_%d.mp4"'
            else
              begin
                if CudaCheckBox.Checked then
                    nCMD := '%s -hwaccel cuvid -ss %s -t %s -y -i "%s" -vcodec h264_nvenc -f mp4 "%s_%d.mp4"'
                else
                    nCMD := '%s -ss %s -t %s -y -i "%s" -vcodec h264 -f mp4 "%s_%d.mp4"';
              end;

            nCMD := Format(nCMD,
              [TPath.GetLibraryPath+'FFMPEG.EXE',
              FormatDateTime('hh:mm:ss', bt), FormatDateTime('hh:mm:ss', IncSecond(StrToTime('00:00:00'), stepSec)),
              InFile.Text,
              ph.Text + preFix.Text, ordNo]);
            DoStatus(nCMD.Text);

            bt := IncSecond(bt, stepSec);
            inc(ordNo);

            WaitShellExecute(nCMD, umlGetFilePath(TPath.GetLibraryPath+'FFMPEG.EXE'), True);

            if IsStop.V then
                break;
          end;
      except
      end;

      TThread.Synchronize(TThread.CurrentThread, procedure
        begin
          MpegFileEdit.Enabled := True;
          SplitTimeEdit.Enabled := True;
          BrowseButton.Enabled := True;
          RunButton.Enabled := True;
        end);
    end);
end;

procedure TMPEGFileSplitMainForm.StopButtonClick(Sender: TObject);
begin
  IsStop.V := True;
end;

procedure TMPEGFileSplitMainForm.Timer1Timer(Sender: TObject);
begin
  DoStatus;
end;

end.
