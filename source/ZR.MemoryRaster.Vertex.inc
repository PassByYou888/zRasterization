{ ****************************************************************************** }
{ * memory Rasterization Vertex                                                * }
{ ****************************************************************************** }

function EnsureCCWinding(var t: TTriangle): Boolean; inline;
begin
  Result := (t[1, 0] - t[0, 0]) * (t[2, 1] - t[0, 1]) > (t[2, 0] - t[0, 0]) * (t[1, 1] - t[0, 1]);
end;

function TexCoordWrapRepeat(F: TGeoFloat): TGeoFloat;
begin
  if F < 0 then
      Result := 1.0 - Trunc(F) + F
  else if F > 1.0 then
      Result := F - Trunc(F)
  else
      Result := F;
end;

procedure Vertex_ComputeBlend(const Sender: TZRVertex; const F, M: TRColor; var B: TRColor);
begin
  // overlap alpha
  TRColorEntry(B).A := umlMax(TRColorEntry(B).A, TRColorEntry(F).A);
  if M >= $FF then
      BlendMem(F, B)
  else
      BlendMemEx(F, B, M);
end;

function Vertex_ComputeNearest(const Sender: TZRVertex; const Sampler: TMZR; const X, Y: TGeoFloat): TRColor;
var
  tu0, tv0: Integer;
begin
  if Sender.LockSamplerCoord and ((X < 0) or (X > 1) or (Y < 0) or (Y > 1)) then
    begin
      Result := RColor(0, 0, 0, $FF);
      exit;
    end;
  tu0 := ClampInt(Trunc(TexCoordWrapRepeat(X) * (Sampler.Width0)), 0, Sampler.Width0i);
  tv0 := ClampInt(Trunc(TexCoordWrapRepeat(Y) * (Sampler.Height0)), 0, Sampler.Height0i);
  Result := Sampler.FastPixel[tu0, tv0];
end;

function Vertex_ComputeLinear(const Sender: TZRVertex; const Sampler: TMZR; const X, Y: TGeoFloat): TRColor;
const
  C_FF: Single = $FF;
var
  fx, fy: TGeoFloat;
  i_x, i_y: Integer;
  i_x2, i_y2: Integer;
  delta_x, delta_y: TGeoFloat;
  k1, k2, k3, K4: TGeoFloat;
  c1, c2, c3, c4: TRColorEntry;
  R, G, B, A: TGeoFloat;
begin
  if Sender.LockSamplerCoord and ((X < 0) or (X > 1) or (Y < 0) or (Y > 1)) then
    begin
      Result := RColor(0, 0, 0, $FF);
      exit;
    end;
  fx := TexCoordWrapRepeat(X) * Sampler.Width0;
  fy := TexCoordWrapRepeat(Y) * Sampler.Height0;

  i_x := ClampInt(Trunc(fx), 0, Sampler.Width0i);
  i_y := ClampInt(Trunc(fy), 0, Sampler.Height0i);

  i_x2 := i_x + 1;
  i_y2 := i_y + 1;
  if (i_x2 > Sampler.Width0) or (i_y2 > Sampler.Height0) then
    begin
      Result := Sampler.FastPixel[i_x, i_y];
      exit;
    end;

  delta_x := Frac(fx);
  delta_y := Frac(fy);

  k1 := (1 - delta_x) * (1 - delta_y);
  k2 := delta_x * (1 - delta_y);
  k3 := delta_x * delta_y;
  K4 := (1 - delta_x) * delta_y;

  c1.BGRA := Sampler.FastPixel[i_x, i_y];
  c2.BGRA := Sampler.FastPixel[i_x2, i_y];
  c3.BGRA := Sampler.FastPixel[i_x2, i_y2];
  c4.BGRA := Sampler.FastPixel[i_x, i_y2];

  R := ((c1.R / C_FF) * k1) + ((c2.R / C_FF) * k2) + ((c3.R / C_FF) * k3) + ((c4.R / C_FF) * K4);
  G := ((c1.G / C_FF) * k1) + ((c2.G / C_FF) * k2) + ((c3.G / C_FF) * k3) + ((c4.G / C_FF) * K4);
  B := ((c1.B / C_FF) * k1) + ((c2.B / C_FF) * k2) + ((c3.B / C_FF) * k3) + ((c4.B / C_FF) * K4);
  A := ((c1.A / C_FF) * k1) + ((c2.A / C_FF) * k2) + ((c3.A / C_FF) * k3) + ((c4.A / C_FF) * K4);

  Result := RColorF(R, G, B, A);
