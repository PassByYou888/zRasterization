unit StringTranslate_FMX_Frm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.StdCtrls,
  ZR.Core, ZR.UnicodeMixedLib, ZR.PascalStrings, ZR.UPascalStrings, ZR.Parsing, ZR.Expression,
  ZR.DrawEngine.SlowFMX;

type
  TStringTranslate_FMX_Form = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Hex2AsciiButton: TButton;
    Ascii2HexButton: TButton;
    Ascii2DeclButton: TButton;
    Ascii2PascalDeclButton: TButton;
    PascalDecl2AsciiButton: TButton;
    Ascii2cButton: TButton;
    c2AsciiButton: TButton;
    Invert_Memo2_Button: TButton;
    Invert_Memo1_Button: TButton;
    procedure Ascii2cButtonClick(Sender: TObject);
    procedure Ascii2DeclButtonClick(Sender: TObject);
    procedure Ascii2HexButtonClick(Sender: TObject);
    procedure Ascii2PascalDeclButtonClick(Sender: TObject);
    procedure c2AsciiButtonClick(Sender: TObject);
    procedure Hex2AsciiButtonClick(Sender: TObject);
    procedure Invert_Memo1_ButtonClick(Sender: TObject);
    procedure Invert_Memo2_ButtonClick(Sender: TObject);
    procedure PascalDecl2AsciiButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  StringTranslate_FMX_Form: TStringTranslate_FMX_Form;

implementation

{$R *.fmx}

uses StyleModuleUnit;


procedure TStringTranslate_FMX_Form.Invert_Memo1_ButtonClick(Sender: TObject);
var
  ns: TStringList;
  i: Integer;
begin
  ns := TStringList.Create;
  for i := Memo1.Lines.Count - 1 downto 0 do
      ns.Add(Memo1.Lines[i]);
  Memo1.Lines.Assign(ns);
  DisposeObject(ns);
end;

procedure TStringTranslate_FMX_Form.Invert_Memo2_ButtonClick(Sender: TObject);
var
  ns: TStringList;
  i: Integer;
begin
  ns := TStringList.Create;
  for i := Memo2.Lines.Count - 1 downto 0 do
      ns.Add(Memo2.Lines[i]);
  Memo2.Lines.Assign(ns);
  DisposeObject(ns);
end;

procedure TStringTranslate_FMX_Form.Hex2AsciiButtonClick(Sender: TObject);
var
  s, n: u_String;
  c: SystemChar;
  output: string;
begin
  s := Memo1.Lines.Text;
  output := '';

  while s <> '' do
    begin
      n := umlGetFirstStr(s, ','#13#10#32#9);
      s := umlDeleteFirstStr(s, ','#13#10#32#9);
      c := SystemChar(umlStrToInt(n, 0));
      output := output + c;
    end;

  Memo2.Lines.Text := output;
end;

procedure TStringTranslate_FMX_Form.Ascii2HexButtonClick(Sender: TObject);
var
  s: u_String;
  c: SystemChar;
  cnt: Integer;
  output: string;
begin
  s := Memo2.Lines.Text;
  output := '';
  cnt := 0;
  for c in s.buff do
    begin
      if cnt > 40 then
        begin
          output := Format('%s,' + #13#10 + '%s', [output, '$' + IntToHex(ord(c), 2)]);
          cnt := 0;
        end
      else
        begin
          if output <> '' then
              output := Format('%s, %s', [output, '$' + IntToHex(ord(c), 2)])
          else
              output := '$' + IntToHex(ord(c), 2);
        end;

      inc(cnt);
    end;

  Memo1.Lines.Text := output;
end;

procedure TStringTranslate_FMX_Form.Ascii2DeclButtonClick(Sender: TObject);
var
  s: u_String;
  c: SystemChar;
  cnt: Integer;
  output: string;
begin
  s := Memo2.Text;
  output := '';
  cnt := 0;
  for c in s.buff do
    begin
      if cnt > 40 then
        begin
          output := Format('%s' + #13#10 + '%s', [output, '#' + IntToStr(ord(c))]);
          cnt := 0;
        end
      else
        begin
          if output <> '' then
              output := output + Format('%s', ['#' + IntToStr(ord(c))])
          else
              output := output + '#' + IntToStr(ord(c));
        end;

      inc(cnt);
    end;

  Memo1.Text := output;
end;

procedure TStringTranslate_FMX_Form.Ascii2PascalDeclButtonClick(Sender: TObject);
var
  i: Integer;
begin
  Memo1.Lines.Clear;
  for i := 0 to Memo2.Lines.Count - 1 do
    begin
      if i = Memo2.Lines.Count - 1 then
          Memo1.Lines.Add(TTextParsing.Translate_Text_To_Pascal_Decl(Memo2.Lines[i] + #13#10) + ';')
      else
          Memo1.Lines.Add(TTextParsing.Translate_Text_To_Pascal_Decl(Memo2.Lines[i] + #13#10) + '+');
    end;
end;

procedure TStringTranslate_FMX_Form.PascalDecl2AsciiButtonClick(Sender: TObject);
begin
  Memo2.Text := EvaluateExpressionValue(tsPascal, Memo1.Text);
end;

procedure TStringTranslate_FMX_Form.Ascii2cButtonClick(Sender: TObject);
var
  i: Integer;
begin
  Memo1.Lines.Clear;
  for i := 0 to Memo2.Lines.Count - 1 do
    begin
      if i = Memo2.Lines.Count - 1 then
          Memo1.Lines.Add(TTextParsing.Translate_Text_To_C_Decl(Memo2.Lines[i] + #13#10) + ';')
      else
          Memo1.Lines.Add(TTextParsing.Translate_Text_To_C_Decl(Memo2.Lines[i] + #13#10) + '+');
    end;
end;

procedure TStringTranslate_FMX_Form.c2AsciiButtonClick(Sender: TObject);
begin
  Memo2.Text := EvaluateExpressionValue(tsC, Memo1.Text);
end;

end.