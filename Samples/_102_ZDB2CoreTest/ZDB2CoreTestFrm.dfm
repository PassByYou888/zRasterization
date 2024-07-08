object ZDB2CoreTestForm: TZDB2CoreTestForm
  Left = 0
  Top = 0
  Caption = 'ZDB2 Core Test. create by.qq600585'
  ClientHeight = 711
  ClientWidth = 1142
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 184
    Width = 1142
    Height = 527
    Align = alBottom
    TabOrder = 0
    WordWrap = False
  end
  object Timer1: TTimer
    Interval = 10
    OnTimer = Timer1Timer
    Left = 568
    Top = 360
  end
end
