{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynEditMiscProcs.pas, released 2000-04-07.
The Original Code is based on the mwSupportProcs.pas file from the
mwEdit component suite by Martin Waldenburg and other developers, the Initial
Author of this file is Michael Hieke.
All Rights Reserved.

Contributors to the SynEdit and mwEdit projects are listed in the
Contributors.txt file.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id$

You may retrieve the latest version of this file at the SynEdit home page,
located at http://SynEdit.SourceForge.net

Known Issues:
-------------------------------------------------------------------------------}

unit SynEditMiscProcs;

{$I synedit.inc}

interface

uses
  {$IFDEF SYN_LAZARUS}
  LCLIntf, LCLType,
  {$ELSE}
  Windows,
  {$ENDIF}
  Classes, SynEditTypes, Graphics;

type
  PIntArray = ^TIntArray;
  TIntArray = array[0..MaxListSize - 1] of integer;

{$IFDEF FPC}
function MulDiv(Factor1,Factor2,Divisor:integer):integer;{$IFDEF HasInline}inline;{$ENDIF}
{$ENDIF}
function Max(x, y: integer): integer;{$IFDEF HasInline}inline;{$ENDIF}
function Min(x, y: integer): integer;{$IFDEF HasInline}inline;{$ENDIF}
function MinMax(x, mi, ma: integer): integer;{$IFDEF HasInline}inline;{$ENDIF}
procedure SwapInt(var l, r: integer);{$IFDEF HasInline}inline;{$ENDIF}
function maxPoint(P1, P2: TPoint): TPoint;
function minPoint(P1, P2: TPoint): TPoint;
{$IFDEF SYN_LAZARUS}
function eqPoint(P1, P2: TPoint): Boolean;
procedure SwapPoint(var P1, P2: TPoint);
{$ENDIF}

function GetIntArray(Count: Cardinal; InitialValue: integer): PIntArray;

procedure InternalFillRect(dc: HDC; const rcPaint: TRect);

// Converting tabs to spaces: To use the function several times it's better
// to use a function pointer that is set to the fastest conversion function.
type
  TConvertTabsProc = function(const Line: AnsiString;
    TabWidth: integer): AnsiString;

function GetBestConvertTabsProc(TabWidth: integer): TConvertTabsProc;
// This is the slowest conversion function which can handle TabWidth <> 2^n.
function ConvertTabs(const Line: AnsiString; TabWidth: integer): AnsiString;

{begin}                                                                         //mh 2000-10-19
type
  TConvertTabsProcEx = function(const Line: AnsiString; TabWidth: integer;
    var HasTabs: boolean): AnsiString;
  {$IFDEF SYN_LAZARUS}
  TSimulateConvertTabsProcEx = function(const Line: AnsiString;
    TabWidth: integer; var HasTabs: boolean): integer; 
    // returns length of converted string
  {$ENDIF}

function GetBestConvertTabsProcEx(TabWidth: integer): TConvertTabsProcEx;
{$IFDEF SYN_LAZARUS}
function GetBestSimulateConvertTabsProcEx(
  TabWidth:integer): TSimulateConvertTabsProcEx;
{$ENDIF}
// This is the slowest conversion function which can handle TabWidth <> 2^n.
function ConvertTabsEx(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): AnsiString;
{end}                                                                           //mh 2000-10-19

function CharIndex2CaretPos(Index, TabWidth: integer;
  const Line: string): integer;
function CaretPos2CharIndex(Position, TabWidth: integer; const Line: string;
  var InsideTabChar: boolean): integer;

// search for the first char of set AChars in Line, starting at index Start
function StrScanForCharInSet(const Line: string; Start: integer;
  AChars: TSynIdentChars): integer;
// the same, but searching backwards
function StrRScanForCharInSet(const Line: string; Start: integer;
  AChars: TSynIdentChars): integer;

function GetEOL(Line: PChar): PChar;

{begin}                                                                         //gp 2000-06-24
// Remove all '/' characters from string by changing them into '\.'.
// Change all '\' characters into '\\' to allow for unique decoding.
function EncodeString(s: string): string;
{$IFDEF SYN_LAZARUS}
function EncodeStringLength(s: string): integer;
function CompareCarets(const FirstCaret, SecondCaret: TPoint): integer;
{$ENDIF}

// Decodes string, encoded with EncodeString.
function DecodeString(s: string): string;
{end}                                                                           //gp 2000-06-24

function fsNot (s : TFontStyles) : TFontStyles; inline;
function fsXor (s1,s2 : TFontStyles) : TFontStyles; inline;

implementation

