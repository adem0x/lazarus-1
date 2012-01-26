{
 *****************************************************************************
 *                             WSLazDeviceAPIS.pas                           *
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
unit WSLazDeviceAPIS;

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
  Types, Math, LazDeviceAPIs,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, WSFactory;

type
  { TWSLazDeviceAPIS }
  
  TWSLazDeviceAPIsClass = class of TWSLazDeviceAPIs;
  TWSLazDeviceAPIs = class(TWSObject)
  public
    class procedure RequestPositionInfo(AMethod: TLazPositionMethod); virtual;
    class procedure SendMessage(AMsg: TLazDeviceMessage); virtual;
    class procedure StartReadingAccelerometerData(); virtual;
    class procedure StopReadingAccelerometerData(); virtual;
  end;

{ WidgetSetRegistration }
procedure RegisterLazDeviceAPIs;

implementation

{ TWSArrow }


{ WidgetSetRegistration }

procedure RegisterLazDeviceAPIs;
const
  Done: Boolean = False;
begin
  if Done then exit;
  WSRegisterLazDeviceAPIs;
//  if not WSRegisterArrow then
//    RegisterWSComponent(TArrow, TWSArrow);
  Done := True;
end;

{ TWSLazDeviceAPIs }

class procedure TWSLazDeviceAPIs.RequestPositionInfo(AMethod: TLazPositionMethod);
begin

end;

class procedure TWSLazDeviceAPIs.SendMessage(AMsg: TLazDeviceMessage);
begin

end;

class procedure TWSLazDeviceAPIs.StartReadingAccelerometerData;
begin

end;

class procedure TWSLazDeviceAPIs.StopReadingAccelerometerData;
begin

end;

end.
