object Form1: TForm1
  Left = 219
  Top = 132
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Harm'#39's 3 x 3 Filter'
  ClientHeight = 449
  ClientWidth = 546
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00CCC0
    000CCCC0000000000CCCC7777CCCCCCC0000CCCC00000000CCCC7777CCCCCCCC
    C0000CCCCCCCCCCCCCC7777CCCCC0CCCCC0000CCCCCCCCCCCC7777CCCCC700CC
    C00CCCC0000000000CCCC77CCC77000C0000CCCC00000000CCCC7777C7770000
    00000CCCC000000CCCC777777777C000C00000CCCC0000CCCC77777C777CCC00
    CC00000CCCCCCCCCC77777CC77CCCCC0CCC000CCCCC00CCCCC777CCC7CCCCCCC
    CCCC0CCCCCCCCCCCCCC7CCCCCCCCCCCC0CCCCCCCCCCCCCCCCCCCCCC7CCC70CCC
    00CCCCCCCC0CC0CCCCCCCC77CC7700CC000CCCCCC000000CCCCCC777CC7700CC
    0000CCCC00000000CCCC7777CC7700CC0000C0CCC000000CCC7C7777CC7700CC
    0000C0CCC000000CCC7C7777CC7700CC0000CCCC00000000CCCC7777CC7700CC
    000CCCCCC000000CCCCCC777CC7700CC00CCCCCCCC0CC0CCCCCCCC77CC770CCC
    0CCCCCCCCCCCCCCCCCCCCCC7CCC7CCCCCCCC0CCCCCCCCCCCCCC7CCCCCCCCCCC0
    CCC000CCCCC00CCCCC777CCC7CCCCC00CC00000CCCCCCCCCC77777CC77CCC000
    C00000CCCC0000CCCC77777C777C000000000CCCC000000CCCC777777777000C
    0000CCCC00000000CCCC7777C77700CCC00CCCC0000000000CCCC77CCC770CCC
    CC0000CCCCCCCCCCCC7777CCCCC7CCCCC0000CCCCCCCCCCCCCC7777CCCCCCCCC
    0000CCCC00000000CCCC7777CCCCCCC0000CCCC0000000000CCCC7777CCC0000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 424
    Top = 137
    Width = 45
    Height = 16
    Caption = 'Divisor:'
  end
  object SpeedButton1: TSpeedButton
    Left = 509
    Top = 8
    Width = 28
    Height = 27
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
      3333333333FFFFF3333333333F797F3333333333F737373FF333333BFB999BFB
      33333337737773773F3333BFBF797FBFB33333733337333373F33BFBFBFBFBFB
      FB3337F33333F33337F33FBFBFB9BFBFBF3337333337F333373FFBFBFBF97BFB
      FBF37F333337FF33337FBFBFBFB99FBFBFB37F3333377FF3337FFBFBFBFB99FB
      FBF37F33333377FF337FBFBF77BF799FBFB37F333FF3377F337FFBFB99FB799B
      FBF373F377F3377F33733FBF997F799FBF3337F377FFF77337F33BFBF99999FB
      FB33373F37777733373333BFBF999FBFB3333373FF77733F7333333BFBFBFBFB
      3333333773FFFF77333333333FBFBF3333333333377777333333}
    NumGlyphs = 2
    OnClick = SpeedButton1Click
  end
  object Label2: TLabel
    Left = 424
    Top = 160
    Width = 32
    Height = 16
    Caption = 'Filter:'
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 105
    Height = 25
    Caption = 'Open Image'
    TabOrder = 0
    OnClick = Button1Click
  end
  object StringGrid1: TStringGrid
    Left = 23
    Top = 45
    Width = 75
    Height = 75
    BorderStyle = bsNone
    ColCount = 3
    DefaultColWidth = 24
    FixedCols = 0
    RowCount = 3
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing, goTabs, goAlwaysShowEditor]
    ScrollBars = ssNone
    TabOrder = 1
  end
  object Edit1: TEdit
    Left = 480
    Top = 128
    Width = 57
    Height = 24
    TabOrder = 2
    Text = '1'
  end
  object Button2: TButton
    Left = 424
    Top = 352
    Width = 113
    Height = 25
    Caption = 'Apply Filter'
    Enabled = False
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 424
    Top = 384
    Width = 113
    Height = 25
    Caption = 'Reset Image'
    Enabled = False
    TabOrder = 4
    OnClick = Button3Click
  end
  object ComboBox1: TComboBox
    Left = 424
    Top = 184
    Width = 113
    Height = 24
    Enabled = False
    ItemHeight = 16
    TabOrder = 5
    Text = 'Laplace'
    OnChange = ComboBox1Change
    Items.Strings = (
      'Laplace'
      'Hipass'
      'Find Edges'
      'Sharpen'
      'Edge Enhance'
      'Color Emboss'
      'Soften'
      'Blur')
  end
  object CheckBox1: TCheckBox
    Left = 118
    Top = 12
    Width = 267
    Height = 21
    Caption = 'Reset image before applying each filter'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
  object Button4: TButton
    Left = 424
    Top = 416
    Width = 113
    Height = 25
    Caption = 'Exit'
    TabOrder = 7
    OnClick = Button4Click
  end
  object rgEdge: TRadioGroup
    Left = 118
    Top = 38
    Width = 195
    Height = 83
    Caption = ' Edge Processing Options '
    ItemIndex = 0
    Items.Strings = (
      'Mirror'
      'Expand'
      'Ignore')
    TabOrder = 8
  end
  object ScrollBox1: TScrollBox
    Left = 8
    Top = 128
    Width = 409
    Height = 313
    TabOrder = 9
    object Image1: TImage
      Left = 0
      Top = 0
      Width = 405
      Height = 309
      AutoSize = True
      Stretch = True
    end
  end
  object OpenPictureDialog1: TOpenPictureDialog
    Left = 40
    Top = 160
  end
end
