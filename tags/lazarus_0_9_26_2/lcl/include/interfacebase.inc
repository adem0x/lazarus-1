{%MainUnit ../interfacebase.pp}
{ $Id$
******************************************************************************
                                  TWidgetSet

                                   WinApi stuff


  !! Keep this alphabetical !!
 ******************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

constructor TWidgetSet.Create;
begin
  inherited Create;
  FThemeServices := CreateThemeServices;
end;

destructor TWidgetSet.Destroy;
begin
  FreeAndNil(FThemeServices);
  inherited Destroy;
end;

procedure TWidgetSet.PassCmdLineOptions;
begin
end;

function TWidgetSet.CreateThemeServices: TThemeServices;
begin
  Result := TThemeServices.Create;
end;

procedure TWidgetSet.AppRun(const ALoop: TApplicationMainLoop);
begin
  if Assigned(ALoop) then ALoop;
end;

procedure TWidgetSet.AppSetIcon(const Small, Big: HICON);
begin
end;

procedure TWidgetSet.AppSetTitle(const ATitle: string);
begin
  Debugln('TWidgetSet.AppSetTitle is not implemented by ', ClassName);
end;

function TWidgetSet.GetLCLCapability(ACapability: TLCLCapability): PtrUInt;
begin
  case ACapability of
    lcCanDrawOutsideOnPaint,
    lcNeedMininimizeAppWithMainForm,
    lcApplicationTitle,
    lcFormIcon:
      Result := 1;
  else
    Result := 0;
  end;
end;

procedure TWidgetSet.DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean);
begin
end;
