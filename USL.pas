unit USL;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Menus;

type
  TFrmScreenLogger = class(TForm)
    ImgScnLogger: TImage;
    Pm: TPopupMenu;
    MniAtualizar: TMenuItem;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MniAtualizarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmScreenLogger: TFrmScreenLogger;

implementation

{$R *.dfm}

uses UID;

procedure TFrmScreenLogger.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Frm33585IDPrincipal.TmrModal.Enabled := False;
  EnableWindow(Frm33585IDPrincipal.Handle, True);
  ImgScnLogger.Picture := nil;
end;

procedure TFrmScreenLogger.FormActivate(Sender: TObject);
begin
  FrmScreenLogger.Caption := 'ScreenLogger - '+
  Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1];
end;

procedure TFrmScreenLogger.MniAtualizarClick(Sender: TObject);
begin
  Frm33585IDPrincipal.Mniscreenlogger.Click;
end;

end.
