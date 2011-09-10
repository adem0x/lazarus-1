{ $Id$}
{
 /***************************************************************************
                               DbCtrls.pp
                               ----------
                     An interface to DB aware Controls
                     Initial Revision : Sun Sep 14 2003


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
{
@abstract(common db aware controls, as in Delphi)
@author(Andrew Johnson <acjgenius@@earthlink.net>)
@created(Sun Sep 14 2003)
@lastmod($Date$)
}
unit DbCtrls;

{$mode objfpc}
{$H+}

interface          

uses
  Types, Classes, SysUtils, DB,
  LCLStrConsts, LCLProc, LMessages, LCLType, LResources, GraphType,
  Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, MaskEdit, ExtCtrls,
  Calendar, Variants;

Type
  { TFieldDataLink }

  TFieldDataLink = class(TDataLink)
  private
    FField: TField;
    FFieldName: string;

    FControl: TComponent;

    // Curent State of Affairs
    FEditing: Boolean;
    IsModified: Boolean;

    // Callbacks
    FOnDataChange: TNotifyEvent;
    FOnEditingChange: TNotifyEvent;
    FOnUpdateData: TNotifyEvent;
    FOnActiveChange: TNotifyEvent;
    FOnFocusRequest: TNotifyEvent;
    FOnLayoutChange: TNotifyEvent;

    function FieldCanModify: boolean;
    function GetCanModify: Boolean;

    // set current field
    procedure SetFieldName(const Value: string);
    procedure UpdateField;

    // make sure the field/fieldname is valid before we do stuff with it
    procedure ValidateField;
  protected
    // Testing Events
    procedure ActiveChanged; override;
    {$IF ((FPC_VERSION = 2) and (FPC_RELEASE = 4) and (FPC_PATCH = 2))}
    procedure DataSetChanged; override;
    {$ENDIF}
    procedure EditingChanged; override;
    procedure LayoutChanged; override;
    procedure RecordChanged(aField: TField); override;
    procedure UpdateData; override;

    procedure FocusControl(aField: TFieldRef); Override;
  public
    constructor Create;
    // for control intitiating db changes etc
    function Edit: Boolean;

    procedure Modified;
    procedure Reset;

    // Attached control
    property Control: TComponent read FControl write FControl;


    // Basic DB interfaces
    property Field: TField read FField;
    property FieldName: string read FFieldName write SetFieldName;

    // Current State of DB
    property CanModify: Boolean read GetCanModify;
    property Editing: Boolean read FEditing;

    // Our Callbacks
    property OnDataChange: TNotifyEvent read FOnDataChange write FOnDataChange;
    property OnEditingChange: TNotifyEvent read FOnEditingChange write FOnEditingChange;
    property OnUpdateData: TNotifyEvent read FOnUpdateData write FOnUpdateData;
    property OnActiveChange: TNotifyEvent read FOnActiveChange write FOnActiveChange;
    property OnFocusRequest: TNotifyEvent read FOnFocusRequest write FOnFocusRequest;
    property OnLayoutChange: TNotifyevent read FOnLayoutChange write FOnLayoutChange;
  end;



  { TDBLookup }
  {
  TDBLookup component is typically owned by a Lookup control like
  TDBLookupListBox or TDBLookupComboBox.
  The ListSource is the other dataset TDataSource from which to retrieve the lookup data
  The KeyField is the lookup key in the ListSource which corresponds to the DataField value
  The ListField is the name of the field in the ListSource to list into the
  Items property of the lookup control.
  which  data
  }

  TDBLookup = class(TComponent)
  private
    FLinkBookMark: TBookMark;
    FControlLink: TFieldDataLink;
    FControlItems: TStrings;
    FHasLookUpField: Boolean;
    FListLink: TFieldDataLink;
    FListSource: TDataSource;
    FDataFieldNames: string;
    FKeyFieldNames: string;
    FListFieldName: string;
    FListFieldIndex: Integer;
    FListLinkTmpSetActive: Boolean;
    FLookUpFieldIsCached: Boolean;
    FDataFields: TList;  // Data Fields to lookup/edit
    FKeyFields: TList;   // Keyfields in lookup dataset
    FListField: TField;  // Result field in lookup dataset
    FLookupCache: boolean;
    FLookupList: TLookupList;
    FNullValueKey: TShortcut;
    procedure ActiveChange(Sender: TObject);
    procedure EditingChange(Sender: TObject);
    procedure FetchLookupData;
    function GetKeyFieldName: string;
    function GetListSource: TDataSource;
    procedure LinkGetBookMark;
    procedure LinkGotoBookMark;
    procedure SetKeyFieldName(const Value: string);
    procedure SetListFieldName(const Value: string);
    procedure SetListSource(Value: TDataSource);
    procedure SetLookupCache(const Value: boolean);
    function HandleNullKey(var Key: Word; Shift: TShiftState): Boolean;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize(AControlDataLink: TFieldDataLink; AControlItems: TStrings);
    function ListFieldValue: string;
    procedure UpdateData(const AListFieldValue: string);
    function  GetKeyValue(const AListFieldValue: string): Variant;
    function  GetListValue(const AKeyValue: Variant; out ItemIndex:Integer): boolean;
    property LookupCache: boolean read FLookupCache  write SetLookupCache;
    // properties to be published by owner control
    // these are not used where data control Field is dbLookup
    property KeyField: string read GetKeyFieldName write SetKeyFieldName;
    property ListField: string read FListFieldName write SetListFieldName;
    property ListFieldIndex: Integer read FListFieldIndex write FListFieldIndex default 0;
    property ListSource: TDataSource read GetListSource write SetListSource;
    property NullValueKey: TShortcut read FNullValueKey write FNullValueKey;
  end;

  { TDBEdit }

  TDBEdit = class(TCustomMaskEdit)
  private
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure FocusRequest(Sender: TObject);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;


    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    function IsReadOnly: boolean;
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetReadOnly: Boolean; override;
    procedure SetReadOnly(Value: Boolean); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: char); override;

    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;

    function EditCanModify: Boolean; override;
    function GetEditText: string; override;

    procedure Change; override;
    procedure Reset; override;

    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure LMPasteFromClip(var Message: TLMessage); message LM_PASTE;
    procedure LMCutToClip(var Message: TLMessage); message LM_CUT;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;

    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property BorderStyle;
    property CharCase;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property EditMask;
    property Font;
    property MaxLength;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnUTF8KeyPress;
  end;


  { TDBText }

  TDBText = class(TCustomLabel)
  private
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    class procedure WSRegisterClass; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BidiMode;
    property BorderSpacing;
    property Color;
    property Constraints;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FocusControl;
    property Font;
    property Layout;
    property ParentBidiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Transparent;
    property Visible;
    property WordWrap;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnChangeBounds;
    property OnContextPopup;
    property OnResize;
    property OnStartDrag;
    property OptimalFill;
  end;

  { TCustomDBListBox }

  TCustomDBListBox = class(TCustomListBox)
  private
    procedure EditingChange(Sender: TObject);
    procedure FocusRequest(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);

    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    FDataLink: TFieldDataLink;
    procedure DataChange(Sender: TObject); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure UpdateData(Sender: TObject); virtual;
    // we need to override the Items Write method for db aware.
    procedure SetItems(Values : TStrings); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    //same as dbedit need to match the datalink status
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
  end;

  { TDBListBox }

  TDBListBox = class(TCustomDBListBox)
  protected
    procedure DataChange(Sender: TObject); override;
    procedure DoSelectionChange(User: Boolean); override;
    procedure UpdateData(Sender: TObject); override;
  public
    procedure EditingDone; override;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property DataField;
    property DataSource;
    property DragCursor;
    property DragMode;
    property ExtendedSelect;
    property ItemHeight;
    property Items;
    property MultiSelect;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentShowHint;
    property ReadOnly;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


  { TDBLookupListBox }

  TDBLookupListBox = class(TCustomDBListBox)
  private
    FLookup: TDBLookup;
    procedure ActiveChange(Sender: TObject);
    function GetKeyField: string;
    function GetKeyValue: Variant;
    function GetListField: string;
    function GetListFieldIndex: Integer;
    function GetListSource: TDataSource;
    function GetLookupCache: boolean;
    function GetNullValueKey: TShortCut;
    procedure SetKeyField(const Value: string);
    procedure SetKeyValue(const AValue: Variant);
    procedure SetListField(const Value: string);
    procedure SetListFieldIndex(const Value: Integer);
    procedure SetListSource(const Value: TDataSource);
    procedure SetLookupCache(const Value: boolean);
    procedure SetNullValueKey(const AValue: TShortCut);
  protected
    procedure DataChange(Sender: TObject); override;
    procedure DoSelectionChange(User: Boolean); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure InitializeWnd; override;
    procedure UpdateData(Sender: TObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    property KeyValue: Variant read GetKeyValue write SetKeyValue;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property BorderStyle;
    property DataField;
    property DataSource;
    property DragCursor;
    property DragMode;
//    property ExtendedSelect;
//    property ItemHeight;
    property KeyField: string read GetKeyField write SetKeyField;
    property ListField: string read GetListField write SetListField;
    property ListFieldIndex: Integer read GetListFieldIndex write SetListFieldIndex;
    property ListSource: TDataSource read GetListSource write SetListSource;
    property LookupCache: boolean read GetLookupCache  write SetLookupCache;
    property NullValueKey: TShortCut read GetNullValueKey write SetNullValueKey default 0;
//    property MultiSelect;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
//    property OnDrawItem;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyPress;
    property OnKeyDown;
    property OnKeyUp;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property Sorted;
//    property Style;
    property TabOrder;
    property TabStop;
    property TopIndex;
    property Visible;
  end;


  { TDBRadioGroup }

  TDBRadioGroup = class(TCustomRadioGroup)
  private
    FDataLink: TFieldDataLink;
    FOnChange: TNotifyEvent;
    FValue: string;
    FInSetValue: boolean;
    FValues: TStrings;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetItems(const AValue: TStrings);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetValue(const AValue: string);
    procedure SetValues(const AValue: TStrings);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Change; virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    property DataLink: TFieldDataLink read FDataLink;
    function GetButtonValue(Index: Integer): string;
    procedure UpdateRadioButtonStates; override;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure EditingDone; override;
    property Field: TField read GetField;
    property ItemIndex;
    property Value: string read FValue write SetValue;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property Columns;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Items write SetItems;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChangeBounds;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseuP;
    property OnResize;
    property OnStartDrag;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property TabOrder;
    property TabStop;
    property Values: TStrings read FValues write SetValues;
    property Visible;
  end;


  { TDBCheckBox }

  TDBCheckBox = class(TCustomCheckBox)
  private
    FDataLink: TFieldDataLink;
    FValueChecked: string;
    FValueUnchecked: string;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure SetValueChecked(const AValue: string);
    procedure SetValueUnchecked(const AValue: string);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetFieldCheckState: TCheckBoxState; virtual;
    procedure DataChange(Sender: TObject); virtual;
    procedure DoOnChange; override;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Checked;
    property Field: TField read GetField;
    property State;
  published
    property AllowGrayed;
    property Align;
    property Anchors;
    property AutoSize;
    property BorderSpacing;
    property Caption;
    property Color;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Hint;
    property OnChange;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property ValueChecked: string read FValueChecked write SetValueChecked;
    property ValueUnchecked: string read FValueUnchecked write SetValueUnchecked;
    property Visible;
  end;
  
  
  { TCustomDBComboBox }

  TCustomDBComboBox = class(TCustomComboBox)
  private
    FDataLink: TFieldDataLink;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure DataChange(Sender: TObject); virtual;
    procedure EditingChange(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure Change; override;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure UpdateText; virtual;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure EditingDone; override;
    property Field: TField read GetField;
    property Text;
    property ItemIndex;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
  end;


     { TDBComboBox }

  TDBComboBox = class(TCustomDBComboBox)
  protected
    procedure UpdateData(Sender: TObject); override;
    procedure UpdateText; override;
  published
    property Anchors;
    property ArrowKeysTraverseList;
    property AutoDropDown;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property DataField;
    property DataSource;
    property DragCursor;
    property DragMode;
    property DropDownCount;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property ItemWidth;
    property MaxLength default -1;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnCloseUp;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnDropDown;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property ReadOnly;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property Visible;
  end;


  { TDBLookupComboBox }

  TDBLookupComboBox = class(TCustomDBComboBox)
  private
    FLookup: TDBLookup;
    procedure ActiveChange(Sender: TObject);
    function GetKeyField: string;
    function GetKeyValue: variant;
    function GetListField: string;
    function GetListFieldIndex: Integer;
    function GetListSource: TDataSource;
    function GetLookupCache: boolean;
    function GetNullValueKey: TShortCut;
    procedure SetKeyField(const Value: string);
    procedure SetKeyValue(const AValue: variant);
    procedure SetListField(const Value: string);
    procedure SetListFieldIndex(const Value: Integer);
    procedure SetListSource(const Value: TDataSource);
    procedure SetLookupCache(const Value: boolean);
    procedure SetNullValueKey(const AValue: TShortCut);
  protected
    procedure InitializeWnd; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure UpdateData(Sender: TObject); override;
    procedure UpdateText; override;
  public
    constructor Create(AOwner: TComponent); override;
    property KeyValue: variant read GetKeyValue write SetKeyValue;
  published
    property Align;
    property Anchors;
    property ArrowKeysTraverseList;
    property AutoComplete;
    property AutoDropDown;
    property AutoSize;
    property BorderSpacing;
    property Color;
    property DataField;
    property DataSource;
    property DragCursor;
    property DragMode;
    property DropDownCount;
    property Enabled;
    property Font;
//    property ItemHeight;
//    property ItemWidth;
    property KeyField: string read GetKeyField write SetKeyField;
    property ListField: string read GetListField write SetListField;
    property ListFieldIndex: Integer read GetListFieldIndex write SetListFieldIndex;
    property ListSource: TDataSource read GetListSource write SetListSource;
    property LookupCache: boolean read GetLookupCache  write SetLookupCache;
//    property MaxLength default -1;
    property NullValueKey: TShortCut read GetNullValueKey write SetNullValueKey default 0;
    property OnChange;
    property OnChangeBounds;
    property OnClick;
    property OnCloseUp;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawItem;
    property OnDropDown;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    property Sorted;
    property Style;
    property TabOrder;
    property TabStop;
    property Visible;
  end;

  { TDBMemo }

  TDBMemo = class(TCustomMemo)
  private
    FDataLink: TFieldDataLink;
    FAutoDisplay: Boolean;
    FDBMemoFocused: Boolean;
    FDBMemoLoaded: Boolean;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure SetAutoDisplay(const AValue: Boolean);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    function GetReadOnly: Boolean; override;
    procedure SetReadOnly(AValue: Boolean); override;
    procedure DataChange(Sender: TObject); virtual;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
    procedure UpdateData(Sender: TObject); virtual;
    procedure FocusRequest(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure Change; override;
    procedure KeyPress(var Key:Char); override;
    procedure WndProc(var AMessage : TLMessage); override;
    class procedure WSRegisterClass; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure EditingDone; override;
    procedure LoadMemo; virtual;
    property Field: TField read GetField;
  published
    property Align;
    property Anchors;
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property BorderSpacing;
    property BorderStyle;
    property CharCase;
    property Color;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property MaxLength;
    property OnChange;
    property OnDragDrop;
    property OnDragOver;
    property OnEditingDone;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentFont;
    property PopupMenu;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property ScrollBars;
    property TabOrder;
    property Tabstop;
    property Visible;
    property WordWrap;
  end;
  
  
  { TDBGroupBox }
  
  TDBGroupBox = class(TCustomGroupBox)
  private
    FDataLink: TFieldDataLink;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure DataChange(Sender: TObject); virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Caption;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Font;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property OnUTF8KeyPress;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
  end;
  

  { TDBImage }

  TDBImage = class(TCustomImage)
  private
    FAutoDisplay: Boolean;
    FDataLink: TFieldDataLink;
    FQuickDraw: Boolean;
    FPictureLoaded: boolean;
    FUpdatingRecord: boolean;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;
    function GetReadOnly: Boolean;
    procedure SetAutoDisplay(const AValue: Boolean);
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetReadOnly(const AValue: Boolean);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure DataChange(Sender: TObject); virtual;
    procedure UpdateData(Sender: TObject); virtual;
    procedure PictureChanged(Sender: TObject); override;
    procedure LoadPicture; virtual;
    procedure Loaded; override;
    class procedure WSRegisterClass; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    property Field: TField read GetField;
    procedure Change; virtual;
  published
    property Align;
    property Anchors;
    property AutoDisplay: Boolean read FAutoDisplay write SetAutoDisplay default True;
    property AutoSize;
    property BorderSpacing;
    property Center;
    property Constraints;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property DragCursor;
    property DragMode;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property Proportional;
    property QuickDraw: Boolean read FQuickDraw write FQuickDraw default True;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;
    property Stretch;
    property Transparent;
    property Visible;
  end;

  { TDBCalendar }

  TDBCalendar = class(TCalendar)
  private
    FDataLink: TFieldDataLink;

    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    procedure FocusRequest(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    function GetField: TField;

    function GetReadOnly: Boolean;
    procedure SetReadOnly(Value: Boolean);

    procedure SetDate(const AValue: String);

    procedure SetDataField(const Value: string);
    procedure SetDataSource(Value: TDataSource);
    procedure UpdateDate(const AValue: string);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure EditingDone; override;

    property Field: TField read GetField;
  published
    property BorderSpacing;
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;

    Property Date write SetDate stored False;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly default False;

    property DisplaySettings stored False;
    property DragCursor;
    property DragMode;
    property Visible;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseMove;
    property OnMouseDown;
    property OnDayChanged;
    property OnMonthChanged;
    property OnStartDrag;
    property OnYearChanged;
  end;


  { TDBCustomNavigator }

type
  TDBNavButton = class;
  TDBNavFocusableButton = class;
  TDBNavDataLink = class;

  TDBNavGlyph = (ngEnabled, ngDisabled);
  TDBNavButtonType = (nbFirst, nbPrior, nbNext, nbLast,
                  nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh);
  TDBNavButtonSet = set of TDBNavButtonType;
  TDBNavButtonStyle = set of (nsAllowTimer, nsFocusRect);
  TDBNavButtonDirection = (nbdHorizontal,nbdVertical);
  TDBNavigatorOption = (navFocusableButtons);
  TDBNavigatorOptions = set of TDBNavigatorOption;

  // for Delphi compatibility
  TNavigateBtn = TDBNavButtonType;

  TDBNavClickEvent = procedure(Sender: TObject;
                                Button: TDBNavButtonType) of object;
  
const
  DefaultDBNavigatorButtons = [nbFirst, nbPrior, nbNext, nbLast,
    nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh];
  DBNavButtonResourceName: array[TDBNavButtonType] of string = (
 { nbFirst   } 'DBNavFirst',
 { nbPrior   } 'DBNavPrior',
 { nbNext    } 'DBNavNext',
 { nbLast    } 'DBNavLast',
 { nbInsert  } 'DBNavInsert',
 { nbDelete  } 'DBNavDelete',
 { nbEdit    } 'DBNavEdit',
 { nbPost    } 'DBNavPost',
 { nbCancel  } 'DBNavCancel',
 { nbRefresh } 'DBNavRefresh'
    );

type

  { TDBCustomNavigator }

  TDBCustomNavigator = class(TCustomPanel)
  private
    FBeforeAction: TDBNavClickEvent;
    FConfirmDelete: Boolean;
    FDataLink: TDBNavDataLink;
    FDirection: TDBNavButtonDirection;
    FFlat: Boolean;
    FOnNavClick: TDBNavClickEvent;
    FShowButtonHints: boolean;
    FVisibleButtons: TDBNavButtonSet;
    FDefaultHints: TStrings;
    FHints: TStrings;
    FUpdateButtonsNeeded: boolean;
    FUpdateButtonsLock: integer;
    FOriginalHints: String;
    FOptions: TDBNavigatorOptions;
    procedure DefaultHintsChanged(Sender: TObject);
    function GetDataSource: TDataSource;
    function GetHints: TStrings;
    procedure SetDataSource(const AValue: TDataSource);
    procedure SetDirection(const AValue: TDBNavButtonDirection);
    procedure SetFlat(const AValue: Boolean);
    procedure SetHints(const AValue: TStrings);
    procedure SetShowButtonHints(const AValue: boolean);
    procedure SetVisibleButtons(const AValue: TDBNavButtonSet);
    procedure CMGetDataLink(var Message: TLMessage); message CM_GETDATALINK;
  protected
    Buttons: array[TDBNavButtonType] of TDBNavButton;
    FocusableButtons: array[TDBNavButtonType] of TDBNavFocusableButton;
    procedure DataChanged; virtual;
    procedure EditingChanged; virtual;
    procedure ActiveChanged; virtual;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure UpdateButtons; virtual;
    procedure UpdateHints; virtual;
    procedure HintsChanged(Sender: TObject); virtual;
    procedure ButtonClickHandler(Sender: TObject); virtual;
    class function GetControlClassDefaultSize: TSize; override;
    procedure BeginUpdateButtons; virtual;
    procedure EndUpdateButtons; virtual;
    procedure SetEnabled(Value: Boolean); override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure BtnClick(Index: TNavigateBtn); virtual;
    function VisibleButtonCount: integer; virtual;
  public
    property BeforeAction: TDBNavClickEvent read FBeforeAction write FBeforeAction;
    property ConfirmDelete: Boolean read FConfirmDelete write FConfirmDelete default True;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property Direction: TDBNavButtonDirection read FDirection write SetDirection default nbdHorizontal;
    property Flat: Boolean read FFlat write SetFlat default False;
    property Hints: TStrings read GetHints write SetHints;
    property Options: TDBNavigatorOptions read FOptions write FOptions;
    property OnClick: TDBNavClickEvent read FOnNavClick write FOnNavClick;
    property VisibleButtons: TDBNavButtonSet read FVisibleButtons
                             write SetVisibleButtons default DefaultDBNavigatorButtons;
    property ShowButtonHints: boolean read FShowButtonHints write SetShowButtonHints default true;
  end;
  
  
  { TDBNavButton }

  TDBNavButton = class(TSpeedButton)
  private
    FIndex: TDBNavButtonType;
    FNavStyle: TDBNavButtonStyle;
  protected
  public
    destructor Destroy; override;
    property NavStyle: TDBNavButtonStyle read FNavStyle write FNavStyle;
    property Index: TDBNavButtonType read FIndex write FIndex;
  end;

  { TDBNavFocusableButton }

  TDBNavFocusableButton = class(TBitBtn)
  private
    FIndex: TDBNavButtonType;
    FNavStyle: TDBNavButtonStyle;
  public
    property NavStyle: TDBNavButtonStyle read FNavStyle write FNavStyle;
    property Index: TDBNavButtonType read FIndex write FIndex;
  end;

  { TNavDataLink }

  TDBNavDataLink = class(TDataLink)
  private
    FNavigator: TDBCustomNavigator;
  protected
    procedure EditingChanged; override;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
  public
    constructor Create(TheNavigator: TDBCustomNavigator);
  end;


  { TDBNavigator }

  TDBNavigator = class(TDBCustomNavigator)
  published
    property Align default alNone;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BeforeAction;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property BorderSpacing;
    property BorderStyle;
    property BorderWidth;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color default clBackground;
    property ConfirmDelete;
    property DataSource;
    property Direction;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Flat;
    property Font;
    property Hints;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDrag;
    property Options;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default False;
    property Visible;
    property VisibleButtons;
  end;
  

// ToDo: Move this to db.pp
function ExtractFieldName(const Fields: string; var StartPos: Integer): string;

procedure ChangeDataSource(AControl: TControl; Link: TDataLink;
  NewDataSource: TDataSource);

procedure Register;

implementation

var
  FieldClasses: TList;

procedure RegFields(const AFieldClasses: array of TFieldClass);
var I: Integer;
    FieldClass: TFieldClass;
begin
  if FieldClasses = nil then FieldClasses := TList.Create;
  for I := Low(AFieldClasses) to High(AFieldClasses) do begin
    FieldClass := AFieldClasses[I];
    if (FieldClass <> Nil) And (FieldClasses.IndexOf(FieldClass) = -1) then
    begin
      FieldClasses.Add(FieldClass);
      RegisterNoIcon([FieldClass]);
      RegisterClass(FieldClass);
    end;
  end;
end;

function ExtractFieldName(const Fields: string; var StartPos: Integer): string;
var
  i: Integer;
begin
  i:=StartPos;
  while (i<=Length(Fields)) and (Fields[i]<>';') do Inc(i);
  Result:=Trim(Copy(Fields,StartPos,i-StartPos));
  if (i<=Length(Fields)) and (Fields[i]=';') then Inc(i);
  StartPos:=i;
end;

procedure ChangeDataSource(AControl: TControl; Link: TDataLink;
  NewDataSource: TDataSource);
begin
  if Link.DataSource=NewDataSource then exit;
  if Link.DataSource<>nil then
    Link.DataSource.RemoveFreeNotification(AControl);
  Link.DataSource:=NewDataSource;
  if Link.DataSource<>nil then
    Link.DataSource.FreeNotification(AControl);
end;

procedure Register;
begin
  RegisterComponents('Data Controls',[TDBNavigator,TDBText,TDBEdit,TDBMemo,
    TDBImage,TDBListBox,TDBLookupListBox,TDBComboBox,TDBLookupComboBox,
    TDBCheckBox, TDBRadioGroup, TDBCalendar,TDBGroupBox]);
  RegFields(DefaultFieldClasses);
end;

function TFieldDataLink.FieldCanModify: boolean;
var
  FieldList: TList;
  i: Integer;
begin
  result := Assigned(FField);
  if not result then
    exit;

  if FField.FieldKind=fkLookup then
  begin
    FieldList := TList.Create;
    try
      DataSet.GetFieldList(FieldList, FField.KeyFields);
      result := (FieldList.Count>0);
      i := 0;
      while result and (i<FieldList.Count) do
      begin
        result := TField(FieldList[i]).CanModify;
        inc(i);
      end;
    finally
      FieldList.Free;
    end;
  end else
    result := FField.CanModify;
end;

{TFieldDataLink  Private Methods}
{
  If the field exists and can be modified, then
  we CanModify as long as this hasn't been set
  ReadOnly somewhere else. Do we need any extra tests here?
}
function TFieldDataLink.GetCanModify: Boolean;
begin
  if FieldCanModify then
    Result := not ReadOnly
  else
    Result := False;
end;

{
  Set the FieldName and then notify the changes though EditingChanged and Reset
  Ensure FField is nil if something goes wrong or FieldName is empty
}
procedure TFieldDataLink.SetFieldName(const Value: string);
begin
  if FFieldName <> Value then
  begin
    FFieldName := Value;
    UpdateField;
    if Active then
    begin
      EditingChanged;
      Reset;
    end;
  end;
end;

procedure TFieldDataLink.UpdateField;
begin
  if Active and (FFieldName <> '') then
    FField := DataSet.FieldByName(FFieldName)
  else
    FField := nil;
end;

{
  This function checks if FField is still associated with the dataset
  If not update the field
}
procedure TFieldDataLink.ValidateField;
begin
  if not (DataSet.FindField(FFieldName) = FField) then
    UpdateField;
end;


{TFieldDataLink  Protected Methods}

{ Delphi Help ->
    Changes to the Active property trigger the ActiveChanged method.
    If an OnActiveChange event handler is assigned, ActiveChanged calls
    this event handler. If ActiveChanged is triggered by a transition into
    an active state, then before calling the event handler, ActiveChanged makes
    sure that the Field for this TFieldDataLink is still valid.
  <-- Delphi Help

   Update the field instance. When not Active field will be set to nil
   Call OnActiveChange
}
procedure TFieldDataLink.ActiveChanged;
begin
  if FFieldName <> '' then
  begin
    UpdateField;
    EditingChanged;
    Reset;
  end;
  if Assigned(FOnActiveChange) then
    FOnActiveChange(Self);
end;

{$IF ((FPC_VERSION = 2) and (FPC_RELEASE = 4) and (FPC_PATCH = 2))}
{
 This is not necessary since TDataLink.DatasetChanged calls RecordChanged
 Keep for now as a workaround to fpc bug 16428 (LayoutChanged not being called)
 The bug is present in fpc 242 (the last LCL supported version) but fixed in fpc 244 and up
}
procedure TFieldDataLink.DataSetChanged;
begin
  ValidateField;
  reset;
end;
{$ENDIF}


{ Delphi Help ->
    Changing the field binding can change the validity of the CanModify
    property, since individual field components can disallow edits. If
    TFieldDataLink is in an editing state when the Field property is changed,
    EditingChanged checks the CanModify property. If CanModify is False, it
    changes back out of the editing state.

    Note: This differs significantly from the inherited EditingChanged method
    of TDataLink. The functionality of the inherited method is replaced in
    TFieldDataLink by the OnEditingChange event handler.
  <-- Delphi Help

  ok so another event... but this time we simply change modified state
  if Editing and not CanModify? or do we also change to match if
  if not Editing and CanModify? i.e If Editing <> CanModify??  Will assume
  the latter just in case. easy to change back if I am wrong.

  Also based on this we replace parent routine, so do we need to keep track
  of Editing state ourself? I hope this is right. Anyone know for sure?

  OK .. based on the Modified routine we need to turn off
  our IsModified routine when succesfull right? so for now just turn
  it off as per my example.
}
procedure TFieldDataLink.EditingChanged;
var
  RealEditState : Boolean;
begin
  RealEditState := (CanModify and Inherited Editing);

  if (FEditing <> RealEditState) then
  begin
    FEditing := RealEditState;
    if not FEditing then
      IsModified := False;
    if Assigned(FOnEditingChange) then
      FOnEditingChange(Self);
  end;
end;

{ Delphi Help ->
    LayoutChanged is called after changes in the layout of one of the
    containers of the Control for this TFieldDataLink that might change the
    validity of its field binding. For example, if the Control is embedded
    within a TCustomDBGrid, and one of the columns is deleted, the Field
    property for the Control might become invalid.
  <-- Delphi Help

  Ensure FField is valid and notify
}
procedure TFieldDataLink.LayoutChanged;
begin
  ValidateField;
  if FField <> nil then
  begin
    EditingChanged;
    Reset;
  end;
  if Assigned(FOnLayoutChange) then
    FOnLayoutChange(Self);
end;

{ Delphi Help ->
    Applications can not call this protected method. It is triggered
    automatically when the contents of the current record change.
    RecordChanged calls the OnDataChange event handler if there is one.

    TDataLink.RecordChanged:
    The Field parameter indicates which field of the current record has changed in value.
    If Field is nil (Delphi) or NULL (C++), any number of fields within the current record may have changed.
  <-- Delphi Help

  Call Reset if AField = FField or aField = nil
}
procedure TFieldDataLink.RecordChanged(aField: TField);
begin
  if (aField = nil) or (aField = FField) then
    Reset;
end;

{ Delphi Help ->
    UpdateData overrides the default UpdateData method to call the
    OnUpdateData event handler where the data-aware control can write any
    pending edits to the record in the dataset.
  <-- Delphi Help

  where..can write pending events. So I guess when we have already
  called Modified? Aka if not IsModified exit otherwise call event?
  works for me.
}
procedure TFieldDataLink.UpdateData;
begin
  if not IsModified then
    exit;

  if Assigned(FOnUpdateData) then
    FOnUpdateData(Self);

  IsModified := False;
end;

{ Delphi Help ->
    Call FocusControl to give the Control associated with this TFieldDataLink
    object the input focus. FocusControl checks whether the Control can receive
    input focus, and if so, calls its SetFocus method to move focus to the
    Control.
  <-- Delphi Help

  so seems it just calls SetFocus on TWinControls, since this DataLink should
  really go into the FCL, we just add our own callback which the DB aware
  controls that can get focus then assign to do the real SetFocus, thus removing
  need for visual dependency.
}

procedure TFieldDataLink.FocusControl(aField: TFieldRef);
begin
  If Assigned(aField) and (aField^ = FField) then
    if Assigned(FOnFocusRequest) then begin
      aField^ := nil;
      FOnFocusRequest(Self);
    end;
end;

{TFieldDataLink  Public Methods}

constructor TFieldDataLink.Create;
begin
  inherited Create;
  VisualControl := True;
  //FField := nil;
  //FFieldname := '';
end;

{ Delphi Help ->
    Use Edit to try to ensure that the contents of the field can be modified.
    A return value of True indicates that the field was already in an editing
    state, or that the DataSource was successfully changed to allow editing.
    A return value of False indicates that the DataSource could not be changed
    to allow editing. For example, if the CanModify property is False, Edit
    fails, and returns False.
  <-- Delphi Help

  ok so the way I see it, since the inherited function calls EditingChanged,
  which we have already overriden to modify our own Editing state if its invalid,
  I should just be calling the inherited routine here, but only if CanModify,
  since there is no point otherwise. But since we _are_ keeping track of editing
  state ourselves we return our own state, not the inherited. If anyone know
  better please fix.
}
function TFieldDataLink.Edit: Boolean;
begin
  if (not FEditing) and CanModify then
    inherited Edit;

  Result := FEditing;
end;

{ Delphi Help ->
    Call Modified when the Control for this TFieldDataLink begins processing
    edits.
  <-- Delphi Help

  ok so. well _that's_ helpfull. for the moment going to keep track
  by adding an IsModified... based on the other functions thus far
  we need to know whether we are in state, so I am assuming it goes

  Call Modified ->
    IsModified:=True;//Waiting for modifications

  Call SomeFunction->
    If IsModified then begin
      (do something)
      IsModified := False;//All modifications complete
    end
    else
     (do something else? exit?);
}
procedure TFieldDataLink.Modified;
begin
  IsModified := True;
end;

{ Delphi Help ->
    The Control that owns a TFieldDataLink object calls its Reset method to
    process a UI action that cancels edits to the field. Reset calls the
    OnDataChange event handler without writing any pending changes to the
    record in the dataset.
  <-- Delphi Help

  Just call to the OnDataChange Event, and turn off IsModified
}
procedure TFieldDataLink.Reset;
begin
  if Assigned(FOnDataChange) then
    FOnDataChange(Self);

  IsModified := False;
end;

{$Include dblookup.inc}
{$Include dbedit.inc}
{$Include dbtext.inc}
{$Include customdblistbox.inc}
{$Include dblistbox.inc}
{$Include dblookuplistbox.inc}
{$Include dbradiogroup.inc}
{$Include dbcheckbox.inc}
{$Include customdbcombobox.inc}
{$Include dbcombobox.inc}
{$Include dblookupcombobox.inc}
{$Include dbmemo.inc}
{$Include dbgroupbox.inc}
{$Include dbimage.inc}
{$Include dbcalendar.inc}
{$Include dbcustomnavigator.inc}


initialization
  {$I lcl_dbnav_images.lrs}

finalization
  FieldClasses.Free;

end.
