object Text_Format_Tool_Form: TText_Format_Tool_Form
  Left = 0
  Top = 0
  Caption = 'Text Format tool.'
  ClientHeight = 653
  ClientWidth = 1174
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    1174
    653)
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 16
    Top = 16
    Width = 1049
    Height = 617
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object FM_INI_Button: TButton
    Left = 1080
    Top = 16
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Format INI'
    TabOrder = 0
    OnClick = FM_INI_ButtonClick
  end
  object FM_Json_Button: TButton
    Left = 1080
    Top = 47
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Format Json'
    TabOrder = 1
    OnClick = FM_Json_ButtonClick
  end
  object fpsTimer: TTimer
    Interval = 100
    OnTimer = fpsTimerTimer
    Left = 176
    Top = 64
  end
end
