unit SampleEditorFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts,
  FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Colors, System.Actions,
  FMX.ActnList, FMX.ListBox, FMX.ScrollBox, FMX.Memo, FMX.TabControl,

  System.IOUtils, System.Math, System.Threading,

  ZR.Core,
  ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status,
  ZR.Notify, ZR.Cadencer,
  ZR.TextDataEngine, ZR.ListEngine,
  ZR.DrawEngine.SlowFMX, ZR.DrawEngine, ZR.Geometry2D, ZR.Geometry3D,
  ZR.MemoryStream,
  ZR.MemoryRaster, ZR.MemoryRaster.MorphologyExpression,
  ZR.DrawEngine.PictureViewer, FMX.Memo.Types;

type
  TSampleEditorForm = class;

  TScriptResultListBoxItem = class(TListBoxItem)
  public
    OwnerForm: TSampleEditorForm;
    Step: TMorphExpStep;
    dIntf: TDrawEngineInterface_FMX;
    d: TDrawEngine;
    pb: TPaintBox;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PBPaint(Sender: TObject; Canvas: TCanvas);
    procedure DoClick(Sender: TObject);
  end;

  TSampleEditorForm = class(TForm, ICadencerProgressInterface)
    leftLayout: TLayout;
    leftSplitter: TSplitter;
    cliLayout: TLayout;
    cliTopLayout: TLayout;
    viewerPB: TPaintBox;
    ScriptMemo: TMemo;
    ScriptSplitter: TSplitter;
    Timer: TTimer;
    Layout1: TLayout;
    RunButton: TButton;
    ActionList: TActionList;
    Action_Run: TAction;
    OpenPictureDialog: TOpenDialog;
    AllLayout: TLayout;
    ScriptResultListBox: TListBox;
    Action_ScriptHelp: TAction;
    Button1: TButton;
    Action_OpenNewEditor: TAction;
    Button3: TButton;
    Action_SaveAs: TAction;
    SavePictureDialog: TSaveDialog;
    Action_Finish: TAction;
    HelpFilterEdit: TEdit;
    CheckBox_ShowPixelInfo: TCheckBox;
    CheckBox_ShowHistogramInfo: TCheckBox;
    Button5: TButton;
    Action_BuildMorphPicture: TAction;
    procedure Action_RunExecute(Sender: TObject);
    procedure Action_SaveAsExecute(Sender: TObject);
    procedure Action_ScriptHelpExecute(Sender: TObject);
    procedure Action_BuildMorphPictureExecute(Sender: TObject);
    procedure CheckBox_ShowHistogramInfoChange(Sender: TObject);
    procedure CheckBox_ShowPixelInfoChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure HelpFilterEditKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure TimerTimer(Sender: TObject);
    procedure viewerPBMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure viewerPBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure viewerPBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure viewerPBMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure viewerPBPaint(Sender: TObject; Canvas: TCanvas);
  protected
    Input: TMZR;
    MorphExp: TMorphExp;
    dIntf: TDrawEngineInterface_FMX;
    d: TDrawEngine;
    ProgEng: TN_Progress_Tool;
    CadEng: TCadencer;
    ViewIntf: TPictureViewerInterface;
  public
    constructor CustomCreate(AOwner: TComponent; ShowOpenDialog: Boolean);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetInputRaster(r: TMZR);
    procedure CadencerProgress(const deltaTime, newTime: Double);
    procedure RunScript(s: U_String);
    procedure DisableScript;
    procedure EnabledScript;
    procedure UpdateMorphExpResult;
  end;

  TSamplerEditorInstanceList = TGenericsList<TSampleEditorForm>;

function OpenSamplerEditor(Bounds: TRect; Input: TMZR): TSampleEditorForm; overload;
function OpenSamplerEditor(Input: TMZR): TSampleEditorForm; overload;
procedure CloseSamplerEditorInstance(ignore: TSampleEditorForm);

var
  SampleEditorForm: TSampleEditorForm;
  SamplerEditorInstance: TSamplerEditorInstanceList;

implementation

{$R *.fmx}


uses StyleModuleUnit, FMXLogFrm;

function OpenSamplerEditor(Bounds: TRect; Input: TMZR): TSampleEditorForm;
var
  f: TSampleEditorForm;
begin
  f := TSampleEditorForm.CustomCreate(nil, False);
  if f <> Application.MainForm then
      f.Parent := Application.MainForm;
  f.Bounds := Bounds;
  f.SetInputRaster(Input);
  f.Show;
  Result := f;
