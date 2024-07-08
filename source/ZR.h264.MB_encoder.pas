{ ****************************************************************************** }
{ * h264 encoder                                                               * }
{ ****************************************************************************** }
unit ZR.h264.MB_encoder;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses
  ZR.h264.Types, ZR.h264.Common, ZR.h264.Util, ZR.h264.Macroblock, ZR.h264.Frame, ZR.h264.Stats,
  ZR.h264.Intra_pred, ZR.h264.inter_pred, ZR.h264.Motion_comp, ZR.h264.Motion_est, ZR.h264.Loopfilter, ZR.h264.stream, ZR.Core;

type
  TMacroblockEncoder = class(TCore_Object_Intermediate)
  private
    mb: TMacroblock;
    Frame: TFrame;
    Stats: TFrameStats;
    intrapred: TIntraPredictor;

    procedure InitMB(mbx, mby: int32_t);
    procedure FinalizeMB;
    procedure EncodeCurrentType;
    procedure Decode;
    procedure SetChromaQPOffset(const AValue: int8_t);
    procedure Store;
    function TrySkip(const use_satd: Boolean): Boolean;
    function TryPostInterEncodeSkip(const score_inter: int32_t): Boolean;
    procedure MakeSkip;
    function GetChromaMcSSD: int32_t;

  public
    mc: TMotionCompensation;
    me: TMotionEstimator;
    h264s: TH264Stream;
    chroma_coding: Boolean;
    num_ref_frames: int32_t;
    Loopfilter: Boolean;
    property ChromaQPOffset: int8_t write SetChromaQPOffset;

    constructor Create; virtual;
    destructor Destroy; override;
    procedure SetFrame(const f: TFrame); virtual;
    procedure Encode(mbx, mby: int32_t); virtual; abstract;
  end;

  TMBEncoderNoAnalyse = class(TMacroblockEncoder)
    constructor Create; override;
    procedure Encode(mbx, mby: int32_t); override;
  end;

  TMBEncoderQuickAnalyse = class(TMacroblockEncoder)
  public
    procedure Encode(mbx, mby: int32_t); override;
  end;

  TMBEncoderQuickAnalyseSATD = class(TMBEncoderQuickAnalyse)
  private
    InterCost: IInterPredCostEvaluator;
  public
    constructor Create; override;
    procedure SetFrame(const f: TFrame); override;
    procedure Encode(mbx, mby: int32_t); override;
  end;

  TMBEncoderRateAnalyse = class(TMacroblockEncoder)
  private
    mb_cache: array [0 .. 2] of TMacroblock; // todo init in constructor
    mb_type_bitcost: array [MB_I_4x4 .. MB_P_SKIP] of int32_t;
    procedure CacheStore;
    procedure CacheLoad;
    procedure EncodeInter;
    procedure EncodeIntra;
    function MBCost: int32_t;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Encode(mbx, mby: int32_t); override;
  end;

implementation

const
  MIN_I_4x4_BITCOST = 27;

procedure TMacroblockEncoder.InitMB(mbx, mby: int32_t);
begin
  mb.x := mbx;
  mb.y := mby;
  if mbx = 0 then
      mb_init_row_ptrs(mb, Frame, mby);

  // load pixels
  DSP.pixel_load_16x16(mb.pixels, mb.pfenc, Frame.stride);
  DSP.pixel_load_8x8(mb.pixels_c[0], mb.pfenc_c[0], Frame.stride_c);
  DSP.pixel_load_8x8(mb.pixels_c[1], mb.pfenc_c[1], Frame.stride_c);

  mb_init(mb, Frame, False);
  mb.residual_bits := 0;
  mb.fref := Frame.refs[0];
  mb.ref := 0;
end;

