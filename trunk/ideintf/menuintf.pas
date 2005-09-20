{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Interface to the IDE menus.
    
  ToDo:
    - Create MainBar menu with the menu interface
    - Create Source Editor Popupmenu with the menu interface
    - Create CodeExplorer Popupmenu with the menu interface
    - Create Project Inspector Popupmenu with the menu interface
    - Create Messages Popupmenu with the menu interface
}
unit MenuIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, Menus, ImgList, Graphics, TextTools, HelpIntf,
  IDECommands;
  
type
  TIDEMenuItem = class;
  TIDEMenuSection = class;

  TAddMenuItemProc =
    function (const NewCaption: string; const NewEnabled: boolean;
              const NewOnClick: TNotifyEvent): TIDEMenuItem of object;

  TNotifyProcedure = procedure(Sender: TObject);

  { TIDEMenuItem
    A menu item in one of the IDE's menus.
    This is only the base class for TIDEMenuSection and TIDEMenuCommand }
    
  { TIDEMenuItem }

  TIDEMenuItem = class(TPersistent)
  private
    FAutoFreeMenuItem: boolean;
    FBitmap: TBitmap;
    FCaption: string;
    FEnabled: Boolean;
    FHint: string;
    FImageIndex: Integer;
    FMenuItem: TMenuItem;
    FMenuItemClass: TMenuItemClass;
    FName: string;
    FOnClickMethod: TNotifyEvent;
    FOnClickProc: TNotifyProcedure;
    FSection: TIDEMenuSection;
    FSectionIndex: Integer;
    FSize: integer;
    FVisible: Boolean;
    FLastVisibleActive: boolean;
    procedure MenuItemClick(Sender: TObject);
    procedure MenuItemDestroy(Sender: TObject);
  protected
    function GetBitmap: TBitmap; virtual;
    function GetCaption: string; virtual;
    function GetHint: String; virtual;
    procedure SetBitmap(const AValue: TBitmap); virtual;
    procedure SetCaption(const AValue: string); virtual;
    procedure SetEnabled(const AValue: Boolean); virtual;
    procedure SetHint(const AValue: String); virtual;
    procedure SetImageIndex(const AValue: Integer); virtual;
    procedure SetMenuItem(const AValue: TMenuItem); virtual;
    procedure SetName(const AValue: string); virtual;
    procedure SetSection(const AValue: TIDEMenuSection); virtual;
    procedure SetVisible(const AValue: Boolean); virtual;
    procedure ClearMenuItems; virtual;
  public
    constructor Create(const TheName: string); virtual;
    destructor Destroy; override;
    function HasBitmap: Boolean;
    procedure CreateMenuItem; virtual;
    function GetPath: string;
    function VisibleActive: boolean; virtual;
    function GetContainerSection: TIDEMenuSection;
    function GetContainerMenuItem: TMenuItem;
    function Size: integer; virtual;
    procedure WriteDebugReport(const Prefix: string); virtual;
    procedure ConsistencyCheck; virtual;
  public
    property Name: string read FName write SetName;
    property Bitmap: TBitmap read GetBitmap write SetBitmap;
    property Hint: String read GetHint write SetHint;
    property ImageIndex: Integer read FImageIndex write SetImageIndex;
    property Visible: Boolean read FVisible write SetVisible;
    property OnClick: TNotifyEvent read FOnClickMethod write FOnClickMethod;
    property OnClickProc: TNotifyProcedure read FOnClickProc write FOnClickProc;
    property Caption: string read GetCaption write SetCaption;
    property Section: TIDEMenuSection read FSection write SetSection;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property MenuItem: TMenuItem read FMenuItem write SetMenuItem;
    property MenuItemClass: TMenuItemClass read FMenuItemClass write FMenuItemClass;
    property SectionIndex: Integer read FSectionIndex;
    property AutoFreeMenuItem: boolean read FAutoFreeMenuItem write FAutoFreeMenuItem;
  end;
  TIDEMenuItemClass = class of TIDEMenuItem;
  
  
  { TIDEMenuSection
    An TIDEMenuItem with childs, either in a sub menu or separated with
    separators.
    If no childs are visible, the section will not be visible.
    }
    
  { TIDEMenuSection }
  
  TIDEMenuSectionState = (
    imssClearing
    );
  TIDEMenuSectionStates = set of TIDEMenuSectionState;

  TIDEMenuSection = class(TIDEMenuItem)
  private
    FBottomSeparator: TMenuItem;
    FChildsAsSubMenu: boolean;
    FNeedBottomSeparator: boolean;
    FNeedTopSeparator: boolean;
    FStates: TIDEMenuSectionStates;
    FSubMenuImages: TCustomImageList;
    FItems: TFPList;
    FTopSeparator: TMenuItem;
    FChildMenuItemsCreated: boolean;
    FVisibleCount: integer;
    FInvalidChildStartIndex: Integer;
    FInvalidChildEndIndex: Integer;
    FUpdateLock: Integer;
    function GetItems(Index: Integer): TIDEMenuItem;
    procedure SeparatorDestroy(Sender : TObject);
    procedure FreeSeparators;
  protected
    procedure SetMenuItem(const AValue: TMenuItem); override;
    procedure SetChildsAsSubMenu(const AValue: boolean); virtual;
    procedure SetSubMenuImages(const AValue: TCustomImageList); virtual;
    procedure ClearMenuItems; override;
    procedure ItemVisibleActiveChanged(AnItem: TIDEMenuItem);
    procedure UpdateChildsIndex(StartIndex: Integer);
    procedure UpdateMenuStructure;
    procedure UpdateSize(Diff: integer);
    procedure Invalidate(FromIndex, ToIndex: integer);
  public
    constructor Create(const TheName: string); override;
    destructor Destroy; override;
    procedure Clear;
    function Count: Integer;
    procedure AddFirst(AnItem: TIDEMenuItem);
    procedure AddLast(AnItem: TIDEMenuItem);
    procedure Insert(Index: Integer; AnItem: TIDEMenuItem);
    procedure Remove(AnItem: TIDEMenuItem);
    procedure CreateMenuItem; override;
    function GetContainerIndex(BehindSeparator: boolean): Integer;
    function GetChildContainerIndex(Index: integer): Integer;
    function IndexOf(AnItem: TIDEMenuItem): Integer;
    function IndexByName(const AName: string): Integer;
    function FindByName(const AName: string): TIDEMenuItem;
    function CreateUniqueName(const AName: string): string;
    function VisibleActive: boolean; override;
    function Size: integer; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure WriteDebugReport(const Prefix: string); override;
    procedure ConsistencyCheck; override;
  public
    property ChildsAsSubMenu: boolean read FChildsAsSubMenu
                                          write SetChildsAsSubMenu default true;
    property SubMenuImages: TCustomImageList read FSubMenuImages
                                             write SetSubMenuImages;
    property Items[Index: Integer]: TIDEMenuItem read GetItems; default;
    property TopSeparator: TMenuItem read FTopSeparator;
    property BottomSeparator: TMenuItem read FBottomSeparator;
    property NeedTopSeparator: boolean read FNeedTopSeparator;
    property NeedBottomSeparator: boolean read FNeedBottomSeparator;
    property VisibleCount: integer read FVisibleCount; // without grandchilds
    property States: TIDEMenuSectionStates read FStates;
  end;
  TIDEMenuSectionClass = class of TIDEMenuSection;


  { TIDEMenuCommand
    A leaf menu item. No childs.
    Hint: The shortcut is defined via the Command property.
  }
  TIDEMenuCommand = class(TIDEMenuItem)
  private
    FAutoCheck: boolean;
    FChecked: Boolean;
    FCommand: TIDECommandKeys;
    FDefault: Boolean;
    FGroupIndex: Byte;
    FRadioItem: Boolean;
    FRightJustify: boolean;
    FShowAlwaysCheckable: boolean;
  protected
    procedure SetAutoCheck(const AValue: boolean); virtual;
    procedure SetChecked(const AValue: Boolean); virtual;
    procedure SetDefault(const AValue: Boolean); virtual;
    procedure SetGroupIndex(const AValue: Byte); virtual;
    procedure SetRadioItem(const AValue: Boolean); virtual;
    procedure SetRightJustify(const AValue: boolean); virtual;
    procedure SetShowAlwaysCheckable(const AValue: boolean); virtual;
    procedure SetCommand(const AValue: TIDECommandKeys); virtual;
    procedure SetMenuItem(const AValue: TMenuItem); override;
  public
    property Command: TIDECommandKeys read FCommand write SetCommand;
    property AutoCheck: boolean read FAutoCheck write SetAutoCheck default False;
    property Checked: Boolean read FChecked write SetChecked default False;
    property Default: Boolean read FDefault write SetDefault default False;
    property GroupIndex: Byte read FGroupIndex write SetGroupIndex default 0;
    property RadioItem: Boolean read FRadioItem write SetRadioItem;
    property RightJustify: boolean read FRightJustify write SetRightJustify;
    property ShowAlwaysCheckable: boolean read FShowAlwaysCheckable
                                          write SetShowAlwaysCheckable;
  end;
  TIDEMenuCommandClass = class of TIDEMenuCommand;
  
  
  { TIDEMenuRoots
    These are the top level menu items of the IDE. }

  TIDEMenuRoots = class(TPersistent)
  private
    FItems: TFPList;// list of TIDEMenuSection
    function GetItems(Index: integer): TIDEMenuSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterMenuRoot(Section: TIDEMenuSection);
    procedure UnregisterMenuRoot(Section: TIDEMenuSection);
    function Count: Integer;
    procedure Clear;
    procedure Delete(Index: Integer);
    function IndexByName(const Name: string): Integer;
    function FindByName(const Name: string): TIDEMenuSection;
    function CreateUniqueName(const Name: string): string;
    function FindByPath(const Path: string;
                        ErrorOnNotFound: boolean): TIDEMenuItem;
  public
    property Items[Index: integer]: TIDEMenuSection read GetItems; default;
  end;

