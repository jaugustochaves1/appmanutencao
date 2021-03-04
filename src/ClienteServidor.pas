unit ClienteServidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Datasnap.DBClient, Data.DB,
  System.NetEncoding, System.ZLib, Datasnap.DSIntf, System.Generics.Collections, System.Generics.Defaults,
  System.IOUtils, System.SyncObjs, System.Threading;

type
  TServidor = class
  private
    FPath: string;
  public
    constructor Create;
    //Tipo do parâmetro não pode ser alterado
    function SalvarArquivos(AData: OleVariant): Boolean;
  end;

  TfClienteServidor = class(TForm)
    ProgressBar: TProgressBar;
    btEnviarSemErros: TButton;
    btEnviarComErros: TButton;
    btEnviarParalelo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btEnviarSemErrosClick(Sender: TObject);
    procedure btEnviarComErrosClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btEnviarParaleloClick(Sender: TObject);
  private
    FPath: string;
    FServidor: TServidor;
    function InitDataset: TClientDataset;
  public
  end;

  TDirectoryHelper = record helper for TDirectory
  public
    class procedure DeleteFiles(const APath: string); static;
  end;

  TProcessamentoServidor = class(TThread)
  strict private
    FServidor: TServidor;
    FData: OleVariant;
  strict protected
    procedure Execute(); override;
  public
    constructor Create(const AData: OleVariant); reintroduce; overload;
    destructor Destroy(); override;
    class function New(const AData: OleVariant): TProcessamentoServidor;
  end;

var
  fClienteServidor: TfClienteServidor;

const
  QTD_ARQUIVOS_ENVIAR = 100;

implementation

{$R *.dfm}

procedure TfClienteServidor.btEnviarComErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
  totalBlobSize: Integer;
begin
  totalBlobSize := 0;
  ProgressBar.Position := 0;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  cds := InitDataset;
  try
    for i := 0 to QTD_ARQUIVOS_ENVIAR do
    begin
      cds.Append;
      cds.FieldByName('RecNo').AsInteger := i + 1;
      TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPath);
      totalBlobSize := totalBlobSize + TBlobField(cds.FieldByName('Arquivo')).BlobSize;
      cds.Post;

      {$REGION Simulação de erro, não alterar}
      if i = (QTD_ARQUIVOS_ENVIAR/2) then
        FServidor.SalvarArquivos(NULL);
      {$ENDREGION}

      if (totalBlobSize > 102400000) then
      begin
        totalBlobSize := 0;
        FServidor.SalvarArquivos(cds.Data);
        cds.EmptyDataSet();
      end;

      ProgressBar.Position := ProgressBar.Position + 1;
      Application.ProcessMessages();
    end;

    if (totalBlobSize > 0) then
      FServidor.SalvarArquivos(cds.Data);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TfClienteServidor.btEnviarParaleloClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
begin
  ProgressBar.Position := 0;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  cds := InitDataset();
  try
    for i := 0 to QTD_ARQUIVOS_ENVIAR do
    begin
      cds.Append();
      cds.FieldByName('RecNo').AsInteger := i + 1;
      TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPath);
      cds.Post();
      TProcessamentoServidor.New(cds.Data).Start();
      cds.EmptyDataSet();
      ProgressBar.Position := ProgressBar.Position + 1;
      Application.ProcessMessages();
    end;
  finally
    FreeAndNil(cds);
  end;
{begin
  ProgressBar.Position := 0;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  TParallel.for (0, 1, QTD_ARQUIVOS_ENVIAR,
    procedure(i: Integer)
    var
      cds: TClientDataset;
    begin
      cds := InitDataset();
      try
        cds.Append();
        cds.FieldByName('RecNo').AsInteger := i + 1;
        TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPath);
        cds.Post();
        TProcessamentoServidor.New(cds.Data).Start();
        TThread.Synchronize(nil,
          procedure()
          begin
            ProgressBar.Position := ProgressBar.Position + 1;
          end);
      finally
        FreeAndNil(cds);
      end;
    end);}