// some nz_coef_cnt-s are set in Decode, therefore it must come before CalculateBStrength
procedure TMacroblockEncoder.FinalizeMB;
begin
  h264s.WriteMB(mb);
  Decode;
  if Loopfilter then
    begin
      CalculateBStrength(@mb);
    end;
  Store;
  if not Loopfilter then
    begin
      inc(Stats.ssd[0], DSP.ssd_16x16(mb.pixels_dec, mb.pfenc, Frame.stride));
      inc(Stats.ssd[1], DSP.ssd_8x8(mb.pixels_dec_c[0], mb.pfenc_c[0], Frame.stride_c));
      inc(Stats.ssd[2], DSP.ssd_8x8(mb.pixels_dec_c[1], mb.pfenc_c[1], Frame.stride_c));
    end;

  inc(mb.pfenc, 16);
  inc(mb.pfdec, 16);
  inc(mb.pfenc_c[0], 8);
  inc(mb.pfenc_c[1], 8);
  inc(mb.pfdec_c[0], 8);
  inc(mb.pfdec_c[1], 8);
end;

procedure TMacroblockEncoder.EncodeCurrentType;
begin
  case mb.mbtype of
    // MB_I_PCM, MB_P_SKIP: no coding

    MB_I_4x4:
      begin
        mb.mv := ZERO_MV;
        encode_mb_intra_i4(mb, Frame, intrapred);
        if chroma_coding then
            encode_mb_chroma(mb, intrapred, True);
      end;

    MB_I_16x16:
      begin
        mb.mv := ZERO_MV;
        intrapred.Predict_16x16(mb.i16_pred_mode, mb.x, mb.y);
        encode_mb_intra_i16(mb);
        if chroma_coding then
            encode_mb_chroma(mb, intrapred, True);
      end;

    MB_P_16x16:
      begin
        encode_mb_inter(mb);
        if chroma_coding then
          begin
            mc.CompensateChroma(mb.fref, mb.mv, mb.x, mb.y, mb.mcomp_c[0], mb.mcomp_c[1]);
            encode_mb_chroma(mb, intrapred, False);
          end;
      end;
  end;
end;

procedure TMacroblockEncoder.Decode;
begin
  case mb.mbtype of
    MB_I_PCM: decode_mb_pcm(mb);
    // MB_I_4x4: decoded during encode
    MB_I_16x16: decode_mb_intra_i16(mb, intrapred);
    MB_P_16x16: decode_mb_inter(mb);
    MB_P_SKIP: decode_mb_inter_pskip(mb);
  end;
  if chroma_coding and (mb.mbtype <> MB_I_PCM) then
      decode_mb_chroma(mb, mb.mbtype in [MB_I_4x4, MB_I_16x16]);
end;

procedure TMacroblockEncoder.SetChromaQPOffset(const AValue: int8_t);
begin
  mb.chroma_qp_offset := AValue;
end;

// store MB to frame's MB array, move decoded pixels to frame
procedure TMacroblockEncoder.Store;
var
  i: int32_t;
begin
  i := mb.y * Frame.mbw + mb.x;
  CopyPtr(@mb, @Frame.mbs[i], SizeOf(TMacroblock));

  if mb.mbtype <> MB_I_4x4 then
      DSP.pixel_save_16x16(mb.pixels_dec, mb.pfdec, Frame.stride);

  DSP.pixel_save_8x8(mb.pixels_dec_c[0], mb.pfdec_c[0], Frame.stride_c);
  DSP.pixel_save_8x8(mb.pixels_dec_c[1], mb.pfdec_c[1], Frame.stride_c);

  // stats
  case mb.mbtype of
    MB_I_4x4:
      begin
        inc(Stats.mb_i4_count);
        for i := 0 to 15 do
            inc(Stats.pred[mb.i4_pred_mode[i]]);
        inc(Stats.pred_8x8_chroma[mb.chroma_pred_mode]);
        inc(Stats.itex_bits, mb.residual_bits);
      end;
    MB_I_16x16:
      begin
        inc(Stats.mb_i16_count);
        inc(Stats.pred16[mb.i16_pred_mode]);
        inc(Stats.pred_8x8_chroma[mb.chroma_pred_mode]);
        inc(Stats.itex_bits, mb.residual_bits);
      end;
    MB_P_16x16:
      begin
        inc(Stats.mb_p_count);
        inc(Stats.ref[mb.ref]);
        inc(Stats.ptex_bits, mb.residual_bits);
      end;
    MB_P_SKIP:
      begin
        inc(Stats.mb_skip_count);
        inc(Stats.ref[mb.ref]);
      end;
  end;
