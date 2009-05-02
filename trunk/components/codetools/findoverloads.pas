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
    A graph of declaration overloads.
}
unit FindOverloads;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileProcs, BasicCodeTools, CodeAtom, CodeTree, CodeGraph,
  CodeCache, FindDeclarationTool, AVL_Tree, FindDeclarationCache, StdCodeTools;

type

  { TOverloadsGraphNode }

  TOverloadsGraphNode = class(TCodeGraphNode)
  public
    Identifier: string;
    Tool: TFindDeclarationTool;
    function AsDebugString: string;
  end;

  TOverloadsGraphEdgeType = (
    ogetParentChild,
    ogetAncestorInherited,
    ogetAliasOld
    );
  TOverloadsGraphEdgeTypes = set of TOverloadsGraphEdgeType;

  { TOverloadsGraphEdge }

  TOverloadsGraphEdge = class(TCodeGraphEdge)
  public
    Typ: TOverloadsGraphEdgeType;
    function AsDebugString: string;
  end;

  { TDeclarationOverloadsGraph }

  TDeclarationOverloadsGraph = class
  private
    FGraph: TCodeGraph;
    FIdentifier: string;
    FOnGetCodeToolForBuffer: TOnGetCodeToolForBuffer;
    FStartCode: TCodeBuffer;
    FStartX: integer;
    FStartY: integer;
    function AddContext(Tool: TFindDeclarationTool;
                        CodeNode: TCodeTreeNode): TOverloadsGraphNode;
    function AddEdge(Typ: TOverloadsGraphEdgeType;
                     FromNode, ToNode: TCodeTreeNode): TOverloadsGraphEdge;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Init(Code: TCodeBuffer; X,Y: integer): Boolean;
    procedure ScanToolForIdentifier(Tool: TStandardCodeTool;
                                    OnlyInterface: boolean);
    property Identifier: string read FIdentifier;
    property Graph: TCodeGraph read FGraph;
    property StartCode: TCodeBuffer read FStartCode;
    property StartX: integer read FStartX;
    property StartY: integer read FStartY;
    property OnGetCodeToolForBuffer: TOnGetCodeToolForBuffer
                     read FOnGetCodeToolForBuffer write FOnGetCodeToolForBuffer;
  end;

const
  OverloadsGraphEdgeTypeNames: array[TOverloadsGraphEdgeType] of string = (
    'Parent-Child',
    'Ancestor-Inherited',
    'Alias-Old'
    );

implementation

{ TDeclarationOverloadsGraph }

function TDeclarationOverloadsGraph.AddContext(Tool: TFindDeclarationTool;
  CodeNode: TCodeTreeNode): TOverloadsGraphNode;
var
  ParentCodeNode: TCodeTreeNode;
  ParentGraphNode: TOverloadsGraphNode;
  ClassNode: TCodeTreeNode;
  Params: TFindDeclarationParams;
  ListOfPFindContext: TFPList;
  i: Integer;
  ContextPtr: PFindContext;
  AncestorGraphNode: TOverloadsGraphNode;
  Context: TFindContext;
  AliasGraphNode: TOverloadsGraphNode;
