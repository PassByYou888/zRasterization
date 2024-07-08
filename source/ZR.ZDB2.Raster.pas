{ ****************************************************************************** }
{ * ZDB 2.0 automated fragment for rasterization support                       * }
{ ****************************************************************************** }
unit ZR.ZDB2.Raster;

{$DEFINE FPC_DELPHI_MODE}
{$I ZR.Define.inc}

interface

uses ZR.Core,
{$IFDEF FPC}
  ZR.FPC.GenericList,
{$ENDIF FPC}
  ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Status, ZR.MemoryStream,
  ZR.DFE, ZR.ZDB2, ZR.Cipher, ZR.MemoryRaster;

type
  TZDB2_List_Raster = class;
  TZDB2_Raster = class;
  TZDB2_Big_List_Raster_Decl__ = TZR_BL<TZDB2_Raster>;

  TZDB2_Raster = class(TCore_Object_Intermediate)
  private
    FPool_Ptr: TZDB2_Big_List_Raster_Decl__.PQueueStruct;
    FTimeOut: TTimeTick;
    FAlive: TTimeTick;
    FID: Integer;
    FData: TZR;
    FRasterFormat: TZRSaveFormat;
    FIsChanged: Boolean;
  public
    CoreSpace: TZDB2_Core_Space;
    Keep: Integer;
    constructor Create(CoreSpace_: TZDB2_Core_Space; ID_: Integer); virtual;
    destructor Destroy; override;
    procedure Progress; virtual;
    procedure Load;
    procedure Flush;
    procedure RecycleMemory;
    procedure Remove;
    function GetData: TZR;
    property Data: TZR read GetData;
    property Data_Direct: TZR read FData;
    property ID: Integer read FID;
    property RasterFormat: TZRSaveFormat read FRasterFormat write FRasterFormat;
    // must be manually IsChanged in program
    property IsChanged: Boolean read FIsChanged write FIsChanged;
  end;

  TZDB2_Raster_Class = class of TZDB2_Raster;

  TOnCreate_ZDB2_Raster = procedure(Sender: TZDB2_List_Raster; Obj: TZDB2_Raster) of object;

  TZDB2_List_Raster = class(TCore_Object_Intermediate)
  private
    procedure DoNoSpace(Trigger: TZDB2_Core_Space; Siz_: Int64; var retry: Boolean);
    function GetAutoFreeStream: Boolean;
    procedure SetAutoFreeStream(const Value: Boolean);
    procedure Do_Free(var obj_: TZDB2_Raster);
  public
    List: TZDB2_Big_List_Raster_Decl__;
    Raster_Class: TZDB2_Raster_Class;
    TimeOut: TTimeTick;
    DeltaSpace: Int64;
    BlockSize: Word;
    IOHnd: TIOHnd;
    CoreSpace: TZDB2_Core_Space;
    OnCreateClass: TOnCreate_ZDB2_Raster;
    constructor Create(Raster_Class_: TZDB2_Raster_Class; OnCreateClass_: TOnCreate_ZDB2_Raster; TimeOut_: TTimeTick;
      Stream_: TCore_Stream; OnlyRead_: Boolean; DeltaSpace_: Int64; BlockSize_: Word; Cipher_: IZDB2_Cipher);
    destructor Destroy; override;
    property AutoFreeStream: Boolean read GetAutoFreeStream write SetAutoFreeStream;
    property IsOnlyRead: Boolean read IOHnd.IsOnlyRead;
    procedure Remove(Obj: TZDB2_Raster; RemoveData_: Boolean);
    procedure Clear;
    function NewDataFrom(ID_: Integer): TZDB2_Raster; overload;
    function NewData: TZDB2_Raster; overload;
    procedure Flush(flush_core_space: Boolean); overload;
    procedure Flush; overload;
    procedure ExtractTo(Stream_: TCore_Stream);
    procedure Progress;
    procedure Push_To_Recycle_Pool(obj_: TZDB2_Raster; RemoveData_: Boolean); // remove from repeat
    procedure Free_Recycle_Pool; // remove from repeat
    function Count: NativeInt;
    function Repeat_: TZDB2_Big_List_Raster_Decl__.TRepeat___; // flow simulate
    function Invert_Repeat_: TZDB2_Big_List_Raster_Decl__.TInvert_Repeat___; // flow simulate

    class procedure Test;
  end;

implementation

uses ZR.ZDB2.Thread.Queue;

constructor TZDB2_Raster.Create(CoreSpace_: TZDB2_Core_Space; ID_: Integer);
begin
  inherited Create;
  FPool_Ptr := nil;
  FTimeOut := 5 * 1000;
  FAlive := GetTimeTick;
  Keep := 0;
  FID := ID_;
  CoreSpace := CoreSpace_;
  FData := nil;
  FRasterFormat := TZRSaveFormat.rsRGB;
  FIsChanged := False;
