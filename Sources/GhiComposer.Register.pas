unit GhiComposer.Register;

interface

procedure Register;

implementation

uses
  ToolsAPI,
  GhiComposer.Wizard;

procedure Register;
begin
  GhiRegisterDockableForm;
  RegisterPackageWizard(TGhiComposerMenuWizard.Create);
end;

end.
