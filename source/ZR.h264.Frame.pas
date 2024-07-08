{ ****************************************************************************** }
{ * h264 encoder                                                               * }
{ ****************************************************************************** }
unit ZR.h264.Frame;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses
  SysUtils, ZR.h264.Types, ZR.h264.Stats, ZR.h264.Common, ZR.h264.Image_LIB, ZR.h264.Pixel_LIB, ZR.h264.Util, ZR.Core;

const
  FRAME_PADDING_W = 16;
  FRAME_EDGE_W = FRAME_PADDING_W div 2;

type
  TFrameManager = class(TCore_Object_Intermediate)
  private
    listL0: array of TFrame;
    ifree: int32_t;
    procedure GetRef(out f: PFrame; const frame_num: int32_t);
  public
    procedure InsertRef(var f: TFrame);
    procedure SetRefs(var f: TFrame; const frame_num, nrefs: int32_t);
    procedure GetFree(var f: TFrame);
    constructor Create(const ref_count, mb_w, mb_h: int32_t);
    destructor Destroy; override;
  end;

procedure frame_new(var Frame: TFrame; const mb_width, mb_height: int32_t);
procedure frame_free(var Frame: TFrame);

procedure frame_img2frame_copy(var Frame: TFrame; const img: TPlanarImage);
procedure frame_paint_edges(var Frame: TFrame);
procedure frame_hpel_interpolate(var Frame: TFrame);

implementation

procedure TFrameManager.GetRef(out f: PFrame; const frame_num: int32_t);
var
  i: int32_t;
begin
  for i := 0 to length(listL0) - 1 do
    if listL0[i].Num = frame_num then
      begin
        f := @listL0[i];
        Exit;
      end;
  RaiseInfo('GetRef - ref not found! %d', [frame_num]);
end;

// insert ref. frame to oldest slot, mark oldest taken slot as free
procedure TFrameManager.InsertRef(var f: TFrame);
var
  i, oldest: int32_t;
begin
  oldest := MaxInt;
  for i := 0 to length(listL0) - 1 do
    if listL0[i].Num < oldest then
      begin
        ifree := i;
        oldest := listL0[i].Num;
      end;
  listL0[ifree] := f;

  oldest := MaxInt;
  for i := 0 to length(listL0) - 1 do
    if listL0[i].Num < oldest then
      begin
        ifree := i;
        oldest := listL0[i].Num;
      end;
end;

procedure TFrameManager.SetRefs(var f: TFrame; const frame_num, nrefs: int32_t);
var
  i: int32_t;
  t: PFrame;
begin
  for i := 1 to nrefs do
    begin
      GetRef(t, frame_num - i);
      f.refs[i - 1] := t;
    end;
end;

procedure TFrameManager.GetFree(var f: TFrame);
begin
  if ifree = -1 then
      RaiseInfo('GetFree - no free frame!');
  f := listL0[ifree];
  ifree := -1;
end;

constructor TFrameManager.Create(const ref_count, mb_w, mb_h: int32_t);
var
  i: int32_t;
begin
  inherited Create;
  ifree := 0;
  SetLength(listL0, ref_count + 1);
  for i := 0 to ref_count do
    begin
      frame_new(listL0[i], mb_w, mb_h);
      listL0[i].Num := -1;
    end;
end;

destructor TFrameManager.Destroy;
var
  i: int32_t;
begin
  for i := 0 to length(listL0) - 1 do
      frame_free(listL0[i]);
  listL0 := nil;
  inherited Destroy;
end;

procedure frame_new(var Frame: TFrame; const mb_width, mb_height: int32_t);
var
  padded_height, padded_width,
    frame_mem_offset, frame_mem_offset_cr: int32_t; // frame memory to image data start offset
  pfsize, pfsize_cr: int32_t; // padded frame luma / chroma plane size
  i: int32_t;
