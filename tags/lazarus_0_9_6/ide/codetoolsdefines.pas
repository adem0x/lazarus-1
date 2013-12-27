{ /***************************************************************************
                 codetoolsdefines.pas  -  Lazarus IDE unit
                 -----------------------------------------

 ***************************************************************************/

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
    - TCodeToolsDefinesEditor is an editor for the CodeTools DefineTree used by
      the IDE. The DefineTree defines all values, that are not in the sources,
      but are provided by for example Makefiles, compiler command lines and
      compiler config files.
      
    There are three types of nodes:
      - auto generated: These are created by the IDE.
      - project specific: These nodes are saved in the project info file (.lpi)
      - the rest are global nodes, saved in the codetoolsoptions.xml file.

}
unit CodeToolsDefines;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLIntf, Forms, Controls, Buttons, StdCtrls, ComCtrls,
  LCLType, ExtCtrls, Menus, LResources, LCLProc, Graphics, Dialogs, SynEdit,
  LazarusIDEStrConsts, DefineTemplates, CodeToolManager,
  CodeToolsOptions, CodeToolsDefPreview, TransferMacros, InputFileDialog,
  IDEOptionDefs, LazConf, IDEProcs;

type

  { TCodeToolsDefinesEditor }

  TCodeToolsDefinesEditor = class(TForm)
    TheImageList: TImageList;
    MainMenu: TMainMenu;
    
    // exit menu
    ExitMenuItem: TMenuItem;
    SaveAndExitMenuItem: TMenuItem;
    DontSaveAndExitMenuItem: TMenuItem;

    // edit nodes
    EditMenuItem: TMenuItem;
    MoveNodeUpMenuItem: TMenuItem;
    MoveNodeDownMenuItem: TMenuItem;
    MoveNodeLvlUpMenuItem: TMenuItem;
    MoveNodeLvlDownMenuItem: TMenuItem;
    InsertBehindMenuItem: TMenuItem;
    InsertBehindDefineMenuItem: TMenuItem;
    InsertBehindDefineRecurseMenuItem: TMenuItem;
    InsertBehindUndefineMenuItem: TMenuItem;
    InsertBehindUndefineRecurseMenuItem: TMenuItem;
    InsertBehindUndefineAllMenuItem: TMenuItem;
    InsertBehindBlockMenuItem: TMenuItem;
    InsertBehindDirectoryMenuItem: TMenuItem;
    InsertBehindIfMenuItem: TMenuItem;
    InsertBehindIfDefMenuItem: TMenuItem;
    InsertBehindIfNotDefMenuItem: TMenuItem;
    InsertBehindElseIfMenuItem: TMenuItem;
    InsertBehindElseMenuItem: TMenuItem;
    InsertAsChildMenuItem: TMenuItem;
    InsertAsChildDefineMenuItem: TMenuItem;
    InsertAsChildDefineRecurseMenuItem: TMenuItem;
    InsertAsChildUndefineMenuItem: TMenuItem;
    InsertAsChildUndefineRecurseMenuItem: TMenuItem;
    InsertAsChildUndefineAllMenuItem: TMenuItem;
    InsertAsChildBlockMenuItem: TMenuItem;
    InsertAsChildDirectoryMenuItem: TMenuItem;
    InsertAsChildIfMenuItem: TMenuItem;
    InsertAsChildIfDefMenuItem: TMenuItem;
    InsertAsChildIfNotDefMenuItem: TMenuItem;
    InsertAsChildElseIfMenuItem: TMenuItem;
    InsertAsChildElseMenuItem: TMenuItem;
    DeleteNodeMenuItem: TMenuItem;
    ConvertActionMenuItem: TMenuItem;
    ConvertActionToDefineMenuItem: TMenuItem;
    ConvertActionToDefineRecurseMenuItem: TMenuItem;
    ConvertActionToUndefineMenuItem: TMenuItem;
    ConvertActionToUndefineRecurseMenuItem: TMenuItem;
    ConvertActionToUndefineAllMenuItem: TMenuItem;
    ConvertActionToBlockMenuItem: TMenuItem;
    ConvertActionToDirectoryMenuItem: TMenuItem;
    ConvertActionToIfMenuItem: TMenuItem;
    ConvertActionToIfDefMenuItem: TMenuItem;
    ConvertActionToIfNotDefMenuItem: TMenuItem;
    ConvertActionToElseIfMenuItem: TMenuItem;
    ConvertActionToElseMenuItem: TMenuItem;
    CopyToClipbrdMenuItem: TMenuItem;
    PasteFromClipbrdMenuItem: TMenuItem;

    // tools
    ToolsMenuItem: TMenuItem;
    OpenPreviewMenuItem: TMenuItem;
    ShowMacroListMenuItem: TMenuItem;

    // templates
    InsertTemplateMenuItem: TMenuItem;
    InsertFPCProjectDefinesTemplateMenuItem: TMenuItem;
    InsertFPCompilerDefinesTemplateMenuItem: TMenuItem;
    InsertFPCSourceDirTemplateMenuItem: TMenuItem;
    InsertLazarusSourceTemplateMenuItem: TMenuItem;
    InsertDelphi5CompilerDefinesTemplateMenuItem: TMenuItem;
    InsertDelphi5DirectoryTemplateMenuItem: TMenuItem;
    InsertDelphi5ProjectTemplateMenuItem: TMenuItem;
    InsertDelphi6CompilerDefinesTemplateMenuItem: TMenuItem;
    InsertDelphi6DirectoryTemplateMenuItem: TMenuItem;
    InsertDelphi6ProjectTemplateMenuItem: TMenuItem;
    InsertDelphi7CompilerDefinesTemplateMenuItem: TMenuItem;
    InsertDelphi7DirectoryTemplateMenuItem: TMenuItem;
    InsertDelphi7ProjectTemplateMenuItem: TMenuItem;
    InsertKylix3CompilerDefinesTemplateMenuItem: TMenuItem;
    InsertKylix3DirectoryTemplateMenuItem: TMenuItem;
    InsertKylix3ProjectTemplateMenuItem: TMenuItem;

    // define tree
    DefineTreeView: TTreeView;

    // selected item
    SelectedItemGroupBox: TGroupBox;
    TypeLabel: TLabel;
    NameLabel: TLabel;
    NameEdit: TEdit;
    DescriptionLabel: TLabel;
    DescriptionEdit: TEdit;
    VariableLabel: TLabel;
    VariableEdit: TEdit;
    ValueNoteBook: TNoteBook;
    ValueAsTextSynEdit: TSynEdit;
    ValueAsFilePathsSynEdit: TSynEdit;
    MoveFilePathUpBitBtn: TBitBtn;
    MoveFilePathDownBitBtn: TBitBtn;
    DeleteFilePathBitBtn: TBitBtn;
    InsertFilePathBitBtn: TBitBtn;
    
    // preview
    //DefinePreview: TCodeToolsDefinesPreview;

    // misc
    procedure CodeToolsDefinesEditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure SelectedItemGroupBoxResize(Sender: TObject);
    procedure ValueNoteBookResize(Sender: TObject);
    procedure DefineTreeViewMouseUp(Sender: TObject; Button: TMouseButton;
                                    Shift: TShiftState;  X,Y: integer);

    // exit menu
    procedure SaveAndExitMenuItemClick(Sender: TObject);
    procedure DontSaveAndExitMenuItemClick(Sender: TObject);

    // value notebook
    procedure ValueNoteBookPageChanged(Sender: TObject);
    procedure MoveFilePathUpBitBtnClick(Sender: TObject);
    procedure MoveFilePathDownBitBtnClick(Sender: TObject);
    procedure DeleteFilePathBitBtnClick(Sender: TObject);
    procedure InsertFilePathBitBtnClick(Sender: TObject);
    
    // edit menu
    procedure InsertNodeMenuItemClick(Sender: TObject);
    procedure MoveNodeUpMenuItemClick(Sender: TObject);
    procedure MoveNodeDownMenuItemClick(Sender: TObject);
    procedure MoveNodeLvlUpMenuItemClick(Sender: TObject);
    procedure MoveNodeLvlDownMenuItemClick(Sender: TObject);
    procedure DeleteNodeMenuItemClick(Sender: TObject);
    procedure ConvertActionMenuItemClick(Sender: TObject);
    
    // tools menu
    procedure OpenPreviewMenuItemClick(Sender: TObject);
    
    // template menu
    procedure InsertFPCProjectDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertFPCompilerDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertFPCSourceDirDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertLazarusSourceDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertDelphiCompilerDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertDelphiDirectoryTemplateMenuItemClick(Sender: TObject);
    procedure InsertDelphiProjectTemplateMenuItemClick(Sender: TObject);
    procedure InsertKylixCompilerDefinesTemplateMenuItemClick(Sender: TObject);
    procedure InsertKylixDirectoryTemplateMenuItemClick(Sender: TObject);
    procedure InsertKylixProjectTemplateMenuItemClick(Sender: TObject);
  private
    FDefineTree: TDefineTree;
    FLastSelectedNode: TTreeNode;
    FBoss: TCodeToolManager;
    FTransferMacros: TTransferMacroList;
    procedure CreateComponents;
    function CreateSeperator : TMenuItem;
    procedure RebuildDefineTreeView;
    procedure AddDefineNodes(ANode: TDefineTemplate; AParent: TTreeNode;
      WithChilds,WithNextSiblings: boolean);
    procedure SetNodeImages(ANode: TTreeNode; WithSubNodes: boolean);
    procedure SetTransferMacros(const AValue: TTransferMacroList);
    procedure ValueAsPathToValueAsText;
    procedure SaveSelectedValues;
    procedure ShowSelectedValues;
    procedure SetTypeLabel;
    function ValueToFilePathText(const AValue: string): string;
    procedure InsertNewNode(Behind: boolean; DefAction: TDefineAction);
    procedure InsertTemplate(NewTemplate: TDefineTemplate);
    function FindUniqueName: string;
    function ConsistencyCheck: integer;
    procedure SetValuesEditable(AValue: boolean);
  public
    procedure SetOptions(ACodeToolBoss: TCodeToolManager;
      Options: TCodeToolsOptions);
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property DefineTree: TDefineTree read FDefineTree;
    property Boss: TCodeToolManager read FBoss write FBoss;
    property Macros: TTransferMacroList
      read FTransferMacros write SetTransferMacros;
  end;

function ShowCodeToolsDefinesEditor(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions; Macros: TTransferMacroList): TModalResult;


implementation


type
  TWinControlClass = class of TWinControl;

