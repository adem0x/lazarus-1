{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Functions to beautify code.
    Goals:
      - Customizable
      - fully automatic
      - Beautification of whole sources. For example a unit, or several
        sources.
      - Beautification of parts of sources. For example selections.
      - Beautification of insertion source. For example beautifying code, that
        will be inserted in another source.
      - Working with syntax errors. The beautification will try its best to
        work, even if the source contains errors.
      - Does not ignore comments and directives
      - Contexts: statements, declarations

  Examples for beautification styles: see scanexamples/indentation.pas
}
unit CodeBeautifier;

{$mode objfpc}{$H+}

interface

{ $DEFINE ShowCodeBeautifier}
{$DEFINE ShowCodeBeautifierParser}

uses
  Classes, SysUtils, FileProcs, KeywordFuncLists, CodeCache, BasicCodeTools;
  
type
  TBeautifySplit =(
    bsNone,
    bsInsertSpace, // insert space before
    bsNewLine,     // break line, no indent
    bsEmptyLine,   // insert empty line, no indent
    bsNewLineAndIndent, // break line, indent
    bsEmptyLineAndIndent, // insert empty line, indent
    bsNewLineUnindent,
    bsEmptyLineUnindent,
    bsNoSplit   // do not break line here when line too long
    );
    
  TWordPolicy = (
    wpNone,
    wpLowerCase,
    wpUpperCase,
    wpLowerCaseFirstLetterUp
    );

  TFABBlockType = (
    bbtNone,
    // code sections
    bbtInterface,
    bbtImplementation,
    bbtInitialization,
    bbtFinalization,
    // identifier sections
    bbtUsesSection,
    bbtTypeSection,
    bbtConstSection,
    bbtVarSection,
    bbtResourceStringSection,
    bbtLabelSection,
    // type blocks
    bbtRecord,
    bbtClass,
    bbtClassInterface,
    bbtClassSection, // public, private, protected, published
    // statement blocks
    bbtProcedure, // procedure, constructor, destructor
    bbtFunction,
    bbtMainBegin,
    bbtCommentaryBegin, // begin without any need
    bbtRepeat,
    bbtProcedureBegin,
    bbtCase,
    bbtCaseOf,    // child of bbtCase
    bbtCaseColon, // child of bbtCase
    bbtCaseBegin, // child of bbtCaseColon
    bbtCaseElse,  // child of bbtCase
    bbtTry,
    bbtFinally,
    bbtExcept,
    bbtIf,
    bbtIfThen,    // child of bbtIf
    bbtIfElse,    // child of bbtIf
    bbtIfBegin    // child of bbtIfThen or bbtIfElse
    );
  TFABBlockTypes = set of TFABBlockType;

const
  bbtAllIdentifierSections = [bbtTypeSection,bbtConstSection,bbtVarSection,
       bbtResourceStringSection,bbtLabelSection];
  bbtAllCodeSections = [bbtInterface,bbtImplementation,bbtInitialization,
                        bbtFinalization];
  bbtAllStatements = [bbtMainBegin,bbtCommentaryBegin,bbtRepeat,bbtProcedureBegin,
                      bbtCaseColon,bbtCaseBegin,bbtCaseElse,
                      bbtTry,bbtFinally,bbtExcept,
                      bbtIfThen,bbtIfElse,bbtIfBegin];
type
  TOnGetFABExamples = procedure(Sender: TObject; Code: TCodeBuffer;
                                out CodeBuffers: TFPList) of object;

  TFABIndentationPolicy = record
    IndentBefore: integer;
    IndentBeforeValid: boolean;
    IndentAfter: integer;
    IndentAfterValid: boolean;
  end;

  { TFABPolicies }

  TFABPolicies = class
  public
    Indentations: array[TFABBlockType] of TFABIndentationPolicy;
    IndentationsFound: array[TFABBlockType] of boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  { TFullyAutomaticBeautifier }

  TFullyAutomaticBeautifier = class
  private
    FOnGetExamples: TOnGetFABExamples;
    procedure ParseSource(const Src: string; SrcLen: integer;
                          NestedComments: boolean; Policies: TFABPolicies);
    procedure FindPolicies(Types: TFABBlockTypes; Policies: TFABPolicies);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetIndent(const Source: string; CleanPos: integer;
                       NewNestedComments: boolean;
                       out Indent: TFABIndentationPolicy): boolean;
    { ToDo:
      - indent on paste  (position + new source)
      - indent auto generated code (several snippets)
      - learn from source
      - learn from nearest lines in source
       }
    property OnGetExamples: TOnGetFABExamples read FOnGetExamples write FOnGetExamples;
  end;