begin
  with Frame do
    begin
      mbw := mb_width;
      mbh := mb_height;
      w := mbw * 16;
      h := mbh * 16;
      w_cr := w div 2;
      h_cr := h div 2;
      padded_width := w + FRAME_PADDING_W * 2;
      padded_height := h + FRAME_PADDING_W * 2;
    end;

  Frame.pw := padded_width;
  Frame.ph := padded_height;
  Frame.stride := padded_width;
  Frame.stride_c := padded_width div 2;

  pfsize := padded_width * padded_height;
  pfsize_cr := pfsize div 4;
  frame_mem_offset := FRAME_PADDING_W * padded_width + FRAME_PADDING_W;
  frame_mem_offset_cr := FRAME_PADDING_W * padded_width div 4 + FRAME_PADDING_W div 2;

  Frame.mbs := fev_malloc(mb_width * mb_height * SizeOf(TMacroblock));
  Frame.aq_table := fev_malloc(mb_width * mb_height);
  Frame.qp := 0;
  Frame.qp_avg := 0;
  Frame.Num := 0;

  Frame.frame_mem_offset := frame_mem_offset;
  Frame.frame_mem_offset_cr := frame_mem_offset_cr;

  // luma plane
  Frame.mem[0] := fev_malloc(pfsize + pfsize_cr * 2);
  Frame.plane[0] := Frame.mem[0] + frame_mem_offset;
  // chroma planes
  Frame.mem[1] := Frame.mem[0] + pfsize;
  Frame.mem[2] := Frame.mem[1] + pfsize_cr;
  Frame.plane[1] := Frame.mem[1] + frame_mem_offset_cr;
  Frame.plane[2] := Frame.mem[2] + frame_mem_offset_cr;
  // decoded planes + interpolated planes
  Frame.mem[3] := fev_malloc(pfsize * 4 + pfsize_cr * 2);
  Frame.plane_dec[0] := Frame.mem[3] + frame_mem_offset;
  for i := 0 to 3 do
      Frame.luma_mc[i] := Frame.plane_dec[0] + pfsize * i;
  for i := 0 to 3 do
      Frame.luma_mc_qpel[i] := Frame.luma_mc[i];
  Frame.luma_mc_qpel[4] := Frame.luma_mc[0] + 1;
  Frame.luma_mc_qpel[5] := Frame.luma_mc[2] + 1;
  Frame.luma_mc_qpel[6] := Frame.luma_mc[0] + padded_width;
  Frame.luma_mc_qpel[7] := Frame.luma_mc[1] + padded_width;

  Frame.mem[4] := Frame.mem[3] + pfsize * 4;
  Frame.mem[5] := Frame.mem[4] + pfsize_cr;
  Frame.plane_dec[1] := Frame.mem[4] + frame_mem_offset_cr;
  Frame.plane_dec[2] := Frame.mem[5] + frame_mem_offset_cr;

  // 4x4 block offsets
  with Frame do
    begin
      blk_offset[0] := 0;
      blk_offset[1] := 4;
      blk_offset[2] := 0 + 4 * stride;
      blk_offset[3] := 4 + 4 * stride;

      blk_offset[4] := 8;
      blk_offset[5] := 12;
      blk_offset[6] := 8 + 4 * stride;
      blk_offset[7] := 12 + 4 * stride;

      blk_offset[8] := 0 + 8 * stride;
      blk_offset[9] := 4 + 8 * stride;
      blk_offset[10] := 0 + 12 * stride;
      blk_offset[11] := 4 + 12 * stride;

      blk_offset[12] := 8 + 8 * stride;
      blk_offset[13] := 12 + 8 * stride;
      blk_offset[14] := 8 + 12 * stride;
      blk_offset[15] := 12 + 12 * stride;

      blk_chroma_offset[0] := 0;
      blk_chroma_offset[1] := 4;
      blk_chroma_offset[2] := 0 + 4 * stride_c;
      blk_chroma_offset[3] := 4 + 4 * stride_c;
    end;

  // other
  Frame.filter_hv_temp := fev_malloc(padded_width * 2);
  Frame.bs_buf := fev_malloc(Frame.w * Frame.h * 3);

  Frame.Stats := TFrameStats.Create;
end;

procedure frame_free(var Frame: TFrame);
begin
  fev_free(Frame.mbs);
  fev_free(Frame.aq_table);
  fev_free(Frame.mem[0]);
  fev_free(Frame.mem[3]);
  fev_free(Frame.filter_hv_temp);
  fev_free(Frame.bs_buf);
  Frame.Stats.Free;

  Frame.plane[0] := nil;
  Frame.plane[1] := nil;
  Frame.plane[2] := nil;
  Frame.filter_hv_temp := nil;

  Frame.stride := 0;
  Frame.stride_c := 0;

  Frame.w := 0;
  Frame.h := 0;
end;

procedure frame_swap(var a, b: TFrame);
var
  t: TFrame;
begin
  t := a;
  a := b;
  b := t;
end;

(* ******************************************************************************
  frame_setup_adapt_q
  adjust mb quant according to variance
*)
procedure frame_setup_adapt_q(var Frame: TFrame; pixbuffer: uint8_p; const base_qp: uint8_t);
const
  QP_RANGE = 10;
  QP_MIN = 15;
  QP_MAX = 51;
  VAR_SHIFT = 14;

var
  x, y: int32_t;
  vari: int32_t;
  qp: int32_t;
  pfenc, pix: uint8_p;
  stride, Avg: int32_t;