var
  IDEMenuRoots: TIDEMenuRoots = nil;// created by the IDE
  // Source Editor: Popupmenu
  SourceEditorMenuRoot: TIDEMenuSection;
  // Source Editor: First dynamic section for often used context sensitive stuff
  SrcEditMenuSectionFirstDynamic: TIDEMenuSection;
  // Source Editor: First static section (e.g. Find Declaration)
  SrcEditMenuSectionFirstStatic: TIDEMenuSection;
  // Source Editor: Clipboard section (e.g. cut, copy, paste)
  SrcEditMenuSectionClipboard: TIDEMenuSection;
  // Source Editor: File Specific dynamic section
  SrcEditMenuSectionFileDynamic: TIDEMenuSection;
  // Source Editor: Marks section
  SrcEditMenuSectionMarks: TIDEMenuSection;
  // Source Editor: Goto Bookmarks Submenu
  SrcEditSubMenuGotoBookmarks: TIDEMenuSection;
  // Source Editor: Set Bookmarks Submenu
  SrcEditSubMenuSetBookmarks: TIDEMenuSection;
  // Source Editor: Flags section
  SrcEditMenuSectionFlags: TIDEMenuSection;
  // Source Editor: Debug submenu
  SrcEditSubMenuDebug: TIDEMenuSection;
  // Source Editor: Move Page section
  SrcEditMenuSectionMovePage: TIDEMenuSection;
  // Source Editor: Refactor submenu
  SrcEditSubMenuRefactor: TIDEMenuSection;

  MessagesMenuRoot: TIDEMenuSection;
  CodeExplorerMenuRoot: TIDEMenuSection;

function RegisterIDEMenuRoot(const Name: string; MenuItem: TMenuItem = nil
                             ): TIDEMenuSection;
function RegisterIDEMenuSection(const Path, Name: string): TIDEMenuSection;
function RegisterIDESubMenu(const Path, Name, Caption: string;
                            const OnClickMethod: TNotifyEvent = nil;
                            const OnClickProc: TNotifyProcedure = nil
                            ): TIDEMenuSection;
function RegisterIDEMenuCommand(const Path, Name, Caption: string;
                                const OnClickMethod: TNotifyEvent = nil;
                                const OnClickProc: TNotifyProcedure = nil;
                                const Command: TIDECommandKeys = nil
                                ): TIDEMenuCommand;

implementation

