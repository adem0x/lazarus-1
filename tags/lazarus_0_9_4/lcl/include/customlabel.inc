{%MainUnit ../stdctrls.pp}

{******************************************************************************
                                TCustomLabel
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
  Method: TCustomLabel.Create
  Params:  AOwner: the owner of the class
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TCustomLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fCompStyle := csLabel;
  FLayout := tlTop;
  fAlignment := taLeftJustify;
  FShowAccelChar:= true;
  ControlStyle := ControlStyle + [csOpaque, csReplicatable];
  SetInitialBounds(0, 0, 65, 17);
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.GetLabelText
  Params: None
  Returns: Nothing

 ------------------------------------------------------------------------------}
function TCustomLabel.GetLabelText: String;
begin
  Result := Caption;  
end;

procedure TCustomLabel.RealSetText(const AValue: TCaption);
begin
  if Text=AValue then exit;
  inherited RealSetText(AValue);
  InvalidatePreferredSize;
  {$IFDEF EnablePreferredSize}
  DoAutoSize;
  {$ENDIF}
end;

{------------------------------------------------------------------------------
  procedure TCustomLabel.Notification(AComponent: TComponent;
    Operation: TOperation);
 ------------------------------------------------------------------------------}
procedure TCustomLabel.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FFocusControl) and (Operation = opRemove) then
    FFocusControl:= nil;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetAlignment
  Params: Value - new proterty value
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetAlignment(Value: TAlignment);
begin
  if fAlignment <> value then begin
    fAlignment:= value;
    if HandleAllocated then
      TWSCustomLabelClass(WidgetSetClass).SetAlignment(Self, Value);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetFocusControl
  Params: Val - new property value
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetFocusControl(Val: TWinControl);
begin
  if Val <> FFocusControl then begin
    FFocusControl:= Val;
    if Val <> nil then Val.FreeNotification(Self);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetLayout
  Params: None
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetLayout(Value: TTextLayout);
begin
  if FLayout <> Value then begin
    FLayout:= Value;
    if HandleAllocated then
      TWSCustomLabelClass(WidgetSetClass).SetLayout(Self, Value);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetShowAccelChar
  Params: Val - new property value
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetShowAccelChar(Val: boolean);
begin
  if Val <> FShowAccelChar then begin
    FShowAccelChar:= Val;
    if HandleAllocated then
      TWSWinControlClass(WidgetSetClass).SetText(Self,Caption);
  end;
end;

{$IFNDEF EnablePreferredSize}
procedure TCustomLabel.DoAutoSize;
var
  R: TRect;
  DC: hDC;
begin
  If AutoSizing or (not AutoSize) or (Caption='') then
    Exit;
  if (not HandleAllocated) or ([csLoading,csDestroying]*ComponentState<>[]) then
    exit;
  AutoSizing := True;
  DC := GetDC(Handle);
  Try
    R := Rect(0,0, Width, Height);
    DrawText(DC, PChar(Caption + 'W'), Length(Caption) + 1, R,
      DT_CalcRect or DT_NoPrefix or DT_Internal);
    Width := R.Right;
    Height := R.Bottom;
  Finally
    ReleaseDC(Handle, DC);
    AutoSizing := False;
  end;
end;
{$ENDIF}

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetWordWrap
  Params: None
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetWordWrap(Value: Boolean);
begin
  if fWordWrap <> value then begin
    fWordWrap:= value;
    if HandleAllocated then
      TWSCustomLabelClass(WidgetSetClass).SetWordWrap(Self, Value);
  end;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.WMActivate
  Params: Message: Activation message
  Returns: Nothing

  Received when the label has a registered activation shortcut for focuscontrol.
 ------------------------------------------------------------------------------}
procedure TCustomLabel.WMActivate(var Message: TLMActivate);
begin
  if (FFocusControl <> nil) and (FFocusControl.CanFocus) then
    FFocusControl.SetFocus;
end;

// included by stdctrls.pp

{ =============================================================================

  $Log$
  Revision 1.19  2004/11/03 14:18:35  mattias
  implemented preferred size for controls for theme depending AutoSizing

  Revision 1.18  2004/09/25 15:05:38  mattias
  implemented Rename Identifier

  Revision 1.17  2004/09/22 14:50:18  micha
  convert LM_SETPROPERTIES message for tcustomlabel to interface methods

  Revision 1.16  2004/09/10 09:43:12  micha
  convert LM_SETLABEL message to interface methods

  Revision 1.15  2004/04/20 23:39:01  marc
  * Fixed setting of TWincontrol.Text during load

  Revision 1.14  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.13  2004/03/08 22:36:01  mattias
  added TWinControl.ParentFormInitializeWnd

  Revision 1.12  2004/03/07 09:37:20  mattias
  added workaround for AutoSize in TCustomLabel

  Revision 1.11  2004/02/23 08:19:04  micha
  revert intf split

  Revision 1.9  2003/02/28 19:10:25  mattias
  added new ... dialog

  Revision 1.8  2002/10/16 17:06:33  lazarus
  MG: fixed handle allocating in TLabel

  Revision 1.7  2002/10/03 00:08:50  lazarus
  AJ: TCustomLabel Autosize, TCustomCheckbox '&' shortcuts started

  Revision 1.6  2002/09/03 20:02:01  lazarus
  Intermediate UI patch to show a bug.

  Revision 1.5  2002/09/03 11:32:49  lazarus

  Added shortcut keys to labels
  Support for alphabetically sorting the properties
  Standardize message and add shortcuts ala Kylix
  Published BorderStyle, unpublished BorderWidth
  ShowAccelChar and FocusControl
  ShowAccelChar and FocusControl for TLabel, escaped ampersands now work.

  Revision 1.4  2002/08/30 10:06:07  lazarus
  Fixed alignment of multiline TLabel.
  Simplified and prettified MessageBoxen.

  Revision 1.3  2002/05/10 06:05:52  lazarus
  MG: changed license to LGPL

  Revision 1.2  2002/04/18 08:09:03  lazarus
  MG: added include comments

  Revision 1.1  2000/07/13 10:28:25  michael
  + Initial import

  Revision 1.3  2000/05/30 22:28:41  lazarus
  MWE:
    Applied patches from Vincent Snijders:
    + Added GetWindowRect
    * Fixed horz label alignment
    + Added vert label alignment


}