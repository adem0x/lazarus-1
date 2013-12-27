{%MainUnit ../graphics.pp}

{ TBitmapImage

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

destructor TBitmapImage.Destroy;
begin
  FreeAndNil(FSaveStream);
  FSaveStreamType:=bnNone;
  if FDIBHandle <> 0 then
  begin
    DeleteObject(FDIBHandle);
    FDIBHandle := 0;
  end;
  FreeHandle;
  inherited Destroy;
end;

function TBitmapImage.HandleAllocated: boolean;
begin
  Result:=FHandle<>0;
end;

function TBitmapImage.GetHandleType: TBitmapHandleType;
begin
  if (FHandle = 0) or (FHandle = FDIBHandle) then
    if FDIBHandle = 0 then
      if FDIB.dsbmih.biSize = 0 then
        Result := bmDDB
      else
        Result := bmDIB
    else
      Result := bmDIB
  else
    Result := bmDDB;
end;

procedure TBitmapImage.FreeHandle;
begin
  FreeMaskHandle;
  if (FHandle <> 0) and (FHandle <> FDIBHandle) then
  begin
    DeleteObject(FHandle);
  end;
  FHandle := 0;
  FPalette := 0;
end;

procedure TBitmapImage.FreeMaskHandle;
begin
  if FMaskHandle <> 0 then
  begin
    DeleteObject(FMaskHandle);
    FMaskHandle := 0;
  end;
end;

function TBitmapImage.ReleaseHandle: HBITMAP;
// simply return the current handle and set to 0 without freeing handles
begin
  Result:=FHandle;
  if FHandle = FDIBHandle then
  begin
    FDIBHandle := 0;
    FDIB.dsbm.bmBits := nil;
  end;
  FHandle:=0;
end;

function TBitmapImage.IsEmpty: boolean;
begin
  Result := (FHandle = 0) and (FDIBHandle = 0)
            and (SaveStream=nil);
end;

function TBitmapImage.GetPixelFormat: TPixelFormat;
begin
  Result:=pfCustom;
  if GetHandleType = bmDDB then
    Result := pfDevice
  else
    case FDIB.dsBmih.biBitCount of
      1: Result := pf1Bit;
      4: Result := pf4Bit;
      8: Result := pf8Bit;
     16: case FDIB.dsBmih.biCompression of
           BI_RGB : Result := pf15Bit;
           BI_BITFIELDS: if FDIB.dsBitFields[1] = $7E0 then
                           Result := pf16Bit;
         end;
     24: Result := pf24Bit;
     32: if FDIB.dsBmih.biCompression = BI_RGB then
           Result := pf32Bit;
    end;
end;

// included by graphics.pp
