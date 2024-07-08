program ZSamplerBuilder;

uses
  FastMM5,
  System.StartUpCopy,
  FMX.Forms,
  System.Classes,
  ZR.Core,
  ZR.PascalStrings,
  ZR.UPascalStrings,
  ZR.UnicodeMixedLib,
  ZR.MediaCenter,
  ZR.MemoryRaster,
  FMX.Types,
  StyleModuleUnit in '..\Common\StyleModuleUnit.pas' {StyleDataModule: TDataModule} ,
  SampleEditorFrm in 'SampleEditorFrm.pas' {SampleEditorForm} ,
  FMXLogFrm in '..\Common\FMXLogFrm.pas' {LogForm};

{$R ZSamplerBuilder.res}
{$R ..\Common\art.res}


procedure Check_Graphic_Mode_Param;
var
  n: U_String;
  i: Integer;
begin
  if (ParamCount > 0) and (not IsDebug) then
    begin
      for i := 1 to ParamCount do
        begin
          n := ParamStr(i);
          if umlMultipleMatch(['-D3D', '-D2D'], n) then
            begin
              GlobalUseDX := True;
              GlobalUseDirect2D := True;
              GlobalUseGPUCanvas := False;
              GlobalUseDXSoftware := False;
            end
          else if umlMultipleMatch(['-GPU'], n) then
            begin
              GlobalUseDX := False;
              GlobalUseDirect2D := False;
              GlobalUseGPUCanvas := True;
              GlobalUseDXSoftware := False;
            end
          else if umlMultipleMatch(['-SOFT'], n) then
            begin
              GlobalUseDX := False;
              GlobalUseDirect2D := False;
              GlobalUseGPUCanvas := False;
              GlobalUseDXSoftware := True;
            end;
        end;
    end;

end;

procedure Switch_GrayTheme(module_: TStyleDataModule);
var
  Stream_: TCore_Stream;
begin
  Stream_ := FileIOOpen('Theme:PolarDark_Win.style');
  if Stream_ <> nil then
    begin
      Stream_.Position := 0;
      module_.GlobalStyleBook.Clear;
      module_.GlobalStyleBook.LoadFromStream(Stream_);
      DisposeObject(Stream_);
      FBGB_bkColor := RColor(34, 36, 48);
      FBGB_color1 := RColor(44, 46, 48);
      FBGB_color2 := RColor(40, 39, 40);
    end;
end;

procedure Check_Theme_Mode_Param(module_: TStyleDataModule);
var
  n: U_String;
  i: Integer;
begin
  if (ParamCount > 0) then
    begin
      for i := 1 to ParamCount do
        begin
          n := ParamStr(i);
          if umlMultipleMatch(['-GrayTheme'], n) then
            begin
              Switch_GrayTheme(module_);
            end;
        end;
    end;
end;

type
  TCustom_StyleDataModule = class(TStyleDataModule)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

constructor TCustom_StyleDataModule.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Check_Theme_Mode_Param(StyleDataModule);
end;

destructor TCustom_StyleDataModule.Destroy;
begin
  inherited Destroy;
end;

begin
  InitGlobalMedia([gmtArt]);
  Check_Graphic_Mode_Param();
  Application.Initialize;
  Application.CreateForm(TCustom_StyleDataModule, StyleDataModule);
  Application.CreateForm(TSampleEditorForm, SampleEditorForm);
  Application.CreateForm(TLogForm, LogForm);
  Application.Run;
  FreeGlobalMedia();
end.