uses
  SysUtils;

{* fontstyle utilities *}

function fsNot (s : TFontStyles) : TFontStyles; inline;
begin
  Result := [low(TFontStyle)..High(TFontStyle)] - s;
end;
function fsXor (s1,s2 : TFontStyles) : TFontStyles; inline;
begin
  Result := s1 + s2 - (s1*s2);
end;

{***}

{$IFDEF FPC}
function MulDiv(Factor1,Factor2,Divisor:integer):integer;
begin
  Result:=(int64(Factor1)*int64(Factor2)) div Divisor;
end;
{$ENDIF}

function Max(x, y: integer): integer;
begin
  if x > y then Result := x else Result := y;
end;

function Min(x, y: integer): integer;
begin
  if x < y then Result := x else Result := y;
end;

function MinMax(x, mi, ma: integer): integer;
begin
  if (x < mi) then Result := mi
    else if (x > ma) then Result := ma else Result := x;
end;

procedure SwapInt(var l, r: integer);
var
  tmp: integer;
begin
  tmp := r;
  r := l;
  l := tmp;
end;

function maxPoint(P1, P2: TPoint): TPoint;
begin
  Result := P1;
  if (P2.y > P1.y) or ((P2.y = P1.y) and (P2.x > P1.x)) then
    Result := P2;
end;

function minPoint(P1, P2: TPoint): TPoint;
begin
  Result := P1;
  if (P2.y < P1.y) or ((P2.y = P1.y) and (P2.x < P1.x)) then
    Result := P2;
end;

{$IFDEF SYN_LAZARUS}
function eqPoint(P1, P2: TPoint): Boolean;
begin
  Result := (P2.y = P1.y) and (P2.x = P1.x);
end;

procedure SwapPoint(var P1, P2: TPoint);
var
  tmp : TPoint;
begin
  tmp := P1;
  P1 := P2;
  P2 := tmp;
end;
{$ENDIF}

{***}

function GetIntArray(Count: Cardinal; InitialValue: integer): PIntArray;
var
  p: PInteger;
begin
  Result := AllocMem(Count * SizeOf(integer));
  if Assigned(Result) and (InitialValue <> 0) then begin
    p := PInteger(Result);
    while (Count > 0) do begin
      p^ := InitialValue;
      Inc(p);
      Dec(Count);
    end;
  end;
end;

procedure InternalFillRect(dc: HDC; const rcPaint: TRect);
begin
  ExtTextOut(dc, 0, 0, ETO_OPAQUE, @rcPaint, nil, 0, nil);
end;

{***}