begin
  Result:=TOverloadsGraphNode(Graph.GetGraphNode(CodeNode,false));
  if Result<>nil then exit;
  // add new node
  //DebugLn(['TDeclarationOverloadsGraph.AddContext ',Tool.MainFilename,' ',CodeNode.DescAsString,' "',dbgstr(copy(Tool.Src,CodeNode.StartPos,20)),'"']);
  Result:=TOverloadsGraphNode(Graph.GetGraphNode(CodeNode,true));
  Result.Tool:=Tool;
  if CodeNode.Desc in AllIdentifierDefinitions then
    Result.Identifier:=Tool.ExtractDefinitionName(CodeNode)
  else begin
    case CodeNode.Desc of
    ctnEnumIdentifier: Result.Identifier:=GetIdentifier(@Tool.Src[CodeNode.StartPos]);
    end;
  end;

  // add parent nodes to graph
  ParentCodeNode:=CodeNode.Parent;
  while ParentCodeNode<>nil do begin
    //DebugLn(['TDeclarationOverloadsGraph.AddContext ',ParentCodeNode.DescAsString]);
    if ParentCodeNode.Desc in
      AllSourceTypes+[ctnClass,ctnClassInterface,ctnRecordType]
    then begin
      //DebugLn(['TDeclarationOverloadsGraph.AddContext ADD parent']);
      ParentGraphNode:=AddContext(Tool,ParentCodeNode);
      AddEdge(ogetParentChild,ParentGraphNode.Node,Result.Node);
      break;
    end;
    if ParentCodeNode.Parent<>nil then
      ParentCodeNode:=ParentCodeNode.Parent
    else
      ParentCodeNode:=ParentCodeNode.PriorBrother;
  end;

  // add ancestors, interfaces
  if (CodeNode.Desc=ctnTypeDefinition)
  and (CodeNode.FirstChild<>nil)
  and (CodeNode.FirstChild.Desc in [ctnClass,ctnClassInterface]) then begin
    //DebugLn(['TDeclarationOverloadsGraph.AddContext a class or interface']);
    // a class or class interface
    ClassNode:=CodeNode.FirstChild;
    Tool.BuildSubTree(ClassNode);

    if (ClassNode.FirstChild<>nil)
    and (ClassNode.FirstChild.Desc=ctnClassInheritance) then begin
      //DebugLn(['TDeclarationOverloadsGraph.AddContext has ancestor(s)']);
      Params:=TFindDeclarationParams.Create;
      ListOfPFindContext:=nil;
      try
        Tool.FindAncestorsOfClass(ClassNode,ListOfPFindContext,Params,false);
        //DebugLn(['TDeclarationOverloadsGraph.AddContext ancestors found: ',ListOfPFindContext<>nil]);
        if ListOfPFindContext<>nil then begin
          for i:=0 to ListOfPFindContext.Count-1 do begin
            //DebugLn(['TDeclarationOverloadsGraph.AddContext ancestor #',i]);
            ContextPtr:=PFindContext(ListOfPFindContext[i]);
            AncestorGraphNode:=AddContext(ContextPtr^.Tool,ContextPtr^.Node);
            AddEdge(ogetAncestorInherited,AncestorGraphNode.Node,Result.Node);
          end;
        end;
      finally
        FreeListOfPFindContext(ListOfPFindContext);
        Params.Free;
      end;
    end;
  end;

  // ToDo: add alias
  if (CodeNode.Desc=ctnTypeDefinition)
  and (CodeNode.FirstChild<>nil)
  and (CodeNode.FirstChild.Desc=ctnIdentifier) then begin
    //DebugLn(['TDeclarationOverloadsGraph.AddContext alias']);
    Params:=TFindDeclarationParams.Create;
    try
      try
        Context:=Tool.FindBaseTypeOfNode(Params,CodeNode);
        if Context.Node<>nil then begin
          while (Context.Node<>nil)
          and (not (Context.Node.Desc in AllIdentifierDefinitions)) do
            Context.Node:=Context.Node.Parent;
          if Context.Node<>nil then begin
            AliasGraphNode:=AddContext(Context.Tool,Context.Node);
            AddEdge(ogetAliasOld,AliasGraphNode.Node,Result.Node);
          end;
        end;
      except
      end;
    finally
      Params.Free;
    end;
  end;

end;

function TDeclarationOverloadsGraph.AddEdge(Typ: TOverloadsGraphEdgeType;
  FromNode, ToNode: TCodeTreeNode): TOverloadsGraphEdge;
begin
  Result:=TOverloadsGraphEdge(Graph.GetEdge(FromNode,ToNode,false));
  if (Result<>nil) then begin
    if Result.Typ<>Typ then
      RaiseCatchableException('TDeclarationOverloadsGraph.AddEdge Typ conflict');
    exit;
  end;
  // create new edge
  Result:=TOverloadsGraphEdge(Graph.GetEdge(FromNode,ToNode,true));
  Result.Typ:=Typ;
  //DebugLn(['TDeclarationOverloadsGraph.AddEdge ',Result.AsDebugString]);
end;

constructor TDeclarationOverloadsGraph.Create;
begin
  FGraph:=TCodeGraph.Create(TOverloadsGraphNode,TOverloadsGraphEdge);