function ShowCodeToolsDefinesEditor(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions; Macros: TTransferMacroList): TModalResult;
var CodeToolsDefinesEditor: TCodeToolsDefinesEditor;
begin
  CodeToolsDefinesEditor:=TCodeToolsDefinesEditor.Create(nil);
  CodeToolsDefinesEditor.SetOptions(ACodeToolBoss,Options);
  CodeToolsDefinesEditor.Macros:=Macros;
  Result:=CodeToolsDefinesEditor.ShowModal;
  if Result=mrOk then begin
    if not CodeToolsDefinesEditor.DefineTree.IsEqual(ACodeToolBoss.DefineTree)
    then begin
      ACodeToolBoss.DefineTree.AssignNonAutoCreated(
        CodeToolsDefinesEditor.DefineTree);
      Options.ReadGlobalDefinesTemplatesFromTree(ACodeToolBoss.DefineTree);
      Options.Save;
    end;
  end;
  CodeToolsDefinesEditor.Free;
end;

{ TCodeToolsDefinesEditor }

procedure TCodeToolsDefinesEditor.SaveAndExitMenuItemClick(Sender: TObject);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  SaveSelectedValues;
  FLastSelectedNode:=nil;
  ModalResult:=mrOk;
end;

procedure TCodeToolsDefinesEditor.DontSaveAndExitMenuItemClick(Sender: TObject);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  ModalResult:=mrCancel;
end;

procedure TCodeToolsDefinesEditor.SelectedItemGroupBoxResize(Sender: TObject);
var SelItemMaxX, SelItemMaxY: integer;
begin
  SelItemMaxX:=SelectedItemGroupBox.ClientWidth;
  SelItemMaxY:=SelectedItemGroupBox.ClientHeight;
  with TypeLabel do begin
    Left:=5;
    Top:=3;
    Width:=SelItemMaxX-2*Left;
  end;
  with NameLabel do begin
    Left:=TypeLabel.Left;
    Top:=TypeLabel.Top+TypeLabel.Height+7;
    Width:=70;
  end;
  with NameEdit do begin
    Left:=NameLabel.Left+NameLabel.Width+5;
    Top:=NameLabel.Top;
    Width:=SelItemMaxX-Left-5;
  end;
  with DescriptionLabel do begin
    Left:=NameLabel.Left;
    Top:=NameLabel.Top+NameLabel.Height+7;
    Width:=70;
  end;
  with DescriptionEdit do begin
    Left:=DescriptionLabel.Left+DescriptionLabel.Width+5;
    Top:=DescriptionLabel.Top;
    Width:=SelItemMaxX-Left-5;
  end;
  with VariableLabel do begin
    Left:=DescriptionLabel.Left;
    Top:=DescriptionLabel.Top+DescriptionLabel.Height+7;
    Width:=70;
  end;
  with VariableEdit do begin
    Left:=VariableLabel.Left+VariableLabel.Width+5;
    Top:=VariableLabel.Top;
    Width:=SelItemMaxX-Left-5;
  end;
  with ValueNoteBook do begin
    Left:=0;
    Top:=VariableLabel.Top+VariableLabel.Height+8;
    Width:=SelItemMaxX;
    Height:=SelItemMaxY-Top;
  end;
end;

procedure TCodeToolsDefinesEditor.FormResize(Sender: TObject);
var MaxX, MaxY, SelGrpBoxTop: integer;
begin
  MaxX:=ClientWidth;
  MaxY:=ClientHeight;
  SelGrpBoxTop:=MaxY-310;

  // define tree ---------------------------------------------------------------
  with DefineTreeView do begin
    Left:=3;
    Top:=3;
    Width:=MaxX-2*Left;
    Height:=SelGrpBoxTop-2*Top;
  end;

  // selected item -------------------------------------------------------------
  with SelectedItemGroupBox do begin
    Left:=DefineTreeView.Left;
    Top:=SelGrpBoxTop;
    Width:=MaxX-2*Left;
    Height:=MaxY-Top-Left;
  end;
end;

procedure TCodeToolsDefinesEditor.CodeToolsDefinesEditorKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift=[]) and (Key=VK_ESCAPE) then ModalResult:=mrCancel;
end;

procedure TCodeToolsDefinesEditor.DefineTreeViewMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
  ShowSelectedValues;
end;

procedure TCodeToolsDefinesEditor.ValueNoteBookPageChanged(Sender: TObject);
begin
  if ValueNoteBook.PageIndex=0 then
    ValueAsPathToValueAsText
  else
    ValueAsFilePathsSynEdit.Text:=ValueToFilePathText(ValueAsTextSynEdit.Text);
end;

procedure TCodeToolsDefinesEditor.MoveFilePathUpBitBtnClick(Sender: TObject);
var y: integer;
begin
  if ValueAsFilePathsSynEdit.ReadOnly then exit;
  y:=ValueAsFilePathsSynEdit.CaretY-1;
  if (y>0) and (y<ValueAsFilePathsSynEdit.Lines.Count) then
    ValueAsFilePathsSynEdit.Lines.Move(y,y-1);
end;

procedure TCodeToolsDefinesEditor.MoveFilePathDownBitBtnClick(Sender: TObject);
var y: integer;
begin
  if ValueAsFilePathsSynEdit.ReadOnly then exit;
  y:=ValueAsFilePathsSynEdit.CaretY-1;
  if (y>=0) and (y<ValueAsFilePathsSynEdit.Lines.Count-1) then
    ValueAsFilePathsSynEdit.Lines.Move(y,y+1);
end;

procedure TCodeToolsDefinesEditor.DeleteFilePathBitBtnClick(Sender: TObject);
var y: integer;
begin
  if ValueAsFilePathsSynEdit.ReadOnly then exit;
  y:=ValueAsFilePathsSynEdit.CaretY-1;
  if (y>=0) and (y<ValueAsFilePathsSynEdit.Lines.Count) then
    ValueAsFilePathsSynEdit.Lines.Delete(y);
end;

procedure TCodeToolsDefinesEditor.InsertFilePathBitBtnClick(Sender: TObject);
var y: integer;
begin
  if ValueAsFilePathsSynEdit.ReadOnly then exit;
  y:=ValueAsFilePathsSynEdit.CaretY-1;
  if (y>=0) and (y<ValueAsFilePathsSynEdit.Lines.Count) then
    ValueAsFilePathsSynEdit.Lines.Insert(y,'');
end;

procedure TCodeToolsDefinesEditor.InsertNodeMenuItemClick(Sender: TObject);
var Behind: boolean;
  DefAction: TDefineAction;
begin
  Behind:=(TMenuItem(Sender).Parent=InsertBehindMenuItem);
  if Sender=InsertBehindDefineMenuItem then DefAction:=da_Define
  else if Sender=InsertBehindDefineRecurseMenuItem then DefAction:=da_DefineRecurse
  else if Sender=InsertBehindUndefineMenuItem then DefAction:=da_Undefine
  else if Sender=InsertBehindUndefineRecurseMenuItem then DefAction:=da_UndefineRecurse
  else if Sender=InsertBehindUndefineAllMenuItem then DefAction:=da_UndefineAll
  else if Sender=InsertBehindBlockMenuItem then DefAction:=da_Block
  else if Sender=InsertBehindDirectoryMenuItem then DefAction:=da_Directory
  else if Sender=InsertBehindIfMenuItem then DefAction:=da_If
  else if Sender=InsertBehindIfDefMenuItem then DefAction:=da_IfDef
  else if Sender=InsertBehindIfNotDefMenuItem then DefAction:=da_IfNDef
  else if Sender=InsertBehindElseIfMenuItem then DefAction:=da_ElseIf
  else if Sender=InsertBehindElseMenuItem then DefAction:=da_Else
  else if Sender=InsertAsChildDefineMenuItem then DefAction:=da_Define
  else if Sender=InsertAsChildDefineRecurseMenuItem then DefAction:=da_DefineRecurse
  else if Sender=InsertAsChildUndefineMenuItem then DefAction:=da_Undefine
  else if Sender=InsertAsChildUndefineRecurseMenuItem then DefAction:=da_UndefineRecurse
  else if Sender=InsertAsChildUndefineAllMenuItem then DefAction:=da_UndefineAll
  else if Sender=InsertAsChildBlockMenuItem then DefAction:=da_Block
  else if Sender=InsertAsChildDirectoryMenuItem then DefAction:=da_Directory
  else if Sender=InsertAsChildIfMenuItem then DefAction:=da_If
  else if Sender=InsertAsChildIfDefMenuItem then DefAction:=da_IfDef
  else if Sender=InsertAsChildIfNotDefMenuItem then DefAction:=da_IfNDef
  else if Sender=InsertAsChildElseIfMenuItem then DefAction:=da_ElseIf
  else if Sender=InsertAsChildElseMenuItem then DefAction:=da_Else;
  InsertNewNode(Behind,DefAction);
end;

procedure TCodeToolsDefinesEditor.MoveNodeUpMenuItemClick(Sender: TObject);
var
  SelTreeNode: TTreeNode;
  SelDefNode, PrevDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if (SelTreeNode=nil) or (SelTreeNode.GetPrevSibling=nil) then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  PrevDefNode:=SelDefNode.Prior;
  // move node up in TreeView
  SelTreeNode.MoveTo(SelTreeNode.GetPrevSibling,naInsert);
  // move node up in DefineTree
  SelDefNode.Unbind;
  SelDefNode.InsertInFront(PrevDefNode);
  SelTreeNode.MakeVisible;
end;

procedure TCodeToolsDefinesEditor.MoveNodeDownMenuItemClick(Sender: TObject);
var
  SelTreeNode: TTreeNode;
  SelDefNode, NextDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if (SelTreeNode=nil) or (SelTreeNode.GetNextSibling=nil) then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  NextDefNode:=SelDefNode.Next;
  // move node down in TreeView
  if SelTreeNode.GetNextSibling.GetNextSibling<>nil then
    SelTreeNode.MoveTo(SelTreeNode.GetNextSibling.GetNextSibling,naInsert)
  else
    SelTreeNode.MoveTo(SelTreeNode.GetNextSibling,naAdd);
  // move node down in DefineTree
  SelDefNode.Unbind;
  SelDefNode.InsertBehind(NextDefNode);
  SelTreeNode.MakeVisible;
end;