function RegisterIDEMenuRoot(const Name: string; MenuItem: TMenuItem
  ): TIDEMenuSection;
begin
  {$IFDEF VerboseMenuIntf}
  //debugln('RegisterIDEMenuRoot Name="',Name,'"');
  {$ENDIF}
  Result:=TIDEMenuSection.Create(Name);
  IDEMenuRoots.RegisterMenuRoot(Result);
  Result.MenuItem:=MenuItem;
end;

function RegisterIDEMenuSection(const Path, Name: string): TIDEMenuSection;
var
  Parent: TIDEMenuSection;
begin
  {$IFDEF VerboseMenuIntf}
  //debugln('RegisterIDEMenuSection Path="',Path,'" Name="',Name,'"');
  {$ENDIF}
  Parent:=IDEMenuRoots.FindByPath(Path,true) as TIDEMenuSection;
  Result:=TIDEMenuSection.Create(Name);
  Result.ChildsAsSubMenu:=false;
  Parent.AddLast(Result);
end;

function RegisterIDESubMenu(const Path, Name, Caption: string;
  const OnClickMethod: TNotifyEvent; const OnClickProc: TNotifyProcedure
  ): TIDEMenuSection;
var
  Parent: TIDEMenuSection;
begin
  {$IFDEF VerboseMenuIntf}
  //debugln('RegisterIDESubMenu Path="',Path,'" Name="',Name,'"');
  {$ENDIF}
  Parent:=IDEMenuRoots.FindByPath(Path,true) as TIDEMenuSection;
  Result:=TIDEMenuSection.Create(Name);
  Result.ChildsAsSubMenu:=true;
  Result.Caption:=Caption;
  Result.OnClick:=OnClickMethod;
  Result.OnClickProc:=OnClickProc;
  Parent.AddLast(Result);
end;

function RegisterIDEMenuCommand(const Path, Name, Caption: string;
  const OnClickMethod: TNotifyEvent; const OnClickProc: TNotifyProcedure;
  const Command: TIDECommandKeys): TIDEMenuCommand;
var
  Parent: TIDEMenuSection;
begin
  {$IFDEF VerboseMenuIntf}
  //debugln('RegisterIDEMenuCommand Path="',Path,'" Name="',Name,'"');
  {$ENDIF}
  Parent:=IDEMenuRoots.FindByPath(Path,true) as TIDEMenuSection;
  Result:=TIDEMenuCommand.Create(Name);
  Result.Caption:=Caption;
  Result.OnClick:=OnClickMethod;
  Result.OnClickProc:=OnClickProc;
  Result.Command:=Command;
  Parent.AddLast(Result);
end;

{ TIDEMenuItem }

procedure TIDEMenuItem.MenuItemClick(Sender: TObject);
begin
  if Assigned(OnClick) then OnClick(Sender);
  if Assigned(OnClickProc) then OnClickProc(Sender);
end;

procedure TIDEMenuItem.MenuItemDestroy(Sender: TObject);
begin
  FMenuItem:=nil;
  FAutoFreeMenuItem:=false;
end;

procedure TIDEMenuItem.SetEnabled(const AValue: Boolean);
begin
  if FEnabled=AValue then exit;
  FEnabled:=AValue;
  if MenuItem<>nil then
    MenuItem.Enabled:=Enabled;
end;

function TIDEMenuItem.GetBitmap: TBitmap;
begin
  if FBitmap=nil then
    FBitmap:=TBitmap.Create;
  FBitmap.Transparent:=True;
  Result:=FBitmap;
end;

function TIDEMenuItem.GetCaption: string;
begin
  if FCaption<>'' then
    Result:=FCaption
  else
    Result:=FName;
end;

function TIDEMenuItem.GetHint: String;
begin
  Result:=FHint;
end;

procedure TIDEMenuItem.SetBitmap(const AValue: TBitmap);
begin
  if FBitmap=AValue then exit;
  if AValue<>nil then
    Bitmap.Assign(AValue)
  else
    FBitmap.Free;
  if MenuItem<>nil then
    MenuItem.Bitmap:=FBitmap;
end;

procedure TIDEMenuItem.SetCaption(const AValue: string);
begin
  FCaption:=AValue;
  if MenuItem<>nil then
    MenuItem.Caption:=Caption;
end;

procedure TIDEMenuItem.SetHint(const AValue: String);
begin
  FHint:=AValue;
  if MenuItem<>nil then
    MenuItem.Hint:=Hint;
end;

procedure TIDEMenuItem.SetImageIndex(const AValue: Integer);
begin
  if FImageIndex=AValue then exit;
  FImageIndex:=AValue;
  if MenuItem<>nil then
    MenuItem.ImageIndex:=ImageIndex;
end;

procedure TIDEMenuItem.SetMenuItem(const AValue: TMenuItem);
begin
  if FMenuItem=AValue then exit;
  if FMenuItem<>nil then ClearMenuItems;
  if FMenuItem=nil then begin
    FMenuItem:=AValue;
    AutoFreeMenuItem:=false;
    if MenuItem<>nil then
      MenuItem.AddHandlerOnDestroy(@MenuItemDestroy);
  end;
  if MenuItem<>nil then begin
    MenuItem.Caption:=Caption;
    MenuItem.Bitmap:=FBitmap;
    MenuItem.Hint:=Hint;
    MenuItem.ImageIndex:=ImageIndex;
    MenuItem.Visible:=Visible;
    MenuItem.OnClick:=@MenuItemClick;
  end;
end;

procedure TIDEMenuItem.SetName(const AValue: string);
begin
  if FName=AValue then exit;
  FName:=AValue;
end;

procedure TIDEMenuItem.SetSection(const AValue: TIDEMenuSection);
var
  OldSection: TIDEMenuSection;
begin
  if FSection=AValue then exit;
  OldSection:=FSection;
  ClearMenuItems;
  if OldSection<>nil then
    OldSection.Remove(Self);
  FSection:=nil;
  if FSection<>nil then
    FSection.AddLast(Self);
end;

procedure TIDEMenuItem.SetVisible(const AValue: Boolean);
var
  OldVisibleActive: Boolean;
