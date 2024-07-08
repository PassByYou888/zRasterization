unit Chinese_GBK_Tool_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Geometry2D, ZR.Geometry3D,
  ZR.Status, ZR.Notify, ZR.DFE,
  ZR.FastGBK, ZR.GBK, ZR.GBKBig, ZR.GBKMediaCenter, ZR.GBKVec;

type
  TChinese_GBK_Tool_Form = class(TForm)
    Memo: TMemo;
    top_bar_Panel: TPanel;
    Simplified_to_Traditional_Button: TButton;
    threadTimer: TTimer;
    Simplified_to_Hongkong_Traditional_Button: TButton;
    Traditional_to_Simplified_Button: TButton;
    Simplified_to_Taiwan_Traditional_Button: TButton;
    Simplified_to_PinYin_Button: TButton;
    procedure Simplified_to_Traditional_ButtonClick(Sender: TObject);
    procedure Simplified_to_Hongkong_Traditional_ButtonClick(Sender: TObject);
    procedure Traditional_to_Simplified_ButtonClick(Sender: TObject);
    procedure Simplified_to_Taiwan_Traditional_ButtonClick(Sender: TObject);
    procedure Simplified_to_PinYin_ButtonClick(Sender: TObject);
    procedure threadTimerTimer(Sender: TObject);
  private
  public
  end;

var
  Chinese_GBK_Tool_Form: TChinese_GBK_Tool_Form;

implementation

{$R *.dfm}


procedure TChinese_GBK_Tool_Form.Simplified_to_Traditional_ButtonClick(Sender: TObject);
var
  s: TUPascalString;
begin
  s.Text := Memo.Lines.Text;
  Memo.Lines.Text := S2T(s.TrimChar(#13#10)).Text;
end;

procedure TChinese_GBK_Tool_Form.Simplified_to_Hongkong_Traditional_ButtonClick(Sender: TObject);
var
  s: TUPascalString;
begin
  s.Text := Memo.Lines.Text;
  Memo.Lines.Text := S2HK(s.TrimChar(#13#10)).Text;
end;

procedure TChinese_GBK_Tool_Form.Traditional_to_Simplified_ButtonClick(Sender: TObject);
var
  s: TUPascalString;
begin
  s.Text := Memo.Lines.Text;
  Memo.Lines.Text := T2S(s.TrimChar(#13#10)).Text;
end;

procedure TChinese_GBK_Tool_Form.Simplified_to_Taiwan_Traditional_ButtonClick(Sender: TObject);
var
  s: TUPascalString;
begin
  s.Text := Memo.Lines.Text;
  Memo.Lines.Text := S2TW(s.TrimChar(#13#10)).Text;
end;

procedure TChinese_GBK_Tool_Form.Simplified_to_PinYin_ButtonClick(Sender: TObject);
var
  s: TUPascalString;
begin
  s.Text := Memo.Lines.Text;
  Memo.Lines.Text := PyNoSpace(s.TrimChar(#13#10)).Text;
end;

procedure TChinese_GBK_Tool_Form.threadTimerTimer(Sender: TObject);
begin
  Check_Soft_Thread_Synchronize;
end;

end.
