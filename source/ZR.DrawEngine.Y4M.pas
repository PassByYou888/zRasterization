{ ****************************************************************************** }
{ * Z.DrawEngine Yuv for mpeg soft Rasterization                               * }
{ ****************************************************************************** }
unit ZR.DrawEngine.Y4M;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses Math, ZR.Geometry3D, ZR.ListEngine, ZR.PascalStrings, ZR.UPascalStrings, ZR.Core, ZR.DrawEngine, ZR.UnicodeMixedLib, ZR.Geometry2D,
  ZR.MemoryRaster, ZR.h264.Y4M, ZR.h264.Image_LIB, ZR.h264.Types;

type
  TDrawEngine_YUV4MPEG = class(TDrawEngine_Raster)
  private
    FYW: TY4MWriter;
  public
    constructor CreateOnFile(const w, h, psf: uint16_t; const FileName: SystemString); overload;
    constructor CreateOnStream(const w, h, psf: uint16_t; const stream: TCore_Stream); overload;

    destructor Destroy; override;

    procedure Progress(deltaTime: Double);

    procedure Flush; override;
    function FrameCount: uint32_t;
    function Y4MSize: Int64_t;
    function PerSecondFrame: TDEFloat;
  end;

implementation

constructor TDrawEngine_YUV4MPEG.CreateOnFile(const w, h, psf: uint16_t; const FileName: SystemString);
var
  NW, NH: uint16_t;
begin
  inherited Create;
  NW := w - (w mod 2);
  NH := h - (h mod 2);
  FYW := TY4MWriter.CreateOnFile(NW, NH, psf, FileName);
  Memory.SetSize(NW, NH);
end;

constructor TDrawEngine_YUV4MPEG.CreateOnStream(const w, h, psf: uint16_t; const stream: TCore_Stream);
var
  NW, NH: uint16_t;
begin
  inherited Create;
  NW := w - (w mod 2);
  NH := h - (h mod 2);
  FYW := TY4MWriter.CreateOnStream(NW, NH, psf, stream);
  Memory.SetSize(NW, NH);
end;

destructor TDrawEngine_YUV4MPEG.Destroy;
begin
  DisposeObject(FYW);
  inherited Destroy;
end;

procedure TDrawEngine_YUV4MPEG.Progress(deltaTime: Double);
begin
  Engine.Progress(1 / FYW.PerSecondFrame);
end;

procedure TDrawEngine_YUV4MPEG.Flush;
begin
  inherited Flush;
  FYW.WriteFrame(Memory);
  FYW.Flush;
end;

function TDrawEngine_YUV4MPEG.FrameCount: uint32_t;
begin
  Result := FYW.FrameCount;
end;

function TDrawEngine_YUV4MPEG.Y4MSize: Int64_t;
begin
  Result := FYW.Y4MSize;
end;

function TDrawEngine_YUV4MPEG.PerSecondFrame: TDEFloat;
begin
  Result := FYW.PerSecondFrame;
end;

end.
