object ZDB2FileDecoderForm: TZDB2FileDecoderForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 20
  Caption = 'ZDB2.0 File Decoder..'
  ClientHeight = 209
  ClientWidth = 689
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
    Left = 0
    Top = 88
    Width = 681
    Height = 34
    AutoSize = False
    Caption = '...'
    Layout = tlBottom
    WordWrap = True
  end
  object DirectoryEdit: TLabeledEdit
    Left = 0
    Top = 59
    Width = 425
    Height = 21
    EditLabel.Width = 48
    EditLabel.Height = 13
    EditLabel.Caption = 'Directory:'
    TabOrder = 5
  end
  object DirBrowseButton: TButton
    Left = 431
    Top = 57
    Width = 26
    Height = 25
    Caption = '..'
    TabOrder = 6
    OnClick = DirBrowseButtonClick
  end
  object SourceZDBFileEdit: TLabeledEdit
    Left = 0
    Top = 16
    Width = 297
    Height = 21
    EditLabel.Width = 91
    EditLabel.Height = 13
    EditLabel.Caption = 'ZDB2 Package File:'
    TabOrder = 0
  end
  object fileBrowseButton: TButton
    Left = 303
    Top = 14
    Width = 26
    Height = 25
    Caption = '..'
    TabOrder = 1
    OnClick = fileBrowseButtonClick
  end
  object ExtractButton: TButton
    Left = 335
    Top = 14
    Width = 75
    Height = 25
    Caption = 'Extract.'
    TabOrder = 2
    OnClick = ExtractButtonClick
  end
  object Memo: TMemo
    Left = 0
    Top = 128
    Width = 689
    Height = 81
    ScrollBars = ssVertical
    TabOrder = 7
    WordWrap = False
  end
  object ProgressBar: TProgressBar
    Left = 472
    Top = 22
    Width = 150
    Height = 17
    TabOrder = 4
  end
  object Button_Abort: TButton
    Left = 416
    Top = 14
    Width = 50
    Height = 25
    Caption = 'Abort'
    Enabled = False
    TabOrder = 3
    OnClick = Button_AbortClick
  end
  object Timer: TTimer
    Interval = 500
    OnTimer = TimerTimer
    Left = 168
    Top = 41
  end
  object OpenDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'ZDB2.0 Files'
        FileMask = '*.OX2'
      end>
    Options = [fdoPathMustExist, fdoFileMustExist]
    Left = 72
    Top = 40
  end
end
