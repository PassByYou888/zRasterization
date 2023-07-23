unit SqeurnceAniFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Layouts, FMX.ListBox,
  FMX.Controls.Presentation, FMX.StdCtrls,

  ZR.Core, ZR.Geometry2D, ZR.UnicodeMixedLib,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.MediaCenter,
  ZR.DrawEngine.SlowFMX, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  TSqeurnceAniForm = class(TForm)
    fpsTimer: TTimer;
    Layout1: TLayout;
    ListBox: TListBox;
    StyleBook1: TStyleBook;
    CheckBoxLoop: TCheckBox;
    Memo1: TMemo;
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure fpsTimerTimer(Sender: TObject);
    procedure Layout1Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure ListBoxClick(Sender: TObject);
    procedure ListBoxKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
    dIntf: TDrawEngineInterface_FMX;
    bk: TZR;
    SequAni: TDETexture;
    constructor Create(AOwner: TComponent); override;
  end;

var
  SqeurnceAniForm: TSqeurnceAniForm;

implementation

{$R *.fmx}


constructor TSqeurnceAniForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // ��Ⱦ�����Ŀ��
  dIntf := TDrawEngineInterface_FMX.Create;
  // ��������
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 32);

  // ����֡����ʵ��
  SequAni := TDrawEngine.NewTexture;

  // Z.MediaCenter.pas��ӵ�д��ģ������ʱ��Դ�ļ���������
  // һ�����,app��exe����ʹ���ⲿ��Դ�ļ�,��Щ��Դ�ļ����ᱻ���ɵ�app��exe�ڲ�
  // gmtArt��ʾ�����
  InitGlobalMedia([gmtArt]);
  // �Ӹ�Ŀ¼������������֡�����ļ���
  ArtLibrary.ROOT.GetOriginNameListFromFilter('*.seq', ListBox.Items);
end;

procedure TSqeurnceAniForm.FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  dIntf.SetSurface(Canvas, Sender);
  with DrawPool(Sender, dIntf) do
    begin
      drawTile(bk);
      Flush;
    end;
end;

procedure TSqeurnceAniForm.fpsTimerTimer(Sender: TObject);
begin
  CheckThread;
  DrawPool.Progress;
  Invalidate;
end;

procedure TSqeurnceAniForm.Layout1Painting(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
begin
  if SequAni.Empty then
      exit;
  dIntf.SetSurface(Canvas, Sender);
  with DrawPool(Sender, dIntf) do
    begin
      DrawDotLineBox(ScreenRectV2, DEColor(1, 1, 1), 2);
      FitDrawSequenceTexture(SequAni.UserToken, SequAni, 1.0, CheckBoxLoop.IsChecked, ScreenRectV2, 1.0);
      Flush;
    end;
end;

procedure TSqeurnceAniForm.ListBoxClick(Sender: TObject);
begin
  if ListBox.Selected = nil then
      exit;
  SequAni.UserToken := ListBox.Selected.Text;
  SequAni.LoadFromStream(ArtLibrary.ROOT[SequAni.UserToken]^.stream);
  SequAni.Update;
end;

procedure TSqeurnceAniForm.ListBoxKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if ListBox.Selected = nil then
      exit;
  SequAni.UserToken := ListBox.Selected.Text;
  SequAni.LoadFromStream(ArtLibrary.ROOT[SequAni.UserToken]^.stream);
  SequAni.Update;
end;

end.
