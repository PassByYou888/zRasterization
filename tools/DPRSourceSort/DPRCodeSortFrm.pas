unit DPRCodeSortFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.Memo.Types,
  ZR.PascalStrings, ZR.UPascalStrings, ZR.UnicodeMixedLib, ZR.Core, ZR.Parsing;

type
  TDPRCodeSortForm = class(TForm)
    Memo1: TMemo;
    Layout1: TLayout;
    SortButton: TButton;
    OpenDialog: TOpenDialog;
    procedure SortButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DPRCodeSortForm: TDPRCodeSortForm;

implementation

{$R *.fmx}


uses StyleModuleUnit;

procedure SortDPRUsesStrings(Code: TCore_Strings);
type
  TData = record
    sour: U_String;
    SortKey: U_String;
  end;

  pData = ^TData;

  TValueRelationship = -1 .. 1;

  function ListSortCompare(Item1, Item2: Pointer): Integer;
  const
    LessThanValue = low(TValueRelationship);
    EqualsValue = 0;
    GreaterThanValue = high(TValueRelationship);
  var
    p1, p2: pData;
    ph1, ph2: string;
  begin
    p1 := Item1;
    p2 := Item2;
    ph1 := p2^.SortKey;
    ph2 := p1^.SortKey;

    Result := CompareText(ph1, ph2);
  end;

  procedure QuickSortList(var SortList: TCore_PointerList; L, R: Integer);
  var
    i, J: Integer;
    p, tmp: Pointer;
  begin
    if L < R then
      begin
        repeat
          if (R - L) = 1 then
            begin
              if ListSortCompare(SortList[L], SortList[R]) > 0 then
                begin
                  tmp := SortList[L];
                  SortList[L] := SortList[R];
                  SortList[R] := tmp;
                end;
              break;
            end;
          i := L;
          J := R;
          p := SortList[(L + R) shr 1];
          repeat
            while ListSortCompare(SortList[i], p) < 0 do
                inc(i);
            while ListSortCompare(SortList[J], p) > 0 do
                dec(J);
            if i <= J then
              begin
                if i <> J then
                  begin
                    tmp := SortList[i];
                    SortList[i] := SortList[J];
                    SortList[J] := tmp;
                  end;
                inc(i);
                dec(J);
              end;
          until i > J;
          if (J - L) > (R - i) then
            begin
              if i < R then
                  QuickSortList(SortList, i, R);
              R := J;
            end
          else
            begin
              if L < J then
                  QuickSortList(SortList, L, J);
              L := i;
            end;
        until L >= R;
      end;
  end;

var
  i, J: Integer;
  p: pData;
  L: TCore_List;
  n: U_String;
  T: TTextParsing;
  LastKey: U_String;
  preProcessHeader: U_String;
  token: TTokenData;
