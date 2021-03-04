unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IOUtils;

type
  TfMain = class(TForm)
    btDatasetLoop: TButton;
    btThreads: TButton;
    btStreams: TButton;
    procedure btDatasetLoopClick(Sender: TObject);
    procedure btStreamsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btThreadsClick(Sender: TObject);
  private
    function ObterNomeAqruivoLog(): string;
    procedure ExceptionHandler(Sender: TObject; E: Exception);
  public
  end;

var
  fMain: TfMain;

implementation

uses
  DatasetLoop, ClienteServidor, Threads;

{$R *.dfm}

procedure TfMain.btDatasetLoopClick(Sender: TObject);
begin
  fDatasetLoop.Show;
end;

procedure TfMain.btStreamsClick(Sender: TObject);
begin
  fClienteServidor.Show;
end;

procedure TfMain.btThreadsClick(Sender: TObject);
begin
  fThreads.Show();
end;

procedure TfMain.ExceptionHandler(Sender: TObject; E: Exception);
begin
  TFile.AppendAllText(ObterNomeAqruivoLog(), Format('[%s] %s - %s',
    [DateTimeToStr(Now()), E.ClassName, E.Message]) + sLineBreak, TEncoding.ANSI);
  Application.ShowException(E);
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Application.OnException := ExceptionHandler;
end;

function TfMain.ObterNomeAqruivoLog(): string;
begin
  Result := TPath.Combine(TPath.GetLibraryPath(), 'error.log');
end;

end.
