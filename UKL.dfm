object FrmKeyLogger: TFrmKeyLogger
  Left = 380
  Top = 369
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'KeyLogger - '
  ClientHeight = 192
  ClientWidth = 598
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Times New Roman'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poDesktopCenter
  OnActivate = FormActivate
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 15
  object Mmo: TMemo
    Left = 0
    Top = 0
    Width = 598
    Height = 192
    Hint = 'Click Com a Direita Para Op'#231#245'es'
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    PopupMenu = Pm
    ReadOnly = True
    ScrollBars = ssVertical
    ShowHint = True
    TabOrder = 0
  end
  object Pm: TPopupMenu
    Left = 16
    Top = 8
    object mnisalvar: TMenuItem
      Caption = 'Salvar Log'
      OnClick = mnisalvarClick
    end
    object mnilimpar: TMenuItem
      Caption = 'Limpar Log'
      OnClick = mnilimparClick
    end
    object MniAtualizar: TMenuItem
      Caption = 'Atualizar Log'
      OnClick = MniAtualizarClick
    end
  end
end
