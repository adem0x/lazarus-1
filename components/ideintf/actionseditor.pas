{ Copyright (C) 2004

 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************


  implementing ActionList Editor

  authors:
     Radek Cervinka, radek.cervinka@centrum.cz
     Mattias Gaertner
     Pawel Piwowar, alfapawel@tlen.pl

  TODO:- multiselect for the actions and categories
       - drag & drop for the actions and categories
       - standard icon for "Standard Action"
}
unit ActionsEditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Forms, Controls, Dialogs,
  ActnList, ExtCtrls, ComCtrls, Buttons, StdCtrls, ObjInspStrConsts,
  ComponentEditors, PropEdits, PropEditUtils, DBActns, StdActns, LCLIntf,
  LCLType, Graphics, Menus, contnrs;

type
  TActStdPropItem = class;
  TActStdProp = class;
  TResultActProc = procedure (const Category: string; ActionClass: TBasicActionClass;
                  ActionProperty: TActStdPropItem; LastItem: Boolean) of object;

  TRecActStdProp = packed record
    Caption: String;
    ShortCut: TShortCut;
    Hint: String;
  end;

  { TActStdPropItem }

  TActStdPropItem = class
  private
    FActProperties: TRecActStdProp;
    FClassName: String;
    procedure SetActClassName(const AValue: String);
    procedure SetActProperties(const AValue: TRecActStdProp);
  public
    property ActClassName: String read FClassName write SetActClassName;
    property ActionProperty: TRecActStdProp read FActProperties write FActProperties;
  end;

  { TActStdProp }

  TActStdProp = class
  private
    fPropList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOfClass(ActClassName: String): TActStdPropItem;
    procedure Add(ActClassType: TClass; HeadLine, ShortCut, Hint: String);
  end;


  TActionListComponentEditor = class;
  
  { TActionListEditor }

  TActionListEditor = class(TForm)
    ActDelete: TAction;
    ActPanelToolBar: TAction;
    ActPanelDescr: TAction;
    ActMoveUp: TAction;
    ActMoveDown: TAction;
    ActNewStd: TAction;
    ActionListSelf: TActionList;
    ActNew: TAction;
    lblCategory: TLabel;
    lblName: TLabel;
    lstCategory: TListBox;
    lstActionName: TListBox;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mItemActListPanelDescr: TMenuItem;
    mItemToolBarNewStdAction: TMenuItem;
    mItemToolBarNewAction: TMenuItem;
    mItemActListNewAction: TMenuItem;
    mItemActListNewStdAction: TMenuItem;
    mItemActListMoveUpAction: TMenuItem;
    mItemActListMoveDownAction: TMenuItem;
    MenuItem6: TMenuItem;
    mItemActListDelAction: TMenuItem;
    MenuItem8: TMenuItem;
    PanelToolbar: TPanel;
    PanelDescr: TPanel;
    btnAdd: TSpeedButton;
    btnDelete: TSpeedButton;
    btnUp: TSpeedButton;
    btnDown: TSpeedButton;
    PopMenuActions: TPopupMenu;
    PopMenuToolBarActions: TPopupMenu;
    SBShowMenuNewActions: TSpeedButton;
    Splitter: TSplitter;
    procedure ActDeleteExecute(Sender: TObject);
    procedure ActDeleteUpdate(Sender: TObject);
    procedure ActMoveDownExecute(Sender: TObject);
    procedure ActMoveDownUpdate(Sender: TObject);
    procedure ActMoveUpUpdate(Sender: TObject);
    procedure ActNewExecute(Sender: TObject);
    procedure ActNewStdExecute(Sender: TObject);
    procedure ActPanelDescrExecute(Sender: TObject);
    procedure ActPanelToolBarExecute(Sender: TObject);
    procedure ActionListEditorClose(Sender: TObject;
      var CloseAction: TCloseAction);
    procedure ActionListEditorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ActionListEditorKeyPress(Sender: TObject; var Key: char);
    procedure lstActionNameDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure SBShowMenuNewActionsClick(Sender: TObject);
    procedure SplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure lstActionNameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lstActionNameMouseDown(Sender: TOBject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lstCategoryClick(Sender: TObject);
    procedure lstActionNameClick(Sender: TObject);
    procedure lstActionNameDblClick(Sender: TObject);
  protected
    procedure OnComponentRenamed(AComponent: TComponent);
    procedure OnComponentSelection(const NewSelection: TPersistentSelectionList);
    procedure OnRefreshPropertyValues;
    function GetSelectedAction: TContainedAction;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  private
    FActionList: TActionList;
    FDesigner: TComponentEditorDesigner;
    procedure ResultStdActProc(const Category: string; ActionClass: TBasicActionClass;
                            ActionProperty: TActStdPropItem; LastItem: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetActionList(AActionList: TActionList);
    procedure FillCategories;
    procedure FillActionByCategory(iIndex: Integer);
    property Designer:TComponentEditorDesigner read FDesigner write FDesigner;
  end; 

  { TActionListComponentEditor }

  TActionListComponentEditor = class(TComponentEditor)
  private
    FActionList: TActionList;
    FDesigner: TComponentEditorDesigner;
  protected
  public
    constructor Create(AComponent: TComponent;
                       ADesigner: TComponentEditorDesigner); override;
    destructor Destroy; override;
    procedure Edit; override;
    property ActionList: TActionList read FActionList write FActionList;
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

  { Action Registration }

  TRegisteredAction = class
  private
    FActionClass: TBasicActionClass;
    FGroupId: Integer;
  public
    constructor Create(TheActionClass: TBasicActionClass; TheGroupID: integer);
    property ActionClass: TBasicActionClass read FActionClass;
    property GroupId: Integer read FGroupId;
  end;
  PRegisteredAction = ^TRegisteredAction;
  
  TRegisteredActionCategory = class
  private
    FCount: integer;
    FName: string;
    FItems: PRegisteredAction;
    FResource: TComponentClass;
    function GetItems(Index: integer): TRegisteredAction;
  public
    constructor Create(const CategoryName: string; AResource: TComponentClass);
    procedure Add(const AClasses: array of TBasicActionClass);
    destructor Destroy; override;
    function IndexOfClass(AClass: TBasicActionClass): Integer;
    procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
    property Count: integer read FCount;
    property Name: string read FName;
    property Items[Index: integer]: TRegisteredAction read GetItems;
    property Resource: TComponentClass read FResource;
  end;

  TRegisteredActionCategories = class
  private
    FItems: TList;
    function GetItems(Index: Integer): TRegisteredActionCategory;
  public
    procedure Add(const CategoryName: String;
                  const AClasses: array of TBasicActionClass;
                  AResource: TComponentClass);
    destructor Destroy; override;
    function IndexOfCategory(const CategoryName: String): integer;
    procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
    function FindResource(AClass: TBasicActionClass): TComponentClass;
    function Count: Integer;
    property Items[Index: Integer]: TRegisteredActionCategory read GetItems;
  end;

  TNotifyActionListChange = procedure;
  TCreateDlgStdActions = procedure(AOwner: TComponent; ResultActProc: TResultActProc;
                                   out Form: TForm);

  { TActionCategoryProperty }

  TActionCategoryProperty = class(TStringPropertyEditor)
  public
    function  GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

var
  RegisteredActions: TRegisteredActionCategories = nil;
  NotifyActionListChange: TNotifyActionListChange = nil;
  CreateDlgStdActions: TCreateDlgStdActions = nil;

procedure RegisterActions(const ACategory: string;
                          const AClasses: array of TBasicActionClass;
                          AResource: TComponentClass);
procedure UnRegisterActions(const Classes: array of TBasicActionClass);
procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
function CreateAction(TheOwner: TComponent;
                      ActionClass: TBasicActionClass): TBasicAction;


implementation

var
  EditorForms : TList = nil;
  
procedure InitFormsList;
begin
  EditorForms:=TList.Create;
end;

procedure ReleaseFormsList;
begin
  EditorForms.Free;
  EditorForms:=nil;
end;

procedure AddActionEditor(Editor: TActionListEditor);
begin
  if Assigned(EditorForms) and (EditorForms.IndexOf(Editor)<0) then 
    EditorForms.Add(Editor);
end;

procedure ReleaseActionEditor(Editor: TActionListEditor);
var
  i : Integer;
begin
  if not Assigned(EditorForms) then Exit;
  i:=EditorForms.IndexOf(Editor);
  if i>=0 then EditorForms.Delete(i);
end;
  
function FindActionEditor(AList: TActionList): TActionListEditor;
var
  i : Integer;
begin
  if AList<>nil then
    for i:=0 to EditorForms.Count-1 do begin
      if TActionListEditor(EditorForms[i]).FActionList=AList then begin
        Result:=TActionListEditor(EditorForms[i]);
        Exit;
      end;
    end;
  Result:=nil
end;


{$R *.lfm}

procedure RegisterActions(const ACategory: string;
  const AClasses: array of TBasicActionClass; AResource: TComponentClass);
begin
  RegisteredActions.Add(ACategory,AClasses,AResource);
end;

procedure UnRegisterActions(const Classes: array of TBasicActionClass);
begin

end;

procedure EnumActions(Proc: TEnumActionProc; Info: Pointer);
begin
  RegisteredActions.EnumActions(Proc,Info);
end;

function CreateAction(TheOwner: TComponent;
  ActionClass: TBasicActionClass): TBasicAction;
var
  ResourceClass: TComponentClass;
  ResInstance: TComponent;
  i: Integer;
  Component: TComponent;
  Action: TBasicAction;
  Src: TCustomAction;
  Dest: TCustomAction;
begin
  Result := ActionClass.Create(TheOwner);
  // find a Resource component registered for this ActionClass
  ResourceClass := RegisteredActions.FindResource(ActionClass);
  if ResourceClass = nil then Exit;
  ResInstance := ResourceClass.Create(nil);
  try
    // find an action owned by the Resource component
    Action:=nil;
    for i:= 0 to ResInstance.ComponentCount-1 do begin
      Component := ResInstance.Components[i];
      if (CompareText(Component.ClassName, ActionClass.ClassName)=0)
         and (Component is TBasicAction) then begin
        Action := TBasicAction(Component);
        Break;
      end;
    end;
    if Action = nil then Exit;

    // copy TCustomAction properties
    if (Action is TCustomAction) and (Result is TCustomAction) then begin
      Src := TCustomAction(Action);
      Dest := TCustomAction(Result);
      Dest.AutoCheck := Src.AutoCheck;
      Dest.Caption:=Src.Caption;
      Dest.Category := Src.Category;
      Dest.Checked:=Src.Checked;
      Dest.Enabled:=Src.Enabled;
      Dest.HelpContext:=Src.HelpContext;
      Dest.HelpKeyword := Src.HelpKeyword;
      Dest.HelpType := Src.HelpType;
      Dest.Hint:=Src.Hint;
      Dest.ImageIndex:=Src.ImageIndex;
      Dest.SecondaryShortCuts := Src.SecondaryShortCuts;
      Dest.ShortCut:=Src.ShortCut;
      Dest.Visible:=Src.Visible;
//      Src.AssignTo(Dest);
      if (Dest is TContainedAction) and (Dest.ImageIndex>=0)
      and (Src is TContainedAction) then begin
        // ToDo: copy image

      end;
    end;
  finally
    ResInstance.Free;
  end;
end;

{ TActionListEditor }

procedure TActionListEditor.OnComponentRenamed(AComponent: TComponent);
begin
  if Visible and Assigned(FActionList)
  and (AComponent is TAction) and (TAction(AComponent).ActionList = FActionList)
  and Assigned(FActionList.ActionByName(AComponent.Name)) then
    lstActionName.Items[lstActionName.ItemIndex] := AComponent.Name;
end;

procedure TActionListEditor.OnComponentSelection(
  const NewSelection: TPersistentSelectionList);
var
  CurSelect: TContainedAction;
  tmpCategory: String;
  function CategoryIndexOf(Name: String): Integer;
  var
    i: Integer;
  begin
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if lstCategory.Items[i] = Name
      then Break;
    end;
    Result := i;
    if (i = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory))
       and (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory))
    then Result := 0;
  end;
