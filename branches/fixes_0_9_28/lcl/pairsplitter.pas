{  $Id$  }
{
 /***************************************************************************
                             pairsplitter.pas
                             ----------------
                        Component Library Controls


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

  Author: Mattias Gaertner
  
  Abstract:
    TPairSplitter component. A component with two TPairSplitterSide childs.
    Both child components can contain other components and the childs are
    divided by a splitter which can be dragged by the user.
}
unit PairSplitter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  LCLType, LCLProc, LMessages, Graphics, GraphType, LCLIntf, Controls, ExtCtrls;
  
type
  TCustomPairSplitter = class;

  { TPairSplitterSide }
  
  TPairSplitterSide = class(TWinControl)
  private
    fCreatedBySplitter: boolean;
    function GetSplitter: TCustomPairSplitter;
  protected
    class procedure WSRegisterClass; override;
    procedure SetParent(AParent: TWinControl); override;
    procedure WMPaint(var PaintMessage: TLMPaint); message LM_PAINT;
    procedure Paint; virtual;
    property Align;
    property Anchors;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  public
    property Splitter: TCustomPairSplitter read GetSplitter;
    property Visible;
    property Left;
    property Top;
    property Width;
    property Height;
  published
    property ChildSizing;
    property ClientWidth;
    property ClientHeight;
    property Cursor;
    property Enabled;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property ShowHint;
    property ParentShowHint;
    property PopupMenu;
  end;
  
  { TCustomPairSplitter }
  
  TPairSplitterType = (
    pstHorizontal,
    pstVertical
    );
    
  TCustomPairSplitter = class(TWinControl)
  private
    FPosition: integer;
    FSides: array[0..1] of TPairSplitterSide;
    FSplitterType: TPairSplitterType;
    FDoNotCreateSides: boolean;
    FLoadCursor: TCursor;
    function GetPosition: integer;
    function GetSides(Index: integer): TPairSplitterSide;
    procedure SetPosition(const AValue: integer);
    procedure SetSplitterType(const AValue: TPairSplitterType);
    procedure AddSide(ASide: TPairSplitterSide);
    procedure RemoveSide(ASide: TPairSplitterSide);
  protected
    class procedure WSRegisterClass; override;
    function GetCursor: TCursor; override;
    procedure SetCursor(Value: TCursor); override;
    class function GetControlClassDefaultSize: TPoint; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateWnd; override;
    procedure UpdatePosition;
    procedure CreateSides;
    procedure Loaded; override;
    function ChildClassAllowed(ChildClass: TClass): boolean; override;
  public
    property Cursor default crHSplit;
    property Sides[Index: integer]: TPairSplitterSide read GetSides;
    property SplitterType: TPairSplitterType read FSplitterType
                                    write SetSplitterType default pstHorizontal;
    property Position: integer read GetPosition write SetPosition;
  end;
  
  
  { TPairSplitter }

  TPairSplitter = class(TCustomPairSplitter)
  published
    property Align;
    property Anchors;
    property BorderSpacing;
    property Cursor;
    property Enabled;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnChangeBounds;
    property ParentShowHint;
    property PopupMenu;
    property Position;
    property ShowHint;
    property SplitterType;
    property Visible;
  end;
  
procedure Register;
  
implementation

uses
  WSPairSplitter;
  
procedure Register;
begin
  RegisterComponents('Additional',[TPairSplitter]);
  RegisterNoIcon([TPairSplitterSide]);
end;

{ TPairSplitterSide }

function TPairSplitterSide.GetSplitter: TCustomPairSplitter;
begin
  if (Parent<>nil) and (Parent is TCustomPairSplitter) then
    Result:=TCustomPairSplitter(Parent)
  else
    Result:=nil;
end;

class procedure TPairSplitterSide.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterPairSplitterSide;
end;

procedure TPairSplitterSide.SetParent(AParent: TWinControl);
var
  ASplitter: TCustomPairSplitter;
begin
  CheckNewParent(AParent);
  // remove from side list of old parent
  ASplitter := Splitter;
  if ASplitter <> nil then
    ASplitter.RemoveSide(Self);

  inherited SetParent(AParent);

  // add to side list of new parent
  ASplitter:=Splitter;
  if ASplitter <> nil then
    ASplitter.AddSide(Self);
end;

procedure TPairSplitterSide.WMPaint(var PaintMessage: TLMPaint);
begin
  if (csDestroying in ComponentState) or (not HandleAllocated) then
    Exit;
  Include(FControlState, csCustomPaint);
  inherited WMPaint(PaintMessage);
  Paint;
  Exclude(FControlState, csCustomPaint);
end;

procedure TPairSplitterSide.Paint;
var
  ACanvas: TControlCanvas;
begin
  if csDesigning in ComponentState then
  begin
    ACanvas := TControlCanvas.Create;
    with ACanvas do
    begin
      Control := Self;
      Pen.Style := psDash;
      Frame(0,0,Width-1,Height-1);
      Free;
    end;
  end;
end;

constructor TPairSplitterSide.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FCompStyle := csPairSplitterSide;
  ControlStyle := ControlStyle + [csAcceptsControls];
end;

destructor TPairSplitterSide.Destroy;
begin
  inherited Destroy;
end;

{ TCustomPairSplitter }

function TCustomPairSplitter.GetSides(Index: integer): TPairSplitterSide;
begin
  if (Index < 0) or (Index > 1) then
    RaiseGDBException('TCustomPairSplitter.GetSides: Index out of bounds');
  Result := FSides[Index];
end;

function TCustomPairSplitter.GetPosition: integer;
begin
  if HandleAllocated and (not (csLoading in ComponentState)) then
    UpdatePosition;
  Result := FPosition;
end;

procedure TCustomPairSplitter.SetPosition(const AValue: integer);
begin
  if FPosition = AValue then
    Exit;
  FPosition := AValue;
  if FPosition < 0 then
    FPosition := 0;
  if HandleAllocated and (not (csLoading in ComponentState)) then
    TWSCustomPairSplitterClass(WidgetSetClass).SetPosition(Self, FPosition);
end;

procedure TCustomPairSplitter.SetSplitterType(const AValue: TPairSplitterType);
const
  DefaultCursors: array[TPairSplitterType] of TCursor =
  (
{ pstHorizontal } crHSplit,
{ pstVertical   } crVSplit
  );
begin
  if FSplitterType = AValue then
    Exit;

  if Cursor = DefaultCursors[FSplitterType] then
    Cursor := DefaultCursors[AValue];

  FSplitterType := AValue;
  
  // TODO: Remove RecreateWnd
  if HandleAllocated then
    RecreateWnd(Self);
end;

procedure TCustomPairSplitter.AddSide(ASide: TPairSplitterSide);
var
  i: Integer;
begin
  if ASide = nil then
    Exit;
  i := Low(FSides);
  repeat
    if FSides[i] = ASide then
    Exit;
    if FSides[i] =nil then
    begin
      FSides[i] := ASide;
      if HandleAllocated then
        TWSCustomPairSplitterClass(WidgetSetClass).AddSide(Self, ASide, i);
      break;
    end;
    inc(i);
    if i > High(FSides) then
    RaiseGDBException('TCustomPairSplitter.AddSide no free side left');
  until False;
end;

procedure TCustomPairSplitter.RemoveSide(ASide: TPairSplitterSide);
var
  i: Integer;
begin
  if ASide = nil then
    Exit;
  for i := Low(FSides) to High(FSides) do
    if FSides[i]=ASide then
    begin
      if HandleAllocated and ASide.HandleAllocated then
        TWSCustomPairSplitterClass(WidgetSetClass).RemoveSide(Self, ASide, i);
      FSides[i] := nil;
    end;
  // if the user deletes a side at designtime, autocreate a new one
  if (csDesigning in ComponentState) then
    CreateSides;
end;

class procedure TCustomPairSplitter.WSRegisterClass;
begin
  inherited WSRegisterClass;
  RegisterCustomPairSplitter;
end;

function TCustomPairSplitter.GetCursor: TCursor;
begin
  // Paul Ishenin: I dont know another method to tell internal splitter about
  // cursor changes
  
  // if widgetset class dont want to get cursor (has no internal splitter) then
  // use default lcl handler
  if not TWSCustomPairSplitterClass(WidgetSetClass).GetSplitterCursor(Self, Result) then
    Result := inherited GetCursor;
end;

procedure TCustomPairSplitter.SetCursor(Value: TCursor);
begin
  FLoadCursor := Value;
  if not HandleAllocated then
    Exit;
  // if widgetset class dont want to set cursor (has no internal splitter) then
  // use default lcl handler
  if not TWSCustomPairSplitterClass(WidgetSetClass).SetSplitterCursor(Self, Value) then
    inherited SetCursor(Value);
end;

class function TCustomPairSplitter.GetControlClassDefaultSize: TPoint;
begin
  Result.X:=90;
  Result.Y:=90;
end;

constructor TCustomPairSplitter.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FCompStyle := csPairSplitter;
  ControlStyle := ControlStyle - [csAcceptsControls];
  FSplitterType := pstHorizontal;
  Cursor := crHSplit;
  SetInitialBounds(0, 0, GetControlClassDefaultSize.X, GetControlClassDefaultSize.Y);
  FPosition:=45;
  CreateSides;
end;

destructor TCustomPairSplitter.Destroy;
var
  i: Integer;
begin
  // destroy the sides
  fDoNotCreateSides:=true;
  for i:=Low(FSides) to High(FSides) do
    if (FSides[i]<>nil) and (FSides[i].fCreatedBySplitter) then
      FSides[i].Free;
  inherited Destroy;
end;

procedure TCustomPairSplitter.CreateWnd;
var
  i: Integer;
  APosition: Integer;
begin
  inherited CreateWnd;
  for i := Low(FSides) to High(FSides) do
    if FSides[i] <> nil then
      TWSCustomPairSplitterClass(WidgetSetClass).AddSide(Self, FSides[i], i);
  APosition := FPosition;
  TWSCustomPairSplitterClass(WidgetSetClass).SetPosition(Self, APosition);
  SetCursor(FLoadCursor);
  if not (csLoading in ComponentState) then
    FPosition := APosition;
end;

procedure TCustomPairSplitter.UpdatePosition;
var
  CurPosition: Integer;
begin
  if HandleAllocated then
  begin
    CurPosition := -1;
    TWSCustomPairSplitterClass(WidgetSetClass).SetPosition(Self, CurPosition);
    FPosition := CurPosition;
  end;
end;

procedure TCustomPairSplitter.CreateSides;
var
  ASide: TPairSplitterSide;
  i: Integer;
begin
  if fDoNotCreateSides or (csDestroying in ComponentState)
  or (csLoading in ComponentState)
  or ((Owner<>nil) and (csLoading in Owner.ComponentState)) then exit;
  // create the missing side controls
  for i := Low(FSides) to High(FSides) do
    if FSides[i]=nil then
    begin
      // For streaming it is important that the side controls are owned by
      // the owner of the splitter
      ASide:=TPairSplitterSide.Create(Owner);
      ASide.fCreatedBySplitter:=true;
      ASide.Parent:=Self;
    end;
end;

procedure TCustomPairSplitter.Loaded;
begin
  inherited Loaded;
  CreateSides;
  if HandleAllocated then
    TWSCustomPairSplitterClass(WidgetSetClass).SetPosition(Self, FPosition);
end;

function TCustomPairSplitter.ChildClassAllowed(ChildClass: TClass): boolean;
begin
  Result := ChildClass.InheritsFrom(TPairSplitterSide) or
            ChildClass.InheritsFrom(TSplitter);
end;

end.