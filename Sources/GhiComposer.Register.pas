unit GhiComposer.Register;

interface

procedure Register;

implementation

uses
  ToolsAPI,
  GhiComposer.Wizard;

procedure Register;
begin
  RegisterPackageWizard(TGhiComposerMenuWizard.Create);
end;

end.
