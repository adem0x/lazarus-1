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
    Dialog and functions to change encodings (e.g. UTF-8) of projects and
    packages.
}
unit ChgEncodingDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, FileProcs, Forms, Controls, Graphics,
  Dialogs, LConvEncoding, ExtCtrls, StdCtrls, ComCtrls, Buttons,
  IDEWindowIntf, SynRegExpr, SrcEditorIntf, IDEHelpIntf,
  CodeCache, CodeToolsStructs, CodeToolManager, AVL_Tree,
  // IDE
  IDEProcs, CodeBrowser, PackageDefs, PackageSystem, Project,
  LazarusIDEStrConsts;

type

  { TChgEncodingDialog }

  TChgEncodingDialog = class(TForm)
    ApplyButton: TBitBtn;
    HelpButton: TBitBtn;
    BtnPanel: TPanel;
    CloseButton: TBitBtn;
    NewEncodingComboBox: TComboBox;
    FileFilterCombobox: TComboBox;
    NewEncodingLabel: TLabel;
    PreviewListView: TListView;
    PreviewGroupBox: TGroupBox;
    OwnerComboBox: TComboBox;
    ScopeGroupBox: TGroupBox;
    RegExprCheckBox: TCheckBox;
    FileFilterLabel: TLabel;
    NonUTF8FilesCheckBox: TCheckBox;
    UTF8FilesCheckBox: TCheckBox;
    FilesGroupBox: TGroupBox;
    procedure ApplyButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
    procedure PreviewClick(Sender: TObject);
  private
    FFiles: TFilenameToStringTree;
    function GetFiles: Boolean;
    procedure UpdatePreview;
  public
  end;

function ShowConvertEncodingDlg: TModalResult;

implementation

{$R *.lfm}

function ShowConvertEncodingDlg: TModalResult;
var
  ChgEncodingDialog: TChgEncodingDialog;
begin
  ChgEncodingDialog:=TChgEncodingDialog.Create(nil);
  Result:=ChgEncodingDialog.ShowModal;
  ChgEncodingDialog.Free;
end;

{ TChgEncodingDialog }

procedure TChgEncodingDialog.FormCreate(Sender: TObject);
var
  List: TStringList;
  Encoding: string;
  i: Integer;
begin
  IDEDialogLayoutList.ApplyLayout(Self);

  Caption:=lisConvertEncoding;

  ScopeGroupBox.Caption:=lisConvertProjectOrPackage;
  NewEncodingLabel.Caption:=lisNewEncoding;
  FilesGroupBox.Caption:=lisFileFilter;
  UTF8FilesCheckBox.Caption:=lisFilesInASCIIOrUTF8Encoding;
  NonUTF8FilesCheckBox.Caption:=lisFilesNotInASCIINorUTF8Encoding;
  FileFilterLabel.Caption:=lisFilter;
  RegExprCheckBox.Caption:=lisRegularExpression;

  CloseButton.Caption:=lisClose;
  ApplyButton.Caption:=lisConvert;
  HelpButton.Caption:=lisHelp;
  CloseButton.LoadGlyphFromResourceName(hInstance, 'btn_close');
  ApplyButton.LoadGlyphFromResourceName(hInstance, 'btn_ok');
  HelpButton.LoadGlyphFromResourceName(hInstance, 'btn_help');

  PreviewGroupBox.Caption:=dlgWRDPreview;
  PreviewListView.Column[0].Caption:=dlgEnvFiles;
  PreviewListView.Column[0].Width:=350;
  PreviewListView.Column[1].Caption:=uemEncoding;

  // get possible encodings
  List:=TStringList.Create;
  GetSupportedEncodings(List);
  for i:=List.Count-1 downto 0 do begin
    Encoding:=List[i];
    if (Encoding='') or (SysUtils.CompareText(Encoding,EncodingAnsi)=0) then
      List.Delete(i);
  end;
  List.Sort;
  NewEncodingComboBox.Items.Assign(List);
  List.Free;
  NewEncodingComboBox.Text:='UTF-8';

  // get possible filters
  List:=TStringList.Create;
  List.Add('*.pas;*.pp;*.p;*.inc;*.lpr;*.lfm;*.lrs;*.txt');
  List.Sort;
  FileFilterCombobox.Items.Assign(List);
  List.Free;
  FileFilterCombobox.Text:=FileFilterCombobox.Items[0];

  // get possible projects and packages
  List:=TStringList.Create;
  for i:=0 to PackageGraph.Count-1 do
    if (List.IndexOf(PackageGraph[i].Name)<0)
    and (not PackageGraph[i].ReadOnly)
    and (not PackageGraph[i].IsVirtual)
    then
      List.Add(PackageGraph[i].Name);
  List.Sort;
  if not Project1.IsVirtual then
    List.Insert(0,lisEdtDefCurrentProject);
  OwnerComboBox.Items.Assign(List);
  List.Free;
  if OwnerComboBox.Items.Count>0 then
    OwnerComboBox.Text:=OwnerComboBox.Items[0]
  else
    OwnerComboBox.Text:='';
  FFiles:=TFilenameToStringTree.Create(FilenamesCaseSensitive);
  UpdatePreview;
