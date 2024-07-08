{ ****************************************************************************** }
{ * FFMPEG Reader                                                              * }
{ ****************************************************************************** }
unit ZR.FFMPEG.Reader;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses SysUtils, Classes,
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.MemoryStream, ZR.ListEngine,
  ZR.Status,
  ZR.MemoryRaster, ZR.FFMPEG;

const
  h264_gpu_decoder = 'h264_cuvid'; // nvidia: h264_cuvid, intel: h264_qsv
  h265_gpu_decoder = 'hevc_cuvid'; // nvidia: hevc_cuvid, intel: hevc_qsv

type
  TFFMPEG_Reader = class;
  TFFMPEG_VideoStreamReader = class;

  TFFMPEG_Reader = class(TCore_Object_Intermediate)
  private
    FVideoSource: TPascalString;
    FWorkOnGPU: Boolean;
    FFormatCtx: PAVFormatContext;
    FVideoCodecCtx: PAVCodecContext;
    FAudioCodecCtx: PAVCodecContext;
    FVideoCodec: PAVCodec;
    FAudioCodec: PAVCodec;
    FFrame: PAVFrame;
    // transform FFrame
    FFrameRGB: PAVFrame;
    FFrameRGB_buffer: PByte;
    FSWS_CTX: PSwsContext;
    // transform second FFrame
    FSecond_FrameRGB: PAVFrame;
    FSecond_FrameRGB_buffer: PByte;
    FSecond_SWS_CTX: PSwsContext;
    // stream info
    VideoStreamIndex: integer;
    AudioStreamIndex: integer;
    VideoStream: PAVStream;
    // packet
    AVPacket_ptr: PAVPacket;
    // internal read-FFrame
    function NextFrame__(Stack_Num_: integer): Boolean;
    function ReadFrame__(Stack_Num_: integer; primary_output, second_output: TMZR; RasterizationCopy_: Boolean): Boolean;
  public
    Prefix_info: SystemString;
    Current: Double;
    Current_Frame: int64;
    Width, Height: integer;
    Second_Width, Second_Height: integer;
    Decoded_Memory_Size: int64;
    property VideoSource: TPascalString read FVideoSource;
    property WorkOnGPU: Boolean read FWorkOnGPU;

    constructor Create(const VideoSource_: TPascalString); overload;
    constructor Create(const VideoSource_: TPascalString; const Used_GPU_: Boolean); overload;
    constructor Create(const VideoSource_: TPascalString; const Used_GPU_: Boolean; const Codec_Param: TPascalString); overload;
    constructor Create(const Prefix_Info_, VideoSource_: TPascalString; const Used_GPU_: Boolean; const Codec_Param: TPascalString); overload;
    constructor Create(const Prefix_Info_, VideoSource_: TPascalString; const RTSP_Used_TCP_, Used_GPU_: Boolean; const Codec_Param: TPascalString); overload;
    destructor Destroy; override;

    class procedure PrintDecodec();

    procedure OpenVideo(const VideoSource_: TPascalString; RTSP_Used_TCP_, Used_GPU_: Boolean; const Codec_Param: TPascalString); overload;
    procedure OpenVideo(const VideoSource_: TPascalString; Used_GPU_: Boolean); overload;
    procedure OpenVideo(const VideoSource_: TPascalString); overload;
    procedure CloseVideo;

    procedure ResetFit(NewWidth, NewHeight: integer);
    procedure Reset_Fit_Second_Raster(New_Second_Width, New_Second_Height: integer);

    function NextFrame(): Boolean;
    function ReadFrame(primary_output: TMZR; RasterizationCopy_: Boolean): Boolean; overload;
    function ReadFrame(primary_output, second_output: TMZR; RasterizationCopy_: Boolean): Boolean; overload;

    procedure Seek(second: Double);
    function Total: Double;
    function CurrentStream_Total_Frame: int64;
    function CurrentStream_PerSecond_Frame(): Double;
    function CurrentStream_PerSecond_FrameRound(): integer;
    property PSF: Double read CurrentStream_PerSecond_Frame;
    property PSFRound: integer read CurrentStream_PerSecond_FrameRound;
    property RoundPSF: integer read CurrentStream_PerSecond_FrameRound;
    property PSF_I: integer read CurrentStream_PerSecond_FrameRound;
    property VideoCodec: PAVCodec read FVideoCodec;
  end;

  TOnWrite_Buffer_Before = procedure(Sender: TFFMPEG_VideoStreamReader; var p: Pointer; var siz: NativeUInt) of object;
  TOnWrite_Buffer_After = procedure(Sender: TFFMPEG_VideoStreamReader; p: Pointer; siz: NativeUInt; Decoded_Num: integer) of object;
  TOnVideo_Build_New_Raster = procedure(Sender: TFFMPEG_VideoStreamReader; Raster: TMZR; var Save_To_Pool: Boolean) of object;

  TFFMPEG_VideoStreamReader = class(TCore_Object_Intermediate)
  private
    FVideoCodecCtx: PAVCodecContext;
    FVideoCodec: PAVCodec;
    FAVParser: PAVCodecParserContext;
    FAVPacket_ptr: PAVPacket;
    FFrame, FFrameRGB: PAVFrame;
    FFrameRGB_buffer: PByte;
    FSWS_CTX: PSwsContext;
    FSwapBuff: TMS64;
    FSerialized_Tool: TZRSerialized;
    FAuto_Write_Serialized: Boolean;
    FVideoRasterPool: TMR_List;
    procedure Set_Serialized_Tool(const Value: TZRSerialized);
    procedure Set_Auto_Write_Serialized(const Value: Boolean);
  protected
    procedure DoWrite_Buffer_Before(var p: Pointer; var siz: NativeUInt); virtual;
    procedure DoVideo_Build_New_Raster(Raster: TMZR; var Save_To_Pool: Boolean); virtual;
    procedure DoWrite_Buffer_After(p: Pointer; siz: NativeUInt; Decoded_Num: integer); virtual;
    procedure InternalOpenDecodec(const codec: PAVCodec; const Codec_Param: U_String);
  public
    Critical: TCritical;
    Decoded_Memory_Size: int64;
    Last_Codec_Param: U_String;
    OnWrite_Buffer_Before: TOnWrite_Buffer_Before;
    OnVideo_Build_New_Raster: TOnVideo_Build_New_Raster;
    OnWrite_Buffer_After: TOnWrite_Buffer_After;

    constructor Create;
    destructor Destroy; override;

    // rasterization serialized.
    property Serialized: TZRSerialized read FSerialized_Tool write Set_Serialized_Tool;
    property Serialized_Tool: TZRSerialized read FSerialized_Tool write Set_Serialized_Tool;
    property Auto_Write_Serialized: Boolean read FAuto_Write_Serialized write Set_Auto_Write_Serialized;

    class procedure PrintDecodec();

    procedure OpenDecodec(const codec_name: U_String); overload;
    procedure OpenDecodec(const codec_name, Codec_Param: U_String); overload;
    procedure OpenDecodec(const codec_id: TAVCodecID); overload;
    procedure OpenDecodec(const codec_id: TAVCodecID; const Codec_Param: U_String); overload;
    procedure OpenDecodec(); overload; // default decodec:AV_CODEC_ID_H264
    procedure OpenH265Decodec();
    procedure OpenH264Decodec();
    procedure OpenMJPEGDecodec();
    procedure CloseCodec;

    // parser and decode FFrame
    // return decode FFrame number on this step
    function WriteBuffer(p: Pointer; siz: NativeUInt): integer; overload;
    function WriteBuffer(stream_: TCore_Stream): integer; overload;

    function DecodedRasterNum: integer;
    function LockVideoPool: TMR_List;
    procedure UnLockVideoPool(freeRaster_: Boolean); overload;
    procedure UnLockVideoPool(); overload;
    procedure ClearVideoPool;
  end;