begin
  // TODO: multiselect
  if Self.Visible
     and Assigned(NewSelection)
     and (NewSelection.Count > 0)
     and (NewSelection.Items[0] is TContainedAction)
     and (TContainedAction(NewSelection.Items[0]).ActionList = FActionList) then
    begin
      if GetSelectedAction = NewSelection.Items[0]
      then Exit;
      CurSelect := TContainedAction(NewSelection.Items[0]);
      CurSelect.Category := Trim(CurSelect.Category);
      tmpCategory := CurSelect.Category;
      if (tmpCategory <> '')
         and (lstCategory.Items.IndexOf(tmpCategory) < 0)
      then FillCategories;
      if tmpCategory = ''
      then tmpCategory := cActionListEditorUnknownCategory;
      if (lstCategory.Items[lstCategory.ItemIndex] <> tmpCategory)
         or ((lstCategory.Items[lstCategory.ItemIndex] = tmpCategory)
              and (lstActionName.Items.IndexOf(CurSelect.Name) < 0)) then begin
        if CurSelect.Category = ''
        then lstCategory.ItemIndex := lstCategory.Items.IndexOf(tmpCategory)
        else lstCategory.ItemIndex := CategoryIndexOf(CurSelect.Category);
        lstCategory.Click;
      end;
      lstActionName.ItemIndex := lstActionName.Items.IndexOf(CurSelect.Name);
      lstActionName.Click;
    end
  else lstActionName.ItemIndex := -1;