begin
  stride := Frame.mbw;
  pix := pixbuffer;

  // derive qp from variance
  Avg := 0;
  for y := 0 to (Frame.mbh - 1) do
    begin
      pfenc := Frame.plane[0] + y * 16 * Frame.stride;

      for x := 0 to (Frame.mbw - 1) do
        begin
          pixel_load_16x16(pix, pfenc, Frame.stride);
          vari := DSP.var_16x16(pix);
          inc(pfenc, 16);
          qp := base_qp - QP_RANGE;
          qp := clip3(QP_MIN, qp + Min(vari shr VAR_SHIFT, QP_RANGE * 2), QP_MAX);
          inc(Avg, qp);
          Frame.aq_table[y * stride + x] := qp;
        end;
    end;

  Frame.aq_table[0] := base_qp;
  Frame.qp_avg := Avg / (Frame.mbw * Frame.mbh);
end;

{ skopirovanie dat do zarovnanej oblasti pamate spolu s vyplnou na okrajoch
}
procedure paint_edge_vert(Src, Dst: uint8_p; stride, h: int32_t; const edge_width: uint8_t);
var
  i, j: int32_t;
begin
  for i := 0 to h - 1 do
    begin
      for j := 0 to edge_width - 1 do
          Dst[j] := Src^;
      inc(Dst, stride);
      inc(Src, stride);
    end;
end;

procedure paint_edge_horiz(Src, Dst: uint8_p; stride: int32_t; const edge_width: uint8_t);
var
  i: int32_t;
begin
  for i := 0 to edge_width - 1 do
    begin
      CopyPtr(Src, Dst, stride);
      inc(Dst, stride);
    end;
end;

procedure frame_img2frame_copy(var Frame: TFrame; const img: TPlanarImage);
var
  w, h, i, j: int32_t;
  dstride, sstride, edge_width: int32_t;
  s, d: uint8_p;
begin
  w := img.width;
  h := img.height;
  // y
  dstride := Frame.stride;
  sstride := img.stride;
  d := Frame.plane[0];
  s := img.plane[0];
  for i := 0 to h - 1 do
    begin
      CopyPtr(s, d, w);
      inc(s, sstride);
      inc(d, dstride);
    end;
  // u/v
  dstride := Frame.stride_c;
  sstride := img.stride_c;
  for j := 1 to 2 do
    begin
      d := Frame.plane[j];
      s := img.plane[j];
      for i := 0 to h div 2 - 1 do
        begin
          CopyPtr(s, d, w div 2);
          inc(s, sstride);
          inc(d, dstride);
        end;
    end;

  // fill non-mod16 edges
  if (w and $F) > 0 then
    begin
      edge_width := 16 - (img.width and $F);
      paint_edge_vert(Frame.plane[0] + w - 1, Frame.plane[0] + w, Frame.stride, Frame.h, edge_width);
      for i := 1 to 2 do
          paint_edge_vert(Frame.plane[i] + w div 2 - 1, Frame.plane[i] + w div 2, Frame.stride_c, Frame.h_cr, edge_width div 2);
    end;
  if (h and $F) > 0 then
    begin
      edge_width := 16 - (img.height and $F);
      paint_edge_horiz(Frame.plane[0] - 16 + Frame.stride * (h - 1), Frame.plane[0] - 16 + Frame.stride * h, Frame.stride, edge_width);
      for i := 1 to 2 do
          paint_edge_horiz(Frame.plane[i] - 8 + Frame.stride_c * (h div 2 - 1), Frame.plane[i] - 8 + Frame.stride_c * h div 2, Frame.stride_c, edge_width);
    end;
end;

(* ******************************************************************************
  fill plane edges with edge pixel's copies
*)
procedure plane_paint_edges(const p: uint8_p; const w, h, stride, edge_width: int32_t);
begin
  // left/right/up/down
  paint_edge_vert(p, p - edge_width, stride, h, edge_width);
  paint_edge_vert(p + w - 1, p + w, stride, h, edge_width);
  paint_edge_horiz(p - edge_width, (p - edge_width) - edge_width * stride, stride, edge_width);
  paint_edge_horiz(p - edge_width + stride * (h - 1), p - edge_width + stride * h, stride, edge_width);
end;

procedure frame_paint_edges(var Frame: TFrame);
var
  i: int32_t;
begin
  plane_paint_edges(Frame.plane_dec[0], Frame.w, Frame.h, Frame.stride, 16);
  for i := 1 to 2 do
      plane_paint_edges(Frame.plane_dec[i], Frame.w_cr, Frame.h_cr, Frame.stride_c, 8);
end;

(* ******************************************************************************
  h.264 6tap hpel filter
*)
{$IF Defined(WIN64)}
{$L frame_x64.obj}
procedure filter_horiz_line_sse2(Src, Dst: pbyte; width: integer); external name 'filter_horiz_line_sse2';
procedure filter_vert_line_sse2(Src, Dst: pbyte; width, stride: integer; tmp: psmallint); external name 'filter_vert_line_sse2';
procedure filter_hvtemp_line_sse2(Src: psmallint; Dst: pbyte; width: integer); external name 'filter_hvtemp_line_sse2';

