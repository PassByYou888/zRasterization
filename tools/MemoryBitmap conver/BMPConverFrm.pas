unit BMPConverFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Edit,
  FMX.StdCtrls, FMX.Layouts, FMX.TabControl, FMX.Controls.Presentation,
  FMX.Objects, FMX.Colors, FMX.Ani, FMX.ListBox, FMX.ExtCtrls,

  ZR.Core, ZR.Status, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib,
  ZR.MemoryRaster, ZR.DrawEngine,
  ZR.Geometry2D,
  ZR.DrawEngine.SlowFMX, ZR.DrawEngine.PictureViewer;

type
  TBMPConverForm = class(TForm)
    converbmp32Button: TButton;
    outputDirLayout: TLayout;
    DestDirEdit: TEdit;
    Label1: TLabel;
    seldirEditButton: TEditButton;
    AddFileButton: TButton;
    ClearButton: TButton;
    OpenDialog: TOpenDialog;
    ListBox: TListBox;
    converseqButton: TButton;
    converjlsButton: TButton;
    RadioButton_JLS8: TRadioButton;
    RadioButton_JLS24: TRadioButton;
    converyv12Button: TButton;
    converbmp24Button: TButton;
    SameDirCheckBox: TCheckBox;
    converHalfYUVButton: TButton;
    converQuartYUVButton: TButton;
    converJpegButton: TButton;
    RadioButton_Jpeg_YCbCrA: TRadioButton;
    RadioButton_Jpeg_YCbCr: TRadioButton;
    RadioButton_Jpeg_Gray: TRadioButton;
    qualilyLayout: TLayout;
    Label2: TLabel;
    JpegQualilyEdit: TEdit;
    RadioButton_Jpeg_GrayA: TRadioButton;
    RadioButton_Jpeg_CMYK: TRadioButton;
    fpsTimer: TTimer;
    pb: TPaintBox;
    converPNGButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure fpsTimerTimer(Sender: TObject);
    procedure AddFileButtonClick(Sender: TObject);
    procedure ClearButtonClick(Sender: TObject);
    procedure converbmp24ButtonClick(Sender: TObject);
    procedure converbmp32ButtonClick(Sender: TObject);
    procedure converHalfYUVButtonClick(Sender: TObject);
    procedure seldirEditButtonClick(Sender: TObject);
    procedure converseqButtonClick(Sender: TObject);
    procedure converjlsButtonClick(Sender: TObject);
    procedure converJpegButtonClick(Sender: TObject);
    procedure converPNGButtonClick(Sender: TObject);
    procedure converQuartYUVButtonClick(Sender: TObject);
    procedure converyv12ButtonClick(Sender: TObject);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    procedure ItemClick(Sender: TObject);
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    Viewer: TPictureViewerInterface;
  end;

var
  BMPConverForm: TBMPConverForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure TBMPConverForm.FormCreate(Sender: TObject);
begin
  DestDirEdit.Text := umlCurrentPath;
  dIntf := TDrawEngineInterface_FMX.Create;
  Viewer := TPictureViewerInterface.Create(DrawPool(pb));
  Viewer.ShowHistogramInfo := False;
  Viewer.ShowPixelInfo := True;
  AddDoStatusHook(Self, DoStatusMethod);
end;

procedure TBMPConverForm.fpsTimerTimer(Sender: TObject);
begin
  EnginePool.Progress(Interval2Delta(fpsTimer.Interval));
  Invalidate;
end;

procedure TBMPConverForm.ItemClick(Sender: TObject);
var
  r: TMZR;
begin
  r := NewZRFromFile(TListBoxItem(Sender).TagString);
  r.BlendBlack;
  Viewer.Clear;
  Viewer.InputPicture(r, True, True);
  Viewer.Fit();
end;

procedure TBMPConverForm.AddFileButtonClick(Sender: TObject);
var
  i: Integer;
  itm: TListBoxItem;
begin
  OpenDialog.Filter := '*.*';
  if not OpenDialog.Execute then
      Exit;
  ListBox.BeginUpdate;
  for i := 0 to OpenDialog.Files.Count - 1 do
    begin
      itm := TListBoxItem.Create(ListBox);
      itm.ItemData.Text := umlGetFileName(OpenDialog.Files[i]);
      itm.ItemData.detail := umlGetFilePath(OpenDialog.Files[i]);
      itm.TagString := OpenDialog.Files[i];
      itm.StyleLookup := 'listboxitemrightdetail';
      itm.height := 35;
      itm.Selectable := False;
      itm.OnClick := ItemClick;
      ListBox.AddObject(itm);
    end;
  ListBox.EndUpdate;