end;

const
  MIN_XY = -FRAME_EDGE_W * 4;

  {
    PSkip test, based on SSD treshold. Also stores SATD luma & SSD chroma score
    true = PSkip is acceptable
  }
function TMacroblockEncoder.TrySkip(const use_satd: Boolean): Boolean;
const
  SKIP_SSD_TRESH = 256;
  SKIP_SSD_CHROMA_TRESH = 96;
var
  mv: TMotionvec;
  score, score_c: int32_t;
begin
  Result := False;
  mb.score_skip := MaxInt;
  if h264s.NoPSkipAllowed then
      Exit;

  if (mb.y < Frame.mbh - 1) or (mb.x < Frame.mbw - 1) then
    begin
      mv := mb.mv_skip;

      // can't handle out-of-frame mvp, don't skip
      if mv.x + mb.x * 64 >= Frame.w * 4 - 34 then
          Exit;
      if mv.y + mb.y * 64 >= Frame.h * 4 - 34 then
          Exit;
      if mv.x + mb.x * 64 < MIN_XY then
          Exit;
      if mv.y + mb.y * 64 < MIN_XY then
          Exit;

      mb.mv := mv;
      mc.Compensate(mb.fref, mb.mv, mb.x, mb.y, mb.mcomp);
      score := DSP.ssd_16x16(mb.pixels, mb.mcomp, 16);
      if use_satd then
          mb.score_skip := DSP.satd_16x16(mb.pixels, mb.mcomp, 16)
      else
          mb.score_skip := DSP.sad_16x16(mb.pixels, mb.mcomp, 16);
      score_c := 0;
      if chroma_coding then
        begin
          mc.CompensateChroma(mb.fref, mb.mv, mb.x, mb.y, mb.mcomp_c[0], mb.mcomp_c[1]);
          inc(score_c, GetChromaMcSSD);
        end;
      mb.score_skip_uv := score_c;

      if (score < SKIP_SSD_TRESH) and (score_c < SKIP_SSD_CHROMA_TRESH) then
          Result := True;
    end;
end;

// test if PSkip is suitable: luma SATD & chroma SSD can't be (much) worse than compensated P16x16
// todo: better tune skip bias
function TMacroblockEncoder.TryPostInterEncodeSkip(const score_inter: int32_t): Boolean;
var
  skip_bias: int32_t;
begin
  Result := False;
  skip_bias := mb.qp * 3;
  if score_inter >= mb.score_skip - skip_bias then
    begin
      if chroma_coding then
        begin
          skip_bias := mb.qp;
          if GetChromaMcSSD >= mb.score_skip_uv - skip_bias then
              Result := True;
        end
      else
          Result := True;
    end;
end;

// test if mb can be changed to skip
procedure TMacroblockEncoder.MakeSkip;
var
  mv: TMotionvec;
begin
  if h264s.NoPSkipAllowed then
      Exit;
  mv := mb.mv_skip;

  // can't handle out-of-frame mvp, don't skip
  if mv.x + mb.x * 64 >= Frame.w * 4 - 34 then
      Exit;
  if mv.y + mb.y * 64 >= Frame.h * 4 - 34 then
      Exit;
  if mv.x + mb.x * 64 < MIN_XY then
      Exit;
  if mv.y + mb.y * 64 < MIN_XY then
      Exit;

  if (mb.cbp = 0) and ((mb.y < Frame.mbh - 1) or (mb.x < Frame.mbw - 1)) then
    begin
      // restore skip ref/mv
      if (mb.ref <> 0) or (mb.mbtype <> MB_P_16x16) then
        begin
          mb.fref := Frame.refs[0];
          mb.ref := 0;
          mb_load_mvs(mb, Frame, num_ref_frames);
        end;
      mb.mbtype := MB_P_SKIP;
      mb.mv := mb.mv_skip;
      mc.Compensate(mb.fref, mb.mv, mb.x, mb.y, mb.mcomp);
      if chroma_coding then
          mc.CompensateChroma(mb.fref, mb.mv, mb.x, mb.y, mb.mcomp_c[0], mb.mcomp_c[1]);
    end;
