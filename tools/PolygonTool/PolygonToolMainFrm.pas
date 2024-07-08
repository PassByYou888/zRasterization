unit PolygonToolMainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Layouts,
  FMX.Edit, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Colors, System.Actions,
  FMX.ActnList, FMX.ListBox, FMX.ScrollBox, FMX.Memo, FMX.Memo.Types,
  FMX.DialogService,

  System.IOUtils, System.Math, System.Threading,

  ZR.Core, ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status,
  ZR.TextDataEngine, ZR.ListEngine,
  ZR.DrawEngine.SlowFMX, ZR.DrawEngine, ZR.Geometry2D, ZR.Geometry3D, ZR.Notify,
  ZR.MemoryRaster, ZR.MemoryStream,
  ZR.FFMPEG.Reader;

type
  TOn_PolygonTool_Result = reference to procedure(Polygon_: TDeflectionPolygonListRenderer);

  TPolygonToolMainForm = class(TForm)
    tl: TLayout;
    pb: TPaintBox;
    fpsTimer: TTimer;
    edit_Layout: TLayout;
    XEdit: TEdit;
    YEdit: TEdit;
    setPictureButton: TButton;
    OpenPictureDialog: TOpenDialog;
    OwnerCheckBox: TCheckBox;
    AngleEdit: TEdit;
    ScaleEdit: TEdit;
    OwnerAngleCheckBox: TLabel;
    OwnerScaleCheckBox: TLabel;
    NewProjButton: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    SaveProjButton: TButton;
    OpenProjButton: TButton;
    SetVideoButton: TButton;
    OpenVideoDialog: TOpenDialog;
    ListBox: TListBox;
    AddGeoButton: TButton;
    DelGeoButton: TButton;
    NameEdit: TEdit;
    Label1: TLabel;
    SaveProjAsButton: TButton;
    BuildCodeButton: TButton;
    ShowCoordinateCheckBox: TCheckBox;
    ShowPolygonCheckBox: TCheckBox;
    Label2: TLabel;
    ClassifierEdit: TEdit;
    RendererTempletSaveDialog: TSaveDialog;
    CompileDataButton: TButton;
    L_Layout: TLayout;
    EditingCheckBox: TCheckBox;
    SetURLButton: TButton;
    Return_Button: TButton;
    R_Splitter: TSplitter;
    cli_Layout: TLayout;
    Layout1: TLayout;
    Renderer_Options_Memo: TMemo;
    Layout2: TLayout;
    Apply_Renderer_Options_Button: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure fpsTimerTimer(Sender: TObject);
    procedure AddGeoButtonClick(Sender: TObject);
    procedure Apply_Renderer_Options_ButtonClick(Sender: TObject);
    procedure CompileDataButtonClick(Sender: TObject);
    procedure BuildCodeButtonClick(Sender: TObject);
    procedure DelGeoButtonClick(Sender: TObject);
    procedure Return_ButtonClick(Sender: TObject);
    procedure NewProjButtonClick(Sender: TObject);
    procedure OpenProjButtonClick(Sender: TObject);
    procedure SaveProjAsButtonClick(Sender: TObject);
    procedure SaveProjButtonClick(Sender: TObject);
    procedure ListBoxItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure PolyOptChange(Sender: TObject);
    procedure setPictureButtonClick(Sender: TObject);
    procedure SetVideoButtonClick(Sender: TObject);
    procedure SetURLButtonClick(Sender: TObject);
  private
    dIntf: TDrawEngineInterface_FMX;
    PolygonList: TDeflectionPolygonListRenderer;
    Activted_Polygon: TDeflectionPolygon;

    // pick state
    pt_pick_idx: Integer;
    l_pick_idx1, l_pick_idx2: Integer;
    poly_pos_pick, poly_rotate_dest_pick: Boolean;
    down_pt, move_pt, up_pt: TVec2; // screen coordinate
    down: Boolean;
    down_btn: TMouseButton;
    shift_state: TShiftState;
    polygonViewer_Radius: TGeoFloat;
    polygonViewer_Rotation_distance: TGeoFloat;

    // other
    backgroundTexture: TMZR;
    DisableEditEvent: Boolean;
    LastOpenFile: U_String;
    mpegReader: TFFMPEG_Reader;

    // result event
    On_Result: TOn_PolygonTool_Result;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure UpdatePolyValueState;
    procedure Reset(reset_scene: Boolean);
    procedure UpdatePolygonList;
    procedure Update_Renderer_Options;

    procedure SwitchAsDefaultEditor;
    procedure SwitchAsGeometryEditor;
    procedure SwitchAsGeometry_Return_Mode_Editor;
  end;

  TPolygonToolInstanceList = TGenericsList<TPolygonToolMainForm>;

var
  PolygonToolMainForm: TPolygonToolMainForm = nil;
  PolygonToolInstanceList: TPolygonToolInstanceList;

