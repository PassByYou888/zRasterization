program _140_Thread_Signal;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  ZR.Core;

procedure Do_Thread();
begin
  TCompute.Sleep(999);
end;

// 单线程信号机制使用原子变量,不区分主线程,可以在任何线程互等
procedure Sigle_Thread_Signal;
var
  // 收发信号状态机
  IsRuning_, IsExit_: Boolean;
begin
  // TCompute可以支持fpc
  TCompute.RunC_NP(Do_Thread, @IsRuning_, @IsExit_);
  // 等状态机
  while IsRuning_ do
      TCompute.Sleep(1);
end;

// 多线程信号机制,这种模型很适合加速分支程序
procedure Multi_Thread_Signal;
var
  i: Integer;
  runing_arry: TBool_Signal_Array;
begin
  SetLength(runing_arry, 10);
  for i := 0 to length(runing_arry) - 1 do
      TCompute.RunC_NP(Do_Thread, @runing_arry[i], nil);

  // 等runing信号全部为false
  Wait_All_Signal(runing_arry, False);
end;

begin
  Sigle_Thread_Signal;
  Multi_Thread_Signal;

end.