end;

function TMacroblockEncoder.GetChromaMcSSD: int32_t;
begin
  Result := DSP.ssd_8x8(mb.pixels_c[0], mb.mcomp_c[0], 16) + DSP.ssd_8x8(mb.pixels_c[1], mb.mcomp_c[1], 16);
end;

constructor TMacroblockEncoder.Create;
begin
  inherited Create;

  mb_alloc(mb);
  mb.chroma_qp_offset := 0;
  intrapred := TIntraPredictor.Create;
  with intrapred do
    begin
      pixels := mb.pixels;
      prediction := mb.pred;
      pixels_c[0] := mb.pixels_c[0];
      pixels_c[1] := mb.pixels_c[1];
      prediction_c[0] := mb.pred_c[0];
      prediction_c[1] := mb.pred_c[1];
      pixel_cache := @mb.intra_pixel_cache;
    end;
end;

destructor TMacroblockEncoder.Destroy;
begin
  mb_free(mb);
  intrapred.Free;
  inherited Destroy;
end;

procedure TMacroblockEncoder.SetFrame(const f: TFrame);
begin
  Frame := f;
  intrapred.frame_stride := Frame.stride;
  intrapred.stride_c := Frame.stride_c;
  intrapred.mb_width := Frame.mbw;
  Stats := f.Stats;
end;

procedure TMBEncoderRateAnalyse.CacheStore;
begin
  with mb_cache[mb.mbtype] do
    begin
      mv := mb.mv;
      ref := mb.ref;
      fref := mb.fref;
      cbp := mb.cbp;
      chroma_dc := mb.chroma_dc;
      nz_coef_cnt := mb.nz_coef_cnt;
      nz_coef_cnt_dc := mb.nz_coef_cnt_dc;
      nz_coef_cnt_chroma_ac := mb.nz_coef_cnt_chroma_ac;
      Block := mb.Block;
    end;
  CopyPtr(mb.dct[0], mb_cache[mb.mbtype].dct[0], 2 * 16 * 25);
end;

procedure TMBEncoderRateAnalyse.CacheLoad;
begin
  with mb_cache[mb.mbtype] do
    begin
      mb.mv := mv;
      mb.ref := ref;
      mb.fref := fref;
      mb.cbp := cbp;
      mb.chroma_dc := chroma_dc;
      mb.nz_coef_cnt := nz_coef_cnt;
      mb.nz_coef_cnt_dc := nz_coef_cnt_dc;
      mb.nz_coef_cnt_chroma_ac := nz_coef_cnt_chroma_ac;
      mb.Block := Block;
    end;
  CopyPtr(mb_cache[mb.mbtype].dct[0], mb.dct[0], 2 * 16 * 25);
end;

function TMBEncoderRateAnalyse.MBCost: int32_t;
begin
  Result := h264s.GetBitCost(mb);
  mb_type_bitcost[mb.mbtype] := Result;
end;

constructor TMBEncoderRateAnalyse.Create;
var
  i: int32_t;
begin
  inherited Create;
  intrapred.UseSATDCompare;
  for i := 0 to 2 do
      mb_cache[i].dct[0] := fev_malloc(2 * 16 * 25);
end;

destructor TMBEncoderRateAnalyse.Destroy;
var
  i: int32_t;
begin
  inherited Destroy;
  for i := 0 to 2 do
      fev_free(mb_cache[i].dct[0]);
end;

procedure TMBEncoderRateAnalyse.EncodeInter;
var
  score_i, score_p: int32_t;
  bits_i16, bits_intra, bits_inter: int32_t;
