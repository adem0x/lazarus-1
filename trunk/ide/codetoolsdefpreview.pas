unit CodeToolsDefPreview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  LCLProc, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, ComCtrls, ExtCtrls, FileUtil, AVGLvlTree,
  SynEdit, DefineTemplates, ExprEval,
  LazarusIDEStrConsts, InputHistory, IDEWindowIntf, CodeToolsOptions;

type
  TCodeToolsDefinesNodeValues = class
  public
    Node: TDefineTemplate;
    ValueParsed: boolean;
    ParsedValue: string;
    ExpressionCalculated: boolean;
    ExpressionResult: string;
    Execute: boolean;
  end;

  { TCodeToolsDefinesDialog }

  TCodeToolsDefinesDialog = class(TForm)
    CloseButton: TButton;
    DirectoryBrowseButton: TButton;
    DirectoryCombobox: TComboBox;
    DirectoryGroupbox: TGroupBox;
    TemplatesMemo: TMemo;
    TemplatesSplitter: TSplitter;
    TemplatesGroupBox: TGroupBox;
    MainSplitter: TSplitter;
    ParsedTemplatesTreeView: TTreeView;
    ValueSynedit: TSynEdit;
    ValueGroupbox: TGroupBox;
    ValuesListview: TListView;
    procedure CodeToolsDefinesDialogCLOSE(Sender: TObject;
      var CloseAction: TCloseAction);
    procedure CodeToolsDefinesDialogCREATE(Sender: TObject);
    procedure DirectoryBrowseButtonCLICK(Sender: TObject);
    procedure DirectoryComboboxCHANGE(Sender: TObject);
    procedure DirectoryGroupboxRESIZE(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ParsedTemplatesTreeViewSelectionChanged(Sender: TObject);
    procedure ValuesListviewSELECTITEM(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    FDefineTree: TDefineTree;
    FNodeValues: TAvgLvlTree;
    procedure SetDefineTree(const AValue: TDefineTree);
    procedure UpdateValues;
    procedure UpdateValue;
    procedure UpdateTemplateValues;
    procedure ClearValues;
    procedure FillTemplateTree;
    procedure SetComboBox(AComboBox: TComboBox; const NewText: string);
    procedure DefineTreeCalculate(Tree: TDefineTree; Node: TDefineTemplate;
                  ValueParsed: boolean; const ParsedValue: string;
                  ExpressionCalculated: boolean; const ExpressionResult: string;
                  Execute: boolean);
  public
    property DefineTree: TDefineTree read FDefineTree write SetDefineTree;
  end;


function ShowCodeToolsDefinesValuesDialog(ADefineTree: TDefineTree;
  const InitialDirectory: string): TModalresult;
  
procedure RebuildDefineTreeView(ATreeView: TTreeView;
  RootTemplate: TDefineTemplate);
procedure AddDefineNodes(ATreeView: TTreeView; ANode: TDefineTemplate;
  AParent: TTreeNode; WithChilds,WithNextSiblings: boolean);
procedure SetNodeImages(ANode: TTreeNode; WithSubNodes: boolean);

function CompareNodeValues(Data1, Data2: Pointer): Integer;
function CompareNodeAndNodeValues(Node, NodeValues: Pointer): Integer;

implementation

function ShowCodeToolsDefinesValuesDialog(ADefineTree: TDefineTree;
  const InitialDirectory: string): TModalresult;
var
  CodeToolsDefinesDialog: TCodeToolsDefinesDialog;
begin
  CodeToolsDefinesDialog:=TCodeToolsDefinesDialog.Create(nil);
  if InitialDirectory<>'' then
    CodeToolsDefinesDialog.SetComboBox(CodeToolsDefinesDialog.DirectoryCombobox,
      InitialDirectory);
  CodeToolsDefinesDialog.DefineTree:=ADefineTree;
  Result:=CodeToolsDefinesDialog.ShowModal;
  CodeToolsDefinesDialog.Free;
end;

procedure RebuildDefineTreeView(ATreeView: TTreeView;
  RootTemplate: TDefineTemplate);
begin
  ATreeView.Items.BeginUpdate;
  ATreeView.Items.Clear;
  AddDefineNodes(ATreeView,RootTemplate,nil,true,true);
  ATreeView.Items.EndUpdate;
end;

procedure AddDefineNodes(
  ATreeView: TTreeView; ANode: TDefineTemplate; AParent: TTreeNode;
  WithChilds, WithNextSiblings: boolean);
var NewTreeNode: TTreeNode;
begin
  if ANode=nil then exit;
  ATreeView.Items.BeginUpdate;
  NewTreeNode:=ATreeView.Items.AddChildObject(AParent,ANode.Name,ANode);
  SetNodeImages(NewTreeNode,false);
  if WithChilds and (ANode.FirstChild<>nil) then begin
    AddDefineNodes(ATreeView,ANode.FirstChild,NewTreeNode,true,true);
  end;
  if WithNextSiblings and (ANode.Next<>nil) then begin
    AddDefineNodes(ATreeView,ANode.Next,AParent,WithChilds,true);
  end;
  ATreeView.Items.EndUpdate;
end;

procedure SetNodeImages(ANode: TTreeNode;
  WithSubNodes: boolean);
var ADefineTemplate: TDefineTemplate;
begin
  ADefineTemplate:=TDefineTemplate(ANode.Data);
  case ADefineTemplate.Action of
    da_Define:          ANode.ImageIndex:=0;
    da_DefineRecurse:   ANode.ImageIndex:=1;
    da_Undefine:        ANode.ImageIndex:=2;
    da_UndefineRecurse: ANode.ImageIndex:=3;
    da_UndefineAll:     ANode.ImageIndex:=4;
    da_Block:           ANode.ImageIndex:=5;
    da_Directory:       ANode.ImageIndex:=6;
    da_If:              ANode.ImageIndex:=7;
    da_IfDef:           ANode.ImageIndex:=8;
    da_IfNDef:          ANode.ImageIndex:=9;
    da_ElseIf:          ANode.ImageIndex:=10;
    da_Else:            ANode.ImageIndex:=11;
  else
    ANode.ImageIndex:=-1;
  end;
  ANode.SelectedIndex:=ANode.ImageIndex;
  if ADefineTemplate.IsAutoGenerated then begin
    ANode.StateIndex:=13;
  end else begin
    ANode.StateIndex:=12;
  end;
  if WithSubNodes then begin
    ANode:=ANode.GetFirstChild;
    while ANode<>nil do begin
      SetNodeImages(ANode,true);
      ANode:=ANode.GetNextSibling;
    end;
  end;
end;

function CompareNodeValues(Data1, Data2: Pointer): Integer;
begin
  Result:=ComparePointers(TCodeToolsDefinesNodeValues(Data1).Node,
                          TCodeToolsDefinesNodeValues(Data2).Node);
end;

function CompareNodeAndNodeValues(Node, NodeValues: Pointer): Integer;
begin
  Result:=ComparePointers(TCodeToolsDefinesNodeValues(Node),
                          TCodeToolsDefinesNodeValues(NodeValues).Node);
end;

{ TCodeToolsDefinesDialog }

procedure TCodeToolsDefinesDialog.DirectoryGroupboxRESIZE(Sender: TObject);
var
  x: Integer;
begin
  with DirectoryCombobox do
    SetBounds(0,0,Parent.ClientWidth-30,Height);
  x:=DirectoryCombobox.Width;
  with DirectoryBrowseButton do
    SetBounds(x,0,Parent.ClientWidth-x,DirectoryCombobox.Height);
end;

procedure TCodeToolsDefinesDialog.FormDestroy(Sender: TObject);
begin
  if FNodeValues<>nil then begin
    FNodeValues.FreeAndClear;
    FreeAndNil(FNodeValues);
  end;
end;

procedure TCodeToolsDefinesDialog.ParsedTemplatesTreeViewSelectionChanged(
  Sender: TObject);
begin
  UpdateTemplateValues;
end;

procedure TCodeToolsDefinesDialog.ValuesListviewSELECTITEM(Sender: TObject;
  Item: TListItem; Selected: Boolean);
begin
  UpdateValue;
end;

procedure TCodeToolsDefinesDialog.SetDefineTree(const AValue: TDefineTree);
begin
  if FDefineTree=AValue then exit;
  FDefineTree:=AValue;
  UpdateValues;
  FillTemplateTree;
end;

procedure TCodeToolsDefinesDialog.UpdateValues;
// let the codetools calculate the defines for the directory
var
  Dir: String;
  Defines: TExpressionEvaluator;
  i: Integer;
  ListItem: TListItem;
  Value: String;
  OldOnCalculate: TDefTreeCalculate;
begin
  Dir:=TrimFilename(DirectoryCombobox.Text);
  if (DefineTree=nil) or (not FilenameIsAbsolute(Dir))
  or (not DirPathExists(Dir)) then begin
    ClearValues;
    exit;
  end;

  // set our debug function, clear codetools cache and calculate the values
  if FNodeValues<>nil then
    FNodeValues.FreeAndClear;
  DefineTree.ClearCache;// make sure the defines are reparsed
  OldOnCalculate:=DefineTree.OnCalculate;
  DefineTree.OnCalculate:=@DefineTreeCalculate;
  try
    Defines:=DefineTree.GetDefinesForDirectory(Dir,false);
  finally
    DefineTree.OnCalculate:=OldOnCalculate;
  end;

  // fill the ValuesListview
  ValuesListview.BeginUpdate;
  for i:=0 to Defines.Count-1 do begin
    if ValuesListview.Items.Count<=i then
      ListItem:=ValuesListview.Items.Add
    else
      ListItem:=ValuesListview.Items[i];
    ListItem.Caption:=Defines.Names(i);
    Value:=Defines.Values(i);
    if length(Value)>100 then
      Value:=copy(Value,1,100)+' ...';
    if ListItem.SubItems.Count<1 then
      ListItem.SubItems.Add(Value)
    else
      ListItem.SubItems[0]:=Value;
  end;
  while ValuesListview.Items.Count>Defines.Count do
    ValuesListview.Items.Delete(ValuesListview.Items.Count-1);
  ValuesListview.EndUpdate;
  UpdateValue;
end;

procedure TCodeToolsDefinesDialog.UpdateValue;
var
  VariableName: String;
  Dir: String;
  Defines: TExpressionEvaluator;
  Value: string;
begin
  Dir:=TrimFilename(DirectoryCombobox.Text);
  if (ValuesListview.Selected=nil) or (DefineTree=nil)
  or (not FilenameIsAbsolute(Dir)) then begin
    ValueGroupbox.Caption:=lisCTDefnoVariableSelected;
    ValueSynedit.Lines.Text:='';
  end else begin
    VariableName:=ValuesListview.Selected.Caption;
    ValueGroupbox.Caption:=Format(lisCTDefVariable, [VariableName]);
    Defines:=DefineTree.GetDefinesForDirectory(Dir,false);
    Value:=Defines.Variables[VariableName];
    ValueSynedit.Lines.Text:=Value;
  end;
end;

procedure TCodeToolsDefinesDialog.UpdateTemplateValues;
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
  s: string;
  AVLNode: TAvgLvlTreeNode;
  NodeValues: TCodeToolsDefinesNodeValues;
begin
  SelTreeNode:=ParsedTemplatesTreeView.Selected;
  if SelTreeNode=nil then begin
    TemplatesMemo.Text:='No node selected';
  end else begin
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    s:='Name="'+SelDefNode.Name+'"'+LineEnding;
    s:=s+'Description="'+SelDefNode.Description+'"'+LineEnding;
    s:=s+'Action="'+DefineActionNames[SelDefNode.Action]+'"'+LineEnding;
    s:=s+'Variable="'+SelDefNode.Variable+'"'+LineEnding;
    s:=s+'Value="'+SelDefNode.Value+'"'+LineEnding;

    if FNodeValues<>nil then begin
      AVLNode:=FNodeValues.FindKey(SelDefNode,@CompareNodeAndNodeValues);
      if AVLNode<>nil then begin
        NodeValues:=TCodeToolsDefinesNodeValues(AVLNode.Data);
        if NodeValues.ValueParsed then
          s:=s+'Parsed Value="'+NodeValues.ParsedValue+'"'+LineEnding;
        if NodeValues.ExpressionCalculated then
          s:=s+'Expression Result="'+NodeValues.ExpressionResult+'"'+LineEnding;
        s:=s+'Executed="'+dbgs(NodeValues.Execute)+'"'+LineEnding;
      end;
    end;
    TemplatesMemo.Text:=s;
  end;
end;

procedure TCodeToolsDefinesDialog.ClearValues;
begin
  ValuesListview.Items.Clear;
  if FNodeValues<>nil then
    FNodeValues.FreeAndClear;
end;

procedure TCodeToolsDefinesDialog.FillTemplateTree;
begin
  RebuildDefineTreeView(ParsedTemplatesTreeView,DefineTree.RootTemplate);
  UpdateTemplateValues;
end;

procedure TCodeToolsDefinesDialog.SetComboBox(AComboBox: TComboBox;
  const NewText: string);
var
  i: Integer;
begin
  i:=AComboBox.Items.IndexOf(NewText);
  if i<0 then
    AComboBox.Items.Add(NewText)
  else
    AComboBox.ItemIndex:=i;
  AComboBox.Text:=NewText;
  //writeln('TCodeToolsDefinesDialog.SetComboBox Text=',AComboBox.Text,' NewText=',NewText);
end;

procedure TCodeToolsDefinesDialog.DefineTreeCalculate(Tree: TDefineTree;
  Node: TDefineTemplate; ValueParsed: boolean; const ParsedValue: string;
  ExpressionCalculated: boolean; const ExpressionResult: string;
  Execute: boolean);
var
  NewNodeValues: TCodeToolsDefinesNodeValues;
begin
  NewNodeValues:=TCodeToolsDefinesNodeValues.Create;
  NewNodeValues.Node:=Node;
  NewNodeValues.ValueParsed:=ValueParsed;
  NewNodeValues.ParsedValue:=ParsedValue;
  NewNodeValues.ExpressionCalculated:=ExpressionCalculated;
  NewNodeValues.ExpressionResult:=ExpressionResult;
  NewNodeValues.Execute:=Execute;
  if FNodeValues=nil then
    FNodeValues:=TAvgLvlTree.Create(@CompareNodeValues);
  FNodeValues.Add(NewNodeValues);
end;

procedure TCodeToolsDefinesDialog.CodeToolsDefinesDialogCREATE(Sender: TObject);
var
  ListColumn: TListColumn;
begin
  IDEDialogLayoutList.ApplyLayout(Self,485,450);

  Caption:=lisCTDefCodeToolsDirectoryValues;
  
  ListColumn:=ValuesListview.Columns.Add;
  ListColumn.Caption:=lisCTDefVariableName;
  ListColumn.Width:=150;
  ListColumn:=ValuesListview.Columns.Add;
  ListColumn.Caption:=dlgRunOValue;
  
  DirectoryGroupbox.Caption:=lisCodeToolsDefsInsertBehindDirectory;
  CloseButton.Caption:=lisMenuClose;
  
  DirectoryCombobox.Items.Assign(
    InputHistories.HistoryLists.GetList(hlCodeToolsDirectories,true));
  if DirectoryCombobox.Items.Count>0 then
    DirectoryCombobox.ItemIndex:=0
  else
    DirectoryCombobox.Text:='';
    
  TemplatesGroupBox.Caption:=lisCTDefDefineTemplates;
    
  MainSplitter.SetSplitterPosition(
         Max(20,Min(ClientWidth-100,CodeToolsOpts.DefinesPreviewMainSplitterPos)));
  TemplatesSplitter.SetSplitterPosition(
         Max(20,Min(TemplatesGroupBox.ClientHeight-50,
                    CodeToolsOpts.DefinesPreviewTemplSplitterPos)));
end;

procedure TCodeToolsDefinesDialog.CodeToolsDefinesDialogCLOSE(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  InputHistories.HistoryLists.GetList(hlCodeToolsDirectories,true).Assign(
    DirectoryCombobox.Items);
  CodeToolsOpts.DefinesPreviewMainSplitterPos:=MainSplitter.GetSplitterPosition;
  CodeToolsOpts.DefinesPreviewTemplSplitterPos:=TemplatesSplitter.GetSplitterPosition;
  CodeToolsOpts.Save;
end;

procedure TCodeToolsDefinesDialog.DirectoryBrowseButtonCLICK(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  Filename: string;
begin
  OpenDialog:=TSelectDirectoryDialog.Create(nil);
  try
    InputHistories.ApplyFileDialogSettings(OpenDialog);
    OpenDialog.Title:=lisCTDefChooseDirectory;
    OpenDialog.Options:=OpenDialog.Options+[ofPathMustExist];
    if OpenDialog.Execute then begin
      Filename:=CleanAndExpandFilename(OpenDialog.Filename);
      SetComboBox(DirectoryCombobox,Filename);
      UpdateValues;
    end;
    InputHistories.StoreFileDialogSettings(OpenDialog);
  finally
    OpenDialog.Free;
  end;
end;

procedure TCodeToolsDefinesDialog.DirectoryComboboxCHANGE(Sender: TObject);
begin
  UpdateValues;
end;

initialization
  {$I codetoolsdefpreview.lrs}

end.

