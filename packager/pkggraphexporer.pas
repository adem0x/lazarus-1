{  $Id$  }
{
 /***************************************************************************
                            pkggraphexplorer.pas
                            --------------------


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
    TPkgGraphExplorer is the IDE window showing the whole package graph.
}
unit PkgGraphExporer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, LResources, Forms, Controls, Buttons, ComCtrls,
  StdCtrls, ExtCtrls, Menus, Dialogs, Graphics, FileCtrl, AVL_Tree,
  LazarusIDEStrConsts, IDEProcs, IDEOptionDefs, EnvironmentOpts,
  Project, BrokenDependenciesDlg, PackageDefs, PackageSystem, PackageEditor;
  
type
  TPkgGraphExplorer = class(TForm)
    ImageList: TImageList;
    PkgTreeLabel: TLabel;
    PkgTreeView: TTreeView;
    PkgListLabel: TLabel;
    PkgListBox: TListBox;
    InfoMemo: TMemo;
    procedure PackageGraphBeginUpdate(Sender: TObject);
    procedure PkgGraphExplorerEndUpdate(Sender: TObject);
    procedure PkgGraphExplorerResize(Sender: TObject);
    procedure PkgGraphExplorerShow(Sender: TObject);
    procedure PkgListBoxClick(Sender: TObject);
    procedure PkgTreeViewDblClick(Sender: TObject);
    procedure PkgTreeViewExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure PkgTreeViewSelectionChanged(Sender: TObject);
  private
    FOnOpenPackage: TOnOpenPackage;
    fSortedPackages: TAVLTree;
    FChangedDuringLock: boolean;
    FUpdateLock: integer;
    procedure SetupComponents;
    function GetPackageImageIndex(Pkg: TLazPackage): integer;
    procedure GetDependency(ANode: TTreeNode; var Pkg: TLazPackage;
      var Dependency: TPkgDependency);
    procedure GetCurrentIsUsedBy(var Dependency: TPkgDependency);
    function SearchParentNodeWithText(ANode: TTreeNode;
      const NodeText: string): TTreeNode;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsUpdating: boolean;
    procedure UpdateAll;
    procedure UpdateTree;
    procedure UpdateList;
    procedure UpdateInfo;
    procedure UpdatePackageName(Pkg: TLazPackage; const OldName: string);
    procedure UpdatePackageID(Pkg: TLazPackage);
    procedure UpdatePackageAdded(Pkg: TLazPackage);
    procedure SelectPackage(Pkg: TLazPackage);
    function FindMainNodeWithText(const s: string): TTreeNode;
  public
    property OnOpenPackage: TOnOpenPackage read FOnOpenPackage write FOnOpenPackage;
  end;
  
var
  PackageGraphExplorer: TPkgGraphExplorer;

implementation

uses Math;

var
  ImgIndexPackage,
  ImgIndexInstallPackage,
  ImgIndexUninstallPackage,
  ImgIndexCirclePackage,
  ImgIndexMissingPackage: integer;


{ TPkgGraphExplorer }

procedure TPkgGraphExplorer.PkgGraphExplorerResize(Sender: TObject);
var
  x: Integer;
  y: Integer;
  w: Integer;
begin
  x:=1;
  y:=1;
  w:=((ClientWidth-3*x) div 2);
  with PkgTreeLabel do
    SetBounds(x,y,w,Height);
  inc(x,PkgTreeLabel.Width+PkgTreeLabel.Left);
  
  with PkgListLabel do
    SetBounds(x,y,w,Height);
  x:=1;
  inc(y,PkgTreeLabel.Height+3);

  with PkgTreeView do
    SetBounds(x,y,w,Max(Parent.ClientHeight-y-80,10));
  inc(x,PkgTreeView.Width+PkgTreeView.Left);

  with PkgListBox do
    SetBounds(x,y,w,PkgTreeView.Height);
  x:=1;
  inc(y,PkgTreeView.Height+1);
  
  with InfoMemo do
    SetBounds(x,y,Parent.ClientWidth-2*x,Max(10,Parent.ClientHeight-y-x));
end;

procedure TPkgGraphExplorer.PackageGraphBeginUpdate(Sender: TObject);
begin
  BeginUpdate;
end;

procedure TPkgGraphExplorer.PkgGraphExplorerEndUpdate(Sender: TObject);
begin
  EndUpdate;
end;

procedure TPkgGraphExplorer.PkgGraphExplorerShow(Sender: TObject);
begin
  UpdateAll;
end;

procedure TPkgGraphExplorer.PkgListBoxClick(Sender: TObject);
var
  Dependency: TPkgDependency;
begin
  GetCurrentIsUsedBy(Dependency);
  if (Dependency=nil) or (Dependency.Owner=nil) then begin
    PkgListBox.ItemIndex:=-1;
    exit;
  end;
  if Dependency.Owner is TLazPackage then begin
    SelectPackage(TLazPackage(Dependency.Owner));
  end;
end;

procedure TPkgGraphExplorer.PkgTreeViewDblClick(Sender: TObject);
var
  Pkg: TLazPackage;
  Dependency: TPkgDependency;
begin
  GetDependency(PkgTreeView.Selected,Pkg,Dependency);
  if Pkg<>nil then begin
    if Assigned(OnOpenPackage) then
      OnOpenPackage(Self,Pkg);
  end;
end;

procedure TPkgGraphExplorer.PkgTreeViewExpanding(Sender: TObject;
  Node: TTreeNode; var AllowExpansion: Boolean);
var
  Pkg, ChildPackage: TLazPackage;
  Dependency: TPkgDependency;
  ViewNode: TTreeNode;
  NodeText: String;
  NodeImgIndex: Integer;
  NextViewNode: TTreeNode;
begin
  // add child nodes
  GetDependency(Node,Pkg,Dependency);
  if Dependency<>nil then begin
    // node is a not fullfilled dependency
    AllowExpansion:=false;
  end else begin
    // node is a package
    ViewNode:=Node.GetFirstChild;
    Dependency:=Pkg.FirstRequiredDependency;
    while Dependency<>nil do begin
      // find required package
      if PackageGraph.OpenDependency(Dependency,ChildPackage)=lprSuccess then
      begin
        // package found
        NodeText:=ChildPackage.IDAsString;
        if SearchParentNodeWithText(Node,NodeText)<>nil then
          NodeImgIndex:=ImgIndexCirclePackage
        else
          NodeImgIndex:=GetPackageImageIndex(ChildPackage);
      end else begin
        // package not found
        NodeText:=Dependency.AsString;
        NodeImgIndex:=ImgIndexMissingPackage;
        // Todo broken packages
      end;
      // add node
      if ViewNode=nil then
        ViewNode:=PkgTreeView.Items.AddChild(Node,NodeText)
      else
        ViewNode.Text:=NodeText;
      ViewNode.ImageIndex:=NodeImgIndex;
      ViewNode.SelectedIndex:=ViewNode.ImageIndex;
      ViewNode.Expanded:=false;
      ViewNode.HasChildren:=
            (ChildPackage<>nil) and (ChildPackage.FirstRequiredDependency<>nil);
      ViewNode:=ViewNode.GetNextSibling;
      Dependency:=Dependency.NextRequiresDependency;
    end;
    // delete unneeded nodes
    while ViewNode<>nil do begin
      NextViewNode:=ViewNode.GetNextSibling;
      ViewNode.Free;
      ViewNode:=NextViewNode;
    end;
  end;
end;

procedure TPkgGraphExplorer.PkgTreeViewSelectionChanged(Sender: TObject);
begin
  UpdateInfo;
  UpdateList;
end;

procedure TPkgGraphExplorer.SetupComponents;

  procedure AddResImg(const ResName: string);
  var Pixmap: TPixmap;
  begin
    Pixmap:=TPixmap.Create;
    Pixmap.TransparentColor:=clWhite;
    Pixmap.LoadFromLazarusResource(ResName);
    ImageList.Add(Pixmap,nil)
  end;

begin
  ImageList:=TImageList.Create(Self);
  with ImageList do begin
    Width:=17;
    Height:=17;
    Name:='ImageList';
    ImgIndexPackage:=Count;
    AddResImg('pkg_package');
    ImgIndexInstallPackage:=Count;
    AddResImg('pkg_package_installed');
    ImgIndexUninstallPackage:=Count;
    AddResImg('pkg_package_uninstall');
    ImgIndexCirclePackage:=Count;
    AddResImg('pkg_package_circle');
    ImgIndexMissingPackage:=Count;
    AddResImg('pkg_conflict');
  end;
  
  PkgTreeLabel:=TLabel.Create(Self);
  with PkgTreeLabel do begin
    Name:='PkgTreeLabel';
    Parent:=Self;
    Caption:='Loaded Packages:';
  end;
  
  PkgTreeView:=TTreeView.Create(Self);
  with PkgTreeView do begin
    Name:='PkgTreeView';
    Parent:=Self;
    Options:=Options+[tvoRightClickSelect];
    Images:=Self.ImageList;
    OnExpanding:=@PkgTreeViewExpanding;
    OnSelectionChanged:=@PkgTreeViewSelectionChanged;
    OnDblClick:=@PkgTreeViewDblClick;
  end;

  PkgListLabel:=TLabel.Create(Self);
  with PkgListLabel do begin
    Name:='PkgListLabel';
    Parent:=Self;
    Caption:='Is required by:';
  end;

  PkgListBox:=TListBox.Create(Self);
  with PkgListBox do begin
    Name:='PkgListBox';
    Parent:=Self;
    OnClick:=@PkgListBoxClick;
  end;

  InfoMemo:=TMemo.Create(Self);
  with InfoMemo do begin
    Name:='InfoMemo';
    Parent:=Self;
  end;
end;

function TPkgGraphExplorer.GetPackageImageIndex(Pkg: TLazPackage): integer;
begin
  if Pkg.Installed<>pitNope then begin
    if Pkg.AutoInstall<>pitNope then begin
      Result:=ImgIndexInstallPackage;
    end else begin
      Result:=ImgIndexUninstallPackage;
    end;
  end else begin
    Result:=ImgIndexPackage;
  end;
end;

procedure TPkgGraphExplorer.GetDependency(ANode: TTreeNode;
  var Pkg: TLazPackage; var Dependency: TPkgDependency);
// if Dependency<>nil then Pkg is the Parent
var
  NodeText: String;
  NodePackageID: TLazPackageID;
begin
  // keep in mind, that packages can be deleted and the node is outdated
  Pkg:=nil;
  Dependency:=nil;
  if ANode=nil then exit;
  NodePackageID:=TLazPackageID.Create;
  try
    // try to find a package
    NodeText:=ANode.Text;
    if NodePackageID.StringToID(NodeText) then
      Pkg:=PackageGraph.FindPackageWithID(NodePackageID);
    if Pkg<>nil then exit;
    // try to find the parent package
    if (ANode.Parent=nil) or (not NodePackageID.StringToID(ANode.Parent.Text))
    then
      exit;
    Pkg:=PackageGraph.FindPackageWithID(NodePackageID);
    if Pkg=nil then exit;
    // there is a parent package -> search the dependency
    Dependency:=Pkg.FirstRequiredDependency;
    while Dependency<>nil do begin
      if Dependency.AsString=NodeText then exit;
      Dependency:=Dependency.NextRequiresDependency;
    end;
  finally
    NodePackageID.Free;
  end;
end;

procedure TPkgGraphExplorer.GetCurrentIsUsedBy(var Dependency: TPkgDependency);
var
  TreePkg: TLazPackage;
  TreeDependency: TPkgDependency;
  ListIndex: Integer;
begin
  Dependency:=nil;
  GetDependency(PkgTreeView.Selected,TreePkg,TreeDependency);
  if (Dependency=nil) and (TreePkg<>nil) then begin
    ListIndex:=PkgListBox.ItemIndex;
    if ListIndex<0 then exit;
    Dependency:=TreePkg.UsedByDepByIndex(ListIndex);
  end;
end;

function TPkgGraphExplorer.SearchParentNodeWithText(ANode: TTreeNode;
  const NodeText: string): TTreeNode;
begin
  Result:=ANode;
  while Result<>nil do begin
    if Result.Text=NodeText then exit;
    Result:=Result.Parent;
  end;
end;

constructor TPkgGraphExplorer.Create(TheOwner: TComponent);
var
  ALayout: TIDEWindowLayout;
begin
  inherited Create(TheOwner);
  fSortedPackages:=TAVLTree.Create(@CompareLazPackageID);
  Name:=NonModalIDEWindowNames[nmiwPkgGraphExplorer];
  Caption:='Package Graph';

  ALayout:=EnvironmentOptions.IDEWindowLayoutList.ItemByFormID(Name);
  ALayout.Form:=TForm(Self);
  ALayout.Apply;
  
  SetupComponents;
  OnResize:=@PkgGraphExplorerResize;
  OnResize(Self);
  OnShow:=@PkgGraphExplorerShow;
  
  PackageGraph.OnBeginUpdate:=@PackageGraphBeginUpdate;
  PackageGraph.OnEndUpdate:=@PkgGraphExplorerEndUpdate;
end;

destructor TPkgGraphExplorer.Destroy;
begin
  FreeAndNil(fSortedPackages);
  inherited Destroy;
end;

procedure TPkgGraphExplorer.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TPkgGraphExplorer.EndUpdate;
begin
  if FUpdateLock<=0 then RaiseException('TPkgGraphExplorer.EndUpdate');
  dec(FUpdateLock);
  if FChangedDuringLock then UpdateAll;
end;

function TPkgGraphExplorer.IsUpdating: boolean;
begin
  Result:=FUpdateLock>0;
end;

procedure TPkgGraphExplorer.UpdateAll;
begin
  if IsUpdating then begin
    FChangedDuringLock:=true;
    exit;
  end;
  FChangedDuringLock:=false;
  UpdateTree;
  UpdateList;
  UpdateInfo;
end;

procedure TPkgGraphExplorer.UpdateTree;
var
  Cnt: Integer;
  i: Integer;
  CurIndex: Integer;
  ViewNode: TTreeNode;
  NextViewNode: TTreeNode;
  HiddenNode: TAVLTreeNode;
  CurPkg: TLazPackage;
begin
  // rebuild internal sorted packages
  fSortedPackages.Clear;
  Cnt:=PackageGraph.Count;
  for i:=0 to Cnt-1 do
    fSortedPackages.Add(PackageGraph[i]);
  // rebuild the TreeView
  PkgTreeView.BeginUpdate;
  CurIndex:=0;
  HiddenNode:=fSortedPackages.FindLowest;
  ViewNode:=PkgTreeView.Items.GetFirstNode;
  while HiddenNode<>nil do begin
    CurPkg:=TLazPackage(HiddenNode.Data);
    if ViewNode=nil then
      ViewNode:=PkgTreeView.Items.Add(nil,CurPkg.IDAsString)
    else
      ViewNode.Text:=CurPkg.IDAsString;
    ViewNode.HasChildren:=CurPkg.FirstRequiredDependency<>nil;
    ViewNode.ImageIndex:=GetPackageImageIndex(CurPkg);
    ViewNode.SelectedIndex:=ViewNode.ImageIndex;
    ViewNode:=ViewNode.GetNextSibling;
    HiddenNode:=fSortedPackages.FindSuccessor(HiddenNode);
    inc(CurIndex);
  end;
  while ViewNode<>nil do begin
    NextViewNode:=ViewNode.GetNextSibling;
    ViewNode.Free;
    ViewNode:=NextViewNode;
  end;
  PkgTreeView.EndUpdate;
end;

procedure TPkgGraphExplorer.UpdateList;
var
  Pkg: TLazPackage;
  Dependency: TPkgDependency;
  UsedByDep: TPkgDependency;
  sl: TStringList;
  NewItem: String;
begin
  GetDependency(PkgTreeView.Selected,Pkg,Dependency);
  if Dependency<>nil then begin
    PkgListBox.Items.Clear;
  end else if Pkg<>nil then begin
    UsedByDep:=Pkg.FirstUsedByDependency;
    sl:=TStringList.Create;
    while UsedByDep<>nil do begin
      NewItem:=GetDependencyOwnerAsString(UsedByDep);
      sl.Add(NewItem);
      UsedByDep:=UsedByDep.NextUsedByDependency;
    end;
    PkgListBox.Items.Assign(sl);
    PkgListBox.ItemIndex:=-1;
    sl.Free;
  end;
end;

procedure TPkgGraphExplorer.UpdateInfo;
var
  Pkg: TLazPackage;
  Dependency: TPkgDependency;
  InfoStr: String;

  procedure AddState(const NewState: string);
  begin
    if (InfoStr<>'') and (InfoStr[length(InfoStr)]<>' ') then
      InfoStr:=InfoStr+', ';
    InfoStr:=InfoStr+NewState;
  end;

begin
  InfoStr:='';
  GetDependency(PkgTreeView.Selected,Pkg,Dependency);
  if Dependency<>nil then begin
    InfoStr:='Package '+Dependency.AsString+' not found';
  end else if Pkg<>nil then begin
    // filename and title
    InfoStr:='Filename:  '+Pkg.Filename;
    // state
    InfoStr:=InfoStr+EndOfLine+'State: ';
    if Pkg.AutoCreated then
      AddState('AutoCreated');
    if Pkg.Installed<>pitNope then
      AddState('Installed');
    if (Pkg.AutoInstall<>pitNope) and (Pkg.Installed=pitNope) then
      AddState('Install on next start');
    if (Pkg.AutoInstall=pitNope) and (Pkg.Installed<>pitNope) then
      AddState('Uninstall on next start');
    InfoStr:=InfoStr+EndOfLine+'Description:  '
                    +BreakString(Pkg.Description,60,length('Description:  '));
  end;
  InfoMemo.Text:=InfoStr;
end;

procedure TPkgGraphExplorer.UpdatePackageName(Pkg: TLazPackage;
  const OldName: string);
begin
  UpdateAll;
end;

procedure TPkgGraphExplorer.UpdatePackageID(Pkg: TLazPackage);
begin
  UpdateAll;
end;

procedure TPkgGraphExplorer.UpdatePackageAdded(Pkg: TLazPackage);
begin
  UpdateAll;
end;

procedure TPkgGraphExplorer.SelectPackage(Pkg: TLazPackage);
var
  NewNode: TTreeNode;
begin
  if Pkg=nil then exit;
  NewNode:=FindMainNodeWithText(Pkg.IDAsString);
  if NewNode<>nil then
    PkgTreeView.Selected:=NewNode;
end;

function TPkgGraphExplorer.FindMainNodeWithText(const s: string): TTreeNode;
begin
  Result:=nil;
  if PkgTreeView.Items.Count=0 then exit;
  Result:=PkgTreeView.Items[0];
  while (Result<>nil) and (Result.Text<>s) do Result:=Result.GetNextSibling;
end;

initialization
  PackageGraphExplorer:=nil;

end.