end;

procedure TZRVertex.ZR_Triangle(const FS: TFragmentSampling; const sc: TRColor; const tex: TMZR; const SamplerTri, RenderTri: TTriangle);

{$IFDEF Parallel}
type
  { fragment parameter }
  TFragmentParam = record
    bitDst, j, start_x, frag_count: Int64;
  end;

  PFragmentParam = ^TFragmentParam;
{$ENDIF Parallel}
  function ComputeDeterminant: TGeoFloat;
  var
    x1, x2, x3, y1, y2, y3: TGeoFloat;
  begin
    x1 := RenderTri[0, 0];
    y1 := RenderTri[0, 1];
    x2 := RenderTri[1, 0];
    y2 := RenderTri[1, 1];
    x3 := RenderTri[2, 0];
    y3 := RenderTri[2, 1];
    Result := (x1 * y2 - x2 * y1) + (x2 * y3 - x3 * y2) + (x3 * y1 - x1 * y3);
  end;

  function ComputeInterpolationConsts(const Determinant, W1, W2, W3: TGeoFloat): TBilerpConsts;
  var
    x1, x2, x3, y1, y2, y3: TGeoFloat;
  begin
    x1 := RenderTri[0, 0];
    y1 := RenderTri[0, 1];
    x2 := RenderTri[1, 0];
    y2 := RenderTri[1, 1];
    x3 := RenderTri[2, 0];
    y3 := RenderTri[2, 1];
    Result.A := ((y2 - y3) * W1 + (y3 - y1) * W2 + (y1 - y2) * W3) / Determinant;
    Result.B := ((x3 - x2) * W1 + (x1 - x3) * W2 + (x2 - x1) * W3) / Determinant;
    Result.c := ((x2 * y3 - x3 * y2) * W1 + (x3 * y1 - x1 * y3) * W2 + (x1 * y2 - x2 * y1) * W3) / Determinant;
  end;

