{  $Id$  }
{
 /***************************************************************************
                          main.pp  -  Toolbar
                          -------------------
                   TMain is the application toolbar window.


                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}
unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, LclLinux, Compiler, StdCtrls, Forms, Buttons, Menus, ComCtrls, Spin,
  Project, Sysutils, FileCtrl, Controls, Graphics, ExtCtrls, Dialogs, LazConf,
  CompReg, CodeTools, MsgView, NewProjectDlg, IDEComp, AbstractFormEditor,
  FormEditor, CustomFormEditor, ObjectInspector, PropEdits, ControlSelection,
  UnitEditor, CompilerOptions, EditorOptions, EnvironmentOpts, TransferMacros,
  KeyMapping, ProjectOpts, IDEProcs, Process;

const
  Version_String = '0.7 alpha';

type
  TIDEToolStatus = (itNone, itBuilder, itDebugger, itCustom);

  TMainIDE = class(TForm)
    ViewUnitsSpeedBtn  : TSpeedButton;
    ViewFormsSpeedBtn  : TSpeedButton;
    NewUnitSpeedBtn    : TSpeedButton;
    OpenFileSpeedBtn   : TSpeedButton;
    OpenFileArrowSpeedBtn : TSpeedButton;
    SaveSpeedBtn       : TSpeedButton;
    SaveAllSpeedBtn    : TSpeedButton;
    ToggleFormSpeedBtn : TSpeedButton;
    NewFormSpeedBtn    : TSpeedButton;
    RunSpeedButton     : TSpeedButton;
    OpenFilePopUpMenu : TPopupMenu;
    Toolbutton1  : TToolButton;
    Toolbutton2  : TToolButton;
    Toolbutton3  : TToolButton;
    Toolbutton4  : TToolButton;
    GlobalMouseSpeedButton : TSpeedButton;

    ComboBox1 : TComboBox;
    Edit1: TEdit;
    SpinEdit1 : TSpinEdit;
    ListBox1 : TListBox;
    mnuMain: TMainMenu;

    mnuFile: TMenuItem;
    mnuEdit: TMenuItem; 
    mnuSearch: TMenuItem;
    mnuView: TMenuItem; 
    mnuProject: TMenuItem; 
    mnuEnvironment:TMenuItem;

    itmSeperator: TMenuItem;

    itmFileNew : TMenuItem;
    itmFileNewForm : TMenuItem;
    itmFileOpen: TMenuItem;
    itmFileRecentOpen: TMenuItem;
    itmFileSave: TMenuItem; 
    itmFileSaveAs: TMenuItem; 
    itmFileSaveAll: TMenuItem; 
    itmFileClose: TMenuItem; 
    itmFileQuit: TMenuItem; 

    itmProjectNew: TMenuItem;
    itmProjectOpen: TMenuItem;
    itmProjectRecentOpen: TMenuItem;
    itmProjectSave: TMenuItem;
    itmProjectSaveAs: TMenuItem;
    itmProjectAddTo: TMenuItem;
    itmProjectRemoveFrom: TMenuItem;
    itmProjectViewSource: TMenuItem;
    itmProjectBuild: TMenuItem;
    itmProjectRun: TMenuItem;
    itmProjectOptions: TMenuItem;
    itmProjectCompilerSettings: TMenuItem;

    itmEditUndo: TMenuItem; 
    itmEditRedo: TMenuItem; 
    itmEditCut: TMenuItem; 
    itmEditCopy: TMenuItem; 
    itmEditPaste: TMenuItem; 

    itmSearchFind: TMenuItem;
    itmSearchFindAgain: TMenuItem;
    itmSearchReplace: TMenuItem;
    itmGotoLineNumber: TMenuItem;

    itmViewInspector: TMenuItem;
    itmViewProject: TMenuItem; 
    itmViewUnits : TMenuItem;
    itmViewCodeExplorer : TMenuItem;
    itmViewForms : TMenuItem;
    itmViewFile : TMenuItem;
    itmViewMessage : TMenuItem;

    itmEnvGeneralOptions: TMenuItem; 
    itmEnvEditorOptions: TMenuItem; 
    
//    pnlSpeedButtons: TPanel;

    CheckBox1 : TCheckBox; 
    ComponentNotebook : TNotebook;
    cmdTest: TButton;
    cmdTest2: TButton;
    Label2 : TLabel;

    // event handlers
    procedure FormShow(Sender : TObject);
    procedure FormClose(Sender : TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender : TObject; var CanClose: boolean);
    procedure FormPaint(Sender : TObject);

    procedure mnuNewUnitClicked(Sender : TObject);
    procedure mnuNewFormClicked(Sender : TObject);
    procedure mnuOpenClicked(Sender : TObject);
    procedure mnuOpenFileAtCursorClicked(Sender : TObject);
    procedure mnuSaveClicked(Sender : TObject);
    procedure mnuSaveAsClicked(Sender : TObject);
    procedure mnuSaveAllClicked(Sender : TObject);
    procedure mnuCloseClicked(Sender : TObject);
    procedure mnuQuitClicked(Sender : TObject);

    procedure mnuViewInspectorClicked(Sender : TObject);
    Procedure mnuViewUnitsClicked(Sender : TObject);
    Procedure mnuViewFormsClicked(Sender : TObject);

    procedure mnuToggleFormUnitClicked(Sender : TObject);

    procedure mnuNewProjectClicked(Sender : TObject);
    procedure mnuOpenProjectClicked(Sender : TObject);
    procedure mnuSaveProjectClicked(Sender : TObject);
    procedure mnuSaveProjectAsClicked(Sender : TObject);
    procedure mnuAddToProjectClicked(Sender : TObject);
    procedure mnuRemoveFromProjectClicked(Sender : TObject);
    procedure mnuViewProjectSourceClicked(Sender : TObject);
    procedure mnuBuildProjectClicked(Sender : TObject);
    procedure mnuRunProjectClicked(Sender : TObject);
    procedure mnuProjectCompilerSettingsClicked(Sender : TObject);
    procedure mnuProjectOptionsClicked(Sender : TObject);

    procedure mnuViewCodeExplorerClick(Sender : TObject);
    procedure mnuViewMessagesClick(Sender : TObject);
    procedure MessageViewDblClick(Sender : TObject);

    procedure mnuEnvGeneralOptionsClicked(Sender : TObject);
    procedure mnuEnvEditorOptionsClicked(Sender : TObject);

    Procedure OpenFileDownArrowClicked(Sender : TObject);
    Procedure ControlClick(Sender : TObject);

    // SourceNotebook events
    Procedure OnSrcNotebookFileNew(Sender : TObject);
    Procedure OnSrcNotebookFileOpen(Sender : TObject);
    Procedure OnSrcNotebookFileOpenAtCursor(Sender : TObject);
    Procedure OnSrcNotebookFileSave(Sender : TObject);
    Procedure OnSrcNotebookFileSaveAs(Sender : TObject);
    Procedure OnSrcNotebookFileClose(Sender : TObject);
    Procedure OnSrcNotebookSaveAll(Sender : TObject);
    Procedure OnSrcNotebookToggleFormUnit(Sender : TObject);
    Procedure OnSrcNotebookProcessCommand(Sender: TObject; Command: integer;
        var Handled: boolean);

    // ObjectInspector events
    procedure OIOnAddAvailableComponent(AComponent:TComponent;
       var Allowed:boolean);
    procedure OIOnSelectComponent(AComponent:TComponent);

    // Environment options dialog events
    procedure OnLoadEnvironmentSettings(Sender: TObject; 
       TheEnvironmentOptions: TEnvironmentOptions);
    procedure OnSaveEnvironmentSettings(Sender: TObject; 
       TheEnvironmentOptions: TEnvironmentOptions);
  private
    FCodeLastActivated : Boolean; //used for toggling between code and forms
    FSelectedComponent : TRegisteredComponent;
    fProject: TProject;
    MacroList: TTransferMacroList;
    FMessagesViewBoundsRectValid: boolean;

    Function CreateSeperator : TMenuItem;
    Procedure SetDefaultsForForm(aForm : TCustomForm);

  protected
    procedure ToolButtonClick(Sender : TObject);
//    Procedure Paint; override;

  public
    ToolStatus: TIDEToolStatus;
 
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    Function SearchPaths : String;

    // files/units
    function DoNewEditorUnit(NewUnitType:TNewUnitType):TModalResult;
    function DoSaveEditorUnit(PageIndex:integer; SaveAs:boolean):TModalResult;
    function DoCloseEditorUnit(PageIndex:integer;
        SaveFirst: boolean):TModalResult;
    function DoOpenEditorFile(AFileName:string;
        ProjectLoading:boolean):TModalResult;
    function DoOpenFileAtCursor(Sender: TObject):TModalResult;
    function DoSaveAll: TModalResult;
    function DoOpenMainUnit(ProjectLoading: boolean): TModalResult;
    function DoViewUnitsAndForms(OnlyForms: boolean): TModalResult;
    
    // project(s)
    property Project: TProject read fProject write fProject;
    function DoNewProject(NewProjectType:TProjectType):TModalResult;
    function DoSaveProject(SaveAs:boolean):TModalResult;
    function DoCloseProject:TModalResult;
    function DoOpenProjectFile(AFileName:string):TModalResult;
    function DoAddActiveUnitToProject: TModalResult;
    function DoRemoveFromProjectDialog: TModalResult;
    function DoBuildProject: TModalResult;
    function DoRunProject: TModalResult;
    function SomethingOfProjectIsModified: boolean;
    function DoCreateProjectForProgram(ProgramFilename,
       ProgramSource: string): TModalResult;

    // helpful methods
    procedure GetCurrentUnit(var ActiveSourceEditor:TSourceEditor; 
      var ActiveUnitInfo:TUnitInfo);
    procedure GetUnitWithPageIndex(PageIndex:integer; 
      var ActiveSourceEditor:TSourceEditor; var ActiveUnitInfo:TUnitInfo);
    function DoSaveStreamToFile(AStream:TStream; const Filename:string; 
      IsPartOfProject:boolean): TModalResult;
    function DoLoadMemoryStreamFromFile(MemStream: TMemoryStream; 
      const AFilename:string): TModalResult;
    function DoBackupFile(const Filename:string; 
      IsPartOfProject:boolean): TModalResult;
    procedure UpdateCaption;
    procedure UpdateMainUnitSrcEdit;
    procedure DoBringToFrontFormOrUnit;
    procedure OnMacroSubstitution(TheMacro: TTransferMacro; var s:string;
      var Handled, Abort: boolean);
    procedure OnCmdLineCreate(var CmdLine: string; var Abort:boolean);
    function DoJumpToCompilerMessage(Index:integer;
      FocusEditor: boolean): boolean;
    procedure DoShowMessagesView;

    procedure LoadMainMenu;
    procedure LoadSpeedbuttons;
    Procedure SetDesigning(Control : TComponent; Value : Boolean);

    // form editor and designer
    property SelectedComponent : TRegisteredComponent 
      read FSelectedComponent write FSelectedComponent;
    procedure OnDesignerGetSelectedComponentClass(Sender: TObject;
      var RegisteredComponent: TRegisteredComponent);
    procedure OnDesignerUnselectComponentClass(Sender: TObject);
    procedure OnDesignerSetDesigning(Sender: TObject; Component: TComponent;
      Value: boolean);
    procedure OnDesignerComponentListChanged(Sender: TObject);
    procedure OnDesignerPropertiesChanged(Sender: TObject);
    procedure OnDesignerAddComponent(Sender: TObject; Component: TComponent;
      ComponentClass: TRegisteredComponent);
    procedure OnDesignerRemoveComponent(Sender: TObject; Component: TComponent);
    procedure OnDesignerModified(Sender: TObject);
    procedure OnControlSelectionChanged(Sender: TObject);

    procedure SaveEnvironment;
    procedure SaveDesktopSettings(TheEnvironmentOptions: TEnvironmentOptions);
    procedure LoadDesktopSettings(TheEnvironmentOptions: TEnvironmentOptions);
  end;



const
  CapLetters = ['A'..'Z'];
  SmallLetters = ['a'..'z'];
  Numbers = ['0'..'1'];

var
  MainIDE : TMainIDE;

  ObjectInspector1 : TObjectInspector;
  PropertyEditorHook1 : TPropertyEditorHook;
  SourceNotebook : TSourceNotebook;


implementation

uses
  ViewUnit_dlg, Math, LResources, Designer;


function LoadPixmapRes(const ResourceName:string; PixMap:TPixMap):boolean;
var
  ms:TMemoryStream;
  res:TLResource;
begin
  Result:=false;
  res:=LazarusResources.Find(ResourceName);
  if (res<>nil) and (res.Value<>'') and (res.ValueType='XPM') then begin
    ms:=TMemoryStream.Create;
    try
      ms.Write(res.Value[1],length(res.Value));
      ms.Position:=0;
      Pixmap.LoadFromStream(ms);
      Result:=true;
    finally
      ms.Free;
    end;
  end;
end;

function LoadSpeedBtnPixMap(const ResourceName:string):TPixmap;
begin
  Result:=TPixmap.Create;
  Result.TransparentColor:=clNone;
  if not LoadPixmapRes(ResourceName,Result) then
    LoadPixmapRes('default',Result);
end;


{ TMainIDE }


constructor TMainIDE.Create(AOwner: TComponent);
const
  PrimaryConfPathOpt='--primary-config-path=';
  SecondaryConfPathOpt='--secondary-config-path=';
var
  i,x : Integer;
  PageCount : Integer;
  RegComp     : TRegisteredComponent;
  RegCompPage : TRegisteredComponentPage;
  IDEComponent : TIdeComponent;
  SelectionPointerPixmap: TPixmap;
begin
  inherited Create(AOwner);

  // parse command line options
  for i:=1 to ParamCount do begin
    if copy(ParamStr(i),1,length(PrimaryConfPathOpt))=PrimaryConfPathOpt then
    begin
      SetPrimaryConfigPath(copy(ParamStr(i),length(PrimaryConfPathOpt)+1,
               length(ParamStr(i))));
    end;
    if copy(ParamStr(i),1,length(SecondaryConfPathOpt))=SecondaryConfPathOpt
    then begin
      SetSecondaryConfigPath(copy(ParamStr(i),length(SecondaryConfPathOpt)+1,
               length(ParamStr(i))));
    end;
  end;

  // load environment and editor options
  CreatePrimaryConfigPath;

  EnvironmentOptions:=TEnvironmentOptions.Create;
  with EnvironmentOptions do begin
    SetLazarusDefaultFilename;
    Load(false);
  end;
  
  EditorOpts:=TEditorOptions.Create;
  EditorOpts.Load;

  // set the IDE mode to none (= editing mode)
  ToolStatus:=itNone;

  // build and position the MainIDE form
  Name := 'MainIDE';
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.WindowPositionsValid) 
  then begin
    BoundsRect := EnvironmentOptions.MainWindowBounds;
  end 
  else begin
    Left := 0;
    Top := 0;
    Width := Screen.Width - 10;
    Height := 125;
  end;
  Position:= poDesigned;

  if LazarusResources.Find(ClassName)=nil then begin
    LoadMainMenu;
    LoadSpeedbuttons;
  end;

  // Component Notebook
  ComponentNotebook := TNotebook.Create(Self);
  with ComponentNotebook do begin
    Parent := Self;
    Name := 'ComponentNotebook';
//    Align := alBottom;
    Left := RunSpeedButton.Left + RunSpeedButton.Width + 4;
//    Top :=50+ 2;
    Top := 0;
    Width := Self.ClientWidth - Left;
    Height := 60; //Self.ClientHeight - ComponentNotebook.Top;
  end;

  PageCount := 0;
  for I := 0 to RegCompList.PageCount-1 do
  begin
    // Component Notebook Pages
    RegCompPage := RegCompList.Pages[i];
    if RegCompPage.Name <> '' then
    Begin
      if (PageCount = 0) then
        ComponentNotebook.Pages.Strings[pagecount] := RegCompPage.Name
      else
        ComponentNotebook.Pages.Add(RegCompPage.Name);
      GlobalMouseSpeedButton := TSpeedButton.Create(Self);
      SelectionPointerPixmap:=LoadSpeedBtnPixMap('tmouse');
      with GlobalMouseSpeedButton do
      Begin
        Parent := ComponentNotebook.Page[PageCount];
        Enabled := True;
        Width := 25;
        Height := 25;
        OnClick := @ControlClick;
        Glyph := SelectionPointerPixmap;
        Visible := True;
        Flat := True;
        Down := True;
        Name := 'GlobalMouseSpeedButton'+inttostr(PageCount);
      end;

      for x := 0 to RegCompPage.Count-1 do  //for every component on the page....
      begin
        RegComp := RegCompPage.Items[x];
        IDEComponent := TIDEComponent.Create;
        IDEComponent.RegisteredComponent := RegComp;
        IDEComponent._SpeedButton(Self,ComponentNotebook.Page[PageCount]);
        IDEComponent.SpeedButton.OnClick := @ControlClick;
        IDEComponent.SpeedButton.Hint := RegComp.ComponentClass.ClassName;
        IDEComponent.SpeedButton.Name := IDEComponent.SpeedButton.Hint;
        IDEComponent.SpeedButton.ShowHint := True;
        IDECompList.Add(IDEComponent);
      end;
      inc(PageCount);
    end;
   end;
  ComponentNotebook.PageIndex := 0;   // Set it to the first page
  ComponentNotebook.OnPageChanged := @ControlClick;
  ComponentNotebook.Show;

  // MainIDE form events
  OnShow := @FormShow;
  OnClose := @FormClose;
  OnCloseQuery := @FormCloseQuery;

  // compiler interface
  Compiler1 := TCompiler.Create;
  with Compiler1 do begin
    OnCommandLineCreate:=@OnCmdLineCreate;
  end;

  // object inspector
  ObjectInspector1 := TObjectInspector.Create(Self);
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.WindowPositionsValid) then begin
    with EnvironmentOptions.ObjectInspectorOptions do
      ObjectInspector1.SetBounds(Left,Top,Width,Height);
  end else begin
    ObjectInspector1.SetBounds(
      0,Top+Height+30,230,Max(Screen.Height-Top-Height-120,50));
  end;
  ObjectInspector1.OnAddAvailComponent:=@OIOnAddAvailableComponent;
  ObjectInspector1.OnSelectComponentInOI:=@OIOnSelectComponent;
  PropertyEditorHook1:=TPropertyEditorHook.Create;
  ObjectInspector1.PropertyEditorHook:=PropertyEditorHook1;
  ObjectInspector1.Show;

  // create formeditor
  FormEditor1 := TFormEditor.Create;
  FormEditor1.Obj_Inspector := ObjectInspector1;

  // source editor / notebook
  SourceNotebook := TSourceNotebook.Create(Self);
  SourceNotebook.OnNewClicked := @OnSrcNotebookFileNew;
  SourceNotebook.OnOpenClicked := @ OnSrcNotebookFileOpen;
  SourceNotebook.OnOpenFileAtCursorClicked := @OnSrcNotebookFileOpenAtCursor;
  SourceNotebook.OnSaveClicked := @OnSrcNotebookFileSave;
  SourceNotebook.OnSaveAsClicked := @OnSrcNotebookFileSaveAs;
  SourceNotebook.OnCloseClicked := @OnSrcNotebookFileClose;
  SourceNotebook.OnSaveAllClicked := @OnSrcNotebookSaveAll;
  SourceNotebook.OnToggleFormUnitClicked := @OnSrcNotebookToggleFormUnit;
  SourceNotebook.OnProcessUserCommand := @OnSrcNotebookProcessCommand;

  // find / replace dialog
  itmSearchFind.OnClick := @SourceNotebook.FindClicked;
  itmSearchFindAgain.OnClick := @SourceNotebook.FindAgainClicked;
  itmSearchReplace.OnClick := @SourceNotebook.ReplaceClicked;

  // message view
  FMessagesViewBoundsRectValid:=false;

  // macros
  MacroList:=TTransferMacroList.Create;
  MacroList.Add(TTransferMacro.Create('Col','',nil));
  MacroList.Add(TTransferMacro.Create('Row','',nil));
  MacroList.Add(TTransferMacro.Create('EdFile','',nil));
  MacroList.Add(TTransferMacro.Create('CurToken','',nil));
  MacroList.Add(TTransferMacro.Create('ProjFile','',nil));
  MacroList.Add(TTransferMacro.Create('ProjPath','',nil));
  MacroList.Add(TTransferMacro.Create('Save','',nil));
  MacroList.Add(TTransferMacro.Create('SaveAll','',nil));
  MacroList.Add(TTransferMacro.Create('Params','',nil));
  MacroList.Add(TTransferMacro.Create('TargetFile','',nil));
  MacroList.Add(TTransferMacro.Create('CompPath','',nil));
  MacroList.Add(TTransferMacro.Create('FPCSrcDir','',nil));
  MacroList.Add(TTransferMacro.Create('LazarusDir','',nil));
  MacroList.OnSubstitution:=@OnMacroSubstitution;

  // control selection (selected components on edited form)
  TheControlSelection:=TControlSelection.Create;
  TheControlSelection.OnChange:=@OnControlSelectionChanged;

  // load command line project or last project or create a new project
  if (ParamCount>0) and (ParamStr(ParamCount)[1]<>'-')
  and (ExtractFileExt(ParamStr(ParamCount))='.lpi')
  and (DoOpenProjectFile(ParamStr(ParamCount))=mrOk) then
    // command line project loaded
  else if (EnvironmentOptions.OpenLastprojectAtStart)
  and (FileExists(EnvironmentOptions.LastSavedProjectFile)) 
  and (DoOpenProjectFile(EnvironmentOptions.LastSavedProjectFile)=mrOk) then
    // last project loaded
  else
    // create new project
    DoNewProject(ptApplication);
end;

destructor TMainIDE.Destroy;
begin
writeln('[TMainIDE.Destroy] A');
  if Project<>nil then begin
    Project.Free;
    Project:=nil;
  end;
  TheControlSelection.OnChange:=nil;
  TheControlSelection.Free;
  TheControlSelection:=nil;
  FormEditor1.Free;
  FormEditor1:=nil;
  PropertyEditorHook1.Free;
  Compiler1.Free;
  MacroList.Free;
  EditorOpts.Free;
  EditorOpts:=nil;
  EnvironmentOptions.Free;
  EnvironmentOptions:=nil;
writeln('[TMainIDE.Destroy] B  -> inherited Destroy...');
  inherited Destroy;
writeln('[TMainIDE.Destroy] END');
end;

procedure TMainIDE.OIOnAddAvailableComponent(AComponent:TComponent;
var Allowed:boolean);
begin
  //Allowed:=(not (AComponent is TGrabber));
end;

procedure TMainIDE.OIOnSelectComponent(AComponent:TComponent);
begin
  with TheControlSelection do begin
    BeginUpdate;
    Clear;
    Add(AComponent);
    EndUpdate;
  end;
  if AComponent.Owner is TControl then
    TControl(AComponent.Owner).Invalidate;
end;

Procedure TMainIDE.ToolButtonClick(Sender : TObject);
Begin
  Assert(False, 'Trace:TOOL BUTTON CLICK!');

end;

Procedure TMainIDE.FormPaint(Sender : TObject);
begin

end;

{------------------------------------------------------------------------------}
procedure TMainIDE.FormShow(Sender : TObject);
Begin

end;

procedure TMainIDE.FormClose(Sender : TObject; var Action: TCloseAction);
begin
  SaveEnvironment;
  if TheControlSelection<>nil then TheControlSelection.Clear;
end;

procedure TMainIDE.FormCloseQuery(Sender : TObject; var CanClose: boolean);
Begin
writeln('[TMainIDE.FormCloseQuery]');
  CanClose:=true;
  if SomethingOfProjectIsModified then begin
    if Application.MessageBox('Save changes to project?','Project changed',
        MB_OKCANCEL)=mrOk then begin
      CanClose:=DoSaveProject(false)<>mrAbort;
      if CanClose=false then exit;
    end;
  end;
  CanClose:=(DoCloseProject<>mrAbort);
End;

{------------------------------------------------------------------------------}
type 
  TMoveFlags = set of (mfTop, mfLeft);

procedure TMainIDE.LoadSpeedbuttons;
  
  function CreateButton(const AName, APixName: String; ANumGlyphs: Integer;
    var ALeft, ATop: Integer; const AMoveFlags: TMoveFlags;
    const AOnClick: TNotifyEvent): TSpeedButton;
  begin
    Result := TSpeedButton.Create(Self);
    with Result do
    begin
      Name := AName;
//      Parent := pnlSpeedButtons;
      Parent := Self;
      Enabled := True;
      Top := ATop;
      Left := ALeft;
      OnClick := AOnClick;
      Glyph := LoadSpeedBtnPixMap(APixName);
      NumGlyphs := ANumGlyphs;
      Flat := True;
      //Transparent:=True;
      if mfTop in AMoveFlags then Inc(ATop, Height + 1);
      if mfLeft in AMoveFlags then Inc(ALeft, Width + 1);
//writeln('---- W=',Width,',',Height,' Transparent=',Transparent);
      Visible := True;
    end;
  end;
var
  ButtonTop, ButtonLeft, n: Integer;

begin
(*
  pnlSpeedButtons := TPanel.Create(Self);
  with pnlSpeedButtons do
  begin
    Parent := Self;
    Visible := True;
    Name := 'pnlSpeedButtons';
    Top := 0;
    Caption := '';
  end;
*)

  ButtonTop := 1;
  ButtonLeft := 1;
  NewUnitSpeedBtn       := CreateButton('NewUnitSpeedBtn'      , 'btn_newunit'   , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuNewUnitClicked);
  OpenFileSpeedBtn      := CreateButton('OpenFileSpeedBtn'     , 'btn_openfile'  , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuOpenClicked);

  // store left
  n := ButtonLeft;
  OpenFileArrowSpeedBtn := CreateButton('OpenFileArrowSpeedBtn', 'btn_downarrow' , 1, ButtonLeft, ButtonTop, [mfLeft], @OpenFileDownArrowClicked);
  OpenFileArrowSpeedBtn.Width := 12;
  ButtonLeft := n+12;
  
  SaveSpeedBtn          := CreateButton('SaveSpeedBtn'         , 'btn_save'      , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuSaveClicked);
  SaveAllSpeedBtn       := CreateButton('SaveAllSpeedBtn'      , 'btn_saveall'   , 1, ButtonLeft, ButtonTop, [mfLeft, mfTop], @mnuSaveAllClicked);
  // new row
  ButtonLeft := 0;
  ViewUnitsSpeedBtn     := CreateButton('ViewUnitsSpeedBtn'    , 'btn_viewunits' , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuViewUnitsClicked);
  ViewFormsSpeedBtn     := CreateButton('ViewFormsSpeedBtn'    , 'btn_viewforms' , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuViewFormsClicked);   
  ToggleFormSpeedBtn    := CreateButton('ToggleFormSpeedBtn'   , 'btn_toggleform', 1, ButtonLeft, ButtonTop, [mfLeft], @mnuToggleFormUnitCLicked);
  NewFormSpeedBtn       := CreateButton('NewFormSpeedBtn'      , 'btn_newform'   , 1, ButtonLeft, ButtonTop, [mfLeft], @mnuNewFormClicked);
  RunSpeedButton        := CreateButton('RunSpeedButton'       , 'btn_run'       , 1, ButtonLeft, ButtonTop, [mfLeft, mfTop], @mnuRunProjectClicked);
  
//  pnlSpeedButtons.Width := ButtonLeft;
//  pnlSpeedButtons.Height := ButtonTop;
  

  // create the popupmenu for the OpenFileArrowSpeedBtn
  OpenFilePopUpMenu := TPopupMenu.Create(self);
  OpenFilePopupMenu.Name:='OpenFilePopupMenu';
  OpenFilePopupMenu.AutoPopup := False;
{ 
  MenuItem := TMenuItem.Create(Self);
  MenuItem.Caption := 'No files have been opened';
  MenuItem.OnClick := nil;
  OpenFilePopupMenu.Items.Add(MenuItem);
}
end;


{------------------------------------------------------------------------------}
procedure TMainIDE.LoadMainMenu;

  procedure AddRecentSubMenu(ParentMenuItem: TMenuItem; FileList: TStringList;
    OnClickEvent: TNotifyEvent);
  var i: integer;
    NewMenuItem: TMenuItem;
  begin
    for i:=0 to FileList.Count-1 do begin
      NewMenuItem:= TMenuItem.Create(Self);
      NewMenuItem.Name:=ParentMenuItem.Name+'Recent'+IntToStr(i);
      NewMenuItem.Caption := FileList[i];
      NewMenuItem.OnClick := OnClickEvent;
      ParentMenuItem.Add(NewMenuItem);
    end;
  end;

begin

//--------------
// The Menu
//--------------

  mnuMain := TMainMenu.Create(Self);
  mnuMain.Name:='mnuMainMenu';
  Menu := mnuMain;

//--------------
// Main menu
//--------------

  mnuFile := TMenuItem.Create(Self);
  mnuFile.Name:='mnuFile';
  mnuFile.Caption := '&File';
  mnuMain.Items.Add(mnuFile);

  mnuEdit := TMenuItem.Create(Self);
  mnuEdit.Name:='mnuEdit';
  mnuEdit.Caption := '&Edit';
  mnuMain.Items.Add(mnuEdit);

  mnuSearch := TMenuItem.Create(Self);
  mnuSearch.Name:='mnuSearch';
  mnuSearch.Caption := '&Search';
  mnuMain.Items.Add(mnuSearch);

  mnuView := TMenuItem.Create(Self);
  mnuView.Name:='mnuView';
  mnuView.Caption := '&View';
  mnuMain.Items.Add(mnuView);

  mnuProject := TMenuItem.Create(Self);
  mnuProject.Name:='mnuProject';
  mnuProject.Caption := '&Project';
  mnuMain.Items.Add(mnuProject);

  mnuEnvironment := TMenuItem.Create(Self);
  mnuEnvironment.Name:='mnuEnvironment';
  mnuEnvironment.Caption := 'E&nvironment';
  mnuMain.Items.Add(mnuEnvironment);

//--------------
// File
//--------------
  
  itmFileNew := TMenuItem.Create(Self);
  itmFileNew.Name:='itmFileNew';
  itmFileNew.Caption := 'New Unit';
  itmFileNew.OnClick := @mnuNewUnitClicked; // ToDo:  new dialog
  mnuFile.Add(itmFileNew);

  itmFileNewForm := TMenuItem.Create(Self);
  itmFileNewForm.Name:='itmFileNewForm';
  itmFileNewForm.Caption := 'New Form';
  itmFileNewForm.OnClick := @mnuNewFormClicked;
  mnuFile.Add(itmFileNewForm);

  mnuFile.Add(CreateSeperator);

  itmFileOpen := TMenuItem.Create(Self);
  itmFileOpen.Name:='itmFileOpen';
  itmFileOpen.Caption := 'Open';
  itmFileOpen.OnClick := @mnuOpenClicked;
  mnuFile.Add(itmFileOpen);

  itmFileRecentOpen := TMenuItem.Create(Self);
  itmFileRecentOpen.Name:='itmFileRecentOpen';
  itmFileRecentOpen.Caption := 'Open Recent';
  mnuFile.Add(itmFileRecentOpen);
  
  AddRecentSubMenu(itmFileRecentOpen,EnvironmentOptions.RecentOpenFiles,
                    @mnuOpenClicked);

  itmFileSave := TMenuItem.Create(Self);
  itmFileSave.Name:='itmFileSave';
  itmFileSave.Caption := 'Save';
  itmFileSave.OnClick := @mnuSaveClicked;
  mnuFile.Add(itmFileSave);

  itmFileSaveAs := TMenuItem.Create(Self);
  itmFileSaveAs.Name:='itmFileSaveAs';
  itmFileSaveAs.Caption := 'Save As';
  itmFileSaveAs.OnClick := @mnuSaveAsClicked;
  mnuFile.Add(itmFileSaveAs);

  itmFileSaveAll := TMenuItem.Create(Self);
  itmFileSaveAll.Name:='itmFileSaveAll';
  itmFileSaveAll.Caption := 'Save All';
  itmFileSaveAll.OnClick := @mnuSaveAllClicked;
  mnuFile.Add(itmFileSaveAll);

  itmFileClose := TMenuItem.Create(Self);
  itmFileClose.Name:='itmFileClose';
  itmFileClose.Caption := 'Close';
  itmFileClose.Enabled := False;
  itmFileClose.OnClick := @mnuCloseClicked;
  mnuFile.Add(itmFileClose);

  mnuFile.Add(CreateSeperator);

  itmFileQuit := TMenuItem.Create(Self);
  itmFileQuit.Name:='itmFileQuit';
  itmFileQuit.Caption := 'Quit';
  itmFileQuit.OnClick := @mnuQuitClicked;
  mnuFile.Add(itmFileQuit);

//--------------
// Edit
//--------------

  itmEditUndo := TMenuItem.Create(nil);
  itmEditUndo.Name:='itmEditUndo';
  itmEditUndo.Caption := 'Undo';
  mnuEdit.Add(itmEditUndo);

  itmEditRedo := TMenuItem.Create(nil);
  itmEditRedo.Name:='itmEditRedo';
  itmEditRedo.Caption := 'Redo';
  mnuEdit.Add(itmEditRedo);

  mnuEdit.Add(CreateSeperator);

  itmEditCut  := TMenuItem.Create(nil);
  itmEditCut.Name:='itmEditCut';
  itmEditCut.Caption := 'Cut';
  mnuEdit.Add(itmEditCut);

  itmEditCopy := TMenuItem.Create(nil);
  itmEditCopy.Name:='itmEditCopy';
  itmEditCopy.Caption := 'Copy';
  mnuEdit.Add(itmEditCopy);

  itmEditPaste := TMenuItem.Create(nil);
  itmEditPaste.Name:='itmEditPaste';
  itmEditPaste.Caption := 'Paste';
  mnuEdit.Add(itmEditPaste);

//--------------
// Search
//--------------

  itmSearchFind := TMenuItem.Create(nil);
  itmSearchFind.Name:='itmSearchFind';
  itmSearchFind.Caption := 'Find';
  mnuSearch.add(itmSearchFind);

  itmSearchFindAgain := TMenuItem.Create(nil);
  itmSearchFindAgain.Name:='itmSearchFindAgain';
  itmSearchFindAgain.caption := 'Find &Again';
  itmSearchFindAgain.Enabled := False;
  mnuSearch.add(itmSearchFindAgain);

  itmSearchReplace := TMenuItem.Create(nil);
  itmSearchReplace.Name:='itmSearchReplace';
  itmSearchReplace.Caption := 'Replace';
  mnuSearch.add(itmSearchReplace);

//--------------
// View
//--------------

  itmViewInspector := TMenuItem.Create(Self);
  itmViewInspector.Name:='itmViewInspector';
  itmViewInspector.Caption := 'Object Inspector';
  itmViewInspector.OnClick := @mnuViewInspectorClicked;
  mnuView.Add(itmViewInspector);

  itmViewProject  := TMenuItem.Create(Self);
  itmViewProject.Name:='itmViewProject';
  itmViewProject.Caption := 'Project Explorer';
  mnuView.Add(itmViewProject);

  mnuView.Add(CreateSeperator);

  itmViewCodeExplorer := TMenuItem.Create(Self);
  itmViewCodeExplorer.Name:='itmViewCodeExplorer';
  itmViewCodeExplorer.Caption := 'Code Explorer';
  itmViewCodeExplorer.OnClick := @mnuViewCodeExplorerClick;
  mnuView.Add(itmViewCodeExplorer);

  mnuView.Add(CreateSeperator);

  itmViewUnits := TMenuItem.Create(Self);
  itmViewUnits.Name:='itmViewUnits';
  itmViewUnits.Caption := 'Units...';
  itmViewUnits.OnClick := @mnuViewUnitsClicked;
  mnuView.Add(itmViewUnits);

  itmViewForms := TMenuItem.Create(Self);
  itmViewForms.Name:='itmViewForms';
  itmViewForms.Caption := 'Forms...';
  itmViewForms.OnClick := @mnuViewFormsClicked;
  mnuView.Add(itmViewForms);

  mnuView.Add(CreateSeperator);

  itmViewMessage := TMenuItem.Create(Self);
  itmViewMessage.Name:='itmViewMessage';
  itmViewMessage.Caption := 'Messages';
  itmViewMessage.OnClick := @mnuViewMessagesClick;
  mnuView.Add(itmViewMessage);

//--------------
// Project
//--------------

  itmProjectNew := TMenuItem.Create(Self);
  itmProjectNew.Name:='itmProjectNew';
  itmProjectNew.Caption := 'New Project';
  itmProjectNew.OnClick := @mnuNewProjectClicked;
  mnuProject.Add(itmProjectNew);

  itmProjectOpen := TMenuItem.Create(Self);
  itmProjectOpen.Name:='itmProjectOpen';
  itmProjectOpen.Caption := 'Open Project';
  itmProjectOpen.OnClick := @mnuOpenProjectClicked;
  mnuProject.Add(itmProjectOpen);

  itmProjectRecentOpen := TMenuItem.Create(Self);
  itmProjectRecentOpen.Name:='itmProjectRecentOpen';
  itmProjectRecentOpen.Caption := 'Open Recent Project';
  mnuProject.Add(itmProjectRecentOpen);
  
  AddRecentSubMenu(itmProjectRecentOpen,EnvironmentOptions.RecentProjectFiles,
                   @mnuOpenProjectClicked);

  itmProjectSave := TMenuItem.Create(Self);
  itmProjectSave.Name:='itmProjectSave';
  itmProjectSave.Caption := 'Save Project';
  itmProjectSave.OnClick := @mnuSaveProjectClicked;
  mnuProject.Add(itmProjectSave);

  itmProjectSaveAs := TMenuItem.Create(Self);
  itmProjectSaveAs.Name:='itmProjectSaveAs';
  itmProjectSaveAs.Caption := 'Save Project As...';
  itmProjectSaveAs.OnClick := @mnuSaveProjectAsClicked;
  mnuProject.Add(itmProjectSaveAs);

  mnuProject.Add(CreateSeperator);

  itmProjectAddTo := TMenuItem.Create(Self);
  itmProjectAddTo.Name:='itmProjectAddTo';
  itmProjectAddTo.Caption := 'Add active unit to Project';
  itmProjectAddTo.OnClick := @mnuAddToProjectClicked;
  mnuProject.Add(itmProjectAddTo);

  itmProjectRemoveFrom := TMenuItem.Create(Self);
  itmProjectRemoveFrom.Name:='itmProjectRemoveFrom';
  itmProjectRemoveFrom.Caption := 'Remove from Project';
  itmProjectRemoveFrom.OnClick := @mnuRemoveFromProjectClicked;
  mnuProject.Add(itmProjectRemoveFrom);

  mnuProject.Add(CreateSeperator);

  itmProjectViewSource := TMenuItem.Create(Self);
  itmProjectViewSource.Name:='itmProjectViewSource';
  itmProjectViewSource.Caption := 'View Source';
  itmProjectViewSource.OnClick := @mnuViewProjectSourceClicked;
  mnuProject.Add(itmProjectViewSource);

  mnuProject.Add(CreateSeperator);

  itmProjectBuild := TMenuItem.Create(Self);
  itmProjectBuild.Name:='itmProjectBuild';
  itmProjectBuild.Caption := 'Build';
  itmProjectBuild.OnClick := @mnuBuildProjectClicked;
  mnuProject.Add(itmProjectBuild);

  itmProjectRun := TMenuItem.Create(Self);
  itmProjectRun.Name:='itmProjectRun';
  itmProjectRun.Caption := 'Run';
  itmProjectRun.OnClick := @mnuRunProjectClicked;
  mnuProject.Add(itmProjectRun);

  mnuProject.Add(CreateSeperator);

  itmProjectCompilerSettings := TMenuItem.Create(Self);
  itmProjectCompilerSettings.Name:='itmProjectCompilerSettings';
  itmProjectCompilerSettings.Caption := 'Compiler Options...';
  itmProjectCompilerSettings.OnClick := @mnuProjectCompilerSettingsClicked;
  mnuProject.Add(itmProjectCompilerSettings);
  
  itmProjectOptions := TMenuItem.Create(Self);
  itmProjectOptions.Name:='itmProjectOptions';
  itmProjectOptions.Caption := 'Project Options...';
  itmProjectOptions.OnClick := @mnuProjectOptionsClicked;
  mnuProject.Add(itmProjectOptions);

//--------------
// Environment
//--------------

  itmEnvGeneralOptions := TMenuItem.Create(nil);
  itmEnvGeneralOptions.Name:='itmEnvGeneralOptions';
  itmEnvGeneralOptions.Caption := 'General options';
  itmEnvGeneralOptions.OnCLick := @mnuEnvGeneralOptionsClicked;
  mnuEnvironment.Add(itmEnvGeneralOptions);

  itmEnvEditorOptions := TMenuItem.Create(nil);
  itmEnvEditorOptions.Name:='itmEnvEditorOptions';
  itmEnvEditorOptions.Caption := 'Editor options';
  itmEnvEditorOptions.OnCLick := @mnuEnvEditorOptionsClicked;
  mnuEnvironment.Add(itmEnvEditorOptions);

end;
{------------------------------------------------------------------------------}

function TMainIDE.CreateSeperator : TMenuItem;
begin
  itmSeperator := TMenuItem.Create(Self);
  itmSeperator.Caption := '-';
  Result := itmSeperator;
end;

{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuToggleFormUnitClicked(Sender : TObject);
Begin
  writeln('Toggle form clicked');
  FCodeLastActivated:=not FCodeLastActivated;
  DoBringToFrontFormOrUnit;
end;

Procedure TMainIDE.SetDesigning(Control : TComponent; Value : Boolean);
Begin
  Writeln('Setting designing');
  Control.SetDesigning(Value);
  Writeln('Set');
end;


Function TMainIDE.SearchPaths : String;
Begin
  Result :=  Project.CompilerOptions.OtherUnitFiles;
End;

{
------------------------------------------------------------------------
-------------------ControlClick-----------------------------------------
------------------------------------------------------------------------
}

Procedure TMainIDE.ControlClick(Sender : TObject);
var
  I : Integer;
  IDECOmp : TIDEComponent;
  Speedbutton : TSpeedbutton;
  Temp : TControl;
begin
  if Sender is TSpeedButton then
  Begin
//    Writeln('sender is a speedbutton');
//    Writeln('The name is '+TSpeedbutton(sender).name);
    SpeedButton := TSpeedButton(Sender);
//    Writeln('Speedbutton s Name is '+SpeedButton.name);
    //find the IDECOmponent that has this speedbutton
    IDEComp := IDECompList.FindCompBySpeedButton(SpeedButton);
    if SelectedComponent <> nil then
      TIDeComponent(
       IdeCompList.FindCompByRegComponent(SelectedComponent)).SpeedButton.Down
         := False
    else begin
      Temp := nil;
      for i := 0 to ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1 do
      begin
        if CompareText(
            TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[I]).Name
            ,'GlobalMouseSpeedButton'+inttostr(ComponentNotebook.Pageindex)) = 0 then
        begin
          temp := TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[i]);
          Break;
        end;
      end;
      if temp <> nil then
        TSpeedButton(Temp).down := False
      else begin
        Writeln('[TMainIDE.ControlClick] ERROR - Control ',
           'GlobalMouseSpeedButton',inttostr(ComponentNotebook.Pageindex),' not found');
        Halt;
      end;
    end;
    if IDECOmp <> nil then Begin
      //draw this button down
      SpeedButton.Down := True;
      SelectedComponent := IDEComp.RegisteredComponent;
    end else begin
      SelectedComponent := nil;
      Temp := nil;
      for i := 0 to ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1 do
      begin
        if CompareText(
          TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[I]).Name
           ,'GlobalMouseSpeedButton'+inttostr(ComponentNotebook.Pageindex)) = 0 then
        begin
          temp := TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[i]);
          Break;
        end;
      end;
      if temp <> nil then
        TSpeedButton(Temp).down := True
      else begin
        Writeln('[TMainIDE.ControlClick] ERROR - Control '
           +'GlobalMouseSpeedButton'+inttostr(ComponentNotebook.Pageindex)+' not found');
        Halt;
      end;
    end;
  end
  else
  Begin
//    Writeln('must be nil');
    //draw old speedbutton up
    if SelectedComponent <> nil then
      TIDeComponent(
        IdeCompList.FindCompByRegComponent(SelectedComponent)).SpeedButton.Down
           := False;
    SelectedComponent := nil;
    Temp := nil;
    for i := 0 to ComponentNotebook.Page[ComponentNotebook.Pageindex].ControlCount-1 do
    begin
      if CompareText(
         TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[I]).Name
         ,'GlobalMouseSpeedButton'+inttostr(ComponentNotebook.Pageindex)) = 0 then
      begin
        temp := TControl(ComponentNotebook.Page[ComponentNotebook.Pageindex].Controls[i]);
        Break;
      end;
    end;
    if temp <> nil then
      TSpeedButton(Temp).down := True
    else begin
      Writeln('[TMainIDE.ControlClick] ERROR - Control '
        +'GlobalMouseSpeedButton'+inttostr(ComponentNotebook.Pageindex)+' not found');
      Halt;
    end;
  end;
//  Writeln('Exiting ControlClick');
end;



{------------------------------------------------------------------------------}
procedure TMainIDE.mnuNewUnitClicked(Sender : TObject);
begin
  DoNewEditorUnit(nuUnit);
end;

procedure TMainIDE.mnuNewFormClicked(Sender : TObject);
begin
  DoNewEditorUnit(nuForm);
end;

procedure TMainIDE.mnuOpenClicked(Sender : TObject);
var OpenDialog:TOpenDialog;
  AFilename: string;
begin
  if (Sender=itmFileOpen) or (Sender=OpenFileSpeedBtn) then begin
    OpenDialog:=TOpenDialog.Create(Application);
    try
      OpenDialog.Title:='Open file';
      OpenDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
      if OpenDialog.Execute then begin
        AFilename:=ExpandFilename(OpenDialog.Filename);
        EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(AFilename);
        if DoOpenEditorFile(AFilename,false)=mrOk then begin
          EnvironmentOptions.AddToRecentOpenFiles(AFilename);
          SaveEnvironment;
        end;
      end;
    finally
      OpenDialog.Free;
    end;
  end else if Sender is TMenuItem then begin
    AFileName:=ExpandFilename(TMenuItem(Sender).Caption);
    if DoOpenEditorFile(AFilename,false)=mrOk then begin
      EnvironmentOptions.AddToRecentOpenFiles(AFilename);
      SaveEnvironment;
    end;
  end;
end;

procedure TMainIDE.mnuOpenFileAtCursorClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoOpenFileAtCursor(Sender);  
end;

procedure TMainIDE.mnuSaveClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,false);
end;

procedure TMainIDE.mnuSaveAsClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,true);
end;

procedure TMainIDE.mnuSaveAllClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoSaveAll;  
end;

procedure TMainIDE.mnuCloseClicked(Sender : TObject);
begin
  if SourceNoteBook.NoteBook=nil then exit;
  DoCloseEditorUnit(SourceNoteBook.NoteBook.PageIndex,true);
end;

Procedure TMainIDE.OnSrcNotebookFileNew(Sender : TObject);
begin
  mnuNewFormClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileClose(Sender : TObject);
begin
  mnuCloseClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileOpen(Sender : TObject);
begin
  mnuOpenClicked(Sender);
end;

Procedure TMainIDE.OnSrcNoteBookFileOpenAtCursor(Sender : TObject);
begin
  mnuOpenFileAtCursorClicked(Sender);  
end;

Procedure TMainIDE.OnSrcNotebookFileSave(Sender : TObject);
begin
  mnuSaveClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookFileSaveAs(Sender : TObject);
begin
  mnuSaveAsClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookSaveAll(Sender : TObject);
begin
  mnuSaveAllClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookToggleFormUnit(Sender : TObject);
begin
  mnuToggleFormUnitClicked(Sender);
end;

Procedure TMainIDE.OnSrcNotebookProcessCommand(Sender: TObject;
  Command: integer;  var Handled: boolean);
begin
  case Command of
   ecBuild:
    begin
      Handled:=true;
      DoBuildProject;
    end;
   ecRun:
    begin
      Handled:=true;
      if DoBuildProject<>mrOk then exit;
      DoRunProject;
    end;
  end;
end;


{------------------------------------------------------------------------------}

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}
{----------------OpenFileDownArrowClicked--------------------------------------}
{------------------------------------------------------------------------------}

Procedure TMainIDE.OpenFileDownArrowClicked(Sender : TObject);
Begin
  //display the PopupMenu
  if OpenFilePopupMenu.Items.Count > 0 then
  OpenFilePopupMenu.Popup(0,0);
end;

//==============================================================================
{
  This function creates a LFM file from any form.
  To create the LFC file use the program lazres or the
  LFMtoLFCfile function.
}
function CreateLFM(AForm:TCustomForm):integer;
// 0 = ok
// -1 = error while streaming AForm to binary stream
// -2 = error while streaming binary stream to text file
var BinStream,TxtMemStream:TMemoryStream;
  Driver: TAbstractObjectWriter;
  Writer:TWriter;
  TxtFileStream:TFileStream;
begin
  Result:=0;
  BinStream:=TMemoryStream.Create;
  try
    try
      Driver:=TBinaryObjectWriter.Create(BinStream,4096);
      try
        Writer:=TWriter.Create(Driver);
        try
          Writer.WriteDescendent(AForm,nil);
        finally
          Writer.Free;
        end;
      finally
        Driver.Free;
      end;
    except
      Result:=-1;
      exit;
    end;
    try
      // transform binary to text and save LFM file
      TxtMemStream:=TMemoryStream.Create;
      TxtFileStream:=TFileStream.Create(lowercase(AForm.ClassName)+'.lfm'
                           ,fmCreate);
      try
        BinStream.Position:=0;
        ObjectBinaryToText(BinStream,TxtMemStream);
        TxtMemStream.Position:=0;
        TxtFileStream.CopyFrom(TxtMemStream,TxtMemStream.Size);
      finally
        TxtMemStream.Free;
        TxtFileStream.Free;
      end;
    except
      Result:=-2;
      exit;
    end;
  finally
    BinStream.Free;
  end;
end;

//==============================================================================

Procedure TMainIDE.SetDefaultsforForm(aForm : TCustomForm);
Begin
writeln('[TMainIDE.SetDefaultsforForm] 1');
  aForm.Designer := TDesigner.Create(aForm, TheControlSelection);
writeln('[TMainIDE.SetDefaultsforForm] 2');
  with TDesigner(aForm.Designer) do begin
    FormEditor := FormEditor1;
    OnGetSelectedComponentClass:=@OnDesignerGetSelectedComponentClass;
    OnUnselectComponentClass:=@OnDesignerUnselectComponentClass;
    OnSetDesigning:=@OnDesignerSetDesigning;
    OnComponentListChanged:=@OnDesignerComponentListChanged;
    OnPropertiesChanged:=@OnDesignerPropertiesChanged;
    OnAddComponent:=@OnDesignerAddComponent;
    OnRemoveComponent:=@OnDesignerRemoveComponent;
    OnGetNonVisualCompIconCanvas:=@IDECompList.OnGetNonVisualCompIconCanvas;
    OnModified:=@OnDesignerModified;
writeln('[TMainIDE.SetDefaultsforForm] 3');
  end;
end;


{------------------------------------------------------------------------------}

procedure TMainIDE.mnuQuitClicked(Sender : TObject);
var CanClose: boolean;
begin
  CanClose:=true;
  OnCloseQuery(Sender, CanClose);
writeln('TMainIDE.mnuQuitClicked 1');
  if CanClose then Close;
writeln('TMainIDE.mnuQuitClicked 2');
end;

{------------------------------------------------------------------------------}
procedure TMainIDE.mnuViewInspectorClicked(Sender : TObject);
begin
  ObjectInspector1.Show;
end;

{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuViewUnitsClicked(Sender : TObject);
begin
  DoViewUnitsAndForms(false);
end;

Procedure TMainIDE.mnuViewFormsClicked(Sender : TObject);
Begin
  DoViewUnitsAndForms(true);
end;

Procedure TMainIDE.mnuViewCodeExplorerClick(Sender : TObject);
begin
  SourceNotebook.Show;
end;

Procedure TMainIDE.mnuViewMessagesClick(Sender : TObject);
Begin
  MessagesView.Show;
End;


{------------------------------------------------------------------------------}

Procedure TMainIDE.mnuNewProjectClicked(Sender : TObject);
var
  NewProjectType: TProjectType;
Begin
  if ChooseNewProject(NewProjectType)=mrCancel then exit;
  DoNewProject(NewprojectType);
end;

Procedure TMainIDE.mnuOpenProjectClicked(Sender : TObject);
var OpenDialog:TOpenDialog;
  AFileName: string;
begin
  if Sender=itmProjectOpen then begin
    OpenDialog:=TOpenDialog.Create(Application);
    try
      OpenDialog.Title:='Open Project File (*.lpi)';
      OpenDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
      if OpenDialog.Execute then begin
        AFilename:=ExpandFilename(OpenDialog.Filename);
        EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(AFilename);
        if DoOpenProjectFile(AFilename)=mrOk then begin
          EnvironmentOptions.AddToRecentProjectFiles(AFilename);
          SaveEnvironment;
        end;
      end;
    finally
      OpenDialog.Free;
    end;
  end else if Sender is TMenuItem then begin
    AFileName:=ExpandFilename(TMenuItem(Sender).Caption);
    if DoOpenProjectFile(AFilename)=mrOk then begin
      EnvironmentOptions.AddToRecentProjectFiles(AFilename);
      SaveEnvironment;
    end;
  end;
end;

Procedure TMainIDE.mnuSaveProjectClicked(Sender : TObject);
Begin
  DoSaveProject(false);
end;

procedure TMainIDE.mnuSaveProjectAsClicked(Sender : TObject);
begin
  DoSaveProject(true);
end;

procedure TMainIDE.mnuAddToProjectClicked(Sender : TObject);
begin
  DoAddActiveUnitToProject;
end;

procedure TMainIDE.mnuRemoveFromProjectClicked(Sender : TObject);
begin
  DoRemoveFromProjectDialog;
end;

procedure TMainIDE.mnuViewProjectSourceClicked(Sender : TObject);
begin
  DoOpenMainUnit(false);
end;

Procedure TMainIDE.mnuBuildProjectClicked(Sender : TObject);
Begin
  DoBuildProject;
end;

Procedure TMainIDE.mnuRunProjectClicked(Sender : TObject);
begin
  DoRunProject;
end;

procedure TMainIDE.mnuProjectCompilerSettingsClicked(Sender : TObject);
var frmCompilerOptions:TfrmCompilerOptions;
begin
  frmCompilerOptions:=TfrmCompilerOptions.Create(Application);
  try
    frmCompilerOptions.CompilerOpts:=Project.CompilerOptions;
    frmCompilerOptions.GetCompilerOptions;
    if frmCompilerOptions.ShowModal=mrOk then begin
      SourceNoteBook.SearchPaths:=SearchPaths;
    end;
  finally
    frmCompilerOptions.Free;
  end;
end;

procedure TMainIDE.mnuProjectOptionsClicked(Sender : TObject);
begin
  if ShowProjectOptionsDialog(Project)=mrOk then begin
    UpdateMainUnitSrcEdit;
  end;
end;

//------------------------------------------------------------------------------

procedure TMainIDE.SaveDesktopSettings(
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  with TheEnvironmentOptions do begin
    MainWindowBounds:=BoundsRect;
    SourceEditorBounds:=SourceNoteBook.BoundsRect;
    MessagesViewBoundsValid:=FMessagesViewBoundsRectValid;
    MessagesViewBounds:=MessagesView.BoundsRect;
    ObjectInspectorOptions.Assign(ObjectInspector1);
    WindowPositionsValid:=true;
  end;
end;

procedure TMainIDE.LoadDesktopSettings(
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  with TheEnvironmentOptions do begin
    if WindowPositionsValid then begin
      BoundsRect:=MainWindowBounds;
      SourceNoteBook.BoundsRect:=SourceEditorBounds;
      if MessagesViewBoundsValid then begin
        MessagesView.BoundsRect:=MessagesViewBounds;
        FMessagesViewBoundsRectValid:=true;
      end;
      ObjectInspectorOptions.AssignTo(ObjectInspector1);
    end;
  end;
end;

procedure TMainIDE.OnLoadEnvironmentSettings(Sender: TObject; 
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  LoadDesktopSettings(TheEnvironmentOptions);
end;

procedure TMainIDE.OnSaveEnvironmentSettings(Sender: TObject; 
  TheEnvironmentOptions: TEnvironmentOptions);
begin
  SaveDesktopSettings(TheEnvironmentOptions);
end;

procedure TMainIDE.mnuEnvGeneralOptionsClicked(Sender : TObject);
var EnvironmentOptionsDialog: TEnvironmentOptionsDialog;
Begin
  EnvironmentOptionsDialog:=TEnvironmentOptionsDialog.Create(Application);
  try
    with EnvironmentOptionsDialog do begin
      SaveDesktopSettings(EnvironmentOptions);
      OnLoadEnvironmentSettings:=@Self.OnLoadEnvironmentSettings;
      OnSaveEnvironmentSettings:=@Self.OnSaveEnvironmentSettings;
      ReadSettings(EnvironmentOptions);
      if ShowModal=mrOk then begin
        WriteSettings(EnvironmentOptions);
        EnvironmentOptions.Save(false);
      end;
    end;
  finally
    EnvironmentOptionsDialog.Free;
  end;
End;

procedure TMainIDE.mnuEnvEditorOptionsClicked(Sender : TObject);
var EditorOptionsForm: TEditorOptionsForm;
Begin
  EditorOptionsForm:=TEditorOptionsForm.Create(Application);
  try
    if EditorOptionsForm.ShowModal=mrOk then
      SourceNotebook.ReloadEditorOptions;
  finally
    EditorOptionsForm.Free;
  end;
End;

procedure TMainIDE.SaveEnvironment;
begin
  SaveDesktopSettings(EnvironmentOptions);
  EnvironmentOptions.Save(false);
end;
//------------------------------------------------------------------------------

Procedure TMainIDE.MessageViewDblClick(Sender : TObject);
Begin

end;

//==============================================================================

function TMainIDE.DoNewEditorUnit(NewUnitType:TNewUnitType):TModalResult;
var NewUnitInfo:TUnitInfo;
  TempForm : TCustomForm;
  CInterface : TComponentInterface;
  NewSrcEdit: TSourceEditor;
  sl: TStringList;
begin
writeln('TMainIDE.DoNewEditorUnit 1');
  Result:=mrCancel;
  NewUnitInfo:=TUnitInfo.Create;
  with NewUnitInfo do begin
    Loaded:=true;
    IsPartOfProject:=true;
  end;
  if NewUnitType in [nuForm, nuUnit] then begin
    NewUnitInfo.UnitName:=Project.NewUniqueUnitName;
  end;
  Project.AddUnit(NewUnitInfo,true);
  if NewUnitType in [nuForm, nuUnit] then begin
    NewUnitInfo.SyntaxHighlighter:=lshFreePascal;
  end;

  if NewUnitType in [nuForm] then begin
    // clear formeditor
    if not Assigned(FormEditor1) then
      FormEditor1 := TFormEditor.Create;
    FormEditor1.ClearSelected;

    // create jitform
    CInterface := TComponentInterface(
      FormEditor1.CreateComponent(nil,TForm,
        ObjectInspector1.Left+ObjectInspector1.Width+40,Top+Height+50,400,300));
    TempForm:=TForm(CInterface.Control);
    NewUnitInfo.Form:=TempForm;
    SetDefaultsForForm(TempForm);

    NewUnitInfo.FormName:=TempForm.Name;
    Project.AddCreateFormToProjectFile(TempForm.ClassName,TempForm.Name);
  end;

  // create source code
  NewUnitInfo.CreateStartCode(NewUnitType);

  // create a new sourceeditor
  sl:=TStringList.Create;
  sl.Text:=NewUnitInfo.Source.Source;
  SourceNotebook.NewFile(NewUnitInfo.UnitName,sl);
  sl.Free;
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  NewSrcEdit.SyntaxHighlighterType:=NewUnitInfo.SyntaxHighlighter;
  Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex);
  NewUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;

  if NewUnitType in [nuForm] then begin
    // show form
    TDesigner(TempForm.Designer).SourceEditor := SourceNoteBook.GetActiveSE;

    TempForm.Show;
    SetDesigning(TempForm,True);

    // select the new form (object inspector, formeditor, control selection)
    PropertyEditorHook1.LookupRoot := TForm(CInterface.Control);
    TDesigner(TempForm.Designer).SelectOnlyThisComponent(TempForm);
  end;
  UpdateMainUnitSrcEdit;

  FCodeLastActivated:=not (NewUnitType in [nuForm]);
writeln('TMainIDE.DoNewUnit end');

end;

function TMainIDE.DoSaveEditorUnit(PageIndex:integer; 
  SaveAs:boolean):TModalResult;
var ActiveSrcEdit:TSourceEditor;
  ActiveUnitInfo:TUnitInfo;
  SaveDialog:TSaveDialog;
  NewUnitName,NewFilename,NewPageName,ResourceFileName,LFMFilename:string;
  SaveAllParts:boolean;
  MemStream,BinCompStream,TxtCompStream:TMemoryStream;
  Driver: TAbstractObjectWriter;
  Writer:TWriter;
  AText,ACaption,CompResourceCode,s: string;
  ResourceCode: TSourceLog;
  FileStream:TFileStream;
begin
writeln('TMainIDE.DoSaveEditorUnit A PageIndex=',PageIndex);
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
  GetUnitWithPageIndex(PageIndex,ActiveSrcEdit,ActiveUnitInfo);
  if ActiveUnitInfo=nil then exit;
  if (Project.MainUnit>=0) and (Project.Units[Project.MainUnit]=ActiveUnitInfo)
  and (ActiveUnitInfo.Filename='') then begin
    Result:=DoSaveProject(false);
    exit;
  end;

  ActiveUnitInfo.ReadOnly:=ActiveSrcEdit.ReadOnly;
  if ActiveUnitInfo.ReadOnly then begin
    Result:=mrOk;
    exit;
  end;
  if ActiveSrcEdit.Modified then begin
    ActiveUnitInfo.Source.Source:=ActiveSrcEdit.Source.Text;
    ActiveUnitInfo.Modified:=true;
  end;

  // load old resource file
  ResourceFileName:=Project.SearchResourceFilename(ActiveUnitInfo);
  ResourceCode:=TSourceLog.Create('');
  try
    if (ActiveUnitInfo.Filename<>'') and (FileExists(ResourceFileName)) then
    begin
      repeat
        try
          FileStream:=TFileStream.Create(ResourceFileName,fmOpenRead);
          try
            SetLength(s,FileStream.Size);
            FileStream.Read(s[1],length(s));
            ResourceCode.Source:=s;
          finally
            FileStream.Free;
          end;
        except
          ACaption:='File read error';
          AText:='Unable to read file "'+ResourceFilename+'".';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
            ,MB_ABORTRETRYIGNORE);
          if Result=mrAbort then exit;
         if Result=mrIgnore then Result:=mrOk;
        end;
      until Result<>mrRetry;
    end;

    SaveAllParts:=false;
    if ActiveUnitInfo.Filename='' then SaveAs:=true;
    if SaveAs then begin
      // let user choose a filename
      SaveDialog:=TSaveDialog.Create(Application);
      try
        SaveDialog.Title:='Save '+ActiveUnitInfo.UnitName;
        SaveDialog.FileName:=lowercase(ActiveUnitInfo.UnitName)+'.pp';
        SaveDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
        if SaveDialog.Execute then begin
          NewFilename:=ExpandFilename(SaveDialog.Filename);
          EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(NewFilename);
          if ExtractFileExt(NewFilename)='' then
            NewFilename:=NewFilename+'.pp';
          if FileExists(NewFilename) then begin
            ACaption:='Overwrite file?';
            AText:='A file "'+NewFilename+'" already exists. Replace it?';
            Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
              ,MB_OKCANCEL);
            if Result=mrCancel then exit;
          end;
          EnvironmentOptions.AddToRecentOpenFiles(NewFilename);
          ActiveUnitInfo.Filename:=NewFilename;
          ActiveSrcEdit.Filename:=ActiveUnitInfo.Filename;
          NewUnitName:=ExtractFileName(ActiveUnitInfo.Filename);
          NewUnitName:=ChangeFileExt(NewUnitName,'');
          // change unitname in source
          if ActiveUnitInfo.UnitName<>NewUnitName then begin
            ActiveUnitInfo.UnitName:=NewUnitName;
            ActiveSrcEdit.Source.Text:=ActiveUnitInfo.Source.Source;
          end;
          // change unitname on SourceNotebook
          ActiveSrcEdit.UnitName:=NewUnitName;
          NewPageName:=SourceNoteBook.FindUniquePageName(
            ActiveUnitInfo.Filename,SourceNoteBook.NoteBook.PageIndex);
          SourceNoteBook.NoteBook.Pages[SourceNoteBook.NoteBook.PageIndex]:=
            NewPageName;
          ResourceFilename:=ChangeFileExt(ActiveUnitInfo.Filename
              ,ResourceFileExt);
          SaveAllParts:=true;
        end else begin
          // user cancels
          Result:=mrCancel;
          exit;
        end;
      finally
        SaveDialog.Free;
      end;
    end;
    if ActiveUnitInfo.Modified or SaveAllParts then begin
      // save source
      Result:=ActiveUnitInfo.WriteUnitSource;
      if Result=mrAbort then exit;
    end;

    // ToDo: save resources only if modified

    if ActiveUnitInfo.HasResources then begin
      LFMFilename:=ChangeFileExt(ActiveUnitInfo.Filename,'.lfm');

      // save lrs - lazarus resource file and lfm - lazarus form text file

      // stream component to binary stream
      BinCompStream:=TMemoryStream.Create;
      try
        repeat
          try
            BinCompStream.Position:=0;
            Driver:=TBinaryObjectWriter.Create(BinCompStream,4096);
            try
              Writer:=TWriter.Create(Driver);
              try
                Writer.WriteDescendent(ActiveUnitInfo.Form,nil);
              finally
                Writer.Free;
              end;
            finally
              Driver.Free;
            end;
          except
            ACaption:='Streaming error';
            AText:='Unable to stream '
              +ActiveUnitInfo.FormName+':T'+ActiveUnitInfo.FormName+'.';
            Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
              ,MB_ABORTRETRYIGNORE);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrOk;
          end;
        until Result<>mrRetry;
        // create lazarus form resource code
        MemStream:=TMemoryStream.Create;
        try
          BinCompStream.Position:=0;
          BinaryToLazarusResourceCode(BinCompStream,MemStream
            ,'T'+ActiveUnitInfo.FormName,'FORMDATA');
          MemStream.Position:=0;
          SetLength(CompResourceCode,MemStream.Size);
          MemStream.Read(CompResourceCode[1],length(CompResourceCode));
        finally
          MemStream.Free;
        end;
        // replace lazarus form resource code
        if not AddResourceCode(ResourceCode,CompResourceCode) then begin
          ACaption:='Resource error';
          AText:='Unable to add resource '
            +'T'+ActiveUnitInfo.FormName+':FORMDATA to internal file. '
            +'Please report this error.';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption),MB_OKCANCEL);
          if Result=mrCancel then Result:=mrAbort;
          exit;
        end;
        repeat
          try
            // transform binary to text
            TxtCompStream:=TMemoryStream.Create;
            try
              BinCompStream.Position:=0;
              ObjectBinaryToText(BinCompStream,TxtCompStream);
              TxtCompStream.Position:=0;
              // save lfm file
              Result:=DoSaveStreamToFile(TxtCompStream,LFMFilename
                ,ActiveUnitInfo.IsPartOfProject);
              if Result<>mrOk then exit;
            finally
              TxtCompStream.Free;
            end;
          except
            ACaption:='Streaming error';
            AText:='Unable to transform binary component stream of '
               +ActiveUnitInfo.FormName+':T'+ActiveUnitInfo.FormName+' into text.';
            Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
              ,MB_ABORTRETRYIGNORE);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrOk;
          end;
        until Result<>mrRetry;
      finally
        BinCompStream.Free;
      end;
      // save resource file
      Result:=DoBackupFile(ResourceFileName,ActiveUnitInfo.IsPartOfProject);
      if Result=mrAbort then exit;
      repeat
        try
          FileStream:=TFileStream.Create(ResourceFileName,fmCreate);
          try
            FileStream.Write(ResourceCode.Source[1],length(ResourceCode.Source));
          finally
            FileStream.Free;
          end;
        except
          ACaption:='File write error';
          AText:='Unable to write to file "'+ResourceFilename+'".';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
            ,MB_ABORTRETRYIGNORE);
          if Result=mrAbort then exit;
          if Result=mrIgnore then Result:=mrOk;
        end;
      until Result<>mrRetry;
    end;
  finally
    ResourceCode.Free;
  end;
  ActiveUnitInfo.Modified:=false;
  ActiveSrcEdit.Modified:=false;
writeln('TMainIDE.DoSaveCurUnit END');
  Result:=mrOk;
end;

function TMainIDE.DoCloseEditorUnit(PageIndex:integer; 
  SaveFirst: boolean):TModalResult;
var ActiveSrcEdit: TSourceEditor;
  ActiveUnitInfo: TUnitInfo;
  ACaption,AText:string;
  i:integer;
  OldDesigner: TDesigner;
begin
writeln('TMainIDE.DoCloseEditorUnit A PageIndex=',PageIndex);
  Result:=mrCancel;
  GetUnitWithPageIndex(PageIndex,ActiveSrcEdit,ActiveUnitInfo);
  if ActiveUnitInfo=nil then exit;
  ActiveUnitInfo.ReadOnly:=ActiveSrcEdit.ReadOnly;
  ActiveUnitInfo.TopLine:=ActiveSrcEdit.EditorComponent.TopLine;
  ActiveUnitInfo.CursorPos:=ActiveSrcEdit.EditorComponent.CaretXY;
  if SaveFirst and (not ActiveUnitInfo.ReadOnly) 
  and ((ActiveSrcEdit.Modified) or (ActiveUnitInfo.Modified)) then begin
    if ActiveUnitInfo.Filename<>'' then
      AText:='File "'+ActiveUnitInfo.Filename+'" has changed. Save?'
    else if ActiveUnitInfo.UnitName<>'' then
      AText:='Unit "'+ActiveUnitInfo.Unitname+'" has changed. Save?'
    else
      AText:='Source of page "'+
        SourceNotebook.NoteBook.Pages[SourceNotebook.NoteBook.PageIndex]
        +'" has changed. Save?';
    ACaption:='Source mofified';
    if Application.MessageBox(PChar(AText),PChar(ACaption),MB_YESNO)=mrYes then
    begin
      Result:=DoSaveEditorUnit(PageIndex,false);
      if Result=mrAbort then exit;
    end;
    Result:=mrOk;
  end;
  // close form
  if ActiveUnitInfo.Form<>nil then begin
    for i:=0 to TWinControl(ActiveUnitInfo.Form).ComponentCount-1 do
      TheControlSelection.Remove(
        TWinControl(ActiveUnitInfo.Form).Components[i]);
    TheControlSelection.Remove(TControl(ActiveUnitInfo.Form));
    OldDesigner:=TDesigner(TCustomForm(ActiveUnitInfo.Form).Designer);
    FormEditor1.DeleteControl(ActiveUnitInfo.Form);
    OldDesigner.Free;
    ActiveUnitInfo.Form:=nil;
  end;
  // close source editor
  SourceNoteBook.CloseFile(PageIndex);
  // close project file (not remove)
  Project.CloseEditorIndex(ActiveUnitInfo.EditorIndex);
  ActiveUnitInfo.Loaded:=false;
  i:=Project.IndexOf(ActiveUnitInfo);
  if (i<>Project.MainUnit) and (ActiveUnitInfo.Filename='') then begin
    Project.RemoveUnit(i);
    UpdateMainUnitSrcEdit;
  end;
writeln('TMainIDE.DoCloseEditorUnit end');
  Result:=mrOk;
end;

function TMainIDE.DoOpenEditorFile(AFileName:string; 
  ProjectLoading:boolean):TModalResult;
var Ext,ACaption,AText:string;
  i,BookmarkID,ProgramNameStart,ProgramNameEnd:integer;
  ReOpen:boolean;
  NewUnitInfo:TUnitInfo;
  NewPageName, NewLFMFilename, NewProgramName, NewSource: string;
  NewSrcEdit: TSourceEditor;
  TxtLFMStream, BinLFMStream, SrcStream:TMemoryStream;
  CInterface: TComponentInterface;
  TempForm: TCustomForm;
  sl: TStringList;
begin
writeln('TMainIDE.DoOpenEditorFile "',AFilename,'"');
  Result:=mrCancel;
  if AFileName='' then exit;
  Ext:=lowercase(ExtractFileExt(AFilename));
  if (not ProjectLoading) and (ToolStatus=itNone)
  and ((Ext='.lpi') or (Ext='.lpr')) then begin
    // load program file and project info file
    Result:=DoOpenProjectFile(AFilename);
    exit;
  end;
  // check if the project knows this file
  i:=Project.UnitCount-1;
  while (i>=0) and (Project.Units[i].Filename<>AFileName) do dec(i);
  Reopen:=(i>=0);
  if ReOpen then begin
    NewUnitInfo:=Project.Units[i];
    if (not ProjectLoading) and NewUnitInfo.Loaded then begin
      // file already open -> change to page
      SourceNoteBook.NoteBook.PageIndex:=NewUnitInfo.EditorIndex;
      Result:=mrOk;
      exit;
    end;
  end else begin
    SrcStream:=TMemoryStream.Create;
    try
      Result:=DoLoadMemoryStreamFromFile(SrcStream,AFilename);
      if (Result in [mrAbort, mrIgnore]) then exit;
      if Result=mrOk then begin
        SetLength(NewSource,SrcStream.Size);
        SrcStream.Read(NewSource[1],length(NewSource));
        // check if unit is a program
        if (not ProjectLoading) and (not ReOpen)
        and ((Ext='.pp') or (Ext='.pas') or (Ext='.dpr') or (Ext='.lpr')) then
        begin
          NewProgramName:=FindProgramNameInSource(NewSource,
             ProgramNameStart,ProgramNameEnd);
          if NewProgramName<>'' then begin
            if FileExists(ChangeFileExt(AFilename,'.lpi')) then begin
              AText:='The file "'+AFilename+'"'
                 +' seems to be the program file of an existing lazarus project.'
                 +' Open project? Cancel will load the source.';
              ACaption:='Project info file detected';
              if Application.MessageBox(PChar(AText),PChar(ACaption)
                  ,MB_OKCANCEL)=mrOk then begin
                Result:=DoOpenProjectFile(ChangeFileExt(AFilename,'.lpi'));
                exit;
              end;
            end else begin
              AText:='The file "'+AFilename+'"'
                +' seems to be a program. Close current project'
                +' and create a new lazarus project for this program?'
                +'  Cancel will load the source.';
              ACaption:='Program detected';
              if Application.MessageBox(PChar(AText),PChar(ACaption)
                 ,MB_OKCANCEL)=mrOK then begin
                Result:=DoCreateProjectForProgram(AFilename,NewSource);
                exit;
              end;
            end;
          end;
        end;
      end;
    finally
      SrcStream.Free;
    end;
    NewUnitInfo:=TUnitInfo.Create;
    NewUnitInfo.Filename:=AFilename;
    Project.AddUnit(NewUnitInfo,false);
  end;
  Result:=NewUnitInfo.ReadUnitSource((Ext='.pp') or (Ext='.pas'));
  if Result<>mrOk then begin
    if not ReOpen then begin
      // this was a new file -> remove the NewUnitInfo
      Project.RemoveUnit(Project.IndexOf(NewUnitInfo));
      NewUnitInfo.Free;
    end else
      NewUnitInfo.Loaded:=false;
    exit;
  end;
  // create a new source editor
  NewUnitInfo.SyntaxHighlighter:=ExtensionToLazSyntaxHighlighter(Ext);
  NewPageName:=NewUnitInfo.UnitName;
  if NewPageName='' then begin
    NewPageName:=ExtractFileName(AFilename);
    NewPageName:=copy(NewPageName,1,length(NewPageName)-length(Ext));
    if NewpageName='' then NewPageName:='file';
  end;
  sl:=TStringList.Create;
  sl.Text:=NewUnitInfo.Source.Source;
  SourceNotebook.NewFile(NewPageName,sl);
  sl.Free;
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  if not ProjectLoading then
    Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex)
  else begin
    for BookmarkID:=0 to 9 do begin
      i:=Project.Bookmarks.IndexOfID(BookmarkID);
      if (i>=0) and (Project.Bookmarks[i].EditorIndex=NewUnitInfo.EditorIndex)
      then begin
        NewSrcEdit.EditorComponent.SetBookmark(BookmarkID,
           Project.Bookmarks[i].CursorPos.X,Project.Bookmarks[i].CursorPos.Y);
        while i>=0 do begin
          Project.Bookmarks.Delete(i);
          i:=Project.Bookmarks.IndexOfID(BookmarkID);
        end;
      end;
    end;
  end;
  NewUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;
  NewSrcEdit.SyntaxHighlighterType:=NewUnitInfo.SyntaxHighlighter;
  NewSrcEdit.EditorComponent.CaretXY:=NewUnitInfo.CursorPos;
  NewSrcEdit.EditorComponent.TopLine:=NewUnitInfo.TopLine;
  NewSrcEdit.EditorComponent.LeftChar:=1;
  
  NewUnitInfo.Loaded:=true;
  // read form data
  if (NewUnitInfo.Unitname<>'') then begin
    // this is a unit -> try to find the lfm file
    NewLFMFilename:=ChangeFileExt(NewUnitInfo.Filename,'.lfm');
    if FileExists(NewLFMFilename) then begin
      // there is a lazarus form text file -> load it
      BinLFMStream:=TMemoryStream.Create;
      try
        TxtLFMStream:=TMemoryStream.Create;
        try
          Result:= DoLoadMemoryStreamFromFile(TxtLFMStream,NewLFMFileName);
          if Result<>mrOk then exit;
          // convert text to binary format
          try
            ObjectTextToBinary(TxtLFMStream,BinLFMStream);
            BinLFMStream.Position:=0;
            Result:=mrOk;
          except
            on E: Exception do begin
              ACaption:='Format error';
              AText:='Unable to convert text form data of file "'
                 +NewLFMFilename+'" into binary stream. ('+E.Message+')';
              Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
                 ,MB_OKCANCEL);
              if Result=mrCancel then begin
                Result:=mrAbort;
                exit;
              end;
            end;
          end;
        finally
          TxtLFMStream.Free;
        end;
        if not Assigned(FormEditor1) then
          FormEditor1 := TFormEditor.Create;
        if not ProjectLoading then FormEditor1.ClearSelected;

        // create jitform
        CInterface := TComponentInterface(
          FormEditor1.CreateFormFromStream(BinLFMStream));
        if CInterface=nil then begin
          ACaption:='Form load error';
          AText:='Unable to build form from file "'
             +NewLFMFilename+'".';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
             ,MB_OKCANCEL);
          if Result=mrCancel then begin
            Result:=mrAbort;
            exit;
          end;
        end;
        TempForm:=TForm(CInterface.Control);
        NewUnitInfo.Form:=TempForm;
        SetDefaultsForForm(TempForm);
        NewUnitInfo.FormName:=TempForm.Name;
        // show form
        TDesigner(TempForm.Designer).SourceEditor := SourceNoteBook.GetActiveSE;

        if not ProjectLoading then begin
          TempForm.Show;
          FCodeLastActivated:=false;
        end;
        SetDesigning(TempForm,True);
        
        // select the new form (object inspector, formeditor, control selection)
        if not ProjectLoading then begin
          PropertyEditorHook1.LookupRoot := TForm(CInterface.Control);
          TDesigner(TempForm.Designer).SelectOnlyThisComponent(TempForm);
        end;
writeln('TMainIDE.DoOpenEditorFile  LFM end');
      finally
        BinLFMStream.Free;
      end;
    end;
  end;
  Result:=mrOk;
writeln('TMainIDE.DoOpenEditorFile END "',AFilename,'"');
end;

function TMainIDE.DoOpenMainUnit(ProjectLoading: boolean): TModalResult;
var MainUnitInfo: TUnitInfo;
  NewPageName: string;
  NewSrcEdit: TSourceEditor;
  ProgramNameStart,ProgramNameEnd: integer;
  sl: TStringList;
begin
writeln('[TMainIDE.DoOpenMainUnit] A');
  Result:=mrCancel;
  if Project.MainUnit<0 then exit;
  MainUnitInfo:=Project.Units[Project.MainUnit];
  if MainUnitInfo.Loaded then begin
    // already loaded switch to source editor
    SourceNotebook.NoteBook.PageIndex:=MainUnitInfo.EditorIndex;
    Result:=mrOk;
    exit;
  end;
  // MainUnit not loaded -> create source editor
  NewPageName:=MainUnitInfo.Unitname;
  if NewPageName='' then begin
    NewPageName:=ExtractFileName(MainUnitInfo.Filename);
    NewPageName:=copy(NewPageName,1,
      length(NewPageName)-length(ExtractFileExt(NewPageName)));
  end;
  if NewpageName='' then begin
    NewPageName:=FindProgramNameInSource(MainUnitInfo.Source.Source
      ,ProgramNameStart,ProgramNameEnd);
  end;
  if NewpageName='' then begin
    NewPageName:='mainunit';
  end;
  sl:=TStringList.Create;
  sl.Text:=MainUnitInfo.Source.Source;
  SourceNotebook.NewFile(NewPageName,sl);
  sl.Free;
  if not ProjectLoading then
    Project.InsertEditorIndex(SourceNotebook.NoteBook.PageIndex);
  MainUnitInfo.EditorIndex:=SourceNotebook.NoteBook.PageIndex;
  MainUnitInfo.Loaded:=true;
  NewSrcEdit:=SourceNotebook.GetActiveSE;
  NewSrcEdit.SyntaxHighlighterType:=MainUnitInfo.SyntaxHighlighter;
  NewSrcEdit.EditorComponent.CaretXY:=MainUnitInfo.CursorPos;
  NewSrcEdit.EditorComponent.TopLine:=MainUnitInfo.TopLine;
  Result:=mrOk;
writeln('[TMainIDE.DoOpenMainUnit] END');
end;

function TMainIDE.DoViewUnitsAndForms(OnlyForms: boolean): TModalResult;
var UnitList: TList;
  i, ProgramNameStart, ProgramNameEnd:integer;
  MainUnitName, Ext, DlgCaption: string;
  MainUnitInfo, AnUnitInfo: TUnitInfo;
  MainUnitIndex: integer;
Begin
  UnitList:= TList.Create;
  try
    MainUnitIndex:=-1;
    for i:=0 to Project.UnitCount-1 do begin
      if Project.Units[i].IsPartOfProject then begin
        if OnlyForms then begin
          if Project.MainUnit=i then MainUnitIndex:=i;
          if Project.Units[i].FormName<>'' then
            UnitList.Add(TViewUnitsEntry.Create(
              Project.Units[i].FormName,i,false));
        end else begin
          if Project.Units[i].UnitName<>'' then begin
            if Project.MainUnit=i then MainUnitIndex:=i;
            UnitList.Add(TViewUnitsEntry.Create(
              Project.Units[i].UnitName,i,false));
          end else if Project.MainUnit=i then begin
            MainUnitInfo:=Project.Units[Project.MainUnit];
            if Project.ProjectType in [ptProgram,ptApplication,ptCustomProgram]
            then begin
              if (MainUnitInfo.Loaded) then
                MainUnitName:=SourceNoteBook.NoteBook.Pages[
                  MainUnitInfo.EditorIndex];
              if MainUnitName='' then begin
                MainUnitName:=FindProgramNameInSource(MainUnitInfo.Source.Source
                  ,ProgramNameStart,ProgramNameEnd);
              end;
              if MainUnitName='' then begin
                MainUnitName:=ExtractFileName(MainUnitInfo.Filename);
                Ext:=ExtractFileExt(MainUnitName);
                MainUnitName:=copy(MainUnitName,1,length(MainUnitName)-length(Ext));
              end;
              if MainUnitName<>'' then begin
                MainUnitIndex:=UnitList.Count;
                UnitList.Add(TViewUnitsEntry.Create(
                  MainUnitName,i,false));
              end;
            end;
          end;
        end;
      end;
    end;
    if OnlyForms then
      DlgCaption:='View forms'
    else
      DlgCaption:='View units';
    if ShowViewUnitsDlg(UnitList,true,DlgCaption)=mrOk then begin
      for i:=0 to UnitList.Count-1 do begin
        if TViewUnitsEntry(UnitList[i]).Selected then begin
          AnUnitInfo:=Project.Units[TViewUnitsEntry(UnitList[i]).ID];
          if AnUnitInfo.Loaded then
            SourceNoteBook.NoteBook.PageIndex:=AnUnitInfo.EditorIndex
          else begin
            if MainUnitIndex=i then
              Result:=DoOpenMainUnit(false)
            else
              Result:=DoOpenEditorFile(AnUnitInfo.Filename,false);
            if Result=mrAbort then exit;
          end;
        end;
      end;
      FCodeLastActivated:=not OnlyForms;
      DoBringToFrontFormOrUnit;
    end;
  finally
    UnitList.Free;
  end;
  Result:=mrOk;
end;

function TMainIDE.DoOpenFileAtCursor(Sender: TObject):TModalResult;
begin
writeln('TMainIDE.DoOpenFileAtCursor');
  Result:=mrCancel;
  // ToDo
  // check if include, unit, or simply a filename
end;

function TMainIDE.DoNewProject(NewProjectType:TProjectType):TModalResult;
var i:integer;
Begin
writeln('TMainIDE.DoNewProject 1');
  Result:=mrCancel;

  If Project<>nil then begin
    if SomethingOfProjectIsModified then begin
      if Application.MessageBox('Save changes to project?','Project changed'
          ,MB_YESNO)=mrYES then begin
        if DoSaveProject(false)=mrAbort then begin
          Result:=mrAbort;
          exit;
        end;
      end;
    end;
    if DoCloseProject=mrAbort then begin
      Result:=mrAbort;
      exit;
    end;
  end;

  Project:=TProject.Create(NewProjectType);
  Project.OnFileBackup:=@DoBackupFile;
  Project.Title := 'Project1';
  Project.CompilerOptions.CompilerPath:='$(CompPath)';
  SourceNotebook.SearchPaths:=Project.CompilerOptions.OtherUnitFiles;

  case NewProjectType of
   ptApplication:
    begin
      // create a first form unit
      Project.CompilerOptions.OtherUnitFiles:=
         '$(LazarusDir)'+OSDirSeparator+'lcl'+OSDirSeparator+'units'
        +';'+
         '$(LazarusDir)'+OSDirSeparator+'lcl'+OSDirSeparator+'units'
         +OSDirSeparator+'gtk';
      DoNewEditorUnit(nuForm);
    end;
   ptProgram,ptCustomProgram:
    begin
      // show program unit
      DoOpenMainUnit(false);
    end;
  end;
 
  // set all modified to false
  for i:=0 to Project.UnitCount-1 do begin
    Project.Units[i].Modified:=false;
  end;
  Project.Modified:=false;

writeln('TMainIDE.DoNewProject end ');
  UpdateCaption;
  Result:=mrOk;
end;

function TMainIDE.DoSaveProject(SaveAs:boolean):TModalResult;
var MainUnitSrcEdit, ASrcEdit: TSourceEditor;
  MainUnitInfo, AnUnitInfo: TUnitInfo;
  SaveDialog: TSaveDialog;
  NewFilename, NewProgramFilename, NewPageName, AText, ACaption, Ext: string;
  i, BookmarkID, BookmarkX, BookmarkY :integer;
begin
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
writeln('TMainIDE.DoSaveProject A');
  // check that all new units are saved first
  for i:=0 to Project.UnitCount-1 do begin
    if (Project.Units[i].Loaded) and (Project.Units[i].Filename='')
    and (Project.MainUnit<>i) then begin
      Result:=DoSaveEditorUnit(Project.Units[i].EditorIndex,false);
      if (Result=mrAbort) or (Result=mrCancel) then exit;
    end;
  end;

  if SourceNotebook.Notebook=nil then
    Project.ActiveEditorIndexAtStart:=-1
  else
    Project.ActiveEditorIndexAtStart:=SourceNotebook.Notebook.PageIndex;
  MainUnitSrcEdit:=nil;
  if Project.MainUnit>=0 then begin
    MainUnitInfo:=Project.Units[Project.MainUnit];
    if MainUnitInfo.Loaded then begin
      MainUnitSrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
        MainUnitInfo.EditorIndex);
      if MainUnitSrcEdit.Modified then begin
        MainUnitInfo.Source.Source:=MainUnitSrcEdit.Source.Text;
        MainUnitInfo.Modified:=true;
      end;
    end;
  end else
    MainUnitInfo:=nil;

  // save some information of the loaded files
  Project.Bookmarks.Clear;
  for i:=0 to Project.UnitCount-1 do begin
    AnUnitInfo:=Project.Units[i];
    if AnUnitInfo.Loaded then begin
      ASrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
         AnUnitInfo.EditorIndex);
      AnUnitInfo.TopLine:=ASrcEdit.EditorComponent.TopLine;
      AnUnitInfo.CursorPos:=ASrcEdit.EditorComponent.CaretXY;
      for BookmarkID:=0 to 9 do begin
        if (ASrcEdit.EditorComponent.GetBookMark(BookmarkID,BookmarkX,BookmarkY))
        and (Project.Bookmarks.IndexOfID(BookmarkID)<0) then begin
          Project.Bookmarks.Add(TProjectBookmark.Create(BookmarkX,BookmarkX,
              AnUnitInfo.EditorIndex,BookmarkID));
        end;
      end;
    end;
  end;

  SaveAs:=SaveAs or (Project.ProjectFile='');
  if SaveAs then begin
    // let user choose a filename
    SaveDialog:=TSaveDialog.Create(Application);
    try
      SaveDialog.Title:='Save Project '+Project.Title;
      if ExtractFileName(Project.ProjectFile)<>'' then
        SaveDialog.FileName:=ExtractFileName(Project.ProjectFile)
      else if Project.Title<>'' then
        SaveDialog.Filename:=ChangeFileExt(Project.Title,'.lpi')
      else if SaveDialog.Filename='' then
        SaveDialog.Filename:='Project1.lpi';
      repeat
        SaveDialog.InitialDir:=EnvironmentOptions.LastOpenDialogDir;
        if SaveDialog.Execute then begin
          NewFilename:=ExpandFilename(SaveDialog.Filename);
          EnvironmentOptions.LastOpenDialogDir:=ExtractFilePath(NewFilename);
          if ExtractFileExt(NewFilename)='' then
            NewFilename:=NewFilename+'.lpi';
          NewProgramFilename:=ChangeFileExt(
            NewFilename,ProjectDefaultExt[Project.ProjectType]);
          if NewFilename=NewProgramFilename then begin
            ACaption:='Choose a different name';
            AText:='The project info file is "'+NewFilename+'" equal '
               +'to the project source file!';
            Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
              ,MB_ABORTRETRYIGNORE);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrRetry;
          end else
            Result:=mrOk;
        end else begin
          // user cancels
          Result:=mrCancel;
          exit;
        end;
      until Result<>mrRetry;

      if FileExists(NewFilename) then begin
        ACaption:='Overwrite file?';
        AText:='A file "'+NewFilename+'" already exists. Replace it?';
        Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
          ,MB_OKCANCEL);
        //Result:=MessageDlg(AText,mtConfirmation,[mbOk,mbCancel],0);
        if Result=mrCancel then exit;
      end else if Project.ProjectType in [ptProgram, ptApplication] then begin
        if FileExists(NewProgramFilename) then begin
          ACaption:='Overwrite file?';
          AText:='A file "'+NewProgramFilename+'" already exists. Replace it?';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
            ,MB_OKCANCEL);
          if Result=mrCancel then exit;
        end;
      end;
      Project.ProjectFile:=NewFilename;
      EnvironmentOptions.AddToRecentProjectFiles(NewFilename);
      if (MainUnitInfo<>nil) and (MainUnitInfo.Loaded) then begin
        // update source editor of main unit
        MainUnitSrcEdit.Source.Text:=MainUnitInfo.Source.Source;
        MainUnitSrcEdit.Filename:=MainUnitInfo.Filename;
        NewPageName:=ExtractFileName(MainUnitInfo.Filename);
        Ext:=ExtractFileExt(NewPagename);
        NewPageName:=copy(NewpageName,1,length(NewPageName)-length(Ext));
        NewPageName:=SourceNoteBook.FindUniquePageName(
          NewPageName,MainUnitInfo.EditorIndex);
        SourceNoteBook.NoteBook.Pages[MainUnitInfo.EditorIndex]:=
          NewPageName;
      end;
    finally
      SaveDialog.Free;
    end;
  end;
  Result:=Project.WriteProject;
  // save source
  if MainUnitInfo<>nil then begin
    if MainUnitInfo.Loaded then begin
      Result:=DoSaveEditorUnit(MainUnitInfo.EditorIndex,false);
      if Result=mrAbort then exit;
    end else begin
      Result:=MainUnitInfo.WriteUnitSource;
      if Result=mrAbort then exit;
    end;
  end;
  EnvironmentOptions.LastSavedProjectFile:=Project.ProjectInfoFile;
  EnvironmentOptions.Save(false);
  if Result=mrOk then begin
    if MainUnitInfo<>nil then MainUnitInfo.Modified:=false;
    if MainUnitSrcEdit<>nil then MainUnitSrcEdit.Modified:=false;
  end;
  UpdateMainUnitSrcEdit;
  UpdateCaption;
writeln('TMainIDE.DoSaveProject End');
end;

function TMainIDE.DoCloseProject:TModalResult;
begin
writeln('TMainIDE.DoCloseProject 1');
  // close all loaded files
  while SourceNotebook.NoteBook<>nil do begin
    Result:=DoCloseEditorUnit(SourceNotebook.Notebook.Pages.Count-1,false);
    if Result=mrAbort then exit;
  end;
  // close Project
  Project.Free;
  Project:=nil;
  Result:=mrOk;
writeln('TMainIDE.DoCloseProject end');
end;

function TMainIDE.DoOpenProjectFile(AFileName:string):TModalResult;
var Ext,AText,ACaption,LPIFilename:string;
  LowestEditorIndex,LowestUnitIndex,LastEditorIndex,i:integer;
  SrcStream: TMemoryStream;
  NewSource: string;
begin
writeln('TMainIDE.DoOpenProjectFile A "'+AFileName+'"');
  Result:=mrCancel;
  if AFileName='' then exit;
  AFilename:=ExpandFileName(AFilename);
  Ext:=lowercase(ExtractFileExt(AFilename));
  if (Ext='.lpr') and (FileExists(ChangeFileExt(AFileName,'.lpi'))) then begin
    // load instead of lazarus program file the project info file
    AFileName:=ChangeFileExt(AFileName,'.lpi');
    Ext:='.lpi';
  end;
  repeat
    if not FileExists(AFilename) then begin
      ACaption:='File not found';
      AText:='File "'+AFilename+'" not found.';
      Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
         ,MB_ABORTRETRYIGNORE);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
  // close the old project
  if SomethingOfProjectIsModified then begin
    if Application.MessageBox('Save changes to project?','Project changed'
      ,MB_OKCANCEL)=mrOK then begin
      if DoSaveProject(false)=mrAbort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
  end;
  Result:=DoCloseProject;
  if Result=mrAbort then exit;
  // create a new one
  LPIFilename:=ChangeFileExt(AFilename,'.lpi');
  Project:=TProject.Create(ptProgram);
  Project.ReadProject(LPIFilename);
  if Project.MainUnit>=0 then begin
    // read MainUnit Source
    SrcStream:=TMemoryStream.Create;
    try
      Result:=DoLoadMemoryStreamFromFile(SrcStream
           ,Project.Units[Project.MainUnit].Filename);
      if Result=mrAbort then exit;
      SetLength(NewSource,SrcStream.Size);
      SrcStream.Read(NewSource[1],length(NewSource));
      Project.Units[Project.MainUnit].Source.Source:=NewSource;
    finally
      SrcStream.Free;
    end;
  end;
  UpdateCaption;
  // restore files
  LastEditorIndex:=-1;
  repeat
    LowestUnitIndex:=-1;
    LowestEditorIndex:=-1;
    for i:=0 to Project.UnitCount-1 do begin
      if (Project.Units[i].Loaded) then begin
        if (Project.Units[i].EditorIndex>LastEditorIndex)
        and ((Project.Units[i].EditorIndex<LowestEditorIndex)
             or (LowestEditorIndex<0)) then
        begin
          LowestEditorIndex:=Project.Units[i].EditorIndex;
          LowestUnitIndex:=i;
        end;
      end;
    end;
    if LowestEditorIndex>=0 then begin
      // reopen file
      Result:=DoOpenEditorFile(Project.Units[LowestUnitIndex].Filename,true);
      if Result=mrAbort then exit;
      if Project.ActiveEditorIndexAtStart=LowestEditorIndex then
        Project.ActiveEditorIndexAtStart:=SourceNoteBook.NoteBook.PageIndex;
      LastEditorIndex:=LowestEditorIndex;
    end;
  until LowestEditorIndex<0;
  // set active editor source editor
  if (SourceNoteBook.NoteBook<>nil) and (Project.ActiveEditorIndexAtStart>=0)
  and (Project.ActiveEditorIndexAtStart<SourceNoteBook.NoteBook.Pages.Count)
  then
    SourceNoteBook.Notebook.PageIndex:=Project.ActiveEditorIndexAtStart;

  // set all modified to false
  for i:=0 to Project.UnitCount-1 do begin
    Project.Units[i].Modified:=false;
  end;
  Project.Modified:=false;
  EnvironmentOptions.LastSavedProjectFile:=Project.ProjectInfoFile;
  EnvironmentOptions.Save(false);
writeln('TMainIDE.DoOpenProjectFile end ');
end;

function TMainIDE.DoCreateProjectForProgram(ProgramFilename
  ,ProgramSource: string): TModalResult;
var NewProjectType:TProjectType;
  ProgramTitle, Ext: string;
  MainUnitInfo: TUnitInfo;
begin
writeln('[TMainIDE.DoCreateProjectForProgram] 1');
  Result:=mrCancel;

  if SomethingOfProjectIsModified then begin
    if Application.MessageBox('Save changes to project?','Project changed'
        ,MB_OKCANCEL)=mrOK then begin
      if DoSaveProject(false)=mrAbort then begin
        Result:=mrAbort;
        exit;
      end;
    end;
  end;

  // let user choose the program type
  if ChooseNewProject(NewProjectType)=mrCancel then exit;

  // close old project
  If Project<>nil then begin
    if DoCloseProject=mrAbort then begin
      Result:=mrAbort;
      exit;
    end;
  end;

  // create a new project
  Project:=TProject.Create(NewProjectType);
  Project.OnFileBackup:=@DoBackupFile;
  ProgramTitle:=ExtractFileName(ProgramFilename);
  Ext:=ExtractFileExt(ProgramTitle);
  ProgramTitle:=copy(ProgramTitle,1,length(ProgramTitle)-length(Ext));
  Project.Title:=ProgramTitle;
  SourceNotebook.SearchPaths:=Project.CompilerOptions.OtherUnitFiles;
  MainUnitInfo:=Project.Units[Project.MainUnit];
  MainUnitInfo.Source.Source:=ProgramSource;
  Project.ProjectFile:=ProgramFilename;
  Project.CompilerOptions.CompilerPath:='$(CompPath)';
  if NewProjectType=ptApplication then begin
    Project.CompilerOptions.OtherUnitFiles:=
       '$(LazarusDir)'+OSDirSeparator+'lcl'+OSDirSeparator+'units'
      +';'+
       '$(LazarusDir)'+OSDirSeparator+'lcl'+OSDirSeparator+'units'
       +OSDirSeparator+'gtk';
  end;

  // show program unit
  Result:=DoOpenMainUnit(false);
  if Result=mrAbort then exit;
 
  UpdateCaption;

writeln('[TMainIDE.DoCreateProjectForProgram] END');
  Result:=mrOk;
end;

function TMainIDE.DoAddActiveUnitToProject: TModalResult;
var
  ActiveSourceEditor:TSourceEditor; 
  ActiveUnitInfo:TUnitInfo;
  s, ShortUnitName: string;
  UnitNameStart, UnitNameEnd: integer;
begin
  Result:=mrCancel;
  GetCurrentUnit(ActiveSourceEditor,ActiveUnitInfo);
  if ActiveUnitInfo<>nil then begin
    if ActiveUnitInfo.IsPartOfProject=false then begin
      if ActiveUnitInfo.Filename<>'' then
        s:='"'+ActiveUnitInfo.Filename+'"'
      else
        s:='"'+SourceNotebook.Notebook.Pages[SourceNotebook.Notebook.PageIndex]
          +'"';
      if (Project.ProjectType in [ptProgram, ptApplication])
      and (ActiveUnitInfo.UnitName<>'')
      and (Project.IndexOfUnitWithName(ActiveUnitInfo.UnitName,true)>=0) then
      begin
        MessageDlg('Unable to add '+s+' to project, because there is already a '
           +'unit with the same name in the project.',mtInformation,[mbOk],0);
      end else begin
        if MessageDlg('Add '+s+' to project?',mtConfirmation,[mbOk,mbCancel],0)
          =mrOk then
        begin
          ActiveUnitInfo.IsPartOfProject:=true;
          if (ActiveUnitInfo.UnitName<>'')
          and (Project.ProjectType in [ptProgram, ptApplication]) then begin
            ShortUnitName:=FindUnitNameInSource(ActiveUnitInfo.Source.Source,
              UnitNameStart,UnitNameEnd);
            if ShortUnitName='' then ShortUnitName:=ActiveUnitInfo.UnitName;
            if (ShortUnitName<>'') then
              AddToProgramUsesSection(Project.Units[Project.MainUnit].Source
                ,ShortUnitName,'');
          end;
          Project.Modified:=true;
        end;
      end;
    end else begin
      if ActiveUnitInfo.Filename<>'' then
        s:='The file "'+ActiveUnitInfo.Filename+'"'
      else
        s:='The file "'
          +SourceNotebook.Notebook.Pages[SourceNotebook.Notebook.PageIndex]
          +'"';
      s:=s+' is already part of the project.';
      MessageDlg(s,mtInformation,[mbOk],0);
    end;
  end else begin
    Result:=mrOk;
  end;
end;

function TMainIDE.DoRemoveFromProjectDialog: TModalResult;
var UnitList: TList;
  i:integer;
  AName: string;
  AnUnitInfo: TUnitInfo;
Begin
  UnitList:=TList.Create;
  try
    for i:=0 to Project.UnitCount-1 do begin
      AnUnitInfo:=Project.Units[i];
      if (AnUnitInfo.IsPartOfProject) and (i<>Project.MainUnit) then begin
        AName:=AnUnitInfo.FileName;
        if (AName='') and (AnUnitInfo.Loaded) then begin
          AName:=SourceNotebook.NoteBook.Pages[AnUnitInfo.EditorIndex];
        end;
        if AName<>'' then
          UnitList.Add(TViewUnitsEntry.Create(AName,i,false));
      end;
    end;
    if ShowViewUnitsDlg(UnitList,true,'Remove from project')=mrOk then begin
      for i:=0 to UnitList.Count-1 do begin
        if TViewUnitsEntry(UnitList[i]).Selected then begin
          AnUnitInfo:=Project.Units[TViewUnitsEntry(UnitList[i]).ID];
          AnUnitInfo.IsPartOfProject:=false;
          if (Project.MainUnit>=0)
          and (Project.ProjectType in [ptProgram, ptApplication]) then begin
            if (AnUnitInfo.UnitName<>'') then
              RemoveFromProgramUsesSection(
                Project.Units[Project.MainUnit].Source,AnUnitInfo.UnitName);
            if (AnUnitInfo.FormName<>'') then
              Project.RemoveCreateFormFromProjectFile(
                  'T'+AnUnitInfo.FormName,AnUnitInfo.FormName);
            UpdateMainUnitSrcEdit;
          end;
        end;
      end;
    end;
  finally
    UnitList.Free;
  end;
  Result:=mrOk;
end;

function TMainIDE.DoBuildProject: TModalResult;
var ActiveSrcEdit: TSourceEditor;
begin
  Result:=mrCancel;
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
  try
    if not (Project.ProjectType in [ptProgram, ptApplication, ptCustomProgram])
    then exit;
    DoSaveAll;
    Assert(False, 'Trace:Build Project Clicked');
    if Project=nil then Begin
      Application.MessageBox('Create a project first!','Error',mb_ok);
      Exit;
    end;
    ActiveSrcEdit:=SourceNotebook.GetActiveSE;
    if ActiveSrcEdit<>nil then ActiveSrcEdit.ErrorLine:=-1;

    ToolStatus:=itBuilder;
    MessagesView.Clear;
    DoShowMessagesView;

    if (SourceNotebook.Top+SourceNotebook.Height) > MessagesView.Top then
      SourceNotebook.Height := Max(50,Min(SourceNotebook.Height,
         MessagesView.Top-SourceNotebook.Top));
    Compiler1.OnOutputString:=@MessagesView.Add;
    Result:=Compiler1.Compile(Project);
    if Result=mrOk then begin
      MessagesView.MessageView.Items.Add(
        'Project "'+Project.Title+'" successfully built. :)');
    end else begin
      DoJumpToCompilerMessage(-1,true);
    end;
  finally
    ToolStatus:=itNone;
  end;
end;

function TMainIDE.DoRunProject: TModalResult;
// quick hack to start programs
// ToDo:
//  -switch the IDE mode to running and free the process when program terminates
//  -implement a better messages form for vast amount of output
//  -target filename
//  -command line parameters
//  -connect program to debugger
var
  TheProcess : TProcess;
  ProgramFilename, Ext, AText : String;
begin
  Result:=mrCancel;
writeln('[TMainIDE.DoRunProject] A');
  if ToolStatus<>itNone then begin
    Result:=mrAbort;
    exit;
  end;
  if not (Project.ProjectType in [ptProgram, ptApplication, ptCustomProgram])
  then exit;

  Ext:=ExtractFileExt(Project.ProjectFile);
  ProgramFilename := LowerCase(copy(Project.ProjectFile,1,
                          length(Project.ProjectFile)-length(Ext)));

  if not FileExists(ProgramFilename) then begin
    AText:='No program file "'+ProgramFilename+'" found!';
    Application.MessageBox(PChar(AText),'File not found',MB_OK);
    exit;
  end;

  try
    TheProcess:=TProcess.Create(ProgramFilename,
       [poRunSuspended,poUsePipes,poNoConsole]);
    TheProcess.Execute;
  except
    on e: Exception do begin
      AText:='Error running program "'+ProgramFilename+'": '+e.Message;
      Application.MessageBox(PChar(AText),'Error',MB_OK);
    end;
  end;
  Result:=mrOk;
writeln('[TMainIDE.DoRunProject] END');
end;

function TMainIDE.SomethingOfProjectIsModified: boolean;
begin
  Result:=(Project<>nil) 
       and (Project.SomethingModified or SourceNotebook.SomethingModified);
end;

function TMainIDE.DoSaveAll: TModalResult;
var i:integer;
begin
writeln('TMainIDE.DoSaveAll');
  Result:=DoSaveProject(false);
  if Result=mrAbort then exit;
  if (SourceNoteBook.Notebook<>nil) then begin
    for i:=0 to SourceNoteBook.Notebook.Pages.Count-1 do begin
      if (Project.MainUnit<0) 
      or (Project.Units[Project.MainUnit].EditorIndex<>i) then begin
        Result:=DoSaveEditorUnit(i,false);
        if Result=mrAbort then exit;
      end;
    end;
  end;
end;

procedure TMainIDE.GetCurrentUnit(var ActiveSourceEditor:TSourceEditor;
      var ActiveUnitInfo:TUnitInfo);
begin
  if SourceNoteBook.NoteBook=nil then begin
    ActiveSourceEditor:=nil;
    ActiveUnitInfo:=nil;
  end else begin
    GetUnitWithPageIndex(SourceNotebook.NoteBook.PageIndex,ActiveSourceEditor,
       ActiveUnitInfo);
  end;
end;

procedure TMainIDE.GetUnitWithPageIndex(PageIndex:integer; 
  var ActiveSourceEditor:TSourceEditor; var ActiveUnitInfo:TUnitInfo);
begin
  if SourceNoteBook.NoteBook=nil then begin
    ActiveSourceEditor:=nil;
    ActiveUnitInfo:=nil;
  end else begin
    ActiveSourceEditor:=SourceNoteBook.FindSourceEditorWithPageIndex(PageIndex);
    if ActiveSourceEditor=nil then
      ActiveUnitInfo:=nil
    else 
      ActiveUnitInfo:=Project.UnitWithEditorIndex(PageIndex);
  end;
end;

function TMainIDE.DoSaveStreamToFile(AStream:TStream; 
  const Filename:string; IsPartOfProject:boolean):TModalResult;
// save to file with backup and user interaction
var fs:TFileStream;
  AText,ACaption:string;
  OldPos: integer;
begin
  Result:=DoBackupFile(Filename,IsPartOfProject);
  if Result<>mrOk then exit;
  OldPos:=AStream.Position;
  repeat
    try
      fs:=TFileStream.Create(Filename,fmCreate);
      try
        AStream.Position:=OldPos;
        fs.CopyFrom(AStream,AStream.Size-AStream.Position);
      finally
        fs.Free;
      end;
    except
      on e:Exception do begin
        ACaption:='Write error';
        AText:=e.Message;
        Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
          ,MB_ABORTRETRYIGNORE);
        if Result=mrIgnore then Result:=mrOk;
        if Result=mrAbort then exit;
      end;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoLoadMemoryStreamFromFile(MemStream: TMemoryStream; 
  const AFilename:string): TModalResult;
var FileStream: TFileStream;
  ACaption,AText:string;
begin
  repeat
    try
      FileStream:=TFileStream.Create(AFilename,fmOpenRead);
      try
        FileStream.Position:=0;
        MemStream.CopyFrom(FileStream,FileStream.Size);
        MemStream.Position:=0;
      finally
        FileStream.Free;
      end;
      Result:=mrOk;
    except
      ACaption:='Read Error';
      AText:='Unable to read file "'+AFilename+'"!';
      Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
        ,MB_ABORTRETRYIGNORE);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
end;

function TMainIDE.DoBackupFile(const Filename:string; 
  IsPartOfProject:boolean): TModalResult;
var BackupFilename, CounterFilename: string;
  AText,ACaption:string;
  BackupInfo: TBackupInfo;
  FilePath, FileNameOnly, FileExt, SubDir: string;
  i: integer;
begin
  Result:=mrOk;
  if not (FileExists(Filename)) then exit;
  if IsPartOfProject then
    BackupInfo:=EnvironmentOptions.BackupInfoProjectFiles
  else
    BackupInfo:=EnvironmentOptions.BackupInfoOtherFiles;
  if (BackupInfo.BackupType=bakNone)
  or ((BackupInfo.BackupType=bakSameName) and (BackupInfo.SubDirectory='')) then
    exit;
  FilePath:=ExtractFilePath(Filename);
  FileExt:=ExtractFileExt(Filename);
  FileNameOnly:=ExtractFilename(Filename);
  FileNameOnly:=copy(FilenameOnly,1,length(FilenameOnly)-length(FileExt));
  if BackupInfo.SubDirectory<>'' then begin
    SubDir:=FilePath+BackupInfo.SubDirectory;
    repeat
      if not DirectoryExists(SubDir) then begin
        if not CreateDir(SubDir) then begin
          Result:=MessageDlg('Unable to create backup directory "'+SubDir+'".'
                ,mtWarning,[mbAbort,mbRetry,mbIgnore],0);
          if Result=mrAbort then exit;
          if Result=mrIgnore then Result:=mrOk;
        end;
      end;
    until Result<>mrRetry;
  end;
  if BackupInfo.BackupType in
   [bakSymbolInFront,bakSymbolBehind,bakUserDefinedAddExt,bakSameName] then
  begin
    case BackupInfo.BackupType of
      bakSymbolInFront:
        BackupFilename:=FileNameOnly+'.~'+copy(FileExt,2,length(FileExt)-1);
      bakSymbolBehind:
        BackupFilename:=FileNameOnly+FileExt+'~';
      bakUserDefinedAddExt:
        BackupFilename:=FileNameOnly+FileExt+'.'+BackupInfo.AdditionalExtension;
      bakSameName:
        BackupFilename:=FileNameOnly+FileExt;
    end;
    if BackupInfo.SubDirectory<>'' then
      BackupFilename:=SubDir+OSDirSeparator+BackupFilename
    else
      BackupFilename:=FilePath+BackupFilename;
    // remove old backup file
    repeat
      if FileExists(BackupFilename) then begin
        if not DeleteFile(BackupFilename) then begin
          ACaption:='Delete file failed';
          AText:='Unable to remove old backup file "'+BackupFilename+'"!';
          Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
            ,MB_ABORTRETRYIGNORE);
          if Result=mrAbort then exit;
          if Result=mrIgnore then Result:=mrOk;
        end;
      end;
    until Result<>mrRetry;
  end else begin
    // backup with counter
    if BackupInfo.SubDirectory<>'' then
      BackupFilename:=SubDir+OSDirSeparator+FileNameOnly+FileExt+';'
    else
      BackupFilename:=Filename+';';
    if BackupInfo.MaxCounter<=0 then begin
      // search first non existing backup filename
      i:=1;
      while FileExists(BackupFilename+IntToStr(i)) do inc(i);
      BackupFilename:=BackupFilename+IntToStr(i);
    end else begin
      // rename all backup files (increase number)
      i:=1;
      while FileExists(BackupFilename+IntToStr(i))
      and (i<=BackupInfo.MaxCounter) do inc(i);
      if i>BackupInfo.MaxCounter then begin
        dec(i);
        CounterFilename:=BackupFilename+IntToStr(BackupInfo.MaxCounter);
        // remove old backup file
        repeat
          if FileExists(CounterFilename) then begin
            if not DeleteFile(CounterFilename) then begin
              ACaption:='Delete file failed';
              AText:='Unable to remove old backup file "'+CounterFilename+'"!';
              Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
                ,MB_ABORTRETRYIGNORE);
              if Result=mrAbort then exit;
              if Result=mrIgnore then Result:=mrOk;
            end;
          end;
        until Result<>mrRetry;
      end;
      // rename all old backup files
      dec(i);
      while i>=1 do begin
        repeat
          if not RenameFile(BackupFilename+IntToStr(i),
             BackupFilename+IntToStr(i+1)) then
          begin
            ACaption:='Rename file failed';
            AText:='Unable to rename file "'+BackupFilename+IntToStr(i)
                  +'" to "'+BackupFilename+IntToStr(i+1)+'"!';
            Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
              ,MB_ABORTRETRYIGNORE);
            if Result=mrAbort then exit;
            if Result=mrIgnore then Result:=mrOk;
          end;
        until Result<>mrRetry;
        dec(i);
      end;
      BackupFilename:=BackupFilename+'1';
    end;
  end;
  // backup file
  repeat
    if not RenameFile(Filename,BackupFilename) then begin
      ACaption:='Rename file failed';
      AText:='Unable to rename file "'+Filename+'" to "'+BackupFilename+'"!';
      Result:=Application.MessageBox(PChar(AText),PChar(ACaption)
        ,MB_ABORTRETRYIGNORE);
      if Result=mrAbort then exit;
      if Result=mrIgnore then Result:=mrOk;
    end;
  until Result<>mrRetry;
end;

procedure TMainIDE.UpdateCaption;
var NewCaption:string;
begin
  NewCaption := 'Lazarus Editor v'+Version_String;
  if Project<>nil then begin
    if Project.Title<>'' then
      NewCaption:=NewCaption +' - '+Project.Title
    else if Project.ProjectFile<>'' then
      NewCaption:=NewCaption+' - '+ExtractFileName(Project.ProjectFile)
    else
      NewCaption:=NewCaption+' - (new project)'
  end;
  Caption:=NewCaption;
end;

procedure TMainIDE.UpdateMainUnitSrcEdit;
var MainUnitSrcEdit: TSourceEditor;
  MainUnitInfo: TUnitInfo;
  CurText: string;
begin
  if Project.MainUnit>=0 then begin
    MainUnitInfo:=Project.Units[Project.MainUnit];
    if MainUnitInfo.Loaded then begin
      MainUnitSrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
        MainUnitInfo.EditorIndex);
      CurText:=MainUnitSrcEdit.Source.Text;
      if CurText<>MainUnitInfo.Source.Source then
        MainUnitSrcEdit.Source.Text:=MainUnitInfo.Source.Source;
    end;
  end;
end;

procedure TMainIDE.DoBringToFrontFormOrUnit;
var AForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
begin
  if FCodeLastActivated then begin
    if SourceNoteBook.NoteBook<>nil then AForm:=SourceNotebook
    else AForm:=nil;
  end else begin
    if (SourceNoteBook.NoteBook<>nil) then begin
      ActiveUnitInfo:=Project.UnitWithEditorIndex(
        SourceNoteBook.NoteBook.PageIndex);
      if (ActiveUnitInfo<>nil) then
        AForm:=TCustomForm(ActiveUnitInfo.Form);
    end;
  end;
  if AForm<>nil then begin
    AForm.Hide;
    AForm.Show;
  end;
end;

procedure TMainIDE.OnMacroSubstitution(TheMacro: TTransferMacro; var s:string;
  var Handled, Abort: boolean);
var MacroName:string;
begin
  if TheMacro=nil then exit;
  MacroName:=lowercase(TheMacro.Name);
  if MacroName='save' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      Abort:=(DoSaveEditorUnit(SourceNoteBook.NoteBook.PageIndex,false)<>mrOk);
    s:='';
  end else if MacroName='saveall' then begin
    Handled:=true;
    Abort:=(DoSaveAll<>mrOk);
    s:='';
  end else if MacroName='edfile' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=Project.UnitWithEditorIndex(SourceNoteBook.NoteBook.PageIndex).Filename
    else
      s:='';
  end else if MacroName='col' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=IntToStr(SourceNoteBook.GetActiveSE.EditorComponent.CaretX);
  end else if MacroName='row' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=IntToStr(SourceNoteBook.GetActiveSE.EditorComponent.CaretY);
  end else if MacroName='projfile' then begin
    Handled:=true;
    s:=Project.ProjectFile;
  end else if MacroName='projpath' then begin
    Handled:=true;
    s:=ExtractFilePath(Project.ProjectFile);
  end else if MacroName='curtoken' then begin
    Handled:=true;
    if SourceNoteBook.NoteBook<>nil then
      s:=IntToStr(SourceNoteBook.GetActiveSE.EditorComponent.CaretY);
  end else if MacroName='lazarusdir' then begin
    Handled:=true;
    s:=EnvironmentOptions.LazarusDirectory;
    if s='' then s:=ExtractFilePath(ParamStr(0));
  end else if MacroName='fpcsrcdir' then begin
    Handled:=true;
    s:=EnvironmentOptions.FPCSourceDirectory;
  end else if MacroName='comppath' then begin
    Handled:=true;
    s:=EnvironmentOptions.CompilerFilename;
  end;
  // ToDo:
  //MacroList.Add(TIDEMacro.Create('CurToken','',nil));
  //MacroList.Add(TIDEMacro.Create('Params','',nil));
  //MacroList.Add(TIDEMacro.Create('TargetFile','',nil));

end;

procedure TMainIDE.OnCmdLineCreate(var CmdLine: string; var Abort:boolean);
// replace all transfer macros in command line
begin
  Abort:=not MacroList.SubstituteStr(CmdLine);
end;

function TMainIDE.DoJumpToCompilerMessage(Index:integer;
  FocusEditor: boolean): boolean;
var MaxMessages: integer;
  Filename, Ext: string;
  CaretXY: TPoint;
  TopLine: integer;
  MsgType: TErrorType;
  SrcEdit: TSourceEditor;
begin
  Result:=false;
  MaxMessages:=MessagesView.MessageView.Items.Count;
  if Index>=MaxMessages then exit;
  if (Index<0) then begin
    // search relevant message (first error, first fatal)
    Index:=0;
    while (Index<MaxMessages) do begin
      if (Compiler1.GetSourcePosition(MessagesView.MessageView.Items[Index],
        Filename,CaretXY,MsgType)) then begin
        if MsgType in [etError,etFatal] then break;
      end;
      inc(Index);
    end;
    if Index>=MaxMessages then exit;
    MessagesView.MessageView.ItemIndex:=Index;
  end;
  if Compiler1.GetSourcePosition(MessagesView.MessageView.Items[Index],
        Filename,CaretXY,MsgType) then begin
    // search the file
    if not FilenameIsAbsolute(Filename) then begin
      Filename:=ExtractFilePath(Project.ProjectFile)+Filename;
    end;
    // open the file in the source editor
    Ext:=lowercase(ExtractFileExt(Filename));
    if (Ext<>'.lfm') or (Ext='.lpi') then begin
      Result:=(DoOpenEditorFile(Filename,false)=mrOk);
      if Result then begin
        // set caret position
        SrcEdit:=SourceNoteBook.GetActiveSE;
        TopLine:=CaretXY.Y-(SrcEdit.EditorComponent.LinesInWindow div 2);
        if TopLine<1 then TopLine:=1;
        SrcEdit.EditorComponent.CaretXY:=CaretXY;
        SrcEdit.EditorComponent.TopLine:=TopLine;
        SrcEdit.ErrorLine:=CaretXY.Y;
        if FocusEditor then begin
//writeln('[TMainIDE.DoJumpToCompilerMessage] A');
          SourceNotebook.BringToFront;
//writeln('[TMainIDE.DoJumpToCompilerMessage] B');
          SrcEdit.EditorComponent.SetFocus;
        end;
      end;
    end;
  end;
end;

procedure TMainIDE.DoShowMessagesView;
var WasVisible: boolean;
begin
  if (EnvironmentOptions.SaveWindowPositions) 
  and (EnvironmentOptions.MessagesViewBoundsValid) then begin
    MessagesView.BoundsRect:=EnvironmentOptions.MessagesViewBounds;
  end else begin
    MessagesView.Top := Screen.Height - 100 - 100;
    MessagesView.Height := 100;
    MessagesView.Left := SourceNotebook.Left;
    MessagesView.Width := SourceNotebook.Width;
  end;
  FMessagesViewBoundsRectValid:=true;
  WasVisible:=MessagesView.Visible;
  MessagesView.Show;
  if not WasVisible then begin
    // quick hack, till BringToFront works correctly
    SourceNotebook.Hide;
    SourceNotebook.Show;
  end;
end;

procedure TMainIDE.OnDesignerGetSelectedComponentClass(Sender: TObject; 
  var RegisteredComponent: TRegisteredComponent);
begin
  RegisteredComponent:=SelectedComponent;
end;

procedure TMainIDE.OnDesignerUnselectComponentClass(Sender: TObject);
begin
  ControlClick(ComponentNoteBook);
end;

procedure TMainIDE.OnDesignerSetDesigning(Sender: TObject; 
  Component: TComponent;  Value: boolean);
begin
  SetDesigning(Component,Value);
end;

procedure TMainIDE.OnDesignerComponentListChanged(Sender: TObject);
begin
  ObjectInspector1.FillComponentComboBox;
end;

procedure TMainIDE.OnDesignerPropertiesChanged(Sender: TObject);
begin
  ObjectInspector1.RefreshPropertyValues;
end;

procedure TMainIDE.OnDesignerAddComponent(Sender: TObject; 
  Component: TComponent; ComponentClass: TRegisteredComponent);
var i: integer;
  ActiveForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
  SrcTxtChanged: boolean;
  ActiveSrcEdit: TSourceEditor;
  FormClassName: string;
  FormClassNameStartPos, FormBodyStartPos: integer;
begin
  ActiveForm:=TDesigner(Sender).Form;
  if ActiveForm=nil then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: TDesigner without a form');
    halt;
  end;
  // find source for form
  i:=Project.UnitCount-1;
  while (i>=0) do begin
    if (Project.Units[i].Loaded) 
    and (Project.Units[i].Form=ActiveForm) then break;
    dec(i);
  end;
  if i<0 then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: form without source');
    halt;
  end;
  ActiveUnitInfo:=Project.Units[i];
  SrcTxtChanged:=false;
  // add needed unit to source
  SrcTxtChanged:=SrcTxtChanged 
      or AddToInterfaceUsesSection(ActiveUnitInfo.Source
        ,ComponentClass.UnitName,'');
  // add component definition to form source
  FormClassName:=ActiveForm.ClassName;
  if FindFormClassDefinitionInSource(ActiveUnitInfo.Source.Source,FormClassName,
     FormClassNameStartPos, FormBodyStartPos) then begin
    if AddFormComponentToSource(ActiveUnitInfo.Source,FormBodyStartPos,
      Component.Name, Component.ClassName) then begin
      SrcTxtChanged:=true;
    end else begin
      Application.MessageBox('No insert point for the new component in source found.'
           ,'Code tool failure',mb_ok);
    end;
  end else begin
    // the form is not mentioned in the source?
    // ignore silently
  end;
  // update source
  if SrcTxtChanged then begin
    ActiveUnitInfo.Modified:=true;
    ActiveSrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
        ActiveUnitInfo.EditorIndex);
    ActiveSrcEdit.Source.Text:=ActiveUnitInfo.Source.Source;
    ActiveSrcEdit.EditorComponent.Modified:=true;
  end;
end;

procedure TMainIDE.OnDesignerRemoveComponent(Sender: TObject;
  Component: TComponent);
var i: integer;
  ActiveForm: TCustomForm;
  ActiveUnitInfo: TUnitInfo;
  SrcTxtChanged: boolean;
  ActiveSrcEdit: TSourceEditor;
  FormClassName: string;
  FormClassNameStartPos, FormBodyStartPos: integer;
begin
  ActiveForm:=TDesigner(Sender).Form;
  if ActiveForm=nil then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: TDesigner without a form');
    halt;
  end;
  // find source for form
  i:=Project.UnitCount-1;
  while (i>=0) do begin
    if (Project.Units[i].Loaded) 
    and (Project.Units[i].Form=ActiveForm) then break;
    dec(i);
  end;
  if i<0 then begin
    writeln('[TMainIDE.OnDesignerAddComponent] Error: form without source');
    halt;
  end;
  ActiveUnitInfo:=Project.Units[i];
  SrcTxtChanged:=false;
  // remove component definition to form source
  FormClassName:=ActiveForm.ClassName;
  if FindFormClassDefinitionInSource(ActiveUnitInfo.Source.Source,FormClassName,
     FormClassNameStartPos, FormBodyStartPos) then begin
    if RemoveFormComponentFromSource(ActiveUnitInfo.Source,FormBodyStartPos,
      Component.Name, Component.ClassName) then begin
      SrcTxtChanged:=true;
    end;
  end else begin
    // the form is not mentioned in the source?
    // ignore silently
  end;
  // update source
  if SrcTxtChanged then begin
    ActiveUnitInfo.Modified:=true;
    ActiveSrcEdit:=SourceNoteBook.FindSourceEditorWithPageIndex(
        ActiveUnitInfo.EditorIndex);
    ActiveSrcEdit.Source.Text:=ActiveUnitInfo.Source.Source;
    ActiveSrcEdit.EditorComponent.Modified:=true;
  end;
end;

procedure TMainIDE.OnDesignerModified(Sender: TObject);
var i: integer;
begin
  i:=Project.IndexOfUnitWithForm(TDesigner(Sender).Form,false);
  if i>=0 then begin
    Project.Units[i].Modified:=true;
    if Project.Units[i].Loaded then
      SourceNotebook.FindSourceEditorWithPageIndex(
        Project.Units[i].EditorIndex).EditorComponent.Modified:=true;
  end;
end;

procedure TMainIDE.OnControlSelectionChanged(Sender: TObject);
var NewSelectedComponents : TComponentSelectionList;
  i: integer;
begin
writeln('[TMainIDE.OnControlSelectionChanged]');
  NewSelectedComponents:=TComponentSelectionList.Create;
  for i:=0 to TheControlSelection.Count-1 do begin
    NewSelectedComponents.Add(TheControlSelection[i].Component);
  end;
  FormEditor1.SelectedComponents:=NewSelectedComponents;
writeln('[TMainIDE.OnControlSelectionChanged] END');
end;


initialization
  {$I images/laz_images.lrs}
  {$I images/mainicon.lrs}

  { $I mainide.lrs}


end.


{ =============================================================================

  $Log$
  Revision 1.105  2001/07/01 15:55:43  lazarus
  MG: JumpToCompilerMessage now centered in source editor

  Revision 1.104  2001/06/27 21:43:23  lazarus
  MG: added project bookmark support

  Revision 1.103  2001/06/26 00:08:35  lazarus
  MG: added code for form icons from Rene E. Beszon

  Revision 1.102  2001/06/06 12:30:40  lazarus
  MG: bugfixes

  Revision 1.100  2001/06/05 10:27:50  lazarus
  MG: saving recent file lists

  Revision 1.98  2001/05/29 08:16:26  lazarus
  MG: bugfixes + starting programs

  Revision 1.97  2001/05/28 10:00:54  lazarus
  MG: removed unused code. fixed editor name bug.

  Revision 1.96  2001/05/27 11:52:00  lazarus
  MG: added --primary-config-path=<filename> cmd line option

  Revision 1.92  2001/04/21 14:50:21  lazarus
  MG: bugfix for mainunits ext <> .lpr

  Revision 1.91  2001/04/13 17:56:16  lazarus
  MWE:
  * Moved menubar outside clientarea
  * Played a bit with the IDE layout
  * Moved the creation of the toolbarspeedbuttons to a separate function

  Revision 1.90  2001/04/04 13:58:50  lazarus
  Added some changes to compreg.pp

  Revision 1.89  2001/04/04 13:55:34  lazarus
  MG: finished TComponentPropertyEditor, added OnModified to oi, cfe and designer

  Revision 1.88  2001/04/04 12:20:34  lazarus
  MG: added  add to/remove from project, small bugfixes

  Revision 1.86  2001/03/31 13:35:22  lazarus
  MG: added non-visual-component code to IDE and LCL

  Revision 1.85  2001/03/29 13:11:33  lazarus
  MG: fixed loading program file bug

  Revision 1.84  2001/03/29 12:38:59  lazarus
  MG: new environment opts, ptApplication bugfixes

  Revision 1.83  2001/03/28 14:08:45  lazarus
  MG: added backup code and fixed removing controls

  Revision 1.82  2001/03/27 11:11:13  lazarus
  MG: fixed mouse msg, added filedialog initialdir

  Revision 1.81  2001/03/26 14:52:30  lazarus
  MG: TSourceLog + compiling bugfixes

  Revision 1.75  2001/03/19 14:00:46  lazarus
  MG: fixed many unreleased DC and GDIObj bugs

  Revision 1.74  2001/03/12 18:57:31  lazarus
  MG: new designer and controlselection code

  Revision 1.68  2001/03/03 11:06:15  lazarus
  added project support, codetools

  Revision 1.62  2001/02/22 17:04:57  lazarus
  added environment options + killed ide unit circles

  Revision 1.61  2001/02/21 22:55:24  lazarus
  small bugfixes + added TOIOptions

  Revision 1.60  2001/02/20 16:53:24  lazarus
  Changes for wordcompletion and many other things from Mattias.
  Shane

  Revision 1.59  2001/02/16 19:13:29  lazarus
  Added some functions
  Shane

  Revision 1.58  2001/02/08 06:09:25  lazarus
  Partially implemented Save Project As menu selection.               CAW

  Revision 1.57  2001/02/06 13:38:57  lazarus
  Fixes from Mattias for EditorOPtions
  Fixes to COmpiler that should allow people to compile if their path is set up.
  Changes to code completion.
  Shane

  Revision 1.56  2001/02/04 04:18:11  lazarus
  Code cleanup and JITFOrms bug fix.
  Shane

  Revision 1.55  2001/02/02 14:23:37  lazarus
  Start of code completion code.
  Shane

  Revision 1.54  2001/02/01 16:45:19  lazarus
  Started the code completion.
  Shane

  Revision 1.52  2001/01/31 13:03:33  lazarus
  Commitng source with new editor.
  Shane

  Revision 1.51  2001/01/31 06:25:35  lazarus
  Removed global unit.
  Removed and commented all references to TUnitInfo.

  Revision 1.50  2001/01/29 05:46:30  lazarus
  Moved Project Options and Compiler Options menus to the Project menu.
  Added Project property to TMainIDE class to allow the project to be
  accessed from other units.                                            CAW

  Revision 1.49  2001/01/18 13:27:30  lazarus
  Minor changees
  Shane

  Revision 1.48  2001/01/16 23:30:45  lazarus
  trying to determine what's crashing LAzarus on load.
  Shane

  Revision 1.45  2001/01/15 20:55:44  lazarus
  Changes for loading filesa
  Shane

  Revision 1.44  2001/01/15 18:25:51  lazarus
  Fixed a stupid error I caused by using a variable as an index in main.pp and this variable sometimes caused an exception because the index was out of range.
  Shane

  Revision 1.43  2001/01/14 03:56:57  lazarus
  Shane

  Revision 1.42  2001/01/13 06:11:06  lazarus
  Minor fixes
  Shane

  Revision 1.41  2001/01/13 03:09:37  lazarus
  Minor changes
  Shane

  Revision 1.40  2001/01/12 18:46:49  lazarus
  Named the speedbuttons in MAINIDE and took out some writelns.
  Shane

  Revision 1.39  2001/01/12 18:10:53  lazarus
  Changes for keyevents in the editor.
  Shane

  Revision 1.38  2001/01/09 21:06:06  lazarus
  Started taking KeyDown messages in TDesigner
  Shane

  Revision 1.37  2001/01/09 18:23:20  lazarus
  Worked on moving controls.  It's just not working with the X and Y coord's I'm getting.
  Shane

  Revision 1.36  2001/01/08 23:48:33  lazarus
  MWE:
    ~ Changed makefiles
    ~ Removed testform from lararus and changed it into program
    * some formatting

  Revision 1.35  2001/01/06 06:28:47  lazarus
  Made Designer control the control movement and such.  I am now using ISDesignMsg to move the controls.
  Shane

  Revision 1.32  2001/01/04 20:33:53  lazarus
  Moved lresources.
  Moved CreateLFM to Main.pp
  Changed Form1 and TFOrm1 to MainIDE and TMainIDE
  Shane

  Revision 1.30  2001/01/03 18:44:54  lazarus
  The Speedbutton now has a numglyphs setting.
  I started the TStringPropertyEditor

  Revision 1.29  2000/12/29 20:43:17  lazarus
  I added the run button with an Enable and disable icon

  Revision 1.25  2000/12/29 13:35:50  lazarus
  Mattias submitted new lresources.pp and lazres.pp files.
  Shane

  Revision 1.23  2000/12/21 20:28:33  lazarus
  Project - RUN will run the program IF the program is the active unit in the Editor.
  Shane

  Revision 1.22  2000/12/20 20:04:30  lazarus
  Made PRoject Build compile the active unit.  This way we can actually play with it by compiling units.

  Revision 1.19  2000/12/19 18:43:12  lazarus
  Removed IDEEDITOR.  This causes the PROJECT class to not function.
  Saving projects no longer works.

  I added TSourceNotebook and TSourceEditor.  They do all the work for saving/closing/opening units.  Somethings work but they are in early development.
  Shane

  Revision 1.18  2000/12/15 18:25:16  lazarus
  Changes from Mattias and I.
  Shane

  Revision 1.16  2000/12/01 20:23:34  lazarus
  renamed Object_Inspector and Prop_edits by removing the underline.
  Shane

  Revision 1.5  2000/08/10 13:22:51  lazarus
  Additions for the FIND dialog
  Shane

  Revision 1.4  2000/08/09 18:32:10  lazarus
  Added more code for the find function.
  Shane

  Revision 1.2  2000/08/07 19:15:05  lazarus
  Added the Search menu to the IDE.
  Shane

  Revision 1.1  2000/07/13 10:27:47  michael
  + Initial import

  Revision 1.152  2000/07/09 20:18:55  lazarus
  MWE:
    + added new controlselection
    + some fixes
    ~ some cleanup

  Revision 1.151  2000/06/29 18:08:56  lazarus
  Shane
    Looking for the editor problem I made a few changes.  I changed everything back to the original though.

  Revision 1.139  2000/06/12 18:33:45  lazarus
  Got the naming to work
  Shane

  Revision 1.136  2000/06/08 17:32:53  lazarus
  trying to add accel to menus.
  Shane

  Revision 1.135  2000/05/10 02:34:43  lazarus
  Changed writelns to Asserts except for ERROR and WARNING messages.   CAW

  Revision 1.134  2000/05/09 18:37:02  lazarus
  *** empty log message ***

  Revision 1.133  2000/05/09 12:52:02  lazarus
  *** empty log message ***

  Revision 1.132  2000/05/08 16:07:32  lazarus
  fixed screentoclient and clienttoscreen
  Shane

  Revision 1.130  2000/05/03 17:19:29  lazarus
  Added the TScreem forms code by hongli@telekabel.nl
  Shane

  Revision 1.124  2000/03/31 18:41:02  lazarus
  Implemented MessageBox / Application.MessageBox calls. No icons yet, though...

  Revision 1.123  2000/03/30 18:23:07  lazarus
  Pulled unneeded code out of main.pp
  Shane

  Revision 1.121  2000/03/24 14:40:41  lazarus
  A little polishing and bug fixing.

  Revision 1.120  2000/03/23 20:40:02  lazarus
  Added some drag code
  Shane

  Revision 1.119  2000/03/22 17:09:28  lazarus
  *** empty log message ***

  Revision 1.118  2000/03/21 21:09:19  lazarus
  *** empty log message ***

  Revision 1.113  2000/03/19 23:01:41  lazarus
  MWE:
    = Changed splashscreen loading/colordepth
    = Chenged Save/RestoreDC to platform  dependent, since they are
      relative to a DC

  Revision 1.112  2000/03/19 03:52:08  lazarus
  Added onclick events for the speedbuttons.
  Shane

  Revision 1.111  2000/03/18 03:08:35  lazarus
  MWE:
    ~ Enabled slpash code again (cvs didn't update spash.pp at first)

  Revision 1.110  2000/03/18 01:08:30  lazarus
  MWE:
    ~ Commentedout SplashScreen (missing)
    + Fixed Speedbutton drawing

  Revision 1.109  2000/03/17 18:47:53  lazarus
  Added a generic splash form
  Shane

  Revision 1.106  2000/03/15 20:15:31  lazarus
  MOdified TBitmap but couldn't get it to work
  Shane

  Revision 1.105  2000/03/15 00:51:57  lazarus
  MWE:
    + Added LM_Paint on expose
    + Added forced creation of gdkwindow if needed
    ~ Modified DrawFrameControl
    + Added BF_ADJUST support on DrawEdge
    - Commented out LM_IMAGECHANGED in TgtkObject.IntSendMessage3
       (It did not compile)

  Revision 1.104  2000/03/14 19:49:04  lazarus
  Modified the painting process for TWincontrol.  Now it runs throug it's FCONTROLS list and paints all them
  Shane

  Revision 1.103  2000/03/14 05:54:01  lazarus
  Changed the name of the compiler options form.        CAW

  Revision 1.102  2000/03/10 18:31:09  lazarus
  Added TSpeedbutton code
  Shane

  Revision 1.101  2000/03/09 23:37:51  lazarus
  MWE:
    * Fixed colorcache
    * Fixed black window in new editor
    ~ Did some cosmetic stuff

  From Peter Dyson <peter@skel.demon.co.uk>:
    + Added Rect api support functions
    + Added the start of ScrollWindowEx

  Revision 1.100  2000/03/09 20:49:25  lazarus
  Added menus for Project Run and Project Build.  They don't do anything yet.

  Revision 1.99  2000/03/07 16:52:58  lazarus
  Fixxed a problem with the main.pp unit determining a new files FORM name.
  Shane

  Revision 1.98  2000/03/03 22:58:25  lazarus
  MWE:
    Fixed focussing problem.
      LM-FOCUS was bound to the wrong signal
    Added GetKeyState api func.
      Now LCL knows if shift/trl/alt is pressed (might be handy for keyboard
      selections ;-)

  Revision 1.97  2000/03/03 20:22:02  lazarus
  Trying to add TBitBtn
  Shane

  Revision 1.95  2000/03/01 00:41:02  lazarus
  MWE:
    Fixed updateshowing problem
    Added some debug code to display the name of messages
    Did a bit of cleanup in main.pp to get the code a bit more readable
      (my editor does funny things with tabs if the indent differs)

  Revision 1.94  2000/02/29 23:00:04  lazarus
  Adding code for the ide.
  Shane

  Revision 1.93  2000/02/28 19:16:03  lazarus
  Added code to the FILE CLOSE to check if the file was modified.  HAven't gotten the application.messagebox working yet though.  It won't stay visible.
  Shane

  Revision 1.92  2000/02/25 19:28:34  lazarus
  Played with TNotebook to see why it crashes when I add a tab and the tnotebook is showing.  Havn't figured it out
  Shane

  Revision 1.91  2000/02/24 21:15:29  lazarus
  Added TCustomForm.GetClientRect and RequestAlign to try and get the controls to align correctly when a MENU is present.  Not Complete yet.

  Fixed the bug in TEdit that caused it not to update it's text property.  I will have to
  look at TMemo to see if anything there was affected.

  Added SetRect to WinAPI calls
  Added AdjustWindowRectEx to WINAPI calls.
  Shane

  Revision 1.90  2000/02/23 14:19:09  lazarus
  Fixed the conflicts caused when two people worked on the ShowModal method for CustomForm and CustomDialog at the same time.
  Shane

  Revision 1.89  2000/02/22 22:19:49  lazarus
  TCustomDialog is a descendant of TComponent.
  Initial cuts a form's proper Close behaviour.

  Revision 1.88  2000/02/22 21:29:42  lazarus
  Added a few more options in the editor like closeing a unit.  Also am keeping track of what page , if any, they are currently on.
  Shane

  Revision 1.85  2000/02/21 17:38:04  lazarus
  Added modalresult to TCustomForm
  Added a View Units dialog box
  Added a View Forms dialog box
  Added a New Unit menu selection
  Added a New Form menu selection
  Shane

  Revision 1.84  2000/02/20 20:13:46  lazarus
  On my way to make alignments and stuff work :-)

  Revision 1.83  2000/02/18 19:38:52  lazarus
  Implemented TCustomForm.Position
  Better implemented border styles. Still needs some tweaks.
  Changed TComboBox and TListBox to work again, at least partially.
  Minor cleanups.

  Revision 1.82  2000/01/31 20:00:21  lazarus
  Added code for Application.ProcessMessages.  Needs work.
  Added TScreen.Width and TScreen.Height.  Added the code into
  GetSystemMetrics for these two properties.
  Shane

  Revision 1.81  2000/01/18 21:47:00  lazarus
  Added OffSetRec

  Revision 1.80  2000/01/10 00:07:12  lazarus
  MWE:
    Added more scrollbar support for TWinControl
    Most signals for TWinContorl are jet connected to the wrong widget
      (now scrolling window, should be fixed)
    Added some cvs entries

  Revision 1.79  2000/01/05 23:13:13  lazarus
  MWE:
    Made some changes to the ideeditor to track notebook problems

  Revision 1.78  2000/01/04 23:12:46  lazarus
  MWE:
    Fixed LM_CHAR message. It is now after the LM_KEYUP message
    Fixed Menus at checkbox example.
    Removed references to TTabbedNtBK (somebody removed the files) and
      chanched it on the compileroptions form

  Revision 1.77  2000/01/04 21:00:34  lazarus
  *** empty log message ***

  Revision 1.76  2000/01/04 19:19:56  lazarus
  Modified notebook.inc so it works.  Don't need tabnotbk.pp anymore...

  Shane

  Revision 1.74  2000/01/03 00:19:20  lazarus
  MWE:
    Added keyup and buttonup events
    Added LM_MOUSEMOVE callback
    Started with scrollbars in editor

  Revision 1.73  1999/12/30 19:49:07  lazarus
  *** empty log message ***

  Revision 1.71  1999/12/29 20:38:22  lazarus
  Modified the toolbar so it now displays itself.  However, I can only add one button at this point.  I will fix that soon....

  Shane

  Revision 1.70  1999/12/23 21:48:13  lazarus
  *** empty log message ***

  Revision 1.66  1999/12/22 01:16:03  lazarus
  MWE:
    Changed/recoded keyevent callbacks
    We Can Edit!
    Commented out toolbar stuff

  Revision 1.65  1999/12/21 21:35:52  lazarus
  committed the latest toolbar code.  Currently it doesn't appear anywhere and I have to get it to add buttons correctly through (I think) setstyle.  I think I'll implement the LM_TOOLBARINSERTBUTTON call there.
  Shane

  Revision 1.64  1999/12/08 00:56:06  lazarus
  MWE:
    Fixed menus. Events aren't enabled yet (dumps --> invalid typecast ??)

  Revision 1.63  1999/11/30 21:30:06  lazarus
  Minor Issues
  Shane

  Revision 1.62  1999/11/25 23:45:08  lazarus
  MWE:
    Added font as GDIobject
    Added some API testcode to testform
    Commented out some more IFDEFs in mwCustomEdit

  Revision 1.61  1999/11/24 18:54:13  lazarus
  Added a unit called ideeditor.pp
  Shane

  Revision 1.60  1999/11/23 22:06:27  lazarus
  Minor changes to get it running again with the latest compiler.  There is something wrong with the compiler that is preventing certain things from working.
  Shane

  Revision 1.59  1999/11/19 14:44:37  lazarus
  Changed the FONTSETNAME to try and load a default font if the first one doesn't work.  This is being done for testing and probably will be removed later.
  Shane

  Revision 1.58  1999/11/17 01:12:52  lazarus
  MWE:
    Added a TestForm and moved mwEdit to that form. The form popsup after
    pressing the testform buttomn

  Revision 1.57  1999/11/05 17:48:17  lazarus
  Added a mwedit1 component to lazarus (MAIN.PP)
  It crashes on create.
  Shane

  Revision 1.56  1999/11/05 00:34:10  lazarus
  MWE: Menu structure updated, events and visible code not added yet

  Revision 1.55  1999/11/01 01:28:28  lazarus
  MWE: Implemented HandleNeeded/CreateHandle/CreateWND
       Now controls are created on demand. A call to CreateComponent shouldn't
       be needed. It is now part of CreateWnd

  Revision 1.54  1999/10/28 23:48:57  lazarus
  MWE: Added new menu classes and started to use handleneeded

  Revision 1.53  1999/10/28 17:17:41  lazarus
  Removed references to FCOmponent.
  Shane

  Revision 1.52  1999/10/19 19:16:51  lazarus
  renamed stdcontrols.pp stdctrls.pp
  Shane

  Revision 1.51  1999/09/30 21:59:00  lazarus
  MWE: Fixed TNoteBook problems
       Modifications: A few
       - Removed some debug messages
       + Added some others
       * changed fixed widged of TPage. Code is still broken.
       + TWinControls are also added to the Controls collection
       + Added TControl.Controls[] property

  Revision 1.50  1999/09/22 20:29:52  lazarus
  *** empty log message ***

  Revision 1.47  1999/07/30 18:18:05  lazarus
  Changes made:  Added a LM_FONTGETSIZE call so you get the size, width and height of the current font.   Not sure if height and size are the same or not.

  Added a cursor to the editor.  When you click you should see it.  Not sure if it works because I can't run Lazarus due to the linking problem.

  Shane

  Revision 1.46  1999/07/27 15:39:42  lazarus
  Changed version number.
  Shane

  Revision 1.45  1999/07/23 17:12:57  lazarus
  TCanvas seems to be working.
  Added Canvas.
     LineTo
     rectangle
     TextOut
     Line

  Shane

  Revision 1.44  1999/07/22 20:55:07  lazarus
  *** empty log message ***

  Revision 1.43  1999/07/18 03:57:32  lazarus
  Minor changes to help diagnose te Canvas and Resize problem.

  Revision 1.40  1999/07/17 06:14:26  lazarus
  TCanvas is almost working.  Added TCanvas.FillRect procedure.
  TCanvas is still getting over written by something.

  Revision 1.39  1999/07/13 02:08:16  lazarus
  no message

  Revision 1.35  1999/07/09 13:54:43  lazarus
  Changed to use Dispatch instead of DispatchStr for messaging.
  You pass it LM_Message which is an integer value and therefore you
  can now use Dispatch to send the integer value back to the class.
  There is currently a problem with having multiple "message" procedures
  in one class so I commented them out for now.

  Shane

  Revision 1.34  1999/06/27 21:34:39  lazarus
  Minor messaging changes.
  Changed from TMyNotifyEvent to TNotifyEvent procedures

  Revision 1.33  1999/05/24 21:20:20  lazarus
  *** empty log message ***

  Revision 1.32  1999/05/20 02:04:58  lazarus
  Modified MAIN so the FILE SAVE menu item tries to save the last activepage

  Revision 1.29  1999/05/17 22:22:38  lazarus
  *** empty log message ***

  Revision 1.28  1999/05/17 04:16:26  lazarus
  TMemo colors files now.
  Still crashes once in a while.  Certain files seem to make it crash.
  Try open buttons.pp

  Revision 1.26  1999/05/15 21:15:06  lazarus
  *** empty log message ***

  Revision 1.25  1999/05/14 18:44:14  lazarus
  *** empty log message ***

  Revision 1.24  1999/05/14 14:53:07  michael
  + Removed objpas from uses clause

  Revision 1.23  1999/05/07 05:46:53  lazarus
  *** empty log message ***

  Revision 1.20  1999/05/03 05:43:06  lazarus
  *** empty log message ***

  Revision 1.19  1999/05/01 03:55:28  lazarus
  *** empty log message ***

  Revision 1.18  1999/04/30 05:28:53  lazarus
  *** empty log message ***

  Revision 1.17  1999/04/28 05:29:36  lazarus
  *** empty log message ***

  Revision 1.16  1999/04/28 05:21:08  lazarus
  *** empty log message ***

  Revision 1.15  1999/04/27 05:08:47  lazarus
  *** empty log message ***

  Revision 1.14  1999/04/26 06:18:25  lazarus
  *** empty log message ***

  Revision 1.13  1999/04/24 03:59:14  lazarus
  *** empty log message ***

  Revision 1.12  1999/04/23 19:42:10  lazarus
  *** empty log message ***

  Revision 1.11  1999/04/23 14:54:58  lazarus
  Added a class TStatusBar and TAling into Comctrls.pp
  Added a class TStatusbar and TAlign into comctrls.pp  They do not work exactly how they were planned.  Plan is to create an Align widget, then a statusbar with an owner of TAlign type.  TAlign would force the TStatusbar to remian on the bottom of the page during a form resize.

  Revision 1.10  1999/04/22 13:46:31  lazarus
  Added ToolTips.
     TControl contains FToolTip, TShowToolTip along with the "Set" methods for these properties.  Every class descendant from TControl can have a TToolTip simply by setting it's pubplic property ToolTip and ShowToolTip := True
     04/22/1999  Shane Miller

  Revision 1.9  1999/04/21 20:58:56  lazarus
  TRadioButton was added in stdControls.  A problem exists in recreating them if the caption changes, but they are functional for now.
  Also, main.pp was modified just to show the use of radiobuttons.

  Revision 1.8  1999/04/21 14:17:45  lazarus
  TToggleBox added.\

  Minor changes have been made to remove excess code once thought required.

  Revision 1.7  1999/04/21 06:12:07  lazarus
  *** empty log message ***

  Revision 1.5  1999/04/20 05:10:39  lazarus
  *** empty log message ***

  Revision 1.4  1999/04/20 03:28:50  lazarus
  *** empty log message ***

  Revision 1.3  1999/04/20 02:56:44  lazarus
  *** empty log message ***

  Revision 1.2  1999/04/18 05:42:11  lazarus
  *** empty log message ***

  Revision 1.1  1999/04/14 07:31:44  michael
  + Initial implementation
}
