{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Shane Miller, Mattias Gaertner

  Abstract:
    Methods to access the form editing of the IDE.
}
unit FormEditingIntf;

{$mode objfpc}{$H+}

interface

uses
  Math, Classes, SysUtils, LCLProc, TypInfo, types, Forms, Controls,
  ProjectIntf, ComponentEditors;
  
const
  ComponentPaletteImageWidth = 24;
  ComponentPaletteImageHeight = 24;
  ComponentPaletteBtnWidth  = ComponentPaletteImageWidth + 3;
  ComponentPaletteBtnHeight = ComponentPaletteImageHeight + 3;

type
  { TIComponentInterface }

  TIComponentInterface = class
  protected
    FComponent : TComponent;
  public
    function GetComponentType    : ShortString; virtual; abstract;
    function GetComponentHandle  : LongInt; virtual; abstract;
    function GetParent           : TIComponentInterface; virtual; abstract;
    function IsTControl          : Boolean; virtual; abstract;
    function GetPropCount	   : Integer; virtual; abstract;
    function GetPropType(Index : Integer) : TTypeKind; virtual; abstract;
    // function GetPropType(Index : Integer) : TPropertyType; virtual; abstract;
    function GetPropName(Index : Integer) : Shortstring; virtual; abstract;
    function GetPropTypeByName(Name : ShortString) : TTypeKind; virtual; abstract;
    // function GetPropTypebyName(Name : ShortString) : TPropertyType; virtual; abstract;
    function GetPropTypeName(Index : Integer) : ShortString; virtual; abstract;

    function GetPropValue(Index : Integer; var Value) : Boolean; virtual; abstract;
    function GetPropValuebyName(Name: Shortstring; var Value) : Boolean; virtual; abstract;
    function SetProp(Index : Integer; const Value) : Boolean; virtual; abstract;
    function SetPropbyName(Name : Shortstring; const Value) : Boolean; virtual; abstract;

    function GetControlCount: Integer; virtual; abstract;
    function GetControl(Index : Integer): TIComponentInterface; virtual; abstract;

    function GetComponentCount: Integer; virtual; abstract;
    function GetComponent(Index : Integer): TIComponentInterface; virtual; abstract;

    function Select: Boolean; virtual; abstract;
    function Focus: Boolean; virtual; abstract;
    function Delete: Boolean; virtual; abstract;

    property Component: TComponent read FComponent;
  end;


  { TIFormInterface }

  TIFormInterface = class
  public
    function Filename            : AnsiString; virtual; abstract;
    function FormModified        : Boolean; virtual; abstract;
    function MarkModified        : Boolean; virtual; abstract;
    function GetFormComponent    : TIComponentInterface; virtual; abstract;
    function FindComponent       : TIComponentInterface; virtual; abstract;
    function GetComponentfromHandle(ComponentHandle:Pointer): TIComponentInterface; virtual; abstract;

    function GetSelCount: Integer; virtual; abstract;
    function GetSelComponent(Index : Integer): TIComponentInterface; virtual; abstract;
    function CreateComponent(CI : TIComponentInterface; TypeClass : TComponentClass;
                             X,Y,W,H : Integer): TIComponentInterface; virtual; abstract;
  end;

  { TDesignerMediator
    To edit designer forms which do not use the LCL, register a TDesignerMediator,
    which will emulate the painting, handle the mouse and editing bounds. }

  TDesignerMediator = class(TComponent)
  private
    FDesigner: TComponentEditorDesigner;
    FLCLForm: TForm;
  protected
    procedure SetDesigner(const AValue: TComponentEditorDesigner);
    procedure SetLCLForm(const AValue: TForm); virtual;
  public
    class function FormClass: TComponentClass; virtual; abstract;
    class function CreateMediator(TheOwner, aForm: TComponent): TDesignerMediator; virtual; abstract;
    class procedure InitFormInstance(aForm: TComponent); virtual; // called after NewInstance, before constructor
  public
    procedure SetBounds(AComponent: TComponent; NewBounds: TRect); virtual;
    procedure GetBounds(AComponent: TComponent; out CurBounds: TRect); virtual;
    procedure SetFormBounds(RootComponent: TComponent; NewBounds, ClientRect: TRect); virtual;
    procedure GetFormBounds(RootComponent: TComponent; out CurBounds, CurClientRect: TRect); virtual;
    procedure GetClientArea(AComponent: TComponent; out CurClientArea: TRect;
                            out ScrollOffset: TPoint); virtual;
    function GetComponentOriginOnForm(AComponent: TComponent): TPoint; virtual;
    procedure Paint; virtual;
    function ComponentIsIcon(AComponent: TComponent): boolean; virtual;
    function ParentAcceptsChild(Parent: TComponent; Child: TComponentClass): boolean; virtual;
    property LCLForm: TForm read FLCLForm write SetLCLForm;
    property Designer: TComponentEditorDesigner read FDesigner write SetDesigner;
  end;
  TDesignerMediatorClass = class of TDesignerMediator;


  { TAbstractFormEditor }
  
  TAbstractFormEditor = class
  protected
    function GetDesignerBaseClasses(Index: integer): TComponentClass; virtual; abstract;
    function GetDesigner(Index: integer): TIDesigner; virtual; abstract;
    function GetDesignerMediators(Index: integer): TDesignerMediatorClass; virtual; abstract;
  public
    // components
    function FindComponentByName(const Name: ShortString
                                 ): TIComponentInterface; virtual; abstract;
    function FindComponent(AComponent: TComponent): TIComponentInterface; virtual; abstract;

    function GetDefaultComponentParent(TypeClass: TComponentClass
                                       ): TIComponentInterface; virtual; abstract;
    function GetDefaultComponentPosition(TypeClass: TComponentClass;
                                         ParentCI: TIComponentInterface;
                                         var X,Y: integer): boolean; virtual; abstract;
    function CreateComponent(ParentCI: TIComponentInterface;
                             TypeClass: TComponentClass;
                             const AUnitName: shortstring;
                             X,Y,W,H: Integer): TIComponentInterface; virtual; abstract;
    function CreateComponentFromStream(BinStream: TStream;
                      AncestorType: TComponentClass;
                      const NewUnitName: ShortString;
                      Interactive: boolean;
                      Visible: boolean = true;
                      ContextObj: TObject = nil): TIComponentInterface; virtual; abstract;
    function CreateChildComponentFromStream(BinStream: TStream;
                                     ComponentClass: TComponentClass;
                                     Root: TComponent;
                                     ParentControl: TWinControl
                                     ): TIComponentInterface; virtual; abstract;

    // ancestors
    function GetAncestorLookupRoot(AComponent: TComponent): TComponent; virtual; abstract;
    function GetAncestorInstance(AComponent: TComponent): TComponent; virtual; abstract;
    function RegisterDesignerBaseClass(AClass: TComponentClass): integer; virtual; abstract;
    function DesignerBaseClassCount: Integer; virtual; abstract;
    property DesignerBaseClasses[Index: integer]: TComponentClass read GetDesignerBaseClasses;
    procedure UnregisterDesignerBaseClass(AClass: TComponentClass); virtual; abstract;
    function IndexOfDesignerBaseClass(AClass: TComponentClass): integer; virtual; abstract;
    function DescendFromDesignerBaseClass(AClass: TComponentClass): integer; virtual; abstract;
    function FindDesignerBaseClassByName(const AClassName: shortstring; WithDefaults: boolean): TComponentClass; virtual; abstract;

    // designers
    function DesignerCount: integer; virtual; abstract;
    property Designer[Index: integer]: TIDesigner read GetDesigner;
    function GetCurrentDesigner: TIDesigner; virtual; abstract;
    function GetDesignerForm(AComponent: TComponent): TCustomForm; virtual; abstract;
    function GetDesignerByComponent(AComponent: TComponent
                                    ): TIDesigner; virtual; abstract;

    // mediators for non LCL forms
    procedure RegisterDesignerMediator(MediatorClass: TDesignerMediatorClass); virtual; abstract; // auto calls RegisterDesignerBaseClass
    procedure UnregisterDesignerMediator(MediatorClass: TDesignerMediatorClass); virtual; abstract; // auto calls UnregisterDesignerBaseClass
    function DesignerMediatorCount: integer; virtual; abstract;
    property DesignerMediators[Index: integer]: TDesignerMediatorClass read GetDesignerMediators;
    function GetDesignerMediatorByComponent(AComponent: TComponent): TDesignerMediator; virtual; abstract;

    // selection
    function SaveSelectionToStream(s: TStream): Boolean; virtual; abstract;
    function InsertFromStream(s: TStream; Parent: TWinControl;
                              Flags: TComponentPasteSelectionFlags
                              ): Boolean; virtual; abstract;
    function ClearSelection: Boolean; virtual; abstract;
    function DeleteSelection: Boolean; virtual; abstract;
    function CopySelectionToClipboard: Boolean; virtual; abstract;
    function CutSelectionToClipboard: Boolean; virtual; abstract;
    function PasteSelectionFromClipboard(Flags: TComponentPasteSelectionFlags
                                         ): Boolean; virtual; abstract;
  end;

