unit EncodingConverFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs, Vcl.ExtCtrls,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status;

type
  TEncodingConverForm = class(TForm)
    Memo: TMemo;
    AddFilesButton: TButton;
    Label1: TLabel;
    OpenDialog: TFileOpenDialog;
    EncodeButton: TButton;
    StatusMemo: TMemo;
    sourEncodeComboBox: TComboBox;
    Label2: TLabel;
    DestEncodeComboBox: TComboBox;
    SignedCheckBox: TCheckBox;
    bkTimer: TTimer;
    SafeScanButton: TButton;
    FilterEdit: TLabeledEdit;
    removeButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure AddFilesButtonClick(Sender: TObject);
    procedure bkTimerTimer(Sender: TObject);
    procedure EncodeButtonClick(Sender: TObject);
    procedure removeButtonClick(Sender: TObject);
    procedure SafeScanButtonClick(Sender: TObject);
  private
  public
    procedure EnabledAll;
    procedure DisableAll;
    procedure DoStatusBackCall(Text_: SystemString; const ID: Integer);
    function GetEncoding(fn: U_String; var buff: TBytes): TEncoding;
  end;

var
  EncodingConverForm: TEncodingConverForm;

implementation

{$R *.dfm}


procedure TEncodingConverForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusBackCall);
  with sourEncodeComboBox do
    begin
      ItemIndex := Items.Add('Auto Detected');
      Items.Add(TEncoding.ANSI.EncodingName);
      Items.Add(TEncoding.ASCII.EncodingName);
      Items.Add(TEncoding.BigEndianUnicode.EncodingName);
      Items.Add(TEncoding.Unicode.EncodingName);
      Items.Add(TEncoding.UTF7.EncodingName);
      Items.Add(TEncoding.UTF8.EncodingName);
    end;
  with DestEncodeComboBox do
    begin
      Items.Add(TEncoding.ANSI.EncodingName);
      Items.Add(TEncoding.ASCII.EncodingName);
      Items.Add(TEncoding.BigEndianUnicode.EncodingName);
      Items.Add(TEncoding.Unicode.EncodingName);
      Items.Add(TEncoding.UTF7.EncodingName);
      ItemIndex := Items.Add(TEncoding.UTF8.EncodingName);
    end;
end;

procedure TEncodingConverForm.AddFilesButtonClick(Sender: TObject);
var
  i: Integer;
begin
  if not OpenDialog.Execute then
      exit;
  DisableAll;
  if Memo.Lines.Count > 0 then
    begin
      for i := 0 to OpenDialog.Files.Count - 1 do
        begin
          umlAddNewStrTo(OpenDialog.Files[i], Memo.Lines, True);
          if i mod 10 = 0 then
              Application.HandleMessage;
        end;
    end
  else
      Memo.Lines.Assign(OpenDialog.Files);
  EnabledAll;
end;

procedure TEncodingConverForm.bkTimerTimer(Sender: TObject);
begin
  DoStatus();
end;

procedure TEncodingConverForm.EncodeButtonClick(Sender: TObject);
var
  i: Integer;
  fn: U_String;
  sBuff, dBuff, dPreamble: TBytes;
  sEnc: TEncoding;
  dEnc: TEncoding;
  fs: TFileStream;
  bom: Boolean;