var
  DX12, DX23, DX31: Int64; // delta X
  DY12, DY23, DY31: Int64; // delta Y
  CY1, CY2, CY3: Int64; // Correct Y
  CX1, CX2, CX3: Int64; // Correct X
  minX, maxX, minY, maxY: Int64;
  i, j, row_last_x, row_frag_count, bitDst: Int64;
  Determinant: TGeoFloat;
  attr_u, attr_v: TBilerpConsts;

  // parallel
{$IFDEF Parallel}
  FragmentParamNum: Integer;
  FragmentParamArry: array of TFragmentParam;
{$ENDIF Parallel}
  function min3(const A, B, c: Int64): Int64;
  begin
    Result := umlMin(A, umlMin(B, c));
    if Result > 0 then
        Result := (Result + 15) div 16
    else
        Result := (Result - 15) div 16;
  end;

  function max3(const A, B, c: Int64): Int64;
  begin
    Result := umlMax(A, umlMax(B, c));
    if Result > 0 then
        Result := (Result + 15) div 16
    else
        Result := (Result - 15) div 16;
  end;

  procedure ZR_Setup;
  var
    x1, x2, x3, y1, y2, y3, c1, c2, c3: Int64;
  begin
    // fixed-point coordinates
    x1 := Round(RenderTri[0, 0] * 16);
    y1 := Round(RenderTri[0, 1] * 16);
    x2 := Round(RenderTri[1, 0] * 16);
    y2 := Round(RenderTri[1, 1] * 16);
    x3 := Round(RenderTri[2, 0] * 16);
    y3 := Round(RenderTri[2, 1] * 16);

    // Deltas
    DX12 := x1 - x2;
    DX23 := x2 - x3;
    DX31 := x3 - x1;
    DY12 := y1 - y2;
    DY23 := y2 - y3;
    DY31 := y3 - y1;

    // Half-edge constants
    c1 := (DY12 * x1 - DX12 * y1) div 16;
    c2 := (DY23 * x2 - DX23 * y2) div 16;
    c3 := (DY31 * x3 - DX31 * y3) div 16;

    // Correct for fill convention
    if (DY12 < 0) or ((DY12 = 0) and (DX12 > 0)) then
        inc(c1);
    if (DY23 < 0) or ((DY23 = 0) and (DX23 > 0)) then
        inc(c2);
    if (DY31 < 0) or ((DY31 = 0) and (DX31 > 0)) then
        inc(c3);

    // Bounding rectangle
    minX := min3(x1, x2, x3);
    maxX := max3(x1, x2, x3);
    minY := min3(y1, y2, y3);
    maxY := max3(y1, y2, y3);

    minX := umlMax(-Window.Width, minX);
    minX := umlMin(Window.Width, minX);
    maxX := umlMin(Window.Width, maxX);
    maxX := umlMax(-Window.Width, maxX);

    minY := umlMax(-Window.Height, minY);
    minY := umlMin(Window.Height, minY);
    maxY := umlMin(Window.Height, maxY);
    maxY := umlMax(-Window.Height, maxY);

    if minX > maxX then
        TSwap<Int64>.Do_(minX, maxX);
    if minY > maxY then
        TSwap<Int64>.Do_(minY, maxY);

    CY1 := c1 + (DX12 * minY - DY12 * minX);
    CY2 := c2 + (DX23 * minY - DY23 * minX);
    CY3 := c3 + (DX31 * minY - DY31 * minX);
  end;

{$IFDEF Parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: Integer);
  begin
    FillFragment(FS, sc, tex,
      FragmentParamArry[pass].bitDst,
      FragmentParamArry[pass].j,
      FragmentParamArry[pass].start_x,
      FragmentParamArry[pass].frag_count,
      attr_v, attr_u);
  end;
{$ENDIF FPC}
{$ENDIF Parallel}


begin
  // prepare pixel rasterization
  Window.ReadyBits();
  ZR_Setup;

  // init triangle interpolation
  Determinant := ComputeDeterminant;
  if Determinant = 0 then
      exit;
  attr_u := ComputeInterpolationConsts(Determinant, SamplerTri[0, 0], SamplerTri[1, 0], SamplerTri[2, 0]);
  attr_v := ComputeInterpolationConsts(Determinant, SamplerTri[0, 1], SamplerTri[1, 1], SamplerTri[2, 1]);

  // prepare parallel
{$IFDEF Parallel}
  FragmentParamNum := 0;
  SetLength(FragmentParamArry, 0);
  if LocalParallel and Parallel and WorkInParallelCore.V and (maxY - minY >= TZRVertex.ParallelHeightTrigger) then
      SetLength(FragmentParamArry, maxY - minY);
{$ENDIF Parallel}
  // fill through bounding rectangle
  bitDst := minY * Window.Width;
  j := minY;
  while j < maxY do
    begin
      CX1 := CY1;
      CX2 := CY2;
      CX3 := CY3;
      row_frag_count := 0;
      row_last_x := 0;
      if (j >= 0) and (j < Window.Height) then // if empty line
        begin
          // prepare row_frag_count
          i := minX;
          while i < maxX do
            begin
              // When all half-space functions positive, pixel is in triangle
              // fast test only sign bits
              if (CX1 or CX2 or CX3 > 0) then
                begin
                  inc(row_frag_count);
                  row_last_x := i;
                end;
              dec(CX1, DY12);
              dec(CX2, DY23);
              dec(CX3, DY31);
              inc(i);
            end;
          if (row_frag_count > 0) then
            begin
{$IFDEF Parallel}
              if (FragmentParamNum < length(FragmentParamArry)) and (row_frag_count >= TZRVertex.ParallelWidthTrigger) then
                begin
                  FragmentParamArry[FragmentParamNum].bitDst := bitDst;
                  FragmentParamArry[FragmentParamNum].j := j;
                  FragmentParamArry[FragmentParamNum].start_x := row_last_x + 1 - row_frag_count;
                  FragmentParamArry[FragmentParamNum].frag_count := row_frag_count;
                  inc(FragmentParamNum);
                end
              else
{$ENDIF Parallel}
                  FillFragment(FS, sc, tex, bitDst, j, row_last_x + 1 - row_frag_count, row_frag_count, attr_v, attr_u);
            end;
        end;
      inc(CY1, DX12);
      inc(CY2, DX23);
      inc(CY3, DX31);
      inc(bitDst, Window.Width);
      inc(j);
    end;

