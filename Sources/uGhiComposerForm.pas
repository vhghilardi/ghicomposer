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
    lblPrompt: TLabel;
    memPrompt: TMemo;
    btnRun: TButton;
    grpConn: TGroupBox;
    lblUrl: TLabel;
    edtUrl: TEdit;
    lblModel: TLabel;
    cboModel: TComboBox;
    btnRefreshModels: TButton;
    lblKey: TLabel;
    edtApiKey: TEdit;
    pnlBottom: TPanel;
    btnApply: TButton;
    reStatus: TRichEdit;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRunClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnRefreshModelsClick(Sender: TObject);
  private
    FIniPath: string;
    FPendingOutText: string;
    FPendingSelOnly: Boolean;
    FPendingTargetFile: string;
    FPendingHasApply: Boolean;
    procedure ApplyLocalizedCaptions;
    procedure SyncModelAfterIni(const AModel: string);
    procedure SyncModelComboAfterLoad;
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
  GhiComposer.AI,
  GhiComposer.Diff;

const
  cDefUrl = 'https://api.openai.com/v1/chat/completions';
  cDefModel = 'gpt-4o-mini';
  cSysPrompt: string =
    'Você é um especialista em Delphi Object Pascal e em arquivos .dfm em formato texto. ' +
    'Responda apenas com o código-fonte completo resultante (sem explicações fora do código, sem cercas markdown). ' +
    'Preserve a codificação e as convenções do arquivo.';

function TfrmGhiComposer.ConfigPath: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'GhiComposer.ini');
end;

procedure TfrmGhiComposer.ApplyLocalizedCaptions;
begin
  grpConn.Caption := 'Endpoint e credenciais (API no estilo OpenAI)';
  lblStatus.Caption := 'Resultado / diff';
  btnRefreshModels.Caption := 'Atualizar lista de modelos';
end;

procedure TfrmGhiComposer.SyncModelAfterIni(const AModel: string);
var
  Idx: Integer;
begin
  cboModel.Text := AModel;
  Idx := cboModel.Items.IndexOf(AModel);
  if Idx >= 0 then
    cboModel.ItemIndex := Idx;
end;

procedure TfrmGhiComposer.SyncModelComboAfterLoad;
var
  M: string;
begin
  M := Trim(cboModel.Text);
  if M = '' then
    M := cDefModel;
  SyncModelAfterIni(M);
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
    cboModel.Text := Ini.ReadString('api', 'model', cDefModel);
    edtApiKey.Text := Ini.ReadString('api', 'key', '');
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
    Ini.WriteString('api', 'model', Trim(cboModel.Text));
    Ini.WriteString('api', 'key', edtApiKey.Text);
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
  FPendingHasApply := False;
  ApplyLocalizedCaptions;
  reStatus.Font.Name := 'Consolas';
  reStatus.Font.Size := 10;
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
begin
  LoadSettings;
  if edtUrl.Text = '' then
    edtUrl.Text := cDefUrl;
  SyncModelComboAfterLoad;
end;

procedure TfrmGhiComposer.btnApplyClick(Sender: TObject);
var
  Ed: IOTASourceEditor;
  V: IOTAEditView;
  Err: string;
  Ext: string;
begin
  if not FPendingHasApply then
    Exit;
  Ext := LowerCase(ExtractFileExt(FPendingTargetFile));
  if (Ext = '.dfm') or (Ext = '.fmx') then
  begin
    if not GhiTryEnsureFormStreamTextView(Err) then
    begin
      GhiRichEditAppendPlain(reStatus, Err);
      Exit;
    end;
  end;
  if not GhiTryGetActiveSourceEditor(Ed, V) then
  begin
    GhiRichEditAppendPlain(reStatus, 'Nenhum editor ativo para aplicar.');
    Exit;
  end;
  if not SameText(GhiGetActiveFileName(Ed), FPendingTargetFile) then
  begin
    GhiRichEditAppendPlain(reStatus,
      'O arquivo ativo não é o mesmo da execução. Abra o arquivo correto ou execute novamente.');
    Exit;
  end;
  if FPendingSelOnly and not GhiHasNonEmptyEditorSelection(Ed) then
  begin
    GhiRichEditAppendPlain(reStatus,
      'Modo seleção: selecione o trecho no editor (como na execução) ou execute novamente.');
    Exit;
  end;
  if not GhiReplaceScope(Ed, V, FPendingOutText, FPendingSelOnly) then
  begin
    GhiRichEditAppendPlain(reStatus, 'Falha ao escrever no editor.');
    Exit;
  end;
  GhiRichEditAppendPlain(reStatus, '');
  GhiRichEditAppendPlain(reStatus, '---');
  GhiRichEditAppendPlain(reStatus, 'Código aplicado.');
  FPendingHasApply := False;
  btnApply.Enabled := False;
