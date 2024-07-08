{ ****************************************************************************** }
{ * JPEG-LS Codec https://github.com/zekiguven/pascal_jls                      * }
{ ****************************************************************************** }
{
  JPEG-LS Codec
  This code is based on http://www.stat.columbia.edu/~jakulin/jpeg-ls/mirror.htm
  Converted from C to Pascal. 2017

  https://github.com/zekiguven/pascal_jls

  author : Zeki Guven
}
unit ZR.JLS.Codec;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses
  ZR.Core, ZR.JLS.Global, ZR.JLS.Encoder, ZR.JLS.Decoder;

type
  PJlsParameters = ZR.JLS.Global.PJlsParameters;
  TJlsParameters = ZR.JLS.Global.TJlsParameters;
  TJlsCustomParameters = ZR.JLS.Global.TJlsCustomParameters;

function jpegls_decompress(SourceStream, OutputStream: TCore_Stream; Info: PJlsParameters): Boolean;
function jpegls_compress(SourceStream, OutputStream: TCore_Stream; Info: PJlsParameters): Boolean;

implementation

function jpegls_decompress(SourceStream, OutputStream: TCore_Stream; Info: PJlsParameters): Boolean;
var
  dec: TJLSDecoder;
begin
  Result := False;
  dec := TJLSDecoder.Create;
  try
    dec.InputStream := SourceStream;
    dec.OutputStream := OutputStream;

    if dec.Execute then
      begin
        if Info <> nil then
          begin
            Info^.width := dec.width;
            Info^.height := dec.height;
            Info^.BitsPerSample := dec.bpp;
            Info^.Components := dec.Components;
            Info^.AllowedLossyError := dec._near;
            Info^.Custom.t1 := dec.t1;
            Info^.Custom.t2 := dec.t2;
            Info^.Custom.t3 := dec.t3;
            Info^.Custom.Reset := dec.Reset;
            Info^.Custom.MaxVal := dec.MaxVal;
          end;
        Result := True;
      end;

  finally
      dec.Free;
  end;
end;

function jpegls_compress(SourceStream, OutputStream: TCore_Stream; Info: PJlsParameters): Boolean;
var
  enc: TJLSEncoder;
begin
  Result := False;
  enc := TJLSEncoder.Create;
  try
    enc.InputStream := SourceStream;
    enc.OutputStream := OutputStream;

    enc.width := Info^.width;
    enc.height := Info^.height;
    enc.bpp := Info^.BitsPerSample;
    enc.Components := Info^.Components;
    enc.t1 := Info^.Custom.t1;
    enc.t2 := Info^.Custom.t2;
    enc.t3 := Info^.Custom.t3;
    enc.Reset := Info^.Custom.Reset;
    enc._near := Info^.AllowedLossyError;
    enc.MaxVal := Info^.Custom.MaxVal;

    if enc.Execute then
      begin
        Result := True;
      end;

  finally
      enc.Free;
  end;
end;

end.
