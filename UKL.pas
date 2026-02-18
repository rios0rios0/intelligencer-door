unit UKL;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Menus;

type
  TFrmKeyLogger = class(TForm)
    Pm: TPopupMenu;
    mnilimpar: TMenuItem;
    mnisalvar: TMenuItem;
    Mmo: TMemo;
    MniAtualizar: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure mnilimparClick(Sender: TObject);
    procedure mnisalvarClick(Sender: TObject);
    procedure MniAtualizarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmKeyLogger: TFrmKeyLogger;

implementation

uses UID;

{$R *.dfm}

procedure TFrmKeyLogger.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  mmo.Clear;
  Frm33585IDPrincipal.TmrModal.Enabled := False;
  EnableWindow(Frm33585IDPrincipal.Handle, True);
end;

procedure TFrmKeyLogger.FormActivate(Sender: TObject);
begin
  FrmKeyLogger.Caption := 'KeyLogger - '+
  Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1];
end;

procedure TFrmKeyLogger.mnilimparClick(Sender: TObject);
begin
  mmo.Clear;
end;

procedure TFrmKeyLogger.mnisalvarClick(Sender: TObject);
begin
  if not DirectoryExists(GetCurrentDir + '\Loggers') then
    CreateDir(GetCurrentDir + '\Loggers');
  mmo.Lines.SaveToFile(GetCurrentDir + '\Loggers\'
  + 'Logs - ' + Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1] + '.txt');
  mmo.Lines.Clear;
end;

procedure TFrmKeyLogger.MniAtualizarClick(Sender: TObject);
begin
  Frm33585IDPrincipal.Mnikeylogger.Click;
end;

end.