end;

procedure TChgEncodingDialog.FormDestroy(Sender: TObject);
begin
  IDEDialogLayoutList.SaveLayout(Self);
  FFiles.Free;
end;

procedure TChgEncodingDialog.ApplyButtonClick(Sender: TObject);
var
  Buf: TCodeBuffer;
  SrcEdit: TSourceEditorInterface;
  Encoding, OldEncoding, NewEncoding: String;
  Node: TAVLTreeNode;
  Item: PStringToStringTreeItem;
  Filename: String;
  HasChanged: boolean;
  li: TListItem;
begin
  NewEncoding:=NormalizeEncoding(NewEncodingComboBox.Text);
  PreviewListView.BeginUpdate;
  PreviewListView.Items.Clear;
  Node:=FFiles.Tree.FindLowest;
  while Node<>nil do begin
    Item:=PStringToStringTreeItem(Node.Data);
    Filename:=Item^.Name;
    Encoding:=Item^.Value;
    DebugLn(['TChgEncodingDialog.ApplyButtonClick Filename=',Filename,' Encoding=',Encoding]);
    Buf:=CodeToolBoss.LoadFile(Filename,true,false);
    if (Buf<>nil) and (not Buf.ReadOnly) then begin
      OldEncoding:=Buf.DiskEncoding;
      SrcEdit:=SourceEditorManagerIntf.SourceEditorIntfWithFilename(Filename);
      HasChanged:=true;
      if SrcEdit<>nil then begin
        DebugLn(['TChgEncodingDialog.ApplyButtonClick changing in source editor: ',Filename]);
        Buf.DiskEncoding:=NewEncoding;
        SrcEdit.Modified:=true;
      end else begin
        DebugLn(['TChgEncodingDialog.ApplyButtonClick changing on disk: ',Filename]);
//        Buf:=CodeToolBoss.LoadFile(Filename,true,false);
        Buf.DiskEncoding:=NewEncoding;
        HasChanged:=Buf.Save;
        if not HasChanged then
          Buf.DiskEncoding:=OldEncoding;
      end;
    end;
    if not HasChanged then begin
      li:=PreviewListView.Items.Add;
      li.Caption:=Filename;
      li.SubItems.Add(Encoding);
    end;
    Node:=FFiles.Tree.FindSuccessor(Node);
  end;
  PreviewListView.EndUpdate;
  PreviewGroupBox.Caption:='Number of files failed to convert: '+IntToStr(PreviewListView.Items.Count);
end;

procedure TChgEncodingDialog.HelpButtonClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TChgEncodingDialog.PreviewClick(Sender: TObject);
begin
  UpdatePreview;
end;

function TChgEncodingDialog.GetFiles: Boolean;
// Returns true if some files were found, even if they were not added to list.
var
  AProject: TProject;
  SearchPath: String;
  APackage: TLazPackage;
  Dir: String;
  FileInfo: TSearchRec;
  CurFilename: String;
  Buf: TCodeBuffer;
  CurEncoding, NewEncoding: String;
  IncludeFilterRegExpr: TRegExpr;
  CurOwner: TObject;
  Expr: String;
  ok: Boolean;
  p: Integer;
