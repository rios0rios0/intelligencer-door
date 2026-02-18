unit MyUtils;

interface

uses Windows, TlHelp32;

const
  PathDelim  = {$IFDEF MSWINDOWS} '\'; {$ELSE} '/'; {$ENDIF}
  DriveDelim = {$IFDEF MSWINDOWS} ':'; {$ELSE} '';  {$ENDIF}
  PathSep    = {$IFDEF MSWINDOWS} ';'; {$ELSE} ':'; {$ENDIF}

function GetProcessIDbyName(ProcessName: string): DWORD;
function WriteStringToProcess(hProcess: Cardinal; S: string): Pointer;
function WriteDataToProcess(hProcess, dwSize: Cardinal; RemoteWriteData: Pointer): Pointer;
function UpperCase(const S: string): string;
function LowerCase(const S: string): string;
function Trim(const S: string): string;
function TestDrive(Drive: Char): Boolean;
function IntToHex(Value: LongInt; Digits: Integer): string;
function IntToStr(Value: Integer): ShortString;
function StrToInt(Value: ShortString): Integer;
function StrPCopy(Dest: PChar; const Source: string): PChar;
function FileExists(FileName: string): Boolean;
function ExtractFileName(const FileName: string): string;
function GetCurrentDir: string;

implementation

function GetProcessIDbyName(ProcessName: string): DWORD;
 var
  MyHandle: THandle;
  Struct: TProcessEntry32;
begin
  Result := 0;
  ProcessName := LowerCase(ProcessName);
  try
    MyHandle := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
    Struct.dwSize := Sizeof(TProcessEntry32);
    if Process32First(MyHandle, Struct) then
    if ProcessName = LowerCase(Struct.szExeFile) then
    begin
      Result := Struct.th32ProcessID;
      Exit;
    end;
    while Process32Next(MyHandle, Struct) do
    if ProcessName = LowerCase(Struct.szExeFile) then
    begin
      Result := Struct.th32ProcessID;
      Exit;
    end;
  except
    Exit;
  end;
end;

function WriteStringToProcess(hProcess: Cardinal; S: string): Pointer;
 var
  BytesWritten: Cardinal;