end;

procedure TfClienteServidor.btEnviarSemErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
  LTotalBlobSize: Integer;
begin
  LTotalBlobSize := 0;
  ProgressBar.Position := 0;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
  cds := InitDataset;
  try
    for i := 0 to QTD_ARQUIVOS_ENVIAR do
    begin
      cds.Append;
      cds.FieldByName('RecNo').AsInteger := i + 1;
      TBlobField(cds.FieldByName('Arquivo')).LoadFromFile(FPath);
      LTotalBlobSize := LTotalBlobSize + TBlobField(cds.FieldByName('Arquivo')).BlobSize;
      cds.Post;

      if (LTotalBlobSize > 102400000) then
      begin
        LTotalBlobSize := 0;
        FServidor.SalvarArquivos(cds.Data);
        cds.EmptyDataSet();
      end;

      ProgressBar.Position := ProgressBar.Position + 1;
      Application.ProcessMessages();
    end;

    if (LTotalBlobSize > 0) then
      FServidor.SalvarArquivos(cds.Data);
  finally
    FreeAndNil(cds);
  end;
end;

procedure TfClienteServidor.FormCreate(Sender: TObject);
begin
  inherited;
  FPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'pdf.pdf';
  FServidor := TServidor.Create;
end;

procedure TfClienteServidor.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FServidor);
end;


function TfClienteServidor.InitDataset: TClientDataset;
begin
  Result := TClientDataset.Create(nil);
  Result.FieldDefs.Add('Arquivo', ftBlob);
  Result.FieldDefs.Add('RecNo', ftInteger);
  Result.CreateDataSet;
end;

{ TServidor }

constructor TServidor.Create;
begin
  FPath := ExtractFilePath(ParamStr(0)) + 'Servidor\';
end;

function TServidor.SalvarArquivos(AData: OleVariant): Boolean;
var
  cds: TClientDataSet;
  FileName: string;
begin
  Result := False;
  TDirectory.CreateDirectory(FPath);
  TDirectory.DeleteFiles(FPath);
  try
    cds := TClientDataset.Create(nil);
    try
      cds.Data := AData;

      {$REGION Simulação de erro, não alterar}
      if cds.RecordCount = 0 then
        Exit;
      {$ENDREGION}

      cds.First;

      while not cds.Eof do
      begin
        FileName := FPath + cds.FieldByName('RecNo').AsString + '.pdf';
        if TFile.Exists(FileName) then
          TFile.Delete(FileName);

        TBlobField(cds.FieldByName('Arquivo')).SaveToFile(FileName);
        cds.Next;
      end;
    finally
      FreeAndNil(cds);
    end;

    Result := True;
  except
    TDirectory.DeleteFiles(FPath);
    raise;
  end;
end;

{ TDirectoryHelper }

class procedure TDirectoryHelper.DeleteFiles(const APath: string);
var
  LFileName: string;
begin
  for LFileName in GetFiles(APath) do
  begin
    try
      TFile.Delete(LFileName);
    except
      on EInOutError do;
      on Exception do raise;
    end;
  end;
end;

{ TProcessamentoServidor }

constructor TProcessamentoServidor.Create(const AData: OleVariant);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FData := AData;
  FServidor := TServidor.Create();
end;

destructor TProcessamentoServidor.Destroy();
begin
  FData := Null;
  FreeAndNil(FServidor);
  inherited Destroy();
end;

procedure TProcessamentoServidor.Execute();
begin
  Synchronize(
    procedure()
    begin
      FServidor.SalvarArquivos(FData);
    end);
end;

class function TProcessamentoServidor.New(const AData: OleVariant): TProcessamentoServidor;
begin
  Assert((VarIsNull(AData).ToInteger() + VarIsEmpty(AData).ToInteger()) = 0);
  Result := TProcessamentoServidor.Create(AData);
end;

end.