const
  FABBlockTypeNames: array[TFABBlockType] of string = (
    'bbtNone',
    // code sections
    'bbtInterface',
    'bbtImplementation',
    'bbtInitialization',
    'bbtFinalization',
    // identifier sections
    'bbtUsesSection',
    'bbtTypeSection',
    'bbtConstSection',
    'bbtVarSection',
    'bbtResourceStringSection',
    'bbtLabelSection',
    // type blocks
    'bbtRecord',
    'bbtClass',
    'bbtClassInterface',
    'bbtClassSection',
    // statement blocks
    'bbtProcedure',
    'bbtFunction',
    'bbtMainBegin',
    'bbtCommentaryBegin',
    'bbtRepeat',
    'bbtProcedureBegin',
    'bbtCase',
    'bbtCaseOf',
    'bbtCaseColon',
    'bbtCaseBegin',
    'bbtCaseElse',
    'bbtTry',
    'bbtFinally',
    'bbtExcept',
    'bbtIf',
    'bbtIfThen',
    'bbtIfElse',
    'bbtIfBegin'
    );

implementation

type
  TBlock = record
    Typ: TFABBlockType;
    StartPos: integer;
    InnerIdent: integer;
  end;
  PBlock = ^TBlock;

  { TBlockStack }

  TBlockStack = class
  public
    Stack: PBlock;
    Capacity: integer;
    Top: integer;
    TopType: TFABBlockType;
    constructor Create;
    destructor Destroy; override;
    procedure BeginBlock(Typ: TFABBlockType; StartPos: integer);
    procedure EndBlock;
    function TopMostIndexOf(Typ: TFABBlockType): integer;
    function EndTopMostBlock(Typ: TFABBlockType): boolean;
    {$IFDEF ShowCodeBeautifier}
    Src: string;
    function PosToStr(p: integer): string;
    {$ENDIF}
  end;

{ TBlockStack }

constructor TBlockStack.Create;
begin
  Top:=-1;
end;

destructor TBlockStack.Destroy;
begin
  ReAllocMem(Stack,0);
  Capacity:=0;
  Top:=-1;
  inherited Destroy;
end;

procedure TBlockStack.BeginBlock(Typ: TFABBlockType; StartPos: integer);
var
  Block: PBlock;
begin
  inc(Top);
  if Top>=Capacity then begin
    if Capacity=0 then
      Capacity:=16
    else
      Capacity:=Capacity*2;
    ReAllocMem(Stack,SizeOf(TBlock)*Capacity);
  end;
  {$IFDEF ShowCodeBeautifier}
  DebugLn([GetIndentStr(Top*2),'TBlockStack.BeginBlock ',FABBlockTypeNames[Typ],' ',StartPos,' at ',PosToStr(StartPos)]);
  {$ENDIF}
  Block:=@Stack[Top];
  Block^.Typ:=Typ;
  Block^.StartPos:=StartPos;
  Block^.InnerIdent:=-1;
  TopType:=Typ;
end;

procedure TBlockStack.EndBlock;
begin
  {$IFDEF ShowCodeBeautifier}
  DebugLn([GetIndentStr(Top*2),'TBlockStack.EndBlock ',FABBlockTypeNames[TopType]]);
  {$ENDIF}
  dec(Top);
  if Top>=0 then
    TopType:=Stack[Top].Typ
  else
    TopType:=bbtNone;
end;

function TBlockStack.TopMostIndexOf(Typ: TFABBlockType): integer;
begin
  Result:=Top;
  while (Result>=0) and (Stack[Result].Typ<>Typ) do dec(Result);