procedure ClosePolygonToolInstance(ignore: TPolygonToolMainForm);
procedure OpenFreeGeometryEditor(raster: TMZR);
procedure OpenFreeGeometry_Return_Mode_Editor(raster: TMZR; info_: U_String; polygon_stream, renderer_options_stream: TMS64; On_Result: TOn_PolygonTool_Result);

implementation

{$R *.fmx}


uses StyleModuleUnit, FMXLogFrm;

procedure ClosePolygonToolInstance(ignore: TPolygonToolMainForm);
var
  i: Integer;
  n: TPolygonToolInstanceList;
begin
  n := TPolygonToolInstanceList.Create;
  for i := 0 to PolygonToolInstanceList.Count - 1 do
    if PolygonToolInstanceList[i] <> ignore then
        n.Add(PolygonToolInstanceList[i]);
  for i := 0 to n.Count - 1 do
      disposeObject(n[i]);
  disposeObject(n);
end;

procedure OpenFreeGeometryEditor(raster: TMZR);
var
  f: TPolygonToolMainForm;
begin
  f := TPolygonToolMainForm.Create(Application);
  if f <> Application.MainForm then
      f.Parent := Application.MainForm;
  f.Position := TFormPosition.MainFormCenter;
  f.SwitchAsGeometryEditor;

  with f do
    begin
      Reset(True);
      backgroundTexture.Assign(raster);
      Reset(False);
      Show;
    end;
end;

procedure OpenFreeGeometry_Return_Mode_Editor(raster: TMZR; info_: U_String; polygon_stream, renderer_options_stream: TMS64; On_Result: TOn_PolygonTool_Result);
var
  f: TPolygonToolMainForm;
begin
  f := TPolygonToolMainForm.Create(Application);
  if f <> Application.MainForm then
      f.Parent := Application.MainForm;
  f.Position := TFormPosition.MainFormCenter;
  f.SwitchAsGeometry_Return_Mode_Editor;
  f.On_Result := On_Result;

  with f do
    begin
      Reset(True);
      if (raster <> nil) and (not raster.Empty) then
        begin
          backgroundTexture.Assign(raster);
          Reset(False);
        end;
      if polygon_stream <> nil then
        begin
          polygon_stream.Position := 0;
          PolygonList.LoadFromStream(polygon_stream);
          if backgroundTexture <> nil then
              PolygonList.Rebuild_From_New_Background_Box(backgroundTexture.BoundsRectV2);
          if PolygonList.Count = 0 then
            begin
              Activted_Polygon := TDeflectionPolygon.Create;
              Activted_Polygon.Name := PolygonList.MakePolygonName('polygon');
              Activted_Polygon.Classifier := 'Default';
              PolygonList.Add(Activted_Polygon);
            end
          else
              Activted_Polygon := PolygonList.First;
          UpdatePolyValueState;
          UpdatePolygonList;
          Renderer_Options_Memo.Lines.Clear;
          if renderer_options_stream <> nil then
            begin
              renderer_options_stream.Position := 0;
              try
                  Renderer_Options_Memo.Lines.LoadFromStream(renderer_options_stream, TEncoding.UTF8);
              except
                  Renderer_Options_Memo.Lines.LoadFromStream(renderer_options_stream);
              end;
            end;
          Update_Renderer_Options();
        end;
      drawPool(pb).PostScrollText(60, info_, 16, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.5));
      Show;
    end;
end;

procedure TPolygonToolMainForm.FormShow(Sender: TObject);
begin
  if Application.MainForm = Self then
      SwitchAsDefaultEditor();
end;

procedure TPolygonToolMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  if Application.MainForm = Self then
      ClosePolygonToolInstance(Self);
end;

procedure TPolygonToolMainForm.fpsTimerTimer(Sender: TObject);
begin
  if Application.MainForm = Self then
    begin
      Check_Soft_Thread_Synchronize(0);
      EnginePool.Progress;
    end;
  Invalidate;
end;

procedure TPolygonToolMainForm.AddGeoButtonClick(Sender: TObject);
var
  poly: TDeflectionPolygon;
begin
  poly := TDeflectionPolygon.Create;
  poly.Classifier := 'Default';
  poly.Name := PolygonList.MakePolygonName('polygon');
  if backgroundTexture <> nil then
      poly.Position := backgroundTexture.Centre
  else
      poly.Position := Activted_Polygon.Position;
  poly.Angle := 0;
  poly.Scale := 1.0;
  PolygonList.Add(poly);

  Activted_Polygon := poly;
  UpdatePolygonList;
  UpdatePolyValueState;
  Update_Renderer_Options();
end;

procedure TPolygonToolMainForm.CompileDataButtonClick(Sender: TObject);
var
  i, j: Integer;
  poly: TDeflectionPolygon;
  v: TVec2;
