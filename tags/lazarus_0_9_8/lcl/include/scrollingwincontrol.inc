{%MainUnit ../forms.pp}

{
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

procedure TScrollingWinControl.SetAutoScroll(Value: Boolean);
begin
  if FAutoScroll <> Value then
  begin
    FAutoScroll := Value;
    if Value then begin
      HorzScrollBar.AutoCalcRange;
      VertScrollBar.AutoCalcRange;
    end;
    UpdateScrollBars;
  end;
end;

procedure TScrollingWinControl.CreateWnd;
begin
  inherited CreateWnd;
  UpdateScrollBars;
end;

procedure TScrollingWinControl.AlignControls(AControl: TControl; var ARect: TRect);
begin
  HorzScrollBar.AutoCalcRange;
  VertScrollBar.AutoCalcRange;
  If not AutoScroll then
    UpdateScrollBars;
  inherited AlignControls(AControl, ARect);
end;

Procedure TScrollingWinControl.WMEraseBkgnd(var Message: TLMEraseBkgnd);
begin
  inherited WMEraseBkgnd(Message);
end;

procedure TScrollingWinControl.WMPaint(var Message: TLMPaint);
begin
  Include(FControlState, csCustomPaint);
  try
    inherited WMPaint(Message);
  finally
    Exclude(FControlState, csCustomPaint);
  end;
end;

Procedure TScrollingWinControl.Paint;
begin
  if Assigned (FOnPaint) then
    FOnPaint(Self);
end;

Procedure TScrollingWinControl.PaintWindow(DC : Hdc);
begin
  FCanvas.Lock;
  try
    FCanvas.Handle := DC;
    try
      Paint;
    finally
      FCanvas.Handle := 0;
    end;
  finally
    FCanvas.Unlock;
  end;
end;

procedure TScrollingWinControl.DoOnResize;
begin
  inherited DoOnResize;
  if AutoScroll or HorzScrollBar.Visible or VertScrollBar.Visible
  then
    UpdateScrollBars;
end;

procedure TScrollingWinControl.SetHorzScrollBar(Value: TControlScrollBar);
begin
  FHorzScrollbar.Assign(Value);
end;

procedure TScrollingWinControl.SetVertScrollBar(Value: TControlScrollBar);
begin
  FVertScrollbar.Assign(Value);
end;

Procedure TScrollingWinControl.UpdateScrollbars;
begin
  If FIsUpdating then exit;
  FIsUpdating := True;
  try
    FVertScrollbar.UpdateScrollbar;
    FHorzScrollbar.UpdateScrollbar;
  finally
    FIsUpdating := False;
  end;
end;

function TScrollingWinControl.HasVisibleScrollbars: boolean;
begin
  Result:=VertScrollBar.Visible and HorzScrollBar.Visible;
end;

procedure TScrollingWinControl.DestroyWnd;
begin
  inherited DestroyWnd;
  if Canvas<>nil then
    Canvas.Handle:=0;
end;

Function TScrollingWinControl.StoreScrollBars : Boolean;
begin
  Result := Not AutoScroll;
end;

procedure TScrollingWinControl.ScrollBy(DeltaX, DeltaY: Integer);
begin
  TWSScrollingWinControlClass(WidgetSetClass).ScrollBy(Self, DeltaX, DeltaY);
  Invalidate;
end;

Procedure TScrollingWinControl.WMVScroll(var Message : TLMVScroll);
begin
  VertScrollbar.ScrollHandler(Message);
end;

Procedure TScrollingWinControl.WMHScroll(var Message : TLMHScroll);
begin
  HorzScrollbar.ScrollHandler(Message);
end;

Constructor TScrollingWinControl.Create(AOwner : TComponent);
begin
  Inherited Create(AOwner);

  FCanvas := TControlCanvas.Create;
  FCanvas.Control := Self;

  FVertScrollbar := TControlScrollBar.Create(Self, sbVertical);
  FHorzScrollbar := TControlScrollBar.Create(Self, sbHorizontal);

  ControlStyle := [csAcceptsControls, csClickEvents, csDoubleClicks];

  SetInitialBounds(0,0, 150, 150);
end;

Destructor TScrollingWinControl.Destroy;
begin
  FreeThenNil(FHorzScrollBar);
  FreeThenNil(FVertScrollBar);
  FreeThenNil(FCanvas);
  inherited Destroy;
end;

// included by forms.pp
