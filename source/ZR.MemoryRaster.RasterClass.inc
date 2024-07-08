{ ****************************************************************************** }
{ * memory Rasterization Classes                                               * }
{ ****************************************************************************** }
procedure MakeMergeTables;
var
  I, J: Integer;
const
  OneByteth: Double = 1.0 / $FF;
begin
  for J := 0 to $FF do
    for I := 0 to $FF do
      begin
        DivTable[I, J] := ClampByte(Round(I * J * OneByteth));
        if I > 0 then
            RcTable[I, J] := ClampByte(Round(J * $FF / I))
        else
            RcTable[I, J] := 0;
      end;
end;

function TYIQ.GetRGB: TRColor;
var
  nY, nI, nQ, R, G, B: TGeoFloat;
begin
  nY := Y;
  nI := I * 1.191 - 0.595;
  nQ := Q * 1.045 - 0.523;
  R := nY + 0.956 * nI + 0.621 * nQ;
  G := nY - 0.272 * nI - 0.647 * nQ;
  B := nY - 1.107 * nI + 1.706 * nQ;
  Result := RColorF(R, G, B);
end;

procedure TYIQ.SetRGB(const Value: TRColor);
var
  R, G, B: TGeoFloat;
begin
  RColor2F(Value, R, G, B);
  Y := 0.299 * R + 0.587 * G + 0.114 * B;
  I := 0.596 * R - 0.274 * G - 0.321 * B;
  I := (I + 0.595) / 1.191;
  Q := 0.211 * R - 0.523 * G + 0.311 * B;
  Q := (Q + 0.523) / 1.045;
end;

function TYIQ.GetRGBA(A: Byte): TRColor;
begin
  Result := GetRGB();
  TRColorEntry(Result).A := A;
end;

procedure TYIQ.SetRGBA(A: Byte; const Value: TRColor);
begin
  SetRGB(Value);
end;

function THSI.GetRGB: TRColor;
var
  nH, nS, nI, R, G, B: TGeoFloat;
begin
  nH := H * 363 - 1;
  nS := S;
  nI := I;
  R := 0;
  G := 0;
  B := 0;
  if nH = 0 then
    begin
      R := nI + 2 * nI * nS;
      G := nI - nI * nS;
      B := nI - nI * nS;
    end
  else if (0 < nH) and (nH < 120) then
    begin
      R := nI + nI * nS * Cos(DegToRad(nH)) / Cos(DegToRad(60 - nH));
      G := nI + nI * nS * (1 - Cos(DegToRad(nH)) / Cos(DegToRad(60 - nH)));
      B := nI - nI * nS;
    end
  else if (nH = 120) then
    begin
      R := nI - nI * nS;
      G := nI + 2 * nI * nS;
      B := nI - nI * nS;
    end
  else if (120 < nH) and (nH < 240) then
    begin
      R := nI - nI * nS;
      G := nI + nI * nS * Cos(DegToRad(nH - 120)) / Cos(DegToRad(180 - nH));
      B := nI + nI * nS * (1 - Cos(DegToRad(nH - 120)) / Cos(DegToRad(180 - nH)));
    end
  else if nH = 240 then
    begin
      R := nI - nI * nS;
      G := nI - nI * nS;
      B := nI + 2 * nI * nS;
    end
  else if (240 < nH) and (nH < 360) then
    begin
      R := nI + nI * nS * (1 - Cos(DegToRad(nH - 240)) / Cos(DegToRad(300 - nH)));
      G := nI - nI * nS;
      B := nI + nI * nS * Cos(DegToRad(nH - 240)) / Cos(DegToRad(300 - nH));
    end
  else if nH > 360 then
    begin
      R := nI;
      G := nI;
      B := nI;
    end;
  Result := RColorF(R, G, B);
end;

procedure THSI.SetRGB(const Value: TRColor);
var
  R, G, B: TGeoFloat;
begin
  RColor2F(Value, R, G, B);
  I := (R + G + B) / 3.0;
  if I > 0 then
      S := 1 - umlMin(umlMin(R, G), B) / I
  else
      S := 0;
  if S <> 0 then
    begin
      R := Round(R * 255);
      G := Round(G * 255);
      B := Round(B * 255);
      if G >= B then
          H := RadToDeg(ArcCos((R - G * 0.5 - B * 0.5) / Sqrt(Sqr(R) + Sqr(G) + Sqr(B) - R * G - R * B - G * B)))
      else
          H := 360.0 - RadToDeg(ArcCos((R - G * 0.5 - B * 0.5) / Sqrt(Sqr(R) + Sqr(G) + Sqr(B) - R * G - R * B - G * B)))
    end
  else
      H := 361.0;

  H := (H + 1) / 363.0;
end;

function THSI.GetRGBA(A: Byte): TRColor;
begin
  Result := GetRGB();
  TRColorEntry(Result).A := A;
end;

procedure THSI.SetRGBA(A: Byte; const Value: TRColor);
begin
  SetRGB(Value);
end;

function TCMYK.GetRGB: TRColor;
var
  R, G, B: TGeoFloat;
begin
  R := (1.0 - C) * (1.0 - K);
  G := (1.0 - M) * (1.0 - K);
  B := (1.0 - Y) * (1.0 - K);
  Result := RColorF(R, G, B);
end;

procedure TCMYK.SetRGB(const Value: TRColor);
var
  R, G, B: TGeoFloat;
begin
  RColor2F(Value, R, G, B);
  K := 1.0 - umlMax(umlMax(R, G), B);
  if K <> 1.0 then
    begin
      C := (1.0 - R - K) / (1.0 - K);
      M := (1.0 - G - K) / (1.0 - K);
      Y := (1.0 - B - K) / (1.0 - K);
    end
  else
    begin
      C := 1.0;
      M := 1.0;
      Y := 1.0;
    end;
end;

function TCMYK.GetRGBA(A: Byte): TRColor;
begin
  Result := GetRGB();
  TRColorEntry(Result).A := A;
end;

procedure TCMYK.SetRGBA(A: Byte; const Value: TRColor);
begin
  SetRGB(Value);
end;

function TMZR.GetExtra: TPascalString_Hash_Pool;
begin
  if FExtra = nil then
      FExtra := TPascalString_Hash_Pool.Create(128, '');
  Result := FExtra;
end;

function TMZR.GetVertex: TZRVertex;
begin
  if FVertex = nil then
      OpenVertex;

  Result := FVertex;
end;

function TMZR.GetFont: TFontZR;
begin
  if FFont = nil then
      OpenFont;

  Result := FFont;
end;

procedure TMZR.SetFont(f: TFontZR);
begin
  CloseFont;
  FFont := TFontZR.Create(f);
end;

function TMZR.GetAggImage: TMemoryZR_AggImage;
begin
  if FAggImage = nil then
      OpenAgg;
  Result := FAggImage;
end;

function TMZR.GetAgg: TMemoryZR_Agg2D;
begin
  if FAgg = nil then
      OpenAgg;
  Result := FAgg;
end;

function TMZR.GetBits: PRColorArray;
begin
  ReadyBits();
  Result := FBits;
end;

function TMZR.GetPixel(const X, Y: Integer): TRColor;
begin
  Result := PixelPtr[X, Y]^;
end;

procedure TMZR.SetPixel(const X, Y: Integer; const Value: TRColor);
begin
  PixelPtr[X, Y]^ := Value;
end;

function TMZR.GetFastPixel(const X, Y: Integer): TRColor;
begin
  Result := FBits^[X + Y * Width];
end;

procedure TMZR.SetFastPixel(const X, Y: Integer; const Value: TRColor);
begin
  FBits^[X + Y * Width] := Value;
end;

function TMZR.GetPixelBGRA(const X, Y: Integer): TRColor;
begin
  Result := RGBA2BGRA(GetPixel(X, Y));
end;

procedure TMZR.SetPixelBGRA(const X, Y: Integer; const Value: TRColor);
begin
  SetPixel(X, Y, BGRA2RGBA(Value));
end;

function TMZR.GetPixelPtr(const X, Y: Integer): PRColor;
begin
  Result := @(Bits^[ClampInt(X, 0, Width - 1) + ClampInt(Y, 0, Height - 1) * Width]);
end;

function TMZR.GetFastPixelPtr(const X, Y: Integer): PRColor;
begin
  Result := @FBits^[X + Y * Width];
end;

function TMZR.GetScanLine(Y: Integer): PRColorArray;
begin
  Result := @Bits^[Y * FWidth];
end;

function TMZR.GetWidth0: TGeoFloat;
begin
  if FWidth > 0 then
      Result := FWidth - 1
  else
      Result := 0;
end;

function TMZR.GetHeight0: TGeoFloat;
begin
  if FHeight > 0 then
      Result := FHeight - 1
  else
      Result := 0;
end;

function TMZR.GetWidth0i: Integer;
begin
  if FWidth > 0 then
      Result := FWidth - 1
  else
      Result := 0;
end;

function TMZR.GetHeight0i: Integer;
begin
  if FHeight > 0 then
      Result := FHeight - 1
  else
      Result := 0;
end;

function TMZR.GetPixelRed(const X, Y: Integer): Byte;
begin
  Result := PRColorEntry(GetPixelPtr(X, Y))^.R;
end;

procedure TMZR.SetPixelRed(const X, Y: Integer; const Value: Byte);
begin
  PRColorEntry(GetPixelPtr(X, Y))^.R := Value;
end;

function TMZR.GetPixelGreen(const X, Y: Integer): Byte;
begin
  Result := PRColorEntry(GetPixelPtr(X, Y))^.G;
end;

procedure TMZR.SetPixelGreen(const X, Y: Integer; const Value: Byte);
begin
  PRColorEntry(GetPixelPtr(X, Y))^.G := Value;
end;

function TMZR.GetPixelBlue(const X, Y: Integer): Byte;
begin
  Result := PRColorEntry(GetPixelPtr(X, Y))^.B;
end;

procedure TMZR.SetPixelBlue(const X, Y: Integer; const Value: Byte);
begin
  PRColorEntry(GetPixelPtr(X, Y))^.B := Value;
end;

function TMZR.GetPixelAlpha(const X, Y: Integer): Byte;
begin
  Result := PRColorEntry(GetPixelPtr(X, Y))^.A;
end;

procedure TMZR.SetPixelAlpha(const X, Y: Integer; const Value: Byte);
begin
  PRColorEntry(GetPixelPtr(X, Y))^.A := Value;
end;

function TMZR.GetGray(const X, Y: Integer): Byte;
begin
  Result := RColor2Gray(GetPixel(X, Y));
end;

procedure TMZR.SetGray(const X, Y: Integer; const Value: Byte);
begin
  SetPixel(X, Y, RColor(Value, Value, Value, $FF));
end;

function TMZR.GetGrayS(const X, Y: Integer): TGeoFloat;
begin
  Result := RColor2GrayS(GetPixel(X, Y));
end;

procedure TMZR.SetGrayS(const X, Y: Integer; const Value: TGeoFloat);
begin
  SetGray(X, Y, ClampByte3(Round(Value * $FF), 0, $FF));
end;

function TMZR.GetGrayD(const X, Y: Integer): Double;
begin
  Result := RColor2GrayD(GetPixel(X, Y));
end;

procedure TMZR.SetGrayD(const X, Y: Integer; const Value: Double);
begin
  SetGrayS(X, Y, Value);
end;

function TMZR.GetPixelF(const X, Y: TGeoFloat): TRColor;
begin
  Result := GetPixel(Round(X), Round(Y));
end;

procedure TMZR.SetPixelF(const X, Y: TGeoFloat; const Value: TRColor);
begin
  SetPixel(Round(X), Round(Y), Value);
end;

function TMZR.GetPixelVec(const v2: TVec2): TRColor;
begin
  Result := GetPixelF(v2[0], v2[1]);
end;

procedure TMZR.SetPixelVec(const v2: TVec2; const Value: TRColor);
begin
  SetPixelF(v2[0], v2[1], Value)
end;

function TMZR.GetPixelLinearMetric(const X, Y: TGeoFloat): TRColor;
const
  C_FF: Single = $FF;
var
  fx, fy: TGeoFloat;
  i_x, i_y: Integer;
  i_x2, i_y2: Integer;
  delta_x, delta_y: TGeoFloat;
  c1, c2, c3, c4: TRColorEntry;
  k1, k2, k3, K4: TGeoFloat;
  R, G, B, A: TGeoFloat;
begin
  fx := umlClamp(X, 0.0, 1.0) * Width0;
  fy := umlClamp(Y, 0.0, 1.0) * Height0;

  i_x := ClampInt(Trunc(fx), 0, Width0i);
  i_y := ClampInt(Trunc(fy), 0, Height0i);

  i_x2 := i_x + 1;
  i_y2 := i_y + 1;
  if (i_x2 > Width0) or (i_y2 > Height0) then
    begin
      Result := Pixel[i_x, i_y];
      exit;
    end;

  delta_x := Frac(fx);
  delta_y := Frac(fy);

  k1 := (1 - delta_x) * (1 - delta_y);
  k2 := delta_x * (1 - delta_y);
  k3 := delta_x * delta_y;
  K4 := (1 - delta_x) * delta_y;

  c1.BGRA := Pixel[i_x, i_y];
  c2.BGRA := Pixel[i_x2, i_y];
  c3.BGRA := Pixel[i_x2, i_y2];
  c4.BGRA := Pixel[i_x, i_y2];

  R := ((c1.R / C_FF) * k1) + ((c2.R / C_FF) * k2) + ((c3.R / C_FF) * k3) + ((c4.R / C_FF) * K4);
  G := ((c1.G / C_FF) * k1) + ((c2.G / C_FF) * k2) + ((c3.G / C_FF) * k3) + ((c4.G / C_FF) * K4);
  B := ((c1.B / C_FF) * k1) + ((c2.B / C_FF) * k2) + ((c3.B / C_FF) * k3) + ((c4.B / C_FF) * K4);
  A := ((c1.A / C_FF) * k1) + ((c2.A / C_FF) * k2) + ((c3.A / C_FF) * k3) + ((c4.A / C_FF) * K4);

  Result := RColorF(R, G, B, A);
end;

function TMZR.GetPixelLinear(const X, Y: Integer): TRColor;
begin
  Result := GetPixelLinearMetric(X / Width0, Y / Height0);
end;

function TMZR.GetPixelYIQ(const X, Y: Integer): TYIQ;
begin
  Result.RGB := Pixel[X, Y];
end;

procedure TMZR.SetPixelYIQ(const X, Y: Integer; const Value: TYIQ);
begin
  Pixel[X, Y] := Value.RGB;
end;

function TMZR.GetPixelHSI(const X, Y: Integer): THSI;
begin
  Result.RGB := Pixel[X, Y];
end;

procedure TMZR.SetPixelHSI(const X, Y: Integer; const Value: THSI);
begin
  Pixel[X, Y] := Value.RGB;
end;

function TMZR.GetPixelCMYK(const X, Y: Integer): TCMYK;
begin
  Result.RGB := Pixel[X, Y];
end;

procedure TMZR.SetPixelCMYK(const X, Y: Integer; const Value: TCMYK);
begin
  Pixel[X, Y] := Value.RGB;
end;

constructor TMZR.Create;
begin
  inherited Create;

  LocalParallel := True;

  FIsChanged := False;
  FDrawEngineMap := nil;

  FSerialized_Read_History_Ptr := nil;
  FSerialized_Write_History_Ptr := nil;
  FSerialized_Engine := nil;
  FSerialized_ID := -1;
  FSerialized_Size := 0;
  FActivted := True;
  FActiveTimeTick := 0;

  FFreeBits := False;
  FBits := nil;
  FWidth := 0;
  FHeight := 0;
  FOuterColor := $00000000; // by default as full transparency black

  FMasterAlpha := $FF;
  FDrawMode := dmBlend;
  FCombineMode := cmBlend;

  FVertex := nil;
  FFont := nil;

  FAggImage := nil;
  FAgg := nil;
  FAggNeed := False;

  FUserObject := nil;
  FUserData := nil;
  FUserFloat := 0;
  FUserText := '';
  FUserToken := '';
  FUserVariant := NULL;
  FUserInt := 0;
  FUserID := 0;
  FExtra := nil;
end;

destructor TMZR.Destroy;
begin
  if FDrawEngineMap <> nil then
      DisposeObject(FDrawEngineMap);
  Safe_ResetSerialized;
  CloseFont;
  CloseVertex;
  CloseAgg;
  RecycleMemory;
  if FExtra <> nil then
      DisposeObject(FExtra);
  inherited Destroy;
end;

procedure TMZR.DoChange();
begin
  FIsChanged := True;
end;

function TMZR.ActiveTimeTick: TTimeTick;
begin
  if FActivted then
    begin
      FActiveTimeTick := GetTimeTick();
      FActivted := False;
    end;
  Result := FActiveTimeTick;
end;

function TMZR.SerializedAndRecycleMemory(RSeri: TZRSerialized): Int64;
begin
  if (FSerialized_Engine <> nil) and (FSerialized_Engine <> RSeri) and empty() then // check instance
      UnserializedMemory();

  if FSerialized_Engine <> RSeri then
      Safe_ResetSerialized; // remove old Serialized_Engine

  FSerialized_Engine := RSeri;
  if FSerialized_Engine <> nil then
      Result := FSerialized_Engine.Write(Self)
  else
      Result := 0;
end;

function TMZR.SerializedAndRecycleMemory(): Int64;
begin
  if FSerialized_Engine <> nil then
      Result := FSerialized_Engine.Write(Self)
  else
      Result := 0;
end;

function TMZR.UnserializedMemory(RSeri: TZRSerialized): Int64;
begin
  if FSerialized_Engine <> RSeri then
      RaiseInfo('error');
  FSerialized_Engine := RSeri;
  Result := UnserializedMemory();
end;

function TMZR.UnserializedMemory(): Int64;
begin
  if FSerialized_Engine <> nil then
      Result := FSerialized_Engine.Read(Self)
  else
      Result := 0;
end;

function TMZR.Is_Serialized(): Boolean;
begin
  Result := (FSerialized_Engine <> nil) and (FSerialized_ID >= 0);
end;

function TMZR.Get_Serialized_Size(RSeri: TZRSerialized): Int64;
begin
  Result := 0;
  if (FSerialized_Engine <> nil) and (FSerialized_Engine = RSeri) and (FSerialized_ID >= 0) then
      Result := FSerialized_Engine.Get_Raster_Size(Self);
end;

function TMZR.Get_Serialized_Size(): Int64;
begin
  Result := 0;
  if (FSerialized_Engine <> nil) and (FSerialized_ID >= 0) then
      Result := FSerialized_Engine.Get_Raster_Size(Self);
end;

function TMZR.RecycleMemory(): Int64;
begin
  Result := 0;
  if Assigned(FBits) and FFreeBits then
    begin
      Result := FWidth * FHeight * 4;
      System.FreeMemory(FBits);
    end;
  FBits := nil;
end;

procedure TMZR.ReadyBits;
begin
  FActivted := True;
  if (FBits = nil) and (FWidth > 0) and (FHeight > 0) and (FSerialized_ID >= 0) and (FSerialized_Engine <> nil) then
      UnserializedMemory();
end;

procedure TMZR.ResetSerialized;
begin
  ReadyBits;
  FSerialized_Read_History_Ptr := nil;
  FSerialized_Write_History_Ptr := nil;
  FSerialized_Engine := nil;
  FSerialized_ID := -1;
  FSerialized_Size := 0;
end;

procedure TMZR.Safe_ResetSerialized;
begin
  if FSerialized_Engine <> nil then
      FSerialized_Engine.Remove(Self);
  FSerialized_Read_History_Ptr := nil;
  FSerialized_Write_History_Ptr := nil;
  FSerialized_Engine := nil;
  FSerialized_ID := -1;
  FSerialized_Size := 0;
end;

procedure TMZR.SetWorkMemory(Forever: Boolean; WorkMemory: Pointer; NewWidth, NewHeight: Integer);
begin
  CloseVertex;
  FreeAgg;

  RecycleMemory;

  if WorkMemory = nil then
    begin
      FFreeBits := True;
      FBits := nil;
      FWidth := NewWidth;
      FHeight := NewHeight;
    end
  else
    begin
      FFreeBits := Forever;
      FBits := PRColorArray(WorkMemory);
      FWidth := NewWidth;
      FHeight := NewHeight;
    end;

  if FAggNeed then
      OpenAgg;

  Safe_ResetSerialized;
end;

procedure TMZR.SetWorkMemory(WorkMemory: Pointer; NewWidth, NewHeight: Integer);
begin
  SetWorkMemory(False, WorkMemory, NewWidth, NewHeight);
end;

procedure TMZR.SetWorkMemory(Forever: Boolean; raster: TMZR);
begin
  SetWorkMemory(Forever, @raster.Bits^[0], raster.Width, raster.Height);
  if Forever then
      raster.FBits := nil;
end;

procedure TMZR.SetWorkMemory(raster: TMZR);
begin
  SetWorkMemory(False, raster);
end;

function TMZR.IsMemoryMap: Boolean;
begin
  Result := (FWidth > 0) and (FHeight > 0) and (not FFreeBits);
end;

function TMZR.IsMapFrom(raster: TMZR): Boolean;
begin
  Result := IsMemoryMap and (not raster.empty) and (FBits = @raster.Bits^[0]);
end;

procedure TMZR.OpenVertex;
begin
  if FVertex = nil then
    begin
      FVertex := TZRVertex.Create(Self);
      FVertex.LocalParallel := LocalParallel;
    end;
end;

procedure TMZR.CloseVertex;
begin
  if FVertex <> nil then
    begin
      DisposeObject(FVertex);
      FVertex := nil;
    end;
end;

procedure TMZR.OpenFont;
begin
  if FFont = nil then
      FFont := TFontZR.Create(Wait_SystemFont_Init);
end;