function ExtractVideoAsPasH264(VideoSource_: TPascalString; dest: TCore_Stream): integer; overload; // pascal native h264
function ExtractVideoAsPasH264(VideoSource_, DestH264: TPascalString): integer; overload; // pascal native h264

// hardware h264
function ExtractVideoAsH264(VideoSource_: TPascalString; dest: TCore_Stream; Bitrate: int64): integer; overload;
function ExtractVideoAsH264(VideoSource_: TPascalString; DestH264: TPascalString; Bitrate: int64): integer; overload;

var
  // Buffer size used for online video(rtsp/rtmp/http/https), 720p 1080p 2K 4K 8K support
  FFMPEG_Reader_BufferSize: integer;

implementation

uses ZR.h264, ZR.FFMPEG.Writer, ZR.Geometry2D;

function ExtractVideoAsPasH264(VideoSource_: TPascalString; dest: TCore_Stream): integer;
var
  ff: TFFMPEG_Reader;
  h: TH264Writer;
  Raster: TMZR;
  tk: TTimeTick;
begin
  DoStatus('FFMPEG open ', [VideoSource_.Text]);
  try
    ff := TFFMPEG_Reader.Create(VideoSource_);
    DoStatus('create h264 stream %d*%d total: %d', [ff.Width, ff.Height, ff.CurrentStream_Total_Frame]);
  except
    Result := 0;
    exit;
  end;
  h := TH264Writer.Create(ff.Width, ff.Height, ff.CurrentStream_Total_Frame, ff.CurrentStream_PerSecond_Frame, dest);
  Raster := TMZR.Create;
  tk := GetTimeTick();
  while ff.ReadFrame(Raster, False) do
    begin
      h.WriteFrame(Raster);
      if GetTimeTick() - tk > 2000 then
        begin
          DoStatus('%s -> h264.stream progress %d/%d', [umlGetFileName(VideoSource_).Text, h.FrameCount, ff.CurrentStream_Total_Frame]);
          h.Flush;
          tk := GetTimeTick();
        end;
    end;
  Result := h.FrameCount;
  disposeObject(ff);
  disposeObject(h);
  DoStatus('done %s -> h264 stream.', [umlGetFileName(VideoSource_).Text]);
end;

function ExtractVideoAsPasH264(VideoSource_, DestH264: TPascalString): integer;
var
  ff: TFFMPEG_Reader;
  h: TH264Writer;
  Raster: TMZR;
  tk: TTimeTick;
begin
  DoStatus('FFMPEG open ', [VideoSource_.Text]);
  try
    ff := TFFMPEG_Reader.Create(VideoSource_);
    DoStatus('create h264 stream %d*%d total: %d', [ff.Width, ff.Height, ff.CurrentStream_Total_Frame]);
  except
    Result := 0;
    exit;
  end;
  h := TH264Writer.Create(ff.Width, ff.Height, ff.CurrentStream_Total_Frame, ff.CurrentStream_PerSecond_Frame, DestH264);
  Raster := TMZR.Create;
  tk := GetTimeTick();
  while ff.ReadFrame(Raster, False) do
    begin
      h.WriteFrame(Raster);
      if GetTimeTick() - tk > 2000 then
        begin
          DoStatus('%s -> %s progress %d/%d', [umlGetFileName(VideoSource_).Text, umlGetFileName(DestH264).Text, h.FrameCount, ff.CurrentStream_Total_Frame]);
          h.Flush;
          tk := GetTimeTick();
        end;
    end;
  Result := h.FrameCount;
  disposeObject(ff);
  disposeObject(h);
  DoStatus('done %s -> %s', [umlGetFileName(VideoSource_).Text, umlGetFileName(DestH264).Text]);
end;

function ExtractVideoAsH264(VideoSource_: TPascalString; dest: TCore_Stream; Bitrate: int64): integer;
var
  ff: TFFMPEG_Reader;
  h: TFFMPEG_Writer;
  Raster: TMZR;
  tk: TTimeTick;
begin
  Result := 0;
  DoStatus('FFMPEG open ', [VideoSource_.Text]);
  try
    ff := TFFMPEG_Reader.Create(VideoSource_);
    DoStatus('create h264 stream %d*%d total: %d', [ff.Width, ff.Height, ff.CurrentStream_Total_Frame]);
  except
      exit;
  end;
  h := TFFMPEG_Writer.Create(dest);
  if h.OpenH264Codec(ff.Width, ff.Height, Round(ff.CurrentStream_PerSecond_Frame), Bitrate) then
    begin
      Raster := TMZR.Create;
      tk := GetTimeTick();
      while ff.ReadFrame(Raster, False) do
        begin
          h.EncodeRaster(Raster);
          if GetTimeTick() - tk > 2000 then
            begin
              DoStatus('%s -> h264.stream progress %d/%d', [umlGetFileName(VideoSource_).Text, Result, ff.CurrentStream_Total_Frame]);
              h.Flush;
              tk := GetTimeTick();
            end;
          inc(Result);
        end;
      disposeObject(Raster);
    end;
  disposeObject(ff);
  disposeObject(h);
  DoStatus('done %s -> h264 stream.', [umlGetFileName(VideoSource_).Text]);
