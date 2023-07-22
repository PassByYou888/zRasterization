{ ****************************************************************************** }
{ * Low MemoryHook                                                             * }
{ ****************************************************************************** }

unit ZR.MH2;

{$I ZR.Define.inc}

interface

uses ZR.ListEngine, ZR.Core;

procedure BeginMemoryHook; overload;
procedure BeginMemoryHook(cacheLen: Integer); overload;
procedure EndMemoryHook;
function GetHookMemorySize: nativeUInt; overload;
function GetHookMemorySize(p: Pointer): nativeUInt; overload;
function GetHookMemoryMinimizePtr: Pointer;
function GetHookMemoryMaximumPtr: Pointer;
function GetHookPtrList: TPointerHashNativeUIntList;
function GetMemoryHooked: TAtomBool;

implementation

var
  HookPtrList: TPointerHashNativeUIntList;
  MemoryHooked: TAtomBool;

{$IFDEF FPC}
{$I ZR.MH_fpc.inc}
{$ELSE}
{$I ZR.MH_delphi.inc}
{$ENDIF}

initialization

InstallMemoryHook;

finalization

UnInstallMemoryHook;

end.