procedure TMZR.CloseFont;
begin
  if FFont <> nil then
    begin
      DisposeObject(FFont);
      FFont := nil;
    end;
end;

procedure TMZR.OpenAgg;
begin
  if empty then
    begin
      FAggNeed := True;
      exit;
    end;
  if FAggImage = nil then
      FAggImage := TMemoryZR_AggImage.Create(Self);

  if FAgg = nil then
    begin
      FAgg := TMemoryZR_Agg2D.Create(TAggPixelFormat.pfBGRA);
      FAgg.Attach(Self);
    end;
end;

procedure TMZR.CloseAgg;
begin
  FreeAgg;
  FAggNeed := False;
end;

procedure TMZR.FreeAgg;
begin
  if Assigned(FAggImage) then
    begin
      DisposeObject(FAggImage);
      FAggImage := nil;
    end;

  if Assigned(FAgg) then
    begin
      DisposeObject(FAgg);
      FAgg := nil;
    end;
end;

function TMZR.AggActivted: Boolean;
begin
  Result := (FAggImage <> nil) and (FAgg <> nil);
end;

procedure TMZR.NoUsage;
begin
end;

procedure TMZR.Update;
begin
  NoUsage;
  DoChange;
end;

procedure TMZR.DiscardMemory;
begin
  if FFont <> nil then
    begin
      DisposeObject(FFont);
      FFont := nil;
    end;

  CloseVertex;
  FreeAgg;
  FBits := nil;
  FFreeBits := True;
  FWidth := 0;
  FHeight := 0;

  Safe_ResetSerialized;
end;

procedure TMZR.SwapInstance(dest: TMZR; Swap_Serialized_: Boolean);
var
  bak_Bits: PRColorArray;
  bak_Width, bak_Height: Integer;
  bak_FreeBits: Boolean;
  bak_Serialized_Read_History_Ptr: TSerialized_History_Pool.PQueueStruct;
  bak_Serialized_Write_History_Ptr: TSerialized_History_Pool.PQueueStruct;
  bak_Serialized_Engine: TZRSerialized;
  bak_Serialized_ID: Integer;
begin
  if Self = dest then
      exit;
  ReadyBits;
  CloseVertex;
  FreeAgg;

  dest.ReadyBits;
  dest.CloseVertex;
  dest.FreeAgg;

  if Swap_Serialized_ then
    begin
      if (FSerialized_Engine <> dest.FSerialized_Engine) then
        begin
          if FSerialized_Engine <> nil then
              FSerialized_Engine.Lock;
          if dest.FSerialized_Engine <> nil then
              dest.FSerialized_Engine.Lock;
        end
      else
        begin
          if FSerialized_Engine <> nil then
              FSerialized_Engine.Lock;
        end;
    end;

  bak_Bits := FBits;
  bak_Width := FWidth;
  bak_Height := FHeight;
  bak_FreeBits := FFreeBits;
  if Swap_Serialized_ then
    begin
      bak_Serialized_Read_History_Ptr := FSerialized_Read_History_Ptr;
      bak_Serialized_Write_History_Ptr := FSerialized_Write_History_Ptr;
      bak_Serialized_Engine := FSerialized_Engine;
      bak_Serialized_ID := FSerialized_ID;
    end;

  FBits := dest.FBits;
  FWidth := dest.FWidth;
  FHeight := dest.FHeight;
  FFreeBits := dest.FFreeBits;
  if Swap_Serialized_ then
    begin
      FSerialized_Read_History_Ptr := dest.FSerialized_Read_History_Ptr;
      FSerialized_Write_History_Ptr := dest.FSerialized_Write_History_Ptr;
      FSerialized_Engine := dest.FSerialized_Engine;
      FSerialized_ID := dest.FSerialized_ID;
    end;

  dest.FBits := bak_Bits;
  dest.FWidth := bak_Width;
  dest.FHeight := bak_Height;
  dest.FFreeBits := bak_FreeBits;
  if Swap_Serialized_ then
    begin
      dest.FSerialized_Read_History_Ptr := bak_Serialized_Read_History_Ptr;
      dest.FSerialized_Write_History_Ptr := bak_Serialized_Write_History_Ptr;
      dest.FSerialized_Engine := bak_Serialized_Engine;
      dest.FSerialized_ID := bak_Serialized_ID;
    end;

  if Swap_Serialized_ then
    begin
      // update Dest Serialized history
      if dest.FSerialized_Read_History_Ptr <> nil then
          dest.FSerialized_Read_History_Ptr^.Data := dest;
      if dest.FSerialized_Write_History_Ptr <> nil then
          dest.FSerialized_Write_History_Ptr^.Data := dest;

      // update Self Serialized history
      if FSerialized_Read_History_Ptr <> nil then
          FSerialized_Read_History_Ptr^.Data := Self;
      if FSerialized_Write_History_Ptr <> nil then
          FSerialized_Write_History_Ptr^.Data := Self;

      if (FSerialized_Engine <> dest.FSerialized_Engine) then
        begin
          if FSerialized_Engine <> nil then
              FSerialized_Engine.UnLock;
          if dest.FSerialized_Engine <> nil then
              dest.FSerialized_Engine.UnLock;
        end
      else
        begin
          if FSerialized_Engine <> nil then
              FSerialized_Engine.UnLock;
        end;
    end;

  DoChange;
  dest.DoChange;
end;

procedure TMZR.SwapInstance(dest: TMZR);
begin
  SwapInstance(dest, False);
end;

function TMZR.BitsSame(sour: TMZR): Boolean;
begin
  Result := (Bits = sour.Bits) and (FWidth = sour.FWidth) and (FHeight = sour.FHeight);
end;

procedure TMZR.Reset;
begin
  if FFont <> nil then
    begin
      DisposeObject(FFont);
      FFont := nil;
    end;

  CloseVertex;
  FreeAgg;
  RecycleMemory;

  FFreeBits := True;
  FWidth := 0;
  FHeight := 0;

  Safe_ResetSerialized;
  DoChange;
end;

function TMZR.Clone: TMZR;
begin
  Result := NewZR();
  Result.Assign(Self);
end;

function TMZR.CreateMapping: TMZR;
begin
  Result := NewZR();
  Result.SetWorkMemory(Self);
end;

procedure TMZR.Assign(sour: TMZR);
begin
  Reset;
  FWidth := sour.FWidth;
  FHeight := sour.FHeight;

  FDrawMode := sour.FDrawMode;
  FCombineMode := sour.FCombineMode;

  FMasterAlpha := sour.FMasterAlpha;
  FOuterColor := sour.FOuterColor;

  CloseVertex;
  FreeAgg;

  FFreeBits := True;
  FAggNeed := sour.FAggNeed;

  FBits := System.GetMemory(sour.FWidth * sour.FHeight * SizeOf(TRColor));
  CopyRColor(sour.Bits^[0], FBits^[0], sour.FWidth * sour.FHeight);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Assign(sour: TMorphologyBinaryzation);
var
  I: Integer;
begin
  Reset;
  FWidth := sour.FWidth;
  FHeight := sour.FHeight;

  FOuterColor := $00000000; // by default as full transparency black
  FMasterAlpha := $FF;
  FDrawMode := dmBlend;
  FCombineMode := cmBlend;

  CloseVertex;
  FreeAgg;

  FFreeBits := True;
  FAggNeed := False;

  FBits := System.GetMemory(sour.FWidth * sour.FHeight * SizeOf(TRColor));
  for I := Width * Height - 1 downto 0 do
    if sour.FBits^[I] then
        FBits^[I] := $FFFFFFFF
    else
        FBits^[I] := $00000000;

  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Assign(sour: TMorphomatics);
var
  I: Integer;
begin
  Reset;
  FWidth := sour.FWidth;
  FHeight := sour.FHeight;

  FOuterColor := $00000000; // by default as full transparency black
  FMasterAlpha := $FF;
  FDrawMode := dmBlend;
  FCombineMode := cmBlend;

  CloseVertex;
  FreeAgg;

  FFreeBits := True;
  FAggNeed := False;

  FBits := System.GetMemory(sour.FWidth * sour.FHeight * SizeOf(TRColor));
  for I := Width * Height - 1 downto 0 do
      MorphToRColor(mpGrayscale, sour.FBits^[I], FBits^[I]);

  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Clear;
begin
  Clear($FF000000);
end;

procedure TMZR.Clear(FillColor_: TRColor);
begin
  if empty then
      exit;
  FillRColor(@Bits^[0], Width * Height, FillColor_);
  DoChange;
end;

function TMZR.MemorySize: Integer;
begin
  Result := Width * Height * SizeOf(TRColor);
end;

function TMZR.GetMD5: TMD5;
begin
  Result := umlMD5(@Bits^[0], MemorySize);
end;

function TMZR.GetCRC32: Cardinal;
begin
  Result := umlCRC32(@Bits^[0], MemorySize);
end;

function TMZR.Get_Gradient_L16_MD5: TMD5;
var
  tmp: TMZR;
begin
  tmp := Clone;
  tmp.Grayscale_Gradient(16);
  Result := tmp.GetMD5;
  DisposeObject(tmp);
end;

procedure TMZR.SetSize(NewWidth, NewHeight: Integer);
begin
  if (NewWidth = FWidth) and (NewHeight = FHeight) and (FBits <> nil) and FFreeBits then
      exit;

  CloseVertex;
  FreeAgg;
  RecycleMemory;
  FFreeBits := True;

  FBits := System.GetMemory(NewWidth * NewHeight * SizeOf(TRColor));
  FWidth := NewWidth;
  FHeight := NewHeight;

  if FAggNeed then
      OpenAgg;

  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.SetSize(NewWidth, NewHeight: Integer; const ClearColor: TRColor);
begin
  SetSize(NewWidth, NewHeight);
  FillRColor(@Bits^[0], NewWidth * NewHeight, ClearColor);
end;

procedure TMZR.SetSizeF(NewWidth, NewHeight: TGeoFloat; const ClearColor: TRColor);
begin
  SetSize(Round(NewWidth), Round(NewHeight), ClearColor);
end;

procedure TMZR.SetSizeF(NewWidth, NewHeight: TGeoFloat);
begin
  SetSize(Round(NewWidth), Round(NewHeight));
end;

procedure TMZR.SetSizeV(SizV: TVec2);
begin
  SetSize(Round(SizV[0]), Round(SizV[1]));
end;

procedure TMZR.SetSizeV(SizV: TVec2; const ClearColor: TRColor);
begin
  SetSize(Round(SizV[0]), Round(SizV[1]), ClearColor);
end;

procedure TMZR.SetSizeR(R: TRectV2; const ClearColor: TRColor);
begin
  SetSizeF(RectWidth(R), RectHeight(R), ClearColor);
end;

procedure TMZR.SetSizeR(R: TRectV2);
begin
  SetSizeF(RectWidth(R), RectHeight(R));
end;

procedure TMZR.SetSizeR(R: TRect; const ClearColor: TRColor);
begin
  SetSizeR(RectV2(R), ClearColor);
end;

procedure TMZR.SetSizeR(R: TRect);
begin
  SetSizeR(RectV2(R));
end;

function TMZR.SizeOfPoint: TPoint;
begin
  Result := Point(Width, Height);
end;

function TMZR.SizeOf2DPoint: TVec2;
begin
  Result := Make2DPoint(Width, Height);
end;

function TMZR.Size2D: TVec2;
begin
  Result := Make2DPoint(Width, Height);
end;

function TMZR.Size0: TVec2;
begin
  Result := Make2DPoint(Width0, Height0);
end;

function TMZR.empty: Boolean;
begin
  Result := (FBits = nil) or (FWidth <= 0) or (FHeight <= 0);
end;

function TMZR.BoundsRect: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Width;
  Result.Bottom := Height;
end;

function TMZR.BoundsRect0: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Width0i;
  Result.Bottom := Height0i;
end;

function TMZR.BoundsRectV2: TRectV2;
begin
  Result := MakeRectV2(0, 0, Width, Height);
end;

function TMZR.BoundsRectV20: TRectV2;
begin
  Result := MakeRectV2(0, 0, Width0, Height0);
end;

function TMZR.BoundsV2Rect4: TV2Rect4;
begin
  Result := TV2Rect4.Init(BoundsRectV2, 0);
end;

function TMZR.BoundsV2Rect40: TV2Rect4;
begin
  Result := TV2Rect4.Init(BoundsRectV20, 0);
end;

function TMZR.Centroid: TVec2;
begin
  Result := Vec2(Width * 0.5, Height * 0.5);
end;

function TMZR.Centre: TVec2;
begin
  Result := Vec2(Width * 0.5, Height * 0.5);
end;

function TMZR.InHere(const X, Y: Integer): Boolean;
begin
  Result := PointInRect(X, Y, 0, 0, Width - 1, Height - 1);
end;

procedure TMZR.FlipHorz;
var
  I, J: Integer;
  p1, p2: PRColor;
  tmp: TRColor;
  W, W2: Integer;
begin
  CloseVertex;
  FreeAgg;

  W := Width;
  p1 := PRColor(Bits);
  p2 := p1;
  inc(p2, Width - 1);
  W2 := Width shr 1;
  for J := 0 to Height - 1 do
    begin
      for I := 0 to W2 - 1 do
        begin
          tmp := p1^;
          p1^ := p2^;
          p2^ := tmp;
          inc(p1);
          dec(p2);
        end;
      inc(p1, W - W2);
      inc(p2, W + W2);
    end;

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.FlipVert;
var
  J, j2: Integer;
  buffer: PRColorArray;
  p1, p2: PRColor;
begin
  CloseVertex;
  FreeAgg;
  j2 := Height - 1;
  buffer := System.GetMemory(Width shl 2);
  for J := 0 to Height div 2 - 1 do
    begin
      p1 := PixelPtr[0, J];
      p2 := PixelPtr[0, j2];
      CopyRColor(p1^, buffer^, Width);
      CopyRColor(p2^, p1^, Width);
      CopyRColor(buffer^, p2^, Width);
      dec(j2);
    end;
  System.FreeMemory(buffer);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Rotate90;
var
  tmp: TMZR;
  X, Y, I, J: Integer;
begin
  CloseVertex;
  FreeAgg;

  ReadyBits();

  tmp := TMZR.Create;

  tmp.SetSize(Height, Width);
  I := 0;
  for Y := 0 to Height - 1 do
    begin
      J := Height - 1 - Y;
      for X := 0 to Width - 1 do
        begin
          tmp.FBits^[J] := FBits^[I];
          inc(I);
          inc(J, Height);
        end;
    end;

  Reset;
  FWidth := tmp.FWidth;
  FHeight := tmp.FHeight;
  FBits := tmp.FBits;

  tmp.FWidth := 0;
  tmp.FHeight := 0;
  tmp.FBits := nil;
  DisposeObject(tmp);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Rotate180;
var
  I, i2: Integer;
  tmp: TRColor;
begin
  ReadyBits();
  i2 := Width * Height - 1;
  for I := 0 to Width * Height div 2 - 1 do
    begin
      tmp := FBits^[i2];
      FBits^[i2] := FBits^[I];
      FBits^[I] := tmp;
      dec(i2);
    end;
  DoChange;
end;

procedure TMZR.Rotate270;
var
  tmp: TMZR;
  X, Y, I, J: Integer;
begin
  CloseVertex;
  FreeAgg;

  ReadyBits();

  tmp := TMZR.Create;

  tmp.SetSize(Height, Width);
  I := 0;
  for Y := 0 to Height - 1 do
    begin
      J := (Width - 1) * Height + Y;
      for X := 0 to Width - 1 do
        begin
          tmp.FBits^[J] := FBits^[I];
          inc(I);
          dec(J, Height);
        end;
    end;

  Reset;
  FWidth := tmp.FWidth;
  FHeight := tmp.FHeight;
  FBits := tmp.FBits;

  tmp.FWidth := 0;
  tmp.FHeight := 0;
  tmp.FBits := nil;
  DisposeObject(tmp);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

function TMZR.Rotate(dest: TMZR; Angle: TGeoFloat; Edge: Integer): TV2R4;
begin
  Result := TV2Rect4.Init(BoundsRectV20(), Angle).TransformToRect(dest.BoundsRectV20(), Edge);
  ProjectionTo(dest, BoundsV2Rect40(), Result, True, 1.0);
end;

function TMZR.Rotate(Angle: TGeoFloat; Edge: Integer; BackgroundColor: TRColor): TV2R4;
var
  n: TMZR;
  V: TV2Rect4;
  R: TRectV2;
begin
  CloseVertex;
  FreeAgg;

  V := TV2Rect4.Init(BoundsRectV20(), Angle);
  R := V.BoundRect;

  n := TMZR.Create;
  n.SetSizeF(RectWidth(R) + Edge * 2, RectHeight(R) + Edge * 2, BackgroundColor);
  Result := Rotate(n, Angle, Edge);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

function TMZR.Rotate(dest: TMZR; Axis: TVec2; Angle: TGeoFloat; Edge: Integer): TV2R4;
begin
  Result := TV2Rect4.Init(BoundsRectV20, Axis, Angle).TransformToRect(dest.BoundsRectV20, Edge);
  ProjectionTo(dest, BoundsV2Rect40, Result, True, 1.0);
end;

function TMZR.Rotate(Axis: TVec2; Angle: TGeoFloat; Edge: Integer; BackgroundColor: TRColor): TV2R4;
var
  n: TMZR;
  V: TV2Rect4;
  R: TRectV2;
begin
  CloseVertex;
  FreeAgg;

  V := TV2Rect4.Init(BoundsRectV20, Axis, Angle);
  R := V.BoundRect;

  n := TMZR.Create;
  n.SetSizeF(RectWidth(R) + Edge * 2, RectHeight(R) + Edge * 2, BackgroundColor);
  Result := Rotate(n, Angle, Edge);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.CalibrateRotate_LineDistance(BackgroundColor: TRColor);
var
  BestLines_: THoughLineArry;
begin
  if empty then
      exit;
  BestLines_ := BuildZRHoughLine(45, 0.1, 50, Self);
  Rotate(-DocumentRotationDetected_MaxDistance(BestLines_), 0, BackgroundColor);
  SetLength(BestLines_, 0);
end;

procedure TMZR.CalibrateRotate_LineMatched(BackgroundColor: TRColor);
var
  BestLines_: THoughLineArry;
begin
  if empty then
      exit;
  BestLines_ := BuildZRHoughLine(45, 0.1, 50, Self);
  Rotate(-DocumentRotationDetected_MaxMatched(BestLines_), 0, BackgroundColor);
  SetLength(BestLines_, 0);
end;

procedure TMZR.CalibrateRotate_AVG(BackgroundColor: TRColor);
var
  BestLines_: THoughLineArry;
begin
  if empty then
      exit;
  BestLines_ := BuildZRHoughLine(45, 0.1, 50, Self);
  Rotate(-DocumentRotationDetected_AVG(BestLines_), 0, BackgroundColor);
  SetLength(BestLines_, 0);
end;

procedure TMZR.CalibrateRotate(BackgroundColor: TRColor);
begin
  CalibrateRotate_AVG(BackgroundColor);
end;

procedure TMZR.CalibrateRotate;
begin
  CalibrateRotate(RColor(0, 0, 0, 0));
end;

procedure TMZR.NonlinearZoomLine(const Source, dest: TMZR; const pass: Integer);
var
  J: Integer;
  SourceI, SourceJ: Double;
  SourceIInt, SourceJInt: Integer;
  SourceINext, SourceJNext: Integer;
begin
  for J := 0 to dest.Height - 1 do
    begin
      SourceI := pass / dest.Width0 * Source.Width0;
      SourceJ := J / dest.Height0 * Source.Height0;

      SourceIInt := Trunc(SourceI);
      SourceJInt := Trunc(SourceJ);

      dest.FastPixel[pass, J] := Source.FastPixel[SourceIInt, SourceJInt];
    end;
end;

procedure TMZR.NonlinearZoomFrom(const Source: TMZR; const NewWidth, NewHeight: Integer);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    NonlinearZoomLine(Source, Self, pass);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    I: Integer;
  begin
    for I := Width - 1 downto 0 do
        NonlinearZoomLine(Source, Self, I);
  end;

begin
  if (Source.Width = NewWidth) and (Source.Height = NewHeight) then
    begin
      Assign(Source);
      exit;
    end;
  SetSize(NewWidth, NewHeight);

  if (Source.Width > 1) and (Source.Width > 1) and (Width > 1) and (Height > 1) then
    begin
      if TMZR.Parallel and LocalParallel and (NewHeight * NewWidth > 800 * 800) then
        begin
{$IFDEF Parallel}
{$IFDEF FPC}
          FPCParallelFor(Nested_ParallelFor, 0, Width - 1);
{$ELSE}
          DelphiParallelFor(0, Width - 1, procedure(pass: Integer)
            begin
              NonlinearZoomLine(Source, Self, pass);
            end);
{$ENDIF FPC}
{$ELSE}
          DoFor();
{$ENDIF Parallel}
        end
      else
          DoFor();
    end;
  DoChange;
end;

procedure TMZR.NonlinearZoom(const NewWidth, NewHeight: Integer);
var
  n: TMZR;
begin
  CloseVertex;
  FreeAgg;

  n := TMZR.Create;
  n.NonlinearZoomFrom(Self, NewWidth, NewHeight);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.ZoomLine(const Source, dest: TMZR; const pass: Integer);
var
  J: Integer;
  SourceI, SourceJ: Double;
begin
  for J := 0 to dest.Height - 1 do
    begin
      SourceI := pass / dest.Width0;
      SourceJ := J / dest.Height0;

      dest.FastPixel[pass, J] := Source.PixelLinearMetric[SourceI, SourceJ];
    end;
end;

procedure TMZR.ZoomFrom(const Source: TMZR; const NewWidth, NewHeight: Integer);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    ZoomLine(Source, Self, pass);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    I: Integer;
  begin
    for I := Width - 1 downto 0 do
        ZoomLine(Source, Self, I);
  end;

