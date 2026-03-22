unit GhiComposer.Diff;

interface

uses
  Vcl.ComCtrls,
  Vcl.Graphics;

procedure GhiRichEditAppendPlain(R: TRichEdit; const S: string);

procedure GhiShowLineDiffInRichEdit(R: TRichEdit; const OldText, NewText: string);

/// <summary>Marca que o modelo deve usar entre .pas e .dfm na resposta.</summary>
function GhiPasDfmSplitMarker: string;

/// <summary>Divide a resposta da IA em parte .pas e parte .dfm quando a marca existe.</summary>
procedure GhiSplitPasDfmAiResponse(const AResponse: string; out APasPart, ADfmPart: string;
  out AHasDfm: Boolean);

implementation

uses
  System.Classes,
  System.Math,
  System.SysUtils,
  Winapi.Windows;

const
  MaxDiffLinesPerSide = 800;
  MaxDiffCells = 3500000;

type
  TLineDiffKind = (ldkDelete, ldkInsert, ldkEqual);

  TLineDiffOp = record
    Kind: TLineDiffKind;
    Line: string;
  end;

function GhiPasDfmSplitMarker: string;
begin
  Result := '---GHI_SPLIT_DFM---';
end;

procedure GhiSplitPasDfmAiResponse(const AResponse: string; out APasPart, ADfmPart: string;
  out AHasDfm: Boolean);
var
  L, Part: TStringList;
  I, J: Integer;
  Mark: string;
begin
  AHasDfm := False;
  APasPart := AResponse;
  ADfmPart := '';
  Mark := GhiPasDfmSplitMarker;
  L := TStringList.Create;
  Part := TStringList.Create;
  try
    L.Text := AResponse;
    for I := 0 to L.Count - 1 do
    begin
      if Trim(L[I]) <> Mark then
        Continue;
      Part.Clear;
      for J := 0 to I - 1 do
        Part.Add(L[J]);
      APasPart := Part.Text;
      Part.Clear;
      for J := I + 1 to L.Count - 1 do
        Part.Add(L[J]);
      ADfmPart := Part.Text;
      AHasDfm := True;
      Exit;
    end;
  finally
    Part.Free;
    L.Free;
  end;
end;

procedure GhiRichEditAppendPlain(R: TRichEdit; const S: string);
var
  P: Integer;
begin
  P := Length(R.Text);
  R.SelStart := P;
  R.SelLength := 0;
  R.SelAttributes.Color := clWindowText;
  R.SelAttributes.BackColor := clWindow;
  R.SelAttributes.Style := [];
  R.SelText := S + sLineBreak;
end;

procedure GhiRichEditAppendStyled(R: TRichEdit; const Line: string; Fore, Back: TColor);
var
  P: Integer;
begin
  P := Length(R.Text);
  R.SelStart := P;
  R.SelLength := 0;
  R.SelAttributes.Color := Fore;
  R.SelAttributes.BackColor := Back;
  R.SelAttributes.Style := [];
  R.SelText := Line + sLineBreak;
end;

procedure GhiShowFallbackDiff(R: TRichEdit; const NewText, Reason: string);
var
  SL: TStringList;
  I: Integer;
begin
  R.Clear;
  R.DefAttributes.Name := R.Font.Name;
  R.DefAttributes.Size := R.Font.Size;
  GhiRichEditAppendPlain(R, Reason);
  GhiRichEditAppendPlain(R, '(Texto novo abaixo; fundo verde.)');
  GhiRichEditAppendPlain(R, '');
  SL := TStringList.Create;
  try
    SL.Text := AdjustLineBreaks(NewText, tlbsLF);
    for I := 0 to SL.Count - 1 do
      GhiRichEditAppendStyled(R, SL[I], TColor(RGB(0, 100, 0)), TColor(RGB(235, 255, 235)));
  finally
    SL.Free;
  end;
end;

procedure GhiShowLineDiffInRichEdit(R: TRichEdit; const OldText, NewText: string);
var
  S0, S1: TStringList;
  n, m, i, j, k, Cnt: Integer;
  L: array of array of Integer;
  St: array of TLineDiffOp;
  DelFore, DelBack, InsFore, InsBack: TColor;
begin
  DelFore := TColor(RGB(180, 0, 0));
  DelBack := TColor(RGB(255, 220, 220));
  InsFore := TColor(RGB(0, 110, 0));
  InsBack := TColor(RGB(220, 255, 220));

  R.Clear;
  R.DefAttributes.Name := R.Font.Name;
  R.DefAttributes.Size := R.Font.Size;
  R.DefAttributes.Color := clWindowText;
  R.DefAttributes.BackColor := clWindow;

  if OldText = NewText then
  begin
    GhiRichEditAppendPlain(R, '(Sem alterações em relação ao trecho enviado.)');
    Exit;
  end;

  S0 := TStringList.Create;
  S1 := TStringList.Create;
  try
    S0.Text := AdjustLineBreaks(OldText, tlbsLF);
    S1.Text := AdjustLineBreaks(NewText, tlbsLF);
    n := S0.Count;
    m := S1.Count;

    if (n > MaxDiffLinesPerSide) or (m > MaxDiffLinesPerSide) or
      (Int64(n) * Int64(m) > MaxDiffCells) then
    begin
      GhiShowFallbackDiff(R, NewText,
        'Trecho grande demais para diff colorido linha a linha. ' +
        IntToStr(n) + ' / ' + IntToStr(m) + ' linhas.');
      Exit;
    end;

    SetLength(L, n + 1, m + 1);
    for i := 0 to n do
      L[i, 0] := 0;
    for j := 0 to m do
      L[0, j] := 0;
    for i := 1 to n do
      for j := 1 to m do
        if S0[i - 1] = S1[j - 1] then
          L[i, j] := L[i - 1, j - 1] + 1
        else
          L[i, j] := Max(L[i - 1, j], L[i, j - 1]);

    SetLength(St, n + m + 16);
    Cnt := 0;
    i := n;
    j := m;
    while (i > 0) or (j > 0) do
    begin
      if (i > 0) and (j > 0) and (S0[i - 1] = S1[j - 1]) then
      begin
        St[Cnt].Kind := ldkEqual;
        St[Cnt].Line := S0[i - 1];
        Inc(Cnt);
        Dec(i);
        Dec(j);
      end
      else if (j > 0) and ((i = 0) or (L[i, j - 1] >= L[i - 1, j])) then
      begin
        St[Cnt].Kind := ldkInsert;
        St[Cnt].Line := S1[j - 1];
        Inc(Cnt);
        Dec(j);
      end
      else if i > 0 then
      begin
        St[Cnt].Kind := ldkDelete;
        St[Cnt].Line := S0[i - 1];
        Inc(Cnt);
        Dec(i);
      end
      else
        Break;
    end;

    GhiRichEditAppendPlain(R, 'Diff (vermelho = removido, verde = adicionado):');
    GhiRichEditAppendPlain(R, '');

    if Cnt > 0 then
      for k := Cnt - 1 downto 0 do
        case St[k].Kind of
        ldkEqual:
          GhiRichEditAppendStyled(R, St[k].Line, clWindowText, clWindow);
        ldkDelete:
          GhiRichEditAppendStyled(R, St[k].Line, DelFore, DelBack);
        ldkInsert:
          GhiRichEditAppendStyled(R, St[k].Line, InsFore, InsBack);
        end;
  finally
    S1.Free;
    S0.Free;
  end;
end;

end.
