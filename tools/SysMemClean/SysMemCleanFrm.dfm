object SysMemCleanForm: TSysMemCleanForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  BorderWidth = 10
  Caption = 'System Memory Clean.'
  ClientHeight = 302
  ClientWidth = 657
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object thInfoLabel: TLabel
    Left = 625
    Top = 0
    Width = 32
    Height = 13
    Alignment = taRightJustify
    Caption = '........'
  end
  object SizeEdit: TLabeledEdit
    Left = 0
    Top = 16
    Width = 161
    Height = 21
    EditLabel.Width = 132
    EditLabel.Height = 13
    EditLabel.Caption = 'Clean System Memory Size:'
    TabOrder = 0
    Text = '16*1024*1024*1024'
  end
  object CleanButton: TButton
    Left = 167
    Top = 14
    Width = 75
    Height = 25
    Caption = 'Clean'
    TabOrder = 1
    OnClick = CleanButtonClick
  end
  object Memo: TMemo
    Left = 0
    Top = 45
    Width = 657
    Height = 257
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
  end
  object fpsTimer: TTimer
    Interval = 100
    OnTimer = fpsTimerTimer
    Left = 256
    Top = 168
  end
  object infoTimer: TTimer
    OnTimer = infoTimerTimer
    Left = 328
    Top = 160
  end
end