end;

function ExtractVideoAsH264(VideoSource_: TPascalString; DestH264: TPascalString; Bitrate: int64): integer;
var
  fs: TCore_FileStream;
begin
  try
    fs := TCore_FileStream.Create(DestH264, fmCreate);
    Result := ExtractVideoAsH264(VideoSource_, fs, Bitrate);
    disposeObject(fs);
  except
      Result := 0;
  end;
end;

function TFFMPEG_Reader.NextFrame__(Stack_Num_: integer): Boolean;
var
  done: Boolean;
  R: integer;
begin
  Result := False;
  if Stack_Num_ > 20 then
    begin
      DoStatus(Prefix_info + 'multiple repair runs failed');
      exit;
    end;
  done := False;
  try
    while (av_read_frame(FFormatCtx, AVPacket_ptr) >= 0) do
      begin
        if (AVPacket_ptr^.stream_index = VideoStreamIndex) then
          begin
            R := avcodec_send_packet(FVideoCodecCtx, AVPacket_ptr);
            if R < 0 then
              begin
                DoStatus(Prefix_info + 'Error sending a packet for decoding: %s, System startup repair operation mode.', [av_err2str(R)]);
                Result := NextFrame__(Stack_Num_ + 1);
                exit;
              end;

            done := False;
            while True do
              begin
                R := avcodec_receive_frame(FVideoCodecCtx, FFrame);

                // success, a FFrame was returned
                if R = 0 then
                  begin
                    AtomInc(Decoded_Memory_Size, Width * Height * 4);
                    break;
                  end;

                // AVERROR(EAGAIN): output is not available in this state - user must try to send new input
                if R = AVERROR_EAGAIN then
                  begin
                    av_packet_unref(AVPacket_ptr);
                    Result := NextFrame__(Stack_Num_);
                    exit;
                  end;

                // AVERROR_EOF: the decoder has been fully flushed, and there will be no more output frames
                if R = AVERROR_EOF then
                  begin
                    avcodec_flush_buffers(FVideoCodecCtx);
                    continue;
                  end;

                // error
                if R < 0 then
                  begin
                    DoStatus(Prefix_info + 'Error receive a packet for decoding: %s, System startup repair operation mode.', [av_err2str(R)]);
                    Result := NextFrame__(Stack_Num_ + 1);
                    exit;
                  end;
              end;

            if (not done) then
                inc(Current_Frame);
            Result := True;
            done := True;
          end;

        av_packet_unref(AVPacket_ptr);
        if done then
            break;
      end;
  except
  end;
end;

function TFFMPEG_Reader.ReadFrame__(Stack_Num_: integer; primary_output, second_output: TMZR; RasterizationCopy_: Boolean): Boolean;
var
  done: Boolean;
  R: integer;
begin
  Result := False;
  if Stack_Num_ > 20 then
    begin
      DoStatus(Prefix_info + 'multiple repair runs failed');
      exit;
    end;
  done := False;
  try
    while (av_read_frame(FFormatCtx, AVPacket_ptr) >= 0) do
      begin
        if (AVPacket_ptr^.stream_index = VideoStreamIndex) then
          begin
            R := avcodec_send_packet(FVideoCodecCtx, AVPacket_ptr);
            if R < 0 then
              begin
                DoStatus(Prefix_info + 'Error sending a packet for decoding: %s, System startup repair operation mode.', [av_err2str(R)]);
                Result := ReadFrame__(Stack_Num_ + 1, primary_output, second_output, RasterizationCopy_);
                exit;
              end;

            done := False;
            while True do
              begin
                R := avcodec_receive_frame(FVideoCodecCtx, FFrame);

                // success, a FFrame was returned
                if R = 0 then
                  begin
                    AtomInc(Decoded_Memory_Size, Width * Height * 4);
                    break;
                  end;

                // AVERROR(EAGAIN): output is not available in this state - user must try to send new input
                if R = AVERROR_EAGAIN then
                  begin
                    av_packet_unref(AVPacket_ptr);
                    Result := ReadFrame__(Stack_Num_, primary_output, second_output, RasterizationCopy_);
                    exit;
                  end;

                // AVERROR_EOF: the decoder has been fully flushed, and there will be no more output frames
                if R = AVERROR_EOF then
                  begin
                    avcodec_flush_buffers(FVideoCodecCtx);
                    continue;
                  end;

                // error
                if R < 0 then
                  begin
                    DoStatus(Prefix_info + 'Error receive a packet for decoding: %s, System startup repair operation mode.', [av_err2str(R)]);
                    Result := ReadFrame__(Stack_Num_ + 1, primary_output, second_output, RasterizationCopy_);
                    exit;
                  end;
              end;

            if (not done) then
              begin
                sws_scale(
                  FSWS_CTX,
                  @FFrame^.data,
                  @FFrame^.linesize,
                  0,
                  FVideoCodecCtx^.Height,
                  @FFrameRGB^.data,
                  @FFrameRGB^.linesize);

                if primary_output <> nil then
                  begin
                    if RasterizationCopy_ then
                      begin
                        primary_output.SetSize(Width, Height);
                        CopyPtr(FFrameRGB^.data[0], @primary_output.Bits^[0], Width * Height * 4);
                      end
                    else
                      begin
                        primary_output.SetWorkMemory(FFrameRGB^.data[0], Width, Height);
                      end;
                  end;

                if (second_output <> nil) and (FSecond_SWS_CTX <> nil) and (FSecond_FrameRGB <> nil) and (FSecond_FrameRGB_buffer <> nil) then
                  begin
                    sws_scale(
                      FSecond_SWS_CTX,
                      @FFrameRGB^.data,
                      @FFrameRGB^.linesize,
                      0,
                      Height,
                      @FSecond_FrameRGB^.data,
                      @FSecond_FrameRGB^.linesize);

                    if RasterizationCopy_ then
                      begin
                        second_output.SetSize(Second_Width, Second_Height);
                        CopyPtr(FSecond_FrameRGB^.data[0], @second_output.Bits^[0], Second_Width * Second_Height * 4);
                      end
                    else
                      begin
                        second_output.SetWorkMemory(FFrameRGB^.data[0], Second_Width, Second_Height);
                      end;
                  end
                else if (second_output <> nil) and (primary_output <> nil) then
                  begin
                    second_output.SetWorkMemory(primary_output);
                  end;

                if (AVPacket_ptr^.pts > 0) and (av_q2d(VideoStream^.time_base) > 0) then
                    Current := AVPacket_ptr^.pts * av_q2d(VideoStream^.time_base);

                done := True;
                inc(Current_Frame);
              end;
            Result := True;
          end;

        av_packet_unref(AVPacket_ptr);
        if done then
            exit;
      end;
  except
  end;
  primary_output.Reset;