{$POINTERMATH ON}


procedure frame_hpel_interpolate(var Frame: TFrame);

  procedure filter_asm(tmp: psmallint);
  var
    width, height: integer;
    stride: integer;
    Src: pbyte;
    Dst: array [0 .. 2] of pbyte;
    y, i: integer;
    edge_offset: integer;
  begin
    width := Frame.w;
    height := Frame.h;
    stride := Frame.stride;
    edge_offset := FRAME_EDGE_W + FRAME_EDGE_W * stride;
    Src := Frame.plane_dec[0] - edge_offset;
    for i := 0 to 2 do
        Dst[i] := Frame.luma_mc[i + 1] - edge_offset;

    for y := -FRAME_EDGE_W to height - 1 + FRAME_EDGE_W do
      begin
        // horiz
        filter_horiz_line_sse2(Src, Dst[0], width + FRAME_EDGE_W * 2);
        // vert: +8 pre dalsie temp hodnoty pre hvtemp filter
        filter_vert_line_sse2(Src, Dst[1], width + FRAME_EDGE_W * 2 + 8, stride, tmp);
        // h+v
        tmp[-1] := tmp[0];
        tmp[-2] := tmp[0];
        filter_hvtemp_line_sse2(tmp, Dst[2], width + FRAME_EDGE_W * 2);
        // next
        inc(Src, stride);
        for i := 0 to 2 do
            inc(Dst[i], stride);
      end;
  end;

begin
  filter_asm(Frame.filter_hv_temp + 2)
end;

{$ELSE}


procedure frame_hpel_interpolate(var Frame: TFrame);
var
  width, height: int32_t;
  stride: int32_t;
  Src: uint8_p;
  Dst: array [0 .. 2] of uint8_p;
  Row: array [-2 .. 3] of uint8_p;
  x, y, i, j: int32_t;
  t: array [-2 .. 3] of int32_t;
  edge_offset: int32_t;

  function Clip(i: int32_t): uint8_t;
  begin
    if i > 255 then
        i := 255
    else if i < 0 then
        i := 0;
    Result := uint8_t(i);
  end;

begin
  width := Frame.w;
  height := Frame.h;
  stride := Frame.stride;
  edge_offset := FRAME_EDGE_W + FRAME_EDGE_W * stride;
  Src := Frame.plane_dec[0] - edge_offset;
  for i := 0 to 2 do
      Dst[i] := Frame.luma_mc[i + 1] - edge_offset;

  // horizontal
  for y := 0 to height - 1 + FRAME_EDGE_W * 2 do
    begin
      for x := 0 to width - 1 + FRAME_EDGE_W * 2 do
        begin
          i := Src[-2 + x] - 5 * Src[-1 + x] + 20 * Src[0 + x] + 20 * Src[1 + x] - 5 * Src[2 + x] + Src[3 + x] + 16;
          if i < 0 then
              i := 0;
          Dst[0][x] := Clip(i shr 5);
        end;
      inc(Src, stride);
      inc(Dst[0], stride);
    end;

  // vertical + hv
  Src := Frame.plane_dec[0] - edge_offset;
  for i := -2 to 3 do
      Row[i] := Src + i * stride;

  for y := 0 to height - 1 + FRAME_EDGE_W * 2 do
    begin
      // fill temps first
      x := -1;
      for j := x - 2 to x + 3 do
          t[j - x] := Row[-2, j] - 5 * Row[-1, j] + 20 * Row[0, j] + 20 * Row[1, j] - 5 * Row[2, j] + Row[3, j];

      for x := 0 to width - 1 + FRAME_EDGE_W * 2 do
        begin
          // reuse coefs from last run
          for j := -1 to 3 do
              t[j - 1] := t[j];
          // get new vertical intermed
          j := x + 3;
          t[3] := Row[-2, j] - 5 * Row[-1, j] + 20 * Row[0, j] + 20 * Row[1, j] - 5 * Row[2, j] + Row[3, j];
          // vert
          i := t[0] + 16;
          if i < 0 then
              i := 0;
          Dst[1][y * stride + x] := Clip(i shr 5);
          // vert + horiz
          i := t[-2] - 5 * t[-1] + 20 * t[0] + 20 * t[1] - 5 * t[2] + t[3] + 512;
          if i < 0 then
              i := 0;
          Dst[2][y * stride + x] := Clip(i shr 10);
        end;

      for i := -2 to 3 do
          inc(Row[i], stride);
    end;
end;
{$IFEND}


end.