begin
  if FVisible=AValue then exit;
  OldVisibleActive:=VisibleActive;
  FVisible:=AValue;
  if MenuItem<>nil then
    MenuItem.Visible:=Visible;
  if (VisibleActive<>OldVisibleActive) and (Section<>nil) then
    Section.ItemVisibleActiveChanged(Self);
end;

procedure TIDEMenuItem.ClearMenuItems;
begin
  if AutoFreeMenuItem then begin
    FAutoFreeMenuItem:=false;
    FMenuItem.Free;
  end;
  FMenuItem:=nil;
end;

constructor TIDEMenuItem.Create(const TheName: string);
begin
  inherited Create;
  FSize:=1;
  FName:=TheName;
  FEnabled:=true;
  FVisible:=true;
  FMenuItemClass:=TMenuItem;
  FSectionIndex:=-1;
  {$IFDEF VerboseMenuIntf}
  //debugln('TIDEMenuItem.Create ',dbgsName(Self),' Name="',Name,'"');
  {$ENDIF}
end;

destructor TIDEMenuItem.Destroy;
begin
  if Section<>nil then
    Section.Remove(Self);
  FreeAndNil(FBitmap);
  if FMenuItem<>nil then begin
    if FAutoFreeMenuItem then
      FreeAndNil(FMenuItem)
    else
      FMenuItem.RemoveAllHandlersOfObject(Self);
  end;
  inherited Destroy;
end;

function TIDEMenuItem.HasBitmap: Boolean;
begin
  Result:=((FBitmap<>nil) and (not FBitmap.Empty))
     or ((ImageIndex>=0) and (Section<>nil) and (Section.SubMenuImages<>nil)
         and (Section.SubMenuImages.Count>ImageIndex));
end;

procedure TIDEMenuItem.CreateMenuItem;
begin
  if FMenuItem<>nil then exit;
  {$IFDEF VerboseMenuIntf}
  //debugln('TIDEMenuItem.CreateMenuItem ',dbgsName(Self),' Name="',Name,'"');
  {$ENDIF}
  MenuItem:=MenuItemClass.Create(nil);
  MenuItem.AddHandlerOnDestroy(@MenuItemDestroy);
  AutoFreeMenuItem:=true;
end;

function TIDEMenuItem.GetPath: string;
var
  Item: TIDEMenuItem;
begin
  Result:=Name;
  Item:=Section;
  while Item<>nil do begin
    Result:=Item.Name+'/'+Result;
    Item:=Item.Section;
  end;
end;

function TIDEMenuItem.VisibleActive: boolean;
// true if Visible=true and not hidden
// false if menu item is hidden (e.g. due to no context, see TIDEMenuSection)
begin
  Result:=Visible;
end;

function TIDEMenuItem.GetContainerSection: TIDEMenuSection;
begin
  if Self is TIDEMenuSection then
    Result:=TIDEMenuSection(Self)
  else
    Result:=Section;
  while (Result<>nil) and (not Result.ChildsAsSubMenu) do
    Result:=Result.Section;
end;

function TIDEMenuItem.GetContainerMenuItem: TMenuItem;
var
  ASection: TIDEMenuSection;
begin
  ASection:=GetContainerSection;
  if (ASection<>nil) then
    Result:=ASection.MenuItem
  else
    Result:=nil;
end;

function TIDEMenuItem.Size: integer;
begin
  Result:=FSize;
end;

procedure TIDEMenuItem.WriteDebugReport(const Prefix: string);
begin
  debugln(Prefix,'SectionIndex=',dbgs(SectionIndex),' Name="',DbgStr(Name),'" VisibleActive=',dbgs(VisibleActive));
end;

procedure TIDEMenuItem.ConsistencyCheck;

  procedure RaiseError;
  var
    s: String;
  begin
    s:='TIDEMenuItem.ConsistencyCheck Name="'+Name+'" Caption="'+DbgStr(Caption)+'"';
    debugln(s);
    RaiseGDBException(s);
  end;

begin
  if MenuItem<>nil then begin
    if MenuItem.HasBitmap<>HasBitmap then
      RaiseError;
    if MenuItem.Enabled<>Enabled then
      RaiseError;
    if MenuItem.Visible<>Visible then
      RaiseError;
    if MenuItem.Caption<>Caption then
      RaiseError;
    if MenuItem.ImageIndex<>ImageIndex then
      RaiseError;
    if MenuItem.Hint<>Hint then
      RaiseError;
  end;
  if (Section=nil) then begin
    if SectionIndex<>-1 then
      RaiseError;
  end else begin
    if SectionIndex<0 then
      RaiseError;
  end;
end;

{ TIDEMenuSection }

procedure TIDEMenuSection.SetSubMenuImages(const AValue: TCustomImageList);
begin
  if FSubMenuImages=AValue then exit;
  FSubMenuImages:=AValue;
  if MenuItem<>nil then
    MenuItem.SubMenuImages:=SubMenuImages;
end;

procedure TIDEMenuSection.ClearMenuItems;
var
  i: Integer;
begin
  FreeSeparators;
  for i:=0 to Count-1 do Items[i].ClearMenuItems;
  inherited ClearMenuItems;
end;

procedure TIDEMenuSection.UpdateChildsIndex(StartIndex: Integer);
var
  i: LongInt;
begin
  for i:=StartIndex to FItems.Count-1 do
    Items[i].FSectionIndex:=i;
end;

