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
unit ZR.Agg.VertexSource;

(*
  ////////////////////////////////////////////////////////////////////////////////
  // Pascal replacement of the TAggVertexSource templetized concept from C++.   //
  // This file is originaly not a part of the AGG.                              //
  ////////////////////////////////////////////////////////////////////////////////
*)

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}
interface
uses
  ZR.Agg.Basics;

type
  TAggCustomVertexSource = class
  protected
    function GetPathCount: Cardinal; virtual;
  public
    procedure Rewind(PathID: Cardinal); virtual;
    function Vertex(x, y: PDouble): Cardinal; virtual;

    function FuncOperatorGamma(x: Double): Double; virtual;

    property PathCount: Cardinal read GetPathCount;
  end;

  TAggVertexSource = class(TAggCustomVertexSource)
  protected
    function GetPathID(index: Cardinal): Cardinal; virtual;
  public
    procedure RemoveAll; virtual;
    procedure AddVertex(x, y: Double; Cmd: Cardinal); virtual;

    property PathID[index: Cardinal]: Cardinal read GetPathID;
  end;

implementation


{ TAggCustomVertexSource }

function TAggCustomVertexSource.GetPathCount: Cardinal;
begin
  Result := 0;
end;

procedure TAggCustomVertexSource.Rewind(PathID: Cardinal);
begin
end;

function TAggCustomVertexSource.Vertex(x, y: PDouble): Cardinal;
begin
  Result := 0;
end;

function TAggCustomVertexSource.FuncOperatorGamma;
begin
  Result := x;
end;

{ TAggVertexSource }

function TAggVertexSource.GetPathID(index: Cardinal): Cardinal;
begin
  Result := 0;
end;

procedure TAggVertexSource.RemoveAll;
begin
end;

procedure TAggVertexSource.AddVertex;
begin
end;

end.