begin
  mb.mbtype := MB_P_16x16;
  mb_load_mvs(mb, Frame, num_ref_frames);

  // early PSkip
  if TrySkip(True) then
    begin
      mb.mbtype := MB_P_SKIP;
      mb_type_bitcost[mb.mbtype] := 0;
      Exit;
    end;

  // encode as inter
  me.Estimate(mb, Frame);
  score_p := DSP.satd_16x16(mb.pixels, mb.mcomp, 16);
  EncodeCurrentType;

  // if there were no coeffs left after quant, try if PSkip is suitable; otherwise just exit with P16x16
  if (mb.cbp = 0) and TryPostInterEncodeSkip(score_p) then
    begin
      MakeSkip;
      // makeskip may fail in turning the MB to skip, so technically not correct; but it's used only in analysis
      mb_type_bitcost[mb.mbtype] := 0;
      Exit;
    end;

  bits_inter := MBCost;

  // early termination if surrounding MBs are inter and have similar bitcost
  if (mb.mba <> nil) and (mb.mbb <> nil) and is_inter(mb.mba^.mbtype) and is_inter(mb.mbb^.mbtype)
    and (bits_inter < (mb.mba^.bitcost + mb.mbb^.bitcost) div 3 * 2) then
      Exit;

  // encode as intra if prediction score isn't much worse
  intrapred.Analyse_16x16(mb.x, mb.y, mb.i16_pred_mode, score_i);
  if score_i < score_p * 2 then
    begin
      CacheStore;
      // I16x16
      mb.mbtype := MB_I_16x16;
      EncodeCurrentType;
      bits_i16 := MBCost;
      // try I4x4 if I16x16 wasn't much worse
      if (bits_i16 < bits_inter * 2) and (Min(bits_inter, bits_i16) > MIN_I_4x4_BITCOST) then
        begin
          CacheStore;
          mb.mbtype := MB_I_4x4;
          EncodeCurrentType;
          bits_intra := MBCost;
          // pick better
          if bits_i16 < bits_intra then
            begin
              mb.mbtype := MB_I_16x16;
              CacheLoad;
              bits_intra := bits_i16;
            end;
        end
      else
          bits_intra := bits_i16;

      // inter / intra?
      if bits_inter < bits_intra then
        begin
          mb.mbtype := MB_P_16x16;
          CacheLoad;
        end;
    end;
end;

procedure TMBEncoderRateAnalyse.EncodeIntra;
var
  bits_i16, bits_i4: int32_t;
  score_i: int32_t;
begin
  intrapred.Analyse_16x16(mb.x, mb.y, mb.i16_pred_mode, score_i);
  mb.mbtype := MB_I_16x16;
  EncodeCurrentType;
  CacheStore;
  bits_i16 := MBCost;
  if bits_i16 <= MIN_I_4x4_BITCOST then
      Exit;

  mb.mbtype := MB_I_4x4;
  EncodeCurrentType;
  bits_i4 := MBCost;
  if bits_i16 < bits_i4 then
    begin
      mb.mbtype := MB_I_16x16;
      CacheLoad;
    end;
end;

procedure TMBEncoderRateAnalyse.Encode(mbx, mby: int32_t);
begin
  InitMB(mbx, mby);

  if Frame.ftype = SLICE_P then
      EncodeInter
  else
      EncodeIntra;

  mb.bitcost := mb_type_bitcost[mb.mbtype];
  FinalizeMB;
end;

procedure TMBEncoderQuickAnalyse.Encode(mbx, mby: int32_t);
const
  I16_SAD_QPBONUS = 10;
var
  score_i, score_p: int32_t;