end;

function TBlockStack.EndTopMostBlock(Typ: TFABBlockType): boolean;
// check if there is this type on the stack and if yes, end it
var
  i: LongInt;
begin
  i:=TopMostIndexOf(Typ);
  if i<0 then exit(false);
  Result:=true;
  while Top>=i do EndBlock;
end;

{$IFDEF ShowCodeBeautifier}
function TBlockStack.PosToStr(p: integer): string;
var
  X: integer;
  Y: LongInt;
begin
  Result:='';
  if Src='' then exit;
  Y:=LineEndCount(Src,1,p,X)+1;
  Result:='Line='+dbgs(Y)+' Col='+dbgs(X);
end;
{$ENDIF}

{ TFullyAutomaticBeautifier }

procedure TFullyAutomaticBeautifier.ParseSource(const Src: string;
  SrcLen: integer; NestedComments: boolean; Policies: TFABPolicies);
var
  Stack: TBlockStack;
  p: Integer;
  AtomStart: integer;

  {$IFDEF ShowCodeBeautifierParser}
  function PosToStr(p: integer): string;
  var
    X: integer;
    Y: LongInt;
  begin
    Y:=LineEndCount(Src,1,p,X)+1;
    Result:='Line='+dbgs(Y)+' Col='+dbgs(X);
  end;
  {$ENDIF}

  procedure BeginBlock(Typ: TFABBlockType);
  begin
    Stack.BeginBlock(Typ,AtomStart);
    {$IFDEF ShowCodeBeautifierParser}
    DebugLn([GetIndentStr(Stack.Top*2),'BeginBlock ',FABBlockTypeNames[Typ],' ',GetAtomString(@Src[AtomStart],NestedComments),' at ',PosToStr(p)]);
    {$ENDIF}
  end;

  procedure EndBlock;
  var
    Block: PBlock;
  begin
    {$IFDEF ShowCodeBeautifierParser}
    DebugLn([GetIndentStr(Stack.Top*2),'EndBlock ',FABBlockTypeNames[Stack.TopType],' ',GetAtomString(@Src[AtomStart],NestedComments),' at ',PosToStr(p)]);
    {$ENDIF}
    Block:=@Stack.Stack[Stack.Top];
    if (Policies<>nil)
    and (not Policies.Indentations[Block^.Typ].IndentBeforeValid) then begin
      with Policies.Indentations[Block^.Typ] do begin
        IndentBefore:=-IndentAfter;
        IndentBeforeValid:=IndentAfterValid;
        {$IFDEF ShowCodeBeautifierParser}
        DebugLn([GetIndentStr(Stack.Top*2),'Indentation learned: ',FABBlockTypeNames[Block^.Typ],' IndentBefore=',IndentBefore]);
        {$ENDIF}
      end;
    end;
    Stack.EndBlock;
  end;

  procedure EndTopMostBlock(Typ: TFABBlockType);
  var
    i: LongInt;
  begin
    i:=Stack.TopMostIndexOf(Typ);
    if i<0 then exit;
    while Stack.Top>=i do EndBlock;
  end;

  procedure EndStatements;
  begin
    while Stack.TopType in bbtAllStatements do EndBlock;
  end;

  procedure StartIdentifierSection(Section: TFABBlockType);
  begin
    EndStatements;  // fix dangling statements
    if Stack.TopType in [bbtProcedure,bbtFunction] then begin
      if (Stack.Top=0) or (Stack.Stack[Stack.Top-1].Typ in [bbtImplementation])
      then begin
        // procedure with begin..end
      end else begin
        // procedure without begin..end
        EndBlock;
      end;
    end;
    if Stack.TopType in bbtAllIdentifierSections then
      EndBlock;
    if Stack.TopType in (bbtAllCodeSections+[bbtNone,bbtProcedure,bbtFunction]) then
      BeginBlock(Section);
  end;

  procedure StartProcedure(Typ: TFABBlockType);
  begin
    EndStatements; // fix dangling statements
    if Stack.TopType in [bbtProcedure,bbtFunction] then begin
      if (Stack.Top=0) or (Stack.Stack[Stack.Top-1].Typ in [bbtImplementation])
      then begin
        // procedure with begin..end
      end else begin
        // procedure without begin..end
        EndBlock;
      end;
    end;
    if Stack.TopType in bbtAllIdentifierSections then
      EndBlock;
    if Stack.TopType in (bbtAllCodeSections+[bbtNone,bbtProcedure,bbtFunction]) then
      BeginBlock(Typ);
  end;

  procedure StartClassSection;
  begin
    if Stack.TopType=bbtClassSection then
      EndBlock;
    if Stack.TopType=bbtClass then
      BeginBlock(bbtClassSection);
  end;