begin
  if (Source.Width = NewWidth) and (Source.Height = NewHeight) then
    begin
      Assign(Source);
      exit;
    end;
  SetSize(NewWidth, NewHeight);

  if (Source.Width > 1) and (Source.Width > 1) and (Width > 1) and (Height > 1) then
    begin
      if TMZR.Parallel and LocalParallel and (NewHeight * NewWidth > 800 * 800) then
        begin
{$IFDEF Parallel}
{$IFDEF FPC}
          FPCParallelFor(Nested_ParallelFor, 0, Width - 1);
{$ELSE}
          DelphiParallelFor(0, Width - 1, procedure(pass: Integer)
            begin
              ZoomLine(Source, Self, pass);
            end);
{$ENDIF FPC}
{$ELSE}
          DoFor();
{$ENDIF Parallel}
        end
      else
          DoFor();
    end;
  DoChange;
end;

procedure TMZR.ZoomFrom(const Source: TMZR; const f: TGeoFloat);
begin
  ZoomFrom(Source, Round(Source.Width * f), Round(Source.Height * f));
end;

procedure TMZR.Zoom(const NewWidth, NewHeight: Integer);
var
  n: TMZR;
begin
  CloseVertex;
  FreeAgg;

  n := TMZR.Create;
  n.ZoomFrom(Self, NewWidth, NewHeight);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.FastBlurZoomFrom(const Source: TMZR; const NewWidth, NewHeight: Integer);
var
  k1, k2: Double;
  n: TMZR;
begin
  if (Source.Width = NewWidth) and (Source.Height = NewHeight) then
    begin
      Assign(Source);
      exit;
    end;
  k1 := Max(NewWidth / Source.Width, NewHeight / Source.Height);
  k2 := Max(Source.Width / NewWidth, Source.Height / NewHeight);
  if (k1 < 1.0) then
    begin
      n := TMZR.Create;
      // preprocess zoom
      FastBlur(Source, n, k2 * 0.5, Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end
  else
    begin
      // zoom
      n := TMZR.Create;
      // preprocess zoom
      FastBlur(Source, n, Min(2, k1 * 0.5), Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end;
  DoChange;
end;

procedure TMZR.FastBlurZoom(const NewWidth, NewHeight: Integer);
var
  n: TMZR;
begin
  CloseVertex;
  FreeAgg;

  n := TMZR.Create;
  n.FastBlurZoomFrom(Self, NewWidth, NewHeight);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.GaussianBlurZoomFrom(const Source: TMZR; const NewWidth, NewHeight: Integer);
var
  k1, k2: Double;
  n: TMZR;
begin
  if (Source.Width = NewWidth) and (Source.Height = NewHeight) then
    begin
      Assign(Source);
      exit;
    end;

  k1 := Max(NewWidth / Source.Width, NewHeight / Source.Height);
  k2 := Max(Source.Width / NewWidth, Source.Height / NewHeight);
  if (k1 < 1.0) then
    begin
      n := TMZR.Create;
      // preprocess zoom
      GaussianBlur(Source, n, k2 * 0.5, Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end
  else
    begin
      n := TMZR.Create;
      // preprocess zoom
      GaussianBlur(Source, n, Min(2, k1 * 0.5), Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end;
  DoChange;
end;

procedure TMZR.GaussianBlurZoom(const NewWidth, NewHeight: Integer);
var
  n: TMZR;
begin
  CloseVertex;
  FreeAgg;

  n := TMZR.Create;
  n.GaussianBlurZoomFrom(Self, NewWidth, NewHeight);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.GrayscaleBlurZoomFrom(const Source: TMZR; const NewWidth, NewHeight: Integer);
var
  k1, k2: Double;
  n: TMZR;
begin
  if (Source.Width = NewWidth) and (Source.Height = NewHeight) then
    begin
      Assign(Source);
      Grayscale;
      exit;
    end;
  k1 := Max(NewWidth / Source.Width, NewHeight / Source.Height);
  k2 := Max(Source.Width / NewWidth, Source.Height / NewHeight);
  if (k1 < 1.0) then
    begin
      n := TMZR.Create;
      // preprocess zoom
      GrayscaleBlur(Source, n, k2 * 0.5, Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end
  else
    begin
      n := TMZR.Create;
      // preprocess zoom
      GrayscaleBlur(Source, n, Min(2, k1 * 0.5), Source.BoundsRect);
      // zoom
      ZoomFrom(n, NewWidth, NewHeight);
      DisposeObject(n);
    end;
  DoChange;
end;

procedure TMZR.GrayscaleBlurZoom(const NewWidth, NewHeight: Integer);
var
  n: TMZR;
begin
  CloseVertex;
  FreeAgg;

  n := TMZR.Create;
  n.GrayscaleBlurZoomFrom(Self, NewWidth, NewHeight);
  Reset;
  FWidth := n.Width;
  FHeight := n.Height;
  FBits := n.Bits;

  n.FBits := nil;
  n.FWidth := 0;
  n.FHeight := 0;
  DisposeObject(n);

  if FAggNeed then
      OpenAgg;
  Safe_ResetSerialized;
  DoChange;
end;

procedure TMZR.Scale(K: TGeoFloat);
begin
  Zoom(Round(Width * K), Round(Height * K));
end;

procedure TMZR.FastBlurScale(K: TGeoFloat);
begin
  FastBlurZoom(Round(Width * K), Round(Height * K));
end;

procedure TMZR.GaussianBlurScale(K: TGeoFloat);
begin
  GaussianBlurZoom(Round(Width * K), Round(Height * K));
end;

procedure TMZR.NonlinearScale(K: TGeoFloat);
begin
  NonlinearZoom(Round(Width * K), Round(Height * K));
end;

procedure TMZR.FastBlur_FitScale(NewWidth, NewHeight: TGeoFloat);
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  FastBlurZoom(Round(RectWidth(R)), Round(RectHeight(R)));
end;

procedure TMZR.GaussianBlur_FitScale(NewWidth, NewHeight: TGeoFloat);
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  GaussianBlurZoom(Round(RectWidth(R)), Round(RectHeight(R)));
end;

procedure TMZR.FitScale(NewWidth, NewHeight: TGeoFloat);
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  Zoom(Round(RectWidth(R)), Round(RectHeight(R)));
end;

procedure TMZR.FitScale(R: TRectV2);
var
  R_: TRectV2;
begin
  R_ := FitRect(BoundsRectV2, R);
  Zoom(Round(RectWidth(R_)), Round(RectHeight(R_)));
end;

procedure TMZR.FitScaleTo(NewWidth, NewHeight: TGeoFloat; Output: TMZR);
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  Output.ZoomFrom(Self, Round(RectWidth(R)), Round(RectHeight(R)));
end;

function TMZR.FitScaleAsNew(NewWidth, NewHeight: TGeoFloat): TMZR;
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  Result := NewZR();
  Result.ZoomFrom(Self, Round(RectWidth(R)), Round(RectHeight(R)));
end;

function TMZR.FitScaleAsNew(R: TRectV2): TMZR;
var
  R_: TRectV2;
begin
  R_ := FitRect(BoundsRectV2, R);
  Result := NewZR();
  Result.ZoomFrom(Self, Round(RectWidth(R_)), Round(RectHeight(R_)));
end;

function TMZR.NonlinearFitScaleAsNew(NewWidth, NewHeight: TGeoFloat): TMZR;
var
  R: TRectV2;
begin
  R := FitRect(BoundsRectV2, RectV2(0, 0, NewWidth, NewHeight));
  Result := NewZR();
  Result.NonlinearZoomFrom(Self, Round(RectWidth(R)), Round(RectHeight(R)));
end;

function TMZR.NonlinearFitScaleAsNew(R: TRectV2): TMZR;
var
  R_: TRectV2;
begin
  R_ := FitRect(BoundsRectV2, R);
  Result := NewZR();
  Result.NonlinearZoomFrom(Self, Round(RectWidth(R_)), Round(RectHeight(R_)));
end;

procedure TMZR.InnerFitScale(Scale_X, Scale_Y: TGeoFloat);
var
  nR: TZR;
begin
  nR := NewZR();
  InnerFitScaleTo(Scale_X, Scale_Y, nR);
  // done
  SwapInstance(nR);
  Update;
  DisposeObject(nR);
end;

procedure TMZR.InnerFitScale(Scale_: TVec2);
begin
  InnerFitScale(Scale_[0], Scale_[1]);
end;

procedure TMZR.InnerFitScaleTo(Scale_X, Scale_Y: TGeoFloat; Output: TMZR);
var
  dest: TRectV2;
begin
  // compute inner fix box
  dest := FitRect(Scale_X, Scale_Y, BoundsRectV20);
  // build new raster
  Output.SetSizeR(dest);
  ProjectionTo(Output, dest, Output.BoundsRectV20, True, 1.0);
end;

function TMZR.InnerFitScaleAsNew(Scale_X, Scale_Y: TGeoFloat): TMZR;
begin
  Result := NewZR();
  InnerFitScaleTo(Scale_X, Scale_Y, Result);
end;

procedure TMZR.InnerFitScaleAndFitResizeTo(Scale_X, Scale_Y, NewWidth, NewHeight: TGeoFloat; Output: TMZR);
var
  dest1, dest2: TRectV2;
begin
  // compute inner fix box
  dest1 := FitRect(Scale_X, Scale_Y, BoundsRectV20);
  dest2 := FitRect(dest1, RectV2(0, 0, NewWidth, NewHeight));
  // build new raster
  Output.SetSizeR(dest2);
  ProjectionTo(Output, dest1, Output.BoundsRectV20, True, 1.0);
end;

function TMZR.InnerFitScaleAndFitResizeAsNew(Scale_X, Scale_Y, NewWidth, NewHeight: TGeoFloat): TMZR;
begin
  Result := NewZR();
  InnerFitScaleAndFitResizeTo(Scale_X, Scale_Y, NewWidth, NewHeight, Result);
end;

procedure TMZR.SigmaGaussian(const SIGMA: TGeoFloat; const SigmaGaussianKernelFactor: Integer);
begin
  PixelSigmaGaussianSampler(True, Self, Self, SIGMA, SigmaGaussianKernelFactor);
  DoChange;
end;

procedure TMZR.SigmaGaussian(const SIGMA: TGeoFloat);
begin
  SigmaGaussian(True, SIGMA, 3);
end;

procedure TMZR.SigmaGaussian(parallel_: Boolean; const SIGMA: TGeoFloat; const SigmaGaussianKernelFactor: Integer);
begin
  PixelSigmaGaussianSampler(parallel_, Self, Self, SIGMA, SigmaGaussianKernelFactor);
  DoChange;
end;

procedure TMZR.SigmaGaussian(parallel_: Boolean; const SIGMA: TGeoFloat);
begin
  SigmaGaussian(parallel_, SIGMA, 3);
end;

function TMZR.FormatAsBGRA: TMZR;
var
  dest: TMZR;
  pass: Integer;
begin
  ReadyBits();
  dest := TMZR.Create;
  dest.SetSize(Width, Height);
  for pass := (Width * Height) - 1 downto 0 do
      dest.FBits^[pass] := RGBA2BGRA(FBits^[pass]);

  Result := dest;
end;

procedure TMZR.FormatBGRA;
var
  pass: Integer;
begin
  ReadyBits();
  for pass := (Width * Height) - 1 downto 0 do
      SwapBR(FBits^[pass]);
  DoChange;
end;

function TMZR.BuildRGB(cSwapBR: Boolean): PRGBArray;
begin
  Result := System.GetMemory(Width * Height * 3);
  OutputRGB(Result^, cSwapBR);
end;

procedure TMZR.InputRGB(var buff; W, H: Integer; cSwapBR: Boolean);
var
  pass: Integer;
  p: PByte;
begin
  if (Width <> W) or (Height <> H) then
      SetSize(W, H);

  ReadyBits();
  p := @buff;
  for pass := 0 to (Width * Height) - 1 do
    begin
      FBits^[pass] := RGB2RGBA(PRGB(p)^);
      if cSwapBR then
          SwapBR(FBits^[pass]);
      inc(p, 3);
    end;
  DoChange;
end;

procedure TMZR.OutputRGB(var buff; cSwapBR: Boolean);
var
  p: PByte;
  pass: Integer;
begin
  ReadyBits();
  p := @buff;
  for pass := 0 to (Width * Height) - 1 do
    begin
      PRGB(p)^ := PRGB(@FBits^[pass])^;
      if cSwapBR then
          SwapBR(PRGB(p)^);
      inc(p, 3);
    end;
end;

function TMZR.FastEncryptGrayscale(): PByteBuffer;
var
  siz: NativeInt;
  p: PByteBuffer;
  I: Integer;
begin
  siz := Width * Height;
  p := System.GetMemory(siz);
  ReadyBits();
  for I := 0 to siz - 1 do
      p^[I] := RColor2FastGray(DirectBits^[I]);
  Result := p;
end;

function TMZR.EncryptGrayscale(): PByteBuffer;
var
  siz: NativeInt;
  p: PByteBuffer;
  I: Integer;
begin
  siz := Width * Height;
  p := System.GetMemory(siz);
  ReadyBits();
  for I := 0 to siz - 1 do
      p^[I] := RColor2Gray(DirectBits^[I]);
  Result := p;
end;

function TMZR.EncryptColor255(): PByteBuffer;
var
  siz: NativeInt;
  p: PByteBuffer;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    p^[pass] := FindColor255Index(DirectBits^[pass]);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to siz - 1 do
      begin
        p^[pass] := FindColor255Index(DirectBits^[pass]);
      end;
  end;

begin
  siz := Width * Height;
  p := System.GetMemory(siz);

  ReadyBits();

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, siz - 1);
{$ELSE FPC}
      DelphiParallelFor(0, siz - 1, procedure(pass: Integer)
        begin
          p^[pass] := FindColor255Index(DirectBits^[pass]);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  Result := p;
end;

function TMZR.EncryptColor65535(): PWordBuffer;
var
  siz: NativeInt;
  p: PWordBuffer;
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    p^[pass] := FindColor65535Index(DirectBits^[pass]);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to siz - 1 do
      begin
        p^[pass] := FindColor65535Index(DirectBits^[pass]);
      end;
  end;

begin
  siz := Width * Height;
  p := System.GetMemory(siz * 2);

  ReadyBits();

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, siz - 1);
{$ELSE FPC}
      DelphiParallelFor(0, siz - 1, procedure(pass: Integer)
        begin
          p^[pass] := FindColor65535Index(DirectBits^[pass]);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  Result := p;
end;

procedure TMZR.DecryptGrayscale(Width_, Height_: Integer; buffer: PByteBuffer);
var
  I: Integer;
begin
  SetSize(Width_, Height_);
  for I := 0 to Width_ * Height_ - 1 do
      DirectBits^[I] := RColor(buffer^[I], buffer^[I], buffer^[I]);
end;

procedure TMZR.DecryptColor255(Width_, Height_: Integer; buffer: PByteBuffer);
var
  I: Integer;
begin
  SetSize(Width_, Height_);
  for I := 0 to Width_ * Height_ - 1 do
      DirectBits^[I] := Color255[buffer^[I]];
end;

procedure TMZR.DecryptColor65535(Width_, Height_: Integer; buffer: PWordBuffer);
var
  I: Integer;
begin
  SetSize(Width_, Height_);
  for I := 0 to Width_ * Height_ - 1 do
      DirectBits^[I] := Color64K[buffer^[I]];
end;

procedure TMZR.ColorReplace(const old_c, new_c: TRColor);
var
  pass: Integer;
  p: PRColor;
begin
  pass := Width * Height;
  if pass <= 0 then
      exit;
  ReadyBits();
  p := @FBits^[0];
  while pass > 0 do
    begin
      if p^ = old_c then
          p^ := new_c;
      inc(p);
      dec(pass);
    end;
  DoChange;
end;

procedure TMZR.ColorTransparent(c_: TRColor);
var
  pass: Integer;
  p: PRColor;
  C: TRColor;
begin
  pass := Width * Height;
  if pass <= 0 then
      exit;
  C := ZRAlphaColor(c_, 0);
  ReadyBits();
  p := @FBits^[0];
  while pass > 0 do
    begin
      if ZRAlphaColor(p^, 0) = C then
          p^ := 0;
      inc(p);
      dec(pass);
    end;
  DoChange;
end;

procedure TMZR.ColorBlend(C: TRColor);
var
  pass: Integer;
  p: PRColor;
begin
  pass := Width * Height;
  if pass <= 0 then
      exit;
  ReadyBits();
  p := @FBits^[0];
  while pass > 0 do
    begin
      p^ := BlendReg(p^, C);
      inc(p);
      dec(pass);
    end;
  DoChange;
end;

procedure TMZR.FastGrayscale;
var
  I: Integer;
  p: PRColorEntry;
begin
  ReadyBits();
  for I := (Width * Height) - 1 downto 0 do
    begin
      p := @FBits^[I];
      p^.R := RColor2FastGray(p^.BGRA);
      p^.G := p^.R;
      p^.B := p^.R;
    end;
  DoChange;
end;

procedure TMZR.Grayscale;
var
  I: Integer;
  p: PRColorEntry;
begin
  ReadyBits();
  for I := (Width * Height) - 1 downto 0 do
    begin
      p := @FBits^[I];
      p^.R := RColor2Gray(p^.BGRA);
      p^.G := p^.R;
      p^.B := p^.R;
    end;
  DoChange;
end;

procedure TMZR.Grayscale_Gradient(level: Byte);
var
  I: Integer;
  p: PRColorEntry;
  f: TGeoFloat;
begin
  if level = $FF then
      Grayscale
  else
    begin
      f := $FF / level;
      ReadyBits();
      for I := (Width * Height) - 1 downto 0 do
        begin
          p := @FBits^[I];
          p^.R := Round(Trunc(RColor2Gray(p^.BGRA) / f) * f);
          p^.G := p^.R;
          p^.B := p^.R;
        end;
    end;
  DoChange;
end;

procedure TMZR.Gradient(level: Byte);
var
  I: Integer;
  p: PRColorEntry;
  f: TGeoFloat;
begin
  if level = $FF then
      Grayscale
  else
    begin
      f := $FF / level;
      ReadyBits();
      for I := (Width * Height) - 1 downto 0 do
        begin
          p := @FBits^[I];
          p^.R := Round(Trunc(p^.R / f) * f);
          p^.G := Round(Trunc(p^.G / f) * f);
          p^.B := Round(Trunc(p^.B / f) * f);
        end;
    end;
  DoChange;
end;

procedure TMZR.ExtractGray(var Output: TByteZR);
var
  I, J: Integer;
begin
  SetLength(Output, FHeight, FWidth);
  for J := 0 to FHeight - 1 do
    for I := 0 to FWidth - 1 do
        Output[J, I] := PixelGray[I, J];
end;

procedure TMZR.ExtractRed(var Output: TByteZR);
var
  I, J: Integer;
begin
  SetLength(Output, FHeight, FWidth);
  for J := 0 to FHeight - 1 do
    for I := 0 to FWidth - 1 do
        Output[J, I] := PixelRed[I, J];
end;

procedure TMZR.ExtractGreen(var Output: TByteZR);
var
  I, J: Integer;
begin
  SetLength(Output, FHeight, FWidth);
  for J := 0 to FHeight - 1 do
    for I := 0 to FWidth - 1 do
        Output[J, I] := PixelGreen[I, J];
end;

procedure TMZR.ExtractBlue(var Output: TByteZR);
var
  I, J: Integer;
begin
  SetLength(Output, FHeight, FWidth);
  for J := 0 to FHeight - 1 do
    for I := 0 to FWidth - 1 do
        Output[J, I] := PixelBlue[I, J];
end;

procedure TMZR.ExtractAlpha(var Output: TByteZR);
var
  I, J: Integer;
begin
  SetLength(Output, FHeight, FWidth);
  for J := 0 to FHeight - 1 do
    for I := 0 to FWidth - 1 do
        Output[J, I] := PixelAlpha[I, J];
end;

function TMZR.ComputeArea_MinLoss_ScaleSpace_NoEdge_Clip(clipArea: TRectV2; SS_width, SS_height: TGeoFloat): TRectV2;
begin
  Result := MinLoss_RectScaleSpace(clipArea, SS_width, SS_height);
end;

function TMZR.ComputeAreaScaleSpace_NoEdge_Clip(clipArea: TRectV2; SS_width, SS_height: TGeoFloat): TRectV2;
begin
  Result := RectScaleSpace(clipArea, SS_width, SS_height);
end;

function TMZR.ComputeAreaScaleSpace(clipArea: TRectV2; SS_width, SS_height: TGeoFloat): TRectV2;
var
  R: TRectV2;
begin
  R := RectScaleSpace(clipArea, SS_width, SS_height);
  R[0, 0] := Max(R[0, 0], 0);
  R[0, 1] := Max(R[0, 1], 0);
  R[1, 0] := Min(R[1, 0], Width0);
  R[1, 1] := Min(R[1, 1], Height0);

  Result := R;
end;

function TMZR.ComputeAreaScaleSpace(clipArea: TRect; SS_width, SS_height: Integer): TRect;
begin
  Result := MakeRect(ComputeAreaScaleSpace(RectV2(clipArea), SS_width, SS_height));
end;

function TMZR.BuildAreaOffset_MinLoss_ScaleSpace(clipArea: TRectV2; SS_width, SS_height: Integer): TMZR;
begin
  Result := NewZR();
  Result.SetSize(SS_width, SS_height);
  ProjectionTo(Result, TV2Rect4.Init(MinLoss_RectScaleSpace(clipArea, SS_width, SS_height), 0), TV2Rect4.Init(Result.BoundsRectV2, 0), True, 1.0);
end;

function TMZR.BuildAreaOffset_MinLoss_ScaleSpace(clipArea: TRect; SS_width, SS_height: Integer): TMZR;
begin
  Result := BuildAreaOffset_MinLoss_ScaleSpace(RectV2(clipArea), SS_width, SS_height);
end;

function TMZR.BuildAreaOffsetScaleSpace(clipArea: TRectV2; SS_width, SS_height: Integer): TMZR;
begin
  Result := NewZR();
  Result.SetSize(SS_width, SS_height);
  ProjectionTo(Result, TV2Rect4.Init(ComputeAreaScaleSpace(clipArea, SS_width, SS_height), 0), TV2Rect4.Init(Result.BoundsRectV2, 0), True, 1.0);
end;

function TMZR.BuildAreaOffsetScaleSpace(clipArea: TRect; SS_width, SS_height: Integer): TMZR;
begin
  Result := BuildAreaOffsetScaleSpace(RectV2(clipArea), SS_width, SS_height);
end;

function TMZR.BuildAreaCopyAs(clipArea: TRectV2): TMZR;
var
  R: TRectV2;
  W, H: TGeoFloat;
begin
  R := FixRect(clipArea);
  W := RectWidth(R);
  H := RectHeight(R);

  Result := NewZR();
  Result.SetSize(Round(W), Round(H));
  ProjectionTo(Result, TV2Rect4.Init(R, 0), TV2Rect4.Init(Result.BoundsRectV2, 0), True, 1.0);
end;

function TMZR.BuildAreaCopyAs(clipArea: TRect): TMZR;
begin
  Result := BuildAreaCopyAs(RectV2(clipArea));
end;

function TMZR.Build_Jitter_Fit_Box_Raster(rand: TMT19937Random; scale_size, scale_pos: TVec2; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; Fit_Matrix_Box_: Boolean; output_Size: TVec2; lock_sampler: Boolean; var sampling_box: TV2R4): TMZR;
var
  dest_box: TRectV2;
  dest_angle: TGeoFloat;
begin
  Make_Image_Jitter_Box(rand, BoundsRectV20, scale_size, scale_pos, XY_Offset_Scale_, Rotate_, Scale_, Fit_Matrix_Box_, output_Size, dest_box, dest_angle);
  sampling_box := TV2R4.Init(dest_box, dest_angle);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, sampling_box, Result.BoundsV2Rect40, True, 1.0);
end;

function TMZR.Build_Jitter_Fit_Box_Raster(rand: TMT19937Random; scale_size, scale_pos: TVec2; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; Fit_Matrix_Box_: Boolean; output_Size: TVec2; lock_sampler: Boolean): TMZR;
var
  dest_box: TRectV2;
  dest_angle: TGeoFloat;
  sampling_box: TV2R4;
begin
  Make_Image_Jitter_Box(rand, BoundsRectV20, scale_size, scale_pos, XY_Offset_Scale_, Rotate_, Scale_, Fit_Matrix_Box_, output_Size, dest_box, dest_angle);
  sampling_box := TV2R4.Init(dest_box, dest_angle);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, sampling_box, Result.BoundsV2Rect40, True, 1.0);
end;

function TMZR.Build_Jitter_Fit_Box_Raster(scale_size, scale_pos: TVec2; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; Fit_Matrix_Box_: Boolean; output_Size: TVec2; lock_sampler: Boolean; var sampling_box: TV2R4): TMZR;
var
  dest_box: TRectV2;
  dest_angle: TGeoFloat;
begin
  Make_Image_Jitter_Box(BoundsRectV20, scale_size, scale_pos, XY_Offset_Scale_, Rotate_, Scale_, Fit_Matrix_Box_, output_Size, dest_box, dest_angle);
  sampling_box := TV2R4.Init(dest_box, dest_angle);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, sampling_box, Result.BoundsV2Rect40, True, 1.0);
end;

function TMZR.Build_Jitter_Fit_Box_Raster(scale_size, scale_pos: TVec2; XY_Offset_Scale_, Rotate_, Scale_: TGeoFloat; Fit_Matrix_Box_: Boolean; output_Size: TVec2; lock_sampler: Boolean): TMZR;
var
  dest_box: TRectV2;
  dest_angle: TGeoFloat;
  sampling_box: TV2R4;
begin
  Make_Image_Jitter_Box(BoundsRectV20, scale_size, scale_pos, XY_Offset_Scale_, Rotate_, Scale_, Fit_Matrix_Box_, output_Size, dest_box, dest_angle);
  sampling_box := TV2R4.Init(dest_box, dest_angle);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, sampling_box, Result.BoundsV2Rect40, True, 1.0);
end;

function TMZR.Build_Fit_Box_Raster(scale_size, scale_pos: TVec2; output_Size: TVec2; Fit_Matrix_Box_, lock_sampler: Boolean; var sampling_box: TV2R4): TMZR;
var
  dest_box: TRectV2;
begin
  dest_box := Compute_Scale_Position_To_Min_Edge_Box_Size(BoundsRectV20, scale_size, scale_pos);
  if Fit_Matrix_Box_ then
      dest_box := MinLoss_RectFit(output_Size[0], output_Size[1], dest_box);
  sampling_box := TV2R4.Init(dest_box, 0);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, dest_box, Result.BoundsRectV20, True, 1.0);
