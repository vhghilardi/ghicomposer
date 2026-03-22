unit GhiComposer.Editor;

interface

uses
  ToolsAPI;

function GhiTryGetActiveSourceEditor(out AEditor: IOTASourceEditor;
  out AView: IOTAEditView): Boolean;
function GhiGetActiveFileName(const AEditor: IOTASourceEditor): string;
function GhiReadScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  ASelectionOnly: Boolean; out AText: string; out AHasSelection: Boolean): Boolean;
function GhiReplaceScope(const AEditor: IOTASourceEditor; const AView: IOTAEditView;
  const ANewText: string; ASelectionOnly: Boolean): Boolean;

implementation

uses
  System.SysUtils,
  System.Classes;

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
  Module: IOTAModule;
begin
  Result := '';
  if AEditor = nil then
    Exit;
  Module := AEditor.Module;
  if Module = nil then
    Exit;
  Result := Module.FileName;
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
begin
  AWriter.Insert(S);
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
  AHasSelection := AView.BlockSize > 0;
  Result := False;
  if (AEditor = nil) or (AView = nil) then
    Exit;

  Reader := AEditor.CreateReader;
  if Reader = nil then
    Exit;

  if ASelectionOnly then
  begin
    if AView.BlockSize <= 0 then
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

  if ASelectionOnly and (AView.BlockSize > 0) then
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

end.
