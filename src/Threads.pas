unit Threads;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, System.Math, System.SyncObjs, Vcl.ExtCtrls,
  System.Types, System.UITypes, System.Threading, System.Generics.Collections;

type
  ILogOperacoes = interface['{0D57624C-CDDE-458B-A36C-436AE465B477}']
    procedure escreveMensagem(const AValue: string);
    procedure atualizaProgresso(const ASender: TObject; const AValue: Integer);
  end;

  TListaThread = class(TThreadList<TThread>)
  strict private
    FOnNotifyItemTerminate: TProc<TThread>;
    procedure OnThreadTerminateHandler(Sender: TObject);
    procedure TerminateThread(const AThread: TThread);
    function recuperaQuantidade(): Integer;
  public
    property quantidade: Integer read RecuperaQuantidade;
    property OnNotifyItemTerminate: TProc<TThread> read FOnNotifyItemTerminate write FOnNotifyItemTerminate;
    procedure Add(const AItem: TThread);
    procedure WithLockList(const AProc: TProc<TList<TThread>>);
    procedure TerminateAll();
  end;

  TfThreads = class(TForm, ILogOperacoes)
    labThreads: TLabel;
    edtQuantidade: TEdit;
    btIniciar: TButton;
    pgrThreads: TProgressBar;
    mmoLog: TMemo;
    Label2: TLabel;
    edtIntervalo: TEdit;
    Label3: TLabel;
    procedure btIniciarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FThreadMonitoramento: TThread;
    FListaThread: TListaThread;
    function CriarThreadMonitaramento(): TThread;
  strict private
    { ILogOperacoes }
    procedure escreveMensagem(const AValue: string);
    procedure atualizaProgresso(const ASender: TObject; const AValue: Integer);
  strict private
    const
      MAX_PROGRESSO = 100;
  public
  end;

  TParametrosThread = record
  public
    IntervaloMaximo: Integer;
  end;

  TProcessoThread = class(TThread)
  strict private
    FLog: ILogOperacoes;
    FParametros: TParametrosThread;
    function ObterIntervalo(): Integer;
  strict protected
    procedure Execute(); override;
  public
    constructor Create(const ALog: ILogOperacoes; const AParametros: TParametrosThread);
    destructor Destroy(); override;
    class function New(const ALog: ILogOperacoes; const AParametros: TParametrosThread): TProcessoThread;
  end;

var
  fThreads: TfThreads;

implementation

{$R *.dfm}

procedure TfThreads.atualizaProgresso(const ASender: TObject; const AValue: Integer);
begin
  TThread.Synchronize(nil,
    procedure()
    begin
      pgrThreads.Position := pgrThreads.Position + 1;
    end);
end;

procedure TfThreads.btIniciarClick(Sender: TObject);
var
  parametrosThread: TParametrosThread;
  indice: Integer;
  numeroThreads: Integer;
begin
  mmoLog.Clear();
  pgrThreads.Position := 0;
  numeroThreads := StrToIntDef(edtQuantidade.Text, 0);
  btIniciar.Enabled := (numeroThreads = 0);
  try
    pgrThreads.Max := numeroThreads * MAX_PROGRESSO;
    parametrosThread.IntervaloMaximo := StrToIntDef(edtIntervalo.Text, 0);
    for indice := 1 to numeroThreads do
    begin
      FListaThread.Add(TProcessoThread.New(Self, parametrosThread));
    end;
  except
    btIniciar.Enabled := True;
    raise;
  end;
end;

function TfThreads.CriarThreadMonitaramento(): TThread;
begin
  Result := TThread.CreateAnonymousThread(
    procedure()
    begin
      while (not TThread.CheckTerminated()) do
      begin
        TThread.Sleep(10);
        TThread.Synchronize(nil,
          procedure()
          var
            contador: Integer;
          begin
            contador := FListaThread.quantidade;
            labThreads.Caption := Format('Threads rodando %d', [contador]);
            btIniciar.Enabled := (contador = 0);
          end);
      end;
    end);
  Result.FreeOnTerminate := False;