end;

procedure TActionListEditor.OnRefreshPropertyValues;
  function ValidCategory: Boolean;
  // spr. czy wszystkie kategorie w ListBox'sie istniej¹ w TActionList
  // inaczej: czy istnieje kategoria elementu wywoluj¹cego zdarzenie
  var
    i, j: Integer;
    bool: Boolean;
  begin
    Result := True;
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if (lstCategory.Items[i] = cActionListEditorUnknownCategory)
         and (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory))
      then Break;
      bool := False;
      if FActionList<>nil then
        for j:= FActionList.ActionCount-1 downto 0 do begin
          if TContainedAction(FActionList.Actions[j]).Category = lstCategory.Items[i] then begin
            bool := True;
            Break;
          end;
        end;
      if not bool then begin
        Result := False;
        Break;
      end;
    end;  // for i
  end;
  function IsCategory(Category: String): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i:= lstCategory.Items.Count-1 downto 0 do begin
      if lstCategory.Items[i] = Category then begin
        Result := True;
        Break;
      end;
    end;
    if (i >= 0)
       and ((i = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory))
            or (i = lstCategory.Items.IndexOf(cActionListEditorAllCategory)))
    then Result := False;
  end;
var
  ASelections: TPersistentSelectionList;
  curSelect: TContainedAction;
  oldSelCategory, tmpCategory: String;
  tmpIndex: Integer;
  tmpValidCategory, tmpIsActCategory: Boolean;
begin
  if Self.Visible then begin
    ASelections:= TPersistentSelectionList.Create;
    GlobalDesignHook.GetSelection(ASelections);
    try
      if (ASelections.Count > 0)
         and (ASelections.Items[0] is TContainedAction)
         and (TContainedAction(ASelections.Items[0]).ActionList = FActionList)
      then begin
        curSelect := TContainedAction(ASelections.Items[0]);
        CurSelect.Category := Trim(CurSelect.Category);
        oldSelCategory := lstCategory.Items[lstCategory.ItemIndex];
        tmpCategory := CurSelect.Category;
        
        tmpValidCategory := ValidCategory;
        tmpIsActCategory := IsCategory(CurSelect.Category);
        
        if tmpCategory = '' then tmpCategory := cActionListEditorUnknownCategory;
        if ((curSelect.Category <> '') and not tmpIsActCategory)
           or not tmpValidCategory
           or ((tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(tmpCategory)])
               and ((lstCategory.Items.IndexOf(cActionListEditorAllCategory) >= 0)
                      and (tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(cActionListEditorAllCategory)]))
               and (tmpCategory <> lstCategory.Items[lstCategory.Items.IndexOf(cActionListEditorUnknownCategory)]))
        then FillCategories;

        tmpIndex := lstCategory.Items.IndexOf(tmpCategory);
        if (lstCategory.Items.Count > 1)
           and ( ((not tmpIsActCategory) and (not tmpValidCategory))
                 or ((lstCategory.Items.IndexOf(oldSelCategory) >=0) and (not tmpIsActCategory))
                 or ((lstCategory.Items.IndexOf(oldSelCategory) = -1) and (tmpIndex >= 0))
                 or ((lstCategory.Items.IndexOf(oldSelCategory) >= 0) and (tmpIndex >= 0)) )
           and (oldSelCategory <> cActionListEditorAllCategory) then begin
          lstCategory.ItemIndex := tmpIndex;
          lstCategory.Click;
        end;
        tmpIndex := lstActionName.items.IndexOf(CurSelect.Name);
        if lstActionName.ItemIndex <> tmpIndex then begin
          lstActionName.ItemIndex := tmpIndex;
          lstActionName.Click;
        end;
      end;
    finally
      ASelections.Free;
    end;
  end;