end;

constructor TFFMPEG_Reader.Create(const VideoSource_: TPascalString);
begin
  inherited Create;
  Prefix_info := VideoSource_;
  OpenVideo(VideoSource_);
end;

constructor TFFMPEG_Reader.Create(const VideoSource_: TPascalString; const Used_GPU_: Boolean);
begin
  inherited Create;
  Prefix_info := VideoSource_;
  OpenVideo(VideoSource_, Used_GPU_);
end;

constructor TFFMPEG_Reader.Create(const VideoSource_: TPascalString; const Used_GPU_: Boolean; const Codec_Param: TPascalString);
begin
  inherited Create;
  Prefix_info := VideoSource_;
  OpenVideo(VideoSource_, True, Used_GPU_, Codec_Param);
end;

constructor TFFMPEG_Reader.Create(const Prefix_Info_, VideoSource_: TPascalString; const Used_GPU_: Boolean; const Codec_Param: TPascalString);
begin
  inherited Create;
  Prefix_info := Prefix_Info_;
  OpenVideo(VideoSource_, True, Used_GPU_, Codec_Param);
end;

constructor TFFMPEG_Reader.Create(const Prefix_Info_, VideoSource_: TPascalString; const RTSP_Used_TCP_, Used_GPU_: Boolean; const Codec_Param: TPascalString);
begin
  inherited Create;
  Prefix_info := Prefix_Info_;
  OpenVideo(VideoSource_, RTSP_Used_TCP_, Used_GPU_, Codec_Param);
end;

destructor TFFMPEG_Reader.Destroy;
begin
  CloseVideo;
  inherited Destroy;
end;

class procedure TFFMPEG_Reader.PrintDecodec;
var
  codec: PAVCodec;
begin
  codec := av_codec_next(nil);
  while codec <> nil do
    begin
      if av_codec_is_decoder(codec) = 1 then
          DoStatus('ID[%d] Name[%s] %s', [integer(codec^.id), string(codec^.name), string(codec^.long_name)]);
      codec := av_codec_next(codec);
    end;
end;

procedure TFFMPEG_Reader.OpenVideo(const VideoSource_: TPascalString; RTSP_Used_TCP_, Used_GPU_: Boolean; const Codec_Param: TPascalString);
var
  gpu_decodec: PAVCodec;
  AV_Options: PPAVDictionary;
  Codec_Options: PPAVDictionary;
  tmp: Pointer;
  i: integer;
  hList: THashStringList;
  av_st: PPAVStream;
  p: Pointer;
  NumByte: integer;
{$IFDEF FPC}
  procedure do_fpc_progress(Sender: THashStringList; Name_: PSystemString; const V: SystemString);
  var
    p1_, p2_: Pointer;
  begin
    p1_ := TPascalString(Name_^).BuildPlatformPChar;
    p2_ := TPascalString(V).BuildPlatformPChar;
    av_dict_set(@Codec_Options, p1_, p2_, 0);
    TPascalString.FreePlatformPChar(p1_);
    TPascalString.FreePlatformPChar(p2_);
  end;
{$ENDIF FPC}