end;

function TMZR.Build_Fit_Box_Raster(scale_size, scale_pos: TVec2; output_Size: TVec2; Fit_Matrix_Box_, lock_sampler: Boolean): TMZR;
var
  dest_box: TRectV2;
begin
  dest_box := Compute_Scale_Position_To_Min_Edge_Box_Size(BoundsRectV20, scale_size, scale_pos);
  if Fit_Matrix_Box_ then
      dest_box := MinLoss_RectFit(output_Size[0], output_Size[1], dest_box);
  Result := NewZR();
  Result.SetSizeF(output_Size[0], output_Size[1], RColor(0, 0, 0, $FF));
  Result.Vertex.LockSamplerCoord := lock_sampler;
  ProjectionTo(Result, dest_box, Result.BoundsRectV20, True, 1.0);
end;

function TMZR.FastAreaCopyAs(X1, Y1, X2, Y2: TGeoInt): TMZR;
var
  W, H, J, I: Integer;
begin
  ForwardRect(X1, Y1, X2, Y2);
  W := X2 - X1;
  H := Y2 - Y1;
  Result := NewZR();
  Result.SetSize(W, H);
  ReadyBits;
  for J := 0 to W - 1 do
    for I := 0 to H - 1 do
      if InHere(I + X1, J + Y1) then
          Result.FastPixel[I, J] := FastPixel[I + X1, J + Y1]
      else
          Result.FastPixel[I, J] := RColor(0, 0, 0);
end;

procedure TMZR.FastAreaCopyFrom(Source: TMZR; DestX, DestY: Integer);
var
  I, J: Integer;
begin
  for J := 0 to Source.Height - 1 do
    for I := 0 to Source.Width - 1 do
      if InHere(I + DestX, J + DestY) then
          FastPixel[I + DestX, J + DestY] := Source.FastPixel[I, J];
  DoChange;
end;

function TMZR.ExistsColor(C: TRColor): Boolean;
var
  I, J: Integer;
begin
  Result := True;
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] = C then
          exit;
  Result := False;
end;

function TMZR.FindFirstColor(C: TRColor): TPoint;
var
  I, J: Integer;
begin
  Result := Point(-1, -1);
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] = C then
        begin
          Result := Point(I, J);
          exit;
        end;
end;

function TMZR.FindLastColor(C: TRColor): TPoint;
var
  I, J: Integer;
begin
  Result := Point(-1, -1);
  for J := Height - 1 downto 0 do
    for I := Width - 1 downto 0 do
      if Pixel[I, J] = C then
        begin
          Result := Point(I, J);
          exit;
        end;
end;

function TMZR.FindNearColor(C: TRColor; Pt: TVec2): TPoint;
var
  I, J: Integer;
  npt: TVec2;
  d1, d2: TGeoFloat;
  pt_X, pt_Y: Integer;
begin
  Result := Point(-1, -1);
  npt := Vec2(-1, -1);
  d2 := Vec2Distance(npt, Pt);
  d1 := d2;
  pt_X := Round(Pt[0]);
  pt_Y := Round(Pt[1]);

  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if (Pixel[I, J] = C) and ((pt_X <> I) or (pt_Y <> J)) then
        begin
          d2 := Vec2Distance(Vec2(I, J), Pt);
          if d2 < d1 then
            begin
              npt := Vec2(I, J);
              d1 := d2;
            end;
        end;

  if (npt[0] >= 0) and (npt[1] >= 0) then
      Result := MakePoint(npt);
end;

function TMZR.ColorBoundsRectV2(C: TRColor): TRectV2;
var
  color_inited_: Boolean;
  I, J: Integer;
begin
  color_inited_ := False;
  Result := NullRectV2;
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] = C then
        begin
          if not color_inited_ then
            begin
              color_inited_ := True;
              Result[0] := Vec2(I, J);
              Result[1] := Result[0];
            end
          else
              Result := BoundRect(Result[0], Result[1], Vec2(I, J));
        end;
end;

function TMZR.ColorBoundsRect(C: TRColor): TRect;
var
  color_inited_: Boolean;
  I, J: Integer;
begin
  color_inited_ := False;
  Result := Rect(0, 0, 0, 0);
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] = C then
        begin
          if not color_inited_ then
            begin
              color_inited_ := True;
              Result.TopLeft := Point(I, J);
              Result.Bottomright := Result.TopLeft;
            end
          else
              Result := BoundRect(Result.TopLeft, Result.Bottomright, Point(I, J));
        end;
end;

function TMZR.ConvexHull(C: TRColor): TV2L;
var
  I, J: Integer;
  found: Boolean;
begin
  Result := TV2L.Create;
  for J := 0 to Height - 1 do
    begin
      found := False;
      for I := 0 to Width - 1 do
        if found then
          begin
            if Pixel[I, J] <> C then
              begin
                Result.Add(I, J);
                found := False;
              end;
          end
        else if Pixel[I, J] = C then
          begin
            Result.Add(I, J);
            found := True;
          end;
    end;
end;

function TMZR.NoneColorBoundsRectV2(C: TRColor): TRectV2;
var
  color_inited_: Boolean;
  I, J: Integer;
begin
  color_inited_ := False;
  Result := NullRectV2;
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] <> C then
        begin
          if not color_inited_ then
            begin
              color_inited_ := True;
              Result[0] := Vec2(I, J);
              Result[1] := Result[0];
            end
          else
              Result := BoundRect(Result[0], Result[1], Vec2(I, J));
        end;
end;

function TMZR.NoneColorBoundsRect(C: TRColor): TRect;
var
  color_inited_: Boolean;
  I, J: Integer;
begin
  color_inited_ := False;
  Result := Rect(0, 0, 0, 0);
  for J := 0 to Height - 1 do
    for I := 0 to Width - 1 do
      if Pixel[I, J] <> C then
        begin
          if not color_inited_ then
            begin
              color_inited_ := True;
              Result.TopLeft := Point(I, J);
              Result.Bottomright := Result.TopLeft;
            end
          else
              Result := BoundRect(Result.TopLeft, Result.Bottomright, Point(I, J));
        end;
end;

procedure TMZR.BlendColor(bk: TRColor);
var
  S: TRColorEntry;
  p: PRColorEntry;
  I: Integer;
begin
  S.BGRA := bk;
  ReadyBits();
  p := @FBits^[0];
  for I := 0 to Width * Height - 1 do
    begin
      S.A := $FF - p^.A;
      BlendMem(S.BGRA, p^.BGRA);
      p^.A := $FF - S.A;
      inc(p);
    end;
end;

procedure TMZR.BlendBlack();
begin
  BlendColor(RColor(0, 0, 0));
end;

procedure TMZR.Black();
begin
  BlendColor(RColor(0, 0, 0));
end;

procedure TMZR.Line(X1, Y1, X2, Y2: Integer; Color: TRColor; L: Boolean);
  procedure VertLine(X, Y1, Y2: Integer);
  var
    I, nH, NL: Integer;
    p: PRColor;
  begin
    if (X < 0) or (X >= Width) then
        exit;
    Y1 := ClampInt(Y1, 0, Height);
    Y2 := ClampInt(Y2, 0, Height);

    if Y2 < Y1 then
        TSwap<Integer>.Do_(Y1, Y2);

    p := PixelPtr[X, Y1];
    I := Y2 - Y1 + 1;
    nH := I shr 2;
    NL := I and $03;
    for I := 0 to nH - 1 do
      begin
        BlendMem(Color, p^);
        inc(p, Width);
        BlendMem(Color, p^);
        inc(p, Width);
        BlendMem(Color, p^);
        inc(p, Width);
        BlendMem(Color, p^);
        inc(p, Width);
      end;
    for I := 0 to NL - 1 do
      begin
        BlendMem(Color, p^);
        inc(p, Width);
      end;
  end;

  procedure HorzLine(X1, Y, X2: Integer);
  var
    I: Integer;
    p: PRColor;
  begin
    if (Y < 0) or (Y >= Height) then
        exit;
    X1 := ClampInt(X1, 0, Width - 1);
    X2 := ClampInt(X2, 0, Width - 1);

    if X1 > X2 then
        TSwap<Integer>.Do_(X1, X2);

    p := PixelPtr[X1, Y];

    for I := X1 to X2 do
      begin
        BlendMem(Color, p^);
        inc(p);
      end;
  end;

var
  dy, dx, SY, SX, I, delta: Integer;
  pi, pl: Integer;
begin
  ReadyBits();

  if (X1 = X2) and (Y1 = Y2) then
    begin
      Pixel[X1, Y1] := Color;
      exit;
    end;

  if FAgg <> nil then
    begin
      FAgg.LineColor := Color;
      FAgg.Line(X1, Y1, X2, Y2);
      DoChange;
      exit;
    end;

  dx := X2 - X1;
  dy := Y2 - Y1;

  if dx > 0 then
      SX := 1
  else if dx < 0 then
    begin
      dx := -dx;
      SX := -1;
    end
  else // Dx = 0
    begin
      if dy > 0 then
          VertLine(X1, Y1, Y2 - 1)
      else if dy < 0 then
          VertLine(X1, Y2 + 1, Y1);
      if L then
          Pixel[X2, Y2] := Color;
      exit;
    end;

  if dy > 0 then
      SY := 1
  else if dy < 0 then
    begin
      dy := -dy;
      SY := -1;
    end
  else // Dy = 0
    begin
      if X2 > X1 then
          HorzLine(X1, Y1, X2 - 1)
      else
          HorzLine(X2 + 1, Y1, X1);
      if L then
          Pixel[X2, Y2] := Color;
      exit;
    end;

  pi := X1 + Y1 * Width;
  SY := SY * Width;
  pl := Width * Height;

  if dx > dy then
    begin
      delta := dx shr 1;
      for I := 0 to dx - 1 do
        begin
          if (pi >= 0) and (pi < pl) then
              BlendMem(Color, FBits^[pi]);

          inc(pi, SX);
          inc(delta, dy);
          if delta >= dx then
            begin
              inc(pi, SY);
              dec(delta, dx);
            end;
        end;
    end
  else // Dx < Dy
    begin
      delta := dy shr 1;
      for I := 0 to dy - 1 do
        begin
          if (pi >= 0) and (pi < pl) then
              BlendMem(Color, FBits^[pi]);

          inc(pi, SY);
          inc(delta, dx);
          if delta >= dy then
            begin
              inc(pi, SX);
              dec(delta, dy);
            end;
        end;
    end;
  if (L) and (pi >= 0) and (pi < pl) then
      BlendMem(Color, FBits^[pi]);
  DoChange;
end;

procedure TMZR.LineF(X1, Y1, X2, Y2: TGeoFloat; Color: TRColor; L: Boolean);
begin
  Line(Round(X1), Round(Y1), Round(X2), Round(Y2), Color, L);
end;

procedure TMZR.LineF(p1, p2: TVec2; Color: TRColor; L: Boolean);
begin
  LineF(p1[0], p1[1], p2[0], p2[1], Color, L);
end;

procedure TMZR.LineF(p1, p2: TVec2; Color: TRColor; L: Boolean; LineDist: TGeoFloat; Cross: Boolean);
begin
  LineF(p1[0], p1[1], p2[0], p2[1], Color, L);
  if not Cross then
      exit;
  DrawCrossF(p1, LineDist, Color);
  DrawCrossF(p2, LineDist, Color);
end;

procedure TMZR.FillRect(X1, Y1, X2, Y2: Integer; Color: TRColor);
var
  J, I: Integer;
  p: PRColor;
begin
  if FAgg <> nil then
    begin
      FAgg.FillColor := Color;
      FAgg.NoLine;
      FAgg.Rectangle(X1, Y1, X2, Y2);
    end
  else
    begin
      FixRect(X1, Y1, X2, Y2);

      if X1 < 0 then
          X1 := 0
      else if X1 >= Width then
          X1 := Width - 1;

      if X2 < 0 then
          X2 := 0
      else if X2 >= Width then
          X2 := Width - 1;

      if Y1 < 0 then
          Y1 := 0
      else if Y1 >= Height then
          Y1 := Height - 1;
      if Y2 < 0 then
          Y2 := 0
      else if Y2 >= Height then
          Y2 := Height - 1;

      for J := Y1 to Y2 - 1 do
        begin
          I := X1;
          p := @ScanLine[J]^[I];
          while I < X2 do
            begin
              BlendMem(Color, p^);
              inc(I);
              inc(p);
            end;
        end;
    end;
  DoChange;
end;

procedure TMZR.FillRect(Dstx, Dsty, LineDist: Integer; Color: TRColor);
var
  l2, X1, Y1, X2, Y2: Integer;
begin
  l2 := LineDist div 2;
  X1 := Dstx - l2;
  Y1 := Dsty - l2;
  X2 := Dstx + l2;
  Y2 := Dsty + l2;
  FillRect(X1, Y1, X2, Y2, Color);
end;

procedure TMZR.FillRect(Dst: TVec2; LineDist: Integer; Color: TRColor);
begin
  FillRect(Round(Dst[0]), Round(Dst[1]), LineDist, Color);
end;

procedure TMZR.FillRect(R: TRect; Color: TRColor);
begin
  FillRect(R.Left, R.Top, R.Right, R.Bottom, Color);
end;

procedure TMZR.FillRect(R: TRectV2; Color: TRColor);
begin
  FillRect(Round(R[0, 0]), Round(R[0, 1]), Round(R[1, 0]), Round(R[1, 1]), Color);
end;

procedure TMZR.FillRect(R: TRectV2; Angle: TGeoFloat; Color: TRColor);
var
  A: TGeoFloat;
  r4: TV2Rect4;
  buff: array [0 .. 4] of TPointDouble;
begin
  A := NormalizeDegAngle(Angle);
  if A = 0 then
      FillRect(R, Color)
  else
    begin
      r4 := TV2Rect4.Init(R, A);
      if FAgg <> nil then
        begin
          buff[0].X := r4.LeftTop[0];
          buff[0].Y := r4.LeftTop[1];
          buff[1].X := r4.RightTop[0];
          buff[1].Y := r4.RightTop[1];
          buff[2].X := r4.RightBottom[0];
          buff[2].Y := r4.RightBottom[1];
          buff[3].X := r4.LeftBottom[0];
          buff[3].Y := r4.LeftBottom[1];
          buff[4].X := r4.LeftTop[0];
          buff[4].Y := r4.LeftTop[1];

          FAgg.FillColor := Color;
          FAgg.NoLine;
          FAgg.Polygon(@buff[0], 5);
        end
      else
          Projection(r4, Color);
    end;
  DoChange;
end;

procedure TMZR.DrawRect(R: TRect; Color: TRColor);
begin
  DrawRect(RectV2(R), Color);
end;

procedure TMZR.DrawRect(R: TRectV2; Color: TRColor);
begin
  if FAgg <> nil then
    begin
      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Rectangle(R[0][0], R[0][1], R[1][0], R[1][1]);
    end
  else
    begin
      LineF(Vec2(R[0][0], R[0][1]), Vec2(R[1][0], R[0][1]), Color, True);
      LineF(Vec2(R[1][0], R[0][1]), Vec2(R[1][0], R[1][1]), Color, True);
      LineF(Vec2(R[1][0], R[1][1]), Vec2(R[0][0], R[1][1]), Color, True);
      LineF(Vec2(R[0][0], R[1][1]), Vec2(R[0][0], R[0][1]), Color, True);
    end;
  DoChange;
end;

procedure TMZR.DrawRect(R: TV2Rect4; Color: TRColor);
var
  buff: array [0 .. 4] of TPointDouble;
begin
  if R.BoundArea < 1 then
      exit;
  if FAgg <> nil then
    begin
      buff[0].X := R.LeftTop[0];
      buff[0].Y := R.LeftTop[1];
      buff[1].X := R.RightTop[0];
      buff[1].Y := R.RightTop[1];
      buff[2].X := R.RightBottom[0];
      buff[2].Y := R.RightBottom[1];
      buff[3].X := R.LeftBottom[0];
      buff[3].Y := R.LeftBottom[1];
      buff[4].X := R.LeftTop[0];
      buff[4].Y := R.LeftTop[1];
      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polyline(@buff[0], 5);
    end
  else
    begin
      LineF(R.LeftTop, R.RightTop, Color, True);
      LineF(R.RightTop, R.RightBottom, Color, True);
      LineF(R.RightBottom, R.LeftBottom, Color, True);
      LineF(R.LeftBottom, R.LeftTop, Color, True);
    end;
  DoChange;
end;

procedure TMZR.DrawRect(R: TRectV2; Angle: TGeoFloat; Color: TRColor);
var
  r4: TV2Rect4;
  buff: array [0 .. 4] of TPointDouble;