begin
  LogForm.Show;
  LogForm.Memo.Lines.Clear;
  DoStatusNoLn;
  for j := 0 to PolygonList.Count - 1 do
    begin
      poly := PolygonList[j];
      DoStatusNoLn(poly.Name + ' ' + #39);
      for i := 0 to poly.Count - 1 do
        begin
          v := poly.Points[i];
          if i > 0 then
              DoStatusNoLn(',');
          DoStatusNoLn('%d,%d', [Round(v[0]), Round(v[1])]);
        end;
      DoStatusNoLn(#39);
      DoStatusNoLn();
    end;
end;

procedure TPolygonToolMainForm.BuildCodeButtonClick(Sender: TObject);
var
  m64: TMS64;
  buff, codeText: TPascalString;
begin
  m64 := TMS64.Create;
  PolygonList.SaveToStream(m64);
  umlEncodeStreamBASE64(m64, buff);
  codeText := umlDivisionBase64Text(buff, 96, True);
  LogForm.Show;
  LogForm.Memo.Lines.Clear;
  DoStatus('// ----------------------------------------------');
  DoStatus('// base64 data source ---------------------------');
  DoStatus('const data = ' + codeText + ';');
  DoStatus('// ----------------------------------------------');
  disposeObject(m64);
  DoStatus('// usage demo');
  DoStatus('(*');
  DoStatus(
    'program PolygonDemo;'#13#10 +
      #13#10 +
      'uses Z.Core, Z.Geometry2D;'#13#10 +
      #13#10 +
      'const data = ' + codeText + ';'#13#10 +
      #13#10 +
      'procedure demo;'#13#10 +
      'var'#13#10 +
      '  polygon: TDeflectionPolygonList;'#13#10 +
      'begin'#13#10 +
      '  polygon:= TDeflectionPolygonList.Create;'#13#10 +
      '  polygon.LoadFromBase64(data);'#13#10 +
      '  DisposeObject(polygon);'#13#10 +
      'end;'#13#10 +
      #13#10 +
      'begin'#13#10 +
      '  demo;'#13#10 +
      'end.'#13#10);
  DoStatus('*)');
end;

procedure TPolygonToolMainForm.DelGeoButtonClick(Sender: TObject);
var
  idx: Integer;
begin
  if PolygonList.Count <= 1 then
      exit;
  idx := PolygonList.IndexOf(Activted_Polygon);
  PolygonList.Remove(Activted_Polygon);
  while (idx >= PolygonList.Count) do
      dec(idx);
  Activted_Polygon := PolygonList[idx];
  UpdatePolygonList;
  UpdatePolyValueState;
  Update_Renderer_Options();
end;

procedure TPolygonToolMainForm.Return_ButtonClick(Sender: TObject);
begin
  if assigned(On_Result) then
      On_Result(PolygonList);
  Close;
end;

procedure TPolygonToolMainForm.NewProjButtonClick(Sender: TObject);
begin
  Renderer_Options_Memo.Lines.Clear;
  Reset(True);
end;

procedure TPolygonToolMainForm.OpenProjButtonClick(Sender: TObject);
var
  m64: TMS64;
begin
  if not OpenDialog.Execute then
      exit;

  Reset(False);
  LastOpenFile := OpenDialog.FileName;
  m64 := TMS64.Create;
  m64.LoadFromFile(LastOpenFile);
  m64.Position := 0;
  PolygonList.LoadFromStream(m64);
  backgroundTexture.SetSizeR(PolygonList.BoundBox);
  FillBlackGrayBackgroundTexture(backgroundTexture, 64);
  disposeObject(m64);

  if PolygonList.Count = 0 then
    begin
      Activted_Polygon := TDeflectionPolygon.Create;
      Activted_Polygon.Name := PolygonList.MakePolygonName('polygon');
      Activted_Polygon.Classifier := 'Default';
      PolygonList.Add(Activted_Polygon);
    end
  else
      Activted_Polygon := PolygonList.First;
  UpdatePolyValueState;
  UpdatePolygonList;

  if umlFileExists(umlChangeFileExt(LastOpenFile, '.polyrender')) then
    begin
      try
          Renderer_Options_Memo.Lines.LoadFromFile(umlChangeFileExt(LastOpenFile, '.polyrender'), TEncoding.UTF8);
      except
          Renderer_Options_Memo.Lines.LoadFromFile(umlChangeFileExt(LastOpenFile, '.polyrender'));
      end;
    end;
  Update_Renderer_Options;
  Apply_Renderer_Options_ButtonClick(nil);
end;

procedure TPolygonToolMainForm.SaveProjAsButtonClick(Sender: TObject);
var
  m64: TMS64;
begin
  if not SaveDialog.Execute then
      exit;
  LastOpenFile := SaveDialog.FileName;

  PolygonList.BackgroundBox := backgroundTexture.BoundsRectV2;
  m64 := TMS64.Create;
  PolygonList.SaveToStream(m64);
  m64.SaveToFile(LastOpenFile);
  disposeObject(m64);
  Update_Renderer_Options;
  PolygonList.SaveRendererConfigure(umlChangeFileExt(LastOpenFile, '.polyrender'));
end;

procedure TPolygonToolMainForm.SaveProjButtonClick(Sender: TObject);
var
  m64: TMS64;
begin
  if LastOpenFile.Len = 0 then
    begin
      if not SaveDialog.Execute then
          exit;
      LastOpenFile := SaveDialog.FileName;
    end;

  PolygonList.BackgroundBox := backgroundTexture.BoundsRectV2;
  m64 := TMS64.Create;
  PolygonList.SaveToStream(m64);
  m64.SaveToFile(LastOpenFile);
  disposeObject(m64);
  Update_Renderer_Options;
  PolygonList.SaveRendererConfigure(umlChangeFileExt(LastOpenFile, '.polyrender'));
end;

procedure TPolygonToolMainForm.ListBoxItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
  if Item.IsSelected then
    begin
      Activted_Polygon := TDeflectionPolygon(Item.TagObject);
      UpdatePolyValueState;
    end;
end;

procedure TPolygonToolMainForm.pbPaint(Sender: TObject; Canvas: TCanvas);
var
  d: TDrawEngine;
  i: Integer;
  smPT: TVec2;
  n: U_String;
  arryBuff: TArrayVec2;
  p1, p2, p3, rot_dest, siz: TVec2;
  pi1, pi2: Integer;
  rgb: TDEColor;
begin
  if mpegReader <> nil then
    begin
      while not mpegReader.ReadFrame(backgroundTexture, False) do
        begin
          mpegReader.Seek(0);
          break;
        end;
      TDETexture(backgroundTexture).ReleaseGPUMemory;
    end;

  PolygonList.BackgroundBox := backgroundTexture.BoundsRectV2;

  dIntf.SetSurface(Canvas, Sender);
  d := drawPool(Sender, dIntf);
  d.ViewOptions := [voFPS, voEdge];
  d.ScreenFrameColor := DEColor(1, 1, 1, 1);

  d.FillBox(d.ScreenRect);

  rgb := DEColor(1, 1, 1);

  if not backgroundTexture.Empty then
      d.DrawPictureInScene(backgroundTexture, backgroundTexture.BoundsRectV2, backgroundTexture.BoundsRectV2, 1.0);

  d.DrawBox(d.SceneToScreen(backgroundTexture.BoundsRectV2), DEColor(rgb, 0.5), 2);

  smPT := d.ScreenToScene(move_pt);

  if not EditingCheckBox.IsChecked then
    begin
      PolygonList.Render(d, PolygonList.BackgroundBox, True);
    end
  else
    begin
      // draw polygon group
      for i := 0 to PolygonList.Count - 1 do
        if PolygonList[i] <> Activted_Polygon then
          begin
            arryBuff := PolygonList[i].BuildArray();
            if ShowPolygonCheckBox.IsChecked then
                d.DrawArrayLineInScene(arryBuff, True, DEColorInv(DEColor(rgb, 0.8)), 2);
            SetLength(arryBuff, 0);
          end;

      // draw picked line
      for i := 1 to Activted_Polygon.Count - 1 do
        begin
          p1 := Activted_Polygon.Points[i - 1];
          p2 := Activted_Polygon.Points[i];
          if (not(ssCtrl in shift_state))
            and (Vec2Distance(d.SceneToScreen(smPT), d.SceneToScreen(ClosestPointOnSegmentFromPoint(p1, p2, smPT))) < polygonViewer_Radius) then
              d.DrawLine(d.SceneToScreen(p1), d.SceneToScreen(p2), DEColor(rgb, 0.8), 2 + 4)
          else
            if ShowPolygonCheckBox.IsChecked then
              d.DrawLine(d.SceneToScreen(p1), d.SceneToScreen(p2), DEColor(rgb, 0.8), 2);
        end;

      // draw picked line
      if (Activted_Polygon.Count > 1) then
        begin
          p1 := Activted_Polygon.Points[0];
          p2 := Activted_Polygon.Points[Activted_Polygon.Count - 1];
          if (not(ssCtrl in shift_state))
            and (Vec2Distance(d.SceneToScreen(smPT), d.SceneToScreen(ClosestPointOnSegmentFromPoint(p1, p2, smPT))) < polygonViewer_Radius) then
              d.DrawLine(d.SceneToScreen(p1), d.SceneToScreen(p2), DEColor(rgb, 0.8), 2 + 4)
          else
            if ShowPolygonCheckBox.IsChecked then
              d.DrawDotLine(d.SceneToScreen(p1), d.SceneToScreen(p2), DEColor(rgb, 0.5), 2);
        end;

      // draw picked vertex
      if (not(ssCtrl in shift_state)) then
        for i := 0 to Activted_Polygon.Count - 1 do
          begin
            if ShowCoordinateCheckBox.IsChecked then
                d.DrawEllipse(d.SceneToScreen(Activted_Polygon.Points[i]), polygonViewer_Radius, DEColor(rgb, 0.8), 2);
            if Vec2Distance(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.Points[i])) < polygonViewer_Radius then
                d.DrawEllipse(d.SceneToScreen(Activted_Polygon.Points[i]), polygonViewer_Radius + 3, DEColor(rgb, 0.8), 2);
          end;

      // polygon offset and scale
      d.FillEllipse(d.SceneToScreen(Activted_Polygon.Position), polygonViewer_Radius, DEColor(rgb, 1.0));
      if Vec2Distance(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.Position)) < polygonViewer_Radius then
          d.DrawEllipse(d.SceneToScreen(Activted_Polygon.Position), polygonViewer_Radius + 3, DEColor(rgb, 1.0), 2);
      rot_dest := PointRotation(d.SceneToScreen(Activted_Polygon.Position), polygonViewer_Rotation_distance, Activted_Polygon.Angle);
      d.DrawDotLine(d.SceneToScreen(Activted_Polygon.Position), rot_dest, DEColor(rgb, 1.0), 1);
      d.DrawEllipse(rot_dest, polygonViewer_Radius, DEColor(rgb, 0.5), 2);
      if Vec2Distance(d.SceneToScreen(smPT), rot_dest) < polygonViewer_Radius then
          d.DrawEllipse(rot_dest, polygonViewer_Radius + 3, DEColor(rgb, 1.0), 2);

      n := PFormat('x:|color(1,0.5,0.5,1)|%f|| y:|color(1,0.5,0.5,1)|%f|| angle:|color(1,0.5,0.5,1)|%f|| scale:|color(1,0.5,0.5,1)|%f',
        [Activted_Polygon.Position[0], Activted_Polygon.Position[1], Activted_Polygon.Angle, Activted_Polygon.Scale]);
      siz := d.GetTextSize(n, 12);
      d.DrawText(rot_dest, d.SceneToScreen(Activted_Polygon.Position), n, 12, DEColor(rgb, 1.0));

      // auto hit for insert
      if (Vec2Distance(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.Position)) > polygonViewer_Radius) and
        (Vec2Distance(d.SceneToScreen(smPT), rot_dest) > polygonViewer_Radius) then
        if (not(ssCtrl in shift_state)) and (ssShift in shift_state) and (not down) then
          begin
            p3 := Activted_Polygon.GetNearLine(smPT, True, pi1, pi2);
            if pi1 >= 0 then
                d.DrawDotLine(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.Points[pi1]), DEColor(rgb, 0.5), 2);
            if pi2 >= 0 then
                d.DrawDotLine(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.Points[pi2]), DEColor(rgb, 0.5), 2);
            d.DrawEllipse(d.SceneToScreen(smPT), polygonViewer_Radius, DEColor(rgb, 0.5), 2);
          end;

      // auto hit for append
      if (ssCtrl in shift_state) and (Activted_Polygon.Count > 0) then
        begin
          d.DrawDotLine(d.SceneToScreen(smPT), d.SceneToScreen(Activted_Polygon.LastPoint), DEColor(rgb, 0.5), 2);
          d.DrawEllipse(d.SceneToScreen(smPT), polygonViewer_Radius, DEColor(rgb, 0.5), 2);
        end;
    end;
  d.Flush;