begin
  FVideoSource := VideoSource_;
  FWorkOnGPU := False;

  AV_Options := nil;
  FFormatCtx := nil;
  FVideoCodecCtx := nil;
  FAudioCodecCtx := nil;
  FVideoCodec := nil;
  FAudioCodec := nil;
  AVPacket_ptr := nil;
  FFrame := nil;

  // transform FFrame
  FFrameRGB := nil;
  FFrameRGB_buffer := nil;
  FSWS_CTX := nil;

  // transform second FFrame
  FSecond_FrameRGB := nil;
  FSecond_FrameRGB_buffer := nil;
  FSecond_SWS_CTX := nil;
  Second_Width := 0;
  Second_Height := 0;

  Decoded_Memory_Size := 0;

  p := VideoSource_.BuildPlatformPChar;

  // Open video source
  try
    tmp := TPascalString(IntToStr(FFMPEG_Reader_BufferSize)).BuildPlatformPChar;
    av_dict_set(@AV_Options, 'buffer_size', tmp, 0);
    TPascalString.FreePlatformPChar(tmp);
    av_dict_set(@AV_Options, 'stimeout', '6000000', 0);
    av_dict_set(@AV_Options, 'max_delay', '50000000', 0);
    av_dict_set(@AV_Options, 'thread_queue_size', '1024', 0);
    if RTSP_Used_TCP_ then
      begin
        av_dict_set(@AV_Options, 'rtsp_flags', '+prefer_tcp', 0);
        av_dict_set(@AV_Options, 'rtsp_transport', '+tcp', 0);
      end
    else
      begin
        av_dict_set(@AV_Options, 'rtsp_transport', 'udp', 0);
        av_dict_set(@AV_Options, 'min_port', '8000', 0);
        av_dict_set(@AV_Options, 'max_port', '20000', 0);
      end;

    if (avformat_open_input(@FFormatCtx, PAnsiChar(p), nil, @AV_Options) <> 0) then
      begin
        RaiseInfo(Prefix_info + 'Could not open source %s', [VideoSource_.Text]);
        exit;
      end;

    // Retrieve stream information
    if avformat_find_stream_info(FFormatCtx, nil) < 0 then
      begin
        if FFormatCtx <> nil then
            avformat_close_input(@FFormatCtx);

        RaiseInfo(Prefix_info + 'Could not find stream information %s', [VideoSource_.Text]);
        exit;
      end;

    if IsConsole then
        av_dump_format(FFormatCtx, 0, PAnsiChar(p), 0);

    VideoStreamIndex := -1;
    AudioStreamIndex := -1;
    VideoStream := nil;
    av_st := FFormatCtx^.streams;
    for i := 0 to FFormatCtx^.nb_streams - 1 do
      begin
        if av_st^^.codec^.codec_type = AVMEDIA_TYPE_VIDEO then
          begin
            VideoStreamIndex := av_st^^.index;
            FVideoCodecCtx := av_st^^.codec;
            VideoStream := av_st^;
          end
        else if av_st^^.codec^.codec_type = AVMEDIA_TYPE_AUDIO then
          begin
            AudioStreamIndex := av_st^^.index;
            FAudioCodecCtx := av_st^^.codec;
          end;
        inc(av_st);
      end;

    if VideoStreamIndex = -1 then
      begin
        RaiseInfo(Prefix_info + 'Dont find a video stream');
        exit;
      end;

    FVideoCodec := avcodec_find_decoder(FVideoCodecCtx^.codec_id);
    if FVideoCodec = nil then
      begin
        RaiseInfo(Prefix_info + 'Unsupported FVideoCodec!');
        exit;
      end;

    if (Used_GPU_) and (CurrentPlatform in [epWin32, epWin64]) and (FVideoCodecCtx^.codec_id in [AV_CODEC_ID_H264, AV_CODEC_ID_HEVC]) then
      begin
        gpu_decodec := nil;
        if FVideoCodecCtx^.codec_id = AV_CODEC_ID_H264 then
            gpu_decodec := avcodec_find_decoder_by_name(h264_gpu_decoder)
        else if FVideoCodecCtx^.codec_id = AV_CODEC_ID_HEVC then
            gpu_decodec := avcodec_find_decoder_by_name(h265_gpu_decoder);

        Codec_Options := nil;
        if Codec_Param <> '' then
          begin
            // custom parameter
            hList := THashStringList.Create;
            hList.AsText := Codec_Param;
{$IFDEF FPC}
            hList.ProgressP(do_fpc_progress);
{$ELSE FPC}
            hList.ProgressP(procedure(Sender: THashStringList; Name_: PSystemString; const V: SystemString)
              var
                p1_, p2_: Pointer;
              begin
                p1_ := TPascalString(Name_^).BuildPlatformPChar;
                p2_ := TPascalString(V).BuildPlatformPChar;
                av_dict_set(@Codec_Options, p1_, p2_, 0);
                TPascalString.FreePlatformPChar(p1_);
                TPascalString.FreePlatformPChar(p2_);
              end);
{$ENDIF FPC}
            disposeObject(hList);
          end;

        if (avcodec_open2(FVideoCodecCtx, gpu_decodec, @Codec_Options) < 0) then // gpu decoder
          begin
            if avcodec_open2(FVideoCodecCtx, FVideoCodec, nil) < 0 then // cpu decoder
              begin
                RaiseInfo(Prefix_info + 'Could not open FVideoCodec');
                exit;
              end;
          end
        else
          begin
            FVideoCodec := gpu_decodec;
            FWorkOnGPU := True;
          end;
      end
    else
      begin
        if avcodec_open2(FVideoCodecCtx, FVideoCodec, nil) < 0 then // cpu decoder
          begin
            RaiseInfo(Prefix_info + 'Could not open FVideoCodec');
            exit;
          end;
      end;

    if AudioStreamIndex >= 0 then
      begin
        FAudioCodec := avcodec_find_decoder(FAudioCodecCtx^.codec_id);
        if FAudioCodec <> nil then
            avcodec_open2(FAudioCodecCtx, FAudioCodec, nil);
      end;

    Width := FVideoCodecCtx^.Width;
    Height := FVideoCodecCtx^.Height;
    Second_Width := 0;
    Second_Height := 0;

    FFrame := av_frame_alloc();
    FFrameRGB := av_frame_alloc();
    if (FFrameRGB = nil) or (FFrame = nil) then
        RaiseInfo(Prefix_info + 'Could not allocate AVFrame structure');
    NumByte := avpicture_get_size(AV_PIX_FMT_BGRA, Width, Height);
    FFrameRGB_buffer := av_malloc(NumByte * 4);
    FSWS_CTX := sws_getContext(FVideoCodecCtx^.Width, FVideoCodecCtx^.Height,
      FVideoCodecCtx^.pix_fmt,
      Width,
      Height,
      AV_PIX_FMT_BGRA,
      SWS_BILINEAR,
      nil,
      nil,
      nil);
    avpicture_fill(PAVPicture(FFrameRGB), FFrameRGB_buffer, AV_PIX_FMT_BGRA, Width, Height);

    AVPacket_ptr := av_packet_alloc();

    Current := 0;
    Current_Frame := 0;
  finally
      TPascalString.FreePlatformPChar(p);
  end;
end;

procedure TFFMPEG_Reader.OpenVideo(const VideoSource_: TPascalString; Used_GPU_: Boolean);
begin
  OpenVideo(VideoSource_, True, Used_GPU_, '');
end;

procedure TFFMPEG_Reader.OpenVideo(const VideoSource_: TPascalString);
begin
  OpenVideo(VideoSource_, False);
end;

procedure TFFMPEG_Reader.CloseVideo;
begin
  if AVPacket_ptr <> nil then
      av_free_packet(AVPacket_ptr);
  if FVideoCodecCtx <> nil then
      avcodec_close(FVideoCodecCtx);
  if FAudioCodecCtx <> nil then
      avcodec_close(FAudioCodecCtx);
  if FFormatCtx <> nil then
      avformat_close_input(@FFormatCtx);
  if FFrame <> nil then
      av_free(FFrame);

  // transform FFrame
  if FFrameRGB_buffer <> nil then
      av_free(FFrameRGB_buffer);
  if FFrameRGB <> nil then
      av_free(FFrameRGB);
  if FSWS_CTX <> nil then
      sws_freeContext(FSWS_CTX);

  // transform second FFrame
  if FSecond_FrameRGB_buffer <> nil then
      av_free(FSecond_FrameRGB_buffer);
  if FSecond_FrameRGB <> nil then
      av_free(FSecond_FrameRGB);
  if FSecond_SWS_CTX <> nil then
      sws_freeContext(FSecond_SWS_CTX);

  FFormatCtx := nil;
  FVideoCodecCtx := nil;
  FAudioCodecCtx := nil;
  FVideoCodec := nil;
  FAudioCodec := nil;
  FFrame := nil;
  AVPacket_ptr := nil;

  // transform FFrame
  FFrameRGB := nil;
  FFrameRGB_buffer := nil;
  FSWS_CTX := nil;

  // transform second FFrame
  FSecond_FrameRGB_buffer := nil;
  FSecond_FrameRGB := nil;
  FSecond_SWS_CTX := nil;
  Second_Width := 0;
  Second_Height := 0;

  Decoded_Memory_Size := 0;
end;

procedure TFFMPEG_Reader.ResetFit(NewWidth, NewHeight: integer);
var
  NumByte: integer;
  R: TRectV2;