{$IFDEF Parallel}
  if FragmentParamNum > 0 then
    begin
{$IFDEF FPC}
      FPCParallelFor(Nested_ParallelFor, 0, FragmentParamNum - 1);
{$ELSE FPC}
      DelphiParallelFor(0, FragmentParamNum - 1, procedure(pass: Integer)
        begin
          FillFragment(FS, sc, tex,
            FragmentParamArry[pass].bitDst,
            FragmentParamArry[pass].j,
            FragmentParamArry[pass].start_x,
            FragmentParamArry[pass].frag_count,
            attr_v, attr_u);
        end);
{$ENDIF FPC}
      SetLength(FragmentParamArry, 0);
    end;
{$ENDIF Parallel}
end;

procedure TZRVertex.FillFragment(const FS: TFragmentSampling; const sc: TRColor; const tex: TMZR;
const bitDst, j, start_x, frag_count: Int64; var attr_v, attr_u: TBilerpConsts);
var
  i, bitX: Int64;
  X, Y: TGeoFloat;
begin
  X := attr_u.A * start_x + attr_u.B * j + attr_u.c;
  Y := attr_v.A * start_x + attr_v.B * j + attr_v.c;

  bitX := bitDst + start_x;
  i := 0;
  while i < frag_count do
    begin
      if (start_x + i >= 0) and (start_x + i < Window.Width) and (bitX >= 0) and (bitX < WindowSize) and (FNearestWriteBuffer[bitX] <> FNearestWriterID) then
        begin
          FNearestWriteBuffer[bitX] := FNearestWriterID;
          case FS of
            fsSolid:
              begin
                with TRColorEntry(Window.FBits^[bitX]) do
                    A := umlMax(A, TRColorEntry(sc).A);
                BlendMem(sc, Window.FBits^[bitX]);
              end;
            fsNearest: ComputeBlend(Self, ComputeNearest(Self, tex, X, Y), tex.MasterAlpha, Window.FBits^[bitX]);
            fsLinear: ComputeBlend(Self, ComputeLinear(Self, tex, X, Y), tex.MasterAlpha, Window.FBits^[bitX]);
          end;
        end;

      X := X + attr_u.A;
      Y := Y + attr_v.A;
      inc(bitX);
      inc(i);
    end;
end;

procedure TZRVertex.NewWriterBuffer;
var
  old: Byte;
begin
  if FCurrentUpdate > 0 then
      exit;
  old := FNearestWriterID;
  inc(FNearestWriterID);
  if FNearestWriterID < old then
    begin
      FillPtrByte(@FNearestWriteBuffer[0], length(FNearestWriteBuffer), FNearestWriterID);
      inc(FNearestWriterID);
    end;