end;

procedure TPolygonToolMainForm.pbMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  d: TDrawEngine;
  i: Integer;
  sPT: TVec2; // scene coordinate
begin
  down_pt := Vec2(X, Y);
  move_pt := down_pt;
  up_pt := move_pt;
  down := True;
  if EditingCheckBox.IsChecked then
      down_btn := Button
  else
      down_btn := TMouseButton.mbRight;
  shift_state := Shift;

  d := drawPool(Sender);
  sPT := d.ScreenToScene(down_pt);
  pt_pick_idx := -1;
  l_pick_idx1 := -1;
  l_pick_idx2 := -1;
  poly_pos_pick := False;
  poly_rotate_dest_pick := False;

  if (down_btn = TMouseButton.mbLeft) and (not(ssCtrl in shift_state)) then
    begin
      if Vec2Distance(d.SceneToScreen(sPT), d.SceneToScreen(Activted_Polygon.Position)) < polygonViewer_Radius then
          poly_pos_pick := True
      else if Vec2Distance(d.SceneToScreen(sPT), PointRotation(d.SceneToScreen(Activted_Polygon.Position), polygonViewer_Rotation_distance, Activted_Polygon.Angle)) < polygonViewer_Radius then
          poly_rotate_dest_pick := True
      else if (not(ssShift in shift_state)) then
        begin
          for i := 0 to Activted_Polygon.Count - 1 do
            begin
              if Vec2Distance(d.SceneToScreen(sPT), d.SceneToScreen(Activted_Polygon.Points[i])) < polygonViewer_Radius then
                begin
                  pt_pick_idx := i;
                  break;
                end;
            end;
          if pt_pick_idx < 0 then
            if Vec2Distance(d.SceneToScreen(sPT), d.SceneToScreen(Activted_Polygon.GetNearLine(sPT, True, l_pick_idx1, l_pick_idx2))) > polygonViewer_Radius then
              begin
                l_pick_idx1 := -1;
                l_pick_idx2 := -1;
              end;
        end;
    end;
