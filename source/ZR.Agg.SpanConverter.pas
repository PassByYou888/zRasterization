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
unit ZR.Agg.SpanConverter;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}
interface
uses
  ZR.Agg.Basics,
  ZR.Agg.Color32,
  ZR.Agg.SpanGenerator;

type
  TAggSpanConvertor = class
  public
    procedure Convert(Span: PAggColor; x, y: Integer; Len: Cardinal); virtual; abstract;
  end;

  TAggSpanConverter = class(TAggSpanGenerator)
  private
    FSpanGen: TAggSpanGenerator;
    FConv: TAggSpanConvertor;
  public
    constructor Create(SpanGen: TAggSpanGenerator; conv: TAggSpanConvertor);

    procedure Prepare(MaxSpanLength: Cardinal); override;
    function Generate(x, y: Integer; Len: Cardinal): PAggColor; override;
  end;

implementation


{ TAggSpanConverter }

constructor TAggSpanConverter.Create(SpanGen: TAggSpanGenerator;
  conv: TAggSpanConvertor);
begin
  FSpanGen := SpanGen;
  FConv := conv;
end;

procedure TAggSpanConverter.Prepare(MaxSpanLength: Cardinal);
begin
  FSpanGen.Prepare(MaxSpanLength);
end;

function TAggSpanConverter.Generate(x, y: Integer; Len: Cardinal): PAggColor;
var
  Span: PAggColor;
begin
  Span := FSpanGen.Generate(x, y, Len);
  FConv.Convert(Span, x, y, Len);
  Result := Span;
end;

end.