type
  TDesignerIDECommandForm = class(TCustomForm)
    // dummy form class, use by the IDE commands for keys in the designers
  end;

var
  FormEditingHook: TAbstractFormEditor; // will be set by the IDE

procedure GetComponentLeftTopOrDesignInfo(AComponent: TComponent; out aLeft, aTop: integer); // get properties if exists, otherwise get DesignInfo
procedure SetComponentLeftTopOrDesignInfo(AComponent: TComponent; aLeft, aTop: integer); // set properties if exists, otherwise set DesignInfo
function TrySetOrdProp(Instance: TPersistent; const PropName: string;
                       Value: integer): boolean;
function TryGetOrdProp(Instance: TPersistent; const PropName: string;
                       out Value: integer): boolean;
function LeftFromDesignInfo(ADesignInfo: LongInt): SmallInt;
function TopFromDesignInfo(ADesignInfo: LongInt): SmallInt;
function LeftTopToDesignInfo(const ALeft, ATop: SmallInt): LongInt;
procedure DesignInfoToLeftTop(ADesignInfo: LongInt; out ALeft, ATop: SmallInt);


implementation


procedure GetComponentLeftTopOrDesignInfo(AComponent: TComponent; out aLeft,
  aTop: integer);
var
  Info: LongInt;
begin
  Info:=AComponent.DesignInfo;
  if not TryGetOrdProp(AComponent,'Left',aLeft) then
    aLeft:=LeftFromDesignInfo(Info);
  if not TryGetOrdProp(AComponent,'Top',aTop) then
    aTop:=TopFromDesignInfo(Info);
