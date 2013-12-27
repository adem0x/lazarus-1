{%MainUnit ../buttons.pp}

{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

{------------------------------------------------------------------------------}
{       TButtonGlyph Constructor                                                    }
{------------------------------------------------------------------------------}
constructor TButtonGlyph.Create;
begin
//  Inherited Create;
  FOriginal := TBitmap.Create;
  FOriginal.Handle := 0;
  FOriginal.OnChange := @GlyphChanged;
end;

{------------------------------------------------------------------------------}
{       TButtonGlyph destructor                                                    }
{------------------------------------------------------------------------------}
destructor TButtonGlyph.Destroy;
Begin
  FOriginal.Free;
  FOriginal:=nil;
  inherited Destroy;
end;

{------------------------------------------------------------------------------}
{       TButtonGlyph SetGlyph                                                  }
{------------------------------------------------------------------------------}
procedure TButtonGlyph.SetGlyph(Value : TBitmap);
var
  GlyphCount : integer;
begin
  if FOriginal = Value then exit;
  {$IFDEF BitmapSharingWorks}
  if FOriginal=nil then begin
    FOriginal:=TBitmap.Create;
  end;
  FOriginal.OnChange:=nil;
  FOriginal.Assign(Value);
  {$ELSE}
  if FOriginal<>nil then begin
    FOriginal.OnChange:=nil;
    FOriginal.Free;
  end;
  FOriginal:= Value;
  {$ENDIF}
  FOriginal.OnChange := @GlyphChanged;
  FNumGlyphs:=1;
  if (FOriginal <> nil) and (FOriginal.Height > 0) then begin
    if FOriginal.Width mod FOriginal.Height = 0 then begin
      GlyphCount:= FOriginal.Width div FOriginal.Height;
      if GlyphCount > 4 then GlyphCount:= 1;
      FNumGlyphs:= TNumGlyphs(GlyphCount);
    end;
  end;
  GlyphChanged(FOriginal);
end;

procedure TButtonGlyph.GlyphChanged(Sender: TObject);
begin
  if Sender = FOriginal then
    if Assigned(FOnChange) then FOnChange(Self);
end;

{------------------------------------------------------------------------------}
{       TButtonGlyph Draw                                                      }
{------------------------------------------------------------------------------}
Function TButtonGlyph.Draw(Canvas: TCanvas; const Client: TRect;
  const Offset: TPoint;  State: TButtonState;  Transparent: Boolean;
  BiDiFlags: Longint): TRect;
var
  gWidth: integer;
  gHeight: integer;
  DestRect, SrcRect: TRect;
  ImgID: integer;
  UseMaskHandle: HBitmap;
begin
  Result:=Client;
  if (FOriginal = nil) then exit;

  gWidth := FOriginal.Width;
  gHeight := FOriginal.Height;
  if (gWidth = 0) or (gHeight = 0)
  or (Client.Left>=Client.Right) or (Client.Top>=Client.Bottom) then Exit;
  
  if NumGlyphs > 1 then
    gWidth := gWidth div NumGlyphs;
    
  ImgID:=0;
  case State of
    bsDisabled:  if NumGlyphs>1 then ImgID:=1;
    bsDown:      if NumGlyphs>2 then ImgID:=2;
    bsExclusive: if NumGlyphs>3 then ImgID:=3;
  end;

  SrcRect := Rect((ImgID*gWidth), 0, ((ImgID+1)*gWidth), gHeight);
  DestRect:=Client;
  inc(DestRect.Left,Offset.X);
  inc(DestRect.Top,Offset.Y);
  If DestRect.Right > DestRect.Left + SrcRect.Right - SrcRect.Left then
    DestRect.Right := DestRect.Left + SrcRect.Right - SrcRect.Left;
  If DestRect.Bottom > DestRect.Top + gHeight then
    DestRect.Bottom := DestRect.Top + gHeight;
  If (SrcRect.Right - SrcRect.Left) <> (DestRect.Right - DestRect.Left) then
    SrcRect.Right := SrcRect.Left + DestRect.Right - DestRect.Left;
  If (SrcRect.Bottom - SrcRect.Top) <> (DestRect.Bottom - DestRect.Top) then
    SrcRect.Bottom := SrcRect.Top + DestRect.Bottom - DestRect.Top;

  //Canvas.CopyRect(DestRect, FOriginal.Canvas, SrcRect)
  UseMaskHandle:=FOriginal.MaskHandle;
  MaskBlt(Canvas.Handle,
          DestRect.Left,DestRect.Top,
          DestRect.Right-DestRect.Left,DestRect.Bottom-DestRect.Top,
          FOriginal.Canvas.Handle,SrcRect.Left,SrcRect.Top,
          UseMaskHandle,SrcRect.Left,SrcRect.Top);

  // ToDo: VCL returns the text rectangle
  Result:=SrcRect;
end;


{------------------------------------------------------------------------------}
{       TButtonGlyph SetNumGlyphs                                               }
{------------------------------------------------------------------------------}
procedure TButtonGlyph.SetNumGlyphs(Value : TNumGlyphs);
begin
  if Value <> FNumGlyphs then begin
    FNumGlyphs := Value;
    GlyphChanged(FOriginal);
  end;
end;

// included by buttons.pp