begin
  r4 := TV2Rect4.Init(R, Angle);
  if FAgg <> nil then
    begin
      buff[0].X := r4.LeftTop[0];
      buff[0].Y := r4.LeftTop[1];
      buff[1].X := r4.RightTop[0];
      buff[1].Y := r4.RightTop[1];
      buff[2].X := r4.RightBottom[0];
      buff[2].Y := r4.RightBottom[1];
      buff[3].X := r4.LeftBottom[0];
      buff[3].Y := r4.LeftBottom[1];
      buff[4].X := r4.LeftTop[0];
      buff[4].Y := r4.LeftTop[1];

      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polyline(@buff[0], 5);
    end
  else
    begin
      LineF(r4.LeftTop, r4.RightTop, Color, True);
      LineF(r4.RightTop, r4.RightBottom, Color, True);
      LineF(r4.RightBottom, r4.LeftBottom, Color, True);
      LineF(r4.LeftBottom, r4.LeftTop, Color, True);
    end;
  DoChange;
end;

procedure TMZR.DrawTriangle(tri: TTriangle; Transform: Boolean; Color: TRColor; Cross: Boolean);
begin
  if Transform then
    begin
      LineF(Vec2Mul(tri[0], Size0), Vec2Mul(tri[1], Size0), Color, True, 5, Cross);
      LineF(Vec2Mul(tri[1], Size0), Vec2Mul(tri[2], Size0), Color, True, 5, Cross);
      LineF(Vec2Mul(tri[2], Size0), Vec2Mul(tri[0], Size0), Color, True, 5, Cross);
    end
  else
    begin
      LineF(tri[0], tri[1], Color, True, 5, Cross);
      LineF(tri[1], tri[2], Color, True, 5, Cross);
      LineF(tri[2], tri[0], Color, True, 5, Cross);
    end;
  DoChange;
end;

procedure TMZR.DrawFlatCross(Dst: TVec2; LineDist: TGeoFloat; Color: TRColor);
var
  L, X1, Y1, X2, Y2: TGeoFloat;
begin
  L := LineDist * 0.5;

  X1 := Dst[0] - L;
  X2 := Dst[0] + L;
  Y1 := Dst[1];
  Y2 := Dst[1];
  LineF(X1, Y1, X2, Y2, Color, True);

  X1 := Dst[0];
  X2 := Dst[0];
  Y1 := Dst[1] - L;
  Y2 := Dst[1] + L;
  LineF(X1, Y1, X2, Y2, Color, True);
end;

procedure TMZR.DrawCross(Dstx, Dsty, LineDist: Integer; Color: TRColor);
var
  L, X1, Y1, X2, Y2: Integer;
begin
  L := LineDist div 2;

  X1 := Dstx - L;
  Y1 := Dsty - L;
  X2 := Dstx + L;
  Y2 := Dsty + L;
  Line(X1, Y1, X2, Y2, Color, True);

  X1 := Dstx - L;
  Y1 := Dsty + L;
  X2 := Dstx + L;
  Y2 := Dsty - L;
  Line(X1, Y1, X2, Y2, Color, True);
end;

procedure TMZR.DrawCrossF(Dstx, Dsty, LineDist: TGeoFloat; Color: TRColor);
begin
  DrawCross(Round(Dstx), Round(Dsty), Round(LineDist), Color);
end;

procedure TMZR.DrawCrossF(Dst: TVec2; LineDist: TGeoFloat; Color: TRColor);
begin
  DrawCrossF(Dst[0], Dst[1], LineDist, Color);
end;

procedure TMZR.DrawCrossF(Polygon: TV2L; LineDist: TGeoFloat; Color: TRColor);
var
  I: Integer;
begin
  for I := 0 to Polygon.Count - 1 do
      DrawCrossF(Polygon[I]^, LineDist, Color);
end;

procedure TMZR.DrawPointListLine(pl: TV2L; Color: TRColor; wasClose: Boolean);
var
  I: Integer;
  p1, p2: PVec2;
  buff: array of TPointDouble;
begin
  if pl.Count < 2 then
      exit;

  if FAgg <> nil then
    begin
      I := pl.Count;
      if wasClose then
          inc(I);

      SetLength(buff, I);

      for I := 0 to pl.Count - 1 do
        begin
          p1 := pl[I];
          buff[I].X := p1^[0];
          buff[I].Y := p1^[1];
        end;
      if wasClose then
        begin
          p1 := pl.First;
          buff[pl.Count].X := p1^[0];
          buff[pl.Count].Y := p1^[1];
        end;

      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polyline(@buff[0], pl.Count + 1);
      SetLength(buff, 0);
    end
  else
    begin
      for I := 1 to pl.Count - 1 do
        begin
          p1 := pl[I - 1];
          p2 := pl[I];
          LineF(p1^, p2^, Color, True);
        end;
      if wasClose then
        begin
          p1 := pl.First;
          p2 := pl.Last;
          LineF(p1^, p2^, Color, True);
        end;
    end;
  DoChange;
end;

procedure TMZR.DrawCircle(CC: TVec2; R: TGeoFloat; Color: TRColor);
var
  vl: TV2L;
begin
  if FAgg <> nil then
    begin
      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Circle(CC[0], CC[1], R);
    end
  else
    begin
      vl := TV2L.Create;
      vl.AddCirclePoint(Round(R), CC, R);
      DrawPointListLine(vl, Color, True);
      DisposeObject(vl);
    end;
  DoChange;
end;

procedure TMZR.FillCircle(CC: TVec2; R: TGeoFloat; Color: TRColor);
var
  vl: TV2L;
begin
  if FAgg <> nil then
    begin
      FAgg.FillColor := Color;
      FAgg.NoLine;
      FAgg.Circle(CC[0], CC[1], R);
    end
  else
    begin
      vl := TV2L.Create;
      vl.AddCirclePoint(Round(R), CC, R);
      Vertex.FillPoly(vl, CC, Color);
      DisposeObject(vl);
    end;
  DoChange;
end;

procedure TMZR.DrawEllipse(CC: TVec2; xRadius, yRadius: TGeoFloat; Color: TRColor);
var
  I, n: Integer;
  S, C: TGeoFloatArray;
  vl: TV2L;
begin
  if Round(xRadius) = Round(yRadius) then
      DrawCircle(CC, xRadius, Color)
  else if FAgg <> nil then
    begin
      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Ellipse(CC[0], CC[1], xRadius, yRadius);
    end
  else
    begin
      n := Round(Max(xRadius, yRadius) * 0.1) + 5;
      SetLength(S, n);
      SetLength(C, n);
      dec(n);
      BuildSinCosCache(@S, @C, 0, 90);
      for I := 0 to n do
        begin
          S[I] := S[I] * yRadius;
          C[I] := C[I] * xRadius;
        end;
      vl := TV2L.Create;
      // first quadrant (top right)
      for I := 0 to n do
          vl.Add(CC[0] + C[I], CC[1] - S[I]);
      // second quadrant (top left)
      for I := n - 1 downto 0 do
          vl.Add(CC[0] - C[I], CC[1] - S[I]);
      // third quadrant (bottom left)
      for I := 1 to n do
          vl.Add(CC[0] - C[I], CC[1] + S[I]);
      // fourth quadrant (bottom right)
      for I := n - 1 downto 0 do
          vl.Add(CC[0] + C[I], CC[1] + S[I]);
      SetLength(S, 0);
      SetLength(C, 0);
      DrawPointListLine(vl, Color, False);
      DisposeObject(vl);
    end;
  DoChange;
end;

procedure TMZR.DrawEllipse(R: TRectV2; Color: TRColor);
var
  cen: TVec2;
begin
  cen := RectCentre(R);
  DrawEllipse(cen, abs(R[0][0] - cen[0]), abs(R[1][1] - cen[1]), Color);
end;

procedure TMZR.FillEllipse(CC: TVec2; xRadius, yRadius: TGeoFloat; Color: TRColor);
var
  I, n: Integer;
  S, C: TGeoFloatArray;
  vl: TV2L;
begin
  if Round(xRadius) = Round(yRadius) then
      FillCircle(CC, xRadius, Color)
  else if FAgg <> nil then
    begin
      FAgg.FillColor := Color;
      FAgg.NoLine;
      FAgg.Ellipse(CC[0], CC[1], xRadius, yRadius);
    end
  else
    begin
      n := Round(Max(xRadius, yRadius) * 0.1) + 5;
      SetLength(S, n);
      SetLength(C, n);
      dec(n);
      BuildSinCosCache(@S, @C, 0, 90);
      for I := 0 to n do
        begin
          S[I] := S[I] * yRadius;
          C[I] := C[I] * xRadius;
        end;
      vl := TV2L.Create;
      // first quadrant (top right)
      for I := 0 to n do
          vl.Add(CC[0] + C[I], CC[1] - S[I]);
      // second quadrant (top left)
      for I := n - 1 downto 0 do
          vl.Add(CC[0] - C[I], CC[1] - S[I]);
      // third quadrant (bottom left)
      for I := 1 to n do
          vl.Add(CC[0] - C[I], CC[1] + S[I]);
      // fourth quadrant (bottom right)
      for I := n - 1 downto 0 do
          vl.Add(CC[0] + C[I], CC[1] + S[I]);
      SetLength(S, 0);
      SetLength(C, 0);
      Vertex.FillPoly(vl, CC, Color);
      DisposeObject(vl);
    end;
  DoChange;
end;

procedure TMZR.FillEllipse(R: TRectV2; Color: TRColor);

var
  cen: TVec2;

begin
  cen := RectCentre(R);
  DrawEllipse(cen, abs(R[0][0] - cen[0]), abs(R[1][1] - cen[1]), Color);
end;

procedure TMZR.FillTriangle(t1, t2, t3: TVec2; Color: TRColor);
begin
  Vertex.DrawTriangle(t1, t2, t3, Color);
end;

procedure TMZR.FillTriangle(t1, t2, t3: TPoint; Color: TRColor);
begin
  FillTriangle(Vec2(t1), Vec2(t1), Vec2(t1), Color);
end;

procedure TMZR.FillTriangle(t1, t2, t3: TPointf; Color: TRColor);
begin
  FillTriangle(Vec2(t1), Vec2(t1), Vec2(t1), Color);
end;

procedure TMZR.FillPolygon(PolygonBuff: TArrayVec2; Color: TRColor);
  procedure Fill_Agg;
  var
    L, I: Integer;
    p1, p2: PVec2;
    buff: array of TPointDouble;
  begin
    L := Length(PolygonBuff);
    SetLength(buff, L + 1);

    for I := 0 to L - 1 do
      begin
        p1 := @PolygonBuff[I];
        buff[I].X := p1^[0];
        buff[I].Y := p1^[1];
      end;

    p1 := @PolygonBuff[0];
    buff[L].X := p1^[0];
    buff[L].Y := p1^[1];

    FAgg.NoLine;
    FAgg.FillColor := Color;
    FAgg.Polygon(@buff[0], L + 1, dpfFillOnly);
    SetLength(buff, 0);
  end;

  procedure Fill_Geo;
  var
    R: TRectV2;
{$IFDEF Parallel}
{$IFDEF FPC}
    procedure Nested_ParallelFor(pass: Integer);
    var
      p: PRColorArray;
      I: Integer;
      Pt: TVec2;
    begin
      p := ScanLine[pass];
      for I := 0 to Width - 1 do
        begin
          Pt := Vec2(I, pass);
          if PointInRect(Pt, R) and PointInPolygon(Pt, PolygonBuff) then
              p^[I] := Color;
        end;
    end;
{$ENDIF FPC}
{$ENDIF Parallel}
    procedure DoFor();
    var
      p: PRColorArray;
      pass, I: Integer;
      Pt: TVec2;
    begin
      for pass := 0 to Height - 1 do
        begin
          p := ScanLine[pass];
          for I := 0 to Width - 1 do
            begin
              Pt := Vec2(I, pass);
              if PointInRect(Pt, R) and PointInPolygon(Pt, PolygonBuff) then
                  p^[I] := Color;
            end;
        end;
    end;

  begin
    R := BoundRect(PolygonBuff);

    if TMZR.Parallel and LocalParallel then
      begin
{$IFDEF Parallel}
{$IFDEF FPC}
        FPCParallelFor(Nested_ParallelFor, 0, Height - 1);
{$ELSE}
        DelphiParallelFor(0, Height - 1, procedure(pass: Integer)
          var
            p: PRColorArray;
            I: Integer;
            Pt: TVec2;
          begin
            p := ScanLine[pass];
            for I := 0 to Width - 1 do
              begin
                Pt := Vec2(I, pass);
                if PointInRect(Pt, R) and PointInPolygon(Pt, PolygonBuff) then
                    p^[I] := Color;
              end;
          end);
{$ENDIF FPC}
{$ELSE}
        DoFor();
{$ENDIF Parallel}
      end
    else
        DoFor();
  end;

begin
  if Length(PolygonBuff) < 2 then
      exit;

  if FAgg <> nil then
      Fill_Agg()
  else
      Fill_Geo();
  DoChange;
end;

procedure TMZR.DrawPolygon(PolygonBuff: TArrayVec2; Color: TRColor);
var
  L, I: Integer;
  p1, p2: PVec2;
  buff: array of TPointDouble;
begin
  L := Length(PolygonBuff);
  if L < 2 then
      exit;

  if FAgg <> nil then
    begin
      SetLength(buff, L + 1);

      for I := 0 to L - 1 do
        begin
          p1 := @PolygonBuff[I];
          buff[I].X := p1^[0];
          buff[I].Y := p1^[1];
        end;

      p1 := @PolygonBuff[0];
      buff[L].X := p1^[0];
      buff[L].Y := p1^[1];

      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polygon(@buff[0], L + 1, dpfStrokeOnly);
      SetLength(buff, 0);
    end
  else
    begin
      for I := 1 to L - 1 do
        begin
          p1 := @PolygonBuff[I - 1];
          p2 := @PolygonBuff[I];
          LineF(p1^, p2^, Color, True);
        end;

      p1 := @PolygonBuff[0];
      p2 := @PolygonBuff[L - 1];
      LineF(p1^, p2^, Color, True);
    end;
  DoChange;
end;

procedure TMZR.FillPolygon(Polygon: T2DPolygon; Color: TRColor);
  procedure Fill_Agg;
  var
    L, I: Integer;
    p1, p2: PVec2;
    buff: array of TPointDouble;
  begin
    L := Polygon.Count;
    SetLength(buff, L + 1);

    for I := 0 to L - 1 do
      begin
        p1 := Polygon[I];
        buff[I].X := p1^[0];
        buff[I].Y := p1^[1];
      end;

    p1 := Polygon[0];
    buff[L].X := p1^[0];
    buff[L].Y := p1^[1];

    FAgg.NoLine;
    FAgg.FillColor := Color;
    FAgg.Polygon(@buff[0], L + 1, dpfFillOnly);
    SetLength(buff, 0);
  end;

  procedure Fill_Geo;
  var
    R: TRectV2;
{$IFDEF Parallel}
{$IFDEF FPC}
    procedure Nested_ParallelFor(pass: Integer);
    var
      p: PRColorArray;
      I: Integer;
      Pt: TVec2;
    begin
      p := ScanLine[pass];
      for I := 0 to Width - 1 do
        begin
          Pt := Vec2(I, pass);
          if PointInRect(Pt, R) and Polygon.InHere(Pt) then
              p^[I] := Color;
        end;
    end;
{$ENDIF FPC}
{$ENDIF Parallel}
    procedure DoFor();
    var
      p: PRColorArray;
      pass, I: Integer;
      Pt: TVec2;
    begin
      for pass := 0 to Height - 1 do
        begin
          p := ScanLine[pass];
          for I := 0 to Width - 1 do
            begin
              Pt := Vec2(I, pass);
              if PointInRect(Pt, R) and Polygon.InHere(Pt) then
                  p^[I] := Color;
            end;
        end;
    end;

  begin
    R := Polygon.BoundBox();
    if TMZR.Parallel and LocalParallel then
      begin
{$IFDEF Parallel}
{$IFDEF FPC}
        FPCParallelFor(Nested_ParallelFor, 0, Height - 1);
{$ELSE}
        DelphiParallelFor(0, Height - 1, procedure(pass: Integer)
          var
            p: PRColorArray;
            I: Integer;
            Pt: TVec2;
          begin
            p := ScanLine[pass];
            for I := 0 to Width - 1 do
              begin
                Pt := Vec2(I, pass);
                if PointInRect(Pt, R) and Polygon.InHere(Pt) then
                    p^[I] := Color;
              end;
          end);
{$ENDIF FPC}
{$ELSE}
        DoFor();
{$ENDIF Parallel}
      end
    else
        DoFor();
  end;

begin
  if Polygon.Count < 2 then
      exit;

  if FAgg <> nil then
      Fill_Agg()
  else
      Fill_Geo();
  DoChange;
end;

procedure TMZR.DrawPolygon(Polygon: T2DPolygon; Color: TRColor);
var
  L, I: Integer;
  p1, p2: PVec2;
  buff: array of TPointDouble;
begin
  L := Polygon.Count;
  if L < 2 then
      exit;

  if FAgg <> nil then
    begin
      SetLength(buff, L + 1);

      for I := 0 to L - 1 do
        begin
          p1 := Polygon[I];
          buff[I].X := p1^[0];
          buff[I].Y := p1^[1];
        end;

      p1 := Polygon[0];
      buff[L].X := p1^[0];
      buff[L].Y := p1^[1];

      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polygon(@buff[0], L + 1, dpfStrokeOnly);
      SetLength(buff, 0);
    end
  else
    begin
      for I := 1 to L - 1 do
        begin
          p1 := Polygon[I - 1];
          p2 := Polygon[I];
          LineF(p1^, p2^, Color, True);
        end;

      p1 := Polygon[0];
      p2 := Polygon[L - 1];
      LineF(p1^, p2^, Color, True);
    end;
  DoChange;
end;

procedure TMZR.FillPolygon(Polygon: T2DPolygonGraph; Color: TRColor);
  procedure Fill_Geo;
  var
    R: TRectV2;
{$IFDEF Parallel}
{$IFDEF FPC}
    procedure Nested_ParallelFor(pass: Integer);
    var
      p: PRColorArray;
      I: Integer;
      Pt: TVec2;
    begin
      p := ScanLine[pass];
      for I := 0 to Width - 1 do
        begin
          Pt := Vec2(I, pass);
          if PointInRect(Pt, R) and Polygon.InHere(Pt) then
              p^[I] := Color;
        end;
    end;
{$ENDIF FPC}
{$ENDIF Parallel}
    procedure DoFor();
    var
      p: PRColorArray;
      pass, I: Integer;
      Pt: TVec2;
    begin
      for pass := 0 to Height - 1 do
        begin
          p := ScanLine[pass];
          for I := 0 to Width - 1 do
            begin
              Pt := Vec2(I, pass);
              if PointInRect(Pt, R) and Polygon.InHere(Pt) then
                  p^[I] := Color;
            end;
        end;
    end;

  begin
    R := Polygon.BoundBox();
    if TMZR.Parallel and LocalParallel then
      begin
{$IFDEF Parallel}
{$IFDEF FPC}
        FPCParallelFor(Nested_ParallelFor, 0, Height - 1);
{$ELSE}
        DelphiParallelFor(0, Height - 1, procedure(pass: Integer)
          var
            p: PRColorArray;
            I: Integer;
            Pt: TVec2;
          begin
            p := ScanLine[pass];
            for I := 0 to Width - 1 do
              begin
                Pt := Vec2(I, pass);
                if PointInRect(Pt, R) and Polygon.InHere(Pt) then
                    p^[I] := Color;
              end;
          end);
{$ENDIF FPC}
{$ELSE}
        DoFor();
{$ENDIF Parallel}
      end
    else
        DoFor();
  end;

begin
  Fill_Geo();
  DoChange;
end;

procedure TMZR.DrawPolygon(Polygon: T2DPolygonGraph; Color: TRColor);
var
  I: Integer;
begin
  DrawPolygon(Polygon.Surround, Color);
  for I := 0 to Polygon.CollapsesCount - 1 do
      DrawPolygon(Polygon.Bands[I], Color);
end;

procedure TMZR.DrawPolygon(Polygon: T2DPolygonGraph; SurroundColor, CollapseColor: TRColor);
var
  I: Integer;
begin
  DrawPolygon(Polygon.Surround, SurroundColor);
  for I := 0 to Polygon.CollapsesCount - 1 do
      DrawPolygon(Polygon.Bands[I], CollapseColor);
end;

procedure TMZR.DrawPolygonCross(Polygon: T2DPolygonGraph; LineDist: TGeoFloat; SurroundColor, CollapseColor: TRColor);
var
  I: Integer;
begin
  DrawCrossF(Polygon.Surround, LineDist, SurroundColor);
  for I := 0 to Polygon.CollapsesCount - 1 do
      DrawCrossF(Polygon.Bands[I], LineDist, CollapseColor);
end;

procedure TMZR.DrawPolygonLine(Polygon: TLines; Color: TRColor; wasClose: Boolean);
var
  L, I: Integer;
  p1, p2: PVec2;
begin
  L := Polygon.Count;
  if L < 2 then
      exit;

  for I := 1 to L - 1 do
    begin
      p1 := Polygon[I - 1];
      p2 := Polygon[I];
      LineF(p1^, p2^, Color, True);
    end;

  if wasClose then
    begin
      p1 := Polygon[0];
      p2 := Polygon[L - 1];
      LineF(p1^, p2^, Color, True);
    end;
  DoChange;
end;

procedure TMZR.DrawPolygon(Polygon: TDeflectionPolygon; ExpandDist: TGeoFloat; Color: TRColor);
var
  L, I: Integer;
  p1, p2: TVec2;
  buff: array of TPointDouble;