end;

function TActionListEditor.GetSelectedAction: TContainedAction;
begin
  if (lstActionName.ItemIndex >= 0)
  and (FActionList<>nil) then
    Result := FActionList.ActionByName(lstActionName.Items[lstActionName.ItemIndex])
  else
    Result := nil;
end;

procedure TActionListEditor.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation=opRemove then begin
    if AComponent=FActionList then begin
      FActionList:=nil;
      FillCategories;
      FillActionByCategory(-1);
      Close;
    end;
  end;
end;

procedure TActionListEditor.ResultStdActProc(const Category: string;
  ActionClass: TBasicActionClass; ActionProperty: TActStdPropItem;
  LastItem: Boolean);
var
  NewAction: TContainedAction;
begin
  if FActionList=nil then exit;
  NewAction := ActionClass.Create(FActionList.Owner) as TContainedAction;
//  NewAction := CreateAction(FActionList.Owner, ActionClass) as TContainedAction;
  if Category <> cActionListEditorUnknownCategory
  then NewAction.Category := Category
  else NewAction.Category := '';
  NewAction.Name := FDesigner.CreateUniqueComponentName(NewAction.ClassName);
  
  if Assigned(ActionProperty) then begin
    TCustomAction(NewAction).Caption := ActionProperty.ActionProperty.Caption;
    TCustomAction(NewAction).ShortCut := ActionProperty.ActionProperty.ShortCut;
    TCustomAction(NewAction).Hint := ActionProperty.ActionProperty.Hint;
  end;

  NewAction.ActionList := FActionList;
  FDesigner.PropertyEditorHook.PersistentAdded(NewAction,True);

  FDesigner.Modified;
  if LastItem
  then FDesigner.SelectOnlyThisComponent(FActionList.ActionByName(NewAction.Name));
end;

procedure TActionListEditor.SplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  lblName.Left := lstActionName.Left + 3;
end;

procedure TActionListEditor.lstActionNameKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift) then begin
     case key of
       VK_UP: if ActMoveUp.Enabled then begin
           ActMoveUp.OnExecute(ActMoveUp);
           Key := 0;
         end;
         
       VK_DOWN: if ActMoveDown.Enabled then begin
           ActMoveDown.OnExecute(ActMoveDown);
           Key := 0;
         end;
      end;
  end;
end;

procedure TActionListEditor.lstActionNameMouseDown(Sender: TOBject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  oldIndex, index: Integer;
begin
  if Button = mbRight then begin
    oldIndex := TListBox(Sender).ItemIndex;
    index := TListBox(Sender).GetIndexAtY(Y);
    if (index >= 0) and (oldIndex <> index) then begin
      TListBox(Sender).ItemIndex := index;
      TListBox(Sender).Click;
    end;
  end;
end;

procedure TActionListEditor.ActDeleteUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := lstActionName.SelCount > 0;
end;

procedure TActionListEditor.ActMoveDownExecute(Sender: TObject);
var
  fact0,fAct1: TContainedAction;
  lboxIndex: Integer;
  direction: Integer;
begin
  if FActionList=nil then exit;
  if TComponent(Sender).Name = 'ActMoveUp'
  then direction := -1
  else direction := 1;

  lboxIndex := lstActionName.ItemIndex;
  
  fact0 := FActionList.ActionByName(lstActionName.Items[lboxIndex]);
  fact1 := FActionList.ActionByName(lstActionName.Items[lboxIndex+direction]);
  fact1.Index := fact0.Index;

  lstActionName.Items.Move(lboxIndex, lboxIndex+direction);
  lstActionName.ItemIndex := lboxIndex+direction;
  FDesigner.Modified;
end;

procedure TActionListEditor.ActMoveDownUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lstActionName.Items.Count > 1)
                         and (lstActionName.ItemIndex >= 0)
                         and (lstActionName.ItemIndex < lstActionName.Items.Count-1);
end;

procedure TActionListEditor.ActMoveUpUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := (lstActionName.Items.Count > 1)
                         and (lstActionName.ItemIndex > 0);
end;

procedure TActionListEditor.ActNewExecute(Sender: TObject);
var
  NewAction: TContainedAction;
begin
  if FActionList=nil then exit;
  NewAction := TAction.Create(FActionList.Owner);
  NewAction.Name := FDesigner.CreateUniqueComponentName(NewAction.ClassName);

  if lstCategory.ItemIndex > 1 // ignore first two items (virtual categories)
  then NewAction.Category := lstCategory.Items[lstCategory.ItemIndex]
  else NewAction.Category := '';

  NewAction.ActionList := FActionList;

  FDesigner.PropertyEditorHook.PersistentAdded(NewAction,True);
  FDesigner.Modified;
end;

procedure TActionListEditor.ActNewStdExecute(Sender: TObject);
var
  Form: TForm;
begin
  CreateDlgStdActions(Self, @ResultStdActProc, Form);
  Form.ShowModal;
end;

procedure TActionListEditor.ActPanelDescrExecute(Sender: TObject);
begin
  PanelDescr.Visible := TAction(Sender).Checked;
end;