end;

destructor TDeclarationOverloadsGraph.Destroy;
begin
  Clear;
  FreeAndNil(FGraph);
  inherited Destroy;
end;

procedure TDeclarationOverloadsGraph.Clear;
begin

end;

function TDeclarationOverloadsGraph.Init(Code: TCodeBuffer; X, Y: integer
  ): Boolean;
var
  Tool: TFindDeclarationTool;
  CleanPos: integer;
  CodeNode: TCodeTreeNode;
begin
  Result:=false;
  FStartCode:=Code;
  FStartX:=X;
  FStartY:=Y;

  Tool:=OnGetCodeToolForBuffer(Self,Code,true);
  if Tool.CaretToCleanPos(CodeXYPosition(X,Y,Code),CleanPos)<>0 then begin
    DebugLn(['TDeclarationOverloadsGraph.Init Tool.CaretToCleanPos failed']);
    exit(false);
  end;
  CodeNode:=Tool.FindDeepestNodeAtPos(CleanPos,true);
  //DebugLn(['TDeclarationOverloadsGraph.Init Add start context']);
  AddContext(Tool,CodeNode);

  fIdentifier:='';
  if CodeNode.Desc in AllIdentifierDefinitions+[ctnEnumIdentifier] then
    fIdentifier:=GetIdentifier(@Tool.Src[CodeNode.StartPos]);

  Result:=true;
end;

procedure TDeclarationOverloadsGraph.ScanToolForIdentifier(
  Tool: TStandardCodeTool; OnlyInterface: boolean);
var
  Entry: PInterfaceIdentCacheEntry;
  Node: TCodeTreeNode;
begin
  if Identifier='' then exit;
  if OnlyInterface then begin
    // use interface cache
    try
      Tool.BuildInterfaceIdentifierCache(false);
    except
    end;
    if Tool.InterfaceIdentifierCache<>nil then begin
      Entry:=Tool.InterfaceIdentifierCache.FindIdentifier(PChar(Identifier));
      while Entry<>nil do begin
        if CompareIdentifiers(Entry^.Identifier,PChar(Identifier))=0 then
          AddContext(Tool,Entry^.Node);
        Entry:=Entry^.NextEntry;
      end;
    end;
  end else begin
    // scan whole unit/program
    try
      Tool.Explore(false);
    except
    end;
    if Tool.Tree=nil then exit;
    Node:=Tool.Tree.Root;
    while Node<>nil do begin
      case Node.Desc of

      ctnTypeDefinition,ctnVarDefinition,ctnConstDefinition,ctnGenericType,
      ctnEnumIdentifier:
        if CompareIdentifiers(@Tool.Src[Node.StartPos],PChar(Identifier))=0
        then
          AddContext(Tool,Node);

      ctnProcedure:
        begin
          Tool.MoveCursorToProcName(Node,true);
          if CompareIdentifiers(@Tool.Src[Tool.CurPos.StartPos],PChar(Identifier))=0
          then
            AddContext(Tool,Node);
        end;

      ctnProperty:
        begin
          Tool.MoveCursorToPropName(Node);
          if CompareIdentifiers(@Tool.Src[Tool.CurPos.StartPos],PChar(Identifier))=0
          then
            AddContext(Tool,Node);
        end;
      end;
      Node:=Node.Next;
    end;
  end;
end;

{ TOverloadsGraphNode }

function TOverloadsGraphNode.AsDebugString: string;
begin
  Result:=Identifier;
  if Node<>nil then
    Result:=Result+' Desc="'+Node.DescAsString+'"';
  if (Tool<>nil) and (Node<>nil) and (Identifier='') then begin
    Result:=Result+' "'+dbgstr(copy(Tool.Src,Node.StartPos,20))+'"';
  end;
end;

{ TOverloadsGraphEdge }

function TOverloadsGraphEdge.AsDebugString: string;
begin
  Result:='Typ='+OverloadsGraphEdgeTypeNames[Typ]
    +' '+(FromNode as TOverloadsGraphNode).AsDebugString
    +'->'
    +(ToNode as TOverloadsGraphNode).AsDebugString;
end;

end.