end;

procedure TPolygonToolMainForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  d: TDrawEngine;
  sPT, pt: TVec2;
begin
  d := drawPool(Sender);
  sPT := d.ScreenToScene(Vec2(X, Y));
  shift_state := Shift;

  if down then
    begin
      if (down_btn = TMouseButton.mbLeft) then
        begin
          pt := Vec2Sub(sPT, d.ScreenToScene(move_pt));

          if poly_pos_pick then
            begin
              if ssShift in shift_state then
                  Activted_Polygon.Rebuild(
                  Activted_Polygon.Scale,
                  Activted_Polygon.Angle,
                  Activted_Polygon.ExpandMode,
                  Vec2Add(Activted_Polygon.Position, pt))
              else
                  Activted_Polygon.Position := Vec2Add(Activted_Polygon.Position, pt);
              UpdatePolyValueState;
            end
          else if poly_rotate_dest_pick then
            begin
              polygonViewer_Rotation_distance := Clamp(PointDistance(d.SceneToScreen(Activted_Polygon.Position), d.SceneToScreen(sPT)), 50, 500);
              if ssShift in shift_state then
                  Activted_Polygon.Rebuild(
                  Activted_Polygon.Scale,
                  PointAngle(d.SceneToScreen(Activted_Polygon.Position), d.SceneToScreen(sPT)),
                  Activted_Polygon.ExpandMode,
                  Activted_Polygon.Position)
              else
                  Activted_Polygon.Angle := PointAngle(d.SceneToScreen(Activted_Polygon.Position), d.SceneToScreen(sPT));
              UpdatePolyValueState;
            end
          else if (l_pick_idx1 >= 0) and (l_pick_idx2 >= 0) then
            begin
              Activted_Polygon.Points[l_pick_idx1] := Vec2Add(Activted_Polygon.Points[l_pick_idx1], pt);
              Activted_Polygon.Points[l_pick_idx2] := Vec2Add(Activted_Polygon.Points[l_pick_idx2], pt);
            end
          else if pt_pick_idx >= 0 then
            begin
              Activted_Polygon.Points[pt_pick_idx] := Vec2Add(Activted_Polygon.Points[pt_pick_idx], pt);
            end;
        end
      else if (down_btn = TMouseButton.mbRight) then
        begin
          d.Offset := Vec2Add(d.Offset, Vec2Sub(Vec2(X, Y), move_pt));
        end;
    end;

  move_pt := Vec2(X, Y);
  up_pt := move_pt;
