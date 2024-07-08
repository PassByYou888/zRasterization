object EncodingConverForm: TEncodingConverForm
  Left = 0
  Top = 0
  AutoSize = True
  BorderStyle = bsDialog
  BorderWidth = 10
  Caption = 'Encoding convert.'
  ClientHeight = 937
  ClientWidth = 1097
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
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 0
    Top = 6
    Width = 160
    Height = 13
    Caption = 'source files and source Encoding:'
  end
  object Label2: TLabel
    Left = 7
    Top = 621
    Width = 59
    Height = 13
    Caption = 'dest Encode'
  end
  object Memo: TMemo
    Left = 0
    Top = 31
    Width = 1097
    Height = 574
    ScrollBars = ssVertical
    TabOrder = 4
    WordWrap = False
  end
  object AddFilesButton: TButton
    Left = 428
    Top = 0
    Width = 75
    Height = 25
    Caption = 'Add Files'
    TabOrder = 1
    OnClick = AddFilesButtonClick
  end
  object EncodeButton: TButton
    Left = 407
    Top = 611
    Width = 104
    Height = 25
    Caption = 'Rebuild text'
    TabOrder = 7
    OnClick = EncodeButtonClick
  end
  object StatusMemo: TMemo
    Left = 0
    Top = 642
    Width = 1097
    Height = 295
    ScrollBars = ssVertical
    TabOrder = 9
    WordWrap = False
  end
  object sourEncodeComboBox: TComboBox
    Left = 171
    Top = 2
    Width = 251
    Height = 21
    Style = csDropDownList
    TabOrder = 0
  end
  object DestEncodeComboBox: TComboBox
    Left = 72
    Top = 613
    Width = 251
    Height = 21
    Style = csDropDownList
    TabOrder = 5
  end
  object SignedCheckBox: TCheckBox
    Left = 518
    Top = 616
    Width = 75
    Height = 17
    Caption = 'signature'
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object SafeScanButton: TButton
    Left = 329
    Top = 611
    Width = 72
    Height = 25
    Caption = 'Safe scan'
    TabOrder = 6
    OnClick = SafeScanButtonClick
  end
  object FilterEdit: TLabeledEdit
    Left = 952
    Top = 2
    Width = 89
    Height = 21
    EditLabel.Width = 126
    EditLabel.Height = 13
    EditLabel.Caption = 'Wildcard expression (*,?):'
    LabelPosition = lpLeft
    TabOrder = 2
    Text = '*.*'
  end
  object removeButton: TButton
    Left = 1047
    Top = 0
    Width = 50
    Height = 25
    Caption = 'clear'
    TabOrder = 3
    OnClick = removeButtonClick
  end
  object OpenDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'all code files'
        FileMask = 
          '*.txt;*.conf;*.ini;*.xml;*.html;*.htm;*.c;*.cpp;*.h;*.hpp;*.cxx;' +
          '*.dpr;*.pas;*.p;*.inc;*.cs;*.java;*.py;*.csv;*.bat;*.sh'
      end
      item
        DisplayName = 'all files'
        FileMask = '*.*'
      end>
    Options = [fdoAllowMultiSelect, fdoPathMustExist, fdoFileMustExist]
    Left = 256
    Top = 96
  end
  object bkTimer: TTimer
    Interval = 100
    OnTimer = bkTimerTimer
    Left = 288
    Top = 184
  end
end
