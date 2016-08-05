object frmMain: TfrmMain
  Left = 0
  Top = 0
  ActiveControl = pc1
  Caption = 'Form'
  ClientHeight = 434
  ClientWidth = 662
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pc1: TRfPageControl
    Left = 0
    Top = 0
    Width = 662
    Height = 434
    ActivePage = tsCar
    Align = alClient
    TabOrder = 0
    ShowSearchFilter = True
    object tsCar: TTabSheet
      Caption = 'Car'
    end
    object ts2: TTabSheet
      Caption = 'Person'
      ImageIndex = 1
    end
    object ts3: TTabSheet
      Caption = 'Color of Car'
      ImageIndex = 2
    end
    object ts4: TTabSheet
      Caption = 'Kind of Water'
      ImageIndex = 3
    end
    object ts5: TTabSheet
      Caption = 'Delphi Programming'
      ImageIndex = 4
    end
    object ts6: TTabSheet
      Caption = 'Stack'
      ImageIndex = 5
    end
    object ts7: TTabSheet
      Caption = 'Component'
      ImageIndex = 6
    end
    object ts8: TTabSheet
      Caption = 'Window'
      ImageIndex = 7
    end
    object ts1: TTabSheet
      Caption = 'Brazil'
      ImageIndex = 8
    end
    object ts9: TTabSheet
      Caption = 'Street'
      ImageIndex = 9
    end
  end
end
