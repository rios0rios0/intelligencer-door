object FrmScreenLogger: TFrmScreenLogger
  Left = 381
  Top = 608
  Width = 612
  Height = 228
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Screen Logger - '
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
  object ImgScnLogger: TImage
    Left = 0
    Top = 0
    Width = 598
    Height = 192
    Hint = 'Click Com a Direita Para Op'#231#245'es'
    Align = alClient
    AutoSize = True
    ParentShowHint = False
    PopupMenu = Pm
    ShowHint = True
  end
  object Pm: TPopupMenu
    Left = 8
    Top = 8
    object MniAtualizar: TMenuItem
      Caption = 'Atualizar'
      OnClick = MniAtualizarClick
    end
  end
end