procedure TCodeToolsDefinesEditor.MoveNodeLvlUpMenuItemClick(Sender: TObject);
var
  SelTreeNode: TTreeNode;
  SelDefNode, PrevDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if (SelTreeNode=nil) or (SelTreeNode.Parent=nil) then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  if SelDefNode.IsAutoGenerated then begin
    MessageDlg(lisCodeToolsDefsNodeIsReadonly,
      lisCodeToolsDefsAutoGeneratedNodesCanNotBeEdited,
      mtInformation,[mbCancel],0);
    exit;
  end;
  // move node one lvl up in TreeView
  if SelTreeNode.Parent.GetNextSibling<>nil then
    SelTreeNode.MoveTo(SelTreeNode.Parent.GetNextSibling,naInsert)
  else
    SelTreeNode.MoveTo(SelTreeNode.Parent,naAdd);
  // move node one lvl up in DefineTree
  PrevDefNode:=SelDefNode.Parent;
  SelDefNode.Unbind;
  SelDefNode.InsertBehind(PrevDefNode);
  SetNodeImages(SelTreeNode,true);
  SelTreeNode.MakeVisible;
end;

procedure TCodeToolsDefinesEditor.MoveNodeLvlDownMenuItemClick(Sender: TObject);
var
  SelTreeNode: TTreeNode;
  SelDefNode, PrevDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if (SelTreeNode=nil) or (SelTreeNode.GetPrevSibling=nil) then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  PrevDefNode:=SelDefNode.Prior;
  if (SelDefNode.IsAutoGenerated) or (PrevDefNode.IsAutoGenerated) then begin
    MessageDlg(lisCodeToolsDefsNodeIsReadonly,
      lisCodeToolsDefsAutoGeneratedNodesCanNotBeEdited,
      mtInformation,[mbCancel],0);
    exit;
  end;
  if (not (PrevDefNode.Action in DefineActionBlocks)) then begin
    MessageDlg(lisCodeToolsDefsInvalidPreviousNode,
      lisCodeToolsDefsPreviousNodeCanNotContainChildNodes,
      mtInformation,[mbCancel],0);
    exit;
  end;
  // move node one lvl down in TreeView
  SelTreeNode.MoveTo(SelTreeNode.GetPrevSibling,naAddChild);
  // move node one lvl up in DefineTree
  SelDefNode.Unbind;
  PrevDefNode.AddChild(SelDefNode);
  SetNodeImages(SelTreeNode.Parent,true);
  SelTreeNode.MakeVisible;
end;

procedure TCodeToolsDefinesEditor.DeleteNodeMenuItemClick(Sender: TObject);
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if (SelTreeNode=nil) then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  if (SelDefNode.IsAutoGenerated) then begin
    MessageDlg(lisCodeToolsDefsNodeIsReadonly,
      lisCodeToolsDefsAutoGeneratedNodesCanNotBeEdited,
      mtInformation,[mbCancel],0);
    exit;
  end;
  if FLastSelectedNode=SelTreeNode then FLastSelectedNode:=nil;
  // delete node in TreeView
  SelTreeNode.Free;
  // delete node in DefineTree
  SelDefNode.Unbind;
  SelDefNode.Free;
end;

procedure TCodeToolsDefinesEditor.ConvertActionMenuItemClick(Sender: TObject);
var
  NewAction: TDefineAction;
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  if SelTreeNode=nil then exit;
  SelDefNode:=TDefineTemplate(SelTreeNode.Data);
  if (SelDefNode.IsAutoGenerated) then begin
    MessageDlg(lisCodeToolsDefsNodeIsReadonly,
      lisCodeToolsDefsAutoGeneratedNodesCanNotBeEdited,
      mtInformation,[mbCancel],0);
    exit;
  end;
  if Sender=ConvertActionToDefineMenuItem then NewAction:=da_Define
  else if Sender=ConvertActionToDefineRecurseMenuItem then NewAction:=da_DefineRecurse
  else if Sender=ConvertActionToUndefineMenuItem then NewAction:=da_Undefine
  else if Sender=ConvertActionToUndefineRecurseMenuItem then NewAction:=da_UndefineRecurse
  else if Sender=ConvertActionToUndefineAllMenuItem then NewAction:=da_UndefineAll
  else if Sender=ConvertActionToBlockMenuItem then NewAction:=da_Block
  else if Sender=ConvertActionToDirectoryMenuItem then NewAction:=da_Directory
  else if Sender=ConvertActionToIfMenuItem then NewAction:=da_If
  else if Sender=ConvertActionToIfDefMenuItem then NewAction:=da_IfDef
  else if Sender=ConvertActionToIfNotDefMenuItem then NewAction:=da_IfNDef
  else if Sender=ConvertActionToElseIfMenuItem then NewAction:=da_ElseIf
  else if Sender=ConvertActionToElseMenuItem then NewAction:=da_Else;
  SelDefNode.Action:=NewAction;
  SetNodeImages(SelTreeNode,false);
  SetTypeLabel;
end;

procedure TCodeToolsDefinesEditor.OpenPreviewMenuItemClick(Sender: TObject);
begin
  ShowCodeToolsDefinesValuesDialog(DefineTree,'');
end;

procedure TCodeToolsDefinesEditor.InsertFPCProjectDefinesTemplateMenuItemClick(
  Sender: TObject);
var InputFileDlg: TInputFileDialog;
  UnitSearchPath, UnitLinkList, DefaultFPCSrcDir, DefaultCompiler,
  CompilerPath, FPCSrcDir: string;
  DirTemplate, FPCTemplate, FPCSrcTemplate: TDefineTemplate;
  TargetOS, TargetProcessor: string;
