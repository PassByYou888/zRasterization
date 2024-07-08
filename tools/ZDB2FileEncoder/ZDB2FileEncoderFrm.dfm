object ZDB2FileEncoderForm: TZDB2FileEncoderForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 30
  Caption = 'ZDB2.0 File Encoder..'
  ClientHeight = 345
  ClientWidth = 697
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object InfoLabel: TLabel
    Left = 220
    Top = 124
    Width = 477
    Height = 31
    AutoSize = False
    Caption = '...'
    Layout = tlBottom
    WordWrap = True
  end
  object DirectoryEdit: TLabeledEdit
    Left = 0
    Top = 16
    Width = 425
    Height = 21
    EditLabel.Width = 48
    EditLabel.Height = 13
    EditLabel.Caption = 'Directory:'
    TabOrder = 0
  end
  object DirBrowseButton: TButton
    Left = 431
    Top = 14
    Width = 26
    Height = 25
    Caption = '..'
    TabOrder = 1
    OnClick = DirBrowseButtonClick
  end
  object DestZDBFileEdit: TLabeledEdit
    Left = 0
    Top = 60
    Width = 297
    Height = 21
    EditLabel.Width = 91
    EditLabel.Height = 13
    EditLabel.Caption = 'ZDB2 Package File:'
    TabOrder = 3
  end
  object fileBrowseButton: TButton
    Left = 303
    Top = 58
    Width = 26
    Height = 25
    Caption = '..'
    TabOrder = 4
    OnClick = fileBrowseButtonClick
  end
  object buildButton: TButton
    Left = 0
    Top = 95
    Width = 75
    Height = 25
    Caption = 'Build.'
    TabOrder = 5
    OnClick = buildButtonClick
  end
  object ThNumEdit: TLabeledEdit
    Left = 128
    Top = 97
    Width = 33
    Height = 21
    EditLabel.Width = 38
    EditLabel.Height = 13
    EditLabel.Caption = 'Thread:'
    LabelPosition = lpLeft
    TabOrder = 6
  end
  object ChunkEdit: TLabeledEdit
    Left = 207
    Top = 97
    Width = 98
    Height = 21
    EditLabel.Width = 34
    EditLabel.Height = 13
    EditLabel.Caption = 'Chunk:'
    LabelPosition = lpLeft
    TabOrder = 7
  end
  object BlockEdit: TLabeledEdit
    Left = 352
    Top = 97
    Width = 81
    Height = 21
    EditLabel.Width = 28
    EditLabel.Height = 13
    EditLabel.Caption = 'Block:'
    LabelPosition = lpLeft
    TabOrder = 8
  end
  object Memo: TMemo
    Left = 8
    Top = 161
    Width = 689
    Height = 184
    ScrollBars = ssVertical
    TabOrder = 11
    WordWrap = False
  end
  object CheckBox_IncludeSub: TCheckBox
    Left = 463
    Top = 18
    Width = 146
    Height = 17
    Caption = 'Include Sub Directory.'
    TabOrder = 2
  end
  object ProgressBar: TProgressBar
    Left = 64
    Top = 138
    Width = 150
    Height = 17
    TabOrder = 10
  end
  object Button_Abort: TButton
    Left = 8
    Top = 130
    Width = 50
    Height = 25
    Caption = 'Abort'
    Enabled = False
    TabOrder = 9
    OnClick = Button_AbortClick
  end
  object Timer: TTimer
    Interval = 500
    OnTimer = TimerTimer
    Left = 120
    Top = 49
  end
  object SaveDialog: TFileSaveDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'ZDB2.0 Files'
        FileMask = '*.OX2'
      end>
    Options = [fdoOverWritePrompt, fdoPathMustExist]
    Left = 208
    Top = 248
  end
end
