{%MainUnit ../comctrls.pp}

{ TToolButton

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

{ TToolButtonActionLink }

procedure TToolButtonActionLink.AssignClient(AClient: TObject);
begin
  inherited AssignClient(AClient);
  FClient := AClient as TToolButton;
end;

function TToolButtonActionLink.IsCheckedLinked: Boolean;
begin
  Result := inherited IsCheckedLinked
    and (TToolButton(FClient).Down = (Action as TCustomAction).Checked);
end;

function TToolButtonActionLink.IsImageIndexLinked: Boolean;
begin
  Result := inherited IsImageIndexLinked
   and (TToolButton(FClient).ImageIndex = (Action as TCustomAction).ImageIndex);
end;

procedure TToolButtonActionLink.SetChecked(Value: Boolean);
begin
  if IsCheckedLinked then TToolButton(FClient).Down := Value;
end;

procedure TToolButtonActionLink.SetImageIndex(Value: Integer);
begin
  DebugLn('TToolButtonActionLink.SetImageIndex A ',ClassName,' Client=',
    TToolButton(FClient).Name,' IsImageIndexLinked=',
    BoolToStr(IsImageIndexLinked),' Old=',
    IntToStr(TToolButton(FClient).ImageIndex),' New=',IntToStr(Value));
  if IsImageIndexLinked then TToolButton(FClient).ImageIndex := Value;
end;

{ TToolButton }

constructor TToolButton.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  fCompStyle := csToolButton;
  FImageIndex := -1;
  FStyle := tbsButton;
  ControlStyle := [csCaptureMouse, csSetCaption, csDesignNoSmoothResize];
  SetInitialBounds(0,0,23,22);
end;

procedure TToolButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  //DebugLn('TToolButton.MouseDown ',Name,':',ClassName,' ',ord(Button),' ',X,',',Y);
  if (Button=mbLeft) and (not (tbfPressed in FToolButtonFlags)) then begin
    Include(FToolButtonFlags,tbfPressed);
    Invalidate;
  end;

  inherited MouseDown(Button,Shift,X,Y);

  if (Style=tbsDropDown) and (Button=mbLeft) and Enabled then begin
    if (FToolBar<>nil) and (X>ClientWidth-FToolBar.FDropDownWidth) then begin
    
    end else begin
      Down := true;
    end;
  end;
end;

procedure TToolButton.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  //DebugLn('TToolButton.MouseMove ',Name,':',ClassName,' ',X,',',Y);
  inherited MouseMove(Shift, X, Y);
end;

procedure TToolButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  //DebugLn('TToolButton.MouseUp ',Name,':',ClassName,' ',ord(Button),' ',X,',',Y);
  if (Button=mbLeft) and (tbfPressed in FToolButtonFlags) then begin
    Exclude(FToolButtonFlags,tbfPressed);
    Invalidate;
  end;

  inherited MouseUp(Button, Shift, X, Y);
  
  if (Button=mbLeft) then begin
    //DebugLn('TToolButton.MouseUp ',Name,':',ClassName,' ',Style=tbsCheck);
    if (Style=tbsButton) then Down:=false;
    if (Style=tbsDropDown) then begin
      if (FToolBar<>nil) and FMouseInControl
      and (X>ClientWidth-FToolBar.FDropDownWidth) then begin
        CheckMenuDropdown;
      end;
      Down:=false;
    end;

    if FMouseInControl then begin
      if (Style=tbsCheck) then Down:=not Down;
      Click;
    end;
  end;
  Invalidate;
end;

procedure TToolButton.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then begin
    if AComponent = DropdownMenu then
      DropdownMenu := nil
    else if AComponent = MenuItem then
      MenuItem := nil;
  end;
end;

procedure TToolButton.Paint;

  procedure DrawDropDownArrow(const DropDownButtonRect: TRect);
  var
    ArrowRect: TRect;
    Points: array[1..3] of TPoint;
  begin
    ArrowRect:=DropDownButtonRect;
    ArrowRect.Left:=DropDownButtonRect.Left+2;
    ArrowRect.Right:=Max(DropDownButtonRect.Right-3,ArrowRect.Left);
    ArrowRect.Top:=(DropDownButtonRect.Top+DropDownButtonRect.Bottom
                    +ArrowRect.Left-ArrowRect.Right) div 2;
    ArrowRect.Bottom:=ArrowRect.Top-ArrowRect.Left+ArrowRect.Right;
    Points[1]:=Point(ArrowRect.Left,ArrowRect.Top);
    Points[2]:=Point((ArrowRect.Left+ArrowRect.Right) div 2,ArrowRect.Bottom);
    Points[3]:=Point(ArrowRect.Right,ArrowRect.Top);
    Canvas.Brush.Color:=clBlack;
    Canvas.Pen.Color:=clBlack;
    Canvas.Polygon(@Points[1],3,false);
  end;

var
  PaintRect: TRect;
  ButtonRect: TRect;
  DropDownButtonRect: TRect;
  DividerRect: TRect;
  TextSize: TSize;
  TextPos: TPoint;
  IconSize: TPoint;
  IconPos: TPoint;
  ImgList: TCustomImageList;
  ImgIndex: integer;
  TS: TTextStyle;
begin
  //DebugLn('TToolButton.Paint A ',Name,' FToolBar=',DbgS(FToolBar),' ',ClientWidth,',',ClientHeight,' ',ord(Style));
  if (FToolBar<>nil) and (ClientWidth>0) and (ClientHeight>0) then begin
    PaintRect:=ClientRect; // the whole paint area

    // calculate button area(s)
    ButtonRect:=PaintRect;
    FLastButtonDrawFlags:=GetButtonDrawFlags;
    if (FLastButtonDrawFlags and DFCS_PUSHED) <> 0 then
      OffsetRect(ButtonRect, 1, 1);
    if Style=tbsDropDown then begin
      DropDownButtonRect:=ButtonRect;
      DropDownButtonRect.Left:=
                        Max(0,DropDownButtonRect.Right-FToolBar.FDropDownWidth);
      ButtonRect.Right:=DropDownButtonRect.Left;
    end;

    // calculate text size
    TextSize.cx:=0;
    TextSize.cy:=0;
    if (Style in [tbsButton,tbsDropDown,tbsCheck])
    and (FToolBar.ShowCaptions) then begin
      if (Caption<>'') then begin
        TextSize:=Canvas.TextExtent(Caption);
      end;
    end;

    // calculate icon size
    IconSize:=Point(0,0);
    GetCurrentIcon(ImgList,ImgIndex);
    if (ImgList<>nil) then begin
      IconSize:=Point(ImgList.Width,ImgList.Height);
      if IconSize.y<=0 then IconSize.X:=0;
    end;

    // calculate text and icon position
    TextPos:=Point(0,0);
    IconPos:=Point(0,0);
    if TextSize.cx>0 then begin
      if IconSize.X>0 then begin
        if FToolBar.List then begin
          // icon left of text
          IconPos.X:=(ButtonRect.Left+ButtonRect.Right-IconSize.x-TextSize.cx-2) div 2;
          IconPos.Y:=(ButtonRect.Top+ButtonRect.Bottom-IconSize.y) div 2;
          TextPos.X:=IconPos.X+IconSize.X+2;
          TextPos.Y:=(ButtonRect.Top+ButtonRect.Bottom-TextSize.cy) div 2;
        end else begin
          // icon above text
          IconPos.X:=(ButtonRect.Left+ButtonRect.Right-IconSize.x) div 2;
          IconPos.Y:=(ButtonRect.Top+ButtonRect.Bottom-IconSize.y-TextSize.cy-2) div 2;
          TextPos.X:=(ButtonRect.Left+ButtonRect.Right-TextSize.cx) div 2;
          TextPos.Y:=IconPos.Y+IconSize.Y+2;
        end;
      end else begin
        // only text
        TextPos.X:=(ButtonRect.Left+ButtonRect.Right-TextSize.cx) div 2;
        TextPos.Y:=(ButtonRect.Top+ButtonRect.Bottom-TextSize.cy) div 2;
      end;
    end else if IconSize.x>0 then begin
      // only icon
      IconPos.X:=(ButtonRect.Left+ButtonRect.Right-IconSize.x) div 2;
      IconPos.Y:=(ButtonRect.Top+ButtonRect.Bottom-IconSize.y) div 2;
    end;

    // draw button
    if (Style in [tbsButton,tbsDropDown,tbsCheck]) and (FLastButtonDrawFlags and DFCS_FLAT = 0) then begin
      DrawFrameControl(Canvas.GetUpdatedHandle([csBrushValid,csPenValid]),
        PaintRect{ButtonRect}, DFC_BUTTON, FLastButtonDrawFlags);
    end;

    // draw dropdown button
    if Style in [tbsDropDown] then begin
      //DrawFrameControl(Canvas.GetUpdatedHandle([csBrushValid,csPenValid]),
      //  DropDownButtonRect, DFC_BUTTON, FLastButtonDrawFlags);
      DrawDropDownArrow(DropDownButtonRect);
    end;

    // draw icon
    if (ImgList<>nil) then begin
      ImgList.Draw(Canvas,IconPos.X,IconPos.Y,ImgIndex,true);
    end;

    // draw text
    if (TextSize.cx>0) then begin
      TS := Canvas.TextStyle;
      TS.Alignment:= taLeftJustify;
      TS.Layout:= tlTop;
      TS.Opaque:= false;
      TS.Clipping:= false;
      TS.SystemFont:=Canvas.Font.IsDefault;
      TS.ShowPrefix:= true;
      Canvas.TextRect(PaintRect, TextPos.X, TextPos.Y, Caption, TS);
    end;

    // draw separator (at runtime: just space, at designtime: a rectangle)
    if (Style in [tbsSeparator,tbsDivider])
    and (csDesigning in ComponentState) then begin
      Canvas.Brush.Color:=clBackground;
      Canvas.Pen.Color:=clBlack;
      dec(PaintRect.Right);
      dec(PaintRect.Bottom);
      Canvas.FrameRect(PaintRect);
    end;
    
    // draw divider
    if (Style in [tbsDivider]) then begin
      DividerRect.Left:=((ButtonRect.Left+ButtonRect.Right) div 2)-1;
      DividerRect.Right:=DividerRect.Left+2;
      DividerRect.Top:=2;
      DividerRect.Bottom:=Max(DividerRect.Top,PaintRect.Bottom-2);
      DrawEdge(Canvas.Handle,DividerRect,EDGE_ETCHED,BF_LEFT);
    end;
  end;
  
  inherited Paint;
end;

procedure TToolButton.Loaded;
begin
  inherited Loaded;
  CopyPropertiesFromMenuItem(FMenuItem);
end;

procedure TToolButton.SetAutoSize(const Value: Boolean);
begin
  if Value = AutoSize then exit;
  Inherited SetAutoSize(Value);
  RequestAlign;
end;

procedure TToolButton.SetToolBar(NewToolBar: TToolBar);
begin
  if FToolBar = NewToolBar then exit;
  Parent := NewToolBar;
end;

procedure TToolButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
var
  NewAction: TCustomAction;
begin
  inherited ActionChange(Sender, CheckDefaults);
  if Sender is TCustomAction then begin
    NewAction:=TCustomAction(Sender);
    if (not CheckDefaults) or (not Down) then
      Down := NewAction.Checked;
    if (not CheckDefaults) or (ImageIndex<0) then
      ImageIndex := NewAction.ImageIndex;
  end;
end;

function TToolButton.GetActionLinkClass: TControlActionLinkClass;
begin
  Result:=TToolButtonActionLink;
end;

procedure TToolButton.CopyPropertiesFromMenuItem(const Value: TMenuItem);
begin
  if Value=nil then exit;
  BeginUpdate;
  Action := Value.Action;
  Caption := Value.Caption;
  Down := Value.Checked;
  Enabled := Value.Enabled;
  Hint := Value.Hint;
  ImageIndex := Value.ImageIndex;
  Visible := Value.Visible;
  EndUpdate;
end;

procedure TToolButton.CMHitTest(var Message: TCMHitTest);
begin
  if (not (Style in [tbsDivider, tbsSeparator])) or (DragKind = dkDock) then
    Message.Result := 1
  else
    Message.Result := 0;
end;

procedure TToolButton.MouseEnter;
begin
  //DebugLn('TToolButton.MouseEnter ',Name);
  inherited MouseEnter;
  SetMouseInControl(true);
end;

procedure TToolButton.MouseLeave;
begin
  //DebugLn('TToolButton.MouseLeave ',Name);
  inherited MouseLeave;
  SetMouseInControl(false);
  if (not MouseCapture) and (tbfPressed in FToolButtonFlags) then begin
    Invalidate;
    Exclude(FToolButtonFlags,tbfPressed);
  end;
end;

procedure TToolButton.SetDown(Value: Boolean);
var
  StartIndex, EndIndex: integer;
  i: Integer;
  CurButton: TToolButton;
begin
  if Value = FDown then exit;
  if (csLoading in ComponentState) then begin
    FDown:=Value;
    exit;
  end;
  
  //DebugLn('TToolButton.SetDown ',Style=tbsCheck,',',FDown,',',GroupAllUpAllowed);
  if (Style=tbsCheck) and FDown and (not GroupAllUpAllowed) then
    exit;

  FDown := Value;
  
  if (Style=tbsCheck) and FDown and Grouped then begin
    DebugLn('TToolButton.SetDown B ');
    // uncheck all other in the group
    GetGroupBounds(StartIndex,EndIndex);
    if StartIndex>=0 then begin
      for i:=StartIndex to EndIndex do begin
        CurButton:=FToolBar.Buttons[i];
        if (CurButton<>Self) and (CurButton.FDown) then begin
          CurButton.FDown:=false;
          CurButton.Invalidate;
        end;
      end;
    end;
  end;

  Invalidate;
  if FToolBar <> nil then
    FToolBar.ToolButtonDown(Self,FDown);
end;

procedure TToolButton.SetDropdownMenu(Value: TPopupMenu);
begin
  if Value = FDropdownMenu then exit;
  FDropdownMenu := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;

procedure TToolButton.SetGrouped(Value: Boolean);
var
  StartIndex, EndIndex: integer;
  CheckedIndex: Integer;
  i: Integer;
  CurButton: TToolButton;
begin
  if FGrouped = Value then exit;
  FGrouped := Value;
  if csLoading in ComponentState then exit;
  
  // make sure, that only one button in a group is checked
  while FGrouped and (Style=tbsCheck) and (FToolBar<>nil) do begin
    GetGroupBounds(StartIndex,EndIndex);
    if StartIndex>=0 then begin
      CheckedIndex:=-1;
      i:=StartIndex;
      while i<=EndIndex do begin
        CurButton:=FToolBar.Buttons[i];
        if CurButton.Down then begin
          if CheckedIndex<0 then
            CheckedIndex:=i
          else begin
            CurButton.Down:=false;
            // the last operation can change everything -> restart
            break;
          end;
        end;
        inc(i);
      end;
      if i>EndIndex then break;
    end;
  end;
end;

procedure TToolButton.SetImageIndex(Value: Integer);
begin
  if FImageIndex = Value then exit;
  //debugln('TToolButton.SetImageIndex ',Name,':',ClassName,' Old=',FImageIndex,' New=',Value);
  FImageIndex := Value;
  if FToolBar <> nil then begin
    RefreshControl;
    Invalidate;
  end;
end;

procedure TToolButton.SetMarked(Value: Boolean);
begin
  if FMarked = Value then exit;
  FMarked := Value;
  if FToolBar <> nil then
    Invalidate;
end;

procedure TToolButton.SetIndeterminate(Value: Boolean);
begin
  if FIndeterminate = Value then exit;
  if Value then SetDown(False);
  FIndeterminate := Value;
  if FToolBar <> nil then
    Invalidate;
end;

procedure TToolButton.SetMenuItem(Value: TMenuItem);
begin
  if Value=FMenuItem then exit;
  // copy values from menuitem
  // is menuitem is still loading, skip this
  if (Value <> nil) and (not (csLoading in Value.ComponentState)) then begin
    CopyPropertiesFromMenuItem(Value);
  end;
  FMenuItem := Value;
end;

procedure TToolButton.SetStyle(Value: TToolButtonStyle);
begin
  if FStyle = Value then exit;
  FStyle := Value;
  if Visible then
    UpdateVisibleToolbar;
end;

procedure TToolButton.SetWrap(Value: Boolean);
begin
  if FWrap = Value then exit;
  FWrap := Value;
  if FToolBar <> nil then
    RefreshControl;
end;

procedure TToolButton.SetMouseInControl(NewMouseInControl: Boolean);
begin
  //DebugLn('TToolButton.SetMouseInControl A ',Name,' Old=',FMouseInControl,' New=',NewMouseInControl);
  if FMouseInControl=NewMouseInControl then exit;
  FMouseInControl:=NewMouseInControl;
  if (Style in [tbsDropDown,tbsButton]) and (not FMouseInControl) then
    Down:=false;
  //DebugLn('TToolButton.SetMouseInControl B ',Name,' Now=',FMouseInControl,' Down=',Down);
  Invalidate;
end;

procedure TToolButton.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TToolButton.EndUpdate;
begin
  Dec(FUpdateCount);
end;

{------------------------------------------------------------------------------
  procedure TToolButton.GetGroupBounds(var StartIndex, EndIndex: integer);
  
  Return the index of the first and the last ToolButton in the group.
  If no ToolBar then negative values are returned.
  If not in a group then StartIndex=EndIndex.
------------------------------------------------------------------------------}
procedure TToolButton.GetGroupBounds(var StartIndex, EndIndex: integer);
var
  CurButton: TToolButton;
begin
  StartIndex:=Index;
  EndIndex:=StartIndex;
  if (Style<>tbsCheck) or (not Grouped) then exit;
  while (StartIndex>0) do begin
    CurButton:=FToolBar.Buttons[StartIndex-1];
    if (CurButton<>nil) and (CurButton.Style=tbsCheck) and (CurButton.Grouped)
    then
      dec(StartIndex)
    else
      break;
  end;
  while (EndIndex<FToolBar.FButtons.Count-1) do begin
    CurButton:=FToolBar.Buttons[EndIndex+1];
    if (CurButton<>nil) and (CurButton.Style=tbsCheck) and (CurButton.Grouped)
    then
      inc(EndIndex)
    else
      break;
  end;
end;

function TToolButton.GetIndex: Integer;
begin
  if FToolBar <> nil then
    Result := FToolBar.FButtons.IndexOf(Self)
  else
    Result := -1;
end;

function TToolButton.IsWidthStored: Boolean;
begin
  Result := Style in [tbsSeparator, tbsDivider];
end;

procedure TToolButton.RefreshControl;
begin
  UpdateControl;
end;

procedure TToolButton.UpdateControl;
begin
  UpdateVisibleToolbar;
end;

function TToolButton.CheckMenuDropdown: Boolean;
begin
  Result := (not (csDesigning in ComponentState))
            and (((DropdownMenu<>nil) and (DropdownMenu.AutoPopup))
                 or (MenuItem<>nil))
            and (FToolBar <> nil);
  if Result then
    Result:=FToolBar.CheckMenuDropdown(Self);
end;

procedure TToolButton.GetCurrentIcon(var ImageList: TCustomImageList;
  var TheIndex: integer);
begin
  ImageList:=nil;
  TheIndex:=-1;
  if (ImageIndex<0) or (FToolBar=nil) then exit;
  
  if Style in [tbsButton,tbsDropDown,tbsCheck] then begin
    TheIndex:=ImageIndex;
    if Enabled and FMouseInControl then
      // if mouse over button then use HotImages
      ImageList:=FToolBar.HotImages
    else if not Enabled then
      // if button disabled then use HotImages
      ImageList:=FToolBar.DisabledImages;
    if (ImageList=nil) or (ImageList.Count<=ImageIndex) then begin
      // if no special icon available, then try the default Images
      ImageList:=FToolBar.Images;
      if (ImageList=nil) or (ImageList.Count<=ImageIndex) then begin
        // no icon available
        ImageList:=nil;
        TheIndex:=-1;
      end;
    end;
  end;
end;

function TToolButton.IsCheckedStored: Boolean;
begin
  Result := (ActionLink = nil)
            or (not TToolButtonActionLink(ActionLink).IsCheckedLinked);
end;

function TToolButton.IsImageIndexStored: Boolean;
begin
  Result := (ActionLink = nil)
            or (not TToolButtonActionLink(ActionLink).IsImageIndexLinked);
end;

procedure TToolButton.AssignTo(Dest: TPersistent);
begin
  inherited AssignTo(Dest);
  if Dest is TCustomAction then begin
    TCustomAction(Dest).Checked := Down;
    TCustomAction(Dest).ImageIndex := ImageIndex;
  end;
end;

function TToolButton.GetButtonDrawFlags: integer;
begin
  Result:=DFCS_BUTTONPUSH;
  if FDown
  or ((tbfPressed in FToolButtonFlags) and FMouseInControl) then
    inc(Result,DFCS_PUSHED);
  if not Enabled then inc(Result,DFCS_INACTIVE);

  if (FToolBar<>nil) and FToolBar.Flat
  and (not (csDesigning in ComponentState)) and (not FMouseInControl)
  and (not FDown) then
    inc(Result,DFCS_FLAT);
end;

procedure TToolButton.SetParent(AParent: TWinControl);
var
  i: Integer;
  NewWidth: Integer;
  NewHeight: Integer;
begin
  CheckNewParent(AParent);
  if AParent=Parent then exit;
  
  // remove from old button list
  if FToolBar<>nil then
    FToolBar.RemoveButton(Self);
  FToolBar:=nil;
  if AParent is TToolBar then begin
    if Style in [tbsButton,tbsDropDown,tbsCheck] then
      NewWidth:=TToolBar(AParent).ButtonWidth
    else
      NewWidth:=Width;
    NewHeight:=TToolBar(AParent).ButtonHeight;
    SetBoundsKeepBase(Left,Top,NewWidth,NewHeight,true);
  end;
  
  // inherited
  inherited SetParent(AParent);
  
  // add to new button list
  if Parent is TToolBar then begin
    FToolBar:=TToolBar(Parent);
    i:=Index;
    if i<0 then
      FToolBar.AddButton(Self);
    UpdateVisibleToolbar;
  end;
  //DebugLn('TToolButton.SetParent A ',Name,' NewIndex=',Index);
end;

procedure TToolButton.UpdateVisibleToolbar;
begin
  //DebugLn('TToolButton.UpdateVisibleToolbar ',Parent is TToolBar);
  if Parent is TToolBar then
    TToolBar(Parent).UpdateVisibleBar;
end;

function TToolButton.GroupAllUpAllowed: boolean;
var
  StartIndex, EndIndex: integer;
  i: Integer;
  CurButton: TToolButton;
begin
  Result:=true;
  if (Style=tbsCheck) and Grouped then begin
    GetGroupBounds(StartIndex,EndIndex);
    if (StartIndex>=0) then begin
      // allow all up, if one button has AllowAllUp
      Result:=false;
      for i:=StartIndex to EndIndex do begin
        CurButton:=FToolBar.Buttons[i];
        if CurButton.AllowAllUp then begin
          Result:=true;
          break;
        end;
      end;
    end;
  end;
end;

procedure TToolButton.DoSetBounds(ALeft, ATop, AWidth, AHeight: integer);
var
  NewButtonWidth: Integer;
  NewButtonHeight: Integer;
  OldLeft: Integer;
  OldTop: Integer;
  OldWidth: Integer;
  OldHeight: Integer;
begin
  if ([csDesigning,csLoading,csDestroying]*ComponentState=[csDesigning])
  and (FToolBar<>nil)
  and (not (tbfPlacingControls in FToolBar.FToolBarFlags))
  and (FToolBar.FUpdateCount=0)
  and (AWidth>0) and (AHeight>0) then begin
    if Style in [tbsButton,tbsDropDown,tbsCheck] then
      NewButtonWidth:=AWidth
    else
      NewButtonWidth:=FToolBar.ButtonWidth;
    NewButtonHeight:=AHeight;
    //DebugLn('TToolButton.DoSetBounds NewButtonSize=',NewButtonWidth,',',NewButtonHeight);
    OldLeft:=Left;
    OldTop:=Top;
    OldWidth:=Width;
    OldHeight:=Height;
    FToolBar.SetButtonSize(NewButtonWidth,NewButtonHeight);
    if (OldLeft<>Left) or (OldTop<>Top)
    or (OldWidth<>Width) or (OldHeight<>Height) then
      // button was auto aligned -> ignore setbounds
      exit;
  end;
  
  inherited DoSetBounds(ALeft, ATop, AWidth, AHeight);
end;

function TToolButton.DialogChar(var Message: TLMKey): boolean;
begin
  if IsAccel(Message.CharCode, Caption) and CanFocus then
  begin
    Click;
    Result := true;
  end else
    Result := inherited;
end;


// included by comctrls.pp