begin
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
  
    DefaultFPCSrcDir:='$(FPCSrcDir)';
    DefaultCompiler:='$(CompPath)';
    UnitSearchPath:='';
    UnitLinkList:='';
    
    BeginUpdate;
    Caption:=lisCodeToolsDefsCreateFPCMacrosAndPathsForAFPCProjectDirectory;

    FileCount:=3;

    FileTitles[0]:=lisCodeToolsDefsProjectDirectory;
    FileDescs[0]:=lisCodeToolsDefsTheFreePascalProjectDirectory;
    FileNames[0]:='';
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];

    FileTitles[1]:=lisCodeToolsDefscompilerPath;
    FileDescs[1]:=BreakString(
      lisCodeToolsDefsThePathToTheFreePascalCompilerForThisProject, 60, 0);
    FileNames[1]:=DefaultCompiler;
    FileFlags[1]:=[iftFilename];

    FileTitles[2]:=lisCodeToolsDefsFPCCVSSourceDirectory;
    FileDescs[2]:=BreakString(
      lisCodeToolsDefsTheFreePascalCVSSourceDirectory, 60, 0);
    FileNames[2]:=DefaultFPCSrcDir;
    FileFlags[2]:=[iftDirectory];

    EndUpdate;
    if ShowModal=mrCancel then exit;

    // ask the compiler for Macros
    CompilerPath:=FileNames[1];
    if Macros<>nil then Macros.SubstituteStr(CompilerPath);
    DebugLn('  CompilerPath="',CompilerPath,'"');
    TargetOS:='';
    TargetProcessor:='';
    if (CompilerPath<>'') and (CompilerPath<>DefaultCompiler) then
      FPCTemplate:=Boss.DefinePool.CreateFPCTemplate(CompilerPath,'',
                                CreateCompilerTestPascalFilename,UnitSearchPath,
                                TargetOS,TargetProcessor,
                                CodeToolsOpts)
    else
      FPCTemplate:=nil;

    // create path defines
    FPCSrcDir:=FileNames[2];
    if Macros<>nil then Macros.SubstituteStr(FPCSrcDir);
    DebugLn('  FPCSrcDir="',FPCSrcDir,'"');
    if (FPCSrcDir<>'') and (FPCSrcDir<>DefaultFPCSrcDir)
    and (UnitSearchPath<>'') then
      FPCSrcTemplate:=Boss.DefinePool.CreateFPCSrcTemplate(FPCSrcDir,
                      UnitSearchPath, 'ppu', TargetOS, TargetProcessor, false,
                      UnitLinkList, CodeToolsOpts)
    else
      FPCSrcTemplate:=nil;

    // create directory defines
    DirTemplate:=TDefineTemplate.Create('FPC Project ('+FileNames[0]+')',
       'Free Pascal Project Directory','',FileNames[0],da_Directory);
       
    if (DefaultFPCSrcDir=Filenames[2]) and (DefaultCompiler=Filenames[1]) then
    begin
      // a normal fpc project -> nothing special needed
      FPCTemplate.Free;
      FPCSrcTemplate.Free;
    end else begin
      // a special fpc project -> create a world of its own
      DirTemplate.AddChild(TDefineTemplate.Create('Reset All',
         'Reset all values','','',da_UndefineAll));
      if FPCTemplate<>nil then
        DirTemplate.AddChild(FPCTemplate);
      if UnitLinkList<>'' then begin
        DirTemplate.AddChild(TDefineTemplate.Create('FPC Unit Links',
          'Source filenames for standard FPC units',
          ExternalMacroStart+'UnitLinks',UnitLinkList,da_DefineRecurse));
      end;
      FPCSrcTemplate.Free;
    end;

    DirTemplate.SetDefineOwner(CodeToolsOpts,true);
    InsertTemplate(DirTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertFPCompilerDefinesTemplateMenuItemClick(
  Sender: TObject);
var InputFileDlg: TInputFileDialog;
  s, CompilerPath, DefaultCompiler: string;
  FPCTemplate: TDefineTemplate;
  TargetOS, TargetProcessor: string;
begin
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    DefaultCompiler:='$(CompPath)';
    
    BeginUpdate;
    Caption:=lisCodeToolsDefsCreateDefinesForFreePascalCompiler;
    FileCount:=1;

    FileTitles[0]:='compiler path';
    FileDescs[0]:=Format(
      lisCodeToolsDefsThePathToTheFreePascalCompilerForExample, [#13,
       '"', GetDefaultCompilerFilename, '"', '"', '"']);
    FileNames[0]:=DefaultCompiler;
    FileFlags[0]:=[iftCmdLine,iftNotEmpty];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    
    CompilerPath:=FileNames[0];
    if Macros<>nil then Macros.SubstituteStr(CompilerPath);
    DebugLn('  CompilerPath="',CompilerPath,'"');
    
    FPCTemplate:=Boss.DefinePool.CreateFPCTemplate(CompilerPath,'',
                                           CreateCompilerTestPascalFilename,s,
                                           TargetOS,TargetProcessor,
                                           CodeToolsOpts);
    if FPCTemplate=nil then exit;
    FPCTemplate.Name:='Free Pascal Compiler ('+CompilerPath+')';
    InsertTemplate(FPCTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertFPCSourceDirDefinesTemplateMenuItemClick
  (Sender: TObject);
var InputFileDlg: TInputFileDialog;
  UnitSearchPath, UnitLinks, DefaultCompiler, CompilerPath, FPCSrcDir: string;
  TargetOS, TargetProcessor: string;
  ResetAllTemplate, FPCSrcTemplate, FPCSrcDirTemplate,
  FPCTemplate: TDefineTemplate;
begin
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    DefaultCompiler:='$(CompPath)';
    UnitSearchPath:='';

    BeginUpdate;
    Caption:=lisCodeToolsDefsCreateDefinesForFreePascalCVSSources;
    FileCount:=2;

    FileTitles[0]:=lisCodeToolsDefsFPCCVSSourceDirectory;
    FileDescs[0]:=lisCodeToolsDefsTheFreePascalCVSSourceDir;
    FileNames[0]:='~/fpc_sources/1.1/fpc';
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];

    FileTitles[1]:=lisCodeToolsDefscompilerPath;
    FileDescs[1]:='The path to the free pascal compiler for this source.'#13
                  +'Used to autocreate macros.';
    FileNames[1]:=DefaultCompiler;
    FileFlags[1]:=[iftFilename];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    
    // ask the compiler for Macros
    CompilerPath:=FileNames[1];
    if Macros<>nil then Macros.SubstituteStr(CompilerPath);
    DebugLn('  CompilerPath="',CompilerPath,'"');

    TargetOS:='';
    TargetProcessor:='';
    FPCTemplate:=Boss.DefinePool.CreateFPCTemplate(CompilerPath,'',
                               CreateCompilerTestPascalFilename,UnitSearchPath,
                               TargetOS,TargetProcessor,CodeToolsOpts);
    if FPCTemplate=nil then begin
      DebugLn('ERROR: unable to get FPC Compiler Macros from "',CompilerPath,'"');
      exit;
    end;
      
    // create FPC CVS Source defines
    FPCSrcDir:=FileNames[0];
    if Macros<>nil then Macros.SubstituteStr(FPCSrcDir);
    DebugLn('  FPCSrcDir="',FPCSrcDir,'"');
    UnitSearchPath:='';
    FPCSrcTemplate:=Boss.DefinePool.CreateFPCSrcTemplate(FPCSrcDir,
                        UnitSearchPath, 'ppu', TargetOS, TargetProcessor, false,
                        UnitLinks, CodeToolsOpts);
    if FPCSrcTemplate=nil then begin
      DebugLn('ERROR: unable to create FPC CVS Src defines for "',FPCSrcDir,'"');
      FPCTemplate.Free;
      exit;
    end;

    // create directory defines
    FPCSrcDirTemplate:=FPCSrcTemplate.FirstChild.Next;
    FPCSrcDirTemplate.UnBind;
    FPCSrcTemplate.Free;
    FPCSrcDirTemplate.Name:='FPC CVS Sources ('+FileNames[0]+')';
    ResetAllTemplate:=TDefineTemplate.Create('Reset All','Reset all values',
                  '','',da_UndefineAll);
    ResetAllTemplate.InsertInFront(FPCSrcDirTemplate.FirstChild);
    FPCTemplate.InsertBehind(ResetAllTemplate);

    FPCSrcDirTemplate.SetDefineOwner(CodeToolsOpts,true);
    InsertTemplate(FPCSrcDirTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertLazarusSourceDefinesTemplateMenuItemClick
  (Sender: TObject);
var
  InputFileDlg: TInputFileDialog;
  LazTemplate: TDefineTemplate;
begin
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    BeginUpdate;
    Caption:=lisCodeToolsDefsCreateDefinesForLazarusDir;
    FileCount:=1;

    FileTitles[0]:=lisCodeToolsDefsLazarusDirectory;
    FileDescs[0]:=lisCodeToolsDefsTheLazarusMainDirectory;
    FileNames[0]:=IDEProcs.ProgramDirectory;
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    LazTemplate:=Boss.DefinePool.CreateLazarusSrcTemplate(FileNames[0],
                               '$('+ExternalMacroStart+'LCLWidgetType)','',
                               CodeToolsOpts);
    if LazTemplate=nil then exit;
    LazTemplate.Name:='Lazarus Directory ('+FileNames[0]+')';
    InsertTemplate(LazTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertDelphiCompilerDefinesTemplateMenuItemClick
  (Sender: TObject);
var DelphiVersion: integer;
begin
  if Sender=InsertDelphi7CompilerDefinesTemplateMenuItem then
    DelphiVersion:=7
  else if Sender=InsertDelphi6CompilerDefinesTemplateMenuItem then
    DelphiVersion:=6
  else
    DelphiVersion:=5;
  InsertTemplate(Boss.DefinePool.CreateDelphiCompilerDefinesTemplate(
                                                  DelphiVersion,CodeToolsOpts));
end;

procedure TCodeToolsDefinesEditor.InsertDelphiDirectoryTemplateMenuItemClick(
  Sender: TObject);
var InputFileDlg: TInputFileDialog;
  DirTemplate: TDefineTemplate;
  DelphiVersion: integer;
  DelphiName: string;
begin
  if Sender=InsertDelphi7DirectoryTemplateMenuItem then
    DelphiVersion:=7
  else if Sender=InsertDelphi6DirectoryTemplateMenuItem then
    DelphiVersion:=6
  else
    DelphiVersion:=5;
  DelphiName:='Delphi'+IntToStr(DelphiVersion);

  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    BeginUpdate;
    Caption:=Format(lisCodeToolsDefsCreateDefinesForDirectory, [DelphiName]);
    FileCount:=1;
    
    FileTitles[0]:=Format(lisCodeToolsDefsdirectory, [DelphiName]);
    FileDescs[0]:=Format(lisCodeToolsDefsDelphiMainDirectoryDesc, [DelphiName,
      #13, DelphiName, #13, IntToStr(DelphiVersion)]);
    FileNames[0]:=SetDirSeparators(
                        'C:/Programme/Borland/Delphi'+IntToStr(DelphiVersion));
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];
    
    EndUpdate;
    if ShowModal=mrCancel then exit;
    DirTemplate:=Boss.DefinePool.CreateDelphiDirectoryTemplate(FileNames[0],
                                                   DelphiVersion,CodeToolsOpts);
    if DirTemplate=nil then exit;
    DirTemplate.Name:=DelphiName+' ('+FileNames[0]+')';
    InsertTemplate(DirTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertDelphiProjectTemplateMenuItemClick(
  Sender: TObject);
var
  InputFileDlg: TInputFileDialog;
  ProjTemplate: TDefineTemplate;
  DelphiVersion: integer;
  DelphiName: string;
begin
  if Sender=InsertDelphi7ProjectTemplateMenuItem then
    DelphiVersion:=7
  else if Sender=InsertDelphi6ProjectTemplateMenuItem then
    DelphiVersion:=6
  else
    DelphiVersion:=5;
  DelphiName:='Delphi'+IntToStr(DelphiVersion);

  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    BeginUpdate;
    Caption:=Format(lisCodeToolsDefsCreateDefinesForProject, [DelphiName]);

    FileCount:=2;
    
    FileTitles[0]:=Format(lisCodeToolsDefsprojectDirectory2, [DelphiName]);
    FileDescs[0]:=Format(lisCodeToolsDefsTheProjectDirectory, [DelphiName, #13]
      );
    FileNames[0]:=SetDirSeparators('C:/Programme/Borland/Delphi'
                   +IntToStr(DelphiVersion)+'/YourProject');
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];
    
    FileTitles[1]:=Format(lisCodeToolsDefsdirectory, [DelphiName]);
    FileDescs[1]:=Format(lisCodeToolsDefsDelphiMainDirectoryForProject, [
      DelphiName, #13, DelphiName, #13, DelphiName, #13, IntToStr(DelphiVersion)
      ]);
    FileNames[1]:=SetDirSeparators('C:/Programme/Borland/Delphi'
                                                      +IntToStr(DelphiVersion));
    FileFlags[1]:=[iftDirectory,iftNotEmpty,iftMustExist];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    ProjTemplate:=Boss.DefinePool.CreateDelphiProjectTemplate(FileNames[0],
                                      FileNames[1],DelphiVersion,CodeToolsOpts);
    if ProjTemplate=nil then exit;
    ProjTemplate.Name:=DelphiName+' Project ('+FileNames[0]+')';
    InsertTemplate(ProjTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertKylixCompilerDefinesTemplateMenuItemClick
  (Sender: TObject);
var KylixVersion: integer;
begin
  KylixVersion:=3;
  InsertTemplate(Boss.DefinePool.CreateKylixCompilerDefinesTemplate(
                                                   KylixVersion,CodeToolsOpts));
end;

procedure TCodeToolsDefinesEditor.InsertKylixDirectoryTemplateMenuItemClick(
  Sender: TObject);
var
  InputFileDlg: TInputFileDialog;
  DirTemplate: TDefineTemplate;
  KylixVersion: integer;
  KylixName: string;
  UserName: String;
begin
  KylixVersion:=3;
  KylixName:='Kylix'+IntToStr(KylixVersion);

  UserName:=GetCurrentUserName;
  if UserName='' then UserName:='user';
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    BeginUpdate;
    Caption:=Format(lisCodeToolsDefsCreateDefinesForDirectory, [KylixName]);
    FileCount:=1;

    FileTitles[0]:=Format(lisCodeToolsDefsdirectory, [KylixName]);
    FileDescs[0]:=Format(lisCodeToolsDefsKylixMainDirectoryDesc, [KylixName,
      #13, KylixName, #13, IntToStr(KylixVersion)]);
    FileNames[0]:=SetDirSeparators(
                             '/home/'+UserName+'/kylix'+IntToStr(KylixVersion));
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    DirTemplate:=Boss.DefinePool.CreateKylixDirectoryTemplate(FileNames[0],
                                                    KylixVersion,CodeToolsOpts);
    if DirTemplate=nil then exit;
    DirTemplate.Name:=KylixName+' ('+FileNames[0]+')';
    InsertTemplate(DirTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.InsertKylixProjectTemplateMenuItemClick(
  Sender: TObject);
var
  InputFileDlg: TInputFileDialog;
  ProjTemplate: TDefineTemplate;
  KylixVersion: integer;
  KylixName: string;
  UserName: String;
begin
  KylixVersion:=3;
  KylixName:='Kylix'+IntToStr(KylixVersion);

  UserName:=GetCurrentUserName;
  if UserName='' then UserName:='user';
  InputFileDlg:=GetInputFileDialog;
  InputFileDlg.Macros:=Macros;
  with InputFileDlg do begin
    BeginUpdate;
    Caption:=Format(lisCodeToolsDefsCreateDefinesForProject, [KylixName]);

    FileCount:=2;

    FileTitles[0]:=Format(lisCodeToolsDefsprojectDirectory2, [KylixName]);
    FileDescs[0]:=Format(lisCodeToolsDefsTheProjectDirectory, [KylixName, #13]
      );
    FileNames[0]:=SetDirSeparators('/home/'+UserName+'/kylix'
                   +IntToStr(KylixVersion)+'/YourProject');
    FileFlags[0]:=[iftDirectory,iftNotEmpty,iftMustExist];

    FileTitles[1]:=Format(lisCodeToolsDefsdirectory, [KylixName]);
    FileDescs[1]:=Format(lisCodeToolsDefsKylixMainDirectoryForProject, [
      KylixName, #13, KylixName, #13, KylixName, #13, IntToStr(KylixVersion)
      ]);
    FileNames[1]:=SetDirSeparators('/home/'+UserName+'/kylix'+IntToStr(KylixVersion));
    FileFlags[1]:=[iftDirectory,iftNotEmpty,iftMustExist];

    EndUpdate;
    if ShowModal=mrCancel then exit;
    ProjTemplate:=Boss.DefinePool.CreateDelphiProjectTemplate(FileNames[0],
                                       FileNames[1],KylixVersion,CodeToolsOpts);
    if ProjTemplate=nil then exit;
    ProjTemplate.Name:=KylixName+' Project ('+FileNames[0]+')';
    InsertTemplate(ProjTemplate);
  end;
end;

procedure TCodeToolsDefinesEditor.ValueNoteBookResize(Sender: TObject);
var
  ValNoteBookMaxX: integer;
begin
  //ValNoteBookMaxX:=ValueNoteBook.ClientWidth-10;//ValueAsTextSynEdit.Parent.ClientWidth;
  //ValNoteBookMaxY:=ValueNoteBook.ClientHeight-30;//ValueAsTextSynEdit.Parent.ClientHeight;
  ValNoteBookMaxX:=ValueAsTextSynEdit.Parent.ClientWidth;
  with ValueAsTextSynEdit do begin
    Left:=0;
    Top:=0;
    Width:=ValNoteBookMaxX;
  end;
  with ValueAsFilePathsSynEdit do begin
    Left:=0;
    Top:=0;
    Width:=ValNoteBookMaxX-80;
  end;
  with MoveFilePathUpBitBtn do begin
    Left:=ValNoteBookMaxX-75;
    Top:=1;
    Width:=ValNoteBookMaxX-Left-5;
  end;
  with MoveFilePathDownBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=MoveFilePathUpBitBtn.Top+MoveFilePathUpBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
  with DeleteFilePathBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=MoveFilePathDownBitBtn.Top+MoveFilePathDownBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
  with InsertFilePathBitBtn do begin
    Left:=MoveFilePathUpBitBtn.Left;
    Top:=DeleteFilePathBitBtn.Top+DeleteFilePathBitBtn.Height+5;
    Width:=MoveFilePathUpBitBtn.Width;
  end;
end;

procedure TCodeToolsDefinesEditor.CreateComponents;

  procedure CreateControl(var AControl: TControl;
    AControlClass: TControlClass; const AName: string;
    AParent: TWinControl);
  begin
    AControl:=AControlClass.Create(Self);
    with AControl do begin
      Name:=AName;
      Parent:=AParent;
      Visible:=true;
    end;
  end;
  
  procedure AddMenuItem(var AMenuItem: TMenuItem; const AName, ACaption: string;
    AParent: TMenuItem);
  begin
    AMenuItem:=TMenuItem.Create(Self);
    AMenuItem.Name:=AName;
    AMenuItem.Caption:=ACaption;
    if AParent=nil then
      MainMenu.Items.Add(AMenuItem)
    else
      AParent.Add(AMenuItem);
  end;
  
  procedure AddResImg(const ResName: string);
  var Pixmap: TPixmap;
  begin
    Pixmap:=TPixmap.Create;
    Pixmap.TransparentColor:=clWhite;
    Pixmap.LoadFromLazarusResource(ResName);
    TheImageList.Add(Pixmap,nil)
  end;

var i: integer;
begin
  TheImageList:=TImageList.Create(Self);
  with TheImageList do begin
    Width:=22;
    Height:=22;
    Name:='TheImageList';
    AddResImg('define_22x22');
    AddResImg('definerecurse_22x22');
    AddResImg('undefine_22x22');
    AddResImg('undefinerecurse_22x22');
    AddResImg('undefineall_22x22');
    AddResImg('block_22x22');
    AddResImg('directory_22x22');
    AddResImg('if_22x22');
    AddResImg('ifdef_22x22');
    AddResImg('ifndef_22x22');
    AddResImg('elseif_22x22');
    AddResImg('else_22x22');
    AddResImg('ctdefinestate_none_22x22');
    AddResImg('ctdefinestate_auto_22x22');
    AddResImg('ctdefinestate_projspec_22x22');
    AddResImg('ctdefinestate_autoproj_22x22');
  end;

  // Main Menu -----------------------------------------------------------------
  MainMenu := TMainMenu.Create(Self);
  MainMenu.Name:='MainMenu';
  Menu := MainMenu;

  // exit menu
  AddMenuItem(ExitMenuItem, 'ExitMenuItem', lisCodeToolsDefsExit, nil);
  AddMenuItem(SaveAndExitMenuItem, 'SaveAndExitMenuItem',
    lisCodeToolsDefsSaveAndExit,
              ExitMenuItem);
  SaveAndExitMenuItem.OnClick:=@SaveAndExitMenuItemClick;
  ExitMenuItem.Add(CreateSeperator);
  AddMenuItem(DontSaveAndExitMenuItem,'DontSaveAndExitMenuItem',
              lisCodeToolsDefsExitWithoutSave, ExitMenuItem);
  DontSaveAndExitMenuItem.OnClick:=@DontSaveAndExitMenuItemClick;

  // edit nodes
  AddMenuItem(EditMenuItem, 'EditMenuItem', lisCodeToolsDefsEdit, nil);
  AddMenuItem(MoveNodeUpMenuItem, 'MoveNodeUpMenuItem',
    lisCodeToolsDefsMoveNodeUp,
              EditMenuItem);
  MoveNodeUpMenuItem.OnClick:=@MoveNodeUpMenuItemClick;
  
  AddMenuItem(MoveNodeDownMenuItem, 'MoveNodeDownMenuItem',
    lisCodeToolsDefsMoveNodeDown,
              EditMenuItem);
  MoveNodeDownMenuItem.OnClick:=@MoveNodeDownMenuItemClick;
  
  AddMenuItem(MoveNodeLvlUpMenuItem, 'MoveNodeLvlUpMenuItem',
    lisCodeToolsDefsMoveNodeOneLevelUp,
              EditMenuItem);
  MoveNodeLvlUpMenuItem.OnClick:=@MoveNodeLvlUpMenuItemClick;
              
  AddMenuItem(MoveNodeLvlDownMenuItem, 'MoveNodeLvlDownMenuItem',
    lisCodeToolsDefsMoveNodeOneLevelDown,
              EditMenuItem);
  MoveNodeLvlDownMenuItem.OnClick:=@MoveNodeLvlDownMenuItemClick;
  
  EditMenuItem.Add(CreateSeperator);
  
  AddMenuItem(InsertBehindMenuItem, 'InsertBehindMenuItem',
    lisCodeToolsDefsInsertNodeBelow,
              EditMenuItem);
              
  AddMenuItem(InsertAsChildMenuItem, 'InsertAsChildMenuItem',
    lisCodeToolsDefsInsertNodeAsChild,
              EditMenuItem);
              
  EditMenuItem.Add(CreateSeperator);
  
  AddMenuItem(DeleteNodeMenuItem, 'DeleteNodeMenuItem',
    lisCodeToolsDefsDeleteNode,
              EditMenuItem);
  DeleteNodeMenuItem.OnClick:=@DeleteNodeMenuItemClick;
  
  AddMenuItem(ConvertActionMenuItem, 'ConvertActionMenuItem',
    lisCodeToolsDefsConvertNode,
              EditMenuItem);

{  EditMenuItem.Add(CreateSeperator);
  AddMenuItem(CopyToClipbrdMenuItem,'CopyToClipbrdMenuItem','Copy to clipboard',
              EditMenuItem);
  AddMenuItem(PasteFromClipbrdMenuItem,'PasteFromClipbrdMenuItem',
              'Paste from clipboard',EditMenuItem);}

  // insert node behind submenu
  AddMenuItem(InsertBehindDefineMenuItem, 'InsertBehindDefineMenuItem',
    lisCodeToolsDefsDefine,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindDefineRecurseMenuItem,
              'InsertBehindDefineRecurseMenuItem',
                lisCodeToolsDefsDefineRecurse,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindUndefineMenuItem,
              'InsertBehindUndefineMenuItem', lisCodeToolsDefsUndefine,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindUndefineRecurseMenuItem,
              'InsertBehindUndefineRecurseMenuItem',
                lisCodeToolsDefsUndefineRecurse,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindUndefineAllMenuItem,
              'InsertBehindUndefineAllMenuItem', lisCodeToolsDefsUndefineAll,
              InsertBehindMenuItem);
  InsertBehindMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertBehindBlockMenuItem, 'InsertBehindBlockMenuItem',
    lisCodeToolsDefsBlock,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindDirectoryMenuItem,
              'InsertBehindDirectoryMenuItem',
                lisCodeToolsDefsInsertBehindDirectory,
              InsertBehindMenuItem);
  InsertBehindMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertBehindIfMenuItem, 'InsertBehindIfMenuItem',
    lisCodeToolsDefsIf,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindIfDefMenuItem, 'InsertBehindIfDefMenuItem',
    lisCodeToolsDefsIfDef,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindIfNotDefMenuItem, 'InsertBehindIfNotDefMenuItem',
    lisCodeToolsDefsIfNDef,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindElseIfMenuItem, 'InsertBehindElseIfMenuItem',
    lisCodeToolsDefsElseIf,
              InsertBehindMenuItem);
  AddMenuItem(InsertBehindElseMenuItem, 'InsertBehindElseMenuItem',
    lisCodeToolsDefsElse,
              InsertBehindMenuItem);
  for i:=0 to InsertBehindMenuItem.Count-1 do
    if InsertBehindMenuItem[i].Caption<>'-' then
      InsertBehindMenuItem[i].OnClick:=@InsertNodeMenuItemClick;

  // insert node as child submenu
  AddMenuItem(InsertAsChildDefineMenuItem, 'InsertAsChildDefineMenuItem',
    lisCodeToolsDefsDefine,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildDefineRecurseMenuItem,
              'InsertAsChildDefineRecurseMenuItem',
                lisCodeToolsDefsDefineRecurse,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildUndefineMenuItem,
              'InsertAsChildUndefineMenuItem', lisCodeToolsDefsUndefine,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildUndefineRecurseMenuItem,
              'InsertAsChildUndefineRecurseMenuItem',
                lisCodeToolsDefsUndefineRecurse,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildUndefineAllMenuItem,
              'InsertAsChildUndefineAllMenuItem', lisCodeToolsDefsUndefineAll,
              InsertAsChildMenuItem);
  InsertAsChildMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertAsChildBlockMenuItem, 'InsertAsChildBlockMenuItem',
    lisCodeToolsDefsBlock,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildDirectoryMenuItem,
              'InsertAsChildDirectoryMenuItem',
                lisCodeToolsDefsInsertBehindDirectory,
              InsertAsChildMenuItem);
  InsertAsChildMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertAsChildIfMenuItem, 'InsertAsChildIfMenuItem',
    lisCodeToolsDefsIf,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildIfDefMenuItem, 'InsertAsChildIfDefMenuItem',
    lisCodeToolsDefsIfDef,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildIfNotDefMenuItem, 'InsertAsChildIfNotDefMenuItem',
    lisCodeToolsDefsIfNDef,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildElseIfMenuItem, 'InsertAsChildElseIfMenuItem',
    lisCodeToolsDefsElseIf,
              InsertAsChildMenuItem);
  AddMenuItem(InsertAsChildElseMenuItem, 'InsertAsChildElseMenuItem',
    lisCodeToolsDefsElse,
              InsertAsChildMenuItem);
  for i:=0 to InsertAsChildMenuItem.Count-1 do
    if InsertAsChildMenuItem[i].Caption<>'-' then
      InsertAsChildMenuItem[i].OnClick:=@InsertNodeMenuItemClick;
      
  // convert node sub menu
  AddMenuItem(ConvertActionToDefineMenuItem, 'ConvertActionToDefineMenuItem',
    lisCodeToolsDefsDefine,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToDefineRecurseMenuItem,
              'ConvertActionToDefineRecurseMenuItem',
                lisCodeToolsDefsDefineRecurse,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToUndefineMenuItem,
              'ConvertActionToUndefineMenuItem', lisCodeToolsDefsUndefine,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToUndefineRecurseMenuItem,
              'ConvertActionToUndefineRecurseMenuItem',
                lisCodeToolsDefsUndefineRecurse,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToUndefineAllMenuItem,
              'ConvertActionToUndefineAllMenuItem', lisCodeToolsDefsUndefineAll,
              ConvertActionMenuItem);
  ConvertActionMenuItem.Add(CreateSeperator);
  AddMenuItem(ConvertActionToBlockMenuItem, 'ConvertActionToBlockMenuItem',
    lisCodeToolsDefsBlock,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToDirectoryMenuItem,
              'ConvertActionToDirectoryMenuItem',
                lisCodeToolsDefsInsertBehindDirectory,
              ConvertActionMenuItem);
  ConvertActionMenuItem.Add(CreateSeperator);
  AddMenuItem(ConvertActionToIfMenuItem, 'ConvertActionToIfMenuItem',
    lisCodeToolsDefsIf,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToIfDefMenuItem, 'ConvertActionToIfDefMenuItem',
    lisCodeToolsDefsIfDef,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToIfNotDefMenuItem,
    'ConvertActionToIfNotDefMenuItem', lisCodeToolsDefsIfNDef,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToElseIfMenuItem, 'ConvertActionToElseIfMenuItem',
    lisCodeToolsDefsElseIf,
              ConvertActionMenuItem);
  AddMenuItem(ConvertActionToElseMenuItem, 'ConvertActionToElseMenuItem',
    lisCodeToolsDefsElse,
              ConvertActionMenuItem);
  for i:=0 to ConvertActionMenuItem.Count-1 do
    if ConvertActionMenuItem[i].Caption<>'-' then
      ConvertActionMenuItem[i].OnClick:=@ConvertActionMenuItemClick;

  // tools
  AddMenuItem(ToolsMenuItem, 'ToolsMenuItem', lisCTDefsTools, nil);
  AddMenuItem(OpenPreviewMenuItem, 'OpenPreviewMenuItem', lisCTDefsOpenPreview,
              ToolsMenuItem);
  OpenPreviewMenuItem.OnClick:=@OpenPreviewMenuItemClick;
              
  {AddMenuItem(ShowMacroListMenuItem,'ShowMacroListMenuItem','Show Macros',
              ToolsMenuItem);}

  // templates
  AddMenuItem(InsertTemplateMenuItem,'InsertTemplateMenuItem',
              lisCodeToolsDefsInsertTemplate, nil);

  // FPC templates
  AddMenuItem(InsertFPCProjectDefinesTemplateMenuItem,
              'InsertFPCProjectDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertFreePascalProjectTe,
              InsertTemplateMenuItem);
  InsertFPCProjectDefinesTemplateMenuItem.OnClick:=
              @InsertFPCProjectDefinesTemplateMenuItemClick;

  AddMenuItem(InsertFPCompilerDefinesTemplateMenuItem,
              'InsertFPCompilerDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertFreePascalCompilerT,
              InsertTemplateMenuItem);
  InsertFPCompilerDefinesTemplateMenuItem.OnClick:=
              @InsertFPCompilerDefinesTemplateMenuItemClick;
              
  AddMenuItem(InsertFPCSourceDirTemplateMenuItem,
              'InsertFPCSourceDirTemplateMenuItem',
              lisCodeToolsDefsInsertFreePascalCVSSource,
              InsertTemplateMenuItem);
  InsertFPCSourceDirTemplateMenuItem.OnClick:=
              @InsertFPCSourceDirDefinesTemplateMenuItemClick;

  // lazarus templates
  InsertTemplateMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertLazarusSourceTemplateMenuItem,
              'InsertLazarusSourceTemplateMenuItem',
              lisCodeToolsDefsInsertLazarusDirectoryTem,
              InsertTemplateMenuItem);
  InsertLazarusSourceTemplateMenuItem.OnClick:=
              @InsertLazarusSourceDefinesTemplateMenuItemClick;

  // Delphi 5 templates
  InsertTemplateMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertDelphi5CompilerDefinesTemplateMenuItem,
              'InsertDelphi5CompilerDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi5CompilerTemp,
              InsertTemplateMenuItem);
  InsertDelphi5CompilerDefinesTemplateMenuItem.OnClick:=
              @InsertDelphiCompilerDefinesTemplateMenuItemClick;
  
  AddMenuItem(InsertDelphi5DirectoryTemplateMenuItem,
              'InsertDelphi5DirectoryTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi5DirectoryTem,
              InsertTemplateMenuItem);
  InsertDelphi5DirectoryTemplateMenuItem.OnClick:=
              @InsertDelphiDirectoryTemplateMenuItemClick;

  AddMenuItem(InsertDelphi5ProjectTemplateMenuItem,
              'InsertDelphi5ProjectTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi5ProjectTempl,
              InsertTemplateMenuItem);
  InsertDelphi5ProjectTemplateMenuItem.OnClick:=
              @InsertDelphiProjectTemplateMenuItemClick;

  // Delphi 6 templates
  InsertTemplateMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertDelphi6CompilerDefinesTemplateMenuItem,
              'InsertDelphi6CompilerDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi6CompilerTemp,
              InsertTemplateMenuItem);
  InsertDelphi6CompilerDefinesTemplateMenuItem.OnClick:=
              @InsertDelphiCompilerDefinesTemplateMenuItemClick;

  AddMenuItem(InsertDelphi6DirectoryTemplateMenuItem,
              'InsertDelphi6DirectoryTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi6DirectoryTem,
              InsertTemplateMenuItem);
  InsertDelphi6DirectoryTemplateMenuItem.OnClick:=
              @InsertDelphiDirectoryTemplateMenuItemClick;

  AddMenuItem(InsertDelphi6ProjectTemplateMenuItem,
              'InsertDelphi6ProjectTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi6ProjectTempl,
              InsertTemplateMenuItem);
  InsertDelphi6ProjectTemplateMenuItem.OnClick:=
              @InsertDelphiProjectTemplateMenuItemClick;

  // Delphi 7 templates
  InsertTemplateMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertDelphi7CompilerDefinesTemplateMenuItem,
              'InsertDelphi7CompilerDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi7CompilerTemp,
              InsertTemplateMenuItem);
  InsertDelphi7CompilerDefinesTemplateMenuItem.OnClick:=
              @InsertDelphiCompilerDefinesTemplateMenuItemClick;

  AddMenuItem(InsertDelphi7DirectoryTemplateMenuItem,
              'InsertDelphi7DirectoryTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi7DirectoryTem,
              InsertTemplateMenuItem);
  InsertDelphi7DirectoryTemplateMenuItem.OnClick:=
              @InsertDelphiDirectoryTemplateMenuItemClick;

  AddMenuItem(InsertDelphi7ProjectTemplateMenuItem,
              'InsertDelphi7ProjectTemplateMenuItem',
              lisCodeToolsDefsInsertDelphi7ProjectTempl,
              InsertTemplateMenuItem);
  InsertDelphi7ProjectTemplateMenuItem.OnClick:=
              @InsertDelphiProjectTemplateMenuItemClick;

  // Kylix 3 templates
  InsertTemplateMenuItem.Add(CreateSeperator);
  AddMenuItem(InsertKylix3CompilerDefinesTemplateMenuItem,
              'InsertKylix3CompilerDefinesTemplateMenuItem',
              lisCodeToolsDefsInsertKylix3CompilerTemp,
              InsertTemplateMenuItem);
  InsertKylix3CompilerDefinesTemplateMenuItem.OnClick:=
              @InsertKylixCompilerDefinesTemplateMenuItemClick;

  AddMenuItem(InsertKylix3DirectoryTemplateMenuItem,
              'InsertKylix3DirectoryTemplateMenuItem',
              lisCodeToolsDefsInsertKylix3DirectoryTem,
              InsertTemplateMenuItem);
  InsertKylix3DirectoryTemplateMenuItem.OnClick:=
              @InsertKylixDirectoryTemplateMenuItemClick;

  AddMenuItem(InsertKylix3ProjectTemplateMenuItem,
              'InsertKylix3ProjectTemplateMenuItem',
              lisCodeToolsDefsInsertKylix3ProjectTempl,
              InsertTemplateMenuItem);
  InsertKylix3ProjectTemplateMenuItem.OnClick:=
              @InsertKylixProjectTemplateMenuItemClick;

  // define tree----------------------------------------------------------------
  CreateControl(DefineTreeView,TTreeView,'DefineTreeView',Self);
  with DefineTreeView do begin
    DefaultItemHeight:=22;
    Images:=TheImageList;
    StateImages:=TheImageList;
    OnMouseUp:=@DefineTreeViewMouseUp;
  end;

  // selected item
  CreateControl(SelectedItemGroupBox,TGroupBox,'SelectedItemGroupBox',Self);
  SelectedItemGroupBox.Caption:=lisCodeToolsDefsSelectedNode;
  SelectedItemGroupBox.OnResize:=@SelectedItemGroupBoxResize;
  
  CreateControl(TypeLabel,TLabel,'TypeLabel',SelectedItemGroupBox);
  
  CreateControl(NameLabel,TLabel,'NameLabel',SelectedItemGroupBox);
  NameLabel.Caption:=lisCodeToolsDefsName;
  
  CreateControl(NameEdit,TEdit,'NameEdit',SelectedItemGroupBox);

  CreateControl(DescriptionLabel,TLabel,'DescriptionLabel',
                   SelectedItemGroupBox);
  DescriptionLabel.Caption:=lisCodeToolsDefsDescription;
                   
  CreateControl(DescriptionEdit,TEdit,'DescriptionEdit',
                   SelectedItemGroupBox);
                   
  CreateControl(VariableLabel,TLabel,'VariableLabel',SelectedItemGroupBox);
  VariableLabel.Caption:=lisCodeToolsDefsVariable;
  
  CreateControl(VariableEdit,TEdit,'VariableEdit',SelectedItemGroupBox);
  
  CreateControl(ValueNoteBook,TNoteBook,'ValueNoteBook',
                   SelectedItemGroupBox);
  with ValueNoteBook do begin
    if PageCount>0 then
      Pages[0]:=lisCodeToolsDefsValueAsText
    else
      Pages.Add(lisCodeToolsDefsValueAsText);
    Pages.Add(lisCodeToolsDefsValueAsFilePaths);
    OnPageChanged:=@ValueNoteBookPageChanged;
    OnResize:=@ValueNoteBookResize;
  end;
                   
  CreateControl(ValueAsTextSynEdit,TSynEdit,'ValueAsTextSynEdit',
                   ValueNoteBook.Page[0]);
  ValueAsTextSynEdit.Options:=[eoBracketHighlight, eoHideRightMargin,
    eoDragDropEditing, eoHalfPageScroll, eoScrollByOneLess, eoScrollPastEol,
    eoSmartTabs, eoTabsToSpaces, eoTrimTrailingSpaces];
  ValueAsTextSynEdit.Gutter.Visible:=false;
  ValueAsTextSynEdit.Align:=alClient;
  ValueAsTextSynEdit.Scrollbars:=ssBoth;
  ValueAsTextSynEdit.Align:=alLeft;

  CreateControl(ValueAsFilePathsSynEdit,TSynEdit,'ValueAsFilePathsSynEdit',
                   ValueNoteBook.Page[1]);
  ValueAsFilePathsSynEdit.Options:=ValueAsTextSynEdit.Options;
  ValueAsFilePathsSynEdit.Gutter.Visible:=false;
  ValueAsFilePathsSynEdit.Scrollbars:=ssBoth;
  ValueAsFilePathsSynEdit.Align:=alLeft;

  CreateControl(MoveFilePathUpBitBtn,TBitBtn,'MoveFilePathUpBitBtn',
                   ValueNoteBook.Page[1]);
  MoveFilePathUpBitBtn.Caption:=dlgUpWord;
  MoveFilePathUpBitBtn.OnClick:=@MoveFilePathUpBitBtnClick;
                   
  CreateControl(MoveFilePathDownBitBtn,TBitBtn,'MoveFilePathDownBitBtn',
                   ValueNoteBook.Page[1]);
  MoveFilePathDownBitBtn.Caption:=dlgDownWord;
  MoveFilePathDownBitBtn.OnClick:=@MoveFilePathDownBitBtnClick;
                   
  CreateControl(DeleteFilePathBitBtn,TBitBtn,'DeleteFilePathBitBtn',
                   ValueNoteBook.Page[1]);
  DeleteFilePathBitBtn.Caption:=dlgEdDelete;
  DeleteFilePathBitBtn.OnClick:=@DeleteFilePathBitBtnClick;
                   
  CreateControl(InsertFilePathBitBtn,TBitBtn,'InsertFilePathBitBtn',
                   ValueNoteBook.Page[1]);
  InsertFilePathBitBtn.Caption:=srVK_INSERT;
  InsertFilePathBitBtn.OnClick:=@InsertFilePathBitBtnClick;
end;

function TCodeToolsDefinesEditor.CreateSeperator : TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := '-';
end;

procedure TCodeToolsDefinesEditor.RebuildDefineTreeView;
begin
  DefineTreeView.Items.BeginUpdate;
  DefineTreeView.Items.Clear;
  AddDefineNodes(FDefineTree.RootTemplate,nil,true,true);
  DefineTreeView.Items.EndUpdate;
end;

procedure TCodeToolsDefinesEditor.AddDefineNodes(
  ANode: TDefineTemplate; AParent: TTreeNode;
  WithChilds, WithNextSiblings: boolean);
var NewTreeNode: TTreeNode;
begin
  if ANode=nil then exit;
//writeln(' AAA ',StringOfChar(' ',ANode.Level*2),' ',ANode.Name,' ',WithChilds,',',WithNextSiblings);
  DefineTreeView.Items.BeginUpdate;
  NewTreeNode:=DefineTreeView.Items.AddChildObject(AParent,ANode.Name,ANode);
  SetNodeImages(NewTreeNode,false);
  if WithChilds and (ANode.FirstChild<>nil) then begin
    AddDefineNodes(ANode.FirstChild,NewTreeNode,true,true);
  end;
  if WithNextSiblings and (ANode.Next<>nil) then begin
    AddDefineNodes(ANode.Next,AParent,WithChilds,true);
  end;
  DefineTreeView.Items.EndUpdate;
end;

procedure TCodeToolsDefinesEditor.SetNodeImages(ANode: TTreeNode;
  WithSubNodes: boolean);
var ADefineTemplate: TDefineTemplate;
begin
  ADefineTemplate:=TDefineTemplate(ANode.Data);
  case ADefineTemplate.Action of
    da_Define: ANode.ImageIndex:=0;
    da_DefineRecurse: ANode.ImageIndex:=1;
    da_Undefine: ANode.ImageIndex:=2;
    da_UndefineRecurse: ANode.ImageIndex:=3;
    da_UndefineAll: ANode.ImageIndex:=4;
    da_Block: ANode.ImageIndex:=5;
    da_Directory: ANode.ImageIndex:=6;
    da_If: ANode.ImageIndex:=7;
    da_IfDef: ANode.ImageIndex:=8;
    da_IfNDef: ANode.ImageIndex:=9;
    da_ElseIf: ANode.ImageIndex:=10;
    da_Else: ANode.ImageIndex:=11;
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

procedure TCodeToolsDefinesEditor.SetTransferMacros(
  const AValue: TTransferMacroList);
begin
  FTransferMacros:=AValue;
end;

procedure TCodeToolsDefinesEditor.ValueAsPathToValueAsText;
var s: string;
  i, j, l: integer;
begin
  s:=ValueAsFilePathsSynEdit.Text;
  l:=length(s);
  // replace line ends with semicolon
  i:=1;
  j:=1;
  while i<=l do begin
    if s[i] in [#10,#13] then begin
      inc(i);
      if (i<l) and (s[i] in [#10,#13]) and (s[i-1]<>s[i]) then begin
        inc(i);
      end;
      s[j]:=';';
      inc(j);
    end else begin
      s[j]:=s[i];
      inc(i);
      inc(j);
    end;
  end;
  dec(j);
  while (j>=1) and (s[j]=';') do dec(j);
  SetLength(s,j);
  ValueAsTextSynEdit.Text:=s;
end;

procedure TCodeToolsDefinesEditor.SaveSelectedValues;
var
  ATreeNode: TTreeNode;
  ADefNode: TDefineTemplate;
  s: string;
  l: integer;
begin
  ATreeNode:=FLastSelectedNode;
  if (ATreeNode<>nil) then begin
    ADefNode:=TDefineTemplate(ATreeNode.Data);
    if (not ADefNode.IsAutoGenerated) then begin
      ADefNode.Name:=NameEdit.Text;
      ATreeNode.Text:=ADefNode.Name;
      ADefNode.Variable:=VariableEdit.Text;
      ADefNode.Description:=DescriptionEdit.Text;
      if ValueNoteBook.PageIndex=1 then
        ValueAsPathToValueAsText;
      s:=ValueAsTextSynEdit.Text;
      l:=length(s);
      if (l>0) and (s[l] in [#13,#10]) then begin
        // remove line end at end of Text, that was added automatically
        dec(l);
        if (l>0) and (s[l] in [#13,#10]) and (s[l]<>s[l+1]) then
          dec(l);
        SetLength(s,l);
      end;
      ADefNode.Value:=s;
    end;
    FLastSelectedNode:=nil;
  end;
end;

procedure TCodeToolsDefinesEditor.ShowSelectedValues;
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
begin
  SelTreeNode:=DefineTreeView.Selected;
  if SelTreeNode<>FLastSelectedNode then begin
    SaveSelectedValues;
  end;
  if SelTreeNode<>nil then begin
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    SetValuesEditable(not SelDefNode.IsAutoGenerated);
    NameEdit.Text:=SelDefNode.Name;
    DescriptionEdit.Text:=SelDefNode.Description;
    VariableEdit.Text:=SelDefNode.Variable;
    ValueAsTextSynEdit.Text:=SelDefNode.Value;
    ValueAsFilePathsSynEdit.Text:=ValueToFilePathText(SelDefNode.Value);
    if SelDefNode.IsAutoGenerated then begin
      //ValueAsTextSynEdit.Options:=ValueAsTextSynEdit.Options+[eoNoCaret];
      ValueAsTextSynEdit.ReadOnly:=true;
    end else begin
      //ValueAsTextSynEdit.Options:=ValueAsTextSynEdit.Options-[eoNoCaret];
      ValueAsTextSynEdit.ReadOnly:=false;
    end;
    ValueAsFilePathsSynEdit.Options:=ValueAsTextSynEdit.Options;
    ValueAsFilePathsSynEdit.ReadOnly:=ValueAsTextSynEdit.ReadOnly;
  end else begin
    SetValuesEditable(false);
    NameEdit.Text:='';
    DescriptionEdit.Text:='';
    VariableEdit.Text:='';
    ValueAsTextSynEdit.Text:='';
    ValueAsFilePathsSynEdit.Text:='';
  end;
  SetTypeLabel;
  FLastSelectedNode:=SelTreeNode;
end;

procedure TCodeToolsDefinesEditor.SetTypeLabel;
var
  SelTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
  s: string;
begin
  SelTreeNode:=DefineTreeView.Selected;
  if SelTreeNode<>nil then begin
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    s:=Format(lisCodeToolsDefsAction, [DefineActionNames[SelDefNode.Action]]);
    if SelDefNode.IsAutoGenerated then
      s:=Format(lisCodeToolsDefsautoGenerated, [s]);
  end else begin
    s:=lisCodeToolsDefsnoneSelected;
  end;
  TypeLabel.Caption:=s;
end;

function TCodeToolsDefinesEditor.ValueToFilePathText(const AValue: string
  ): string;
var i: integer;
begin
  Result:=AValue;
  for i:=1 to length(Result) do
    if Result[i]=';' then Result[i]:=#13;
end;

procedure TCodeToolsDefinesEditor.InsertNewNode(Behind: boolean;
  DefAction: TDefineAction);
var SelTreeNode, NodeInFront, ParentNode,
  NewTreeNode: TTreeNode;
  NewDefNode: TDefineTemplate;
  NewName, NewDescription, NewVariable, NewValue: string;
begin
  SelTreeNode:=DefineTreeView.Selected;
  SaveSelectedValues;
  NodeInFront:=nil;
  ParentNode:=nil;
  if SelTreeNode<>nil then begin
    // there is an selected node
    if Behind then begin
      // insert behind selected node
      NodeInFront:=SelTreeNode;
      ParentNode:=NodeInFront.Parent;
    end else begin
      // insert as last child of selected node
      ParentNode:=SelTreeNode;
      NodeInFront:=ParentNode.GetFirstChild;
      if NodeInFront<>nil then begin
        while NodeInFront.GetNextSibling<>nil do
          NodeInFront:=NodeInFront.GetNextSibling;
      end;
    end;
  end else begin
    // no node selected, add as last root node
    NodeInFront:=DefineTreeView.Items.GetLastNode;
  end;
  if (ParentNode<>nil) and (TDefineTemplate(ParentNode.Data).IsAutoGenerated)
  then begin
    MessageDlg(lisCodeToolsDefsInvalidParent, Format(
      lisCodeToolsDefsAutoCreatedNodesReadOnly, [#13]), mtInformation,
      [mbCancel],0);
    exit;
  end;
  if (ParentNode<>nil)
  and (not (TDefineTemplate(ParentNode.Data).Action in DefineActionBlocks)) then
  begin
    MessageDlg(lisCodeToolsDefsInvalidParentNode,
      lisCodeToolsDefsParentNodeCanNotContainCh,
      mtInformation,[mbCancel],0);
    exit;
  end;
  NewName:=FindUniqueName;
  NewDescription:=NewName;
  NewVariable:='';
  NewValue:='';
  NewDefNode:=TDefineTemplate.Create(NewName,NewDescription,NewVariable,
                                     NewValue,DefAction);
  NewDefNode.Owner:=CodeToolsOpts;
  // add node to treeview
  if (NodeInFront<>nil) then
    // insert in front
    NewTreeNode:=DefineTreeView.Items.InsertObjectBehind(
                  NodeInFront,NewName,NewDefNode)
  else
    // add as last child
    NewTreeNode:=DefineTreeView.Items.AddChildObject(ParentNode,NewName,
                                                     NewDefNode);

  // add node to define tree
  if NodeInFront<>nil then
    NewDefNode.InsertBehind(TDefineTemplate(NodeInFront.Data))
  else if ParentNode<>nil then
    TDefineTemplate(ParentNode.Data).AddChild(NewDefNode)
  else
    FDefineTree.Add(NewDefNode);

  SetNodeImages(NewTreeNode,true);
  DefineTreeView.Selected:=NewTreeNode;
  ShowSelectedValues;
end;

procedure TCodeToolsDefinesEditor.InsertTemplate(NewTemplate: TDefineTemplate);

  procedure AddChilds(ATreeNode: TTreeNode);
  var ADefNode, ChildDefNode: TDefineTemplate;
    ChildTreeNode: TTreeNode;
  begin
    if ATreeNode=nil then exit;
    ADefNode:=TDefineTemplate(ATreeNode.Data);
    ChildDefNode:=ADefNode.FirstChild;
    while ChildDefNode<>nil do begin
      ChildTreeNode:=DefineTreeView.Items.AddChildObject(ATreeNode,
                                                ChildDefNode.Name,ChildDefNode);
      AddChilds(ChildTreeNode);
      ChildDefNode:=ChildDefNode.Next;
    end;
  end;

var
  SelTreeNode, NewTreeNode: TTreeNode;
  SelDefNode: TDefineTemplate;
begin
  SaveSelectedValues;
  if NewTemplate=nil then exit;
  NewTemplate.RemoveFlags([dtfAutoGenerated]);
  FLastSelectedNode:=nil;
  SelTreeNode:=DefineTreeView.Selected;
  if SelTreeNode<>nil then begin
    // insert behind selected node
    SelDefNode:=TDefineTemplate(SelTreeNode.Data);
    // insert in TreeView
    NewTreeNode:=DefineTreeView.Items.InsertObjectBehind(SelTreeNode,
                           NewTemplate.Name,NewTemplate);
    // insert in DefineTree
    NewTemplate.InsertBehind(SelDefNode);
  end else begin
    // add as last root node
    // add in TreeView
    NewTreeNode:=DefineTreeView.Items.AddObject(nil,NewTemplate.Name,NewTemplate);
    // add in DefineTree
    DefineTree.Add(NewTemplate);
  end;
  // add childs to TreeView
  AddChilds(NewTreeNode);
  // show and select
  SetNodeImages(NewTreeNode,true);
  NewTreeNode.Selected:=true;
  ShowSelectedValues;
end;

function TCodeToolsDefinesEditor.FindUniqueName: string;
var i: integer;
begin
  i:=1;
  while (DefineTree.FindDefineTemplateByName(lisCodeToolsDefsNewNode+IntToStr(i
    ), false)<>nil)
  do inc(i);
  Result:=lisCodeToolsDefsNewNode+IntToStr(i);
end;

function TCodeToolsDefinesEditor.ConsistencyCheck: integer;

  function CheckNode(ATreeNode: TTreeNode): integer;
  var ADefNode, DummyDefNode: TDefineTemplate;
  begin
    if ATreeNode=nil then exit;
    ADefNode:=TDefineTemplate(ATreeNode.Data);
//writeln(' CheckNode "',ATreeNode.Text,'" "',ADefNode.Name,'"');
    if ADefNode=nil then begin
      Result:=-1;  exit;
    end;
    if (ATreeNode.GetPrevSibling<>nil)
    and (TDefineTemplate(ATreeNode.GetPrevSibling.Data)<>ADefNode.Prior) then
    begin
      Result:=-2;  exit;
    end;
    if (ATreeNode.GetNextSibling<>nil)
    and (TDefineTemplate(ATreeNode.GetNextSibling.Data)<>ADefNode.Next) then
    begin
      DbgOut(' ERROR: ',ATreeNode.GetNextSibling.Text,' ');
      if ADefNode.Next<>nil then DbgOut('ADefNode.Next=',ADefNode.Next.Name,' ')
      else DbgOut('ADefNode.Next=nil ');
      DummyDefNode:=TDefineTemplate(ATreeNode.GetNextSibling.Data);
      if DummyDefNode<>nil then
        DebugLn('ATreeNode.GetNextSibling.Next=',DummyDefNode.Name)
      else
        DebugLn('ATreeNode.GetNextSibling.Next=nil');
{writeln('=============================================');
DefineTreeView.WriteDebugReport('TV ',true);
writeln('=============================================');
DefineTree.WriteDebugReport;
writeln('=============================================');}
      Result:=-3;  exit;
    end;
    if (ATreeNode.GetFirstChild<>nil)
    and (TDefineTemplate(ATreeNode.GetFirstChild.Data)<>ADefNode.FirstChild)
    then begin
      Result:=-4;  exit;
    end;
    Result:=CheckNode(ATreeNode.GetFirstChild);
    if Result<0 then exit;
    Result:=CheckNode(ATreeNode.GetNextSibling);
    if Result<0 then exit;
  end;

begin
  DefineTreeView.ConsistencyCheck;
  DefineTree.ConsistencyCheck;
  Result:=CheckNode(DefineTreeView.Items.GetFirstNode);
  if Result<0 then begin
    dec(Result,300000);
    exit;
  end;
  Result:=0;
end;

procedure TCodeToolsDefinesEditor.SetValuesEditable(AValue: boolean);
begin
  SelectedItemGroupBox.Enabled:=true;
  TypeLabel.Enabled:=true;
  NameLabel.Enabled:=AValue;
  NameEdit.Enabled:=AValue;
  DescriptionLabel.Enabled:=AValue;
  DescriptionEdit.Enabled:=AValue;
  VariableLabel.Enabled:=AValue;
  VariableEdit.Enabled:=AValue;
  ValueAsTextSynEdit.ReadOnly:=not AValue;
  ValueAsFilePathsSynEdit.ReadOnly:=not AValue;
  MoveFilePathUpBitBtn.Enabled:=AValue;
  MoveFilePathDownBitBtn.Enabled:=AValue;
  DeleteFilePathBitBtn.Enabled:=AValue;
  InsertFilePathBitBtn.Enabled:=AValue;
end;

procedure TCodeToolsDefinesEditor.SetOptions(ACodeToolBoss: TCodeToolManager;
  Options: TCodeToolsOptions);
begin
  FLastSelectedNode:=nil;
  FBoss:=ACodeToolBoss;
  FDefineTree.Assign(ACodeToolBoss.DefineTree);
  RebuildDefineTreeView;
  ShowSelectedValues;
end;

constructor TCodeToolsDefinesEditor.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Position:=poScreenCenter;
  IDEDialogLayoutList.ApplyLayout(Self,500,460);

  if LazarusResources.Find(ClassName)=nil then begin
    Caption:=lisCodeToolsDefsCodeToolsDefinesEditor;
    OnResize:=@FormResize;
    OnKeyDown:=@CodeToolsDefinesEditorKeyDown;
    
    CreateComponents;
  end;
  FDefineTree:=TDefineTree.Create;
  FormResize(Self);
end;

destructor TCodeToolsDefinesEditor.Destroy;
begin
  FDefineTree.Free;
  inherited Destroy;
end;

//==============================================================================

initialization
  {$I codetoolsdefines.lrs}


end.
