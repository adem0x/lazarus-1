{ $Id$}
{
 *****************************************************************************
 *                                WSForms.pp                                 * 
 *                                ----------                                 * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
}
unit WSForms;

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
  Forms,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, Controls, LCLType, WSFactory;

type
  { TWSScrollingWinControl }

  TWSScrollingWinControlClass = class of TWSScrollingWinControl;
  TWSScrollingWinControl = class(TWSWinControl)
  published
    class procedure ScrollBy(const AWinControl: TScrollingWinControl; 
      const DeltaX, DeltaY: integer); virtual;
  end;

  { TWSScrollBox }

  TWSScrollBox = class(TWSScrollingWinControl)
  published
  end;

  { TWSCustomFrame }

  TWSCustomFrame = class(TWSScrollingWinControl)
  published
  end;

  { TWSFrame }

  TWSFrame = class(TWSCustomFrame)
  published
  end;

  { TWSCustomForm }

  TWSCustomForm = class(TWSScrollingWinControl)
  published
    class procedure CloseModal(const ACustomForm: TCustomForm); virtual;
    class procedure SetAllowDropFiles(const AForm: TCustomForm; AValue: Boolean); virtual;
    class procedure SetBorderIcons(const AForm: TCustomForm;
        const ABorderIcons: TBorderIcons); virtual;
    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); virtual;
    class procedure SetFormStyle(const AForm: TCustomform; const AFormStyle: TFormStyle); virtual;
    class procedure SetIcon(const AForm: TCustomForm; const Small, Big: HICON); virtual;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); virtual;
    class procedure SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition); virtual;
    class procedure ShowModal(const ACustomForm: TCustomForm); virtual;
  end;
  TWSCustomFormClass = class of TWSCustomForm;

  { TWSForm }

  TWSForm = class(TWSCustomForm)
  published
  end;

  { TWSHintWindow }

  TWSHintWindow = class(TWSCustomForm)
  published
  end;

  { TWSScreen }

  TWSScreen = class(TWSLCLComponent)
  published
  end;

  { TWSApplicationProperties }

  TWSApplicationProperties = class(TWSLCLComponent)
  published
  end;

  { WidgetSetRegistration }

  procedure RegisterScrollingWinControl;
  procedure RegisterScrollBox;
  procedure RegisterCustomFrame;
  procedure RegisterCustomForm;
  procedure RegisterHintWindow;

implementation

{ TWSScrollingWinControl }

class procedure TWSScrollingWinControl.ScrollBy(const AWinControl: TScrollingWinControl;
  const DeltaX, DeltaY: integer);
begin
end;
  
{ TWSCustomForm }

class procedure TWSCustomForm.CloseModal(const ACustomForm: TCustomForm);
begin
end;

class procedure TWSCustomForm.SetAllowDropFiles(const AForm: TCustomForm;
  AValue: Boolean);
begin
end;

class procedure TWSCustomForm.SetBorderIcons(const AForm: TCustomForm;
        const ABorderIcons: TBorderIcons);
begin
end;

class procedure TWSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
begin
  // will be done in interface override
end;

class procedure TWSCustomForm.SetFormStyle(const AForm: TCustomform;
  const AFormStyle: TFormStyle);
begin
end;
    
class procedure TWSCustomForm.SetIcon(const AForm: TCustomForm; const Small, Big: HICON);
begin
end;

class procedure TWSCustomForm.SetShowInTaskbar(const AForm: TCustomForm;
  const AValue: TShowInTaskbar);
begin
end;

class procedure TWSCustomForm.SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition);
begin
end;
   
class procedure TWSCustomForm.ShowModal(const ACustomForm: TCustomForm);
begin
end;

{ WidgetSetRegistration }

procedure RegisterScrollingWinControl;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterScrollingWinControl;
//  if not WSRegisterScrollingWinControl then
//    RegisterWSComponent(TScrollingWinControl, TWSScrollingWinControl);
  Done := True;
end;

procedure RegisterScrollBox;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterScrollBox;
//  if not WSRegisterScrollBox then
//    RegisterWSComponent(TScrollBox, TWSScrollBox);
  Done := True;
end;

procedure RegisterCustomFrame;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterCustomFrame;
//  if not WSRegisterCustomFrame then
//    RegisterWSComponent(TCustomFrame, TWSCustomFrame);
  Done := True;
end;

procedure RegisterCustomForm;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterCustomForm;
//  if not WSRegisterCustomForm then
//    RegisterWSComponent(TCustomForm, TWSCustomForm);
  Done := True;
end;

procedure RegisterHintWindow;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterHintWindow;
//  if not WSRegisterHintWindow then
//    RegisterWSComponent(THintWindow, TWSHintWindow);
  Done := True;
end;

end.