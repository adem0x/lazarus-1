{%MainUnit ../forms.pp}
{******************************************************************************
                          TApplicationProperties
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

Procedure TApplicationProperties.SetCaptureExceptions(Const AValue : boolean);
begin
  FCaptureExceptions := AValue;

  If not (csDesigning in ComponentState) then
    Application.CaptureExceptions := AValue;
end;

Procedure TApplicationProperties.SetHelpFile(Const AValue : string);
begin
  FHelpFile := AValue;

  If not (csDesigning in ComponentState) then
    Application.HelpFile := AValue;
end;

Procedure TApplicationProperties.SetHint(Const AValue : string);
begin
  FHint := AValue;

  If not (csDesigning in ComponentState) then
    Application.Hint := AValue;
end;

Procedure TApplicationProperties.SetHintColor(Const AValue : TColor);
begin
  FHintColor := AValue;

  If not (csDesigning in ComponentState) then
    Application.HintColor := AValue;
end;

Procedure TApplicationProperties.SetHintHidePause(Const AValue : Integer);
begin
  FHintHidePause := AValue;

  If not (csDesigning in ComponentState) then
    Application.HintHidePause := AValue;
end;

Procedure TApplicationProperties.SetHintPause(Const AValue : Integer);
begin
  FHintPause := AValue;

  If not (csDesigning in ComponentState) then
    Application.HintPause := AValue;
end;

Procedure TApplicationProperties.SetHintShortCuts(Const AValue : Boolean);
begin
  FHintShortCuts := AValue;

  If not (csDesigning in ComponentState) then
    Application.HintShortCuts := AValue;
end;

Procedure TApplicationProperties.SetHintShortPause(Const AValue : Integer);
begin
  FHintShortPause := AValue;

  If not (csDesigning in ComponentState) then
    Application.HintShortPause := AValue;
end;

Procedure TApplicationProperties.SetShowHint(Const AValue : Boolean);
begin
  FShowHint := AValue;

  If not (csDesigning in ComponentState) then
    Application.ShowHint := AValue;
end;

Procedure TApplicationProperties.SetTitle(Const AValue : String);
begin
  FTitle := AValue;

  If not (csDesigning in ComponentState) then
    Application.Title := AValue;
end;

Procedure TApplicationProperties.SetOnException(Const AValue : TExceptionEvent);
begin
  FOnException := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnException := AValue;
end;

Procedure TApplicationProperties.SetOnIdle(Const AValue : TIdleEvent);
begin
  FOnIdle := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnIdle := AValue;
end;

Procedure TApplicationProperties.SetOnIdleEnd(Const AValue : TNotifyEvent);
begin
  FOnIdleEnd := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnIdleEnd := AValue;
end;

Procedure TApplicationProperties.SetOnHelp(Const AValue : THelpEvent);
begin
  FOnHelp := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnHelp := AValue;
end;

Procedure TApplicationProperties.SetOnHint(Const AValue : TNotifyEvent);
begin
  FOnHint := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnHint := AValue;
end;

Procedure TApplicationProperties.SetOnShowHint(Const AValue : TShowHintEvent);
begin
  FOnShowHint := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnShowHint := AValue;
end;

Procedure TApplicationProperties.SetOnUserInput(Const AValue : TOnUserInputEvent);
begin
  FOnUserInput := AValue;

  If not (csDesigning in ComponentState) then
    Application.OnUserInput := AValue;
end;

constructor TApplicationProperties.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  If (csDesigning in ComponentState) then begin
    FCaptureExceptions:=true;
    FHintColor := DefHintColor;
    FHintPause := DefHintPause;
    FHintShortCuts := True;
    FHintShortPause := DefHintShortPause;
    FHintHidePause := DefHintHidePause;
    FShowHint := true;
  end
  else begin
    FCaptureExceptions := Application.CaptureExceptions;
    FHelpFile := Application.HelpFile;
    FHint := Application.Hint;
    FHintColor := Application.HintColor;
    FHintHidePause := Application.HintHidePause;
    FHintPause := Application.HintPause;
    FHintShortCuts := Application.HintShortCuts;
    FHintShortPause := Application.HintShortPause;
    FShowHint := Application.ShowHint;
    FTitle := Application.Title;
  end;

  FOnIdle := nil;
  FOnException := nil;
  FOnIdle := nil;
  FOnIdleEnd := nil;
  FOnHelp := nil;
  FOnHint := nil;
  FOnShowHint := nil;
  FOnUserInput := nil;
end;

// included by forms.pp

{ =============================================================================

  $Log$
  Revision 1.1  2004/07/25 01:04:45  mattias
  TXMLPropStorage basically working

}