{%MainUnit ../stdctrls.pp}
{  $Id$  }

{******************************************************************************
                                     TCustomMemo
 ******************************************************************************
 
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{------------------------------------------------------------------------------
  Method: TCustomMemo.Create
  Params: 
  Returns: 

  Constructor for the class
 ------------------------------------------------------------------------------}
constructor TCustomMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCompStyle := csMemo;
  FWordWrap := True;
  //FLines := TMemoStrings.Create(Self);
  FLines := TStringList.Create; //TODO finish TTextStrings and add them here instead of TStringList
  //TMemoStrings(FLines).MemoWidgetClass := TWSCustomMemoClass(WidgetSetClass);
  FVertScrollbar := TMemoScrollBar.Create(Self, sbVertical);
  FHorzScrollbar := TMemoScrollBar.Create(Self, sbHorizontal);
  SetInitialBounds(0,0,150,90);
end;

{------------------------------------------------------------------------------
  Method: TCustomMemo.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TCustomMemo.Destroy;
begin
  FreeThenNil(FLines);
  FreeThenNil(FVertScrollbar);
  FreeThenNil(FHorzScrollbar);
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Method: TCustomMemo.Append
  Params: 
  Returns: 

 ------------------------------------------------------------------------------}
procedure TCustomMemo.Append(const Value : String);
begin
  Lines.Add(Value);
end;

{------------------------------------------------------------------------------
  procedure TCustomMemo.SetHorzScrollBar(const AValue: TMemoScrollBar);
 ------------------------------------------------------------------------------}
procedure TCustomMemo.SetHorzScrollBar(const AValue: TMemoScrollBar);
begin
  if FHorzScrollBar=AValue then exit;
  FHorzScrollBar:=AValue;
end;

{------------------------------------------------------------------------------
  procedure TCustomMemo.SetVertScrollBar(const AValue: TMemoScrollBar);
 ------------------------------------------------------------------------------}
procedure TCustomMemo.SetVertScrollBar(const AValue: TMemoScrollBar);
begin
  if FVertScrollBar=AValue then exit;
  FVertScrollBar:=AValue;
end;

{------------------------------------------------------------------------------
  function TCustomMemo.StoreScrollBars: boolean;
 ------------------------------------------------------------------------------}
function TCustomMemo.StoreScrollBars: boolean;
begin
  Result:=true;
end;

procedure TCustomMemo.CreateHandle;
var
  NewStrings : TStrings;
begin
  //DebugLn('[TCustomMemo.CreateHandle] A ',FLines.ClassName);
  inherited CreateHandle;
  //DebugLn('[TCustomMemo.CreateHandle] B ',DbgSName(Self),' ',FLines.ClassName,' FLines.Count=',dbgs(FLines.Count));
  
  // fetch/create the interface item list
  NewStrings := TWSCustomMemoClass(WidgetSetClass).GetStrings(Self);
  // copy the items (text)
  NewStrings.Assign(Lines);

  // free old items
  FLines.Free;

  // new item list is the interface item list
  FLines:= NewStrings;

  //DebugLn('[TCustomMemo.CreateHandle] END ',DbgSName(Self),' ',FLines.ClassName,' FLines.Count=',dbgs(FLines.Count));
end;

procedure TCustomMemo.DestroyHandle;
var
  NewStrings : TStringList;

begin
  if Assigned(FLines) then begin
    // create internal item list
    NewStrings:= TStringList.Create;

    // copy items (text+objects) from the interface items list
    NewStrings.Assign(Lines);

    FLines.Free;
    // new item list is the internal item list
    FLines:= NewStrings;
  end;
  inherited DestroyHandle;
end;

function TCustomMemo.RealGetText: TCaption;
begin
  Result := Lines.Text;
  //debugln('TCustomMemo.RealGetText "',Result,'"');
end;

procedure TCustomMemo.RealSetText(const Value: TCaption);
begin
  //debugln('TCustomMemo.RealSetText "',Value,'"');
  Lines.Text := Value;
end;

function TCustomMemo.GetCachedText(var CachedText: TCaption): boolean;
begin
  Result:= false;
end;

{------------------------------------------------------------------------------
  Method: TCustomMemo.SetLines
  Params: 
  Returns: 

 ------------------------------------------------------------------------------}
procedure TCustomMemo.SetLines(const Value : TStrings);
begin
  if (Value <> nil) then
    FLines.Assign(Value);
end;

{------------------------------------------------------------------------------
  procedure TCustomMemo.SetScrollbars(const Value : TScrollStyle);
 ------------------------------------------------------------------------------}
procedure TCustomMemo.SetScrollbars(const Value : TScrollStyle);
begin
  if Value <> FScrollbars then begin
    FScrollbars:= Value;
    if HandleAllocated and (not (csLoading in ComponentState)) then
      TWSCustomMemoClass(WidgetSetClass).SetScrollbars(Self, Value);
  end;
end;

{------------------------------------------------------------------------------
  procedure TCustomMemo.InitializeWnd;
 ------------------------------------------------------------------------------}
procedure TCustomMemo.InitializeWnd;
begin
  inherited InitializeWnd;
end;

{------------------------------------------------------------------------------
  procedure TCustomMemo.Loaded;
 ------------------------------------------------------------------------------}
procedure TCustomMemo.Loaded;
begin
  inherited Loaded;

  if HandleAllocated then begin
    TWSCustomMemoClass(WidgetSetClass).SetScrollbars(Self, FScrollbars);
    TWSCustomMemoClass(WidgetSetClass).SetWordWrap(Self, FWordWrap);
  end;
end;

{------------------------------------------------------------------------------
  function TCustomMemo.WordWrapIsStored: boolean;
 ------------------------------------------------------------------------------}
function TCustomMemo.WordWrapIsStored: boolean;
begin
  Result:=not WordWrap;
end;

procedure TCustomMemo.ControlKeyDown(var Key: Word; Shift: TShiftState);
begin
  if not ReadOnly then begin
    if (Key=VK_RETURN) and (Shift=[]) then exit;
    if (Key=VK_TAB) and (Shift-[ssShift]=[]) then exit;
  end;
  inherited ControlKeyDown(Key, Shift);
end;

procedure TCustomMemo.WMChar(var Message: TLMChar);
begin
  // all normal characters are handled by the memo
  Message.Result := 1;
end;

{------------------------------------------------------------------------------
  Method: TCustomMemo.SetWordWrap
  Params: 
  Returns: 

 ------------------------------------------------------------------------------}
procedure TCustomMemo.SetWordWrap(const Value : boolean);
begin
  if Value <> FWordWrap then begin
    //DebugLn('TCustomMemo.SetWordWrap ',Name,' Old=',FWordWrap,' New=',Value);
    FWordWrap := Value;
    if HandleAllocated and (not (csLoading in ComponentState)) then
      TWSCustomMemoClass(WidgetSetClass).SetWordWrap(Self, Value);
  end;    
end;

// included by stdctrls.pp