begin
  preProcessHeader := '';
  L := TCore_List.Create;
  for i := 0 to Code.Count - 1 do
    begin
      n := umlTrimSpace(Code[i]);
      if (n.Len > 0) then
        begin
          T := TTextParsing.Create(n, tsPascal, nil);
          if (T.TokenStatistics[ttTextDecl] = 1) then
            begin
              new(p);
              p^.sour := n;
              if p^.sour.Last <> ',' then
                begin
                  if p^.sour.Last = ';' then
                      p^.sour.Last := ','
                  else
                      p^.sour.Append(',');
                end;

              token := T.TokenIndex[ttTextDecl, 0]^;
              p^.SortKey := T.GetTextBody(T.GetStr(token.bPos, token.ePos));

              if umlExistsChar(p^.SortKey, '\') then
                  p^.SortKey := umlDeleteLastStr(p^.SortKey, '\')
              else
                  p^.SortKey := '';

              L.Add(p);
            end
          else
            begin
              if T.TokenStatistics[ttAscii] > 0 then
                  preProcessHeader := preProcessHeader + '  ' + n + #13#10;
            end;
          DisposeObject(T);
        end;
    end;

  QuickSortList(L.ListData^, 0, L.Count - 1);

  Code.Clear;
  Code.BeginUpdate;
  LastKey := '';
  if preProcessHeader.Len > 0 then
    begin
      Code.Add('  (* system unit *)');
      Code.Add(preProcessHeader.Text);
    end;
  Code.Add('  (* project root unit *)');
  for i := 0 to L.Count - 1 do
    begin
      p := L[i];
      n := p^.SortKey;
      if not LastKey.Same(n) then
        begin
          Code.Add(Format('', []));
          Code.Add(Format('  (* %s *)', [n.Text]));
          LastKey := n;
        end;

      Code.Add('  ' + p^.sour);
      Dispose(p);
    end;
  Code.EndUpdate;

  L.Free;
end;

function ParseAndSortDPRSource(sourceCode: U_String): U_String;
var
  SourceOutput, UsesOutput: U_String;
  InitedUnit, InitedUses: Boolean;

  procedure AppendCode(s: U_String);
  begin
    if InitedUses then
        UsesOutput.Append(s)
    else
        SourceOutput.Append(s);
  end;

  procedure BeginParseUses;
  begin
  end;

  procedure EndParseUses;
  var
    ns: TCore_StringList;
  begin
    ns := TCore_StringList.Create;
    ns.Text := UsesOutput.Text;
    SortDPRUsesStrings(ns);
    UsesOutput.Text := ns.Text;
    DisposeObject(ns);
    UsesOutput := umlDeleteLastStr(UsesOutput, ',');
    SourceOutput.Text := SourceOutput.Text + #13#10 + UsesOutput.Text;
  end;

var
  T: TTextParsing;
  cp: Integer;
  ePos: Integer;
  s: U_String;
begin
  SourceOutput := '';
  T := TTextParsing.Create(sourceCode, tsPascal);

  InitedUnit := False;
  InitedUses := False;

  cp := 1;

  while cp <= T.ParsingData.L do
    begin
      if T.isTextDecl(cp) then
        begin
          ePos := T.GetTextDeclEndPos(cp);
          s := T.GetStr(cp, ePos);
          AppendCode(s);
          cp := ePos
        end
      else if T.isComment(cp) then
        begin
          ePos := T.GetCommentEndPos(cp);
          s := T.GetStr(cp, ePos);
          AppendCode(s);
          cp := ePos;
        end
      else if T.isNumber(cp) then
        begin
          ePos := T.GetNumberEndPos(cp);
          s := T.GetStr(cp, ePos);
          AppendCode(s);
          cp := ePos;
        end
      else if T.isSymbol(cp) then
        begin
          ePos := T.GetSymbolEndPos(cp);
          if (InitedUnit) and (InitedUses) then
            if T.ParsingData.Text[cp] = ';' then
              begin
                InitedUses := False;
                EndParseUses;
              end;

          s := T.GetStr(cp, ePos);
          AppendCode(s);
          cp := ePos;
        end
      else if T.isAscii(cp) then
        begin
          ePos := T.GetAsciiEndPos(cp);
          s := T.GetStr(cp, ePos);
          AppendCode(s);
          cp := ePos;

          if not InitedUnit then
            begin
              if (s.Same('library')) or (s.Same('program')) then
                  InitedUnit := True;
            end;

          if (InitedUnit) and (not InitedUses) then
            begin
              if s.Same('uses') then
                begin
                  InitedUses := True;
                  BeginParseUses;
                end;
            end;
        end
      else
        begin
          AppendCode(T.GetChar(cp));
          inc(cp);
        end;
    end;

  DisposeObject(T);
  Result := SourceOutput;
end;

procedure TDPRCodeSortForm.SortButtonClick(Sender: TObject);
begin
  Memo1.Text := ParseAndSortDPRSource(Memo1.Text);
end;

end.