begin
  Result := VirtualAllocEx(hProcess, nil, Length(S) + 1, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  WriteProcessMemory(hProcess, Result, PChar(S), Length(S) + 1, BytesWritten);
end;

function WriteDataToProcess(hProcess, dwSize: Cardinal; RemoteWriteData: Pointer): Pointer;
 var
  BytesWritten: Cardinal;
begin
  Result := VirtualAllocEx(hProcess, nil, dwSize, MEM_COMMIT or MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  WriteProcessMemory(hProcess, Result, RemoteWriteData, dwSize, BytesWritten);
end;

function UpperCase(const S: string): string;
 var
  I: Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
    if Result[I] in ['a'..'z'] then
       Dec(Result[I], 32);
end;

function LowerCase(const S: string): string;
 var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while (L <> 0) do
  begin
    Ch := Source^;
    if (Ch >= 'A') and (Ch <= 'Z') then
      Inc(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

function Trim(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= ' ' do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;

function InternalGetDiskSpace(Drive: Byte;
  var TotalSpace, FreeSpaceAvailable: Int64): Bool;
 var
  RootPath: array[0..4] of Char;
  RootPtr: PChar;
begin
  RootPtr := nil;
  if (Drive > 0) then
  begin
    RootPath[0] := Char(Drive + $40);
    RootPath[1] := ':';
    RootPath[2] := '\';
    RootPath[3] := #0;
    RootPtr := RootPath;
  end;
  Result := GetDiskFreeSpaceEx(RootPtr, FreeSpaceAvailable, TotalSpace, nil);
end;

function DiskSize(Drive: Byte): Int64;
 var
  FreeSpace: Int64;
begin
  if not InternalGetDiskSpace(Drive, Result, FreeSpace) then
    Result := -1;
end;

function TestDrive(Drive: Char): Boolean;
 var
  I: Byte;
begin
  I := Ord(Drive) - 64;
  Result := DiskSize(I) >= 0;
end;

function IntToHex(Value: LongInt; Digits: Integer): string;
 var
  Res: string;
begin
  if (Value = 0) then
    Res := StringOfChar('0', Digits);
  if (Value < 0) then
    Res := StringOfChar('F', 16);

  while (Value > 0) do
  begin
    case (Value mod 16) of
      10: Res := 'A' + Res;
      11: Res := 'B' + Res;
      12: Res := 'C' + Res;
      13: Res := 'D' + Res;
      14: Res := 'E' + Res;
      15: Res := 'F' + Res;
    else
      Res := IntToStr(Value mod 16) + Res;
    end;
    Value := Value div 16;
  end;
  if ((Digits > 1) and (Length(Res) < Digits)) then
  begin
    Res := StringOfChar('0', (Digits - Length(Res))) + Res;
  end;
  Result := Res;
end;

function IntToStr(Value: Integer): ShortString;
// Value  = eax
// Result = edx
asm
  push ebx
  push esi
  push edi

  mov edi,edx
  xor ecx,ecx
  mov ebx,10
  xor edx,edx

  cmp eax,0 // check for negative
  setl dl
  mov esi,edx
  jnl @reads
  neg eax

  @reads:
    mov  edx,0   // edx = eax mod 10
    div  ebx     // eax = eax div 10
    add  edx,48  // '0' = #48
    push edx
    inc  ecx
    cmp  eax,0
  jne @reads

  dec esi
  jnz @positive
  push 45 // '-' = #45
  inc ecx

  @positive:
  mov [edi],cl // set length byte
  inc edi

  @writes:
    pop eax
    mov [edi],al
    inc edi
    dec ecx
  jnz @writes

  pop edi
  pop esi
  pop ebx
end;

function StrToInt(Value: ShortString): Integer;
// Value   = eax
// Result  = eax
asm
  push ebx
  push esi

  mov esi,eax
  xor eax,eax
  movzx ecx,Byte([esi]) // read length byte
  cmp ecx,0
  je @exit

  movzx ebx,Byte([esi+1])
  xor edx,edx // edx = 0
  cmp ebx,45  // check for negative '-' = #45
  jne @loop

  dec edx // edx = -1
  inc esi // skip '-'
  dec ecx

  @loop:
    inc   esi
    movzx ebx,Byte([esi])
    imul  eax,10
    sub   ebx,48 // '0' = #48
    add   eax,ebx
    dec   ecx
  jnz @loop

  mov ecx,eax
  and ecx,edx
  shl ecx,1
  sub eax,ecx

  @exit:
  pop esi
  pop ebx
end;

function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     EBX,ECX
        XOR     AL,AL
        TEST    ECX,ECX
        JZ      @@1
        REPNE   SCASB
        JNE     @@1
        INC     ECX
@@1:    SUB     EBX,ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,EDI
        MOV     ECX,EBX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EBX
        AND     ECX,3
        REP     MOVSB
        STOSB
        MOV     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;

function StrPCopy(Dest: PChar; const Source: string): PChar;
begin
  Result := StrLCopy(Dest, PChar(Source), Length(Source));
end;

function FileExists(FileName: string): Boolean;
 var
  FndData: TWin32FindData;
  fndHandle: Integer;
  ErrorMode: Word;
begin
  Result := False;
  ErrorMode := SetErrorMode(SEM_FailCriticalErrors);
  fndHandle := FindFirstFile(PChar(FileName), FndData);
  SetErrorMode(ErrorMode);
  if fndHandle <> Integer( INVALID_HANDLE_VALUE ) then
  begin
    Windows.FindClose(fndHandle);
    if (FndData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
       Result := True;
  end;
end;

function StrScan(const Str: PChar; Chr: Char): PChar; assembler;
asm
        PUSH    EDI
        PUSH    EAX
        MOV     EDI,Str
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        POP     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        DEC     EAX
@@1:    POP     EDI
end;

function LastDelimiter(const Delimiters, S: string): Integer;
 var
  P: PChar;
begin
  Result := Length(S);
  P := PChar(Delimiters);
  while Result > 0 do
  begin
    if (S[Result] <> #0) and (StrScan(P, S[Result]) <> nil) then
        Exit;
    Dec(Result);
  end;
end;

function ExtractFileName(const FileName: string): string;
var
  I: Integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, I + 1, MaxInt);
end;

function GetCurrentDir: string;
begin
  GetDir(0, Result);
end;

end.
