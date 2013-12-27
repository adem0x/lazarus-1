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

  TODO:

    - Enable Tabbing/Focusing to focus FocusControl
    - Enable Escaped '&' Shortcut to focus FocusControl
    - Compare/Match AutoSize to Delphi/Kylix's
    - ?? Check For Full Delphi/Kylix Compatibility

}

procedure TCustomLabel.CalcSize(var AWidth, AHeight: integer);
  { assumes: (Parent <> nil) and Parent.HandleAllocated }
var
  R : TRect;
  DC : hDC;
  Flags: Cardinal;
  OldFont: HGDIOBJ;
begin
  DC := GetDC(Parent.Handle);
  try
    R := Rect(0,0, Width, Height);
    OldFont:=SelectObject(DC, Font.Handle);
    Flags:=DT_CalcRect or DT_NoPrefix;
    if WordWrap then inc(Flags,DT_WordBreak);
    DrawText(DC, PChar(Caption), Length(Caption), R, Flags);
    SelectObject(DC, OldFont);
    AWidth := R.Right - R.Left;
    AHeight := R.Bottom - R.Top;
  finally
    ReleaseDC(Parent.Handle, DC);
  end;
end;

Procedure TCustomLabel.DoAutoSize;
var
  NewWidth, NewHeight: integer;
begin
  //debugln('TCustomLabel.DoAutoSize ',DbgSName(Self),' AutoSizing=',dbgs(AutoSizing),' AutoSize=',dbgs(AutoSize),' Parent=',DbgSName(Parent),' csLoading=',dbgs(csLoading in ComponentState),' Parnet.HandleAllocated=',dbgs((Parent<>nil) and (Parent.HandleAllocated)));
  if OptimalFill and (not AutoSize) then begin
    AdjustFontForOptimalFill;
    exit;
  end;
  
  if AutoSizing or not AutoSize then
    Exit;
  if ([csLoading,csDestroying]*ComponentState<>[])
  or (Parent = nil) or Parent.AutoSizeDelayed then
    exit;
  AutoSizing := True;
  try
    CalcSize(NewWidth, NewHeight);
    //debugln('TCustomLabel.DoAutoSize ',dbgs(Left),' ',dbgs(Top),' ',dbgs(NewWidth),' ',dbgs(NewHeight));
    SetBounds(Left, Top, NewWidth, NewHeight);
  finally
    AutoSizing := False;
  end;
end;

Procedure TCustomLabel.SetAlignment(Value : TAlignment);
begin
  //debugln('TCustomLabel.SetAlignment Old=',dbgs(ord(Alignment)),' New=',dbgs(ord(Value)),' csLoading=',dbgs(csLoading in ComponentState));
  if FAlignment <> Value then begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TCustomLabel.Notification(AComponent : TComponent; Operation : TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FFocusControl) and (Operation = opRemove) then
    FFocusControl:= nil;
end;

procedure TCustomLabel.SetFocusControl(Value : TWinControl);
begin
  if Value <> FFocusControl then begin
    FFocusControl:= Value;
    if Value <> nil then Value.FreeNotification(Self);
  end;
end;

procedure TCustomLabel.WMActivate(var Message: TLMActivate);
begin
  if (FFocusControl <> nil) and (FFocusControl.CanFocus) then
    FFocusControl.SetFocus;
end;

Function TCustomLabel.GetAlignment : TAlignment;
begin
  Result := FAlignment;
end;

Procedure TCustomLabel.SetShowAccelChar(Value : Boolean);
begin
  If FShowAccelChar <> Value then begin
    FShowAccelChar := Value;
    Invalidate;
  end;
end;

procedure TCustomLabel.CMTextChanged(var Message: TLMSetText);
begin
  Invalidate;
  AdjustSize;
end;

procedure TCustomLabel.Resize;
begin
  inherited Resize;
  if OptimalFill and (not AutoSize) then
    AdjustFontForOptimalFill;
end;

Function TCustomLabel.GetShowAccelChar : Boolean;
begin
  Result := FShowAccelChar;
end;

function TCustomLabel.CanTab: boolean;
begin
  Result:=false;
end;

constructor TCustomLabel.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Font.OnChange := @FontChange;
  ControlStyle := [csSetCaption, csOpaque, csClickEvents, csDoubleClicks,
                   csReplicatable];
  Width := 65;
  Height := 17;
  FShowAccelChar := True;
  Color := clNone;
  AutoSize:=true;
end;

function TCustomLabel.GetTransparent: boolean;
begin
  Result := Color = clNone;
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
    Invalidate;
  end;
end;

procedure TCustomLabel.SetTransparent(NewTransparent: boolean);
begin
  if NewTransparent then
    Color := clNone;
end;

{------------------------------------------------------------------------------
  Method: TCustomLabel.SetWordWrap
  Params: None
  Returns: Nothing

 ------------------------------------------------------------------------------}
procedure TCustomLabel.SetWordWrap(Value: Boolean);
begin
  if fWordWrap <> value then begin
    fWordWrap:= value;
    Invalidate;
  end;
end;

