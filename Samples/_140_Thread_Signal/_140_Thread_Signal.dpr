program _140_Thread_Signal;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  ZR.Core;

procedure Do_Thread();
begin
  TCompute.Sleep(999);
end;

// ���߳��źŻ���ʹ��ԭ�ӱ���,���������߳�,�������κ��̻߳���
procedure Sigle_Thread_Signal;
var
  // �շ��ź�״̬��
  IsRuning_, IsExit_: Boolean;
begin
  // TCompute����֧��fpc
  TCompute.RunC_NP(Do_Thread, @IsRuning_, @IsExit_);
  // ��״̬��
  while IsRuning_ do
      TCompute.Sleep(1);
end;

// ���߳��źŻ���,����ģ�ͺ��ʺϼ��ٷ�֧����
procedure Multi_Thread_Signal;
var
  i: Integer;
  runing_arry: TBool_Signal_Array;
begin
  SetLength(runing_arry, 10);
  for i := 0 to length(runing_arry) - 1 do
      TCompute.RunC_NP(Do_Thread, @runing_arry[i], nil);

  // ��runing�ź�ȫ��Ϊfalse
  Wait_All_Signal(runing_arry, False);
end;

begin
  Sigle_Thread_Signal;
  Multi_Thread_Signal;

end.
