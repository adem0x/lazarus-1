{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: SynHighlighterInno.pas, released 2000-05-01.
The Initial Author of this file is Satya.
Portions created by Satya are Copyright 2000 Satya.
All Rights Reserved.

Contributors to the SynEdit project are listed in the Contributors.txt file.

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
{
@abstract(Provides an Inno script file highlighter for SynEdit)
@author(Satya)
@created(2000-05-01)
@lastmod(2000-07-17)
The SynHighlighterInno unit provides an Inno script file highlighter for SynEdit.
Check out http://www.jrsoftware.org for the free Inno Setup program.
}
unit SynHighlighterInno;

{$I SynEdit.inc}

interface

uses
  SysUtils, Windows, Messages, Classes, Controls, Graphics, Registry,
  SynEditTypes, SynEditHighlighter, SynHighlighterHashEntries;

type
  TtkTokenKind = (tkComment, tkConstant, tkIdentifier, tkKey, tkNull, tkNumber,
    tkParameter, tkSection, tkSpace, tkString, tkSymbol, tkUnknown);

  TProcTableProc = procedure of object;

  TSynInnoSyn = class(TSynCustomHighlighter)
  private
    fLine: PChar;
    fLineNumber: integer;
    fProcTable: array[#0..#255] of TProcTableProc;
    Run: LongInt;
    fStringLen: Integer;
    fToIdent: PChar;
    fTokenPos: Integer;
    fTokenID: TtkTokenKind;
    fConstantAttri: TSynHighlighterAttributes;
    fCommentAttri: TSynHighlighterAttributes;
    fSectionAttri: TSynHighlighterAttributes;
    fParamAttri: TSynHighlighterAttributes;
    fIdentifierAttri: TSynHighlighterAttributes;
    fInvalidAttri: TSynHighlighterAttributes;
    fKeyAttri: TSynHighlighterAttributes;
    fNumberAttri: TSynHighlighterAttributes;
    fSpaceAttri: TSynHighlighterAttributes;
    fStringAttri: TSynHighlighterAttributes;
    fSymbolAttri: TSynHighlighterAttributes;
    fKeywords: TSynHashEntryList;
    function KeyHash(ToHash: PChar): integer;
    function KeyComp(const aKey: string): Boolean;
    procedure SymbolProc;
    procedure CRProc;
    procedure IdentProc;
    procedure LFProc;
    procedure NullProc;
    procedure NumberProc;
    procedure SectionProc;
    procedure SpaceProc;
    procedure EqualProc;
    procedure ConstantProc;
    procedure SemiColonProc;
    procedure StringProc;
    procedure UnknownProc;

    procedure DoAddKeyword(AKeyword: string; AKind: integer);
    function IdentKind(MayBe: PChar): TtkTokenKind;
    procedure MakeMethodTables;
  protected
    function GetIdentChars: TSynIdentChars; override;
  public
    {$IFNDEF SYN_CPPB_1} class {$ENDIF}                                         //mh 2000-07-14
    function GetLanguageName: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetDefaultAttribute(Index: integer): TSynHighlighterAttributes;
      override;
    function GetEol: Boolean; override;
    function GetToken: string; override;
    function GetTokenAttribute: TSynHighlighterAttributes; override;
    function GetTokenID: TtkTokenKind;
    function GetTokenKind: integer; override;
    function GetTokenPos: Integer; override;
    procedure Next; override;
    procedure SetLine(NewValue: string; LineNumber:Integer); override;
  published
    property ConstantAttri: TSynHighlighterAttributes read fConstantAttri
      write fConstantAttri;
    property CommentAttri: TSynHighlighterAttributes read fCommentAttri
      write fCommentAttri;
    property IdentifierAttri: TSynHighlighterAttributes read fIdentifierAttri
      write fIdentifierAttri;
    property InvalidAttri: TSynHighlighterAttributes read fInvalidAttri
      write fInvalidAttri;
    property KeyAttri: TSynHighlighterAttributes read fKeyAttri write fKeyAttri;
    property NumberAttri: TSynHighlighterAttributes read fNumberAttri
      write fNumberAttri;
    property ParameterAttri: TSynHighlighterAttributes read fParamAttri
      write fParamAttri;
    property SectionAttri: TSynHighlighterAttributes read fSectionAttri
      write fSectionAttri;
    property SpaceAttri: TSynHighlighterAttributes read fSpaceAttri
      write fSpaceAttri;
    property StringAttri: TSynHighlighterAttributes read fStringAttri
      write fStringAttri;
    property SymbolAttri: TSynHighlighterAttributes read fSymbolAttri
      write fSymbolAttri;
  end;

implementation

uses
  SynEditStrConst;

var
  Identifiers: array[#0..#255] of ByteBool;
  mHashTable: array[#0..#255] of Integer;

const
  {Note: new 'Section names' and the new 'Constants' need not be added
         as they are handled in a different way.}
  {Ref:  Keywords and Parameters are updated as they were last modified in
         Inno Setup / Inno Setup Extensions v1.3.16}

  Keywords: string =
    'AdminPrivilegesRequired,AllowNoIcons,AllowRootDirectory,' +
    'AlwaysCreateUninstallIcon,AlwaysRestart,AlwaysUsePersonalGroup,' +
    'AppCopyright,AppId,AppMutex,AppName,AppPublisher,AppPublisherURL,' +
    'AppSupportURL,AppUpdatesURL,AppVerName,AppVersion,Attribs,BackColor,' +
    'BackColor2,BackColorDirection,BackSolid,Bits,ChangesAssociations,Components,' +
    'CompressLevel,CopyMode,CreateAppDir,CreateUninstallRegKey,' +
    'DefaultDirName,DefaultGroupName,Description,DestDir,DestName,' +
    'DirExistsWarning,DisableAppendDir,DisableDirExistsWarning,DisableDirPage,' +
    'DisableFinishedPage,DisableProgramGroupPage,DisableReadyMemo,' +
    'DisableStartupPrompt,DiskClusterSize,DiskSize,DiskSpaceMBLabel,DiskSpanning,' +
    'DontMergeDuplicateFiles,EnableDirDoesntExistWarning,ExtraDiskSpaceRequired,' +
    'Filename,Flags,FlatComponentsList,FontInstall,IconFilename,IconIndex,' +
    'InfoAfterFile,InfoBeforeFile,InstallMode,Key,LicenseFile,MessagesFile,' +
    'MinVersion,Name,OnlyBelowVersion,OutputBaseFilename,OutputDir,' +
    'OverwriteUninstRegEntries,Parameters,Password,ReserveBytes,Root,RunOnceId,' +
    'Section,ShowComponentSizes,Source,SourceDir,Subkey,Type,Types,' +
    'UninstallDisplayIcon,UninstallDisplayName,UninstallFilesDir,' +
    'UninstallIconName,UninstallLogMode,UninstallStyle,Uninstallable,' +
    'UsePreviousAppDir,UsePreviousGroup,UsePreviousSetupType,UseSetupLdr,' +
    'ValueData,ValueName,ValueType,WindowResizable,WindowShowCaption,' +
    'WindowStartMaximized,WindowVisible,WizardImageBackColor,WizardImageFile,' +
    'WizardSmallImageFile,WizardStyle,WorkingDir';

  Parameters: string =
    'HKCC,HKCR,HKCU,HKLM,HKU,alwaysoverwrite,alwaysskipifsameorolder,append,' +
    'binary,classic,closeonexit,comparetimestampalso,confirmoverwrite,' +
    'createkeyifdoesntexist,createonlyiffileexists,createvalueifdoesntexist,' +
    'deleteafterinstall,deletekey,deletevalue,dirifempty,dontcloseonexit,' +
    'dontcreatekey,dword,expandsz,external,files,filesandordirs,fixed,' +
    'fontisnttruetype,iscustom,isreadme,modern,multisz,new,noerror,none,normal,' +
    'nowait,onlyifdoesntexist,overwrite,overwritereadonly,preservestringtype,' +
    'regserver,regtypelib,restart,restartreplace,runminimized,sharedfile,' +
    'shellexec,skipifnotsilent,skipifsilent,silent,skipifdoesntexist,' +
    'skipifsourcedoesntexist,string,uninsclearvalue,uninsdeleteentry,' +
    'uninsdeletekey,uninsdeletekeyifempty,uninsdeletesection,' +
    'uninsdeletesectionifempty,uninsdeletevalue,uninsneveruninstall,' +
    'useapppaths,verysilent,waituntilidle';

procedure MakeIdentTable;
var
  c: char;
begin
  FillChar(Identifiers, SizeOf(Identifiers), 0);
  for c := 'a' to 'z' do
    Identifiers[c] := TRUE;
  for c := 'A' to 'Z' do
    Identifiers[c] := TRUE;
  for c := '0' to '9' do
    Identifiers[c] := TRUE;
  Identifiers['_'] := TRUE;

  FillChar(mHashTable, SizeOf(mHashTable), 0);
  mHashTable['_'] := 1;
  for c := 'a' to 'z' do
    mHashTable[c] := 2 + Ord(c) - Ord('a');
  for c := 'A' to 'Z' do
    mHashTable[c] := 2 + Ord(c) - Ord('A');
end;

function TSynInnoSyn.KeyHash(ToHash: PChar): integer;
begin
  Result := 0;
  while Identifiers[ToHash^] do begin
{$IFOPT Q-}
    Result := 7 * Result + mHashTable[ToHash^];
{$ELSE}
    Result := (7 * Result + mHashTable[ToHash^]) and $FFFFFF;
{$ENDIF}
    inc(ToHash);
  end;
  Result := Result and $1FF; // 511
  fStringLen := ToHash - fToIdent;
end;

function TSynInnoSyn.KeyComp(const aKey: string): Boolean;
var
  i: integer;
  pKey1, pKey2: PChar;
begin
  pKey1 := fToIdent;
  // Note: fStringLen is always > 0 !
  pKey2 := pointer(aKey);
  for i := 1 to fStringLen do
  begin
    if mHashTable[pKey1^] <> mHashTable[pKey2^] then
    begin
      Result := FALSE;
      exit;
    end;
    Inc(pKey1);
    Inc(pKey2);
  end;
  Result := TRUE;
end;

function TSynInnoSyn.IdentKind(MayBe: PChar): TtkTokenKind;
var
  Entry: TSynHashEntry;
begin
  fToIdent := MayBe;
  Entry := fKeywords[KeyHash(MayBe)];
  while Assigned(Entry) do begin
    if Entry.KeywordLen > fStringLen then
      break
    else if Entry.KeywordLen = fStringLen then
      if KeyComp(Entry.Keyword) then begin
        Result := TtkTokenKind(Entry.Kind);
        exit;
      end;
    Entry := Entry.Next;
  end;
  Result := tkIdentifier;
end;

procedure TSynInnoSyn.MakeMethodTables;
var
  I: Char;
begin
  for I := #0 to #255 do
    case I of
      #13: fProcTable[I] := CRProc;
      'A'..'Z', 'a'..'z', '_': fProcTable[I] := IdentProc;
      #10: fProcTable[I] := LFProc;
      #0: fProcTable[I] := NullProc;
      '0'..'9': fProcTable[I] := NumberProc;
      #1..#9, #11, #12, #14..#32: fProcTable[I] := SpaceProc;
      #59 {';'}: fProcTable[I] := SemiColonProc;
      #61 {=} : fProcTable[I] := EqualProc;
      #34: fProcTable[I] := StringProc;
      '#', ':', ',', '(', ')': fProcTable[I] := SymbolProc;
      '{': fProcTable[I] := ConstantProc;
      #91 {[} : fProcTable[i] := SectionProc;
      else fProcTable[I] := UnknownProc;
    end;
end;

constructor TSynInnoSyn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fKeywords := TSynHashEntryList.Create;

  fCommentAttri := TSynHighlighterAttributes.Create(SYNS_AttrComment);
  fCommentAttri.Style := [fsItalic];
  fCommentAttri.Foreground := clGray;
  AddAttribute(fCommentAttri);

  fIdentifierAttri := TSynHighlighterAttributes.Create(SYNS_AttrIdentifier);
  AddAttribute(fIdentifierAttri);

  fInvalidAttri := TSynHighlighterAttributes.Create(SYNS_AttrIllegalChar);
  AddAttribute(fInvalidAttri);

  fKeyAttri := TSynHighlighterAttributes.Create(SYNS_AttrReservedWord);
  fKeyAttri.Style := [fsBold];
  fKeyAttri.Foreground := clNavy;
  AddAttribute(fKeyAttri);

  fNumberAttri := TSynHighlighterAttributes.Create(SYNS_AttrNumber);
  fNumberAttri.Foreground := clMaroon;
  AddAttribute(fNumberAttri);

  fSpaceAttri := TSynHighlighterAttributes.Create(SYNS_AttrSpace);
  AddAttribute(fSpaceAttri);

  fStringAttri := TSynHighlighterAttributes.Create(SYNS_AttrString);
  fStringAttri.Foreground := clBlue;
  AddAttribute(fStringAttri);

  fConstantAttri := TSynHighlighterAttributes.Create(SYNS_AttrDirective);
  fConstantAttri.Style := [fsBold, fsItalic];
  fConstantAttri.Foreground := clTeal;
  AddAttribute(fConstantAttri);

  fSymbolAttri := TSynHighlighterAttributes.Create(SYNS_AttrSymbol);
  AddAttribute(fSymbolAttri);

  //Parameters
  fParamAttri := TSynHighlighterAttributes.Create(SYNS_AttrPreprocessor);
  fParamAttri.Style := [fsBold];
  fParamAttri.Foreground := clOlive;
  AddAttribute(fParamAttri);

  fSectionAttri := TSynHighlighterAttributes.Create(SYNS_AttrSection);
  fSectionAttri.Style := [fsBold];
  fSectionAttri.Foreground := clRed;
  AddAttribute(fSectionAttri);

  SetAttributesOnChange(DefHighlightChange);
  EnumerateKeywords(Ord(tkKey), Keywords, IdentChars, DoAddKeyword);
  EnumerateKeywords(Ord(tkParameter), Parameters, IdentChars, DoAddKeyword);
  MakeMethodTables;
  fDefaultFilter := SYNS_FilterInno;
end;

destructor TSynInnoSyn.Destroy;
begin
  fKeywords.Free;
  inherited Destroy;
end;

procedure TSynInnoSyn.SetLine(NewValue: string; LineNumber: Integer);
begin
  fLine := PChar(NewValue);
  Run := 0;
  fLineNumber := LineNumber;
  Next;
end;

procedure TSynInnoSyn.SymbolProc;
begin
  fTokenID := tkSymbol;
  inc(Run);
end;

procedure TSynInnoSyn.CRProc;
begin
  fTokenID := tkSpace;
  inc(Run);
  if fLine[Run] = #10 then inc(Run);
end;

procedure TSynInnoSyn.EqualProc;
begin
// If any word has equal (=) symbol,
// then the immediately followed text is treated as string
// (though it does not have quotes)
  fTokenID := tkString;
  repeat
    Inc(Run);
    if fLine[Run] = ';' then begin
      Inc(Run);
      break;
    end;
  until fLine[Run] in [#0, #10, #13];
end;

procedure TSynInnoSyn.IdentProc;
begin
  fTokenID := IdentKind((fLine + Run));
  inc(Run, fStringLen);
  while Identifiers[fLine[Run]] do inc(Run);
end;

procedure TSynInnoSyn.SectionProc;
begin
  // if it is not column 0 mark as tkParameter and get out of here
  if Run > 0 then
  begin
    fTokenID := tkUnknown;
    inc(Run);
    Exit;
  end;

  // this is column 0 ok it is a Section
  fTokenID := tkSection;
  repeat
    Inc(Run);
    if fLine[Run] = ']' then
    begin
      Inc(Run);
      break;
    end;
  until fLine[Run] in [#0, #10, #13];
end;

procedure TSynInnoSyn.LFProc;
begin
  fTokenID := tkSpace;
  inc(Run);
end;

procedure TSynInnoSyn.NullProc;
begin
  fTokenID := tkNull;
end;

procedure TSynInnoSyn.NumberProc;
begin
  fTokenID := tkNumber;
  repeat
    Inc(Run);
  until not (fLine[Run] in ['0'..'9']);
end;

procedure TSynInnoSyn.ConstantProc;
begin
  fTokenID := tkConstant;
  repeat
    Inc(Run);
    if fLine[Run] = '}' then
    begin
      Inc(Run);
      break;
    end;
  until fLine[Run] in [#0, #10, #13];
end;

procedure TSynInnoSyn.SpaceProc;
begin
  fTokenID := tkSpace;
  repeat
    Inc(Run);
  until (fLine[Run] > #32) or (fLine[Run] in [#0, #10, #13]);
end;

procedure TSynInnoSyn.SemiColonProc;
begin
  if Run > 0 then begin
    fTokenID := tkUnknown;
    inc(Run);
  end else begin
    fTokenID := tkComment;
    repeat
      Inc(Run);
    until (fLine[Run] in [#0, #10, #13]);
  end;
end;

procedure TSynInnoSyn.StringProc;
begin
  fTokenID := tkString;
  if (FLine[Run + 1] = #34) and (FLine[Run + 2] = #34) then inc(Run, 2);
  repeat
    case FLine[Run] of
      #0, #10, #13: break;
    end;
    inc(Run);
  until FLine[Run] = #34;
  if FLine[Run] <> #0 then inc(Run);
end;

procedure TSynInnoSyn.UnknownProc;
begin
  inc(Run);
  fTokenID := tkUnknown;
end;

procedure TSynInnoSyn.Next;
begin
  fTokenPos := Run;
  fProcTable[fLine[Run]];
end;

function TSynInnoSyn.GetDefaultAttribute(Index: integer):
  TSynHighlighterAttributes;
begin
  case Index of
    SYN_ATTR_COMMENT: Result := fCommentAttri;
    SYN_ATTR_IDENTIFIER: Result := fIdentifierAttri;
    SYN_ATTR_KEYWORD: Result := fKeyAttri;
    SYN_ATTR_STRING: Result := fStringAttri;
    SYN_ATTR_WHITESPACE: Result := fSpaceAttri;
    else Result := nil;
  end;
end;

function TSynInnoSyn.GetEol: Boolean;
begin
  Result := (fTokenId = tkNull);
end;

function TSynInnoSyn.GetToken: String;
var
  Len: LongInt;
begin
  Len := Run - fTokenPos;
  SetString(Result, (FLine + fTokenPos), Len);
end;

function TSynInnoSyn.GetTokenAttribute: TSynHighlighterAttributes;
begin
  case fTokenID of
    tkComment: Result := fCommentAttri;
    tkParameter: Result := fParamAttri;
    tkSection: Result := fSectionAttri;
    tkIdentifier: Result := fIdentifierAttri;
    tkKey: Result := fKeyAttri;
    tkNumber: Result := fNumberAttri;
    tkSpace: Result := fSpaceAttri;
    tkString: Result := fStringAttri;
    tkConstant: Result := fConstantAttri;
    tkSymbol: Result := fSymbolAttri;
    tkUnknown: Result := fIdentifierAttri;
    else Result := nil;
  end;
end;

function TSynInnoSyn.GetTokenKind: integer;
begin
  Result := Ord(fTokenId);
end;

function TSynInnoSyn.GetTokenID: TtkTokenKind;
begin
  Result := fTokenId;
end;

function TSynInnoSyn.GetTokenPos: Integer;
begin
  Result := fTokenPos;
end;

function TSynInnoSyn.GetIdentChars: TSynIdentChars;
begin
  Result := ['_', 'a'..'z', 'A'..'Z', '0'..'9'];
end;

{$IFNDEF SYN_CPPB_1} class {$ENDIF}                                             //mh 2000-07-14
function TSynInnoSyn.GetLanguageName: string;
begin
  Result := SYNS_LangInno;
end;

procedure TSynInnoSyn.DoAddKeyword(AKeyword: string; AKind: integer);
var
  HashValue: integer;
begin
  HashValue := KeyHash(PChar(AKeyword));
  fKeywords[HashValue] := TSynHashEntry.Create(AKeyword, AKind);
end;

initialization
  MakeIdentTable;
{$IFNDEF SYN_CPPB_1}                                                            //mh 2000-07-14
  RegisterPlaceableHighlighter(TSynInnoSyn);
{$ENDIF}
end.