end;

procedure TZRVertex.internal_Draw(const RenderTri: TTriangle; const Sampler: TRColor);
var
  nRenderTri: TTriangle;
begin
  nRenderTri := RenderTri;
  {
    Make sure the triangle has counter-clockwise winding
    For a triangle A B C, you can find the winding by computing the cross product (B - A) rx (C - A).
    For 2d tri's, with z=0, it will only have a z component.
    To give all the same winding, swap vertices C and B if this z component is negative.
  }
  if EnsureCCWinding(nRenderTri) then
      SwapVec2(nRenderTri[1], nRenderTri[2]);

  try
    ZR_Triangle(TFragmentSampling.fsSolid, Sampler, nil, ZeroTriangle, TriRound(TriMul(nRenderTri, Window.Size0)));
    if TZRVertex.DebugTriangle then
        Window.DrawTriangle(RenderTri, True, TZRVertex.DebugTriangleColor, False);
  except
  end;
end;

procedure TZRVertex.internal_Draw(const SamplerTri, RenderTri: TTriangle; const Sampler: TMZR; const bilinear_sampling: Boolean);
var
  nSamplerTri, nRenderTri: TTriangle;
  F: TFragmentSampling;
begin
  nSamplerTri := SamplerTri;
  nRenderTri := RenderTri;
  {
    Make sure the triangle has counter-clockwise winding
    For a triangle A B C, you can find the winding by computing the cross product (B - A) rx (C - A).
    For 2d tri's, with z=0, it will only have a z component.
    To give all the same winding, swap vertices C and B if this z component is negative.
  }
  if EnsureCCWinding(nRenderTri) then
    begin
      SwapVec2(nRenderTri[1], nRenderTri[2]);
      SwapVec2(nSamplerTri[1], nSamplerTri[2]);
    end;

  // offset texel centers
  nSamplerTri := TriSub(nSamplerTri, Vec2(1.0 / (2.0 * Sampler.Width0), 1.0 / (2.0 * Sampler.Height0)));
  // scale vertices to pixel grid
  nRenderTri := TriRound(TriMul(nRenderTri, Window.Size0));

  if bilinear_sampling then
      F := TFragmentSampling.fsLinear
  else
      F := TFragmentSampling.fsNearest;

  try
    Sampler.ReadyBits();
    ZR_Triangle(F, RColor(0, 0, 0), Sampler, nSamplerTri, nRenderTri);
    if TZRVertex.DebugTriangle then
        Window.DrawTriangle(RenderTri, True, TZRVertex.DebugTriangleColor, False);
  except
  end;
end;

