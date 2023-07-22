{ ****************************************************************************** }
{ * memory Rasterization AGG                                                   * }
{ ****************************************************************************** }
constructor TMemoryZR_AggImage.Create(raster: TMZR);
begin
  inherited Create(PInt8u(raster.ScanLine[0]), raster.width, raster.height, 4 * raster.width);
end;

procedure TMemoryZR_AggImage.Attach(raster: TMZR);
begin
  inherited Attach(PInt8u(raster.ScanLine[0]), raster.width, raster.height, 4 * raster.width);
end;

function TMemoryZR_Agg2D.GetImageBlendColor: TRColor;
begin
  Result := AggColor(FImageBlendColor);
end;

procedure TMemoryZR_Agg2D.SetImageBlendColor(const Value: TRColor);
begin
  inherited ImageBlendColor := AggColor(Value);
end;

function TMemoryZR_Agg2D.GetFillColor: TRColor;
begin
  Result := AggColor(FFillColor);
end;

procedure TMemoryZR_Agg2D.SetFillColor(const Value: TRColor);
begin
  inherited FillColor := AggColor(Value);
end;

function TMemoryZR_Agg2D.GetLineColor: TRColor;
begin
  Result := AggColor(FLineColor);
end;

procedure TMemoryZR_Agg2D.SetLineColor(const Value: TRColor);
begin
  inherited LineColor := AggColor(Value);
end;

procedure TMemoryZR_Agg2D.Attach(raster: TMZR);
begin
  inherited Attach(PInt8u(raster.ScanLine[0]), raster.width, raster.height, 4 * raster.width);
end;

procedure TMemoryZR_Agg2D.FillLinearGradient(x1, y1, x2, y2: Double; c1, c2: TRColor; Profile: Double);
begin
  inherited FillLinearGradient(x1, y1, x2, y2, AggColor(c1), AggColor(c2), Profile);
end;

procedure TMemoryZR_Agg2D.LineLinearGradient(x1, y1, x2, y2: Double; c1, c2: TRColor; Profile: Double);
begin
  inherited LineLinearGradient(x1, y1, x2, y2, AggColor(c1), AggColor(c2), Profile);
end;

procedure TMemoryZR_Agg2D.FillRadialGradient(x, y, r: Double; c1, c2: TRColor; Profile: Double);
begin
  inherited FillRadialGradient(x, y, r, AggColor(c1), AggColor(c2), Profile);
end;

procedure TMemoryZR_Agg2D.LineRadialGradient(x, y, r: Double; c1, c2: TRColor; Profile: Double);
begin
  inherited LineRadialGradient(x, y, r, AggColor(c1), AggColor(c2), Profile);
end;

procedure TMemoryZR_Agg2D.FillRadialGradient(x, y, r: Double; c1, c2, c3: TRColor);
begin
  inherited FillRadialGradient(x, y, r, AggColor(c1), AggColor(c2), AggColor(c3));
end;

procedure TMemoryZR_Agg2D.LineRadialGradient(x, y, r: Double; c1, c2, c3: TRColor);
begin
  inherited LineRadialGradient(x, y, r, AggColor(c1), AggColor(c2), AggColor(c3));
end;
