unit uGhiComposerForm;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  DockForm;

type
  TfrmGhiComposer = class(TDockableForm)
    pgcMain: TPageControl;
    tabChat: TTabSheet;
    tabApi: TTabSheet;
    tabAdvanced: TTabSheet;
    lblPrompt: TLabel;
    memPrompt: TMemo;
    chkSelOnly: TCheckBox;
    lblFile: TLabel;
    grpConn: TGroupBox;
    lblUrl: TLabel;
    edtUrl: TEdit;
    lblModel: TLabel;
    edtModel: TEdit;
    lblKey: TLabel;
    edtApiKey: TEdit;
    grpAdvanced: TGroupBox;
    lblSystemPrompt: TLabel;
    memSystemPrompt: TMemo;
    lblConnTimeout: TLabel;
    edtConnTimeout: TEdit;
    lblRespTimeout: TLabel;
    edtRespTimeout: TEdit;
    chkStripFences: TCheckBox;
    lblTemperature: TLabel;
    edtTemperature: TEdit;
    lblMaxTokens: TLabel;
    edtMaxTokens: TEdit;
    pnlBottom: TPanel;
    btnRun: TButton;
    btnClose: TButton;
    memStatus: TMemo;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRunClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FIniPath: string;
    procedure LoadSettings;
    procedure SaveSettings;
    function ConfigPath: string;
  public
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.IniFiles,
  System.StrUtils,
  ToolsAPI,
  GhiComposer.DockRef,
  GhiComposer.Editor,
  GhiComposer.AI;

const
  cDefUrl = 'https://api.openai.com/v1/chat/completions';
  cDefModel = 'gpt-4o-mini';
  cSysPrompt: string =
    'Você é um especialista em Delphi Object Pascal e em arquivos .dfm em formato texto. ' +
    'Responda apenas com o código-fonte completo resultante (sem explicações fora do código, sem cercas markdown). ' +
    'Preserve a codificação e as convenções do arquivo.';

function IniEncodeEscapedLines(const S: string): string;
begin
  Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
end;

