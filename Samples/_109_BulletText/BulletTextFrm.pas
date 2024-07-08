unit BulletTextFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Edit, FMX.Colors, FMX.ListBox, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,

  ZR.Core, ZR.PascalStrings, ZR.UnicodeMixedLib, ZR.Status, ZR.ListEngine,
  ZR.Geometry2D, ZR.Geometry3D,
  ZR.Expression, ZR.OpCode,
  ZR.DrawEngine, ZR.BulletMovementEngine, ZR.MemoryRaster, ZR.MediaCenter, ZR.ZDB.HashItem_LIB,
  ZR.DrawEngine.SlowFMX;

type
  TBulletTextForm = class(TForm)
    fpsTimer: TTimer;
    Layout1: TLayout;
    Label1: TLabel;
    textEdit: TEdit;
    fireTextButton: TEditButton;
    Layout2: TLayout;
    Label2: TLabel;
    sizeEdit: TEdit;
    fontComboColorBox: TComboColorBox;
    curveCheckBox: TCheckBox;
    OverlapShadowCheckBox: TCheckBox;
    debugCheckBox: TCheckBox;
    edgeCheckBox: TCheckBox;
    Layout3: TLayout;
    Label3: TLabel;
    fontComboBox: TComboBox;
    Memo: TMemo;
    edgeComboColorBox: TComboColorBox;
    RandomFireEditButton: TEditButton;
    procedure fireTextButtonClick(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure RandomFireEditButtonClick(Sender: TObject);
    procedure textEditKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
  private
    procedure DoStatus_Backcall(Text_: SystemString; const ID: Integer);
  public
    dIntf: TDrawEngineInterface_FMX;
    bk: TZR;
    arrow: TResourceTexture;
    arrow_ani: TResourceTexture;
    Bullet_Pool: TBullet_Pool;
    fl: TFontZRList;
    dict: TPascalStringList;
    function BuildTextPath(box_: TRectV2): TV2L; overload;
    function BuildTextPath(Text_: U_String; size: TGeoFloat): TV2L; overload;
    function BuildTextCurvePath(box_: TRectV2; Frequency: Integer): TV2L; overload;
    function BuildTextCurvePath(Text_: U_String; size: TGeoFloat; Frequency: Integer): TV2L; overload;
    constructor Create(AOwner: TComponent); override;
  end;

var
  BulletTextForm: TBulletTextForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure TBulletTextForm.fireTextButtonClick(Sender: TObject);
const
  C_Speed = 100;
var
  path: TV2L;
  siz: Integer;
  c, ec: TDEColor;
  fr: TFontZR;
  tmp: TZR;
begin
  siz := EStrToInt(sizeEdit.Text, 16);
  with TAlphaColorF.Create(fontComboColorBox.Color) do
      c := DEColor(R, G, B, A);
  with TAlphaColorF.Create(edgeComboColorBox.Color) do
      ec := DEColor(R, G, B, A);

  if (fontComboBox.ItemIndex >= 0) and (fontComboBox.Items.Objects[fontComboBox.ItemIndex] <> nil) then
    begin
      fr := fontComboBox.Items.Objects[fontComboBox.ItemIndex] as TFontZR;

      if edgeCheckBox.IsChecked then
          tmp := fr.BuildEffectText_Edge(textEdit.Text, Vec2(0.5, 0.5), 0, 1.0, fr.FontSize, DColor2RColor(c), DColor2RColor(ec))
      else
          tmp := fr.BuildEffectText(1, textEdit.Text, Vec2(0.5, 0.5), 0, 1.0, fr.FontSize, DColor2RColor(c));

      if curveCheckBox.IsChecked then
          path := BuildTextCurvePath(tmp.BoundsRectV2, 5)
      else
          path := BuildTextPath(tmp.BoundsRectV2);

      if OverlapShadowCheckBox.IsChecked then
          Bullet_Pool.Add(TBullet_Picture_OverlapShadow.Create(batFMX, tmp, tmp.BoundsRectV2, Vec2Mul(tmp.Size2D, siz / fr.FontSize), 1.0, True, path.first^, 0, C_Speed, 360, path))
      else
          Bullet_Pool.Add(TBullet_Picture.Create(batFMX, tmp, tmp.BoundsRectV2, Vec2Mul(tmp.Size2D, siz / fr.FontSize), 1.0, True, path.first^, 0, C_Speed, 360, path));

      path.Free;

      Bullet_Pool.Last^.Data.AutoFreeObjects.Add(tmp);
    end
  else
    begin
      if curveCheckBox.IsChecked then
          path := BuildTextCurvePath(textEdit.Text, siz, 5)
      else
          path := BuildTextPath(textEdit.Text, siz);

      if OverlapShadowCheckBox.IsChecked then
          Bullet_Pool.Add(TBullet_Text_OverlapShadow.Create(batFMX, textEdit.Text, siz, c, path.first^, 0, C_Speed, 360, path))
      else
          Bullet_Pool.Add(TBullet_Text.Create(batFMX, textEdit.Text, siz, c, path.first^, 0, C_Speed, 360, path));
      path.Free;
    end;
end;

procedure TBulletTextForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [];
  d.DrawTile(bk);
  if debugCheckBox.IsChecked then
      Bullet_Pool.DebugRender(d, False, DEColor(1, 0, 0))
  else
      Bullet_Pool.Render(d, False);

  d.BeginCaptureShadow(Vec2(2, 2), 1.0);
  d.DrawText(
    TDrawEngine.RebuildNumColor(d.LastDrawInfo + #13#10 + PFormat('��Ļ: %d', [Bullet_Pool.Count]), '|color(1,0.5,0.5)|', '||'),
    16, DEColor(1, 1, 1), Vec2(3, 3));
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TBulletTextForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Bullet_Pool.Progress(DrawPool.LastDeltaTime);
  Invalidate;
end;

procedure TBulletTextForm.RandomFireEditButtonClick(Sender: TObject);
begin
  RandomFireEditButton.Enabled := False;
  TCompute.RunP_NP(procedure
    var
      i: Integer;
    begin
      for i := 1 to 200 do
        begin
          TCompute.Sync(procedure
            begin
              MT19937Randomize;
              fontComboColorBox.Color := TAlphaColorF.Create(umlRandomRangeS(0.1, 1), umlRandomRangeS(0.1, 1), umlRandomRangeS(0.1, 1), 1.0).ToAlphaColor;
              edgeComboColorBox.Color := TAlphaColorF.Create(umlRandomRangeS(0.1, 1), umlRandomRangeS(0.1, 1), umlRandomRangeS(0.1, 1), 1.0).ToAlphaColor;
              sizeEdit.Text := IntToStr(umlRandomRange(20, 36));
              curveCheckBox.IsChecked := umlRandomRange(0, 100) mod 2 = 0;
              OverlapShadowCheckBox.IsChecked := umlRandomRange(0, 100) mod 2 = 0;
              edgeCheckBox.IsChecked := umlRandomRange(0, 100) mod 2 = 0;
              fontComboBox.ItemIndex := umlRandomRange(0, fontComboBox.Items.Count - 1);
              textEdit.Text := dict[umlRandomRange(0, dict.Count - 1)];
              fireTextButtonClick(fireTextButton);
            end);

          TCompute.Sleep(100);
        end;
      TCompute.Sync(procedure
        begin
          RandomFireEditButton.Enabled := True;
        end);
    end);
end;

procedure TBulletTextForm.textEditKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = VKRETURN then
    begin
      fireTextButtonClick(fireTextButton);
    end;
end;

procedure TBulletTextForm.DoStatus_Backcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
  Memo.GoToTextEnd;
end;

function TBulletTextForm.BuildTextPath(box_: TRectV2): TV2L;
var
  siz: TVec2;
  box: TRectV2;
  x, y: TGeoFloat;
  num: Integer;
begin
  siz := RectSize(box_);
  x := DrawPool(Self).width + 1;
  num := 0;
  repeat
    // �ظ�����,������Ļ�������,��ʼ�����Ŷ�
    inc(num);
    if num > 100 then
      begin
        x := x + siz[0] * 0.5;
        num := 0;
      end;
    y := umlRandomRangeS(0, DrawPool(Self).height - siz[1]);
  until not Bullet_Pool.RenderBoxIsOverlap(RectV2(x, y, x + siz[0], y + siz[1]), RectV2(-100, 0, width, height));
  box := RectV2(x, y, x + siz[0], y + siz[1]);
  Result := TV2L.Create;
  Result.Add(RectCentre(box));
  Result.Add(-siz[0] * 0.5, y);
end;

function TBulletTextForm.BuildTextPath(Text_: U_String; size: TGeoFloat): TV2L;
begin
  Result := BuildTextPath(RectV2(Vec2(0, 0), DrawPool(Self).GetTextSize(Text_, size)));
end;

function TBulletTextForm.BuildTextCurvePath(box_: TRectV2; Frequency: Integer): TV2L;
var
  L: TVec2;
  i: Integer;
  Vibrate: TGeoFloat;
begin
  Result := BuildTextPath(box_);
  L := Result.Last^;
  Result.Delete(1);
  Result.AddSubdivision(Frequency, L);
  Vibrate := 10;
  for i := 1 to Result.Count - 2 do
    begin
      Result[i]^[1] := Result[i]^[1] + Vibrate;
      Vibrate := -Vibrate;
    end;
  Result.SplineSmoothOpened;
end;

function TBulletTextForm.BuildTextCurvePath(Text_: U_String; size: TGeoFloat; Frequency: Integer): TV2L;
var
  L: TVec2;
  i: Integer;
  Vibrate: TGeoFloat;
begin
  Result := BuildTextPath(Text_, size);
  L := Result.Last^;
  Result.Delete(1);
  Result.AddSubdivision(Frequency, L);
  Vibrate := 10;
  for i := 1 to Result.Count - 2 do
    begin
      Result[i]^[1] := Result[i]^[1] + Vibrate;
      Vibrate := -Vibrate;
    end;
  Result.SplineSmoothOpened;
end;

constructor TBulletTextForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // ��Ⱦ�����Ŀ��
  dIntf := TDrawEngineInterface_FMX.Create;
  // ��������
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 64);

  Draw_Engine_Auto_Hook_Check_Thread := False;

  // �˶���������
  Bullet_Pool := TBullet_Pool.Create;

  // �ӿ�DoStatus
  AddDoStatusHook(Self, DoStatus_Backcall);

  // ����ʱ�����ں�̨����
  fontComboBox.Enabled := False;
  fontComboBox.Items.Clear;
  fontComboBox.Items.AddObject('ϵͳ����', nil);
  RandomFireEditButton.Enabled := False;
  TCompute.RunP_NP(procedure
    var
      i: Integer;
      fr: TFontZR;
      L: TCore_List;
      stream: TCore_Stream;
    begin
      // Z.MediaCenter.pas��ӵ�д��ģ������ʱ��Դ�ļ���������
      // һ�����,app��exe����ʹ���ⲿ��Դ�ļ�,��Щ��Դ�ļ����ᱻ���ɵ�app��exe�ڲ�
      // gmtArt��ʾ�����
      // gmtFonts��ʾ�����
      InitGlobalMedia([gmtArt, gmtFonts, gmtDict]);
      // TResourceTexture�ṩ��fileIO��������
      arrow := TResourceTexture.Create;
      arrow.LoadFromFileIO('arrow_test.bmp');

      arrow_ani := TResourceTexture.Create;
      arrow_ani.LoadFromFileIO('arrow_ani.seq');

      fl := TFontZRList.Create;
      L := TCore_List.Create;
      FontsLibrary.ROOT.GetListFromFilter('*.zFont', L);

      for i := 0 to L.Count - 1 do
        begin
          fr := TFontZR.Create;
          fr.LoadFromStream(FontsLibrary.ROOT[PHashItemData(L[i])^.OriginName]^.stream);
          fl.Add(fr);
          DoStatus('��ȡ���� %s', [PHashItemData(L[i])^.OriginName]);
          fontComboBox.Items.AddObject(fr.FontInfo, fr);
        end;

      dict := TPascalStringList.Create;
      stream := FileIOOpen('����.txt');
      dict.LoadFromStream(stream);
      stream.Free;

      TCompute.Sync(procedure
        begin
          fontComboBox.Enabled := True;
          fontComboBox.ItemIndex := 0;
          RandomFireEditButton.Enabled := True;
          // ���ڽ�ʡ�ڴ�,���������ͷ���Դ
          FreeGlobalMedia;
        end);
    end);
end;

end.
