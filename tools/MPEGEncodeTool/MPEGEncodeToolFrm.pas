unit MPEGEncodeToolFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo,

  System.IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status, ZR.ListEngine, ZR.DFE, ZR.Notify,
  ZR.Geometry2D, ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX,
  ZR.DrawEngine.PictureViewer,
  ZR.FFMPEG, ZR.FFMPEG.Reader, ZR.FFMPEG.Writer;

type
  TMPEGEncodeToolForm = class(TForm)
    sourceOpenDialog: TOpenDialog;
    bkTimer: TTimer;
    DestSaveDialog: TSaveDialog;
    toolLayout: TLayout;
    VideoSourceLayout: TLayout;
    Label1: TLabel;
    VideoSourceEdit: TEdit;
    BrowseSourceEditButton: TEditButton;
    VideoDestLayout: TLayout;
    Label2: TLabel;
    VideoDestEdit: TEdit;
    BrowseDestEditButton: TEditButton;
    AutoFileNameEditButton: TEditButton;
    RunEncodeButton: TButton;
    StopButton: TButton;
    quietCheckBox: TCheckBox;
    pb: TPaintBox;
    fitButton: TButton;
    rb_Layout: TLayout;
    GPU_Decoder_CheckBox: TCheckBox;
    GPU_Encoder_CheckBox: TCheckBox;
    DecoderOptMemo: TMemo;
    EncoderOptMemo: TMemo;
    UDP_CheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure bkTimerTimer(Sender: TObject);
    procedure BrowseSourceEditButtonClick(Sender: TObject);
    procedure BrowseDestEditButtonClick(Sender: TObject);
    procedure AutoFileNameEditButtonClick(Sender: TObject);
    procedure RunEncodeButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure fitButtonClick(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    dIntf: TDrawEngineInterface_FMX;
    d: TDrawEngine;
    vidTex: TDETexture;
    isStop: TAtomBool;
    FinishOnClose: Boolean;
    PicViewIntf: TPictureViewerInterface;
    procedure bkStatus(AText: SystemString; const ID: Integer);
  public
    procedure DoEncode(sour, dest: string);
    procedure DoPlay(sour: string);
  end;

var
  MPEGEncodeToolForm: TMPEGEncodeToolForm;

function ProcessVideoFileNameFromMacro(fileName: SystemString): SystemString;

implementation

{$R *.fmx}


uses StyleModuleUnit;

function ProcessVideoFileNameFromMacro(fileName: SystemString): SystemString;
var
  ht: THashStringList;
  now_: TDateTime;
  Year, Month, Day: Word;
  Hour, Min_, Sec, MSec: Word;
begin
  ht := THashStringList.Create;
  now_ := Now();
  DecodeDate(now_, Year, Month, Day);
  DecodeTime(now_, Hour, Min_, Sec, MSec);

  ht['Year'] := IntToStr(Year);
  ht['Month'] := IntToStr(Month);
  ht['Day'] := IntToStr(Day);
  ht['Hour'] := IntToStr(Hour);
  ht['Min'] := IntToStr(Min_);
  ht['Sec'] := IntToStr(Sec);
  ht['MSec'] := IntToStr(MSec);

  ht.ProcessMacro(fileName, '%', '%', Result);
  disposeObject(ht);
end;

procedure TMPEGEncodeToolForm.FormCreate(Sender: TObject);
var
  i: Integer;
  n: U_String;
begin
  AddDoStatusHook(self, bkStatus);
  dIntf := TDrawEngineInterface_FMX.Create;
  d := TDrawEngine.Create;
  d.ViewOptions := [voEdge];
  d.DrawInterface := dIntf;
  vidTex := TDrawEngine.NewTexture();
  isStop := TAtomBool.Create(True);
  FinishOnClose := False;
  PicViewIntf := TPictureViewerInterface.Create(d);
  PicViewIntf.ShowHistogramInfo := False;
  PicViewIntf.ShowPixelInfo := True;
  PicViewIntf.ShowPictureInfo := True;
  PicViewIntf.ShowBackground := True;

  if not ZR.FFMPEG.FFMPEGOK then
      ZR.FFMPEG.Load_ffmpeg(TPath.GetLibraryPath);

  if not ZR.FFMPEG.FFMPEGOK then
      ShowMessage('FFMPEG error!!');

  VideoSourceEdit.Text := '';
  VideoDestEdit.Text := '';

  for i := 1 to ParamCount do
    begin
      n := ParamStr(i);
      if not umlMultipleMatch(['-D3D', '-D2D', '-GPU', '-SOFT', '-GrayTheme'], n) then
        begin
          if umlMultipleMatch(['-TCP', 'TCP'], n) then
              UDP_CheckBox.IsChecked := False
          else if umlMultipleMatch(['-UDP', 'UDP'], n) then
              UDP_CheckBox.IsChecked := True
          else if VideoSourceEdit.Text = '' then
              VideoSourceEdit.Text := n
          else if VideoDestEdit.Text = '' then
              VideoDestEdit.Text := n;
        end;
    end;

  if (VideoSourceEdit.Text <> '') and (VideoDestEdit.Text <> '') then
    begin
      DoEncode(VideoSourceEdit.Text, VideoDestEdit.Text);
      quietCheckBox.IsChecked := False;
      FinishOnClose := True;
    end
  else if (VideoSourceEdit.Text <> '') then
      DoPlay(VideoSourceEdit.Text);
end;

procedure TMPEGEncodeToolForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := isStop.V;
  if not CanClose then
    begin
      FinishOnClose := True;
      isStop.V := True;
      WindowState := TWindowState.wsMinimized;
    end;
end;

procedure TMPEGEncodeToolForm.bkTimerTimer(Sender: TObject);
begin
  CheckThread;
  d.Progress();
  if umlTrimSpace(VideoDestEdit.Text).L > 0 then
    begin
      RunEncodeButton.Text := 'Encode';
    end
  else
    begin
      RunEncodeButton.Text := 'Play';
    end;
  Invalidate;
end;

procedure TMPEGEncodeToolForm.BrowseSourceEditButtonClick(Sender: TObject);
begin
  if umlFileExists(VideoSourceEdit.Text) then
      sourceOpenDialog.fileName := VideoSourceEdit.Text;
  if not sourceOpenDialog.Execute then
      exit;
  VideoSourceEdit.Text := sourceOpenDialog.fileName;
end;

procedure TMPEGEncodeToolForm.BrowseDestEditButtonClick(Sender: TObject);
begin
  if umlFileExists(VideoDestEdit.Text) then
      DestSaveDialog.fileName := VideoDestEdit.Text;
  if not DestSaveDialog.Execute then
      exit;
  VideoDestEdit.Text := DestSaveDialog.fileName;
end;

procedure TMPEGEncodeToolForm.AutoFileNameEditButtonClick(Sender: TObject);
var
  dir: string;
begin
  dir := umlGetFilePath(VideoDestEdit.Text);
  if selectDirectory('select directory.', '/', dir) then
      VideoDestEdit.Text := umlCombineFileName(dir, '%Year%_%Month%_%Day% %Hour%_%Min%.h264');
end;

procedure TMPEGEncodeToolForm.RunEncodeButtonClick(Sender: TObject);
begin
  DoEncode(VideoSourceEdit.Text, VideoDestEdit.Text);
end;

procedure TMPEGEncodeToolForm.StopButtonClick(Sender: TObject);
begin
  isStop.V := True;
end;

procedure TMPEGEncodeToolForm.fitButtonClick(Sender: TObject);
begin
  PicViewIntf.Fit;
end;

procedure TMPEGEncodeToolForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  PicViewIntf.TapDown(Vec2(X, Y));
end;

procedure TMPEGEncodeToolForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  PicViewIntf.TapMove(Vec2(X, Y));
end;

procedure TMPEGEncodeToolForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  PicViewIntf.TapUp(Vec2(X, Y));
end;

procedure TMPEGEncodeToolForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  d.ScaleCameraFromWheelDelta(WheelDelta);
end;

procedure TMPEGEncodeToolForm.pbPaint(Sender: TObject; Canvas: TCanvas);
begin
  dIntf.SetSurface(Canvas, Sender);
  d.SetSize;
  PicViewIntf.Render;
end;

procedure TMPEGEncodeToolForm.bkStatus(AText: SystemString; const ID: Integer);
begin
  d.PostScrollText(15, AText, 16, DEColor(1, 1, 1));
end;

procedure TMPEGEncodeToolForm.DoEncode(sour, dest: string);
begin
  TCompute.RunP_NP(procedure
    var
      OriDest, NewDest, tmpDest: string;
      Encoder: Boolean;
      Reader: TFFMPEG_Reader;
      Writer: TFFMPEG_Writer;
      fs: TCore_FileStream;
      tmpRaster: TMZR;
      lastCheckTime: TTimeTick;
    begin
      Encoder := umlTrimSpace(dest).L > 0;
      OriDest := umlTrimSpace(dest);

      TCompute.Synchronize(TCompute.CurrentThread, procedure
        begin
          PicViewIntf.Clear;
          VideoSourceLayout.Enabled := False;
          VideoDestLayout.Enabled := False;
          RunEncodeButton.Enabled := False;
          isStop.V := False;
          VideoSourceEdit.Password := True;
          rb_Layout.Visible := False;
        end);

      while not isStop.V do
        begin
          try
              Reader := TFFMPEG_Reader.Create('', sour, not self.UDP_CheckBox.IsChecked, GPU_Decoder_CheckBox.IsChecked, DecoderOptMemo.Lines.Text);
          except
            TCompute.Sleep(1000);
            continue;
          end;

          if Encoder then
            begin
              NewDest := ProcessVideoFileNameFromMacro(OriDest);
              umlCreateDirectory(umlGetFilePath(NewDest));
              fs := TCore_FileStream.Create(NewDest, fmCreate);
              Writer := TFFMPEG_Writer.Create(fs);

              // encoder custom options
              Writer.Addional_Options.ImportFromStrings(EncoderOptMemo.Lines);
              // used gpu encoder
              if (not GPU_Encoder_CheckBox.IsChecked) or
                (not Writer.OpenH264Codec('h264_nvenc', Reader.Width, Reader.Height, Reader.PSFRound, 500, 1, 2 * 1024 * 1024)) then
                  Writer.OpenH264Codec(Reader.Width, Reader.Height, Reader.PSFRound, 500, 1, 2 * 1024 * 1024); // used cpu encoder
              lastCheckTime := GetTimeTick();
            end;

          tmpRaster := NewZR();
          while (not isStop.V) and (Reader.ReadFrame(tmpRaster, False)) do
            begin
              if Encoder then
                begin
                  Writer.EncodeRaster(tmpRaster);
                  if GetTimeTick() - lastCheckTime > 60 * 1000 then
                    begin
                      tmpDest := ProcessVideoFileNameFromMacro(OriDest);
                      if not SameText(tmpDest, NewDest) then
                        begin
                          Writer.Flush();
                          disposeObjectAndNil(fs);
                          disposeObjectAndNil(Writer);
                          NewDest := tmpDest;

                          umlCreateDirectory(umlGetFilePath(NewDest));
                          fs := TCore_FileStream.Create(NewDest, fmCreate);
                          Writer := TFFMPEG_Writer.Create(fs);
                          if not Writer.OpenH264Codec('nvenc', Reader.Width, Reader.Height, Reader.PSFRound, 500, 1, 2 * 1024 * 1024) then
                              Writer.OpenH264Codec(Reader.Width, Reader.Height, Reader.PSFRound, 500, 1, 2 * 1024 * 1024);
                        end;
                      lastCheckTime := GetTimeTick();
                    end;
                end;

              TCompute.Synchronize(TCompute.CurrentThread, procedure
                begin
                  if (not quietCheckBox.IsChecked) or (PicViewIntf.Count = 0) then
                    begin
                      vidTex.Assign(tmpRaster);
                      vidTex.Update;
                    end;

                  if PicViewIntf.Count = 0 then
                    begin
                      PicViewIntf.InputPicture(vidTex, sour, True, False, False);
                      PicViewIntf.Fit();
                    end;

                  if Encoder then
                      PicViewIntf.First.texInfo := Format('%s(%s) current: %f total: %d',
                      [NewDest, umlSizeToStr(Writer.Size).Text, Reader.Current, Reader.Current_Frame])
                  else
                      PicViewIntf.First.texInfo := Format('current: %f total: %d',
                      [Reader.Current, Reader.Current_Frame]);
                end);
            end;
          disposeObjectAndNil(tmpRaster);
          disposeObjectAndNil(Reader);
          if Encoder then
            begin
              Writer.Flush();
              disposeObjectAndNil(fs);
              disposeObjectAndNil(Writer);
              isStop.V := True;
            end;
          TCompute.Sleep(1000);
        end;

      TCompute.Sync(procedure
        begin
          PicViewIntf.Clear;
          rb_Layout.Visible := True;
          VideoSourceLayout.Enabled := True;
          VideoDestLayout.Enabled := True;
          RunEncodeButton.Enabled := True;
          isStop.V := True;
          VideoSourceEdit.Password := False;
          if FinishOnClose then
            begin
              SysPost.PostExecuteP_NP(0.1, procedure
                begin
                  Close;
                end);
            end;
        end);
    end);
end;

procedure TMPEGEncodeToolForm.DoPlay(sour: string);
begin
  DoEncode(sour, '');
end;

end.
