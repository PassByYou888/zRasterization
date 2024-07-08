object Chinese_GBK_Tool_Form: TChinese_GBK_Tool_Form
  Left = 0
  Top = 0
  Caption = 'Chinese GBK Tool.'
  ClientHeight = 587
  ClientWidth = 1128
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 41
    Width = 1128
    Height = 546
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object top_bar_Panel: TPanel
    Left = 0
    Top = 0
    Width = 1128
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    BorderWidth = 5
    TabOrder = 1
    ExplicitLeft = 160
    ExplicitTop = 128
    ExplicitWidth = 185
    object Simplified_to_Traditional_Button: TButton
      Left = 5
      Top = 5
      Width = 156
      Height = 31
      Align = alLeft
      Caption = 'Simplified to Traditional'
      TabOrder = 0
      WordWrap = True
      OnClick = Simplified_to_Traditional_ButtonClick
    end
    object Simplified_to_Hongkong_Traditional_Button: TButton
      Left = 161
      Top = 5
      Width = 184
      Height = 31
      Align = alLeft
      Caption = 'Simplified to Hongkong Traditional'
      TabOrder = 1
      WordWrap = True
      OnClick = Simplified_to_Hongkong_Traditional_ButtonClick
    end
    object Traditional_to_Simplified_Button: TButton
      Left = 345
      Top = 5
      Width = 152
      Height = 31
      Align = alLeft
      Caption = 'Traditional to Simplified'
      TabOrder = 2
      WordWrap = True
      OnClick = Traditional_to_Simplified_ButtonClick
    end
    object Simplified_to_Taiwan_Traditional_Button: TButton
      Left = 497
      Top = 5
      Width = 192
      Height = 31
      Align = alLeft
      Caption = 'Simplified to Taiwan Traditional'
      TabOrder = 3
      WordWrap = True
      OnClick = Simplified_to_Taiwan_Traditional_ButtonClick
    end
    object Simplified_to_PinYin_Button: TButton
      Left = 1016
      Top = 5
      Width = 107
      Height = 31
      Align = alRight
      Caption = 'Simplified to PinYin'
      TabOrder = 4
      WordWrap = True
      OnClick = Simplified_to_PinYin_ButtonClick
    end
  end
  object threadTimer: TTimer
    Interval = 1
    OnTimer = threadTimerTimer
    Left = 328
    Top = 232
  end
end
