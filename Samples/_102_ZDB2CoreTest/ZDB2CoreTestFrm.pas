unit ZDB2CoreTestFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts, FMX.StdCtrls, FMX.Edit, FMX.Memo.Types,

  ZR.Core, ZR.PascalStrings, ZR.Status, ZR.UnicodeMixedLib, ZR.MemoryStream, ZR.Cipher,
  ZR.DrawEngine, ZR.DrawEngine.SlowFMX, ZR.Geometry2D, ZR.Expression,
  ZR.ZDB2, ZR.IOThread, ZR.MemoryRaster;

type
  TZDB2CoreTestForm = class(TForm)
    Memo: TMemo;
    pb: TPaintBox;
    Timer1: TTimer;
    write_Layout: TLayout;
    Label1: TLabel;
    write_size_Edit: TEdit;
    EditButton_write_: TEditButton;
    EditButton_fill_space: TEditButton;
    Button_Print_ID: TButton;
    remove_Layout: TLayout;
    Label2: TLabel;
    remove_Edit: TEdit;
    EditButton_remove: TEditButton;
    Button_reset: TButton;
    Button_query: TButton;
    Button_flush: TButton;
    procedure Button_Print_IDClick(Sender: TObject);
    procedure Button_resetClick(Sender: TObject);
    procedure Button_queryClick(Sender: TObject);
    procedure Button_flushClick(Sender: TObject);
    procedure EditButton_write_Click(Sender: TObject);
    procedure EditButton_fill_spaceClick(Sender: TObject);
    procedure EditButton_removeClick(Sender: TObject);
    procedure pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure pbPaint(Sender: TObject; Canvas: TCanvas);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure DoStatus_Bcakcall(Text_: SystemString; const ID: Integer);
  public
    bk: TZR;
    ZDB: TZDB2_Core_Space;
    dIntf: TDrawEngineInterface_FMX;
    mouse_pt: TVec2;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ZDB2CoreTestForm: TZDB2CoreTestForm;

implementation

{$R *.fmx}


constructor TZDB2CoreTestForm.Create(AOwner: TComponent);
var
  hnd: PIOHnd;
begin
  inherited Create(AOwner);
  AddDoStatusHook(Self, DoStatus_Bcakcall);
  dIntf := TDrawEngineInterface_FMX.Create;

  New(hnd);
  InitIOHnd(hnd^);
  umlFileCreateAsStream(TMS64.CustomCreate($FFFF), hnd^);
  ZDB := TZDB2_Core_Space.Create(hnd);
  hnd^.AutoFree := True;
  ZDB.AutoCloseIOHnd := True;
  ZDB.AutoFreeIOHnd := True;

  ZDB.BuildSpace(1024 * 1024 * 16, 8 * 1024);

  DoStatus('创建内存模拟zdb2数据库. 物理体积:%s 物理单元:%d', [umlSizeToStr(ZDB.State^.Physics).Text, ZDB.BlockCount]);

  bk := NewZR;
  bk.SetSize($FF, $FF);
  FillBlackGrayBackgroundTexture(bk, 64, RColorF(0.8, 0.8, 0.8), RColorF(0.9, 0.9, 0.9), RColorF(0.85, 0.85, 0.85));
end;

destructor TZDB2CoreTestForm.Destroy;
begin
  DisposeObject(dIntf);
  DisposeObject(ZDB);
  DisposeObject(bk);
  DeleteDoStatusHook(Self);
  inherited Destroy;
end;

procedure TZDB2CoreTestForm.Button_Print_IDClick(Sender: TObject);
var
  ID: TZDB2_BlockHandle;
  i, n: Integer;
