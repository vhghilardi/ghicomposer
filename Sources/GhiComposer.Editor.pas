unit GhiComposer.Editor;

interface

uses
  ToolsAPI;

function GhiTryGetActiveSourceEditor(out AEditor: IOTASourceEditor;
  out AView: IOTAEditView): Boolean;
/// <summary>
/// Se o foco estiver no designer (IOTAFormEditor), ativa o editor de fonte do .dfm/.fmx
/// (equivalente a View as Text). Se já estiver no .dfm/.fmx em texto, não altera.
/// Units só .pas sem formulário: retorna True sem mudança.
/// </summary>
function GhiTryEnsureFormStreamTextView(out AError: string): Boolean;
function GhiGetActiveFileName(const AEditor: IOTASourceEditor): string;
function GhiHasNonEmptyEditorSelection(const AEditor: IOTASourceEditor): Boolean;
function GhiReadScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  ASelectionOnly: Boolean; out AText: string; out AHasSelection: Boolean): Boolean;
function GhiReplaceScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  const ANewText: string; ASelectionOnly: Boolean): Boolean;
/// <summary>
/// Abre/foca um arquivo no IDE (para aplicar .pas + .dfm em sequência).
/// </summary>
function GhiIdeOpenFile(const AFileName: string): Boolean;
/// <summary>
/// Se a unit ativa for .pas e o módulo tiver .dfm/.fmx, devolve o IOTASourceEditor do stream do form.
/// </summary>
function GhiTryGetCompanionFormStreamEditor(const APasEditor: IOTASourceEditor;
  out AFormStreamEditor: IOTASourceEditor): Boolean;
/// <summary>
/// Lê o buffer inteiro do editor de fonte (ex.: .dfm ainda sem vista — tenta Show até obter vista).
/// </summary>
function GhiReadEntireSourceBuffer(const ASE: IOTASourceEditor; out AText: string): Boolean;

implementation

uses
  System.SysUtils,
  System.Classes,
  Vcl.Forms;

function GhiOtaEditorFileName(const AEditor: IOTAEditor): string;
begin
  Result := '';
  if AEditor = nil then
    Exit;
  Result := AEditor.FileName;
end;

function GhiTryGetFormStreamSourceEditor(const AModule: IOTAModule;
  out ASE: IOTASourceEditor): Boolean;
var
  I, N: Integer;
  E: IOTAEditor;
  S: IOTASourceEditor;
  Ext: string;
begin
  Result := False;
  ASE := nil;
  if AModule = nil then
    Exit;
  N := AModule.GetModuleFileCount;
  for I := 0 to N - 1 do
  begin
    E := AModule.GetModuleFileEditor(I);
    Ext := LowerCase(ExtractFileExt(GhiOtaEditorFileName(E)));
    if (Ext <> '.dfm') and (Ext <> '.fmx') then
      Continue;
    if Supports(E, IOTASourceEditor, S) then
    begin
      ASE := S;
      Result := True;
      Exit;
    end;
  end;
end;

function GhiFindFormStreamSourceEditor(const AModule: IOTAModule;
  out AEditor: IOTAEditor): Boolean;
var
  S: IOTASourceEditor;
begin
  Result := GhiTryGetFormStreamSourceEditor(AModule, S);
  if Result then
    AEditor := S as IOTAEditor
  else
    AEditor := nil;
end;

function GhiTryEnsureFormStreamTextView(out AError: string): Boolean;
var
  EdSvcs: IOTAEditorServices;
  V: IOTAEditView;
  SE: IOTASourceEditor;
  FE: IOTAFormEditor;
  AModule: IOTAModule;
  DfmEd: IOTAEditor;