end;

destructor TZDB2_Raster.Destroy;
begin
  Flush;
  inherited Destroy;
end;

procedure TZDB2_Raster.Progress;
begin
  if FData = nil then
      exit;
  if (Keep <= 0) and (GetTimeTick - FAlive > FTimeOut) then
    begin
      Flush;
{$IFDEF SHOW_ZDB2_Data_Free_LOG}
      DoStatus('%s -> %s Space Recycle ID %s size:%d', [UnitName, ClassName, CoreSpace.GetSpaceHndAsText(FID).Text, CoreSpace.GetDataSize(FID)]);
{$ENDIF SHOW_ZDB2_Data_Free_LOG}
    end;
end;

procedure TZDB2_Raster.Load;
var
  m64: TZDB2_Mem;
begin
  if FID < 0 then
      exit;
  m64 := TZDB2_Mem.Create;

  if CoreSpace.ReadData(m64, FID) then
    begin
      try
        FData.LoadFromStream(m64.Stream64);
        FIsChanged := False;
      except
        FID := -1;
        FData.Clear;
      end;
    end
  else
      FData.Clear;

  DisposeObject(m64);
end;

procedure TZDB2_Raster.Flush;
var
  m64: TMS64;
  old_ID: Integer;
begin
  if FData = nil then
      exit;
  if not CoreSpace.Space_IOHnd^.IsOnlyRead then
    begin
      m64 := TMS64.Create;
      try
        FData.SaveToStream(m64, FRasterFormat);
        if FIsChanged or (FID < 0) then
          begin
            old_ID := FID;
            CoreSpace.WriteData(m64.Mem64, FID, False);
            if old_ID >= 0 then
                CoreSpace.RemoveData(old_ID, False);
          end;
      except
      end;
      DisposeObject(m64);
    end;
  DisposeObjectAndNil(FData);
end;

procedure TZDB2_Raster.RecycleMemory;
begin
  DisposeObjectAndNil(FData);
end;

procedure TZDB2_Raster.Remove;
begin
  if CoreSpace.Space_IOHnd^.IsOnlyRead then
      exit;
  if FID >= 0 then
      CoreSpace.RemoveData(FID, False);
  DisposeObjectAndNil(FData);
  FID := -1;
end;

function TZDB2_Raster.GetData: TZR;
begin
  if FData = nil then
    begin
      FData := NewZR();
      Load;
    end;
  Result := FData;
  FAlive := GetTimeTick;
end;

procedure TZDB2_List_Raster.DoNoSpace(Trigger: TZDB2_Core_Space; Siz_: Int64; var retry: Boolean);
begin
  retry := Trigger.Fast_AppendSpace(DeltaSpace, BlockSize);
end;

function TZDB2_List_Raster.GetAutoFreeStream: Boolean;
begin
  Result := IOHnd.AutoFree;
end;

procedure TZDB2_List_Raster.SetAutoFreeStream(const Value: Boolean);
begin
  IOHnd.AutoFree := Value;
end;

procedure TZDB2_List_Raster.Do_Free(var obj_: TZDB2_Raster);
begin
  DisposeObjectAndNil(obj_);
end;

constructor TZDB2_List_Raster.Create(Raster_Class_: TZDB2_Raster_Class; OnCreateClass_: TOnCreate_ZDB2_Raster; TimeOut_: TTimeTick;
  Stream_: TCore_Stream; OnlyRead_: Boolean; DeltaSpace_: Int64; BlockSize_: Word; Cipher_: IZDB2_Cipher);
var
  buff: TZDB2_BlockHandle;
  ID_: Integer;
  m64: TMem64;
begin
  inherited Create;
  List := TZDB2_Big_List_Raster_Decl__.Create;
  List.OnFree := Do_Free;

  Raster_Class := Raster_Class_;
  TimeOut := TimeOut_;
  DeltaSpace := DeltaSpace_;
  BlockSize := BlockSize_;
  InitIOHnd(IOHnd);
  umlFileCreateAsStream(Stream_, IOHnd, OnlyRead_);
  CoreSpace := TZDB2_Core_Space.Create(@IOHnd);
  CoreSpace.Cipher := Cipher_;
  CoreSpace.Mode := smNormal;
  CoreSpace.AutoCloseIOHnd := True;
  CoreSpace.OnNoSpace := DoNoSpace;
  if umlFileSize(IOHnd) > 0 then
    begin
      if not CoreSpace.Open then
          RaiseInfo('error.');
    end;
  OnCreateClass := OnCreateClass_;
  if CoreSpace.BlockCount = 0 then
      exit;

  if (PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.Identifier = $FFFF) and
    CoreSpace.Check(PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID) then
    begin
      m64 := TMem64.Create;
      CoreSpace.ReadData(m64, PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID);
      SetLength(buff, m64.Size shr 2);
      if length(buff) > 0 then
          CopyPtr(m64.Memory, @buff[0], length(buff) shl 2);
      DisposeObject(m64);
      CoreSpace.RemoveData(PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID, False);
      FillPtr(@CoreSpace.UserCustomHeader^[0], SizeOf(TSequence_Table_Head), 0);
    end
  else
      buff := CoreSpace.BuildTableID;

  for ID_ in buff do
    if CoreSpace.Check(ID_) then
        NewDataFrom(ID_);
  SetLength(buff, 0);