begin
  ID := ZDB.BuildTableID;
  for i in ID do
    begin
      DoStatusNoLn('%d' + #9, [i]);
      inc(n);
      if n >= 10 then
        begin
          DoStatusNoLn(#13#10);
          n := 0;
        end;
    end;
  DoStatusNoLn();
end;

procedure TZDB2CoreTestForm.Button_resetClick(Sender: TObject);
var
  hnd: PIOHnd;
begin
  ZDB.Free;

  New(hnd);
  InitIOHnd(hnd^);
  umlFileCreateAsStream(TMS64.CustomCreate($FFFF), hnd^);
  ZDB := TZDB2_Core_Space.Create(hnd);
  hnd^.AutoFree := True;
  ZDB.AutoCloseIOHnd := True;
  ZDB.AutoFreeIOHnd := True;

  ZDB.BuildSpace(1024 * 1024 * 16, 8 * 1024);
  DoStatus('创建内存模拟zdb2数据库. 物理体积:%s 物理单元:%d', [umlSizeToStr(ZDB.State^.Physics).Text, ZDB.BlockCount]);
end;

procedure TZDB2CoreTestForm.Button_queryClick(Sender: TObject);
var
  ID: TZDB2_BlockHandle;
  i: Integer;
  n: TZDB2_Mem;
begin
  ID := ZDB.BuildTableID;
  for i in ID do
    begin
      n := TZDB2_Mem.Create;
      ZDB.ReadData(n, i);
      DoStatus('条目:%d md5:%s crc32:%8x', [i, umlMD5String(n.Memory, n.Size).UpperText, umlCRC32(n.Memory, n.Size)]);
      n.Free;
    end;
end;

procedure TZDB2CoreTestForm.Button_flushClick(Sender: TObject);
begin
  ZDB.Save;
end;

procedure TZDB2CoreTestForm.DoStatus_Bcakcall(Text_: SystemString; const ID: Integer);
begin
  Memo.Lines.Add(Text_);
  Memo.GoToTextEnd;
end;

procedure TZDB2CoreTestForm.EditButton_write_Click(Sender: TObject);
var
  Mem: TZDB2_Mem;
  ID: Integer;
begin
  Mem := TZDB2_Mem.Create;
  Mem.Size := EStrToInt(write_size_Edit.Text, 1024);
  ZDB.WriteData(Mem, ID, False);
  Mem.Free;
end;

procedure TZDB2CoreTestForm.EditButton_fill_spaceClick(Sender: TObject);
var
  Mem: TZDB2_Mem;
  ID: Integer;
begin
  Mem := TZDB2_Mem.Create;
  Mem.Size := umlRandomRange(8000, 1024 * 1024);
  if ZDB.WriteData(Mem, ID) then
    begin
      DoStatus('写入成功 ID:%d 大小:%d', [ID, ZDB.GetDataSize(ID)]);
      EditButton_fill_spaceClick(Sender);
    end;
  Mem.Free;
end;

procedure TZDB2CoreTestForm.EditButton_removeClick(Sender: TObject);
var
  ID: Integer;
begin
  ID := EStrToInt(remove_Edit.Text, -1);
  if ZDB.RemoveData(ID, True) then
      DoStatus('删除成功 ID:%d', [ID])
  else
      DoStatus('删除错误 ID:%d', [ID]);
end;

procedure TZDB2CoreTestForm.pbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  mouse_pt := vec2(X, Y);
end;

procedure TZDB2CoreTestForm.pbPaint(Sender: TObject; Canvas: TCanvas);
const
  c_Metric = 10; // 呈现器度量单位
  c_Edge = 2;    // 呈现器边缘尺度
var
  d: TDrawEngine;
  f, i, j, num: Integer;
  X, Y: TGeoFloat;
  box, r: TRectV2;
  p: PZDB2_Block;
  hndID: Integer;
  State: PZDB2_Core_SpaceState;
  n: U_String;
begin
  Canvas.Font.Style := [TFontStyle.fsBold];
  dIntf.SetSurface(Canvas, Sender);
  d := DrawPool(Sender, dIntf);

  d.DrawTile(bk);

  // d.FillBox(d.ScreenRect, DEColor(0, 0, 0, 1));

  // 将并行处理数据画出来
  f := round(sqrt(ZDB.BlockCount)); // 以平方根方式切割预览数据
  num := 0;
  X := 0;
  Y := 0;
  box := RectV2(X, Y, X, Y);
  p := nil;
  hndID := -1;
  for j := 0 to f do
    begin
      for i := 0 to f do
        begin
          r := RectV2(X, Y, X + c_Metric, Y + c_Metric);
          if num < ZDB.BlockCount then
            begin
              if Vec2InRect(mouse_pt, d.SceneToScreen(r)) then
                begin
                  p := @ZDB.BlockBuffer[num];
                  hndID := ZDB.GetSpaceHndID(p^.ID);
                end;
            end;

          X := X + c_Metric + c_Edge;
          inc(num);
          box := BoundRect(box, r);
        end;
      Y := Y + c_Metric + c_Edge;
      X := 0;
    end;

  num := 0;
  X := 0;
  Y := 0;
  box := RectV2(X, Y, X, Y);
  for j := 0 to f do
    begin
      for i := 0 to f do
        begin
          r := RectV2(X, Y, X + c_Metric, Y + c_Metric);
          if num < ZDB.BlockCount then
            with ZDB.BlockBuffer[num] do
              begin
                if UsedSpace = Size then
                    d.FillBoxInScene(r, DEColor(1, 0, 0, 1))
                else if UsedSpace > 0 then
                    d.FillBoxInScene(r, DEColor(1, 0.5, 0.5, 1))
                else
                    d.FillBoxInScene(r, DEColor(0.5, 0.5, 0.5, 1));
              end;

          X := X + c_Metric + c_Edge;
          inc(num);
          box := BoundRect(box, r);
        end;
      Y := Y + c_Metric + c_Edge;
      X := 0;
    end;

  if hndID >= 0 then
    begin
      num := 0;
      X := 0;
      Y := 0;
      box := RectV2(X, Y, X, Y);
      for j := 0 to f do
        begin
          for i := 0 to f do
            begin
              r := RectV2(X, Y, X + c_Metric, Y + c_Metric);
              if num < ZDB.BlockCount then
                with ZDB.BlockBuffer[num] do
                  begin
                    if (UsedSpace > 0) and (ZDB.GetSpaceHndID(ID) = hndID) then
                        d.DrawBox(d.SceneToScreen(r), DEColor(1, 1, 1), 2);
                  end;

              X := X + c_Metric + c_Edge;
              inc(num);
              box := BoundRect(box, r);
            end;
          Y := Y + c_Metric + c_Edge;
          X := 0;
        end;
    end;

  d.CameraR := rectEdge(box, 50);

  if (p <> nil) and (hndID >= 0) then
    begin
      n := Format('数据尺寸:%d 物理尺寸:%d ID:%d',
        [ZDB.GetDataSize(hndID), ZDB.GetDataPhysics(hndID), hndID]);

      n := TDrawEngine.RebuildNumAndWordColor(n, '|color(0.8,1,0.8)|', '||', [], []);
      d.BeginCaptureShadow(vec2(1, 1), 0.9);
      d.Draw_BK_Text(n, 14, DEColor(1, 1, 1), DEColor(0, 0, 0, 0.9), Vec2Add(mouse_pt, vec2(15, 0)));
      d.EndCaptureShadow;
    end;

  with ZDB.State^ do
    begin
      n := Format('数据条目:%d 数据库尺寸:%s 自由空间:%s 缓存:%s 读取统计:%d 读取流量:%s 写入次数统计:%d 写入流量:%s',
        [ZDB.BlockCount,
          umlSizeToStr(Physics).Text,
          umlSizeToStr(FreeSpace).Text,
          umlSizeToStr(Cache).Text,
          ReadNum, umlSizeToStr(ReadSize).Text,
          WriteNum, umlSizeToStr(WriteSize).Text]);

      n := TDrawEngine.RebuildNumAndWordColor(n, '|color(0,1,0)|', '||', [], []);
      d.Draw_BK_Text(n, 12, d.ScreenRect, DEColor(1, 1, 1, 1), DEColor(0, 0, 0, 0.9), False);
    end;
  d.Flush;
end;

procedure TZDB2CoreTestForm.Timer1Timer(Sender: TObject);
begin
  DrawPool.Progress();
  ZR.Core.CheckThreadSynchronize;
  Invalidate;
end;

end.