end;

procedure SetComponentLeftTopOrDesignInfo(AComponent: TComponent;
  aLeft, aTop: integer);
var
  HasLeft: Boolean;
  HasTop: Boolean;
begin
  HasLeft:=TrySetOrdProp(AComponent,'Left',aLeft);
  HasTop:=TrySetOrdProp(AComponent,'Top',aTop);
  if HasLeft and HasTop then exit;
  ALeft := Max(Low(SmallInt), Min(ALeft, High(SmallInt)));
  ATop := Max(Low(SmallInt), Min(ATop, High(SmallInt)));
  AComponent.DesignInfo:=LeftTopToDesignInfo(aLeft,aTop);
end;

function TrySetOrdProp(Instance: TPersistent; const PropName: string;
  Value: integer): boolean;
var
  PropInfo: PPropInfo;
begin
  PropInfo:=GetPropInfo(Instance.ClassType,PropName);
  if PropInfo=nil then exit(false);
  SetOrdProp(Instance,PropInfo,Value);
  Result:=true;
end;

function TryGetOrdProp(Instance: TPersistent; const PropName: string; out
  Value: integer): boolean;
var
  PropInfo: PPropInfo;
begin
  PropInfo:=GetPropInfo(Instance.ClassType,PropName);
  if PropInfo=nil then exit(false);
  Value:=GetOrdProp(Instance,PropInfo);
  Result:=true;
end;

function LeftFromDesignInfo(ADesignInfo: LongInt): SmallInt;
var
  DesignInfoRec: packed record
    Left: SmallInt;
    Top: SmallInt;
  end absolute ADesignInfo;
begin
  Result := DesignInfoRec.Left;
end;

function TopFromDesignInfo(ADesignInfo: LongInt): SmallInt;
var
  DesignInfoRec: packed record
    Left: SmallInt;
    Top: SmallInt;
  end absolute ADesignInfo;
begin
  Result := DesignInfoRec.Top;
end;

function LeftTopToDesignInfo(const ALeft, ATop: SmallInt): LongInt;
var
  ResultRec: packed record
    Left: SmallInt;
    Top: SmallInt;
  end absolute Result;
