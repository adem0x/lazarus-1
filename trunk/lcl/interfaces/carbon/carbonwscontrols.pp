{ $Id$}
{
 *****************************************************************************
 *                            CarbonWSControls.pp                            *
 *                              ---------------                              *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit CarbonWSControls;

{$mode objfpc}{$H+}

interface

uses
  // libs
  FPCMacOSAll, CarbonUtils, CarbonExtra, Classes,
  // LCL
  Controls, LCLType, LMessages, LCLProc,
  // widgetset
  WSControls, WSLCLClasses, WSProc,
  // interface
  CarbonDef, CarbonProc, CarbonPrivate;

type

  { TCarbonWSDragImageList }

  TCarbonWSDragImageList = class(TWSDragImageList)
  private
  protected
  public
  end;

  { TCarbonWSControl }

  TCarbonWSControl = class(TWSControl)
  private
  protected
  public
  end;

  { TCarbonWSWinControl }

  TCarbonWSWinControlClass = class of TCarbonWSWincontrol;
  TCarbonWSWinControl = class(TWSWinControl)
  private
  protected
  public
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); virtual;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
  end;

  { TCarbonWSGraphicControl }

  TCarbonWSGraphicControl = class(TWSGraphicControl)
  private
  protected
  public
  end;

  { TCarbonWSCustomControl }

  TCarbonWSCustomControl = class(TWSCustomControl)
  private
  protected
  public
  end;

  { TCarbonWSImageList }

  TCarbonWSImageList = class(TWSImageList)
  private
  protected
  public
  end;


implementation

{ TCarbonWSWinControl }

function TCarbonWSWinControl.GetText(const AWinControl: TWinControl;
  var AText: String): Boolean;
var
  CFString: CFStringRef;
  Str: Pointer;
  StrSize: CFIndex; //Integer;
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetText')
  then Exit;

  Result := CopyControlTitleAsCFString(ControlRef(AWinControl.Handle),
                                       CFString) = NoErr;
  if Result = False then Exit;
  
  // Try the quick way first
  Str := CFStringGetCStringPtr(CFString, DEFAULT_CFSTRING_ENCODING);
  if Str <> nil then begin
    AText := PChar(Str);
  end else begin
    // if that doesn't work this will
    StrSize := CFStringGetLength(CFString);
    GetMem(Str,StrSize);
    Result := CFStringGetCString(CFString, Str, StrSize, DEFAULT_CFSTRING_ENCODING);
    AText := PChar(Str);
    FreeMem(Str);
  end;

  CFRelease(Pointer(CFString));
  if Result = False then Exit;
end;

class procedure TCarbonWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
var
  NewBounds: FPCMacOSAll.Rect;
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetText') then Exit;

  NewBounds.left:=AWinControl.Left;
  NewBounds.top:=AWinControl.Top;
  NewBounds.right:=AWinControl.Left+AWinControl.Width;
  NewBounds.bottom:=AWinControl.Top+AWinControl.Height;
  DebugLn('TCarbonWSWinControl.SetBounds ',dbgsName(AWinControl),' NewBounds=',dbgs(NewBounds));
  if SetWindowBounds(WindowRef(AWinControl.Handle),kWindowStructureRgn,NewBounds)
  <> NoErr then begin
    DebugLn('TCarbonWSWinControl.SetBounds ',dbgsName(AWinControl),' failed');
  end;
end;

procedure TCarbonWSWinControl.SetText(const AWinControl: TWinControl;
  const AText: String);
var
  CFString: CFStringRef;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'SetText')
  then Exit;
  
  DebugLn('TCarbonWSWinControl.SetText ',dbgsName(AWinControl),' ',AText);

  CFString := CFStringCreateWithCString(nil, Pointer(PChar(AText)),
                                        DEFAULT_CFSTRING_ENCODING);
  SetControlTitleWithCFString(ControlRef(AWinControl.Handle), CFString);
  CFRelease(Pointer(CFString));
end;

procedure TCarbonWSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWincontrol, 'DestroyHandle')
  then Exit;
  
  DebugLn('TCarbonWSWinControl.DestroyHandle ',dbgsName(AWinControl));
  DisposeControl(ControlRef(AWinControl.Handle));
end;

function TCarbonWSWinControl.GetClientBounds(const AWincontrol: TWinControl;
  var ARect: TRect): Boolean;
var
  AHiRect: HIRect;
begin
  Result := HIViewGetBounds(HIViewRef(AWinControl.Handle), AHiRect) = 0;
  if not Result then Exit;
  ARect.Top := Trunc(AHiRect.Origin.y);
  ARect.Left := Trunc(AHiRect.Origin.x);
  ARect.Right := ARect.Left + Trunc(AHiRect.size.width);
  ARect.Bottom := ARect.Top + Trunc(AHIRect.size.height);
end;

function TCarbonWSWinControl.GetClientRect(const AWincontrol: TWinControl;
  var ARect: TRect): Boolean;
var
  AHiRect: HIRect;
begin
  Result := HIViewGetBounds(HIViewRef(AWinControl.Handle), AHiRect) = 0;
  if not Result then Exit;
  ARect.Top := 0;//AHiRect.Origin.y;
  ARect.Left := 0;//AHiRect.Origin.x;
  ARect.Right := ARect.Left + Trunc(AHiRect.size.width);
  ARect.Bottom := ARect.Top + Trunc(AHIRect.size.height);
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TDragImageList, TCarbonWSDragImageList);
//  RegisterWSComponent(TControl, TCarbonWSControl);
  RegisterWSComponent(TWinControl, TCarbonWSWinControl, TCarbonPrivateHiView);
//  RegisterWSComponent(TGraphicControl, TCarbonWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TCarbonWSCustomControl);
//  RegisterWSComponent(TImageList, TCarbonWSImageList);
////////////////////////////////////////////////////

finalization
//  if MCarbonWSWinControl_Dispose_UPP <> nil then DisposeEventHandlerUPP(MCarbonWSWinControl_Dispose_UPP);
//  if MCarbonWSWinControl_Hit_UPP <> nil then DisposeEventHandlerUPP(MCarbonWSWinControl_Hit_UPP);

end.