var
  r: PChar;
  Block: PBlock;
  Indent: Integer;
begin
  Stack:=TBlockStack.Create;
  try
    p:=1;
    repeat
      ReadRawNextPascalAtom(Src,p,AtomStart,NestedComments);
      DebugLn(['TFullyAutomaticBeautifier.ParseSource ',copy(Src,AtomStart,p-AtomStart)]);
      if p>SrcLen then break;

      if (Stack.Top>=0) then begin
        Block:=@Stack.Stack[Stack.Top];
        if (Policies<>nil)
        and (not Policies.Indentations[Block^.Typ].IndentAfterValid) then begin
          // set block InnerIdent
          if (Block^.InnerIdent<0)
          and (not PositionsInSameLine(Src,Block^.StartPos,AtomStart)) then begin
            Block^.InnerIdent:=GetLineIndent(Src,AtomStart);
            if Block^.Typ in [bbtIfThen,bbtIfElse] then
              Indent:=Block^.InnerIdent-GetLineIndent(Src,Stack.Stack[Stack.Top-1].StartPos)
            else
              Indent:=Block^.InnerIdent-GetLineIndent(Src,Block^.StartPos);
            Policies.Indentations[Block^.Typ].IndentAfter:=Indent;
            Policies.Indentations[Block^.Typ].IndentAfterValid:=true;
            {$IFDEF ShowCodeBeautifierParser}
            DebugLn([GetIndentStr(Stack.Top*2),'Indentation learned: ',FABBlockTypeNames[Block^.Typ],' IndentAfter=',Policies.Indentations[Block^.Typ].IndentAfter]);
            {$ENDIF}
          end;
        end;
      end;

      r:=@Src[AtomStart];
      case UpChars[r^] of
      'B':
        if CompareIdentifiers('BEGIN',r)=0 then begin
          while Stack.TopType in (bbtAllIdentifierSections+bbtAllCodeSections) do
            EndBlock;
          case Stack.TopType of
          bbtNone:
            BeginBlock(bbtMainBegin);
          bbtProcedure,bbtFunction:
            BeginBlock(bbtProcedureBegin);
          bbtMainBegin:
            BeginBlock(bbtCommentaryBegin);
          bbtCaseElse,bbtCaseColon:
            BeginBlock(bbtCaseBegin);
          bbtIfThen,bbtIfElse:
            BeginBlock(bbtIfBegin);
          end;
        end;
      'C':
        case UpChars[r[1]] of
        'A': // CA
          if CompareIdentifiers('CASE',r)=0 then begin
            if Stack.TopType in bbtAllStatements then
              BeginBlock(bbtCase);
          end;
        'L': // CL
          if CompareIdentifiers('CLASS',r)=0 then begin
            if Stack.TopType=bbtTypeSection then
              BeginBlock(bbtClass);
          end;
        'O': // CO
          if CompareIdentifiers('CONST',r)=0 then
            StartIdentifierSection(bbtConstSection);
        end;
      'E':
        case UpChars[r[1]] of
        'L': // EL
          if CompareIdentifiers('ELSE',r)=0 then begin
            case Stack.TopType of
            bbtCaseOf,bbtCaseColon:
              begin
                EndBlock;
                BeginBlock(bbtCaseElse);
              end;
            bbtIfThen:
              begin
                EndBlock;
                BeginBlock(bbtIfElse);
              end;
            end;
          end;
        'N': // EN
          if CompareIdentifiers('END',r)=0 then begin
            // if statements can be closed by end without semicolon
            while Stack.TopType in [bbtIf,bbtIfThen,bbtIfElse] do EndBlock;
            if Stack.TopType=bbtClassSection then
              EndBlock;

            case Stack.TopType of
            bbtMainBegin,bbtCommentaryBegin,
            bbtRecord,bbtClass,bbtClassInterface,bbtTry,bbtFinally,bbtExcept,
            bbtCase,bbtCaseBegin,bbtIfBegin:
              EndBlock;
            bbtCaseOf,bbtCaseElse,bbtCaseColon:
              begin
                EndBlock;
                if Stack.TopType=bbtCase then
                  EndBlock;
              end;
            bbtProcedureBegin:
              begin
                EndBlock;
                if Stack.TopType in [bbtProcedure,bbtFunction] then
                  EndBlock;
              end;
            bbtInterface,bbtImplementation,bbtInitialization,bbtFinalization:
              EndBlock;
            end;
          end;
        'X': // EX
          if CompareIdentifiers('EXCEPT',r)=0 then begin
            if Stack.TopType=bbtTry then begin
              EndBlock;
              BeginBlock(bbtExcept);
            end;
          end;
        end;
      'F':
        case UpChars[r[1]] of
        'I': // FI
          if CompareIdentifiers('FINALIZATION',r)=0 then begin
            while Stack.TopType in (bbtAllCodeSections+bbtAllIdentifierSections+bbtAllStatements)
            do
              EndBlock;
            if Stack.TopType=bbtNone then
              BeginBlock(bbtInitialization);
          end else if CompareIdentifiers('FINALLY',r)=0 then begin
            if Stack.TopType=bbtTry then begin
              EndBlock;
              BeginBlock(bbtFinally);
            end;
          end;
        'O': // FO
          if CompareIdentifiers('FORWARD',r)=0 then begin
            if Stack.TopType in [bbtProcedure,bbtFunction] then begin
              EndBlock;
            end;
          end;
        'U': // FU
          if CompareIdentifiers('FUNCTION',r)=0 then
            StartProcedure(bbtFunction);
        end;
      'I':
        case UpChars[r[1]] of
        'F': // IF
          if p-AtomStart=2 then begin
            // 'IF'
            if Stack.TopType in bbtAllStatements then
              BeginBlock(bbtIf);
          end;
        'N': // IN
          case UpChars[r[2]] of
          'I': // INI
            if CompareIdentifiers('INITIALIZATION',r)=0 then begin
              while Stack.TopType in (bbtAllCodeSections+bbtAllIdentifierSections+bbtAllStatements)
              do
                EndBlock;
              if Stack.TopType=bbtNone then
                BeginBlock(bbtInitialization);
            end;
          'T': // INT
            if CompareIdentifiers('INTERFACE',r)=0 then begin
              case Stack.TopType of
              bbtNone:
                BeginBlock(bbtInterface);
              bbtTypeSection:
                BeginBlock(bbtClassInterface);
              end;
            end;
          end;
        'M': // IM
          if CompareIdentifiers('IMPLEMENTATION',r)=0 then begin
            while Stack.TopType in (bbtAllCodeSections+bbtAllIdentifierSections+bbtAllStatements)
            do
              EndBlock;
            if Stack.TopType=bbtNone then
              BeginBlock(bbtImplementation);
          end;
        end;
      'L':
        if CompareIdentifiers('LABEL',r)=0 then
          StartIdentifierSection(bbtLabelSection);
      'O':
        if CompareIdentifiers('OF',r)=0 then begin
          case Stack.TopType of
          bbtCase:
            BeginBlock(bbtCaseOf);
          bbtClass,bbtClassInterface:
            EndBlock;
          end;
        end;
      'P':
        case UpChars[r[1]] of
        'R': // PR
          case UpChars[r[2]] of
          'I': // PRI
            if (CompareIdentifiers('PRIVATE',r)=0) then
              StartClassSection;
          'O': // PRO
            case UpChars[r[3]] of
            'T': // PROT
              if (CompareIdentifiers('PROTECTED',r)=0) then
                StartClassSection;
            'C': // PROC
              if CompareIdentifiers('PROCEDURE',r)=0 then
                StartProcedure(bbtProcedure);
            end;
          end;
        'U': // PU
          if (CompareIdentifiers('PUBLIC',r)=0)
          or (CompareIdentifiers('PUBLISHED',r)=0) then
            StartClassSection;
        end;
      'R':
        case UpChars[r[1]] of
        'E': // RE
          case UpChars[r[2]] of
          'C': // REC
            if CompareIdentifiers('RECORD',r)=0 then
              BeginBlock(bbtRecord);
          'P': // REP
            if CompareIdentifiers('REPEAT',r)=0 then
              if Stack.TopType in bbtAllStatements then
                BeginBlock(bbtRepeat);
          'S': // RES
            if CompareIdentifiers('RESOURCESTRING',r)=0 then
              StartIdentifierSection(bbtResourceStringSection);
          end;
        end;
      'T':
        case UpChars[r[1]] of
        'H': // TH
          if CompareIdentifiers('THEN',r)=0 then begin
            if Stack.TopType=bbtIf then
              BeginBlock(bbtIfThen);
          end;
        'R': // TR
          if CompareIdentifiers('TRY',r)=0 then begin
            if Stack.TopType in bbtAllStatements then
              BeginBlock(bbtTry);
          end;
        'Y': // TY
          if CompareIdentifiers('TYPE',r)=0 then begin
            StartIdentifierSection(bbtTypeSection);
          end;
        end;
      'U':
        case UpChars[r[1]] of
        'S': // US
          if CompareIdentifiers('USES',r)=0 then begin
            if Stack.TopType in [bbtNone,bbtInterface,bbtImplementation] then
              BeginBlock(bbtUsesSection);
          end;
        'N': // UN
          if CompareIdentifiers('UNTIL',r)=0 then begin
            EndTopMostBlock(bbtRepeat);
          end;
        end;
      'V':
        if CompareIdentifiers('VAR',r)=0 then begin
          StartIdentifierSection(bbtVarSection);
        end;
      ';':
        case Stack.TopType of
        bbtUsesSection:
          EndBlock;
        bbtCaseColon:
          begin
            EndBlock;
            BeginBlock(bbtCaseOf);
          end;
        bbtIfThen,bbtIfElse:
          while Stack.TopType in [bbtIf,bbtIfThen,bbtIfElse] do
            EndBlock;
        end;
      ':':
        if p-AtomStart=1 then begin
          // colon
          case Stack.TopType of
          bbtCaseOf:
            begin
              EndBlock;
              BeginBlock(bbtCaseColon);
            end;
          bbtIf:
            EndBlock;
          bbtIfThen,bbtIfElse:
            begin
              EndBlock;
              if Stack.TopType=bbtIf then
                EndBlock;
            end;
          end;
        end;
      end;
    until false;
  finally
    Stack.Free;
  end;
end;

procedure TFullyAutomaticBeautifier.FindPolicies(Types: TFABBlockTypes;
  Policies: TFABPolicies);
begin

end;

constructor TFullyAutomaticBeautifier.Create;
begin

end;

destructor TFullyAutomaticBeautifier.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TFullyAutomaticBeautifier.Clear;
begin

end;

function TFullyAutomaticBeautifier.GetIndent(const Source: string;
  CleanPos: integer; NewNestedComments: boolean;
  out Indent: TFABIndentationPolicy): boolean;
var
  Policies: TFABPolicies;
begin
  Result:=false;
  FillByte(Indent,SizeOf(Indent),0);

  Policies:=TFABPolicies.Create;
  try
    // parse source
    ParseSource(Source,length(Source),NewNestedComments,Policies);

  finally
    Policies.Free;
  end;

  //SrcPolicies:=
end;

{ TFABPolicies }

constructor TFABPolicies.Create;
begin

end;

destructor TFABPolicies.Destroy;
begin
  inherited Destroy;
end;

procedure TFABPolicies.Clear;
var
  i: TFABBlockType;
begin
  for i:=low(Indentations) to High(Indentations) do
    IndentationsFound[i]:=false;
end;

end.

