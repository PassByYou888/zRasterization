{ ****************************************************************************** }
{ * FFMPEG Encoder                                                             * }
{ ****************************************************************************** }
unit ZR.FFMPEG.Writer;

{$I ..\ZR.Define.inc}

interface

uses SysUtils,
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.ListEngine, ZR.MemoryStream, ZR.Status,
  ZR.MemoryRaster, ZR.FFMPEG;

const
  h264_gpu_encoder = 'h264_nvenc'; // nvidia: h264_nvenc, intel: h264_qsv, amd: h264_amf
  h265_gpu_encoder = 'hevc_nvenc'; // nvidia: hevc_nvenc, intel: hevc_qsv, amd: hevc_amf

type
  TFFMPEG_Writer = class(TCore_Object)
  protected
    FAddional_Options: THashStringList;
    VideoCodec: PAVCodec;
    VideoCodecCtx: PAVCodecContext;
    AVPacket_Ptr: PAVPacket;
    Frame, FrameRGB: PAVFrame;
    SWS_CTX: PSwsContext;
    FOutput: TCore_Stream;
    FAutoFreeOutput: Boolean;
    FPixelFormat: TAVPixelFormat;
    FLastWidth, FLastHeight: Integer;
    FEncodeNum: Integer;
    function InternalOpenCodec_(const codec: PAVCodec; const Width, Height, PSF, gop, bFrame, quantizerMin, quantizerMax: Integer; const Bitrate: Int64): Boolean;
    function InternalOpenCodec(const codec: PAVCodec; const Width, Height, PSF, gop, bFrame, quantizerMin, quantizerMax: Integer; const Bitrate: Int64): Boolean;
  public
    Critical: TCritical;
    constructor Create(output_: TCore_Stream);
    destructor Destroy; override;

    class procedure PrintEncodec();

    property Addional_Options: THashStringList read FAddional_Options;
    function OpenCodec(const codec_name: U_String; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean; overload;
    function OpenCodec(const codec_id: TAVCodecID; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean; overload;
    function OpenH264Codec(const Width, Height, PSF: Integer; const Bitrate: Int64): Boolean; overload;
    function OpenH264Codec(const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean; overload;
    function OpenH264Codec(const codec_name: U_String; const Width, Height, PSF: Integer; const Bitrate: Int64): Boolean; overload;
    function OpenH264Codec(const codec_name: U_String; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean; overload;
    // default quantizerMin=2, quantizerMax=31
    function OpenJPEGCodec(const Width, Height, quantizerMin, quantizerMax: Integer): Boolean; overload;
    function OpenJPEGCodec(const Width, Height: Integer): Boolean; overload;
    procedure CloseCodec;

    function EncodeRaster(raster: TMZR; var Updated: Integer): Boolean; overload;
    function EncodeRaster(raster: TMZR): Boolean; overload;
    procedure Flush;

    property EncodeNum: Integer read FEncodeNum;
    function Size: Int64;
    function LockOutput: TCore_Stream;
    procedure UnLockOutoput;
    property AutoFreeOutput: Boolean read FAutoFreeOutput write FAutoFreeOutput;
    property PixelFormat: TAVPixelFormat read FPixelFormat write FPixelFormat;
    property LastWidth: Integer read FLastWidth;
    property LastHeight: Integer read FLastHeight;
  end;

function Fast_Encode_As_MJPEG(Input: TMZR; output: TMS64): Boolean;

var
  FFMPEG_Writer_Global_Critical: TCritical;

implementation

function Fast_Encode_As_MJPEG(Input: TMZR; output: TMS64): Boolean;
begin
  Result := False;
  if not FFMPEGOK then
      exit;
  with TFFMPEG_Writer.Create(output) do
    begin
      OpenJPEGCodec(Input.Width, Input.Height);
      EncodeRaster(Input);
      Flush;
      Free;
    end;
  Result := True;
end;

function TFFMPEG_Writer.InternalOpenCodec_(const codec: PAVCodec; const Width, Height, PSF, gop, bFrame, quantizerMin, quantizerMax: Integer; const Bitrate: Int64): Boolean;
var
  AV_Options: PPAVDictionary;
  r: Integer;
{$IFDEF FPC}
  procedure do_fpc_progress(Sender: THashStringList; Name_: PSystemString; const V: SystemString);
  var
    p1_, p2_: Pointer;
  begin
    p1_ := TPascalString(Name_^).BuildPlatformPChar;
    p2_ := TPascalString(V).BuildPlatformPChar;
    av_dict_set(@AV_Options, p1_, p2_, 0);
    TPascalString.FreePlatformPChar(p1_);
    TPascalString.FreePlatformPChar(p2_);
  end;
{$ENDIF FPC}


begin
  Result := False;
  VideoCodec := codec;

  if not Assigned(VideoCodec) then
    begin
      DoStatus('not found Codec.');
      exit;
    end;

  try
      VideoCodecCtx := avcodec_alloc_context3(VideoCodec);
  except
      VideoCodecCtx := nil;
  end;

  if not Assigned(VideoCodecCtx) then
    begin
      DoStatus('Could not allocate video codec context');
      exit;
    end;

  AVPacket_Ptr := av_packet_alloc();

  VideoCodecCtx^.bit_rate := Bitrate;
  VideoCodecCtx^.Width := Width - (Width mod 2);
  VideoCodecCtx^.Height := Height - (Height mod 2);
  VideoCodecCtx^.time_base.num := 1;
  VideoCodecCtx^.time_base.den := PSF;
  VideoCodecCtx^.framerate.num := PSF;
  VideoCodecCtx^.framerate.den := 1;
  VideoCodecCtx^.gop_size := gop;
  VideoCodecCtx^.max_b_frames := bFrame;
  VideoCodecCtx^.pix_fmt := FPixelFormat;
  VideoCodecCtx^.qmin := quantizerMin;
  VideoCodecCtx^.qmax := quantizerMax;

  AV_Options := nil;
  if FAddional_Options.Count > 0 then
    begin
      // custom options
{$IFDEF FPC}
      FAddional_Options.ProgressP(@do_fpc_progress);
{$ELSE FPC}
      FAddional_Options.ProgressP(procedure(Sender: THashStringList; Name_: PSystemString; const V: SystemString)
        var
          p1_, p2_: Pointer;
        begin
          p1_ := TPascalString(Name_^).BuildPlatformPChar;
          p2_ := TPascalString(V).BuildPlatformPChar;
          av_dict_set(@AV_Options, p1_, p2_, 0);
          TPascalString.FreePlatformPChar(p1_);
          TPascalString.FreePlatformPChar(p2_);
        end);
{$ENDIF FPC}
    end;
  try
    r := avcodec_open2(VideoCodecCtx, VideoCodec, @AV_Options);
    if r < 0 then
      begin
        DoStatus('Could not open codec: %s', [av_err2str(r)]);
        exit;
      end;
  except
    DoStatus('Could not open codec.', []);
    exit;
  end;

  // alloc frame
  Frame := av_frame_alloc();
  FrameRGB := av_frame_alloc();
  if (FrameRGB = nil) or (Frame = nil) then
    begin
      DoStatus('Could not allocate AVFrame structure');
      exit;
    end;

  Frame^.format := Ord(VideoCodecCtx^.pix_fmt);
  Frame^.Width := VideoCodecCtx^.Width;
  Frame^.Height := VideoCodecCtx^.Height;
  Frame^.pts := 0;

  // alignment
  r := av_frame_get_buffer(Frame, 32);
  if r < 0 then
    begin
      DoStatus('Could not allocate the video frame data');
      exit;
    end;

  FrameRGB^.format := Ord(AV_PIX_FMT_BGRA);
  FrameRGB^.Width := Frame^.Width;
  FrameRGB^.Height := Frame^.Height;

  SWS_CTX := sws_getContext(
  FrameRGB^.Width,
    FrameRGB^.Height,
    AV_PIX_FMT_BGRA,
    Frame^.Width,
    Frame^.Height,
    FPixelFormat,
    SWS_BILINEAR,
    nil,
    nil,
    nil);

  FLastWidth := Width;
  FLastHeight := Height;
  FEncodeNum := 0;
  Result := True;
end;

function TFFMPEG_Writer.InternalOpenCodec(const codec: PAVCodec; const Width, Height, PSF, gop, bFrame, quantizerMin, quantizerMax: Integer; const Bitrate: Int64): Boolean;
begin
  FFMPEG_Writer_Global_Critical.Lock;
  try
      Result := InternalOpenCodec_(codec, Width, Height, PSF, gop, bFrame, quantizerMin, quantizerMax, Bitrate);
  finally
      FFMPEG_Writer_Global_Critical.UnLock;
  end;
end;

constructor TFFMPEG_Writer.Create(output_: TCore_Stream);
begin
  inherited Create;
  FAddional_Options := THashStringList.Create;
  VideoCodecCtx := nil;
  VideoCodec := nil;
  AVPacket_Ptr := nil;
  Frame := nil;
  FrameRGB := nil;
  SWS_CTX := nil;
  FOutput := output_;
  FAutoFreeOutput := False;
  FPixelFormat := AV_PIX_FMT_YUV420P;
  FLastWidth := 0;
  FLastHeight := 0;
  FEncodeNum := 0;
  Critical := TCritical.Create;
end;

destructor TFFMPEG_Writer.Destroy;
begin
  CloseCodec;
  if FAutoFreeOutput then
      DisposeObject(FOutput);
  DisposeObject(FAddional_Options);
  DisposeObject(Critical);
  inherited Destroy;
end;

class procedure TFFMPEG_Writer.PrintEncodec;
var
  codec: PAVCodec;
begin
  codec := av_codec_next(nil);
  while codec <> nil do
    begin
      if av_codec_is_encoder(codec) = 1 then
          DoStatus('ID[%d] Name[%s] %s', [Integer(codec^.id), string(codec^.name), string(codec^.long_name)]);
      codec := av_codec_next(codec);
    end;
end;

function TFFMPEG_Writer.OpenCodec(const codec_name: U_String; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean;
var
  tmp: Pointer;
begin
  FPixelFormat := AV_PIX_FMT_YUV420P;
  tmp := codec_name.BuildPlatformPChar();
  try
      Result := InternalOpenCodec(avcodec_find_encoder_by_name(tmp), Width, Height, PSF, gop, bFrame, 2, 31, Bitrate);
  except
      Result := False;
  end;
  U_String.FreePlatformPChar(tmp);
end;

function TFFMPEG_Writer.OpenCodec(const codec_id: TAVCodecID; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean;
begin
  FPixelFormat := AV_PIX_FMT_YUV420P;
  try
      Result := InternalOpenCodec(avcodec_find_encoder(codec_id), Width, Height, PSF, gop, bFrame, 2, 31, Bitrate);
  except
      Result := False;
  end;
end;

function TFFMPEG_Writer.OpenH264Codec(const Width, Height, PSF: Integer; const Bitrate: Int64): Boolean;
begin
  Result := OpenCodec(AV_CODEC_ID_H264, Width, Height, PSF, PSF div 2, 1, Bitrate);
end;

function TFFMPEG_Writer.OpenH264Codec(const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean;
begin
  Result := OpenCodec(AV_CODEC_ID_H264, Width, Height, PSF, gop, bFrame, Bitrate);
end;

function TFFMPEG_Writer.OpenH264Codec(const codec_name: U_String; const Width, Height, PSF: Integer; const Bitrate: Int64): Boolean;
begin
  Result := OpenCodec(codec_name, Width, Height, PSF, PSF div 2, 1, Bitrate);
end;

function TFFMPEG_Writer.OpenH264Codec(const codec_name: U_String; const Width, Height, PSF, gop, bFrame: Integer; const Bitrate: Int64): Boolean;
begin
  Result := OpenCodec(codec_name, Width, Height, PSF, gop, bFrame, Bitrate);
end;

function TFFMPEG_Writer.OpenJPEGCodec(const Width, Height, quantizerMin, quantizerMax: Integer): Boolean;
begin
  FPixelFormat := AV_PIX_FMT_YUVJ420P;
  try
      Result := InternalOpenCodec(avcodec_find_encoder(AV_CODEC_ID_MJPEG), Width, Height, 25, 1, 0, quantizerMin, quantizerMax, 1024 * 1024);
  except
      Result := False;
  end;
end;

function TFFMPEG_Writer.OpenJPEGCodec(const Width, Height: Integer): Boolean;
begin
  Result := OpenJPEGCodec(Width, Height, 2, 31);
end;

procedure TFFMPEG_Writer.CloseCodec;
begin
  if VideoCodecCtx <> nil then
      avcodec_free_context(@VideoCodecCtx);

  if Frame <> nil then
      av_frame_free(@Frame);

  if AVPacket_Ptr <> nil then
      av_packet_free(@AVPacket_Ptr);

  if SWS_CTX <> nil then
      sws_freeContext(SWS_CTX);

  if FrameRGB <> nil then
      av_frame_free(@FrameRGB);

  VideoCodecCtx := nil;
  VideoCodec := nil;
  AVPacket_Ptr := nil;
  Frame := nil;
  FrameRGB := nil;
  SWS_CTX := nil;
end;

function TFFMPEG_Writer.EncodeRaster(raster: TMZR; var Updated: Integer): Boolean;
var
  r: Integer;
  tmp: TZR;
begin
  Result := False;
  if FrameRGB = nil then
      exit;
  if raster = nil then
      exit;
  if SWS_CTX = nil then
      exit;
  if Frame = nil then
      exit;
  if VideoCodecCtx = nil then
      exit;
  if AVPacket_Ptr = nil then
      exit;

  tmp := TZR.Create;
  if (raster.Width <> FLastWidth) or (raster.Height <> FLastHeight) then
      tmp.ZoomFrom(raster, FLastWidth, FLastHeight)
  else
      tmp.SetWorkMemory(raster);

  Critical.Lock;
  try
    // FrameRGB
    FrameRGB^.data[0] := @tmp.Bits^[0];
    FrameRGB^.Width := Frame^.Width;
    FrameRGB^.Height := Frame^.Height;
    FrameRGB^.linesize[0] := Frame^.Width * 4;

    // transform BGRA to YV420
    sws_scale(SWS_CTX,
      @FrameRGB^.data,
      @FrameRGB^.linesize,
      0,
      Frame^.Height,
      @Frame^.data,
      @Frame^.linesize);

    (* make sure the frame data is writable *)
    r := av_frame_make_writable(Frame);
    if r < 0 then
      begin
        DoStatus('av_frame_make_writable failed!');
        exit;
      end;

    r := avcodec_send_frame(VideoCodecCtx, Frame);
    if r < 0 then
      begin
        DoStatus('Error sending a frame for encoding');
        exit;
      end;

    // seek stream to end
    FOutput.Position := FOutput.Size;

    while r >= 0 do
      begin
        r := avcodec_receive_packet(VideoCodecCtx, AVPacket_Ptr);
        if (r = AVERROR_EAGAIN) or (r = AVERROR_EOF) then
            Break;
        if r < 0 then
          begin
            DoStatus('Error during encoding');
            exit;
          end;

        FOutput.Write(AVPacket_Ptr^.data^, AVPacket_Ptr^.Size);
        inc(Updated);
        av_packet_unref(AVPacket_Ptr);
      end;
    Result := True;
    AtomInc(Frame^.pts);
  finally
    AtomInc(FEncodeNum);
    Critical.UnLock;
    DisposeObject(tmp);
  end;
end;

function TFFMPEG_Writer.EncodeRaster(raster: TMZR): Boolean;
var
  Updated: Integer;
begin
  Updated := 0;
  Result := EncodeRaster(raster, Updated);
end;

procedure TFFMPEG_Writer.Flush;
var
  r: Integer;
begin
  Critical.Lock;
  try
    (*
      avcodec_send_frame(VideoCodecCtx, here It can be NULL), in which case it is considered a flush packet.
      This signals the end of the stream. If the encoder still has packets buffered,
      it will return them after this call.
      Once flushing mode has been entered, additional flush packets are ignored, and sending frames will return AVERROR_EOF.
    *)
    r := avcodec_send_frame(VideoCodecCtx, nil);
    if r < 0 then
      begin
        DoStatus('Error sending eof frame');
        exit;
      end;

    // seek stream to end
    FOutput.Position := FOutput.Size;

    while r >= 0 do
      begin
        r := avcodec_receive_packet(VideoCodecCtx, AVPacket_Ptr);
        if (r = AVERROR_EAGAIN) or (r = AVERROR_EOF) then
            Break;
        if r < 0 then
          begin
            DoStatus('Error during encoding');
            Break;
          end;

        FOutput.Write(AVPacket_Ptr^.data^, AVPacket_Ptr^.Size);
        av_packet_unref(AVPacket_Ptr);
      end;
    avcodec_flush_buffers(VideoCodecCtx);
  finally
      Critical.UnLock;
  end;
end;

function TFFMPEG_Writer.Size: Int64;
begin
  Result := LockOutput().Size;
  UnLockOutoput();
end;

function TFFMPEG_Writer.LockOutput: TCore_Stream;
begin
  Critical.Lock;
  Result := FOutput;
end;

procedure TFFMPEG_Writer.UnLockOutoput;
begin
  Critical.UnLock;
end;

initialization

FFMPEG_Writer_Global_Critical := TCritical.Create;

finalization

DisposeObjectAndNil(FFMPEG_Writer_Global_Critical);

end.
