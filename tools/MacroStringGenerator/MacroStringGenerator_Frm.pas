unit MacroStringGenerator_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask,

  ZR.AES, ZR.BulletMovementEngine,
  ZR.Cadencer, ZR.Cipher, ZR.Compress, ZR.Core, ZR.Delphi.JsonDataObjects, ZR.DFE,
  ZR.Expression, ZR.FPC.GenericList, ZR.Geometry.Low, ZR.Geometry.Rotation,
  ZR.Geometry2D, ZR.Geometry3D, ZR.HashList.Templet, ZR.IOThread, ZR.Json,
  ZR.Line2D.Templet, ZR.LinearAction, ZR.ListEngine, ZR.Matched.Templet, ZR.MD5,
  ZR.MediaCenter, ZR.MemoryStream, ZR.MH, ZR.MH_ZDB, ZR.MH1, ZR.MH2, ZR.MH3,
  ZR.MovementEngine, ZR.Notify, ZR.Number, ZR.OpCode, ZR.Parsing,
  ZR.PascalStrings, ZR.Status, ZR.TextDataEngine, ZR.TextTable,
  ZR.UnicodeMixedLib, ZR.UPascalStrings, ZR.UReplace, ZR.FastGBK;

type
  TMacroStringGenerator_Form = class(TForm)
    fpsTimer: TTimer;
    templet_info_Label: TLabel;
    templet_Memo: TMemo;
    excel_source_info_Label: TLabel;
    excel_source_Memo: TMemo;
    output_info_Label: TLabel;
    output_Memo: TMemo;
    Build_Button: TButton;
    procedure Build_ButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
  private
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MacroStringGenerator_Form: TMacroStringGenerator_Form;

implementation

{$R *.dfm}


procedure TMacroStringGenerator_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

constructor TMacroStringGenerator_Form.Create(AOwner: TComponent);
var
  i: Integer;
begin
  inherited Create(AOwner);
  output_Memo.Lines.WriteBOM := False;
  excel_source_Memo.Lines.Clear;
  for i := 1 to 100 do
      excel_source_Memo.Lines.Add(PFormat('s%d,s%d,s%d,s%d', [i, i, i, i]));
end;

destructor TMacroStringGenerator_Form.Destroy;
begin
  inherited Destroy;
end;

procedure TMacroStringGenerator_Form.Build_ButtonClick(Sender: TObject);
var
  i, j: Integer;
  n, tmp: U_String;
  h: THashStringList;
  Templet: U_String;
begin
  // step 3, build header
  output_Memo.Lines.BeginUpdate;
  output_Memo.Lines.Clear;

  Templet := templet_Memo.Lines.Text;
  Templet := Templet.TrimChar(#13#10#9#32);

  // step 4, extract excel data
  h := THashStringList.Create;
  for i := 0 to excel_source_Memo.Lines.Count - 1 do
    begin
      n := umlTrimSpace(excel_source_Memo.Lines[i]);
      if n = '' then
          continue;
      h['<s1>'] := '';
      h['<s2>'] := '';
      h['<s3>'] := '';
      h['<s4>'] := '';
      h.SetDefaultText('<Line>', n);
      h.SetDefaultText_I32('<LineNo>', i);

      tmp := umlGetFirstStr(n, #9',;');
      n := umlDeleteFirstStr(n, #9',;');
      if tmp <> '' then
          h['<s1>'] := tmp;

      tmp := umlGetFirstStr(n, #9',;');
      n := umlDeleteFirstStr(n, #9',;');
      if tmp <> '' then
          h['<s2>'] := tmp;

      tmp := umlGetFirstStr(n, #9',;');
      n := umlDeleteFirstStr(n, #9',;');
      if tmp <> '' then
          h['<s3>'] := tmp;

      tmp := umlGetFirstStr(n, #9',;');
      n := umlDeleteFirstStr(n, #9',;');
      if tmp <> '' then
          h['<s4>'] := tmp;

      output_Memo.Lines.Add(h.Replace(Templet, False, true, 0, 0));
    end;

  output_Memo.Lines.EndUpdate;
  DisposeObjectAndNil(h);
end;

end.