begin
  if MessageDlg('modifying the encoding, content of the file maybe change. are you sure to continue?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      exit;

  DisableAll;
  case DestEncodeComboBox.ItemIndex of
    0: dEnc := TEncoding.ANSI;
    1: dEnc := TEncoding.ASCII;
    2: dEnc := TEncoding.BigEndianUnicode;
    3: dEnc := TEncoding.Unicode;
    4: dEnc := TEncoding.UTF7;
    5: dEnc := TEncoding.UTF8;
    else raiseInfo('error.');
  end;
  dPreamble := dEnc.GetPreamble;
  i := 0;
  while i < Memo.Lines.Count do
    begin
      fn := Memo.Lines[i];
      if umlFileExists(fn) then
        begin
          try
            sEnc := GetEncoding(fn, sBuff);
            dBuff := TEncoding.Convert(sEnc, dEnc, sBuff);
          except
            DoStatus('%s encoding -> %s%s failed!', [umlGetFileName(fn).Text, if_(bom, '(signature)', ''), dEnc.EncodingName]);
            Memo.Lines.Delete(i);
            continue;
          end;
          SetLength(sBuff, 0);
          fs := TFileStream.Create(fn, fmCreate);
          try
            bom := SignedCheckBox.Checked and (Length(dPreamble) > 0);
            if bom then
                fs.WriteBuffer(dPreamble, Length(dPreamble));
            fs.WriteBuffer(dBuff, Length(dBuff));
          finally
              disposeObject(fs);
          end;
          DoStatus('convert %s encoding %s -> %s%s', [umlGetFileName(fn).Text, sEnc.EncodingName, if_(bom, '(signature)', ''), dEnc.EncodingName]);
        end;
      inc(i);
      Application.HandleMessage;
    end;
  EnabledAll;
end;

procedure TEncodingConverForm.SafeScanButtonClick(Sender: TObject);
var
  i: Integer;
  fn: U_String;
  sBuff, dBuff, dPreamble: TBytes;
  sEnc: TEncoding;
  dEnc: TEncoding;
  fs: TFileStream;
  bom: Boolean;
begin
  DisableAll;
  case DestEncodeComboBox.ItemIndex of
    0: dEnc := TEncoding.ANSI;
    1: dEnc := TEncoding.ASCII;
    2: dEnc := TEncoding.BigEndianUnicode;
    3: dEnc := TEncoding.Unicode;
    4: dEnc := TEncoding.UTF7;
    5: dEnc := TEncoding.UTF8;
    else raiseInfo('error.');
  end;
  dPreamble := dEnc.GetPreamble;

  i := 0;
  while i < Memo.Lines.Count do
    begin
      fn := Memo.Lines[i];
      if umlFileExists(fn) then
        begin
          try
            sEnc := GetEncoding(fn, sBuff);
            dBuff := TEncoding.Convert(sEnc, dEnc, sBuff);
            DoStatus('%s encoding %s -> %s%s safe detected passed!', [umlGetFileName(fn).Text, sEnc.EncodingName, if_(bom, '(signature)', ''), dEnc.EncodingName]);
            SetLength(sBuff, 0);
          except
            DoStatus('%s encoding -> %s%s failed!', [umlGetFileName(fn).Text, if_(bom, '(signature)', ''), dEnc.EncodingName]);
            Memo.Lines.Delete(i);
            continue;
          end;
        end;
      inc(i);
      Application.HandleMessage;
    end;
  EnabledAll;
end;

procedure TEncodingConverForm.EnabledAll;
begin
  Memo.Enabled := True;
  AddFilesButton.Enabled := True;
  EncodeButton.Enabled := True;
  StatusMemo.Enabled := True;
  sourEncodeComboBox.Enabled := True;
  DestEncodeComboBox.Enabled := True;
  SignedCheckBox.Enabled := True;
  SafeScanButton.Enabled := True;
end;

procedure TEncodingConverForm.DisableAll;
begin
  Memo.Enabled := False;
  AddFilesButton.Enabled := False;
  EncodeButton.Enabled := False;
  StatusMemo.Enabled := False;
  sourEncodeComboBox.Enabled := False;
  DestEncodeComboBox.Enabled := False;
  SignedCheckBox.Enabled := False;
  SafeScanButton.Enabled := False;
end;

procedure TEncodingConverForm.DoStatusBackCall(Text_: SystemString; const ID: Integer);
begin
  StatusMemo.Lines.Add(Text_);
end;

function TEncodingConverForm.GetEncoding(fn: U_String; var buff: TBytes): TEncoding;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
  SetLength(buff, fs.Size);
  fs.Read(buff[0], fs.Size);
  disposeObject(fs);

  Result := nil;

  case sourEncodeComboBox.ItemIndex of
    0: TEncoding.GetBufferEncoding(buff, Result, TEncoding.Default);
    1: Result := TEncoding.ANSI;
    2: Result := TEncoding.ASCII;
    3: Result := TEncoding.BigEndianUnicode;
    4: Result := TEncoding.Unicode;
    5: Result := TEncoding.UTF7;
    6: Result := TEncoding.UTF8;
    else raiseInfo('error.');
  end;
end;

procedure TEncodingConverForm.removeButtonClick(Sender: TObject);
var
  i: Integer;
begin
  i := 0;
  while i < Memo.Lines.Count do
    begin
      if umlMultipleMatch(True, FilterEdit.Text, Memo.Lines[i]) then
          Memo.Lines.Delete(i)
      else
          inc(i);
    end;
end;

end.