procedure TActionListEditor.ActPanelToolBarExecute(Sender: TObject);
begin
  PanelToolBar.Visible := TAction(Sender).Checked;
end;

procedure TActionListEditor.ActionListEditorClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TActionListEditor.ActionListEditorKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  MousePoint: TPoint;
begin
  MousePoint := Self.ClientToScreen(Point(0,0));
  if Key = VK_APPS
  then PopMenuActions.PopUp(MousePoint.X, MousePoint.Y);
end;

procedure TActionListEditor.ActionListEditorKeyPress(Sender: TObject;
  var Key: char);
begin
  if Ord(Key) = VK_ESCAPE then Self.Close;
end;

procedure TActionListEditor.lstActionNameDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  ACanvas: TCanvas;
  R: TRect;
  dh, dth: Integer;
  AAction: TCustomAction;
  S: String;
begin
  if FActionList=nil then exit;;
  ACanvas := TListBox(Control).Canvas;
  if odSelected in State then
  begin
    ACanvas.Brush.Color := clHighlight;
    ACanvas.Font.Color := clHighlightText;
  end
  else begin
    ACanvas.Brush.Color := clWindow;
    ACanvas.Font.Color := clWindowText;
  end;
  S := TListBox(Control).Items[Index];
  R := ARect;
  dh := R.Bottom - R.Top;
  ACanvas.FillRect(R);
  inc(R.Left, 2);
  if (TListBox(Control).Items.Objects[Index] is TCustomAction)
  and (FActionList.Images <> nil) then begin
    AAction := TListBox(Control).Items.Objects[Index] as TCustomAction;
    R.Right := R.Left + dh;
    if AAction.ImageIndex <> -1 then
    begin
      dth := FActionList.Images.Height;
      if dth > dh then
        FActionList.Images.StretchDraw(ACanvas, AAction.ImageIndex, Rect(R.Left, R.Top + 1, R.Left + dh - 2, R.Bottom - 1))
      else
        FActionList.Images.Draw(ACanvas, R.Left, R.Top + (dh -dth) div 2, AAction.ImageIndex);
    end;
    Inc(R.Left, dh + 2);
  end;
  dth := Canvas.TextHeight(S);
  ACanvas.TextOut(R.Left, R.Top + (dh - dth) div 2, S);
  if odFocused in State then
    ACanvas.DrawFocusRect(ARect);
end;

procedure TActionListEditor.SBShowMenuNewActionsClick(Sender: TObject);
var
  MousePoint: TPoint;
begin
  MousePoint := SBShowMenuNewActions.ClientToScreen(Point(0, btnAdd.Height-1));
  PopMenuToolBarActions.PopUp(MousePoint.X-btnAdd.Width, MousePoint.Y);
  SBShowMenuNewActions.Down := False;
end;

procedure TActionListEditor.ActDeleteExecute(Sender: TObject);
  function IsCategory(Category: String): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i:= FActionList.ActionCount-1 downto 0 do begin
      if FActionList.Actions[i].Category = Category then begin
        Result := True;
        Break;
      end;
    end;
  end;
var
  iNameIndex: Integer;
  OldName: String;
  OldAction: TContainedAction;
  OldIndex: LongInt;
begin
  if FActionList=nil then exit;
  iNameIndex := lstActionName.ItemIndex;
  if iNameIndex < 0 then Exit;
  OldName := lstActionName.Items[iNameIndex];
  lstActionName.Items.Delete(iNameIndex);

  OldAction := FActionList.ActionByName(OldName);
  OldName := OldAction.Category;

  // be gone
  if Assigned(OldAction) then
  begin
    try
      FDesigner.PropertyEditorHook.DeletePersistent(TPersistent(OldAction));
      OldAction:=nil;
    except
      on E: Exception do begin
        MessageDlg(oisErrorDeletingAction,
          Format(oisErrorWhileDeletingAction, [LineEnding, E.Message]), mtError,
          [mbOk], 0);
      end;
    end;
  end;

  if lstActionName.Items.Count = 0 then // last act in category > rebuild
    FillCategories
  else
  begin
    if iNameIndex >= lstActionName.Items.Count
    then lstActionName.ItemIndex := lstActionName.Items.Count -1
    else lstActionName.ItemIndex := iNameIndex;

    FDesigner.SelectOnlyThisComponent(
       FActionList.ActionByName(lstActionName.Items[lstActionName.ItemIndex]));
  end;

  If not IsCategory(OldName) then begin
    OldIndex:=lstCategory.Items.IndexOf(OldName);
    if OldIndex>=0 then
      lstCategory.Items.Delete(OldIndex);
  end;
  if lstActionName.ItemIndex < 0
  then FDesigner.SelectOnlyThisComponent(FActionList);
end;

procedure TActionListEditor.lstCategoryClick(Sender: TObject);
begin
  if lstCategory.ItemIndex >= 0
  then FillActionByCategory(lstCategory.ItemIndex);
end;

procedure TActionListEditor.lstActionNameClick(Sender: TObject);
var
  CurAction: TContainedAction;
begin
  // TODO: multiselect
  if lstActionName.ItemIndex < 0 then Exit;
  CurAction := GetSelectedAction;
  if CurAction = nil then Exit;

  FDesigner.SelectOnlyThisComponent(CurAction);
end;

procedure TActionListEditor.lstActionNameDblClick(Sender: TObject);
var
  CurAction: TContainedAction;
begin
  if lstActionName.GetIndexAtY(lstActionName.ScreenToClient(Mouse.CursorPos).Y) < 0
  then Exit;
  CurAction := GetSelectedAction;
  if CurAction = nil then Exit;
  // Add OnExecute for this action
  CreateComponentEvent(CurAction,'OnExecute');