begin
  // free transform FFrame
  if FFrameRGB_buffer <> nil then
      av_free(FFrameRGB_buffer);
  FFrameRGB_buffer := nil;
  if FFrameRGB <> nil then
      av_free(FFrameRGB);
  FFrameRGB := nil;
  if FSWS_CTX <> nil then
      sws_freeContext(FSWS_CTX);
  FSWS_CTX := nil;

  // realloc transform FFrame
  R := FitRect(FVideoCodecCtx^.Width, FVideoCodecCtx^.Height, RectV2(0, 0, NewWidth, NewHeight));
  Width := RoundWidth(R);
  Height := RoundHeight(R);
  FFrameRGB := av_frame_alloc();
  if (FFrameRGB = nil) then
      RaiseInfo(Prefix_info + 'Could not allocate AVFrame structure');
  NumByte := avpicture_get_size(AV_PIX_FMT_BGRA, Width, Height);
  FFrameRGB_buffer := av_malloc(NumByte * 4);
  FSWS_CTX := sws_getContext(FVideoCodecCtx^.Width, FVideoCodecCtx^.Height,
    FVideoCodecCtx^.pix_fmt,
    Width,
    Height,
    AV_PIX_FMT_BGRA,
    SWS_BILINEAR,
    nil,
    nil,
    nil);
  avpicture_fill(PAVPicture(FFrameRGB), FFrameRGB_buffer, AV_PIX_FMT_BGRA, Width, Height);
end;

procedure TFFMPEG_Reader.Reset_Fit_Second_Raster(New_Second_Width, New_Second_Height: integer);
var
  NumByte: integer;
  R: TRectV2;
begin
  // free transform FFrame
  if FSecond_FrameRGB_buffer <> nil then
      av_free(FSecond_FrameRGB_buffer);
  FSecond_FrameRGB_buffer := nil;
  if FSecond_FrameRGB <> nil then
      av_free(FSecond_FrameRGB);
  FSecond_FrameRGB := nil;
  if FSecond_SWS_CTX <> nil then
      sws_freeContext(FSecond_SWS_CTX);
  FSecond_SWS_CTX := nil;

  // realloc transform FFrame
  R := FitRect(Width, Height, RectV2(0, 0, New_Second_Width, New_Second_Height));
  Second_Width := RoundWidth(R);
  Second_Height := RoundHeight(R);
  FSecond_FrameRGB := av_frame_alloc();
  if (FSecond_FrameRGB = nil) then
      RaiseInfo(Prefix_info + 'Could not allocate AVFrame structure');
  NumByte := avpicture_get_size(AV_PIX_FMT_BGRA, Second_Width, Second_Height);
  FSecond_FrameRGB_buffer := av_malloc(NumByte * 4);
  FSecond_SWS_CTX := sws_getContext(Width, Height,
    AV_PIX_FMT_BGRA,
    Second_Width,
    Second_Height,
    AV_PIX_FMT_BGRA,
    SWS_BILINEAR,
    nil,
    nil,
    nil);
  avpicture_fill(PAVPicture(FSecond_FrameRGB), FSecond_FrameRGB_buffer, AV_PIX_FMT_BGRA, Second_Width, Second_Height);
end;

function TFFMPEG_Reader.NextFrame(): Boolean;
begin
  try
      Result := NextFrame__(0);
  except
      Result := False;
  end;
end;

function TFFMPEG_Reader.ReadFrame(primary_output: TMZR; RasterizationCopy_: Boolean): Boolean;
begin
  try
      Result := ReadFrame__(0, primary_output, nil, RasterizationCopy_);
  except
      Result := False;
  end;
end;

function TFFMPEG_Reader.ReadFrame(primary_output, second_output: TMZR; RasterizationCopy_: Boolean): Boolean;
begin
  try
      Result := ReadFrame__(0, primary_output, second_output, RasterizationCopy_);
  except
      Result := False;
  end;
end;

procedure TFFMPEG_Reader.Seek(second: Double);
begin
  if second = 0 then
    begin
      CloseVideo;
      OpenVideo(FVideoSource, FWorkOnGPU);
    end
  else
      av_seek_frame(FFormatCtx, -1, Round(second * AV_TIME_BASE), AVSEEK_FLAG_ANY);
end;

function TFFMPEG_Reader.Total: Double;
begin
  Result := umlMax(FFormatCtx^.duration / AV_TIME_BASE, 0);
end;

function TFFMPEG_Reader.CurrentStream_Total_Frame: int64;
begin
  Result := umlMax(VideoStream^.nb_frames, 0);
end;

function TFFMPEG_Reader.CurrentStream_PerSecond_Frame(): Double;
begin
  with VideoStream^.r_frame_rate do
      Result := umlMax(num / den, 0);
end;

function TFFMPEG_Reader.CurrentStream_PerSecond_FrameRound(): integer;
begin
  Result := Round(CurrentStream_PerSecond_Frame());
end;

procedure TFFMPEG_VideoStreamReader.Set_Serialized_Tool(const Value: TZRSerialized);
begin
  Critical.Lock;
  FSerialized_Tool := Value;
  Critical.UnLock;
end;

procedure TFFMPEG_VideoStreamReader.Set_Auto_Write_Serialized(const Value: Boolean);
begin
  Critical.Lock;
  FAuto_Write_Serialized := Value;
  Critical.UnLock;
end;

procedure TFFMPEG_VideoStreamReader.DoWrite_Buffer_Before(var p: Pointer; var siz: NativeUInt);
begin
  if assigned(OnWrite_Buffer_Before) then
      OnWrite_Buffer_Before(Self, p, siz);
end;

procedure TFFMPEG_VideoStreamReader.DoVideo_Build_New_Raster(Raster: TMZR; var Save_To_Pool: Boolean);
begin
  if assigned(OnVideo_Build_New_Raster) then
      OnVideo_Build_New_Raster(Self, Raster, Save_To_Pool);
end;

procedure TFFMPEG_VideoStreamReader.DoWrite_Buffer_After(p: Pointer; siz: NativeUInt; Decoded_Num: integer);
begin
  if assigned(OnWrite_Buffer_After) then
      OnWrite_Buffer_After(Self, p, siz, Decoded_Num);
end;