begin
  FFiles.Clear;
  Result:=False;
  // check owner
  if OwnerComboBox.Text=lisEdtDefCurrentProject then
    CurOwner:=Project1
  else
    CurOwner:=PackageGraph.FindPackageWithName(OwnerComboBox.Text,nil);
  if CurOwner=nil then begin
    DebugLn(['TChgEncodingDialog.UpdatePreview package not found: ',OwnerComboBox.Text]);
    exit;
  end;

  // find search paths
  if CurOwner is TProject then begin
    AProject:=TProject(CurOwner);
    SearchPath:=AProject.SourceDirectories.CreateSearchPathFromAllFiles;
    SearchPath:=MergeSearchPaths(SearchPath,AProject.CompilerOptions.GetIncludePath(false));
  end else begin
    APackage:=TLazPackage(CurOwner);
    SearchPath:=APackage.SourceDirectories.CreateSearchPathFromAllFiles;
    SearchPath:=MergeSearchPaths(SearchPath,APackage.CompilerOptions.GetIncludePath(false));
  end;

  // find files
  IncludeFilterRegExpr:=TRegExpr.Create;
  try
    Expr:=FileFilterCombobox.Text;
    if not RegExprCheckBox.Checked then
      Expr:=SimpleSyntaxToRegExpr(Expr);
    ok:=false;
    try
      IncludeFilterRegExpr.Expression:=Expr;
      ok:=true;
    except
      on E: Exception do begin
        DebugLn('Invalid Include File Expression ',Expr,' ',E.Message);
        MessageDlg('Error in regular expression',
          E.Message,mtError,[mbCancel],0);
      end;
    end;
    if not ok then exit;

    NewEncoding:=NormalizeEncoding(NewEncodingComboBox.Text);
    p:=1;
    while (p<=length(SearchPath)) do begin
      Dir:=GetNextDirectoryInSearchPath(SearchPath,p);
      if Dir='' then continue;
      Dir:=AppendPathDelim(Dir);
      DebugLn(['TChgEncodingDialog.GetFiles Dir=',Dir]);
      if FindFirstUTF8(Dir+FileMask,faAnyFile,FileInfo)=0 then
      try
        repeat
          // check if special file
          if (FileInfo.Name='.') or (FileInfo.Name='..') or (FileInfo.Name='') then
            continue;
          CurFilename:=Dir+FileInfo.Name;
          if FFiles.Contains(CurFilename) then
            continue;
          if not IncludeFilterRegExpr.Exec(CurFilename) then
            continue;
          if not FileIsTextCached(CurFilename) then
            continue;

          if (FileInfo.Attr and faDirectory)>0 then begin
            // skip directory
          end else begin
            Buf:=CodeToolBoss.LoadFile(CurFilename,true,false);
            if Buf<>nil then begin
              //DebugLn(['TChgEncodingDialog.GetFiles Filename=',CurFilename,' Encoding=',NormalizeEncoding(Buf.DiskEncoding)]);
              CurEncoding:=NormalizeEncoding(Buf.DiskEncoding);
              Result:=True;
              if CurEncoding=NewEncoding then
                continue;
              if (CurEncoding=EncodingUTF8) and (not UTF8FilesCheckBox.Checked) then
                continue;
              if (CurEncoding<>EncodingUTF8) and (not NonUTF8FilesCheckBox.Checked) then
                continue;
              FFiles[CurFilename]:=Buf.DiskEncoding;
            end else begin
              DebugLn(['TChgEncodingDialog.UpdatePreview read error: ',CurFilename]);
            end;
          end;
        until FindNextUTF8(FileInfo)<>0;
      finally
        FindCloseUTF8(FileInfo);
      end;
    end;
  finally
    IncludeFilterRegExpr.Free;
  end;
end;

procedure TChgEncodingDialog.UpdatePreview;
var
  Node: TAVLTreeNode;
  Item: PStringToStringTreeItem;
  Filename: String;
  Encoding: String;
  li: TListItem;
  HasFiles: Boolean;
begin
  Screen.Cursor:=crHourGlass;
  try
    HasFiles:=GetFiles;
    PreviewListView.Items.Clear;
    if HasFiles and (FFiles.Tree.Count=0) then begin
      li:=PreviewListView.Items.Add;
      li.Caption:=lisFilesHaveRightEncoding;
      ApplyButton.Enabled:=False;
      exit;
    end;
    PreviewListView.BeginUpdate;
    Node:=FFiles.Tree.FindLowest;
    while Node<>nil do begin
      Item:=PStringToStringTreeItem(Node.Data);
      Filename:=Item^.Name;
      Encoding:=Item^.Value;
      DebugLn(['TChgEncodingDialog.UpdatePreview Filename=',Filename,' Encoding=',Encoding]);
      li:=PreviewListView.Items.Add;
      li.Caption:=Filename;
      li.SubItems.Add(Encoding);
      Node:=FFiles.Tree.FindSuccessor(Node);
    end;
    PreviewListView.EndUpdate;
    PreviewGroupBox.Caption:=
      Format(lisNumberOfFilesToConvert, [IntToStr(PreviewListView.Items.Count)]);
    ApplyButton.Enabled:=True;
  finally
    Screen.Cursor:=crDefault;
  end;
end;

end.

