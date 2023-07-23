object FontBuildForm: TFontBuildForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 10
  Caption = 'Font Build. create by qq.600585'
  ClientHeight = 761
  ClientWidth = 1335
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Image: TImage
    Left = 111
    Top = 271
    Width = 1224
    Height = 346
  end
  object Label1: TLabel
    Left = 8
    Top = 31
    Width = 54
    Height = 13
    Caption = 'Antialiasing'
  end
  object BuildButton: TButton
    Left = 0
    Top = 174
    Width = 91
    Height = 25
    Caption = 'Build Font'
    TabOrder = 0
    OnClick = BuildButtonClick
  end
  object SaveButton: TButton
    Left = 0
    Top = 254
    Width = 91
    Height = 25
    Caption = 'Save'
    TabOrder = 1
    OnClick = SaveButtonClick
  end
  object Memo: TMemo
    Left = 0
    Top = 623
    Width = 1335
    Height = 138
    TabOrder = 2
    WordWrap = False
  end
  object SetFontButton: TButton
    Left = 0
    Top = 0
    Width = 91
    Height = 25
    Caption = 'Set Font'
    TabOrder = 3
    OnClick = SetFontButtonClick
  end
  object ProgressBar: TProgressBar
    Left = 111
    Top = 0
    Width = 1224
    Height = 17
    TabOrder = 4
  end
  object LoadButton: TButton
    Left = 0
    Top = 229
    Width = 91
    Height = 25
    Caption = 'Open'
    TabOrder = 5
    OnClick = LoadButtonClick
  end
  object AATrackBar: TTrackBar
    Left = 0
    Top = 44
    Width = 91
    Height = 45
    Max = 4
    ParentShowHint = False
    ShowHint = False
    ShowSelRange = False
    TabOrder = 6
    TickMarks = tmBoth
  end
  object IncludeallCheckBox: TCheckBox
    Left = 8
    Top = 95
    Width = 97
    Height = 17
    Caption = 'include ALL'
    TabOrder = 7
  end
  object SampleMemo: TMemo
    Left = 111
    Top = 23
    Width = 1224
    Height = 242
    Lines.Strings = (
      
        '||Default-Size|| |color(0.5,0.5,0.5),size:24|24-size|| |s:16|16-' +
        'Size||'
      '|color(1,0,0,1),size:24|24-Size-red|color(1,1,0)| Default-Size'
      '|color(0,1,0,1),size:50|50 size text'
      '|s:32|32-size-text')
    TabOrder = 8
    OnChange = SampleMemoChange
  end
  object ExportBMPButton: TButton
    Left = 0
    Top = 357
    Width = 91
    Height = 25
    Caption = 'Export as .BMP'
    TabOrder = 9
    OnClick = ExportBMPButtonClick
  end
  object IncludeGBKCheckBox: TCheckBox
    Left = 8
    Top = 118
    Width = 97
    Height = 17
    Caption = 'GBK-chinese'
    TabOrder = 10
  end
  object FontDialog: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    Options = []
    Left = 376
    Top = 184
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.zfont'
    Filter = 'zFont(*.zfont)|*.zfont|All files(*.*)|*.*'
    Left = 376
    Top = 232
  end
  object OpenDialog: TOpenDialog
    DefaultExt = '.zfont'
    Filter = 'zFont(*.zfont)|*.zfont|All files(*.*)|*.*'
    Left = 376
    Top = 136
  end
  object bmpSaveDialog: TSaveDialog
    DefaultExt = '.bmp'
    Filter = 'bitmap file(*.bmp)|*.bmp'
    Left = 376
    Top = 288
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 376
    Top = 336
  end
end
