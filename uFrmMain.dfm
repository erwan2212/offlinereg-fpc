object Form1: TForm1
  Left = 730
  Top = 208
  Width = 680
  Height = 480
  Caption = 'Offline Registry Editor 0.2'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object TreeView1: TTreeView
    Left = 8
    Top = 16
    Width = 281
    Height = 353
    AutoExpand = True
    Indent = 19
    ReadOnly = True
    TabOrder = 0
    OnClick = TreeView1Click
    OnDblClick = TreeView1DblClick
    OnGetSelectedIndex = TreeView1GetSelectedIndex
  end
  object Edit1: TEdit
    Left = 8
    Top = 376
    Width = 649
    Height = 21
    Color = clScrollBar
    ReadOnly = True
    TabOrder = 1
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 410
    Width = 672
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ListView1: TListView
    Left = 296
    Top = 16
    Width = 361
    Height = 353
    Columns = <
      item
        Caption = 'Name'
        Width = 100
      end
      item
        Caption = 'Value'
        Width = 100
      end
      item
        Caption = 'Type'
        Width = 100
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 3
    ViewStyle = vsReport
  end
  object OpenDialog1: TOpenDialog
    Left = 88
    Top = 248
  end
  object MainMenu1: TMainMenu
    Left = 320
    Top = 176
    object File1: TMenuItem
      Caption = 'File'
      object Open1: TMenuItem
        Caption = 'Open'
        OnClick = Open1Click
      end
      object Close1: TMenuItem
        Caption = 'Close'
        OnClick = Close1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        OnClick = Save1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Quit1: TMenuItem
        Caption = 'Quit'
        OnClick = Quit1Click
      end
    end
    object ools1: TMenuItem
      Caption = 'Tools'
      object Deleteselectedkey1: TMenuItem
        Caption = 'Delete selected key'
        OnClick = Deleteselectedkey1Click
      end
      object CreateKey1: TMenuItem
        Caption = 'CreateKey'
        OnClick = CreateKey1Click
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Deleteselectedvalue1: TMenuItem
        Caption = 'Delete selected value'
        OnClick = Deleteselectedvalue1Click
      end
      object CreateValuestring1: TMenuItem
        Caption = 'CreateValue (string)'
        OnClick = CreateValuestring1Click
      end
      object EditValue1: TMenuItem
        Caption = 'Edit selected value'
        OnClick = EditValue1Click
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Copyselectedvaluetoclipboard1: TMenuItem
        Caption = 'Copy selected value to clipboard'
        OnClick = Copyselectedvaluetoclipboard1Click
      end
      object Copypathfromselectedkeytoclipboard1: TMenuItem
        Caption = 'Copy path from selected key to clipboard'
        OnClick = Copypathfromselectedkeytoclipboard1Click
      end
    end
    object About1: TMenuItem
      Caption = 'About'
      object Me1: TMenuItem
        Caption = 'Me'
        OnClick = Me1Click
      end
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 128
    Top = 248
  end
end