end;

constructor TActionListEditor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := oisActionListEditor;
  lblCategory.Caption := oisCategory;
  lblName.Caption := oisAction;
  Splitter.MinSize := lblCategory.Left + lblCategory.Width;
  ActNew.Hint := cActionListEditorNewAction;
  ActNewStd.Hint := cActionListEditorNewStdAction;
  ActDelete.Hint := cActionListEditorDeleteActionHint;
  ActMoveUp.Hint := cActionListEditorMoveUpAction;
  ActMoveDown.Hint := cActionListEditorMoveDownAction;
  ActPanelDescr.Caption := cActionListEditorPanelDescrriptions;
  ActPanelToolBar.Caption := cActionListEditorPanelToolBar;
  SBShowMenuNewActions.Hint := cActionListEditorNewAction;
  mItemToolBarNewAction.Caption := cActionListEditorNewAction;
  mItemToolBarNewStdAction.Caption := cActionListEditorNewStdAction;
  mItemActListNewAction.Caption := cActionListEditorNewAction;
  mItemActListNewStdAction.Caption := cActionListEditorNewStdAction;
  mItemActListMoveDownAction.Caption := cActionListEditorMoveDownAction;
  mItemActListMoveUpAction.Caption := cActionListEditorMoveUpAction;
  mItemActListDelAction.Caption := cActionListEditorDeleteAction;

  btnAdd.LoadGlyphFromResourceName(HInstance, 'laz_add');
  btnDelete.LoadGlyphFromResourceName(HInstance, 'laz_delete');
  btnUp.LoadGlyphFromResourceName(HInstance, 'arrow_up');
  btnDown.LoadGlyphFromResourceName(HInstance, 'arrow_down');

  GlobalDesignHook.AddHandlerComponentRenamed(@OnComponentRenamed);
  GlobalDesignHook.AddHandlerSetSelection(@OnComponentSelection);
  GlobalDesignHook.AddHandlerRefreshPropertyValues(@OnRefreshPropertyValues);

  AddActionEditor(Self);
end;

destructor TActionListEditor.Destroy;
begin
  if Assigned(GlobalDesignHook)
  then GlobalDesignHook.RemoveAllHandlersForObject(Self);

  ReleaseActionEditor(Self);
  
  inherited Destroy;
end;

procedure TActionListEditor.SetActionList(AActionList: TActionList);
begin
  if FActionList = AActionList then exit;
  if FActionList<>nil then RemoveFreeNotification(FActionList);
  FActionList := AActionList;
  if FActionList<>nil then FreeNotification(FActionList);
  FillCategories;
  FillActionByCategory(-1);
end;

procedure TActionListEditor.FillCategories;
var
  i: Integer;
  sCategory: String;
  xIndex: Integer;
  sOldCategory: String;
  countCategory: Integer;
begin
  // try remember old category
  sOldCategory := '';
  if (lstCategory.Items.Count>0) and (lstCategory.ItemIndex>-1)
  then sOldCategory := lstCategory.Items[lstCategory.ItemIndex];

  lstCategory.Items.BeginUpdate;
  try
    countCategory := lstCategory.Items.Count;
    lstCategory.Clear;

    if FActionList<>nil then
      for i := 0 to FActionList.ActionCount-1 do begin
        sCategory := FActionList.Actions[i].Category;
        if sCategory = ''
        then Continue;
        xIndex := lstCategory.Items.IndexOf(sCategory);
        if xIndex < 0
        then lstCategory.Items.Add(sCategory);
      end;
    if lstCategory.Items.Count > 0
    then lstCategory.Sorted := True;
    lstCategory.Sorted := False;
    
    xIndex := lstCategory.Items.IndexOf(sOldCategory);
    
    if lstCategory.Items.Count > 0 then begin
      lstCategory.Items.Insert(0, cActionListEditorAllCategory);
      if xIndex > 0 then Inc(xIndex);
    end;
    if lstCategory.Items.Count > 0 then
      begin
        lstCategory.Items.Insert(1, cActionListEditorUnknownCategory);
        if xIndex > 0 then Inc(xIndex);
      end
    else lstCategory.Items.Add(cActionListEditorUnknownCategory);
  finally
    lstCategory.Items.EndUpdate;
  end;
  if xIndex < 0 then begin
    if Assigned(GetSelectedAction)
       and (GetSelectedAction.Category = '')
    then xIndex := lstCategory.Items.IndexOf(cActionListEditorUnknownCategory)
    else xIndex := 0;
  end;
  lstCategory.ItemIndex := xIndex;

  if ( ((lstCategory.ItemIndex <> lstCategory.items.IndexOf(cActionListEditorAllCategory))
         or (lstActionName.Items.Count = 0))
      or (countCategory <> lstCategory.Items.Count) )
  then FillActionByCategory(xIndex);
end;

procedure TActionListEditor.FillActionByCategory(iIndex:Integer);
var
  i: Integer;
  sCategory: String;
  IndexedActionName: String;
