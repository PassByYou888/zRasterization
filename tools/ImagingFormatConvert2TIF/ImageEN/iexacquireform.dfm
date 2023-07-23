object iexAcquireForm: TiexAcquireForm
  Left = 873
  Top = 351
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'Select Acquire Device'
  ClientHeight = 266
  ClientWidth = 314
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 314
    Height = 266
    Align = alClient
  end
  object lblCaption: TLabel
    Left = 12
    Top = 10
    Width = 135
    Height = 13
    Caption = 'Select an acquisition device:'
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 220
    Width = 314
    Height = 45
    BevelOuter = bvNone
    TabOrder = 1
    object btnOK: TBitBtn
      Left = 134
      Top = 8
      Width = 80
      Height = 25
      Caption = 'OK'
      Default = True
      Enabled = False
      ModalResult = 1
      TabOrder = 0
      OnClick = btnOKClick
      Glyph.Data = {
        36060000424D3606000000000000360000002800000020000000100000000100
        18000000000000060000C40E0000C40E00000000000000000000FF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FF006600006600FF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF656565656565FF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FF0066001EB2311FB133006600FF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6565659A9A9A9A9A9A65
        6565FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FF00660031C24F22B7381AB02D21B437006600FF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF656565ABABAB9E9E9E9797979C
        9C9C656565FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        00660047D36D3BCB5E25A83B0066001BA92E1DB132006600FF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FF656565BFBFBFB5B5B598989865656594
        9494999999656565FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF006600
        4FD67953DE7F31B54D006600FF00FF006600179D271EAE31006600FF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FF656565C4C4C4CACACAA5A5A5656565FF00FF65
        65658C8C8C989898656565FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        00660041C563006600FF00FFFF00FFFF00FFFF00FF00660019AA2B006600FF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FF656565B5B5B5656565FF00FFFF00FFFF
        00FFFF00FF656565939393656565FF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FF006600FF00FFFF00FFFF00FFFF00FFFF00FFFF00FF006600149D210066
        00FF00FFFF00FFFF00FFFF00FFFF00FFFF00FF656565FF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FF6565658A8A8A656565FF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF0066
        00006600FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FF656565656565FF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FF006600006600FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FF656565656565FF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
      NumGlyphs = 2
    end
    object btnCancel: TBitBtn
      Left = 220
      Top = 8
      Width = 81
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
      Glyph.Data = {
        36060000424D3606000000000000360000002800000020000000100000000100
        18000000000000060000C40E0000C40E00000000000000000000FF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FF00009A00009AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF00009A0000
        9AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6B6B6B6BFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FF6B6B6B6B6B6BFF00FFFF00FFFF00FFFF00FFFF00FF
        00009A174AFD103BF400009AFF00FFFF00FFFF00FFFF00FF00009A002CF80030
        FC00009AFF00FFFF00FFFF00FFFF00FF6B6B6BA8A8A8A0A0A06B6B6BFF00FFFF
        00FFFF00FFFF00FF6B6B6B9A9A9A9C9C9C6B6B6BFF00FFFF00FFFF00FFFF00FF
        00009A1A47F81A4CFF123BF100009AFF00FFFF00FF00009A012DF60132FF002A
        F300009AFF00FFFF00FFFF00FFFF00FF6B6B6BA7A7A7AAAAAA9F9F9F6B6B6BFF
        00FFFF00FF6B6B6B9999999E9E9E9797976B6B6BFF00FFFF00FFFF00FFFF00FF
        FF00FF00009A1C47F61B4DFF143EF400009A00009A002DF80134FF032BF20000
        9AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BA7A7A7ABABABA2A2A26B
        6B6B6B6B6B9A9A9A9E9E9E9898986B6B6BFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FF00009A1D48F61D50FF103DFB0431FE0132FF002CF600009AFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BA7A7A7ACACACA3
        A3A39F9F9F9E9E9E9999996B6B6BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FF00009A1A48F91342FF0C3CFF0733F600009AFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BA7A7A7A7
        A7A7A3A3A39C9C9C6B6B6BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FF00009A214EFC1D4BFF1847FF1743F600009AFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BACACACAC
        ACACA9A9A9A4A4A46B6B6BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FF00009A2E5BF92C5FFF224DF8204BF82355FF1B46F600009AFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BB1B1B1B3B3B3AB
        ABABAAAAAAAFAFAFA6A6A66B6B6BFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FF00009A3664FA386BFF2D59F400009A00009A224CF42558FF1D49F60000
        9AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6BB6B6B6B9B9B9AEAEAE6B
        6B6B6B6B6BA9A9A9B0B0B0A7A7A76B6B6BFF00FFFF00FFFF00FFFF00FFFF00FF
        00009A4071FA4274FF325DF100009AFF00FFFF00FF00009A224DF1275AFF204C
        F800009AFF00FFFF00FFFF00FFFF00FF6B6B6BBBBBBBBEBEBEAFAFAF6B6B6BFF
        00FFFF00FF6B6B6BA7A7A7B1B1B1AAAAAA6B6B6BFF00FFFF00FFFF00FFFF00FF
        00009A497AFC3B66F300009AFF00FFFF00FFFF00FFFF00FF00009A2550F42655
        FA00009AFF00FFFF00FFFF00FFFF00FF6B6B6BC0C0C0B5B5B56B6B6BFF00FFFF
        00FFFF00FFFF00FF6B6B6BAAAAAAAEAEAE6B6B6BFF00FFFF00FFFF00FFFF00FF
        FF00FF00009A00009AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF00009A0000
        9AFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF6B6B6B6B6B6BFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FF6B6B6B6B6B6BFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF
        FF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00
        FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF
        00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FFFF00FF}
      NumGlyphs = 2
    end
  end
  object lbxSources: TListBox
    Left = 12
    Top = 31
    Width = 289
    Height = 185
    Style = lbOwnerDrawFixed
    ItemHeight = 18
    TabOrder = 0
    OnClick = lbxSourcesClick
    OnDrawItem = lbxSourcesDrawItem
  end
  object imlDevices: TImageList
    Left = 244
    Top = 64
    Bitmap = {
      494C010103000400040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000949494009C9C
      9C009494940094949400ADADAD00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000847B84008484840000000000000000000000
      0000000000000000000000000000000000000000000094949400CECECE00D6D6
      D600BDBDBD00CECECE00C6C6C6009494940094949400ADADAD00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000004A4A4A004A4A4A004A4A4A004A4A4A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00009CBDA5009CA59C009CBDA500BDC6C600847B7B0073636300ADADAD000000
      00000000000000000000000000000000000094949400CECECE00B5B5B500C6C6
      C600BDBDBD00BDBDBD00C6C6C600F7F7F700F7F7F700D6D6D600949494009494
      9400ADADAD000000000000000000000000000000000000000000000000000000
      00004A4A4A008C848400B5B5B500C6C6C6009C9C9C004A4A4A004A4A4A004A4A
      4A00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000008C8C8C006B6B
      6B0084848400E7E7E700CEE7D600C6CECE00ADA5A500AD9494009C7B7B008473
      7300A5A5A50000000000000000000000000094949400C6C6C600D6D6D600C6C6
      C600BDBDBD00BDBDBD00B5B5B500E7E7E700B5B5B5009C9C9C007B7B7B008C8C
      8C00BDBDBD0094949400ADADAD00000000000000000000000000000000004A4A
      4A008C8C8C009C949C00736B7300A5A5A500D6D6D600FFFFFF00EFEFEF00BDB5
      B5004A4A4A004A4A4A004A4A4A00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000009C9C9C00B5B5B500B5B5B500ADAD
      B500CECED600E7E7E700E7DED600E7E7D600D6CECE00B5ADAD00BDA5A500C69C
      9C00AD7B7B007B6B6B009CA5A5000000000094949400C6C6C600DEDEDE00C6C6
      C600C6C6C600C6C6C600C6C6C600CECECE00A5A5A500525252004A4A4A004A4A
      4A006B6B6B00C6C6C600DEDEDE00ADADAD0000000000000000004A4A4A008C84
      8C008C8C8C00A59CA5006B6B6B006B6B6B008C8C8C0094949400A5A5A500B5B5
      B500E7E7E700A5A5A500D6D6D600848484000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000B5B5B500E7EFEF00F7F7EF00F7EF
      EF00EFE7E700EFEFE700F7D6B500FFF7E700FFF7E700F7C69C00C6AD9400B59C
      9400C69CA500DE949C00BD7B7B007B63630094949400C6C6C600DEDEDE00C6C6
      C600C6C6C600C6C6C600C6C6C600C6C6C6007B7B7B00525252004A4A4A004A4A
      4A00525252009C9C9C00D6D6D60094949400000000004A4A4A00DED6DE00D6D6
      D600ADA5AD009C949C00B5B5B5009C9C9C006B6B6B006B6B6B006B6B6B006B6B
      6B00949494009C9C9C006B6B6B006B6B6B000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000DEDEDE00D6CEC600E7C6
      A500F7E7CE00FFFFF700FFDEB500FFF7E700FFF7E700FFCE9400FFB56B00E7A5
      5200BD8C5200AD846300BD848400B573730094949400C6C6C600E7E7E700C6C6
      C600C6C6C600BDBDBD00C6C6C600CECECE00737373004A4A4A00946331009C63
      21005252520084848400CECECE00949494004A4A4A00ADA5AD00E7DEE700E7DE
      E700EFEFEF00737373007373730094949400BDBDBD00C6C6C600BDBDBD00ADA5
      AD006B6B6B006B6B6B00737373006B6B6B000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000CECE
      C600B5B5B500BDBDBD00D6BDA500EFE7D600FFF7E700FFCE9400FFBD7300DE9C
      4A00AD733100846339008C6B6B009C6B6B0094949400CECECE00E7E7E700CECE
      CE00CECECE00C6C6C600C6C6C600D6D6D6008C8C8C005A5A5A006B5A4A007B63
      4A00525252008C8C8C00C6C6C600949494004A4A4A00F7F7F700EFEFEF00F7FF
      FF00EFEFEF00EFEFEF00D6D6D600A59CA500847B8400737373007B7B7B009C9C
      9C00BDBDBD00CECECE00A5A5A5004A4A4A000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000ADB5AD00A59C9400AD947B007B6B5A006B5A
      520094737300B5848C00CE9494000000000094949400CECECE00F7F7F700CECE
      CE00CECECE00CECECE00BDBDBD00C6C6C600D6D6D60063636300636363005A5A
      5A0063636300C6C6C600BDBDBD00949494004A4A4A00FFFFFF00FFFFFF00F7FF
      FF00F7FFFF00EFEFEF00E7E7EF00E7DEE700D6D6D600C6C6C600ADA5AD00847B
      7B006B6B6B00737373006B6B6B00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000ADADAD007373730042424200524A52008C737300AD8C
      8C00BD9C9C0000000000000000000000000094949400DEDEDE00DEDEDE00D6D6
      D600BDBDBD00A5A5A500A5A5A500B5B5B500D6D6D600DEDEDE00848484007B7B
      7B00C6C6C600C6C6C600B5B5B500949494004A4A4A00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00F7FFFF00EFE7EF00E7DEE700D6D6D600CEC6CE00C6C6C600ADA5
      AD004A4A4A004A4A4A0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000009494
      94007B7B7B007B7B7B0084848400ADADAD00BDBDBD00A59C9C00AD9C9C000000
      00000000000000000000000000000000000094949400D6D6D600EFEFEF00FFFF
      FF00CECECE009C9C9C00ADADAD00ADADAD00ADADAD00ADADAD00D6D6D600D6D6
      D6009C9C9C009C9C9C00ADADAD00949494005A5A5A005A5A5A005A5A5A00EFEF
      EF00E7E7E700F7F7F700F7F7F700EFE7EF00DEDEDE00C6C6C6008C848C004A4A
      4A00000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000CECECE00A5A5A500BDBD
      BD00D6CECE00EFDEDE00EFF7F700D6D6D600BDBDBD00BDBDBD00000000000000
      000000000000000000000000000000000000ADADAD00FFFFFF00E7E7E7007B7B
      7B009C9C9C009C9C9C007B7B7B00ADADAD009C9C9C007B7B7B008C8C8C009494
      94005A5A5A005A5A5A0073737300949494000000000000000000000000005A5A
      5A004A4A4A004A4A4A00ADA5AD00A5A5A500A5A5A5004A4A4A00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000D6D6D600BDBDBD00C6C6
      C600BD848400BD8C8C00ADADAD00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000ADADAD009494
      94009C9C9C00B5B5B500E7E7E700F7F7F700EFEFEF00D6D6D6009C9C9C008C8C
      8C00848484007373730094949400ADADAD000000000000000000000000000000
      000000000000000000004A4A4A004A4A4A004A4A4A0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000ADADAD009494940094949400949494009494
      940094949400ADADAD0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFFFFFF0000FFFFC1FFFFFF0000
      FE7F803FF87F0000F01F0007F00F0000C0070001E001000000010000C0000000
      00000000800000008000000000000000E000000000000000FE01000000010000
      FC07000000030000E01F0000000F0000803F0000E03F000081FFC000FC7F0000
      FFFFFE03FFFF0000FFFFFFFFFFFF000000000000000000000000000000000000
      000000000000}
  end
end