procedure TIDEMenuSection.UpdateMenuStructure;
// updates all FNeedBottomSeparator and FNeedTopSeparator
var
  ContainerMenuItem: TMenuItem;
  ContainerMenuIndex: integer;
  Item: TIDEMenuItem;
  CurSection: TIDEMenuSection;

  procedure UpdateNeedTopSeparator;
  // a separator at top is needed, if
  // - this section is imbedded (not ChildsAsSubMenu)
  // - and this section is visible
  // - and this section has visible childs
  // - and there is a visible menu item in front
  var
    i: Integer;
    NewNeedTopSeparator: Boolean;
  begin
    NewNeedTopSeparator:=false;
    if (not ChildsAsSubMenu) and (Section<>nil) and VisibleActive then begin
      // check for any visible item in front
      i:=SectionIndex-1;
      while i>=0 do begin
        if Section[i].VisibleActive then begin
          // there is a visible menu item in front
          // => the Top separator is needed
          //debugln('TIDEMenuSection.UpdateNeedTopSeparator Name="',Name,'" ItemInFront="',Section[i].Name,'"');
          NewNeedTopSeparator:=true;
          break;
        end;
        dec(i);
      end;
    end;
    
    if NewNeedTopSeparator<>FNeedTopSeparator then begin
      FNeedTopSeparator:=NewNeedTopSeparator;
      if FNeedTopSeparator then
        UpdateSize(1)
      else
        UpdateSize(-1);
    end;

    if ContainerMenuItem=nil then exit;
    if FNeedTopSeparator<>(TopSeparator<>nil) then begin
      // FNeedTopSeparator has changed
      if TopSeparator<>nil then begin
        // TopSeparator is not needed anymore
        FreeAndNil(FTopSeparator);
        {$IFDEF VerboseMenuIntf}
        debugln('TIDEMenuSection.UpdateMenuStructure FREE TopSeparator Name="',Name,'"');
        {$ENDIF}
      end else begin
        // TopSeparator is needed
        FTopSeparator:=TMenuItem.Create(nil);
        FTopSeparator.AddHandlerOnDestroy(@SeparatorDestroy);
        FTopSeparator.Caption:='-';
        {$IFDEF VerboseMenuIntf}
        debugln('TIDEMenuSection.UpdateNeedTopSeparator CREATE TopSeparator Name="',Name,'" ContainerMenuIndex=',dbgs(ContainerMenuIndex),' ContainerMenuItem.Count=',dbgs(ContainerMenuItem.Count));
        {$ENDIF}
        ContainerMenuItem.Insert(ContainerMenuIndex,FTopSeparator);
      end;
    end;
  end;

  procedure UpdateNeedBottomSeparator;
  // a separator at bottom is needed, if
  // - this section is imbedded (not ChildsAsSubMenu)
  // - and this section is visible
  // - and this section has visible childs
  // - and there is a visible menu item behind and it has no top separator
  var
    ItemBehind: TIDEMenuItem;
    i: Integer;
    NewNeedBottomSeparator: Boolean;
  begin
    NewNeedBottomSeparator:=false;
    //debugln('TIDEMenuSection.UpdateNeedBottomSeparator Name="',Name,'" ChildsAsSubMenu=',dbgs(ChildsAsSubMenu),' Section=',dbgs(Section<>nil),' VisibleActive=',dbgs(VisibleActive));
    if (not ChildsAsSubMenu) and (Section<>nil) and VisibleActive then begin
      // check for any visible item in front
      i:=SectionIndex+1;
      while i<Section.Count do begin
        ItemBehind:=Section[i];
        if ItemBehind.VisibleActive then begin
          // there is a visible menu item behind
          //debugln('TIDEMenuSection.UpdateNeedBottomSeparator Name="',Name,'" ItemBehind="',ItemBehind.Name,'"');
          if (ItemBehind is TIDEMenuSection)
          and (not TIDEMenuSection(ItemBehind).ChildsAsSubMenu)
          then begin
            // the visible menu item behind will create its own separator
          end else begin
            // the Bottom separator is needed
            NewNeedBottomSeparator:=true;
          end;
          break;
        end;
        inc(i);
      end;
    end;
    {$IFDEF VerboseMenuIntf}
    debugln('TIDEMenuSection.UpdateNeedBottomSeparator Name="',Name,'" Need BottomSeparator=',dbgs(NewNeedBottomSeparator));
    {$ENDIF}

    if NewNeedBottomSeparator<>FNeedBottomSeparator then begin
      FNeedBottomSeparator:=NewNeedBottomSeparator;
      if FNeedBottomSeparator then
        UpdateSize(1)
      else
        UpdateSize(-1);
    end;

    if ContainerMenuItem=nil then exit;
    if FNeedBottomSeparator<>(BottomSeparator<>nil) then begin
      // FNeedBottomSeparator has changed
      if BottomSeparator<>nil then begin
        // BottomSeparator is not needed anymore
        FreeAndNil(FBottomSeparator);
        {$IFDEF VerboseMenuIntf}
        debugln('TIDEMenuSection.UpdateMenuStructure FREE BottomSeparator Name="',Name,'"');
        {$ENDIF}
      end else begin
        // BottomSeparator is needed
        FBottomSeparator:=TMenuItem.Create(nil);
        FBottomSeparator.AddHandlerOnDestroy(@SeparatorDestroy);
        FBottomSeparator.Caption:='-';
        {$IFDEF VerboseMenuIntf}
        debugln('TIDEMenuSection.UpdateMenuStructure CREATE BottomSeparator Name="',Name,'" ContainerMenuIndex=',dbgs(ContainerMenuIndex),' ContainerMenuItem.Count=',dbgs(ContainerMenuItem.Count));
        {$ENDIF}
        ContainerMenuItem.Insert(ContainerMenuIndex,FBottomSeparator);
      end;
    end;
  end;

