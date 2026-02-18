unit UDG;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Menus;

type
  TFrmDiagnostico = class(TForm)
    Mmo: TMemo;
    Pm1: TPopupMenu;
    MniSalvar: TMenuItem;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MniSalvarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmDiagnostico: TFrmDiagnostico;

implementation

uses UID;

{$R *.dfm}

procedure TFrmDiagnostico.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Mmo.Clear;
  Frm33585IDPrincipal.TmrModal.Enabled := False;
  EnableWindow(Frm33585IDPrincipal.Handle, True);
end;

procedure TFrmDiagnostico.FormActivate(Sender: TObject);
begin
  FrmDiagnostico.Caption := 'Diagnóstico - ' +
  Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1];
end;

procedure TFrmDiagnostico.MniSalvarClick(Sender: TObject);
begin
  if not DirectoryExists(GetCurrentDir + '\Loggers') then
    CreateDir(GetCurrentDir + '\Loggers');
  Mmo.Lines.SaveToFile(GetCurrentDir + '\Loggers\'
  + 'Diagnóstico - ' + Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1] + '.txt');
end;

end.