function TCustomLabel.DialogChar(var Message: TLMKey): boolean;
begin
  Result := false;
  if not FShowAccelChar then exit;
  if FFocusControl = nil then exit;

  if IsAccel(Message.CharCode, Caption) and FFocusControl.CanFocus then
  begin
    Result := true;
    FFocusControl.SetFocus;
  end else
    Result := inherited;
end;

procedure TCustomLabel.Loaded;
begin
  inherited Loaded;
  AdjustSize;
end;

{-------------------------------------------------------------------------------
  function TCustomLabel.CalcFittingFontHeight(const TheText: string;
    MaxWidth, MaxHeight: Integer;
    var FontSize, NeededWidth, NeededHeight: integer): Boolean;

  Calculates the maximum font size for TheText to fit into MaxWidth and
  MaxHeight.
-------------------------------------------------------------------------------}
function TCustomLabel.CalcFittingFontHeight(const TheText: string;
  MaxWidth, MaxHeight: Integer;
  var FontHeight, NeededWidth, NeededHeight: integer): Boolean;
var
  R : TRect;
  DC : hDC;
  Flags: Cardinal;
  OldFont: HGDIOBJ;
  MinFontHeight: Integer;
  MaxFontHeight: Integer;
  AFont: TFont;
  CurFontHeight: LongInt;
begin
  Result:=false;
  if (Parent=nil) or (Parent.AutoSizeDelayed) or (TheText='')
  or (MaxWidth<1) or (MaxHeight<1) then exit;
  AFont:=TFont.Create;
  AFont.Assign(Font);
  CurFontHeight:=AFont.Height;
  MinFontHeight:=5;
  MaxFontHeight:=MaxHeight*2;
  if (CurFontHeight<MinFontHeight) or (CurFontHeight>MaxFontHeight) then
    CurFontHeight:=(MinFontHeight+MaxFontHeight) div 2;
  Flags:=DT_CalcRect or DT_NoPrefix;
  if WordWrap then inc(Flags,DT_WordBreak);
  
  // give a clipping rectangle with space, so that the bounds returned by
  // DrawText can be bigger and we know, the tried font is too big.
  R := Rect(0,0, MaxWidth, MaxHeight*2);
  
  DC := GetDC(Parent.Handle);
  try
    while (MinFontHeight<=MaxFontHeight) and (CurFontHeight>=MinFontHeight)
    and (CurFontHeight<=MaxFontHeight) do begin
      AFont.Height:=CurFontHeight; // NOTE: some TFont do not allow any integer
      //debugln('TCustomLabel.CalcFittingFontHeight A ',dbgs(MinFontHeight),'<=',dbgs(AFont.Height),'<=',dbgs(MaxFontHeight));
      OldFont:=SelectObject(DC, AFont.Handle);
      DrawText(DC, PChar(TheText), Length(TheText), R, Flags);
      SelectObject(DC, OldFont);
      NeededWidth := R.Right - R.Left;
      NeededHeight := R.Bottom - R.Top;
      //debugln('TCustomLabel.CalcFittingFontHeight B NeededWidth=',dbgs(NeededWidth),' NeededHeight=',dbgs(NeededHeight),' MaxWidth=',dbgs(MaxWidth),' MaxHeight=',dbgs(MaxHeight));
      if (NeededWidth>0) and (NeededHeight>0)
      and (NeededWidth<=MaxWidth) and (NeededHeight<=MaxHeight) then begin
        // TheText fits into the bounds
        if (not Result) or (FontHeight<AFont.Height) then
          FontHeight:=AFont.Height;
        Result:=true;
        MinFontHeight:=CurFontHeight;
        // -> try bigger (binary search)
        CurFontHeight:=(MaxFontHeight+CurFontHeight+1) div 2; // +1 to round up
        if CurFontHeight=MinFontHeight then break;
      end else begin
        // TheText does not fit into the bounds
        MaxFontHeight:=CurFontHeight-1;
        // -> try smaller (binary search)
        CurFontHeight:=(MinFontHeight+CurFontHeight) div 2;
      end;
    end
  finally
    ReleaseDC(Parent.Handle, DC);
    AFont.Free;
  end;
end;

{-------------------------------------------------------------------------------
  function TCustomLabel.AdjustFontForOptimalFill: Boolean;
  
  Maximizes Font.Height
  Return true if Font.Height changed.
-------------------------------------------------------------------------------}
function TCustomLabel.AdjustFontForOptimalFill: Boolean;
var
  NeededWidth: Integer;
  NeededHeight: Integer;
  NewFontHeight: Integer;
  OldFontHeight: LongInt;
begin
  Result:=false;
  if not CalcFittingFontHeight(Caption,Width,Height,NeededWidth,NeededHeight,
                               NewFontHeight) then exit;
  if Font.Height=NewFontHeight then exit;
  //debugln('TCustomLabel.AdjustFontForOptimalFill OldFontHeight=',dbgs(Font.Height),' NewFontHeight=',dbgs(NewFontHeight));
  OldFontHeight:=Font.Height;
  Font.Height:=NewFontHeight;
  Result:=OldFontHeight<>Font.Height;
end;

