object FileRecurseSearchTool_Form: TFileRecurseSearchTool_Form
  Left = 0
  Top = 0
  Caption = 'File Recurse Search Tool.'
  ClientHeight = 361
  ClientWidth = 864
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 880
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Consolas'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  DesignSize = (
    864
    361)
  PixelsPerInch = 96
  TextHeight = 14
  object LogInfoLabel: TLabel
    Left = 119
    Top = 84
    Width = 28
    Height = 14
    Caption = 'Log:'
  end
  object RootDirectoryEdit: TLabeledEdit
    Left = 144
    Top = 16
    Width = 505
    Height = 22
    EditLabel.Width = 105
    EditLabel.Height = 14
    EditLabel.Caption = 'Root Directory:'
    LabelPosition = lpLeft
    TabOrder = 0
  end
  object BrowseRoorDirectoryButton: TButton
    Left = 655
    Top = 15
    Width = 34
    Height = 25
    Caption = '..'
    TabOrder = 1
    OnClick = BrowseRoorDirectoryButtonClick
  end
  object FileFilterEdit: TLabeledEdit
    Left = 144
    Top = 44
    Width = 225
    Height = 22
    EditLabel.Width = 84
    EditLabel.Height = 14
    EditLabel.Caption = 'File Filter:'
    LabelPosition = lpLeft
    TabOrder = 2
  end
  object DoSearchButton: TButton
    Left = 16
    Top = 73
    Width = 97
    Height = 25
    Caption = 'Do Search.'
    TabOrder = 3
    OnClick = DoSearchButtonClick
  end
  object Memo: TMemo
    Left = 16
    Top = 104
    Width = 833
    Height = 241
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 4
    WordWrap = False
  end
  object CoreTimer: TTimer
    Interval = 100
    OnTimer = CoreTimerTimer
    Left = 312
    Top = 160
  end
end
