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
    TCodeCompletionCodeTool enhances TMethodJumpingCodeTool.
    
    Code Completion is
      - complete properties
          - complete property statements
          - add private variables and private access methods
      - add missing method bodies
          - add useful statements
      - add missing forward proc bodies
      - add missing semicolons at end of procedures
      - complete event assignments
      - complete local variables
      - complete local variables as parameter
      - insert header comment for classes

  ToDo:
    -add code for array properties (TList, TFPList, array of, Pointer array)
      TList:
        property Items[Index: integer]: AType;
        -> creates via dialog
          property Items[Index: integer]: Type2 read GetItems write SetItems;
          private FItems: TList;
          private function GetItems(Index: integer): Type2;
            begin
              Result:=Type2(FItems[Index]);
            end;
          private procedure SetItems(Index: integer; const AValue: Type2);
            begin
              FItems[Index]:=Type2;
            end;
          public constructor Create;
            begin
              FItems:=TList.Create;
            end;
          public destructor Destroy; override;
            begin
              FItems.Free;
              inherited Destroy;
            end;

    -VarExists: search vars in ancestors too
}
unit CodeCompletionTool;

{$ifdef FPC}{$mode objfpc}{$endif}{$H+}

interface

{$I codetools.inc}

{off $DEFINE CTDEBUG}
{$DEFINE VerboseCompletionAdds}
{off $DEFINE VerboseUpdateProcBodySignatures}
{off $DEFINE VerboseCompleteMethod}
{off $DEFINE VerboseCompleteLocalVarAssign}
{off $DEFINE VerboseCompleteEventAssign}

uses
  {$IFDEF MEM_CHECK}
  MemCheck,
  {$ENDIF}
  Classes, SysUtils, FileProcs, CodeToolsStrConsts, CodeTree, CodeAtom,
  CodeCache, CustomCodeTool, PascalParserTool, MethodJumpTool,
  FindDeclarationTool, KeywordFuncLists, CodeToolsStructs, BasicCodeTools,
  LinkScanner, SourceChanger, CodeGraph, AVL_Tree;

type
  TNewClassPart = (ncpPrivateProcs, ncpPrivateVars,
                   ncpProtectedProcs, ncpProtectedVars,
                   ncpPublicProcs, ncpPublicVars,
                   ncpPublishedProcs, ncpPublishedVars);
                   
  TNewVarLocation = (
    ncpvPrivate,ncpvProtected,ncpvPublic,ncpvPublished,ncpvLocal
    );

const
  NewClassPartProcs = [ncpPrivateProcs,ncpProtectedProcs,ncpPublicProcs,ncpPublishedProcs];
  NewClassPartVars = [ncpPrivateVars,ncpProtectedVars,ncpPublicVars,ncpPublishedVars];

  NewClassPartVisibility: array[TNewClassPart] of TPascalClassSection = (
    pcsPrivate, pcsPrivate,
    pcsProtected, pcsProtected,
    pcsPublic, pcsPublic,
    pcsPublished, pcsPublished
    );
    
  PascalClassSectionToNodeDesc: array[TPascalClassSection] of TCodeTreeNodeDesc = (
    ctnClassPrivate,   // pcsPrivate
    ctnClassProtected, // pcsProtected
    ctnClassPublic,    // pcsPublic
    ctnClassPublished  // pcsPublished
  );
  
type
  TCodeCompletionCodeTool = class;

  { TCodeCompletionCodeTool }

  TCodeCompletionCodeTool = class(TMethodJumpingCodeTool)
  private
    ASourceChangeCache: TSourceChangeCache;
    FCodeCompleteClassNode: TCodeTreeNode; // the class that is to be completed (ctnClass, ...)
    FCompletingStartNode: TCodeTreeNode; // the first variable/method/GUID node in FCodeCompleteClassNode
    FAddInheritedCodeToOverrideMethod: boolean;
    FCompleteProperties: boolean;
    FirstInsert: TCodeTreeNodeExtension; // list of insert requests
    FSetPropertyVariablename: string;
    FJumpToProcName: string;
    NewClassSectionIndent: array[TPascalClassSection] of integer;
    NewClassSectionInsertPos: array[TPascalClassSection] of integer;
    fFullTopLvlName: string;// used by OnTopLvlIdentifierFound
    fNewMainUsesSectionUnits: TAVLTree; // tree of AnsiString
    procedure AddNewPropertyAccessMethodsToClassProcs(ClassProcs: TAVLTree;
      const TheClassName: string);
    function UpdateProcBodySignatures(ClassProcs, ProcBodyNodes: TAVLTree;
      ProcAttrCopyDefToBody: TProcHeadAttributes; out ProcsCopied: boolean): boolean;
    procedure GuessMethodDefBodyMapping(ClassProcs, ProcBodyNodes: TAVLTree);
    function GatherClassProcDefinitions(ClassNode: TCodeTreeNode;
      RemoveAbstracts: boolean): TAVLTree;
    function GatherClassProcBodies(ClassNode: TCodeTreeNode): TAVLTree;
    procedure CheckForOverrideAndAddInheritedCode(
      ANodeExt: TCodeTreeNodeExtension; Indent: integer);
    function CompleteProperty(PropNode: TCodeTreeNode): boolean;
    function GetFirstClassIdentifier(ClassNode: TCodeTreeNode): TCodeTreeNode;
    procedure SetCodeCompleteClassNode(const AClassNode: TCodeTreeNode);
    procedure SetCodeCompleteSrcChgCache(const AValue: TSourceChangeCache);
    function OnTopLvlIdentifierFound(Params: TFindDeclarationParams;
        const FoundContext: TFindContext): TIdentifierFoundResult;
    procedure RemoveNewMainUsesSectionUnit(p: PChar);
  protected
    procedure CheckWholeUnitParsed(var Node1, Node2: TCodeTreeNode);
    procedure FreeClassInsertionList;
    procedure InsertNewClassParts(PartType: TNewClassPart);
    function InsertAllNewClassParts: boolean;
    function InsertClassHeaderComment: boolean;
    function InsertMissingClassSemicolons: boolean;
    function InsertAllNewUnitsToMainUsesSection: boolean;
    function FindClassMethodsComment(StartPos: integer;
           out CommentStart, CommentEnd: integer): boolean;
    function CreateMissingProcBodies: boolean;
    function ApplyChangesAndJumpToFirstNewProc(CleanPos: integer;
           OldTopLine: integer; AddMissingProcBodies: boolean;
           out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
    function NodeExtIsVariable(ANodeExt: TCodeTreeNodeExtension): boolean;
    function NodeExtHasVisibilty(ANodeExt: TCodeTreeNodeExtension;
      Visibility: TPascalClassSection): boolean;
    procedure FindInsertPositionForForwardProc(
           SourceChangeCache: TSourceChangeCache;
           ProcNode: TCodeTreeNode; var Indent, InsertPos: integer);
    procedure FindInsertPositionForProcInterface(var Indent, InsertPos: integer;
           SourceChangeCache: TSourceChangeCache);
    function CheckLocalVarAssignmentSyntax(CleanCursorPos: integer;
           out VarNameAtom,AssignmentOperator,TermAtom: TAtomPosition): boolean;
    function CheckLocalVarForInSyntax(CleanCursorPos: integer;
           out VarNameAtom,TermAtom: TAtomPosition): boolean;
    function AddLocalVariable(CleanCursorPos: integer; OldTopLine: integer;
                       VariableName, VariableType, VariableTypeUnitName: string;
                       out NewPos: TCodeXYPosition; out NewTopLine: integer;
                       SourceChangeCache: TSourceChangeCache;
                       CleanLevelPos: integer = 0): boolean;
    procedure AdjustCursor(OldCodePos: TCodePosition; OldTopLine: integer;
                          out NewPos: TCodeXYPosition; out NewTopLine: integer);
    procedure AddNeededUnitToMainUsesSection(AnUnitName: PChar);
    procedure AddMethodCompatibleToProcType(AClassNode: TCodeTreeNode;
                  const AnEventName: string; ProcContext: TFindContext; out
                  MethodDefinition: string; out MethodAttr: TProcHeadAttributes;
                  SourceChangeCache: TSourceChangeCache);
    procedure AddProcedureCompatibleToProcType(
                  const NewProcName: string; ProcContext: TFindContext; out
                  MethodDefinition: string; out MethodAttr: TProcHeadAttributes;
                  SourceChangeCache: TSourceChangeCache;
                  CursorNode: TCodeTreeNode = nil);
    function CompleteClass(AClassNode: TCodeTreeNode;
                           CleanCursorPos, OldTopLine: integer;
                           CursorNode: TCodeTreeNode;
                var NewPos: TCodeXYPosition; var NewTopLine: integer): boolean;
    function CompleteForwardProcs(CursorPos: TCodeXYPosition;
                     ProcNode, CursorNode: TCodeTreeNode;
                     var NewPos: TCodeXYPosition; var NewTopLine: integer;
                     SourceChangeCache: TSourceChangeCache): boolean;
    function CompleteLocalVariableAssignment(CleanCursorPos,
                       OldTopLine: integer; CursorNode: TCodeTreeNode;
                       var NewPos: TCodeXYPosition; var NewTopLine: integer;
                       SourceChangeCache: TSourceChangeCache): boolean;
    function CompleteEventAssignment(CleanCursorPos,
                       OldTopLine: integer; CursorNode: TCodeTreeNode;
                       out IsEventAssignment: boolean;
                       var NewPos: TCodeXYPosition; var NewTopLine: integer;
                       SourceChangeCache: TSourceChangeCache): boolean;
    function CompleteLocalVariableForIn(CleanCursorPos,
                       OldTopLine: integer; CursorNode: TCodeTreeNode;
                       var NewPos: TCodeXYPosition; var NewTopLine: integer;
                       SourceChangeCache: TSourceChangeCache): boolean;
    function CompleteLocalIdentifierByParameter(CleanCursorPos,
                       OldTopLine: integer; CursorNode: TCodeTreeNode;
                       var NewPos: TCodeXYPosition; var NewTopLine: integer;
                       SourceChangeCache: TSourceChangeCache): boolean;
    function CompleteMethodByBody(CleanCursorPos, OldTopLine: integer;
                           CursorNode: TCodeTreeNode;
                           var NewPos: TCodeXYPosition; var NewTopLine: integer;
                           SourceChangeCache: TSourceChangeCache): boolean;
    function CreateParamListFromStatement(CursorNode: TCodeTreeNode;
                                          BracketOpenPos: integer;
                                          out CleanList: string): string;
    function CompleteProcByCall(CleanCursorPos, OldTopLine: integer;
                           CursorNode: TCodeTreeNode;
                           var NewPos: TCodeXYPosition; var NewTopLine: integer;
                           SourceChangeCache: TSourceChangeCache): boolean;
  protected
    procedure DoDeleteNodes(StartNode: TCodeTreeNode); override;
    property CodeCompleteClassNode: TCodeTreeNode
                     read FCodeCompleteClassNode write SetCodeCompleteClassNode;
    property CodeCompleteSrcChgCache: TSourceChangeCache
                       read ASourceChangeCache write SetCodeCompleteSrcChgCache;
  public
    constructor Create;
    function CompleteCode(CursorPos: TCodeXYPosition; OldTopLine: integer;
                          out NewPos: TCodeXYPosition; out NewTopLine: integer;
                          SourceChangeCache: TSourceChangeCache): boolean;
    function CreateVariableForIdentifier(CursorPos: TCodeXYPosition; OldTopLine: integer;
                          out NewPos: TCodeXYPosition; out NewTopLine: integer;
                          SourceChangeCache: TSourceChangeCache): boolean;
    function AddMethods(CursorPos: TCodeXYPosition;// position in class declaration
                        OldTopLine: integer;
                        ListOfPCodeXYPosition: TFPList;
                        const VirtualToOverride: boolean;
                        out NewPos: TCodeXYPosition; out NewTopLine: integer;
                        SourceChangeCache: TSourceChangeCache): boolean;
    function AddPublishedVariable(const UpperClassName,VarName, VarType: string;
                      SourceChangeCache: TSourceChangeCache): boolean; override;
    function GatherPublishedMethods(ClassNode: TCodeTreeNode;
                              out ListOfPFindContext: TFPList): boolean;

    // graph of definitions of a unit
    function GatherUnitDefinitions(out TreeOfCodeTreeNodeExt: TAVLTree;
                      OnlyInterface, ExceptionOnRedefinition: boolean): boolean;
    function BuildUnitDefinitionGraph(
                        out DefinitionsTreeOfCodeTreeNodeExt: TAVLTree;
                        out Graph: TCodeGraph; OnlyInterface: boolean): boolean;
    procedure WriteCodeGraphDebugReport(Graph: TCodeGraph);

    // redefinitions
    function GetRedefinitionNodeText(Node: TCodeTreeNode): string;
    function FindRedefinitions(out TreeOfCodeTreeNodeExt: TAVLTree;
                        WithEnums: boolean): boolean;
    function RemoveRedefinitions(TreeOfCodeTreeNodeExt: TAVLTree;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function FindAliasDefinitions(out TreeOfCodeTreeNodeExt: TAVLTree;
                                  OnlyWrongType: boolean): boolean;
    function FixAliasDefinitions(TreeOfCodeTreeNodeExt: TAVLTree;
                                SourceChangeCache: TSourceChangeCache): boolean;

    // const functions
    function FindConstFunctions(out TreeOfCodeTreeNodeExt: TAVLTree): boolean;
    function ReplaceConstFunctions(TreeOfCodeTreeNodeExt: TAVLTree;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function FindTypeCastFunctions(out TreeOfCodeTreeNodeExt: TAVLTree): boolean;

    // typecast functions
    function ReplaceTypeCastFunctions(TreeOfCodeTreeNodeExt: TAVLTree;
                                SourceChangeCache: TSourceChangeCache): boolean;
    function MovePointerTypesToTargetSections(
                                SourceChangeCache: TSourceChangeCache): boolean;

    // sort procs
    function FixForwardDefinitions(SourceChangeCache: TSourceChangeCache
                                   ): boolean;

    // empty functions
    function FindEmptyMethods(CursorPos: TCodeXYPosition;
                              const AClassName: string; // can be ''
                              const Sections: TPascalClassSections;
                              ListOfPCodeXYPosition: TFPList;
                              out AllEmpty: boolean): boolean;
    function FindEmptyMethods(CursorPos: TCodeXYPosition;
                              const AClassName: string; // can be ''
                              const Sections: TPascalClassSections;
                              CodeTreeNodeExtensions: TAVLTree;
                              out AllEmpty: boolean): boolean;
    function RemoveEmptyMethods(CursorPos: TCodeXYPosition;
                              const AClassName: string;
                              const Sections: TPascalClassSections;
                              SourceChangeCache: TSourceChangeCache;
                              out AllRemoved: boolean;
                              const Attr: TProcHeadAttributes;
                              out RemovedProcHeads: TStrings): boolean;

    // assign/init records/classes
    function FindAssignMethod(CursorPos: TCodeXYPosition;
        out ClassNode: TCodeTreeNode;
        out AssignDeclNode: TCodeTreeNode;
        var MemberNodeExts: TAVLTree; // tree of TCodeTreeNodeExtension, Node=var or property, Data=write property
        out AssignBodyNode: TCodeTreeNode;
        out InheritedDeclContext: TFindContext;
        ProcName: string = '' // default is 'Assign'
        ): boolean;
    function AddAssignMethod(ClassNode: TCodeTreeNode; MemberNodeExts: TFPList;
        const ProcName, ParamName, ParamType: string;
        OverrideMod, CallInherited, CallInheritedOnlyInElse: boolean;
        SourceChanger: TSourceChangeCache;
        out NewPos: TCodeXYPosition; out NewTopLine: integer;
        LocalVarName: string = '' // default aSource
        ): boolean;

    // guess type of an undeclared identifier
    function GuessTypeOfIdentifier(CursorPos: TCodeXYPosition;
        out IsKeyword, IsSubIdentifier: boolean;
        out ExistingDefinition: TFindContext; // next existing definition
        out ListOfPFindContext: TFPList; // possible classes
        out NewExprType: TExpressionType; out NewType: string): boolean; // false = not at an identifier
    function DeclareVariableNearBy(InsertPos: TCodeXYPosition;
        const VariableName, NewType, NewUnitName: string;
        Visibility: TCodeTreeNodeDesc;
        SourceChangeCache: TSourceChangeCache;
        LevelPos: TCodeXYPosition  // optional
        ): boolean;
    function DeclareVariableAt(CursorPos: TCodeXYPosition;
        const VariableName, NewType, NewUnitName: string;
        SourceChangeCache: TSourceChangeCache): boolean;

    // custom class completion
    function InitClassCompletion(const AClassName: string;
                                 SourceChangeCache: TSourceChangeCache): boolean;
    function InitClassCompletion(ClassNode: TCodeTreeNode;
                                 SourceChangeCache: TSourceChangeCache): boolean;
    function ApplyClassCompletion(AddMissingProcBodies: boolean): boolean;
    function ProcExistsInCodeCompleteClass(
                                    const NameAndParamsUpCase: string): boolean;
    function VarExistsInCodeCompleteClass(const UpperName: string): boolean;
    procedure AddClassInsertion(
        const CleanDef, Def, IdentifierName: string;
        TheType: TNewClassPart; PosNode: TCodeTreeNode = nil;
        const Body: string = '');
    procedure AddNeededUnitsToMainUsesSectionForRange(
        StartPos, EndPos: integer; CompletionTool: TCodeCompletionCodeTool);

    property SetPropertyVariablename: string read FSetPropertyVariablename
                                             write FSetPropertyVariablename;
    property CompleteProperties: boolean read FCompleteProperties
                                         write FCompleteProperties;
    property AddInheritedCodeToOverrideMethod: boolean
                                        read FAddInheritedCodeToOverrideMethod
                                        write FAddInheritedCodeToOverrideMethod;

    procedure CalcMemSize(Stats: TCTMemStats); override;
  end;

  
implementation

type
  TNodeMoveEdge = class
  public
    GraphNode: TCodeGraphNode;
    DestPos: integer;
    TologicalLevel: integer;
    SrcPos: integer;
  end;
  
function CompareNodeMoveEdges(NodeMove1, NodeMove2: Pointer): integer;
var
  Node1: TNodeMoveEdge;
  Node2: TNodeMoveEdge;
begin
  Node1:=TNodeMoveEdge(NodeMove1);
  Node2:=TNodeMoveEdge(NodeMove2);
  if Node1.DestPos>Node2.DestPos then
    Result:=1
  else if Node1.DestPos<Node2.DestPos then
    Result:=-1
  else if Node1.TologicalLevel>Node2.TologicalLevel then
    Result:=1
  else if Node1.TologicalLevel<Node2.TologicalLevel then
    Result:=-1
  else if Node1.SrcPos>Node2.SrcPos then
    Result:=1
  else if Node1.SrcPos<Node2.SrcPos then
    Result:=-1
  else
    Result:=0;
end;


{ TCodeCompletionCodeTool }

function TCodeCompletionCodeTool.ProcExistsInCodeCompleteClass(
  const NameAndParamsUpCase: string): boolean;
// NameAndParams should be uppercase and contains the proc name and the
// parameter list without names and default values
// and should not contain any comments and no result type
var ANodeExt: TCodeTreeNodeExtension;
begin
  Result:=false;
  // search in new nodes, which will be inserted
  ANodeExt:=FirstInsert;
  while ANodeExt<>nil do begin
    if CompareTextIgnoringSpace(ANodeExt.Txt,NameAndParamsUpCase,true)=0 then
      exit(true);
    ANodeExt:=ANodeExt.Next;
  end;
  // ToDo: check ancestor procs too
  // search in current class
  Result:=(FindProcNode(FCompletingStartNode,NameAndParamsUpCase,[phpInUpperCase])<>nil);
end;

procedure TCodeCompletionCodeTool.SetCodeCompleteClassNode(const AClassNode: TCodeTreeNode);
begin
  FreeClassInsertionList;
  FJumpToProcName:='';
  FCodeCompleteClassNode:=AClassNode;
  if CodeCompleteClassNode=nil then begin
    FCompletingStartNode:=nil;
    exit;
  end;
  ClearIgnoreErrorAfter;
  // find first variable/method/GUID
  FCompletingStartNode:=GetFirstClassIdentifier(CodeCompleteClassNode);
end;

procedure TCodeCompletionCodeTool.SetCodeCompleteSrcChgCache(
  const AValue: TSourceChangeCache);
begin
  ASourceChangeCache:=AValue;
  ASourceChangeCache.MainScanner:=Scanner;
end;

function TCodeCompletionCodeTool.OnTopLvlIdentifierFound(
  Params: TFindDeclarationParams; const FoundContext: TFindContext
  ): TIdentifierFoundResult;
var
  TrimmedIdentifier: string;
begin
  if not (fdfTopLvlResolving in Params.Flags) then exit;
  with Params do begin
    case NewNode.Desc of
    ctnTypeDefinition,ctnVarDefinition,ctnConstDefinition,ctnGenericType:
      TrimmedIdentifier:=NewCodeTool.ExtractDefinitionName(NewNode);
    ctnProperty:
      TrimmedIdentifier:=NewCodeTool.ExtractPropName(NewNode,false);
    else
      TrimmedIdentifier:=GetIdentifier(Params.Identifier);
    end;
  end;
  fFullTopLvlName:=fFullTopLvlName+TrimmedIdentifier;
  Result:=ifrSuccess;
end;

procedure TCodeCompletionCodeTool.RemoveNewMainUsesSectionUnit(p: PChar);
var
  AVLNode: TAVLTreeNode;
  s: string;
begin
  if fNewMainUsesSectionUnits=nil then exit;
  AVLNode:=fNewMainUsesSectionUnits.Find(p);
  if AVLNode=nil then exit;
  Pointer(s):=AVLNode.Data;
  s:='';
  fNewMainUsesSectionUnits.Delete(AVLNode);
  if s='' then ;
end;

procedure TCodeCompletionCodeTool.CheckWholeUnitParsed(
  var Node1, Node2: TCodeTreeNode);
var
  Pos1: Integer;
  Pos2: Integer;
begin
  //DebugLn(['TCodeCompletionCodeTool.CheckWholeUnitParsed ',EndOfSourceFound,' LastErrorMessage="',LastErrorMessage,'" LastErrorCurPos=',dbgs(LastErrorCurPos)]);
  if (ScannedRange=lsrEnd) and (not LastErrorValid) then exit;
  Pos1:=0;
  Pos2:=0;
  if Node1<>nil then Pos1:=Node1.StartPos;
  if Node2<>nil then Pos2:=Node2.StartPos;
  ClearIgnoreErrorAfter;
  BuildTree(lsrEnd); // parse whole unit
  if Node1<>nil then Node1:=FindDeepestNodeAtPos(Pos1,true);
  if Node2<>nil then Node2:=FindDeepestNodeAtPos(Pos2,true);
end;

function TCodeCompletionCodeTool.VarExistsInCodeCompleteClass(
  const UpperName: string): boolean;
var ANodeExt: TCodeTreeNodeExtension;
begin
  Result:=false;
  // search in new nodes, which will be inserted
  ANodeExt:=FirstInsert;
  while ANodeExt<>nil do begin
    if CompareTextIgnoringSpace(ANodeExt.Txt,UpperName,true)=0 then
      exit(true);
    ANodeExt:=ANodeExt.Next;
  end;
  // ToDo: check ancestor vars too
  // search in current class
  Result:=(FindVarNode(FCompletingStartNode,UpperName)<>nil);
end;

procedure TCodeCompletionCodeTool.AddClassInsertion(
  const CleanDef, Def, IdentifierName: string; TheType: TNewClassPart;
  PosNode: TCodeTreeNode; const Body: string);
{ add an insert request entry to the list of insertions
  For example: a request to insert a new variable or a new method to the class

  CleanDef:  The sceleton of the new insertion. e.g. the variablename or the
             method header without parameter names.
  Def:       The insertion code.
  IdentifierName: e.g. the variablename or the method name
  TheType:   see TNewClassPart
  PosNode:   optional. The node, to which the request belongs. e.g. the
             property node, if the insert is the auto created private variable.
  Body:      optional. Normally a method body is auto created. This overrides
             the body code.

}
var NewInsert, InsertPos, LastInsertPos: TCodeTreeNodeExtension;
begin
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeCompletionCodeTool.AddClassInsertion] CleanDef="',CleanDef,'" Def="',Def,'" Identifiername="',Identifiername,'" Body="',Body,'"');
  {$ENDIF}
  if CodeCompleteClassNode.Desc in AllClassInterfaces then begin
    // a class interface has no section -> put them all into 'public'
    if TheType in NewClassPartProcs then
      TheType:=ncpPublicProcs
    else if TheType in NewClassPartVars then
      raise Exception.Create('TCodeCompletionCodeTool.AddClassInsertion can not add variables to a class interface');
  end;
  
  NewInsert:=TCodeTreeNodeExtension.Create;
  with NewInsert do begin
    Node:=PosNode;
    Txt:=CleanDef;
    ExtTxt1:=Def;
    ExtTxt2:=IdentifierName;
    ExtTxt3:=Body;
    Flags:=ord(TheType);
  end;
  if FirstInsert=nil then begin
    FirstInsert:=NewInsert;
    exit;
  end;
  if ASourceChangeCache.BeautifyCodeOptions.ClassPartInsertPolicy=cpipLast then
  begin
    // add as last to inserts
    InsertPos:=FirstInsert;
    while (InsertPos.Next<>nil) do
      InsertPos:=InsertPos.Next;
    InsertPos.Next:=NewInsert;
  end else begin
    // insert alphabetically
    InsertPos:=FirstInsert;
    LastInsertPos:=nil;
    //DebugLn('GGG "',InsertPos.Txt,'" "',CleanDef,'" ',CompareTextIgnoringSpace(InsertPos.Txt,CleanDef,false));
    while (InsertPos<>nil)
    and (CompareTextIgnoringSpace(InsertPos.Txt,CleanDef,false)>=0) do begin
      LastInsertPos:=InsertPos;
      InsertPos:=InsertPos.Next;
    end;
    if LastInsertPos<>nil then begin
      // insert after LastInsertPos
      NewInsert.Next:=LastInsertPos.Next;
      LastInsertPos.Next:=NewInsert;
    end else begin
      // insert as first
      NewInsert.Next:=InsertPos;
      FirstInsert:=NewInsert;
    end;
    {InsertPos:=FirstInsert;
    while InsertPos<>nil do begin
      DebugLn(' HHH ',InsertPos.Txt);
      InsertPos:=InsertPos.Next;
    end;}
  end;
end;

procedure TCodeCompletionCodeTool.FreeClassInsertionList;
// dispose all new variables/procs definitions
var
  ANodeExt: TCodeTreeNodeExtension;
  AVLNode: TAVLTreeNode;
  s: string;
begin
  while FirstInsert<>nil do begin
    ANodeExt:=FirstInsert;
    FirstInsert:=FirstInsert.Next;
    ANodeExt.Free;
  end;
  if fNewMainUsesSectionUnits<>nil then begin
    AVLNode:=fNewMainUsesSectionUnits.FindLowest;
    while AVLNode<>nil do begin
      Pointer(s):=AVLNode.Data;
      s:='';
      AVLNode:=fNewMainUsesSectionUnits.FindSuccessor(AVLNode);
    end;
    if s='' then ;
    FreeAndNil(fNewMainUsesSectionUnits);
  end;
end;

function TCodeCompletionCodeTool.NodeExtIsVariable(
  ANodeExt: TCodeTreeNodeExtension): boolean;
begin
  Result:=TNewClassPart(ANodeExt.Flags) in NewClassPartVars;
end;

function TCodeCompletionCodeTool.NodeExtHasVisibilty(
  ANodeExt: TCodeTreeNodeExtension; Visibility: TPascalClassSection): boolean;
begin
  case Visibility of
  pcsPrivate:
    Result:=(ANodeExt.Flags=ord(ncpPrivateVars))
         or (ANodeExt.Flags=ord(ncpPrivateProcs));
  pcsProtected:
    Result:=(ANodeExt.Flags=ord(ncpProtectedVars))
         or (ANodeExt.Flags=ord(ncpProtectedProcs));
  pcsPublic:
    Result:=(ANodeExt.Flags=ord(ncpPublicVars))
         or (ANodeExt.Flags=ord(ncpPublicProcs));
  pcsPublished:
    Result:=(ANodeExt.Flags=ord(ncpPublishedVars))
         or (ANodeExt.Flags=ord(ncpPublishedProcs));
  else
    Result:=false;
  end;
end;

procedure TCodeCompletionCodeTool.FindInsertPositionForForwardProc(
  SourceChangeCache: TSourceChangeCache; ProcNode: TCodeTreeNode; var Indent,
  InsertPos: integer);

  procedure SetIndentAndInsertPos(Node: TCodeTreeNode; Behind: boolean);
  begin
    Indent:=GetLineIndent(Src,Node.StartPos);
    if Behind then
      InsertPos:=FindLineEndOrCodeAfterPosition(Node.EndPos)
    else
      InsertPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
  end;

var
  NearestProcNode, StartSearchProc: TCodeTreeNode;
  IsInInterface: boolean;
  ProcBodyNodes, ForwardProcNodes: TAVLTree; // tree of TCodeTreeNodeExtension
  ProcAVLNode, NearestAVLNode: TAVLTreeNode;
  ProcNodeExt, NearestNodeExt: TCodeTreeNodeExtension;
  InsertBehind: boolean;
  NearestAVLNodeInFront: TAVLTreeNode;
  NearestAVLNodeBehind: TAVLTreeNode;
  ProcPosInFront: Integer;
  ProcPosBehind: Integer;
  EmptyLinesInFront: Integer;
  EmptyLinesBehind: Integer;
begin
  IsInInterface:=ProcNode.HasParentOfType(ctnInterface);
  if IsInInterface then begin
    // forward proc in interface
    StartSearchProc:=FindImplementationNode;
    if StartSearchProc=nil then
      RaiseException('Implementation section not found');
    if StartSearchProc.FirstChild<>nil then begin
      // implementation not empty
      StartSearchProc:=StartSearchProc.FirstChild
    end else begin
      // implementation is empty
      // -> add it as first body
      Indent:=GetLineIndent(Src,StartSearchProc.StartPos);
      InsertPos:=StartSearchProc.StartPos+length('implementation');
      exit;
    end;
  end else begin
    // forward proc in code
    // start searching for bodies behind proc
    StartSearchProc:=ProcNode.NextBrother;
    if StartSearchProc=nil then begin
      // There are no nodes behind
      // -> insert code directly behind
      SetIndentAndInsertPos(ProcNode,true);
      exit;
    end;
  end;

  //debugln(['TCodeCompletionCodeTool.FindInsertPositionForForwardProc ',ord(SourceChangeCache.BeautifyCodeOptions.ForwardProcBodyInsertPolicy)]);
  if SourceChangeCache.BeautifyCodeOptions.KeepForwardProcOrder then begin
    // KeepForwardProcOrder: gather all procs and try to insert the new body
    //  in the same order of other forward proc definitions.
    ForwardProcNodes:=nil;
    ProcAVLNode:=nil;
    ProcBodyNodes:=nil;
    ProcNodeExt:=nil;
    
    try
      // gather all forward procs definitions on the same level
      ForwardProcNodes:=GatherProcNodes(ProcNode.Parent.FirstChild,
                 [phpInUpperCase,phpIgnoreProcsWithBody,phpIgnoreMethods],'');

      // gather all proc bodies
      ProcBodyNodes:=GatherProcNodes(StartSearchProc,
                     [phpInUpperCase,phpIgnoreForwards,phpIgnoreMethods],'');
                     
      // remove current forward proc from tree
      ProcAVLNode:=FindAVLNodeWithNode(ForwardProcNodes,ProcNode);
      if ProcAVLNode=nil then
        RaiseException('TCodeCompletionCodeTool.FindInsertPositionForForwardProc '
         +' Internal Error, current forward proc not found');
      ProcNodeExt:=TCodeTreeNodeExtension(ProcAVLNode.Data);
      ForwardProcNodes.Delete(ProcAVLNode);

      // remove all forward procs without bodies
      IntersectProcNodes(ForwardProcNodes,ProcBodyNodes,true);
      
      // sort forward proc definitions with source position
      ForwardProcNodes.OnCompare:=@CompareCodeTreeNodeExtWithNodeStartPos;
      
      // For debugging:
      {ProcAVLNode:=ForwardProcNodes.FindLowest;
      while ProcAVLNode<>nil do begin
        NearestProcNode:=TCodeTreeNodeExtension(ProcAVLNode.Data).Node;
        DebugLn(['FindInsertPositionForForwardProc B ',NearestProcNode.StartPos,' "',copy(Src,NearestProcNode.StartPos,20),'"']);
        ProcAVLNode:=ForwardProcNodes.FindSuccessor(ProcAVLNode);
      end;}

      // find nearest forward procs (distance measured in chars)
      NearestAVLNode:=ForwardProcNodes.FindNearest(ProcNodeExt);
      if NearestAVLNode<>nil then begin
      
        //DebugLn('FindInsertPositionForForwardProc Nearest ',TCodeTreeNodeExtension(NearestAVLNode.Data).Node.StartPos,' ',ProcNode.StartPos);

        // find nearest forward procs in front and after
        if TCodeTreeNodeExtension(NearestAVLNode.Data).Node.StartPos
          <ProcNode.StartPos
        then begin
          NearestAVLNodeInFront:=NearestAVLNode;
          NearestAVLNodeBehind:=ForwardProcNodes.FindPrecessor(NearestAVLNode);
        end else begin
          NearestAVLNodeInFront:=ForwardProcNodes.FindSuccessor(NearestAVLNode);
          NearestAVLNodeBehind:=NearestAVLNode;
        end;
        
        // choose the nearest of both (distance measured in emtpy lines,
        // this way blocks of procs are kept)
        if (NearestAVLNodeInFront<>nil) and (NearestAVLNodeBehind<>nil) then
        begin
          ProcPosInFront:=
               TCodeTreeNodeExtension(NearestAVLNodeInFront.Data).Node.StartPos;
          ProcPosBehind:=
               TCodeTreeNodeExtension(NearestAVLNodeBehind.Data).Node.StartPos;
          EmptyLinesInFront:=EmptyCodeLineCount(Src,
                       ProcPosInFront,ProcNode.StartPos,Scanner.NestedComments);
          EmptyLinesBehind:=EmptyCodeLineCount(Src,
                        ProcNode.StartPos,ProcPosBehind,Scanner.NestedComments);
          //DebugLn('FindInsertPositionForForwardProc Nearest InFront or After: EmptyLinesInFront=',EmptyLinesInFront,' EmptyLinesBehind=',EmptyLinesBehind);
          if EmptyLinesInFront<EmptyLinesBehind then
            NearestAVLNode:=NearestAVLNodeInFront
          else
            NearestAVLNode:=NearestAVLNodeBehind;
        end;
        
        NearestNodeExt:=TCodeTreeNodeExtension(NearestAVLNode.Data);
        NearestProcNode:=NearestNodeExt.Node;
        
        //DebugLn('FindInsertPositionForForwardProc C ',NearestProcNode.StartPos,' "',copy(Src,NearestProcNode.StartPos,20),'"');
        InsertBehind:=NearestProcNode.StartPos<ProcNode.StartPos;

        // the corresponding body was linked by IntersectProcNodes in Data
        NearestAVLNode:=TAVLTreeNode(NearestNodeExt.Data);
        NearestNodeExt:=TCodeTreeNodeExtension(NearestAVLNode.Data);
        NearestProcNode:=NearestNodeExt.Node;
        SetIndentAndInsertPos(NearestProcNode,InsertBehind);
        exit;
      end else begin
        // there is no other proc => use ForwardProcBodyInsertPolicy
      end;
      
    finally
      // clean up
      ProcNodeExt.Free;
      DisposeAVLTree(ProcBodyNodes);
      DisposeAVLTree(ForwardProcNodes);
    end;
  end;

  if SourceChangeCache.BeautifyCodeOptions.ForwardProcBodyInsertPolicy
    = fpipInFrontOfMethods
  then begin
    // Try to insert new proc in front of existing methods

    // find first method
    NearestProcNode:=StartSearchProc;
    while (NearestProcNode<>nil) and (not NodeIsMethodBody(NearestProcNode)) do
      NearestProcNode:=NearestProcNode.NextBrother;
    if NearestProcNode<>nil then begin
      // the comments in front of the first method probably belong to the class
      // Therefore insert behind the node in front of the first method
      if NearestProcNode.PriorBrother<>nil then
        SetIndentAndInsertPos(NearestProcNode.PriorBrother,true)
      else begin
        Indent:=GetLineIndent(Src,NearestProcNode.StartPos);
        InsertPos:=NearestProcNode.Parent.StartPos;
        while (InsertPos<=NearestProcNode.StartPos)
        and (not IsSpaceChar[Src[InsertPos]]) do
          inc(InsertPos);
      end;
      exit;
    end;
  end else if SourceChangeCache.BeautifyCodeOptions.ForwardProcBodyInsertPolicy
    = fpipBehindMethods
  then begin
    // Try to insert new proc behind existing methods

    // find last method (go to last brother and search backwards)
    NearestProcNode:=StartSearchProc;
    while (NearestProcNode.NextBrother<>nil) do
      NearestProcNode:=NearestProcNode.NextBrother;
    while (NearestProcNode<>nil) and (not NodeIsMethodBody(NearestProcNode)) do
      NearestProcNode:=NearestProcNode.PriorBrother;
    if NearestProcNode<>nil then begin
      SetIndentAndInsertPos(NearestProcNode,true);
      exit;
    end;
  end;
  
  // Default position: Insert behind last node
  NearestProcNode:=StartSearchProc;
  while (NearestProcNode.NextBrother<>nil) do
    NearestProcNode:=NearestProcNode.NextBrother;
  if NearestProcNode<>nil then begin
    SetIndentAndInsertPos(NearestProcNode,true);
    exit;
  end;

  RaiseException('TCodeCompletionCodeTool.FindInsertPositionForForwardProc '
   +' Internal Error: no insert position found');
end;

procedure TCodeCompletionCodeTool.FindInsertPositionForProcInterface(
  var Indent, InsertPos: integer; SourceChangeCache: TSourceChangeCache);
var
  InsertNode: TCodeTreeNode;
begin
  InsertNode:=FindInterfaceNode;
  if InsertNode<>nil then begin
    // there is an interface
    // -> append at end of interface
    InsertPos:=FindLineEndOrCodeInFrontOfPosition(InsertNode.EndPos,true);
    Indent:=GetLineIndent(Src,InsertNode.EndPos);
  end;
  if InsertPos<1 then begin
    // there is no interface
    // -> insert in front of any proc
    InsertNode:=FindFirstSectionChild;
    while (InsertNode<>nil) and (InsertNode.Desc<>ctnProcedure) do
      InsertNode:=InsertNode.NextBrother;
    if InsertNode<>nil then begin
      InsertPos:=FindLineEndOrCodeInFrontOfPosition(InsertNode.StartPos,true);
      Indent:=GetLineIndent(Src,InsertPos);
    end;
  end;
  if InsertPos<1 then begin
    InsertNode:=FindFirstSectionChild;
    if InsertNode<>nil then begin
      Indent:=GetLineIndent(Src,InsertNode.StartPos);
      if InsertNode.Desc=ctnUsesSection then
        // insert behind uses section
        InsertPos:=FindLineEndOrCodeAfterPosition(InsertNode.EndPos)
      else
        // insert as first
        InsertPos:=FindLineEndOrCodeInFrontOfPosition(InsertNode.StartPos);
    end else begin
      // insert in interface or somewhere at start
      InsertNode:=Tree.Root;
      InsertPos:=FindLineEndOrCodeInFrontOfPosition(InsertNode.EndPos,true);
      Indent:=GetLineIndent(Src,InsertNode.EndPos);
    end;
  end;
end;

function TCodeCompletionCodeTool.CheckLocalVarAssignmentSyntax(
  CleanCursorPos: integer; out VarNameAtom, AssignmentOperator,
  TermAtom: TAtomPosition): boolean;
// check for VarName:=Term
begin
  Result:=false;
  MoveCursorToCleanPos(CleanCursorPos);
  
  // find variable name
  GetIdentStartEndAtPosition(Src,CleanCursorPos,
    VarNameAtom.StartPos,VarNameAtom.EndPos);
  //debugln('TCodeCompletionCodeTool.CheckLocalVarAssignmentSyntax VarNameAtom="',dbgstr(Src,VarNameAtom.StartPos,VarNameAtom.EndPos-VarNameAtom.StartPos),'"');
  if VarNameAtom.StartPos=VarNameAtom.EndPos then exit;
  MoveCursorToAtomPos(VarNameAtom);
  if AtomIsKeyWord then exit;
  
  // find assignment operator
  ReadNextAtom;
  if not (AtomIs(':=') or AtomIs('+=') or AtomIs('-=') or AtomIs('*=')
    or AtomIs('/=')) then exit;
  AssignmentOperator:=CurPos;
  //debugln('TCodeCompletionCodeTool.CheckLocalVarAssignmentSyntax AssignmentOperator="',dbgstr(Src,AssignmentOperator.StartPos,AssignmentOperator.EndPos-AssignmentOperator.StartPos),'"');

  // find term
  ReadNextAtom;
  TermAtom.StartPos:=CurPos.StartPos;
  TermAtom.EndPos:=FindEndOfExpression(TermAtom.StartPos);
  //debugln('TCodeCompletionCodeTool.CheckLocalVarAssignmentSyntax TermAtom="',dbgstr(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos),'"');

  Result:=TermAtom.EndPos>TermAtom.StartPos;
end;

function TCodeCompletionCodeTool.CheckLocalVarForInSyntax(
  CleanCursorPos: integer; out VarNameAtom, TermAtom: TAtomPosition): boolean;
// check for: for VarName in Term do
{off $DEFINE VerboseForInCompletion}
var
  InAtomEndPos: LongInt;
begin
  Result:=false;
  MoveCursorToCleanPos(CleanCursorPos);

  // find variable name
  GetIdentStartEndAtPosition(Src,CleanCursorPos,
    VarNameAtom.StartPos,VarNameAtom.EndPos);
  //debugln('TCodeCompletionCodeTool.CheckLocalVarForInSyntax A ',GetAtom(VarNameAtom),' "',copy(Src,CleanCursorPos,10),'"');
  if VarNameAtom.StartPos=VarNameAtom.EndPos then begin
    {$IFDEF VerboseForInCompletion}
    debugln('TCodeCompletionCodeTool.CheckLocalVarForInSyntax no identifier at cursor ',GetAtom(VarNameAtom),' "',copy(Src,CleanCursorPos,10),'"');
    {$ENDIF}
    exit;
  end;
  MoveCursorToAtomPos(VarNameAtom);
  if AtomIsKeyWord then exit;

  // find 'in' operator
  ReadNextAtom;
  if not UpAtomIs('IN') then begin
    {$IFDEF VerboseForInCompletion}
    debugln('TCodeCompletionCodeTool.CheckLocalVarForInSyntax no in keyword ',GetAtom(VarNameAtom));
    {$ENDIF}
    exit;
  end;
  InAtomEndPos:=CurPos.EndPos;

  // find 'for' keyword
  MoveCursorToCleanPos(VarNameAtom.StartPos);
  ReadPriorAtom;
  if not UpAtomIs('FOR') then begin
    {$IFDEF VerboseForInCompletion}
    debugln('TCodeCompletionCodeTool.CheckLocalVarForInSyntax no for keyword ',GetAtom);
    {$ENDIF}
    exit;
  end;

  // find term
  MoveCursorToCleanPos(InAtomEndPos);
  ReadNextAtom;
  TermAtom.StartPos:=CurPos.StartPos;
  TermAtom.EndPos:=FindEndOfExpression(TermAtom.StartPos);

  {$IFDEF VerboseForInCompletion}
  debugln('TCodeCompletionCodeTool.CheckLocalVarForInSyntax term="',GetAtom(TermAtom),'"');
  {$ENDIF}
  Result:=TermAtom.EndPos>TermAtom.StartPos;
end;

function TCodeCompletionCodeTool.AddLocalVariable(CleanCursorPos: integer;
  OldTopLine: integer; VariableName, VariableType,
  VariableTypeUnitName: string; out NewPos: TCodeXYPosition;
  out NewTopLine: integer; SourceChangeCache: TSourceChangeCache;
  CleanLevelPos: integer): boolean;
// if CleanLevelPos<1 then CleanLevelPos:=CleanCursorPos
// CleanLevelPos selects the target node, e.g. a ctnProcedure
var
  CursorNode, VarSectionNode, VarNode: TCodeTreeNode;
  Indent, InsertPos: integer;
  InsertTxt: string;
  OldCodePos: TCodePosition;
  Node: TCodeTreeNode;
  ParentNode: TCodeTreeNode;
  OtherSectionNode: TCodeTreeNode;
  HeaderNode: TCodeTreeNode;
begin
  Result:=false;
  if CleanLevelPos<1 then CleanLevelPos:=CleanCursorPos;
  //DebugLn('TCodeCompletionCodeTool.AddLocalVariable START CleanCursorPos=',CleanPosToStr(CleanCursorPos),' CleanLevelPos=',CleanPosToStr(CleanLevelPos));
  if not CleanPosToCodePos(CleanCursorPos,OldCodePos) then begin
    RaiseException('TCodeCompletionCodeTool.AddLocalVariable Internal Error: '
      +'CleanPosToCodePos');
  end;

  // find the level and find sections in front
  Node:=Tree.Root;
  VarSectionNode:=nil;
  OtherSectionNode:=nil;
  HeaderNode:=nil;
  ParentNode:=nil;
  while Node<>nil do begin
    if Node.StartPos>CleanCursorPos then break;
    CursorNode:=Node;
    if Node.Desc in [ctnProcedureHead,ctnUsesSection] then
      HeaderNode:=Node
    else if Node.Desc=ctnVarSection then
      VarSectionNode:=Node
    else if Node.Desc in AllDefinitionSections then
      OtherSectionNode:=Node;
    if (Node.StartPos<=CleanLevelPos)
    and ((Node.EndPos>CleanLevelPos)
      or ((Node.EndPos=CleanLevelPos)
         and ((Node.NextBrother=nil) or (Node.NextBrother.StartPos>CleanLevelPos))))
    then begin
      if Node.Desc in [ctnInterface,ctnImplementation,ctnProgram,ctnLibrary,
        ctnPackage,ctnProcedure]
      then begin
        // this node can have a var section
        VarSectionNode:=nil;
        OtherSectionNode:=nil;
        HeaderNode:=nil;
        ParentNode:=Node;
      end else if Node.Desc=ctnUnit then begin
        // the grand children can have a var section
      end else begin
        break;
      end;
      Node:=Node.FirstChild;
    end else
      Node:=Node.NextBrother;
  end;

  if ParentNode=nil then begin
    // no target for a var
    RaiseException('TCodeCompletionCodeTool.AddLocalVariable Internal Error: '
      +'invalid target for a var');
  end;

  InsertTxt:=VariableName+':'+VariableType+';';
  //DebugLn(['TCodeCompletionCodeTool.AddLocalVariable C InsertTxt="',InsertTxt,'" ParentNode=',ParentNode.DescAsString,' HeaderNode=',HeaderNode.DescAsString,' OtherSectionNode=',OtherSectionNode.DescAsString,' VarSectionNode=',VarSectionNode.DescAsString,' CursorNode=',CursorNode.DescAsString]);

  if (VarSectionNode<>nil) then begin
    // there is already a var section
    // -> append variable
    //debugln(['TCodeCompletionCodeTool.AddLocalVariable insert into existing var section']);
    VarNode:=VarSectionNode.LastChild;
    if VarNode<>nil then begin
      Indent:=GetLineIndent(Src,VarNode.StartPos);
      if PositionsInSameLine(Src,VarSectionNode.StartPos,VarNode.StartPos) then
        inc(Indent,SourceChangeCache.BeautifyCodeOptions.Indent);
      InsertPos:=FindLineEndOrCodeAfterPosition(VarNode.EndPos);
    end else begin
      Indent:=GetLineIndent(Src,VarSectionNode.StartPos);
      MoveCursorToNodeStart(VarSectionNode);
      ReadNextAtom;
      InsertPos:=CurPos.EndPos;
    end;
  end else begin
    // there is no var section yet
    // -> create a new var section and append variable
    if OtherSectionNode<>nil then begin
      // there is a type/const section in front
      // => put the var section below
      //debugln(['TCodeCompletionCodeTool.AddLocalVariable start a new var section below '+OtherSectionNode.DescAsString]);
      InsertPos:=OtherSectionNode.EndPos;
      Indent:=GetLineIndent(Src,OtherSectionNode.StartPos);
    end else begin
      // there is no var/type/const section in front
      if (ParentNode.Desc=ctnProcedure) and (HeaderNode=nil) then
        HeaderNode:=ParentNode.FirstChild;
      if (HeaderNode=nil)
      and (ParentNode.FirstChild<>nil)
      and (ParentNode.FirstChild.Desc=ctnUsesSection) then
        HeaderNode:=ParentNode.FirstChild;

      if CursorNode.Desc in [ctnBeginBlock,ctnAsmBlock] then begin
        // add the var section directly in front of the begin
        //debugln(['TCodeCompletionCodeTool.AddLocalVariable start a new var section in front of begin block']);
        InsertPos:=CursorNode.StartPos;
        Indent:=GetLineIndent(Src,InsertPos);
      end else if HeaderNode<>nil then begin
        // put the var section below the header
        //debugln(['TCodeCompletionCodeTool.AddLocalVariable start a new var section below '+HeaderNode.DescAsString]);
        InsertPos:=HeaderNode.EndPos;
        Indent:=GetLineIndent(Src,InsertPos);
      end else begin
        // insert behind section keyword
        //debugln(['TCodeCompletionCodeTool.AddLocalVariable start a new var section at start of '+ParentNode.DescAsString]);
        MoveCursorToNodeStart(ParentNode);
        ReadNextAtom;
        InsertPos:=CurPos.EndPos;
        Indent:=GetLineIndent(Src,InsertPos);
      end;
    end;
    InsertTxt:='var'+SourceChangeCache.BeautifyCodeOptions.LineEnd
               +GetIndentStr(Indent+SourceChangeCache.BeautifyCodeOptions.Indent)
               +InsertTxt;
  end;
  
  // insert new code
  InsertTxt:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
                InsertTxt,Indent);
  //DebugLn('TCodeCompletionCodeTool.AddLocalVariable E ',InsertTxt,' ');
  SourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,InsertTxt);

  if (VariableTypeUnitName<>'')
  and (not IsHiddenUsedUnit(PChar(VariableTypeUnitName))) then begin
    if not AddUnitToMainUsesSection(VariableTypeUnitName,'',SourceChangeCache)
    then begin
      debugln(['TCodeCompletionCodeTool.AddLocalVariable AddUnitToMainUsesSection failed']);
      exit;
    end;
  end;
  if not SourceChangeCache.Apply then begin
    debugln(['TCodeCompletionCodeTool.AddLocalVariable SourceChangeCache.Apply failed']);
    exit;
  end;

  // adjust cursor position
  AdjustCursor(OldCodePos,OldTopLine,NewPos,NewTopLine);

  Result:=true;
end;

procedure TCodeCompletionCodeTool.AdjustCursor(OldCodePos: TCodePosition;
  OldTopLine: integer; out NewPos: TCodeXYPosition; out NewTopLine: integer);
begin
  OldCodePos.Code.AdjustPosition(OldCodePos.P);
  NewPos.Code:=OldCodePos.Code;
  OldCodePos.Code.AbsoluteToLineCol(OldCodePos.P,NewPos.Y,NewPos.X);
  NewTopLine:=NewPos.Y-VisibleEditorLines+1;
  if NewTopLine<1 then NewTopLine:=1;
  if NewTopLine<OldTopLine then
    NewTopLine:=OldTopLine;
  //DebugLn('TCodeCompletionCodeTool.AdjustCursor END NewPos: Line=',NewPos.Y,' Col=',NewPos.X,' NewTopLine=',NewTopLine);
end;

procedure TCodeCompletionCodeTool.AddNeededUnitToMainUsesSection(
  AnUnitName: PChar);
var
  s: String;
begin
  if GetIdentLen(AnUnitName)=0 then exit;
  if CompareIdentifiers(AnUnitName,'System')=0 then exit;
  if (CompareIdentifiers(AnUnitName,'ObjPas')=0)
  and (Scanner.CompilerMode in [cmDELPHI,cmOBJFPC])
  and (Scanner.PascalCompiler=pcFPC) then
    exit;
  if (CompareIdentifiers(AnUnitName,'MacPas')=0)
  and (Scanner.CompilerMode=cmMacPas)
  and (Scanner.PascalCompiler=pcFPC) then
    exit;

  if fNewMainUsesSectionUnits=nil then
    fNewMainUsesSectionUnits:=TAVLTree.Create(TListSortCompare(@CompareIdentifiers));
  //DebugLn(['TCodeCompletionCodeTool.AddNeededUnitToMainUsesSection AnUnitName="',AnUnitName,'"']);
  if fNewMainUsesSectionUnits.Find(AnUnitName)<>nil then exit;
  s:=GetIdentifier(AnUnitName);
  fNewMainUsesSectionUnits.Add(Pointer(s));
  Pointer(s):=nil;
end;

procedure TCodeCompletionCodeTool.AddMethodCompatibleToProcType(
  AClassNode: TCodeTreeNode; const AnEventName: string;
  ProcContext: TFindContext; out MethodDefinition: string; out
  MethodAttr: TProcHeadAttributes; SourceChangeCache: TSourceChangeCache);
var
  CleanMethodDefinition: string;
begin
  MethodDefinition:='';
  MethodAttr:=[];

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteEventAssignment: Extract method param list...');
  {$ENDIF}
  // extract method param list and result type
  CleanMethodDefinition:=UpperCaseStr(AnEventName)
                +ProcContext.Tool.ExtractProcHead(ProcContext.Node,
                     [phpWithoutClassName, phpWithoutName, phpInUpperCase]);

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteEventAssignment: Initializing CodeCompletion...');
  {$ENDIF}
  // initialize class for code completion
  CodeCompleteClassNode:=AClassNode;
  CodeCompleteSrcChgCache:=SourceChangeCache;

  // insert new published method to class
  MethodAttr:=[phpWithStart, phpWithoutClassKeyword, phpWithVarModifiers,
               phpWithParameterNames,phpWithDefaultValues,phpWithResultType];
  MethodDefinition:=TrimCodeSpace(ProcContext.Tool.ExtractProcHead(
                       ProcContext.Node,
                       MethodAttr+[phpWithoutClassName,phpWithoutName]));
  MethodDefinition:=SourceChangeCache.BeautifyCodeOptions.
                 AddClassAndNameToProc(MethodDefinition, '', AnEventName);
  {$IFDEF CTDEBUG}
  DebugLn('  CompleteEventAssignment: Add Method To Class...');
  {$ENDIF}
  if not ProcExistsInCodeCompleteClass(CleanMethodDefinition) then begin
    // insert method definition into class
    AddClassInsertion(CleanMethodDefinition, MethodDefinition,
                      AnEventName, ncpPublishedProcs);
  end;
  MethodDefinition:=SourceChangeCache.BeautifyCodeOptions.
                 AddClassAndNameToProc(MethodDefinition,
                   ExtractClassName(AClassNode,false,true), AnEventName);
  if not InsertAllNewClassParts then
    RaiseException(ctsErrorDuringInsertingNewClassParts);

  // insert all missing proc bodies
  if not CreateMissingProcBodies then
    RaiseException(ctsErrorDuringCreationOfNewProcBodies);
end;

procedure TCodeCompletionCodeTool.AddProcedureCompatibleToProcType(
  const NewProcName: string; ProcContext: TFindContext; out
  MethodDefinition: string; out MethodAttr: TProcHeadAttributes;
  SourceChangeCache: TSourceChangeCache; CursorNode: TCodeTreeNode);
var
  StartNode: TCodeTreeNode;
  Node: TCodeTreeNode;
  InFrontOfNode: TCodeTreeNode;
  Indent: Integer;
  InsertPos: Integer;
  NewProc: String;
begin
  // find a nice insert position in front of methods and CursorNode
  StartNode:=FindImplementationNode;
  if (StartNode=nil) and (Tree.Root.Desc<>ctnUnit) then
    StartNode:=Tree.Root;
  InFrontOfNode:=nil;
  if StartNode<>nil then begin
    Node:=StartNode.FirstChild;
    while Node<>nil do begin
      if (CursorNode<>nil) and (Node.StartPos>CursorNode.StartPos) then break;
      if Node.Desc<>ctnUsesSection then
        InFrontOfNode:=Node;
      if NodeIsMethodBody(Node)
      or (Node.Desc in [ctnBeginBlock,ctnAsmBlock]) then
        break;
      Node:=Node.NextBrother;
    end;
  end;
  if InFrontOfNode<>nil then begin
    // insert in front
    Indent:=GetLineIndent(Src,InFrontOfNode.StartPos);
    InsertPos:=FindLineEndOrCodeInFrontOfPosition(InFrontOfNode.StartPos);
  end else begin
    Node:=FindMainUsesSection(false);
    if Node<>nil then begin
      // insert behind uses section
      Indent:=GetLineIndent(Src,Node.StartPos);
      InsertPos:=FindLineEndOrCodeAfterPosition(Node.EndPos);
    end else begin
      // insert at start
      if StartNode=nil then begin
        // unit without implementation
        RaiseException('need implementation section to insert new procedure');
      end;
      Node:=StartNode.Next;
      if Node<>nil then begin
        // insert in front of second node
        InsertPos:=Node.StartPos;
        Indent:=GetLineIndent(Src,InsertPos);
      end else if StartNode.Desc=ctnImplementation then begin
        // empty implementation => insert at start
        Indent:=GetLineIndent(Src,StartNode.StartPos);
        InsertPos:=StartNode.StartPos+length('implementation');
      end else begin
        // empty program
        RaiseException('no insert place found for the new procedure');
      end;
    end;
  end;

  // extract method param list, result type and modifiers
  MethodAttr:=[phpWithStart, phpWithoutClassKeyword, phpWithVarModifiers,
               phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
               phpWithCallingSpecs];
  MethodDefinition:=TrimCodeSpace(
                ProcContext.Tool.ExtractProcHead(ProcContext.Node,
                              MethodAttr+[phpWithoutClassName,phpWithoutName]));
  MethodDefinition:=SourceChangeCache.BeautifyCodeOptions.
                 AddClassAndNameToProc(MethodDefinition, '', NewProcName);
  debugln(['TCodeCompletionCodeTool.AddProcedureCompatibleToProcType MethodDefinition="',MethodDefinition,'"']);

  // create code and insert
  NewProc:=SourceChangeCache.BeautifyCodeOptions.BeautifyProc(MethodDefinition,Indent,true);
  debugln(['TCodeCompletionCodeTool.AddProcedureCompatibleToProcType NewProc="',NewProc,'"']);
  if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,NewProc)
  then
    RaiseException('unable to insert code at '+CleanPosToStr(InsertPos,true));
end;

procedure TCodeCompletionCodeTool.AddNeededUnitsToMainUsesSectionForRange(
  StartPos, EndPos: integer; CompletionTool: TCodeCompletionCodeTool);
var
  Params: TFindDeclarationParams;
  OldCursor: TAtomPosition;
  ContextNode: TCodeTreeNode;
  NewUnitName: String;
begin
  Params:=nil;
  ContextNode:=nil;
  try
    MoveCursorToCleanPos(StartPos);
    repeat
      ReadNextAtom;
      if (CurPos.StartPos>EndPos) or (CurPos.Flag=cafNone) then exit;
      if AtomIsIdentifier then begin
        //DebugLn(['AddNeededUnitsForRange ',GetAtom]);
        // save cursor
        OldCursor:=CurPos;
        // search identifier
        if Params=nil then
          Params:=TFindDeclarationParams.Create;
        if ContextNode=nil then
          ContextNode:=FindDeepestNodeAtPos(CurPos.StartPos,true);
        ContextNode := ContextNode.GetNodeOfType(ctnProcedureType);
        Params.ContextNode:=ContextNode;
        Params.SetIdentifier(Self,@Src[CurPos.StartPos],@CheckSrcIdentifier);
        Params.Flags:=fdfDefaultForExpressions+[fdfExceptionOnPredefinedIdent];
        try
          //DebugLn(['TCodeCompletionCodeTool.AddNeededUnitsToMainUsesSectionForRange Identifier=',GetAtom]);
          FindIdentifierInContext(Params);
          // identifier found
          NewUnitName:=Params.NewCodeTool.GetSourceName(false);
          //DebugLn(['TCodeCompletionCodeTool.AddNeededUnitsToMainUsesSectionForRange NewUnitName=',NewUnitName]);
          if NewUnitName<>'' then
            CompletionTool.AddNeededUnitToMainUsesSection(PChar(NewUnitName));
        except
          on E: ECodeToolError do;
        end;
        // restore cursor
        MoveCursorToAtomPos(OldCursor);
      end;
    until false;
  finally
    Params.Free;
  end;
end;

procedure TCodeCompletionCodeTool.CalcMemSize(Stats: TCTMemStats);
begin
  inherited CalcMemSize(Stats);
  Stats.Add('TCodeCompletionCodeTool',
     MemSizeString(FSetPropertyVariablename)
    +MemSizeString(FJumpToProcName)
    +length(NewClassSectionIndent)*SizeOf(integer)
    +length(NewClassSectionInsertPos)*SizeOf(integer)
    +MemSizeString(fFullTopLvlName));
 if fNewMainUsesSectionUnits<>nil then
   Stats.Add('TCodeCompletionCodeTool.fNewMainUsesSectionUnits',
     SizeOf(TAVLTreeNode)*fNewMainUsesSectionUnits.Count);
end;

function TCodeCompletionCodeTool.CompleteClass(AClassNode: TCodeTreeNode;
  CleanCursorPos, OldTopLine: integer; CursorNode: TCodeTreeNode;
  var NewPos: TCodeXYPosition; var NewTopLine: integer): boolean;
var
  SectionNode: TCodeTreeNode;
  ANode: TCodeTreeNode;
begin
  Result:=true;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode In-a-class ',NodeDescriptionAsString(AClassNode.Desc));
  {$ENDIF}
  // cursor is in class/object definition
  if (AClassNode.SubDesc and ctnsForwardDeclaration)>0 then exit;
  CheckWholeUnitParsed(AClassNode,CursorNode);
  // parse class and build CodeTreeNodes for all properties/methods
  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode C ',dbgs(CleanCursorPos),', |',copy(Src,CleanCursorPos,8));
  {$ENDIF}
  CodeCompleteClassNode:=AClassNode;
  try
    // go through all properties and procs
    //  insert read + write prop specifiers
    //  demand Variables + Procs + Proc Bodies
    {$IFDEF CTDEBUG}
    DebugLn('TCodeCompletionCodeTool.CompleteCode Complete Properties ... ');
    {$ENDIF}
    if CodeCompleteClassNode.Desc in AllClassObjects then
      SectionNode:=CodeCompleteClassNode.FirstChild
    else
      SectionNode:=CodeCompleteClassNode;
    while SectionNode<>nil do begin
      ANode:=SectionNode.FirstChild;
      while ANode<>nil do begin
        if ANode.Desc=ctnProperty then begin
          // check if property is complete
          if not CompleteProperty(ANode) then
            RaiseException(ctsUnableToCompleteProperty);
        end;
        ANode:=ANode.NextBrother;
      end;
      if SectionNode=CodeCompleteClassNode then break;
      SectionNode:=SectionNode.NextBrother;
    end;

    {$IFDEF CTDEBUG}
    DebugLn('TCodeCompletionCodeTool.CompleteCode Apply ... ');
    {$ENDIF}
    // apply the changes and jump to first new proc body
    Result:=ApplyChangesAndJumpToFirstNewProc(CleanCursorPos,OldTopLine,true,
                                              NewPos,NewTopLine);
  finally
    FreeClassInsertionList;
  end;
end;

function TCodeCompletionCodeTool.CompleteForwardProcs(
  CursorPos: TCodeXYPosition;
  ProcNode, CursorNode: TCodeTreeNode;
  var NewPos: TCodeXYPosition; var NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
// add proc bodies for forward procs
var
  RevertableJump: boolean;
  ProcBodyNodes: TAVLTree;
  StartProcNode: TCodeTreeNode;
  CurProcNode: TCodeTreeNode;
  EndProcNode: TCodeTreeNode;
  ProcCode: String;
  Indent: integer;
  InsertPos: integer;
begin
  Result:=true;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode in a forward procedure ... ');
  {$ENDIF}
  CheckWholeUnitParsed(CursorNode,ProcNode);
  // gather all proc bodies
  ProcBodyNodes:=GatherProcNodes(FindNextNodeOnSameLvl(ProcNode),
                      [phpInUpperCase,phpIgnoreForwards,phpIgnoreMethods],'');
  try
    // find first forward proc without body
    StartProcNode:=ProcNode;
    CurProcNode:=StartProcNode;
    repeat
      ProcCode:=ExtractProcHead(CurProcNode,[phpInUpperCase]);
      if (FindNodeInTree(ProcBodyNodes,ProcCode)<>nil)
      or (ProcNodeHasSpecifier(CurProcNode,psEXTERNAL)) then begin
        // node is already completed
        if CurProcNode=ProcNode then begin
          // cursor node is already completed -> stop completion
          exit;
        end;
        break;
      end;
      StartProcNode:=CurProcNode;
      CurProcNode:=CurProcNode.PriorBrother;
    until (CurProcNode=nil) or (CurProcNode.Desc<>ctnProcedure)
    or ((CurProcNode.SubDesc and ctnsForwardDeclaration)=0);

    // find last forward proc without body
    EndProcNode:=ProcNode;
    CurProcNode:=EndProcNode;
    repeat
      ProcCode:=ExtractProcHead(CurProcNode,[phpInUpperCase]);
      if (FindNodeInTree(ProcBodyNodes,ProcCode)<>nil)
      or (ProcNodeHasSpecifier(CurProcNode,psEXTERNAL)) then begin
        // node is already completed
        if CurProcNode=ProcNode then begin
          // cursor node is already completed -> stop completion
          exit;
        end;
        break;
      end;
      EndProcNode:=CurProcNode;
      CurProcNode:=CurProcNode.NextBrother;
    until (CurProcNode=nil) or (CurProcNode.Desc<>ctnProcedure)
    or ((CurProcNode.SubDesc and ctnsForwardDeclaration)=0);

    // find a nice insert position
    FindInsertPositionForForwardProc(SourceChangeCache,StartProcNode,
                                     Indent,InsertPos);

    // build nice procs
    CurProcNode:=StartProcNode;
    repeat
      ProcCode:=ExtractProcHead(CurProcNode,[phpWithStart,
                  phpWithoutClassKeyword,
                  phpWithVarModifiers,phpWithParameterNames,phpWithResultType,
                  phpWithCallingSpecs,phpDoNotAddSemicolon]);
      if ProcCode='' then
        RaiseException('CompleteForwardProcs: unable to parse forward proc node');
      if ProcCode[length(ProcCode)]<>';' then begin
        // add missing semicolon
        ProcCode:=ProcCode+';';
        UndoReadNextAtom;
        if not SourceChangeCache.Replace(gtNone,gtNone,
          CurPos.EndPos,CurPos.EndPos,';') then
            RaiseException('CompleteForwardProcs: unable to insert semicolon');
      end;
      ProcCode:=SourceChangeCache.BeautifyCodeOptions.BeautifyProc(ProcCode,
                                                                 Indent,true);
      if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,
        InsertPos,InsertPos,ProcCode) then
          RaiseException('CompleteForwardProcs: unable to insert new proc body');
      // next
      if CurProcNode=EndProcNode then break;
      CurProcNode:=FindNextNodeOnSameLvl(CurProcNode);
    until false;
    if not SourceChangeCache.Apply then
      RaiseException('CompleteForwardProcs: unable to apply changes');

    // reparse code and find jump point into new proc
    Result:=FindJumpPoint(CursorPos,NewPos,NewTopLine,RevertableJump);
  finally
    DisposeAVLTree(ProcBodyNodes);
  end;
end;

function TCodeCompletionCodeTool.CompleteLocalVariableAssignment(
  CleanCursorPos, OldTopLine: integer;
  CursorNode: TCodeTreeNode;
  var NewPos: TCodeXYPosition; var NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  VarNameAtom, AssignmentOperator, TermAtom: TAtomPosition;
  NewType: string;
  Params: TFindDeclarationParams;
  ExprType: TExpressionType;
  MissingUnit: String;
begin
  Result:=false;

  {$IFDEF VerboseCompleteLocalVarAssign}
  DebugLn('  CompleteLocalVariableAssignment: A');
  {$ENDIF}
  if not ((CursorNode.Desc=ctnBeginBlock)
          or CursorNode.HasParentOfType(ctnBeginBlock)) then exit;
  if CursorNode.Desc=ctnBeginBlock then
    BuildSubTreeForBeginBlock(CursorNode);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

  {$IFDEF VerboseCompleteLocalVarAssign}
  DebugLn('  CompleteLocalVariableAssignment: B CheckLocalVarAssignmentSyntax ...');
  {$ENDIF}
  // check assignment syntax
  if not CheckLocalVarAssignmentSyntax(CleanCursorPos,
    VarNameAtom,AssignmentOperator,TermAtom)
  then begin
    {$IFDEF VerboseCompleteLocalVarAssign}
    debugln(['TCodeCompletionCodeTool.CompleteLocalVariableAssignment CheckLocalVarAssignmentSyntax=false']);
    {$ENDIF}
    exit;
  end;
  {$IFDEF VerboseCompleteLocalVarAssign}
  debugln(['TCodeCompletionCodeTool.CompleteLocalVariableAssignment VarNameAtom=',dbgstr(Src,VarNameAtom.StartPos,VarNameAtom.EndPos-VarNameAtom.StartPos),' AssignmentOperator=',dbgstr(Src,AssignmentOperator.StartPos,AssignmentOperator.EndPos-AssignmentOperator.StartPos),' TermAtom=',dbgstr(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos)]);
  {$ENDIF}

  // search variable
  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    {$IFDEF VerboseCompleteLocalVarAssign}
    DebugLn('  CompleteLocalVariableAssignment: check if variable is already defined ...');
    {$ENDIF}
    // check if identifier exists
    Result:=IdentifierIsDefined(VarNameAtom,CursorNode,Params);
    //debugln(['TCodeCompletionCodeTool.CompleteLocalVariableAssignment Identifier=',dbgstr(Src,VarNameAtom.StartPos,VarNameAtom.EndPos-VarNameAtom.StartPos),' exists=',Result]);
    if Result then begin
      MoveCursorToCleanPos(VarNameAtom.StartPos);
      ReadNextAtom;
      RaiseExceptionFmt(ctsIdentifierAlreadyDefined,[GetAtom]);
    end;

    {$IFDEF VerboseCompleteLocalVarAssign}
    DebugLn('  CompleteLocalVariableAssignment: Find type of term ...',
    ' Term="',copy(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos),'"');
    {$ENDIF}
    // find type of term
    Params.ContextNode:=CursorNode;
    NewType:=FindTermTypeAsString(TermAtom,Params,ExprType);
    if NewType='' then
      RaiseException('CompleteLocalVariableAssignment Internal error: NewType=""');

  finally
    Params.Free;
    DeactivateGlobalWriteLock;
  end;

  MissingUnit:='';
  if (ExprType.Desc=xtContext)
  and (ExprType.Context.Tool<>nil) then
    MissingUnit:=GetUnitNameForUsesSection(ExprType.Context.Tool);
  Result:=AddLocalVariable(CleanCursorPos,OldTopLine,GetAtom(VarNameAtom),
                      NewType,MissingUnit,NewPos,NewTopLine,SourceChangeCache);
end;

function TCodeCompletionCodeTool.CompleteEventAssignment(CleanCursorPos,
  OldTopLine: integer; CursorNode: TCodeTreeNode;
  out IsEventAssignment: boolean;
  var NewPos: TCodeXYPosition; var NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  SearchedClassName: string;
{ examples:
    Button1.OnClick:=|
    OnClick:=@AnEve|nt
    with Button1 do OnMouseDown:=@|

  If OnClick is a method then it will be completed to
    Button1.OnClick:=@Button1Click;
  and a 'procedure Button1Click(Sender: TObject);' with a method body will
  be added to the published section of the class of the Begin..End Block.
}

  function CheckEventAssignmentSyntax(out PropVarAtom: TAtomPosition;
    out AssignmentOperator, AddrOperatorPos: integer;
    out UserEventAtom: TAtomPosition;
    out SemicolonPos: integer): boolean;
  begin
    Result:=false;

    // check if in begin..end block
    if not ((CursorNode.Desc=ctnBeginBlock)
            or CursorNode.HasParentOfType(ctnBeginBlock)) then exit;
    // read event name (optional)

    while (CleanCursorPos<SrcLen)
    and (Src[CleanCursorPos] in [':','=',' ',#9]) do
      inc(CleanCursorPos);
    GetIdentStartEndAtPosition(Src,CleanCursorPos,
                               UserEventAtom.StartPos,UserEventAtom.EndPos);
    MoveCursorToAtomPos(UserEventAtom);
    if AtomIsKeyWord then exit;
    ReadPriorAtom;
    // check @ operator (optional)
    if AtomIsChar('@') then begin
      AddrOperatorPos:=CurPos.StartPos;
      ReadPriorAtom;
    end else
      AddrOperatorPos:=-1;
    // check assignment operator :=
    if not AtomIs(':=') then exit;
    ReadPriorAtom;
    AssignmentOperator:=CurPos.EndPos;
    // check event name
    if not AtomIsIdentifier then exit;
    PropVarAtom:=CurPos;

    // check for semicolon at end of statement
    MoveCursorToCleanPos(UserEventAtom.EndPos);
    ReadNextAtom;
    if AtomIsChar(';') then
      SemicolonPos:=CurPos.StartPos
    else
      SemicolonPos:=-1;

    {$IFDEF CTDEBUG}
    DebugLn('  CheckEventAssignmentSyntax: "',copy(Src,PropertyAtom.StartPos,
          UserEventAtom.EndPos-PropertyAtom.StartPos),'"');
    {$ENDIF}

    Result:=true;
  end;

  function FindEventTypeAtCursor(PropVarAtom: TAtomPosition;
    out PropVarContext, ProcContext: TFindContext;
    Params: TFindDeclarationParams): boolean;
  begin
    Result:=false;
    // find declaration of property identifier
    Params.ContextNode:=CursorNode;
    MoveCursorToCleanPos(PropVarAtom.StartPos);
    Params.SetIdentifier(Self,@Src[CurPos.StartPos],nil);
    fFullTopLvlName:='';
    Params.OnTopLvlIdentifierFound:=@OnTopLvlIdentifierFound;
    Params.Flags:=[fdfSearchInParentNodes,fdfSearchInAncestors,
                   fdfTopLvlResolving,fdfFindVariable];
    if (not FindDeclarationOfIdentAtParam(Params)) then begin
      {$IFDEF CTDEBUG}
      DebugLn('FindEventTypeAtCursor identifier "',GetIdentifier(@Src[CurPos.StartPos]),'" not found');
      {$ENDIF}
      exit;
    end;
    if not (Params.NewNode.Desc in [ctnProperty,ctnVarDefinition]) then begin
      {$IFDEF CTDEBUG}
      DebugLn('FindEventTypeAtCursor not a property/variable');
      {$ENDIF}
      exit;
    end;
    PropVarContext:=CreateFindContext(Params);
    // identifier is property
    // -> check type of property
    Params.Flags:=[fdfSearchInParentNodes,fdfSearchInAncestors];
    ProcContext:=PropVarContext.Tool.FindBaseTypeOfNode(
                                                    Params,PropVarContext.Node);
    if (ProcContext.Node=nil) or (ProcContext.Node.Desc<>ctnProcedureType)
    then begin
      {$IFDEF CTDEBUG}
      DebugLn('FindEventTypeAtCursor not a procedure type');
      {$ENDIF}
      exit;
    end;
    // identifier is property/var of type proc => this is an event
    Result:=true;
  end;

  function CreateEventFullName(AClassNode: TCodeTreeNode; UserEventAtom,
    PropVarAtom: TAtomPosition): string;
  var PropVarName, AClassName: string;
    l: integer;
  begin
    if UserEventAtom.StartPos=UserEventAtom.EndPos then begin
      Result:=fFullTopLvlName;
      l:=PropVarAtom.EndPos-PropVarAtom.StartPos;
      PropVarName:=copy(Src,PropVarAtom.StartPos,l);
      if SysUtils.CompareText(PropVarName,RightStr(Result,l))<>0 then
        Result:=Result+PropVarName;
      if SysUtils.CompareText(PropVarName,Result)=0 then begin
        // this is an event of the class (not event of published objects)
        // -> add form name
        MoveCursorToNodeStart(AClassNode.Parent);
        ReadNextAtom;
        AClassName:=GetAtom;
        if (length(AClassName)>1) and (AClassName[1] in ['t','T']) then
          System.Delete(AClassName,1,1);
        Result:=AClassName+Result;
      end;
      // convert OnClick to Click
      if (UpperCaseStr(LeftStr(PropVarName,2))='ON')
      and (SysUtils.CompareText(RightStr(Result,l),PropVarName)=0)
      then
        Result:=LeftStr(Result,length(Result)-l)+RightStr(Result,l-2);
    end else begin
      Result:=copy(Src,UserEventAtom.StartPos,
                          UserEventAtom.EndPos-UserEventAtom.StartPos);
    end;
    {$IFDEF CTDEBUG}
    DebugLn('CreateEventFullName "',Result,'"');
    {$ENDIF}
  end;

  function FindProcAndClassNode(out ProcNode, AClassNode: TCodeTreeNode
    ): boolean;
  var
    ANode: TCodeTreeNode;
  begin
    Result:=false;
    AClassNode:=nil;
    ProcNode:=CursorNode;
    while (ProcNode<>nil) do begin
      if (ProcNode.Desc=ctnProcedure) then begin
        SearchedClassname:=ExtractClassNameOfProcNode(ProcNode,true);
        if SearchedClassName<>'' then break;
      end;
      ProcNode:=ProcNode.Parent;
    end;
    if (ProcNode=nil) then exit;
    ANode:=FindClassNodeForMethodBody(ProcNode,true,false);
    if (ANode=nil) then exit;
    // search class node
    while ANode<>nil do begin
      if ANode.Desc in AllClassObjects then break;
      ANode:=ANode.Parent;
    end;
    if ANode=nil then exit;
    AClassNode:=ANode;
    Result:=true;
  end;

  function CompleteAssignment(const AnEventName: string;
    AssignmentOperator, AddrOperatorPos, SemicolonPos: integer;
    UserEventAtom: TAtomPosition): boolean;
  var RValue: string;
    StartInsertPos, EndInsertPos: integer;
  begin
    {$IFDEF CTDEBUG}
    DebugLn('  CompleteEventAssignment: Changing right side of assignment...');
    {$ENDIF}
    // add new event name as right value of assignment
    // add address operator @ if needed or user provided it himself
    RValue:=AnEventName+';';
    if (AddrOperatorPos>0)
    or ((Scanner.PascalCompiler=pcFPC) and (Scanner.CompilerMode<>cmDelphi))
    then
      RValue:='@'+RValue;
    RValue:=':='+RValue;
    RValue:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(RValue,0);
    StartInsertPos:=AssignmentOperator;
    EndInsertPos:=SemicolonPos+1;
    if EndInsertPos<1 then
      EndInsertPos:=UserEventAtom.EndPos;
    if EndInsertPos<1 then
      EndInsertPos:=AddrOperatorPos;
    if EndInsertPos<1 then
      EndInsertPos:=AssignmentOperator+2;
    Result:=SourceChangeCache.Replace(gtNone,gtNewLine,
                                      StartInsertPos,EndInsertPos,RValue);
  end;

  procedure AddProcedure(Identifier: string;
    TypeTool: TFindDeclarationTool; TypeNode: TCodeTreeNode);
  var
    ProcContext: TFindContext;
    AMethodDefinition: string;
    AMethodAttr: TProcHeadAttributes;
  begin
    // create new method
    ProcContext:=CreateFindContext(TypeTool,TypeNode);
    AddProcedureCompatibleToProcType(Identifier,
      ProcContext,AMethodDefinition,AMethodAttr,SourceChangeCache,
      CursorNode);

    // apply the changes
    if not SourceChangeCache.Apply then
      RaiseException(ctsUnableToApplyChanges);

    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalIdentifierByParameter.AddProcedure: jumping to new method body...');
    {$ENDIF}
    // jump to new method body
    if not JumpToMethod(AMethodDefinition,AMethodAttr,NewPos,NewTopLine,false)
    then
      RaiseException('CompleteLocalIdentifierByParameter.AddProcedure JumpToMethod failed');
  end;

// function CompleteEventAssignment: boolean
var
  UserEventAtom, PropVarAtom: TAtomPosition;
  AssignmentOperator, AddrOperatorPos, SemicolonPos: integer;
  Params: TFindDeclarationParams;
  PropertyContext, ProcContext: TFindContext;
  FullEventName, AMethodDefinition: string;
  AMethodAttr: TProcHeadAttributes;
  ProcNode, AClassNode: TCodeTreeNode;
  Identifier: String;
begin
  IsEventAssignment:=false;
  Result:=false;

  {$IFDEF VerboseCompleteEventAssign}
  DebugLn('  CompleteEventAssignment: CheckEventAssignmentSyntax...');
  {$ENDIF}
  // check assigment syntax
  if not CheckEventAssignmentSyntax(PropVarAtom, AssignmentOperator,
                                   AddrOperatorPos, UserEventAtom, SemicolonPos)
  then
    exit;
  IsEventAssignment:=true;

  ProcNode:=nil;
  AClassNode:=nil;
  CheckWholeUnitParsed(CursorNode,ProcNode);

  if CursorNode.Desc=ctnBeginBlock then
    BuildSubTreeForBeginBlock(CursorNode);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

  {$IFDEF VerboseCompleteEventAssign}
  DebugLn('  CompleteEventAssignment: check if a method and find class...');
  {$ENDIF}
  FindProcAndClassNode(ProcNode,AClassNode);

  Params:=TFindDeclarationParams.Create;
  try
    {$IFDEF VerboseCompleteEventAssign}
    DebugLn('  CompleteEventAssignment: FindEventTypeAtCursor...');
    {$ENDIF}
    // check if identifier is event property and build
    Result:=FindEventTypeAtCursor(PropVarAtom,PropertyContext,ProcContext,
                                  Params);
    if not Result then exit;

    if ProcContext.Tool.ProcNodeHasOfObject(ProcContext.Node) then begin
      if AClassNode<>nil then begin
        {$IFDEF VerboseCompleteEventAssign}
        DebugLn('  CompleteEventAssignment: CreateEventFullName... UserEventAtom.StartPos=',dbgs(UserEventAtom.StartPos));
        {$ENDIF}
        // create a nice event name
        FullEventName:=CreateEventFullName(AClassNode,UserEventAtom,PropVarAtom);
        if FullEventName='' then exit;

        // add published method and method body and right side of assignment
        AddMethodCompatibleToProcType(AClassNode,FullEventName,ProcContext,
          AMethodDefinition,AMethodAttr,SourceChangeCache);
        if not CompleteAssignment(FullEventName,AssignmentOperator,
          AddrOperatorPos,SemicolonPos,UserEventAtom)
        then
          RaiseException('CompleteEventAssignment CompleteAssignment failed');
      end else if ProcContext.Tool.ProcNodeHasOfObject(ProcContext.Node) then begin
        {$IFDEF VerboseCompleteEventAssign}
        debugln(['  CompleteEventAssignment:  proc is "of object"']);
        {$ENDIF}
        MoveCursorToCleanPos(PropVarAtom.StartPos);
        RaiseException('Complete event failed: procedure of object needs a class');
      end;
    end else begin
      // create procedure (not method)
      {$IFDEF VerboseCompleteEventAssign}
      debugln(['  CompleteEventAssignment: create a proc name']);
      {$ENDIF}
      // get name
      Identifier:='';
      if (UserEventAtom.StartPos>1) and (UserEventAtom.StartPos<=SrcLen) then
        Identifier:=GetIdentifier(@Src[UserEventAtom.StartPos]);
      if Identifier='' then
        Identifier:=GetIdentifier(@Src[PropVarAtom.StartPos]);
      if Identifier='' then begin
        MoveCursorToCleanPos(PropVarAtom.StartPos);
        RaiseException('Complete event failed: need a name');
      end;
      // create proc
      {$IFDEF VerboseCompleteEventAssign}
      debugln(['  CompleteEventAssignment: create a proc name']);
      {$ENDIF}
      AddProcedureCompatibleToProcType(Identifier,
        ProcContext,AMethodDefinition,AMethodAttr,SourceChangeCache,
        CursorNode);
    end;
  finally
    Params.Free;
  end;

  {$IFDEF VerboseCompleteEventAssign}
  DebugLn('  CompleteEventAssignment: Applying changes...');
  {$ENDIF}
  // apply the changes
  if not SourceChangeCache.Apply then
    RaiseException(ctsUnableToApplyChanges);

  {$IFDEF VerboseCompleteEventAssign}
  DebugLn('  CompleteEventAssignment: jumping to new method body...');
  {$ENDIF}
  // jump to new method body
  if not JumpToMethod(AMethodDefinition,AMethodAttr,NewPos,NewTopLine,false)
  then
    RaiseException('CompleteEventAssignment Internal Error 2');

  Result:=true;
end;

function TCodeCompletionCodeTool.CompleteLocalVariableForIn(CleanCursorPos,
  OldTopLine: integer; CursorNode: TCodeTreeNode; var NewPos: TCodeXYPosition;
  var NewTopLine: integer; SourceChangeCache: TSourceChangeCache): boolean;
var
  VarNameAtom: TAtomPosition;
  TermAtom: TAtomPosition;
  Params: TFindDeclarationParams;
  NewType: String;
  ExprType: TExpressionType;
  MissingUnit: String;
begin
  Result:=false;

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteLocalVariableForIn: A');
  {$ENDIF}
  if not ((CursorNode.Desc=ctnBeginBlock)
          or CursorNode.HasParentOfType(ctnBeginBlock)) then exit;
  if CursorNode.Desc=ctnBeginBlock then
    BuildSubTreeForBeginBlock(CursorNode);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteLocalVariableForIn: B CheckLocalVarForInSyntax ...');
  {$ENDIF}
  // check assignment syntax
  if not CheckLocalVarForInSyntax(CleanCursorPos,
    VarNameAtom,TermAtom)
  then
    exit;
  DebugLn(['TCodeCompletionCodeTool.CompleteLocalVariableForIn Var=',GetAtom(VarNameAtom),' Term=',GetAtom(TermAtom)]);

  // search variable
  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalVariableForIn: check if variable is already defined ...');
    {$ENDIF}
    // check if identifier exists
    Result:=IdentifierIsDefined(VarNameAtom,CursorNode,Params);
    if Result then begin
      MoveCursorToCleanPos(VarNameAtom.StartPos);
      ReadNextAtom;
      RaiseExceptionFmt(ctsIdentifierAlreadyDefined,[GetAtom]);
    end;

    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalVariableForIn: Find type of term ...',
    ' Term="',copy(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos),'"');
    {$ENDIF}
    // find type of term
    NewType:=FindForInTypeAsString(TermAtom,CursorNode,Params,ExprType);
    if NewType='' then
      RaiseException('CompleteLocalVariableForIn Internal error: NewType=""');

  finally
    Params.Free;
    DeactivateGlobalWriteLock;
  end;

  MissingUnit:='';
  if (ExprType.Desc=xtContext)
  and (ExprType.Context.Tool<>nil) then
    MissingUnit:=GetUnitNameForUsesSection(ExprType.Context.Tool);

  Result:=AddLocalVariable(CleanCursorPos,OldTopLine,GetAtom(VarNameAtom),
                      NewType,MissingUnit,NewPos,NewTopLine,SourceChangeCache);
end;

function TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter(
  CleanCursorPos, OldTopLine: integer; CursorNode: TCodeTreeNode;
  var NewPos: TCodeXYPosition; var NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;

  procedure AddMethod(Identifier: string;
    TypeTool: TFindDeclarationTool; TypeNode: TCodeTreeNode);
  var
    AMethodAttr: TProcHeadAttributes;
    AMethodDefinition: string;
    ProcContext: TFindContext;
    AClassNode: TCodeTreeNode;
  begin
    // parameter needs a method => search class of method
    AClassNode:=FindClassOrInterfaceNode(CursorNode,true);
    if (AClassNode=nil) then
      RaiseException('parameter needs a method');
    ProcContext:=CreateFindContext(TypeTool,TypeNode);

    // create new method
    AddMethodCompatibleToProcType(AClassNode,Identifier,
      ProcContext,AMethodDefinition,AMethodAttr,SourceChangeCache);

    // apply the changes
    if not SourceChangeCache.Apply then
      RaiseException(ctsUnableToApplyChanges);

    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalIdentifierByParameter.AddMethod: jumping to new method body...');
    {$ENDIF}
    // jump to new method body
    if not JumpToMethod(AMethodDefinition,AMethodAttr,NewPos,NewTopLine,false)
    then
      RaiseException('CompleteLocalIdentifierByParameter.AddMethod JumpToMethod failed');
  end;

  procedure AddProcedure(Identifier: string;
    TypeTool: TFindDeclarationTool; TypeNode: TCodeTreeNode);
  var
    ProcContext: TFindContext;
    AMethodDefinition: string;
    AMethodAttr: TProcHeadAttributes;
  begin
    // create new method
    ProcContext:=CreateFindContext(TypeTool,TypeNode);
    AddProcedureCompatibleToProcType(Identifier,
      ProcContext,AMethodDefinition,AMethodAttr,SourceChangeCache,
      CursorNode);

    // apply the changes
    if not SourceChangeCache.Apply then
      RaiseException(ctsUnableToApplyChanges);

    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalIdentifierByParameter.AddProcedure: jumping to new method body...');
    {$ENDIF}
    // jump to new method body
    if not JumpToMethod(AMethodDefinition,AMethodAttr,NewPos,NewTopLine,false)
    then
      RaiseException('CompleteLocalIdentifierByParameter.AddProcedure JumpToMethod failed');
  end;

var
  VarNameRange, ProcNameAtom: TAtomPosition;
  ParameterIndex: integer;
  Params: TFindDeclarationParams;
  ParameterNode: TCodeTreeNode;
  TypeNode: TCodeTreeNode;
  NewType: String;
  IgnorePos: TCodePosition;
  MissingUnitName: String;
  ProcStartPos: LongInt;
  ExprType: TExpressionType;
  Context: TFindContext;
  HasAtOperator: Boolean;
  TypeTool: TFindDeclarationTool;
  AliasType: TFindContext;
  Identifier: String;
begin
  Result:=false;

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteLocalIdentifierByParameter: A');
  {$ENDIF}
  if not ((CursorNode.Desc=ctnBeginBlock)
          or CursorNode.HasParentOfType(ctnBeginBlock)) then exit;
  if CursorNode.Desc=ctnBeginBlock then
    BuildSubTreeForBeginBlock(CursorNode);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteLocalIdentifierByParameter: B check if it is a parameter ...');
  {$ENDIF}
  // check parameter syntax
  if not CheckParameterSyntax(CursorNode.StartPos,CleanCursorPos,
                              VarNameRange,ProcNameAtom,ParameterIndex)
  then
    exit;
  HasAtOperator:=false;
  if (VarNameRange.StartPos<=SrcLen)
  and (Src[VarNameRange.StartPos]='@') then begin
    HasAtOperator:=true;
    MoveCursorToCleanPos(VarNameRange.StartPos+1);
    ReadNextAtom;
    VarNameRange.StartPos:=CurPos.StartPos;
    //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter HasAtOperator ',GetAtom(VarNameRange)]);
  end;
  Identifier:=ExtractCode(VarNameRange.StartPos,VarNameRange.EndPos,[]);
  if not IsValidIdent(Identifier) then exit;

  {$IFDEF CTDEBUG}
  DebugLn('  CompleteLocalIdentifierByParameter VarNameAtom=',GetAtom(VarNameAtom),' ProcNameAtom=',GetAtom(ProcNameAtom),' ParameterIndex=',dbgs(ParameterIndex));
  {$ENDIF}

  // search variable
  Params:=TFindDeclarationParams.Create;
  try
    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalIdentifierByParameter: check if variable is already defined ...');
    {$ENDIF}
    // check if identifier exists
    Result:=IdentifierIsDefined(VarNameRange,CursorNode,Params);
    if Result then begin
      MoveCursorToCleanPos(VarNameRange.StartPos);
      ReadNextAtom;
      RaiseExceptionFmt(ctsIdentifierAlreadyDefined,[GetAtom]);
    end;

    {$IFDEF CTDEBUG}
    DebugLn('  CompleteLocalIdentifierByParameter: Find declaration of parameter list ...  procname="',GetAtom(ProcNameAtom),'"');
    {$ENDIF}

    Context:=CreateFindContext(Self,CursorNode);
    ProcStartPos:=FindStartOfTerm(ProcNameAtom.EndPos,false);
    if ProcStartPos<ProcNameAtom.StartPos then begin
      // for example: Canvas.Line
      // find class
      {$IFDEF CTDEBUG}
      debugln(['TCodeCompletionCodeTool.CompleteLocalVariableByParameter Call="',ExtractCode(ProcStartPos,ProcNameAtom.EndPos,[]),'"']);
      {$ENDIF}
      Params.ContextNode:=Context.Node;
      Params.Flags:=fdfDefaultForExpressions+[fdfFunctionResult,fdfFindChildren];
      ExprType:=FindExpressionResultType(Params,ProcStartPos,ProcNameAtom.StartPos);
      if ExprType.Desc<>xtContext then begin
        debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter Call="',ExtractCode(ProcStartPos,ProcNameAtom.StartPos,[]),'" gives ',ExprTypeToString(ExprType)]);
        exit;
      end;
      // resolve point '.'
      Context:=ExprType.Context;
      //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter base class: ',FindContextToString(Context)]);
      Params.Clear;
      Params.Flags:=fdfDefaultForExpressions;
      Context:=Context.Tool.FindBaseTypeOfNode(Params,Context.Node);
      {$IFDEF CTDEBUG}
      debugln(['TCodeCompletionCodeTool.CompleteLocalVariableByParameter search proc in sub context: ',FindContextToString(Context)]);
      {$ENDIF}
    end;

    // find declaration of parameter list
    // ToDo: search in all overloads for the best fit
    Params.ContextNode:=Context.Node;
    Params.SetIdentifier(Self,@Src[ProcNameAtom.StartPos],nil);
    Params.Flags:=fdfDefaultForExpressions+[fdfFindVariable];
    if Context.Node=CursorNode then
      Params.Flags:=Params.Flags+[fdfSearchInParentNodes,fdfIgnoreCurContextNode]
    else
      Params.Flags:=Params.Flags-[fdfSearchInParentNodes,fdfIgnoreCurContextNode];
    CleanPosToCodePos(VarNameRange.StartPos,IgnorePos);
    IgnoreErrorAfter:=IgnorePos;
    try
      {$IFDEF CTDEBUG}
      debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter searching ',GetIdentifier(Params.Identifier),' [',dbgs(Params.Flags),'] in ',FindContextToString(Context)]);
      {$ENDIF}
      if not Context.Tool.FindIdentifierInContext(Params) then exit;
    finally
      ClearIgnoreErrorAfter;
    end;
    NewType:='';
    MissingUnitName:='';
    if Params.NewNode=nil then exit;
    //DebugLn('TCodeCompletionCodeTool.CompleteLocalVariableAsParameter Proc/PropNode=',Params.NewNode.DescAsString,' ',copy(Params.NewCodeTool.Src,Params.NewNode.StartPos,50));
    ParameterNode:=Params.NewCodeTool.FindNthParameterNode(Params.NewNode,
                                                           ParameterIndex);
    if (ParameterNode=nil)
    and (Params.NewNode.Desc in [ctnProperty,ctnProcedure]) then begin
      DebugLn(['  CompleteLocalIdentifierByParameter Procedure has less than ',ParameterIndex+1,' parameters']);
      exit;
    end;
    if ParameterNode=nil then exit;
    //DebugLn('TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter ParameterNode=',ParameterNode.DescAsString,' ',copy(Params.NewCodeTool.Src,ParameterNode.StartPos,50));
    TypeTool:=Params.NewCodeTool;
    TypeNode:=FindTypeNodeOfDefinition(ParameterNode);
    if TypeNode=nil then begin
      DebugLn('  CompleteLocalIdentifierByParameter Parameter has no type');
      exit;
    end;
    // default: copy the type
    NewType:=TypeTool.ExtractCode(TypeNode.StartPos,TypeNode.EndPos,[]);

    // search type
    Params.Clear;
    Params.ContextNode:=TypeNode;
    Params.Flags:=[fdfSearchInParentNodes,fdfSearchInAncestors,
                   fdfTopLvlResolving];
    AliasType:=CleanFindContext;
    ExprType:=TypeTool.FindExpressionResultType(Params,
                              TypeNode.StartPos,TypeNode.EndPos,@AliasType);
    //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter parameter type: AliasType=',FindContextToString(AliasType)]);

    if HasAtOperator then begin
      debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter HasAtOperator ExprType=',ExprTypeToString(ExprType)]);
      NewType:='';
      if (ExprType.Desc<>xtContext)
      or (ExprType.Context.Node=nil) then begin
        debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter parameter has @ operator, but this is not implemented for ',ExprTypeToString(ExprType)]);
        exit;
      end;
      TypeNode:=ExprType.Context.Node;
      TypeTool:=ExprType.Context.Tool;
      if (TypeNode.Desc=ctnPointerType) then begin
        // for example PMapID = ^...
        if (TypeNode.FirstChild<>nil)
        and (TypeNode.FirstChild.Desc=ctnIdentifier) then begin
          // for example PMapID = ^TMapID
          NewType:=TypeTool.ExtractCode(TypeNode.FirstChild.StartPos,
                                        TypeNode.FirstChild.EndPos,[]);
          //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter pointer to ',NewType]);
          Params.Clear;
          Params.ContextNode:=TypeNode;
          Params.Flags:=fdfDefaultForExpressions;
          AliasType:=CleanFindContext;
          ExprType:=TypeTool.FindExpressionResultType(Params,
            TypeNode.FirstChild.StartPos,TypeNode.FirstChild.EndPos,
            @AliasType);
          //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter parameter is pointer to type: AliasType=',FindContextToString(AliasType)]);
        end;
      end else if TypeNode.Desc=ctnProcedureType then begin
        // for example TNotifyEvent = procedure(...
        if TypeTool.ProcNodeHasOfObject(TypeNode) then begin
          AddMethod(Identifier,TypeTool,TypeNode);
        end else begin
          // parameter needs a procedure
          AddProcedure(Identifier,TypeTool,TypeNode);
        end;
        exit(true);
      end;
      if NewType='' then begin
        debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter parameter has @ operator, but this is not implemented for ',ExprTypeToString(ExprType)]);
        exit;
      end;
    end;
    if AliasType.Node<>nil then begin
      // an identifier
      MissingUnitName:=GetUnitNameForUsesSection(AliasType.Tool);
      //debugln(['TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter MissingUnitName=',MissingUnitName]);
    end;

    //DebugLn('TCodeCompletionCodeTool.CompleteLocalIdentifierByParameter NewType=',NewType);
    if NewType='' then
      RaiseException('CompleteLocalIdentifierByParameter Internal error: NewType=""');
    //DebugLn('  CompleteLocalIdentifierByParameter Dont know: ',Params.NewNode.DescAsString);

  finally
    Params.Free;
  end;

  Result:=AddLocalVariable(CleanCursorPos,OldTopLine,GetAtom(VarNameRange),
                   NewType,MissingUnitName,NewPos,NewTopLine,SourceChangeCache);
end;

function TCodeCompletionCodeTool.CompleteMethodByBody(
  CleanCursorPos, OldTopLine: integer;
  CursorNode: TCodeTreeNode;
  var NewPos: TCodeXYPosition; var NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
const
  ProcAttrCopyBodyToDef = [phpWithStart,phpWithoutClassName,phpWithVarModifiers,
    phpWithParameterNames,phpWithDefaultValues,phpWithResultType];

  procedure MergeProcModifiers(DefProcNode, BodyProcNode: TCodeTreeNode;
    var ProcCode: String);
  var
    FirstBodyModAtom: TAtomPosition;
    BodyHeadEnd: Integer;
    DefHeadEnd: Integer;
    Modifier: shortstring;
    OldCursor: TAtomPosition;
    AddModifier: boolean;
  begin
    MoveCursorToFirstProcSpecifier(DefProcNode);
    if DefProcNode.FirstChild<>nil then
      DefHeadEnd:=DefProcNode.FirstChild.EndPos
    else
      DefHeadEnd:=DefProcNode.EndPos;
    FirstBodyModAtom:=CleanAtomPosition;
    BodyHeadEnd:=0;
    while CurPos.EndPos<DefHeadEnd do begin
      if CurPos.Flag<>cafSemicolon then begin
        // a modifier of the definition
        Modifier:=copy(GetAtom,1,255);
        //debugln(['MergeProcModifiers body modifier: ',Modifier]);
        if not IsKeyWordCallingConvention.DoItCaseInsensitive(Modifier) then
        begin
          // test if body already has this modifier
          OldCursor:=CurPos;
          if BodyHeadEnd=0 then begin
            MoveCursorToFirstProcSpecifier(BodyProcNode);
            FirstBodyModAtom:=CurPos;
            if BodyProcNode.FirstChild<>nil then
              BodyHeadEnd:=BodyProcNode.FirstChild.EndPos
            else
              BodyHeadEnd:=BodyProcNode.EndPos;
          end else
            MoveCursorToAtomPos(FirstBodyModAtom);
          while CurPos.EndPos<BodyHeadEnd do begin
            if CurPos.Flag<>cafSemicolon then begin
              if AtomIs(Modifier) then break;
              // skip to next modifier of body
              repeat
                ReadNextAtom;
              until (CurPos.Flag=cafSemicolon) or (CurPos.EndPos>=BodyHeadEnd);
            end else
              ReadNextAtom;
          end;
          AddModifier:=CurPos.EndPos>=BodyHeadEnd;
          MoveCursorToAtomPos(OldCursor);
        end else
          AddModifier:=false;
        // skip to next modifier of definition
        repeat
          if AddModifier then begin
            if (IsIdentStartChar[Src[CurPos.StartPos]]
            and IsIdentChar[ProcCode[length(ProcCode)]]) // space needed between words
            or IsSpaceChar[Src[CurPos.StartPos-1]] // copy space from body
            then
              ProcCode:=ProcCode+' ';
            ProcCode:=ProcCode+GetAtom;
          end;
          ReadNextAtom;
        until (CurPos.Flag=cafSemicolon) or (CurPos.EndPos>=DefHeadEnd);
        if AddModifier then
          ProcCode:=ProcCode+';';
      end else
        ReadNextAtom;
    end;
  end;

var
  CurClassName: String;
  BodyProcNode: TCodeTreeNode;
  CleanProcCode: String;
  ProcName: String;
  OldCodePos: TCodePosition;
  ClassProcs: TAVLTree;
  ProcBodyNodes: TAVLTree;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  DefProcNode: TCodeTreeNode;
  NewProcCode: String;
  OldProcCode: String;
  FromPos: Integer;
  EndPos: Integer;
  Indent: Integer;
begin
  Result:=false;

  // check if cursor in a method
  if CursorNode.Desc=ctnProcedure then
    BodyProcNode:=CursorNode
  else
    BodyProcNode:=CursorNode.GetNodeOfType(ctnProcedure);
  if (BodyProcNode=nil) or (BodyProcNode.Desc<>ctnProcedure)
  or (not NodeIsMethodBody(BodyProcNode)) then begin
    {$IFDEF VerboseCompleteMethod}
    DebugLn(['TCodeCompletionCodeTool.CompleteMethodByBody node is not a method body ',BodyProcNode<>nil]);
    {$ENDIF}
    exit;
  end;

  CheckWholeUnitParsed(CursorNode,BodyProcNode);

  // find corresponding class declaration
  CurClassName:=ExtractClassNameOfProcNode(BodyProcNode);
  if CurClassName='' then begin
    DebugLn(['CompleteMethodByBody ExtractClassNameOfProcNode failed']);
    exit;
  end;
  //DebugLn(['CompleteMethod CurClassName=',CurClassName]);
  CodeCompleteClassNode:=FindClassNodeInUnit(CurClassName,true,false,false,true);

  ClassProcs:=nil;
  ProcBodyNodes:=nil;
  try
    // find the corresponding node in the class
    DefProcNode:=nil;

    // gather existing proc definitions in the class
    ClassProcs:=GatherClassProcDefinitions(CodeCompleteClassNode,true);
    CleanProcCode:=ExtractProcHead(BodyProcNode,[phpInUpperCase]);
    NodeExt:=FindCodeTreeNodeExt(ClassProcs,CleanProcCode);
    if NodeExt<>nil then begin
      DefProcNode:=TCodeTreeNodeExtension(NodeExt).Node;
    end else begin
      // the proc was not found by name+params
      // => guess
      ProcBodyNodes:=GatherClassProcBodies(CodeCompleteClassNode);
      GuessMethodDefBodyMapping(ClassProcs,ProcBodyNodes);
      AVLNode:=ProcBodyNodes.FindLowest;
      NodeExt:=nil;
      while AVLNode<>nil do begin
        NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        if NodeExt.Node=BodyProcNode then begin
          if NodeExt.Data<>nil then
            DefProcNode:=TCodeTreeNodeExtension(NodeExt.Data).Node;
          break;
        end;
        AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
      end;
    end;

    if DefProcNode<>nil then begin
      // update existing definition
      {$IFDEF VerboseCompleteMethod}
      DebugLn(['TCodeCompletionCodeTool.CompleteMethodByBody corresponding definition exists for "',CleanProcCode,'"']);
      {$ENDIF}
      OldProcCode:=ExtractProcHead(DefProcNode,ProcAttrCopyBodyToDef+[phpWithProcModifiers]);
      NewProcCode:=ExtractProcHead(BodyProcNode,ProcAttrCopyBodyToDef+[phpWithCallingSpecs]);
      // some modifiers are only allowed in the definition
      // => keep the old definition modifiers
      MergeProcModifiers(DefProcNode,BodyProcNode,NewProcCode);
      if CompareTextIgnoringSpace(NewProcCode,OldProcCode,false)=0 then
        exit(true); // already matching
      // ToDo: definition needs update
      {$IFDEF VerboseCompleteMethod}
      debugln(['TCodeCompletionCodeTool.CompleteMethodByBody OldProcCode="',OldProcCode,'"']);
      debugln(['TCodeCompletionCodeTool.CompleteMethodByBody NewProcCode="',NewProcCode,'"']);
      {$ENDIF}
      // store old cursor position
      if not CleanPosToCodePos(CleanCursorPos,OldCodePos) then begin
        RaiseException('TCodeCompletionCodeTool.CompleteMethodByBody Internal Error: '
          +'CleanPosToCodePos');
      end;

      Indent:=GetLineIndent(Src,DefProcNode.StartPos);
      FromPos:=DefProcNode.StartPos;
      EndPos:=DefProcNode.EndPos;
      SourceChangeCache.MainScanner:=Scanner;
      NewProcCode:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
                                  NewProcCode,Indent,[bcfDoNotIndentFirstLine]);
      {$IFDEF VerboseCompleteMethod}
      debugln('TCodeCompletionCodeTool.CompleteMethodByBody final NewProcCode:');
      debugln(NewProcCode);
      {$ENDIF}
      if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,EndPos,NewProcCode)
      then
        exit;
      Result:=SourceChangeCache.Apply;
    end else begin
      // insert new definition
      ProcName:=ExtractProcName(BodyProcNode,[phpWithoutClassName]);
      {$IFDEF VerboseCompleteMethod}
      DebugLn(['TCodeCompletionCodeTool.CompleteMethodByBody Adding body to definition "',CleanProcCode,'"']);
      {$ENDIF}

      // store old cursor position
      if not CleanPosToCodePos(CleanCursorPos,OldCodePos) then begin
        RaiseException('TCodeCompletionCodeTool.CompleteMethodByBody Internal Error: '
          +'CleanPosToCodePos');
      end;

      CodeCompleteSrcChgCache:=SourceChangeCache;

      // add method declaration
      NewProcCode:=ExtractProcHead(BodyProcNode,ProcAttrCopyBodyToDef+[phpWithCallingSpecs]);
      CleanProcCode:=ExtractProcHead(BodyProcNode,
                       [phpWithoutClassKeyword,phpWithoutClassName,phpInUpperCase]);
      AddClassInsertion(CleanProcCode,NewProcCode,ProcName,ncpPrivateProcs);

      // apply changes
      Result:=ApplyClassCompletion(false);
    end;
    // adjust cursor position
    AdjustCursor(OldCodePos,OldTopLine,NewPos,NewTopLine);
  finally
    DisposeAVLTree(ClassProcs);
    DisposeAVLTree(ProcBodyNodes);
  end;

  {$IFDEF VerboseCompleteMethod}
  DebugLn(['TCodeCompletionCodeTool.CompleteMethodByBody END OldCodePos.P=',OldCodePos.P,' OldTopLine=',OldTopLine,' NewPos=',Dbgs(NewPos),' NewTopLine=',NewTopLine]);
  {$ENDIF}
end;

function TCodeCompletionCodeTool.CreateParamListFromStatement(
  CursorNode: TCodeTreeNode; BracketOpenPos: integer; out CleanList: string
  ): string;
var
  ParamNames: TStringToStringTree;
  
  function CreateParamName(ExprStartPos, ExprEndPos: integer;
    const ParamType: string): string;
  var
    i: Integer;
  begin
    Result:='';
    // use the last identifier of expression as name
    MoveCursorToCleanPos(ExprStartPos);
    repeat
      ReadNextAtom;
      if AtomIsIdentifier then
        Result:=GetAtom
      else
        Result:='';
    until CurPos.EndPos>=ExprEndPos;
    // otherwise use ParamType
    if Result='' then
      Result:=ParamType;
    // otherwise use 'Param'
    if (Result='') or (not IsValidIdent(Result)) then
      Result:='Param';
    // prepend an 'a'
    if Result[1]<>'a' then
      Result:='a'+Result;
    // make unique
    if ParamNames=nil then
      ParamNames:=TStringToStringTree.Create(false);
    if ParamNames.Contains(Result) then begin
      i:=1;
      while ParamNames.Contains(Result+IntToStr(i)) do inc(i);
      Result:=Result+IntToStr(i);
    end;
    ParamNames[Result]:='used';
  end;
  
var
  i: Integer;
  ExprList: TExprTypeList;
  ParamExprType: TExpressionType;
  ParamType: String;
  ExprStartPos: LongInt;
  ExprEndPos: LongInt;
  Params: TFindDeclarationParams;
  ParamName: String;
  // create param list without brackets
begin
  Result:='';
  CleanList:='';
  ExprList:=nil;
  ParamNames:=nil;
  ActivateGlobalWriteLock;
  Params:=TFindDeclarationParams.Create;
  try
    // check parameter list
    Params.ContextNode:=CursorNode;
    ExprList:=CreateParamExprListFromStatement(BracketOpenPos,Params);

    // create parameter list
    MoveCursorToCleanPos(BracketOpenPos);
    ReadNextAtom;
    //DebugLn(['TCodeCompletionCodeTool.CreateParamListFromStatement BracketClose=',BracketClose]);
    for i:=0 to ExprList.Count-1 do begin
      ReadNextAtom;
      ExprStartPos:=CurPos.StartPos;
      // read til comma or bracket close
      repeat
        //DebugLn(['TCodeCompletionCodeTool.CreateParamListFromStatement loop ',GetAtom]);
        if (CurPos.StartPos>SrcLen)
        or (CurPos.Flag in [cafRoundBracketClose,cafEdgedBracketClose,cafComma])
        then
          break;
        if CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen] then begin
          ReadTilBracketClose(true);
        end;
        ReadNextAtom;
      until false;
      ExprEndPos:=CurPos.StartPos;
      //DebugLn(['TCodeCompletionCodeTool.CreateParamListFromStatement Param=',copy(Src,ExprStartPos,ExprEndPos-ExprStartPos)]);
      // get type
      ParamExprType:=ExprList.Items[i];
      ParamType:=FindExprTypeAsString(ParamExprType,ExprStartPos,Params);
      // create a nice parameter name
      ParamName:=CreateParamName(ExprStartPos,ExprEndPos,ParamType);
      //DebugLn(['TCodeCompletionCodeTool.CreateParamListFromStatement ',i,' ',ParamName,':',ParamType]);
      if Result<>'' then begin
        Result:=Result+';';
        CleanList:=CleanList+';';
      end;
      Result:=Result+ParamName+':'+ParamType;
      CleanList:=CleanList+':'+ParamType;
      // next
      MoveCursorToCleanPos(ExprEndPos);
      ReadNextAtom;
    end;
  finally
    ExprList.Free;
    Params.Free;
    ParamNames.Free;
    DeactivateGlobalWriteLock;
  end;
end;

function TCodeCompletionCodeTool.CompleteProcByCall(CleanCursorPos,
  OldTopLine: integer; CursorNode: TCodeTreeNode; var NewPos: TCodeXYPosition;
  var NewTopLine: integer; SourceChangeCache: TSourceChangeCache): boolean;
// check if 'procname(expr list);'
const
  ShortProcFormat = [phpWithoutClassKeyword];

  function CheckProcSyntax(out BeginNode: TCodeTreeNode;
    out ProcNameAtom: TAtomPosition;
    out BracketOpenPos, BracketClosePos: LongInt): boolean;
  begin
    Result:=false;
    // check if in a begin..end block
    if CursorNode=nil then exit;
    BeginNode:=CursorNode.GetNodeOfType(ctnBeginBlock);
    if BeginNode=nil then exit;
    // check if CleanCursorPos is valid
    if (CleanCursorPos>SrcLen) then CleanCursorPos:=SrcLen;
    if (CleanCursorPos<1) then exit;
    // skip bracket
    if (Src[CleanCursorPos]='(') then dec(CleanCursorPos);
    // go to start of identifier
    while (CleanCursorPos>1) and (IsIdentChar[Src[CleanCursorPos-1]]) do
      dec(CleanCursorPos);
    // read procname
    MoveCursorToCleanPos(CleanCursorPos);
    ReadNextAtom;
    if not AtomIsIdentifier then exit;
    ProcNameAtom:=CurPos;
    // read bracket
    ReadNextAtom;
    if CurPos.Flag<>cafRoundBracketOpen then exit;
    BracketOpenPos:=CurPos.StartPos;
    // read bracket close
    if not ReadTilBracketClose(false) then exit;
    BracketClosePos:=CurPos.StartPos;
    Result:=true;
  end;
  
  function CheckFunctionType(const ProcNameAtom: TAtomPosition;
    out IsFunction: Boolean;
    out FuncType: String;
    out ProcExprStartPos: integer): boolean;
  begin
    Result:=false;
    // find start of proc expression (e.g. Button1.Constrains.DoSomething)
    IsFunction:=false;
    FuncType:='';
    ProcExprStartPos:=FindStartOfTerm(ProcNameAtom.EndPos,false);
    if ProcExprStartPos<0 then exit;
    MoveCursorToCleanPos(ProcExprStartPos);
    ReadPriorAtom;
    if (CurPos.Flag in [cafRoundBracketOpen,cafEdgedBracketOpen])
    or (UpAtomIs(':=')) then begin
      FuncType:='integer';
      IsFunction:=true;
    end;
    Result:=true;
  end;
  
  function CheckProcDoesNotExist(Params: TFindDeclarationParams;
    const ProcNameAtom: TAtomPosition): boolean;
  begin
    Result:=false;
    // check if proc already exists
    Params.ContextNode:=CursorNode;
    Params.SetIdentifier(Self,@Src[ProcNameAtom.StartPos],@CheckSrcIdentifier);
    Params.Flags:=[fdfSearchInParentNodes,
                   fdfTopLvlResolving,fdfSearchInAncestors,
                   fdfIgnoreCurContextNode];
    if FindIdentifierInContext(Params) then begin
      // proc already exists
      DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall proc already exists']);
      MoveCursorToCleanPos(ProcNameAtom.StartPos);
      ReadNextAtom;
      RaiseExceptionFmt(ctsIdentifierAlreadyDefined,[GetAtom]);
    end;
    Result:=true;
  end;

  function CreateProcCode(CursorNode: TCodeTreeNode;
    const ProcNameAtom: TAtomPosition;
    IsFunction: boolean; const FuncType: string;
    BracketOpenPos, Indent: integer;
    out CleanProcHead, ProcCode: string): boolean;
  var
    le: String;
    ProcName: String;
  begin
    Result:=false;

    // create param list
    ProcCode:=CreateParamListFromStatement(CursorNode,BracketOpenPos,CleanProcHead);
    if ProcCode<>'' then begin
      ProcCode:='('+ProcCode+')';
      CleanProcHead:='('+CleanProcHead+')';
    end;

    // prepend proc name
    ProcName:=GetAtom(ProcNameAtom);
    ProcCode:=ProcName+ProcCode;
    CleanProcHead:=ProcName+CleanProcHead;

    // prepend 'procedure' keyword
    if IsFunction then
      ProcCode:='function '+ProcCode+':'+FuncType+';'
    else
      ProcCode:='procedure '+ProcCode+';';
    CleanProcHead:=CleanProcHead+';';

    // append begin..end
    le:=SourceChangeCache.BeautifyCodeOptions.LineEnd;
    ProcCode:=ProcCode+le
      +'begin'+le
      +le
      +'end;';

    ProcCode:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(ProcCode,Indent);

    DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall ',ProcCode]);
    Result:=true;
  end;

  function CreatePathForNewProc(InsertPos: integer;
    const CleanProcHead: string;
    var NewProcPath: TStrings): boolean;
  var
    ContextNode: TCodeTreeNode;
  begin
    Result:=false;
    // find context at insert position
    ContextNode:=FindDeepestNodeAtPos(InsertPos,true);
    if (ContextNode.Desc=ctnProcedure) and (ContextNode.StartPos=InsertPos)
    or ((ContextNode.LastChild<>nil) and (ContextNode.LastChild.StartPos<InsertPos))
    then
      // ContextNode is a procedure below or above the insert position
      // => after the insert the new proc will not be a child
      // -> it will become a child of its parent
      ContextNode:=ContextNode.Parent;
    NewProcPath:=CreateSubProcPath(ContextNode,ShortProcFormat);
    // add new proc
    NewProcPath.Add(CleanProcHead);
    
    DebugLn(['CreatePathForNewProc NewProcPath=',NewProcPath.Text]);
    Result:=true;
  end;

  function FindJumpPointToNewProc(SubProcPath: TStrings): boolean;
  var
    NewProcNode: TCodeTreeNode;
  begin
    Result:=false;
    // reparse code and find jump point into new proc
    BuildTree(lsrEnd);
    NewProcNode:=FindSubProcPath(SubProcPath,ShortProcFormat,true);
    {$IFDEF CTDebug}
    DebugLn('TCodeCompletionCodeTool.CompleteProcByCall A found=',dbgs(NewProcNode<>nil));
    {$ENDIF}
    if NewProcNode=nil then exit;
    Result:=FindJumpPointInProcNode(NewProcNode,NewPos,NewTopLine);
    {$IFDEF CTDebug}
    DebugLn('TCodeCompletionCodeTool.CompleteProcByCall END ',NewProcNode.DescAsString,' ',dbgs(Result),' ',dbgs(NewPos.X),',',dbgs(NewPos.Y),' ',dbgs(NewTopLine));
    {$ENDIF}
  end;

var
  BeginNode: TCodeTreeNode;
  ProcNameAtom: TAtomPosition;
  BracketOpenPos, BracketClosePos: integer;
  ExprType: TExpressionType;
  Params: TFindDeclarationParams;
  InsertPos: LongInt;
  Indent: LongInt;
  ExprList: TExprTypeList;
  ProcNode: TCodeTreeNode;
  ProcCode: String;
  ProcExprStartPos: LongInt;
  IsFunction: Boolean;
  FuncType: String;
  CleanProcHead: string;
  NewProcPath: TStringList;
begin
  Result:=false;
  if not CheckProcSyntax(BeginNode,ProcNameAtom,BracketOpenPos,BracketClosePos)
  then exit;

  CheckWholeUnitParsed(CursorNode,BeginNode);

  Params:=TFindDeclarationParams.Create;
  ExprList:=nil;
  ActivateGlobalWriteLock;
  try
    if not CheckFunctionType(ProcNameAtom,IsFunction,FuncType,ProcExprStartPos)
    then exit;
    DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall ',copy(Src,ProcNameAtom.StartPos,BracketClosePos+1-ProcNameAtom.StartPos)]);
    if not CheckProcDoesNotExist(Params,ProcNameAtom) then exit;

    // find context (e.g. Button1.|)
    Params.Clear;
    Params.ContextNode:=CursorNode;
    ExprType:=FindExpressionTypeOfTerm(-1,ProcNameAtom.StartPos,Params,false);
    DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall ',ExprTypeToString(ExprType)]);
    
    if ExprType.Desc=xtNone then begin
      // default context
      if NodeIsInAMethod(CursorNode) then begin
        // eventually: create a new method
        DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall eventually: create a new method']);
        exit;
      end else begin
        ProcNode:=CursorNode.GetNodeOfType(ctnProcedure);
        if ProcNode<>nil then begin
          // this is a normal proc or sub proc
          // insert new proc in front
          InsertPos:=FindLineEndOrCodeInFrontOfPosition(ProcNode.StartPos);
          Indent:=GetLineIndent(Src,ProcNode.StartPos);
        end else begin
          // this is a begin..end without proc (e.g. program or unit code)
          // insert new proc in front
          InsertPos:=FindLineEndOrCodeInFrontOfPosition(BeginNode.StartPos);
          Indent:=GetLineIndent(Src,BeginNode.StartPos);
        end;
      end;
    end else begin
      // eventually: create a new method in another class
      DebugLn(['TCodeCompletionCodeTool.CompleteProcByCall eventually: create a new method in another class']);
      exit;
    end;

    if not CreateProcCode(CursorNode,ProcNameAtom,
      IsFunction,FuncType,BracketOpenPos,Indent,
      CleanProcHead,ProcCode) then exit;

  finally
    DeactivateGlobalWriteLock;
    Params.Free;
    ExprList.Free;
  end;
  
  // insert proc body
  if not SourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,
    InsertPos,InsertPos,ProcCode)
  then
    exit;
    
  // remember old path
  NewProcPath:=nil;
  try
    if not CreatePathForNewProc(InsertPos,CleanProcHead,TStrings(NewProcPath)) then exit;
    if not SourceChangeCache.Apply then exit;
    if not FindJumpPointToNewProc(NewProcPath) then exit;
    Result:=true;
  finally
    NewProcPath.Free;
  end;
end;

procedure TCodeCompletionCodeTool.DoDeleteNodes(StartNode: TCodeTreeNode);
begin
  inherited DoDeleteNodes(StartNode);
  FreeClassInsertionList;
end;

function TCodeCompletionCodeTool.AddPublishedVariable(const UpperClassName,
  VarName, VarType: string; SourceChangeCache: TSourceChangeCache): boolean;
begin
  Result:=false;
  if (UpperClassName='') or (VarName='') or (VarType='')
  or (SourceChangeCache=nil) or (Scanner=nil) then exit;
  // find classnode
  BuildTree(lsrImplementationStart);
  // initialize class for code completion
  CodeCompleteClassNode:=FindClassNodeInInterface(UpperClassName,true,false,true);
  CodeCompleteSrcChgCache:=SourceChangeCache;
  // check if variable already exists
  if not VarExistsInCodeCompleteClass(UpperCaseStr(VarName)) then begin
    AddClassInsertion(UpperCaseStr(VarName),
                      VarName+':'+VarType+';',VarName,ncpPublishedVars);
    if not InsertAllNewClassParts then
      RaiseException(ctsErrorDuringInsertingNewClassParts);
    // apply the changes
    if not SourceChangeCache.Apply then
      RaiseException(ctsUnableToApplyChanges);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.GetRedefinitionNodeText(Node: TCodeTreeNode
  ): string;
begin
  case Node.Desc of
  ctnProcedure:
    Result:=ExtractProcHead(Node,[phpInUpperCase,phpWithoutSemicolon]);
  ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition,ctnEnumIdentifier,
  ctnGenericType:
    Result:=ExtractDefinitionName(Node);
  else
    Result:='';
  end;
end;

function TCodeCompletionCodeTool.FindRedefinitions(
  out TreeOfCodeTreeNodeExt: TAVLTree; WithEnums: boolean): boolean;
var
  AllNodes: TAVLTree;

  procedure AddRedefinition(Redefinition, Definition: TCodeTreeNode;
    const NodeText: string);
  var
    NodeExt: TCodeTreeNodeExtension;
  begin
    DebugLn(['AddRedefinition ',NodeText,' Redefined=',CleanPosToStr(Redefinition.StartPos),' Definition=',CleanPosToStr(Definition.StartPos)]);
    //DebugLn(['AddRedefinition as source: Definition="',ExtractNode(Definition,[]),'" Redefinition="',ExtractNode(Redefinition,[]),'"']);
    NodeExt:=TCodeTreeNodeExtension.Create;
    NodeExt.Node:=Redefinition;
    NodeExt.Data:=Definition;
    NodeExt.Txt:=NodeText;
    if TreeOfCodeTreeNodeExt=nil then
      TreeOfCodeTreeNodeExt:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    TreeOfCodeTreeNodeExt.Add(NodeExt);
  end;
  
  procedure AddDefinition(Node: TCodeTreeNode; const NodeText: string);
  var
    NodeExt: TCodeTreeNodeExtension;
  begin
    NodeExt:=TCodeTreeNodeExtension.Create;
    NodeExt.Node:=Node;
    NodeExt.Txt:=NodeText;
    AllNodes.Add(NodeExt);
  end;
  
var
  Node: TCodeTreeNode;
  NodeText: String;
  AVLNode: TAVLTreeNode;
begin
  Result:=false;
  TreeOfCodeTreeNodeExt:=nil;
  BuildTree(lsrImplementationStart);

  AllNodes:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  try
    Node:=Tree.Root;
    while Node<>nil do begin
      case Node.Desc of
      ctnImplementation, ctnInitialization, ctnFinalization,
      ctnBeginBlock, ctnAsmBlock:
        // skip implementation
        break;
      ctnVarDefinition, ctnTypeDefinition, ctnConstDefinition, ctnProcedure,
      ctnEnumIdentifier, ctnGenericType:
        begin
          NodeText:=GetRedefinitionNodeText(Node);
          AVLNode:=FindCodeTreeNodeExtAVLNode(AllNodes,NodeText);
          if AVLNode<>nil then begin
            AddRedefinition(Node,TCodeTreeNodeExtension(AVLNode.Data).Node,NodeText);
            Node:=Node.NextSkipChilds;
          end else begin
            AddDefinition(Node,NodeText);
            if WithEnums
            and (Node.FirstChild<>nil)
            and (Node.FirstChild.Desc=ctnEnumerationType) then
              Node:=Node.FirstChild
            else
              Node:=Node.NextSkipChilds;
          end;
        end;
      else
        Node:=Node.Next;
      end;
    end;
  finally
    DisposeAVLTree(AllNodes);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.RemoveRedefinitions(
  TreeOfCodeTreeNodeExt: TAVLTree;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  AVLNode: TAVLTreeNode;
  NodesToDo: TAVLTree;// tree of TCodeTreeNode
  Node: TCodeTreeNode;
  StartNode: TCodeTreeNode;
  EndNode: TCodeTreeNode;
  IsListStart: Boolean;
  IsListEnd: Boolean;
  StartPos: LongInt;
  EndPos: LongInt;
begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  if (TreeOfCodeTreeNodeExt=nil) or (TreeOfCodeTreeNodeExt.Count=0) then
    exit(true);
  SourceChangeCache.MainScanner:=Scanner;

  NodesToDo:=TAVLTree.Create;
  try
    // put the nodes to remove into the NodesToDo
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      Node:=TCodeTreeNodeExtension(AVLNode.Data).Node;
      //DebugLn(['TCodeCompletionCodeTool.RemoveRedefinitions add to NodesToDo ',GetRedefinitionNodeText(Node)]);
      NodesToDo.Add(Node);
      AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    end;
    
    // delete all redefinitions
    while NodesToDo.Count>0 do begin
      // find a block of redefinitions
      StartNode:=TCodeTreeNode(NodesToDo.Root.Data);
      //DebugLn(['TCodeCompletionCodeTool.RemoveRedefinitions StartNode=',StartNode.StartPos,' ',GetRedefinitionNodeText(StartNode)]);
      EndNode:=StartNode;
      while (StartNode.PriorBrother<>nil)
      and (NodesToDo.Find(StartNode.PriorBrother)<>nil) do
        StartNode:=StartNode.PriorBrother;
      while (EndNode.NextBrother<>nil)
      and (NodesToDo.Find(EndNode.NextBrother)<>nil) do
        EndNode:=EndNode.NextBrother;
      //DebugLn(['TCodeCompletionCodeTool.RemoveRedefinitions Start=',StartNode.StartPos,' ',GetRedefinitionNodeText(StartNode),' End=',EndNode.StartPos,' ',GetRedefinitionNodeText(EndNode)]);

      // check if a whole section is deleted
      if (StartNode.PriorBrother=nil) and (EndNode.NextBrother=nil)
      and (StartNode.Parent<>nil)
      and (StartNode.Parent.Desc in AllDefinitionSections) then begin
        StartNode:=StartNode.Parent;
        EndNode:=StartNode;
      end;
      
      // compute nice code positions to delete
      StartPos:=FindLineEndOrCodeInFrontOfPosition(StartNode.StartPos);
      EndPos:=FindLineEndOrCodeAfterPosition(EndNode.EndPos);
      
      // check list of definitions
      if EndNode.Desc in AllIdentifierDefinitions then begin
        // check list definition. For example:
        //  delete, delete: char;    ->   delete whole
        //  a,delete, delete: char;  ->   a: char;
        //  delete,delete,c: char;   ->   c: char;
        //  a,delete,delete,c: char; ->   a,c:char;
        IsListStart:=(StartNode.PriorBrother=nil)
                 or ((StartNode.PriorBrother<>nil)
                     and (StartNode.PriorBrother.FirstChild<>nil));
        IsListEnd:=(EndNode.FirstChild<>nil);
        if IsListStart and IsListEnd then begin
          // case 1: delete, delete: char;    ->   delete whole
        end else begin
          // case 2-4: keep type
          // get start position of first deleting identifier
          StartPos:=StartNode.StartPos;
          // get end position of last deleting identifier
          EndPos:=EndNode.StartPos+GetIdentLen(@Src[EndNode.StartPos]);
          if IsListEnd then begin
            // case 2: a,delete, delete: char;  ->   a: char;
            // delete comma in front of start too
            MoveCursorToCleanPos(StartNode.PriorBrother.StartPos);
            ReadNextAtom; // read identifier
            ReadNextAtom; // read comma
            StartPos:=CurPos.StartPos;
          end else begin
            // case 3,4
            // delete comma behind end too
            MoveCursorToCleanPos(EndNode.StartPos);
            ReadNextAtom; // read identifier
            ReadNextAtom; // read comma
            EndPos:=CurPos.StartPos;
          end;
        end;
      end;
      
      // replace
      DebugLn(['TCodeCompletionCodeTool.RemoveRedefinitions deleting:']);
      debugln('"',copy(Src,StartPos,EndPos-StartPos),'"');
      
      if not SourceChangeCache.Replace(gtNone,gtNone,StartPos,EndPos,'') then
        exit;
      
      // remove nodes from NodesToDo
      Node:=StartNode;
      repeat
        NodesToDo.Remove(Node);
        //DebugLn(['TCodeCompletionCodeTool.RemoveRedefinitions removed ',Node.StartPos,' ',GetRedefinitionNodeText(Node),' ',NodesToDo.Find(Node)<>nil]);
        Node:=Node.Next;
      until (Node=nil) or
         ((Node.StartPos>EndNode.StartPos) and (not Node.HasAsParent(EndNode)));
    end;
  finally
    NodesToDo.Free;
  end;
  
  Result:=SourceChangeCache.Apply;
end;

function TCodeCompletionCodeTool.FindAliasDefinitions(out
  TreeOfCodeTreeNodeExt: TAVLTree; OnlyWrongType: boolean): boolean;
// finds all public definitions of the form 'const A = B;'
var
  AllNodes: TAVLTree;

  procedure CheckAlias(Node: TCodeTreeNode);
  var
    ReferingNode: TCodeTreeNode;
    ReferingNodeText: String;
    ReferingPos: LongInt;
    NodeExt: TCodeTreeNodeExtension;
    BracketStartPos: LongInt;
    NeededType: TCodeTreeNodeDesc;
    
    procedure GetReferingNode;
    begin
      if ReferingNodeText<>'' then exit;
      ReferingNodeText:=GetIdentifier(@Src[ReferingPos]);
      NodeExt:=FindCodeTreeNodeExtWithIdentifier(AllNodes,PChar(ReferingNodeText));
      if (NodeExt<>nil) then
        ReferingNode:=NodeExt.Node;
    end;
    
  begin
    // check if definition is an alias
    // Example:  const A = B;  or   const A = B();
    
    if (Node.Parent=nil) then exit;
    if not (Node.Parent.Desc in [ctnConstSection,ctnTypeSection]) then exit;
    // this is a const or type
    MoveCursorToNodeStart(Node);
    // read A
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    // read =
    ReadNextAtom;
    if CurPos.Flag<>cafEqual then exit;
    // read B
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    ReferingPos:=CurPos.StartPos;
    ReadNextAtom;
    if CurPos.Flag=cafRoundBracketOpen then begin
      BracketStartPos:=CurPos.StartPos;
      ReadTilBracketClose(true);
      //BracketEndPos:=CurPos.StartPos;
      ReadNextAtom;
    end else
      BracketStartPos:=0;
    if CurPos.Flag<>cafSemicolon then exit;
    
    ReferingNode:=nil;
    NeededType:=ctnNone;

    if BracketStartPos>0 then begin
      if WordIsKeyWord.DoItCaseInsensitive(@Src[ReferingPos]) then
        exit;
      // this is a type cast
      NeededType:=ctnConstDefinition;
      //GetReferingNode;
      if (ReferingNode<>nil) then begin
        // ToDo: check if it is a typecast to a procedure type
        // then the alias should be replaced with a procdure
        //if (ReferingNode=ctnTypeDefinition)
      end;
    end else begin
      // this is a const or type alias
      //DebugLn(['TCodeCompletionCodeTool.FindAliasDefinitions Alias: ',Node.DescAsString,' ',ExtractNode(Node,[])]);
      GetReferingNode;
      if (ReferingNode<>nil) then begin
        NeededType:=ReferingNode.Desc;
      end;
    end;
    if NeededType=ctnNone then exit;
    // add alias
    if NeededType<>Node.Desc then begin
      DebugLn(['TCodeCompletionCodeTool.FindAliasDefinitions Wrong: ',Node.DescAsString,' ',ExtractNode(Node,[]),' ',Node.DescAsString,'<>',NodeDescToStr(NeededType)]);
    end;
    if TreeOfCodeTreeNodeExt=nil then
      TreeOfCodeTreeNodeExt:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    NodeExt:=TCodeTreeNodeExtension.Create;
    NodeExt.Node:=Node;
    NodeExt.Txt:=GetRedefinitionNodeText(Node);
    NodeExt.Data:=ReferingNode;
    NodeExt.Flags:=NeededType;
    TreeOfCodeTreeNodeExt.Add(NodeExt);
  end;
  
  procedure UpdateDefinition(const NodeText: string; Node: TCodeTreeNode);
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    AVLNode:=FindCodeTreeNodeExtAVLNode(AllNodes,NodeText);
    if AVLNode=nil then begin
      // add new node
      NodeExt:=TCodeTreeNodeExtension.Create;
      NodeExt.Node:=Node;
      NodeExt.Txt:=NodeText;
      AllNodes.Add(NodeExt);
    end else begin
      // update node
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      NodeExt.Node:=Node;
    end;
  end;
  
  procedure CollectAllDefinitions;
  var
    Node: TCodeTreeNode;
  begin
    Node:=Tree.Root;
    while Node<>nil do begin
      case Node.Desc of
      ctnImplementation, ctnInitialization, ctnFinalization,
      ctnBeginBlock, ctnAsmBlock:
        // skip implementation
        break;
      ctnTypeDefinition, ctnConstDefinition:
        begin
          // remember the definition
          UpdateDefinition(GetRedefinitionNodeText(Node),Node);
          Node:=Node.NextSkipChilds;
        end;
      ctnProcedure:
        begin
          UpdateDefinition(ExtractProcName(Node,[]),Node);
          Node:=Node.NextSkipChilds;
        end;
      else
        Node:=Node.Next;
      end;
    end;
  end;
  
  procedure CollectAllAliasDefinitions;
  var
    Node: TCodeTreeNode;
  begin
    Node:=Tree.Root;
    while Node<>nil do begin
      case Node.Desc of
      ctnImplementation, ctnInitialization, ctnFinalization,
      ctnBeginBlock, ctnAsmBlock:
        // skip implementation
        break;
      ctnTypeDefinition, ctnConstDefinition:
        begin
          CheckAlias(Node);
          Node:=Node.NextSkipChilds;
        end;
      ctnProcedure:
        Node:=Node.NextSkipChilds;
      else
        Node:=Node.Next;
      end;
    end;
  end;
  
  procedure ResolveAliases;
  
    function FindAliasRoot(Node: TCodeTreeNode;
      out NeededRootDesc: TCodeTreeNodeDesc): TCodeTreeNode;
    var
      AliasText: String;
      AVLNode: TAVLTreeNode;
      ReferingNode: TCodeTreeNode;
      OldDesc: TCodeTreeNodeDesc;
      NodeExt: TCodeTreeNodeExtension;
    begin
      Result:=Node;
      NeededRootDesc:=Node.Desc;
      if Node.Desc=ctnProcedure then
        AliasText:=ExtractProcName(Node,[])
      else
        AliasText:=GetRedefinitionNodeText(Node);
      if AliasText='' then exit;
      AVLNode:=FindCodeTreeNodeExtAVLNode(TreeOfCodeTreeNodeExt,AliasText);
      if AVLNode=nil then exit;
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      NeededRootDesc:=TCodeTreeNodeDesc(NodeExt.Flags);

      ReferingNode:=TCodeTreeNode(NodeExt.Data);
      if ReferingNode=nil then exit;
      // this is an alias => search further
      if ReferingNode.Desc=ctnNone then begin
        // circle
        exit;
      end;
      // mark node as visited
      OldDesc:=Node.Desc;
      Node.Desc:=ctnNone;
      Result:=FindAliasRoot(ReferingNode,NeededRootDesc);
      // unmark node as visited
      Node.Desc:=OldDesc;
      if NeededRootDesc=ctnNone then
        NeededRootDesc:=Node.Desc;
    end;
  
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
    ReferingNode: TCodeTreeNode;
    NeededType: TCodeTreeNodeDesc;
  begin
    if TreeOfCodeTreeNodeExt=nil then exit;
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      ReferingNode:=TCodeTreeNode(NodeExt.Data);
      if ReferingNode<>nil then begin
        // this node is an alias.
        // => find the root alias
        ReferingNode:=FindAliasRoot(ReferingNode,NeededType);
        NodeExt.Data:=ReferingNode;
        NodeExt.Flags:=NeededType;
      end;
      AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    end;
  end;
  
  procedure RemoveGoodAliases;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
    NeededType: TCodeTreeNodeDesc;
    NextAVLNode: TAVLTreeNode;
  begin
    if TreeOfCodeTreeNodeExt=nil then exit;
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      NextAVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      NeededType:=TCodeTreeNodeDesc(NodeExt.Flags);
      if NodeExt.Node.Desc=NeededType then begin
        TreeOfCodeTreeNodeExt.FreeAndDelete(AVLNode);
      end;
      AVLNode:=NextAVLNode;
    end;
  end;
  
begin
  Result:=false;
  TreeOfCodeTreeNodeExt:=nil;
  BuildTree(lsrImplementationStart);

  AllNodes:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  try
    if OnlyWrongType then
      CollectAllDefinitions;
    CollectAllAliasDefinitions;
    if OnlyWrongType then begin
      ResolveAliases;
      RemoveGoodAliases;
    end;
  finally
    DisposeAVLTree(AllNodes);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.FixAliasDefinitions(
  TreeOfCodeTreeNodeExt: TAVLTree; SourceChangeCache: TSourceChangeCache
  ): boolean;
{ replaces public dummy functions with a constant.
  The function body will be removed.
  See the function FindAliasDefinitions.
}
  function FindReferingNodeExt(DefNode: TCodeTreeNode): TCodeTreeNodeExtension;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Node=DefNode then begin
        Result:=NodeExt;
        exit;
      end;
      AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    end;
    Result:=nil;
  end;

var
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  DefNode: TCodeTreeNode;
  ReferingNode: TCodeTreeNode;
  NextAVLNode: TAVLTreeNode;
  ReferingNodeInFront: TCodeTreeNodeExtension;
  ReferingNodeBehind: TCodeTreeNodeExtension;
  NewSrc: String;
  FromPos: LongInt;
  ToPos: LongInt;
  ReferingType: TCodeTreeNodeDesc;
  NewSection: String;
  ProcName: String;
  OldProcName: String;
begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  if (TreeOfCodeTreeNodeExt=nil) or (TreeOfCodeTreeNodeExt.Count=0) then
    exit(true);
  SourceChangeCache.MainScanner:=Scanner;

  // remove all nodes which can not be handled here
  AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
  while AVLNode<>nil do begin
    NextAVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
    DefNode:=NodeExt.Node;
    ReferingType:=TCodeTreeNodeDesc(NodeExt.Flags);
    ReferingNode:=TCodeTreeNode(NodeExt.Data);
    if (ReferingType=ctnProcedure) then begin
      // procedure alias => check if it is an 'external' procedure
      if (ReferingNode=nil) or (ReferingNode.Desc<>ctnProcedure)
      or (not ProcNodeHasSpecifier(ReferingNode,psEXTERNAL)) then
        ReferingType:=ctnNone;
    end;
    if (not (ReferingType in [ctnTypeDefinition,ctnConstDefinition,ctnProcedure]))
    or (DefNode.Desc=ReferingType) then begin
      TreeOfCodeTreeNodeExt.FreeAndDelete(AVLNode);
    end;
    AVLNode:=NextAVLNode;
  end;

  // insert additional sections
  AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
  while AVLNode<>nil do begin
    NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
    DefNode:=NodeExt.Node;
    ReferingType:=TCodeTreeNodeDesc(NodeExt.Flags);
    ReferingNode:=TCodeTreeNode(NodeExt.Data);

    //DebugLn(['TCodeCompletionCodeTool.FixAliasDefinitions Old=',DefNode.DescAsString,' New=',NodeDescToStr(ReferingType)]);

    // check in front
    if ReferingType in [ctnTypeDefinition,ctnConstDefinition] then begin
      case ReferingType of
      ctnTypeDefinition: NewSection:='type';
      ctnConstDefinition: NewSection:='const';
      ctnProcedure: NewSrc:='';
      else NewSection:='bug';
      end;

      if DefNode.PriorBrother=nil then begin
        // this is the start of the section
        MoveCursorToNodeStart(DefNode.Parent);
        ReadNextAtom;
        if not SourceChangeCache.Replace(gtNone,gtNone,
          CurPos.StartPos,CurPos.EndPos,NewSection) then exit;
      end else begin
        // this is not the start of the section
        ReferingNodeInFront:=FindReferingNodeExt(DefNode.PriorBrother);
        if (ReferingNodeInFront=nil)
        or (TCodeTreeNodeDesc(ReferingNodeInFront.Flags)<>ReferingType) then
        begin
          // the node in front has a different section
          FromPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.StartPos);
          if not SourceChangeCache.Replace(gtEmptyLine,gtNewLine,
             FromPos,FromPos,NewSection) then exit;
        end;
      end;
    end else if ReferingType=ctnProcedure then begin
      // alias to an external procedure
      // => replace alias with complete external procedure header

      if DefNode.PriorBrother=nil then begin
        // this is the start of the section
        FromPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.Parent.StartPos);
        ToPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.StartPos);
        if not SourceChangeCache.Replace(gtNone,gtNone,
          FromPos,ToPos,'') then exit;
      end;

      NewSrc:=ExtractProcHead(ReferingNode,[phpWithStart,phpWithVarModifiers,
        phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
        phpWithOfObject,phpWithCallingSpecs,phpWithProcModifiers]);
      OldProcName:=ExtractProcName(ReferingNode,[]);
      FromPos:=System.Pos(OldProcName,NewSrc);
      if DefNode.Desc in [ctnTypeDefinition,ctnConstDefinition] then
        ProcName:=ExtractDefinitionName(DefNode)
      else if DefNode.Desc=ctnProcedure then
        ProcName:=ExtractProcName(DefNode,[])
      else
        ProcName:=NodeExt.Txt;
      NewSrc:=copy(NewSrc,1,FromPos-1)+ProcName
             +copy(NewSrc,FromPos+length(OldProcName),length(NewSrc));
      FromPos:=DefNode.StartPos;
      ToPos:=DefNode.EndPos;
      if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,NewSrc)
      then
        exit;
    end;
    
    // check behind
    if DefNode.NextBrother=nil then begin
      // this is the end of the section
    end else begin
      // this is not the end of the section
      ReferingNodeBehind:=FindReferingNodeExt(DefNode.NextBrother);
      if ReferingNodeBehind<>nil then begin
        // the next node will change the section
      end else begin
        // the next node should stay in the same type of section
        case DefNode.NextBrother.Desc of
        ctnTypeDefinition: NewSrc:='type';
        ctnConstDefinition: NewSrc:='const';
        else NewSrc:='';
        end;
        if NewSrc<>'' then begin
          FromPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.NextBrother.StartPos);
          if not SourceChangeCache.Replace(gtEmptyLine,gtNewLine,
             FromPos,FromPos,NewSrc) then exit;
        end;
      end;
    end;

    AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
  end;
  Result:=SourceChangeCache.Apply;
end;

function TCodeCompletionCodeTool.FindConstFunctions(
  out TreeOfCodeTreeNodeExt: TAVLTree): boolean;
{ find public dummy functions that can be replaced with a constant
  For example:
  
      function MPI_CONVERSION_FN_NULL : PMPI_Datarep_conversion_function;
      begin
         MPI_CONVERSION_FN_NULL:=PMPI_Datarep_conversion_function(0);
      end;
      
   Where the expression only contains unit defined types, constants,
   variables, built-in const functions and no members nor functions.

    NodeExt.Txt: description
    NodeExt.Node: definition node
    NodeExt.Data: function body node
    NodeExt.ExtTxt1: ExtractCode(ExprStart,ExprEnd,[]);
}
var
  Definitions: TAVLTree;
  
  function FindProcWithName(Identifier: PChar): TCodeTreeNodeExtension;
  begin
    Result:=FindCodeTreeNodeExtWithIdentifier(Definitions,Identifier);
  end;

  procedure CheckProcNode(ProcNode: TCodeTreeNode);
  // check if node is a function (not class function)
  var
    Node: TCodeTreeNode;
    FuncName: String;
    ExprStart: LongInt;
    NodeText: String;
    NodeExt: TCodeTreeNodeExtension;
    ExprEnd: LongInt;
    ResultNodeExt: TCodeTreeNodeExtension;

    function CheckExprIdentifier(Identifier: PChar): boolean;
    var
      NodeExt: TCodeTreeNodeExtension;
      NewPos: Integer;
      AtomStart: integer;
    begin
      Result:=true;
      if CompareIdentifiers('Result',Identifier)=0 then exit;
      if CompareIdentifiers(PChar(FuncName),Identifier)=0 then exit;
      // check for const and type definitions
      NodeExt:=FindCodeTreeNodeExt(Definitions,GetIdentifier(Identifier));
      if NodeExt=nil then
        NodeExt:=FindProcWithName(Identifier);
      
      if (NodeExt<>nil) and (NodeExt.Node<>nil) then begin
        if NodeExt.Node.Desc in [ctnConstDefinition,ctnTypeDefinition] then
          exit;
        if (NodeExt.Node.Desc=ctnProcedure) and IsPCharInSrc(Identifier) then
        begin
          // read atom behind identifier name
          NewPos:=PtrInt(PtrUInt(Identifier))-PtrInt(PtrUInt(@Src[1]))+1;
          inc(NewPos,GetIdentLen(Identifier));
          ReadRawNextPascalAtom(Src,NewPos,AtomStart,Scanner.NestedComments,true);
          if (AtomStart<=SrcLen) and (Src[AtomStart]<>'(') then begin
            // no parameters
            // this is the function pointer, not the result => constant
            exit;
          end;
        end;
      end;

      // check for compiler built in operators, constants and types
      if IsWordBuiltInFunc.DoItCaseInsensitive(Identifier) then exit;
      if WordIsBinaryOperator.DoItCaseInsensitive(Identifier) then exit;
      if WordIsPredefinedFPCIdentifier.DoItCaseInsensitive(Identifier) then exit;
      Result:=false;
    end;

  begin
    if (ProcNode=nil) or (ProcNode.Desc<>ctnProcedure) then exit;
    //DebugLn(['CheckProcNode START ',ExtractProcHead(ProcNode,[])]);
    MoveCursorToNodeStart(ProcNode);
    // read 'function'
    ReadNextAtom;
    if not UpAtomIs('FUNCTION') then exit;
    // read name
    ReadNextAtom;
    FuncName:=GetAtom;
    ReadNextAtom;
    if CurPos.Flag=cafRoundBracketOpen then begin
      // skip optional empty parameter list ()
      ReadNextAtom;
      if CurPos.Flag<>cafRoundBracketClose then exit;
      ReadNextAtom;
    end;
    // read :
    if CurPos.Flag<>cafColon then exit;
    // read result type
    ReadNextAtom;
    if not AtomIsIdentifier then exit;

    // check if there is a public definition of the procedure
    NodeText:=GetRedefinitionNodeText(ProcNode);
    if TreeOfCodeTreeNodeExt<>nil then begin
      ResultNodeExt:=FindCodeTreeNodeExt(TreeOfCodeTreeNodeExt,NodeText);
      if ResultNodeExt<>nil then begin
        DebugLn(['CheckProcNode function exists twice']);
        exit;
      end;
    end;

    NodeExt:=FindCodeTreeNodeExt(Definitions,NodeText);
    if (NodeExt=nil) or (NodeExt.Node=nil) or (NodeExt.Node.Desc<>ctnProcedure)
    then begin
      DebugLn(['CheckProcNode function is not public NodeText=',NodeText]);
      exit;
    end;

    // check child nodes only contain the proc head and a begin block
    Node:=ProcNode.FirstChild;
    if Node=nil then exit;
    if Node.Desc=ctnProcedureHead then begin
      Node:=Node.NextBrother;
      if Node=nil then exit;
    end;
    if Node.Desc<>ctnBeginBlock then exit;

    //DebugLn(['CheckProcNode has begin block']);
    
    // check begin block is only a single assignment
    MoveCursorToNodeStart(Node);
    // read begin
    ReadNextAtom;
    // read 'Result' or 'FunctionName'
    ReadNextAtom;
    if (not UpAtomIs('RESULT')) and (not AtomIs(FuncName)) then exit;
    // read :=
    ReadNextAtom;
    if not UpAtomIs(':=') then exit;
    // read expression
    ReadNextAtom;
    ExprStart:=CurPos.StartPos;
    ExprEnd:=ExprStart;
    while (CurPos.EndPos<=Node.EndPos) do begin
      if (CurPos.Flag in [cafSemicolon,cafEnd]) then
        break;
      // check if all identifiers can be used in a constant expression
      if AtomIsIdentifier
      and not CheckExprIdentifier(@Src[CurPos.StartPos]) then
        exit;
      ExprEnd:=CurPos.EndPos;
      ReadNextAtom;
    end;
    if ExprStart=ExprEnd then exit;
    
    //DebugLn(['CheckProcNode FOUND']);
    
    // save values
    ResultNodeExt:=TCodeTreeNodeExtension.Create;
    ResultNodeExt.Txt:=NodeText;
    ResultNodeExt.Node:=NodeExt.Node;
    ResultNodeExt.Data:=ProcNode;
    ResultNodeExt.ExtTxt1:=ExtractCode(ExprStart,ExprEnd,[]);
    if TreeOfCodeTreeNodeExt=nil then
      TreeOfCodeTreeNodeExt:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    TreeOfCodeTreeNodeExt.Add(ResultNodeExt);
  end;
  
var
  Node: TCodeTreeNode;
begin
  Result:=false;
  TreeOfCodeTreeNodeExt:=nil;

  try
    BuildTree(lsrImplementationStart);

    // first step: find all unit identifiers (excluding implementation section)
    if not GatherUnitDefinitions(Definitions,true,true) then exit;
    //DebugLn(['TCodeCompletionCodeTool.FindConstFunctions ',Src]);
    
    // now check all functions
    Node:=Tree.Root;
    while Node<>nil do begin
      case Node.Desc of
      ctnInterface, ctnUsesSection, ctnBeginBlock, ctnAsmBlock, ctnProcedureHead,
      ctnTypeSection, ctnConstSection, ctnVarSection, ctnResStrSection:
        Node:=Node.NextSkipChilds;
      ctnProcedure:
        begin
          CheckProcNode(Node);
          Node:=Node.NextSkipChilds;
        end;
      else
        Node:=Node.Next;
      end;
    end;
    
  finally
    DisposeAVLTree(Definitions);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.ReplaceConstFunctions(
  TreeOfCodeTreeNodeExt: TAVLTree; SourceChangeCache: TSourceChangeCache
  ): boolean;
{ replaces public dummy functions with a constant.
  The function body will be removed.
  See the function FindConstFunctions.
}
  function IsConstSectionNeeded(Node: TCodeTreeNode): boolean;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    if Node.PriorBrother.Desc=ctnConstSection then exit(false);
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Node=Node.PriorBrother then begin
        // the function in front will be replaced too
        exit(false);
      end;
      AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    end;
    Result:=true;
  end;

var
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  DefNode: TCodeTreeNode;
  BodyNode: TCodeTreeNode;
  Expr: String;
  FromPos: LongInt;
  ToPos: LongInt;
  NewSrc: String;
begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  if (TreeOfCodeTreeNodeExt=nil) or (TreeOfCodeTreeNodeExt.Count=0) then
    exit(true);
  SourceChangeCache.MainScanner:=Scanner;

  AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
  while AVLNode<>nil do begin
    NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
    DebugLn(['TCodeCompletionCodeTool.ReplaceConstFunctions ',NodeExt.Txt]);
    DefNode:=NodeExt.Node;
    BodyNode:=TCodeTreeNode(NodeExt.Data);
    Expr:=NodeExt.ExtTxt1;
    DebugLn(['TCodeCompletionCodeTool.ReplaceConstFunctions Expr=',Expr]);
    
    // remove body node
    FromPos:=FindLineEndOrCodeInFrontOfPosition(BodyNode.StartPos);
    ToPos:=FindLineEndOrCodeAfterPosition(BodyNode.EndPos);
    if (ToPos<=SrcLen) and (Src[ToPos] in [#10,#13]) then begin
      inc(ToPos);
      if (ToPos<=SrcLen) and (Src[ToPos] in [#10,#13])
      and (Src[ToPos-1]<>Src[ToPos]) then
        inc(ToPos);
    end;
    DebugLn(['TCodeCompletionCodeTool.ReplaceConstFunctions Body="',copy(Src,FromPos,ToPos-FromPos),'"']);
    SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'');
    
    // replace definition
    FromPos:=DefNode.StartPos;
    ToPos:=DefNode.EndPos;
    if Src[ToPos]=';' then inc(ToPos);// add semicolon
    NewSrc:=GetIndentStr(SourceChangeCache.BeautifyCodeOptions.Indent)
      +ExtractProcName(DefNode,[])+' = '+Expr+';';
    SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,NewSrc);
    // add 'const' keyword
    if IsConstSectionNeeded(DefNode) then begin
      FromPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.StartPos);
      SourceChangeCache.Replace(gtEmptyLine,gtNewLine,FromPos,FromPos,'const');
    end;

    AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
  end;
  Result:=SourceChangeCache.Apply;
end;

function TCodeCompletionCodeTool.FindTypeCastFunctions(out
  TreeOfCodeTreeNodeExt: TAVLTree): boolean;
{ find public dummy functions that can be replaced with a type
  For example:

  function PMPI_Win_f2c(win : longint) : MPI_Win;
    begin
       PMPI_Win_f2c:=MPI_Win(win);
    end;

   Where the expression is Result := ResultType(Parameter).

    NodeExt.Txt: description
    NodeExt.Node: definition node
    NodeExt.Data: function body node
    NodeExt.ExtTxt1: ResultType
}
var
  Definitions: TAVLTree;

  procedure CheckProcNode(ProcNode: TCodeTreeNode);
  // check if node is a function (not class function)
  var
    Node: TCodeTreeNode;
    FuncName: PChar;
    NodeText: String;
    NodeExt: TCodeTreeNodeExtension;
    ResultNodeExt: TCodeTreeNodeExtension;
    ParamName: PChar;
    ResultType: PChar;
  begin
    if (ProcNode=nil) or (ProcNode.Desc<>ctnProcedure) then exit;
    //DebugLn(['CheckProcNode START ',ExtractProcHead(ProcNode,[])]);
    MoveCursorToNodeStart(ProcNode);
    ReadNextAtom;
    // read 'function'
    if not UpAtomIs('FUNCTION') then exit;
    ReadNextAtom;
    // read name
    if CurPos.Flag<>cafWord then exit;
    FuncName:=@Src[CurPos.StartPos];
    ReadNextAtom;
    // read (
    if CurPos.Flag<>cafRoundBracketOpen then exit;
    ReadNextAtom;
    // read optional const
    if UpAtomIs('CONST') then
      ReadNextAtom;
    // read parameter name
    if CurPos.Flag<>cafWord then exit;
    ParamName:=@Src[CurPos.StartPos];
    ReadNextAtom;
    // read :
    if CurPos.Flag<>cafColon then exit;
    ReadNextAtom;
    // read parameter type
    if CurPos.Flag<>cafWord then exit;
    ReadNextAtom;
    // read )
    if CurPos.Flag<>cafRoundBracketClose then exit;
    ReadNextAtom;
    // read :
    if CurPos.Flag<>cafColon then exit;
    // read result type
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    ResultType:=@Src[CurPos.StartPos];

    // check if there is a public definition of the procedure
    NodeText:=GetRedefinitionNodeText(ProcNode);
    if TreeOfCodeTreeNodeExt<>nil then begin
      ResultNodeExt:=FindCodeTreeNodeExt(TreeOfCodeTreeNodeExt,NodeText);
      if ResultNodeExt<>nil then begin
        DebugLn(['CheckProcNode function exists twice']);
        exit;
      end;
    end;

    NodeExt:=FindCodeTreeNodeExt(Definitions,NodeText);
    if (NodeExt=nil) or (NodeExt.Node=nil) or (NodeExt.Node.Desc<>ctnProcedure)
    then begin
      DebugLn(['CheckProcNode function is not public NodeText=',NodeText]);
      exit;
    end;

    // check child nodes only contain the proc head and a begin block
    Node:=ProcNode.FirstChild;
    if Node=nil then exit;
    if Node.Desc=ctnProcedureHead then begin
      Node:=Node.NextBrother;
      if Node=nil then exit;
    end;
    if Node.Desc<>ctnBeginBlock then exit;

    //DebugLn(['CheckProcNode has begin block']);

    // check begin block is only a single assignment
    MoveCursorToNodeStart(Node);
    // read begin
    ReadNextAtom;
    // read 'Result' or 'FunctionName'
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    if (not UpAtomIs('RESULT'))
    and (CompareIdentifiers(FuncName,@Src[CurPos.StartPos])<>0) then exit;
    // read :=
    ReadNextAtom;
    if not UpAtomIs(':=') then exit;
    // read type cast to result type
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    if (CompareIdentifiers(ResultType,@Src[CurPos.StartPos])<>0) then exit;
    // read (
    ReadNextAtom;
    if CurPos.Flag<>cafRoundBracketOpen then exit;
    // read parameter
    ReadNextAtom;
    if CurPos.Flag<>cafWord then exit;
    if (CompareIdentifiers(ParamName,@Src[CurPos.StartPos])<>0) then exit;
    // read )
    ReadNextAtom;
    if CurPos.Flag<>cafRoundBracketClose then exit;
    //DebugLn(['CheckProcNode FOUND']);

    // save values
    ResultNodeExt:=TCodeTreeNodeExtension.Create;
    ResultNodeExt.Txt:=NodeText;
    ResultNodeExt.Node:=NodeExt.Node;
    ResultNodeExt.Data:=ProcNode;
    ResultNodeExt.ExtTxt1:=GetIdentifier(ResultType);
    if TreeOfCodeTreeNodeExt=nil then
      TreeOfCodeTreeNodeExt:=TAVLTree.Create(@CompareCodeTreeNodeExt);
    TreeOfCodeTreeNodeExt.Add(ResultNodeExt);
  end;

var
  Node: TCodeTreeNode;
begin
  Result:=false;
  TreeOfCodeTreeNodeExt:=nil;
  try
    BuildTree(lsrImplementationStart);
  
    // first step: find all unit identifiers (excluding implementation section)
    if not GatherUnitDefinitions(Definitions,true,true) then exit;

    // now check all functions
    Node:=Tree.Root;
    while Node<>nil do begin
      case Node.Desc of
      ctnInterface, ctnUsesSection, ctnBeginBlock, ctnAsmBlock, ctnProcedureHead,
      ctnTypeSection, ctnConstSection, ctnVarSection, ctnResStrSection:
        Node:=Node.NextSkipChilds;
      ctnProcedure:
        begin
          CheckProcNode(Node);
          Node:=Node.NextSkipChilds;
        end;
      else
        Node:=Node.Next;
      end;
    end;

  finally
    DisposeAVLTree(Definitions);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.ReplaceTypeCastFunctions(
  TreeOfCodeTreeNodeExt: TAVLTree; SourceChangeCache: TSourceChangeCache
  ): boolean;
{ replaces public dummy functions with a type.
  The function body will be removed.
  See the function FindTypeCastFunctions.
}
  function IsTypeSectionNeeded(Node: TCodeTreeNode): boolean;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    if Node.PriorBrother.Desc=ctnTypeSection then exit(false);
    AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Node=Node.PriorBrother then begin
        // the function in front will be replaced too
        exit(false);
      end;
      AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
    end;
    Result:=true;
  end;

var
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  DefNode: TCodeTreeNode;
  BodyNode: TCodeTreeNode;
  Expr: String;
  FromPos: LongInt;
  ToPos: LongInt;
  NewSrc: String;
begin
  Result:=false;
  if SourceChangeCache=nil then exit;
  if (TreeOfCodeTreeNodeExt=nil) or (TreeOfCodeTreeNodeExt.Count=0) then
    exit(true);
  SourceChangeCache.MainScanner:=Scanner;

  AVLNode:=TreeOfCodeTreeNodeExt.FindLowest;
  while AVLNode<>nil do begin
    NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
    DebugLn(['TCodeCompletionCodeTool.ReplaceTypeCastFunctions ',NodeExt.Txt]);
    DefNode:=NodeExt.Node;
    BodyNode:=TCodeTreeNode(NodeExt.Data);
    Expr:=NodeExt.ExtTxt1;
    DebugLn(['TCodeCompletionCodeTool.ReplaceTypeCastFunctions Expr=',Expr]);

    // remove body node
    FromPos:=FindLineEndOrCodeInFrontOfPosition(BodyNode.StartPos);
    ToPos:=FindLineEndOrCodeAfterPosition(BodyNode.EndPos);
    if (ToPos<=SrcLen) and (Src[ToPos] in [#10,#13]) then begin
      inc(ToPos);
      if (ToPos<=SrcLen) and (Src[ToPos] in [#10,#13])
      and (Src[ToPos-1]<>Src[ToPos]) then
        inc(ToPos);
    end;
    DebugLn(['TCodeCompletionCodeTool.ReplaceTypeCastFunctions Body="',copy(Src,FromPos,ToPos-FromPos),'"']);
    SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'');

    // replace definition
    FromPos:=DefNode.StartPos;
    ToPos:=DefNode.EndPos;
    if Src[ToPos]=';' then inc(ToPos);// add semicolon
    NewSrc:=GetIndentStr(SourceChangeCache.BeautifyCodeOptions.Indent)
      +ExtractProcName(DefNode,[])+' = '+Expr+';';
    SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,NewSrc);
    // add 'type' keyword
    if IsTypeSectionNeeded(DefNode) then begin
      FromPos:=FindLineEndOrCodeInFrontOfPosition(DefNode.StartPos);
      SourceChangeCache.Replace(gtEmptyLine,gtNewLine,FromPos,FromPos,'type');
    end;

    AVLNode:=TreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
  end;
  Result:=SourceChangeCache.Apply;
end;

function TCodeCompletionCodeTool.MovePointerTypesToTargetSections(
  SourceChangeCache: TSourceChangeCache): boolean;
const
  NodeMovedFlag = 1;
var
  NodeMoves: TCodeGraph;// an edge means, move the FromNode in front of the ToNode
  
  procedure InitNodeMoves;
  begin
    if NodeMoves=nil then
      NodeMoves:=TCodeGraph.Create;
  end;
  
  procedure ClearNodeMoves;
  begin
    FreeAndNil(NodeMoves);
  end;
  
  procedure AddMove(Node, InsertInFrontOf: TCodeTreeNode);
  begin
    if Node=InsertInFrontOf then exit;
    if Node=nil then RaiseException('inconsistency');
    if InsertInFrontOf=nil then RaiseException('inconsistency');
    NodeMoves.AddEdge(Node,InsertInFrontOf);
  end;
  
  function WholeSectionIsMoved(SectionNode: TCodeTreeNode): boolean;
  var
    Node: TCodeTreeNode;
    GraphNode: TCodeGraphNode;
  begin
    Node:=SectionNode.FirstChild;
    while Node<>nil do begin
      GraphNode:=NodeMoves.GetGraphNode(Node,false);
      if (GraphNode=nil) or (GraphNode.OutTreeCount=0) then
        exit(false);
      Node:=Node.NextBrother;
    end;
    Result:=true;
  end;
  
  function ApplyNodeMove(GraphNode: TCodeGraphNode; MoveNode: boolean;
    InsertPos, Indent: integer): boolean;
  // if MoveNode=true then move code of GraphNode.Node to InsertPos
  // Always: move recursively all nodes that should be moved to GraphNode too
  var
    AVLNode: TAVLTreeNode;
    GraphEdge: TCodeGraphEdge;
    Node: TCodeTreeNode;
    FromPos: LongInt;
    ToPos: LongInt;
    NodeSrc: String;
  begin
    Result:=false;
    Node:=GraphNode.Node;
    // marked as moved
    GraphNode.Flags:=NodeMovedFlag;
    DebugLn(['ApplyNodeMoves ',ExtractNode(Node,[])]);
    if MoveNode then begin
      FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
      ToPos:=FindLineEndOrCodeAfterPosition(Node.EndPos);
      NodeSrc:=GetIndentStr(Indent)+Trim(copy(Src,FromPos,ToPos-FromPos));
      // remove
      if (Node.PriorBrother=nil)
      and (Node.Parent<>nil) and (Node.Parent.Desc in AllDefinitionSections)
      and WholeSectionIsMoved(Node.Parent)
      then begin
        // the whole section is moved and this is the first node of the section
        // remove the section header too
        FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.Parent.StartPos);
      end;
      DebugLn(['ApplyNodeMove Remove: "',copy(Src,FromPos,ToPos-FromPos),'"']);
      if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then exit;
      // insert
      DebugLn(['ApplyNodeMove Insert: "',NodeSrc,'"']);
      if not SourceChangeCache.Replace(gtNewLine,gtNewLine,
        InsertPos,InsertPos,NodeSrc) then exit;
    end;
    // move dependent nodes
    if GraphNode.InTree<>nil then begin
      AVLNode:=GraphNode.InTree.FindLowest;
      while AVLNode<>nil do begin
        GraphEdge:=TCodeGraphEdge(AVLNode.Data);
        if not ApplyNodeMove(GraphEdge.FromNode,true,InsertPos,Indent) then exit;
        AVLNode:=GraphNode.InTree.FindSuccessor(AVLNode);
      end;
    end;
    Result:=true;
  end;
  
  function ApplyNodeMoves(ExceptionOnCircle: boolean): boolean;
  var
    GraphEdge: TCodeGraphEdge;
    ListOfGraphNodes: TFPList;
    i: Integer;
    GraphNode: TCodeGraphNode;
    InsertPos: LongInt;
    Indent: LongInt;
  begin
    Result:=false;
    if NodeMoves.Edges.Count=0 then exit(true);
    
    // check that every node has no more than one destination
    GraphNode:=NodeMoves.FindGraphNodeWithNumberOfOutEdges(2,-1);
    if GraphNode<>nil then begin
      DebugLn(['TCodeCompletionCodeTool.MovePointerTypesToTargetSections.ApplyNodeMoves inconsistency: node should be moved to several places: ',ExtractNode(GraphNode.Node,[])]);
      raise Exception.Create('TCodeCompletionCodeTool.MovePointerTypesToTargetSections.ApplyNodeMoves node should be moved to several places');
    end;
    
    // sort topologically and break all circles
    repeat
      GraphEdge:=NodeMoves.GetTopologicalSortedList(ListOfGraphNodes,true,false,true);
      if GraphEdge=nil then break;
      if ExceptionOnCircle then
        raise Exception.Create('TCodeCompletionCodeTool.MovePointerTypesToTargetSections.ApplyNodeMoves found circle: From='+ExtractNode(GraphEdge.FromNode.Node,[])+' To='+ExtractNode(GraphEdge.ToNode.Node,[]));
      DebugLn(['TCodeCompletionCodeTool.MovePointerTypesToTargetSections.ApplyNodeMoves break circle: From=',ExtractNode(GraphEdge.FromNode.Node,[]),' To=',ExtractNode(GraphEdge.ToNode.Node,[])]);
      NodeMoves.DeleteEdge(GraphEdge);
      ListOfGraphNodes.Free;
    until false;
    
    for i:=0 to ListOfGraphNodes.Count-1 do begin
      GraphNode:=TCodeGraphNode(ListOfGraphNodes[i]);
      DebugLn(['ApplyNodeMoves i=',i,' ',ExtractNode(GraphNode.Node,[]),' InFrontCnt=',GraphNode.InTreeCount,' BehindCnt=',GraphNode.OutTreeCount]);
    end;
    
    { apply changes
      the ListOfGraphNodes is sorted topologically with nodes at end must be
      moved first
      For example:
        var AnArray: array[0..EndValue] of char;
        const EndValue = TMyInteger(1);
        type TMyInteger = longint;
      Edges: TMyInteger -> AnArray
             EndValue -> AnArray
      List:
    }
    NodeMoves.ClearNodeFlags;
    for i:=ListOfGraphNodes.Count-1 downto 0 do begin
      GraphNode:=TCodeGraphNode(ListOfGraphNodes[i]);
      if GraphNode.Flags=0 then begin
        InsertPos:=FindLineEndOrCodeInFrontOfPosition(GraphNode.Node.StartPos);
        Indent:=GetLineIndent(Src,GraphNode.Node.StartPos);
        if not ApplyNodeMove(GraphNode,false,InsertPos,Indent) then exit;
      end;
    end;
    Result:=SourceChangeCache.Apply;
  end;

var
  Definitions: TAVLTree;// tree of TCodeTreeNodeExtension
  Graph: TCodeGraph;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  Node: TCodeTreeNode;
  GraphNode: TCodeGraphNode;
  RequiredAVLNode: TAVLTreeNode;
  GraphEdge: TCodeGraphEdge;
  RequiredNode: TCodeTreeNode;
  RequiredTypeNode: TCodeTreeNode;
begin
  Result:=false;
  if (SourceChangeCache=nil) or (Scanner=nil) then exit;
  NodeMoves:=nil;
  Definitions:=nil;
  Graph:=nil;
  try
    // move the pointer types to the same type sections
    if not BuildUnitDefinitionGraph(Definitions,Graph,false) then exit;
    SourceChangeCache.MainScanner:=Scanner;
    if Definitions=nil then exit(true);
    InitNodeMoves;
    
    AVLNode:=Definitions.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      Node:=NodeExt.Node;
      if (Node.Desc=ctnTypeDefinition) and (Node.FirstChild<>nil)
      and (Node.FirstChild.Desc=ctnPointerType) then begin
        // this is a pointer type
        // check if it only depends on the type nodes of a single section
        //DebugLn(['MovePointerTypesToTargetSections Pointer=',ExtractNode(Node,[])]);
        RequiredTypeNode:=nil;
        GraphNode:=Graph.GetGraphNode(Node,false);
        if GraphNode.OutTree<>nil then begin
          RequiredAVLNode:=GraphNode.OutTree.FindLowest;
          while RequiredAVLNode<>nil do begin
            GraphEdge:=TCodeGraphEdge(RequiredAVLNode.Data);
            RequiredNode:=GraphEdge.ToNode.Node;
            if (RequiredNode.Desc=ctnTypeDefinition)
            and (RequiredNode.Parent.Desc=ctnTypeSection) then begin
              //DebugLn(['MovePointerTypesToTargetSections required=',ExtractNode(RequiredNode,[])]);
              if RequiredTypeNode=nil then begin
                RequiredTypeNode:=RequiredNode;
              end
              else if RequiredTypeNode.Parent<>RequiredNode.Parent then begin
                DebugLn(['MovePointerTypesToTargetSections required nodes in different type sections']);
                RequiredTypeNode:=nil;
                break;
              end;
            end else begin
              DebugLn(['MovePointerTypesToTargetSections required nodes are not only types']);
              RequiredTypeNode:=nil;
              break;
            end;
            RequiredAVLNode:=GraphNode.OutTree.FindSuccessor(RequiredAVLNode);
          end;
        end;
        if (RequiredTypeNode<>nil) then begin
          // this pointer type depends only on the type nodes of a single type
          // section
          if (Node.Parent<>RequiredNode.Parent) then begin
            // pointer type is in other section => move
            DebugLn(['MovePointerTypesToTargetSections move Pointer=',ExtractNode(Node,[]),' Required=',ExtractNode(RequiredNode,[])]);
            AddMove(Node,RequiredNode);
          end;
        end;
      end;
      AVLNode:=Definitions.FindSuccessor(AVLNode);
    end;
    Result:=ApplyNodeMoves(false);
  finally
    DisposeAVLTree(Definitions);
    Graph.Free;
    ClearNodeMoves;
  end;
end;

function TCodeCompletionCodeTool.FixForwardDefinitions(
  SourceChangeCache: TSourceChangeCache): boolean;

  function UpdateGraph(var Definitions: TAVLTree; var Graph: TCodeGraph;
    Rebuild: boolean): boolean;
  begin
    if Definitions<>nil then begin
      DisposeAVLTree(Definitions);
    end;
    if Graph<>nil then begin
      Graph.Free;
      Graph:=nil;
    end;
    if Rebuild then
      Result:=BuildUnitDefinitionGraph(Definitions,Graph,true)
    else
      Result:=true;
  end;

  function CreateTypeSectionForCircle(CircleOfGraphNodes: TFPList;
    var Definitions: TAVLTree; var Graph: TCodeGraph): boolean;
  // CircleOfGraphNodes is a list of TCodeGraphNode that should be moved
  // to a new type section
  
    function IndexOfNode(Node: TCodeTreeNode): integer;
    begin
      Result:=CircleOfGraphNodes.Count-1;
      while (Result>=0)
      and (TCodeGraphNode(CircleOfGraphNodes[Result]).Node<>Node) do
        dec(Result);
    end;
  
  var
    i: Integer;
    GraphNode: TCodeGraphNode;
    Node: TCodeTreeNode;
    NewTxt: String;
    EndGap: TGapTyp;
    InsertPos: LongInt;
    Indent: LongInt;
    FromPos: LongInt;
    ToPos: LongInt;
  begin
    // check if whole type sections are moved and combine them
    i:=CircleOfGraphNodes.Count-1;
    while i>=0 do begin
      GraphNode:=TCodeGraphNode(CircleOfGraphNodes[i]);
      Node:=GraphNode.Node;
      if Node.Parent.Desc=ctnTypeSection then begin
        if IndexOfNode(Node.Parent)>=0 then begin
          // the whole type section of this type will be moved
          // => remove this type
          CircleOfGraphNodes.Delete(i);
        end else begin
          // check if all types of this type section will be moved
          Node:=Node.Parent.FirstChild;
          while (Node<>nil) and (IndexOfNode(Node)>=0) do
            Node:=Node.NextBrother;
          if Node=nil then begin
            // all types of this type section will be moved
            // => remove the type and add the type section instead
            CircleOfGraphNodes.Delete(i);
            CircleOfGraphNodes.Add(Graph.AddGraphNode(GraphNode.Node.Parent));
          end;
        end;
      end;
      dec(i);
    end;
  
    // create new type section
    // Note: InsertPos must be outside the types and type sections which are moved
    GraphNode:=TCodeGraphNode(CircleOfGraphNodes[0]);
    Node:=GraphNode.Node;
    if Node.Parent.Desc=ctnTypeSection then
      Node:=Node.Parent;
    InsertPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
    Indent:=GetLineIndent(Src,Node.StartPos);
    SourceChangeCache.Replace(gtEmptyLine,gtNewLine,InsertPos,InsertPos,
      GetIndentStr(Indent)+'type');
    inc(Indent,SourceChangeCache.BeautifyCodeOptions.Indent);
    // move the types
    for i:=0 to CircleOfGraphNodes.Count-1 do begin
      GraphNode:=TCodeGraphNode(CircleOfGraphNodes[i]);
      Node:=GraphNode.Node;
      if i=CircleOfGraphNodes.Count-1 then
        EndGap:=gtEmptyLine
      else
        EndGap:=gtNewLine;
      if Node.Desc=ctnTypeSection then begin
        // remove type section
        FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
        ToPos:=FindLineEndOrCodeAfterPosition(Node.EndPos,true);
        DebugLn(['CreateTypeSectionForCircle Removing type section: ',ExtractCode(FromPos,ToPos,[])]);
        SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'');
        // add all types of type section to new type section
        if Node.FirstChild<>nil then begin
          FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.FirstChild.StartPos);
          ToPos:=FindLineEndOrCodeAfterPosition(Node.LastChild.EndPos);
          NewTxt:=GetIndentStr(Indent)+ExtractCode(FromPos,ToPos,[phpWithComments]);
          DebugLn(['CreateTypeSectionForCircle Adding types: ',NewTxt]);
          SourceChangeCache.Replace(gtNewLine,EndGap,InsertPos,InsertPos,NewTxt);
        end;
      end else if Node.Desc in [ctnTypeDefinition,ctnGenericType] then begin
        // remove type
        FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
        ToPos:=FindLineEndOrCodeAfterPosition(Node.EndPos);
        DebugLn(['CreateTypeSectionForCircle Removing node: ',ExtractCode(FromPos,ToPos,[])]);
        SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'');
        // add type to new type section
        NewTxt:=GetIndentStr(Indent)+ExtractNode(Node,[phpWithComments]);
        DebugLn(['CreateTypeSectionForCircle Adding type: ',NewTxt]);
        SourceChangeCache.Replace(gtNewLine,EndGap,InsertPos,InsertPos,NewTxt);
      end else
        raise Exception.Create('inconsistency');
    end;
    // apply changes
    Result:=SourceChangeCache.Apply;
    if not Result then exit;
    // rebuild graph
    Result:=UpdateGraph(Definitions,Graph,true);
  end;

  function FixCircle(var Definitions: TAVLTree;
    var Graph: TCodeGraph; CircleNode: TCodeGraphNode): boolean;
  var
    CircleOfGraphNodes: TFPList; // list of TCodeGraphNode

    procedure RaiseCanNotFixCircle(const Msg: string);
    var
      i: Integer;
      GraphNode: TCodeGraphNode;
      s: String;
    begin
      DebugLn(['RaiseCanNotFixCircle Msg="',Msg,'"']);
      s:='Can not auto fix a circle in definitions: '+Msg;
      for i:=0 to CircleOfGraphNodes.Count-1 do begin
        GraphNode:=TCodeGraphNode(CircleOfGraphNodes[i]);
        DebugLn(['  ',i,': ',GetRedefinitionNodeText(GraphNode.Node)]);
      end;
      raise Exception.Create(s);
    end;
    
  var
    i: Integer;
    GraphNode: TCodeGraphNode;
    ParentNode: TCodeTreeNode;
    Node: TCodeTreeNode;
    NeedsMoving: Boolean;
  begin
    Result:=false;
    CircleOfGraphNodes:=nil;
    try
      // get all nodes of this CircleOfGraphNodes
      Graph.GetMaximumCircle(CircleNode,CircleOfGraphNodes);
      // check if all nodes are types
      for i:=0 to CircleOfGraphNodes.Count-1 do begin
        GraphNode:=TCodeGraphNode(CircleOfGraphNodes[i]);
        if not (GraphNode.Node.Desc in [ctnTypeDefinition,ctnGenericType])
        then begin
          RaiseCanNotFixCircle('Only types can build circles, not '+GraphNode.Node.DescAsString);
        end;
      end;
      NeedsMoving:=false;
      // check if the whole type CircleOfGraphNodes has one parent
      ParentNode:=TCodeGraphNode(CircleOfGraphNodes[0]).Node.Parent;
      for i:=1 to CircleOfGraphNodes.Count-1 do begin
        GraphNode:=TCodeGraphNode(CircleOfGraphNodes[i]);
        if GraphNode.Node.Parent<>ParentNode then begin
          DebugLn(['FixCircle circle is not yet in one type section -> needs moving']);
          NeedsMoving:=true;
          break;
        end;
      end;
      // check if the parent only contains the CircleOfGraphNodes nodes
      if not NeedsMoving then begin
        Node:=ParentNode.FirstChild;
        while Node<>nil do begin
          i:=CircleOfGraphNodes.Count-1;
          while (i>=0) and (TCodeGraphNode(CircleOfGraphNodes[i]).Node<>Node) do dec(i);
          if i<0 then begin
            DebugLn(['FixCircle circle has not yet its own type section -> needs moving']);
            NeedsMoving:=true;
            break;
          end;
          Node:=Node.NextBrother;
        end;
      end;
      
      if NeedsMoving then begin
        DebugLn(['TCodeCompletionCodeTool.FixForwardDefinitions.FixCircle moving types into one type section']);
        Result:=CreateTypeSectionForCircle(CircleOfGraphNodes,Definitions,Graph);
        exit;
      end else begin
        // remove definitions nodes and use the type section instead
        DebugLn(['FixCircle already ok']);
        Graph.CombineNodes(CircleOfGraphNodes,Graph.GetGraphNode(ParentNode,true));
      end;

    finally
      CircleOfGraphNodes.Free;
    end;
    Result:=true;
  end;
  
  function CheckCircles(var Definitions: TAVLTree;
    var Graph: TCodeGraph): boolean;
  var
    ListOfGraphNodes: TFPList;
    CircleEdge: TCodeGraphEdge;
  begin
    Result:=false;
    ListOfGraphNodes:=nil;
    try
      Graph.DeleteSelfCircles;
      repeat
        //WriteCodeGraphDebugReport(Graph);
        CircleEdge:=Graph.GetTopologicalSortedList(ListOfGraphNodes,true,false,false);
        if CircleEdge=nil then break;
        DebugLn(['FixForwardDefinitions.CheckCircles Circle found containing ',
          GetRedefinitionNodeText(CircleEdge.FromNode.Node),
          ' and ',
          GetRedefinitionNodeText(CircleEdge.ToNode.Node)]);
        if not FixCircle(Definitions,Graph,CircleEdge.FromNode) then exit;
      until false;
    finally
      ListOfGraphNodes.Free;
    end;
    Result:=true;
  end;
  
  function MoveNodes(TreeOfNodeMoveEdges: TAVLTree): boolean;
  // TreeOfNodeMoveEdges is a tree of TNodeMoveEdge
  // it is sorted for insert position (i.e. left node must be inserted
  //   in front of right node)
  
    function NodeWillBeMoved(Node: TCodeTreeNode): boolean;
    var
      AVLNode: TAVLTreeNode;
      CurMove: TNodeMoveEdge;
      GraphNode: TCodeGraphNode;
    begin
      AVLNode:=TreeOfNodeMoveEdges.FindLowest;
      while AVLNode<>nil do begin
        CurMove:=TNodeMoveEdge(AVLNode.Data);
        GraphNode:=CurMove.GraphNode;
        if GraphNode.Node=Node then exit(true);
        AVLNode:=TreeOfNodeMoveEdges.FindSuccessor(AVLNode);
      end;
      Result:=false;
    end;
    
    function GetFirstVarDefSequenceNode(Node: TCodeTreeNode): TCodeTreeNode;
    begin
      while (Node.PriorBrother<>nil) and (Node.PriorBrother.FirstChild=nil) do
        Node:=Node.PriorBrother;
      Result:=Node;
    end;

    function GetLastVarDefSequenceNode(Node: TCodeTreeNode): TCodeTreeNode;
    begin
      Result:=nil;
      while (Node<>nil) do begin
        Result:=Node;
        if (Node.FirstChild<>nil) then break;
        Node:=Node.NextBrother;
      end;
    end;

    function WholeVarDefSequenceWillBeMoved(Node: TCodeTreeNode): boolean;
    // test, if all variable definitions of a sequence will be moved
    // example: var a,b,c: integer;
    begin
      Node:=GetFirstVarDefSequenceNode(Node);
      while (Node<>nil) do begin
        if not NodeWillBeMoved(Node) then exit(false);
        if (Node.FirstChild<>nil) then break;// this is the last of the sequence
        Node:=Node.NextBrother;
      end;
      Result:=true;
    end;
    
    function WholeSectionWillBeMoved(Node: TCodeTreeNode): boolean;
    // test, if all child nodes will be moved
    begin
      Node:=Node.FirstChild;
      while (Node<>nil) do begin
        if not NodeWillBeMoved(Node) then exit(false);
        Node:=Node.NextBrother;
      end;
      Result:=true;
    end;
  
  var
    AVLNode: TAVLTreeNode;
    CurMove: TNodeMoveEdge;
    GraphNode: TCodeGraphNode;// move what
    PosGraphNode: TCodeGraphNode;// move where (in front of)
    Node: TCodeTreeNode;
    FromPos: LongInt;
    ToPos: LongInt;
    DestNode: TCodeTreeNode;
    NextAVLNode: TAVLTreeNode;
    NextMove: TNodeMoveEdge;
    NextGraphNode: TCodeGraphNode;// move what next
    NextPosGraphNode: TCodeGraphNode;// move where next (in front of)
    NextInsertAtSamePos: boolean;
    NeedSection: TCodeTreeNodeDesc;
    LastSection: TCodeTreeNodeDesc;
    LastInsertAtSamePos: boolean;
    InsertPos: LongInt;
    Indent: LongInt;
    DestSection: TCodeTreeNodeDesc;
    NewTxt: String;
    DestNodeInFront: TCodeTreeNode;
  begin
    Result:=false;
    AVLNode:=TreeOfNodeMoveEdges.FindLowest;
    LastSection:=ctnNone;
    LastInsertAtSamePos:=false;
    DestNode:=nil;
    DestSection:=ctnNone;
    // process every move
    while AVLNode<>nil do begin
      CurMove:=TNodeMoveEdge(AVLNode.Data);
      GraphNode:=CurMove.GraphNode;// move what
      PosGraphNode:=TCodeGraphNode(GraphNode.Data);// move where (in front of)
      NextAVLNode:=TreeOfNodeMoveEdges.FindSuccessor(AVLNode);
      if NextAVLNode<>nil then begin
        NextMove:=TNodeMoveEdge(NextAVLNode.Data);
        NextGraphNode:=NextMove.GraphNode;// move what next
        NextPosGraphNode:=TCodeGraphNode(NextGraphNode.Data);// move where next
        NextInsertAtSamePos:=NextPosGraphNode=PosGraphNode;
      end else begin
        NextInsertAtSamePos:=false;
      end;
      DebugLn(['MoveNodes: move ',
        GetRedefinitionNodeText(GraphNode.Node),' ',CleanPosToStr(GraphNode.Node.StartPos),
        ' (TopoLvl=',CurMove.TologicalLevel,')',
        ' in front of ',GetRedefinitionNodeText(PosGraphNode.Node),' ',CleanPosToStr(PosGraphNode.Node.StartPos)
        ]);
      Node:=GraphNode.Node;
      DestNode:=PosGraphNode.Node;
      
      // remove node
      if (Node.Parent<>nil)
      and (Node.Parent.Desc in AllDefinitionSections)
      and WholeSectionWillBeMoved(Node.Parent) then begin
        // the whole type/var/const section will be moved
        if Node.PriorBrother=nil then begin
          // this is the first node of the section
          // => remove the whole section
          FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.Parent.StartPos);
          ToPos:=FindLineEndOrCodeAfterPosition(Node.Parent.EndPos,true);
        end else begin
          // this is not the first node of the section
          // => remove nothing
          FromPos:=0;
          ToPos:=0;
        end;
      end
      else if Node.Desc=ctnVarDefinition then begin
        // removing a variable definition can be tricky, because for example
        // var a,b,c: integer;
        if Node.FirstChild<>nil then begin
          // this is the last of a sequence
          if WholeVarDefSequenceWillBeMoved(Node) then begin
            // the whole variable definition will be moved
            // and this is the last of the sequence
            // => remove the whole definition (names and type)
            FromPos:=FindLineEndOrCodeInFrontOfPosition(
                                     GetFirstVarDefSequenceNode(Node).StartPos);
            ToPos:=FindLineEndOrCodeAfterPosition(
                                   GetLastVarDefSequenceNode(Node).EndPos,true);
          end else if NodeWillBeMoved(Node.PriorBrother) then begin
            // this is for example: var a,b,c: integer
            // and only b and c will be moved. The b, plus the space behind was
            // already marked for removal
            // => remove the c and the space behind
            FromPos:=Node.StartPos;
            MoveCursorToNodeStart(Node);
            ReadNextAtom;// read identifier
            AtomIsIdentifierE;
            ToPos:=FindLineEndOrCodeAfterPosition(CurPos.EndPos,true);
          end else begin
            // this is for example: var a,b: integer
            // and only b will be moved.
            // => remove ,b plus the space behind
            MoveCursorToNodeStart(Node.PriorBrother);
            ReadNextAtom;// read identifier
            AtomIsIdentifierE;
            ReadNextAtom;// read comma
            if not AtomIsChar(',') then RaiseCharExpectedButAtomFound(',');
            FromPos:=CurPos.StartPos;
            ReadNextAtom;// read identifier
            AtomIsIdentifierE;
            ReadNextAtom;//read colon
            if not AtomIsChar(':') then RaiseCharExpectedButAtomFound(':');
            ToPos:=CurPos.StartPos;
          end;
        end else begin
          // this is not the last of a sequence
          if WholeVarDefSequenceWillBeMoved(Node) then begin
            // the whole sequence will be moved. This is done by the last node.
            // => nothing to do
            FromPos:=0;
            ToPos:=0;
          end else begin
            // remove the b,
            FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
            MoveCursorToNodeStart(Node);
            ReadNextAtom;// read identifier
            AtomIsIdentifierE;
            ReadNextAtom;// read comma
            if not AtomIsChar(',') then RaiseCharExpectedButAtomFound(',');
            ToPos:=CurPos.StartPos;
          end;
        end;
      end else begin
        // remove the whole node
        FromPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
        ToPos:=FindLineEndOrCodeAfterPosition(Node.EndPos);
      end;
      if ToPos>FromPos then begin
        DebugLn(['MoveNodes remove "',ExtractCode(FromPos,ToPos,[]),'"']);
        if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then
          exit;
      end;

      // find needed section type
      if Node.Desc in AllIdentifierDefinitions then
        NeedSection:=Node.Parent.Desc
      else
        NeedSection:=ctnNone;

      // find insert position
      if not LastInsertAtSamePos then begin
        //DebugLn(['MoveNodes LastInsertAtSamePos=false, compute destination ...']);
        if (DestNode.Desc in AllIdentifierDefinitions) then begin
          DestNode:=GetFirstVarDefSequenceNode(DestNode);
          DestSection:=DestNode.Parent.Desc;
          if DestNode.PriorBrother<>nil then begin
            // the destination is in front of a definition, but in the middle
            // of a section
            // example: type a=char; | b=byte;
            // => insert in front of destination
            //DebugLn(['MoveNodes destination is middle of a section. Node in front=',GetRedefinitionNodeText(DestNode.PriorBrother)]);
          end else begin
            // the destination is the first node of a section
            // example: type | t=char;
            if NeedSection=DestSection then begin
              // insertion needs the same section type
              // => insert in front of destination
            end else begin
              // insertion needs another section type
              // => insert in front of the section
              DestNode:=DestNode.Parent;
            end;
            //DebugLn(['MoveNodes destination is first node of a section ']);
          end;
        end else begin
          // the destination is not in a section
          // example: in front of a type section
          // => insert in front of destination
          // find the section in front
          DestNodeInFront:=DestNode.PriorBrother;
          while (DestNodeInFront<>nil) and NodeWillBeMoved(DestNodeInFront) do
            DestNodeInFront:=DestNodeInFront.PriorBrother;
          if (DestNodeInFront<>nil)
          and (DestNodeInFront.Desc in AllDefinitionSections) then
            DestSection:=DestNodeInFront.Desc
          else
            DestSection:=ctnNone;
          //DebugLn(['MoveNodes destination is not in a section']);
        end;
        InsertPos:=FindLineEndOrCodeAfterPosition(DestNode.StartPos);
        Indent:=GetLineIndent(Src,DestNode.StartPos);
        //DebugLn(['MoveNodes DestNode=',GetRedefinitionNodeText(DestNode),':',DestNode.DescAsString,' DestSection=',NodeDescToStr(DestSection)]);
      end;
      
      // start a new section if needed
      //DebugLn(['MoveNodes LastInsertAtSamePos=',LastInsertAtSamePos,' NeedSection=',NodeDescToStr(NeedSection),' LastSection=',NodeDescToStr(LastSection),' DestSection=',NodeDescToStr(DestSection)]);
      if (LastInsertAtSamePos and (NeedSection<>LastSection))
      or ((not LastInsertAtSamePos) and (NeedSection<>DestSection)) then begin
        // start a new section
        case NeedSection of
        ctnVarSection: NewTxt:='var';
        ctnConstSection: NewTxt:='const';
        ctnResStrSection: NewTxt:='resourcestring';
        ctnTypeSection: NewTxt:='type';
        ctnLabelSection: NewTxt:='label';
        else NewTxt:='';
        end;
        if NewTxt<>'' then begin
          DebugLn(['MoveNodes start new section: insert "',NewTxt,'"']);
          if not SourceChangeCache.Replace(gtEmptyLine,gtNewLine,
                                           InsertPos,InsertPos,NewTxt)
          then
            exit;
          Indent:=SourceChangeCache.BeautifyCodeOptions.Indent;
        end;
      end;

      // insert node
      if Node.Desc=ctnVarDefinition then begin
        NewTxt:=GetIdentifier(@Src[Node.StartPos]);
        MoveCursorToNodeStart(GetLastVarDefSequenceNode(Node));
        ReadNextAtom;
        AtomIsIdentifierE;
        ReadNextAtom;
        if not AtomIsChar(':') then RaiseCharExpectedButAtomFound(':');
        FromPos:=CurPos.StartPos;
        ToPos:=Node.EndPos;
        NewTxt:=NewTxt+ExtractCode(FromPos,ToPos,[phpWithComments]);
      end else begin
        FromPos:=Node.StartPos;
        ToPos:=FindLineEndOrCodeAfterPosition(Node.EndPos);
        NewTxt:=ExtractCode(FromPos,ToPos,[phpWithComments]);
      end;
      NewTxt:=GetIndentStr(Indent)+NewTxt;
      DebugLn(['MoveNodes insert "',NewTxt,'"']);
      if not SourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,
        NewTxt) then exit;

      // restore destination section if needed
      if not NextInsertAtSamePos then begin
        // this was the last insertion at this destination
        DebugLn(['MoveNodes this was the last insertion at this dest NeedSection=',NodeDescToStr(NeedSection),' DestSection=',NodeDescToStr(DestSection)]);
        if (DestNode.Desc in AllIdentifierDefinitions)
        and (NeedSection<>DestSection)
        and (DestSection in AllDefinitionSections) then begin
          // restore the section of destination
          case DestSection of
          ctnVarSection: NewTxt:='var';
          ctnConstSection: NewTxt:='const';
          ctnResStrSection: NewTxt:='resourcestring';
          ctnTypeSection: NewTxt:='type';
          ctnLabelSection: NewTxt:='label';
          else NewTxt:='';
          end;
          if NewTxt<>'' then begin
            DebugLn(['MoveNodes restore destination  section: insert "',NewTxt,'"']);
            if not SourceChangeCache.Replace(gtEmptyLine,gtNewLine,
                                             InsertPos,InsertPos,NewTxt)
            then
              exit;
          end;
        end;
      end;

      LastSection:=NeedSection;
      LastInsertAtSamePos:=NextInsertAtSamePos;
      AVLNode:=NextAVLNode;
    end;
    Result:=SourceChangeCache.Apply;
  end;

  function CheckOrder(var Definitions: TAVLTree;
    var Graph: TCodeGraph): boolean;
  // sort definitions topologically in source
  // the Graph must be acyclic
  var
    ListOfGraphNodes: TFPList;
    CircleEdge: TCodeGraphEdge;
    i: Integer;
    GraphNode: TCodeGraphNode;
    AVLNode: TAVLTreeNode;
    UsedByGraphNode: TCodeGraphNode;
    PosGraphNode: TCodeGraphNode;
    PosUsedByGraphNode: TCodeGraphNode;
    NodeMoveEdges: TAVLTree;
    NewMoveEdge: TNodeMoveEdge;
  begin
    Result:=false;
    ListOfGraphNodes:=nil;
    NodeMoveEdges:=TAVLTree.Create(@CompareNodeMoveEdges);
    try
      //WriteCodeGraphDebugReport(Graph);
      
      // create a topologically sorted list
      CircleEdge:=Graph.GetTopologicalSortedList(ListOfGraphNodes,false,true,false);
      if CircleEdge<>nil then
        raise Exception.Create('not acyclic');

      { set the GraphNode.Data to those GraphNodes leaves
        with the lowest Node.StartPos
        For example:
          var AnArray: array[0..EndValue] of char;
          const EndValue = TMyInteger(1);
          type TMyInteger = integer;
        EndValue must be moved in front of AnArray
        and TMyInteger must be moved in front of EndValue and AnArray.
        The topological list gives:
          TMyInteger
          EndValue
          AnArray
        NOTE: topological order alone can not be used,
          because unrelated definitions will be mixed somehow.
      }
      // init the destinations
      for i:=0 to ListOfGraphNodes.Count-1 do begin
        GraphNode:=TCodeGraphNode(ListOfGraphNodes[i]);
        //DebugLn(['CheckOrder ',GetRedefinitionNodeText(GraphNode.Node)]);
        GraphNode.Data:=GraphNode;
      end;
      // calculate the destinations as minimum of all dependencies
      for i:=ListOfGraphNodes.Count-1 downto 0 do begin
        GraphNode:=TCodeGraphNode(ListOfGraphNodes[i]);
        if GraphNode.InTree<>nil then begin
          AVLNode:=GraphNode.InTree.FindLowest;
          while AVLNode<>nil do begin
            UsedByGraphNode:=TCodeGraphEdge(AVLNode.Data).FromNode;
            // for example: type TMyPointer = TMyInteger;
            // GraphNode.Node is TMyInteger
            // UsedByGraphNode.Node is TMyPointer
            //DebugLn(['CheckOrder GraphNode=',GetRedefinitionNodeText(GraphNode.Node),' UsedBy=',GetRedefinitionNodeText(UsedByGraphNode.Node)]);
            PosGraphNode:=TCodeGraphNode(GraphNode.Data);
            PosUsedByGraphNode:=TCodeGraphNode(UsedByGraphNode.Data);
            if PosGraphNode.Node.StartPos>PosUsedByGraphNode.Node.StartPos then
              GraphNode.Data:=PosUsedByGraphNode;
            AVLNode:=GraphNode.InTree.FindSuccessor(AVLNode);
          end;
        end;
      end;
      // create the list of moves
      // sorted for: 1. destination position,
      //             2. topological level,
      //             3. origin position in source
      for i:=0 to ListOfGraphNodes.Count-1 do begin
        GraphNode:=TCodeGraphNode(ListOfGraphNodes[i]);
        PosGraphNode:=TCodeGraphNode(GraphNode.Data);
        if GraphNode<>PosGraphNode then begin
          DebugLn(['CheckOrder Move: ',
            GetRedefinitionNodeText(GraphNode.Node),' ',CleanPosToStr(GraphNode.Node.StartPos),
            ' TopoLvl=',GraphNode.Flags,
            ' in front of ',GetRedefinitionNodeText(PosGraphNode.Node),' ',CleanPosToStr(PosGraphNode.Node.StartPos)
            ]);
          NewMoveEdge:=TNodeMoveEdge.Create;
          NewMoveEdge.GraphNode:=GraphNode;
          NewMoveEdge.DestPos:=PosGraphNode.Node.StartPos;
          NewMoveEdge.TologicalLevel:=GraphNode.Flags;
          NewMoveEdge.SrcPos:=GraphNode.Node.StartPos;
          NodeMoveEdges.Add(NewMoveEdge);
        end;
      end;
      
      Result:=MoveNodes(NodeMoveEdges);
    finally
      DisposeAVLTree(NodeMoveEdges);
      ListOfGraphNodes.Free;
    end;
  end;
  
var
  Definitions: TAVLTree;
  Graph: TCodeGraph;
begin
  Result:=false;
  if (SourceChangeCache=nil) or (Scanner=nil) then begin
    DebugLn(['TCodeCompletionCodeTool.FixForwardDefinitions no scanner']);
    exit;
  end;
  Definitions:=nil;
  Graph:=nil;
  try
    // Workaround:
    // move the pointer types to the same type sections
    //if not MovePointerTypesToTargetSections(SourceChangeCache) then exit;
    //exit(true);
    
    if not BuildUnitDefinitionGraph(Definitions,Graph,true) then begin
      DebugLn(['TCodeCompletionCodeTool.FixForwardDefinitions BuildUnitDefinitionGraph failed']);
      exit;
    end;
    if Graph=nil then begin
      // no definitions found
      exit(true);
    end;
    SourceChangeCache.MainScanner:=Scanner;
    // fix circles
    if not CheckCircles(Definitions,Graph) then begin
      DebugLn(['TCodeCompletionCodeTool.FixForwardDefinitions CheckCircles failed']);
      exit;
    end;
    // now the graph is acyclic and nodes can be moved
    if not CheckOrder(Definitions,Graph) then begin
      DebugLn(['TCodeCompletionCodeTool.FixForwardDefinitions CheckOrder failed']);
      exit;
    end;
  finally
    UpdateGraph(Definitions,Graph,false);
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.GatherUnitDefinitions(out
  TreeOfCodeTreeNodeExt: TAVLTree;
  OnlyInterface, ExceptionOnRedefinition: boolean): boolean;
  
  procedure RaiseRedefinition(Node1, Node2: TCodeTreeNode);
  begin
    MoveCursorToNodeStart(Node1);
    RaiseException('redefinition found: '+GetRedefinitionNodeText(Node1)
      +' at '+CleanPosToStr(Node1.StartPos)
      +' and at '+CleanPosToStr(Node2.StartPos));
  end;

  procedure AddDefinition(Node: TCodeTreeNode);
  var
    NodeExt: TCodeTreeNodeExtension;
    NodeText: String;
  begin
    NodeText:=GetRedefinitionNodeText(Node);
    NodeExt:=FindCodeTreeNodeExt(TreeOfCodeTreeNodeExt,NodeText);
    if NodeExt<>nil then begin
      if NodeIsForwardProc(NodeExt.Node)
      and (not NodeIsForwardProc(Node)) then begin
        // this is the procedure body of the forward definition -> skip
        exit;
      end;
      if ExceptionOnRedefinition then
        RaiseRedefinition(NodeExt.Node,Node);
    end;
    NodeExt:=TCodeTreeNodeExtension.Create;
    NodeExt.Txt:=NodeText;
    TreeOfCodeTreeNodeExt.Add(NodeExt);
    NodeExt.Node:=Node;
  end;

var
  Node: TCodeTreeNode;
begin
  Result:=false;
  TreeOfCodeTreeNodeExt:=nil;
  if OnlyInterface then
    BuildTree(lsrImplementationStart)
  else
    BuildTree(lsrEnd);

  // find all unit identifiers (excluding sub types)
  TreeOfCodeTreeNodeExt:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  Node:=Tree.Root;
  while Node<>nil do begin
    case Node.Desc of
    ctnProcedureHead, ctnParameterList, ctnInitialization, ctnFinalization,
    ctnBeginBlock, ctnAsmBlock:
      Node:=Node.NextSkipChilds;
    ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition,ctnEnumIdentifier,
    ctnGenericType:
      begin
        // add or update definition
        AddDefinition(Node);

        if (Node.Desc=ctnTypeDefinition)
        and (Node.FirstChild<>nil)
        and (Node.FirstChild.Desc=ctnEnumerationType) then
          Node:=Node.FirstChild
        else
          Node:=Node.NextSkipChilds;
      end;
    ctnProcedure:
      begin
        AddDefinition(Node);
        Node:=Node.NextSkipChilds;
      end;
    else
      if OnlyInterface and (Node.Desc=ctnImplementation) then
        break;
      Node:=Node.Next;
    end;
  end;
  
  Result:=true;
end;

function TCodeCompletionCodeTool.BuildUnitDefinitionGraph(out
  DefinitionsTreeOfCodeTreeNodeExt: TAVLTree; out Graph: TCodeGraph;
  OnlyInterface: boolean): boolean;
  
  procedure CheckRange(Node: TCodeTreeNode; FromPos, ToPos: integer);
  // search the range for defined identifiers
  // and add edges to graph
  var
    Identifier: PChar;
    NodeExt: TCodeTreeNodeExtension;
  begin
    if (FromPos>=ToPos) or (FromPos<1) then exit;
    //DebugLn(['CheckRange Range="',dbgstr(Src[FromPos..ToPos-1]),'"']);
    MoveCursorToCleanPos(FromPos);
    repeat
      ReadNextAtom;
      if (CurPos.StartPos>=ToPos) or (CurPos.StartPos>SrcLen) then break;
      if AtomIsIdentifier then begin
        Identifier:=@Src[CurPos.StartPos];
        NodeExt:=FindCodeTreeNodeExtWithIdentifier(
                                     DefinitionsTreeOfCodeTreeNodeExt,
                                     Identifier);
        if NodeExt<>nil then begin
          if Graph=nil then
            Graph:=TCodeGraph.Create;
          //if Graph.GetEdge(Node,NodeExt.Node,false)=nil then
          //  DebugLn(['CheckRange AddEdge: ',GetRedefinitionNodeText(Node),' uses ',GetRedefinitionNodeText(NodeExt.Node)]);
          Graph.AddEdge(Node,NodeExt.Node);
        end;
      end;
    until false;
  end;
  
  procedure CheckSubNode(Node, SubNode: TCodeTreeNode);
  var
    ProcHead: TCodeTreeNode;
    ParamList: TCodeTreeNode;
    ChildNode: TCodeTreeNode;
    FunctionResult: TCodeTreeNode;
  begin
    //DebugLn(['CheckSubNode ',GetRedefinitionNodeText(Node),' ',GetRedefinitionNodeText(SubNode)]);
    case SubNode.Desc of
    
    ctnTypeDefinition,ctnVarDefinition,ctnGenericType,ctnConstDefinition:
      begin
        ChildNode:=FindTypeNodeOfDefinition(SubNode);
        if ChildNode<>nil then begin
          CheckSubNode(Node,ChildNode);
        end else if SubNode.Desc=ctnConstDefinition then begin
          CheckRange(Node,ChildNode.StartPos,SubNode.EndPos);
        end;
      end;
      
    ctnProcedure:
      begin
        BuildSubTreeForProcHead(SubNode,FunctionResult);
        ProcHead:=SubNode.FirstChild;
        ParamList:=ProcHead.FirstChild;
        if ParamList<>nil then begin
          ChildNode:=ParamList.FirstChild;
          while ChildNode<>nil do begin
            if (ChildNode.Desc=ctnVarDefinition) and (ChildNode.FirstChild<>nil)
            then begin
              CheckRange(Node,ChildNode.FirstChild.StartPos,ChildNode.EndPos);
            end;
            ChildNode:=ChildNode.NextBrother;
          end;
        end;
        if FunctionResult<>nil then begin
          CheckRange(Node,FunctionResult.StartPos,
                     FunctionResult.StartPos
                     +GetIdentLen(@Src[FunctionResult.StartPos]));
        end;
      end;

    ctnClassInterface, ctnDispinterface, ctnClass, ctnObject, ctnRecordType,
    ctnObjCClass, ctnObjCCategory, ctnObjCProtocol, ctnCPPClass:
      begin
        ChildNode:=SubNode.FirstChild;
        while (ChildNode<>nil) and (ChildNode.HasAsParent(SubNode)) do begin
          if ChildNode.Desc in AllIdentifierDefinitions then begin
            CheckSubNode(Node,ChildNode);
            ChildNode:=ChildNode.NextSkipChilds;
          end else
            ChildNode:=ChildNode.Next;
        end;
      end;
      
    else
      CheckRange(Node,SubNode.StartPos,SubNode.Parent.EndPos);
    end;
  end;
  
var
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  Node: TCodeTreeNode;
begin
  Result:=false;
  DefinitionsTreeOfCodeTreeNodeExt:=nil;
  Graph:=nil;
  if not GatherUnitDefinitions(DefinitionsTreeOfCodeTreeNodeExt,false,true) then
  begin
    DebugLn(['TCodeCompletionCodeTool.BuildUnitDefinitionGraph GatherUnitDefinitions failed']);
    exit;
  end;
  if DefinitionsTreeOfCodeTreeNodeExt=nil then exit(true);
  
  AVLNode:=DefinitionsTreeOfCodeTreeNodeExt.FindLowest;
  while AVLNode<>nil do begin
    NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
    Node:=NodeExt.Node;
    CheckSubNode(Node,Node);
    AVLNode:=DefinitionsTreeOfCodeTreeNodeExt.FindSuccessor(AVLNode);
  end;

  Result:=true;
end;

procedure TCodeCompletionCodeTool.WriteCodeGraphDebugReport(Graph: TCodeGraph);

  function NodeToStr(Node: TCodeTreeNode): string;
  begin
    case Node.Desc of
    ctnProcedure:
      Result:=ExtractProcHead(Node,[phpInUpperCase,phpWithoutSemicolon]);
    ctnVarDefinition,ctnConstDefinition,ctnTypeDefinition,ctnEnumIdentifier,
    ctnGenericType:
      Result:=ExtractDefinitionName(Node);
    else
      Result:=Node.DescAsString;
    end;
    Result:=Result+'{'+CleanPosToStr(Node.StartPos)+'}';
  end;

var
  AVLNode: TAVLTreeNode;
  GraphNode: TCodeGraphNode;
  Node: TCodeTreeNode;
  Cnt: LongInt;
  EdgeAVLNode: TAVLTreeNode;
  Edge: TCodeGraphEdge;
begin
  DebugLn(['TCodeCompletionCodeTool.WriteCodeGraphDebugReport ',DbgSName(Graph),
    ' NodeCount=',Graph.Nodes.Count,
    ' EdgeCount=',Graph.Edges.Count]);
  Graph.ConsistencyCheck;
  AVLNode:=Graph.Nodes.FindLowest;
  while AVLNode<>nil do begin
    GraphNode:=TCodeGraphNode(AVLNode.Data);
    Node:=GraphNode.Node;
    DebugLn(['  ',NodeToStr(Node),' needs ',GraphNode.OutTreeCount,' definitions, is used by ',GraphNode.InTreeCount,' definitions.']);
    if GraphNode.OutTreeCount>0 then begin
      DbgOut('    Needs:');
      EdgeAVLNode:=GraphNode.OutTree.FindLowest;
      Cnt:=0;
      while EdgeAVLNode<>nil do begin
        inc(Cnt);
        if Cnt=5 then begin
          DbgOut(' ...');
          break;
        end;
        Edge:=TCodeGraphEdge(EdgeAVLNode.Data);
        DbgOut(' '+NodeToStr(Edge.ToNode.Node));
        EdgeAVLNode:=GraphNode.OutTree.FindSuccessor(EdgeAVLNode);
      end;
      DebugLn;
    end;
    if GraphNode.InTreeCount>0 then begin
      DbgOut('    Used by:');
      EdgeAVLNode:=GraphNode.InTree.FindLowest;
      Cnt:=0;
      while EdgeAVLNode<>nil do begin
        inc(Cnt);
        if Cnt=5 then begin
          DbgOut(' ...');
          break;
        end;
        Edge:=TCodeGraphEdge(EdgeAVLNode.Data);
        DbgOut(' '+NodeToStr(Edge.FromNode.Node));
        EdgeAVLNode:=GraphNode.InTree.FindSuccessor(EdgeAVLNode);
      end;
      DebugLn;
    end;
    AVLNode:=Graph.Nodes.FindSuccessor(AVLNode);
  end;
end;

function TCodeCompletionCodeTool.FindEmptyMethods(CursorPos: TCodeXYPosition;
  const AClassName: string; const Sections: TPascalClassSections;
  ListOfPCodeXYPosition: TFPList; out AllEmpty: boolean): boolean;
var
  ProcBodyNodes: TAVLTree;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  Caret: TCodeXYPosition;
  CaretP: PCodeXYPosition;
begin
  Result:=false;
  ProcBodyNodes:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  try
    Result:=FindEmptyMethods(CursorPos,AClassName,Sections,ProcBodyNodes,AllEmpty);
    if Result then begin
      AVLNode:=ProcBodyNodes.FindLowest;
      while AVLNode<>nil do begin
        NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        if CleanPosToCaret(NodeExt.Node.StartPos,Caret) then begin
          New(CaretP);
          CaretP^:=Caret;
          ListOfPCodeXYPosition.Add(CaretP);
        end;
        AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
      end;
    end;
  finally
    DisposeAVLTree(ProcBodyNodes);
  end;
end;

function TCodeCompletionCodeTool.FindEmptyMethods(CursorPos: TCodeXYPosition;
  const AClassName: string; const Sections: TPascalClassSections;
  CodeTreeNodeExtensions: TAVLTree;
  out AllEmpty: boolean): boolean;
// NodeExt.Node is the body node
// NodeExt.Data is the definition node
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  TypeSectionNode: TCodeTreeNode;
  ProcBodyNodes, ClassProcs: TAVLTree;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  NextAVLNode: TAVLTreeNode;
  DefAVLNode: TAVLTreeNode;
  DefNodeExt: TCodeTreeNodeExtension;
  Desc: TCodeTreeNodeDesc;
  Fits: Boolean;
  s: TPascalClassSection;
  
  procedure GatherClassProcs;
  var
    PublishedMethods: TFPList;
  begin
    // gather existing proc definitions in the class
    if ClassProcs=nil then begin
      PublishedMethods:=nil;
      try
        {$IFDEF EnableInheritedEmptyMethods}
        DebugLn(['GatherClassProcs EnableInheritedEmptyMethods']);
        GatherPublishedMethods(FCompletingStartNode,PublishedMethods);
        {$ENDIF}
      finally
        FreeListOfPFindContext(PublishedMethods);
      end;
      ClassProcs:=GatherProcNodes(FCompletingStartNode,
         [phpInUpperCase,phpAddClassName],
         ExtractClassName(CodeCompleteClassNode,true));
    end;
  end;
  
begin
  Result:=false;
  AllEmpty:=false;
  if (AClassName<>'') and (CursorPos.Y<1) then begin
    BuildTree(lsrEnd);
    CursorNode:=FindClassNodeInInterface(AClassName,true,false,true);
    CodeCompleteClassNode:=CursorNode;
  end else begin
    BuildTreeAndGetCleanPos(CursorPos,CleanCursorPos);
    CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
    CodeCompleteClassNode:=FindClassNode(CursorNode);
  end;
  if CodeCompleteClassNode=nil then begin
    DebugLn(['TCodeCompletionCodeTool.FindEmptyMethods no class at ',Dbgs(CursorPos)]);
    exit;
  end;
  ProcBodyNodes:=nil;
  ClassProcs:=nil;
  try
    // gather body nodes
    TypeSectionNode:=CodeCompleteClassNode.GetTopMostNodeOfType(ctnTypeSection);
    ProcBodyNodes:=GatherProcNodes(TypeSectionNode,
                        [phpInUpperCase,phpIgnoreForwards,phpOnlyWithClassname],
                         ExtractClassName(CodeCompleteClassNode,true));
    // collect all emtpy bodies
    AVLNode:=ProcBodyNodes.FindLowest;
    while AVLNode<>nil do begin
      NextAVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      //DebugLn(['TCodeCompletionCodeTool.FindEmptyMethods ',NodeExt.Txt,' ',ProcBodyIsEmpty(NodeExt.Node)]);
      // check if proc body is empty (no code, no comments)
      if ProcBodyIsEmpty(NodeExt.Node) then begin
        GatherClassProcs;
        // search the corresponding node in the class
        DefAVLNode:=ClassProcs.Find(NodeExt);
        if (DefAVLNode<>nil) then begin
          DefNodeExt:=TCodeTreeNodeExtension(DefAVLNode.Data);
          // check visibility section
          if (DefNodeExt.Node.Parent<>nil) then begin
            Desc:=DefNodeExt.Node.Parent.Desc;
            Fits:=false;
            for s:=Low(TPascalClassSection) to High(TPascalClassSection) do
              if (s in Sections) and (PascalClassSectionToNodeDesc[s]=Desc) then
                Fits:=true;
            if Fits then begin
              // empty and right section => add to tree
              ProcBodyNodes.Delete(AVLNode);
              NodeExt.Data:=DefNodeExt.Node;
              CodeTreeNodeExtensions.Add(NodeExt);
            end;
          end;
        end;
      end;
      AVLNode:=NextAVLNode;
    end;
    AllEmpty:=ProcBodyNodes.Count=0;
    Result:=true;
  finally
    DisposeAVLTree(ClassProcs);
    DisposeAVLTree(ProcBodyNodes);
  end;
end;

function TCodeCompletionCodeTool.RemoveEmptyMethods(CursorPos: TCodeXYPosition;
  const AClassName: string; const Sections: TPascalClassSections;
  SourceChangeCache: TSourceChangeCache;
  out AllRemoved: boolean;
  const Attr: TProcHeadAttributes; out RemovedProcHeads: TStrings): boolean;
var
  ProcBodyNodes: TAVLTree;
  AVLNode: TAVLTreeNode;
  NodeExt: TCodeTreeNodeExtension;
  FirstNodeExt: TCodeTreeNodeExtension;
  LastNodeExt: TCodeTreeNodeExtension;
  FromPos: LongInt;
  ToPos: LongInt;
  FirstGroup: Boolean;
  CommentEndPos: integer;
  CommentStartPos: integer;
  ProcDefNodes: TAVLTree;
  NextAVLNode: TAVLTreeNode;
  ProcHead: String;
begin
  Result:=false;
  AllRemoved:=false;
  RemovedProcHeads:=nil;
  if (SourceChangeCache=nil) or (Scanner=nil) then exit;
  SourceChangeCache.MainScanner:=Scanner;
  ProcDefNodes:=nil;
  ProcBodyNodes:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  try
    Result:=FindEmptyMethods(CursorPos,AClassName,Sections,ProcBodyNodes,AllRemoved);
    if Result and (ProcBodyNodes<>nil) and (ProcBodyNodes.Count>0) then begin
      // sort the nodes for position
      ProcBodyNodes.OnCompare:=@CompareCodeTreeNodeExtWithPos;
      ProcDefNodes:=TAVLTree.Create(@CompareCodeTreeNodeExtWithPos);
      
      // delete bodies
      AVLNode:=ProcBodyNodes.FindLowest;
      FirstGroup:=true;
      while AVLNode<>nil do begin
        // gather a group of continuous proc nodes
        FirstNodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        LastNodeExt:=FirstNodeExt;
        AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
        while (AVLNode<>nil) do begin
          NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
          if NodeExt.Node<>LastNodeExt.Node.NextBrother then break;
          LastNodeExt:=NodeExt;
          AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
        end;
        // delete group
        FromPos:=FindLineEndOrCodeInFrontOfPosition(FirstNodeExt.Node.StartPos,true);
        ToPos:=FindLineEndOrCodeAfterPosition(LastNodeExt.Node.EndPos,true);
        {$IFDEF VerboseBug16168}
        debugln(['TCodeCompletionCodeTool.RemoveEmptyMethods ',dbgstr(copy(Src,FromPos,ToPos-FromPos))]);
        {$ENDIF}
        if AllRemoved and FirstGroup
        and FindClassMethodsComment(FromPos,CommentStartPos,CommentEndPos) then begin
          // all method bodies will be removed => remove the default comment too
          if FindNextNonSpace(Src,CommentEndPos)>=FromPos then begin
            // the default comment is directly in front
            // => remove it too
            FromPos:=FindLineEndOrCodeInFrontOfPosition(CommentStartPos,true);
          end;
        end;
        if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then
          exit;
        FirstGroup:=false;
      end;
      
      // create the tree of proc definitions: ProcDefNodes
      AVLNode:=ProcBodyNodes.FindLowest;
      while AVLNode<>nil do begin
        NextAVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
        NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        // remove NodeExt from ProcBodyNodes
        ProcBodyNodes.Delete(AVLNode);
        // and add it to ProcDefNodes
        // the definition node is the Data
        // Note: the class can contain errors and therefore some method bodies
        // refer to the same definition => skip doubles
        NodeExt.Node:=TCodeTreeNode(NodeExt.Data);
        NodeExt.Position:=NodeExt.Node.StartPos;
        if (NodeExt.Node<>nil) and (ProcDefNodes.Find(NodeExt)=nil) then begin
          ProcDefNodes.Add(NodeExt);
          if RemovedProcHeads=nil then
            RemovedProcHeads:=TStringList.Create;
          ProcHead:=ExtractProcHead(NodeExt.Node,Attr);
          RemovedProcHeads.Add(ProcHead);
        end else begin
          NodeExt.Free;
        end;
        AVLNode:=NextAVLNode;
      end;
      
      // delete definitions
      AVLNode:=ProcDefNodes.FindLowest;
      while AVLNode<>nil do begin
        // gather a group of continuous proc nodes
        FirstNodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
        LastNodeExt:=FirstNodeExt;
        AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
        while (AVLNode<>nil) do begin
          NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
          if NodeExt.Node<>LastNodeExt.Node.NextBrother then break;
          LastNodeExt:=NodeExt;
          AVLNode:=ProcBodyNodes.FindSuccessor(AVLNode);
        end;
        // delete group
        FromPos:=FindLineEndOrCodeInFrontOfPosition(FirstNodeExt.Node.StartPos,true);
        ToPos:=FindLineEndOrCodeAfterPosition(LastNodeExt.Node.EndPos,true);
        if not SourceChangeCache.Replace(gtNone,gtNone,FromPos,ToPos,'') then
          exit;
      end;
    end;
    Result:=SourceChangeCache.Apply;
  finally
    DisposeAVLTree(ProcBodyNodes);
    DisposeAVLTree(ProcDefNodes);
  end;
end;

function TCodeCompletionCodeTool.FindAssignMethod(CursorPos: TCodeXYPosition;
  out ClassNode: TCodeTreeNode; out AssignDeclNode: TCodeTreeNode;
  var MemberNodeExts: TAVLTree; out AssignBodyNode: TCodeTreeNode;
  out InheritedDeclContext: TFindContext;
  ProcName: string): boolean;
{ if CursorPos is in a class declaration search for a method "Assign"
  and its corresponding body.
  If CursorPos is in a method body use this as a Assign method and return
  its corresponding declararion.
  If neither return false.
  Also return a tree of all variables and properties (excluding ancestors).
}

  procedure SearchAssign(Tool: TFindDeclarationTool; Node: TCodeTreeNode;
    var DeclNode: TCodeTreeNode);
  var
    Child: TCodeTreeNode;
    CurProcName: String;
  begin
    if Node=nil then exit;
    Child:=Node.FirstChild;
    while Child<>nil do begin
      if Child.Desc in AllClassSections then
        SearchAssign(Tool,Child,DeclNode)
      else if Child.Desc=ctnProcedure then begin
        CurProcName:=Tool.ExtractProcName(Child,[]);
        if CompareIdentifiers(PChar(CurProcName),PChar(ProcName))=0 then begin
          if DeclNode<>nil then begin
            debugln(['WARNING: TCodeCompletionCodeTool.FindAssignMethod.SearchAssign'
              +' multiple ',ProcName,' methods found, using the first at ',CleanPosToStr(DeclNode.StartPos)]);
          end else
            DeclNode:=Child;
        end;
      end;
      Child:=Child.NextBrother;
    end;
  end;

  procedure GatherAssignableMembers(Node: TCodeTreeNode);
  var
    Child: TCodeTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    if Node=nil then exit;
    Child:=Node.FirstChild;
    while Child<>nil do begin
      if Child.Desc in AllClassSections then
        GatherAssignableMembers(Child)
      else if (Child.Desc=ctnVarDefinition)
      or ((Child.Desc=ctnProperty)
        and (PropertyHasSpecifier(Child,'read'))
        and (PropertyHasSpecifier(Child,'write')))
      then begin
        // a variable or a property which is readable and writable
        if MemberNodeExts=nil then
          MemberNodeExts:=TAVLTree.Create(@CompareCodeTreeNodeExtTxtAndPos);
        NodeExt:=TCodeTreeNodeExtension.Create;
        NodeExt.Node:=Child;
        NodeExt.Position:=Child.StartPos;
        if Child.Desc=ctnVarDefinition then
          NodeExt.Txt:=ExtractDefinitionName(Child)
        else
          NodeExt.Txt:=ExtractPropName(Child,false);
        MemberNodeExts.Add(NodeExt);
      end;

      Child:=Child.NextBrother;
    end;
  end;

  procedure FindVarsWrittenByProperties;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
    WrittenNodeExt: TCodeTreeNodeExtension;
  begin
    if MemberNodeExts=nil then exit;
    AVLNode:=MemberNodeExts.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Node.Desc=ctnProperty then begin
        if PropertyHasSpecifier(NodeExt.Node,'write') then begin
          ReadNextAtom;
          if AtomIsIdentifier then begin
            WrittenNodeExt:=FindCodeTreeNodeExtWithIdentifier(MemberNodeExts,
                                      @Src[CurPos.StartPos]);
            if WrittenNodeExt<>nil then
              WrittenNodeExt.Data:=NodeExt.Node;
          end;
        end;
      end;
      AVLNode:=MemberNodeExts.FindSuccessor(AVLNode);
    end;
  end;

  procedure FindInheritedAssign;
  var
    Params: TFindDeclarationParams;
  begin
    if ClassNode=nil then exit;
    Params:=TFindDeclarationParams.Create;
    try
      Params.Flags:=[fdfSearchInAncestors];
      Params.Identifier:=PChar(ProcName);
      Params.ContextNode:=ClassNode;
      if not FindIdentifierInContext(Params) then exit;
      //debugln(['FindInheritedAssign NewNode=',Params.NewNode.DescAsString]);
      if Params.NewNode=nil then exit;
      if Params.NewNode.Desc<>ctnProcedure then exit;
      InheritedDeclContext:=CreateFindContext(Params);
    finally
      Params.Free;
    end;
  end;

var
  CleanPos: integer;
  CursorNode: TCodeTreeNode;
  Node: TCodeTreeNode;
begin
  Result:=false;
  ClassNode:=nil;
  AssignDeclNode:=nil;
  AssignBodyNode:=nil;
  InheritedDeclContext:=CleanFindContext;
  BuildTreeAndGetCleanPos(CursorPos,CleanPos);
  if ProcName='' then ProcName:='Assign';
  // check context
  CursorNode:=FindDeepestNodeAtPos(CleanPos,true);
  Node:=CursorNode;
  while (Node<>nil) do begin
    if (Node.Desc=ctnProcedure) then begin
      if NodeIsMethodBody(Node) then begin
        // cursor in method body
        AssignBodyNode:=Node;
        Result:=true;
        AssignDeclNode:=FindCorrespondingProcNode(AssignBodyNode);
        if AssignDeclNode<>nil then
          ClassNode:=FindClassOrInterfaceNode(AssignDeclNode.Parent);
        break;
      end;
    end else if (Node.Desc in AllClassObjects) then begin
      // cursor in class/record
      Result:=true;
      ClassNode:=Node;
      SearchAssign(Self,ClassNode,AssignDeclNode);
      if AssignDeclNode<>nil then
        AssignBodyNode:=FindCorrespondingProcNode(AssignDeclNode);
      break;
    end;
    Node:=Node.Parent;
  end;
  if ClassNode=nil then exit;
  GatherAssignableMembers(ClassNode);
  FindVarsWrittenByProperties;
  FindInheritedAssign;
end;

function TCodeCompletionCodeTool.AddAssignMethod(ClassNode: TCodeTreeNode;
  MemberNodeExts: TFPList; const ProcName, ParamName, ParamType: string;
  OverrideMod, CallInherited, CallInheritedOnlyInElse: boolean;
  SourceChanger: TSourceChangeCache; out NewPos: TCodeXYPosition;
  out NewTopLine: integer; LocalVarName: string): boolean;
var
  NodeExt: TCodeTreeNodeExtension;
  CleanDef: String;
  Def: String;
  aClassName: String;
  ProcBody: String;
  e: String;
  SameType: boolean;
  Indent: Integer;
  IndentStep: LongInt;
  SrcVar: String;
  i: Integer;
begin
  Result:=false;
  NewPos:=CleanCodeXYPosition;
  NewTopLine:=-1;
  if ClassNode=nil then exit;
  if (ParamName='') or (ParamType='') then exit;
  aClassName:=ExtractClassName(ClassNode,false);
  CleanDef:=ProcName+'('+ParamType+');';
  Def:='procedure '+ProcName+'('+ParamName+':'+ParamType+');';
  if OverrideMod then Def:=Def+'override;';
  SrcVar:=ParamName;
  // create the proc header
  SameType:=CompareIdentifiers(PChar(aClassName),PChar(ParamType))=0;
  e:=SourceChanger.BeautifyCodeOptions.LineEnd;
  Indent:=0;
  IndentStep:=SourceChanger.BeautifyCodeOptions.Indent;
  ProcBody:='procedure '+aClassName+'.'+ProcName+'('+ParamName+':'+ParamType+');'+e;
  if not SameType then begin
    // add local variable
    SrcVar:=LocalVarName;
    if SrcVar='' then
      SrcVar:='aSource';
    if CompareIdentifiers(PChar(SrcVar),PChar(ParamName))=0 then begin
      if CompareIdentifiers(PChar(SrcVar),'aSource')=0 then
        SrcVar:='aSrc'
      else
        SrcVar:='aSource';
    end;
    ProcBody:=ProcBody+'var'+e
       +GetIndentStr(Indent+IndentStep)+SrcVar+':'+aClassName+';'+e;
  end;
  ProcBody:=ProcBody+'begin'+e;
  inc(Indent,IndentStep);

  // call inherited
  if CallInherited and (not CallInheritedOnlyInElse) then
    ProcBody:=ProcBody
      +GetIndentStr(Indent)+'inherited '+ProcName+'('+ParamName+');'+e;

  if not SameType then begin
    // add a parameter check to the new procedure
    ProcBody:=ProcBody
        +GetIndentStr(Indent)+'if '+ParamName+' is '+aClassName+' then'+e
        +GetIndentStr(Indent)+'begin'+e;
    inc(Indent,IndentStep);
    ProcBody:=ProcBody+GetIndentStr(Indent)+SrcVar+':='+aClassName+'('+ParamName+');'+e;
  end;

  // add assignments
  if MemberNodeExts<>nil then begin
    for i:=0 to MemberNodeExts.Count-1 do begin
      NodeExt:=TCodeTreeNodeExtension(MemberNodeExts[i]);
      // add assignment
      ProcBody:=ProcBody+GetIndentStr(Indent)+NodeExt.Txt+':='+SrcVar+'.'+NodeExt.Txt+';'+e;
    end;
  end;

  if not SameType then begin
    // close if block
    dec(Indent,IndentStep);
    if CallInherited and CallInheritedOnlyInElse then begin
      ProcBody:=ProcBody+GetIndentStr(Indent)+'end else'+e
          +GetIndentStr(Indent+IndentStep)+'inherited '+ProcName+'('+ParamName+');'+e;
    end else begin
      ProcBody:=ProcBody+GetIndentStr(Indent)+'end;'+e
    end;
  end;
  // close procedure body
  ProcBody:=ProcBody+'end;';

  if not InitClassCompletion(ClassNode,SourceChanger) then exit;
  ProcBody:=SourceChanger.BeautifyCodeOptions.BeautifyStatement(ProcBody,0);
  AddClassInsertion(CleanDef,Def,ProcName,ncpPublicProcs,nil,ProcBody);
  Result:=ApplyChangesAndJumpToFirstNewProc(ClassNode.StartPos,1,true,
                   NewPos,NewTopLine);
end;

function TCodeCompletionCodeTool.GuessTypeOfIdentifier(
  CursorPos: TCodeXYPosition; out IsKeyword, IsSubIdentifier: boolean;
  out ExistingDefinition: TFindContext; out ListOfPFindContext: TFPList;
  out NewExprType: TExpressionType; out NewType: string): boolean;
{ examples:
   identifier:=<something>
   aclass.identifier:=<something>
   <something>:=aclass.identifier
   <something>:=<something>+aclass.identifier
   <proc>(,,aclass.identifier)
   for identifier in <something>

 checks where the identifier is already defined
 checks if the identifier is a sub identifier (e.g. A.identifier)
 creates the list of possible locations and notes
 checks if it is the target of an assignment and guess the type
 checks if it is the source of an for in and guess the type
 ToDo: checks if it is the target of an assignment and guess the type
 ToDo: checks if it is a parameter and guess the type
}
var
  CleanCursorPos: integer;
  Params: TFindDeclarationParams;
  CursorNode: TCodeTreeNode;
  IdentifierAtom: TAtomPosition;
  TermAtom: TAtomPosition;
  i: Integer;
  Context: PFindContext;
  Section: TCodeTreeNode;
  ExistingNodeInProc: Boolean;
  Keep: Boolean;
  InAtomEndPos: Integer;
begin
  Result:=false;
  IsKeyword:=false;
  IsSubIdentifier:=false;
  ExistingDefinition:=CleanFindContext;
  ListOfPFindContext:=nil;
  NewExprType:=CleanExpressionType;
  NewType:='';
  BuildTreeAndGetCleanPos(CursorPos, CleanCursorPos);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

  // find identifier name
  GetIdentStartEndAtPosition(Src,CleanCursorPos,
    IdentifierAtom.StartPos,IdentifierAtom.EndPos);
  debugln('TCodeCompletionCodeTool.GuessTypeOfIdentifier A Atom=',GetAtom(IdentifierAtom),' "',dbgstr(Src,CleanCursorPos,10),'"');
  if IdentifierAtom.StartPos=IdentifierAtom.EndPos then exit;
  Result:=true;

  MoveCursorToAtomPos(IdentifierAtom);
  if AtomIsKeyWord then begin
    debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier is keyword: ',GetAtom]);
    IsKeyword:=true;
    exit;
  end;

  // search identifier
  ActivateGlobalWriteLock;
  try
    Params:=TFindDeclarationParams.Create;
    try
      {$IFDEF CTDEBUG}
      DebugLn('  GuessTypeOfIdentifier: check if variable is already defined ...');
      {$ENDIF}
      // check if identifier exists
      Result:=IdentifierIsDefined(IdentifierAtom,CursorNode,Params);
      if Result then begin
        // identifier is already defined
        ExistingDefinition.Tool:=Params.NewCodeTool;
        ExistingDefinition.Node:=Params.NewNode;
        debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier identifier already defined at ',FindContextToString(ExistingDefinition)]);
      end;
    finally
      Params.Free;
    end;

    // find all possible contexts
    if not FindIdentifierContextsAtStatement(IdentifierAtom.StartPos,
      IsSubIdentifier,ListOfPFindContext)
    then begin
      debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier FindIdentifierContextsAtStatement failed']);
      exit;
    end;

    // remove contexts conflicting with the already defined identifier
    if (ExistingDefinition.Node<>nil) and (ListOfPFindContext<>nil) then begin
      Section:=ExistingDefinition.Node;
      while Section<>nil do begin
        if Section.Desc in AllDefinitionSections then break;
        Section:=Section.Parent;
      end;
      ExistingNodeInProc:=ExistingDefinition.Node.HasParentOfType(ctnProcedure);
      if Section<>nil then begin
        for i:=ListOfPFindContext.Count-1 downto 0 do begin
          Context:=PFindContext(ListOfPFindContext[i]);
          Keep:=true;
          if ExistingNodeInProc then begin
            if (Context^.Tool<>ExistingDefinition.Tool)
            or (Context^.Node.StartPos<=ExistingDefinition.Node.StartPos) then
              Keep:=false; // existing is local var => delete all outside
          end;

          if Keep
          and (Context^.Tool=ExistingDefinition.Tool)
          and (((ExistingDefinition.Node=Context^.Node)
              or ExistingDefinition.Node.HasAsParent(Context^.Node)))
          then begin
            // context is outside or same as existing context
            // (e.g. identifier is already defined in the class) => delete
            Keep:=false;
          end;
          if Keep then continue;
          Dispose(Context);
          ListOfPFindContext.Delete(i);
        end;
      end;
    end;

    // find assignment operator
    MoveCursorToAtomPos(IdentifierAtom);
    ReadNextAtom;
    if AtomIs(':=') then begin
      // is assignment
      //AssignmentOperator:=CurPos;

      // find term
      ReadNextAtom;
      TermAtom.StartPos:=CurPos.StartPos;
      TermAtom.EndPos:=FindEndOfExpression(TermAtom.StartPos);
      if TermAtom.StartPos=TermAtom.EndPos then begin
        debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier nothing behind := operator']);
        exit;
      end;
      debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier guessing type of assignment :="',dbgstr(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos),'"']);

      // find type of term
      Params:=TFindDeclarationParams.Create;
      try
        Params.ContextNode:=CursorNode;
        NewType:=FindTermTypeAsString(TermAtom,Params,NewExprType);
      finally
        Params.Free;
      end;
      debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier Assignment type=',NewType]);
      Result:=true;
    end;

    if not Result then begin
      MoveCursorToAtomPos(IdentifierAtom);
      // find 'in' operator
      ReadNextAtom;
      if UpAtomIs('IN') then begin
        InAtomEndPos:=CurPos.EndPos;

        // find 'for' keyword
        MoveCursorToCleanPos(IdentifierAtom.StartPos);
        ReadPriorAtom;
        if not UpAtomIs('FOR') then exit;

        // find term
        MoveCursorToCleanPos(InAtomEndPos);
        ReadNextAtom;
        TermAtom.StartPos:=CurPos.StartPos;
        TermAtom.EndPos:=FindEndOfExpression(TermAtom.StartPos);

        debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier guessing type of for-in list "',dbgstr(Src,TermAtom.StartPos,TermAtom.EndPos-TermAtom.StartPos),'"']);
        // find type of term
        Params:=TFindDeclarationParams.Create;
        try
          NewType:=FindForInTypeAsString(TermAtom,CursorNode,Params,NewExprType);
        finally
          Params.Free;
        end;
        debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier For-In type=',NewType]);
        Result:=true;
      end;
    end;

    if not Result then begin
      debugln(['TCodeCompletionCodeTool.GuessTypeOfIdentifier can not guess type']);
      exit;
    end;

  finally
    DeactivateGlobalWriteLock;
  end;
end;

function TCodeCompletionCodeTool.DeclareVariableNearBy(
  InsertPos: TCodeXYPosition; const VariableName, NewType, NewUnitName: string;
  Visibility: TCodeTreeNodeDesc; SourceChangeCache: TSourceChangeCache;
  LevelPos: TCodeXYPosition): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  NewPos: TCodeXYPosition;
  NewTopLine: integer;
  Node: TCodeTreeNode;
  ClassPart: TNewClassPart;
  LevelCleanPos: integer;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  debugln(['TCodeCompletionCodeTool.DeclareVariableNearBy InsertPos=',dbgs(InsertPos),' Name="',VariableName,'" Type="',NewType,'" Unit=',NewUnitName,' LevelPos=',dbgs(LevelPos)]);
  {$ENDIF}
  BuildTreeAndGetCleanPos(InsertPos,CleanCursorPos);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  CaretToCleanPos(LevelPos,LevelCleanPos);
  if LevelCleanPos>0 then begin
    Node:=FindDeepestNodeAtPos(LevelCleanPos,false);
    while Node<>nil do begin
      //debugln(['TCodeCompletionCodeTool.DeclareVariableNearBy Node=',Node.DescAsString]);
      if Node.Desc in AllClassObjects then begin
        // class member
        debugln(['TCodeCompletionCodeTool.DeclareVariableNearBy class member']);
        // initialize class for code completion
        InitClassCompletion(Node,SourceChangeCache);
        // check if variable already exists
        if VarExistsInCodeCompleteClass(UpperCaseStr(VariableName)) then begin
          debugln(['TCodeCompletionCodeTool.DeclareVariableNearBy member already exists: ',VariableName,' Class=',ExtractClassName(Node,false)]);
          exit;
        end;
        ClassPart:=ncpPublishedVars;
        case Visibility of
        ctnClassPrivate: ClassPart:=ncpPrivateVars;
        ctnClassProtected: ClassPart:=ncpProtectedVars;
        ctnClassPublic: ClassPart:=ncpPublicVars;
        end;
        AddClassInsertion(UpperCaseStr(VariableName),
                          VariableName+':'+NewType+';',VariableName,ClassPart);
        if not InsertAllNewClassParts then
          RaiseException(ctsErrorDuringInsertingNewClassParts);
        if (NewUnitName<>'')
        and (not IsHiddenUsedUnit(PChar(NewUnitName)))
        and (not AddUnitToMainUsesSection(NewUnitName,'',SourceChangeCache)) then
        begin
          debugln(['TCodeCompletionCodeTool.DeclareVariableNearBy AddUnitToMainUsesSection for new class memeber failed']);
          exit;
        end;
        // apply the changes
        if not SourceChangeCache.Apply then
          RaiseException(ctsUnableToApplyChanges);
        exit(true);
      end;
      Node:=Node.Parent;
    end;
  end;
  SourceChangeCache.MainScanner:=Scanner;
  Node:=CursorNode;
  Result:=AddLocalVariable(CleanCursorPos,1,VariableName,NewType,NewUnitName,
                           NewPos,NewTopLine,SourceChangeCache,LevelCleanPos);
end;

function TCodeCompletionCodeTool.DeclareVariableAt(CursorPos: TCodeXYPosition;
  const VariableName, NewType, NewUnitName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  NewCode: String;
  FrontGap: TGapTyp;
  AfterGap: TGapTyp;
  InsertPos: Integer;
  Indent: Integer;
  Node: TCodeTreeNode;
  NeedSection: Boolean;
begin
  Result:=false;
  {$IFDEF CTDEBUG}
  debugln(['TCodeCompletionCodeTool.DeclareVariableAt CursorPos=',dbgs(CursorPos),' Name="',VariableName,'" Type="',NewType,'" Unit=',NewUnitName]);
  {$ENDIF}
  BuildTreeAndGetCleanPos(CursorPos,CleanCursorPos);
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  SourceChangeCache.MainScanner:=Scanner;
  InsertPos:=CleanCursorPos;
  Indent:=0;
  FrontGap:=gtNewLine;
  AfterGap:=gtNewLine;
  {$IFDEF CTDEBUG}
  debugln(['TCodeCompletionCodeTool.DeclareVariableAt CursorNode=',CursorNode.DescAsString]);
  {$ENDIF}
  NewCode:=VariableName+':'+NewType+';';
  NeedSection:=false;
  if CursorNode.Desc=ctnVarDefinition then begin
    // insert in front of another var
    CursorNode:=GetFirstGroupVarNode(CursorNode);
    InsertPos:=CursorNode.StartPos;
    Indent:=GetLineIndent(Src,InsertPos);
  end else if CursorNode.Desc in (AllClassBaseSections
    +[ctnVarSection,ctnRecordType,ctnClassClassVar])
  then begin
    // insert into a var section
    if (CursorNode.FirstChild=nil)
    or (CursorNode.FirstChild.StartPos>InsertPos) then begin
      MoveCursorToNodeStart(CursorNode);
      ReadNextAtom;
      if (CurPos.EndPos<CursorNode.EndPos)
      and ((CursorNode.FirstChild=nil) or (CursorNode.FirstChild.StartPos>CurPos.EndPos))
      and (InsertPos<CurPos.EndPos) then
        InsertPos:=CurPos.EndPos;
    end;
    if CursorNode.FirstChild<>nil then
      Indent:=GetLineIndent(Src,CursorNode.FirstChild.StartPos)
    else
      Indent:=GetLineIndent(Src,CursorNode.StartPos)
              +SourceChangeCache.BeautifyCodeOptions.Indent;
  end else if CursorNode.Desc in [ctnProcedure,ctnInterface,ctnImplementation,
    ctnProgram,ctnLibrary,ctnPackage]
  then begin
    Node:=CursorNode.FirstChild;
    // make sure to insert behind uses section and proc header
    if (Node<>nil) and (Node.Desc in [ctnUsesSection,ctnProcedureHead]) then
    begin
      if (Node<>nil) and (InsertPos<Node.EndPos) then
        InsertPos:=Node.EndPos;
    end;
    // find node in front
    while (Node<>nil) and (Node.NextBrother<>nil)
    and (Node.NextBrother.StartPos<InsertPos) do
      Node:=Node.NextBrother;
    if (Node<>nil) and (Node.Desc=ctnVarSection) then begin
      // append to a var section
      if Node.LastChild<>nil then
        Indent:=GetLineIndent(Src,Node.LastChild.StartPos)
      else
        Indent:=GetLineIndent(Src,Node.StartPos)
                +SourceChangeCache.BeautifyCodeOptions.Indent;
    end else begin
      // start a new var section
      NeedSection:=true;
      if Node<>nil then
        Indent:=GetLineIndent(Src,Node.StartPos)
      else if CursorNode.FirstChild<>nil then
        Indent:=GetLineIndent(Src,CursorNode.FirstChild.StartPos)
      else
        Indent:=GetLineIndent(Src,CursorNode.StartPos);
    end;
  end else begin
    // default: add the variable at cursor
    NeedSection:=true;
  end;
  if NeedSection then
    NewCode:='var'+SourceChangeCache.BeautifyCodeOptions.LineEnd
      +GetIndentStr(SourceChangeCache.BeautifyCodeOptions.Indent)+NewCode;
  NewCode:=SourceChangeCache.BeautifyCodeOptions.BeautifyStatement(NewCode,
    Indent,[bcfIndentExistingLineBreaks]);

  SourceChangeCache.BeginUpdate;
  try
    if (NewUnitName<>'') then begin
      if not AddUnitToMainUsesSection(NewUnitName,'',SourceChangeCache) then begin
        debugln(['TCodeCompletionCodeTool.DeclareVariableAt AddUnitToMainUsesSection failed']);
        exit;
      end;
    end;
    {$IFDEF VerboseCompletionAdds}
    debugln(['TCodeCompletionCodeTool.DeclareVariableAt NewCode="',dbgstr(NewCode),'"']);
    {$ENDIF}
    if not SourceChangeCache.Replace(FrontGap,AfterGap,InsertPos,InsertPos,NewCode)
    then exit;
    Result:=true;
  finally
    if not Result then
      SourceChangeCache.Clear;
    if not SourceChangeCache.EndUpdate then
      Result:=false;
  end;
end;

function TCodeCompletionCodeTool.GatherPublishedMethods(
  ClassNode: TCodeTreeNode; out ListOfPFindContext: TFPList): boolean;
var
  Ancestors: TFPList; // list of PFindContext
  i: Integer;
  Context: PFindContext;
begin
  Result:=false;
  Ancestors:=nil;
  ListOfPFindContext:=nil;
  try
    if not FindClassAndAncestors(ClassNode,Ancestors,false) then exit;
    if Ancestors=nil then exit(true);
    for i:=0 to Ancestors.Count-1 do begin
      Context:=PFindContext(Ancestors[i]);
      DebugLn(['TCodeCompletionCodeTool.GatherPublishedMethods ',Context^.Node.DescAsString]);
    end;
  finally
    FreeListOfPFindContext(Ancestors);
  end;
end;

function TCodeCompletionCodeTool.InitClassCompletion(
  const AClassName: string;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  ClassNode: TCodeTreeNode;
begin
  Result:=false;
  BuildTree(lsrEnd);
  if ScannedRange<>lsrEnd then exit;
  if (SourceChangeCache=nil) or (Scanner=nil) then exit;
  ClassNode:=FindClassNodeInUnit(AClassName,true,false,false,true);
  Result:=InitClassCompletion(ClassNode,SourceChangeCache);
end;

function TCodeCompletionCodeTool.InitClassCompletion(ClassNode: TCodeTreeNode;
  SourceChangeCache: TSourceChangeCache): boolean;
begin
  if (ClassNode=nil) then exit(false);
  CodeCompleteClassNode:=ClassNode;
  CodeCompleteSrcChgCache:=SourceChangeCache;
  FreeClassInsertionList;
  Result:=true;
end;

function TCodeCompletionCodeTool.ApplyClassCompletion(
  AddMissingProcBodies: boolean): boolean;
begin
  Result:=false;
  try
    // insert all new class parts
    if not InsertAllNewClassParts then
      RaiseException(ctsErrorDuringInsertingNewClassParts);
    // insert all missing proc bodies
    if AddMissingProcBodies and (not CreateMissingProcBodies) then
      RaiseException(ctsErrorDuringCreationOfNewProcBodies);
    // apply the changes
    if not CodeCompleteSrcChgCache.Apply then
      RaiseException(ctsUnableToApplyChanges);
    Result:=true;
  finally
    FreeClassInsertionList;
  end;
end;

function TCodeCompletionCodeTool.CompleteProperty(
  PropNode: TCodeTreeNode): boolean;
{
 examples:
   property Visible;
   property Count: integer;
   property Color: TColor read FColor write SetColor;
   property Items[Index1, Index2: integer]: integer read GetItems; default;
   property X: integer index 1 read GetCoords write SetCoords stored IsStored;
   property C: char read GetC stored False default 'A';
   property Col8: ICol8 read FCol8 write FCol8 implements ICol8, IColor;
   property Visible: WordBool readonly dispid 401;

   property specifiers without parameters:
     ;nodefault, ;default

   property specifiers with parameters:
     index <id or number>, read <id>, write <id>, stored <id>,
     default <constant>, implements <id>[,<id>...]
}
type
  TPropPart = (ppName,       // property name
               ppParamList,  // param list
               ppUnitType,   // optional: unit in front of identifier
               ppType,       // type identifier
               ppIndexWord,  // 'index'
               ppIndex,      // index constant
               ppReadWord,   // 'read'
               ppRead,       // read identifier
               ppWriteWord,  // 'write'
               ppWrite,      // write identifier
               ppStoredWord, // 'stored'
               ppStored,     // stored identifier
               ppImplementsWord,// 'implements'
               ppImplements, // implements identifier
               ppDefaultWord,// 'default'  (the default value keyword,
                             //             not the default property)
               ppDefault,    // default constant
               ppNoDefaultWord,// 'nodefault'
               ppDispidWord, // 'dispid'
               ppDispid      // dispid constant
               );

var
  Parts: array[TPropPart] of TAtomPosition;
  PartIsAtom: array[TPropPart] of boolean;

  procedure ReadSimpleSpec(SpecWord, SpecParam: TPropPart);
  // allowed after simple specifier like 'read':
  //   one semicolon
  //   or an <identifier>
  //   or an <identifier>.<identifier>
  //   (only read, write: ) or an <identifier>[ordinal expression]
  //   or a specifier
  begin
    if Parts[SpecWord].StartPos>=1 then
      RaiseExceptionFmt(ctsPropertySpecifierAlreadyDefined,[GetAtom]);
    Parts[SpecWord]:=CurPos;
    ReadNextAtom;
    if AtomIsChar(';') then exit;
    AtomIsIdentifierE;
    if WordIsPropertySpecifier.DoItCaseInsensitive(Src,CurPos.StartPos,
      CurPos.EndPos-CurPos.StartPos)
    then
      exit;
    Parts[SpecParam]:=CurPos;
    ReadNextAtom;
    while CurPos.Flag=cafPoint do begin
      ReadNextAtom;
      AtomIsIdentifierE;
      ReadNextAtom;
      PartIsAtom[SpecParam]:=false;
      Parts[SpecParam].EndPos:=CurPos.EndPos;
    end;
    if (SpecParam in [ppRead,ppWrite])
    and (CurPos.Flag=cafEdgedBracketOpen) then begin
      // array access
      PartIsAtom[SpecParam]:=false;
      ReadTilBracketClose(true);
      ReadNextAtom;
    end;
  end;

var
  CleanAccessFunc, CleanParamList, ParamList, PropType, VariableName: string;
  IsClassProp: boolean;
  InsertPos: integer;
  BeautifyCodeOpts: TBeautifyCodeOptions;
  IndexType: string;
  
  procedure InitCompleteProperty;
  var APart: TPropPart;
  begin
    for APart:=Low(TPropPart) to High(TPropPart) do begin
      Parts[APart].StartPos:=-1;
      PartIsAtom[APart]:=true;
    end;
    IndexType:='Integer';
  end;
  
  procedure ReadPropertyKeywordAndName;
  begin
    MoveCursorToNodeStart(PropNode);
    ReadNextAtom; // read 'property'
    IsClassProp:=false;
    if UpAtomIs('CLASS') then begin
      IsClassProp:=true;
      ReadNextAtom;
    end;
    ReadNextAtom; // read name
    Parts[ppName]:=CurPos;
    ReadNextAtom;
  end;
  
  procedure ReadPropertyParamList;
  begin
    if AtomIsChar('[') then begin
      // read parameter list '[ ... ]'
      Parts[ppParamList].StartPos:=CurPos.StartPos;
      InitExtraction;
      if not ReadParamList(true,true,[phpInUpperCase,phpWithoutBrackets])
      then begin
        {$IFDEF CTDEBUG}
        DebugLn('[TCodeCompletionCodeTool.CompleteProperty] error parsing param list');
        {$ENDIF}
        RaiseException(ctsErrorInParamList);
      end;
      CleanParamList:=GetExtraction(true);
      Parts[ppParamList].EndPos:=CurPos.EndPos;
    end else
      CleanParamList:='';
  end;
  
  procedure ReadPropertyType;

    procedure CheckIdentifier;
    begin
      if (CurPos.StartPos>PropNode.EndPos)
      or UpAtomIs('END') or AtomIsChar(';') or (not AtomIsIdentifier)
      or AtomIsKeyWord then begin
        // no type name found -> ignore this property
        RaiseExceptionFmt(ctsPropertTypeExpectedButAtomFound,[GetAtom]);
      end;
    end;

  begin
    ReadNextAtom; // read type
    CheckIdentifier;
    Parts[ppType]:=CurPos;
    ReadNextAtom;
    if CurPos.Flag=cafPoint then begin
      // unit.identifier
      Parts[ppUnitType]:=Parts[ppType];
      ReadNextAtom;
      CheckIdentifier;
      Parts[ppType]:=CurPos;
      ReadNextAtom;
    end;
  end;
  
  procedure ReadIndexSpecifier;
  begin
    if UpAtomIs('INDEX') then begin
      if Parts[ppIndexWord].StartPos>=1 then
        RaiseException(ctsIndexSpecifierRedefined);
      Parts[ppIndexWord]:=CurPos;
      ReadNextAtom;
      if WordIsPropertySpecifier.DoItCaseInsensitive(Src,CurPos.StartPos,
        CurPos.EndPos-CurPos.StartPos) then
        RaiseExceptionFmt(ctsIndexParameterExpectedButAtomFound,[GetAtom]);
      Parts[ppIndex].StartPos:=CurPos.StartPos;
      ReadConstant(true,false,[]);
      Parts[ppIndex].EndPos:=LastAtoms.GetValueAt(0).EndPos;
      PartIsAtom[ppIndex]:=false;
    end;
  end;

  procedure ReadDispidSpecifier;
  begin
    if UpAtomIs('DISPID') then begin
      if Parts[ppDispidWord].StartPos>=1 then
        RaiseException(ctsDispidSpecifierRedefined);
      Parts[ppDispidWord]:=CurPos;
      ReadNextAtom;
      if WordIsPropertySpecifier.DoItCaseInsensitive(Src,CurPos.StartPos,
        CurPos.EndPos-CurPos.StartPos) then
        RaiseExceptionFmt(ctsDispidParameterExpectedButAtomFound,[GetAtom]);
      Parts[ppDispid].StartPos:=CurPos.StartPos;
      ReadConstant(true,false,[]);
      Parts[ppDispid].EndPos:=LastAtoms.GetValueAt(0).EndPos;
      PartIsAtom[ppDispid]:=false;
    end;
  end;
  
  procedure ReadReadSpecifier;
  begin
    if UpAtomIs('READ') then ReadSimpleSpec(ppReadWord,ppRead);
  end;
  
  procedure ReadWriteSpecifier;
  begin
    if UpAtomIs('WRITE') then ReadSimpleSpec(ppWriteWord,ppWrite);
  end;

  procedure ReadOptionalSpecifiers;
  begin
    while (CurPos.StartPos<PropNode.EndPos) do begin
      if (CurPos.Flag in [cafSemicolon,cafEnd]) then break;
      if UpAtomIs('STORED') then begin
        ReadSimpleSpec(ppStoredWord,ppStored);
      end else if UpAtomIs('DEFAULT') then begin
        if Parts[ppDefaultWord].StartPos>=1 then
          RaiseException(ctsDefaultSpecifierRedefined);
        Parts[ppDefaultWord]:=CurPos;
        ReadNextAtom;
        if WordIsPropertySpecifier.DoItCaseInsensitive(Src,CurPos.StartPos,
          CurPos.EndPos-CurPos.StartPos) then
          RaiseExceptionFmt(ctsDefaultParameterExpectedButAtomFound,[GetAtom]);
        Parts[ppDefault].StartPos:=CurPos.StartPos;
        ReadConstant(true,false,[]);
        Parts[ppDefault].EndPos:=LastAtoms.GetValueAt(0).EndPos;
        PartIsAtom[ppDefault]:=false;
      end else if UpAtomIs('NODEFAULT') then begin
        if Parts[ppNoDefaultWord].StartPos>=1 then
          RaiseException(ctsNodefaultSpecifierDefinedTwice);
        Parts[ppNoDefaultWord]:=CurPos;
        ReadNextAtom;
      end else if UpAtomIs('IMPLEMENTS') then begin
        ReadSimpleSpec(ppImplementsWord,ppImplements);
        while CurPos.Flag=cafComma do begin
          ReadNextAtom;
          AtomIsIdentifierE;
          if WordIsPropertySpecifier.DoItCaseInsensitive(Src,CurPos.StartPos,
            CurPos.EndPos-CurPos.StartPos) then
            RaiseExceptionFmt(ctsIndexParameterExpectedButAtomFound,[GetAtom]);
          ReadNextAtom;
        end;
      end else 
        RaiseExceptionFmt(ctsStrExpectedButAtomFound,[';',GetAtom]);
    end;
  end;
  
  procedure CompleteReadSpecifier;
  var
    IsGetterFunc: boolean;
    VarCode: String;
    AccessParamPrefix: String;
    AccessParam: String;
    AccessFunc: String;
  begin
    // check read specifier
    VariableName:='';
    if not PartIsAtom[ppRead] then exit;
    if (Parts[ppReadWord].StartPos<=0) and (Parts[ppWriteWord].StartPos>0) then
      exit;
    {$IFDEF CTDEBUG}
    DebugLn('[TCodeCompletionCodeTool.CompleteProperty] read specifier needed');
    {$ENDIF}
    AccessParamPrefix:=BeautifyCodeOpts.PropertyReadIdentPrefix;
    if Parts[ppRead].StartPos>0 then
      AccessParam:=copy(Src,Parts[ppRead].StartPos,
                        Parts[ppRead].EndPos-Parts[ppRead].StartPos)
    else begin
      if (Parts[ppParamList].StartPos>0) or (Parts[ppIndexWord].StartPos>0)
      or (SysUtils.CompareText(AccessParamPrefix,
              LeftStr(AccessParam,length(AccessParamPrefix)))=0)
      or (CodeCompleteClassNode.Desc in AllClassInterfaces) then
      begin
        // create the default read identifier for a function
        AccessParam:=AccessParamPrefix+copy(Src,Parts[ppName].StartPos,
                                   Parts[ppName].EndPos-Parts[ppName].StartPos);
      end else begin
        // create the default read identifier for a variable
        AccessParam:=BeautifyCodeOpts.PrivateVariablePrefix
                                 +copy(Src,Parts[ppName].StartPos,
                                   Parts[ppName].EndPos-Parts[ppName].StartPos);
      end;
    end;

    // complete read identifier in property definition
    if (Parts[ppRead].StartPos<0) and CompleteProperties then begin
      // insert read specifier
      if Parts[ppReadWord].StartPos>0 then begin
        // 'read' keyword exists -> insert read identifier behind
        InsertPos:=Parts[ppReadWord].EndPos;
        ASourceChangeCache.Replace(gtSpace,gtNone,InsertPos,InsertPos,
           AccessParam);
      end else begin
        // 'read' keyword does not exist -> insert behind index and type
        if Parts[ppIndex].StartPos>0 then
          InsertPos:=Parts[ppIndex].EndPos
        else if Parts[ppIndexWord].StartPos>0 then
          InsertPos:=Parts[ppIndexWord].EndPos
        else
          InsertPos:=Parts[ppType].EndPos;
        ASourceChangeCache.Replace(gtSpace,gtNone,InsertPos,InsertPos,
           BeautifyCodeOpts.BeautifyKeyWord('read')+' '+AccessParam);
      end;
    end;

    IsGetterFunc:=(Parts[ppParamList].StartPos>0)
      or ((Parts[ppIndexWord].StartPos>0)
          and not VarExistsInCodeCompleteClass(UpperCaseStr(AccessParam)))
      or (SysUtils.CompareText(AccessParamPrefix,
            LeftStr(AccessParam,length(AccessParamPrefix)))=0)
      or (CodeCompleteClassNode.Desc in AllClassInterfaces);
    if not IsGetterFunc then
      VariableName:=AccessParam;

    // check if read access method exists
    if (Parts[ppIndexWord].StartPos<1) then begin
      if (Parts[ppParamList].StartPos>0) then begin
        // param list, no index
        CleanAccessFunc:=UpperCaseStr(AccessParam)+'('+CleanParamList+');';
      end else begin
        // no param list, no index
        CleanAccessFunc:=UpperCaseStr(AccessParam)+';';
      end;
    end else begin
      // ToDo: find out type of index
      if (Parts[ppParamList].StartPos>0) then begin
        // index + param list
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+IndexType+';')
                        +CleanParamList+');';
      end else begin
        // index, no param list
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+IndexType+');');
      end;
    end;
    if ProcExistsInCodeCompleteClass(CleanAccessFunc) then exit;

    // check if read access variable exists
    if (Parts[ppParamList].StartPos<1)
    and (CodeCompleteClassNode.Desc in AllClassObjects)
    and VarExistsInCodeCompleteClass(UpperCaseStr(AccessParam)) then exit;

    // complete read access specifier
    if IsGetterFunc then begin
      // the read identifier is a function
      {$IFDEF CTDEBUG}
      DebugLn('[TCodeCompletionCodeTool.CompleteProperty] CleanAccessFunc ',CleanAccessFunc,' does not exist');
      {$ENDIF}
      // add insert demand for function
      // build function code
      if (Parts[ppParamList].StartPos>0) then begin
        MoveCursorToCleanPos(Parts[ppParamList].StartPos);
        ReadNextAtom;
        InitExtraction;
        if not ReadParamList(true,true,[phpWithParameterNames,
                             phpWithoutBrackets,phpWithVarModifiers,
                             phpWithComments])
        then begin
          {$IFDEF CTDEBUG}
          DebugLn('[TCodeCompletionCodeTool.CompleteProperty] Error reading param list');
          {$ENDIF}
          RaiseException(ctsErrorInParamList);
        end;
        ParamList:=GetExtraction(false);
        if (Parts[ppIndexWord].StartPos<1) then begin
          // param list, no index
          AccessFunc:='function '+AccessParam
                      +'('+ParamList+'):'+PropType+';';
        end else begin
          // index + param list
          AccessFunc:='function '+AccessParam
                      +'(AIndex:'+IndexType+';'+ParamList+'):'+PropType+';';
        end;
      end else begin
        if (Parts[ppIndexWord].StartPos<1) then begin
          // no param list, no index
          AccessFunc:='function '+AccessParam+':'+PropType+';';
        end else begin
          // index, no param list
          AccessFunc:='function '+AccessParam
                      +'(AIndex:'+IndexType+'):'+PropType+';';
        end;
      end;
      if IsClassProp then
        AccessFunc:='class '+AccessFunc+' static;';
      // add new Insert Node
      if CompleteProperties then
        AddClassInsertion(CleanAccessFunc,AccessFunc,AccessParam,
                          ncpPrivateProcs,PropNode);
    end else begin
      // the read identifier is a variable
      // variable does not exist yet -> add insert demand for variable
      VarCode:=VariableName+':'+PropType+';';
      if IsClassProp then VarCode:='class var '+VarCode;
      AddClassInsertion(UpperCaseStr(VariableName),
         VarCode,VariableName,ncpPrivateVars,PropNode);
    end;
  end;
  
  procedure CompleteWriteSpecifier;
  var
    ProcBody: String;
    AccessParamPrefix: String;
    AccessParam: String;
    AccessFunc: String;
  begin
    // check write specifier
    if not PartIsAtom[ppWrite] then exit;
    if (Parts[ppWriteWord].StartPos<1) and (Parts[ppReadWord].StartPos>0) then
      exit;
    {$IFDEF CTDEBUG}
    DebugLn('[TCodeCompletionCodeTool.CompleteProperty] write specifier needed');
    {$ENDIF}
    AccessParamPrefix:=BeautifyCodeOpts.PropertyWriteIdentPrefix;
    if Parts[ppWrite].StartPos>0 then
      AccessParam:=copy(Src,Parts[ppWrite].StartPos,
            Parts[ppWrite].EndPos-Parts[ppWrite].StartPos)
    else
      AccessParam:=AccessParamPrefix+copy(Src,Parts[ppName].StartPos,
            Parts[ppName].EndPos-Parts[ppName].StartPos);

    // complete property definition for write specifier
    if (Parts[ppWrite].StartPos<0) and CompleteProperties then begin
      // insert write specifier
      if Parts[ppWriteWord].StartPos>0 then begin
        // 'write' keyword exists -> insert write identifier behind
        InsertPos:=Parts[ppWriteWord].EndPos;
        ASourceChangeCache.Replace(gtSpace,gtNone,InsertPos,InsertPos,
           AccessParam);
      end else begin
        // 'write' keyword does not exist
        //  -> insert behind type, index and write specifier
        if Parts[ppRead].StartPos>0 then
          InsertPos:=Parts[ppRead].EndPos
        else if Parts[ppReadWord].StartPos>0 then
          InsertPos:=Parts[ppReadWord].EndPos
        else if Parts[ppIndex].StartPos>0 then
          InsertPos:=Parts[ppIndex].EndPos
        else if Parts[ppIndexWord].StartPos>0 then
          InsertPos:=Parts[ppIndexWord].EndPos
        else
          InsertPos:=Parts[ppType].EndPos;
        ASourceChangeCache.Replace(gtSpace,gtNone,InsertPos,InsertPos,
           BeautifyCodeOpts.BeautifyKeyWord('write')+' '+AccessParam);
      end;
    end;

    // check if write method exists
    if (Parts[ppIndexWord].StartPos<1) then begin
      if (Parts[ppParamList].StartPos>0) then begin
        // param list, no index
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+CleanParamList+';'
                           +PropType+');');
      end else begin
        // no param list, no index
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+PropType+');');
      end;
    end else begin
      // ToDo: find out index type
      if (Parts[ppParamList].StartPos>0) then begin
        // index + param list
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+IndexType+';'
                  +CleanParamList+';'+PropType+');');
      end else begin
        // index, no param list
        CleanAccessFunc:=UpperCaseStr(AccessParam+'('+IndexType+';'+PropType+');');
      end;
    end;
    if ProcExistsInCodeCompleteClass(CleanAccessFunc) then exit;

    // check if write variable exists
    if (Parts[ppParamList].StartPos<1)
    and (CodeCompleteClassNode.Desc in AllClassObjects)
    and VarExistsInCodeCompleteClass(UpperCaseStr(AccessParam)) then exit;

    // complete class
    if (Parts[ppParamList].StartPos>0)
    or ((Parts[ppIndexWord].StartPos>0)
        and not VarExistsInCodeCompleteClass(UpperCaseStr(AccessParam)))
    or (SysUtils.CompareText(AccessParamPrefix,
            LeftStr(AccessParam,length(AccessParamPrefix)))=0)
    or (CodeCompleteClassNode.Desc in AllClassInterfaces) then
    begin
      // add insert demand for function
      // build function code
      ProcBody:='';
      if (Parts[ppParamList].StartPos>0) then begin
        MoveCursorToCleanPos(Parts[ppParamList].StartPos);
        ReadNextAtom;
        InitExtraction;
        if not ReadParamList(true,true,[phpWithParameterNames,
                             phpWithoutBrackets,phpWithVarModifiers,
                             phpWithComments])
        then
          RaiseException(ctsErrorInParamList);
        ParamList:=GetExtraction(false);
        if (Parts[ppIndexWord].StartPos<1) then begin
          // param list, no index
          AccessFunc:='procedure '+AccessParam
                      +'('+ParamList+';'+SetPropertyVariablename+':'
                      +PropType+');';
        end else begin
          // index + param list
          AccessFunc:='procedure '+AccessParam
                      +'(AIndex:'+IndexType+';'+ParamList+';'
                      +SetPropertyVariablename+':'+PropType+');';
        end;
      end else begin
        if (Parts[ppIndexWord].StartPos<1) then begin
          // no param list, no index
          AccessFunc:=
            'procedure '+AccessParam
            +'('+SetPropertyVariablename+':'+PropType+');';
          if VariableName<>'' then begin
            { read spec is a variable -> add simple assign code to body
              For example:
              
              procedure SetMyInt(AValue: integer);
              begin
                if FMyInt=AValue then exit;
                FMyInt:=AValue;
              end;
            
            }
            ProcBody:=
              'procedure '
              +ExtractClassName(PropNode.Parent.Parent,false)+'.'+AccessParam
              +'('+SetPropertyVariablename+':'+PropType+');'
              +BeautifyCodeOpts.LineEnd
              +'begin'+BeautifyCodeOpts.LineEnd
              +GetIndentStr(BeautifyCodeOpts.Indent)
                +'if '+VariableName+'='+SetPropertyVariablename+' then Exit;'
                +BeautifyCodeOpts.LineEnd
              +GetIndentStr(BeautifyCodeOpts.Indent)
                +VariableName+':='+SetPropertyVariablename+';'
                +BeautifyCodeOpts.LineEnd
              +'end;';
            if IsClassProp then
              ProcBody:='class '+ProcBody;
          end;
        end else begin
          // index, no param list
          AccessFunc:='procedure '+AccessParam
                  +'(AIndex:'+IndexType+';'+SetPropertyVariablename+':'+PropType+');';
        end;
      end;
      // add new Insert Node
      if IsClassProp then
        AccessFunc:='class '+AccessFunc+' static;';
      if CompleteProperties then
        AddClassInsertion(CleanAccessFunc,AccessFunc,AccessParam,
                          ncpPrivateProcs,PropNode,ProcBody);
    end else begin
      // the write identifier is a variable
      // -> add insert demand for variable
      if CompleteProperties then
        AddClassInsertion(UpperCaseStr(AccessParam),
           AccessParam+':'+PropType+';',AccessParam,ncpPrivateVars,PropNode);
    end;
  end;
  
  procedure CompleteStoredSpecifier;
  var
    AccessParam: String;
    AccessFunc: String;
  begin
    // check stored specifier
    if not PartIsAtom[ppStored] then exit;
    if (Parts[ppStoredWord].StartPos<1) then exit;
    {$IFDEF CTDEBUG}
    DebugLn('[TCodeCompletionCodeTool.CompleteProperty] stored specifier needed');
    {$ENDIF}
    if Parts[ppStored].StartPos>0 then begin
      if (CompareIdentifiers(@Src[Parts[ppStored].StartPos],'False')=0)
      or (CompareIdentifiers(@Src[Parts[ppStored].StartPos],'True')=0) then
        exit;
      AccessParam:=copy(Src,Parts[ppStored].StartPos,
            Parts[ppStored].EndPos-Parts[ppStored].StartPos);
    end else
      AccessParam:=copy(Src,Parts[ppName].StartPos,
        Parts[ppName].EndPos-Parts[ppName].StartPos)
        +BeautifyCodeOpts.PropertyStoredIdentPostfix;
    CleanAccessFunc:=UpperCaseStr(AccessParam);
    // check if procedure exists
    if (not ProcExistsInCodeCompleteClass(CleanAccessFunc+';'))
    and (not VarExistsInCodeCompleteClass(CleanAccessFunc))
    then begin
      // add insert demand for function
      // build function code
      if Parts[ppIndexWord].StartPos < 1 then begin
        // no index
        AccessFunc := 'function ' + AccessParam + ':Boolean;';
        CleanAccessFunc := CleanAccessFunc+';';
      end else begin
        // index
        AccessFunc := 'function ' + AccessParam + '(AIndex:'+IndexType+'):Boolean;';
        CleanAccessFunc := UpperCaseStr(CleanAccessFunc + '('+IndexType+');');
      end;
      if IsClassProp then
        AccessFunc:='class '+AccessFunc+' static;';;
      // add new Insert Node
      if CompleteProperties then
        AddClassInsertion(CleanAccessFunc,AccessFunc,AccessParam,
                          ncpPrivateProcs,PropNode);
    end;
    if Parts[ppStored].StartPos<0 then begin
      // insert stored specifier
      InsertPos:=Parts[ppStoredWord].EndPos;
      if CompleteProperties then
        ASourceChangeCache.Replace(gtSpace,gtNone,InsertPos,InsertPos,
                                   AccessParam);
    end;
  end;

  procedure CompleteSemicolon;
  begin
    if (PropNode.EndPos<=SrcLen) and (Src[PropNode.EndPos-1]<>';') then begin
      InsertPos:=PropNode.EndPos;
      if CompleteProperties then
        ASourceChangeCache.Replace(gtNone,gtNone,InsertPos,InsertPos,';');
    end;
  end;

begin
  Result:=false;
  InitCompleteProperty;
  ReadPropertyKeywordAndName;
  ReadPropertyParamList;
  
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeCompletionCodeTool.CompleteProperty] Checking Property ',GetAtom);
  {$ENDIF}
  if not AtomIsChar(':') then begin
    {$IFDEF CTDEBUG}
    DebugLn('[TCodeCompletionCodeTool.CompleteProperty] no type : found -> ignore property');
    {$ENDIF}
    // no type -> ignore this property
    Result:=true;
    exit;
  end;
  
  ReadPropertyType;
  // parse specifiers
  if CodeCompleteClassNode.Desc <> ctnDispinterface then begin
    ReadIndexSpecifier;
    ReadReadSpecifier;
    ReadWriteSpecifier;
    ReadOptionalSpecifiers;
  end else begin
    if UpAtomIs('READONLY') or UpAtomIs('WRITEONLY') then
      ReadNextAtom;
    ReadDispidSpecifier;
  end;
  PropType:=copy(Src,Parts[ppType].StartPos,
                 Parts[ppType].EndPos-Parts[ppType].StartPos);
  if Parts[ppUnitType].StartPos>0 then
    PropType:=copy(Src,Parts[ppUnitType].StartPos,
              Parts[ppUnitType].EndPos-Parts[ppUnitType].StartPos)+'.'+PropType;
               
  // complete property
  BeautifyCodeOpts:=ASourceChangeCache.BeautifyCodeOptions;
  if CodeCompleteClassNode.Desc <> ctnDispinterface then begin
    CompleteReadSpecifier;
    CompleteWriteSpecifier;
    CompleteStoredSpecifier;
  end;
  CompleteSemicolon;
  
  Result:=true;
end;

function TCodeCompletionCodeTool.GetFirstClassIdentifier(
  ClassNode: TCodeTreeNode): TCodeTreeNode;
const
  Identifiers = AllIdentifierDefinitions+[ctnProperty,ctnProcedure,ctnClassGUID];
begin
  if ClassNode=nil then exit(nil);
  Result:=ClassNode.FirstChild;
  while Result<>nil do begin
    if (Result.Desc in Identifiers) then
      exit;
    Result:=FindNextIdentNodeInClass(Result);
  end;
end;

procedure TCodeCompletionCodeTool.InsertNewClassParts(PartType: TNewClassPart);
var ANodeExt: TCodeTreeNodeExtension;
  ClassSectionNode, ANode, InsertNode: TCodeTreeNode;
  Indent, InsertPos: integer;
  CurCode: string;
  IsVariable, InsertBehind: boolean;
  Visibility: TPascalClassSection;
begin
  ANodeExt:=FirstInsert;
  Visibility:=NewClassPartVisibility[PartType];
  // insert all nodes of specific type
  while ANodeExt<>nil do begin
    IsVariable:=NodeExtIsVariable(ANodeExt);
    if (cardinal(ord(PartType))=ANodeExt.Flags) then begin
      // search a destination section
      ClassSectionNode:=nil;
      if Visibility=pcsPublished then begin
        // insert into first published section
        ClassSectionNode:=CodeCompleteClassNode.FirstChild;
        while not (ClassSectionNode.Desc in AllClassSections) do
          ClassSectionNode:=ClassSectionNode.NextBrother;
        // the first class section is always a published section, even if there
        // is no 'published' keyword. If the class starts with the 'published'
        // keyword, then it will be more beautiful to insert vars and procs to
        // this second published section
        if (ClassSectionNode.FirstChild=nil)
        and (ClassSectionNode.NextBrother<>nil)
        and (ClassSectionNode.NextBrother.Desc=ctnClassPublished)
        then
          ClassSectionNode:=ClassSectionNode.NextBrother;
      end else if ANodeExt.Node<>nil then begin
        // search a section of the same Visibility in front of the node
        if CodeCompleteClassNode.Desc in AllClassObjects then
        begin
          ClassSectionNode:=ANodeExt.Node.Parent.PriorBrother;
          while (ClassSectionNode<>nil)
          and (ClassSectionNode.Desc<>ClassSectionNodeType[Visibility]) do
            ClassSectionNode:=ClassSectionNode.PriorBrother;
        end else begin
          ClassSectionNode:=CodeCompleteClassNode;
        end;
      end else begin
        // search a section of the same Visibility
        if CodeCompleteClassNode.Desc in AllClassObjects then
        begin
          ClassSectionNode:=CodeCompleteClassNode.FirstChild;
          while (ClassSectionNode<>nil)
          and (ClassSectionNode.Desc<>ClassSectionNodeType[Visibility]) do
            ClassSectionNode:=ClassSectionNode.NextBrother;
        end else begin
          ClassSectionNode:=CodeCompleteClassNode;
        end;
      end;
      if ClassSectionNode=nil then begin
        // there is no existing class section node
        // -> insert in the new one
        Indent:=NewClassSectionIndent[Visibility]
                    +ASourceChangeCache.BeautifyCodeOptions.Indent;
        InsertPos:=NewClassSectionInsertPos[Visibility];
        if InsertPos<1 then
          raise Exception.Create('TCodeCompletionCodeTool.InsertNewClassParts inconsistency: missing section: please create a bug report');
      end else begin
        // there is an existing class section to insert into
        
        // find a nice insert position
        InsertNode:=nil; // the new part will be inserted after this node
                         //   nil means insert as first
        InsertBehind:=true;
        ANode:=ClassSectionNode.FirstChild;

        // skip the class GUID
        if (ANode<>nil) and (ANode.Desc=ctnClassGUID) then begin
          InsertNode:=ANode;
          ANode:=ANode.NextBrother;
        end;

        // insert methods behind variables
        if not IsVariable then begin
          while (ANode<>nil) and (ANode.Desc=ctnVarDefinition) do begin
            InsertNode:=ANode;
            ANode:=ANode.NextBrother;
          end;
        end;

        // find a nice position between similar siblings
        case ASourceChangeCache.BeautifyCodeOptions.ClassPartInsertPolicy of
        
        cpipAlphabetically:
          begin
            while ANode<>nil do begin
              if IsVariable then begin
                // the insertion is a new variable
                if (ANode.Desc<>ctnVarDefinition)
                or (CompareNodeIdentChars(ANode,ANodeExt.Txt)<0) then
                  break;
              end else begin
                // the insertion is a new method
                case ANode.Desc of
                
                ctnProcedure:
                  begin
                    CurCode:=ExtractProcName(ANode,[]);
                    if SysUtils.CompareText(CurCode,ANodeExt.ExtTxt2)>0 then
                      break;
                  end;
                  
                ctnProperty:
                  begin
                    if ASourceChangeCache.BeautifyCodeOptions
                        .MixMethodsAndProperties then
                    begin
                      CurCode:=ExtractPropName(ANode,false);
                      if SysUtils.CompareText(CurCode,ANodeExt.ExtTxt2)>0 then
                        break;
                    end else
                      break;
                  end;
                  
                end;
              end;
              InsertNode:=ANode;
              ANode:=ANode.NextBrother;
            end;
          end;
          
        else
          // cpipLast
          begin
            while ANode<>nil do begin
              if IsVariable then begin
                // the insertion is a variable
                if (ANode.Desc<>ctnVarDefinition) then
                  break;
              end else begin
                // the insertion is a method
                if (not ASourceChangeCache.BeautifyCodeOptions.MixMethodsAndProperties)
                and (ANode.Desc=ctnProperty) then
                  break;
              end;
              InsertNode:=ANode;
              ANode:=ANode.NextBrother;
            end;
          end
        end;

        if InsertNode<>nil then begin
          //debugln(['TCodeCompletionCodeTool.InsertNewClassParts insert behind existing']);
          // for variable lists: a,b,c: integer
          // use last node
          if InsertBehind then begin
            while (InsertNode.Desc=ctnVarDefinition)
            and (InsertNode.FirstChild=nil)
            and (InsertNode.NextBrother<>nil)
            and (InsertNode.NextBrother.Desc=ctnVarDefinition) do
              InsertNode:=InsertNode.NextBrother;
          end;

          if (not IsVariable) and (InsertNode.Desc=ctnVarDefinition)
          and (InsertNode.NextBrother<>nil) then begin
            // insertion is a new method and it should be inserted behind
            // variables. Because methods and variables should be separated
            // there is a next node, insert the new method in front of the next
            // node, instead of inserting it right behind the variable.
            // This makes sure to use existing separation comments/empty lines.
            InsertNode:=InsertNode.NextBrother;
            InsertBehind:=false;
          end;
          
          Indent:=GetLineIndent(Src,InsertNode.StartPos);
          if InsertBehind then begin
            // insert behind InsertNode
            InsertPos:=FindLineEndOrCodeAfterPosition(InsertNode.EndPos);
          end else begin
            // insert in front of InsertNode
            InsertPos:=InsertNode.StartPos;
          end;
        end else begin
          // insert as first variable/proc
          //debugln(['TCodeCompletionCodeTool.InsertNewClassParts insert as first var: ',ClassSectionNode.DescAsString,' ',dbgstr(copy(Src,ClassSectionNode.StartPos,ClassSectionNode.EndPos-ClassSectionNode.StartPos))]);
          Indent:=GetLineIndent(Src,ClassSectionNode.StartPos)
                    +ASourceChangeCache.BeautifyCodeOptions.Indent;
          InsertPos:=ClassSectionNode.StartPos;
          if (ClassSectionNode.Desc=ctnClassPublished)
          and (CompareIdentifiers(@Src[ClassSectionNode.StartPos],'published')<>0)
          then begin
            // the first published section has no keyword
            if ClassSectionNode.NextBrother<>nil then
              Indent:=GetLineIndent(Src,ClassSectionNode.NextBrother.StartPos)
                      +ASourceChangeCache.BeautifyCodeOptions.Indent
            else
              Indent:=GetLineIndent(Src,ClassSectionNode.Parent.StartPos)
                      +ASourceChangeCache.BeautifyCodeOptions.Indent;
          end else if (ClassSectionNode.Desc in AllClassBaseSections)
          then begin
            // skip keyword
            MoveCursorToCleanPos(InsertPos);
            ReadNextAtom;
            if UpAtomIs('STRICT') then
              ReadNextAtom;
            //debugln(['TCodeCompletionCodeTool.InsertNewClassParts insert as first of ',ClassSectionNode.DescAsString,' Atom=',GetAtom]);
            ANode:=ClassSectionNode.Next;
            if (ANode<>nil) and (CurPos.EndPos<=ANode.StartPos) then
              InsertPos:=CurPos.EndPos;
          end else if ClassSectionNode.Desc in AllClassInterfaces then begin
            // skip class interface header
            MoveCursorToCleanPos(InsertPos);
            ReadNextAtom; // skip 'interface'
            InsertPos:=CurPos.EndPos;
            if ReadNextAtomIsChar('(') then begin
              ReadTilBracketClose(true);
              InsertPos:=CurPos.EndPos;
            end;
          end;
          //debugln(['TCodeCompletionCodeTool.InsertNewClassParts insert as first, somewhere after InsertPos=',CleanPosToStr(InsertPos)]);
          InsertPos:=FindLineEndOrCodeAfterPosition(InsertPos);
          //debugln(['TCodeCompletionCodeTool.InsertNewClassParts insert as first, InsertPos=',CleanPosToStr(InsertPos)]);
        end;
      end;
      CurCode:=ANodeExt.ExtTxt1;
      CurCode:=ASourceChangeCache.BeautifyCodeOptions.BeautifyStatement(
                          CurCode,Indent);
      {$IFDEF CTDEBUG}
      DebugLn('TCodeCompletionCodeTool.InsertNewClassParts:');
      DebugLn(CurCode);
      {$ENDIF}
      ASourceChangeCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,
         CurCode);
      if (not IsVariable)
      and (ASourceChangeCache.BeautifyCodeOptions.MethodInsertPolicy
        =mipClassOrder) then
      begin
        // this was a new method definition and the body should be added in
        // Class Order
        // -> save information about the inserted position
        ANodeExt.Position:=InsertPos;
      end;
    end;
    ANodeExt:=ANodeExt.Next;
  end;
end;
  
function TCodeCompletionCodeTool.InsertAllNewClassParts: boolean;
var
  NewSectionKeyWordNeeded: boolean;
  NewSection: TPascalClassSection;

  function GetTopMostPositionNode(Visibility: TPascalClassSection
    ): TCodeTreeNode;
  var
    ANodeExt: TCodeTreeNodeExtension;
  begin
    Result:=nil;
    ANodeExt:=FirstInsert;
    while ANodeExt<>nil do begin
      if (ANodeExt.Node<>nil)
      and ((Result=nil) or (Result.StartPos>ANodeExt.Node.StartPos))
      and (NodeExtHasVisibilty(ANodeExt,Visibility))
      then
        Result:=ANodeExt.Node;
      ANodeExt:=ANodeExt.Next;
    end;
  end;
  
  function GetFirstNodeExtWithVisibility(Visibility: TPascalClassSection
    ): TCodeTreeNodeExtension;
  begin
    Result:=FirstInsert;
    while Result<>nil do begin
      if NodeExtHasVisibilty(Result,Visibility) then
        break;
      Result:=Result.Next;
    end;
  end;

  function GetFirstVisibilitySectionNode: TCodeTreeNode;
  begin
    if CodeCompleteClassNode.Desc in AllClassInterfaces then
      Result:=CodeCompleteClassNode
    else begin
      Result:=CodeCompleteClassNode.FirstChild;
      while not (Result.Desc in AllClassBaseSections) do
        Result:=Result.NextBrother;
    end;
  end;
  
  procedure AddClassSection(Visibility: TPascalClassSection);
  var
    TopMostPositionNode: TCodeTreeNode;
    SectionNode: TCodeTreeNode;
    SectionKeyWord: String;
    ANode: TCodeTreeNode;
    FirstVisibilitySection: TCodeTreeNode;
    NewCode: String;
  begin
    NewClassSectionInsertPos[Visibility]:=-1;
    NewClassSectionIndent[Visibility]:=0;
    if CodeCompleteClassNode.Desc in AllClassInterfaces then begin
      // a class interface has no sections
      exit;
    end;
  
    // check if section is needed
    if GetFirstNodeExtWithVisibility(Visibility)=nil then exit;
    // search topmost position node for this Visibility
    TopMostPositionNode:=GetTopMostPositionNode(Visibility);
    SectionNode:=nil;
    // search a Visibility section in front of topmost position node
    if TopMostPositionNode<>nil then begin
      SectionNode:=TopMostPositionNode;
      while (SectionNode<>nil) and (SectionNode.Parent<>CodeCompleteClassNode)
      do
        SectionNode:=SectionNode.Parent;
      if SectionNode<>nil then
        SectionNode:=SectionNode.PriorBrother;
    end else
      SectionNode:=CodeCompleteClassNode.LastChild;
    while (SectionNode<>nil)
    and (SectionNode.Desc<>ClassSectionNodeType[Visibility]) do
      SectionNode:=SectionNode.PriorBrother;
    if (SectionNode<>nil) then begin
      //DebugLn(['AddClassSection section exists for ',NodeDescriptionAsString(ClassSectionNodeType[Visibility])]);
      exit;
    end;
    { There is no section of this Visibility in front (or at all)
      -> Insert a new section in front of topmost node.
      Normally the best place for a new section is at the end of
      the first published section. But if a variable is already
      needed in the first published section, then the new section
      must be inserted in front of all }
    FirstVisibilitySection:=GetFirstVisibilitySectionNode;
    if (TopMostPositionNode<>nil)
    and (FirstVisibilitySection<>nil)
    and ((TopMostPositionNode.HasAsParent(FirstVisibilitySection)
          or (TopMostPositionNode=FirstVisibilitySection)))
    then begin
      // topmost node is in the first section
      // -> insert the new section as the first section
      ANode:=FirstVisibilitySection;
      NewClassSectionIndent[Visibility]:=GetLineIndent(Src,ANode.StartPos);
      if (ANode.FirstChild<>nil) and (ANode.FirstChild.Desc<>ctnClassGUID)
      then
        NewClassSectionInsertPos[Visibility]:=ANode.StartPos
      else
        NewClassSectionInsertPos[Visibility]:=ANode.FirstChild.EndPos;
      if (not NewSectionKeyWordNeeded)
      and (CompareNodeIdentChars(ANode, UpperCase(PascalClassSectionKeywords[NewSection]))<>0) then begin
        NewSectionKeyWordNeeded:=true;
        NewClassSectionInsertPos[NewSection]:=
          NewClassSectionInsertPos[Visibility];
        NewClassSectionIndent[NewSection]:=
          NewClassSectionIndent[Visibility];
      end;
    end else begin
      ANode:=nil;
      case Visibility of
      pcsProtected:
        // insert after last private section
        ANode:=FindLastClassSection(CodeCompleteClassNode,ctnClassPrivate);
      pcsPublic:
        begin
          // insert after last private, protected section
          ANode:=FindClassSection(CodeCompleteClassNode,ctnClassProtected);
          if ANode=nil then
            ANode:=FindClassSection(CodeCompleteClassNode,ctnClassPrivate);
        end;
      end;
      if ANode=nil then begin
        // default: insert new section behind first published section
        ANode:=FirstVisibilitySection;
      end;
      NewClassSectionIndent[Visibility]:=GetLineIndent(Src,ANode.StartPos);
      NewClassSectionInsertPos[Visibility]:=ANode.EndPos;
    end;
    SectionKeyWord:=PascalClassSectionKeywords[Visibility];
    NewCode:=ASourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord(SectionKeyWord);
    ASourceChangeCache.Replace(gtNewLine,gtNewLine,
      NewClassSectionInsertPos[Visibility],
      NewClassSectionInsertPos[Visibility],
      GetIndentStr(NewClassSectionIndent[Visibility])+NewCode);
  end;

begin
  Result:=InsertClassHeaderComment;
  if not Result then exit;

  Result:=InsertMissingClassSemicolons;
  if not Result then exit;

  if FirstInsert=nil then begin
    Result:=true;
    exit;
  end;
  NewSectionKeyWordNeeded:=false;// 'published'/'public' keyword after first private section needed
  if CodeCompleteClassNode.Desc = ctnClass then
    NewSection := pcsPublished
  else
    NewSection := pcsPublic;

  AddClassSection(pcsPrivate);
  InsertNewClassParts(ncpPrivateVars);
  InsertNewClassParts(ncpPrivateProcs);

  AddClassSection(pcsProtected);
  InsertNewClassParts(ncpProtectedVars);
  InsertNewClassParts(ncpProtectedProcs);

  if NewSectionKeyWordNeeded and (NewSection = pcsPublic) then begin
    ASourceChangeCache.Replace(gtNewLine,gtNewLine,
      NewClassSectionInsertPos[NewSection],
      NewClassSectionInsertPos[NewSection],
      GetIndentStr(NewClassSectionIndent[NewSection])+
        ASourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord(PascalClassSectionKeywords[NewSection]));
  end
  else
    AddClassSection(pcsPublic);
  InsertNewClassParts(ncpPublicVars);
  InsertNewClassParts(ncpPublicProcs);

  if NewSectionKeyWordNeeded and (NewSection = pcsPublished) then begin
    ASourceChangeCache.Replace(gtNewLine,gtNewLine,
      NewClassSectionInsertPos[NewSection],
      NewClassSectionInsertPos[NewSection],
      GetIndentStr(NewClassSectionIndent[NewSection])+
        ASourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord(PascalClassSectionKeywords[NewSection]));
  end;
  InsertNewClassParts(ncpPublishedVars);
  InsertNewClassParts(ncpPublishedProcs);

  Result:=true;
end;

function TCodeCompletionCodeTool.InsertClassHeaderComment: boolean;
var
  ClassNode: TCodeTreeNode;
  ClassIdentifierNode: TCodeTreeNode;
  Code: String;
  InsertPos: LongInt;
  Indent: LongInt;
  StartPos, CommentStart, CommentEnd: TCodeXYPosition;
begin
  Result:=true;
  if not ASourceChangeCache.BeautifyCodeOptions.ClassHeaderComments then exit;
  // check if there is already a comment in front of the class
  
  // find the start of the class (the position in front of the class name)
  ClassNode:=CodeCompleteClassNode;
  if ClassNode=nil then exit;
  ClassIdentifierNode:=
                   ClassNode.GetNodeOfTypes([ctnTypeDefinition,ctnGenericType]);
  if ClassIdentifierNode=nil then begin
    DebugLn('TCodeCompletionCodeTool.InsertClassHeaderComment WARNING: class without name', ClassNode.DescAsString);
    exit;
  end;
  if not CleanPosToCaret(ClassIdentifierNode.StartPos,StartPos) then exit;
  Code:=ExtractDefinitionName(ClassIdentifierNode);
  
  // check if there is already a comment in front
  if FindCommentInFront(StartPos,Code,false,true,false,false,true,true,
                        CommentStart,CommentEnd)
  then
    // comment already exists
    exit;
  if CommentStart.Code=nil then ;
  if CommentEnd.Code=nil then ;

  // insert comment in front
  InsertPos:=ClassIdentifierNode.StartPos;
  Indent:=GetLineIndent(Src,InsertPos);
  Code:=GetIndentStr(Indent)+'{ '+Code+' }';
  ASourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,
                             InsertPos,InsertPos,Code);
end;

function TCodeCompletionCodeTool.InsertMissingClassSemicolons: boolean;
var
  ANode: TCodeTreeNode;
  ProcCode: String;
begin
  Result:=false;
  ANode:=FCompletingStartNode;
  while (ANode<>nil) do begin
    if ANode.Desc=ctnProcedure then begin
      if ANode.FirstChild=nil then begin
        debugln(['TCodeCompletionCodeTool.InsertMissingClassSemicolons warning: broken proc node: ',CleanPosToStr(ANode.StartPos)]);
        exit;
      end;
      ProcCode:=ExtractProcHead(ANode,[phpWithStart,
                  phpWithoutClassKeyword,
                  phpWithVarModifiers,phpWithParameterNames,phpWithResultType,
                  phpWithProcModifiers,phpDoNotAddSemicolon]);
      if (ProcCode<>'') and (ProcCode[length(ProcCode)]<>';') then begin
        // add missing semicolon at end of procedure head
        UndoReadNextAtom;
        {$IFDEF VerboseCompletionAdds}
        debugln(['TCodeCompletionCodeTool.InsertMissingClassSemicolons add missing semicolon at end of procedure head ProcCode="',dbgstr(ProcCode),'"']);
        {$ENDIF}
        if not ASourceChangeCache.Replace(gtNone,gtNone,
          CurPos.EndPos,CurPos.EndPos,';') then
            RaiseException('InsertMissingClassSemicolons: unable to insert semicolon');
      end;
      MoveCursorToFirstProcSpecifier(ANode);
      if (CurPos.Flag<>cafSemicolon) and (CurPos.EndPos<ANode.FirstChild.EndPos)
      and (LastAtoms.Count>0)
      then begin
        // add missing semicolon in front of proc modifiers
        UndoReadNextAtom;
        {$IFDEF VerboseCompletionAdds}
        debugln(['TCodeCompletionCodeTool.InsertMissingClassSemicolons add missing semicolon in front of proc modifiers ProcCode="',dbgstr(ProcCode),'"']);
        {$ENDIF}
        if not ASourceChangeCache.Replace(gtNone,gtNone,
          CurPos.EndPos,CurPos.EndPos,';') then
            RaiseException('InsertMissingClassSemicolons: unable to insert semicolon');
      end;
    end;
    // next node
    if ANode.NextBrother<>nil then begin
      ANode:=ANode.NextBrother;
    end else begin
      ANode:=ANode.Parent.NextBrother;
      while (ANode<>nil) and (ANode.Desc in (AllCodeSections+AllClassSections))
      and (ANode.FirstChild=nil) do
        ANode:=ANode.NextBrother;
      if ANode<>nil then ANode:=ANode.FirstChild;
    end;
  end;
  Result:=true;
end;

function TCodeCompletionCodeTool.InsertAllNewUnitsToMainUsesSection: boolean;
var
  UsesNode: TCodeTreeNode;
  AVLNode: TAVLTreeNode;
  CurSourceName: String;
  SectionNode: TCodeTreeNode;
  NewUsesTerm: String;
  NewUnitName: String;
  InsertPos: LongInt;
begin
  Result:=true;
  if (fNewMainUsesSectionUnits=nil) then exit;
  //DebugLn(['TCodeCompletionCodeTool.InsertAllNewUnitsToMainUsesSection ']);
  UsesNode:=FindMainUsesSection;

  // remove units, that are already in the uses section
  CurSourceName:=GetSourceName(false);
  RemoveNewMainUsesSectionUnit(PChar(CurSourceName)); // the unit itself
  if UsesNode<>nil then begin
    MoveCursorToNodeStart(UsesNode);
    ReadNextAtom; // read 'uses'
    repeat
      ReadNextAtom; // read name
      if AtomIsChar(';') then break;
      RemoveNewMainUsesSectionUnit(@Src[CurPos.StartPos]);
      ReadNextAtom;
      if UpAtomIs('IN') then begin
        ReadNextAtom;
        ReadNextAtom;
      end;
      if AtomIsChar(';') then break;
      if not AtomIsChar(',') then break;
    until (CurPos.StartPos>SrcLen);;
    
    if (fNewMainUsesSectionUnits.Count=0) then exit;
  end;
  
  // add units
  NewUsesTerm:='';
  AVLNode:=fNewMainUsesSectionUnits.FindLowest;
  while AVLNode<>nil do begin
    if NewUsesTerm<>'' then
      NewUsesTerm:=NewUsesTerm+', ';
    NewUnitName:=GetIdentifier(PChar(AVLNode.Data));
    //DebugLn(['TCodeCompletionCodeTool.InsertAllNewUnitsToMainUsesSection NewUnitName=',NewUnitName]);
    NewUsesTerm:=NewUsesTerm+NewUnitName;
    AVLNode:=fNewMainUsesSectionUnits.FindSuccessor(AVLNode);
  end;
  if UsesNode<>nil then begin
    // add unit to existing uses section
    MoveCursorToNodeStart(UsesNode); // for nice error position
    InsertPos:=UsesNode.EndPos-1; // position of semicolon at end of uses section
    NewUsesTerm:=', '+NewUsesTerm;
    if not ASourceChangeCache.Replace(gtNone,gtNone,InsertPos,InsertPos,
                                      NewUsesTerm) then exit;
  end else begin
    // create a new uses section
    if Tree.Root=nil then exit;
    SectionNode:=Tree.Root;
    MoveCursorToNodeStart(SectionNode);
    ReadNextAtom;
    if UpAtomIs('UNIT') then begin
      // search interface
      SectionNode:=SectionNode.NextBrother;
      if (SectionNode=nil) or (SectionNode.Desc<>ctnInterface) then exit;
      MoveCursorToNodeStart(SectionNode);
      ReadNextAtom;
    end;
    InsertPos:=CurPos.EndPos;
    NewUsesTerm:=ASourceChangeCache.BeautifyCodeOptions.BeautifyKeyWord('uses')
                 +' '+NewUsesTerm+';';
    if not ASourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,
                                     InsertPos,InsertPos,NewUsesTerm) then exit;
  end;
end;

function TCodeCompletionCodeTool.FindClassMethodsComment(StartPos: integer; out
  CommentStart, CommentEnd: integer): boolean;
var
  Code: String;
begin
  Result:=false;
  Code:=ExtractClassName(CodeCompleteClassNode,false);
  // search the comment
  Result:=FindCommentInFront(StartPos,Code,false,false,false,true,true,
                             CommentStart,CommentEnd)
end;

procedure TCodeCompletionCodeTool.AddNewPropertyAccessMethodsToClassProcs(
  ClassProcs: TAVLTree;  const TheClassName: string);
var ANodeExt: TCodeTreeNodeExtension;
  NewNodeExt: TCodeTreeNodeExtension;
begin
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeCompletionCodeTool.AddNewPropertyAccessMethodsToClassProcs]');
  {$ENDIF}
  // add new property access methods to ClassProcs
  ANodeExt:=FirstInsert;
  while ANodeExt<>nil do begin
    if not NodeExtIsVariable(ANodeExt) then begin
      if FindNodeInTree(ClassProcs,ANodeExt.Txt)=nil then begin
        NewNodeExt:=TCodeTreeNodeExtension.Create;
        with NewNodeExt do begin
          Txt:=UpperCaseStr(TheClassName)+'.'+ANodeExt.Txt; // Name+ParamTypeList
          ExtTxt1:=ASourceChangeCache.BeautifyCodeOptions.AddClassAndNameToProc(
             ANodeExt.ExtTxt1,TheClassName,''); // complete proc head code
          ExtTxt3:=ANodeExt.ExtTxt3;
          Position:=ANodeExt.Position;
          {$IFDEF CTDEBUG}
          DebugLn('  Txt="',Txt,'"');
          DebugLn('  ExtTxt1="',ExtTxt1,'"');
          DebugLn('  ExtTxt3="',ExtTxt3,'"');
          {$ENDIF}
        end;
        ClassProcs.Add(NewNodeExt);
      end;
    end;
    ANodeExt:=ANodeExt.Next;
  end;
end;

procedure TCodeCompletionCodeTool.CheckForOverrideAndAddInheritedCode(
  ANodeExt: TCodeTreeNodeExtension; Indent: integer);
// check for 'override' directive and add 'inherited' code to body
var
  ProcCode, ProcCall: string;
  ProcNode, ClassNode: TCodeTreeNode;
  i: integer;
  InclProcCall: Boolean;
  Beauty: TBeautifyCodeOptions;
  Params: TFindDeclarationParams;
  Tool: TFindDeclarationTool;
begin
  if not AddInheritedCodeToOverrideMethod then exit;
  {$IFDEF CTDEBUG}
  DebugLn('[TCodeCompletionCodeTool.CheckForOverrideAndAddInheritedCode]');
  {$ENDIF}
  Beauty:=ASourceChangeCache.BeautifyCodeOptions;
  ProcNode:=ANodeExt.Node;
  if (ProcNode=nil) and (ANodeExt.ExtTxt3<>'') then Exit;
  InclProcCall:=False;
  if (ProcNodeHasSpecifier(ProcNode,psOVERRIDE)) then begin
    // Check for ancestor abstract method.
    Params:=TFindDeclarationParams.Create;
    try
      ClassNode:=CodeCompleteClassNode;
      Tool:=Self;
      while Tool.FindAncestorOfClass(ClassNode,Params,True) do begin
        Tool:=Params.NewCodeTool;
        ClassNode:=Params.NewNode;
        Params.ContextNode:=ClassNode;
        Params.IdentifierTool:=Self;
        // FirstChild skips keywords 'procedure' or 'function' or 'class procedure'
        Params.SetIdentifier(Self,@Src[ProcNode.FirstChild.StartPos],nil);
        if Tool.FindIdentifierInContext(Params) then begin
          // Found ancestor definition.
          if (Params.NewNode<>nil)
          and (Params.NewNode.Desc in [ctnProcedure,ctnProcedureHead]) then
            InclProcCall:=not Tool.ProcNodeHasSpecifier(Params.NewNode,psABSTRACT);
          Break;
        end;
      end;
    finally
      Params.Free;
    end;
    if InclProcCall then begin
      ProcCode:=ExtractProcHead(ProcNode,[phpWithStart,phpAddClassname,
                                          phpWithVarModifiers,phpWithParameterNames,
                                          phpWithResultType,phpWithCallingSpecs]);
      ProcCall:='inherited '+ExtractProcHead(ProcNode,[phpWithoutClassName,
                                        phpWithParameterNames,phpWithoutParamTypes]);
      for i:=1 to length(ProcCall)-1 do
        if ProcCall[i]=';' then
          ProcCall[i]:=',';
      if ProcCall[length(ProcCall)]<>';' then
        ProcCall:=ProcCall+';';
      if NodeIsFunction(ProcNode) then
        ProcCall:=Beauty.BeautifyIdentifier('Result')+':='+ProcCall;
      ProcCode:=ProcCode+Beauty.LineEnd+'begin'+Beauty.LineEnd
                     +GetIndentStr(Beauty.Indent)+ProcCall+Beauty.LineEnd+'end;';
      ProcCode:=Beauty.BeautifyProc(ProcCode,Indent,false);
      ANodeExt.ExtTxt3:=ProcCode;
    end;
  end;
end;

function TCodeCompletionCodeTool.UpdateProcBodySignatures(ClassProcs,
  ProcBodyNodes: TAVLTree; ProcAttrCopyDefToBody: TProcHeadAttributes; out
  ProcsCopied: boolean): boolean;
{ ClassProcs and ProcBodyNodes were created by GatherProcNodes
  trees of TCodeTreeNodeExtension sorted with CompareCodeTreeNodeExt
  Node.Desc = ctnProcedure
  Node.Txt = ExtractProcHead(Node,SomeAttributes)
}
var
  BodyAVLNode: TAVLTreeNode;
  BodyNodeExt: TCodeTreeNodeExtension;
  DefNodeExt: TCodeTreeNodeExtension;
  InsertPos: LongInt;
  Indent: LongInt;
  BodyProcHeadNode: TCodeTreeNode;
  InsertEndPos: LongInt;
  NewProcCode: String;
  OldProcCode: String;
  Bodies: TFPList;
  i: Integer;
begin
  Result:=true;
  ProcsCopied:=false;
  Bodies:=nil;
  try
    // create a mapping in ClassProcs Data to ProcBodyNodes
    GuessMethodDefBodyMapping(ClassProcs,ProcBodyNodes);

    // replace body proc head(s) with class proc head(s)
    Bodies:=TFPList.Create;
    BodyAVLNode:=ProcBodyNodes.FindLowest;
    while BodyAVLNode<>nil do begin
      Bodies.Add(BodyAVLNode.Data);
      BodyAVLNode:=ProcBodyNodes.FindSuccessor(BodyAVLNode);
    end;
    for i:=0 to Bodies.Count-1 do begin
      BodyNodeExt:=TCodeTreeNodeExtension(Bodies[i]);
      DefNodeExt:=TCodeTreeNodeExtension(BodyNodeExt.Data);
      if DefNodeExt<>nil then begin
        // this body has a definition
        // compare body and definition
        NewProcCode:=ExtractProcHead(DefNodeExt.Node,ProcAttrCopyDefToBody);
        BodyProcHeadNode:=BodyNodeExt.Node.FirstChild;
        InsertPos:=BodyNodeExt.Node.StartPos;
        InsertEndPos:=BodyProcHeadNode.EndPos;
        Indent:=GetLineIndent(Src,InsertPos);
        NewProcCode:=ASourceChangeCache.BeautifyCodeOptions.BeautifyProc(
                     NewProcCode,Indent,false);
        OldProcCode:=ExtractProcHead(BodyNodeExt.Node,ProcAttrCopyDefToBody);
        if CompareTextIgnoringSpace(NewProcCode,OldProcCode,true)<>0 then begin
          // update body
          //debugln(['TCodeCompletionCodeTool.UpdateProcBodySignatures Old="',dbgstr(OldProcCode),'" New="',dbgstr(NewProcCode),'"']);
          ProcsCopied:=true;
          if not ASourceChangeCache.Replace(gtNone,gtNone,InsertPos,InsertEndPos,NewProcCode) then
            exit(false);
        end;
        // change body signature as exactly the same as definition,
        // so that no new body is created for this definition
        ProcBodyNodes.RemovePointer(BodyNodeExt);
        BodyNodeExt.Txt:=DefNodeExt.Txt;
        ProcBodyNodes.Add(BodyNodeExt);
      end;
    end;
  finally
    FreeAndNil(Bodies);
    ClearNodeExtData(ProcBodyNodes);
    ClearNodeExtData(ClassProcs);
  end;
end;

procedure TCodeCompletionCodeTool.GuessMethodDefBodyMapping(ClassProcs,
  ProcBodyNodes: TAVLTree);
{ ClassProcs and ProcBodyNodes are trees of TCodeTreeNodeExtension
  ClassProcs Data points to mapped ProcBodyNodes nodes
}

  procedure MapBodiesAndDefsByNameAndParams;
  var
    BodyAVLNode: TAVLTreeNode;
    BodyNodeExt: TCodeTreeNodeExtension;
    DefAVLNode: TAVLTreeNode;
  begin
    BodyAVLNode:=ProcBodyNodes.FindLowest;
    while BodyAVLNode<>nil do begin
      BodyNodeExt:=TCodeTreeNodeExtension(BodyAVLNode.Data);
      if BodyNodeExt.Data=nil then begin
        DefAVLNode:=ClassProcs.Find(BodyNodeExt);
        if DefAVLNode<>nil then begin
          // exact match => connect
          BodyNodeExt.Data:=DefAVLNode.Data;
          TCodeTreeNodeExtension(DefAVLNode.Data).Data:=BodyNodeExt;
        end else begin
          {$IFDEF VerboseUpdateProcBodySignatures}
          debugln(['  MapBodiesAndDefsByNameAndParams has no exact match definition: '+BodyNodeExt.Txt]);
          {$ENDIF}
        end;
      end;
      BodyAVLNode:=ProcBodyNodes.FindSuccessor(BodyAVLNode);
    end;
  end;

  function CreateNameTree(NodeExtTree: TAVLTree; SkipNodesWithData: boolean): TAVLTree;
  var
    AVLNodeExt: TAVLTreeNode;
    ProcNode: TCodeTreeNode;
    NodeExt: TCodeTreeNodeExtension;
    NewNodeExt: TCodeTreeNodeExtension;
  begin
    Result:=nil;
    if NodeExtTree=nil then exit;
    AVLNodeExt:=NodeExtTree.FindLowest;
    while AVLNodeExt<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNodeExt.Data);
      if (not SkipNodesWithData) or (NodeExt.Data=nil) then begin
        {$IFDEF VerboseUpdateProcBodySignatures}
        if NodeExtTree=ProcBodyNodes then
          debugln(['CreateNameTree body without corresponding def: ',NodeExt.Txt])
        else
          debugln(['CreateNameTree def without corresponding body: ',NodeExt.Txt]);
        {$ENDIF}
        ProcNode:=NodeExt.Node;
        NewNodeExt:=TCodeTreeNodeExtension.Create;
        NewNodeExt.Node:=ProcNode;
        NewNodeExt.Txt:=ExtractProcName(ProcNode,[phpWithoutClassName]);
        NewNodeExt.Data:=NodeExt;
        if Result=nil then
          Result:=TAVLTree.Create(@CompareCodeTreeNodeExt);
        Result.Add(NewNodeExt);
      end;
      AVLNodeExt:=NodeExtTree.FindSuccessor(AVLNodeExt);
    end;
  end;

  procedure MapBodiesAndDefsByName;
  var
    BodyNodesByName, DefNodesByName: TAVLTree;
    BodyAVLNode: TAVLTreeNode;
    LastBodySameName: TAVLTreeNode;
    FirstDefSameName: TAVLTreeNode;
    LastDefSameName: TAVLTreeNode;
    ProcBodyExt: TCodeTreeNodeExtension;
    DefExt: TCodeTreeNodeExtension;
    DefNameExt: TCodeTreeNodeExtension;
    ProcBodyByNameExt: TCodeTreeNodeExtension;
  begin
    BodyNodesByName:=nil;
    DefNodesByName:=nil;
    try
      // create a tree of proc names and nodes, that were not yet mapped
      // one for the bodies ...
      BodyNodesByName:=CreateNameTree(ProcBodyNodes,true);
      if BodyNodesByName=nil then exit;
      // ... and one for the definitions
      DefNodesByName:=CreateNameTree(ClassProcs,true);
      if DefNodesByName=nil then exit;
      // check each body if it can be mapped bijective by name
      BodyAVLNode:=BodyNodesByName.FindLowest;
      while BodyAVLNode<>nil do begin
        ProcBodyByNameExt:=TCodeTreeNodeExtension(BodyAVLNode.Data);
        ProcBodyExt:=TCodeTreeNodeExtension(ProcBodyByNameExt.Data);
        LastBodySameName:=BodyNodesByName.FindRightMostSameKey(BodyAVLNode);
        if LastBodySameName<>BodyAVLNode then begin
          // multiple bodies with same name => skip
          {$IFDEF VerboseUpdateProcBodySignatures}
          debugln(['  MapBodiesAndDefsByName multiple definitionless bodies with same name:']);
          repeat
            ProcBodyByNameExt:=TCodeTreeNodeExtension(BodyAVLNode.Data);
            ProcBodyExt:=TCodeTreeNodeExtension(ProcBodyByNameExt.Data);
            debugln(['    '+ProcBodyExt.Txt]);
            BodyAVLNode:=BodyNodesByName.FindSuccessor(BodyAVLNode);
          until BodyAVLNode<>LastBodySameName;
          {$ENDIF}
          BodyAVLNode:=LastBodySameName;
        end else begin
          // there is only one body with this name that has no exact definition
          // => search in definitions
          FirstDefSameName:=DefNodesByName.FindLeftMost(ProcBodyByNameExt);
          if FirstDefSameName<>nil then begin
            // there is at least one definition with this name and without a body
            DefNameExt:=TCodeTreeNodeExtension(FirstDefSameName.Data);
            DefExt:=TCodeTreeNodeExtension(DefNameExt.Data);
            LastDefSameName:=DefNodesByName.FindRightMostSameKey(FirstDefSameName);
            if LastDefSameName=FirstDefSameName then begin
              // there is exactly one definition with this name and without a body
              // => connect
              ProcBodyExt.Data:=DefExt;
              DefExt.Data:=ProcBodyExt;
            end else begin
              {$IFDEF VerboseUpdateProcBodySignatures}
              debugln(['  MapBodiesAndDefsByName multiple bodyless definitions with same name: ']);
              repeat
                DefNameExt:=TCodeTreeNodeExtension(FirstDefSameName.Data);
                DefExt:=TCodeTreeNodeExtension(DefNameExt.Data);
                debugln(['    '+DefExt.Txt]);
                FirstDefSameName:=DefNodesByName.FindSuccessor(FirstDefSameName);
              until FirstDefSameName=LastDefSameName;
              {$ENDIF}
            end;
          end;
        end;
        BodyAVLNode:=BodyNodesByName.FindSuccessor(BodyAVLNode);
      end;
    finally
      if BodyNodesByName<>nil then begin
        BodyNodesByName.FreeAndClear;
        BodyNodesByName.Free;
      end;
      if DefNodesByName<>nil then begin
        DefNodesByName.FreeAndClear;
        DefNodesByName.Free;
      end;
    end;
  end;

  function GetNodeExtWithoutData(Tree: TAVLTree; out Count: integer
    ): TCodeTreeNodeExtension;
  var
    AVLNode: TAVLTreeNode;
    NodeExt: TCodeTreeNodeExtension;
  begin
    Result:=nil;
    Count:=0;
    AVLNode:=Tree.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      if NodeExt.Data=nil then begin
        inc(Count);
        Result:=NodeExt;
      end;
      AVLNode:=Tree.FindSuccessor(AVLNode);
    end;
  end;

  procedure MapLastBodyAndDef;
  var
    BodyNodeExt: TCodeTreeNodeExtension;
    Cnt: integer;
    DefNodeExt: TCodeTreeNodeExtension;
  begin
    BodyNodeExt:=GetNodeExtWithoutData(ProcBodyNodes,Cnt);
    if Cnt>1 then debugln(['Note: TCodeCompletionCodeTool.UpdateProcBodySignatures.MapLastBodyAndDef multiple bodies which can not be mapped to definitions']);
    if Cnt<>1 then exit;
    DefNodeExt:=GetNodeExtWithoutData(ClassProcs,Cnt);
    if Cnt>1 then debugln(['Note: TCodeCompletionCodeTool.UpdateProcBodySignatures.MapLastBodyAndDef multiple definitions which can not be mapped to bodies']);
    if Cnt<>1 then exit;
    BodyNodeExt.Data:=DefNodeExt;
    DefNodeExt.Data:=BodyNodeExt;
  end;

begin
  ClearNodeExtData(ProcBodyNodes);
  ClearNodeExtData(ClassProcs);
  MapBodiesAndDefsByNameAndParams; // first: map all exact matches between bodies and defs
  MapBodiesAndDefsByName; // second: map remaining by name without params
  MapLastBodyAndDef; // last: map if there is exactly one unmatching body and def
end;

function TCodeCompletionCodeTool.GatherClassProcDefinitions(
  ClassNode: TCodeTreeNode; RemoveAbstracts: boolean): TAVLTree;
var
  AnAVLNode: TAVLTreeNode;
  NextAVLNode: TAVLTreeNode;
  ANodeExt: TCodeTreeNodeExtension;
  ANode: TCodeTreeNode;
begin
  Result:=GatherProcNodes(ClassNode.FirstChild,
             [phpInUpperCase,phpAddClassName],ExtractClassName(ClassNode,true));
  if RemoveAbstracts then begin
    AnAVLNode:=Result.FindLowest;
    while AnAVLNode<>nil do begin
      NextAVLNode:=Result.FindSuccessor(AnAVLNode);
      ANodeExt:=TCodeTreeNodeExtension(AnAVLNode.Data);
      ANode:=ANodeExt.Node;
      if (ANode<>nil) and (ANode.Desc=ctnProcedure)
      and ProcNodeHasSpecifier(ANode,psABSTRACT) then begin
        Result.Delete(AnAVLNode);
        ANodeExt.Free;
      end;
      AnAVLNode:=NextAVLNode;
    end;
  end;
end;

function TCodeCompletionCodeTool.GatherClassProcBodies(ClassNode: TCodeTreeNode
  ): TAVLTree;
var
  TypeSectionNode: TCodeTreeNode;
begin
  TypeSectionNode:=ClassNode.GetTopMostNodeOfType(ctnTypeSection);
  Result:=GatherProcNodes(TypeSectionNode,
                      [phpInUpperCase,phpIgnoreForwards,phpOnlyWithClassname],
                       ExtractClassName(ClassNode,true));
end;

function TCodeCompletionCodeTool.CreateMissingProcBodies: boolean;
const
  ProcAttrDefToBody = [phpWithStart,
               phpAddClassname,phpWithVarModifiers,
               phpWithParameterNames,phpWithResultType,phpWithCallingSpecs];
var
  TheClassName: string;
   
  procedure InsertProcBody(ANodeExt: TCodeTreeNodeExtension;
    InsertPos, Indent: integer);
  var ProcCode: string;
  begin
    if ANodeExt.ExtTxt3<>'' then
      ProcCode:=ANodeExt.ExtTxt3
    else
      ProcCode:=ANodeExt.ExtTxt1;
    ProcCode:=ASourceChangeCache.BeautifyCodeOptions.AddClassAndNameToProc(
                 ProcCode,TheClassName,'');
    {$IFDEF CTDEBUG}
    DebugLn('CreateMissingProcBodies InsertProcBody ',TheClassName,' "',ProcCode,'"');
    {$ENDIF}
    ProcCode:=ASourceChangeCache.BeautifyCodeOptions.BeautifyProc(
                 ProcCode,Indent,ANodeExt.ExtTxt3='');
    ASourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,ProcCode);
    if FJumpToProcName='' then begin
      // remember one proc body to jump to after the completion
      FJumpToProcName:=ANodeExt.Txt;
      if System.Pos('.',FJumpToProcName)<1 then
        FJumpToProcName:=TheClassName+'.'+FJumpToProcName;
      if FJumpToProcName[length(FJumpToProcName)]<>';' then
        FJumpToProcName:=FJumpToProcName+';';
      {$IFDEF CTDEBUG}
      DebugLn('CreateMissingProcBodies FJumpToProcName="',FJumpToProcName,'"');
      {$ENDIF}
    end;
  end;

  procedure CreateCodeForMissingProcBody(TheNodeExt: TCodeTreeNodeExtension;
    Indent: integer);
  var
    ANode: TCodeTreeNode;
    ProcCode: string;
  begin
    CheckForOverrideAndAddInheritedCode(TheNodeExt,Indent);
    if (TheNodeExt.ExtTxt1='') and (TheNodeExt.ExtTxt3='') then begin
      ANode:=TheNodeExt.Node;
      if (ANode<>nil) and (ANode.Desc=ctnProcedure) then begin
        ProcCode:=ExtractProcHead(ANode,ProcAttrDefToBody);
        TheNodeExt.ExtTxt3:=ASourceChangeCache.BeautifyCodeOptions.BeautifyProc(
                     ProcCode,Indent,true);
      end;
    end;
  end;

var
  ProcBodyNodes, ClassProcs: TAVLTree;
  ANodeExt, ANodeExt2: TCodeTreeNodeExtension;
  ExistingNode, MissingNode, AnAVLNode, NextAVLNode,
  NearestAVLNode: TAVLTreeNode;
  cmp, MissingNodePosition: integer;
  FirstExistingProcBody, LastExistingProcBody, ImplementationNode,
  ANode, ANode2: TCodeTreeNode;
  ClassStartComment, s: string;
  Caret1, Caret2: TCodeXYPosition;
  MethodInsertPolicy: TMethodInsertPolicy;
  NearestNodeValid: boolean;
  
  procedure FindTopMostAndBottomMostProcBodies;
  begin
    ExistingNode:=ProcBodyNodes.FindLowest;
    if ExistingNode<>nil then
      LastExistingProcBody:=TCodeTreeNodeExtension(ExistingNode.Data).Node
    else
      LastExistingProcBody:=nil;
    FirstExistingProcBody:=LastExistingProcBody;
    while ExistingNode<>nil do begin
      ANode:=TCodeTreeNodeExtension(ExistingNode.Data).Node;
      if ANode.StartPos<FirstExistingProcBody.StartPos then
        FirstExistingProcBody:=ANode;
      if ANode.StartPos>LastExistingProcBody.StartPos then
        LastExistingProcBody:=ANode;
      //DebugLn(['FindTopMostAndBottomMostProcBodies ',TCodeTreeNodeExtension(ExistingNode.Data).Txt]);
      ExistingNode:=ProcBodyNodes.FindSuccessor(ExistingNode);
    end;
  end;
  
  procedure CheckForDoubleDefinedMethods;
  begin
    AnAVLNode:=ClassProcs.FindLowest;
    while AnAVLNode<>nil do begin
      NextAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
      if NextAVLNode<>nil then begin
        ANodeExt:=TCodeTreeNodeExtension(AnAVLNode.Data);
        ANodeExt2:=TCodeTreeNodeExtension(NextAVLNode.Data);
        if CompareTextIgnoringSpace(ANodeExt.Txt,ANodeExt2.Txt,false)=0 then
        begin
          // proc redefined -> error
          if ANodeExt.Node.StartPos>ANodeExt2.Node.StartPos then begin
            ANode:=ANodeExt.Node;
            ANode2:=ANodeExt2.Node;
          end else begin
            ANode:=ANodeExt2.Node;
            ANode2:=ANodeExt.Node;
          end;
          debugln(['CheckForDoubleDefinedMethods redefined']);
          debugln('  1. ',ANodeExt.Txt,' ',CleanPosToStr(ANodeExt.Node.StartPos));
          debugln('  2. ',ANodeExt2.Txt,' ',CleanPosToStr(ANodeExt2.Node.StartPos));
          CleanPosToCaret(ANode.FirstChild.StartPos,Caret1);
          CleanPosToCaret(ANode2.FirstChild.StartPos,Caret2);
          s:=IntToStr(Caret2.Y)+','+IntToStr(Caret2.X);
          if Caret1.Code<>Caret2.Code then
            s:=s+' in '+CreateRelativePath(Caret2.Code.Filename,ExtractFilePath(Caret1.Code.Filename));
          MoveCursorToNodeStart(ANode.FirstChild);
          RaiseException('procedure redefined (first at '+s+')');
        end;
      end;
      AnAVLNode:=NextAVLNode;
    end;
  end;

  procedure FindInsertPointForNewClass(out InsertPos, Indent: LongInt);

    procedure SetIndentAndInsertPos(Node: TCodeTreeNode; Behind: boolean);
    begin
      Indent:=GetLineIndent(Src,Node.StartPos);
      if Behind then
        InsertPos:=FindLineEndOrCodeAfterPosition(Node.EndPos)
      else
        InsertPos:=FindLineEndOrCodeInFrontOfPosition(Node.StartPos);
    end;

  var
    StartSearchProc: TCodeTreeNode;
    NearestProcNode: TCodeTreeNode;
    UnitInterfaceNode: TCodeTreeNode;
  begin
    InsertPos:=0;
    Indent:=0;
    ImplementationNode:=FindImplementationNode;
    StartSearchProc:=nil;
    UnitInterfaceNode:=FindInterfaceNode;
    if (UnitInterfaceNode<>nil)
    and CodeCompleteClassNode.HasAsParent(UnitInterfaceNode) then begin
      // class is in interface section
      // -> insert at the end of the implementation section
      if ImplementationNode=nil then begin
        // create implementation section
        InsertPos:=UnitInterfaceNode.EndPos;
        Indent:=GetLineIndent(Src,UnitInterfaceNode.StartPos);
        if not CodeCompleteSrcChgCache.Replace(gtNewLine,gtNewLine,InsertPos,InsertPos,
          CodeCompleteSrcChgCache.BeautifyCodeOptions.BeautifyKeyWord('implementation'))
        then begin
          MoveCursorToCleanPos(InsertPos);
          RaiseException('unable to insert implementation section (read only?)');
        end;
        exit;
      end else if (ImplementationNode.FirstChild=nil)
      or (ImplementationNode.FirstChild.Desc=ctnBeginBlock) then begin
        // implementation is empty
        Indent:=GetLineIndent(Src,ImplementationNode.StartPos);
        if ImplementationNode.FirstChild<>nil then
          InsertPos:=ImplementationNode.FirstChild.StartPos
        else
          InsertPos:=ImplementationNode.EndPos;
        exit;
      end;
      StartSearchProc:=ImplementationNode.FirstChild;
    end else begin
      // class is not in interface section
      StartSearchProc:=CodeCompleteClassNode.GetTopMostNodeOfType(ctnTypeSection);
    end;
    case ASourceChangeCache.BeautifyCodeOptions.ForwardProcBodyInsertPolicy of
    fpipInFrontOfMethods:
      begin
        // Try to insert new proc in front of existing methods

        // find first method
        NearestProcNode:=StartSearchProc;
        while (NearestProcNode<>nil) and (NearestProcNode.Desc<>ctnBeginBlock)
        and (not NodeIsMethodBody(NearestProcNode)) do
          NearestProcNode:=NearestProcNode.NextBrother;
        if NearestProcNode<>nil then begin
          // the comments in front of the first method probably belong to the class
          // Therefore insert behind the node in front of the first method
          Indent:=GetLineIndent(Src,NearestProcNode.StartPos);
          if NearestProcNode.PriorBrother<>nil then begin
            InsertPos:=FindLineEndOrCodeAfterPosition(NearestProcNode.PriorBrother.EndPos);
          end else begin
            InsertPos:=NearestProcNode.Parent.StartPos;
            while (InsertPos<=NearestProcNode.StartPos)
            and (not IsSpaceChar[Src[InsertPos]]) do
              inc(InsertPos);
          end;
          exit;
        end;
      end;
    fpipBehindMethods:
      begin
        // Try to insert new proc behind existing methods

        // find last method (go to last brother and search backwards)
        if (StartSearchProc<>nil)
        and (StartSearchProc.Parent<>nil) then begin
          NearestProcNode:=StartSearchProc.Parent.LastChild;
        end;
        while (NearestProcNode<>nil) and (not NodeIsMethodBody(NearestProcNode)) do
          NearestProcNode:=NearestProcNode.PriorBrother;
        if NearestProcNode<>nil then begin
          SetIndentAndInsertPos(NearestProcNode,NearestProcNode.Desc<>ctnBeginBlock);
          exit;
        end;
      end;
    end;

    // Default position: Insert behind last node
    if (StartSearchProc<>nil)
    and (StartSearchProc.Parent<>nil) then begin
      NearestProcNode:=StartSearchProc.Parent.LastChild;
      if NearestProcNode.Desc=ctnBeginBlock then
        NearestProcNode:=NearestProcNode.PriorBrother;
    end;
    if NearestProcNode<>nil then begin
      Indent:=0;
      InsertPos:=FindLineEndOrCodeAfterPosition(NearestProcNode.EndPos);
      SetIndentAndInsertPos(NearestProcNode,true);
      exit;
    end;

    RaiseException('TCodeCompletionCodeTool.CreateMissingProcBodies.FindInsertPointForNewClass '
     +' Internal Error: no insert position found');
  end;
  
  procedure InsertClassMethodsComment(InsertPos, Indent: integer);
  var
    CommentStartPos: integer;
    CommentEndPos: integer;
  begin
    // insert class comment
    if ClassProcs.Count=0 then exit;
    if not ASourceChangeCache.BeautifyCodeOptions.ClassImplementationComments
    then
      exit;
    // find the start of the class (the position in front of the class name)
    // check if there is already a comment in front
    if FindClassMethodsComment(InsertPos,CommentStartPos,CommentEndPos) then begin
      // comment already exists
      exit;
    end;
    ClassStartComment:=GetIndentStr(Indent)
                       +'{ '+ExtractClassName(CodeCompleteClassNode,false)+' }';
    ASourceChangeCache.Replace(gtEmptyLine,gtEmptyLine,InsertPos,InsertPos,
                               ClassStartComment);
  end;
  
var
  InsertPos: integer;
  Indent: integer;
  ProcsCopied: boolean;
begin
  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CreateMissingProcBodies Gather existing method bodies ... ');
  {$ENDIF}
  if CodeCompleteClassNode.Desc in AllClassInterfaces then begin
    // interfaces have no implementations
    {$IFDEF CTDEBUG}
    debugln(['TCodeCompletionCodeTool.CreateMissingProcBodies interface ',CodeCompleteClassNode.DescAsString]);
    {$ENDIF}
    exit(true);
  end;
  
  Result:=false;
  MethodInsertPolicy:=ASourceChangeCache.BeautifyCodeOptions.MethodInsertPolicy;
  // gather existing class proc bodies
  ClassProcs:=nil;
  ProcBodyNodes:=nil;
  try
    //debugln(['TCodeCompletionCodeTool.CreateMissingProcBodies get class procs of ',CodeCompleteClassNode.DescAsString]);
    ClassProcs:=GatherClassProcDefinitions(CodeCompleteClassNode,true);
    //debugln(['TCodeCompletionCodeTool.CreateMissingProcBodies get bodies of ',CodeCompleteClassNode.DescAsString]);
    ProcBodyNodes:=GatherClassProcBodies(CodeCompleteClassNode);

    {AnAVLNode:=ClassProcs.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' Gathered ProcDef ',TCodeTreeNodeExtension(AnAVLNode.Data).Txt);
      AnAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
    end;
    AnAVLNode:=ProcBodyNodes.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' Gathered ProcBody ',TCodeTreeNodeExtension(AnAVLNode.Data).Txt);
      AnAVLNode:=ProcBodyNodes.FindSuccessor(AnAVLNode);
    end;}

    // find topmost and bottommost proc body
    FindTopMostAndBottomMostProcBodies;

    {$IFDEF CTDEBUG}
    DebugLn('TCodeCompletionCodeTool.CreateMissingProcBodies Gather existing method declarations ... ');
    {$ENDIF}
    TheClassName:=ExtractClassName(CodeCompleteClassNode,false);

    // check for double defined methods in ClassProcs
    CheckForDoubleDefinedMethods;

    // check for changed procs
    if not UpdateProcBodySignatures(ClassProcs,ProcBodyNodes,ProcAttrDefToBody,
      ProcsCopied)
    then exit;

    // there are new methods

    CurNode:=FirstExistingProcBody;
    
    {AnAVLNode:=ClassProcs.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' SignaturesUpdated ProcDef ',TCodeTreeNodeExtension(AnAVLNode.Data).Txt);
      AnAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
    end;}
    
    AddNewPropertyAccessMethodsToClassProcs(ClassProcs,TheClassName);

    {AnAVLNode:=ClassProcs.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' AfterPropsCompleted ',TCodeTreeNodeExtension(AnAVLNode.Data).Txt);
      AnAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
    end;}

    if MethodInsertPolicy=mipClassOrder then begin
      // insert in ClassOrder -> get a definition position for every method
      AnAVLNode:=ClassProcs.FindLowest;
      while AnAVLNode<>nil do begin
        ANodeExt:=TCodeTreeNodeExtension(AnAVLNode.Data);
        if ANodeExt.Position<1 then
          // position not set => this proc was already there => there is a node
          ANodeExt.Position:=ANodeExt.Node.StartPos;
        // find corresponding proc body
        NextAVLNode:=ProcBodyNodes.Find(ANodeExt);
        if NextAVLNode<>nil then begin
          // NextAVLNode.Data is the TCodeTreeNodeExtension for the method body
          // (note 1)
          ANodeExt.Data:=NextAVLNode.Data;
        end;
        AnAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
      end;
      // sort the method definitions with the definition position
      ClassProcs.OnCompare:=@CompareCodeTreeNodeExtWithPos;
    end;

    {AnAVLNode:=ClassProcs.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' BeforeAddMissing ProcDef "',TCodeTreeNodeExtension(AnAVLNode.Data).Txt,'"');
      AnAVLNode:=ClassProcs.FindSuccessor(AnAVLNode);
    end;
    AnAVLNode:=ProcBodyNodes.FindLowest;
    while AnAVLNode<>nil do begin
      DebugLn(' BeforeAddMissing ProcBody "',TCodeTreeNodeExtension(AnAVLNode.Data).Txt,'"');
      AnAVLNode:=ProcBodyNodes.FindSuccessor(AnAVLNode);
    end; }

    // search for missing proc bodies
    if (ProcBodyNodes.Count=0) then begin
      // there were no old proc bodies of the class -> start class
      {$IFDEF CTDEBUG}
      DebugLn('TCodeCompletionCodeTool.CreateMissingProcBodies Starting class in implementation ');
      {$ENDIF}
      FindInsertPointForNewClass(InsertPos,Indent);
      //debugln(['TCodeCompletionCodeTool.CreateMissingProcBodies Indent=',Indent,' InsertPos=',dbgstr(copy(Src,InsertPos-10,10)),'|',dbgstr(copy(Src,InsertPos,10))]);
      InsertClassMethodsComment(InsertPos,Indent);

      // insert all proc bodies
      MissingNode:=ClassProcs.FindHighest;
      while (MissingNode<>nil) do begin
        ANodeExt:=TCodeTreeNodeExtension(MissingNode.Data);
        CreateCodeForMissingProcBody(ANodeExt,Indent);
        InsertProcBody(ANodeExt,InsertPos,Indent);
        MissingNode:=ClassProcs.FindPrecessor(MissingNode);
      end;
      
    end else begin
      // there were old class procs already
      // -> search a good Insert Position behind or in front of
      //    another proc body of this class
      {$IFDEF CTDEBUG}
      DebugLn('TCodeCompletionCodeTool.CreateMissingProcBodies  Insert missing bodies between existing ... ClassProcs.Count=',dbgs(ClassProcs.Count));
      {$ENDIF}

      // set default insert position
      Indent:=GetLineIndent(Src,LastExistingProcBody.StartPos);
      InsertPos:=FindLineEndOrCodeAfterPosition(LastExistingProcBody.EndPos);
                        
      // check for all defined class methods (MissingNode), if there is a body
      MissingNode:=ClassProcs.FindHighest;
      NearestNodeValid:=false;
      while (MissingNode<>nil) do begin
        ANodeExt:=TCodeTreeNodeExtension(MissingNode.Data);
        ExistingNode:=ProcBodyNodes.Find(MissingNode.Data);
        //DebugLn(['TCodeCompletionCodeTool.CreateMissingProcBodies ANodeExt.Txt=',ANodeExt.Txt,' ExistingNode=',ExistingNode<>nil]);
        if ExistingNode=nil then begin
          //DebugLn(['TCodeCompletionCodeTool.CreateMissingProcBodies ANodeExt.Txt=',ANodeExt.Txt,' ExistingNode=',TCodeTreeNodeExtension(ExistingNode.Data).Txt]);
          // MissingNode does not have a body -> insert proc body
          case MethodInsertPolicy of
          mipAlphabetically:
            begin
              // search alphabetically nearest proc body
              ExistingNode:=ProcBodyNodes.FindNearest(MissingNode.Data);
              cmp:=CompareCodeTreeNodeExt(ExistingNode.Data,MissingNode.Data);
              if (cmp<0) then begin
                AnAVLNode:=ProcBodyNodes.FindSuccessor(ExistingNode);
                if AnAVLNode<>nil then begin
                  ExistingNode:=AnAVLNode;
                  cmp:=1;
                end;
              end;
              ANodeExt2:=TCodeTreeNodeExtension(ExistingNode.Data);
              ANode:=ANodeExt2.Node;
              Indent:=GetLineIndent(Src,ANode.StartPos);
              if cmp>0 then begin
                // insert behind ExistingNode
                InsertPos:=FindLineEndOrCodeAfterPosition(ANode.EndPos);
              end else begin
                // insert in front of ExistingNode
                InsertPos:=FindLineEndOrCodeInFrontOfPosition(ANode.StartPos);
              end;
            end;

          mipClassOrder:
            begin
              // search definition-position nearest proc node
              MissingNodePosition:=ANodeExt.Position;
              if not NearestNodeValid then begin
                // search NearestAVLNode method with body in front of MissingNode
                // and NextAVLNode method with body behind MissingNode
                NearestAVLNode:=nil;
                NextAVLNode:=ClassProcs.FindHighest;
                NearestNodeValid:=true;
              end;
              while (NextAVLNode<>nil) do begin
                ANodeExt2:=TCodeTreeNodeExtension(NextAVLNode.Data);
                if ANodeExt2.Data<>nil then begin
                  // method has body
                  if ANodeExt2.Position>MissingNodePosition then
                    break;
                  NearestAVLNode:=NextAVLNode;
                end;
                NextAVLNode:=ClassProcs.FindPrecessor(NextAVLNode);
              end;
              if NearestAVLNode<>nil then begin
                // there is a NearestAVLNode in front -> insert behind body
                ANodeExt2:=TCodeTreeNodeExtension(NearestAVLNode.Data);
                // see above (note 1) for ANodeExt2.Data
                ANode:=TCodeTreeNodeExtension(ANodeExt2.Data).Node;
                Indent:=GetLineIndent(Src,ANode.StartPos);
                InsertPos:=FindLineEndOrCodeAfterPosition(ANode.EndPos);
              end else if NextAVLNode<>nil then begin
                // there is a NextAVLNode behind -> insert in front of body
                ANodeExt2:=TCodeTreeNodeExtension(NextAVLNode.Data);
                // see above (note 1) for ANodeExt2.Data
                ANode:=TCodeTreeNodeExtension(ANodeExt2.Data).Node;
                Indent:=GetLineIndent(Src,ANode.StartPos);
                InsertPos:=FindLineEndOrCodeInFrontOfPosition(ANode.StartPos);
              end;
            end;
          end;
          CreateCodeForMissingProcBody(ANodeExt,Indent);
          InsertProcBody(ANodeExt,InsertPos,0);
        end;
        MissingNode:=ClassProcs.FindPrecessor(MissingNode);
      end;
    end;
    Result:=true;
  finally
    DisposeAVLTree(ClassProcs);
    DisposeAVLTree(ProcBodyNodes);
  end;
end;

function TCodeCompletionCodeTool.ApplyChangesAndJumpToFirstNewProc(
  CleanPos: integer; OldTopLine: integer; AddMissingProcBodies: boolean;
  out NewPos: TCodeXYPosition; out NewTopLine: integer): boolean;
var
  OldCodeXYPos: TCodeXYPosition;
  OldCodePos: TCodePosition;
  CursorNode: TCodeTreeNode;
  CurClassName: String;
  ProcNode: TCodeTreeNode;
begin
  Result:=false;

  try
    // extend class declaration
    if not InsertAllNewClassParts then
      RaiseException(ctsErrorDuringInsertingNewClassParts);

    // create missing method bodies
    if AddMissingProcBodies and (not CreateMissingProcBodies) then
      RaiseException(ctsErrorDuringCreationOfNewProcBodies);

    CurClassName:=ExtractClassName(CodeCompleteClassNode,false);

    // apply the changes and jump to first new proc body
    if not CleanPosToCodePos(CleanPos,OldCodePos) then
      RaiseException('TCodeCompletionCodeTool.CompleteCode Internal Error CleanPosToCodePos');
    if not CleanPosToCaret(CleanPos,OldCodeXYPos) then
      RaiseException('TCodeCompletionCodeTool.CompleteCode Internal Error CleanPosToCaret');
    if not ASourceChangeCache.Apply then
      RaiseException(ctsUnableToApplyChanges);

  finally
    FreeClassInsertionList;
  end;

  if FJumpToProcName<>'' then begin
    {$IFDEF CTDEBUG}
    DebugLn('TCodeCompletionCodeTool.ApplyChangesAndJumpToFirstNewProc Jump to new proc body ... "',FJumpToProcName,'"');
    {$ENDIF}
    // there was a new proc body
    // -> find it and jump to

    // reparse code
    BuildTreeAndGetCleanPos(OldCodeXYPos,CleanPos);
    // find CodeTreeNode at cursor
    CursorNode:=FindDeepestNodeAtPos(CleanPos,true);
    // due to insertions in front of the class, the cursor position could
    // have changed
    if CursorNode<>nil then
      CursorNode:=CursorNode.GetTopMostNodeOfType(ctnTypeSection);
    FCodeCompleteClassNode:=FindClassNode(CursorNode,CurClassName,true,false);
    if CodeCompleteClassNode=nil then
      RaiseException('oops, I lost your class');
    ProcNode:=FindProcNode(CursorNode,FJumpToProcName,[phpInUpperCase,phpIgnoreForwards]);
    if ProcNode=nil then begin
      debugln(['TCodeCompletionCodeTool.ApplyChangesAndJumpToFirstNewProc Proc="',FJumpToProcName,'"']);
      RaiseException(ctsNewProcBodyNotFound);
    end;
    Result:=FindJumpPointInProcNode(ProcNode,NewPos,NewTopLine);
  end else begin
    {$IFDEF CTDEBUG}
    DebugLn('TCodeCompletionCodeTool.ApplyChangesAndJumpToFirstNewProc Adjust Cursor ... ');
    {$ENDIF}
    // there was no new proc body
    // -> adjust cursor
    AdjustCursor(OldCodePos,OldTopLine,NewPos,NewTopLine);
    Result:=true;
  end;
end;

function TCodeCompletionCodeTool.CompleteCode(CursorPos: TCodeXYPosition;
  OldTopLine: integer; out NewPos: TCodeXYPosition; out NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  OldCleanCursorPos: LongInt;
var
  ProcNode, ImplementationNode, AClassNode: TCodeTreeNode;
  IsEventAssignment: boolean;
begin
  //DebugLn(['TCodeCompletionCodeTool.CompleteCode CursorPos=',Dbgs(CursorPos),' OldTopLine=',OldTopLine]);

  Result:=false;
  if (SourceChangeCache=nil) then 
    RaiseException('need a SourceChangeCache');
  BuildTreeAndGetCleanPos(trTillCursor,lsrEnd,CursorPos,CleanCursorPos,
                          [btSetIgnoreErrorPos]);
  OldCleanCursorPos:=CleanCursorPos;
  NewPos:=CleanCodeXYPosition;
  NewTopLine:=0;

  // find CodeTreeNode at cursor
  // skip newline chars
  while (CleanCursorPos>1) and (Src[CleanCursorPos] in [#10,#13]) do
    dec(CleanCursorPos);
  // skip space (first try left)
  while (CleanCursorPos>1) and (Src[CleanCursorPos] in [' ',#9,';']) do
    dec(CleanCursorPos);
  if (CleanCursorPos>0) and (CleanCursorPos<SrcLen)
  and (Src[CleanCursorPos] in [#10,#13]) then begin
    // then try right
    repeat
      inc(CleanCursorPos);
    until (CleanCursorPos>=SrcLen) or (not (Src[CleanCursorPos] in [' ',#9]));
  end;
  
  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  CodeCompleteSrcChgCache:=SourceChangeCache;

  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode A CleanCursorPos=',dbgs(CleanCursorPos),' NodeDesc=',NodeDescriptionAsString(CursorNode.Desc));
  {$ENDIF}
  ImplementationNode:=FindImplementationNode;
  if ImplementationNode=nil then ImplementationNode:=Tree.Root;

  // test if in a class
  AClassNode:=FindClassOrInterfaceNode(CursorNode);
  if AClassNode<>nil then begin
    Result:=CompleteClass(AClassNode,CleanCursorPos,OldTopLine,CursorNode,
                          NewPos,NewTopLine);
    exit;
  end;
  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode not in-a-class ... ');
  {$ENDIF}
  
  // test if forward proc
  //debugln('TCodeCompletionCodeTool.CompleteCode ',CursorNode.DescAsString);
  ProcNode:=CursorNode.GetNodeOfType(ctnProcedure);
  if (ProcNode=nil) and (CursorNode.Desc=ctnProcedure) then
    ProcNode:=CursorNode;
  if (ProcNode<>nil) and (ProcNode.Desc=ctnProcedure)
  and ((ProcNode.SubDesc and ctnsForwardDeclaration)>0) then begin
    // Node is forward Proc
    Result:=CompleteForwardProcs(CursorPos,ProcNode,CursorNode,NewPos,NewTopLine,
                         SourceChangeCache);
    exit;
  end;
  
  // test if Event assignment (MyClick:=@Button1.OnClick)
  Result:=CompleteEventAssignment(CleanCursorPos,OldTopLine,CursorNode,
                         IsEventAssignment,NewPos,NewTopLine,SourceChangeCache);
  if IsEventAssignment then exit;
  
  // test if Local variable assignment (i:=3)
  Result:=CompleteLocalVariableAssignment(CleanCursorPos,OldTopLine,
                                CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;

  // test if Local variable iterator (for i in j)
  Result:=CompleteLocalVariableForIn(CleanCursorPos,OldTopLine,
                                CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;

  // test if undeclared local variable as parameter (GetPenPos(x,y))
  Result:=CompleteLocalIdentifierByParameter(CleanCursorPos,OldTopLine,
                                CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;
  
  // test if procedure call
  Result:=CompleteProcByCall(CleanCursorPos,OldTopLine,
                               CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;

  // test if method body
  Result:=CompleteMethodByBody(OldCleanCursorPos,OldTopLine,CursorNode,
                         NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;

  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CompleteCode  nothing to complete ... ');
  {$ENDIF}
end;

function TCodeCompletionCodeTool.CreateVariableForIdentifier(
  CursorPos: TCodeXYPosition; OldTopLine: integer; out NewPos: TCodeXYPosition;
  out NewTopLine: integer; SourceChangeCache: TSourceChangeCache): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
begin
  Result:=false;
  NewPos:=CleanCodeXYPosition;
  NewTopLine:=0;
  if (SourceChangeCache=nil) then
    RaiseException('need a SourceChangeCache');
  BuildTreeAndGetCleanPos(CursorPos, CleanCursorPos);

  CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);
  CodeCompleteSrcChgCache:=SourceChangeCache;

  {$IFDEF CTDEBUG}
  DebugLn('TCodeCompletionCodeTool.CreateVariableForIdentifier A CleanCursorPos=',dbgs(CleanCursorPos),' NodeDesc=',NodeDescriptionAsString(CursorNode.Desc));
  {$ENDIF}

  // test if Local variable assignment (i:=3)
  Result:=CompleteLocalVariableAssignment(CleanCursorPos,OldTopLine,
                                CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;

  // test if undeclared local variable as parameter (GetPenPos(x,y))
  Result:=CompleteLocalIdentifierByParameter(CleanCursorPos,OldTopLine,
                                CursorNode,NewPos,NewTopLine,SourceChangeCache);
  if Result then exit;
end;

function TCodeCompletionCodeTool.AddMethods(CursorPos: TCodeXYPosition;
  OldTopLine: integer;
  ListOfPCodeXYPosition: TFPList;
  const VirtualToOverride: boolean;
  out NewPos: TCodeXYPosition; out NewTopLine: integer;
  SourceChangeCache: TSourceChangeCache): boolean;
var
  CleanCursorPos: integer;
  CursorNode: TCodeTreeNode;
  i: Integer;
  CodeXYPos: TCodeXYPosition;
  ProcNode: TCodeTreeNode;
  NewMethods: TAVLTree;// Tree of TCodeTreeNodeExtension
  NewCodeTool: TFindDeclarationTool;
  CleanProcCode: String;
  FullProcCode: String;
  VirtualStartPos: LongInt;
  VirtualEndPos: integer;
  VisibilityDesc: TCodeTreeNodeDesc;
  NodeExt: TCodeTreeNodeExtension;
  AVLNode: TAVLTreeNode;
  ProcName: String;
  NewClassPart: TNewClassPart;
  Beautifier: TBeautifyCodeOptions;
  ProcCode: String;
  CurClassName: String;
begin
  Result:=false;
  if (ListOfPCodeXYPosition=nil) or (ListOfPCodeXYPosition.Count=0) then
    exit(true);
  
  if (SourceChangeCache=nil) then
    RaiseException('need a SourceChangeCache');

  CodeCompleteSrcChgCache:=SourceChangeCache;
  Beautifier:=SourceChangeCache.BeautifyCodeOptions;
  NewMethods:=TAVLTree.Create(@CompareCodeTreeNodeExt);
  try
    ActivateGlobalWriteLock;
    try
      // collect all methods
      for i:=0 to ListOfPCodeXYPosition.Count-1 do begin
        //get next code position
        CodeXYPos:=PCodeXYPosition(ListOfPCodeXYPosition[i])^;
        // get codetool for this position
        NewCodeTool:=OnGetCodeToolForBuffer(Self,CodeXYPos.Code,true);
        if NewCodeTool=nil then begin
          DebugLn(['TCodeCompletionCodeTool.AddMethods unit not found for source ',CodeXYPos.Code.Filename,'(',CodeXYPos.Y,',',CodeXYPos.X,')']);
          exit;
        end;
        // parse unit
        NewCodeTool.BuildTreeAndGetCleanPos(CodeXYPos,CleanCursorPos);
        // find node at position
        ProcNode:=NewCodeTool.BuildSubTreeAndFindDeepestNodeAtPos(CleanCursorPos,true);
        if (ProcNode.Desc<>ctnProcedure)
        or (ProcNode.Parent=nil) then begin
          NewCodeTool.MoveCursorToNodeStart(ProcNode);
          RaiseException('TCodeCompletionCodeTool.AddMethods source position not a procedure');
        end;
        // find visibility
        VisibilityDesc:=ctnClassPublic;
        if ProcNode.Parent.Desc in AllClassBaseSections then
          VisibilityDesc:=ProcNode.Parent.Desc;
        // extract proc
        ProcName:=NewCodeTool.ExtractProcName(ProcNode,[phpWithoutClassName,phpInUpperCase]);
        CleanProcCode:=NewCodeTool.ExtractProcHead(ProcNode,[phpWithoutClassName]);
        FullProcCode:=NewCodeTool.ExtractProcHead(ProcNode,
                    [phpWithStart,phpWithoutClassName,phpWithVarModifiers,
                     phpWithParameterNames,phpWithDefaultValues,phpWithResultType,
                     phpWithCallingSpecs,phpWithProcModifiers]);
        if VirtualToOverride then begin
          VirtualStartPos:=SearchProcSpecifier(FullProcCode,'virtual',
                          VirtualEndPos,NewCodeTool.Scanner.NestedComments);
          if VirtualStartPos>=1 then begin
            // replace virtual with override
            FullProcCode:=copy(FullProcCode,1,VirtualStartPos-1)
                         +'override;'
                         +copy(FullProcCode,VirtualEndPos,length(FullProcCode));
          end;
          // remove abstract
          FullProcCode:=RemoveProcSpecifier(FullProcCode,'abstract',
                                            NewCodeTool.Scanner.NestedComments);
        end;

        ProcCode:=NewCodeTool.ExtractProcHead(ProcNode,[phpWithStart,
                  phpWithoutClassName,phpWithVarModifiers,phpWithParameterNames,
                  phpWithResultType,phpWithCallingSpecs]);
        ProcCode:=ProcCode+Beautifier.LineEnd
                    +'begin'+Beautifier.LineEnd
                    +GetIndentStr(Beautifier.Indent)+Beautifier.LineEnd
                    +'end;';

        // add method data
        NodeExt:=TCodeTreeNodeExtension.Create;
        NodeExt.Txt:=CleanProcCode;
        NodeExt.ExtTxt1:=FullProcCode;
        NodeExt.ExtTxt2:=ProcName;
        NodeExt.ExtTxt3:=ProcCode;
        NodeExt.Flags:=VisibilityDesc;
        NewMethods.Add(NodeExt);
        //DebugLn(['TCodeCompletionCodeTool.AddMethods ',i,' CleanProcTxt=',CleanProcCode,' FullProcTxt=',FullProcCode]);
      end;

    finally
      DeactivateGlobalWriteLock;
    end;

    BuildTreeAndGetCleanPos(CursorPos,CleanCursorPos);

    // find node at position
    CursorNode:=FindDeepestNodeAtPos(CleanCursorPos,true);

    // if cursor is on type node, find class node
    if CursorNode.Desc=ctnTypeDefinition then
      CursorNode:=CursorNode.FirstChild
    else if CursorNode.Desc=ctnGenericType then
      CursorNode:=CursorNode.LastChild
    else
      CursorNode:=FindClassOrInterfaceNode(CursorNode);
    if (CursorNode=nil) or (not (CursorNode.Desc in AllClasses)) then begin
      DebugLn(['TIdentCompletionTool.AddMethods cursor not in a class']);
      exit;
    end;
    //DebugLn(['TCodeCompletionCodeTool.AddMethods CursorNode=',CursorNode.DescAsString]);

    CodeCompleteSrcChgCache:=SourceChangeCache;
    CodeCompleteClassNode:=CursorNode;
    CurClassName:=ExtractClassName(CursorNode,false);

    // add methods
    AVLNode:=NewMethods.FindLowest;
    while AVLNode<>nil do begin
      NodeExt:=TCodeTreeNodeExtension(AVLNode.Data);
      CleanProcCode:=NodeExt.Txt;
      FullProcCode:=NodeExt.ExtTxt1;
      ProcName:=NodeExt.ExtTxt2;
      ProcCode:=NodeExt.ExtTxt3;
      VisibilityDesc:=TCodeTreeNodeDesc(NodeExt.Flags);
      case VisibilityDesc of
      ctnClassPrivate:   NewClassPart:=ncpPrivateProcs;
      ctnClassProtected: NewClassPart:=ncpProtectedProcs;
      ctnClassPublic:    NewClassPart:=ncpPublicProcs;
      ctnClassPublished: NewClassPart:=ncpPublishedProcs;
      else               NewClassPart:=ncpPublicProcs;
      end;

      // change classname
      ProcCode:=Beautifier.AddClassAndNameToProc(ProcCode,CurClassName,ProcName);
      AddClassInsertion(CleanProcCode,FullProcCode,ProcName,NewClassPart,nil,
                        ProcCode);
      
      AVLNode:=NewMethods.FindSuccessor(AVLNode);
    end;
    
    // apply changes
    if not ApplyChangesAndJumpToFirstNewProc(CleanCursorPos,OldTopLine,true,
      NewPos,NewTopLine) then exit;

    Result:=true;
  finally
    FreeClassInsertionList;
    DisposeAVLTree(NewMethods);
  end;
end;

constructor TCodeCompletionCodeTool.Create;
begin
  inherited Create;
  FSetPropertyVariablename:='AValue';
  FCompleteProperties:=true;
  FAddInheritedCodeToOverrideMethod:=true;
end;


end.