function IniDecodeEscapedLines(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if (S[I] = '\') and (I < Length(S)) then
    begin
      Inc(I);
      case S[I] of
        'n':
          Result := Result + sLineBreak;
        '\':
          Result := Result + '\';
      else
        Result := Result + '\' + S[I];
      end;
      Inc(I);
    end
    else
    begin
      Result := Result + S[I];
      Inc(I);
    end;
  end;
end;

function TfrmGhiComposer.ConfigPath: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'GhiComposer.ini');
end;

procedure TfrmGhiComposer.LoadSettings;
var
  Ini: TIniFile;
begin
  if not TFile.Exists(FIniPath) then
    Exit;
  Ini := TIniFile.Create(FIniPath);
  try
    edtUrl.Text := Ini.ReadString('api', 'url', cDefUrl);
    edtModel.Text := Ini.ReadString('api', 'model', cDefModel);
    edtApiKey.Text := Ini.ReadString('api', 'key', '');
    chkSelOnly.Checked := Ini.ReadBool('editor', 'selection_only', False);
    memSystemPrompt.Text := IniDecodeEscapedLines(Ini.ReadString('advanced', 'system_prompt', ''));
    edtConnTimeout.Text := Ini.ReadString('advanced', 'conn_timeout_ms', '60000');
    edtRespTimeout.Text := Ini.ReadString('advanced', 'resp_timeout_ms', '120000');
    chkStripFences.Checked := Ini.ReadBool('advanced', 'strip_fences', True);
    edtTemperature.Text := Ini.ReadString('advanced', 'temperature', '');
    edtMaxTokens.Text := Ini.ReadString('advanced', 'max_tokens', '');
  finally
    Ini.Free;
  end;
end;

procedure TfrmGhiComposer.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Ini.WriteString('api', 'url', edtUrl.Text);
    Ini.WriteString('api', 'model', edtModel.Text);
    Ini.WriteString('api', 'key', edtApiKey.Text);
    Ini.WriteBool('editor', 'selection_only', chkSelOnly.Checked);
    Ini.WriteString('advanced', 'system_prompt', IniEncodeEscapedLines(memSystemPrompt.Text));
    Ini.WriteString('advanced', 'conn_timeout_ms', edtConnTimeout.Text);
    Ini.WriteString('advanced', 'resp_timeout_ms', edtRespTimeout.Text);
    Ini.WriteBool('advanced', 'strip_fences', chkStripFences.Checked);
    Ini.WriteString('advanced', 'temperature', edtTemperature.Text);
    Ini.WriteString('advanced', 'max_tokens', edtMaxTokens.Text);
  finally
    Ini.Free;
  end;
end;

procedure TfrmGhiComposer.FormCreate(Sender: TObject);
begin
  AutoSave := True;
  SaveStateNecessary := True;
  DeskSection := 'GhiComposer';
  FIniPath := ConfigPath;
end;

procedure TfrmGhiComposer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
  Action := caHide;
end;

procedure TfrmGhiComposer.FormDestroy(Sender: TObject);
begin
  if GhiComposerDockForm = Self then
    GhiComposerDockForm := nil;
  SaveSettings;
end;

procedure TfrmGhiComposer.FormShow(Sender: TObject);
var
  Ed: IOTASourceEditor;
  V: IOTAEditView;
begin
  LoadSettings;
  if edtUrl.Text = '' then
    edtUrl.Text := cDefUrl;
  if edtModel.Text = '' then
    edtModel.Text := cDefModel;
  if Trim(edtConnTimeout.Text) = '' then
    edtConnTimeout.Text := '60000';
  if Trim(edtRespTimeout.Text) = '' then
    edtRespTimeout.Text := '120000';
  lblFile.Caption := 'Arquivo: (nenhum editor de código ativo)';
  if GhiTryGetActiveSourceEditor(Ed, V) then
    lblFile.Caption := 'Arquivo: ' + GhiGetActiveFileName(Ed);
end;

procedure TfrmGhiComposer.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGhiComposer.btnRunClick(Sender: TObject);
var
  Ed: IOTASourceEditor;
  V: IOTAEditView;
  Code, Err, OutText: string;
  HasSel: Boolean;
  Cfg: TGhiAIConfig;
  UserBlock: string;
  InvFS: TFormatSettings;
begin
  InvFS := FormatSettings;
  InvFS.DecimalSeparator := '.';
  InvFS.ThousandSeparator := ',';
  memStatus.Clear;
  if not GhiTryGetActiveSourceEditor(Ed, V) then
  begin
    memStatus.Lines.Add('Abra um .pas ou .dfm como texto no editor e tente novamente.');
    Exit;
  end;

  if Trim(memPrompt.Text) = '' then
  begin
    memStatus.Lines.Add('Digite o pedido na aba Chat.');
    pgcMain.ActivePage := tabChat;
    Exit;
  end;

  if not GhiReadScope(Ed, V, chkSelOnly.Checked, Code, HasSel) then
  begin
    memStatus.Lines.Add('Não foi possível ler o editor.');
    Exit;
  end;

  if chkSelOnly.Checked and not HasSel then
  begin
    memStatus.Lines.Add('Selecione texto no editor ou desmarque "Apenas texto selecionado".');
    Exit;
  end;

  if Trim(edtUrl.Text) = '' then
  begin
    memStatus.Lines.Add('Informe o endpoint na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  if Trim(edtModel.Text) = '' then
  begin
    memStatus.Lines.Add('Informe o modelo na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  if Trim(edtApiKey.Text) = '' then
  begin
    memStatus.Lines.Add('Informe a API Key na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  Cfg.Endpoint := Trim(edtUrl.Text);
  Cfg.Model := Trim(edtModel.Text);
  Cfg.ApiKey := Trim(edtApiKey.Text);
  Cfg.ConnectionTimeoutMs := StrToIntDef(Trim(edtConnTimeout.Text), 60000);
  Cfg.ResponseTimeoutMs := StrToIntDef(Trim(edtRespTimeout.Text), 120000);
  Cfg.StripMarkdownFences := chkStripFences.Checked;
  Cfg.MaxTokens := StrToIntDef(Trim(edtMaxTokens.Text), 0);
  if Cfg.MaxTokens < 0 then
    Cfg.MaxTokens := 0;
  if Trim(edtTemperature.Text) = '' then
    Cfg.Temperature := -1
  else if not TryStrToFloat(Trim(edtTemperature.Text), Cfg.Temperature, InvFS) then
  begin
    memStatus.Lines.Add('Temperatura inválida (use ponto decimal, ex.: 0.7). Veja Opções avançadas.');
    pgcMain.ActivePage := tabAdvanced;
    Exit;
  end;

  UserBlock :=
    'Arquivo: ' + GhiGetActiveFileName(Ed) + sLineBreak +
    'Modo: ' + IfThen(chkSelOnly.Checked, 'substituir apenas a seleção.', 'substituir o arquivo inteiro.') + sLineBreak +
    sLineBreak + 'Pedido:' + sLineBreak + memPrompt.Text + sLineBreak + sLineBreak +
    'Código atual:' + sLineBreak + Code;

  Err := GhiChatCompletion(Cfg, IfThen(Trim(memSystemPrompt.Text) <> '',
    memSystemPrompt.Text, cSysPrompt), UserBlock, OutText);
  if Err <> '' then
  begin
    memStatus.Lines.Add(Err);
    Exit;
  end;

  if Trim(OutText) = '' then
  begin
    memStatus.Lines.Add('Resposta vazia do modelo.');
    Exit;
  end;

  memStatus.Text := OutText;

  case MessageDlg('Substituir o código no editor pelo resultado do modelo?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      begin
        if not GhiReplaceScope(Ed, V, OutText, chkSelOnly.Checked) then
          memStatus.Lines.Add('Falha ao escrever no editor.')
        else
          memStatus.Lines.Add('Código aplicado.');
      end;
    mrNo:
      memStatus.Lines.Add('Não aplicado. O texto do modelo permanece acima.');
  else
    { cancel }
  end;
end;

end.
