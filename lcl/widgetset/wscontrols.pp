{ $Id$}
{
 *****************************************************************************
 *                               WSControls.pp                               * 
 *                               -------------                               * 
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
unit WSControls;

{$mode objfpc}{$H+}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Controls, Graphics,
////////////////////////////////////////////////////
  WSLCLClasses, WSImgList;

type
  { TWSDragImageList }

  TWSDragImageList = class(TWSCustomImageList)
  end;

  { TWSControl }

  TWSControl = class(TWSLCLComponent)
    class procedure AddControl(const AControl: TControl); virtual;
    class procedure SetCursor(const AControl: TControl; const ACursor: TCursor); virtual;
  end;

  TWSControlClass = class of TWSControl;

  { TWSWinControl }

  TWSWinControl = class(TWSControl)
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; virtual;
    class function  GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; virtual;

    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); virtual;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); virtual;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); virtual;
    class procedure SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); virtual;
    class procedure SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); virtual;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); virtual;
    class procedure SetColor(const AWinControl: TWinControl); virtual;

    class procedure DestroyHandle(const AWinControl: TWinControl); virtual;
    class procedure Invalidate(const AWinControl: TWinControl); virtual;
    class procedure ShowHide(const AWinControl: TWinControl); virtual;
  end;       
  TWSWinControlClass = class of TWSWinControl;

  { TWSGraphicControl }

  TWSGraphicControl = class(TWSControl)
  end;

  { TWSCustomControl }

  TWSCustomControl = class(TWSWinControl)
  end;

  { TWSImageList }

  TWSImageList = class(TWSDragImageList)
  end;


implementation


{ TWSControl }

procedure TWSControl.AddControl(const AControl: TControl);
begin
end;

procedure TWSControl.SetCursor(const AControl: TControl; const ACursor: TCursor);
begin
end;

{ TWSWinControl }

procedure TWSWinControl.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
end;

{------------------------------------------------------------------------------
  Function: TWSWinControl.GetText
  Params:  Sender: The control to retrieve the text from
  Returns: the requested text

  Retrieves the text from a control. 
 ------------------------------------------------------------------------------}
function TWSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean; 
begin
  Result := false;
end;
  
function TWSWinControl.GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; 
var
  S: String;
begin
  Result := GetText(AWinControl, S);
  if Result
  then ALength := Length(S);
end;
  
procedure TWSWinControl.SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); 
begin
end;
    
procedure TWSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
begin
end;

procedure TWSWinControl.SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); 
begin
end;

procedure TWSWinControl.SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); 
begin
end;

{------------------------------------------------------------------------------
  Method: TWSWinControl.SetLabel
  Params:  AWinControl - the calling object
           AText       - String to be set as label/text for a control
  Returns: Nothing

  Sets the label text on a widget
 ------------------------------------------------------------------------------}
procedure TWSWinControl.SetText(const AWinControl: TWinControl; const AText: String); 
begin
end;

procedure TWSWinControl.SetColor(const AWinControl: TWinControl);
begin
end;

procedure TWSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
end;

procedure TWSWinControl.Invalidate(const AWinControl: TWinControl);
begin
end;

procedure TWSWinControl.ShowHide(const AWinControl: TWinControl);
begin
end;

initialization

////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TDragImageList, TWSDragImageList);
  RegisterWSComponent(TControl, TWSControl);
  RegisterWSComponent(TWinControl, TWSWinControl);
//  RegisterWSComponent(TGraphicControl, TWSGraphicControl);
//  RegisterWSComponent(TCustomControl, TWSCustomControl);
//  RegisterWSComponent(TImageList, TWSImageList);
////////////////////////////////////////////////////
end.
