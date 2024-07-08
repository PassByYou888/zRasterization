object StringTranslateForm: TStringTranslateForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 15
  Caption = 'declaration translate..'
  ClientHeight = 426
  ClientWidth = 1138
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
  object Memo1: TMemo
    Left = 0
    Top = 32
    Width = 498
    Height = 393
    TabStop = False
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ScrollBars = ssVertical
    TabOrder = 2
    WordWrap = False
  end
  object Memo2: TMemo
    Left = 640
    Top = 31
    Width = 498
    Height = 395
    TabStop = False
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ScrollBars = ssVertical
    TabOrder = 10
    WordWrap = False
  end
  object Hex2AsciiButton: TButton
    Left = 504
    Top = 62
    Width = 130
    Height = 25
    Caption = 'hex 2 ascii ->'
    TabOrder = 4
    OnClick = Hex2AsciiButtonClick
  end
  object Ascii2HexButton: TButton
    Left = 504
    Top = 31
    Width = 130
    Height = 25
    Caption = '<- ascii 2 hex'
    TabOrder = 3
    OnClick = Ascii2HexButtonClick
  end
  object Ascii2DeclButton: TButton
    Left = 504
    Top = 136
    Width = 130
    Height = 25
    Caption = '<- ascii 2 declaration'
    TabOrder = 5
    OnClick = Ascii2DeclButtonClick
  end
  object Ascii2PascalDeclButton: TButton
    Left = 504
    Top = 167
    Width = 130
    Height = 25
    Caption = '<- ascii 2 pascal'
    TabOrder = 6
    OnClick = Ascii2PascalDeclButtonClick
  end
  object PascalDecl2AsciiButton: TButton
    Left = 504
    Top = 198
    Width = 130
    Height = 25
    Caption = 'pascal 2 ascii ->'
    TabOrder = 7
    OnClick = PascalDecl2AsciiButtonClick
  end
  object Ascii2cButton: TButton
    Left = 504
    Top = 271
    Width = 130
    Height = 25
    Caption = '<- ascii 2 c'
    TabOrder = 8
    OnClick = Ascii2cButtonClick
  end
  object c2AsciiButton: TButton
    Left = 504
    Top = 302
    Width = 130
    Height = 25
    Caption = 'c 2 ascii ->'
    TabOrder = 9
    OnClick = c2AsciiButtonClick
  end
  object Invert_Memo2_Button: TButton
    Left = 1079
    Top = 0
    Width = 51
    Height = 25
    Caption = 'invert'
    TabOrder = 1
    OnClick = Invert_Memo2_ButtonClick
  end
  object Invert_Memo1_Button: TButton
    Left = 8
    Top = 1
    Width = 51
    Height = 25
    Caption = 'invert'
    TabOrder = 0
    OnClick = Invert_Memo1_ButtonClick
  end
end