begin
  L := Polygon.Count;
  if L < 2 then
      exit;

  if FAgg <> nil then
    begin
      SetLength(buff, L + 1);

      for I := 0 to L - 1 do
        begin
          p1 := Polygon.Expands[I, ExpandDist];
          buff[I].X := p1[0];
          buff[I].Y := p1[1];
        end;

      p1 := Polygon.Expands[0, ExpandDist];
      buff[L].X := p1[0];
      buff[L].Y := p1[1];

      FAgg.NoFill;
      FAgg.LineColor := Color;
      FAgg.Polygon(@buff[0], L + 1, dpfStrokeOnly);
      SetLength(buff, 0);
    end
  else
    begin
      for I := 1 to L - 1 do
        begin
          p1 := Polygon.Expands[I - 1, ExpandDist];
          p2 := Polygon.Expands[I, ExpandDist];
          LineF(p1, p2, Color, True);
        end;

      p1 := Polygon.Expands[0, ExpandDist];
      p2 := Polygon.Expands[L - 1, ExpandDist];
      LineF(p1, p2, Color, True);
    end;
  DoChange;
end;

function TMZR.PixelAtNoneBGBorder(const X, Y: Integer; const BGColor, BorderColor: TRColor; const halfBorderSize: Integer; var detectColor: TRColor): Boolean;
var
  I, J: Integer;
  C: TRColor;
begin
  if Pixel[X, Y] = BGColor then
    for J := Y - halfBorderSize to Y + halfBorderSize do
      if (J >= 0) and (J < Height) then
        for I := X - halfBorderSize to X + halfBorderSize do
          if (I >= 0) and (I < Width) then
            begin
              C := Pixel[I, J];
              if (C <> BGColor) and (C <> BorderColor) then
                begin
                  Result := True;
                  detectColor := C;
                  exit;
                end;
            end;
  Result := False;
end;

function TMZR.PixelAtNoneBGBorder(const X, Y: Integer; const BGColor: TRColor; const halfBorderSize: Integer; var detectColor: TRColor): Boolean;
var
  I, J: Integer;
  C: TRColor;
begin
  if FastPixel[X, Y] = BGColor then
    for J := Y - halfBorderSize to Y + halfBorderSize do
      if (J >= 0) and (J < Height) then
        for I := X - halfBorderSize to X + halfBorderSize do
          if (I >= 0) and (I < Width) then
            begin
              C := FastPixel[I, J];
              if (C <> BGColor) then
                begin
                  Result := True;
                  detectColor := C;
                  exit;
                end;
            end;
  Result := False;
end;

procedure TMZR.FillNoneBGColorBorder(parallel_: Boolean; BGColor, BorderColor: TRColor; BorderSize: Integer);
var
  halfBorderSize: Integer;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    I: Integer;
    detectColor: TRColor;
  begin
    for I := 0 to Width - 1 do
      if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
          FastPixel[I, pass] := BorderColor;
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    I, pass: Integer;
    detectColor: TRColor;
  begin
    for pass := 0 to Height - 1 do
      for I := 0 to Width - 1 do
        if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
            FastPixel[I, pass] := BorderColor;
  end;