end;

procedure TBMPConverForm.ClearButtonClick(Sender: TObject);
begin
  ListBox.Clear;
end;

procedure TBMPConverForm.converbmp24ButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.bmp')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.bmp');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.SaveToBmp24File(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converbmp32ButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.bmp')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.bmp');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.BlendBlack;
      b.SaveToBmp32File(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converHalfYUVButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.hyuv')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.hyuv');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.SaveToHalfYUVFile(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.seldirEditButtonClick(Sender: TObject);
var
  v: string;
begin
  v := DestDirEdit.Text;
  if SelectDirectory('output directory', '', v) then
      DestDirEdit.Text := v;
end;

procedure TBMPConverForm.converseqButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.seq')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.seq');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TSequenceMemoryZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TSequenceMemoryZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.BlendBlack;
      b.SaveToFile(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converjlsButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.jls')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.jls');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TSequenceMemoryZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TSequenceMemoryZR.Create;
      LoadMemoryBitmap(itm.TagString, b);

      if RadioButton_JLS8.IsChecked then
          b.SaveToJpegLS1File(GetDestFile(F))
      else if RadioButton_JLS24.IsChecked then
          b.SaveToJpegLS3File(GetDestFile(F))
      else
          RaiseInfo('error.');

      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converJpegButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.jpg')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.jpg');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.BlendBlack;

      if RadioButton_Jpeg_YCbCrA.IsChecked then
          b.SaveToJpegYCbCrAFile(GetDestFile(F), umlStrToInt(JpegQualilyEdit.Text, 90))
      else if RadioButton_Jpeg_YCbCr.IsChecked then
          b.SaveToJpegYCbCrFile(GetDestFile(F), umlStrToInt(JpegQualilyEdit.Text, 90))
      else if RadioButton_Jpeg_GrayA.IsChecked then
          b.SaveToJpegGrayAFile(GetDestFile(F), umlStrToInt(JpegQualilyEdit.Text, 90))
      else if RadioButton_Jpeg_Gray.IsChecked then
          b.SaveToJpegGrayFile(GetDestFile(F), umlStrToInt(JpegQualilyEdit.Text, 90))
      else if RadioButton_Jpeg_CMYK.IsChecked then
          b.SaveToJpegCMYKFile(GetDestFile(F), umlStrToInt(JpegQualilyEdit.Text, 90));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converPNGButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.png')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.png');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.BlendBlack;
      b.SaveToPNGFile(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converQuartYUVButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.qyuv')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.qyuv');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.SaveToQuartYUVFile(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.converyv12ButtonClick(Sender: TObject);
  function GetDestFile(sour: string): string;
  var
    F: string;
  begin
    if SameDirCheckBox.IsChecked then
        Result := umlChangeFileExt(sour, '.yv12')
    else
      begin
        F := umlGetFileName(sour);
        Result := umlChangeFileExt(umlCombineFileName(DestDirEdit.Text, F), '.yv12');
      end;
  end;

var
  i: Integer;
  itm: TListBoxItem;
  F: string;
  b: TMZR;
begin
  if ListBox.Count <= 0 then
      Exit;

  for i := 0 to ListBox.Count - 1 do
    begin
      itm := ListBox.ListItems[i];
      F := itm.TagString;

      b := TMZR.Create;
      LoadMemoryBitmap(itm.TagString, b);
      b.SaveToYV12File(GetDestFile(F));
      DoStatus('%s -> %s ok!', [umlGetFileName(itm.TagString).Text, umlGetFileName(GetDestFile(F)).Text]);
      disposeObject(b);
      Application.ProcessMessages;
    end;
  DoStatus('all conver done!', []);
end;

procedure TBMPConverForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  DrawPool(pb).PostScrollText(5, AText, 12, DEColor(1, 1, 1, 1));
end;

procedure TBMPConverForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapDown(vec2(X, Y));
end;

procedure TBMPConverForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapMove(vec2(X, Y));
end;

procedure TBMPConverForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  Viewer.TapUp(vec2(X, Y));
end;

procedure TBMPConverForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      Viewer.ScaleCamera(1.1)
  else
      Viewer.ScaleCamera(0.9);
end;

procedure TBMPConverForm.pbPaint(Sender: TObject; Canvas: TCanvas);
begin
  dIntf.SetSurface(Canvas, Sender);
  Viewer.DrawEng := DrawPool(Sender, dIntf);
  Viewer.Render;
end;

end.
