object MacroStringGenerator_Form: TMacroStringGenerator_Form
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 20
  Caption = 'Macro String Generate tool.'
  ClientHeight = 436
  ClientWidth = 1253
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object templet_info_Label: TLabel
    Left = 0
    Top = 7
    Width = 283
    Height = 13
    Caption = 'macro templet:<s1>,<s2>,<s3>,<s4>,<Line>,<LineNo>'
  end
  object excel_source_info_Label: TLabel
    Left = 319
    Top = 5
    Width = 170
    Height = 13
    Caption = 'excel data source, used "#9,;" split'
  end
  object output_info_Label: TLabel
    Left = 750
    Top = 7
    Width = 64
    Height = 13
    Caption = 'marco output'
  end
  object templet_Memo: TMemo
    Left = 0
    Top = 26
    Width = 313
    Height = 410
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = [fsBold]
    Lines.Strings = (
      's1:<s1>, s2:<s2>, s3:<s3>, s4:<s4>')
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object excel_source_Memo: TMemo
    Left = 319
    Top = 26
    Width = 425
    Height = 409
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = [fsBold]
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object output_Memo: TMemo
    Left = 750
    Top = 26
    Width = 503
    Height = 409
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = [fsBold]
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 3
    WordWrap = False
  end
  object Build_Button: TButton
    Left = 833
    Top = 0
    Width = 48
    Height = 25
    Caption = 'Build'
    TabOrder = 2
    OnClick = Build_ButtonClick
  end
  object fpsTimer: TTimer
    Interval = 100
    OnTimer = fpsTimerTimer
    Left = 248
    Top = 16
  end
end