begin
  if FActionList=nil then
  begin
    lstActionName.Items.Clear;
    exit;
  end;
  lstActionName.Items.BeginUpdate;
  try
    if iIndex < 0 then iIndex := 0;  // the first possition
    if lstActionName.ItemIndex > -1
    then IndexedActionName := lstActionName.Items[lstActionName.ItemIndex];

    lstActionName.Clear;
    // handle all
    if (iIndex = lstCategory.Items.IndexOf(cActionListEditorAllCategory)) then begin
      for i := 0 to FActionList.ActionCount-1 do
        lstActionName.Items.AddObject(FActionList.Actions[i].Name, FActionList.Actions[i]);
      Exit;
    end;

    // handle unknown
    if iIndex = lstCategory.Items.IndexOf(cActionListEditorUnknownCategory) then begin
      for i := 0 to FActionList.ActionCount-1 do begin
        if Trim(FActionList.Actions[i].Category) = '' then
          lstActionName.Items.AddObject(FActionList.Actions[i].Name, FActionList.Actions[i]);
      end;
      Exit; //throught finally
    end;

    // else sort to categories
    sCategory := lstCategory.Items[iIndex];
    for i := 0 to FActionList.ActionCount-1 do
    begin
      if FActionList.Actions[i].Category = sCategory
      then lstActionName.Items.AddObject(FActionList.Actions[i].Name, FActionList.Actions[i]);
    end;
  finally
    lstActionName.Items.EndUpdate;
    if (IndexedActionName <> '')
       and (lstActionName.Items.IndexOf(IndexedActionName) > -1)
    then lstActionName.ItemIndex := lstActionName.Items.IndexOf(IndexedActionName)
    else if lstActionName.ItemIndex = -1
    then FDesigner.SelectOnlyThisComponent(FActionList);
  end;
end;


{ TActionListComponentEditor }

constructor TActionListComponentEditor.Create(AComponent: TComponent;
  ADesigner: TComponentEditorDesigner);
begin
  inherited Create(AComponent, ADesigner);
  FDesigner := ADesigner;
end;

destructor TActionListComponentEditor.Destroy;
begin
  inherited Destroy;
end;

procedure TActionListComponentEditor.Edit;
var
  AActionList: TActionList;
  AEditor: TActionListEditor;
begin
  AActionList := GetComponent as TActionList;
  if AActionList = nil
  then raise Exception.Create('TActionListComponentEditor.Edit AActionList=nil');
  AEditor:=FindActionEditor(AActionList);
  if not Assigned(AEditor) then begin
    AEditor:=TActionListEditor.Create(Application);
    with AEditor do begin
      lstActionName.ItemIndex := -1;
      Designer := Self.FDesigner;
      SetActionList(AActionList);
    end;
  end;
  AEditor.ShowOnTop;
end;

function TActionListComponentEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TActionListComponentEditor.GetVerb(Index: Integer): string;
begin
  Result := oisActionListComponentEditor;
end;

procedure TActionListComponentEditor.ExecuteVerb(Index: Integer);
begin
  Edit;
end;


{ TRegisteredAction }

constructor TRegisteredAction.Create(TheActionClass: TBasicActionClass;
  TheGroupID: integer);
begin
  FActionClass := TheActionClass;
  FGroupId := TheGroupID;
end;


{ TRegisteredActionCategory }

function TRegisteredActionCategory.GetItems(Index: integer): TRegisteredAction;
begin
  Result := FItems[Index];
end;

constructor TRegisteredActionCategory.Create(const CategoryName: string;
  AResource: TComponentClass);
begin
  FName := CategoryName;
  FResource := AResource;
end;

procedure TRegisteredActionCategory.Add(
  const AClasses: array of TBasicActionClass);
var
  i: integer;
  CurCount: Integer;
  IsDouble: Boolean;
  j: Integer;
  AClass: TBasicActionClass;
  l: Integer;
begin
  l := High(AClasses)-Low(AClasses)+1;
  if l = 0 then exit;
  CurCount := FCount;
  Inc(FCount,l);
  // add all classes (ignoring doubles)
  ReAllocMem(FItems,SizeOf(TBasicActionClass)*FCount);
  for i:=Low(AClasses) to High(AClasses) do begin
    AClass:=AClasses[i];
    // check if already exists
    IsDouble:=false;
    for j:=0 to CurCount-1 do begin
      if FItems[j].ActionClass = AClass then begin
        IsDouble := True;
        Break;
      end;
    end;
    // add
    if not IsDouble then begin
      // TODO use current designer group instead of -1
      FItems[CurCount] := TRegisteredAction.Create(AClass,-1);
      Inc(CurCount);
      RegisterNoIcon([AClass]);
      Classes.RegisterClass(AClass);
    end;
  end;
  // resize FItems
  if CurCount < FCount then begin
    FCount := CurCount;
    ReAllocMem(FItems,SizeOf(TBasicActionClass)*FCount);
  end;
end;

destructor TRegisteredActionCategory.Destroy;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do Items[i].Free;
  ReAllocMem(FItems,0);
  inherited Destroy;
end;

function TRegisteredActionCategory.IndexOfClass(AClass: TBasicActionClass
  ): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (FItems[Result].ActionClass<>AClass) do Dec(Result);
end;

procedure TRegisteredActionCategory.EnumActions(Proc: TEnumActionProc;
  Info: Pointer);
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Proc(Name,FItems[i].ActionClass,Info);
end;


{ TRegisteredActionCategories }

function TRegisteredActionCategories.GetItems(Index: integer
  ): TRegisteredActionCategory;
begin
  Result:=TRegisteredActionCategory(FItems[Index]);
end;

procedure TRegisteredActionCategories.Add(const CategoryName: string;
  const AClasses: array of TBasicActionClass; AResource: TComponentClass);
var
  i: LongInt;
  Category: TRegisteredActionCategory;
begin
  i := IndexOfCategory(CategoryName);
  if i >= 0 then begin
    Category := Items[i];
    if Category.Resource<>AResource then
      raise Exception.Create('TRegisteredActionCategories.Add Resource<>OldResource');
  end else begin
    Category := TRegisteredActionCategory.Create(CategoryName,AResource);
    if FItems = nil then FItems := TList.Create;
    FItems.Add(Category);
  end;
  Category.Add(AClasses);
  if Assigned(NotifyActionListChange) then
    NotifyActionListChange;
