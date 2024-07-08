program FMX_FONTConsoleBuild;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  FastMM5,
  SysUtils, Windows,

  ZR.Core, ZR.ListEngine,
  ZR.MemoryStream, ZR.MemoryRaster, ZR.Geometry2D, ZR.Status, ZR.PascalStrings, ZR.UPascalStrings,
  ZR.FastGBK,
  ZR.UnicodeMixedLib, ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.DrawEngine.FMXCharacterMapBuilder;

function GenerateArrayBuff(const ASCII_, GBK_, FULL_: Boolean): TUArrayChar;
var
  c: USystemChar;
  i, j: Integer;
begin
  SetLength(Result, TFontZR.C_MAXWORD + 1);
  j := 0;
  for i := 0 to TFontZR.C_MAXWORD do
    begin
      c := USystemChar(i);
      if IfGBKChar(c, ASCII_, GBK_, FULL_) then
        begin
          Result[j] := c;
          inc(j);
        end;
    end;
  SetLength(Result, j);
end;

procedure Make(const fontName_: U_String; const font_size_: Integer; const SavePath_: U_String; const AA_, BOLD_, ASCII_, GBK_, FULL_: Boolean);
var
  fr: TFontZR;
  n: U_String;
begin
  if not(ASCII_ or GBK_ or FULL_) then
    begin
      DoStatus('"%s" need ASCII or GBK or FULL', [fontName_.Text]);
      exit;
    end;
  DoStatus('build "%s" size=%d AA=%s BOLD=%s ASCII=%s GBK=%s FULL=%s', [
      fontName_.Text,
      font_size_,
      umlBoolToStr(AA_).Text,
      umlBoolToStr(BOLD_).Text,
      umlBoolToStr(ASCII_).Text,
      umlBoolToStr(GBK_).Text,
      umlBoolToStr(FULL_).Text
      ]);
  DoStatus('');

  n := PFormat('%s_%s%d%s%s%s.zFont',
    [fontName_.ReplaceChar(#32, '_').Text, if_(BOLD_, '(BOLD)', ''), font_size_, if_(ASCII_, '(ASCII)', ''), if_(GBK_, '(GBK)', ''), if_(FULL_, '(FULL)', '')]);

  if umlFileExists(umlCombineFileName(SavePath_, n)) then
      exit;
  fr := BuildFMXCharacterAsFontRaster(AA_, fontName_,
    font_size_, BOLD_, false, GenerateArrayBuff(ASCII_, GBK_, FULL_));
  fr.Build(fontName_ + if_(AA_, ' (AA)', '') + if_(BOLD_, '(BOLD)', ''), font_size_, true);
  fr.ClearFragZR();
  fr.SaveToFile(umlCombineFileName(SavePath_, n));
  disposeObject(fr);
  DoStatus('build %s done', [n.Text]);
  DoStatus('');
  TCompute.Sleep(1000);
end;

procedure FillParam();
var
  fontName_: U_String;
  font_size_: Integer;
  SavePath_: U_String;
  AA_, BOLD_, ASCII_, GBK_, FULL_: Boolean;
  ErrCode: Integer;
begin
  ExitCode := 1;
  if ParamCount <> 8 then
      exit;

  try
    fontName_ := ParamStr(1);
    font_size_ := umlStrToInt(ParamStr(2), 36);
    SavePath_ := ParamStr(3);
    AA_ := umlStrToBool(ParamStr(4));
    BOLD_ := umlStrToBool(ParamStr(5));
    ASCII_ := umlStrToBool(ParamStr(6));
    GBK_ := umlStrToBool(ParamStr(7));
    FULL_ := umlStrToBool(ParamStr(8));
  except
      exit;
  end;

  try
    Make(fontName_, font_size_, SavePath_, AA_, BOLD_, ASCII_, GBK_, FULL_);
    ExitCode := 0;
  except
  end;
end;

begin
  FillParam;

end.