end;

procedure TfrmGhiComposer.btnRefreshModelsClick(Sender: TObject);
var
  Err: string;
  Cur: string;
begin
  reStatus.Clear;
  FPendingHasApply := False;
  btnApply.Enabled := False;
  if Trim(edtUrl.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Informe o endpoint (chat completions) na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;
  if Trim(edtApiKey.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Informe a API Key para carregar a lista de modelos.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  Cur := Trim(cboModel.Text);
  if Cur = '' then
    Cur := cDefModel;

  Screen.Cursor := crHourGlass;
  try
    Err := GhiListChatModels(edtUrl.Text, edtApiKey.Text, cboModel.Items);
  finally
    Screen.Cursor := crDefault;
  end;

  if Err <> '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Lista de modelos: ' + Err);
    Exit;
  end;

  SyncModelAfterIni(Cur);
  GhiRichEditAppendPlain(reStatus, Format('Lista de modelos: %d id(s) carregado(s).', [cboModel.Items.Count]));
end;

procedure TfrmGhiComposer.btnRunClick(Sender: TObject);
var
  Ed: IOTASourceEditor;
  V: IOTAEditView;
  Code, Err, OutText: string;
  HasSel: Boolean;
  SelOnly: Boolean;
  Cfg: TGhiAIConfig;
  UserBlock: string;
begin
  reStatus.Clear;
  FPendingHasApply := False;
  btnApply.Enabled := False;
  if not GhiTryEnsureFormStreamTextView(Err) then
  begin
    GhiRichEditAppendPlain(reStatus, Err);
    Exit;
  end;
  if not GhiTryGetActiveSourceEditor(Ed, V) then
  begin
    GhiRichEditAppendPlain(reStatus,
      'Abra um .pas, .dfm em modo texto ou o designer do formulário e tente novamente.');
    Exit;
  end;

  if Trim(memPrompt.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Digite o pedido na aba Chat.');
    pgcMain.ActivePage := tabChat;
    Exit;
  end;

  SelOnly := False;
  if GhiHasNonEmptyEditorSelection(Ed) then
  begin
    case MessageDlg(
      'Há texto selecionado no editor.' + sLineBreak + sLineBreak +
      'Sim = enviar e depois substituir apenas a seleção.' + sLineBreak +
      'Não = enviar e substituir o arquivo inteiro.' + sLineBreak + sLineBreak +
      'Cancelar = não executar o pedido.',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrCancel:
        Exit;
      mrYes:
        SelOnly := True;
      mrNo:
        SelOnly := False;
    else
      Exit;
    end;
  end;

  if not GhiReadScope(Ed, V, SelOnly, Code, HasSel) then
  begin
    GhiRichEditAppendPlain(reStatus, 'Não foi possível ler o editor.');
    Exit;
  end;

  if SelOnly and not HasSel then
  begin
    GhiRichEditAppendPlain(reStatus, 'A seleção não pôde ser lida; tente novamente no editor.');
    Exit;
  end;

  if Trim(edtUrl.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Informe o endpoint na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  if Trim(cboModel.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Informe o modelo na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  if Trim(edtApiKey.Text) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Informe a API Key na aba API.');
    pgcMain.ActivePage := tabApi;
    Exit;
  end;

  Cfg.Endpoint := Trim(edtUrl.Text);
  Cfg.Model := Trim(cboModel.Text);
  Cfg.ApiKey := Trim(edtApiKey.Text);

  UserBlock :=
    'Arquivo: ' + GhiGetActiveFileName(Ed) + sLineBreak +
    'Modo: ' + IfThen(SelOnly, 'substituir apenas a seleção.', 'substituir o arquivo inteiro.') + sLineBreak +
    sLineBreak + 'Pedido:' + sLineBreak + memPrompt.Text + sLineBreak + sLineBreak +
    'Código atual:' + sLineBreak + Code;

  Err := GhiChatCompletion(Cfg, cSysPrompt, UserBlock, OutText);
  if Err <> '' then
  begin
    GhiRichEditAppendPlain(reStatus, Err);
    Exit;
  end;

  if Trim(OutText) = '' then
  begin
    GhiRichEditAppendPlain(reStatus, 'Resposta vazia do modelo.');
    Exit;
  end;

  GhiShowLineDiffInRichEdit(reStatus, Code, OutText);

  FPendingOutText := OutText;
  FPendingSelOnly := SelOnly;
  FPendingTargetFile := GhiGetActiveFileName(Ed);
  FPendingHasApply := True;
  btnApply.Enabled := True;
  GhiRichEditAppendPlain(reStatus, '');
  GhiRichEditAppendPlain(reStatus, '---');
  GhiRichEditAppendPlain(reStatus, 'Use o botão Aplicar para gravar o resultado no editor.');
end;

end.
