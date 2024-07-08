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
    // 控制发射坐标
    cenBox, destBox: TRectV2;
    cenBoxRadius, destBoxRadius: TGeoFloat;
    destAngle: TGeoFloat;
    // 粒子系统绑定的序列帧
    sequenceAnimateTexture: TZR;
    // 粒子系统
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

  // 如果带有很多运行文件,就把这些文件打包
  // InitGlobalMedia是一种载入数据的应用方式,可支持多平台
  // 文件打包可以使用FilePackage这类工具制作
  // gmtArt表示纹理,图片类的资源包,以art作为resource标识符
  InitGlobalMedia([gmtArt]);

  // 初始化渲染输出接口
  dIntf := TDrawEngineInterface_FMX.Create;
  // 初始化平铺背景图片
  bk := NewZR();
  bk.SetSize(128, 128);
  FillBlackGrayBackgroundTexture(bk, 64);

  // 初始化DoStatusIO接口
  AddDoStatusHook(self, DoStatus_backcall);

  // 初始化旋转运动使用的变量
  cenBox := NullRect;
  destBox := NullRect;
  cenBoxRadius := 5;
  destBoxRadius := 30;
  destAngle := 0;

  // 涉及到大量资源文件时,fileIO是首选方式
  // fileIO是一种虚拟IO的支持API系统,可以跨越文件包来获取stream
  // fileIO的支持位于MediaCenter.pas库
  // 通过fileIOOpen访问包数据
  stream := FileIOOpen('demo3.seq');
  sequenceAnimateTexture := NewZRFromStream(stream);
  stream.Free;

  particles := DrawPool(pb).CreateParticles;
  // 指定序列帧动画纹理
  particles.SequenceTexture := sequenceAnimateTexture;
  // 序列帧动画完成时间,单位秒
  particles.SequenceTextureCompleteTime := 0.5;
  // 粒子大小
  particles.ParticleSize := 15;
  particles.ParticleSizeMinScale := 0.5;
  particles.ParticleSizeMaxScale := 10.0;
  // 粒子透明度
  particles.MinAlpha := 0.0;
  particles.MaxAlpha := 0.05;
  // 粒子生存时间
  particles.LifeTime := 1.0;
  // 限制最大粒子
  particles.MaxParticle := 0;
  // 每秒生成粒子
  particles.GenSpeedOfPerSecond := 500;
  // 开启粒子自动生成
  particles.Enabled := True;

  DoStatus('粒子系统绑定了序列帧以后由于同处于一个纹理单元和一个绘制批次,硬件加速是非常明显.');
  DoStatus('按 60 fps 初步估算同屏渲染每秒有 20 万以上绘制命令.');
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

  // 渲染器主循环
  DrawPool.Progress;

  // 计算旋转坐标
  cen := RectCentre(RectV2(ClientRect));
  cenBox := RectV2(cen, cenBoxRadius * 2, cenBoxRadius * 2);
  destAngle := NormalizeDegAngle(destAngle + 180 * DrawPool.LastDeltaTime);
  dPt := Vec2Rotation(cen, MinF(cen[0], cen[1]) * 0.8, destAngle);
  destBox := RectV2(dPt, destBoxRadius * 2, destBoxRadius * 2);

  // 粒子发射坐标
  particles.FireSource := destBox;
  // 粒子运动方向
  particles.FireDirection := RectDirection(destBox, cenBox);
  // 粒子运动的加速比例
  particles.Acceleration := 1;
  // 粒子运动速度
  particles.MinSpeed := 5;
  particles.MaxSpeed := 10;

  // zDrawEngine是跨平台的渲染器接口,由于FMX比较易于使用,不需要三方控件,所以zDrawEngine渲染默认都向fmx输出
  // 当跨越到树莓派这类设备时,castle-engine是个不错的图形输出接口
  // 刷新FMX
  Invalidate;
end;

procedure TParticleRenderForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
begin
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);
  d.ViewOptions := [voFPS];
  // 画背景
  d.DrawTile(bk, bk.BoundsRectV2, 1.0);
  // 画中心目标
  d.DrawEllipse(cenBox, DEColor(1, 1, 1), 2);
  // 画旋转目标
  d.DrawEllipse(destBox, DEColor(1, 1, 1), 2);
  // 画粒子
  d.DrawParticle(particles);
  d.Flush;
end;

end.