begin
  if (FInvalidChildStartIndex>FInvalidChildEndIndex) then exit;
  if FUpdateLock>0 then begin
    exit;
  end;
  if FInvalidChildStartIndex<0 then FInvalidChildStartIndex:=0;

  if (Section<>nil) and (not Section.ChildsAsSubMenu)
  and (Section.FInvalidChildStartIndex<=SectionIndex) then begin
    // the sections in front need update too
    // => start the update in front
    {$IFDEF VerboseMenuIntf}
    debugln('TIDEMenuSection.UpdateMenuStructure Front Section="',Section.Name,'" Name="',Name,'" Section.Invalid=',dbgs(Section.FInvalidChildStartIndex),'..',dbgs(Section.FInvalidChildEndIndex),' Count=',dbgs(Count),' SectionIndex=',dbgs(SectionIndex));
    {$ENDIF}
    Section.UpdateMenuStructure;
  end else begin
    // the sections in front are uptodate
    ContainerMenuItem:=GetContainerMenuItem;
    if ChildsAsSubMenu then
      ContainerMenuIndex:=0
    else
      ContainerMenuIndex:=GetContainerIndex(false);
    {$IFDEF VerboseMenuIntf}
    debugln('TIDEMenuSection.UpdateMenuStructure Childs Name="',Name,'" Invalid=',dbgs(FInvalidChildStartIndex),'..',dbgs(FInvalidChildEndIndex),' Count=',dbgs(Count));
    {$ENDIF}

    // update TopSeparator
    if FInvalidChildStartIndex=0 then
      UpdateNeedTopSeparator;
    if FTopSeparator<>nil then
      inc(ContainerMenuIndex);

    // update childs
    while (FInvalidChildStartIndex<=FInvalidChildEndIndex)
    and (FInvalidChildStartIndex<Count) do begin
      Item:=Items[FInvalidChildStartIndex];
      inc(FInvalidChildStartIndex);
      {$IFDEF VerboseMenuIntf}
      debugln('TIDEMenuSection.UpdateMenuStructure Name="',Name,'" Item.Name="',Item.Name,'" ContainerMenuIndex=',dbgs(ContainerMenuIndex));
      {$ENDIF}
      if Item is TIDEMenuSection then
        CurSection:=TIDEMenuSection(Item)
      else
        CurSection:=nil;
        // insert menu item
      if (CurSection=nil) or CurSection.ChildsAsSubMenu then begin
        if ContainerMenuItem<>nil then begin
          Item.CreateMenuItem;
          if Item.MenuItem.Parent=nil then begin
            {$IFDEF VerboseMenuIntf}
            debugln('TIDEMenuSection.UpdateMenuStructure INSERT MenuItem Name="',Name,'" Item="',Item.Name,'" ContainerMenuIndex=',dbgs(ContainerMenuIndex),' ContainerMenuItem.Count=',dbgs(ContainerMenuItem.Count));
            {$ENDIF}
            ContainerMenuItem.Insert(ContainerMenuIndex,Item.MenuItem);
          end;
        end;
      end;
      // update grand childs
      if CurSection<>nil then begin
        CurSection:=TIDEMenuSection(Item);
        CurSection.FInvalidChildStartIndex:=0;
        CurSection.FInvalidChildEndIndex:=CurSection.Count-1;
        CurSection.UpdateMenuStructure;
      end;
      // next
      inc(ContainerMenuIndex,Item.Size);
    end;

    // update BottomSeparator
    if FInvalidChildEndIndex>=Count-1 then
      UpdateNeedBottomSeparator;
  end;
end;

procedure TIDEMenuSection.UpdateSize(Diff: integer);
var
  ASection: TIDEMenuSection;
begin
  ASection:=Self;
  while (ASection<>nil) do begin
    inc(ASection.FSize,Diff);
    if ASection.ChildsAsSubMenu then break;
    ASection:=ASection.Section;
  end;
end;

procedure TIDEMenuSection.Invalidate(FromIndex, ToIndex: integer);
var
  i: Integer;
begin
  if (FInvalidChildStartIndex>FInvalidChildEndIndex) then begin
    // init invalid range
    FInvalidChildStartIndex:=Count;
    FInvalidChildEndIndex:=-1;
  end;
  
  if (FInvalidChildStartIndex>FromIndex) then begin
    FInvalidChildStartIndex:=FromIndex;
    // adjust FInvalidChildStartIndex
    // the bottom separators depend on the next visible item
    // => If the next visible item is invalidated, then the update must start
    //    at the nearest visible in front
    i:=FInvalidChildStartIndex-1;
    while (i>=0) and (not Items[i].VisibleActive) do dec(i);
    if i>=0 then
      FInvalidChildStartIndex:=i;
  end;

  if FInvalidChildEndIndex<ToIndex then begin
    FInvalidChildEndIndex:=ToIndex;
    // adjust FInvalidChildEndIndex
    // the top separators depend on the previous visible item
    // => If the previous visible item is invalidated, then the update must end
    //    at the nearest visible behind
    i:=FInvalidChildEndIndex+1;
    while (i<Count) and (not Items[i].VisibleActive) do inc(i);
    if i<Count then
      FInvalidChildEndIndex:=i;
  end;
end;

procedure TIDEMenuSection.ItemVisibleActiveChanged(AnItem: TIDEMenuItem);
var
  OldVisibleActive: Boolean;
begin
  if imssClearing in FStates then
    exit;
  if AnItem.VisibleActive=AnItem.FLastVisibleActive then
    RaiseGDBException('');
  AnItem.FLastVisibleActive:=AnItem.VisibleActive;

  Invalidate(AnItem.SectionIndex,AnItem.SectionIndex);
  {$IFDEF VerboseMenuIntf}
  debugln('TIDEMenuSection.ItemVisibleActiveChanged Self="',Name,'" AnItem="',AnItem.Name,'" AnItem.VisibleActive=',dbgs(AnItem.VisibleActive));
  {$ENDIF}
  OldVisibleActive:=VisibleActive;

  // update FVisibleCount
  if AnItem.VisibleActive then
    inc(FVisibleCount)
  else
    dec(FVisibleCount);

  if (OldVisibleActive<>VisibleActive) and (Section<>nil) then begin
    // section visibility changed
    Invalidate(0,Count-1);
    {$IFDEF VerboseMenuIntf}
    debugln('TIDEMenuSection.ItemVisibleActiveChanged B Self="',Name,'"');
    {$ENDIF}
    Section.ItemVisibleActiveChanged(Self);
  end;
  
  // create/free Separators
  UpdateMenuStructure;
end;

constructor TIDEMenuSection.Create(const TheName: string);
begin
  inherited Create(TheName);
  FSize:=0;
  FChildsAsSubMenu:=true;
  FItems:=TFPList.Create;
end;

destructor TIDEMenuSection.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TIDEMenuSection.Clear;
var
  i: Integer;
  OldVisibleActive: boolean;
begin
  BeginUpdate;
  if imssClearing in FStates then
    raise Exception.Create('TIDEMenuSection.Clear imssClearing is set');
  Include(FStates,imssClearing);
  OldVisibleActive:=VisibleActive;

  FInvalidChildStartIndex:=0;
  FInvalidChildEndIndex:=0;
  
  FreeSeparators;

  UpdateSize(-FItems.Count);
  for i:=FItems.Count-1 downto 0 do TObject(FItems[i]).Free;
  FItems.Clear;
  FChildMenuItemsCreated:=false;
  FVisibleCount:=0;
  Exclude(FStates,imssClearing);
  if (Section<>nil) and (OldVisibleActive<>VisibleActive) then
    Section.ItemVisibleActiveChanged(Self);
  EndUpdate;