end;

function OpenSamplerEditor(Input: TMZR): TSampleEditorForm;
var
  f: TSampleEditorForm;
begin
  f := TSampleEditorForm.CustomCreate(nil, False);
  if f <> Application.MainForm then
      f.Parent := Application.MainForm;
  f.SetInputRaster(Input);
  f.Show;
  Result := f;
end;

procedure CloseSamplerEditorInstance(ignore: TSampleEditorForm);
var
  i: Integer;
  n: TSamplerEditorInstanceList;
begin
  n := TSamplerEditorInstanceList.Create;
  for i := 0 to SamplerEditorInstance.Count - 1 do
    if SamplerEditorInstance[i] <> ignore then
        n.Add(SamplerEditorInstance[i]);
  for i := 0 to n.Count - 1 do
      disposeObject(n[i]);
  disposeObject(n);
end;

constructor TScriptResultListBoxItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  OwnerForm := nil;
  Step := nil;

  pb := TPaintBox.Create(Self);
  pb.Parent := Self;
  pb.HitTest := False;
  pb.Align := TAlignLayout.Client;
  pb.OnPaint := PBPaint;

  dIntf := TDrawEngineInterface_FMX.Create;
  d := TDrawEngine.Create;
  d.ViewOptions := [];

  Selectable := False;
  OnClick := DoClick;
end;

destructor TScriptResultListBoxItem.Destroy;
begin
  disposeObject(dIntf);
  disposeObject(d);
  inherited Destroy;
end;

procedure TScriptResultListBoxItem.DoClick(Sender: TObject);
begin
  if (Step <> nil) and (Step.OutData <> nil) then
    begin
      if Step.OutData.DebugViewer = nil then
          Step.OutData.BuildDebugViewer();
      if Step.OutData.DebugViewer = nil then
          exit;
      OwnerForm.ViewIntf.Clear;
      OwnerForm.ViewIntf.InputPicture(Step.OutData.DebugViewer, Step.ExpStr, False);
      OwnerForm.ViewIntf.DrawEng.CameraR := Step.OutData.DebugViewer.BoundsRectV2;
    end;
end;