procedure TFFMPEG_VideoStreamReader.InternalOpenDecodec(const codec: PAVCodec; const Codec_Param: U_String);
var
  tmp: Pointer;
  AV_Options: PPAVDictionary;
  hList: THashStringList;
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
  FVideoCodec := codec;
  Last_Codec_Param := Codec_Param;

  if FVideoCodec = nil then
      RaiseInfo('no found decoder', []);

  FAVParser := av_parser_init(Ord(FVideoCodec^.id));
  if not assigned(FAVParser) then
      RaiseInfo('Parser not found');

  FVideoCodecCtx := avcodec_alloc_context3(FVideoCodec);
  if not assigned(FVideoCodecCtx) then
      RaiseInfo('Could not allocate video Codec context');

  AV_Options := nil;
  tmp := TPascalString(IntToStr(FFMPEG_Reader_BufferSize)).BuildPlatformPChar;
  av_dict_set(@AV_Options, 'buffer_size', tmp, 0);
  TPascalString.FreePlatformPChar(tmp);

  if Codec_Param <> '' then
    begin
      // custom parameter
      hList := THashStringList.Create;
      hList.AsText := Codec_Param;
{$IFDEF FPC}
      hList.ProgressP(do_fpc_progress);
{$ELSE FPC}
      hList.ProgressP(procedure(Sender: THashStringList; Name_: PSystemString; const V: SystemString)
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
      disposeObject(hList);
    end;

  if avcodec_open2(FVideoCodecCtx, FVideoCodec, @AV_Options) < 0 then
      RaiseInfo('Could not open Codec.');

  FAVPacket_ptr := av_packet_alloc();
  FFrame := av_frame_alloc();
end;

constructor TFFMPEG_VideoStreamReader.Create;
begin
  inherited Create;
  FVideoCodecCtx := nil;
  FVideoCodec := nil;
  FAVParser := nil;
  FAVPacket_ptr := nil;
  FFrame := nil;
  FFrameRGB := nil;
  FFrameRGB_buffer := nil;
  FSWS_CTX := nil;

  FSwapBuff := TMS64.CustomCreate(128 * 1024);
  FSerialized_Tool := nil;
  FAuto_Write_Serialized := False;
  FVideoRasterPool := TMR_List.Create;

  Critical := TCritical.Create;
  Decoded_Memory_Size := 0;
  Last_Codec_Param := '';
  OnWrite_Buffer_Before := nil;
  OnVideo_Build_New_Raster := nil;
  OnWrite_Buffer_After := nil;
end;

destructor TFFMPEG_VideoStreamReader.Destroy;
begin
  CloseCodec();
  disposeObject(FSwapBuff);

  ClearVideoPool();
  disposeObject(FVideoRasterPool);
  disposeObject(Critical);
  inherited Destroy;
end;

class procedure TFFMPEG_VideoStreamReader.PrintDecodec;
var
  codec: PAVCodec;
begin
  codec := av_codec_next(nil);
  while codec <> nil do
    begin
      if av_codec_is_decoder(codec) = 1 then
          DoStatus('ID[%d] Name[%s] %s', [integer(codec^.id), string(codec^.name), string(codec^.long_name)]);
      codec := av_codec_next(codec);
    end;
end;

procedure TFFMPEG_VideoStreamReader.OpenDecodec(const codec_name: U_String);
begin
  OpenDecodec(codec_name, '');
end;

procedure TFFMPEG_VideoStreamReader.OpenDecodec(const codec_name, Codec_Param: U_String);
var
  tmp: Pointer;
  codec: PAVCodec;
begin
  tmp := codec_name.BuildPlatformPChar();
  codec := avcodec_find_decoder_by_name(tmp);
  U_String.FreePlatformPChar(tmp);

  if codec = nil then
      RaiseInfo('no found decoder: %s', [codec_name.Text]);

  InternalOpenDecodec(codec, Codec_Param);
end;

procedure TFFMPEG_VideoStreamReader.OpenDecodec(const codec_id: TAVCodecID);
begin
  InternalOpenDecodec(avcodec_find_decoder(codec_id), '');
end;

procedure TFFMPEG_VideoStreamReader.OpenDecodec(const codec_id: TAVCodecID; const Codec_Param: U_String);
begin
  InternalOpenDecodec(avcodec_find_decoder(codec_id), Codec_Param);
end;

procedure TFFMPEG_VideoStreamReader.OpenDecodec();
begin
  OpenDecodec(AV_CODEC_ID_H264);
end;

procedure TFFMPEG_VideoStreamReader.OpenH265Decodec();
begin
  OpenDecodec(AV_CODEC_ID_H265);
end;

procedure TFFMPEG_VideoStreamReader.OpenH264Decodec();
begin
  OpenDecodec(AV_CODEC_ID_H264);
end;

procedure TFFMPEG_VideoStreamReader.OpenMJPEGDecodec;
begin
  OpenDecodec(AV_CODEC_ID_MJPEG);
end;

procedure TFFMPEG_VideoStreamReader.CloseCodec;
begin
  Critical.Lock;
  try
    if FAVParser <> nil then
        av_parser_close(FAVParser);
    if FVideoCodecCtx <> nil then
        avcodec_free_context(@FVideoCodecCtx);
    if FFrame <> nil then
        av_frame_free(@FFrame);
    if FAVPacket_ptr <> nil then
        av_packet_free(@FAVPacket_ptr);
    if FFrameRGB_buffer <> nil then
        av_free(FFrameRGB_buffer);
    if FSWS_CTX <> nil then
        sws_freeContext(FSWS_CTX);
    if FFrameRGB <> nil then
        av_frame_free(@FFrameRGB);
    FVideoCodecCtx := nil;
    FVideoCodec := nil;
    FAVParser := nil;
    FAVPacket_ptr := nil;
    FFrame := nil;
    FFrameRGB := nil;
    FFrameRGB_buffer := nil;
    FSWS_CTX := nil;
    FSwapBuff.Clear;
  finally
      Critical.UnLock;
  end;
end;

function TFFMPEG_VideoStreamReader.WriteBuffer(p: Pointer; siz: NativeUInt): integer;
var
  Decoded_Num: integer;

  function decode(): Boolean;
  var
    R: integer;
    NumByte: integer;
    vr: TMZR;
    Save_To_Pool: Boolean;
  begin
    Result := False;

    R := avcodec_send_packet(FVideoCodecCtx, FAVPacket_ptr);
    if R < 0 then
      begin
        RaiseInfo('Error sending a packet for decoding');
        exit;
      end;

    while R >= 0 do
      begin
        R := avcodec_receive_frame(FVideoCodecCtx, FFrame);
        if (R = AVERROR_EAGAIN) or (R = AVERROR_EOF) then
            break;

        if R < 0 then
          begin
            RaiseInfo('Error during decoding');
            exit;
          end;

        // check FFMPEG color conversion and scaling
        if (FSWS_CTX = nil) or (FFrameRGB = nil) or (FFrameRGB^.Width <> FFrame^.Width) or (FFrameRGB^.Height <> FFrame^.Height) then
          begin
            if FFrameRGB <> nil then
                av_frame_free(@FFrameRGB);
            if FFrameRGB_buffer <> nil then
                av_free(FFrameRGB_buffer);
            if FSWS_CTX <> nil then
                sws_freeContext(FSWS_CTX);

            FFrameRGB := av_frame_alloc();
            NumByte := avpicture_get_size(AV_PIX_FMT_BGRA, FFrame^.Width, FFrame^.Height);
            FFrameRGB_buffer := av_malloc(NumByte * 4);
            FSWS_CTX := sws_getContext(FFrame^.Width, FFrame^.Height,
              FVideoCodecCtx^.pix_fmt,
              FFrame^.Width,
              FFrame^.Height,
              AV_PIX_FMT_BGRA,
              SWS_BILINEAR,
              nil,
              nil,
              nil);
            avpicture_fill(PAVPicture(FFrameRGB), FFrameRGB_buffer, AV_PIX_FMT_BGRA, FFrame^.Width, FFrame^.Height);
            FFrameRGB^.Width := FFrame^.Width;
            FFrameRGB^.Height := FFrame^.Height;
          end;

        try
          sws_scale(FSWS_CTX,
            @FFrame^.data,
            @FFrame^.linesize,
            0,
            FFrame^.Height,
            @FFrameRGB^.data,
            @FFrameRGB^.linesize);

          // extract Frame to Raster
          vr := NewZR();
          vr.SetSize(FFrameRGB^.Width, FFrameRGB^.Height);
          CopyRColor(FFrameRGB^.data[0]^, vr.Bits^[0], FFrameRGB^.Width * FFrameRGB^.Height);

          Save_To_Pool := True;
          DoVideo_Build_New_Raster(vr, Save_To_Pool);

          AtomInc(Decoded_Memory_Size, vr.MemorySize);

          if Save_To_Pool then
            begin
              FVideoRasterPool.Add(vr);
              if FAuto_Write_Serialized and (FSerialized_Tool <> nil) then
                  vr.SerializedAndRecycleMemory(FSerialized_Tool);
            end;

          inc(Decoded_Num);
        except
            FFrameRGB := nil;
        end;
      end;

    Result := True;
  end;

var
  np: Pointer;
  nsiz: NativeUInt;
  bufPos: int64;
  R: integer;
  nbuff: TMS64;
begin
  Decoded_Num := 0;
  Result := 0;
  if (p = nil) or (siz = 0) then
      exit;

  Critical.Lock;
  try
    np := p;
    nsiz := siz;
    DoWrite_Buffer_Before(np, nsiz);
    FSwapBuff.Position := FSwapBuff.Size;
    FSwapBuff.WritePtr(np, nsiz);

    bufPos := 0;
    while FSwapBuff.Size - bufPos > 0 do
      begin
        R := av_parser_parse2(FAVParser, FVideoCodecCtx, @FAVPacket_ptr^.data, @FAVPacket_ptr^.Size,
          FSwapBuff.PositionAsPtr(bufPos), FSwapBuff.Size - bufPos, AV_NOPTS_VALUE, AV_NOPTS_VALUE, 0);

        if R < 0 then
            RaiseInfo('Error while parsing');

        inc(bufPos, R);

        if FAVPacket_ptr^.Size <> 0 then
          if not decode() then
              break;
      end;

    if FSwapBuff.Size - bufPos > 0 then
      begin
        nbuff := TMS64.CustomCreate(FSwapBuff.Delta);
        FSwapBuff.Position := bufPos;
        nbuff.CopyFrom(FSwapBuff, FSwapBuff.Size - bufPos);
        FSwapBuff.NewParam(nbuff);
        nbuff.DiscardMemory;
        disposeObject(nbuff);
      end
    else
        FSwapBuff.Clear;
  finally
      Critical.UnLock;
  end;

  Result := Decoded_Num;
  av_packet_unref(FAVPacket_ptr);
  DoWrite_Buffer_After(np, nsiz, Decoded_Num);
end;

function TFFMPEG_VideoStreamReader.WriteBuffer(stream_: TCore_Stream): integer;
const
  C_Chunk_Buff_Size = 1 * 1024 * 1024;
var
  tempBuff: Pointer;
  chunk: NativeInt;
begin
  if stream_ is TMS64 then
    begin
      Result := WriteBuffer(TMS64(stream_).Memory, stream_.Size);
      exit;
    end;
  if stream_ is TMemoryStream then
    begin
      Result := WriteBuffer(TMemoryStream(stream_).Memory, stream_.Size);
      exit;
    end;

  Result := 0;
  tempBuff := System.GetMemory(C_Chunk_Buff_Size);
  stream_.Position := 0;
  while (stream_.Position < stream_.Size) do
    begin
      chunk := umlMin(stream_.Size - stream_.Position, C_Chunk_Buff_Size);
      if chunk <= 0 then
          break;
      stream_.Read(tempBuff^, chunk);
      inc(Result, WriteBuffer(tempBuff, chunk));
    end;
  System.FreeMemory(tempBuff);
end;

function TFFMPEG_VideoStreamReader.DecodedRasterNum: integer;
begin
  Critical.Lock;
  Result := FVideoRasterPool.Count;
  Critical.UnLock;
end;

function TFFMPEG_VideoStreamReader.LockVideoPool: TMR_List;
begin
  Critical.Lock;
  Result := FVideoRasterPool;
end;

procedure TFFMPEG_VideoStreamReader.UnLockVideoPool(freeRaster_: Boolean);
var
  i: integer;
begin
  if freeRaster_ then
    begin
      for i := 0 to FVideoRasterPool.Count - 1 do
          disposeObject(FVideoRasterPool[i]);
      FVideoRasterPool.Clear;
    end;
  Critical.UnLock;
end;

procedure TFFMPEG_VideoStreamReader.UnLockVideoPool();
begin
  UnLockVideoPool(False);
end;

procedure TFFMPEG_VideoStreamReader.ClearVideoPool;
begin
  LockVideoPool();
  UnLockVideoPool(True);
end;

initialization

// Buffer size used for online video(rtsp or rtmp), 720p 1080p 2K 4K 8K support
{$IFDEF CPU64}
FFMPEG_Reader_BufferSize := 8 * 1024 * 1024;
{$ELSE CPU64}
FFMPEG_Reader_BufferSize := 2 * 1024 * 1024;
{$ENDIF CPU64}

end.