end;

function TIDEMenuSection.Count: Integer;
begin
  Result:=FItems.Count;
end;

procedure TIDEMenuSection.AddFirst(AnItem: TIDEMenuItem);
begin
  Insert(0,AnItem);
end;

procedure TIDEMenuSection.AddLast(AnItem: TIDEMenuItem);
begin
  Insert(Count,AnItem);
end;

procedure TIDEMenuSection.Insert(Index: Integer; AnItem: TIDEMenuItem);
begin
  AnItem.fName:=CreateUniqueName(AnItem.Name);
  FItems.Insert(Index,AnItem);
  UpdateChildsIndex(Index);
  UpdateSize(1);
  AnItem.FSection:=Self;
  if AnItem.VisibleActive then
    ItemVisibleActiveChanged(AnItem);
  {$IFDEF VerboseMenuIntf}
  ConsistencyCheck;
  {$ENDIF}
end;

procedure TIDEMenuSection.Remove(AnItem: TIDEMenuItem);
var
  OldVisibleActive: Boolean;
begin
  if imssClearing in FStates then exit;
  OldVisibleActive:=AnItem.VisibleActive;
  FItems.Delete(AnItem.SectionIndex);
  UpdateChildsIndex(AnItem.SectionIndex);
  UpdateSize(-1);
  AnItem.FSection:=nil;
  if OldVisibleActive then
    ItemVisibleActiveChanged(AnItem);
  // set the Index as last
  AnItem.FSectionIndex:=0;
end;

procedure TIDEMenuSection.CreateMenuItem;
begin
  if ChildsAsSubMenu then
    inherited CreateMenuItem;
end;

function TIDEMenuSection.GetContainerIndex(BehindSeparator: boolean): Integer;
var
  SiblingIndex: Integer;
begin
  Result:=0;
  if (Section=nil) then exit;

  // get the start of the parent Section
  if not Section.ChildsAsSubMenu then
    inc(Result,Section.GetContainerIndex(true));
  // add all siblings in front
  SiblingIndex:=0;
  while (Section[SiblingIndex]<>Self) do begin
    inc(Result,Section[SiblingIndex].Size);
    inc(SiblingIndex);
  end;
  // add separator
  if BehindSeparator and NeedTopSeparator then
    inc(Result);
end;

function TIDEMenuSection.GetChildContainerIndex(Index: integer): Integer;
var
  i: Integer;
begin
  if ChildsAsSubMenu then
    Result:=0
  else
    Result:=GetContainerIndex(true);
  for i:=0 to Index-1 do
    inc(Result,Items[i].Size);
end;

function TIDEMenuSection.IndexOf(AnItem: TIDEMenuItem): Integer;
begin
  Result:=FItems.IndexOf(AnItem);
end;

function TIDEMenuSection.IndexByName(const AName: string): Integer;
begin
  Result:=Count-1;
  while (Result>=0) and (CompareText(AName,Items[Result].Name)<>0) do
    dec(Result);
end;

function TIDEMenuSection.FindByName(const AName: string): TIDEMenuItem;
var
  i: LongInt;
begin
  i:=IndexByName(AName);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

function TIDEMenuSection.CreateUniqueName(const AName: string): string;
begin
  Result:=AName;
  if IndexByName(Result)<0 then exit;
  Result:=CreateFirstIdentifier(Result);
  while IndexByName(Result)>=0 do
    Result:=CreateNextIdentifier(Result);
end;

function TIDEMenuSection.VisibleActive: boolean;
begin
  Result:=VisibleCount>0;
end;

function TIDEMenuSection.Size: integer;
begin
  if ChildsAsSubMenu then
    Result:=1
  else
    Result:=inherited Size;
end;

procedure TIDEMenuSection.BeginUpdate;
begin
  inc(FUpdateLock);
end;

procedure TIDEMenuSection.EndUpdate;
begin
  if FUpdateLock<=0 then
    RaiseGDBException('TIDEMenuSection.EndUpdate');
  dec(FUpdateLock);
  UpdateMenuStructure;
end;

procedure TIDEMenuSection.WriteDebugReport(const Prefix: string);
var
  i: Integer;
begin
  inherited WriteDebugReport(Prefix);
  for i:=0 to Count-1 do Items[i].WriteDebugReport(Prefix+'  ');
end;

procedure TIDEMenuSection.ConsistencyCheck;
var
  i: Integer;
  Item: TIDEMenuItem;
  RealVisibleCount: Integer;
begin
  inherited ConsistencyCheck;
  RealVisibleCount:=0;
  for i:=0 to Count-1 do begin
    Item:=Items[i];
    Item.ConsistencyCheck;
    if Item.SectionIndex<>i then
      RaiseGDBException('');
    if Item.VisibleActive then
      inc(RealVisibleCount);
  end;
  if RealVisibleCount<>VisibleCount then
    RaiseGDBException('');
end;

function TIDEMenuSection.GetItems(Index: Integer): TIDEMenuItem;
begin
  Result:=TIDEMenuItem(FItems[Index]);
end;

procedure TIDEMenuSection.SeparatorDestroy(Sender: TObject);
begin
  if Sender=FTopSeparator then
    FTopSeparator:=nil;
  if Sender=FBottomSeparator then
    FBottomSeparator:=nil;
end;

procedure TIDEMenuSection.FreeSeparators;
begin
  FNeedTopSeparator:=false;
  FreeAndNil(FTopSeparator);
  FNeedBottomSeparator:=false;
  FreeAndNil(FBottomSeparator);
end;

procedure TIDEMenuSection.SetMenuItem(const AValue: TMenuItem);
begin
  if MenuItem=AValue then exit;
  inherited SetMenuItem(AValue);
  Invalidate(0,Count-1);
  {$IFDEF VerboseMenuIntf}
  debugln('TIDEMenuSection.SetMenuItem Name="',Name,'"');
  {$ENDIF}
  UpdateMenuStructure;
end;

