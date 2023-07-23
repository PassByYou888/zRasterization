object LFilePackageWithZDBMainForm: TLFilePackageWithZDBMainForm
  Left = 0
  Top = 0
  Caption = 'Large-Scale File Package.'
  ClientHeight = 430
  ClientWidth = 1082
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 304
    Width = 1082
    Height = 5
    Cursor = crVSplit
    Align = alBottom
    AutoSnap = False
    ResizeStyle = rsUpdate
    ExplicitTop = 389
    ExplicitWidth = 1167
  end
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 1082
    Height = 41
    Align = alTop
    BorderWidth = 5
    TabOrder = 0
    object Bevel4: TBevel
      Left = 133
      Top = 6
      Width = 10
      Height = 29
      Align = alLeft
      Shape = bsSpacer
      ExplicitLeft = 38
      ExplicitTop = 8
      ExplicitHeight = 33
    end
    object NewButton: TButton
      Left = 6
      Top = 6
      Width = 50
      Height = 29
      Align = alLeft
      Caption = 'New'
      TabOrder = 0
      OnClick = NewButtonClick
    end
    object OpenButton: TButton
      Left = 143
      Top = 6
      Width = 50
      Height = 29
      Align = alLeft
      Caption = 'Open'
      TabOrder = 2
      OnClick = OpenButtonClick
    end
    object NewCustomButton: TButton
      Left = 56
      Top = 6
      Width = 77
      Height = 29
      Align = alLeft
      Caption = 'New Custom'
      TabOrder = 1
      OnClick = NewCustomButtonClick
    end
  end
  object Memo: TMemo
    Left = 0
    Top = 309
    Width = 1082
    Height = 121
    Align = alBottom
    BorderStyle = bsNone
    TabOrder = 1
    WordWrap = False
  end
  object OpenDialog: TOpenDialog
    Filter = 
      'all files(*.OX;*.ImgMat)|*.OX;*.ImgMat|Object Data(*.OX)|*.OX|Im' +
      'age Matrix(*.ImgMat)|*.ImgMat|All(*.*)|*.*'
    Options = [ofPathMustExist, ofFileMustExist, ofShareAware, ofNoTestFileCreate, ofEnableSizing]
    Left = 56
    Top = 104
  end
  object SaveDialog: TSaveDialog
    DefaultExt = '.OX'
    Filter = 'Object Data(*.OX)|*.OX|All(*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 56
    Top = 56
  end
end