end;

procedure TfThreads.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
  if FListaThread.quantidade > 0 then
  begin
    if MessageDlg('Deseja encerrar todas as Threads?',mtError, mbOKCancel, 0) = mrOK then
    begin
      FListaThread.TerminateAll();
      CanClose := True;
    end;
  end
  else
   CanClose := True;
end;

procedure TfThreads.FormCreate(Sender: TObject);
begin
  FListaThread := TListaThread.Create();
  FListaThread.OnNotifyItemTerminate :=
    procedure(AThread: TThread)
    begin
      if Assigned(AThread.FatalException) then
      begin
        escreveMensagem(Format('A Thread %d finalizou com uma exceção %s', [AThread.ThreadID, Exception(AThread.FatalException).Message]));
      end;
    end;
  FThreadMonitoramento := CriarThreadMonitaramento();
  FThreadMonitoramento.Start();
end;

procedure TfThreads.FormDestroy(Sender: TObject);
begin
  FThreadMonitoramento.Terminate();
  FThreadMonitoramento.WaitFor();
  FreeAndNil(FThreadMonitoramento);
  FListaThread.TerminateAll();
  FreeAndNil(FListaThread);
end;

procedure TfThreads.escreveMensagem(const AValue: string);
begin
  TThread.Synchronize(nil,
    procedure()
    begin
      mmoLog.Lines.Add(Format('[%s] %s', [DateTimeToStr(Now()), AValue]));
    end);
end;

{ TProcessoThread }

constructor TProcessoThread.Create(const ALog: ILogOperacoes; const AParametros: TParametrosThread);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FLog := ALog;
  FParametros := AParametros;
end;

destructor TProcessoThread.Destroy();
begin
  inherited Destroy();
end;

procedure TProcessoThread.Execute();
var
  progresso: Integer;
begin
  Randomize();
  FLog.escreveMensagem(Format('%d - Iniciando processamento', [ThreadID]));
  for progresso := 0 to 100 do
  begin
    if Terminated then
      Break;
    TThread.Sleep(ObterIntervalo());
    FLog.atualizaProgresso(Self, progresso);
  end;
  FLog.escreveMensagem(Format('%d - Processamento finalizado', [ThreadID]));
end;

class function TProcessoThread.New(const ALog: ILogOperacoes; const AParametros: TParametrosThread): TProcessoThread;
begin
  Result := TProcessoThread.Create(ALog, AParametros);
  Result.Start();
end;

function TProcessoThread.ObterIntervalo(): Integer;
begin
  Result := Random(FParametros.IntervaloMaximo);
end;

{ TListaThread<T> }

procedure TListaThread.Add(const AItem: TThread);
begin
  AItem.OnTerminate := OnThreadTerminateHandler;
  inherited Add(AItem);
end;

function TListaThread.recuperaQuantidade(): Integer;
var
  LResult: Integer;
begin
  WithLockList(
    procedure(AList: TList<TThread>)
    begin
      LResult := AList.Count;
    end);
  Result := LResult;
end;

procedure TListaThread.TerminateAll();
begin
  WithLockList(
    procedure(AList: TList<TThread>)
    begin
      while (AList.Count > 0) do
      begin
        TerminateThread(AList.ExtractAt(0));
      end;
    end);
end;

procedure TListaThread.TerminateThread(const AThread: TThread);
begin
  AThread.FreeOnTerminate := False;
  AThread.Terminate();
  AThread.WaitFor();
  AThread.DisposeOf();
end;

procedure TListaThread.OnThreadTerminateHandler(Sender: TObject);
begin
  FOnNotifyItemTerminate(TThread(Sender));
  Remove(TThread(Sender));
end;

procedure TListaThread.WithLockList(const AProc: TProc<TList<TThread>>);
var
  LList: TList<TThread>;
begin
  LList := LockList();
  try
    AProc(LList);
  finally
    UnlockList();
  end;
end;

end.