end;

procedure TPolygonToolMainForm.pbMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  d: TDrawEngine;
  pi1, pi2: Integer;
  sPT, pt: TVec2;
begin
  d := drawPool(Sender);
  sPT := d.ScreenToScene(Vec2(X, Y));
  shift_state := Shift;

  if down and (down_btn = TMouseButton.mbLeft)
    and (pt_pick_idx < 0) and (l_pick_idx1 < 0) and (l_pick_idx2 < 0)
    and (not poly_pos_pick) and (not poly_rotate_dest_pick) then
    begin
      if ssShift in shift_state then
        begin
          pt := Activted_Polygon.GetNearLine(sPT, True, pi1, pi2);
          if pi2 >= 0 then
              Activted_Polygon.InsertPoint(pi2, sPT);
        end
      else
          Activted_Polygon.AddPoint(sPT);
    end;

  down := False;
  up_pt := Vec2(X, Y);
end;

procedure TPolygonToolMainForm.pbMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
var
  v: TGeoFloat;
begin
  if ssCtrl in Shift then
    begin
      if WheelDelta > 0 then
          Activted_Polygon.Scale := Activted_Polygon.Scale * 1.1
      else
          Activted_Polygon.Scale := Activted_Polygon.Scale * 0.9;
      UpdatePolyValueState;
    end
  else
    begin
      if ssShift in Shift then
          v := 0.5
      else
          v := 0.1;

      with drawPool(pb) do
        if WheelDelta > 0 then
            ScaleCamera(1.1)
        else
            ScaleCamera(0.9);
    end;

  Handled := True;
end;

procedure TPolygonToolMainForm.PolyOptChange(Sender: TObject);
var
  v: TVec2;
  a: TGeoFloat;
  s: TGeoFloat;
