object ZDBPerfTestForm: TZDBPerfTestForm
  Left = 0
  Top = 0
  Caption = 'ZDB2.0 Performance Test. create by.qq600585'
  ClientHeight = 506
  ClientWidth = 905
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  TextHeight = 13
  object StateLabel: TLabel
    Left = 176
    Top = 175
    Width = 28
    Height = 13
    Caption = '.......'
  end
  object FileEdit: TLabeledEdit
    Left = 176
    Top = 32
    Width = 329
    Height = 21
    EditLabel.Width = 60
    EditLabel.Height = 21
    EditLabel.Caption = #25968#25454#24211#25991#20214
    LabelPosition = lpLeft
    TabOrder = 0
    Text = ''
  end
  object PhySpaceEdit: TLabeledEdit
    Left = 176
    Top = 59
    Width = 178
    Height = 21
    EditLabel.Width = 124
    EditLabel.Height = 21
    EditLabel.Caption = #25968#25454#24211#23610#23544'/'#25903#25345#34920#36798#24335
    LabelPosition = lpLeft
    TabOrder = 1
    Text = ''
  end
  object BlockSizeEdit: TLabeledEdit
    Left = 176
    Top = 86
    Width = 89
    Height = 21
    EditLabel.Width = 48
    EditLabel.Height = 21
    EditLabel.Caption = #21333#20803#23610#23544
    LabelPosition = lpLeft
    TabOrder = 2
    Text = ''
  end
  object NewFileButton: TButton
    Left = 176
    Top = 113
    Width = 137
    Height = 25
    Caption = #21019#24314'ZDB2.0'#25968#25454#24211
    TabOrder = 3
    OnClick = NewFileButtonClick
  end
  object Memo: TMemo
    Left = 0
    Top = 304
    Width = 905
    Height = 202
    Align = alBottom
    Lines.Strings = (
      'ZDB2.0'#20869#26680#20013#30340#23384#20648#27169#22411#26377#33021#21147#23558'NVME/SSD/HDD'#36825#31867#35774#22791#36305#28385
      #22522#20110'ZDB2.0'#26500#24314#30340#22823#25968#25454#23384#20648#31243#24207#23436#20840#25353'HPC'#25351#26631#23450#20041
      'by.qq600585'
      '')
    TabOrder = 4
  end
  object CloseDBButton: TButton
    Left = 176
    Top = 144
    Width = 90
    Height = 25
    Caption = #20851#38381#25968#25454#24211
    TabOrder = 5
    OnClick = CloseDBButtonClick
  end
  object ProgressBar: TProgressBar
    Left = 319
    Top = 113
    Width = 370
    Height = 25
    TabOrder = 6
  end
  object FillDBButton: TButton
    Left = 176
    Top = 202
    Width = 329
    Height = 25
    Caption = #29992#38543#26426#25968#25454#22635#28385'('#27979#35797#20889#20837#33021#21147','#30828#20214#35774#22791#20915#23450#24615#33021')'
    TabOrder = 7
    OnClick = FillDBButtonClick
  end
  object AppendSpaceButton: TButton
    Left = 176
    Top = 264
    Width = 178
    Height = 25
    Caption = #25193#23481#23384#20648#31354#38388'('#19981#20250#30772#22351'ID)'
    TabOrder = 8
    OnClick = AppendSpaceButtonClick
  end
  object TraversalButton: TButton
    Left = 176
    Top = 233
    Width = 178
    Height = 25
    Caption = #36941#21382#20840#24211'('#27979#35797#35835#21462#33021#21147')'
    TabOrder = 9
    OnClick = TraversalButtonClick
  end
  object checkTimer: TTimer
    Interval = 10
    OnTimer = checkTimerTimer
    Left = 40
    Top = 112
  end
  object stateTimer: TTimer
    OnTimer = stateTimerTimer
    Left = 40
    Top = 176
  end
end
