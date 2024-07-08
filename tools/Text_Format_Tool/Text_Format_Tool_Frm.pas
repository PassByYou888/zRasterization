unit Text_Format_Tool_Frm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,

  ZR.AES, ZR.BulletMovementEngine,
  ZR.Cadencer, ZR.Cipher, ZR.Compress, ZR.Core, ZR.Delphi.JsonDataObjects, ZR.DFE,
  ZR.Expression, ZR.FPC.GenericList, ZR.Geometry.Low, ZR.Geometry.Rotation,
  ZR.Geometry2D, ZR.Geometry3D, ZR.HashList.Templet, ZR.IOThread, ZR.Json,
  ZR.Line2D.Templet, ZR.LinearAction, ZR.ListEngine, ZR.Matched.Templet, ZR.MD5,
  ZR.MediaCenter, ZR.MemoryStream, ZR.MH, ZR.MH_ZDB, ZR.MH1, ZR.MH2, ZR.MH3,
  ZR.MovementEngine, ZR.Notify, ZR.Number, ZR.OpCode, ZR.Parsing,
  ZR.PascalStrings, ZR.Status, ZR.TextDataEngine, ZR.TextTable,
  ZR.UnicodeMixedLib, ZR.UPascalStrings, ZR.UReplace;

type
  TText_Format_Tool_Form = class(TForm)
    Memo: TMemo;
    FM_INI_Button: TButton;
    fpsTimer: TTimer;
    FM_Json_Button: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FM_INI_ButtonClick(Sender: TObject);
    procedure FM_Json_ButtonClick(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
  private
  public
  end;

var
  Text_Format_Tool_Form: TText_Format_Tool_Form;

implementation

{$R *.dfm}


procedure TText_Format_Tool_Form.FormCreate(Sender: TObject);
begin
  Memo.Lines.WriteBOM := False;
end;

procedure TText_Format_Tool_Form.FM_INI_ButtonClick(Sender: TObject);
var
  te: THashTextEngine;
begin
  Memo.Lines.BeginUpdate;
  try
    te := THashTextEngine.Create;
    te.DataImport(Memo.Lines);
    te.Rebuild;
    Memo.Lines.Clear;
    te.DataExport(Memo.Lines);
    disposeObject(te);
  except
  end;
  Memo.Lines.EndUpdate;
end;

procedure TText_Format_Tool_Form.FM_Json_ButtonClick(Sender: TObject);
var
  j: TZ_JsonObject;
begin
  Memo.Lines.BeginUpdate;
  try
    j := TZ_JsonObject.Create;
    j.LoadFromLines(Memo.Lines);
    Memo.Lines.Clear;
    j.SaveToLines(Memo.Lines);
    disposeObject(j);
  except
  end;
  Memo.Lines.EndUpdate;
end;

procedure TText_Format_Tool_Form.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
end;

end.