procedure TIDEMenuSection.SetChildsAsSubMenu(const AValue: boolean);
begin
  if FChildsAsSubMenu=AValue then exit;
  FChildsAsSubMenu:=AValue;
  ClearMenuItems;
  if Section<>nil then begin
    Section.Invalidate(SectionIndex,SectionIndex);
    {$IFDEF VerboseMenuIntf}
    debugln('TIDEMenuSection.SetChildsAsSubMenu Name="',Name,'"');
    {$ENDIF}
    Section.UpdateMenuStructure;
  end;
end;

{ TIDEMenuCommand }

procedure TIDEMenuCommand.SetAutoCheck(const AValue: boolean);
begin
  if FAutoCheck=AValue then exit;
  FAutoCheck:=AValue;
  if MenuItem<>nil then MenuItem.AutoCheck:=AutoCheck;
end;

procedure TIDEMenuCommand.SetChecked(const AValue: Boolean);
begin
  if FChecked=AValue then exit;
  FChecked:=AValue;
  if MenuItem<>nil then MenuItem.Checked:=Checked;
end;

procedure TIDEMenuCommand.SetDefault(const AValue: Boolean);
begin
  if FDefault=AValue then exit;
  FDefault:=AValue;
  if MenuItem<>nil then MenuItem.Default:=Default;
end;

procedure TIDEMenuCommand.SetGroupIndex(const AValue: Byte);
begin
  if FGroupIndex=AValue then exit;
  FGroupIndex:=AValue;
  if MenuItem<>nil then
    MenuItem.GroupIndex:=GroupIndex;
end;

procedure TIDEMenuCommand.SetRadioItem(const AValue: Boolean);
begin
  if FRadioItem=AValue then exit;
  FRadioItem:=AValue;
  if MenuItem<>nil then
    MenuItem.RadioItem:=RadioItem;
end;

procedure TIDEMenuCommand.SetRightJustify(const AValue: boolean);
begin
  if FRightJustify=AValue then exit;
  FRightJustify:=AValue;
  if MenuItem<>nil then
    MenuItem.RightJustify:=RightJustify;
end;

procedure TIDEMenuCommand.SetShowAlwaysCheckable(const AValue: boolean);
begin
  if FShowAlwaysCheckable=AValue then exit;
  FShowAlwaysCheckable:=AValue;
  if MenuItem<>nil then
    MenuItem.ShowAlwaysCheckable:=ShowAlwaysCheckable;
end;

procedure TIDEMenuCommand.SetCommand(const AValue: TIDECommandKeys);
begin
  if FCommand=AValue then exit;
  FCommand:=AValue;
  if MenuItem<>nil then
    MenuItem.ShortCut:=IDEShortCutToMenuShortCut(AValue.KeyA);
end;

procedure TIDEMenuCommand.SetMenuItem(const AValue: TMenuItem);
begin
  inherited SetMenuItem(AValue);
  if MenuItem<>nil then begin
    MenuItem.AutoCheck:=AutoCheck;
    MenuItem.Checked:=Checked;
    MenuItem.Default:=Default;
    MenuItem.RadioItem:=RadioItem;
    MenuItem.RightJustify:=RightJustify;
    MenuItem.ShowAlwaysCheckable:=ShowAlwaysCheckable;
    if Command<>nil then
      MenuItem.ShortCut:=IDEShortCutToMenuShortCut(Command.KeyA)
    else
      MenuItem.ShortCut:=ShortCut(0,[]);
    MenuItem.GroupIndex:=GroupIndex;
  end;
end;

{ TIDEMenuRoots }

function TIDEMenuRoots.GetItems(Index: integer): TIDEMenuSection;
begin
  Result:=TIDEMenuSection(FItems[Index]);
end;

constructor TIDEMenuRoots.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TIDEMenuRoots.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TIDEMenuRoots.RegisterMenuRoot(Section: TIDEMenuSection);
begin
  Section.FName:=CreateUniqueName(Section.Name);
  FItems.Add(Section);
end;

procedure TIDEMenuRoots.UnregisterMenuRoot(Section: TIDEMenuSection);
begin
  FItems.Remove(Section);
end;

function TIDEMenuRoots.Count: Integer;
begin
  Result:=FItems.Count;
end;

procedure TIDEMenuRoots.Clear;
var
  i: Integer;
begin
  for i:=FItems.Count-1 downto 0 do begin
    Items[i].ClearMenuItems;
    Items[i].Free;
  end;
  FItems.Clear;
end;

procedure TIDEMenuRoots.Delete(Index: Integer);
var
  OldItem: TIDEMenuSection;
begin
  OldItem:=Items[Index];
  UnregisterMenuRoot(OldItem);
  OldItem.Free;
end;

function TIDEMenuRoots.IndexByName(const Name: string): Integer;
begin
  Result:=Count-1;
  while (Result>=0) and (CompareText(Name,Items[Result].Name)<>0) do
    dec(Result);
end;

function TIDEMenuRoots.FindByName(const Name: string): TIDEMenuSection;
var
  i: LongInt;
begin
  i:=IndexByName(Name);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

function TIDEMenuRoots.CreateUniqueName(const Name: string): string;
begin
  Result:=Name;
  if IndexByName(Result)<0 then exit;
  Result:=CreateFirstIdentifier(Result);
  while IndexByName(Result)>=0 do
    Result:=CreateNextIdentifier(Result);
end;

function TIDEMenuRoots.FindByPath(const Path: string;
  ErrorOnNotFound: boolean): TIDEMenuItem;
var
  StartPos: Integer;
  EndPos: LongInt;
  Name: String;
begin
  Result:=nil;
  StartPos:=1;
  while StartPos<=length(Path) do begin
    EndPos:=StartPos;
    while (EndPos<=length(Path)) and (Path[EndPos]<>'/') do inc(EndPos);
    if EndPos>StartPos then begin
      Name:=copy(Path,StartPos,EndPos-StartPos);
      if Result=nil then
        // search root
        Result:=FindByName(Name)
      else if Result is TIDEMenuSection then
        // search child
        Result:=TIDEMenuSection(Result).FindByName(Name)
      else
        // path too long -> we are already at a leaf
        Result:=nil;
      if Result=nil then break;
    end;
    StartPos:=EndPos+1;
  end;
  if Result=nil then begin
    if ErrorOnNotFound then begin
      raise Exception.Create('IDE Menu path not found: '+Path);
    end;
  end;
end;

end.

