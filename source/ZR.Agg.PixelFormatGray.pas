{ ****************************************************************************** }
{ * memory Rasterization AGG support                                           * }
{ ****************************************************************************** }


(*
  ////////////////////////////////////////////////////////////////////////////////
  //                                                                            //
  //  Anti-Grain Geometry (modernized Pascal fork, aka 'AggPasMod')             //
  //    Maintained by Christian-W. Budde (Christian@pcjv.de)                    //
  //    Copyright (c) 2012-2017                                                 //
  //                                                                            //
  //  Based on:                                                                 //
  //    Pascal port by Milan Marusinec alias Milano (milan@marusinec.sk)        //
  //    Copyright (c) 2005-2006, see http://www.aggpas.org                      //
  //                                                                            //
  //  Original License:                                                         //
  //    Anti-Grain Geometry - Version 2.4 (Public License)                      //
  //    Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)     //
  //    Contact: McSeem@antigrain.com / McSeemAgg@yahoo.com                     //
  //                                                                            //
  //  Permission to copy, use, modify, sell and distribute this software        //
  //  is granted provided this copyright notice appears in all copies.          //
  //  This software is provided "as is" without express or implied              //
  //  warranty, and with no claim as to its suitability for any purpose.        //
  //                                                                            //
  ////////////////////////////////////////////////////////////////////////////////
*)
unit ZR.Agg.PixelFormatGray;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}
interface
uses
  ZR.Agg.Basics,
  ZR.Agg.PixelFormat,
  ZR.Agg.Color32,
  ZR.Agg.RenderingBuffer;

procedure PixelFormatGray8(out PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);

procedure PixelFormatGray8Bgr24r(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);
procedure PixelFormatGray8Bgr24g(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);
procedure PixelFormatGray8Bgr24b(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);

procedure PixelFormatGray8Pre(out PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);

procedure PixelFormatGray8PreBgr24r(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);
procedure PixelFormatGray8PreBgr24g(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);
procedure PixelFormatGray8PreBgr24b(var PixelFormatProcessor: TAggPixelFormatProcessor; RenderingBuffer: TAggRenderingBuffer);

implementation

function Fmt8Row(This: TAggPixelFormatProcessor; x, y: Integer): TAggRowDataType;
begin
  Result.Initialize(x, This.width - 1,
    PInt8u(PtrComp(This.RenderingBuffer.Row(y)) + x * This.Step + This.Offset));
end;

procedure GrayGammaDirApply(This: TAggPixelFormatProcessor; p: PInt8u);
begin
  p^ := This.Apply.dir[p^];
end;

procedure GrayGammaInvApply(This: TAggPixelFormatProcessor; p: PInt8u);
begin
  p^ := This.Apply.Inv[p^];
end;

procedure GrayForEachPixel(This: TAggPixelFormatProcessor; f: TAggFuncApplyGamma);
var
  y, Len: Cardinal;
  p: PInt8u;
begin
  y := 0;

  while y < This.height do
    begin
      Len := This.width;
      p := PInt8u(PtrComp(This.RenderingBuffer.Row(y)) + This.Offset);

      repeat
        f(This, p);

        inc(PtrComp(p), This.Step);
        dec(Len);

      until Len = 0;

      inc(y);
    end;
end;

{$I ZR.Agg.PixelFormatGray8.inc}


procedure PixelFormatGray8;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 1, 0);

  PixelFormatProcessor.PixWidth := 1;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8BlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8BlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8BlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8BlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8BlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8BlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8BlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8BlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8BlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8Bgr24r;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 2);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8BlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8BlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8BlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8BlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8BlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8BlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8BlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8BlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8BlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8Bgr24g;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 1);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8BlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8BlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8BlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8BlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8BlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8BlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8BlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8BlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8BlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8Bgr24b;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 0);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8BlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8BlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8BlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8BlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8BlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8BlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8BlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8BlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8BlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

{$I ZR.Agg.PixelFormatGray8Pre.inc}


procedure PixelFormatGray8Pre;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 1, 0);

  PixelFormatProcessor.PixWidth := 1;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8PreBlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8PreBlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8PreBlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8PreBlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8PreBlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8PreBlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8PreBlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8PreBlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8PreBlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8PreBgr24r;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 2);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8PreBlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8PreBlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8PreBlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8PreBlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8PreBlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8PreBlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8PreBlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8PreBlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8PreBlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8PreBgr24g;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 1);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8PreBlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8PreBlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8PreBlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8PreBlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8PreBlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8PreBlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8PreBlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8PreBlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8PreBlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

procedure PixelFormatGray8PreBgr24b;
begin
  PixelFormatProcessor := TAggPixelFormatProcessor.Create(RenderingBuffer, 3, 0);

  PixelFormatProcessor.PixWidth := 3;

  PixelFormatProcessor.CopyPixel := @Gray8CopyPixel;
  PixelFormatProcessor.BlendPixel := @Gray8PreBlendPixel;

  PixelFormatProcessor.Pixel := @Gray8Pixel;
  PixelFormatProcessor.Row := @Fmt8Row;

  PixelFormatProcessor.CopyHorizontalLine := @Gray8CopyHorizontalLine;
  PixelFormatProcessor.CopyVerticalLine := @Gray8CopyVerticalLine;

  PixelFormatProcessor.BlendHorizontalLine := @Gray8PreBlendHorizontalLine;
  PixelFormatProcessor.BlendVerticalLine := @Gray8PreBlendVerticalLine;

  PixelFormatProcessor.BlendSolidHSpan := @Gray8PreBlendSolidHSpan;
  PixelFormatProcessor.BlendSolidVSpan := @Gray8PreBlendSolidVSpan;

  PixelFormatProcessor.CopyColorHSpan := @Gray8CopyColorHSpan;
  PixelFormatProcessor.CopyColorVSpan := @Gray8CopyColorVSpan;

  PixelFormatProcessor.BlendColorHSpan := @Gray8PreBlendColorHSpan;
  PixelFormatProcessor.BlendColorVSpan := @Gray8PreBlendColorVSpan;

  PixelFormatProcessor.CopyFrom := @Gray8CopyFrom;
  PixelFormatProcessor.BlendFrom := nil; // not defined in Z.Agg.PixelFormatGray.h

  PixelFormatProcessor.BlendFromColor := @Gray8PreBlendFromColor;
  PixelFormatProcessor.BlendFromLUT := @Gray8PreBlendFromLUT;

  PixelFormatProcessor.ForEachPixel := @GrayForEachPixel;
  PixelFormatProcessor.GammaDirApply := @GrayGammaDirApply;
  PixelFormatProcessor.GammaInvApply := @GrayGammaInvApply;
end;

end.