end;

destructor TZDB2_List_Raster.Destroy;
begin
  Flush;
  Clear;
  DisposeObjectAndNil(CoreSpace);
  List.Free;
  inherited Destroy;
end;

procedure TZDB2_List_Raster.Remove(Obj: TZDB2_Raster; RemoveData_: Boolean);
begin
  if RemoveData_ then
      Obj.Remove;
  List.Remove_P(Obj.FPool_Ptr);
end;

procedure TZDB2_List_Raster.Clear;
begin
  List.Clear;
end;

function TZDB2_List_Raster.NewDataFrom(ID_: Integer): TZDB2_Raster;
begin
  Result := Raster_Class.Create(CoreSpace, ID_);
  Result.FTimeOut := TimeOut;
  Result.FPool_Ptr := List.Add(Result);
  if Assigned(OnCreateClass) then
      OnCreateClass(self, Result);
end;

function TZDB2_List_Raster.NewData: TZDB2_Raster;
begin
  if IOHnd.IsOnlyRead then
      Result := nil
  else
      Result := NewDataFrom(-1);
end;

procedure TZDB2_List_Raster.Flush(flush_core_space: Boolean);
var
  __For__: TZDB2_Big_List_Raster_Decl__.TRepeat___;
  buff: TZDB2_BlockHandle;
  m64: TMem64;
begin
  if IOHnd.IsOnlyRead then
      exit;

  if (PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.Identifier = $FFFF) and
    CoreSpace.Check(PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID) then
    begin
      CoreSpace.RemoveData(PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID, False);
      FillPtr(@CoreSpace.UserCustomHeader^[0], SizeOf(TSequence_Table_Head), 0);
    end;

  if List.num > 0 then
    begin
      __For__ := List.Repeat_;
      repeat
        if (__For__.Queue^.Data.FID < 0) and (__For__.Queue^.Data.FData = nil) then
          begin
            List.Push_To_Recycle_Pool(__For__.Queue);
            DisposeObjectAndNil(__For__.Queue^.Data);
          end
        else
            __For__.Queue^.Data.Flush;
      until not __For__.Next;
      List.Free_Recycle_Pool;
    end;

  if List.num > 0 then
    begin
      // remove invalid
      SetLength(buff, List.num);

      __For__ := List.Repeat_;
      repeat
          buff[__For__.I__] := __For__.Queue^.Data.FID;
      until not __For__.Next;

      // store
      if flush_core_space then
        begin
          m64 := TMem64.Create;
          m64.Mapping(@buff[0], length(buff) shl 2);
          PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.Identifier := $FFFF;
          CoreSpace.WriteData(m64, PSequence_Table_Head(@CoreSpace.UserCustomHeader^[0])^.ID, False);
          DisposeObject(m64);
          SetLength(buff, 0);
        end;
    end
  else
    begin
      FillPtr(@CoreSpace.UserCustomHeader^[0], SizeOf(TSequence_Table_Head), 0);
    end;

  if flush_core_space then
      CoreSpace.Flush;
end;

procedure TZDB2_List_Raster.Flush;
begin
  Flush(True);
end;

procedure TZDB2_List_Raster.ExtractTo(Stream_: TCore_Stream);
var
  TmpIOHnd: TIOHnd;
  TmpSpace: TZDB2_Core_Space;
  __For__: TZDB2_Big_List_Raster_Decl__.TRepeat___;
  buff: TZDB2_BlockHandle;
  m64: TMem64;
begin
  Flush(False);
  InitIOHnd(TmpIOHnd);
  umlFileCreateAsStream(Stream_, TmpIOHnd);
  TmpSpace := TZDB2_Core_Space.Create(@TmpIOHnd);
  TmpSpace.Cipher := CoreSpace.Cipher;
  TmpSpace.Mode := smBigData;
  TmpSpace.OnNoSpace := DoNoSpace;

  if List.num > 0 then
    begin
      SetLength(buff, List.num);
      __For__ := List.Repeat_();
      repeat
        m64 := TMem64.Create;
        if CoreSpace.ReadData(m64, __For__.Queue^.Data.FID) then
          if not TmpSpace.WriteData(m64, buff[__For__.I__], False) then
              RaiseInfo('error');
        DisposeObject(m64);
        CoreSpace.DoProgress(List.num - 1, __For__.I__);
      until not __For__.Next;

      m64 := TMem64.Create;
      m64.Mapping(@buff[0], length(buff) shl 2);
      PSequence_Table_Head(@TmpSpace.UserCustomHeader^[0])^.Identifier := $FFFF;
      TmpSpace.WriteData(m64, PSequence_Table_Head(@TmpSpace.UserCustomHeader^[0])^.ID, False);
      DisposeObject(m64);
      SetLength(buff, 0);
    end
  else
      FillPtr(@TmpSpace.UserCustomHeader^[0], SizeOf(TSequence_Table_Head), 0);

  TmpSpace.Flush;
  DisposeObject(TmpSpace);