begin
  if DisableEditEvent then
      exit;

  v[0] := umlStrToFloat(XEdit.Text);
  v[1] := umlStrToFloat(YEdit.Text);
  a := umlStrToFloat(AngleEdit.Text);
  s := umlStrToFloat(ScaleEdit.Text);

  if OwnerCheckBox.IsChecked then
    begin
      Activted_Polygon.Rebuild(s, a, Activted_Polygon.ExpandMode, v);
    end
  else
    begin
      Activted_Polygon.Position := v;
      Activted_Polygon.Angle := a;
      Activted_Polygon.Scale := s;
    end;
  Activted_Polygon.Name := '';
  Activted_Polygon.Name := PolygonList.MakePolygonName(NameEdit.Text);
  Activted_Polygon.Classifier := ClassifierEdit.Text;
  UpdatePolygonList;
  Update_Renderer_Options();
end;

procedure TPolygonToolMainForm.setPictureButtonClick(Sender: TObject);
begin
  OpenPictureDialog.Filter := TBitmapCodecManager.GetFilterString;
  if not OpenPictureDialog.Execute then
      exit;

  if mpegReader <> nil then
    begin
      disposeObject(mpegReader);
      mpegReader := nil;
    end;

  disposeObject(backgroundTexture);
  backgroundTexture := NewZRFromFile(OpenPictureDialog.FileName);
end;

procedure TPolygonToolMainForm.SetVideoButtonClick(Sender: TObject);
begin
  if not OpenVideoDialog.Execute then
      exit;

  if mpegReader <> nil then
    begin
      disposeObject(mpegReader);
      mpegReader := nil;
    end;

  mpegReader := TFFMPEG_Reader.Create(OpenVideoDialog.FileName, False);
end;

procedure TPolygonToolMainForm.SetURLButtonClick(Sender: TObject);
begin
  TDialogService.InputQuery('video URL', ['rtsp://host'], ['rtsp://user:password@host:port'],
      procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if AResult <> mrOk then
          exit;
      if mpegReader <> nil then
        begin
          disposeObject(mpegReader);
          mpegReader := nil;
        end;

      mpegReader := TFFMPEG_Reader.Create(AValues[0], False);
    end);
end;

constructor TPolygonToolMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  dIntf := TDrawEngineInterface_FMX.Create;
  PolygonList := TDeflectionPolygonListRenderer.Create;

  Activted_Polygon := TDeflectionPolygon.Create;
  Activted_Polygon.Name := PolygonList.MakePolygonName('polygon');
  PolygonList.Add(Activted_Polygon);
  UpdatePolygonList;

  backgroundTexture := nil;
  On_Result := nil;
  Reset(True);

  PolygonToolInstanceList.Add(Self);
end;

destructor TPolygonToolMainForm.Destroy;
begin
  PolygonToolInstanceList.Remove(Self);
  inherited Destroy;
end;

procedure TPolygonToolMainForm.Apply_Renderer_Options_ButtonClick(Sender: TObject);
begin
  Update_Renderer_Options();
  PolygonList.RendererConfigure.Clear;
  PolygonList.RendererConfigure.DataImport(Renderer_Options_Memo.Lines);
end;

procedure TPolygonToolMainForm.UpdatePolyValueState;
begin
  DisableEditEvent := True;

  XEdit.Text := FloatToStr(Activted_Polygon.Position[0]);
  YEdit.Text := FloatToStr(Activted_Polygon.Position[1]);
  AngleEdit.Text := FloatToStr(Activted_Polygon.Angle);
  ScaleEdit.Text := FloatToStr(Activted_Polygon.Scale);
  NameEdit.Text := Activted_Polygon.Name;
  ClassifierEdit.Text := Activted_Polygon.Classifier;

  DisableEditEvent := False;
end;

procedure TPolygonToolMainForm.Reset(reset_scene: Boolean);
var
  d: TDrawEngine;
begin
  if reset_scene then
    begin
      d := drawPool(pb);
      d.Scale := 1.0;
      d.Offset := Vec2(100, 100);
    end;

  PolygonList.Clear;
  Activted_Polygon := TDeflectionPolygon.Create;
  Activted_Polygon.Name := PolygonList.MakePolygonName('polygon');
  Activted_Polygon.Classifier := 'Default';
  PolygonList.Add(Activted_Polygon);
  UpdatePolygonList;

  pt_pick_idx := -1;
  l_pick_idx1 := -1;
  l_pick_idx2 := -1;
  poly_pos_pick := False;
  poly_rotate_dest_pick := False;
  down_pt := ZeroVec2;
  move_pt := ZeroVec2;
  up_pt := ZeroVec2;
  down := False;
  down_btn := TMouseButton.mbLeft;
  shift_state := [];
  polygonViewer_Radius := 10;
  DisableEditEvent := False;

  if reset_scene then
    begin
      polygonViewer_Rotation_distance := 50;
      if backgroundTexture <> nil then
          disposeObject(backgroundTexture);
      backgroundTexture := TDrawEngine.NewTexture;
      backgroundTexture.SetSize(800, 600);
      FillBlackGrayBackgroundTexture(backgroundTexture, 32);
      LastOpenFile := '';
      if mpegReader <> nil then
        begin
          disposeObject(mpegReader);
          mpegReader := nil;
        end;
    end;

  if backgroundTexture <> nil then
    begin
      Activted_Polygon.Position := backgroundTexture.Centroid;
      PolygonList.BackgroundBox := backgroundTexture.BoundsRectV2;
    end;

  UpdatePolyValueState;
  Update_Renderer_Options();