end;

destructor TRegisteredActionCategories.Destroy;
var
  i: Integer;
begin
  for i:= Count-1 downto 0 do Items[i].Free;
  FItems.Free;
  inherited Destroy;
end;

function TRegisteredActionCategories.IndexOfCategory(const CategoryName: string
  ): integer;
begin
  Result := Count-1;
  while (Result>=0) and (CompareText(Items[Result].Name,CategoryName)<>0) do
    Dec(Result);
end;

procedure TRegisteredActionCategories.EnumActions(Proc: TEnumActionProc;
  Info: Pointer);
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].EnumActions(Proc,Info);
end;

function TRegisteredActionCategories.FindResource(AClass: TBasicActionClass
  ): TComponentClass;
var
  Category: TRegisteredActionCategory;
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count-1 do begin
    Category := Items[i];
    if Category.IndexOfClass(AClass) >= 0 then begin
      Result := Category.Resource;
      Break;
    end;
  end;
end;

function TRegisteredActionCategories.Count: integer;
begin
  if FItems = nil
  then Result := 0
  else Result := FItems.Count;
end;

{ TActStdProp }

procedure TActStdProp.Add(ActClassType: TClass; HeadLine, ShortCut, Hint: String);
var
  ActItem: TActStdPropItem;
  ActionProperty: TRecActStdProp;
begin
  if Assigned(IndexOfClass(ActClassType.ClassName)) then Exit;
  ActItem := TActStdPropItem.Create;
  ActItem.ActClassName := ActClassType.ClassName;
  ActionProperty.Caption := HeadLine;
  ActionProperty.ShortCut := TextToShortCut(ShortCut);
  ActionProperty.Hint := Hint;
  ActItem.ActionProperty := ActionProperty;
  fPropList.Add(ActItem);
end;

constructor TActStdProp.Create;
begin
  fPropList := TObjectList.Create;
end;

destructor TActStdProp.Destroy;
begin
  fPropList.Free;
  inherited Destroy;
end;

function TActStdProp.IndexOfClass(ActClassName: String): TActStdPropItem;
var
  i: Integer;
begin
  Result := nil;
  for i:= 0 to fPropList.Count-1 do begin
    if TActStdPropItem(fPropList[i]).ActClassName = ActClassName then begin
      Result := TActStdPropItem(fPropList[i]);
      Break;
    end;
  end;
end;

{ TActStdPropItem }

procedure TActStdPropItem.SetActClassName(const AValue: String);
begin
  if FClassName = AValue then Exit;
  FClassName := AValue;
end;

procedure TActStdPropItem.SetActProperties(const AValue: TRecActStdProp);
begin
  FActProperties := AValue;
end;

procedure RegisterStandardActions;
begin
  // TODO
  //  - default images for actions

  RegisterActions(cActionListEditorUnknownCategory, [TAction], nil);
  // register edit actions
  RegisterActions(cActionListEditorEditCategory, [TEditCut, TEditCopy, TEditPaste, TEditSelectAll,
   TEditUndo, TEditDelete], nil);
  // register search/replace actions
  RegisterActions(cActionListEditorSearchCategory, [TSearchFind, TSearchReplace, TSearchFindFirst, 
   TSearchFindNext], nil);
  // register help actions
  RegisterActions(cActionListEditorHelpCategory, [THelpAction, THelpContents, THelpTopicSearch,
    THelpOnHelp, THelpContextAction], nil);
  // register dialog actions
  RegisterActions(cActionListEditorDialogCategory, [TColorSelect, TFontEdit], nil);
  // register file actions
  RegisterActions(cActionListEditorFileCategory, [TFileOpen, TFileOpenWith, TFileSaveAs, TFileExit], nil);
  // register database actions
  RegisterActions(cActionListEditorDatabaseCategory, [TDataSetFirst, TDataSetLast, TDataSetNext,
    TDataSetPrior, TDataSetRefresh, TDataSetCancel, TDataSetDelete, TDataSetEdit,
    TDataSetInsert, TDataSetPost], nil);
end;

{ TActionCategoryProperty }

function TActionCategoryProperty.GetAttributes: TPropertyAttributes;
begin
  Result:=inherited GetAttributes + [paValueList, paSortList];
end;

procedure TActionCategoryProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  Values: TStringList;
  Act:TContainedAction;
  ActLst:TCustomActionList;
  S:string;
begin
  ActLst:=nil;
  Act:=GetComponent(0) as TContainedAction;
  if Assigned(Act) then
    ActLst:=Act.ActionList;
  if not Assigned(ActLst) then exit;
  Values := TStringList.Create;
  try
    for i:=0 to ActLst.ActionCount-1 do
    begin
      S:=ActLst.Actions[i].Category;
      if Values.IndexOf(S)<0 then
        Values.Add(S);
    end;
    for i := 0 to Values.Count - 1 do
      Proc(Values[I]);
  finally
    Values.Free;
  end;
end;

initialization
  NotifyActionListChange := nil;

  RegisteredActions := TRegisteredActionCategories.Create;
  RegisterActionsProc := @RegisterActions;
  UnRegisterActionsProc := @UnregisterActions;
  EnumRegisteredActionsProc := @EnumActions;
  CreateActionProc := @CreateAction;
  
  RegisterComponentEditor(TActionList,TActionListComponentEditor);
  RegisterStandardActions;
  RegisterPropertyEditor(TypeInfo(string), TContainedAction, 'Category', TActionCategoryProperty);
  InitFormsList;

finalization
  ReleaseFormsList;
  RegisteredActions.Free;
  RegisteredActions := nil;
end.

