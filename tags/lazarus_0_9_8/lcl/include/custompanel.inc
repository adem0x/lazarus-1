{%MainUnit ../extctrls.pp}

{******************************************************************************
                                TCustomRadioBox
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
{

  Delphi compatibility:

  - TPanel is compatible with Delphi implementation
}

{------------------------------------------------------------------------------
  constructor TCustomPanel.Create (TheOwner : TComponent);
 ------------------------------------------------------------------------------}
constructor TCustomPanel.Create (TheOwner : TComponent);
begin
  inherited Create (TheOwner);
  FCompStyle:= csPanel;
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse,
    csClickEvents, csSetCaption, csDoubleClicks, csReplicatable,
    csNoFocus]
    - [csOpaque]; // we need the default background
  FBevelOuter := bvRaised;
  FBevelInner := bvNone;
  FBevelWidth := 1;
  FAlignment := taCenter;
  Color:=clBtnface;// clBackground;
  SetInitialBounds(0,0,170,50);
  ParentColor := True;
end;

procedure TCustomPanel.SetAlignment(const Value: TAlignment);
begin
  if FAlignment <> Value then begin
    FAlignment := Value;
    Invalidate;
  end;
end;

procedure TCustomPanel.SetBevelWidth(const Value: TBevelWidth);
begin
  if FBevelWidth <> Value then begin
    FBevelWidth := Value;
    Invalidate;
  end;
end;

procedure TCustomPanel.SetBevelInner(const Value: TPanelBevel);
begin
  if BevelInner <> Value then begin
    FBevelInner := Value;
    Invalidate;
  end;
end;

procedure TCustomPanel.SetBevelOuter(const Value: TPanelBevel);
begin
  if BevelOuter <> Value then begin
    FBevelOuter := Value;
    Invalidate;
  end;
end;

procedure TCustomPanel.SetBorderWidth(const Value: TBorderWidth);
begin
  if FBorderWidth <> Value then begin
    FBorderWidth := Value;
    Realign;
    Invalidate;
  end;
end;

procedure TCustomPanel.Paint;
var
  ARect: TRect;
  TS : TTextStyle;
begin
  ARect := GetClientRect;
  if BevelOuter <> bvNone then
  begin
    Canvas.Frame3d(ARect, BevelWidth, BevelOuter);
    InflateRect(ARect, -1, -1);
  end;

  if BevelInner <> bvNone then 
  begin
    if BorderWidth > 0 then InflateRect(ARect, -BorderWidth, -BorderWidth);
    Canvas.Frame3d(ARect, BevelWidth, BevelInner);
    InflateRect(ARect, -1, -1);
  end;

  if Caption <> '' then begin
    TS := Canvas.TextStyle;
    TS.Alignment:= Alignment;
    TS.Layout:= tlCenter;
    TS.Opaque:= false;
    TS.Clipping:= false;
    Canvas.TextRect(ARect,ARect.Left,ARect.Top, Caption, TS);
  end;
end;

function TCustomPanel.ParentColorIsStored: boolean;
begin
  Result:=not ParentColor;
end;

function TCustomPanel.CanTab: Boolean;
begin
  Result:=false;
end;

procedure TCustomPanel.AdjustClientRect(var Rect: TRect);
var
  BevelSize: Integer;
begin
  inherited AdjustClientRect(Rect);
  BevelSize := BorderWidth;
  if BevelOuter <> bvNone then Inc(BevelSize, BevelWidth);
  if BevelInner <> bvNone then Inc(BevelSize, BevelWidth);
  //debugln('TCustomPanel.AdjustClientRect ',DbgSName(Self),' BorderWidth=',dbgs(BorderWidth),' BevelWidth=',dbgs(BevelWidth),' BevelSize=',dbgs(BevelSize));
  InflateRect(Rect, -BevelSize, -BevelSize);
end;

procedure TCustomPanel.RealSetText(const Value: TCaption);
begin
  if Caption <> Value 
  then begin
    inherited RealSetText(Value);
    Invalidate;
  end;
end;

// included by extctrls.pp