begin
  InitMB(mbx, mby);

  // encode
  if Frame.ftype = SLICE_P then
    begin
      mb.mbtype := MB_P_16x16;
      mb_load_mvs(mb, Frame, num_ref_frames);

      // skip
      if TrySkip(True) then
        begin
          mb.mbtype := MB_P_SKIP;
          FinalizeMB;
          Exit;
        end;

      // inter score
      me.Estimate(mb, Frame);
      score_p := DSP.sad_16x16(mb.pixels, mb.mcomp, 16);

      // intra score
      intrapred.Analyse_16x16(mb.x, mb.y, mb.i16_pred_mode, score_i);
      if score_i < score_p then
        begin
          if score_i < mb.qp * I16_SAD_QPBONUS then
              mb.mbtype := MB_I_16x16
          else
              mb.mbtype := MB_I_4x4;
          mb.ref := 0;
        end;

      // encode mb
      EncodeCurrentType;

      // if there were no coeffs left, try skip
      if is_inter(mb.mbtype) and (mb.cbp = 0) and TryPostInterEncodeSkip(score_p) then
        begin
          MakeSkip;
        end;

    end
  else
    begin
      mb.mbtype := MB_I_4x4;
      EncodeCurrentType;
    end;

  FinalizeMB;
end;

constructor TMBEncoderQuickAnalyseSATD.Create;
begin
  inherited Create;
  intrapred.UseSATDCompare;
end;

procedure TMBEncoderQuickAnalyseSATD.SetFrame(const f: TFrame);
begin
  inherited SetFrame(f);
  InterCost := h264s.GetInterPredCostEvaluator;
end;

procedure TMBEncoderQuickAnalyseSATD.Encode(mbx, mby: int32_t);
const
  I16_SATD_QPBONUS = 50;
  INTRA_MODE_PENALTY = 10;

var
  score_i, score_p: int32_t;

begin
  InitMB(mbx, mby);

  // encode
  if Frame.ftype = SLICE_P then
    begin
      mb.mbtype := MB_P_16x16;
      mb_load_mvs(mb, Frame, num_ref_frames);

      // skip
      if TrySkip(True) then
        begin
          mb.mbtype := MB_P_SKIP;
          FinalizeMB;
          Exit;
        end;

      // inter score
      me.Estimate(mb, Frame);
      score_p := DSP.satd_16x16(mb.pixels, mb.mcomp, 16);
      inc(score_p, InterCost.bitcost(mb.mv - mb.mvp));

      // intra score
      intrapred.Analyse_16x16(mb.x, mb.y, mb.i16_pred_mode, score_i);
      if score_i + INTRA_MODE_PENALTY < score_p then
        begin
          if score_i < mb.qp * I16_SATD_QPBONUS then
              mb.mbtype := MB_I_16x16
          else
              mb.mbtype := MB_I_4x4;
          mb.ref := 0;
        end;

      // encode mb
      EncodeCurrentType;

      // if there were no coeffs left, try skip
      if is_inter(mb.mbtype) and (mb.cbp = 0) and TryPostInterEncodeSkip(score_p) then
        begin
          MakeSkip;
        end;

    end
  else
    begin
      intrapred.Analyse_16x16(mb.x, mb.y, mb.i16_pred_mode, score_i);
      if score_i < mb.qp * I16_SATD_QPBONUS then
          mb.mbtype := MB_I_16x16
      else
          mb.mbtype := MB_I_4x4;
      EncodeCurrentType;
    end;

  FinalizeMB;
end;

constructor TMBEncoderNoAnalyse.Create;
begin
  inherited Create;
end;

procedure TMBEncoderNoAnalyse.Encode(mbx, mby: int32_t);
begin
  InitMB(mbx, mby);

  if Frame.ftype = SLICE_P then
    begin
      mb.mbtype := MB_P_16x16;
      mb_load_mvs(mb, Frame, num_ref_frames);
      // skip
      if TrySkip(False) then
        begin
          mb.mbtype := MB_P_SKIP;
        end
      else
        begin
          me.Estimate(mb, Frame);
          EncodeCurrentType;
        end;
    end
  else
    begin
      mb.mbtype := MB_I_4x4;
      EncodeCurrentType;
    end;

  FinalizeMB;
end;

end.