// mh: Please don't change; no stack frame and efficient register use.
function GetHasTabs(pLine: PChar; var CharsBefore: integer): boolean;
begin
  CharsBefore := 0;
  if Assigned(pLine) then begin
    while (pLine^ <> #0) do begin
      if (pLine^ = #9) then break;
      Inc(CharsBefore);
      Inc(pLine);
    end;
    Result := (pLine^ = #9);
  end else
    Result := FALSE;
end;

{$IFDEF SYN_LAZARUS}
function StringHasTabs(const Line: string; var CharsBefore: integer): boolean;
var LineLen: integer;
begin
  LineLen:=length(Line);
  CharsBefore := 1;
  while (CharsBefore<=LineLen) and (Line[CharsBefore]<>#9) do
    inc(CharsBefore);
  Result:=CharsBefore<=LineLen;
  dec(CharsBefore);
end;
{$ENDIF}

{begin}                                                                         //mh 2000-10-19
function ConvertTabs1Ex(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): AnsiString;
var
  pDest: PChar;
  nBeforeTab: integer;
begin
  Result := Line;  // increment reference count only
  if GetHasTabs(pointer(Line), nBeforeTab) then begin
    HasTabs := TRUE;                                                            //mh 2000-11-08
    pDest := @Result[nBeforeTab + 1]; // this will make a copy of Line
    // We have at least one tab in the string, and the tab width is 1.
    // pDest points to the first tab char. We overwrite all tabs with spaces.
    repeat
      if (pDest^ = #9) then pDest^ := ' ';
      Inc(pDest);
    until (pDest^ = #0);
  end else
    HasTabs := FALSE;
end;

{$IFDEF SYN_LAZARUS}
function SimulateConvertTabs1Ex(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): integer;
// TabWidth=1
var
  i: integer;
begin
  Result:=length(Line);
  i:=1;
  while (i<=Result) and (Line[i]<>#9) do inc(i);
  HasTabs:=(i<=Result);
end;
{$ENDIF}

function ConvertTabs1(const Line: AnsiString; TabWidth: integer): AnsiString;
var
  HasTabs: boolean;
begin
  Result := ConvertTabs1Ex(Line, TabWidth, HasTabs);
end;

function ConvertTabs2nEx(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): AnsiString;
var
  i, DestLen, TabCount, TabMask: integer;
  pSrc, pDest: PChar;
begin
  Result := Line;  // increment reference count only
  if GetHasTabs(pointer(Line), DestLen) then begin
    HasTabs := TRUE;                                                            //mh 2000-11-08
    pSrc := @Line[1 + DestLen];
    // We have at least one tab in the string, and the tab width equals 2^n.
    // pSrc points to the first tab char in Line. We get the number of tabs
    // and the length of the expanded string now.
    TabCount := 0;
    TabMask := (TabWidth - 1) xor $7FFFFFFF;
    repeat
      if (pSrc^ = #9) then begin
        DestLen := (DestLen + TabWidth) and TabMask;
        Inc(TabCount);
      end else
        Inc(DestLen);
      Inc(pSrc);
    until (pSrc^ = #0);
    // Set the length of the expanded string.
    SetLength(Result, DestLen);
    DestLen := 0;
    pSrc := PChar(Line);
    pDest := PChar(Result);
    // We use another TabMask here to get the difference to 2^n.
    TabMask := TabWidth - 1;
    repeat
      if (pSrc^ = #9) then begin
        i := TabWidth - (DestLen and TabMask);
        Inc(DestLen, i);
        repeat
          pDest^ := ' ';
          Inc(pDest);
          Dec(i);
        until (i = 0);
        Dec(TabCount);
        if (TabCount = 0) then begin
          repeat
            Inc(pSrc);
            pDest^ := pSrc^;
            Inc(pDest);
          until (pSrc^ = #0);
          exit;
        end;
      end else begin
        pDest^ := pSrc^;
        Inc(pDest);
        Inc(DestLen);
      end;
      Inc(pSrc);
    until (pSrc^ = #0);
  end else
    HasTabs := FALSE;
end;

{$IFDEF SYN_LAZARUS}
function SimulateConvertTabs2nEx(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): integer;
var
  LineLen, DestLen, SrcPos, TabMask: integer;
begin
  LineLen:=length(Line);
  if StringHasTabs(Line, DestLen) then begin
    HasTabs := TRUE;
    SrcPos:=DestLen+1;
    // We have at least one tab in the string, and the tab width equals 2^n.
    // pSrc points to the first tab char in Line. We get the number of tabs
    // and the length of the expanded string now.
    TabMask := (TabWidth - 1) xor $7FFFFFFF;
    repeat
      if (Line[SrcPos] = #9) then 
        DestLen := (DestLen + TabWidth) and TabMask
      else
        Inc(DestLen);
      Inc(SrcPos);
    until (SrcPos>LineLen);
    Result:=DestLen;
  end else begin
    Result := LineLen;
    HasTabs := FALSE;
  end;
end;
{$ENDIF}

function ConvertTabs2n(const Line: AnsiString; TabWidth: integer): AnsiString;
var
  HasTabs: boolean;
begin
  Result := ConvertTabs2nEx(Line, TabWidth, HasTabs);
end;

function ConvertTabsEx(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): AnsiString;
var
  i, DestLen, TabCount: integer;
  pSrc, pDest: PChar;
begin
  Result := Line;  // increment reference count only
  if GetHasTabs(pointer(Line), DestLen) then begin
    HasTabs := TRUE;                                                            //mh 2000-11-08
    pSrc := @Line[1 + DestLen];
    // We have at least one tab in the string, and the tab width is greater
    // than 1. pSrc points to the first tab char in Line. We get the number
    // of tabs and the length of the expanded string now.
    TabCount := 0;
    repeat
      if (pSrc^ = #9) then begin
        DestLen := DestLen + TabWidth - DestLen mod TabWidth;
        Inc(TabCount);
      end else
        Inc(DestLen);
      Inc(pSrc);
    until (pSrc^ = #0);
    // Set the length of the expanded string.
    SetLength(Result, DestLen);
    DestLen := 0;
    pSrc := PChar(Line);
    pDest := PChar(Result);
    repeat
      if (pSrc^ = #9) then begin
        i := TabWidth - (DestLen mod TabWidth);
        Inc(DestLen, i);
        repeat
          pDest^ := ' ';
          Inc(pDest);
          Dec(i);
        until (i = 0);
        Dec(TabCount);
        if (TabCount = 0) then begin
          repeat
            Inc(pSrc);
            pDest^ := pSrc^;
            Inc(pDest);
          until (pSrc^ = #0);
          exit;
        end;
      end else begin
        pDest^ := pSrc^;
        Inc(pDest);
        Inc(DestLen);
      end;
      Inc(pSrc);
    until (pSrc^ = #0);
  end else
    HasTabs := FALSE;
end;

{$IFDEF SYN_LAZARUS}
function SimulateConvertTabsEx(const Line: AnsiString; TabWidth: integer;
  var HasTabs: boolean): integer;
var
  LineLen, DestLen, SrcPos: integer;
begin
  LineLen:=length(Line);
  if StringHasTabs(Line, DestLen) then begin
    HasTabs := TRUE;
    SrcPos := DestLen+1;
    // We have at least one tab in the string, and the tab width is greater
    // than 1. pSrc points to the first tab char in Line. We get the number
    // of tabs and the length of the expanded string now.
    repeat
      if (Line[SrcPos] = #9) then
        DestLen := DestLen + TabWidth - DestLen mod TabWidth
      else
        Inc(DestLen);
      Inc(SrcPos);
    until (SrcPos > LineLen);
    Result:=DestLen;
  end else begin
    Result:=LineLen;
    HasTabs := FALSE;
  end;
end;
{$ENDIF}

function ConvertTabs(const Line: AnsiString; TabWidth: integer): AnsiString;
var
  HasTabs: boolean;
begin
  Result := ConvertTabsEx(Line, TabWidth, HasTabs);
end;

function IsPowerOfTwo(TabWidth: integer): boolean;
var
  nW: integer;
begin
  nW := 2;
  repeat
    if (nW >= TabWidth) then break;
    Inc(nW, nW);
  until (nW >= $10000);  // we don't want 64 kByte spaces...
  Result := (nW = TabWidth);
end;

function GetBestConvertTabsProc(TabWidth: integer): TConvertTabsProc;
begin
  if (TabWidth < 2) then Result := TConvertTabsProc(@ConvertTabs1)
    else if IsPowerOfTwo(TabWidth) then
      Result := TConvertTabsProc(@ConvertTabs2n)
    else
      Result := TConvertTabsProc(@ConvertTabs);
end;

function GetBestConvertTabsProcEx(TabWidth: integer): TConvertTabsProcEx;
begin
  if (TabWidth < 2) then
    Result := TConvertTabsProcEx(@ConvertTabs1Ex)
  else if IsPowerOfTwo(TabWidth) then
    Result := TConvertTabsProcEx(@ConvertTabs2nEx)
  else
    Result := TConvertTabsProcEx(@ConvertTabsEx);
end;
{end}                                                                           //mh 2000-10-19

{$IFDEF SYN_LAZARUS}
function GetBestSimulateConvertTabsProcEx(
  TabWidth:integer): TSimulateConvertTabsProcEx;
begin
  if (TabWidth < 2) then Result := 
    TSimulateConvertTabsProcEx(@SimulateConvertTabs1Ex)
  else if IsPowerOfTwo(TabWidth) then
    Result := TSimulateConvertTabsProcEx(@SimulateConvertTabs2nEx)
  else
    Result := TSimulateConvertTabsProcEx(@SimulateConvertTabsEx);
end;
{$ENDIF}

{***}

function CharIndex2CaretPos(Index, TabWidth: integer;
  const Line: string): integer;
var
  iChar: integer;
  pNext: PChar;
begin
// possible sanity check here: Index := Max(Index, Length(Line));
  if Index > 1 then begin
    if (TabWidth <= 1) or not GetHasTabs(pointer(Line), iChar) then
      Result := Index
    else begin
      if iChar + 1 >= Index then
        Result := Index
      else begin
        // iChar is number of chars before first #9
        Result := iChar;
        // Index is *not* zero-based
        Inc(iChar);
        Dec(Index, iChar);
        pNext := @Line[iChar];
        while Index > 0 do begin
          case pNext^ of
            #0: break;
            #9: begin
                  // Result is still zero-based
                  Inc(Result, TabWidth);
                  Dec(Result, Result mod TabWidth);
                end;
            else Inc(Result);
          end;
          Dec(Index);
          Inc(pNext);
        end;
        // done with zero-based computation
        Inc(Result);
      end;
    end;
  end else
    Result := 1;
end;

function CaretPos2CharIndex(Position, TabWidth: integer; const Line: string;
  var InsideTabChar: boolean): integer;
var
  iPos: integer;
  pNext: PChar;
begin
  InsideTabChar := FALSE;
  if Position > 1 then begin
    if (TabWidth <= 1) or not GetHasTabs(pointer(Line), iPos) then
      Result := Position
    else begin
      if iPos + 1 >= Position then
        Result := Position
      else begin
        // iPos is number of chars before first #9
        Result := iPos + 1;
        pNext := @Line[Result];
        // for easier computation go zero-based (mod-operation)
        Dec(Position);
        while iPos < Position do begin
          case pNext^ of
            #0: break;
            #9: begin
                  Inc(iPos, TabWidth);
                  Dec(iPos, iPos mod TabWidth);
                  if iPos > Position then begin
                    InsideTabChar := TRUE;
                    break;
                  end;
                end;
            else Inc(iPos);
          end;
          Inc(Result);
          Inc(pNext);
        end;
      end;
    end;
  end else
    Result := Position;
end;

function StrScanForCharInSet(const Line: string; Start: integer;
  AChars: TSynIdentChars): integer;
var
  p: PChar;
begin
  if (Start > 0) and (Start <= Length(Line)) then
  begin
    p := PChar(@Line[Start]);
    repeat
      if p^ in AChars then
      begin
        Result := Start;
        exit;
      end;
      Inc(p);
      Inc(Start);
    until p^ = #0;
  end;
  Result := 0;
end;

function StrRScanForCharInSet(const Line: string; Start: integer;
  AChars: TSynIdentChars): integer;
var
  p: PChar;
begin
  if (Start > 0) and (Start <= Length(Line)) then
  begin
    p := PChar(@Line[Start]);
    repeat
      if p^ in AChars then
      begin
        Result := Start;
        exit;
      end;
      Dec(p);
      Dec(Start);
    until Start < 1;
  end;
  Result := 0;
end;

function GetEOL(Line: PChar): PChar;
begin
  Result := Line;
  if Assigned(Result) then
    while not (Result^ in [#0, #10, #13]) do
      Inc(Result);
end;

{begin}                                                                         //gp 2000-06-24
{$IFOPT R+}{$DEFINE RestoreRangeChecking}{$ELSE}{$UNDEF RestoreRangeChecking}{$ENDIF}
{$R-}
function EncodeString(s: string): string;
var
  i, j: integer;
begin
  {$IFDEF SYN_LAZARUS}
  SetLength(Result, EncodeStringLength(s));
  {$ELSE}
  SetLength(Result, 2 * Length(s)); // worst case
  {$ENDIF}
  j := 0;
  for i := 1 to Length(s) do begin
    Inc(j);
    if s[i] = '\' then begin
      Result[j] := '\';
      {$IFDEF SYN_LAZARUS}
      Inc(j);
      Result[j] := '\';
      {$ELSE}
      Result[j + 1] := '\';
      Inc(j);
      {$ENDIF}
    end else if s[i] = '/' then begin
      Result[j] := '\';
      {$IFDEF SYN_LAZARUS}
      Inc(j);
      Result[j] := '.';
      {$ELSE}
      Result[j + 1] := '.';
      Inc(j);
      {$ENDIF}
    end else
      Result[j] := s[i];
  end; //for
  {$IFNDEF SYN_LAZARUS}
  SetLength(Result, j);
  {$ENDIF}
end; { EncodeString }

{$IFDEF SYN_LAZARUS}
function EncodeStringLength(s: string): integer;
var
  i, len: integer;
begin
  len:=length(s);
  Result := len;
  for i := 1 to len do
    if (s[i] in ['\','/']) then
      Inc(Result);
end;

function CompareCarets(const FirstCaret, SecondCaret: TPoint): integer;
begin
  if (FirstCaret.Y<SecondCaret.Y) then
    Result:=1
  else if (FirstCaret.Y>SecondCaret.Y) then
    Result:=-1
  else if (FirstCaret.X<SecondCaret.X) then
    Result:=1
  else if (FirstCaret.X>SecondCaret.X) then
    Result:=-1
  else
    Result:=0;
end;

{$ENDIF}

function DecodeString(s: string): string;
var
  i, j: integer;
begin
  SetLength(Result, Length(s)); // worst case
  j := 0;
  i := 1;
  while i <= Length(s) do begin
    Inc(j);
    if s[i] = '\' then begin
      Inc(i);
      if s[i] = '\' then
        Result[j] := '\'
      else
        Result[j] := '/';
    end else
      Result[j] := s[i];
    Inc(i);
  end; //for
  SetLength(Result,j);
end; { DecodeString }
{$IFDEF RestoreRangeChecking}{$R+}{$ENDIF}
{end}                                                                           //gp 2000-06-24

end.

