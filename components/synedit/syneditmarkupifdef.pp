(* SynEditMarkupIfDef

 Provides a framework to high-(low-)light "{$IFDEF  }" blocks. This unit is
 directly bound to the pascal Highlighter.
 The evaluation of IFDEF expression must be done by user code.

 The state of the IFDEF directives (true/false/unknown) is stored in a
 differential AVL tree.
 Each Node represents a line in the text (and may also indicate the number of
 IFDEF free lines following). The nodes contain a list of all IFDEF on their line.

 This allows to quickly find and insert/delete nodes, as well as move nodes
 (change line), if text is edited.

 The tree can be accessed, validated, invalidated, adjusted by several "shared"
 SynEdit.

*)
unit SynEditMarkupIfDef;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, types, SynEditMiscClasses, SynHighlighterPas,
  SynEditMarkupHighAll, SynEditHighlighterFoldBase, SynEditFoldedView, LazSynEditText,
  SynEditMiscProcs, LazClasses, LazLoggerBase, Graphics, LCLProc;

type

  { TSynRefCountedDict }

  TSynRefCountedDict = class(TRefCountedObject)
  private
    FDict: TSynSearchDictionary; // used to check for single line nodes (avoid using highlighter)
    procedure CheckWordEnd(MatchEnd: PChar; MatchIdx: Integer; var IsMatch: Boolean;
      var StopSeach: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function GetMatchAtChar(AText: PChar; ATextLen: Integer): Integer;

    property Dict: TSynSearchDictionary read FDict;
  end;


  TSynMarkupHighIfDefLinesNode = class;
  TSynMarkupHighIfDefLinesTree = class;

  { TSynMarkupHighIfDefEntry - Information about a single $IfDef/$Else/$EndIf }

  TSynMarkupIfDefNodeFlag = (
    idnMultiLineTag                 // The "{$IFDEF ... }" wraps across lines.
                                    // Only allowed on last node AND if FLine.FEndLineOffs > 0
  );
  SynMarkupIfDefNodeFlags = set of TSynMarkupIfDefNodeFlag;

  TSynMarkupIfdefNodeType = (
    idnIfdef, idnElseIf, idnElse, idnEndIf,
    idnCommentedIfdef // Keep Ifdef if commented
  );

  TSynMarkupIfdefNodeStateEx  = (idnEnabled, idnDisabled,
    idnNotInCode,  // in currently inactive outer IfDef
    idnInvalid,    // not known for other reasons. Will not ask again
    idnUnknown,    // needs requesting
    idnRequested
    );
  TSynMarkupIfdefNodeState    = idnEnabled..idnInvalid;

  TSynMarkupIfdefStateRequest = function(Sender: TObject; // SynEdit
    LinePos, XStartPos: Integer // pos of the "{"
    ): TSynMarkupIfdefNodeState of object;

  PSynMarkupHighIfDefEntry = ^TSynMarkupHighIfDefEntry;
  TSynMarkupHighIfDefEntry = class
  private
    FLine: TSynMarkupHighIfDefLinesNode;
    FNodeType: TSynMarkupIfdefNodeType;
    FNodeState, FOpeningPeerNodeState: TSynMarkupIfdefNodeStateEx;
    FNodeFlags: SynMarkupIfDefNodeFlags;
    FPeer1, FPeer2: TSynMarkupHighIfDefEntry;
    FRelativeNestDepth: Integer;
    FStartColumn, FEndColumn: Integer;
    function GetIsDisabled: Boolean;
    function GetIsEnabled: Boolean;
    function GetIsRequested: Boolean;
    function GetNeedsRequesting: Boolean;
    function GetNodeState: TSynMarkupIfdefNodeStateEx;
    procedure SetLine(AValue: TSynMarkupHighIfDefLinesNode);

    function  NodeStateForPeer(APeerType: TSynMarkupIfdefNodeType): TSynMarkupIfdefNodeStateEx;
    procedure SetOpeningPeerNodeState(AValueOfPeer, AValue: TSynMarkupIfdefNodeStateEx);
    procedure SetNodeState(AValue: TSynMarkupIfdefNodeStateEx);

    function  GetPeer(APeerType: TSynMarkupIfdefNodeType): TSynMarkupHighIfDefEntry;
    procedure SetPeer(APeerType: TSynMarkupIfdefNodeType; ANewPeer: TSynMarkupHighIfDefEntry);
    procedure ClearPeerField(APeer: PSynMarkupHighIfDefEntry);
    procedure RemoveForwardPeers;
    procedure MaybeClearOtherPeerField(APeerField: PSynMarkupHighIfDefEntry);

    function  GetPeerField(APeerType: TSynMarkupIfdefNodeType): PSynMarkupHighIfDefEntry;
    function  GetOtherPeerField(APeer: PSynMarkupHighIfDefEntry): PSynMarkupHighIfDefEntry;
    function  IsForwardPeerField(APeer: PSynMarkupHighIfDefEntry): Boolean;

    procedure ApplyNodeStateToLine(ARemove: Boolean = False);
    procedure RemoveNodeStateFromLine;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearPeers;
  public
    procedure MakeDisabled;
    procedure MakeEnabled;
    procedure MakeRequested;
    procedure MakeUnknown;
    property  IsEnabled:   Boolean read GetIsEnabled;
    property  IsDisabled:  Boolean read GetIsDisabled;
    property  IsRequested: Boolean read GetIsRequested;
    property  NeedsRequesting: Boolean read GetNeedsRequesting;
    function  IsDisabledOpening: Boolean;
    function  IsDisabledClosing: Boolean;
    function  NodeType: TSynMarkupIfdefNodeType;
    property  NodeState: TSynMarkupIfdefNodeStateEx read GetNodeState write SetNodeState;
    property  NodeFlags: SynMarkupIfDefNodeFlags read FNodeFlags write FNodeFlags;
    property  Line: TSynMarkupHighIfDefLinesNode read FLine write SetLine;
    property  StartColumn: Integer read FStartColumn write FStartColumn;
    property  EndColumn:   Integer read FEndColumn write FEndColumn;
    // RelativeNestDepth (opening depth)) First node is always 0 // nodes in line can be negative
    property  RelativeNestDepth: Integer read FRelativeNestDepth;
    function  ClosingPeer: TSynMarkupHighIfDefEntry;
// COMMENT  BEFORE  AUTO  COMPLETE !!!!!
    property IfDefPeer: TSynMarkupHighIfDefEntry index idnIfdef read GetPeer write SetPeer;
    property ElsePeer: TSynMarkupHighIfDefEntry  index idnElse  read GetPeer write SetPeer;
    property EndIfPeer: TSynMarkupHighIfDefEntry index idnEndIf read GetPeer write SetPeer;
  end;

  { TSynMarkupHighIfDefLinesNode - List of all nodes on the same line }

  SynMarkupIfDefLineFlag = (
    idlValid,            // X start/stop positions are ok
    idlHasUnknownNodes,  // need requesting
    idlHasNodesNotInCode,
    idlDisposed,          // Node is disposed, may be re-used
    idlInGlobalClear      // Skip unlinking Peers
  );
  SynMarkupIfDefLineFlags = set of SynMarkupIfDefLineFlag;

  TSynMarkupHighIfDefLinesNode = class(TSynSizedDifferentialAVLNode)
  private
    FDisabledEntryCloseCount: Integer;
    FDisabledEntryOpenCount: Integer;
    FEntries: Array of TSynMarkupHighIfDefEntry;
    FEntryCount: Integer;

    FLastEntryEndLineOffs: Integer;
    FLineFlags: SynMarkupIfDefLineFlags;
    FScanEndOffs: Integer;
    function GetEntry(AIndex: Integer): TSynMarkupHighIfDefEntry;
    function GetEntryCapacity: Integer;
    function GetId: PtrUInt;
    procedure SetEntry(AIndex: Integer; AValue: TSynMarkupHighIfDefEntry);
    procedure SetEntryCapacity(AValue: Integer);
    procedure SetEntryCount(AValue: Integer);
  protected
    procedure AdjustPositionOffset(AnAdjustment: integer); // Caller is responsible for staying between neighbours
    property NextDispose: TSynSizedDifferentialAVLNode read FParent write FParent;
  public
    constructor Create;
    destructor Destroy; override;
    procedure MakeDisposed;
    property LineFlags: SynMarkupIfDefLineFlags read FLineFlags;
    // LastEntryEndLineOffs: For last Entry only, if entry closing "}" is on a diff line. (can go one OVER ScanEndOffs)
    property LastEntryEndLineOffs: Integer read FLastEntryEndLineOffs write FLastEntryEndLineOffs;
    // ScanEndOffs: How many (empty) lines were scanned after this node
    property ScanEndOffs: Integer read FScanEndOffs write FScanEndOffs;
    property DisabledEntryOpenCount: Integer read FDisabledEntryOpenCount write FDisabledEntryOpenCount;
    property DisabledEntryCloseCount: Integer read FDisabledEntryCloseCount write FDisabledEntryCloseCount;
  public
    function AddEntry(AIndex: Integer = -1): TSynMarkupHighIfDefEntry;
    procedure DeletEntry(AIndex: Integer; AFree: Boolean = false);
    procedure ReduceCapacity;
    function IndexOf(AEntry: TSynMarkupHighIfDefEntry): Integer;
    property EntryCount: Integer read FEntryCount write SetEntryCount;
    property EntryCapacity: Integer read GetEntryCapacity write SetEntryCapacity;
    property Entry[AIndex: Integer]: TSynMarkupHighIfDefEntry read GetEntry write SetEntry; default;
  end;

  { TSynMarkupHighIfDefLinesNodeInfo }

  TSynMarkupHighIfDefLinesNodeInfo = object
  private
    FAtBOL: Boolean;
    FAtEOL: Boolean;
    FNode: TSynMarkupHighIfDefLinesNode;
    FTree: TSynMarkupHighIfDefLinesTree;
    FStartLine, Index: Integer; // Todo: Indek is not used
    FCacheNestMinimum, FCacheNestStart, FCacheNestEnd: Integer;
    function GetLastEntryEndLine: Integer;
    function GetLastEntryEndLineOffs: Integer;
    function GetEntry(AIndex: Integer): TSynMarkupHighIfDefEntry;
    function GetEntryCount: Integer;
    function GetLineFlags: SynMarkupIfDefLineFlags;
    function GetScanEndLine: Integer;
    function GetScanEndOffs: Integer;
    procedure SetEntry(AIndex: Integer; AValue: TSynMarkupHighIfDefEntry);
    procedure SetEntryCount(AValue: Integer);
    procedure SetLastEntryEndLineOffs(AValue: Integer);
    procedure SetScanEndLine(AValue: Integer);
    procedure SetScanEndOffs(AValue: Integer);
    procedure SetStartLine(AValue: Integer);  // Caller is responsible for staying between neighbours
  public
    procedure ClearInfo;
    procedure InitForNode(ANode: TSynMarkupHighIfDefLinesNode; ALine: Integer);
    function Precessor: TSynMarkupHighIfDefLinesNodeInfo;
    function Successor: TSynMarkupHighIfDefLinesNodeInfo;
  public
    procedure ClearNestCache;
    function NestMinimumDepthAtNode: Integer;
    function NestDepthAtNodeStart: Integer;
    function NestDepthAtNodeEnd: Integer;
  public
    function IsValid: Boolean;
    procedure Invalidate;
    function HasNode: Boolean;
    property StartLine: Integer read FStartLine write SetStartLine;
    property LineFlags: SynMarkupIfDefLineFlags read GetLineFlags;
    property LastEntryEndLineOffs: Integer read GetLastEntryEndLineOffs write SetLastEntryEndLineOffs;
    property LastEntryEndLine: Integer read GetLastEntryEndLine; // write SetLastEntryEndLineOffs;
    property ScanEndOffs: Integer read GetScanEndOffs write SetScanEndOffs;
    property ScanEndLine: Integer read GetScanEndLine write SetScanEndLine;
    function ValidToLine(const ANextNode: TSynMarkupHighIfDefLinesNodeInfo): Integer; // ScanEndLine or next node

    //function AddEntry: TSynMarkupHighIfDefEntry;
    //procedure DeletEntry(AIndex: Integer; AFree: Boolean = false);
    property EntryCount: Integer read GetEntryCount write SetEntryCount;
    property Entry[AIndex: Integer]: TSynMarkupHighIfDefEntry read GetEntry write SetEntry;
    property AtBOL: Boolean read FAtBOL;
    property AtEOL: Boolean read FAtEOL;
    property Node: TSynMarkupHighIfDefLinesNode read FNode;
  end;

  { TSynMarkupHighIfDefLinesNodeInfoList }

  TSynMarkupHighIfDefLinesNodeInfoList = object
  private
    FCount: Integer;
    FNestOpenNodes: Array of TSynMarkupHighIfDefLinesNodeInfo;
    function GetCapacity: Integer;
    function GetCount: Integer;
    function GetNode(AIndex: Integer): TSynMarkupHighIfDefLinesNodeInfo;
    procedure SetCapacity(AValue: Integer);
    procedure SetCount(AValue: Integer);
    procedure SetNode(AIndex: Integer; AValue: TSynMarkupHighIfDefLinesNodeInfo);
    procedure SetNodes(ALow, AHigh: Integer; const AValue: TSynMarkupHighIfDefLinesNodeInfo);
  public
    property Count: Integer read GetCount write SetCount;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Node[AIndex: Integer]: TSynMarkupHighIfDefLinesNodeInfo read GetNode write SetNode;
    property Nodes[ALow, AHigh: Integer]: TSynMarkupHighIfDefLinesNodeInfo write SetNodes;
    Procedure PushNodeLine(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
    procedure dbg;
  end;

  { TSynMarkupHighIfDefLinesTree }

  TSynMarkupHighIfDefLinesTree = class(TSynSizedDifferentialAVLTree)
  private
    FHighlighter: TSynPasSyn;
    FLines: TSynEditStrings;
    FClearing: Boolean;
    FDisposedNodes: TSynSizedDifferentialAVLNode;
    FOnNodeStateRequest: TSynMarkupIfdefStateRequest;
    FRequestingNodeState: Boolean;

    procedure SetHighlighter(AValue: TSynPasSyn);
    procedure SetLines(AValue: TSynEditStrings);
    function GetHighLighterWithLines: TSynCustomFoldHighlighter;
  private
    procedure MaybeRequestNodeStates(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
    procedure MaybeValidateNode(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
    procedure MaybeExtendNodeBackward(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
      AStopAtLine: Integer = 0);
    procedure MaybeExtendNodeForward(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
      var ANextNode: TSynMarkupHighIfDefLinesNodeInfo;
      AStopBeforeLine: Integer = -1);

    function  GetOrInsertNodeAtLine(ALinePos: Integer): TSynMarkupHighIfDefLinesNodeInfo;
    procedure ConnectPeers(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
                           var ANestList: TSynMarkupHighIfDefLinesNodeInfoList;
                           AOuterLines: TLazSynEditNestedFoldsList = nil);
    function  CheckLineForNodes(ALine: Integer): Boolean;
    procedure ScanLine(ALine: Integer; var ANodeForLine: TSynMarkupHighIfDefLinesNode;
                       ACheckOverlapOnCreateLine: Boolean = False);

    procedure DoLinesEdited(Sender: TSynEditStrings; aLinePos, aBytePos, aCount,
                            aLineBrkCnt: Integer; aText: String);
    procedure DoHighlightChanged(Sender: TSynEditStrings; AIndex, ACount : Integer);
  protected
    function  CreateNode(APosition: Integer): TSynSizedDifferentialAVLNode; override;
    procedure DisposeNode(var ANode: TSynSizedDifferentialAVLNode); override;
    procedure RemoveLine(var ANode: TSynMarkupHighIfDefLinesNode);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    procedure DebugPrint(Flat: Boolean = False);

    function FindNodeAtPosition(ALine: Integer;
                                AMode: TSynSizedDiffAVLFindMode): TSynMarkupHighIfDefLinesNodeInfo;
                                overload;

    function  CreateOpeningList: TLazSynEditNestedFoldsList;
    procedure DiscardOpeningList(AList: TLazSynEditNestedFoldsList);

    procedure ValidateRange(AStartLine, AEndLine: Integer;
                            OuterLines: TLazSynEditNestedFoldsList);
    procedure SetNodeState(ALinePos, AstartPos: Integer; AState: TSynMarkupIfdefNodeState);

    property OnNodeStateRequest: TSynMarkupIfdefStateRequest read FOnNodeStateRequest write FOnNodeStateRequest;
    property Highlighter: TSynPasSyn read FHighlighter write SetHighlighter;
    property Lines : TSynEditStrings read FLines write SetLines;
  end;

  { TSynEditMarkupIfDef }

  TSynEditMarkupIfDef = class(TSynEditMarkupHighlightMatches)
  private
    FFoldView: TSynEditFoldedView;
    FHighlighter: TSynPasSyn;
    FIfDefTree: TSynMarkupHighIfDefLinesTree;
    FOuterLines: TLazSynEditNestedFoldsList;
    FNeedValidate: Boolean;

    procedure SetFoldView(AValue: TSynEditFoldedView);
    procedure SetHighlighter(AValue: TSynPasSyn);
    procedure DoBufferChanged(Sender: TObject);
    function  DoNodeStateRequest(Sender: TObject; LinePos, XStartPos: Integer): TSynMarkupIfdefNodeState;

    Procedure ValidateMatches;
  protected
    procedure DoFoldChanged(aLine: Integer);
    procedure DoTopLineChanged(OldTopLine : Integer); override;
    procedure DoLinesInWindoChanged(OldLinesInWindow : Integer); override;
    procedure DoMarkupChanged(AMarkup: TSynSelectedColor); override;
    procedure DoTextChanged(StartLine, EndLine, ACountDiff: Integer); override; // 1 based
    procedure DoVisibleChanged(AVisible: Boolean); override;
    procedure SetLines(const AValue: TSynEditStrings); override;
  public
    constructor Create(ASynEdit : TSynEditBase);
    destructor Destroy; override;
    procedure IncPaintLock; override;
    procedure DecPaintLock; override;

    // AFirst/ ALast are 1 based
    //Procedure Invalidate(SkipPaint: Boolean = False);
    //Procedure InvalidateLines(AFirstLine: Integer = 0; ALastLine: Integer = 0; SkipPaint: Boolean = False);
    //Procedure SendLineInvalidation(AFirstIndex: Integer = -1;ALastIndex: Integer = -1);

    property FoldView: TSynEditFoldedView read FFoldView write SetFoldView;
    property Highlighter: TSynPasSyn read FHighlighter write SetHighlighter;
  end;

function dbgs(AFlag: SynMarkupIfDefLineFlag): String; overload;
function dbgs(AFlags: SynMarkupIfDefLineFlags): String; overload;
function dbgs(AFlag: TSynMarkupIfDefNodeFlag): String; overload;
function dbgs(AFlags: SynMarkupIfDefNodeFlags): String; overload;
function dbgs(AFlag: TSynMarkupIfdefNodeType): String; overload;
function dbgs(AFlag: TSynMarkupIfdefNodeStateEx): String; overload;

implementation

uses
  SynEdit;
var
  TheDict: TSynRefCountedDict = nil;
XXXCurTree: TSynMarkupHighIfDefLinesTree = nil;

type

  { TSynRefCountedDictIfDef }

  TSynRefCountedDictIfDef = class(TSynRefCountedDict)
  public
    destructor Destroy; override;
  end;

procedure MaybeCreateDict;
begin
  if TheDict = nil then
    TheDict := TSynRefCountedDictIfDef.Create;
end;

function dbgs(AFlag: SynMarkupIfDefLineFlag): String;
begin
  Result := '';
  WriteStr(Result, AFlag);
end;

function dbgs(AFlags: SynMarkupIfDefLineFlags): String;
var
  i: SynMarkupIfDefLineFlag;
begin
  Result := '';
  for i := low(AFlags) to high(AFlags) do
    if i in AFlags then
      if Result = '' then
        Result := Result + dbgs(i)
      else
        Result := Result + ', ' + dbgs(i);
  Result := '[' + Result + ']';
end;

function dbgs(AFlag: TSynMarkupIfDefNodeFlag): String;
begin
  Result := '';
  WriteStr(Result, AFlag);
end;

function dbgs(AFlags: SynMarkupIfDefNodeFlags): String;
var
  i: TSynMarkupIfDefNodeFlag;
begin
  Result := '';
  for i := low(AFlags) to high(AFlags) do
    if i in AFlags then
      if Result = '' then
        Result := Result + dbgs(i)
      else
        Result := Result + ', ' + dbgs(i);
  Result := '[' + Result + ']';
end;

function dbgs(AFlag: TSynMarkupIfdefNodeType): String;
begin
  Result := '';
  WriteStr(Result, AFlag);
end;

function dbgs(AFlag: TSynMarkupIfdefNodeStateEx): String;
begin
  Result := '';
  WriteStr(Result, AFlag);
end;

{ TSynRefCountedDictIfDef }

destructor TSynRefCountedDictIfDef.Destroy;
begin
  inherited Destroy;
  TheDict := nil;
end;

{ TSynMarkupHighIfDefLinesNodeInfoList }

function TSynMarkupHighIfDefLinesNodeInfoList.GetCapacity: Integer;
begin
  Result := Length(FNestOpenNodes);
end;

function TSynMarkupHighIfDefLinesNodeInfoList.GetCount: Integer;
begin
  if Capacity = 0 then
    FCount := 0;
  Result := FCount;
end;

function TSynMarkupHighIfDefLinesNodeInfoList.GetNode(AIndex: Integer): TSynMarkupHighIfDefLinesNodeInfo;
begin
  Assert((AIndex < Count) and (AIndex >= 0), 'TSynMarkupHighIfDefLinesNodeInfoList.GetNode Index');
  Result := FNestOpenNodes[AIndex];
end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.SetCapacity(AValue: Integer);
begin
  if Capacity = 0 then
    FCount := 0;
  SetLength(FNestOpenNodes, AValue);
  FCount := Min(FCount, AValue);
end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.SetCount(AValue: Integer);
begin
  if Capacity = 0 then
    FCount := 0;
  if Count = AValue then Exit;
  Capacity := Max(FCount, Capacity);
  FCount := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.SetNode(  AIndex: Integer;
  AValue: TSynMarkupHighIfDefLinesNodeInfo);
begin
  Assert((  AIndex < Count) and (  AIndex >= 0), 'TSynMarkupHighIfDefLinesNodeInfoList.SetNode Index');
  FNestOpenNodes[  AIndex] := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.SetNodes(ALow, AHigh: Integer;
  const AValue: TSynMarkupHighIfDefLinesNodeInfo);
var
  i: Integer;
begin
  if AHigh >= Count then begin
    Capacity := 1 + AHigh + Min(AHigh div 2, 100);
    Count := AHigh + 1;
  end;
  for i := ALow to AHigh do
    FNestOpenNodes[i] := AValue;
end;

//procedure TSynMarkupHighIfDefLinesNodeInfoList.FixOuterLineForNode(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
//var
//  j: Integer;
//begin
//  j := ANode.NestDepthAtNodeStart;
//  if j = 0 then
//    exit;
//  ANode.OuterNestingNode := Node[j];
//  if (not Node[j].HighestValidNestedNode.HasNode) or
//     (Node[j].HighestValidNestedNode.StartLine < ANode.StartLine)
//  then
//    Node[j].HighestValidNestedNode := ANode;
//end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.PushNodeLine(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
begin
  Nodes[ANode.NestMinimumDepthAtNode+1, ANode.NestDepthAtNodeEnd] := ANode;
end;

procedure TSynMarkupHighIfDefLinesNodeInfoList.dbg;
var
  i: Integer;
begin
  for i := 0 to Count-1 do begin
    DbgOut(['##  ',i, ': ', dbgs(Node[i].HasNode)]);
    if Node[i].HasNode then  DbgOut(['(', Node[i].StartLine, ')']);
  end;
  DebugLn();
end;

{ TSynRefCountedDict }

procedure TSynRefCountedDict.CheckWordEnd(MatchEnd: PChar; MatchIdx: Integer;
  var IsMatch: Boolean; var StopSeach: Boolean);
begin
  IsMatch := not ((MatchEnd+1)^ in ['a'..'z', 'A'..'Z', '0'..'9', '_']);
end;

constructor TSynRefCountedDict.Create;
begin
  inherited Create;
  FDict := TSynSearchDictionary.Create;
  FDict.Add('{$if',     1);
  FDict.Add('{$ifc',    1);
  FDict.Add('{$ifdef',  1);
  FDict.Add('{$ifndef', 1);
  FDict.Add('{$ifopt',  1);

  FDict.Add('{$else',   2);
  FDict.Add('{$elsec',  2);

  FDict.Add('{$elseif', 4);
  FDict.Add('{$elifc',  4);

  FDict.Add('{$endif',  3);
  FDict.Add('{$ifend',  3);
  FDict.Add('{$endc',   3);

end;

destructor TSynRefCountedDict.Destroy;
begin
  FDict.Free;
  inherited Destroy;
end;

function TSynRefCountedDict.GetMatchAtChar(AText: PChar; ATextLen: Integer): Integer;
begin
  Result := FDict.GetMatchAtChar(AText, ATextLen, @CheckWordEnd);
end;

{ TSynMarkupHighIfDefEntry }

function TSynMarkupHighIfDefEntry.NodeType: TSynMarkupIfdefNodeType;
begin
  Result := FNodeType;
end;

function TSynMarkupHighIfDefEntry.ClosingPeer: TSynMarkupHighIfDefEntry;
begin
  case NodeType of
    idnIfdef, idnElseIf:
      if ElsePeer <> nil then
        Result := ElsePeer
      else
        Result := EndIfPeer;
    idnElse:  Result := EndIfPeer;
    idnEndIf: assert(False, 'endif has no close peer');
    idnCommentedIfdef: assert(false, 'ClosingPeer for idnCommentedIfdef not possible');
  end;
end;

function TSynMarkupHighIfDefEntry.GetPeerField(APeerType: TSynMarkupIfdefNodeType): PSynMarkupHighIfDefEntry;
begin
  Result := nil;
  case NodeType of
    idnIfdef:
      case APeerType of
        idnIfdef: assert(false, 'Invalid node state for getting peer field');
        idnElse, idnElseIf:  Result := @FPeer1;
        idnEndIf: Result := @FPeer2;
      end;
    idnElseIf:
      case   APeerType of
        idnIfdef: Result := @FPeer1;
        idnElse, idnElseIf:  Result := @FPeer2;
        idnEndIf: Result := @FPeer2;
      end;
    idnElse:
      case   APeerType of
        idnIfdef: Result := @FPeer1;
        idnElse, idnElseIf:  assert(false, 'Invalid node state for getting peer field');
        idnEndIf: Result := @FPeer2;
      end;
    idnEndIf:
      case   APeerType of
        idnIfdef: Result := @FPeer1;
        idnElse, idnElseIf:  Result := @FPeer2;
        idnEndIf: assert(false, 'Invalid node state for getting peer field');
      end;
    idnCommentedIfdef: assert(false, 'GetPeerField for idnCommentedIfdef not possible');
  end;
end;

function TSynMarkupHighIfDefEntry.GetOtherPeerField(APeer: PSynMarkupHighIfDefEntry): PSynMarkupHighIfDefEntry;
begin
  if APeer = @FPeer1 then
    Result := @FPeer2
  else
    Result := @FPeer1;
end;

function TSynMarkupHighIfDefEntry.IsForwardPeerField(APeer: PSynMarkupHighIfDefEntry): Boolean;
begin
  Result := False;
  case NodeType of
    idnIfdef:   Result := True;
    idnElseIf:  Result := APeer = @FPeer2;
    idnElse:    Result := APeer = @FPeer2;
    idnEndIf:   Result := False;
    idnCommentedIfdef: assert(false, 'GetPeerField for idnCommentedIfdef not possible');
  end;
end;

function TSynMarkupHighIfDefEntry.GetIsDisabled: Boolean;
begin
  Result := FNodeState = idnDisabled;
end;

function TSynMarkupHighIfDefEntry.GetIsEnabled: Boolean;
begin
  Result := FNodeState = idnEnabled;
end;

function TSynMarkupHighIfDefEntry.GetIsRequested: Boolean;
begin
  Result := FNodeState = idnRequested;
end;

function TSynMarkupHighIfDefEntry.GetNeedsRequesting: Boolean;
begin
  Result := ( (NodeType = idnIfdef) or
              ( (NodeType = idnElseIf) and (FOpeningPeerNodeState = idnEnabled) )
            ) and
            (not(FNodeState in [idnEnabled, idnDisabled, idnRequested, idnInvalid]));
end;

function TSynMarkupHighIfDefEntry.GetNodeState: TSynMarkupIfdefNodeStateEx;
begin
  Result := FNodeState
end;

function TSynMarkupHighIfDefEntry.GetPeer(APeerType: TSynMarkupIfdefNodeType): TSynMarkupHighIfDefEntry;
begin
  Result := GetPeerField(APeerType)^;
end;

procedure TSynMarkupHighIfDefEntry.SetLine(AValue: TSynMarkupHighIfDefLinesNode);
begin
  if FLine = AValue then Exit;

  RemoveNodeStateFromLine;
  FLine := AValue;
  ApplyNodeStateToLine;
end;

procedure TSynMarkupHighIfDefEntry.SetOpeningPeerNodeState(AValueOfPeer,
  AValue: TSynMarkupIfdefNodeStateEx);
begin
  FOpeningPeerNodeState := AValueOfPeer;
  if NodeType in [idnElse, idnEndIf] then
    SetNodeState(AValueOfPeer)
  else
  if NodeType = idnElseIf then
    case AValue of
      idnEnabled:  MakeUnknown;
      idnDisabled: SetNodeState(idnDisabled);
      else         SetNodeState(idnUnknown);
    end;
end;

procedure TSynMarkupHighIfDefEntry.SetNodeState(AValue: TSynMarkupIfdefNodeStateEx);
begin
  RemoveNodeStateFromLine;
  FNodeState := AValue;
  ApplyNodeStateToLine;

  case NodeType of
    idnIfdef, idnElseIf: begin
        if (ElsePeer <> nil) and (ElsePeer.NodeType <> idnElseIf) then
          ElsePeer.SetOpeningPeerNodeState(NodeState, NodeStateForPeer(idnElse))
        else
        if EndIfPeer <> nil then
          EndIfPeer.SetOpeningPeerNodeState(NodeState, NodeStateForPeer(idnEndIf));
      end;
    idnElse: begin
        if EndIfPeer <> nil then
          EndIfPeer.SetOpeningPeerNodeState(NodeState, NodeStateForPeer(idnEndIf));
      end;
    idnCommentedIfdef: Assert(false, 'SetOpeningPeerNodeState for idnCommentedIfdef not possible');
  end;

end;

procedure TSynMarkupHighIfDefEntry.MakeDisabled;
begin
  NodeState := idnDisabled;
end;

procedure TSynMarkupHighIfDefEntry.MakeEnabled;
begin
  NodeState := idnEnabled;
end;

procedure TSynMarkupHighIfDefEntry.MakeRequested;
begin
  NodeState := idnRequested;
end;

procedure TSynMarkupHighIfDefEntry.MakeUnknown;
begin
  NodeState := idnUnknown;
end;

function TSynMarkupHighIfDefEntry.IsDisabledOpening: Boolean;
begin
  Result := (NodeType in [idnIfdef, idnElseIf, idnElse]) and (NodeState = idnDisabled);
end;

function TSynMarkupHighIfDefEntry.IsDisabledClosing: Boolean;
begin
  Result := (NodeType in [idnElse, idnElseIf, idnEndIf]) and (FOpeningPeerNodeState = idnDisabled);
end;

procedure TSynMarkupHighIfDefEntry.SetPeer(APeerType: TSynMarkupIfdefNodeType;
  ANewPeer: TSynMarkupHighIfDefEntry);
var
  OwnPeerField, OthersPeerField: PSynMarkupHighIfDefEntry;
begin
  //assert((ANewPeer=nil) or (APeerType = ANewPeer.NodeType), 'APeerType = ANewPeer.NodeType'); // elseif can be set as ifdef
  OwnPeerField := GetPeerField(APeerType);
  if OwnPeerField^ = ANewPeer then begin
    assert((OwnPeerField^ = nil) or (OwnPeerField^.GetPeerField(NodeType)^ = self), 'Peer does not point back to self');
    assert((NodeType = idnElse) or (OwnPeerField^ = nil) or (GetOtherPeerField(OwnPeerField)^ = nil), 'Only ELSE has 2 peers');
    exit;
  end;

  ClearPeerField(OwnPeerField);

  if ANewPeer = nil then begin
    OwnPeerField^ := ANewPeer;

    if not IsForwardPeerField(OwnPeerField) then
      SetOpeningPeerNodeState(idnUnknown, idnUnknown);
  end
  else begin
    // If new peer is part of another pair, disolve that pair. This may set OwnPeerField = nil, if new pair points to this node
    assert(ANewPeer.GetPeer(NodeType) <> self, 'New peer points to this, but was not known by this / link is not bidirectional');
    if (NodeType = idnElseIf) and (APeerType = idnElse) then // APeerType never is idnElseIf;
      OthersPeerField := ANewPeer.GetPeerField(idnIfdef) // act as ifdef
    else
      OthersPeerField := ANewPeer.GetPeerField(NodeType);
    ANewPeer.ClearPeerField(OthersPeerField);
    MaybeClearOtherPeerField(OwnPeerField);
    ANewPeer.MaybeClearOtherPeerField(OthersPeerField);

    OthersPeerField^ := Self;
    OwnPeerField^ := ANewPeer;

    if IsForwardPeerField(OwnPeerField) then
      OwnPeerField^.SetOpeningPeerNodeState(NodeState, NodeStateForPeer(OwnPeerField^.NodeType))
    else
      SetOpeningPeerNodeState(OwnPeerField^.NodeState, OwnPeerField^.NodeStateForPeer(NodeType));
  end;

end;

procedure TSynMarkupHighIfDefEntry.ClearPeerField(APeer: PSynMarkupHighIfDefEntry);
begin
  if APeer^ = nil then exit;
//  assert(APeer^.GetPeerField(NodeType)^ = self, 'ClearPeerField: Peer does not point back to self');

  if IsForwardPeerField(APeer) then
    APeer^.SetOpeningPeerNodeState(idnUnknown, idnUnknown)
  else
    SetOpeningPeerNodeState(idnUnknown, idnUnknown);

  if APeer^.FPeer1 = self then
    APeer^.FPeer1  := nil
  else
  if APeer^.FPeer2 = self then
    APeer^.FPeer2  := nil
  else
    assert(false, 'ClearPeerField: did not find back reference');
  APeer^ := nil;
end;

procedure TSynMarkupHighIfDefEntry.RemoveForwardPeers;
begin
  case NodeType of
    idnIfdef, idnElseIf: begin
        ElsePeer := nil;
        EndIfPeer := nil;
      end;
    idnElse: begin
        EndIfPeer := nil;
      end;
    idnEndIf: begin
      end;
  end;
end;

procedure TSynMarkupHighIfDefEntry.MaybeClearOtherPeerField(APeerField: PSynMarkupHighIfDefEntry);
var
  OwnOtherPeerField: PSynMarkupHighIfDefEntry;
begin
  if not (NodeType in [idnIfdef, idnEndIf]) then
    exit;

  // idnIfdef, idnEndIf are only allowed either ONE peer
  OwnOtherPeerField := GetOtherPeerField(APeerField);
  if OwnOtherPeerField^ <> nil then begin
    debugln(['Setting other peer to nil while setting (p1=True / P2=false)', dbgs(APeerField=@FPeer1)]);
    ClearPeerField(OwnOtherPeerField);
    assert(OwnOtherPeerField^ = nil, 'OwnOtherPeerField was emptied, by setting the peers backpointer to nil')
  end;
end;

procedure TSynMarkupHighIfDefEntry.ApplyNodeStateToLine(ARemove: Boolean = False);
var
  i: Integer;
begin
  if (FLine <> nil) then begin
    i := 1;
    if ARemove then i := -1;
    case NodeType of
      idnIfdef: begin
        if NodeState = idnDisabled then
          FLine.DisabledEntryOpenCount := FLine.DisabledEntryOpenCount + i;
        end;
      idnElse, idnElseIf: begin
          if FOpeningPeerNodeState = idnDisabled then
            FLine.DisabledEntryCloseCount := FLine.DisabledEntryCloseCount + i;
          if NodeState = idnDisabled then
            FLine.DisabledEntryOpenCount := FLine.DisabledEntryOpenCount + i;
        end;
      idnEndIf: begin
          if FOpeningPeerNodeState = idnDisabled then
            FLine.DisabledEntryCloseCount := FLine.DisabledEntryCloseCount + i;
        end;
    end;
  end;

  if not ARemove then begin
    if NodeState = idnNotInCode then
      Include(FLine.FLineFlags, idlHasNodesNotInCode)
    else
    if NeedsRequesting then
      Include(FLine.FLineFlags, idlHasUnknownNodes);
  end;
end;

procedure TSynMarkupHighIfDefEntry.RemoveNodeStateFromLine;
begin
  ApplyNodeStateToLine(True);
end;

function TSynMarkupHighIfDefEntry.NodeStateForPeer(APeerType: TSynMarkupIfdefNodeType): TSynMarkupIfdefNodeStateEx;
const
  NodeStateMap: array [Boolean] of TSynMarkupIfdefNodeStateEx =
    (idnDisabled, idnEnabled); // False, True
begin
  Result := idnUnknown;
  Assert(NodeType <> APeerType, 'NodeStateForPeer: NodeType <> APeerType');
  case NodeState of
    idnEnabled: begin
        case NodeType of
          idnIfdef:  Result := NodeStateMap[APeerType = idnEndIf]; // idnElse[if] will be idnDisabled;
          idnElseIf: Result := NodeStateMap[APeerType = idnEndIf]; // idnElse[if] will be idnDisabled;
          idnElse:   Result := NodeStateMap[APeerType = idnEndIf]; // idnIfdef will be idnDisabled;;
          idnEndIf:  Result := idnEnabled;
        end;
      end;
    idnDisabled: begin
        case NodeType of
          idnIfdef:  Result := NodeStateMap[APeerType <> idnEndIf];
          idnElseIf: Result := NodeStateMap[APeerType <> idnEndIf];
          idnElse:   Result := NodeStateMap[APeerType <> idnEndIf];
          idnEndIf:  Result := idnDisabled;
        end;
      end;
  end;
end;

constructor TSynMarkupHighIfDefEntry.Create;
begin
  FNodeState := idnUnknown;
end;

destructor TSynMarkupHighIfDefEntry.Destroy;
begin
  NodeState := idnUnknown; //  RemoveNodeStateFromLine;
  if (FLine <> nil) and not(idlInGlobalClear in FLine.LineFlags) then
    ClearPeers;
  inherited Destroy;
end;

procedure TSynMarkupHighIfDefEntry.ClearPeers;
begin
  ClearPeerField(@FPeer1);
  ClearPeerField(@FPeer2);
  //if NodeType <> idnIfdef then
  //  NodeState := idnUnknown;
end;

{ TSynMarkupHighIfDefLinesNode }

function TSynMarkupHighIfDefLinesNode.GetEntry(AIndex: Integer): TSynMarkupHighIfDefEntry;
begin
  Result := FEntries[AIndex];
end;

function TSynMarkupHighIfDefLinesNode.GetEntryCapacity: Integer;
begin
  Result := Length(FEntries);
end;

function TSynMarkupHighIfDefLinesNode.GetId: PtrUInt;
begin
  Result := PtrUInt(Self);
end;

procedure TSynMarkupHighIfDefLinesNode.SetEntry(AIndex: Integer;
  AValue: TSynMarkupHighIfDefEntry);
begin
  FEntries[AIndex] := AValue;
  if AValue <> nil then
    AValue.Line := Self;
end;

procedure TSynMarkupHighIfDefLinesNode.SetEntryCapacity(AValue: Integer);
var
  i, j: Integer;
begin
  j := Length(FEntries);
  if j = AValue then Exit;
  for i := j - 1 downto AValue do
    FreeAndNil(FEntries[i]);
  SetLength(FEntries, AValue);
  for i := j to AValue - 1 do
    FEntries[i] := nil;
end;

procedure TSynMarkupHighIfDefLinesNode.SetEntryCount(AValue: Integer);
begin
  if FEntryCount = AValue then Exit;
  FEntryCount := AValue;
  if EntryCapacity < FEntryCount then
    EntryCapacity := FEntryCount;
end;

procedure TSynMarkupHighIfDefLinesNode.AdjustPositionOffset(AnAdjustment: integer);
begin
  Assert((Successor = nil) or (GetPosition + AnAdjustment < Successor.GetPosition), 'GetPosition + AnAdjustment < Successor.GetPosition');
  Assert((Precessor = nil) or (GetPosition + AnAdjustment > Precessor.GetPosition), 'GetPosition + AnAdjustment > Precessor.GetPosition');
  FPositionOffset := FPositionOffset + AnAdjustment;
  if FLeft <> nil then
    TSynMarkupHighIfDefLinesNode(FLeft).FPositionOffset :=
      TSynMarkupHighIfDefLinesNode(FLeft).FPositionOffset - AnAdjustment;
  if FRight <> nil then
    TSynMarkupHighIfDefLinesNode(FRight).FPositionOffset :=
      TSynMarkupHighIfDefLinesNode(FRight).FPositionOffset - AnAdjustment;
end;

constructor TSynMarkupHighIfDefLinesNode.Create;
begin
  FSize := 1; // used for index
  FScanEndOffs := 0;
end;

destructor TSynMarkupHighIfDefLinesNode.Destroy;
begin
  inherited Destroy;
  MakeDisposed;
end;

procedure TSynMarkupHighIfDefLinesNode.MakeDisposed;
begin
  FLineFlags := [idlDisposed] + FLineFlags * [idlInGlobalClear];
  while EntryCount > 0 do
    DeletEntry(EntryCount-1, True);
  assert((FDisabledEntryOpenCount =0) and (FDisabledEntryCloseCount = 0), 'no close count left over');
  FDisabledEntryOpenCount := 0;
  FDisabledEntryCloseCount := 0;
end;

function TSynMarkupHighIfDefLinesNode.AddEntry(AIndex: Integer): TSynMarkupHighIfDefEntry;
var
  c: Integer;
begin
  c := EntryCount;
  EntryCount := c + 1;
  assert(FEntries[c]=nil, 'FEntries[c]=nil');
  Result := TSynMarkupHighIfDefEntry.Create;
  Result.Line := Self;
  if (AIndex > 0) then begin
    Assert(AIndex <= c, 'Add node index <= count');
    while c > AIndex do begin
      FEntries[c] := FEntries[c - 1];
      dec(c);
    end;
  end;
  FEntries[c] := Result;
end;

procedure TSynMarkupHighIfDefLinesNode.DeletEntry(AIndex: Integer; AFree: Boolean);
begin
  Assert((AIndex >= 0) and (AIndex < FEntryCount), 'DeletEntry');
  if AFree then
    FEntries[AIndex].Free
  else
    FEntries[AIndex] := nil;
  while AIndex < FEntryCount - 1 do begin
    FEntries[AIndex] := FEntries[AIndex + 1];
    inc(AIndex);
  end;
  FEntries[AIndex] := nil;
  dec(FEntryCount);
end;

procedure TSynMarkupHighIfDefLinesNode.ReduceCapacity;
begin
  EntryCapacity := EntryCount;
end;

function TSynMarkupHighIfDefLinesNode.IndexOf(AEntry: TSynMarkupHighIfDefEntry): Integer;
begin
  Result := EntryCount - 1;
  while (Result >= 0) and (Entry[Result] <> AEntry) do
    dec(Result);
end;

{ TSynMarkupHighIfDefLinesNodeInfo }

procedure TSynMarkupHighIfDefLinesNodeInfo.SetStartLine(AValue: Integer);
begin
  Assert(FNode <> nil, 'TSynMarkupHighIfDefLinesNodeInfo.SetStartLine has node');
  if FStartLine = AValue then Exit;
  FNode.AdjustPositionOffset(AValue - FStartLine);
  FStartLine := AValue;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetLineFlags: SynMarkupIfDefLineFlags;
begin
  if not HasNode then
    exit([]);
  Result := FNode.LineFlags;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetLastEntryEndLineOffs: Integer;
begin
  if not HasNode then
    exit(0);
  Result := FNode.LastEntryEndLineOffs;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetLastEntryEndLine: Integer;
begin
  if not HasNode then
    exit(0);
  Result := StartLine + FNode.LastEntryEndLineOffs;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetEntry(AIndex: Integer): TSynMarkupHighIfDefEntry;
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.GetEntry');
  Result := FNode.Entry[AIndex];
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetEntryCount: Integer;
begin
  if not HasNode then
    exit(0);
  Result := FNode.EntryCount;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetScanEndLine: Integer;
begin
  if not IsValid then
    exit(StartLine);
  if ScanEndOffs >= 0 then
    Result := StartLine + ScanEndOffs
  else
    Result := StartLine;
end;

function TSynMarkupHighIfDefLinesNodeInfo.GetScanEndOffs: Integer;
begin
  if not HasNode then
    exit(0);
  Result := FNode.ScanEndOffs;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.SetEntry(AIndex: Integer;
  AValue: TSynMarkupHighIfDefEntry);
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.SetEntry');
  FNode.Entry[AIndex] := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.SetEntryCount(AValue: Integer);
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.SetEntryCount');
  FNode.EntryCount := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.SetLastEntryEndLineOffs(AValue: Integer);
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.SetEndLineOffs');
  FNode.LastEntryEndLineOffs := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.SetScanEndLine(AValue: Integer);
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.SetScanEndLine');
  ScanEndOffs := AValue - StartLine;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.SetScanEndOffs(AValue: Integer);
begin
  Assert(HasNode, 'HasNode for TSynMarkupHighIfDefLinesNodeInfo.SetScanEndOffs');
  FNode.ScanEndOffs := AValue;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.ClearInfo;
begin
  FStartLine := 0;
  Index      := 0;
  FNode := nil;
  FAtBOL := False;
  FAtEOL := False;
  ClearNestCache;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.InitForNode(ANode: TSynMarkupHighIfDefLinesNode;
  ALine: Integer);
begin
  ClearInfo;
  FNode := ANode;
  FStartLine := ALine;
end;

function TSynMarkupHighIfDefLinesNodeInfo.Precessor: TSynMarkupHighIfDefLinesNodeInfo;
begin
  ClearNestCache;
  Result.FTree := FTree;
  If HasNode then begin
    Result.FStartLine := FStartLine;
    Result.Index      := Index;
    Result.FNode := TSynMarkupHighIfDefLinesNode(FNode.Precessor(Result.FStartLine, Result.Index));
    Result.FAtBOL := not Result.HasNode;
    Result.FAtEOL := False;
  end
  else
  if AtEOL then begin
    Result.FNode := TSynMarkupHighIfDefLinesNode(FTree.Last(Result.FStartLine, Result.Index));
    Result.FAtBOL := not Result.HasNode;
    Result.FAtEOL := False;
  end
  else begin
    Result.ClearInfo;
  end;
end;

function TSynMarkupHighIfDefLinesNodeInfo.Successor: TSynMarkupHighIfDefLinesNodeInfo;
begin
  ClearNestCache;
  Result.FTree := FTree;
  If HasNode then begin
    Result.FStartLine := FStartLine;
    Result.Index      := Index;
    Result.FNode := TSynMarkupHighIfDefLinesNode(FNode.Successor(Result.FStartLine, Result.Index));
    Result.FAtBOL := False;
    Result.FAtEOL := not Result.HasNode;
  end
  else
  if FAtBOL then begin
    Result.FNode := TSynMarkupHighIfDefLinesNode(FTree.First(Result.FStartLine, Result.Index));
    Result.FAtBOL := False;
    Result.FAtEOL := not Result.HasNode;
  end
  else begin
    Result.ClearInfo;
  end;
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.ClearNestCache;
begin
  FCacheNestMinimum := -1;
  FCacheNestStart   := -1;
  FCacheNestEnd     := -1;
end;

function TSynMarkupHighIfDefLinesNodeInfo.NestMinimumDepthAtNode: Integer;
begin
  assert(FTree <> nil, 'NestWinimumDepthAtNode has tree');
  if FCacheNestMinimum < 0 then
    FCacheNestMinimum :=
      FTree.GetHighLighterWithLines.FoldBlockMinLevel(ToIdx(StartLine), FOLDGROUP_IFDEF,
                                           [sfbIncludeDisabled]);
  Result := FCacheNestMinimum;
end;

function TSynMarkupHighIfDefLinesNodeInfo.NestDepthAtNodeStart: Integer;
begin
  assert(FTree <> nil, 'NestDepthAtNodeStart has tree');
  if FCacheNestStart < 0 then
    FCacheNestStart :=
      FTree.GetHighLighterWithLines.FoldBlockEndLevel(ToIdx(StartLine)-1, FOLDGROUP_IFDEF,
                                           [sfbIncludeDisabled]);
  Result := FCacheNestStart;
end;

function TSynMarkupHighIfDefLinesNodeInfo.NestDepthAtNodeEnd: Integer;
begin
  assert(FTree <> nil, 'NestDepthAtNodeEnd has tree');
  if FCacheNestEnd < 0 then
    FCacheNestEnd :=
      FTree.GetHighLighterWithLines.FoldBlockEndLevel(ToIdx(StartLine), FOLDGROUP_IFDEF,
                                           [sfbIncludeDisabled]);
  Result := FCacheNestEnd;
end;

function TSynMarkupHighIfDefLinesNodeInfo.ValidToLine(const ANextNode: TSynMarkupHighIfDefLinesNodeInfo): Integer;
begin
  if not HasNode then
    exit(-1);
  if not IsValid then
    exit(StartLine);

  if ScanEndOffs >= 0 then begin
    Result := StartLine + ScanEndOffs;
    assert((not ANextNode.HasNode) or (Result<ANextNode.StartLine), '(ANextNode=nil) or (Result<ANextNode.StartLine)');
  end
  else
  if ANextNode.HasNode then
    Result := ANextNode.StartLine - 1
  else
    Result := StartLine;
end;

function TSynMarkupHighIfDefLinesNodeInfo.IsValid: Boolean;
begin
  Result := HasNode and (idlValid in LineFlags);
end;

procedure TSynMarkupHighIfDefLinesNodeInfo.Invalidate;
begin
  Exclude(Node.FLineFlags, idlValid);
end;

function TSynMarkupHighIfDefLinesNodeInfo.HasNode: Boolean;
begin
  Result := FNode <> nil;
end;

{ TSynMarkupHighIfDefLinesTree }

procedure TSynMarkupHighIfDefLinesTree.SetHighlighter(AValue: TSynPasSyn);
begin
  if FHighlighter = AValue then Exit;
  FHighlighter := AValue;
  Clear;
end;

procedure TSynMarkupHighIfDefLinesTree.SetLines(AValue: TSynEditStrings);
begin
  if FLines = AValue then Exit;

  if FLines <> nil then begin
    FLines.RemoveChangeHandler(senrHighlightChanged, @DoHighlightChanged);
    FLines.RemoveEditHandler(@DoLinesEdited);
  end;

  FLines := AValue;
  Clear;

  if FLines <> nil then begin
    FLines.AddChangeHandler(senrHighlightChanged, @DoHighlightChanged);
    FLines.AddEditHandler(@DoLinesEdited);
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.MaybeRequestNodeStates(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
var
  e: TSynMarkupHighIfDefEntry;
  i: Integer;
  NewState: TSynMarkupIfdefNodeState;
begin
  if (not (idlHasUnknownNodes in ANode.LineFlags)) or
     (not Assigned(FOnNodeStateRequest)) or
     FRequestingNodeState
  then
    exit;
  Exclude(ANode.Node.FLineFlags, idlHasUnknownNodes);
  FRequestingNodeState := True;
  try
    i := 0;
    while i < ANode.EntryCount do begin
      // replace Sender in Markup object
      e := ANode.Entry[i];
      if e.NeedsRequesting then begin
        NewState := FOnNodeStateRequest(nil, ANode.StartLine, e.StartColumn);
        e.NodeState := NewState;
      end;
      inc(i);
    end;
  finally
    FRequestingNodeState := False;
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.MaybeValidateNode(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
begin
  Assert(ANode.HasNode, 'ANode.HasNode in MaybeValidateNode');
// TODO: search first
  if (not ANode.IsValid) then begin
    debugln(['Validating existing node ', ANode.StartLine, ' - ', ANode.ScanEndLine]);
    ScanLine(ANode.StartLine, ANode.FNode);
  end;
  MaybeRequestNodeStates(ANode);
end;

procedure TSynMarkupHighIfDefLinesTree.MaybeExtendNodeBackward(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
  AStopAtLine: Integer);
var
  Line: Integer;
begin
  Assert(ANode.HasNode, 'ANode.HasNode in MaybeExtendNodeDownwards');
  MaybeValidateNode(ANode);
  if (ANode.EntryCount = 0) then begin
    // ANode is a Scan-Start-Marker and may be extended downto StartLine
    Line := ANode.StartLine;
    while Line > AStopAtLine do begin
      dec(Line);
      if CheckLineForNodes(Line) then begin
        ScanLine(Line, ANode.FNode);
        if ANode.EntryCount > 0 then begin
          MaybeRequestNodeStates(ANode);
          break;
        end;
      end;
    end;
    if ANode.StartLine <> Line then begin
      debugln(['EXTEND BACK node ', ANode.StartLine, ' - ', ANode.ScanEndLine, ' TO ', Line]);
      ANode.StartLine := Line;
    end;
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.MaybeExtendNodeForward(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
  var ANextNode: TSynMarkupHighIfDefLinesNodeInfo; AStopBeforeLine: Integer);
var
  Line: Integer;
begin
  ANextNode.ClearInfo;
  Assert(ANode.IsValid, 'ANode.IsValid in MaybeExtendNodeForward');
  if AStopBeforeLine < 0 then AStopBeforeLine := Lines.Count + 1;
    // ANode is a Scan-Start-Marker and may be extended downto StartLine
    Line := ANode.StartLine + ANode.ScanEndOffs;
    while Line < AStopBeforeLine - 1 do begin
      inc(Line);
      if CheckLineForNodes(Line) then begin
        ScanLine(Line, ANextNode.FNode);
        if ANextNode.HasNode then begin
          ANextNode.FStartLine := Line;  // directly to field
          ANode.ScanEndLine := Line - 1;
          MaybeRequestNodeStates(ANextNode);
          exit;
        end;
      end;
    end;
    // Line is empty, include in offs
    if ANode.ScanEndLine <> Line then begin
      debugln(['EXTEND FORWARD node ', ANode.StartLine, ' - ', ANode.ScanEndLine, ' TO ', Line]);
      ANode.ScanEndLine := Line;
    end;
end;

function TSynMarkupHighIfDefLinesTree.GetOrInsertNodeAtLine(ALinePos: Integer): TSynMarkupHighIfDefLinesNodeInfo;
begin
  Result := FindNodeAtPosition(ALinePos, afmPrev); // might be multiline
  if (not Result.HasNode) then begin
    Result := FindNodeAtPosition(ALinePos, afmCreate);
  end
  else
  if (Result.StartLine <> ALinePos) then begin
    if Result.ScanEndLine >= ALinePos then
      Result.ScanEndLine := ALinePos - 1;
    if Result.LastEntryEndLine > ALinePos then begin
      Result.LastEntryEndLineOffs := 0;
      Assert(Result.EntryCount > 0, 'Result.EntryCount > 0 : in Outer Nesting');
      Result.Entry[Result.EntryCount].MakeUnknown;
      //Result.; xxxxxxxxxxxxxxxxxxxxxxxx TODO invalidate
    end;
    Result := FindNodeAtPosition(ALinePos, afmCreate);
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.ConnectPeers(var ANode: TSynMarkupHighIfDefLinesNodeInfo;
  var ANestList: TSynMarkupHighIfDefLinesNodeInfoList; AOuterLines: TLazSynEditNestedFoldsList);
var
  PeerList: array of TSynMarkupHighIfDefEntry; // List of Else/Endif in the current line, that where opened in a previous line
  OpenList: array of TSynMarkupHighIfDefEntry; // List of IfDef/Else in the current line
  CurDepth, MaxListIdx, MinOpenDepth, MaxOpenDepth, MaxPeerDepth, MinPeerDepth: Integer;
  i, j, OtherDepth: Integer;
  OtherLine: TSynMarkupHighIfDefLinesNodeInfo;

  function OpenIdx(AIdx: Integer): Integer; // correct negative idx
  begin
    Result := AIdx;
    if Result >= 0 then exit;
    Result := MaxListIdx + (-AIdx);
  end;

begin
  /// Scan for onel line blocks
  CurDepth := ANode.NestDepthAtNodeStart;
  MinOpenDepth := MaxInt;
  MaxOpenDepth := -1;
  MinPeerDepth := MaxInt;
  MaxPeerDepth := -1;

  MaxListIdx := CurDepth + ANode.EntryCount + 1;
  SetLength(OpenList, MaxListIdx + ANode.EntryCount);
  SetLength(PeerList, MaxListIdx);

  for i := 0 to ANode.EntryCount - 1 do begin
    case ANode.Entry[i].NodeType of
      idnIfdef: begin
          inc(CurDepth);
          OpenList[OpenIdx(CurDepth)] := ANode.Entry[i]; // Store IfDef, with Index at end of IfDef (inside block)
          if CurDepth < MinOpenDepth then MinOpenDepth := CurDepth;
          if CurDepth > MaxOpenDepth then MaxOpenDepth := CurDepth;
        end;
      idnElse, idnElseIf: begin
          If CurDepth <= 0 then begin
            debugln(['Ignoring node with has no opening at all in line ', ANode.StartLine]);
          end;

          if (CurDepth >= MinOpenDepth) and (CurDepth <= MaxOpenDepth) then begin
            // Opening Node on this line
            assert(CurDepth = MaxOpenDepth, 'ConnectPeers: Same line peer skips opening node(s)');
            case OpenList[OpenIdx(CurDepth)].NodeType of
              idnIfdef, idnElseIf:
                if OpenList[OpenIdx(CurDepth)].ElsePeer <> ANode.Entry[i] then begin
                  Debugln(['New Peer for ',dbgs(OpenList[OpenIdx(CurDepth)].NodeType), ' to else same line']);
                  OpenList[OpenIdx(CurDepth)].ElsePeer := ANode.Entry[i];
                  //dec(MaxOpenDepth); // Will be set with the current entry
                end;
              idnElse: DebugLn('Ignoring invalid double else (on same line)');
            end;
          end
          else
          If CurDepth >= 0 then begin
            // Opening Node in previous line
            PeerList[CurDepth] := ANode.Entry[i];
            assert((MaxPeerDepth=-1) or ((MinPeerDepth <= MaxPeerDepth) and (CurDepth = MinPeerDepth-1)), 'ConnectPeers: skipped noeds during line scan');
            if CurDepth < MinPeerDepth then MinPeerDepth := CurDepth;
            if CurDepth > MaxPeerDepth then MaxPeerDepth := CurDepth;
          end;

          OpenList[OpenIdx(CurDepth)] := ANode.Entry[i]; // Store IfDef, with Index at end of IfDef (inside block)
          if CurDepth < MinOpenDepth then MinOpenDepth := CurDepth;
          if CurDepth > MaxOpenDepth then MaxOpenDepth := CurDepth;
        end;
      idnEndIf: begin
          If CurDepth <= 0 then begin
            debugln(['Ignoring node with has no opening at all in line', ANode.StartLine]);
            dec(CurDepth);
            continue;  // This node has no opening node
          end;

          if (CurDepth >= MinOpenDepth) and (CurDepth <= MaxOpenDepth) then begin
            // Opening Node on this line
            assert(CurDepth = MaxOpenDepth, 'ConnectPeers: Same line peer skips opening node(s)');
            if OpenList[OpenIdx(CurDepth)].EndIfPeer <> ANode.Entry[i] then begin
              Debugln(['New Peer for ',dbgs(OpenList[OpenIdx(CurDepth)].NodeType), ' to endif same line']);
              OpenList[OpenIdx(CurDepth)].EndIfPeer := ANode.Entry[i];
              dec(MaxOpenDepth);
            end;
          end
          else begin
            // Opening Node in previous line
            PeerList[CurDepth] := ANode.Entry[i];
            assert((MaxPeerDepth=-1) or ((MinPeerDepth <= MaxPeerDepth) and (CurDepth = MinPeerDepth-1)), 'ConnectPeers: skipped noeds during line scan');
            if CurDepth < MinPeerDepth then MinPeerDepth := CurDepth;
            if CurDepth > MaxPeerDepth then MaxPeerDepth := CurDepth;
          end;

          dec(CurDepth);
        end;
    end;
  end;



  // Find peers in previous lines. MinPeerDepth <= 0 have no opening
  // Opening (IfDef) nodes will be connected when there closing node is found.
  for i := MaxPeerDepth downto Max(MinPeerDepth, 1) do begin
    // Todo: MAybe optimize, if it can be known that an existing peer link is correct
    //case PeerList[i].NodeType of
    //  idnElse:  if PeerList[i].IfDefPeer <> nil then continue;
    //  idnEndIf: if PeerList[i].ElsePeer  <> nil then continue;
    //end;

    if (PeerList[i].NodeType = idnElse) and (AOuterLines <> nil) then begin
      // scanning outer lines
      j := ToPos(AOuterLines.NodeLineEx[i-1, 1]);
      if j < 0 then begin
        debugln(['Skipping peer for ELSE with NO IFDEF at depth ', i-1, ' before line ', ANode.StartLine]);
        continue;
      end;
      OtherLine := GetOrInsertNodeAtLine(j);
      MaybeValidateNode(OtherLine);
    end
    else
      OtherLine := ANestList.Node[i];

    OtherDepth := OtherLine.NestDepthAtNodeEnd;
    j := OtherLine.EntryCount;
    while j > 0 do begin
      dec(j);
      if OtherDepth = i then begin
        case OtherLine.Entry[j].NodeType of
          idnIfdef: begin
              assert(PeerList[i].NodeType in [idnElse, idnElseIf, idnEndIf], 'PeerList[i].NodeType in [idnElse, idnEndIf] for other ifdef');
              if PeerList[i].IfDefPeer <> OtherLine.Entry[j] then begin
                if OtherLine.Entry[j].GetPeer(PeerList[i].NodeType) <> nil then begin
                  debugln(['COMPARING MaxPeerdepth for ',dbgs(PeerList[i].NodeType), ' to ifdef other line']);
                  if (OtherLine.NestDepthAtNodeStart + OtherLine.Entry[j].RelativeNestDepth + 1 = i
//                     ANode.NestDepthAtNodeStart + PeerList[i].RelativeNestDepth
)
                  then begin
                    Debugln(['New Peer (REPLACE) for ',dbgs(PeerList[i].NodeType), ' to ifdef other line']);
                    PeerList[i].IfDefPeer := OtherLine.Entry[j];
                  end;
                end
                else begin
                  Debugln(['New Peer for ',dbgs(PeerList[i].NodeType), ' to ifdef other line']);
                  PeerList[i].IfDefPeer := OtherLine.Entry[j];
                end;
              end;
              j := -1;
              break;
            end;
          idnElse, idnElseIf: begin
              assert(PeerList[i].NodeType in [idnElse, idnElseIf, idnEndIf], 'PeerList[i].NodeType in [idnElse, idnEndIf] for other else');
              if (PeerList[i].NodeType = idnEndIf) then begin
                if PeerList[i].ElsePeer <> OtherLine.Entry[j] then begin

                  if OtherLine.Entry[j].GetPeer(PeerList[i].NodeType) <> nil then begin
                    debugln(['COMPARING MaxPeerdepth for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                    if OtherLine.NestDepthAtNodeStart + OtherLine.Entry[j].RelativeNestDepth = i
//                       ANode.NestDepthAtNodeStart + PeerList[i].RelativeNestDepth
                    then begin
                      Debugln(['New Peer (REPLACE) for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                      PeerList[i].ElsePeer := OtherLine.Entry[j];
                    end;
                  end
                  else begin
                    Debugln(['New Peer for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                    PeerList[i].ElsePeer := OtherLine.Entry[j];
                  end;
                end;
                j := -1;
              end
              else
              if (PeerList[i].NodeType in [idnElseIf, idnElse]) and (OtherLine.Entry[j].NodeType = idnElseIf)
              then begin
                if PeerList[i].IfDefPeer <> OtherLine.Entry[j] then begin
                  if OtherLine.Entry[j].GetPeer(PeerList[i].NodeType) <> nil then begin
                    debugln(['COMPARING MaxPeerdepth for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                    if OtherLine.NestDepthAtNodeStart + OtherLine.Entry[j].RelativeNestDepth = i
//                       ANode.NestDepthAtNodeStart + PeerList[i].RelativeNestDepth
                    then begin
                      Debugln(['New Peer (REPLACE) for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                      PeerList[i].IfDefPeer := OtherLine.Entry[j];
                    end;
                  end
                  else begin
                    Debugln(['New Peer for ',dbgs(PeerList[i].NodeType), ' to else other line']);
                    PeerList[i].IfDefPeer := OtherLine.Entry[j];
                  end;
                end;
                j := -1;
              end
              else begin
                DebugLn('Ignoring invalid double else');
              end;
              break;
            end;
        end;
      end;
      case OtherLine.Entry[j].NodeType of
        idnIfdef: inc(OtherDepth);
        idnElse, idnElseIf:  ; //
        idnEndIf: dec(OtherDepth);
      end;
    end;

    if j >= 0 then begin
      // no peer found
      case PeerList[i].NodeType of
        idnIfdef: ;
        idnElse, idnElseIf:  begin
            Debugln(['CLEARING ifdef Peer for ',dbgs(PeerList[i].NodeType)]);
            PeerList[i].IfDefPeer := nil;
            //DoModified;
          end;
        idnEndIf: begin
            Debugln(['CLEARING BOTH Peer for ',dbgs(PeerList[i].NodeType)]);
            PeerList[i].ClearPeers;
            //DoModified;
          end;
      end;

    end;

  end;
end;

procedure TSynMarkupHighIfDefLinesTree.DoLinesEdited(Sender: TSynEditStrings; aLinePos,
  aBytePos, aCount, aLineBrkCnt: Integer; aText: String);

  function IndexOfEntryAfter(ANode: TSynMarkupHighIfDefLinesNode; AXPos: Integer): Integer;
  var
    Cnt: Integer;
  begin
    Result := 0;
    Cnt := aNode.EntryCount;
    while (Result < Cnt) and (ANode.Entry[Result].StartColumn < aBytePos) do
      inc(Result);
    // if LastEntryEndLineOffs = 0, then keep at count. Migth check closing pos of (Result-1)
    if (Result = Cnt) and (ANode.LastEntryEndLineOffs > 0) then
      Result := -1;
  end;

  procedure AdjustEntryXPos(ANode: TSynMarkupHighIfDefLinesNode; ADiffX: Integer;
    AStartIdx: Integer = 0; ADestNode: TSynMarkupHighIfDefLinesNode = nil);
  var
    Cnt, SkipEndIdx, DestPos, j: Integer;
    CurEntry: TSynMarkupHighIfDefEntry;
  begin
    Cnt := aNode.EntryCount;
    if AStartIdx >= Cnt then
      exit;
    if (aNode.LastEntryEndLineOffs > 0) then
      SkipEndIdx := Cnt - 1
    else
      SkipEndIdx := -1;

    if ADestNode = nil then begin
      for j := AStartIdx to Cnt - 1 do begin
        CurEntry := aNode.Entry[j];
        CurEntry.StartColumn := CurEntry.StartColumn + ADiffX;
        if (j <> SkipEndIdx) then
          CurEntry.EndColumn   := CurEntry.EndColumn + ADiffX;
      end;
    end
    else begin
      DestPos := ADestNode.EntryCount;
      ADestNode.EntryCount := DestPos + (Cnt - AStartIdx);
      for j := AStartIdx to Cnt - 1 do begin
        CurEntry := aNode.Entry[j];
        aNode.Entry[j] := nil;
        CurEntry.StartColumn := CurEntry.StartColumn + ADiffX;
        if (j <> SkipEndIdx) then
          CurEntry.EndColumn   := CurEntry.EndColumn + ADiffX;
        ADestNode.Entry[DestPos] := CurEntry;
        inc(DestPos);
      end;
      ANode.EntryCount := AStartIdx;
      ADestNode.LastEntryEndLineOffs := ANode.LastEntryEndLineOffs;
      ANode.LastEntryEndLineOffs := 0;
    end;
  end;

var
  i, c: Integer;
  WorkNode, NextNode, LinePosNode: TSynMarkupHighIfDefLinesNodeInfo;
  WorkLine, LineAfterDelete: Integer;

begin
  // Line nodes vill be invalidated in DoHighlightChanged

  if aLineBrkCnt > 0 then begin
    WorkNode := FindNodeAtPosition(aLinePos - 1, afmPrev);
    if WorkNode.HasNode then begin
      WorkLine := WorkNode.StartLine;
      if aLinePos <= WorkNode.LastEntryEndLine then begin
        c := WorkNode.EntryCount - 1;
        assert(c >= 0, 'must have node, if LastEntryOffs > 0 [insert lines]');
        if (aLinePos = WorkNode.LastEntryEndLine) then begin
          if (WorkNode.Entry[c].EndColumn > aBytePos) then begin
            WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs + aLineBrkCnt;
            WorkNode.Entry[c].EndColumn := WorkNode.Entry[c].EndColumn - aBytePos + 1;
          end;
        end
        else
          WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs + aLineBrkCnt;
        WorkNode.Entry[c].MakeUnknown;
      end;
      if aLinePos <= WorkLine + WorkNode.ScanEndOffs then begin
        assert(aLinePos > WorkLine);
        WorkNode.ScanEndOffs := aLinePos - WorkLine;
      end;
    end;

    WorkNode := WorkNode.Successor;
    if (not WorkNode.HasNode) then
      exit;
    WorkLine := WorkNode.StartLine;
    NextNode.ClearInfo;

    if (WorkLine > aLinePos) or
       ( (WorkLine = aLinePos) and
         ( (aBytePos <= 1) or (WorkNode.EntryCount = 0) or (WorkNode.Entry[0].StartColumn >= aBytePos) )
       )
    then begin
      // Move Entire Line
      AdjustForLinesInserted(aLinePos, aLineBrkCnt);
      // Adjust the FIELD directly
      WorkNode.FStartLine := WorkNode.FStartLine + aLineBrkCnt;
      if aBytePos > 1 then
        AdjustEntryXPos(WorkNode.Node, (-aBytePos) + 1);
    end
    else begin
      // Move part of Line (or nothing)
      AdjustForLinesInserted(aLinePos + 1, aLineBrkCnt);
      if (WorkLine = aLinePos) then begin
        i := IndexOfEntryAfter(WorkNode.Node, aBytePos);
        if i >= 0 then begin
          NextNode := FindNodeAtPosition(aLinePos + aLineBrkCnt, afmCreate);
          AdjustEntryXPos(WorkNode.Node, (-aBytePos) + 1, i, NextNode.Node);
          if (i > 0) and (WorkNode.Entry[i-1].EndColumn > aBytePos) then begin
            WorkNode.LastEntryEndLineOffs := aLineBrkCnt;
            WorkNode.Entry[i-1].EndColumn := WorkNode.Entry[i-1].EndColumn - aBytePos + 1;
            WorkNode.Entry[i-1].MakeUnknown;
          end;
        end
        else begin
          assert(WorkNode.LastEntryEndLineOffs > 0, 'WorkNode.LastEntryEndLineOffs > 0');
          c := WorkNode.EntryCount - 1;
          if (c >= 0) and (WorkNode.Entry[c].StartColumn < aBytePos) then begin
            WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs + aLineBrkCnt;
            WorkNode.Entry[c].MakeUnknown;
          end;
        end;
      end
      else begin
        if aLinePos <= WorkNode.LastEntryEndLine then begin
          c := WorkNode.EntryCount - 1;
          assert(c >= 0, 'must have node, if LastEntryOffs > 0 [insert lines]');
          if (aLinePos = WorkNode.LastEntryEndLine) then begin
            if (WorkNode.Entry[c].EndColumn > aBytePos) then begin
              WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs + aLineBrkCnt;
              WorkNode.Entry[c].EndColumn := WorkNode.Entry[c].EndColumn - aBytePos + 1;
            end;
          end
          else
            WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs + aLineBrkCnt;
          WorkNode.Entry[c].MakeUnknown;
        end;
        if aLinePos <= WorkLine + WorkNode.ScanEndOffs then begin
          assert(aLinePos > WorkLine);
          WorkNode.ScanEndOffs := aLinePos - WorkLine;
        end;
      end;
    end;
//DebugLn('---INS');DebugPrint(true);
  end

  else
  if aLineBrkCnt < 0 then begin
    aLineBrkCnt := - aLineBrkCnt;
    WorkNode := FindNodeAtPosition(aLinePos - 1, afmPrev);
    if WorkNode.HasNode then begin
      WorkLine := WorkNode.StartLine;
      if aLinePos <= WorkNode.LastEntryEndLine then begin
        c := WorkNode.EntryCount - 1;
        assert(c >= 0, 'must have node, if LastEntryOffs > 0 [insert lines]');
        if (aLinePos < WorkNode.LastEntryEndLine) or (WorkNode.Entry[c].EndColumn > aBytePos) then begin
          if aLinePos + aLineBrkCnt > WorkNode.LastEntryEndLine then
            WorkNode.Entry[c].EndColumn := 1
          else
          if (aLinePos + aLineBrkCnt = WorkNode.LastEntryEndLine) then
            WorkNode.Entry[c].EndColumn := WorkNode.Entry[c].EndColumn + aBytePos - 1;
          WorkNode.LastEntryEndLineOffs := WorkNode.LastEntryEndLineOffs - aLineBrkCnt;
          WorkNode.Entry[c].MakeUnknown;
        end;
      end;
      if aLinePos <= WorkLine + WorkNode.ScanEndOffs then begin
        assert(aLinePos > WorkLine);
        WorkNode.ScanEndOffs := aLinePos - WorkLine;
      end;
    end;

    WorkNode := WorkNode.Successor;
    if (not WorkNode.HasNode) then
      exit;
    WorkLine := WorkNode.StartLine;
    NextNode.ClearInfo;

    LinePosNode.ClearInfo;
    if (WorkNode.StartLine = aLinePos) then begin
      LinePosNode := WorkNode;
      WorkNode := WorkNode.Successor;
    end;
    LineAfterDelete := aLinePos + aLineBrkCnt;
    while (WorkNode.HasNode) and (WorkNode.StartLine < LineAfterDelete) do begin
      NextNode := WorkNode.Successor;
      RemoveLine(WorkNode.FNode);
DebugLn(['RemoveLine ', WorkNode.StartLine]);
      WorkNode := NextNode;
    end;

    if LinePosNode.HasNode and (LinePosNode.LastEntryEndLineOffs > 0) then begin
      c := LinePosNode.EntryCount - 1;
      if LinePosNode.LastEntryEndLineOffs < aLineBrkCnt then
        LinePosNode.Entry[c].EndColumn := aBytePos //  no known end
      else
      if LinePosNode.LastEntryEndLineOffs = aLineBrkCnt then
        LinePosNode.Entry[c].EndColumn := LinePosNode.Entry[c].EndColumn + aBytePos - 1;
      LinePosNode.LastEntryEndLineOffs := Max(0, LinePosNode.LastEntryEndLineOffs - aLineBrkCnt);
    end;
    if (WorkNode.StartLine = LineAfterDelete) then begin
      if LinePosNode.HasNode then begin
        AdjustEntryXPos(WorkNode.Node, aBytePos - 1, 0, LinePosNode.Node);
DebugLn(['RemoveLine XX ', WorkNode.StartLine]);
        RemoveLine(WorkNode.FNode);
        WorkNode.ClearInfo;
      end
      else begin
        AdjustEntryXPos(WorkNode.Node, aBytePos - 1);
DebugLn(['change startline ', WorkNode.StartLine ,' to ', aLinePos]);
        WorkNode.StartLine := aLinePos;
      end;
    end;

//DebugPrint(true);
    AdjustForLinesDeleted(aLinePos + 1, aLineBrkCnt);
//DebugLn('---DEL');DebugPrint(true);
  end

  else begin
    WorkNode := FindNodeAtPosition(aLinePos, afmPrev);
    if (not WorkNode.HasNode) then
      exit;
    WorkLine := WorkNode.StartLine;

    if aLinePos = WorkLine then begin
      i := IndexOfEntryAfter(WorkNode.Node, aBytePos);
      if i >= 0 then begin
        AdjustEntryXPos(WorkNode.Node, aCount, i);
        if (i > 0) and (WorkNode.Entry[i-1].EndColumn > aBytePos) then begin
          WorkNode.Entry[i-1].EndColumn := Max(aBytePos, WorkNode.Entry[i-1].EndColumn + aCount);
          WorkNode.Entry[i-1].MakeUnknown;
        end;
        if aCount < 0 then begin
          c := WorkNode.EntryCount - 1;
          while ( (i < c) or ((i = c) and (WorkNode.LastEntryEndLineOffs=0)) ) and
                (WorkNode.Entry[i].EndColumn < aBytePos)
          do begin
            WorkNode.Node.DeletEntry(i, True);
            dec(c);
          end;
          if (i <= c) and (WorkNode.Entry[i].StartColumn < aBytePos) then begin
            WorkNode.Entry[i].StartColumn := aBytePos;
            WorkNode.Entry[i].MakeUnknown;
          end;
        end;
      end;
//DebugLn('---MOV');DebugPrint(true);

      WorkNode := WorkNode.Precessor;
      if (not WorkNode.HasNode) then
        exit;
    end;

    assert(WorkNode.StartLine < aLinePos);
    WorkLine := WorkNode.StartLine + WorkNode.ScanEndOffs;
    if (WorkLine >= aLinePos) then
      WorkNode.ScanEndOffs := aLinePos - 1 - WorkNode.StartLine;

    WorkLine := WorkNode.StartLine + WorkNode.LastEntryEndLineOffs;
    i := WorkNode.EntryCount - 1;
    if (WorkLine >= aLinePos) and (i >= 0) then begin
      if (WorkLine = aLinePos) and (WorkNode.Entry[i].EndColumn > aBytePos) then
        WorkNode.Entry[i].EndColumn := Max(aBytePos, WorkNode.Entry[i].EndColumn + aCount);
      WorkNode.Entry[i].MakeUnknown;
    end;

  end;

end;

procedure TSynMarkupHighIfDefLinesTree.DoHighlightChanged(Sender: TSynEditStrings; AIndex,
  ACount: Integer);
var
  LinePos: Integer;
  WorkNode: TSynMarkupHighIfDefLinesNodeInfo;
begin
  // Invalidate. The highlighter should only run once, so no need to collect multply calls
  LinePos := ToPos(AIndex);
  WorkNode := FindNodeAtPosition(LinePos, afmPrev);
  if WorkNode.HasNode and (Max(WorkNode.ScanEndLine, WorkNode.LastEntryEndLine) >= LinePos) then
    WorkNode.Invalidate;
  WorkNode := WorkNode.Successor;
  LinePos := LinePos + ACount;
  while WorkNode.HasNode and (WorkNode.StartLine <= LinePos) do begin
    WorkNode.Invalidate;
    WorkNode := WorkNode.Successor;
  end;
end;

function TSynMarkupHighIfDefLinesTree.GetHighLighterWithLines: TSynCustomFoldHighlighter;
begin
  Result := FHighlighter;
  if (Result = nil) then
    exit;
  Result.CurrentLines := FLines;
end;

function TSynMarkupHighIfDefLinesTree.CreateNode(APosition: Integer): TSynSizedDifferentialAVLNode;
begin
  if FDisposedNodes <> nil then begin
    Result := FDisposedNodes;
    FDisposedNodes := TSynMarkupHighIfDefLinesNode(Result).NextDispose;
    TSynMarkupHighIfDefLinesNode(Result).FLineFlags := [];
  end
  else
    Result := TSynMarkupHighIfDefLinesNode.Create;
end;

procedure TSynMarkupHighIfDefLinesTree.DisposeNode(var ANode: TSynSizedDifferentialAVLNode);
begin
  if FClearing then begin
    Include(TSynMarkupHighIfDefLinesNode(ANode).FLineFlags, idlInGlobalClear);
    inherited DisposeNode(ANode);
  end
  else begin
    TSynMarkupHighIfDefLinesNode(ANode).MakeDisposed;
    TSynMarkupHighIfDefLinesNode(ANode).NextDispose := FDisposedNodes;
    FDisposedNodes := TSynMarkupHighIfDefLinesNode(ANode);
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.RemoveLine(var ANode: TSynMarkupHighIfDefLinesNode);
begin
  RemoveNode(TSynSizedDifferentialAVLNode(ANode));
  DisposeNode(TSynSizedDifferentialAVLNode(ANode));
end;

constructor TSynMarkupHighIfDefLinesTree.Create;
begin
  inherited Create;
  FRequestingNodeState := False;
  MaybeCreateDict;
  TheDict.AddReference;
end;

destructor TSynMarkupHighIfDefLinesTree.Destroy;
begin
  Lines := nil;
  inherited Destroy;
  TheDict.ReleaseReference;
end;

function TSynMarkupHighIfDefLinesTree.CreateOpeningList: TLazSynEditNestedFoldsList;
begin
  Result := TLazSynEditNestedFoldsList.Create(@GetHighLighterWithLines);
  Result.ResetFilter;
  Result.Clear;
  //Result.Line :=
  Result.FoldGroup := FOLDGROUP_IFDEF;
  Result.FoldFlags := [sfbIncludeDisabled];
  Result.IncludeOpeningOnLine := False;
end;

procedure TSynMarkupHighIfDefLinesTree.DiscardOpeningList(AList: TLazSynEditNestedFoldsList);
begin
  AList.Free;
end;

function TSynMarkupHighIfDefLinesTree.CheckLineForNodes(ALine: Integer): Boolean;
var
  m, e: Integer;
  LineText, LineTextLower: String;
  h: TSynCustomFoldHighlighter;
begin
  h := GetHighLighterWithLines;
  m := h.FoldBlockMinLevel(ToIdx(ALine), FOLDGROUP_IFDEF, [sfbIncludeDisabled]);
  e := h.FoldBlockEndLevel(ToIdx(ALine), FOLDGROUP_IFDEF, [sfbIncludeDisabled]);
  Result := (m < e);

  if not Result then begin
    LineText := Lines[ToIdx(ALine)];
    if LineText = '' then
      exit;
    LineTextLower := LowerCase(LineText);
    Result := TheDict.Dict.Search(@LineTextLower[1], Length(LineTextLower), nil) <> nil;
  end;
end;

procedure TSynMarkupHighIfDefLinesTree.ScanLine(ALine: Integer;
  var ANodeForLine: TSynMarkupHighIfDefLinesNode; ACheckOverlapOnCreateLine: Boolean);
var
  FoldNodeInfoList: TLazSynFoldNodeInfoList;
  LineTextLower: String;
  NodesAddedCnt: Integer;
  LineNeedsReq: Boolean;

  function FindCloseCurlyBracket(StartX: Integer; out ALineOffs: Integer): Integer;
  var
    CurlyLvl: Integer;
    i, l, c: Integer;
    s: String;
  begin
    Result := StartX;
    ALineOffs := 0;
    CurlyLvl := 1;

    l := Length(LineTextLower);
    while Result <= l do begin
      case LineTextLower[Result] of
        '{': inc(CurlyLvl);
        '}': if CurlyLvl = 1 then exit
             else dec(CurlyLvl);
      end;
      inc(Result);
    end;

    c := Lines.Count;
    i := ToIdx(ALine) + 1;
    inc(ALineOffs);
    while (i < c) do begin
      // TODO: get range flag fron pas highlighter
      s := Lines[i];
      l := Length(s);
      Result := 1;
      while Result <= l do begin
        case s[Result] of
          '{': inc(CurlyLvl);
          '}': if CurlyLvl = 1 then exit
               else dec(CurlyLvl);
        end;
        inc(Result);
      end;
      inc(i);
      inc(ALineOffs);
    end;

    Result := -1;
  end;

  function GetEntry(ALogStart, ALogEnd, ALineOffs: Integer;
    AType: TSynMarkupIfdefNodeType): TSynMarkupHighIfDefEntry;
  var
    i: Integer;
  begin
    if ANodeForLine = nil then begin
      if ACheckOverlapOnCreateLine then
        ANodeForLine := GetOrInsertNodeAtLine(ALine).Node
      else
        ANodeForLine := FindNodeAtPosition(ALine, afmCreate).FNode;
      ANodeForLine.EntryCapacity := FoldNodeInfoList.Count;
    end;
    if NodesAddedCnt >= ANodeForLine.EntryCount then begin
      DebugLn(['Add Entry at end ', dbgs(AType)]);
      Result := ANodeForLine.AddEntry;
      LineNeedsReq := True;
    end
    else begin
      // TODO: check for commented notes, maybe keep
      i := NodesAddedCnt;
      Result := nil;

      // Check if existing node matches
      while (i < ANodeForLine.EntryCount-1) and (ANodeForLine.Entry[i].StartColumn < ALogStart) do
        inc(i);
      if i < ANodeForLine.EntryCount then begin
        Result := ANodeForLine.Entry[i];
        if (Result.NodeType = AType) and
           (Result.StartColumn = ALogStart) and
           (Result.EndColumn = ALogEnd) and
           ((idnMultiLineTag in Result.NodeFlags) = (ALineOffs > 0)) and
           ( (ALineOffs = 0) or (ALineOffs = ANodeForLine.LastEntryEndLineOffs) )
        then begin
          // Does match exactly, keep as is
          DebugLn(['++++ KEEPING NODE ++++ ', ALine, ' ', dbgs(AType), ': ', ALogStart, ' - ', ALogEnd]);
          if not LineNeedsReq then
            LineNeedsReq := Result.NeedsRequesting;
          if i > NodesAddedCnt then begin
            // Delete the skipped notes
            dec(i);
            while i >= NodesAddedCnt do begin
              ANodeForLine.DeletEntry(i, True);
              dec(i);
            end;
          end;
        end
        else
          Result := nil;
      end;

      If Result = nil then begin
        DebugLn(['Add Entry ', dbgs(AType), ' at idx ', NodesAddedCnt, ' of ', ANodeForLine.EntryCount]);
        // No matching node found
        if ANodeForLine.Entry[NodesAddedCnt].StartColumn < ALogEnd then
          Result := ANodeForLine.Entry[NodesAddedCnt]
        else
          Result := ANodeForLine.AddEntry(NodesAddedCnt);
        Result.ClearPeers;
        Result.FNodeType := AType;
        LineNeedsReq := True;
      end;
    end;
    inc(NodesAddedCnt);
    Result.StartColumn := ALogStart;
    Result.EndColumn   := ALogEnd;
    Result.FNodeType := AType;
  end;

var
  fn, fn2: TSynFoldNodeInfo;
  LogStartX, LogEndX, LineLen, LineOffs: Integer;
  Entry: TSynMarkupHighIfDefEntry;
  i, c, RelNestDepth, RelNestDepthNext: Integer;
  NType: TSynMarkupIfdefNodeType;
begin
  DebugLnEnter(['>> ScanLine ', ALine, ' ', dbgs(ANodeForLine), ' ', dbgs(ACheckOverlapOnCreateLine)]);
  LineNeedsReq := False;
  FoldNodeInfoList := GetHighLighterWithLines.FoldNodeInfo[ToIdx(ALine)];
  FoldNodeInfoList.AddReference;
  FoldNodeInfoList.ActionFilter := []; //[sfaOpen, sfaClose];
  FoldNodeInfoList.GroupFilter := FOLDGROUP_IFDEF;

  if (ANodeForLine <> nil) and (ANodeForLine.EntryCapacity < FoldNodeInfoList.Count) then
    ANodeForLine.EntryCapacity := FoldNodeInfoList.Count;
  NodesAddedCnt := 0;
  RelNestDepthNext := 0;

  LineTextLower := LowerCase(Lines[ToIdx(ALine)]);
  LineLen := Length(LineTextLower);

  i := -1;
  LogEndX := 0;
  c := FoldNodeInfoList.Count - 1;
  while i < c do begin
    inc(i);
    fn := FoldNodeInfoList[i];
    if sfaInvalid in fn.FoldAction then
      continue;

    LogStartX := ToPos(fn.LogXStart)-1;  // LogXStart is at "$", we need "{"
    if (LogStartX < 1) or (LogStartX > LineLen) then begin
      assert(false, '(LogStartX < 1) or (LogStartX > LineLen) ');
      continue;
    end;
//    assert(LogStartX >= LogEndX, 'ifdef xpos found before end of previous ifdef');

    LogEndX := FindCloseCurlyBracket(LogStartX+1, LineOffs) + 1;
    RelNestDepth := RelNestDepthNext;
    case TheDict.GetMatchAtChar(@LineTextLower[LogStartX], LineLen + 1 - LogStartX) of
      1: // ifdef
        begin
          assert(sfaOpen in fn.FoldAction, 'sfaOpen in fn.FoldAction');
          NType := idnIfdef;
          inc(RelNestDepthNext);
        end;
      2: // else
        begin
          assert(i < c, '$ELSE i < c');
          inc(i);
          fn2 := FoldNodeInfoList[i];
          assert(sfaClose in fn.FoldAction, 'sfaClose in fn.FoldAction');
          assert(sfaOpen in fn2.FoldAction, 'sfaOpen in fn2.FoldAction');
          assert(fn.LogXStart = fn2.LogXStart, 'sfaOpen in fn2.FoldAction');
          NType := idnElse;
        end;
      3: // endif
        begin
          assert(sfaClose in fn.FoldAction, 'sfaOpen in fn.FoldAction');
          NType := idnEndIf;
          dec(RelNestDepthNext);
        end;
      4: // ElseIf
        begin
          assert(i < c, '$ELSE i < c');
          inc(i);
          fn2 := FoldNodeInfoList[i];
          assert(sfaClose in fn.FoldAction, 'sfaClose in fn.FoldAction');
          assert(sfaOpen in fn2.FoldAction, 'sfaOpen in fn2.FoldAction');
          assert(fn.LogXStart = fn2.LogXStart, 'sfaOpen in fn2.FoldAction');
          NType := idnElseIf;
        end;
      else
        begin
          assert(false, 'not found ifdef');
          continue;
        end;
    end;

    Entry := GetEntry(LogStartX, LogEndX, LineOffs, NType);
    Entry.FRelativeNestDepth := RelNestDepth;

    if LineOffs > 0 then begin
      if ANodeForLine.LastEntryEndLineOffs <> LineOffs then begin
        LineNeedsReq := True;
      end;
      ANodeForLine.LastEntryEndLineOffs := LineOffs;
      Include(Entry.FNodeFlags, idnMultiLineTag);
      break;
    end;

  end;

  FoldNodeInfoList.ReleaseReference;
  if ANodeForLine <> nil then begin
    Include(ANodeForLine.FLineFlags, idlValid);
    if (NodesAddedCnt > 0) and LineNeedsReq then
      Include(ANodeForLine.FLineFlags, idlHasUnknownNodes);
    ANodeForLine.EntryCount := NodesAddedCnt;
    ANodeForLine.ReduceCapacity;
    ANodeForLine.ScanEndOffs := Max(0, LineOffs-1);
  end;
  DebugLnExit(['<< ScanLine']);
end;

procedure TSynMarkupHighIfDefLinesTree.ValidateRange(AStartLine, AEndLine: Integer;
  OuterLines: TLazSynEditNestedFoldsList);
var
  NestList: TSynMarkupHighIfDefLinesNodeInfoList;

  procedure FixNodePeers(var ANode: TSynMarkupHighIfDefLinesNodeInfo);
  begin
    if ANode.EntryCount = 0 then
      exit;
    ConnectPeers(ANode, NestList);
    NestList.PushNodeLine(ANode);
  end;

var
  NextNode, Node, TmpNode: TSynMarkupHighIfDefLinesNodeInfo;
  i, j, NodeValidTo: Integer;
  SkipPeers: Boolean;
begin
XXXCurTree := self; try
  TmpNode.FTree := Self;

  (*** Outer Nesting ***)
  OuterLines.Line := ToIdx(AStartLine);
  For i := 0 to OuterLines.Count - 1 do begin
    j := ToPos(OuterLines.NodeLine[i]);
    Node := GetOrInsertNodeAtLine(j);
    Assert(CheckLineForNodes(j), 'CheckLineForNodes(j) : in Outer Nesting');
    MaybeValidateNode(Node);
//    FixNodePeers(Node);
    ConnectPeers(Node, NestList, OuterLines);
    NestList.PushNodeLine(Node);
  end;

  (*** Find or create a node for StartLine ***)

  Node := FindNodeAtPosition(AStartLine, afmPrev); // might be multiline
//debugln(['Validate RANGE ', AStartLine, ' - ', AEndLine,' -- 1st node ', Node.StartLine, ' - ', Node.ScanEndLine]);
  NextNode := Node.Successor;
  assert((not NextNode.HasNode) or (AStartLine < NextNode.StartLine), 'AStartLine < NextNode.StartLine');

  if (not Node.HasNode) or (AStartLine > Node.ValidToLine(NextNode)) then begin
    // Node does not cover startline
    if NextNode.HasNode and (NextNode.EntryCount = 0) then begin
      // NextNode is/was a Start-Of-Scan marker
      if (not NextNode.IsValid) then begin
        Node := NextNode;
        Node.StartLine := AStartLine;
        NextNode := Node.Successor;
      end
      else
      if (NextNode.StartLine <= AEndLine) then begin
        MaybeExtendNodeBackward(NextNode, AStartLine);
        if NextNode.StartLine = AStartLine then begin
          Node := NextNode;
          NextNode := Node.Successor;
        end;
      end;
    end;

    if (not Node.HasNode) or (AStartLine > Node.ValidToLine(NextNode)) then begin
      Node := FindNodeAtPosition(AStartLine, afmCreate);
      NextNode := Node.Successor;
    end;
  end;

  SkipPeers := Node.StartLine < AStartLine; // NO peer info available, if node starts before startline
  MaybeValidateNode(Node);
  assert((AStartLine >= Node.StartLine) and (AStartLine <= Node.StartLine + Node.ScanEndLine), 'AStartLine is in Node');

  (*** Node is at StartLine, NextNode is set --- Scan to Endline ***)

  while (Node.HasNode) and (NextNode.HasNode) and
        (Node.ValidToLine(NextNode) < AEndLine) and
        (NextNode.StartLine <= AEndLine)
  do begin
    Assert(Node.IsValid, 'Node.IsValid while "Scan to Endline"');
//DebugLn('#L==='); DebugPrint(true);NestList.dbg;DebugLn('#L');

    if not SkipPeers then
      FixNodePeers(Node);
    SkipPeers := False;
    MaybeValidateNode(NextNode);
    NodeValidTo := Node.ValidToLine(NextNode);
    MaybeExtendNodeBackward(NextNode, NodeValidTo + 1);
    assert(NextNode.StartLine > NodeValidTo, 'NextNode.StartLine > NodeValidTo');

    TmpNode.ClearInfo;
    MaybeExtendNodeForward(Node, TmpNode, NextNode.StartLine);
    assert(NextNode.StartLine > Node.ScanEndLine, 'NextNode.StartLine > Node.ScanEndLine');

    if NextNode.StartLine = Node.ScanEndLine + 1 then begin
      Assert(not TmpNode.HasNode, 'not TmpNode.HasNode');
      if NextNode.EntryCount = 0 then begin
        // Merge nodes
        Node.ScanEndOffs := Node.ScanEndOffs  + NextNode.ScanEndOffs + 1;
        RemoveLine(NextNode.FNode);
        NextNode := Node.Successor;
        // Do NOT FixNodePeers again for Node
        SkipPeers := True;
      end
      else begin
        Node := NextNode;
        NextNode := Node.Successor;
      end;
      continue;
    end;

    // scan gap
    Assert(TmpNode.HasNode, 'TmpNode.HasNode');
    Assert(NextNode.EntryCount > 0, 'NextNode.EntryCount > 0');
    Node := TmpNode;
    TmpNode.ClearInfo;
    while Node.ScanEndLine + 1 < NextNode.StartLine do begin
      MaybeExtendNodeForward(Node, TmpNode, NextNode.StartLine);
      if not TmpNode.HasNode then
        break;
      FixNodePeers(Node);
      assert(Node.ScanEndLine + 1 < NextNode.StartLine, 'Scan gap still before next node');
      Node := TmpNode;
      TmpNode.ClearInfo;
    end;
    assert(Node.ScanEndLine + 1 = NextNode.StartLine, 'Scan gap has reached next node');
    NextNode := Node.Successor;

  end;

  assert(Node.HasNode);
//DebugLn('#F==='); DebugPrint(true);NestList.dbg;DebugLn('#F');
  if not SkipPeers then
    FixNodePeers(Node);


  while Node.ScanEndLine < AEndLine do begin
    MaybeExtendNodeForward(Node, TmpNode, AEndLine + 1);
    if not TmpNode.HasNode then
      break;
    assert(Node.ScanEndLine < AEndLine, 'Scan gap still before AEndLine');
    Node := TmpNode;
    TmpNode.ClearInfo;

    FixNodePeers(Node);
  end;
  assert(Node.ScanEndLine >= AEndLine, 'Scan gap has reached AEndLine');

finally XXXCurTree := nil; end;
end;

procedure TSynMarkupHighIfDefLinesTree.SetNodeState(ALinePos, AstartPos: Integer;
  AState: TSynMarkupIfdefNodeState);
var
  Node: TSynMarkupHighIfDefLinesNodeInfo;
  e, e2: TSynMarkupHighIfDefEntry;
  LineNeedReq: Boolean;
  i: Integer;
begin
  Node := FindNodeAtPosition(ALinePos, afmNil);
  if not Node.HasNode then begin
    ScanLine(ALinePos, Node.FNode, True);
    if Node.HasNode then begin
      Node.FStartLine := ALinePos;  // directly to field
    end
    else begin
      assert(false, 'SetNodeState did not find a node (ScanLine)');
      exit;
    end;
  end;

  i := Node.EntryCount;
  assert(i > 0, 'SetNodeState did not find a node (zero entries)');
  e := nil;
  LineNeedReq := False;
  repeat
    dec(i);
    e2 := Node.Entry[i];
    if e2.StartColumn = AstartPos then
      e := e2
    else
      LineNeedReq := LineNeedReq or e2.NeedsRequesting;
  until (i = 0) or (e <> nil);

  assert(e <> nil, 'SetNodeState did not find a node (no matching entry)');
  assert(e.NodeType in [idnIfdef, idnElseIf], 'SetNodeState did not find a node (e.NodeType <> idnIfdef)');
  if (e = nil) or not(e.NodeType in [idnIfdef, idnElseIf]) then
    exit;

  e.NodeState := AState;

  dec(i); // Assume the node, just set does not need requesting
  while (i >= 0) and (not LineNeedReq) do begin
    e2 := Node.Entry[i];
    LineNeedReq := LineNeedReq or e2.NeedsRequesting;
    dec(i);
  end;

  if not LineNeedReq then
    Exclude(Node.Node.FLineFlags, idlHasUnknownNodes);
end;

procedure TSynMarkupHighIfDefLinesTree.DebugPrint(Flat: Boolean);
  function PeerLine(AEntry: TSynMarkupHighIfDefEntry): string;
  begin
    if AEntry = nil then exit('-                 ');
    Result := Format('%2d/%2d (%10s)', [AEntry.FLine.GetPosition, AEntry.StartColumn, dbgs(PtrUInt(AEntry))]);
  end;

  function PeerLines(AEntry: TSynMarkupHighIfDefEntry): string;
  begin
    Result := '?????';
    case AEntry.NodeType of
      idnIfdef: begin
          Result := '>>Else:  ' + PeerLine(AEntry.ElsePeer) +
                 '   >>EndIf: ' + PeerLine(AEntry.EndIfPeer);
        end;
      idnElse: begin
          Result := '<<If:    ' + PeerLine(AEntry.IfDefPeer) +
                 '   >>EndIf: ' + PeerLine(AEntry.EndIfPeer);
        end;
      idnElseIf: begin
          if AEntry.ElsePeer <> nil then
            Result := '<<If:    ' + PeerLine(AEntry.IfDefPeer) +
                   '   >>EndIf: ' + PeerLine(AEntry.EndIfPeer)
          else
            Result := '<<If:    ' + PeerLine(AEntry.IfDefPeer) +
                   '   >>Else:  ' + PeerLine(AEntry.ElsePeer);
        end;
      idnEndIf: begin
          Result := '<<Else:  ' + PeerLine(AEntry.ElsePeer) +
                 '   <<If:    ' + PeerLine(AEntry.IfDefPeer);
        end;
    end;
  end;

  procedure DebugPrintNode(ANode: TSynMarkupHighIfDefLinesNode; PreFix, PreFixOne: String);
    function DbgsLine(ANode: TSynMarkupHighIfDefLinesNode): String;
    begin
      Result := 'nil';
      if ANode <> nil then Result := IntToStr(ANode.GetPosition);
    end;
  var
    i: Integer;
  begin
    DebugLn([PreFixOne, 'Line=', ANode.GetPosition, ' ScannedTo=', ANode.ScanEndOffs,
      '  Cnt=', ANode.EntryCount,
      ' EndLine=', ANode.LastEntryEndLineOffs,
      ' Flags=', dbgs(ANode.LineFlags),
      ' D-Open=', ANode.DisabledEntryOpenCount,
      ' D-Close=', ANode.DisabledEntryCloseCount
       ]);
    for i := 0 to ANode.EntryCount - 1 do
      DebugLn(Format('%s%s%s  x1-x2=%2d - %2d   %6s  %8s  flg=%12s %s',
                [PreFix, '       # ', dbgs(PtrUInt(ANode.Entry[i])),
                 ANode.Entry[i].StartColumn, ANode.Entry[i].EndColumn,
                 dbgs(ANode.Entry[i].NodeType),
                 dbgs(ANode.Entry[i].NodeState),
                dbgs(ANode.Entry[i].NodeFlags),
                PeerLines(ANode.Entry[i])
                //'  p1=', PeerLine(ANode.Entry[i].FPeer1),
                //'  p2=', PeerLine(ANode.Entry[i].FPeer2)
      ]));
    if Flat then
      exit;
    if ANode.FLeft <> nil then
      DebugPrintNode(TSynMarkupHighIfDefLinesNode(ANode.FLeft), PreFix+'   ', PreFix + 'L: ');
    if ANode.FRight <> nil then
      DebugPrintNode(TSynMarkupHighIfDefLinesNode(ANode.FRight), PreFix+'   ', PreFix + 'R: ');
  end;
var
  i: Integer;
  n: TSynMarkupHighIfDefLinesNode;
begin
  if Flat then begin
    i := 1;
    n := TSynMarkupHighIfDefLinesNode(First);
    while n <> nil do begin
      DebugPrintNode(n, '    ', format('%3d ', [i]));
      n := TSynMarkupHighIfDefLinesNode(n.Successor);
      inc(i);
    end;
  end
  else
    DebugPrintNode(TSynMarkupHighIfDefLinesNode(FRoot), '', '');
end;

procedure TSynMarkupHighIfDefLinesTree.Clear;
var
  n: TSynSizedDifferentialAVLNode;
begin
  FClearing := True;
  inherited Clear;
  while FDisposedNodes <> nil do begin
    n := FDisposedNodes;
    FDisposedNodes := TSynMarkupHighIfDefLinesNode(n).NextDispose;
    n.Free;
  end;
  FClearing := False;
end;

function TSynMarkupHighIfDefLinesTree.FindNodeAtPosition(ALine: Integer;
  AMode: TSynSizedDiffAVLFindMode): TSynMarkupHighIfDefLinesNodeInfo;
begin
  Result.ClearInfo;
  Result.FTree := Self;
  Result.FNode :=
    TSynMarkupHighIfDefLinesNode(FindNodeAtPosition(ALine, AMode,
      Result.FStartLine, Result.Index));
  if Result.FNode = nil then begin
    Result.FAtBOL := AMode = afmPrev;
    Result.FAtEOL := AMode = afmNext;
  end;
end;

{ TSynEditMarkupIfDef }

procedure TSynEditMarkupIfDef.SetFoldView(AValue: TSynEditFoldedView);
begin
  if FFoldView = AValue then Exit;
  FFoldView := AValue;
end;

procedure TSynEditMarkupIfDef.SetHighlighter(AValue: TSynPasSyn);
begin
  if FHighlighter = AValue then Exit;
  FHighlighter := AValue;
  FIfDefTree.Highlighter := AValue;
end;

procedure TSynEditMarkupIfDef.ValidateMatches;
var
  LastMatchIdx: Integer;
  LastLine: Integer;

  function EntryToPointAtBegin(Entry: TSynMarkupHighIfDefEntry; Line: Integer): TPoint;
  begin
    Result.y := Line;
    Result.x := Entry.StartColumn;
  end;

  function EntryToPointAtEnd(Entry: TSynMarkupHighIfDefEntry; Line: Integer): TPoint;
  begin
    Result.y := Line;
    if idnMultiLineTag in Entry.NodeFlags then
      Result.y := Line + Entry.Line.LastEntryEndLineOffs;
    Result.x := Entry.EndColumn;
  end;

  procedure AddMatch(Entry1: TSynMarkupHighIfDefEntry; Line1: Integer;
    Entry2: TSynMarkupHighIfDefEntry; Line2: Integer);
  var
    Match, OldMatch: TSynMarkupHighAllMatch;
  begin
    if Entry1 <> nil then
      Match.StartPoint := EntryToPointAtEnd(Entry1, Line1)
    else
      Match.StartPoint := point(1, TopLine);
    if Entry2 <> nil then
      Match.EndPoint := EntryToPointAtBegin(Entry2, Line2)
    else
      Match.EndPoint := point(1, LastLine+1);

    inc(LastMatchIdx);
debugln(['MATCH AT ', dbgs(Match.StartPoint), ' ', dbgs(Match.EndPoint)]);

    if LastMatchIdx >= Matches.Count then begin
      Matches.Match[LastMatchIdx] := Match;
      DebugLn(['!!!!!!! Invalidate  ', Match.StartPoint.y, ' - ', Match.EndPoint.y]);
      InvalidateSynLines(Match.StartPoint.y, Match.EndPoint.y);
      exit;
    end;

    OldMatch := Matches.Match[LastMatchIdx];
    if ( (ComparePoints(OldMatch.StartPoint, Match.StartPoint) = 0) or
         (Entry1 = nil) and (ComparePoints(OldMatch.StartPoint, Match.StartPoint) <= 0)
       ) and
       ( (ComparePoints(OldMatch.EndPoint, Match.EndPoint) = 0) or
         (Entry2 = nil) and (ComparePoints(OldMatch.EndPoint, Match.EndPoint) >= 0)
       )
    then
      exit; // existing match found

    if ComparePoints(OldMatch.StartPoint, Match.EndPoint) >= 0 then
      Matches.Insert(LastMatchIdx, 1)
    else
begin
      InvalidateSynLines(OldMatch.StartPoint.y, OldMatch.EndPoint.y);;
      DebugLn(['!!!!!!! Invalidate  ', Match.StartPoint.y, ' - ', Match.EndPoint.y]);
end;

    Matches.Match[LastMatchIdx] := Match;
    DebugLn(['!!!!!!! Invalidate  ', Match.StartPoint.y, ' - ', Match.EndPoint.y]);
    InvalidateSynLines(Match.StartPoint.y, Match.EndPoint.y);
  end;

var
  NestLvl, NestLvlLow, FoundLvl, CurLine, EndLvl, FirstEntryIdx: Integer;
  j, d: Integer;
  NodeInfo: TSynMarkupHighIfDefLinesNodeInfo;
  Node: TSynMarkupHighIfDefLinesNode;
  Entry, EntryFound, Peer: TSynMarkupHighIfDefEntry;
  m: TSynMarkupHighAllMatch;
begin
  if (FPaintLock > 0) or (not SynEdit.IsVisible) then begin
    FNeedValidate := True;
    exit;
  end;
  FNeedValidate := False;

  if Highlighter = nil then begin
    FIfDefTree.Clear;
    exit;
  end;

  LastLine := ScreenRowToRow(LinesInWindow+1);
  FIfDefTree.ValidateRange(TopLine, LastLine, FOuterLines);

  LastMatchIdx := -1;
  EntryFound := nil;

  // *** Check outerlines, for node that goes into visible area
  NestLvl := -1;
  while NestLvl < FOuterLines.Count - 1 do begin
    inc(NestLvl);

    CurLine := ToPos(FOuterLines.NodeLine[NestLvl]);
    NestLvlLow := NestLvl;
    while (NestLvl < FOuterLines.Count - 1) and (ToPos(FOuterLines.NodeLine[NestLvl + 1]) = CurLine) do
      inc(NestLvl);

    NodeInfo := FIfDefTree.FindNodeAtPosition(CurLine, afmNil);
    Node := NodeInfo.Node;
    assert(NodeInfo.HasNode, 'ValidateMatches: No node for outerline');

    if NodeInfo.Node.DisabledEntryOpenCount <= NodeInfo.Node.DisabledEntryCloseCount then
      continue;

    EndLvl := NodeInfo.NestDepthAtNodeEnd;
    //d := NestLvl - NestLvlLow + 1;
    EntryFound := nil;
    FoundLvl := EndLvl + 1;

    j := Node.EntryCount;
    while (j > 0) {and (d > 0)} do begin
      dec(j);
      Entry := Node.Entry[j];
      case Entry.NodeType of
        idnIfdef: dec(EndLvl);
        idnEndIf: inc(EndLvl);
      end;

      if EndLvl > FoundLvl - 1 then
        continue;

      dec(FoundLvl);
      if Entry.IsDisabledOpening then
        EntryFound := Entry;

      if FoundLvl = NestLvlLow then
        break;
    end;

    if EntryFound = nil then
      Continue;

    Peer := EntryFound.ClosingPeer;
    If Peer = nil then
      break;      // Disabled to end of display or beyond (end of validated)
    d := Peer.Line.GetPosition;
    if (d >= TopLine)  //or ( (idnMultiLineTag in Peer.NodeFlags) and (d + Peer.Line.LastEntryEndLineOffs) )
    then
      break;
  end;
  // *** END Check outerlines, for node that goes into visible area
  // *** if found, then it is in EntryFound and Peer

  if EntryFound <> nil then begin
    AddMatch(EntryFound, CurLine, Peer, d);
    NodeInfo.InitForNode(Peer.Line, d);
    Node := NodeInfo.Node;
    FirstEntryIdx := Node.IndexOf(Peer) + 1;
  end
  else begin
//    Peer := nil;
    NodeInfo := FIfDefTree.FindNodeAtPosition(TopLine, afmNext);
    Node := NodeInfo.Node;
    FirstEntryIdx := 0;
  end;
  CurLine := NodeInfo.StartLine;

  while (Node <> nil) and (CurLine <= LastLine) do begin
    EntryFound := nil;
    while FirstEntryIdx < Node.EntryCount do begin
      Entry := Node.Entry[FirstEntryIdx];
      if Entry.IsDisabledOpening then begin
        EntryFound := Entry;
        break;
      end;
      inc(FirstEntryIdx);
    end;

    if EntryFound <> nil then begin
      Peer := EntryFound.ClosingPeer;
      If Peer = nil then begin   // Disabled to end of display or beyond (end of validated)
        AddMatch(EntryFound, CurLine, Peer, 0);
        NodeInfo.ClearInfo;
        break;
      end;
      if Peer.Line = Node then begin
        AddMatch(EntryFound, CurLine, Peer, CurLine);
        FirstEntryIdx := Node.IndexOf(Peer) + 1;
        continue;
      end;
      d := Peer.Line.GetPosition;
      assert(d > CurLine, 'Node goes backward');
      AddMatch(EntryFound, CurLine, Peer, d);
      NodeInfo.InitForNode(Peer.Line, d);
      Node := NodeInfo.Node;
      FirstEntryIdx := Node.IndexOf(Peer) + 1;
      CurLine := NodeInfo.StartLine;
      continue;
    end;

    NodeInfo := NodeInfo.Successor;
    if not NodeInfo.HasNode then
      break;
    CurLine := NodeInfo.StartLine;
    Node := NodeInfo.Node;
    FirstEntryIdx := 0;
  end;

  // delete remaining matchdata
  while Matches.Count - 1 > LastMatchIdx do begin
    m := Matches.Match[Matches.Count - 1];
    DebugLn(['!!!!!!! Invalidate  ', m.StartPoint.y, ' - ', m.EndPoint.y]);
    if (m.EndPoint.y >= TopLine) and (m.StartPoint.y <= LastLine) then
      InvalidateSynLines(m.StartPoint.y, m.EndPoint.y);
    Matches.Delete(Matches.Count - 1);
  end;

end;

procedure TSynEditMarkupIfDef.DoFoldChanged(aLine: Integer);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoTopLineChanged(OldTopLine: Integer);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoLinesInWindoChanged(OldLinesInWindow: Integer);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoMarkupChanged(AMarkup: TSynSelectedColor);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoTextChanged(StartLine, EndLine, ACountDiff: Integer);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoVisibleChanged(AVisible: Boolean);
begin
  ValidateMatches;
end;

procedure TSynEditMarkupIfDef.DoBufferChanged(Sender: TObject);
//var
//  m: TSynEditMarkup;
begin
//TODO: get ifdeftree from other.
  //// The owning SynEdit is not yet in the list of edits
  //if TSynEditStringList(Sender).AttachedSynEditCount = 0 then begin
  //  // Recreate Tree
  //end
  //else begin
  //  m :=  TCustomSynEdit(TSynEditStringList(Sender).AttachedSynEdits[0]).MarkupByClass[TSynEditMarkupIfDef];
  //end;

  //FIfDefTree.Lines  pointing to view => so still valid
  FIfDefTree.Clear;
  ValidateMatches;
end;

function TSynEditMarkupIfDef.DoNodeStateRequest(Sender: TObject; LinePos,
  XStartPos: Integer): TSynMarkupIfdefNodeState;
begin
  Result := idnEnabled;
  if pos('y', copy(SynEdit.Lines[LinePos-1], XStartPos, 100)) > 1 then
    Result := idnDisabled;
  DebugLn(['STATE REQUEST ', LinePos, ' ', XStartPos, ' : ', dbgs(Result)]);
end;

procedure TSynEditMarkupIfDef.SetLines(const AValue: TSynEditStrings);
begin
  if Lines <> nil then begin
    Lines.RemoveGenericHandler(senrTextBufferChanged, TMethod(@DoBufferChanged));
    //FLines.RemoveEditHandler(@DoLinesEdited);
//    FLines.RemoveChangeHandler(senrHighlightChanged, @DoHighlightChanged);
  end;

  inherited SetLines(AValue);
  FIfDefTree.Lines := AValue;

  if Lines <> nil then begin
    Lines.AddGenericHandler(senrTextBufferChanged, TMethod(@DoBufferChanged));
    //FLines.AddChangeHandler(senrHighlightChanged, @DoHighlightChanged);
//    FLines.AddEditHandler(@DoLinesEdited);
  end;
end;

constructor TSynEditMarkupIfDef.Create(ASynEdit: TSynEditBase);
begin
  inherited Create(ASynEdit);
  FIfDefTree := TSynMarkupHighIfDefLinesTree.Create;
  FIfDefTree.OnNodeStateRequest := @DoNodeStateRequest;
  FOuterLines := FIfDefTree.CreateOpeningList;

  MarkupInfo.Clear;
  MarkupInfo.Background := clLtGray;
end;

destructor TSynEditMarkupIfDef.Destroy;
begin
  inherited Destroy;
  FIfDefTree.DiscardOpeningList(FOuterLines);
  FreeAndNil(FIfDefTree);
end;

procedure TSynEditMarkupIfDef.IncPaintLock;
begin
  if FPaintLock = 0 then begin
    FNeedValidate := False;
  end;
  inherited IncPaintLock;
end;

procedure TSynEditMarkupIfDef.DecPaintLock;
begin
  inherited DecPaintLock;
  if (FPaintLock = 0) and FNeedValidate then
    ValidateMatches;
end;


var OldAssert: TAssertErrorProc = @SysAssert;
Procedure MyAssert(const Msg,FName:ShortString;LineNo:Longint;ErrorAddr:Pointer);
var
  t: TSynMarkupHighIfDefLinesTree;
begin
debugln('################# '+Msg);
if XXXCurTree <> nil then begin
  t := XXXCurTree;
  XXXCurTree:= nil;
  t.DebugPrint(true);
end;
  if OldAssert <> nil
  then OldAssert(Msg, FName, LineNo, ErrorAddr)
  else halt(0);
end;

initialization
  OldAssert := AssertErrorProc;
  AssertErrorProc := @MyAssert;

end.