Procedure TCustomLabel.Paint;
var
  TR : TTextStyle;
  R : TRect;
  TextLeft, TextTop: integer;
  lTextWidth, lTextHeight: integer;
begin
  R := Rect(0,0,Width,Height);
  With Canvas do begin
    Color := Self.Color;
    Font := Self.Font;
    if Color<>clNone then
      FillRect(R);
{
    If BorderStyle <> sbsNone then begin
      InflateRect(R,-2,-2);
      Pen.Style := psSolid;
      If BorderStyle = sbsSunken then
        Pen.Color := clBtnShadow
      else
        Pen.Color := clBtnHighlight;
      MoveTo(0, 0);
      LineTo(Width - 1,0);
      MoveTo(0, 0);
      LineTo(0,Height - 1);
      If BorderStyle = sbsSunken then
        Pen.Color := clBtnHighlight
      else
        Pen.Color := clBtnShadow;
      MoveTo(0,Height - 1);
      LineTo(Width - 1,Height - 1);
      MoveTo(Width - 1, 0);
      LineTo(Width - 1,Height);
    end;
}
    //Brush.Color:=clRed;
    //FillRect(R);
    FillChar(TR,SizeOf(TR),0);
    With TR do begin
      Alignment := Self.Alignment;
      WordBreak := True;
      Clipping := True;
      ShowPrefix := ShowAccelChar;
      SystemFont:=false;
    end;
    CalcSize(lTextWidth, lTextHeight);
    TextLeft := R.Left;
    case Layout of
      tlTop:    TextTop := R.Top;
      tlCenter: TextTop := (R.Bottom - R.Top - lTextHeight) div 2;
      tlBottom: TextTop := R.Bottom - R.Top - lTextHeight;
    end;
    //debugln('TCustomLabel.Paint ',dbgs(Alignment=tacenter),' ',dbgs(Layout=tlCenter),' ',dbgs(TextLeft),' TextTop=',dbgs(TextTop),' ',dbgs(R));
    TextRect(R, TextLeft, TextTop, Caption, TR);
  end;
end;

Procedure TCustomLabel.FontChange(Sender : TObject);
begin
  If Caption <> '' then
    Invalidate;
end;

procedure TCustomLabel.SetOptimalFill(const AValue: Boolean);
begin
  if FOptimalFill=AValue then exit;
  FOptimalFill:=AValue;
  if OptimalFill and AutoSize then
    AutoSize:=false;
  Invalidate;
end;

 // included by stdctrls.pp


{
  $Log$
  Revision 1.32  2005/06/18 16:10:09  mattias
  implemented TCustomLabel.OptimalFill: boolean

  Revision 1.31  2005/04/28 10:05:29  micha
  fix accelerator handling firing too quickly, better WM_CHAR has-been-handled heuristic
  check for focusability of label.focuscontrol

  Revision 1.30  2005/04/27 12:37:28  micha
  implement/fix button/label shortcut accelchar handling

  Revision 1.29  2005/04/19 15:06:30  mattias
  fixed small aesthetical editoroptions bugs

  Revision 1.28  2005/02/03 15:10:23  micha
  implement shortcut handling, tcustomlabel accelerator focuscontrol functionality

  Revision 1.27  2005/01/26 17:51:34  mattias
  calling autosizing on changing TLabel.Caption

  Revision 1.26  2005/01/24 12:23:11  mattias
  fixed TColorButton.Paint

  Revision 1.25  2005/01/24 11:49:42  mattias
  added checks for filenames with spaces

  Revision 1.24  2005/01/21 14:18:11  micha
  implement TCustomLabel.Layout

  Revision 1.23  2005/01/21 13:38:10  micha
  implement TCustomLabel.Transparent

  Revision 1.22  2005/01/17 16:42:35  mattias
  improved TLabel autosizing

  Revision 1.21  2005/01/08 22:13:21  vincents
  TLabel.ShowAccelChar default value is True

  Revision 1.20  2005/01/07 20:51:11  micha
  swap TCustomStaticText and TCustomLabel

  Revision 1.9  2004/12/31 11:27:35  mattias
  skip FillRect in TStaticText.Paint when Color=clNone

  Revision 1.8  2004/09/24 13:45:32  mattias
  fixed TCanvas.TextRect Delphi compatible Rect and added TBarChart from Michael VC

  Revision 1.7  2004/08/04 09:57:17  mattias
  TStaticText.CanTab=false

  Revision 1.6  2004/05/21 09:03:55  micha
  implement new borderstyle
  - centralize to twincontrol (protected)
  - public expose at tcustomcontrol to let interface access it

  Revision 1.5  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.4  2004/03/07 09:37:20  mattias
  added workaround for AutoSize in TCustomLabel

  Revision 1.3  2004/01/03 23:14:59  mattias
  default font can now change height and fixed gtk crash

  Revision 1.2  2002/10/23 20:47:26  lazarus
  AJ: Started Form Scrolling
      Started StaticText FocusControl
      Fixed Misc Dialog Problems
      Added TApplication.Title

  Revision 1.1  2002/10/21 15:51:27  lazarus
  AJ: moved TCustomStaticText code to include/customstatictext.inc


}