begin
  AError := '';
  Result := True;
  if not Supports(BorlandIDEServices, IOTAEditorServices, EdSvcs) then
  begin
    AError := 'Serviços do editor não disponíveis.';
    Exit(False);
  end;
  V := EdSvcs.TopView;
  if V = nil then
  begin
    AError := 'Nenhuma vista de editor ativa.';
    Exit(False);
  end;

  if Supports(V.Buffer, IOTASourceEditor, SE) and (SE <> nil) then
    Exit(True);

  if Supports(V.Buffer, IOTAFormEditor, FE) and (FE <> nil) then
  begin
    AModule := (FE as IOTAEditor).Module;
    if not GhiFindFormStreamSourceEditor(AModule, DfmEd) or (DfmEd = nil) then
    begin
      AError := 'Formulário visual ativo, mas não foi encontrado .dfm/.fmx em modo texto.';
      Exit(False);
    end;
    DfmEd.Show;
    Application.ProcessMessages;
    Exit(True);
  end;

  Result := True;
end;

function GhiHasNonEmptyEditorSelection(const AEditor: IOTASourceEditor): Boolean;
var
  BS, BA: TOTACharPos;
begin
  Result := False;
  if AEditor = nil then
    Exit;
  BS := AEditor.BlockStart;
  BA := AEditor.BlockAfter;
  Result := (BS.Line <> BA.Line) or (BS.CharIndex <> BA.CharIndex);
end;

function GhiTryGetActiveSourceEditor(out AEditor: IOTASourceEditor;
  out AView: IOTAEditView): Boolean;
var
  EdSvcs: IOTAEditorServices;
begin
  AEditor := nil;
  AView := nil;
  Result := False;
  if not Supports(BorlandIDEServices, IOTAEditorServices, EdSvcs) then
    Exit;
  AView := EdSvcs.TopView;
  if AView = nil then
    Exit;
  if not Supports(AView.Buffer, IOTASourceEditor, AEditor) then
    Exit;
  Result := (AEditor <> nil) and (AView <> nil);
end;

function GhiGetActiveFileName(const AEditor: IOTASourceEditor): string;
var
  M: IOTAModule;
  I, N: Integer;
  Ed: IOTAEditor;
  E: IOTAEditor;
begin
  Result := '';
  if AEditor = nil then
    Exit;
  Ed := AEditor as IOTAEditor;
  M := AEditor.Module;
  if M <> nil then
  begin
    N := M.GetModuleFileCount;
    for I := 0 to N - 1 do
    begin
      E := M.GetModuleFileEditor(I);
      if E = Ed then
        Exit(GhiOtaEditorFileName(E));
    end;
  end;
  Result := GhiOtaEditorFileName(Ed);
end;

function Utf8BufferToString(const AReader: IOTAEditReader; AStartPos, AEndPos: Integer): string;
var
  N: Integer;
  Raw: TBytes;
begin
  Result := '';
  N := AEndPos - AStartPos - 1;
  if N <= 0 then
    Exit;
  SetLength(Raw, N);
  AReader.GetText(AStartPos, @Raw[0], N);
  Result := TEncoding.UTF8.GetString(Raw);
end;

procedure StringToUtf8Insert(const AWriter: IOTAEditWriter; const S: string);
var
  U8: UTF8String;
begin
  U8 := UTF8Encode(S);
  AWriter.Insert(PAnsiChar(U8));
end;

function GhiReadScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  ASelectionOnly: Boolean; out AText: string; out AHasSelection: Boolean): Boolean;
var
  Reader: IOTAEditReader;
  StartPos, EndPos: Integer;
  BlockStart, BlockAfter: TOTACharPos;
  Lines: Integer;