begin
  if BGColor = BorderColor then
      exit;
  ReadyBits;
  halfBorderSize := BorderSize shr 1;
  if halfBorderSize <= 0 then
      halfBorderSize := 1;

  if parallel_ then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(TMZR.Parallel and LocalParallel, Nested_ParallelFor, 0, Height - 1);
{$ELSE FPC}
      DelphiParallelFor(TMZR.Parallel and LocalParallel, 0, Height - 1, procedure(pass: Integer)
        var
          I: Integer;
          detectColor: TRColor;
        begin
          for I := 0 to Width - 1 do
            if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
                FastPixel[I, pass] := BorderColor;
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  DoChange;
end;

procedure TMZR.FillNoneBGColorBorder(BGColor, BorderColor: TRColor; BorderSize: Integer);
begin
  FillNoneBGColorBorder(False, BGColor, BorderColor, BorderSize);
end;

procedure TMZR.FillNoneBGColorAlphaBorder(parallel_: Boolean; BGColor, BorderColor: TRColor; BorderSize: Integer; Output: TMZR);
var
  halfBorderSize: Integer;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    I: Integer;
    detectColor: TRColor;
    p: PRColor;
  begin
    for I := 0 to Width - 1 do
      if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
        begin
          p := Output.PixelPtr[I, pass];
          p^ := RAlphaColor(BorderColor, TRColorEntry(p^).A);
        end;
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    I, pass: Integer;
    detectColor: TRColor;
    p: PRColor;
  begin
    for pass := 0 to Height - 1 do
      for I := 0 to Width - 1 do
        if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
          begin
            p := Output.PixelPtr[I, pass];
            p^ := RAlphaColor(BorderColor, TRColorEntry(p^).A);
          end;
  end;

begin
  if BGColor = BorderColor then
      exit;
  ReadyBits;
  Output.ReadyBits;
  halfBorderSize := BorderSize shr 1;
  if halfBorderSize <= 0 then
      halfBorderSize := 1;

  if parallel_ then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(TMZR.Parallel and LocalParallel, Nested_ParallelFor, 0, Height - 1);
{$ELSE FPC}
      DelphiParallelFor(TMZR.Parallel and LocalParallel, 0, Height - 1, procedure(pass: Integer)
        var
          I: Integer;
          detectColor: TRColor;
          p: PRColor;
        begin
          for I := 0 to Width - 1 do
            if PixelAtNoneBGBorder(I, pass, BGColor, BorderColor, halfBorderSize, detectColor) then
              begin
                p := Output.PixelPtr[I, pass];
                p^ := RAlphaColor(BorderColor, TRColorEntry(p^).A);
              end;
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  DoChange;
end;

procedure TMZR.FillNoneBGColorAlphaBorder(BGColor, BorderColor: TRColor; BorderSize: Integer; Output: TMZR);
begin
  FillNoneBGColorAlphaBorder(True, BGColor, BorderColor, BorderSize, Output);
end;

procedure TMZR.FillNoneBGColorAlphaBorder(BGColor, BorderColor: TRColor; BorderSize: Integer);
var
  tmp: TMZR;
begin
  tmp := TMZR.Create;
  tmp.SetSize(Width, Height, 0);
  FillNoneBGColorAlphaBorder(False, BGColor, BorderColor, BorderSize, tmp);
  tmp.DrawTo(Self);
  DisposeObject(tmp);
end;

function TMZR.TextSize(Text: SystemString; siz: TGeoFloat): TVec2;
begin
  Result := Vec2Mul(Font.TextSize(Text), siz / Font.FontSize)
end;

procedure TMZR.DrawText(Text: SystemString; X, Y: TGeoFloat; RotateVec: TVec2; Angle, alpha, siz: TGeoFloat; TextColor: TRColor);
begin
  Font.DrawText(Text, Self, X, Y, RotateVec, Angle, alpha, siz, TextColor);
  DoChange;
end;

procedure TMZR.DrawText(Text: SystemString; X, Y: TGeoFloat; siz: TGeoFloat; TextColor: TRColor);
begin
  DrawText(Text, X, Y, Vec2(0.5, 0.5), 0, 1, siz, TextColor);
end;

procedure TMZR.DrawText(Text: SystemString; X, Y: TGeoFloat; RotateVec: TVec2; Angle, alpha, siz: TGeoFloat; TextColor: TRColor; var DrawCoordinate: TArrayV2R4);
begin
  Font.DrawText(Text, Self, X, Y, RotateVec, Angle, alpha, siz, TextColor, DrawCoordinate);
  DoChange;
end;

procedure TMZR.DrawText(Text: SystemString; X, Y: TGeoFloat; siz: TGeoFloat; TextColor: TRColor; var DrawCoordinate: TArrayV2R4);
begin
  DrawText(Text, X, Y, Vec2(0.5, 0.5), 0, 1, siz, TextColor, DrawCoordinate);
end;

function TMZR.ComputeDrawTextCoordinate(Text: SystemString; X, Y: TGeoFloat; RotateVec: TVec2; Angle, siz: TGeoFloat; var DrawCoordinate, BoundBoxCoordinate: TArrayV2R4): TVec2;
begin
  Result := Font.ComputeDrawCoordinate(Text, X, Y, RotateVec, Angle, siz, DrawCoordinate, BoundBoxCoordinate);
end;

function TMZR.ComputeTextSize(Text: SystemString; RotateVec: TVec2; Angle, siz: TGeoFloat): TVec2;
begin
  Result := Font.ComputeTextSize(Text, RotateVec, Angle, siz);
end;

function TMZR.ComputeTextConvexHull(Text: SystemString; X, Y: TGeoFloat; RotateVec: TVec2; Angle, siz: TGeoFloat): TArrayVec2;
begin
  Result := Font.ComputeTextConvexHull(Text, X, Y, RotateVec, Angle, siz);
end;

function TMZR.GetDrawEngineMap: TCore_Object;
var
  d: TDrawEngine;
begin
  if FDrawEngineMap = nil then
      FDrawEngineMap := TDrawEngine.Create;
  d := TDrawEngine(FDrawEngineMap);

  if (d.ZR_.Memory.Width <> Width) or (d.ZR_.Memory.Height <> Height) or (d.ZR_.Memory.FBits <> FBits) then
    begin
      d.ZR_.SetWorkMemory(Self);
      d.ZR_.UsedAgg := True;
      d.ZR_.Memory.Font := Font;
      d.ViewOptions := [];
    end;
  d.SetSize(Self);
  d.SetDrawInterfaceAsDefault;
  Result := d;
  DoChange;
end;

procedure TMZR.ProjectionTo(Dst: TMZR; const sourRect, DestRect: TV2Rect4; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  Dst.Vertex.DrawRect(sourRect, DestRect, Self, bilinear_sampling, alpha);
  Dst.DoChange;
end;

procedure TMZR.ProjectionTo(Dst: TMZR; const sourRect, DestRect: TRectV2; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  ProjectionTo(Dst, TV2Rect4.Init(sourRect, 0), TV2Rect4.Init(DestRect, 0), bilinear_sampling, alpha);
  Dst.DoChange;
end;

procedure TMZR.Projection(const DestRect: TV2Rect4; const Color: TRColor);
begin
  Vertex.DrawRect(DestRect, Color);
  DoChange;
end;

procedure TMZR.Projection(sour: TMZR; const sourRect, DestRect: TV2Rect4; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  Vertex.DrawRect(sourRect, DestRect, sour, bilinear_sampling, alpha);
  DoChange;
end;

procedure TMZR.Projection(sour: TMZR; const sourRect, DestRect: TRectV2; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  Projection(sour, TV2Rect4.Init(sourRect, 0), TV2Rect4.Init(DestRect, 0), bilinear_sampling, alpha);
  DoChange;
end;

procedure TMZR.ProjectionPolygonTo(const sour_Polygon: TV2L; Dst: TMZR; DestRect: TRectV2; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
var
  R: TRectV2;
  nR: TMZR;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    I: Integer;
  begin
    for I := 0 to Width - 1 do
      if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
          nR[I, pass] := PixelLinear[I, pass];
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass, I: Integer;
  begin
    for pass := 0 to Height - 1 do
      for I := 0 to Width - 1 do
        if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
            nR[I, pass] := PixelLinear[I, pass];
  end;

begin
  nR := NewZR();
  nR.SetSize(Width, Height, RColor(0, 0, 0, 0));
  R := sour_Polygon.BoundBox();

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Height - 1, procedure(pass: Integer)
        var
          I: Integer;
        begin
          for I := 0 to Width - 1 do
            if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
                nR[I, pass] := PixelLinear[I, pass];
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  nR.ProjectionTo(Dst, R, DestRect, bilinear_sampling, alpha);
  DisposeObject(nR);
  Dst.DoChange;
end;

procedure TMZR.ProjectionPolygonTo(const sour_Polygon: T2DPolygonGraph; Dst: TMZR; DestRect: TRectV2; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
var
  R: TRectV2;
  nR: TMZR;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  var
    I: Integer;
  begin
    for I := 0 to Width - 1 do
      if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
          nR[I, pass] := PixelLinear[I, pass];
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass, I: Integer;
  begin
    for pass := 0 to Height - 1 do
      for I := 0 to Width - 1 do
        if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
            nR[I, pass] := PixelLinear[I, pass];
  end;

begin
  nR := NewZR();
  nR.SetSize(Width, Height, RColor(0, 0, 0, 0));
  R := sour_Polygon.BoundBox();

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Height - 1, procedure(pass: Integer)
        var
          I: Integer;
        begin
          for I := 0 to Width - 1 do
            if (PointInRect(I, pass, R)) and (sour_Polygon.InHere(Vec2(I, pass))) then
                nR[I, pass] := PixelLinear[I, pass];
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  nR.ProjectionTo(Dst, R, DestRect, bilinear_sampling, alpha);
  DisposeObject(nR);
  Dst.DoChange;
end;

procedure TMZR.Draw(Src: TMZR);
begin
  Src.DrawTo(Self);
  DoChange;
end;

procedure TMZR.Draw(Dstx, Dsty: Integer; Src: TMZR);
begin
  Src.DrawTo(Self, Dstx, Dsty);
  DoChange;
end;

procedure TMZR.Draw(Dstx, Dsty: Integer; const SrcRect: TRect; Src: TMZR);
begin
  Src.DrawTo(Self, Dstx, Dsty, SrcRect);
  DoChange;
end;

procedure TMZR.DrawTo(Dst: TMZR);
begin
  if (Dst.FAgg <> nil) and (FAggImage <> nil) then
      Dst.FAgg.TransformImage(FAggImage, 0, 0, FWidth, FHeight, 0, 0, FWidth, FHeight)
  else
      BlockTransfer(Dst, 0, 0, Dst.BoundsRect, Self, BoundsRect, DrawMode);
  Dst.DoChange;
end;

procedure TMZR.DrawTo(Dst: TMZR; Dstx, Dsty: Integer; const SrcRect: TRect);
begin
  if (Dst.FAgg <> nil) and (FAggImage <> nil) then
      Dst.FAgg.TransformImage(FAggImage, SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom, Dstx, Dsty, FWidth, FHeight)
  else
      BlockTransfer(Dst, Dstx, Dsty, Dst.BoundsRect, Self, SrcRect, DrawMode);
  Dst.DoChange;
end;

procedure TMZR.DrawTo(Dst: TMZR; Dstx, Dsty: Integer);
begin
  if (Dst.FAgg <> nil) and (FAggImage <> nil) then
      Dst.FAgg.TransformImage(FAggImage, 0, 0, FWidth, FHeight, Dstx, Dsty, FWidth, FHeight)
  else
      BlockTransfer(Dst, Dstx, Dsty, Dst.BoundsRect, Self, BoundsRect, DrawMode);
  Dst.DoChange;
end;

procedure TMZR.DrawTo(Dst: TMZR; DstPt: TVec2);
begin
  DrawTo(Dst, Round(DstPt[0]), Round(DstPt[1]));
end;

function TMZR.BuildMorphologySegmentation(OnGetPixelSegClassify: TOnGetPixelSegClassify): TMorphologySegmentation;
begin
  Result := TMorphologySegmentation.Create;
  Result.OnGetPixelSegClassify := OnGetPixelSegClassify;
  Result.BuildSegmentation(Self);
end;

function TMZR.BuildMorphologySegmentation(): TMorphologySegmentation;
begin
  Result := TMorphologySegmentation.Create;
  Result.BuildSegmentation(Self);
end;

procedure TMZR.BuildMorphomaticsTo(MorphPix_: TMorphologyPixel; output_: TMorphomatics);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    output_.Bits^[pass] := RColorToMorph(FBits^[pass], MorphPix_);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to Width * Height - 1 do
      begin
        output_.Bits^[pass] := RColorToMorph(FBits^[pass], MorphPix_);
      end;
  end;

begin
  ReadyBits();
  output_.SetSize(Width, Height);

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Width * Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Width * Height - 1, procedure(pass: Integer)
        begin
          output_.Bits^[pass] := RColorToMorph(FBits^[pass], MorphPix_);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
end;

function TMZR.BuildMorphomatics(MorphPix_: TMorphologyPixel): TMorphomatics;
begin
  Result := TMorphomatics.Create;
  Result.LocalParallel := LocalParallel;
  BuildMorphomaticsTo(MorphPix_, Result);
end;

procedure TMZR.BuildApproximateMorphomaticsTo(ApproximateColor_: TRColor; output_: TMorphomatics);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    output_.Bits^[pass] := RColorToApproximateMorph(FBits^[pass], ApproximateColor_);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to Width * Height - 1 do
      begin
        output_.Bits^[pass] := RColorToApproximateMorph(FBits^[pass], ApproximateColor_);
      end;
  end;

begin
  ReadyBits();
  output_.SetSize(Width, Height);

  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Width * Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Width * Height - 1, procedure(pass: Integer)
        begin
          output_.Bits^[pass] := RColorToApproximateMorph(FBits^[pass], ApproximateColor_);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
end;

function TMZR.BuildApproximateMorphomatics(ApproximateColor_: TRColor): TMorphomatics;
begin
  Result := TMorphomatics.Create;
  Result.LocalParallel := LocalParallel;
  BuildApproximateMorphomaticsTo(ApproximateColor_, Result);
end;

procedure TMZR.DrawMorphomatics(MorphPix_: TMorphologyPixel; Morph: TMorphomatics);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    MorphToRColor(MorphPix_, Morph.Bits^[pass], FBits^[pass]);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to Width * Height - 1 do
      begin
        MorphToRColor(MorphPix_, Morph.Bits^[pass], FBits^[pass]);
      end;
  end;

begin
  if Morph.Width * Morph.Height <> Width * Height then
      SetSize(Morph.Width, Morph.Height, RColor(0, 0, 0, 0));

  ReadyBits();
  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Width * Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Width * Height - 1, procedure(pass: Integer)
        begin
          MorphToRColor(MorphPix_, Morph.Bits^[pass], FBits^[pass]);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  DoChange;
end;

procedure TMZR.DrawMorphomatics(Morph: TMorphomatics);
begin
  DrawMorphomatics(mpGrayscale, Morph);
end;

procedure TMZR.DrawBinaryzation(Morph: TMorphologyBinaryzation);
var
  I: Integer;
begin
  if Morph.Width * Morph.Height <> Width * Height then
      SetSize(Width, Height);

  ReadyBits();
  for I := Width * Height - 1 downto 0 do
    if Morph.Bits^[I] then
        FBits^[I] := $FFFFFFFF
    else
        FBits^[I] := $FF000000;
  DoChange;
end;

procedure TMZR.DrawBinaryzation(MorphPix_: TMorphologyPixel; Morph: TMorphologyBinaryzation);
{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    MorphToRColor(MorphPix_, if_(Morph.Bits^[pass], 1.0, 0.0), FBits^[pass]);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}
  procedure DoFor();
  var
    pass: Integer;
  begin
    for pass := 0 to Width * Height - 1 do
      begin
        MorphToRColor(MorphPix_, if_(Morph.Bits^[pass], 1.0, 0.0), FBits^[pass]);
      end;
  end;

begin
  if Morph.Width * Morph.Height <> Width * Height then
      SetSize(Morph.Width, Morph.Height, RColor(0, 0, 0, 0));

  ReadyBits();
  if TMZR.Parallel and LocalParallel then
    begin
{$IFDEF Parallel}
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, Width * Height - 1);
{$ELSE FPC}
      DelphiParallelFor(0, Width * Height - 1, procedure(pass: Integer)
        begin
          MorphToRColor(MorphPix_, if_(Morph.Bits^[pass], 1.0, 0.0), FBits^[pass]);
        end);
{$ENDIF FPC}
{$ELSE Parallel}
      DoFor();
{$ENDIF Parallel}
    end
  else
      DoFor();
  DoChange;
end;

function TMZR.BuildHistogram(MorphPix_: TMorphologyPixel; Height_: Integer; hColor: TRColor): TMZR;
var
  morph_: TMorphomatics;
begin
  morph_ := BuildMorphomatics(MorphPix_);
  Result := morph_.BuildHistogram(Height_, hColor);
  DisposeObject(morph_);
  Result.DoChange;
end;

class function TMZR.CanLoadStream(stream: TCore_Stream): Boolean;
var
  bakPos: Int64;
  hflag, hflag2: Word;
  Header: TBmpHeader;
  J: TMemoryJpegZR;
begin
  Result := False;
  if stream.Size < 8 then
      exit;
  try
    bakPos := stream.Position;

    if IsPNG(stream) then
        Result := True
    else
      begin
        stream.Position := bakPos;
        stream.Read(hflag, 2);
        if (hflag = $8D42)
          or (hflag = $8D43)
          or (hflag = $8D44)
          or (hflag = $8D46)
          or (hflag = $8D47) // half yuv
          or (hflag = $8D48) // quart yuv
          or (hflag = $8D50) // grayscale
          or (hflag = $8D51) // color 255
          or (hflag = $8D52) // color 65535
        then
            Result := True
        else if (hflag = $D8FF) or (hflag = $8DFF) then
            Result := True
        else
          begin
            stream.Position := bakPos;
            stream.ReadBuffer(Header, SizeOf(TBmpHeader));
            Result := (Header.bfType = $4D42) and (Header.biBitCount in [24, 32]) and (Header.biPlanes = 1) and (Header.biCompression = 0);
          end;
      end;

    stream.Position := bakPos;
  except
  end;
end;

procedure TMZR.LoadFromBmpStream(stream: TCore_Stream);
var
  I, J, K, W: Integer;
  Header: TBmpHeader;
  tempBuff: TBytes;
begin
  Reset;

  stream.ReadBuffer(Header, SizeOf(TBmpHeader));

  // Check for Windows bitmap magic bytes and general compatibility of the
  // bitmap data that ought to be loaded...
  if (Header.bfType = $4D42) and (Header.biBitCount in [24, 32]) and (Header.biPlanes = 1) and (Header.biCompression = 0) then
    begin
      SetSize(Header.biWidth, abs(Header.biHeight));
      if (Header.biWidth <= 0) or (abs(Header.biHeight) <= 0) then
          exit;
      ReadyBits();

      if Header.biBitCount = 32 then
        begin
          // 32bit bitmap
          // Check whether the bitmap is saved top-down
          if Header.biHeight > 0 then
            begin
              W := Width * 4;
              for I := Height - 1 downto 0 do
                begin
                  stream.ReadBuffer(ScanLine[I]^, W);
                end;
            end
          else
            begin
              stream.ReadBuffer(FBits^, Width * Height * 4);
            end;
        end
      else // 24bit bitmap
        begin
          W := FWidth * 3;
          K := W mod 4;
          if K <> 0 then
              inc(W, 4 - K);

          SetLength(tempBuff, W * FHeight);
          stream.ReadBuffer(tempBuff[0], W * FHeight);

          // Check whether the bitmap is saved top-down
          if Header.biHeight > 0 then
            begin
              K := 0;
              for J := Height - 1 downto 0 do
                begin
                  for I := 0 to FWidth - 1 do
                      FBits^[I + J * FWidth] := RGB2RGBA(PRGB(@tempBuff[K + I * 3])^);
                  inc(K, W);
                end;
            end
          else
            begin
              K := 0;
              for J := 0 to Height - 1 do
                begin
                  for I := 0 to FWidth - 1 do
                      FBits^[I + J * FWidth] := RGB2RGBA(PRGB(@tempBuff[K + I * 3])^);
                  inc(K, W);
                end;
            end;

          SetLength(tempBuff, 0);
        end;
    end
  else
    begin
      raise Core_Exception.Create('bmp format failed!');
    end;
end;

procedure TMZR.LoadFromStream(stream: TCore_Stream);
var
  bakPos: Int64;

  hflag, hflag2: Word;
  m64: TMS64;
  J: TMemoryJpegZR;

  W, H: Integer;
  p: Pointer;
begin
  Reset;

  bakPos := stream.Position;

  if IsPNG(stream) then
    begin
      LoadZRFromPNG(Self, stream);
      exit;
    end;

  stream.Position := bakPos;
  stream.Read(hflag, 2);
  if hflag = $8D42 then
    begin
      m64 := TMS64.Create;
      DecompressStream(stream, m64);
      m64.Position := 0;
      LoadFromBmpStream(m64);
      DisposeObject(m64);
      exit;
    end
  else if hflag = $8D43 then
    begin
      m64 := TMS64.Create;
      DeflateDecompressStream(stream, m64);
      m64.Position := 0;
      LoadFromBmpStream(m64);
      DisposeObject(m64);
      exit;
    end
  else if hflag = $8D44 then
    begin
      m64 := TMS64.Create;
      BRRCDecompressStream(stream, m64);
      m64.Position := 0;
      LoadFromBmpStream(m64);
      DisposeObject(m64);
      exit;
    end
  else if hflag = $4D42 then
    begin
      stream.Position := bakPos;
      LoadFromBmpStream(stream);
    end
    // jls endian/jpeg support
  else if (hflag = $D8FF) or (hflag = $8DFF) then
    begin
      stream.Read(hflag2, 2);
      stream.Position := bakPos;

      if (hflag2 = $F7FF) then
        // jls
          DecodeJpegLSZRFromStream(stream, Self)
      else
        begin
          // jpeg
          stream.Position := bakPos;

          m64 := TMS64.Create;
          if stream is TMS64 then
              m64.SetPointerWithProtectedMode(TMS64(stream).Memory, stream.Size - stream.Position)
          else if stream is TCore_MemoryStream then
              m64.SetPointerWithProtectedMode(TCore_MemoryStream(stream).Memory, stream.Size - stream.Position)
          else
              m64.CopyFrom(stream, stream.Size - stream.Position);

          m64.Position := 0;

          J := TMemoryJpegZR.Create;
          J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
          J.Image.StoredCS := TJpegColorSpace.jcAutoDetect;
          J.Scale := TJpegScale.jsFull;
          J.Performance := jpBestSpeed;
          try
            J.LoadFromStream(m64);
            J.GetZR(Self);
            stream.Position := bakPos + m64.Position;
          except
          end;

          DisposeObject(m64);
          DisposeObject(J);
        end;
    end
    // yv12 format
  else if hflag = $8D46 then
    begin
      YV12ToZR_(stream, Self);
      exit;
    end
    // half yuv format
  else if hflag = $8D47 then
    begin
      HalfYUVToZR_(stream, Self);
      exit;
    end
    // quart yuv format
  else if hflag = $8D48 then
    begin
      QuartYUVToZR_(stream, Self);
      exit;
    end
    // grapscale
  else if hflag = $8D50 then
    begin
      stream.Read(W, 4);
      stream.Read(H, 4);

      if stream is TMS64 then
        begin
          p := TMS64(stream).PositionAsPtr;
          DecryptGrayscale(W, H, p);
        end
      else
        begin
          p := System.GetMemory(W * H);
          stream.Read(p^, W * H);
          DecryptGrayscale(W, H, p);
          System.FreeMemory(p);
        end;
      exit;
    end
    // color 255
  else if hflag = $8D51 then
    begin
      stream.Read(W, 4);
      stream.Read(H, 4);

      if stream is TMS64 then
        begin
          p := TMS64(stream).PositionAsPtr;
          DecryptColor255(W, H, p);
        end
      else
        begin
          p := System.GetMemory(W * H);
          stream.Read(p^, W * H);
          DecryptColor255(W, H, p);
          System.FreeMemory(p);
        end;
      exit;
    end
    // color 65535
  else if hflag = $8D52 then
    begin
      stream.Read(W, 4);
      stream.Read(H, 4);

      if stream is TMS64 then
        begin
          p := TMS64(stream).PositionAsPtr;
          DecryptColor65535(W, H, p);
        end
      else
        begin
          p := System.GetMemory(W * H * 2);
          stream.Read(p^, W * H * 2);
          DecryptColor65535(W, H, p);
          System.FreeMemory(p);
        end;
      exit;
    end
  else
      stream.Position := bakPos;

  FIsChanged := False;
end;

procedure TMZR.SaveToStream(stream: TCore_Stream; ZRSave_: TZRSaveFormat);
begin
  case ZRSave_ of
    rsRGBA: SaveToStream(stream);
    rsRGB: SaveToBmp24Stream(stream);
    rsYV12: SaveToYV12Stream(stream);
    rsHalfYUV: SaveToHalfYUVStream(stream);
    rsQuartYUV: SaveToQuartYUVStream(stream);
    rsFastYV12: SaveToFastYV12Stream(stream);
    rsFastHalfYUV: SaveToFastHalfYUVStream(stream);
    rsFastQuartYUV: SaveToFastQuartYUVStream(stream);
    rsJPEG_YCbCrA_Qualily90: SaveToJpegYCbCrAStream(stream, 90);
    rsJPEG_YCbCr_Qualily90: SaveToJpegYCbCrStream(stream, 90);
    rsJPEG_Gray_Qualily90: SaveToJPEGGrayStream(stream, 90);
    rsJPEG_GrayA_Qualily90: SaveToJPEGGrayAStream(stream, 90);
    rsJPEG_YCbCrA_Qualily80: SaveToJpegYCbCrAStream(stream, 80);
    rsJPEG_YCbCr_Qualily80: SaveToJpegYCbCrStream(stream, 80);
    rsJPEG_Gray_Qualily80: SaveToJPEGGrayStream(stream, 80);
    rsJPEG_GrayA_Qualily80: SaveToJPEGGrayAStream(stream, 80);
    rsJPEG_YCbCrA_Qualily70: SaveToJpegYCbCrAStream(stream, 70);
    rsJPEG_YCbCr_Qualily70: SaveToJpegYCbCrStream(stream, 70);
    rsJPEG_Gray_Qualily70: SaveToJPEGGrayStream(stream, 70);
    rsJPEG_GrayA_Qualily70: SaveToJPEGGrayAStream(stream, 70);
    rsJPEG_YCbCrA_Qualily60: SaveToJpegYCbCrAStream(stream, 60);
    rsJPEG_YCbCr_Qualily60: SaveToJpegYCbCrStream(stream, 60);
    rsJPEG_Gray_Qualily60: SaveToJPEGGrayStream(stream, 60);
    rsJPEG_GrayA_Qualily60: SaveToJPEGGrayAStream(stream, 60);
    rsJPEG_YCbCrA_Qualily50: SaveToJpegYCbCrAStream(stream, 50);
    rsJPEG_YCbCr_Qualily50: SaveToJpegYCbCrStream(stream, 50);
    rsJPEG_Gray_Qualily50: SaveToJPEGGrayStream(stream, 50);
    rsJPEG_GrayA_Qualily50: SaveToJPEGGrayAStream(stream, 50);
    rsJPEG_CMYK_Qualily90: SaveToJPEGCMYKStream(stream, 90);
    rsJPEG_CMYK_Qualily80: SaveToJPEGCMYKStream(stream, 80);
    rsJPEG_CMYK_Qualily70: SaveToJPEGCMYKStream(stream, 70);
    rsJPEG_CMYK_Qualily60: SaveToJPEGCMYKStream(stream, 60);
    rsJPEG_CMYK_Qualily50: SaveToJPEGCMYKStream(stream, 50);
    rsJPEG_YCbCrA_Qualily100: SaveToJpegYCbCrAStream(stream, 100);
    rsJPEG_YCbCr_Qualily100: SaveToJpegYCbCrStream(stream, 100);
    rsJPEG_Gray_Qualily100: SaveToJPEGGrayStream(stream, 100);
    rsJPEG_GrayA_Qualily100: SaveToJPEGGrayAStream(stream, 100);
    rsJPEG_CMYK_Qualily100: SaveToJPEGCMYKStream(stream, 100);
    rsPNG: SaveToPNGStream(stream);
    rsGrayscale: SaveToGrayscaleStream(stream);
    rsColor255: SaveToColor255Stream(stream);
  end;
end;

procedure TMZR.SaveToStream(stream: TCore_Stream);
begin
  SaveToBmp32Stream(stream);
end;

procedure TMZR.SaveToBmp32Stream(stream: TCore_Stream);
var
  Header: TBmpHeader;
  BitmapSize: Integer;
begin
  BitmapSize := (FWidth * FHeight) * 4;

  Header.bfType := $4D42;
  Header.bfSize := BitmapSize + SizeOf(TBmpHeader);
  Header.bfReserved1 := 0;
  Header.bfReserved2 := 0;
  // Save offset relative. However, the spec says it has to be file absolute,
  // which we can not do properly within a stream...
  Header.bfOffBits := SizeOf(TBmpHeader);
  Header.biSize := $28;
  Header.biWidth := Width;

  Header.biHeight := -FHeight;

  Header.biPlanes := 1;
  Header.biBitCount := 32;
  Header.biCompression := 0;
  Header.biSizeImage := BitmapSize;
  Header.biXPelsPerMeter := 0;
  Header.biYPelsPerMeter := 0;
  Header.biClrUsed := 0;
  Header.biClrImportant := 0;

  stream.WriteBuffer(Header, SizeOf(TBmpHeader));

  stream.WriteBuffer(Bits^, BitmapSize);
end;

procedure TMZR.SaveToBmp24Stream(stream: TCore_Stream);
var
  wSiz, M: Integer;
  Header: TBmpHeader;
  BitmapSize: Integer;
  tempBuff: TBytes;
  p: PRGB;
  I, J: Integer;
begin
  wSiz := FWidth * 3;
  M := wSiz mod 4;
  if M <> 0 then
      inc(wSiz, 4 - M);

  BitmapSize := wSiz * FHeight;

  Header.bfType := $4D42;
  Header.bfSize := BitmapSize + SizeOf(TBmpHeader);
  Header.bfReserved1 := 0;
  Header.bfReserved2 := 0;
  Header.bfOffBits := SizeOf(TBmpHeader);
  Header.biSize := $28;
  Header.biWidth := FWidth;
  Header.biHeight := FHeight;

  Header.biPlanes := 1;
  Header.biBitCount := 24;
  Header.biCompression := 0;
  Header.biSizeImage := BitmapSize;
  Header.biXPelsPerMeter := 0;
  Header.biYPelsPerMeter := 0;
  Header.biClrUsed := 0;
  Header.biClrImportant := 0;

  ReadyBits();

  stream.WriteBuffer(Header, SizeOf(TBmpHeader));

  SetLength(tempBuff, wSiz);
  for I := FWidth * 3 to wSiz - 1 do
      tempBuff[I] := 0;

  for J := Height - 1 downto 0 do
    begin
      p := PRGB(@tempBuff[0]);
      for I := 0 to FWidth - 1 do
        begin
          p^ := RGBA2RGB(FBits^[J * FWidth + I]);
          inc(p);
        end;
      stream.WriteBuffer(tempBuff[0], wSiz);
    end;

  SetLength(tempBuff, 0);
end;

procedure TMZR.SaveToZLibCompressStream(stream: TCore_Stream);
var
  hflag: Word;
  m64: TMS64;
begin
  hflag := $8D42; // MemoryRaster compress format
  stream.Write(hflag, 2);

  m64 := TMS64.Create;
  SaveToBmp32Stream(m64);
  m64.Position := 0;
  MaxCompressStream(m64, stream);
  DisposeObject(m64);
end;

procedure TMZR.SaveToDeflateCompressStream(stream: TCore_Stream);
var
  hflag: Word;
  m64: TMS64;
begin
  hflag := $8D43; // MemoryRaster compress format
  stream.Write(hflag, 2);

  m64 := TMS64.Create;
  SaveToBmp32Stream(m64);
  m64.Position := 0;
  DeflateCompressStream(m64, stream);
  DisposeObject(m64);
end;

procedure TMZR.SaveToBRRCCompressStream(stream: TCore_Stream);
var
  hflag: Word;
  m64: TMS64;
begin
  hflag := $8D44; // MemoryRaster compress format
  stream.Write(hflag, 2);

  m64 := TMS64.Create;
  SaveToBmp32Stream(m64);
  m64.Position := 0;
  BRRCCompressStream(m64, stream);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegLS1Stream(stream: TCore_Stream);
begin
  EncodeJpegLSZRToStream1(Self, stream);
end;

procedure TMZR.SaveToJpegLS3Stream(stream: TCore_Stream);
begin
  EncodeJpegLSZRToStream3(Self, stream);
end;

procedure TMZR.SaveToYV12Stream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D46; // yv12 format
  stream.Write(hflag, 2);
  ZR_ToYV12(True, Self, stream);
end;

procedure TMZR.SaveToFastYV12Stream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D46; // yv12 format
  stream.Write(hflag, 2);
  ZR_ToYV12(False, Self, stream);
end;

procedure TMZR.SaveToHalfYUVStream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D47; // half yuv format
  stream.Write(hflag, 2);
  ZR_ToHalfYUV(True, Self, stream);
end;

procedure TMZR.SaveToFastHalfYUVStream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D47; // yu12 format
  stream.Write(hflag, 2);
  ZR_ToHalfYUV(False, Self, stream);
end;

procedure TMZR.SaveToQuartYUVStream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D48; // quart yuv format
  stream.Write(hflag, 2);
  ZR_ToQuartYUV(True, Self, stream);
end;

procedure TMZR.SaveToFastQuartYUVStream(stream: TCore_Stream);
var
  hflag: Word;
begin
  hflag := $8D48; // quart yuv format
  stream.Write(hflag, 2);
  ZR_ToQuartYUV(False, Self, stream);
end;

procedure TMZR.SaveToJpegYCbCrAStream(stream: TCore_Stream; Quality: TJpegQuality);
var
  J: TMemoryJpegZR;
  m64: TMS64;
begin
  J := TMemoryJpegZR.Create;
  J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
  J.Image.StoredCS := TJpegColorSpace.jcYCbCrA;
  J.CompressionQuality := Quality;
  J.Performance := jpBestSpeed;
  J.SetZR(Self);

  m64 := TMS64.Create;
  J.SaveToStream(m64);
  stream.Write(m64.Memory^, m64.Size);
  DisposeObject(m64);

  DisposeObject(J);
end;

procedure TMZR.SaveToJpegYCbCrStream(stream: TCore_Stream; Quality: TJpegQuality);
var
  J: TMemoryJpegZR;
  m64: TMS64;
begin
  J := TMemoryJpegZR.Create;
  J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
  J.Image.StoredCS := TJpegColorSpace.jcYCbCr;
  J.CompressionQuality := Quality;
  J.Performance := jpBestSpeed;
  J.SetZR(Self);

  m64 := TMS64.Create;
  J.SaveToStream(m64);
  stream.Write(m64.Memory^, m64.Size);
  DisposeObject(m64);

  DisposeObject(J);
end;

procedure TMZR.SaveToJPEGCMYKStream(stream: TCore_Stream; Quality: TJpegQuality);
var
  J: TMemoryJpegZR;
  m64: TMS64;
begin
  J := TMemoryJpegZR.Create;
  J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
  J.Image.StoredCS := TJpegColorSpace.jcCMYK;
  J.CompressionQuality := Quality;
  J.Performance := jpBestSpeed;
  J.SetZR(Self);

  m64 := TMS64.Create;
  J.SaveToStream(m64);
  stream.Write(m64.Memory^, m64.Size);
  DisposeObject(m64);

  DisposeObject(J);
end;

procedure TMZR.SaveToJPEGGrayStream(stream: TCore_Stream; Quality: TJpegQuality);
var
  J: TMemoryJpegZR;
  m64: TMS64;
begin
  J := TMemoryJpegZR.Create;
  J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
  J.Image.StoredCS := TJpegColorSpace.jcGray;
  J.CompressionQuality := Quality;
  J.Performance := jpBestSpeed;
  J.SetZR(Self);

  m64 := TMS64.Create;
  J.SaveToStream(m64);
  stream.Write(m64.Memory^, m64.Size);
  DisposeObject(m64);

  DisposeObject(J);
end;

procedure TMZR.SaveToJPEGGrayAStream(stream: TCore_Stream; Quality: TJpegQuality);
var
  J: TMemoryJpegZR;
  m64: TMS64;
begin
  J := TMemoryJpegZR.Create;
  J.Image.BitmapCS := TJpegColorSpace.jcRGBA;
  J.Image.StoredCS := TJpegColorSpace.jcGrayA;
  J.CompressionQuality := Quality;
  J.Performance := jpBestSpeed;
  J.SetZR(Self);

  m64 := TMS64.Create;
  J.SaveToStream(m64);
  stream.Write(m64.Memory^, m64.Size);
  DisposeObject(m64);

  DisposeObject(J);
end;

procedure TMZR.SaveToGrayscaleStream(stream: TCore_Stream);
var
  hflag: Word;
  W, H: Integer;
  p: PByteBuffer;
begin
  hflag := $8D50; // grayscale format
  stream.Write(hflag, 2);
  W := Width;
  H := Height;
  stream.Write(W, 4);
  stream.Write(H, 4);
  p := EncryptGrayscale();
  stream.Write(p^, W * H);
  System.FreeMemory(p);
end;

procedure TMZR.SaveToColor255Stream(stream: TCore_Stream);
var
  hflag: Word;
  W, H: Integer;
  p: PByteBuffer;
begin
  hflag := $8D51; // color 255 format
  stream.Write(hflag, 2);
  W := Width;
  H := Height;
  stream.Write(W, 4);
  stream.Write(H, 4);
  p := EncryptColor255();
  stream.Write(p^, W * H);
  System.FreeMemory(p);
end;

procedure TMZR.SaveToColor65535Stream(stream: TCore_Stream);
var
  hflag: Word;
  W, H: Integer;
  p: PWordBuffer;
begin
  hflag := $8D52; // color 255 format
  stream.Write(hflag, 2);
  W := Width;
  H := Height;
  stream.Write(W, 4);
  stream.Write(H, 4);
  p := EncryptColor65535();
  stream.Write(p^, W * H * 2);
  System.FreeMemory(p);
end;

procedure TMZR.SaveToPNGStream(stream: TCore_Stream);
begin
  SaveZRToPNG(Self, stream);
end;

class function TMZR.CanLoadFile(fn: SystemString): Boolean;
var
  m64: TCore_FileStream;
begin
  m64 := TCore_FileStream.Create(fn, fmOpenRead);
  try
      Result := CanLoadStream(m64);
  except
      Result := False;
  end;
  DisposeObject(m64);
end;

procedure TMZR.LoadFromFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
    m64.LoadFromFile(fn);
    m64.Position := 0;
    LoadFromStream(m64);
  except
      Reset();
  end;
  DisposeObject(m64);
end;

procedure TMZR.SaveToBmp32File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToBmp32Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToBmp24File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToBmp24Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToFile(fn: SystemString);
var
  mem: TMS64;
begin
  if umlMultipleMatch('*.seq', fn) and (Self is TSequenceMemoryZR) then
    begin
      mem := TMS64.Create;
      TSequenceMemoryZR(Self).SaveToSequenceStream(mem);
      mem.SaveToFile(fn);
      DisposeObject(mem);
    end
  else if umlMultipleMatch('*.jpg', fn) then
      SaveToJpegYCbCrFile(fn, 90)
  else if umlMultipleMatch('*.jpeg', fn) then
      SaveToJpegYCbCrFile(fn, 90)
  else if umlMultipleMatch('*.bmp', fn) then
      SaveToBmp32File(fn)
  else if umlMultipleMatch('*.yv12', fn) then
      SaveToYV12File(fn)
  else if umlMultipleMatch('*.jls', fn) then
      SaveToJpegLS3File(fn)
  else if umlMultipleMatch('*.hyuv', fn) then
      SaveToHalfYUVFile(fn)
  else if umlMultipleMatch('*.qyuv', fn) then
      SaveToQuartYUVFile(fn)
  else if umlMultipleMatch('*.png', fn) then
      SaveToPNGFile(fn)
  else if umlMultipleMatch('*.zlib_bmp', fn) then
      SaveToZLibCompressFile(fn)
  else if umlMultipleMatch('*.deflate_bmp', fn) then
      SaveToDeflateCompressFile(fn)
  else if umlMultipleMatch('*.BRRC_bmp', fn) then
      SaveToBRRCCompressFile(fn)
  else if umlMultipleMatch(['*.gray', '*.grayscale'], fn) then
      SaveToGrayscaleFile(fn)
  else if umlMultipleMatch(['*.255', '*.256'], fn) then
      SaveToColor255File(fn)
  else if umlMultipleMatch('*.64K', fn) then
      SaveToColor65535File(fn)
  else
      SaveToBmp32File(fn);
end;

procedure TMZR.SaveToZLibCompressFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToZLibCompressStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToDeflateCompressFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToDeflateCompressStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToBRRCCompressFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToBRRCCompressStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegLS1File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJpegLS1Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegLS3File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJpegLS3Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToYV12File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToYV12Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToFastYV12File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToFastYV12Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToHalfYUVFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToHalfYUVStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToFastHalfYUVFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToFastHalfYUVStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToQuartYUVFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToQuartYUVStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToFastQuartYUVFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToFastQuartYUVStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegYCbCrAFile(fn: SystemString; Quality: TJpegQuality);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJpegYCbCrAStream(m64, Quality);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegYCbCrFile(fn: SystemString; Quality: TJpegQuality);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJpegYCbCrStream(m64, Quality);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegCMYKFile(fn: SystemString; Quality: TJpegQuality);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJPEGCMYKStream(m64, Quality);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegGrayFile(fn: SystemString; Quality: TJpegQuality);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJPEGGrayStream(m64, Quality);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToJpegGrayAFile(fn: SystemString; Quality: TJpegQuality);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToJPEGGrayAStream(m64, Quality);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToGrayscaleFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToGrayscaleStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToColor255File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToColor255Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToColor65535File(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToColor65535Stream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

procedure TMZR.SaveToPNGFile(fn: SystemString);
var
  m64: TMS64;
begin
  m64 := TMS64.Create;
  try
      SaveToPNGStream(m64);
  except
  end;
  m64.SaveToFile(fn);
  DisposeObject(m64);
end;

constructor TMR_List.Create;
begin
  Create(False);
end;

constructor TMR_List.Create(AutoFreeZR_: Boolean);
begin
  inherited Create;
  FCritical := TCritical.Create;
  AutoFreeZR := AutoFreeZR_;
  UserToken := '';
end;

destructor TMR_List.Destroy;
begin
  DisposeObject(FCritical);
  Clear;
  inherited Destroy;
end;

procedure TMR_List.Lock;
begin
  FCritical.Lock;
end;

procedure TMR_List.UnLock;
begin
  FCritical.UnLock;
end;

procedure TMR_List.Remove(obj: TMZR);
begin
  if AutoFreeZR then
      DisposeObject(obj);
  inherited Remove(obj);
end;

procedure TMR_List.Delete(index: Integer);
begin
  if (index >= 0) and (index < Count) then
    begin
      if AutoFreeZR then
          DisposeObject(Items[index]);
      inherited Delete(index);
    end;
end;

procedure TMR_List.Clear;
var
  I: Integer;
begin
  if AutoFreeZR then
    for I := 0 to Count - 1 do
        DisposeObject(Items[I]);
  inherited Clear;
end;

procedure TMR_List.AddZRList(L_: TMR_List);
var
  I: Integer;
begin
  for I := 0 to L_.Count - 1 do
      Add(L_[I]);
end;

procedure TMR_List.AddZR2DMatrix(M_: TMR_2D_Matrix);
var
  I: Integer;
begin
  for I := 0 to M_.Count - 1 do
      AddZRList(M_[I]);
end;

function TMR_List.BuildArray: TMR_Array;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
      Result[I] := Items[I];
end;

procedure TMR_List.Clean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
      DisposeObject(Items[I]);
  Clear;
end;

constructor TMR_List_Hash_Pool.Create;
begin
  Create(False);
end;

constructor TMR_List_Hash_Pool.Create(AutoFreeZR_: Boolean);
begin
  inherited Create($FFFF, nil);
  AutoFreeZR := AutoFreeZR_;
end;

procedure TMR_List_Hash_Pool.DoFree(var Key: SystemString; var Value: TMR_List);
begin
  if AutoFreeZR then
      DisposeObject(Value);
  Value := nil;
end;

function TMR_List_Hash_Pool.Compare_Value(const Value_1, Value_2: TMR_List): Boolean;
begin
  Result := Value_1 = Value_2;
end;

procedure TMR_List_Hash_Pool.GetNameList(L_: TPascalStringList);
var
  r__: TMR_List_Hash_Pool___.TRepeat___;
begin
  L_.Clear;
  if Num <= 0 then
      exit;
  r__ := Repeat_;
  repeat
      L_.Add(r__.Queue^.Data^.Data.Primary, r__.Queue^.Data^.Data.Second);
  until not r__.Next;
end;

constructor TMR_2D_Matrix.Create;
begin
  Create(False);
end;

constructor TMR_2D_Matrix.Create(AutoFree_MR_List_: Boolean);
begin
  inherited Create;
  FCritical := TCritical.Create;
  AutoFree_MR_List := AutoFree_MR_List_;
end;

destructor TMR_2D_Matrix.Destroy;
begin
  DisposeObject(FCritical);
  Clear;
  inherited Destroy;
end;

procedure TMR_2D_Matrix.Lock;
begin
  FCritical.Lock;
end;

procedure TMR_2D_Matrix.UnLock;
begin
  FCritical.UnLock;
end;

procedure TMR_2D_Matrix.Remove(obj: TMR_List);
begin
  if AutoFree_MR_List then
      DisposeObject(obj);
  inherited Remove(obj);
end;

procedure TMR_2D_Matrix.Delete(index: Integer);
begin
  if (index >= 0) and (index < Count) then
    begin
      if AutoFree_MR_List then
          DisposeObject(Items[index]);
      inherited Delete(index);
    end;
end;

procedure TMR_2D_Matrix.Clear;
var
  I: Integer;
begin
  if AutoFree_MR_List then
    for I := 0 to Count - 1 do
        DisposeObject(Items[I]);
  inherited Clear;
end;

procedure TMR_2D_Matrix.AddZR2DMatrix(M_: TMR_2D_Matrix);
var
  I: Integer;
begin
  for I := 0 to M_.Count - 1 do
      Add(M_[I]);
end;

function TMR_2D_Matrix.BuildArray: TMR_2DArray;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Count - 1 do
      Result[I] := Items[I].BuildArray;
end;

procedure TMR_2D_Matrix.Clean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    begin
      Items[I].Clean;
      DisposeObject(Items[I]);
    end;
  inherited Clear;
end;

procedure TByteZRList.SaveToStream(stream: TCore_Stream);
var
  d: TDFE;
  I: Integer;
  br: TByteZR;
  m64: TMS64;
begin
  d := TDFE.Create;
  d.WriteInteger(Count);

  for I := 0 to Count - 1 do
    begin
      m64 := TMS64.CustomCreate(512 * 1024);
      br := Items[I];
      SaveByteZRToStream(br, m64);
      d.WriteStream(m64);
      DisposeObject(m64);
    end;

  d.EncodeAsZLib(stream, True);

  DisposeObject(d);
end;

procedure TByteZRList.LoadFromStream(stream: TCore_Stream);
var
  d: TDFE;
  C, I: Integer;
  br: TByteZR;
  m64: TMS64;
begin
  Clear;
  d := TDFE.Create;
  d.DecodeFrom(stream, True);

  C := d.Reader.ReadInteger;

  for I := 0 to C - 1 do
    begin
      m64 := TMS64.Create;
      d.Reader.ReadStream(m64);
      m64.Position := 0;
      LoadByteZRFromStream(br, m64);
      Add(br);
      DisposeObject(m64);
    end;

  DisposeObject(d);
end;

procedure TZRSerialized.Do_NoSpace(Trigger: TZDB2_Core_Space; Siz_: Int64; var retry: Boolean);
begin
  retry := FZDB2.Fast_AppendSpace(FZDB2_Delta, FZDB2_Block)
end;

function TZRSerialized.Get_AutoFreeStream: Boolean;
begin
  Result := FIOHnd.AutoFree;
end;

procedure TZRSerialized.Set_AutoFreeStream(const Value: Boolean);
begin
  FIOHnd.AutoFree := Value;
end;

constructor TZRSerialized.Create(stream_: TCore_Stream);
var
  n: U_String;
begin
  inherited Create;
  // init
  InitIOHnd(FIOHnd);
  if stream_.Size > 0 then
      stream_.Size := 0;

  if stream_ is TCore_FileStream then
      n := TCore_FileStream(stream_).filename
  else if stream_ is TReliableFileStream then
      n := TReliableFileStream(stream_).filename
  else
      n := '';
  umlFileCreateAsStream(n, stream_, FIOHnd, False);
  FSerialized_File := n;

  FZDB2 := TZDB2_Core_Space.Create(@FIOHnd);
  FZDB2.Mode := TZDB2_SpaceMode.smBigData;
  FZDB2.AutoCloseIOHnd := True;
  FZDB2.OnNoSpace := Do_NoSpace;
  FZDB2_Block := $FFFF;
  FZDB2_Delta := 500 * 1024 * 1024;
  FZDB2.Open;

  FCritical := TCritical.Create;
  FPixel_Model := TRasterSerialized_Pixel_Model.rspmBGRA;

  FWrite_History_Pool := TSerialized_History_Pool.Create;
  FRead_History_Pool := TSerialized_History_Pool.Create;
  FEnabled_Write_History := False;
  FEnabled_Read_History := False;

  FRemove_Serialized_File_On_Destroy := False;

  // update global Pool
  FInstance_Queue_Ptr := RasterSerialized_Instance_Pool.Add(Self);

  if FSerialized_File <> '' then
      DoStatus('Inited Serialized: "%s"', [FSerialized_File.Text])
  else
      DoStatus('Inited Serialized: "Memory Mode."');
end;

constructor TZRSerialized.Create_To_File(FileName_: U_String);
begin
  inherited Create;
  // init
  InitIOHnd(FIOHnd);
  umlFileCreate(FileName_, FIOHnd);

  FZDB2 := TZDB2_Core_Space.Create(@FIOHnd);
  FZDB2.Mode := TZDB2_SpaceMode.smBigData;
  FZDB2.AutoCloseIOHnd := True;
  FZDB2.OnNoSpace := Do_NoSpace;
  FZDB2_Block := $FFFF;
  FZDB2_Delta := 500 * 1024 * 1024;
  FZDB2.Open;

  FCritical := TCritical.Create;
  FPixel_Model := TRasterSerialized_Pixel_Model.rspmBGRA;

  FWrite_History_Pool := TSerialized_History_Pool.Create;
  FRead_History_Pool := TSerialized_History_Pool.Create;
  FEnabled_Write_History := False;
  FEnabled_Read_History := False;

  FSerialized_File := FileName_;
  FRemove_Serialized_File_On_Destroy := False;
  // update global Pool
  FInstance_Queue_Ptr := RasterSerialized_Instance_Pool.Add(Self);

  if FSerialized_File <> '' then
      DoStatus('Inited Serialized: "%s"', [FSerialized_File.Text]);
end;

constructor TZRSerialized.Create_To_Directory(Directory_, File_Prefix_: U_String);
var
  Path_, FileName_: U_String;
begin
  inherited Create;

  // generate temp file
  Path_ := Directory_;
  if Path_ = '' then
      Path_ := umlGetCurrentPath();
  repeat
      FileName_ := umlCombineFileName(Path_, PFormat('%s%s.ZDB2', [File_Prefix_.Text, umlGenerate_Random_Name().Text]));
  until not umlFileExists(FileName_);
  umlCreateDirectory(Path_);

  // init
  InitIOHnd(FIOHnd);
  umlFileCreate(FileName_, FIOHnd);

  FZDB2 := TZDB2_Core_Space.Create(@FIOHnd);
  FZDB2.Mode := TZDB2_SpaceMode.smBigData;
  FZDB2.AutoCloseIOHnd := True;
  FZDB2.OnNoSpace := Do_NoSpace;
  FZDB2_Block := $FFFF;
  FZDB2_Delta := 500 * 1024 * 1024;
  FZDB2.Open;

  FCritical := TCritical.Create;
  FPixel_Model := TRasterSerialized_Pixel_Model.rspmBGRA;

  FWrite_History_Pool := TSerialized_History_Pool.Create;
  FRead_History_Pool := TSerialized_History_Pool.Create;
  FEnabled_Write_History := False;
  FEnabled_Read_History := False;

  FSerialized_File := FileName_;
  FRemove_Serialized_File_On_Destroy := True;
  // update global Pool
  FInstance_Queue_Ptr := RasterSerialized_Instance_Pool.Add(Self);

  if FSerialized_File <> '' then
      DoStatus('Inited Serialized: "%s"', [FSerialized_File.Text]);
end;

destructor TZRSerialized.Destroy;
begin
  // update global Pool
  RasterSerialized_Instance_Pool.Remove_P(FInstance_Queue_Ptr);

  // free
  Clear_History();
  DisposeObject(FZDB2);
  DisposeObject(FCritical);
  DisposeObject(FWrite_History_Pool);
  DisposeObject(FRead_History_Pool);

  if FSerialized_File <> '' then
      DoStatus('Free Serialized: "%s"', [FSerialized_File.Text])
  else
      DoStatus('Free Serialized: "Memory Mode."');

  if FRemove_Serialized_File_On_Destroy and (FSerialized_File <> '') and (umlFileExists(FSerialized_File)) then
    begin
      umlDeleteFile(FSerialized_File);
      DoStatus('Remove Serialized: "%s"', [FSerialized_File.Text])
    end;
  inherited Destroy;
end;

function TZRSerialized.Write(R: TMZR): Int64;
var
  H: TZRSerializedHeader;
  ID: Integer;
  m64: TMem64;
  I: Integer;
  p: PByte;
begin
  Result := 0;
  if (R = nil) or (R.empty()) then
      exit;

  FCritical.Acquire;
  try
    H.Width := R.Width;
    H.Height := R.Height;
    case FPixel_Model of
      TRasterSerialized_Pixel_Model.rspmBGRA: H.siz := R.Width * R.Height * 4;
      TRasterSerialized_Pixel_Model.rspmBGR: H.siz := R.Width * R.Height * 3;
    end;
    H.UsedAgg := R.FAggNeed;
    H.Pixel := FPixel_Model;

    // remove old
    if R.FSerialized_ID >= 0 then
        FZDB2.RemoveData(R.FSerialized_ID, False);

    // serialized write
    m64 := TMem64.Create;
    m64.Size := SizeOf(TZRSerializedHeader) + H.siz;
    m64.WritePtr(@H, SizeOf(TZRSerializedHeader));

    // write pixel
    case FPixel_Model of
      TRasterSerialized_Pixel_Model.rspmBGRA: m64.WritePtr(@R.FBits^[0], H.siz);
      TRasterSerialized_Pixel_Model.rspmBGR:
        begin
          p := m64.PosAsPtr;
          for I := 0 to (R.Width * R.Height) - 1 do
            begin
              PRGB(p)^ := PRGB(@R.DirectBits^[I])^;
              inc(p, 3);
            end;
        end;
    end;

    // update to zdb2
    if FZDB2.WriteData(m64, ID, False) then
      begin
        // free memory
        R.CloseVertex;
        R.FreeAgg;
        System.FreeMemory(R.FBits);
        R.FBits := nil;
        R.FSerialized_ID := ID;
        R.FSerialized_Size := H.siz;
        Result := H.siz;
      end;
    DisposeObject(m64);

    if FEnabled_Write_History then
      begin
        try
          if (R.FSerialized_Write_History_Ptr <> nil) and (R.FSerialized_Write_History_Ptr^.Instance___ = FWrite_History_Pool) then
              FWrite_History_Pool.Remove_P(R.FSerialized_Write_History_Ptr);
          R.FSerialized_Write_History_Ptr := FWrite_History_Pool.Add(R);
        except
        end;
      end;
  finally
      FCritical.Release;
  end;
end;

function TZRSerialized.Read(R: TMZR): Int64;
var
  H: TZRSerializedHeader;
  m64: TMem64;
  I: Integer;
  p: PByte;
begin
  Result := 0;
  if (R = nil) or (R.FSerialized_ID < 0) then
      exit;

  R.CloseVertex;
  R.FreeAgg;

  FCritical.Acquire;
  try
    if (R.FSerialized_ID >= 0) then
      begin
        m64 := TMem64.Create;
        if FZDB2.ReadData(m64, R.FSerialized_ID) then
          begin
            m64.Position := 0;
            m64.ReadPtr(@H, SizeOf(TZRSerializedHeader));

            // recycle
            if Assigned(R.FBits) and R.FFreeBits then
                System.FreeMemory(R.FBits);

            // alloc
            R.FBits := System.GetMemory(H.Width * H.Height * 4);
            R.FWidth := H.Width;
            R.FHeight := H.Height;

            // read pixel
            case H.Pixel of
              TRasterSerialized_Pixel_Model.rspmBGRA: CopyPtr(m64.PosAsPtr, @R.FBits^[0], H.siz);
              TRasterSerialized_Pixel_Model.rspmBGR:
                begin
                  p := m64.PosAsPtr;
                  for I := 0 to (H.Width * H.Height) - 1 do
                    begin
                      R.DirectBits^[I] := RGB2RGBA(PRGB(p)^);
                      inc(p, 3);
                    end;
                end;
            end;

            R.FFreeBits := True;
            if H.UsedAgg then
                R.OpenAgg;
            Result := H.siz;
            R.FSerialized_Size := H.siz;
          end;
        DisposeObject(m64);
      end;

    if FEnabled_Read_History then
      begin
        try
          if (R.FSerialized_Read_History_Ptr <> nil) and (R.FSerialized_Read_History_Ptr^.Instance___ = FRead_History_Pool) then
              FRead_History_Pool.Remove_P(R.FSerialized_Read_History_Ptr);
          R.FSerialized_Read_History_Ptr := FRead_History_Pool.Add(R);
        except
        end;
      end;
  finally
      FCritical.Release;
  end;
end;

function TZRSerialized.Get_Raster_Size(R: TMZR): Int64;
var
  H: TZRSerializedHeader;
  m64: TMem64;
  hnd: TZDB2_BlockHandle;
begin
  Result := 0;
  if (R = nil) or (R.FSerialized_ID < 0) then
      exit;

  FCritical.Acquire;
  try
    if (R.FSerialized_ID >= 0) then
      begin
        m64 := TMem64.Create;
        m64.Size := SizeOf(TZRSerializedHeader);
        hnd := FZDB2.GetSpaceHnd(R.FSerialized_ID);
        if Length(hnd) > 0 then
          if FZDB2.Block_IO_Custom_Read(m64.Memory, hnd[0], 0, SizeOf(TZRSerializedHeader)) then
            begin
              m64.Position := 0;
              m64.ReadPtr(@H, SizeOf(TZRSerializedHeader));
              R.FSerialized_Size := H.siz;
              Result := H.siz;
            end;
        DisposeObject(m64);
        SetLength(hnd, 0);

        if FEnabled_Read_History then
          begin
            try
              if (R.FSerialized_Read_History_Ptr <> nil) and (R.FSerialized_Read_History_Ptr^.Instance___ = FRead_History_Pool) then
                  FRead_History_Pool.Remove_P(R.FSerialized_Read_History_Ptr);
              R.FSerialized_Read_History_Ptr := FRead_History_Pool.Add(R);
            except
            end;
          end;
      end;
  finally
      FCritical.Release;
  end;
end;

procedure TZRSerialized.Remove(R: TMZR);
var
  I: Integer;
begin
  FCritical.Acquire;
  try
    // remove old
    if R.FSerialized_ID >= 0 then
        FZDB2.RemoveData(R.FSerialized_ID, False);

    if (R.FSerialized_Write_History_Ptr <> nil) and (R.FSerialized_Write_History_Ptr^.Instance___ = FWrite_History_Pool) then
        FWrite_History_Pool.Remove_P(R.FSerialized_Write_History_Ptr);
    R.FSerialized_Write_History_Ptr := nil;

    if (R.FSerialized_Read_History_Ptr <> nil) and (R.FSerialized_Read_History_Ptr^.Instance___ = FRead_History_Pool) then
        FRead_History_Pool.Remove_P(R.FSerialized_Read_History_Ptr);
    R.FSerialized_Read_History_Ptr := nil;
  finally
      FCritical.Release;
  end;
end;

procedure TZRSerialized.Clear_History;
begin
  FCritical.Acquire;
  try
    if FRead_History_Pool.Num > 0 then
      with FRead_History_Pool.Repeat_ do
        repeat
            Queue^.Data.FSerialized_Read_History_Ptr := nil;
        until not Next;
    FRead_History_Pool.Clear;

    if FWrite_History_Pool.Num > 0 then
      with FWrite_History_Pool.Repeat_ do
        repeat
            Queue^.Data.FSerialized_Write_History_Ptr := nil;
        until not Next;
    FWrite_History_Pool.Clear;
  finally
      FCritical.Release;
  end;
end;

procedure TZRSerialized.Format_Space;
begin
  FCritical.Acquire;
  try
      FZDB2.Format_Space;
  finally
      FCritical.Release;
  end;
end;

procedure TZRSerialized.Lock;
begin
  FCritical.Acquire;
end;

procedure TZRSerialized.UnLock;
begin
  FCritical.Release;
end;

function TZRSerialized.StreamSize: Int64;
begin
  FCritical.Acquire;
  with FZDB2.State^ do
      Result := Physics - FreeSpace;
  FCritical.Release;
end;
