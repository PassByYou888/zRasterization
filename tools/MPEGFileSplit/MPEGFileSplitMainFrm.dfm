object MPEGFileSplitMainForm: TMPEGFileSplitMainForm
  Left = 0
  Top = 0
  Caption = 'MPEG Split Tool.'
  ClientHeight = 444
  ClientWidth = 1322
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    1322
    444)
  TextHeight = 13
  object MpegFileEdit: TLabeledEdit
    Left = 64
    Top = 24
    Width = 1169
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 46
    EditLabel.Height = 21
    EditLabel.Caption = 'MPEG File'
    LabelPosition = lpLeft
    TabOrder = 0
    Text = ''
  end
  object SplitTimeEdit: TLabeledEdit
    Left = 64
    Top = 64
    Width = 58
    Height = 21
    EditLabel.Width = 45
    EditLabel.Height = 21
    EditLabel.Caption = 'Split Time'
    LabelPosition = lpLeft
    TabOrder = 1
    Text = '00:02:30'
  end
  object BrowseButton: TButton
    Left = 1239
    Top = 22
    Width = 57
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Browse'
    TabOrder = 2
    OnClick = BrowseButtonClick
  end
  object RunButton: TButton
    Left = 16
    Top = 113
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 3
    OnClick = RunButtonClick
  end
  object Memo: TMemo
    Left = 16
    Top = 144
    Width = 1289
    Height = 281
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clBlack
    Font.Charset = ANSI_CHARSET
    Font.Color = clLime
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = [fsBold]
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 4
    WordWrap = False
  end
  object StopButton: TButton
    Left = 97
    Top = 113
    Width = 75
    Height = 25
    Caption = 'Stop'
    TabOrder = 5
    OnClick = StopButtonClick
  end
  object CudaCheckBox: TCheckBox
    Left = 271
    Top = 66
    Width = 129
    Height = 17
    Caption = 'Used Cuda technology'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object FastCopyCheckBox: TCheckBox
    Left = 136
    Top = 66
    Width = 129
    Height = 17
    Caption = 'Used Copy technology'
    TabOrder = 7
  end
  object OpenDialog: TOpenDialog
    Filter = 
      'All Mpeg files|*.mp4;*.mkv;*.avi;*.flv;*.h264;*.y4m|All files|*.' +
      '*'
    Left = 216
    Top = 80
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 216
    Top = 144
  end
end