begin
  AText := '';
  AHasSelection := False;
  Result := False;
  if (AEditor = nil) or (AView = nil) then
    Exit;

  AHasSelection := GhiHasNonEmptyEditorSelection(AEditor);

  Reader := AEditor.CreateReader;
  if Reader = nil then
    Exit;

  if ASelectionOnly then
  begin
    if not GhiHasNonEmptyEditorSelection(AEditor) then
      Exit;
    BlockStart := AEditor.BlockStart;
    BlockAfter := AEditor.BlockAfter;
  end
  else
  begin
    BlockStart.Line := 1;
    BlockStart.CharIndex := 0;
    Lines := AEditor.GetLinesInBuffer;
    BlockAfter.Line := Lines + 1;
    BlockAfter.CharIndex := 0;
  end;

  StartPos := AView.CharPosToPos(BlockStart);
  EndPos := AView.CharPosToPos(BlockAfter);
  AText := Utf8BufferToString(Reader, StartPos, EndPos);
  Result := True;
end;

function GhiReplaceScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  const ANewText: string; ASelectionOnly: Boolean): Boolean;
var
  Writer: IOTAEditWriter;
  StartPos, EndPos: Integer;
  BlockStart, BlockAfter: TOTACharPos;
  Lines: Integer;
begin
  Result := False;
  if (AEditor = nil) or (AView = nil) then
    Exit;

  Writer := AView.Buffer.CreateUndoableWriter;
  if Writer = nil then
    Exit;

  if ASelectionOnly and GhiHasNonEmptyEditorSelection(AEditor) then
  begin
    BlockStart := AEditor.BlockStart;
    BlockAfter := AEditor.BlockAfter;
  end
  else
  begin
    BlockStart.Line := 1;
    BlockStart.CharIndex := 0;
    Lines := AEditor.GetLinesInBuffer;
    BlockAfter.Line := Lines + 1;
    BlockAfter.CharIndex := 0;
  end;

  StartPos := AView.CharPosToPos(BlockStart);
  EndPos := AView.CharPosToPos(BlockAfter);
  Writer.CopyTo(StartPos);
  Writer.DeleteTo(EndPos);
  StringToUtf8Insert(Writer, ANewText);
  Result := True;
end;

function GhiIdeOpenFile(const AFileName: string): Boolean;
var
  Act: IOTAActionServices;
begin
  Result := False;
  if Trim(AFileName) = '' then
    Exit;
  if not Supports(BorlandIDEServices, IOTAActionServices, Act) then
    Exit;
  Act.OpenFile(AFileName);
  Application.ProcessMessages;
  Result := True;
end;

function GhiTryGetCompanionFormStreamEditor(const APasEditor: IOTASourceEditor;
  out AFormStreamEditor: IOTASourceEditor): Boolean;
var
  Ext, PasFn, DfmFn: string;
  M: IOTAModule;
  Dfm: IOTASourceEditor;
begin
  Result := False;
  AFormStreamEditor := nil;
  if APasEditor = nil then
    Exit;
  PasFn := GhiGetActiveFileName(APasEditor);
  Ext := LowerCase(ExtractFileExt(PasFn));
  if Ext <> '.pas' then
    Exit;
  M := APasEditor.Module;
  if M = nil then
    Exit;
  if not GhiTryGetFormStreamSourceEditor(M, Dfm) or (Dfm = nil) then
    Exit;
  DfmFn := GhiOtaEditorFileName(Dfm as IOTAEditor);
  if SameText(PasFn, DfmFn) then
    Exit;
  AFormStreamEditor := Dfm;
  Result := True;
end;

function GhiReadEntireSourceBuffer(const ASE: IOTASourceEditor; out AText: string): Boolean;
var
  V: IOTAEditView;
  Dummy: Boolean;
  Attempt: Integer;
  N: Integer;
begin
  AText := '';
  Result := False;
  if ASE = nil then
    Exit;
  for Attempt := 0 to 2 do
  begin
    N := ASE.GetEditViewCount;
    if N > 0 then
    begin
      V := ASE.GetEditView(0);
      if (V <> nil) and GhiReadScope(ASE, V, False, AText, Dummy) then
        Exit(True);
    end;
    (ASE as IOTAEditor).Show;
    Application.ProcessMessages;
  end;
end;

end.
