unit ParticleRenderFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  System.IOUtils,

  ZR.Core, ZR.PascalStrings, ZR.DFE, ZR.Geometry2D,
  ZR.Json,
  ZR.Status,
  ZR.MemoryRaster, ZR.DrawEngine, ZR.DrawEngine.SlowFMX,
  ZR.MediaCenter;

type
  TParticleRenderForm = class(TForm)
    fpsTimer: TTimer;
    pb: TPaintBox;
    procedure fpsTimerTimer(Sender: TObject);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
  private
    dIntf: TDrawEngineInterface_FMX;
    bk: TZR;
    // ���Ʒ�������
    cenBox, destBox: TRectV2;
    cenBoxRadius, destBoxRadius: TGeoFloat;
    destAngle: TGeoFloat;
    // ����ϵͳ�󶨵�����֡
    sequenceAnimateTexture: TZR;
    // ����ϵͳ
    particles: TParticles;

    procedure DoStatus_backcall(Text_: SystemString; const ID: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ParticleRenderForm: TParticleRenderForm;

implementation

{$R *.fmx}


constructor TParticleRenderForm.Create(AOwner: TComponent);
var
  stream: TStream;
begin
  inherited Create(AOwner);

  // ������кܶ������ļ�,�Ͱ���Щ�ļ����
  // InitGlobalMedia��һ���������ݵ�Ӧ�÷�ʽ,��֧�ֶ�ƽ̨
  // �ļ��������ʹ��FilePackage���๤������
  // gmtArt��ʾ����,ͼƬ�����Դ��,��art��Ϊresource��ʶ��
  InitGlobalMedia([gmtArt]);

  // ��ʼ����Ⱦ����ӿ�
  dIntf := TDrawEngineInterface_FMX.Create;
  // ��ʼ��ƽ�̱���ͼƬ
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 64);

  // ��ʼ��DoStatusIO�ӿ�
  AddDoStatusHook(self, DoStatus_backcall);

  // ��ʼ����ת�˶�ʹ�õı���
  cenBox := NullRect;
  destBox := NullRect;
  cenBoxRadius := 5;
  destBoxRadius := 30;
  destAngle := 0;

  // �漰��������Դ�ļ�ʱ,fileIO����ѡ��ʽ
  // fileIO��һ������IO��֧��APIϵͳ,���Կ�Խ�ļ�������ȡstream
  // fileIO��֧��λ��MediaCenter.pas��
  // ͨ��fileIOOpen���ʰ�����
  stream := FileIOOpen('demo3.seq');
  sequenceAnimateTexture := NewZRFromStream(stream);
  stream.Free;

  particles := DrawPool(pb).CreateParticles;
  // ָ������֡��������
  particles.SequenceTexture := sequenceAnimateTexture;
  // ����֡�������ʱ��,��λ��
  particles.SequenceTextureCompleteTime := 0.5;
  // ���Ӵ�С
  particles.ParticleSize := 15;
  particles.ParticleSizeMinScale := 0.5;
  particles.ParticleSizeMaxScale := 10.0;
  // ����͸����
  particles.MinAlpha := 0.0;
  particles.MaxAlpha := 0.05;
  // ��������ʱ��
  particles.LifeTime := 1.0;
  // �����������
  particles.MaxParticle := 0;
  // ÿ����������
  particles.GenSpeedOfPerSecond := 500;
  // ���������Զ�����
  particles.Enabled := True;

  DoStatus('����ϵͳ��������֡�Ժ�����ͬ����һ������Ԫ��һ����������,Ӳ�������Ƿǳ�����.');
  DoStatus('�� 60 fps ��������ͬ����Ⱦÿ���� 20 �����ϻ�������.');
end;

destructor TParticleRenderForm.Destroy;
begin
  DeleteDoStatusHook(self);
  dIntf.Free;
  inherited Destroy;
end;

procedure TParticleRenderForm.DoStatus_backcall(Text_: SystemString; const ID: Integer);
begin
  DrawPool(pb).PostScrollText(60.0, TDrawEngine.RebuildNumColor(Text_, '|color(1,0.5,0.5)|', '||'), 12, DEColor(1, 1, 1));
end;

procedure TParticleRenderForm.fpsTimerTimer(Sender: TObject);
var
  cen, dPt: TVec2;
begin
  CheckThreadSynchronize;

  // ��Ⱦ����ѭ��
  DrawPool.Progress;

  // ������ת����
  cen := RectCentre(RectV2(ClientRect));
  cenBox := RectV2(cen, cenBoxRadius * 2, cenBoxRadius * 2);
  destAngle := NormalizeDegAngle(destAngle + 180 * DrawPool.LastDeltaTime);
  dPt := Vec2Rotation(cen, MinF(cen[0], cen[1]) * 0.8, destAngle);
  destBox := RectV2(dPt, destBoxRadius * 2, destBoxRadius * 2);

  // ���ӷ�������
  particles.FireSource := destBox;
  // �����˶�����
  particles.FireDirection := RectDirection(destBox, cenBox);
  // �����˶��ļ��ٱ���
  particles.Acceleration := 1;
  // �����˶��ٶ�
  particles.MinSpeed := 5;
  particles.MaxSpeed := 10;

  // zDrawEngine�ǿ�ƽ̨����Ⱦ���ӿ�,����FMX�Ƚ�����ʹ��,����Ҫ�����ؼ�,����zDrawEngine��ȾĬ�϶���fmx���
  // ����Խ����ݮ�������豸ʱ,castle-engine�Ǹ������ͼ������ӿ�
  // ˢ��FMX
  Invalidate;
end;

procedure TParticleRenderForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voFPS];
  // ������
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);
  // ������Ŀ��
  d.DrawEllipse(cenBox, DEColor(1, 1, 1), 2);
  // ����תĿ��
  d.DrawEllipse(destBox, DEColor(1, 1, 1), 2);
  // ������
  d.DrawParticle(particles);
  d.Flush;
end;

end.