begin
  ResultRec.Left := ALeft;
  ResultRec.Top := ATop;
end;

procedure DesignInfoToLeftTop(ADesignInfo: LongInt; out ALeft, ATop: SmallInt);
var
  DesignInfoRec: packed record
    Left: SmallInt;
    Top: SmallInt;
  end absolute ADesignInfo;
begin
  ALeft := DesignInfoRec.Left;
  ATop := DesignInfoRec.Top;
end;

{ TDesignerMediator }

procedure TDesignerMediator.SetDesigner(const AValue: TComponentEditorDesigner
  );
begin
  if FDesigner=AValue then exit;
  FDesigner:=AValue;
end;

procedure TDesignerMediator.SetLCLForm(const AValue: TForm);
begin
  if FLCLForm=AValue then exit;
  FLCLForm:=AValue;
end;

class procedure TDesignerMediator.InitFormInstance(aForm: TComponent);
begin

end;

procedure TDesignerMediator.SetBounds(AComponent: TComponent; NewBounds: TRect
  );
begin
  SetComponentLeftTopOrDesignInfo(AComponent,NewBounds.Left,NewBounds.Top);
end;

procedure TDesignerMediator.GetBounds(AComponent: TComponent; out
  CurBounds: TRect);
var
  aLeft: integer;
  aTop: integer;
begin
  GetComponentLeftTopOrDesignInfo(AComponent,aLeft,aTop);
  CurBounds:=Rect(aLeft,aTop,aLeft+ComponentPaletteBtnWidth,aTop+ComponentPaletteBtnHeight);
end;

procedure TDesignerMediator.SetFormBounds(RootComponent: TComponent; NewBounds,
  ClientRect: TRect);
// default: use NewBounds as position and the ClientRect as size
var
  r: TRect;
begin
  r:=Bounds(NewBounds.Left,NewBounds.Top,
            ClientRect.Right-ClientRect.Left,ClientRect.Bottom-ClientRect.Top);
  //debugln(['TDesignerMediator.SetFormBounds NewBounds=',dbgs(NewBounds),' ClientRect=',dbgs(ClientRect),' r=',dbgs(r)]);
  SetBounds(RootComponent,r);
end;

procedure TDesignerMediator.GetFormBounds(RootComponent: TComponent; out
  CurBounds, CurClientRect: TRect);
// default: clientarea is whole bounds and CurBounds.Width/Height=0
// The IDE will use the clientarea to determine the size of the form
begin
  GetBounds(RootComponent,CurBounds);
  //debugln(['TDesignerMediator.GetFormBounds ',dbgs(CurBounds)]);
  CurClientRect:=Rect(0,0,CurBounds.Right-CurBounds.Left,
                      CurBounds.Bottom-CurBounds.Top);
  CurBounds.Right:=CurBounds.Left;
  CurBounds.Bottom:=CurBounds.Top;
  //debugln(['TDesignerMediator.GetFormBounds ',dbgs(CurBounds),' ',dbgs(CurClientRect)]);
end;

procedure TDesignerMediator.GetClientArea(AComponent: TComponent; out
  CurClientArea: TRect; out ScrollOffset: TPoint);
// default: no ScrollOffset and client area is whole bounds
begin
  GetBounds(AComponent,CurClientArea);
  OffsetRect(CurClientArea,-CurClientArea.Left,-CurClientArea.Top);
  ScrollOffset:=Point(0,0);
end;

function TDesignerMediator.GetComponentOriginOnForm(AComponent: TComponent): TPoint;
var
  Parent: TComponent;
  ClientArea: TRect;
  ScrollOffset: TPoint;
begin
  Result:=Point(0,0);
  while AComponent<>nil do begin
    Parent:=AComponent.GetParentComponent;
    if Parent=nil then break;
    GetClientArea(Parent,ClientArea,ScrollOffset);
    inc(Result.X,ClientArea.Left+ScrollOffset.X);
    inc(Result.Y,ClientArea.Top+ScrollOffset.Y);
  end;
end;

procedure TDesignerMediator.Paint;
begin

end;

function TDesignerMediator.ComponentIsIcon(AComponent: TComponent): boolean;
begin
  Result:=true;
end;

function TDesignerMediator.ParentAcceptsChild(Parent: TComponent;
  Child: TComponentClass): boolean;
begin
  Result:=false;
end;

end.