end;

procedure TZDB2_List_Raster.Progress;
var
  __For__: TZDB2_Big_List_Raster_Decl__.TRepeat___;
begin
  if List.num > 0 then
    begin
      __For__ := List.Repeat_();
      repeat
          __For__.Queue^.Data.Progress;
      until not __For__.Next;
    end;
end;

procedure TZDB2_List_Raster.Push_To_Recycle_Pool(obj_: TZDB2_Raster; RemoveData_: Boolean);
begin
  List.Push_To_Recycle_Pool(obj_.FPool_Ptr);
  if RemoveData_ then
      obj_.Remove;
end;

procedure TZDB2_List_Raster.Free_Recycle_Pool;
begin
  List.Free_Recycle_Pool;
end;

function TZDB2_List_Raster.Count: NativeInt;
begin
  Result := List.num;
end;

function TZDB2_List_Raster.Repeat_: TZDB2_Big_List_Raster_Decl__.TRepeat___;
begin
  Result := List.Repeat_;
end;

function TZDB2_List_Raster.Invert_Repeat_: TZDB2_Big_List_Raster_Decl__.TInvert_Repeat___;
begin
  Result := List.Invert_Repeat_;
end;

class procedure TZDB2_List_Raster.Test;
var
  Cipher_: TZDB2_Cipher;
  M64_1, M64_2: TMS64;
  i: Integer;
  tmp_Raster: TZDB2_Raster;
  L: TZDB2_List_Raster;
  tk: TTimeTick;
begin
  TCompute.Sleep(1000);
  Cipher_ := TZDB2_Cipher.Create(TCipherSecurity.csRijndael, 'hello world', 1, True, True);
  M64_1 := TMS64.CustomCreate(1 * 1024 * 1024);
  M64_2 := TMS64.CustomCreate(1 * 1024 * 1024);

  tk := GetTimeTick;
  with TZDB2_List_Raster.Create(TZDB2_Raster, nil, 5000, M64_1, False, 64 * 1048576, 200, Cipher_) do
    begin
      AutoFreeStream := False;
      for i := 0 to 20 - 1 do
        begin
          tmp_Raster := NewData();
          tmp_Raster.Data.SetSize(64 + i, 64 + i);
          tmp_Raster.Flush;
        end;
      DoStatus('build %d of Raster,time:%dms', [List.num, GetTimeTick - tk]);
      Free;
    end;

  tk := GetTimeTick;
  L := TZDB2_List_Raster.Create(TZDB2_Raster, nil, 5000, M64_1, False, 64 * 1048576, 200, Cipher_);
  with L.Repeat_ do
    repeat
      if (Queue^.Data.Data.Width <> 64 + I__) or (Queue^.Data.Data.Height <> 64 + I__) then
          DoStatus('%s - test error.', [L.ClassName]);
      Queue^.Data.Data.Clear(RColorF(1, 1, 1));
      Queue^.Data.IsChanged := True;
    until not Next;
  DoStatus('load %d of Raster,time:%dms', [L.List.num, GetTimeTick - tk]);
  L.ExtractTo(M64_2);
  L.Free;

  tk := GetTimeTick;
  L := TZDB2_List_Raster.Create(TZDB2_Raster, nil, 5000, M64_2, False, 64 * 1048576, 200, Cipher_);
  with L.Invert_Repeat_ do
    repeat
      if (Queue^.Data.Data.Width <> 64 + I__) or (Queue^.Data.Data.Height <> 64 + I__) then
          DoStatus('%s - test error.', [L.ClassName]);
      if Queue^.Data.Data.PixelVec[Queue^.Data.Data.Centroid] <> RColorF(1, 1, 1) then
          DoStatus('%s - test error.', [L.ClassName]);
      if I__ mod 2 = 0 then
          L.Push_To_Recycle_Pool(Queue^.Data, True);
    until not Prev;
  L.Free_Recycle_Pool;
  DoStatus('extract and remove done num=%d, stream of Raster,time:%dms', [L.List.num, GetTimeTick - tk]);
  L.Free;

  DisposeObject(M64_1);
  DisposeObject(M64_2);
  DisposeObject(Cipher_);
end;

end.