procedure TScriptResultListBoxItem.PBPaint(Sender: TObject; Canvas: TCanvas);
var
  tex: TMZR;
  tmpR, r: TRectV2;
  text_input, text_result, n: U_String;
  Err: Boolean;
  c: U_String;
  textSiz: TVec2;
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;

  tex := nil;
  text_input := '';
  text_result := '';
  Err := True;
  tmpR := d.ScreenRect;
  if (Step <> nil) and (Step.OutData <> nil) then
    begin
      text_input := Step.ExpStr;
      text_result := Step.ExpResult;
      Err := text_result.StrExists('error');
      if Step.OutData.DebugViewer = nil then
          Step.OutData.BuildDebugViewer();

      if Step.OutData.DebugViewer <> nil then
        begin
          tex := Step.OutData.DebugViewer;
          tmpR := FitRect(tex.BoundsRectV2, d.ScreenRect);
          r[0] := Vec2(d.width - RectWidth(tmpR) - 2, 1);
          r[1] := Vec2(d.width - 1, d.height - 1);
          d.FitDrawPicture(tex, tex.BoundsRectV2, r, 1.0);
        end;
    end;

  if Err then
      c := 'color(1,0,0)'
  else
      c := 'color(0.5,1,0.5)';

  if text_input.L > 30 then
      text_input := text_input.Copy(1, 27) + '...';
  if text_result.L > 30 then
      text_result := text_result.Copy(1, 27) + '...';

  n := '|s:10,color(0.2,0.5,0.2)|' + text_input + '||' + #13#10 + text_result;
  n := umlStringReplace(n, '[', '[|s:10,' + c + '|', True);
  n := umlStringReplace(n, ']', '||]', True);
  if tex <> nil then
      n.Append(#13#10 + '|color(0.5,0.5,0.5)|%d * %d||', [tex.width, tex.height])
  else
      n.Append(#13#10 + '|color(0.5,0.5,0.5)|no outout||');
  textSiz := d.GetTextSize(n, 12);

  d.BeginCaptureShadow(Vec2(2, 2), 1.0);
  d.DrawText(n, 12, DEColor(1, 1, 1, 1), Vec2(5, (d.height - textSiz[1]) * 0.5));
  d.EndCaptureShadow;
  d.Flush;
end;

procedure TSampleEditorForm.Action_RunExecute(Sender: TObject);
begin
  RunScript(ScriptMemo.Text);
end;

procedure TSampleEditorForm.Action_SaveAsExecute(Sender: TObject);
var
  ZR_: TMZR;
begin
  if not SavePictureDialog.Execute then
      exit;
  ZR_ := ViewIntf.Items[0].Raster;
  if umlMultipleMatch('*.bmp', SavePictureDialog.FileName) then
      ZR_.SaveToBmp24File(SavePictureDialog.FileName)
  else if umlMultipleMatch('*.jpg', SavePictureDialog.FileName) then
      ZR_.SaveToJpegYCbCrFile(SavePictureDialog.FileName, 90)
  else if umlMultipleMatch('*.jls', SavePictureDialog.FileName) then
      ZR_.SaveToJpegLS3File(SavePictureDialog.FileName)
  else if umlMultipleMatch('*.yv12', SavePictureDialog.FileName) then
      ZR_.SaveToYV12File(SavePictureDialog.FileName)
  else
      SaveZR(ZR_, SavePictureDialog.FileName);
end;

procedure TSampleEditorForm.Action_ScriptHelpExecute(Sender: TObject);
var
  mRunTime: TMorphExpRunTime;
  s: TPascalStringList;
  i: Integer;
begin
  LogForm.VisibleLog := True;

  // build script reference information
  mRunTime := TMorphExpRunTime.Create;
  s := mRunTime.GetAllProcDescription();

  if HelpFilterEdit.Text <> '' then
    begin
      for i := 0 to s.Count - 1 do
        if umlSearchMatch(HelpFilterEdit.Text, s[i]) then
            DoStatus(s[i]);
    end
  else
      DoStatusL(s);

  DisposeObjectAndNil(s);
  DisposeObjectAndNil(mRunTime);
end;

procedure TSampleEditorForm.Action_BuildMorphPictureExecute(Sender: TObject);
begin
  ViewIntf.BuildMorphViewData;
end;

procedure TSampleEditorForm.CheckBox_ShowHistogramInfoChange(Sender: TObject);
begin
  ViewIntf.WaitThread;
  ViewIntf.ShowHistogramInfo := TCheckBox(Sender).IsChecked;
end;

procedure TSampleEditorForm.CheckBox_ShowPixelInfoChange(Sender: TObject);
begin
  ViewIntf.ShowPixelInfo := TCheckBox(Sender).IsChecked;
end;

procedure TSampleEditorForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ViewIntf.WaitThread();

  Action := TCloseAction.caFree;

  if Application.MainForm = Self then
      CloseSamplerEditorInstance(Self);
end;

procedure TSampleEditorForm.HelpFilterEditKeyUp(Sender: TObject; var Key:
    Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = VKRETURN then
      Action_ScriptHelp.Execute;
end;

procedure TSampleEditorForm.TimerTimer(Sender: TObject);
begin
  CheckThread;
  CadEng.Progress;
end;

procedure TSampleEditorForm.viewerPBMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapDown(Vec2(X, Y));
end;

procedure TSampleEditorForm.viewerPBMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapMove(Vec2(X, Y));
end;

procedure TSampleEditorForm.viewerPBMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  ViewIntf.TapUp(Vec2(X, Y));
end;

procedure TSampleEditorForm.viewerPBMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  Handled := True;
  if WheelDelta > 0 then
      ViewIntf.ScaleCamera(1.1)
  else
      ViewIntf.ScaleCamera(0.9);
end;

procedure TSampleEditorForm.viewerPBPaint(Sender: TObject; Canvas: TCanvas);
begin
  dIntf.SetSurface(Canvas, Sender);
  d.DrawInterface := dIntf;
  d.SetSize;
  ViewIntf.Render;
end;

constructor TSampleEditorForm.CustomCreate(AOwner: TComponent; ShowOpenDialog: Boolean);
begin
  inherited Create(AOwner);

  // init classes
  Input := NewZR();
  MorphExp := TMorphExp.Create;
  dIntf := TDrawEngineInterface_FMX.Create;
  d := TDrawEngine.Create;
  d.ViewOptions := [voEdge];
  ProgEng := TN_Progress_Tool.Create;
  CadEng := TCadencer.Create;
  CadEng.ProgressInterface := Self;
  ViewIntf := TPictureViewerInterface.Create(d);
  ViewIntf.ShowHistogramInfo := CheckBox_ShowHistogramInfo.IsChecked;
  ViewIntf.ShowPixelInfo := CheckBox_ShowPixelInfo.IsChecked;

  SamplerEditorInstance.Add(Self);

  // delay show openDialog
  if ShowOpenDialog then
    begin
      ProgEng.PostExecuteP_NP(0, procedure
        var
          r: TRect;
          ZR_: TMZR;
          i: Integer;
          n: U_String;
          done_: Boolean;
        begin
          r := Bounds;
          done_ := False;
          if ParamCount > 0 then
            begin
              for i := 1 to ParamCount do
                begin
                  n := ParamStr(i);
                  if not umlMultipleMatch(['-D3D', '-D2D', '-GPU', '-SOFT', '-GrayTheme'], n) then
                    if umlFileExists(n) then
                      begin
                        ZR_ := NewZRFromFile(n);
                        if ViewIntf.Count = 0 then
                          begin
                            SetInputRaster(ZR_);
                          end
                        else
                          begin
                            r.Offset(30, 30);
                            OpenSamplerEditor(r, ZR_);
                          end;
                        disposeObject(ZR_);
                        done_ := True;
                      end;
                end;
            end;
          if not done_ then
            begin
              if not OpenPictureDialog.Execute then
                begin
                  Close;
                  exit;
                end;

              for i := 0 to OpenPictureDialog.Files.Count - 1 do
                begin
                  n := OpenPictureDialog.Files[i];
                  ZR_ := NewZRFromFile(n);
                  if ViewIntf.Count = 0 then
                    begin
                      SetInputRaster(ZR_);
                    end
                  else
                    begin
                      r.Offset(30, 30);
                      OpenSamplerEditor(r, ZR_);
                    end;
                  disposeObject(ZR_);
                end;
            end;
        end);
    end;
end;

constructor TSampleEditorForm.Create(AOwner: TComponent);
begin
  CustomCreate(AOwner, True);
end;

destructor TSampleEditorForm.Destroy;
begin
  SamplerEditorInstance.Remove(Self);

  DisposeObjectAndNil(ViewIntf);
  DisposeObjectAndNil(d);
  DisposeObjectAndNil(dIntf);
  DisposeObjectAndNil(MorphExp);
  DisposeObjectAndNil(Input);
  DisposeObjectAndNil(ProgEng);
  DisposeObjectAndNil(CadEng);
  inherited Destroy;
end;

procedure TSampleEditorForm.SetInputRaster(r: TMZR);
begin
  Input.Assign(r);
  ViewIntf.Clear;
  ViewIntf.InputPicture(Input, 'origin input', False);

  ProgEng.PostExecuteP_NP(0.0, procedure
    begin
      d.CameraR := Input.BoundsRectV2;
    end);
end;

procedure TSampleEditorForm.CadencerProgress(const deltaTime, newTime: Double);
begin
  ProgEng.Progress(deltaTime);
  d.Progress(deltaTime);
  Invalidate;
end;

procedure TSampleEditorForm.RunScript(s: U_String);
begin
  ScriptResultListBox.Clear;
  DisableScript;
  TCompute.RunP(nil, nil, procedure(thSender: TCompute)
    begin
      MorphExp.Run(Input, s);

      TThread.Synchronize(thSender, procedure
        begin
          EnabledScript;
          UpdateMorphExpResult;
        end);
    end);
end;

procedure TSampleEditorForm.DisableScript;
begin
  AllLayout.Enabled := False;
end;

procedure TSampleEditorForm.EnabledScript;
begin
  AllLayout.Enabled := True;
end;

procedure TSampleEditorForm.UpdateMorphExpResult;
var
  i: Integer;
  li: TScriptResultListBoxItem;
begin
  ScriptResultListBox.BeginUpdate;
  ScriptResultListBox.Clear;
  for i := 0 to MorphExp.Steps.Count - 1 do
    begin
      li := TScriptResultListBoxItem.Create(ScriptResultListBox);
      li.OwnerForm := Self;
      li.Step := MorphExp.Steps[i];
      li.height := 50;
      li.Parent := ScriptResultListBox;
    end;
  ScriptResultListBox.EndUpdate;
end;

initialization

SamplerEditorInstance := TSamplerEditorInstanceList.Create;

finalization

DisposeObjectAndNil(SamplerEditorInstance);

end.