end;

procedure TPolygonToolMainForm.UpdatePolygonList;
  function ExistsPolygonFromListBox(polygon: TDeflectionPolygon): Boolean;
  var
    i: Integer;
  begin
    for i := 0 to ListBox.Count - 1 do
      if ListBox.ListItems[i].TagObject = polygon then
        begin
          Result := True;
          exit;
        end;
    Result := False;
  end;

  function ExistsPolygonFromPolygonList(polygon: TDeflectionPolygon): Boolean;
  begin
    Result := PolygonList.IndexOf(polygon) >= 0;
  end;

var
  i: Integer;
  li: TListBoxItem;
  poly: TDeflectionPolygon;
begin
  i := 0;
  while i < ListBox.Count do
    begin
      li := ListBox.ListItems[i];
      poly := TDeflectionPolygon(li.TagObject);
      if not ExistsPolygonFromPolygonList(poly) then
          disposeObject(li)
      else
        begin
          if not poly.Name.Same(poly.Classifier + ': ' + poly.Name) then
              li.Text := poly.Classifier + ': ' + poly.Name;
          inc(i);
        end;
    end;

  i := 0;
  while i < PolygonList.Count do
    begin
      poly := PolygonList[i];
      if not ExistsPolygonFromListBox(poly) then
        begin
          li := TListBoxItem.Create(ListBox);
          li.Parent := ListBox;
          li.Text := poly.Classifier + ': ' + poly.Name;
          li.TagObject := poly;
        end;
      inc(i);
    end;

  i := 0;
  while i < ListBox.Count do
    begin
      li := ListBox.ListItems[i];
      poly := TDeflectionPolygon(li.TagObject);
      if Activted_Polygon = poly then
          li.IsSelected := True;
      inc(i);
    end;
end;

procedure TPolygonToolMainForm.Update_Renderer_Options;
var
  te: TTextDataEngine;
  L: TPascalStringList;
  i: Integer;
begin
  te := TTextDataEngine.Create;
  te.DataImport(Renderer_Options_Memo.Lines);

  PolygonList.RebuildConfigure(True);
  L := TPascalStringList.Create;

  te.GetSectionList(L);
  for i := 0 to L.Count - 1 do
    if not PolygonList.RendererConfigure.Exists(L[i]) then
        te.Delete(L[i]);

  L.Clear;
  PolygonList.RendererConfigure.GetSectionList(L);
  for i := 0 to L.Count - 1 do
    if not te.Exists(L[i]) then
        te.Strings[L[i]].Assign(PolygonList.RendererConfigure.Strings[L[i]]);
  disposeObject(L);

  Renderer_Options_Memo.Lines.Clear;
  te.DataExport(Renderer_Options_Memo.Lines);
  PolygonList.RendererConfigure.Assign(te);
  disposeObject(te);
end;

procedure TPolygonToolMainForm.SwitchAsDefaultEditor;
begin
  Return_Button.Visible := False;
  NewProjButton.Visible := True;
  OpenProjButton.Visible := True;
  SaveProjButton.Visible := True;
  SaveProjAsButton.Visible := True;
  setPictureButton.Visible := True;
  SetVideoButton.Visible := True;
  SetURLButton.Visible := True;
  CompileDataButton.Visible := True;
end;

procedure TPolygonToolMainForm.SwitchAsGeometryEditor;
begin
  Return_Button.Visible := False;
  NewProjButton.Visible := False;
  OpenProjButton.Visible := False;
  SaveProjButton.Visible := False;
  SaveProjAsButton.Visible := False;
  setPictureButton.Visible := False;
  SetVideoButton.Visible := False;
  SetURLButton.Visible := False;
  CompileDataButton.Visible := True;
end;

procedure TPolygonToolMainForm.SwitchAsGeometry_Return_Mode_Editor;
begin
  Return_Button.Visible := True;
  NewProjButton.Visible := False;
  OpenProjButton.Visible := False;
  SaveProjButton.Visible := False;
  SaveProjAsButton.Visible := False;
  setPictureButton.Visible := False;
  SetVideoButton.Visible := False;
  SetURLButton.Visible := False;
  CompileDataButton.Visible := False;
end;

initialization

PolygonToolInstanceList := TPolygonToolInstanceList.Create;

finalization

DisposeObjectAndNil(PolygonToolInstanceList);

end.
