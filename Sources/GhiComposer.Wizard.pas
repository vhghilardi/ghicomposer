unit GhiComposer.Wizard;

interface

uses
  ToolsAPI;

type
  TGhiComposerMenuWizard = class(TNotifierObject, IOTAWizard, IOTAMenuWizard)
  private
    procedure ShowComposer;
  public
    { IOTAWizard }
    function GetIDString: string;
    function GetName: string;
    function GetAuthor: string;
    function GetComment: string;
    function GetPage: string;
    function GetGlyph: Cardinal;
    function GetState: TWizardState;
    function GetDesigner: string;
    procedure Execute;
    { IOTAMenuWizard }
    function GetMenuText: string;
  end;

implementation

uses
  uGhiComposerForm;

{ TGhiComposerMenuWizard }

procedure TGhiComposerMenuWizard.Execute;
begin
  ShowComposer;
end;

function TGhiComposerMenuWizard.GetAuthor: string;
begin
  Result := 'GhiComposer';
end;

function TGhiComposerMenuWizard.GetComment: string;
begin
  Result := 'Abre o GhiComposer para pedir correcoes e geracao de codigo no editor ativo (.pas / .dfm).';
end;

function TGhiComposerMenuWizard.GetDesigner: string;
begin
  Result := '';
end;

function TGhiComposerMenuWizard.GetGlyph: Cardinal;
begin
  Result := 0;
end;

function TGhiComposerMenuWizard.GetIDString: string;
begin
  Result := 'GhiComposer.MenuWizard';
end;

function TGhiComposerMenuWizard.GetMenuText: string;
begin
  Result := 'GhiComposer...';
end;

function TGhiComposerMenuWizard.GetName: string;
begin
  Result := 'GhiComposer';
end;

function TGhiComposerMenuWizard.GetPage: string;
begin
  Result := '';
end;

function TGhiComposerMenuWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TGhiComposerMenuWizard.ShowComposer;
var
  F: TfrmGhiComposer;
begin
  F := TfrmGhiComposer.Create(nil);
  try
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
