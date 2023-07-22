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
unit ZR.Agg.EllipseBresenham;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}
interface
uses
  ZR.Agg.Basics;

type
  TAggEllipseBresenhamInterpolator = record
  private
    FRadiusSquared, FTwoRadiusSquared: TPointInteger;
    FDelta, FInc: TPointInteger;
    FCurF: Integer;
  public
    procedure Initialize(radius: Integer); overload;
    procedure Initialize(RX, RY: Integer); overload;

    procedure IncOperator;

    property deltax: Integer read FDelta.x;
    property deltay: Integer read FDelta.y;
  end;

implementation


{ TAggEllipseBresenhamInterpolator }

procedure TAggEllipseBresenhamInterpolator.Initialize(radius: Integer);
begin
  FRadiusSquared := PointInteger(radius * radius, radius * radius);

  FTwoRadiusSquared.x := FRadiusSquared.x shl 1;
  FTwoRadiusSquared.y := FRadiusSquared.y shl 1;

  FDelta := PointInteger(0);

  FInc.x := 0;
  FInc.y := -radius * FTwoRadiusSquared.x;
  FCurF := 0;
end;

procedure TAggEllipseBresenhamInterpolator.Initialize(RX, RY: Integer);
begin
  FRadiusSquared := PointInteger(RX * RX, RY * RY);

  FTwoRadiusSquared.x := FRadiusSquared.x shl 1;
  FTwoRadiusSquared.y := FRadiusSquared.y shl 1;

  FDelta := PointInteger(0);

  FInc.x := 0;
  FInc.y := -RY * FTwoRadiusSquared.x;
  FCurF := 0;
end;

procedure TAggEllipseBresenhamInterpolator.IncOperator;
var
  mx, my, Mxy, Minimum, fx, fy, FXY: Integer;
  flag: Boolean;
begin
  mx := FCurF + FInc.x + FRadiusSquared.y;
  fx := mx;

  if mx < 0 then
      mx := -mx;

  my := FCurF + FInc.y + FRadiusSquared.x;
  fy := my;

  if my < 0 then
      my := -my;

  Mxy := FCurF + FInc.x + FRadiusSquared.y + FInc.y + FRadiusSquared.x;
  FXY := Mxy;

  if Mxy < 0 then
      Mxy := -Mxy;

  Minimum := mx;
  flag := True;

  if Minimum > my then
    begin
      Minimum := my;
      flag := False;
    end;

  FDelta := PointInteger(0);

  if Minimum > Mxy then
    begin
      inc(FInc.x, FTwoRadiusSquared.y);
      inc(FInc.y, FTwoRadiusSquared.x);

      FCurF := FXY;

      FDelta.x := 1;
      FDelta.y := 1;

      Exit;
    end;

  if flag then
    begin
      inc(FInc.x, FTwoRadiusSquared.y);

      FCurF := fx;
      FDelta.x := 1;

      Exit;
    end;

  inc(FInc.y, FTwoRadiusSquared.x);

  FCurF := fy;
  FDelta.y := 1;
end;

end.