procedure TZRVertex.internal_Draw(const SamplerTri, RenderTri: TTriangle; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
var
  MA: Cardinal;
begin
  MA := Sampler.MasterAlpha;
  if alpha > 1.0 then
      Sampler.MasterAlpha := ClampByte(Trunc(alpha))
  else
      Sampler.MasterAlpha := ClampByte(Trunc(alpha * $FF));

  try
      internal_Draw(SamplerTri, RenderTri, Sampler, bilinear_sampling);
  except
  end;

  Sampler.MasterAlpha := MA;
end;

constructor TZRVertex.Create(raster: TMZR);
begin
  inherited Create;
  SetLength(FNearestWriteBuffer, raster.Width * raster.Height);
  FNearestWriterID := 0;
  FCurrentUpdate := 0;
  ComputeBlend := Vertex_ComputeBlend;
  ComputeNearest := Vertex_ComputeNearest;
  ComputeLinear := Vertex_ComputeLinear;
  LockSamplerCoord := True;
  LocalParallel := True;
  Window := raster;
  WindowSize := Window.Width * Window.Height;
  UserData := nil;
end;

destructor TZRVertex.Destroy;
begin
  SetLength(FNearestWriteBuffer, 0);
  inherited Destroy;
end;

function TZRVertex.BeginUpdate: Byte;
begin
  if FCurrentUpdate = 0 then
      NewWriterBuffer;
  inc(FCurrentUpdate);
  Result := FNearestWriterID;
end;

procedure TZRVertex.EndUpdate;
begin
  dec(FCurrentUpdate);
end;

procedure TZRVertex.DrawTriangle(const v1, v2, v3: TVec2; const Sampler: TRColor);
begin
  NewWriterBuffer;
  internal_Draw(TriDiv(Tri(v1, v2, v3), Window.Size0), Sampler);
end;

procedure TZRVertex.DrawTriangle(const RenderTri: TTriangle; const Sampler: TRColor);
begin
  NewWriterBuffer;
  internal_Draw(TriDiv(RenderTri, Window.Size0), Sampler);
end;

procedure TZRVertex.DrawTriangle(const SamplerTri, RenderTri: TTriangle; const Sampler: TMZR; const bilinear_sampling: Boolean);
begin
  NewWriterBuffer;
  internal_Draw(TriDiv(SamplerTri, Sampler.Size0), TriDiv(RenderTri, Window.Size0), Sampler, bilinear_sampling);
end;

procedure TZRVertex.DrawTriangle(const SamplerTri, RenderTri: TTriangle; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  NewWriterBuffer;
  internal_Draw(TriDiv(SamplerTri, Sampler.Size0), TriDiv(RenderTri, Window.Size0), Sampler, bilinear_sampling, alpha);
end;

procedure TZRVertex.DrawRect(const RenVec: TV2Rect4; const Sampler: TRColor);
var
  RV: TV2Rect4;
  RenderTri: TTriangle;
begin
  NewWriterBuffer;
  RV := RenVec.Div_(Window.Size0);
  RenderTri[0] := RV.LeftTop;
  RenderTri[1] := RV.RightTop;
  RenderTri[2] := RV.LeftBottom;
  internal_Draw(RenderTri, Sampler);
  RenderTri[0] := RV.LeftBottom;
  RenderTri[1] := RV.RightTop;
  RenderTri[2] := RV.RightBottom;
  internal_Draw(RenderTri, Sampler);
end;

procedure TZRVertex.DrawRect(const SamVec, RenVec: TV2Rect4; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
var
  SV, RV: TV2Rect4;
  SamplerTri, RenderTri: TTriangle;
begin
  NewWriterBuffer;
  SV := SamVec.Div_(Sampler.Size0);
  RV := RenVec.Div_(Window.Size0);

  SamplerTri[0] := SV.LeftTop;
  SamplerTri[1] := SV.RightTop;
  SamplerTri[2] := SV.LeftBottom;
  RenderTri[0] := RV.LeftTop;
  RenderTri[1] := RV.RightTop;
  RenderTri[2] := RV.LeftBottom;
  internal_Draw(SamplerTri, RenderTri, Sampler, bilinear_sampling, alpha);

  SamplerTri[0] := SV.LeftBottom;
  SamplerTri[1] := SV.RightTop;
  SamplerTri[2] := SV.RightBottom;
  RenderTri[0] := RV.LeftBottom;
  RenderTri[1] := RV.RightTop;
  RenderTri[2] := RV.RightBottom;
  internal_Draw(SamplerTri, RenderTri, Sampler, bilinear_sampling, alpha);
end;

procedure TZRVertex.DrawRect(const RenVec: TRectV2; const Sampler: TRColor);
begin
  DrawRect(TV2Rect4.Init(RenVec, 0), Sampler);
end;

procedure TZRVertex.DrawRect(const SamVec, RenVec: TRectV2; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  DrawRect(TV2Rect4.Init(SamVec, 0), TV2Rect4.Init(RenVec, 0), Sampler, bilinear_sampling, alpha);
end;

procedure TZRVertex.DrawRect(const RenVec: TRectV2; const RenAngle: TGeoFloat; const Sampler: TRColor);
begin
  DrawRect(TV2Rect4.Init(RenVec, RenAngle), Sampler);
end;

procedure TZRVertex.DrawRect(const SamVec, RenVec: TRectV2; const RenAngle: TGeoFloat; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  DrawRect(TV2Rect4.Init(SamVec, 0), TV2Rect4.Init(RenVec, RenAngle), Sampler, bilinear_sampling, alpha);
end;

procedure TZRVertex.DrawRect(const SamVec: TV2Rect4; const RenVec: TRectV2; const RenAngle: TGeoFloat; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  DrawRect(SamVec, TV2Rect4.Init(RenVec, RenAngle), Sampler, bilinear_sampling, alpha);
end;

procedure TZRVertex.FillPoly(const RenVec: TV2L; const cen: TVec2; const Sampler: TRColor);
var
  RV: TV2L;
  rCen: TVec2;
  i: Integer;
  RenderTri: TTriangle;
begin
  NewWriterBuffer;

  RV := TV2L.Create;
  RV.Assign(RenVec);
  RV.FDiv(Window.Width0, Window.Height0);
  rCen := Vec2Div(cen, Window.Size0);

  for i := 1 to RV.Count - 1 do
    begin
      RenderTri[0] := rCen;
      RenderTri[1] := RV[i]^;
      RenderTri[2] := RV[i - 1]^;
      internal_Draw(RenderTri, Sampler);
    end;

  RenderTri[0] := rCen;
  RenderTri[1] := RV.First^;
  RenderTri[2] := RV.Last^;
  internal_Draw(RenderTri, Sampler);
  DisposeObject(RV);
end;

procedure TZRVertex.FillPoly(const RenVec: TV2L; const Sampler: TRColor);
begin
  FillPoly(RenVec, RenVec.Centroid, Sampler);
end;

procedure TZRVertex.FillPoly(const SamVec, RenVec: TV2L; const SamCen, RenCen: TVec2; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
var
  SV, RV: TV2L;
  sCen, rCen: TVec2;
  i: Integer;
  SamplerTri, RenderTri: TTriangle;
begin
  if SamVec.Count <> RenVec.Count then
      RaiseInfo('vertex error');

  NewWriterBuffer;

  SV := TV2L.Create;
  SV.Assign(SamVec);
  SV.FDiv(Sampler.Width0, Sampler.Height0);
  sCen := Vec2Div(SamCen, Sampler.Size0);

  RV := TV2L.Create;
  RV.Assign(RenVec);
  RV.FDiv(Window.Width0, Window.Height0);
  rCen := Vec2Div(RenCen, Window.Size0);

  for i := 1 to SV.Count - 1 do
    begin
      SamplerTri[0] := sCen;
      SamplerTri[1] := SV[i]^;
      SamplerTri[2] := SV[i - 1]^;

      RenderTri[0] := rCen;
      RenderTri[1] := RV[i]^;
      RenderTri[2] := RV[i - 1]^;
      internal_Draw(SamplerTri, RenderTri, Sampler, bilinear_sampling, alpha);
    end;

  SamplerTri[0] := sCen;
  SamplerTri[1] := SV.First^;
  SamplerTri[2] := SV.Last^;

  RenderTri[0] := rCen;
  RenderTri[1] := RV.First^;
  RenderTri[2] := RV.Last^;
  internal_Draw(SamplerTri, RenderTri, Sampler, bilinear_sampling, alpha);

  DisposeObject(SV);
  DisposeObject(RV);
end;

procedure TZRVertex.FillPoly(const SamVec, RenVec: TV2L; const Sampler: TMZR; const bilinear_sampling: Boolean; const alpha: TGeoFloat);
begin
  FillPoly(SamVec, RenVec, SamVec.Centroid, RenVec.Centroid, Sampler, bilinear_sampling, alpha);
end;
