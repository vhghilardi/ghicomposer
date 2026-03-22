unit GhiComposer.AI;

interface

uses
  System.SysUtils;

type
  TGhiAIConfig = record
    Endpoint: string;
    Model: string;
    ApiKey: string;
    ConnectionTimeoutMs: Integer;
    ResponseTimeoutMs: Integer;
    Temperature: Double;
    MaxTokens: Integer;
    StripMarkdownFences: Boolean;
  end;

function GhiChatCompletion(const Cfg: TGhiAIConfig; const ASystemPrompt, AUserPrompt: string;
  out AContent: string): string;

implementation

uses
  System.Classes,
  System.JSON,
  System.Net.HttpClient;

function StripCodeFences(const S: string): string;
var
  T: string;
  I, L: Integer;
begin
  T := Trim(S);
  if not T.StartsWith('```') then
    Exit(T);
  Delete(T, 1, 3);
  I := 1;
  L := Length(T);
  while (I <= L) and (T[I] in [#13, #10]) do
    Inc(I);
  while (I <= L) and not (T[I] in [#13, #10]) do
    Inc(I);
  while (I <= L) and (T[I] in [#13, #10]) do
    Inc(I);
  if I > 1 then
    Delete(T, 1, I - 1);
  T := Trim(T);
  L := Length(T);
  if (L >= 3) and (Copy(T, L - 2, 3) = '```') then
    Delete(T, L - 2, 3);
  Result := Trim(T);
end;

function GhiChatCompletion(const Cfg: TGhiAIConfig; const ASystemPrompt, AUserPrompt: string;
  out AContent: string): string;
var
  Client: THTTPClient;
  Root, Msg, Choice, ErrObj: TJSONObject;
  Arr, Choices: TJSONArray;
  Resp: IHTTPResponse;
  Body, Raw: string;
  V: TJSONValue;
  ReqStream: TStringStream;
begin
  AContent := '';
  Result := '';

  if Trim(Cfg.Endpoint) = '' then
    Exit('URL do endpoint vazia.');
  if Trim(Cfg.ApiKey) = '' then
    Exit('API Key vazia.');
  if Trim(Cfg.Model) = '' then
    Exit('Modelo vazio.');

  Root := TJSONObject.Create;
  try
    Root.AddPair('model', Cfg.Model);
    Arr := TJSONArray.Create;
    if Trim(ASystemPrompt) <> '' then
    begin
      Msg := TJSONObject.Create;
      Msg.AddPair('role', 'system');
      Msg.AddPair('content', ASystemPrompt);
      Arr.AddElement(Msg);
    end;
    Msg := TJSONObject.Create;
    Msg.AddPair('role', 'user');
    Msg.AddPair('content', AUserPrompt);
    Arr.AddElement(Msg);
    Root.AddPair('messages', Arr);
    if Cfg.Temperature >= 0 then
      Root.AddPair('temperature', Cfg.Temperature);
    if Cfg.MaxTokens > 0 then
      Root.AddPair('max_tokens', Cfg.MaxTokens);
    Body := Root.ToJSON;
  finally
    Root.Free;
  end;

  Client := THTTPClient.Create;
  ReqStream := TStringStream.Create(Body, TEncoding.UTF8);
  try
    Client.CustomHeaders['Authorization'] := 'Bearer ' + Cfg.ApiKey;
    Client.CustomHeaders['Content-Type'] := 'application/json';
    if Cfg.ConnectionTimeoutMs < 1000 then
      Client.ConnectionTimeout := 60000
    else
      Client.ConnectionTimeout := Cfg.ConnectionTimeoutMs;
    if Cfg.ResponseTimeoutMs < 1000 then
      Client.ResponseTimeout := 120000
    else
      Client.ResponseTimeout := Cfg.ResponseTimeoutMs;
    ReqStream.Position := 0;
    Resp := Client.Post(Cfg.Endpoint, ReqStream);
    Raw := Resp.ContentAsString(TEncoding.UTF8);
    if Resp.StatusCode >= 400 then
      Exit(Format('HTTP %d: %s', [Resp.StatusCode, Raw]));
  finally
    ReqStream.Free;
    Client.Free;
  end;

  V := TJSONObject.ParseJSONValue(Raw);
  if V = nil then
    Exit('Resposta JSON inválida.');

  try
    if not (V is TJSONObject) then
      Exit('A resposta não é um objeto JSON.');
    Root := TJSONObject(V);

    if Root.TryGetValue<TJSONArray>('choices', Choices) and (Choices.Count > 0) then
    begin
      Choice := Choices.Items[0] as TJSONObject;
      if Choice = nil then
        Exit('choices[0] inválido.');
      if not Choice.TryGetValue<TJSONObject>('message', Msg) then
        Exit('Campo "message" ausente na resposta.');
      if not Msg.TryGetValue<string>('content', AContent) then
        Exit('Campo "content" ausente na resposta.');
      if Cfg.StripMarkdownFences then
        AContent := StripCodeFences(AContent);
      Exit('');
    end;

    if Root.TryGetValue<TJSONObject>('error', ErrObj) then
    begin
      if not ErrObj.TryGetValue<string>('message', Raw) then
        Raw := ErrObj.ToString;
      Exit('Erro da API: ' + Raw);
    end;

    Exit('Formato de resposta inesperado.');
  finally
    V.Free;
  end;
end;

end.
