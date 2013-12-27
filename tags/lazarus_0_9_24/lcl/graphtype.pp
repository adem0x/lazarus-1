{  $Id$  }
{
 /***************************************************************************
                                graphtype.pp
                                ------------
                    Graphic related platform independent types
                    and utility functions.
                    Initial Revision  : Sat Feb 02 0:02:58 2002

 ***************************************************************************/

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
unit GraphType;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LCLProc;

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

type
  TGraphicsColor = -$7FFFFFFF-1..$7FFFFFFF;
  TGraphicsFillStyle = (
    fsSurface, // fill till the color (it fills all execpt this color)
    fsBorder   // fill this color (it fills only conneted pixels of this color)
    );
  TGraphicsBevelCut = (bvNone, bvLowered, bvRaised, bvSpace);

//------------------------------------------------------------------------------
// raw image data
type
  { Colorformat: Higher values means higher intensity.
    For example: Red=0 means no red, Alpha=0 means transparent }
  TRawImageColorFormat = (
    ricfRGBA,   // one pixel contains red, green, blue and alpha
                // If AlphaPrec=0 then there is no alpha.
                // Same for RedPrec, GreenPrec and BluePrec.
    ricfGray    // R=G=B. The Red stores the Gray. AlphaPrec can be >0.
    );

  TRawImageByteOrder = (
    riboLSBFirst, // least significant byte first
    riboMSBFirst  // most significant byte first
    );
    
  TRawImageBitOrder = (
    riboBitsInOrder, // Bit 0 is pixel 0
    riboReversedBits // Bit 0 is pixel 7 (Bit 1 is pixel 6, ...)
    );

  TRawImageLineEnd = (
    rileTight,         // no gap at end of lines
    rileByteBoundary,  // each line starts at byte boundary. For example:
                       // If BitsPerPixel=3 and Width=1, each line has a gap
                       // of 5 unused bits at the end.
    rileWordBoundary,  // each line starts at word (16bit) boundary
    rileDWordBoundary, // each line starts at double word (32bit) boundary
    rileQWordBoundary, // each line starts at quad word (64bit) boundary
    rileDQWordBoundary // each line starts at double quad word (128bit) boundary
    );

  TRawImageLineOrder = (
    riloTopToBottom, // The line 0 is the top line
    riloBottomToTop  // The line 0 is the bottom line
    );

  { TRawImageDescription }

  TRawImageDescription = object
    Format: TRawImageColorFormat;
    Width: cardinal;
    Height: cardinal;
    Depth: Byte; // used bits per pixel
    BitOrder: TRawImageBitOrder;
    ByteOrder: TRawImageByteOrder;
    LineOrder: TRawImageLineOrder;
    LineEnd: TRawImageLineEnd;
    BitsPerPixel: Byte; // bits per pixel. can be greater than Depth.
    RedPrec: Byte; // red precision. bits for red
    RedShift: Byte;
    GreenPrec: Byte;
    GreenShift: Byte; // bitshift. Direction: from least to most significant
    BluePrec: Byte;
    BlueShift: Byte;
    AlphaPrec: Byte;
    AlphaShift: Byte;

    // The next values are only valid, if there is a mask (MaskBitsPerPixel > 0)
    // Masks are always separate with a depth of 1 bpp. One pixel can occupy
    // one byte at most
    // a value of 1 means that pixel is masked
    // a value of 0 means the pixel value is shown
    MaskBitsPerPixel: Byte; // bits per mask pixel, usually 1, 0 when no mask
    MaskShift: Byte;        // the shift (=position) of the mask bit
    MaskLineEnd: TRawImageLineEnd;
    MaskBitOrder: TRawImageBitOrder;

    // The next values are only valid, if there is a palette (PaletteColorCount > 0)
    PaletteColorCount: Word;   // entries in color palette. 0 when no palette.
    PaletteBitsPerIndex: Byte; // bits per palette index, this can be larger than the colors used
    PaletteShift: Byte;        // bitshift. Direction: from least to most significant
    PaletteLineEnd: TRawImageLineEnd;
    PaletteBitOrder: TRawImageBitOrder;
    PaletteByteOrder: TRawImageByteOrder;
    
    // don't use a contructor here, it will break compatebility with a record
    procedure Init;
    
    procedure Init_BPP24_B8G8R8_BIO_TTB(AWidth, AHeight: integer);
    procedure Init_BPP24_B8G8R8_M1_BIO_TTB(AWidth, AHeight: integer);
    procedure Init_BPP32_B8G8R8_BIO_TTB(AWidth, AHeight: integer);
    procedure Init_BPP32_B8G8R8_M1_BIO_TTB(AWidth, AHeight: integer);
    procedure Init_BPP32_B8G8R8A8_BIO_TTB(AWidth, AHeight: integer);
    procedure Init_BPP32_B8G8R8A8_M1_BIO_TTB(AWidth, AHeight: integer);

    function GetDescriptionFromMask: TRawImageDescription;
    function GetDescriptionFromAlpha: TRawImageDescription;


    function BytesPerLine: PtrUInt;
    function BitsPerLine: PtrUInt;
    function MaskBytesPerLine: PtrUInt;
    function MaskBitsPerLine: PtrUInt;

    function AsString: string;
    function IsEqual(ADescription: TRawImageDescription): Boolean;
  end;
  PRawImageDescription = ^TRawImageDescription;
  
  // Note: not all devices/images have all parts at any time. But if a part can
  // be applied to the device/image, the 'Description' describes its structure.


  TRawImagePosition = record
    Byte: PtrUInt;
    Bit: cardinal;
  end;
  PRawImagePosition = ^TRawImagePosition;

  { TRawImage }

  TRawImage = object
    Description: TRawImageDescription;
    Data: PByte;
    DataSize: PtrUInt;
    Mask: PByte;
    MaskSize: PtrUInt;
    Palette: PByte;
    PaletteSize: PtrUInt;
    
    // don't use a contructor here, it will break compatebility with a record
    procedure Init;
    procedure CreateData(AZeroMem: Boolean);

    procedure FreeData;
    procedure ReleaseData;
    procedure ExtractRect(const ARect: TRect; out ADst: TRawImage);

    function  ReadBits(const APosition: TRawImagePosition; APrec, AShift: Byte): Word;
    procedure ReadChannels(const APosition: TRawImagePosition; out ARed, AGreen, ABlue, AAlpha: Word);
    procedure ReadMask(const APosition: TRawImagePosition; out AMask: Boolean);
    procedure WriteBits(const APosition: TRawImagePosition; APrec, AShift: Byte; ABits: Word);
    procedure WriteChannels(const APosition: TRawImagePosition; ARed, AGreen, ABlue, AAlpha: Word);
    procedure WriteMask(const APosition: TRawImagePosition; AMask: Boolean);

    function  IsMasked(ATestPixels: Boolean): Boolean;
    function  IsTransparent(ATestPixels: Boolean): Boolean;
    function  IsEqual(AImage: TRawImage): Boolean;
  end;
  PRawImage = ^TRawImage;

  { TRawImageLineStarts }

  TRawImageLineStarts = object
  private
    FWidth: Cardinal;
    FHeight: Cardinal;
    FBitsPerPixel: Byte;
    FLineEnd: TRawImageLineEnd;
    FLineOrder: TRawImageLineOrder;
  public
    Positions: array of TRawImagePosition;

    // don't use a contructor here, it will break compatibility with a record
    procedure Init(AWidth, AHeight: cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd; ALineOrder: TRawImageLineOrder);
    function GetPosition(x, y: cardinal): TRawImagePosition;
  end;
  PRawImageLineStarts = ^TRawImageLineStarts;

const
  RawImageColorFormatNames: array[TRawImageColorFormat] of string = (
    'ricfRGBA',
    'ricfGray'
    );

  RawImageByteOrderNames: array[TRawImageByteOrder] of string = (
    'riboLSBFirst',
    'riboMSBFirst'
    );

  RawImageBitOrderNames: array[TRawImageBitOrder] of string = (
    'riboBitsInOrder',
    'riboReversedBits'
    );

  RawImageLineEndNames: array[TRawImageLineEnd] of string = (
    'rileTight',
    'rileByteBoundary',
    'rileWordBoundary',
    'rileDWordBoundary',
    'rileQWordBoundary',
    'rileDQWordBoundary'
    );

  RawImageLineOrderNames: array[TRawImageLineOrder] of string = (
    'riloTopToBottom',
    'riloBottomToTop'
    );
    
  DefaultByteOrder = {$IFDEF Endian_Little}riboLSBFirst{$ELSE}riboMSBFirst{$ENDIF};


function GetBytesPerLine(AWidth: Cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd): PtrUInt;
function GetBitsPerLine(AWidth: Cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd): PtrUInt;

function CopyImageData(AWidth, AHeight, ARowStride: Integer; ABPP: Word;
                       ASource: Pointer; const ARect: TRect; ASourceOrder: TRawImageLineOrder;
                       ADestinationOrder: TRawImageLineOrder; ADestinationEnd: TRawImageLineEnd;
                       out ADestination: Pointer; out ASize: PtrUInt): Boolean;

{.$define OldRawImageProcs}

// TODO: remove
{$ifdef OldRawImageProcs}
function RawImageMaskIsEmpty(RawImage: PRawImage; TestPixels: boolean): boolean;
function RawImageDescriptionAsString(Desc: PRawImageDescription): string;
procedure FreeRawImageData(RawImage: PRawImage);
procedure ReleaseRawImageData(RawImage: PRawImage);

procedure CreateRawImageData(Width, Height, BitsPerPixel: cardinal;
                             LineEnd: TRawImageLineEnd;
                             var Data: Pointer; var DataSize: PtrUInt);
procedure CreateRawImageLineStarts(Width, Height, BitsPerPixel: cardinal;
                                   LineEnd: TRawImageLineEnd;
                                   var LineStarts: PRawImagePosition);
procedure CreateRawImageDescFromMask(SrcRawImageDesc,
                                     DestRawImageDesc: PRawImageDescription);
procedure GetRawImageXYPosition(RawImageDesc: PRawImageDescription;
                                LineStarts: PRawImagePosition; x, y: cardinal;
                                var Position: TRawImagePosition);
procedure ExtractRawImageRect(SrcRawImage: PRawImage; const SrcRect: TRect;
                              DestRawImage: PRawImage);


procedure ReadRawImageBits(TheData: PByte; const Position: TRawImagePosition;
                       BitsPerPixel, Prec, Shift: cardinal;
                       BitOrder: TRawImageBitOrder; var Bits: word);
procedure WriteRawImageBits(TheData: PByte; const Position: TRawImagePosition;
                       BitsPerPixel, Prec, Shift: cardinal;
                       BitOrder: TRawImageBitOrder; Bits: word);

procedure ReAlignRawImageLines(var Data: Pointer; var Size: PtrUInt;
  Width, Height, BitsPerPixel: cardinal;
  var OldLineEnd: TRawImageLineEnd; NewLineEnd: TRawImageLineEnd);

{$endif}

var
  MissingBits: array[0..15] of array[0..7] of word;

implementation

uses
  Math;


{------------------------------------------------------------------------------
  Function: CopyImageData
 ------------------------------------------------------------------------------}

function CopyImageData(AWidth, AHeight, ARowStride: Integer; ABPP: Word; ASource: Pointer; const ARect: TRect; ASourceOrder: TRawImageLineOrder;
                       ADestinationOrder: TRawImageLineOrder; ADestinationEnd: TRawImageLineEnd; out ADestination: Pointer; out ASize: PtrUInt): Boolean;
const
  SIZEMAP: array[TRawImageLineEnd] of Byte = (
    0, 0, 1, 3, 7, 15
  );
var
  W, H, RS, x, LineBytes, LineCount, CopySize, ZeroSize, DstRowInc: Integer;
  P, DstRowPtr: PByte;
  ShiftL, ShiftR: Byte;
  SrcPtr: PByte absolute ASource;
  DstPtr: PByte absolute ADestination;
begin
  // check if we are within bounds
  Result := False;
  if ARect.Left < 0 then Exit;
  if ARect.Top < 0 then Exit;

  W := ARect.Right - ARect.Left;
  H := ARect.Bottom - ARect.Top;
  if W < 0 then Exit;
  if H < 0 then Exit;
  
  // calc destination rowstride
  RS := (W * ABPP + 7) shr 3;
  x := RS and SIZEMAP[ADestinationEnd];
  if x <> 0
  then Inc(RS, 1 + SIZEMAP[ADestinationEnd] - x);

  // check if we can copy all
  if  (ARect.Left = 0) and (ARect.Top = 0)
  and (ARect.Right = AWidth) and (ARect.Bottom = AHeight)
  and (ASourceOrder = ADestinationOrder)
  and (ARowStride = RS)
  then begin
    // full copy
    ASize := AHeight * ARowStride;
    GetMem(ADestination, ASize);
    Move(ASource^, ADestination^, ASize);
    Exit(True);
  end;

  // partial copy

  // calc numer of lines to copy
  if AHeight - ARect.Top < H
  then LineCount := AHeight - ARect.Top
  else LineCount := H;

  ASize := H * RS;
  GetMem(ADestination, ASize);

  if (W = AWidth)
  and (ASourceOrder = ADestinationOrder)
  and (RS = ARowStride)
  then begin
    // easy case, only LineCount lines to copy
    CopySize := LineCount * ARowStride;
    ZeroSize := ASize - CopySize;
    
    if ASourceOrder = riloTopToBottom
    then begin
      // top to bottom, adjust start
      Inc(SrcPtr, ARect.Top * ARowStride);
      Move(SrcPtr[0], DstPtr[0], CopySize);
      // wipe remaining
      if ZeroSize > 0
      then FillChar(DstPtr[CopySize], ZeroSize, 0);
    end
    else begin
      // bottom to top
      // wipe remaining
      if ZeroSize > 0
      then FillChar(DstPtr[0], ZeroSize, 0);
      
      x := AHeight - ARect.Bottom;
      if x > 0
      then Inc(SrcPtr, x * ARowStride);
      Move(SrcPtr[0], DstPtr[ZeroSize], CopySize);
    end;
    Exit(True);
  end;

  // calc number of bytes to copy
  // and wipe destination when source width is smaller than destination
  // I'm to lazy to zero line by line, so we might do to much here
  if AWidth < W
  then begin
    LineBytes := ((AWidth - ARect.Left) * ABPP + 7) shr 3;
    FillByte(DstPtr[0], ASize, 0);
  end
  else begin
    LineBytes := RS;
    if H <> LineCount
    then FillByte(DstPtr[0], ASize, 0);
  end;

  // move to start line
  DstRowPtr := ADestination;
  if ASourceOrder = riloTopToBottom
  then begin
    Inc(SrcPtr, ARect.Top * ARowStride);
  end
  else begin
    x := AHeight - ARect.Bottom;
    if x >= 0
    then Inc(SrcPtr, x * ARowStride)
    else Inc(DstRowPtr, -x * RS);
  end;
  
  // check source and destionation order
  if ASourceOrder = ADestinationOrder
  then begin
    DstRowInc := RS;
  end
  else begin
    // reversed, so fill destination backwards
    DstRowInc := -RS;
    Inc(DstRowPtr, (LineCount - 1) * RS);
  end;

  // move to left pixel
  Inc(SrcPtr, (ARect.Left * ABPP) shr 3);

  // check if we can do byte copies
  ShiftL := (ARect.Left * ABPP) and 7;
  if ShiftL = 0
  then begin
    // Partial width, byte aligned
    while LineCount > 0 do
    begin
      Move(SrcPtr^, DstRowPtr^, LineBytes);
      Inc(SrcPtr, ARowStride);
      Inc(DstRowPtr, DstRowInc);
      Dec(LineCount);
    end;
    Exit(True);
  end;

  // Partial width, not aligned
  ShiftR := 8 - ShiftL;
  while LineCount > 0 do
  begin
    P := DstRowPtr;
    for x := 0 to RS - 1 do
    begin
      p^ := (SrcPtr[x] shl ShiftL) or (SrcPtr[x+1] shr ShiftR);
      Inc(p);
    end;
    Inc(SrcPtr, ARowStride);
    Inc(DstRowPtr, DstRowInc);
    Dec(LineCount);
  end;
  Result := True;
end;

{------------------------------------------------------------------------------
  Function: GetBytesPerLine
 ------------------------------------------------------------------------------}

function GetBytesPerLine(AWidth: Cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd): PtrUInt;
begin
  Result := (GetBitsPerLine(AWidth, ABitsPerPixel, ALineEnd) + 7) shr 3;
end;

{------------------------------------------------------------------------------
  Function: GetBitsPerLine
 ------------------------------------------------------------------------------}
 
function GetBitsPerLine(AWidth: Cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd): PtrUInt;
begin
  Result := AWidth * ABitsPerPixel;
  case ALineEnd of
    rileTight: ;
    rileByteBoundary:   Result := (Result +  7) and not PtrUInt(7);
    rileWordBoundary:   Result := (Result + 15) and not PtrUInt(15);
    rileDWordBoundary:  Result := (Result + 31) and not PtrUInt(31);
    rileQWordBoundary:  Result := (Result + 63) and not PtrUInt(63);
    rileDQWordBoundary: Result := (Result +127) and not PtrUInt(127);
  end;
end;

{------------------------------------------------------------------------------
  Function: RawImage_ReadBits
 ------------------------------------------------------------------------------}
 
procedure RawImage_ReadBits(AData: PByte; const APosition: TRawImagePosition;
                       ABitsPerPixel, APrec, AShift: Byte;
                       ABitOrder: TRawImageBitOrder; out ABits: Word);
var
  PB: PByte;
  PW: PWord  absolute PB;
  PC: PCardinal absolute PB;
  PrecMask: Word;
begin
  PrecMask := (Word(1) shl APrec) - 1;
  PB := @AData[APosition.Byte];
  case ABitsPerPixel of
  1,2,4:
      begin
        if ABitOrder = riboBitsInOrder then
          ABits := (PB^ shr (AShift + APosition.Bit)) and PrecMask
        else
          ABits := (PB^ shr (AShift + 7 - APosition.Bit)) and PrecMask;
      end;
  8:  begin
        ABits := (PB^ shr AShift) and PrecMask;
      end;
  16: begin
        {$note check endian and/or source byte order}
        ABits := (PW^ shr AShift) and PrecMask;
      end;
  32: begin
        {$note check endian and/or source byte order}
        ABits := (PC^ shr AShift) and PrecMask;
      end;
  else
    ABits:=0;
  end;

  if APrec<16
  then begin
    // add missing bits
    ABits := ABits shl (16 - APrec);
    ABits := ABits or MissingBits[APrec, ABits shr 13];
  end;
end;

{------------------------------------------------------------------------------
  Function: RawImage_WriteBits
 ------------------------------------------------------------------------------}

procedure RawImage_WriteBits(AData: PByte; const APosition: TRawImagePosition;
                       ABitsPerPixel, APrec, AShift: Byte;
                       ABitOrder: TRawImageBitOrder; ABits: Word);
var
  PB: PByte;
  PW: PWord absolute PB;
  PC: PCardinal absolute PB;
  PrecMask: Cardinal;
  BitShift: Integer;
begin
  PB := @AData[APosition.Byte];
  PrecMask := (Cardinal(1) shl APrec) - 1;
  ABits := ABits shr (16 - APrec);

  case ABitsPerPixel of
  1,2,4:
      begin
        if ABitOrder = riboBitsInOrder
        then BitShift := AShift + APosition.Bit
        else BitShift := AShift + 7 - APosition.Bit;

        PrecMask := not(PrecMask shl BitShift);
        PB^ := (PB^ and PrecMask) or (ABits shl BitShift);
      end;
  8:  begin
        PrecMask := not(PrecMask shl aShift);
        PB^ := (PB^ and PrecMask) or (ABits shl AShift);
      end;
  16: begin
        {$note check endian and/or source byte order}
        PrecMask := not(PrecMask shl AShift);
        PW^ := (PW^ and PrecMask) or (ABits shl AShift);
      end;
  32: begin
        {$note check endian and/or source byte order}
        PrecMask := not(PrecMask shl AShift);
        PC^ := (PC^ and PrecMask) or (ABits shl AShift);
      end;
  end;
end;

{------------------------------------------------------------------------------
  Function: IntersectRect
  Params:  var DestRect: TRect; const SrcRect1, SrcRect2: TRect
  Returns: Boolean

  Intersects SrcRect1 and SrcRect2 into DestRect.
  Intersecting means that DestRect will be the overlapping area of SrcRect1 and
  SrcRect2. If SrcRect1 and SrcRect2 do not overlapp the Result is false, else
  true.
 ------------------------------------------------------------------------------}
function IntersectRect(var DestRect: TRect;
  const SrcRect1, SrcRect2: TRect): Boolean;
begin
  Result := False;

  // test if rectangles intersects
  Result:=(SrcRect2.Left < SrcRect1.Right)
      and (SrcRect2.Right > SrcRect1.Left)
      and (SrcRect2.Top < SrcRect1.Bottom)
      and (SrcRect2.Bottom > SrcRect1.Top);

  if Result then begin
    DestRect.Left:=Max(SrcRect1.Left,SrcRect2.Left);
    DestRect.Top:=Max(SrcRect1.Top,SrcRect2.Top);
    DestRect.Right:=Min(SrcRect1.Right,SrcRect2.Right);
    DestRect.Bottom:=Min(SrcRect1.Bottom,SrcRect2.Bottom);
  end else begin
    FillChar(DestRect,SizeOf(DestRect),0);
  end;
end;

{ TRawImageDescription }

procedure TRawImageDescription.Init;
begin
  FillChar(Self, SizeOf(Self), 0);
end;

procedure TRawImageDescription.Init_BPP24_B8G8R8_BIO_TTB(AWidth, AHeight: integer);
{ pf24bit:

 Format=ricfRGBA HasPalette=false Depth=24 PaletteColorCount=0
 BitOrder=riboBitsInOrder ByteOrder=DefaultByteOrder
 LineOrder=riloTopToBottom
 BitsPerPixel=24 LineEnd=rileDWordBoundary
 RedPrec=8 RedShift=16 GreenPrec=8 GreenShift=8 BluePrec=8 BlueShift=0
}
begin
  // setup an artificial ScanLineImage with format RGB 24 bit, 24bit depth format
  FillChar(Self, SizeOf(Self), 0);

  Format := ricfRGBA;
  Depth := 24; // used bits per pixel
  Width := AWidth;
  Height := AHeight;
  BitOrder := riboBitsInOrder;
  ByteOrder := riboLSBFirst;
  LineOrder := riloTopToBottom;
  BitsPerPixel := 24; // bits per pixel. can be greater than Depth.
  LineEnd := rileDWordBoundary;
  RedPrec := 8; // red precision. bits for red
  RedShift := 16;
  GreenPrec := 8;
  GreenShift := 8; // bitshift. Direction: from least to most significant
  BluePrec := 8;
//  BlueShift:=0;
//  AlphaPrec:=0;
//  MaskBitsPerPixel:=0;
end;

procedure TRawImageDescription.Init_BPP24_B8G8R8_M1_BIO_TTB(AWidth, AHeight: integer);
{ pf24bit:

 Format=ricfRGBA HasPalette=false Depth=24 PaletteColorCount=0
 BitOrder=riboBitsInOrder ByteOrder=DefaultByteOrder
 LineOrder=riloTopToBottom
 BitsPerPixel=24 LineEnd=rileDWordBoundary
 RedPrec=8 RedShift=16 GreenPrec=8 GreenShift=8 BluePrec=8 BlueShift=0
 Masked
}
begin
  // setup an artificial ScanLineImage with format RGB 24 bit, 24bit depth format
  FillChar(Self, SizeOf(Self), 0);

  Format := ricfRGBA;
  Depth := 24; // used bits per pixel
  Width := AWidth;
  Height := AHeight;
  BitOrder := riboBitsInOrder;
  ByteOrder := riboLSBFirst;
  LineOrder := riloTopToBottom;
  BitsPerPixel := 24; // bits per pixel. can be greater than Depth.
  LineEnd := rileDWordBoundary;
  RedPrec := 8; // red precision. bits for red
  RedShift := 16;
  GreenPrec := 8;
  GreenShift := 8; // bitshift. Direction: from least to most significant
  BluePrec := 8;
//  BlueShift := 0;
//  AlphaPrec := 0;
  MaskBitsPerPixel := 1;
  MaskBitOrder := riboBitsInOrder;
//  MaskShift := 0;        // the shift (=position) of the mask bit
  MaskLineEnd := rileWordBoundary;
end;

procedure TRawImageDescription.Init_BPP32_B8G8R8_BIO_TTB(AWidth, AHeight: integer);
{ pf32bit:

 Format=ricfRGBA HasPalette=false Depth=24 PaletteColorCount=0
 BitOrder=riboBitsInOrder ByteOrder=DefaultByteOrder
 LineOrder=riloTopToBottom
 BitsPerPixel=32 LineEnd=rileDWordBoundary
 RedPrec=8 RedShift=16 GreenPrec=8 GreenShift=8 BluePrec=8 BlueShift=0
 No alpha
 No mask
}
begin
  // setup an artificial ScanLineImage with format RGB 24 bit, 32bit depth format
  FillChar(Self, SizeOf(Self), 0);

  Format := ricfRGBA;
  Depth := 24; // used bits per pixel
  Width := AWidth;
  Height := AHeight;
  BitOrder := riboBitsInOrder;
  ByteOrder := riboLSBFirst;
  LineOrder := riloTopToBottom;
  BitsPerPixel := 32; // bits per pixel. can be greater than Depth.
  LineEnd := rileDWordBoundary;
  RedPrec := 8; // red precision. bits for red
  RedShift := 16;
  GreenPrec := 8;
  GreenShift := 8; // bitshift. Direction: from least to most signifikant
  BluePrec := 8;
//  BlueShift := 0;
//  AlphaPrec := 0;
//  MaskBitsPerPixel:=0;
end;

procedure TRawImageDescription.Init_BPP32_B8G8R8_M1_BIO_TTB(AWidth, AHeight: integer);
{ pf32bit:

 Format=ricfRGBA HasPalette=false Depth=24 PaletteColorCount=0
 BitOrder=riboBitsInOrder ByteOrder=DefaultByteOrder
 LineOrder=riloTopToBottom
 BitsPerPixel=32 LineEnd=rileDWordBoundary
 RedPrec=8 RedShift=16 GreenPrec=8 GreenShift=8 BluePrec=8 BlueShift=0
 no alpha
 with mask
}
begin
  // setup an artificial ScanLineImage with format RGB 24 bit, 32bit depth format
  FillChar(Self, SizeOf(Self), 0);

  Format := ricfRGBA;
  Depth := 24; // used bits per pixel
  Width := AWidth;
  Height := AHeight;
  BitOrder := riboBitsInOrder;
  ByteOrder := riboLSBFirst;
  LineOrder := riloTopToBottom;
  BitsPerPixel := 32; // bits per pixel. can be greater than Depth.
  LineEnd := rileDWordBoundary;
  RedPrec := 8; // red precision. bits for red
  RedShift := 16;
  GreenPrec := 8;
  GreenShift := 8; // bitshift. Direction: from least to most signifikant
  BluePrec := 8;
//  BlueShift := 0;
//  AlphaPrec := 0;
  MaskBitsPerPixel := 1;
  MaskBitOrder := riboBitsInOrder;
//  MaskShift := 0;        // the shift (=position) of the mask bit
  MaskLineEnd := rileWordBoundary;
end;

function TRawImageDescription.MaskBitsPerLine: PtrUInt;
begin
  Result := GetBitsPerLine(Width, MaskBitsPerPixel, MaskLineEnd);
end;

function TRawImageDescription.MaskBytesPerLine: PtrUInt;
begin
  Result := (GetBitsPerLine(Width, MaskBitsPerPixel, MaskLineEnd) + 7) shr 3;
end;

procedure TRawImageDescription.Init_BPP32_B8G8R8A8_BIO_TTB(AWidth, AHeight: integer);
{ pf32bit:

 Format=ricfRGBA HasPalette=false Depth=32 PaletteColorCount=0
 BitOrder=riboBitsInOrder ByteOrder=DefaultByteOrder
 LineOrder=riloTopToBottom
 BitsPerPixel=32 LineEnd=rileDWordBoundary
 RedPrec=8 RedShift=16 GreenPrec=8 GreenShift=8 BluePrec=8 BlueShift=0
 alpha
 no mask
}
begin
  // setup an artificial ScanLineImage with format RGB 32 bit, 32bit depth format
  FillChar(Self, SizeOf(Self), 0);

  Format := ricfRGBA;
  Depth := 32; // used bits per pixel
  Width := AWidth;
  Height := AHeight;
  BitOrder := riboBitsInOrder;
  ByteOrder := riboLSBFirst;
  LineOrder := riloTopToBottom;
  BitsPerPixel := 32; // bits per pixel. can be greater than Depth.
  LineEnd := rileDWordBoundary;
  RedPrec := 8; // red precision. bits for red
  RedShift := 16;
  GreenPrec := 8;
  GreenShift := 8; // bitshift. Direction: from least to most signifikant
  BluePrec := 8;
  BlueShift := 0;
  AlphaPrec := 8;
  AlphaShift := 24;
//  MaskBitsPerPixel := 0;
end;

procedure TRawImageDescription.Init_BPP32_B8G8R8A8_M1_BIO_TTB(AWidth, AHeight: integer);
begin
  Init_BPP32_B8G8R8A8_BIO_TTB(Width, Height);

  MaskBitsPerPixel := 1;
  MaskBitOrder := riboBitsInOrder;
  MaskLineEnd := rileWordBoundary;
end;


function TRawImageDescription.GetDescriptionFromMask: TRawImageDescription;
begin
  Result.Init;

  Result.Format       := ricfGray;
  Result.Width        := Width;
  Result.Height       := Height;
  Result.Depth        := 1; // per def
  Result.BitOrder     := MaskBitOrder;
  Result.ByteOrder    := DefaultByteOrder;
  Result.LineOrder    := LineOrder;
  Result.LineEnd      := MaskLineEnd;
  Result.BitsPerPixel := MaskBitsPerPixel;
  Result.RedPrec      := 1;
  Result.RedShift     := MaskShift;
end;

function TRawImageDescription.BitsPerLine: PtrUInt;
begin
  Result := GetBitsPerLine(Width, BitsPerPixel, LineEnd);
end;

function TRawImageDescription.BytesPerLine: PtrUInt;
begin
  Result := (GetBitsPerLine(Width, BitsPerPixel, LineEnd) + 7) shr 3;
end;

function TRawImageDescription.GetDescriptionFromAlpha: TRawImageDescription;
begin
  Result.Init;

  Result.Format       := ricfGray;
  Result.Width        := Width;
  Result.Height       := Height;
  Result.Depth        := AlphaPrec;
  Result.BitOrder     := BitOrder;
  Result.ByteOrder    := ByteOrder;
  Result.LineOrder    := LineOrder;
  Result.LineEnd      := LineEnd;
  Result.BitsPerPixel := BitsPerPixel;
  Result.RedPrec      := AlphaPrec;
  Result.RedShift     := AlphaShift;
end;

function TRawImageDescription.AsString: string;

  function BoolStr(b: boolean): string;
  begin
    if b then
      Result:='true'
    else
      Result:='false';
  end;

begin
  Result:=
     ' Format='+RawImageColorFormatNames[Format]
    +' HasPalette->'+BoolStr(PaletteColorCount <> 0)
    +' HasMask->'+BoolStr(PaletteColorCount <> 0)
    +' Depth='+IntToStr(Depth)
    +' Width='+IntToStr(Width)
    +' Height='+IntToStr(Height)
    +' BitOrder='+RawImageBitOrderNames[BitOrder]
    +' ByteOrder='+RawImageByteOrderNames[ByteOrder]
    +' LineOrder='+RawImageLineOrderNames[LineOrder]
    +' LineEnd='+RawImageLineEndNames[LineEnd]
    +' BitsPerPixel='+IntToStr(BitsPerPixel)
    +' BytesPerLine->'+IntToStr(GetBytesPerLine(Width,BitsPerPixel,LineEnd))
    +' RedPrec='+IntToStr(RedPrec)
    +' RedShift='+IntToStr(RedShift)
    +' GreenPrec='+IntToStr(GreenPrec)
    +' GreenShift='+IntToStr(GreenShift)
    +' BluePrec='+IntToStr(BluePrec)
    +' BlueShift='+IntToStr(BlueShift)
    +' AlphaPrec='+IntToStr(AlphaPrec)
    +' AlphaShift='+IntToStr(AlphaShift)
    +' ~~~mask~~~'
    +' MaskBitsPerPixel='+IntToStr(MaskBitsPerPixel)
    +' MaskShift='+IntToStr(MaskShift)
    +' MaskLineEnd='+RawImageLineEndNames[MaskLineEnd]
    +' MaskBitOrder='+RawImageBitOrderNames[MaskBitOrder]
    +' MaskBytesPerLine->'+IntToStr(GetBytesPerLine(Width,MaskBitsPerPixel,MaskLineEnd))
    +' ~~~palette~~~'
    +' PaletteColorCount='+IntToStr(PaletteColorCount)
    +' PaletteBitsPerIndex='+IntToStr(PaletteBitsPerIndex)
    +' PaletteShift='+IntToStr(PaletteShift)
    +' PaletteLineEnd='+RawImageLineEndNames[PaletteLineEnd]
    +' PaletteBitOrder='+RawImageBitOrderNames[PaletteBitOrder]
    +' PaletteByteOrder='+RawImageByteOrderNames[PaletteByteOrder]
    +' PaletteBytesPerLine->'+IntToStr(GetBytesPerLine(Width,PaletteBitsPerIndex,PaletteLineEnd))
    +'';
end;

function TRawImageDescription.IsEqual(ADescription: TRawImageDescription): Boolean;
begin
  Result := CompareMem(@Self, @ADescription, SizeOf(Self));
end;


{ TRawImage }

function TRawImage.IsMasked(ATestPixels: Boolean): Boolean;

  function CheckMask: boolean;
  var
    Width: cardinal;
    Height: cardinal;
    UsedBitsPerLine: cardinal;
    TotalBits: Cardinal;
    TotalBitsPerLine: cardinal;
    TotalBytesPerLine: cardinal;
    UnusedBitsAtEnd: Byte;
    UnusedBytesAtEnd: Byte;
    P: PCardinal;
    LinePtr: PByte;
    x, y, xEnd: Integer;
    EndMask: Cardinal; // No mask bits should be set. The Cardinal at line end
                       // can contain some unused bits. This mask AND cardinal
                       // at line end makes the unsused bits all 0.

    procedure CreateEndMask;
    begin
      if Description.MaskBitOrder = riboBitsInOrder
      then EndMask := ($FF shr UnusedBitsAtEnd)
      else EndMask := ($FF shl UnusedBitsAtEnd) and $FF;
      // add unused bytes
      {$ifdef endian_big}
      // read in memory -> [??][eM][uu][uu]
      EndMask := ($FFFFFF00 or EndMask) shl (UnusedBytesAtEnd shl 3);
      {$else}
      // read in memory -> [uu][uu][eM][??]
      EndMask := ((EndMask shl 24) or $00FFFFFF) shr (UnusedBytesAtEnd shl 3);
      {$endif}
    end;
    
    // separate dump procs to avoid code flow cluttering
    // added here in case somone want to debug
    {$IFDEF VerboseRawImage}
    procedure DumpFull;
    begin
      DebugLn('RawImageMaskIsEmpty FullByte y=',dbgs(y),' x=',dbgs(x),' Byte=',DbgS(p^));
    end;

    procedure DumpEdge;
    begin
      DebugLn('RawImageMaskIsEmpty EdgeByte y=',dbgs(y),' x=',dbgs(x),
        ' Byte=',HexStr(Cardinal(p^),2),
        //' UnusedMask=',HexStr(Cardinal(UnusedMask),2),
        //' OR='+dbgs(p^ or UnusedMask),
        ' UnusedBitsAtEnd='+dbgs(UnusedBitsAtEnd),
        ' UsedBitsPerLine='+dbgs(UsedBitsPerLine),
        ' Width='+dbgs(Width),
        ' ARawImage.Description.MaskBitsPerPixel='+dbgs(Description.MaskBitsPerPixel));
    end;
    {$endif}

  begin
    Result := True;
    
    Width := Description.Width;
    Height := Description.Height;

    TotalBitsPerLine := GetBitsPerLine(Width, Description.MaskBitsPerPixel, Description.MaskLineEnd);
    TotalBits := Height * TotalBitsPerLine;
    if MaskSize < PtrUInt((TotalBits + 7) shr 3)
    then raise Exception.Create('RawImage_IsMasked - Invalid MaskSize');

    UsedBitsPerLine := Width * Description.MaskBitsPerPixel;
    UnusedBitsAtEnd := TotalBitsPerLine - UsedBitsPerLine;

    if UnusedBitsAtEnd = 0
    then begin
      // the next line follows the previous one, so we can compare the whole
      // memblock in one go

      P := PCardinal(Mask);
      for x := 1 to TotalBits shr 5 do
      begin
        if p^ <> 0 then Exit;
        Inc(p);
      end;

      // redefine UnusedBitsAtEnd as the bits at the end of the block
      UnusedBitsAtEnd := TotalBits and $1F;
      if UnusedBitsAtEnd <> 0
      then begin
        // check last piece
        UnusedBytesAtEnd := UnusedBitsAtEnd shr 3;
        // adjust to byte bounds
        UnusedBitsAtEnd := UnusedBitsAtEnd and 7;
        CreateEndMask;

        if p^ and EndMask <> 0 then Exit;
      end;
    end
    else begin
      // scan each line
      TotalBytesPerLine := TotalBitsPerLine shr 3;
      UnusedBytesAtEnd := UnusedBitsAtEnd shr 3;

      // Number of cardinals to check
      xEnd := (TotalBytesPerLine - UnusedBytesAtEnd) shr 2;
      
      // Adjust unused to only the last checked
      UnusedBytesAtEnd := UnusedBytesAtEnd and 3;
      UnusedBitsAtEnd := UnusedBitsAtEnd and 7;

      // create mask for the last bits
      CreateEndMask;

      LinePtr := Mask;
      for y := 0 to Height - 1 do
      begin
        p := PCardinal(LinePtr);
        for x := 0 to xEnd - 1 do
        begin
          if p^ <> 0 then Exit;
          Inc(p);
        end;
        // check last end
        if (EndMask <> 0) and (p^ and EndMask <> 0) then Exit;

        Inc(LinePtr, TotalBytesPerLine);
      end;
    end;
    Result := False;
  end;
  
begin
  Result := False;
  //DebugLn('RawImageMaskIsEmpty Quicktest: empty ',dbgs(RawImage^.Description.Width),'x',dbgs(RawImage^.Description.Height));

  // quick test
  if (Mask = nil)
  or (MaskSize = 0)
  or (Description.MaskBitsPerPixel = 0)
  or (Description.Width = 0)
  or (Description.Height = 0)
  then begin
    {$IFDEF VerboseRawImage}
    DebugLn('RawImageMaskIsEmpty Quicktest: empty');
    {$ENDIF}
    exit;
  end;

  if ATestPixels
  then begin
    Result := CheckMask;

    {$IFDEF VerboseRawImage}
    DebugLn('RawImageMaskIsEmpty Empty=',dbgs(not Result));
    {$ENDIF}
  end
  else begin
    Result := True;
    {$IFDEF VerboseRawImage}
    DebugLn('RawImageMaskIsEmpty NoPixelTest: not empty');
    {$ENDIF}
    Exit;
  end;
end;

function TRawImage.IsTransparent(ATestPixels: Boolean): Boolean;
  function CheckAlpha: Boolean;
  begin
    {$note TODO: implement CheckAlpha}
    Result := True;
  end;
begin
  Result :=
    (Data <> nil) and
    (DataSize <> 0) and
    (Description.AlphaPrec <> 0) and
    (Description.Width = 0) and
    (Description.Height = 0);

  if Result and ATestPixels then
    Result := CheckAlpha;
end;

function TRawImage.ReadBits(const APosition: TRawImagePosition; APrec, AShift: Byte): Word;
begin
  RawImage_ReadBits(Data, APosition, Description.BitsPerPixel, APrec, AShift, Description.BitOrder, Result);
end;

procedure TRawImage.ReadChannels(const APosition: TRawImagePosition; out ARed, AGreen, ABlue, AAlpha: Word);
var
  D: TRawImageDescription absolute Description;
begin
  case Description.Format of
    ricfRGBA: begin
      RawImage_ReadBits(Data, APosition, D.BitsPerPixel, D.RedPrec, D.RedShift, D.BitOrder, ARed);
      RawImage_ReadBits(Data, APosition, D.BitsPerPixel, D.GreenPrec, D.GreenShift, D.BitOrder, AGreen);
      RawImage_ReadBits(Data, APosition, D.BitsPerPixel, D.BluePrec, D.BlueShift, D.BitOrder, ABlue);
    end;

    ricfGray: begin
      RawImage_ReadBits(Data, APosition, D.BitsPerPixel, D.RedPrec, D.RedShift, D.BitOrder, ARed);
      AGreen := ARed;
      ABlue := ARed;
    end;

  else
    ARed := 0;
    AGreen := 0;
    ABlue := 0;
    AAlpha := 0;
    Exit;
  end;
  
  if D.AlphaPrec > 0
  then RawImage_ReadBits(Data, APosition, D.BitsPerPixel, D.AlphaPrec, D.AlphaShift, D.BitOrder, AAlpha)
  else AAlpha := High(AAlpha);
end;

procedure TRawImage.ReadMask(const APosition: TRawImagePosition; out AMask: Boolean);
var
  D: TRawImageDescription absolute Description;
  M: Word;
begin
  if (D.MaskBitsPerPixel > 0) and (Mask <> nil)
  then begin
    RawImage_ReadBits(Mask, APosition, D.MaskBitsPerPixel, 1, D.MaskShift, D.MaskBitOrder, M);
    AMask := M <> 0;
  end
  else AMask := False;
end;

procedure TRawImage.FreeData;
begin
  FreeMem(Data);
  Data := nil;
  DataSize:=0;

  FreeMem(Mask);
  Mask := nil;
  MaskSize := 0;
  
  FreeMem(Palette);
  Palette := nil;
  PaletteSize:=0;
end;

procedure TRawImage.Init;
begin
  Description.Init;
  Data := nil;
  DataSize:=0;
  Mask := nil;
  MaskSize := 0;
  Palette := nil;
  PaletteSize:=0;
end;

function TRawImage.IsEqual(AImage: TRawImage): Boolean;
begin
  //Result := CompareMem(@Self, @AImage, SizeOf(Self));
  Result :=
    Description.IsEqual(AImage.Description) and
    (DataSize = AImage.DataSize) and
    (MaskSize = AImage.MaskSize) and
    (PaletteSize = AImage.PaletteSize);

  if Result then
    Result := Result and CompareMem(Data, AImage.Data, DataSize);
  if Result then
    Result := Result and CompareMem(Mask, AImage.Mask, MaskSize);
  if Result then
    Result := Result and CompareMem(Palette, AImage.Palette, PaletteSize);
end;

procedure TRawImage.ReleaseData;
begin
  Data := nil;
  DataSize := 0;
  Mask := nil;
  MaskSize := 0;
  Palette := nil;
  PaletteSize := 0;
end;

procedure TRawImage.WriteBits(const APosition: TRawImagePosition; APrec, AShift: Byte; ABits: Word);
begin
  RawImage_WriteBits(Data, APosition, Description.BitsPerPixel, APrec, AShift, Description.BitOrder, ABits);
end;

procedure TRawImage.WriteChannels(const APosition: TRawImagePosition; ARed, AGreen, ABlue, AAlpha: Word);
var
  D: TRawImageDescription absolute Description;
begin
  case D.Format of
    ricfRGBA: begin
      RawImage_WriteBits(Data, APosition, D.BitsPerPixel, D.RedPrec, D.RedShift, D.BitOrder, ARed);
      RawImage_WriteBits(Data, APosition, D.BitsPerPixel, D.GreenPrec, D.GreenShift, D.BitOrder, AGreen);
      RawImage_WriteBits(Data, APosition, D.BitsPerPixel, D.BluePrec, D.BlueShift, D.BitOrder, ABlue);
    end;

    ricfGray: begin
      RawImage_WriteBits(Data, APosition, D.BitsPerPixel, D.RedPrec, D.RedShift, D.BitOrder, ARed);
    end;
  else
    Exit;
  end;

  if D.AlphaPrec = 0 then Exit;

  RawImage_WriteBits(Data, APosition, D.BitsPerPixel, D.AlphaPrec, D.AlphaShift, D.BitOrder, AAlpha);
end;

procedure TRawImage.WriteMask(const APosition: TRawImagePosition; AMask: Boolean);
const
  M: array[Boolean] of Word = (0, $FFFF);
var
  D: TRawImageDescription absolute Description;
begin
  if Mask = nil then Exit;
  if D.MaskBitsPerPixel = 0 then Exit;
  RawImage_WriteBits(Mask, APosition, D.MaskBitsPerPixel, 1, D.MaskShift, D.MaskBitOrder, M[AMask]);
end;

procedure TRawImage.CreateData(AZeroMem: Boolean);
var
  Size: QWord;
begin
  // get current size
  if Description.Width = 0 then Exit;
  if Description.Height = 0 then Exit;

  // calculate size
  with Description do
    Size := GetBitsPerLine(Width, BitsPerPixel, LineEnd);
  Size := (Size * Description.Height) shr 3;
  
  if Size < High(DataSize)
  then DataSize := Size
  else DataSize := High(DataSize);

  ReAllocMem(Data, DataSize);

  if AZeroMem
  then FillChar(Data^, DataSize, 0);
  
  // Setup mask if needed
  if Description.MaskBitsPerPixel = 0 then Exit;
  
  // calculate mask size
  with Description do
    Size := GetBitsPerLine(Width, MaskBitsPerPixel, MaskLineEnd);
  Size := (Size * Description.Height) shr 3;

  if Size < High(MaskSize)
  then MaskSize := Size
  else MaskSize := High(MaskSize);

  ReAllocMem(Mask, MaskSize);

  if AZeroMem
  then FillChar(Mask^, MaskSize, 0);
end;

procedure TRawImage.ExtractRect(const ARect: TRect; out ADst: TRawImage);
  procedure ExtractData(AData: PByte; ADataSize: PtrUInt; ABitsPerPixel: Byte;
                        ABitOrder: TRawImageBitOrder; ALineEnd: TRawImageLineEnd;
                        ADest: PByte; ADestSize: PtrUInt);
  var
    SrcWidth, SrcHeight: cardinal;
    DstWidth, DstHeight: cardinal;
    x, y: Integer;
    LineOrder: TRawImageLineOrder;
    SrcLineStarts, DstLineStarts: TRawImageLineStarts;
    SrcStartPos, SrcEndPos, DstStartPos: TRawImagePosition;
    Shift0, Shift1: Byte;
    SrcPos: PByte;
    DstPos: PByte;
    ByteCount: PtrUInt;
  begin
    SrcWidth := Description.Width;
    DstWidth := ADst.Description.Width;
    LineOrder := Description.LineOrder;

    //DebugLn'ExtractRawImageDataRect data=',DbgS(DestData),' Size=',DestDataSize);
    if SrcWidth = DstWidth
    then begin
      if LineOrder = riloTopToBottom
      then // copy whole source from beginning
        System.Move(AData[0], ADest[0], ADestSize)
      else // copy remainder
        System.Move(AData[ADataSize - ADestSize], ADest[0], ADestSize);
      Exit;
    end;
    
    SrcHeight := Description.Height;
    DstHeight := ADst.Description.Height;

    // calculate line starts
    if LineOrder = riloTopToBottom
    then // we only need the first part from start
      SrcLineStarts.Init(SrcWidth, ARect.Top + DstHeight, ABitsPerPixel, ALineEnd, LineOrder)
    else
      SrcLineStarts.Init(SrcWidth, SrcHeight - ARect.Top, ABitsPerPixel, ALineEnd, LineOrder);
    DstLineStarts.Init(DstWidth, DstHeight, ABitsPerPixel, ALineEnd, LineOrder);

    // copy
    for y := 0 to DstHeight - 1 do
    begin
      SrcStartPos := SrcLineStarts.GetPosition(ARect.Left, y + ARect.Top);
      SrcEndPos   := SrcLineStarts.GetPosition(ARect.Right, y + ARect.Top);
      DstStartPos := DstLineStarts.GetPosition(0, y);
      
      //DebugLn'ExtractRawImageDataRect A y=',y,' SrcByte=',SrcLineStartPosition.Byte,' SrcBit=',SrcLineStartPosition.Bit,
      //' DestByte=',DestLineStartPosition.Byte,' DestBit=',DestLineStartPosition.Bit);

      if  (SrcStartPos.Bit = 0) and (DstStartPos.Bit = 0)
      then begin
        // copy bytes
        ByteCount := SrcEndPos.Byte - SrcStartPos.Byte;
        if SrcEndPos.Bit > 0
        then Inc(ByteCount);
          
        //DebugLn'ExtractRawImageDataRect B ByteCount=',ByteCount);
        System.Move(AData[SrcStartPos.Byte], ADest[DstStartPos.Byte], ByteCount);
      end
      else if DstStartPos.Bit = 0
      then begin
        // copy and move bits
        ByteCount := (DstWidth * ABitsPerPixel + 7) shr 3;
        SrcPos := @AData[SrcStartPos.Byte];
        DstPos := @ADest[DstStartPos.Byte];
        Shift0 := SrcStartPos.Bit;
        Shift1 := 8 - Shift0;

        if ABitOrder = riboBitsInOrder
        then begin
          // src[byte|bit]: 07 06 05 04 03 02 01 00 :: 17 16 15 14 13 12 11 10 :
          // imagine startbit = 3 ->
          // dst[byte|bit]: 12 11 10 07 06 05 04 03 :
          for x := 0 to ByteCount - 1 do
          begin
            DstPos^ := (SrcPos[0] shr Shift0) or (SrcPos[1] shl Shift1);
            inc(SrcPos);
            inc(DstPos);
          end;
        end
        else begin
          // src[byte|bit]: 07 06 05 04 03 02 01 00 :: 17 16 15 14 13 12 11 10 :
          // imagine startbit = 3 ->
          // dst[byte|bit]: 04 03 02 01 00 17 16 15 :
          for x := 0 to ByteCount - 1 do
          begin
            DstPos^ := (SrcPos[0] shl Shift0) or (SrcPos[1] shr Shift1);
            inc(SrcPos);
            inc(DstPos);
          end;
        end;
      end
      else begin
        DebugLn('ToDo: ExtractRawImageRect DestLineStartPosition.Bit>0');
        break;
      end;
    end;
  end;

var
  R: TRect;
begin
  //DebugLn'ExtractRawImageRect SrcRawImage=',RawImageDescriptionAsString(@SrcRawImage^.Description),
  //  ' SrcRect=',SrcRect.Left,',',SrcRect.Top,',',SrcRect.Right,',',SrcRect.Bottom);

  // copy description
  ADst.Description := Description;
  ADst.ReleaseData;

  // get intersection
  IntersectRect(R, Rect(0, 0, Description.Width, Description.Height), ARect);
  ADst.Description.Width := R.Right - R.Left;
  ADst.Description.Height := R.Bottom - R.Top;
  if (ADst.Description.Width <= 0)
  or (ADst.Description.Height <= 0)
  then begin
    ADst.Description.Width := 0;
    ADst.Description.Height := 0;
    Exit;
  end;
  
  // allocate some space
  ADst.CreateData(False);

  // extract rectangle from Data
  ExtractData(Data, DataSize, Description.BitsPerPixel, Description.BitOrder,
              Description.LineEnd, ADst.Data, ADst.DataSize);

  // extract rectangle from MAsk

  if Description.MaskBitsPerPixel = 0 then Exit;
  if Mask = nil then Exit;
  if MaskSize = 0 then Exit;


  //DebugLn'ExtractRawImageRect Mask SrcRawImage=',RawImageDescriptionAsString(@SrcMaskDesc));
  ExtractData(Mask, MaskSize, Description.MaskBitsPerPixel, Description.MaskBitOrder,
              Description.MaskLineEnd, ADst.Mask, ADst.MaskSize);
end;

{ TRawImageLineStarts }

function TRawImageLineStarts.GetPosition(x, y: cardinal): TRawImagePosition;
var
  BitOffset: Cardinal;
begin
  if FLineOrder = riloBottomToTop then
    y := FHeight - y;
  Result := Positions[y];
  BitOffset := x * FBitsPerPixel + Result.Bit;
  Result.Bit := BitOffset and 7;
  Inc(Result.Byte, BitOffset shr 3);
end;

procedure TRawImageLineStarts.Init(AWidth, AHeight: cardinal; ABitsPerPixel: Byte; ALineEnd: TRawImageLineEnd; ALineOrder: TRawImageLineOrder);
var
  PixelCount: cardinal;
  BitsPerLine: cardinal;
  CurLine: cardinal;
  BytesPerLine: cardinal;
  ExtraBitsPerLine: Byte;
  CurBitOffset: Byte;
  LoopBit: Byte;
  LoopByte: PtrUInt;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FBitsPerPixel := ABitsPerPixel;
  FLineEnd := ALineEnd;
  FLineOrder := ALineOrder;
  
  // get current size
  PixelCount := AWidth * AHeight;
  if PixelCount = 0 then exit;

  // calculate BitsPerLine, BytesPerLine and ExtraBitsPerLine
  BitsPerLine := GetBitsPerLine(AWidth, ABitsPerPixel, ALineEnd);
  BytesPerLine := BitsPerLine shr 3;
  ExtraBitsPerLine := BitsPerLine and 7;

  // create line start array
  SetLength(Positions, AHeight);

  Positions[0].Byte := 0;
  Positions[0].Bit := 0;
  LoopBit := 0;
  LoopByte := 0;
  for CurLine := 1 to AHeight-1 do
  begin
    CurBitOffset := LoopBit + ExtraBitsPerLine;
    LoopByte := LoopByte + BytesPerLine + (CurBitOffset shr 3);
    LoopBit := CurBitOffset and 7;
    Positions[CurLine].Byte := LoopByte;
    Positions[CurLine].Bit := LoopBit;
  end;
end;



{$ifdef OldRawImageProcs}
function RawImageMaskIsEmpty(RawImage: PRawImage; TestPixels: boolean): boolean;
begin
  Result := not RawImage^.IsMasked(TestPixels);
end;
{$endif}

{$ifdef OldRawImageProcs}
function RawImageDescriptionAsString(Desc: PRawImageDescription): string;
begin
  Result := Desc^.AsString;
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure FreeRawImageData(RawImage: PRawImage);
begin
  RawImage^.FreeData;
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure ReleaseRawImageData(RawImage: PRawImage);
begin
  RawImage^.ReleaseData;
end;
{$endif}

{-------------------------------------------------------------------------------
  Beware: Data is used in ReallocMem

-------------------------------------------------------------------------------}
{$ifdef OldRawImageProcs}
procedure CreateRawImageData(Width, Height, BitsPerPixel: cardinal;
  LineEnd: TRawImageLineEnd; var Data: Pointer; var DataSize: PtrUInt);
var
  PixelCount: PtrUInt;
  BitsPerLine: PtrUInt;
  DataBits: QWord;
begin
  // get current size
  PixelCount:=Width*Height;
  if PixelCount=0 then exit;

  // calculate BitsPerLine
  BitsPerLine:=GetBitsPerLine(Width,BitsPerPixel,LineEnd);

  // create pixels
  DataBits:=QWord(BitsPerLine)*Height;
  DataSize:=cardinal((DataBits+7) shr 3);
  ReAllocMem(Data,DataSize);
  FillChar(Data^,DataSize,0);
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure CreateRawImageDescFromMask(SrcRawImageDesc,
  DestRawImageDesc: PRawImageDescription);
begin
  // original code raises an exception, imo it is perfectly valid
  // to create a black image (MWE)
  if (SrcRawImageDesc^.MaskBitsPerPixel = 0) then
    RaiseGDBException('CreateRawImageFromMask Alpha not separate');

  DestRawImageDesc^ := SrcRawImageDesc^.GetDescriptionFromMask;
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure GetRawImageXYPosition(RawImageDesc: PRawImageDescription;
  LineStarts: PRawImagePosition; x, y: cardinal;
  var Position: TRawImagePosition);
var
  BitOffset: cardinal;
begin
  if RawImageDesc^.LineOrder=riloBottomToTop then
    y:=RawImageDesc^.Height-y;
  Position:=LineStarts[y];
  BitOffset:=RawImageDesc^.BitsPerPixel*cardinal(x)+Position.Bit;
  Position.Bit:=(BitOffset and 7);
  inc(Position.Byte,BitOffset shr 3);
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure ExtractRawImageRect(SrcRawImage: PRawImage; const SrcRect: TRect;
  DestRawImage: PRawImage);
begin
  SrcRawImage^.ExtractRect(SrcRect, DestRawImage^);
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure CreateRawImageLineStarts(Width, Height, BitsPerPixel: cardinal;
  LineEnd: TRawImageLineEnd; var LineStarts: PRawImagePosition);
// LineStarts is recreated, so make sure it is nil or a valid mem
var
  PixelCount: cardinal;
  BitsPerLine: cardinal;
  CurLine: cardinal;
  BytesPerLine: cardinal;
  ExtraBitsPerLine: cardinal;
  CurBitOffset: cardinal;
begin
  // get current size
  PixelCount:=Width*Height;
  if PixelCount=0 then exit;

  // calculate BitsPerLine, BytesPerLine and ExtraBitsPerLine
  BitsPerLine:=GetBitsPerLine(Width,BitsPerPixel,LineEnd);
  BytesPerLine:=BitsPerLine shr 3;
  ExtraBitsPerLine:=BitsPerLine and 7;

  // create line start array
  ReAllocMem(LineStarts,Height*SizeOf(TRawImagePosition));
  LineStarts[0].Byte:=0;
  LineStarts[0].Bit:=0;
  for CurLine:=1 to Height-1 do begin
    CurBitOffset:=LineStarts[CurLine-1].Bit+ExtraBitsPerLine;
    LineStarts[CurLine].Byte:=LineStarts[CurLine-1].Byte+BytesPerLine
                                 +(CurBitOffset shr 3);
    LineStarts[CurLine].Bit:=CurBitOffset and 7;
  end;
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure ReadRawImageBits(TheData: PByte;
  const Position: TRawImagePosition;
  BitsPerPixel, Prec, Shift: cardinal; BitOrder: TRawImageBitOrder;
  var Bits: word);
begin
  RawImage_ReadBits(TheData, Position, BitsPerPixel, Prec, Shift, BitOrder, Bits);
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure WriteRawImageBits(TheData: PByte;
  const Position: TRawImagePosition;
  BitsPerPixel, Prec, Shift: cardinal; BitOrder: TRawImageBitOrder; Bits: word);
begin
  RawImage_WriteBits(TheData, Position, BitsPerPixel, Prec, Shift, BitOrder, Bits);
end;
{$endif}

{$ifdef OldRawImageProcs}
procedure ReAlignRawImageLines(var Data: Pointer; var Size: PtrUInt;
  Width, Height, BitsPerPixel: cardinal;
  var OldLineEnd: TRawImageLineEnd; NewLineEnd: TRawImageLineEnd);
var
  OldBytesPerLine: PtrUInt;
  OldSize: PtrUInt;
  NewBytesPerLine: PtrUInt;
  NewSize: PtrUInt;
  y: Integer;
  OldPos: Pointer;
  NewPos: Pointer;
begin
  if OldLineEnd=NewLineEnd then exit;
  if (Width=0) or (Height=0) then exit;
  OldBytesPerLine:=GetBytesPerLine(Width,BitsPerPixel,OldLineEnd);
  OldSize:=OldBytesPerLine*PtrUInt(Height);
  if OldSize<>Size then
    RaiseGDBException('ReAlignRawImageLines OldSize<>Size');
  NewBytesPerLine:=GetBytesPerLine(Width,BitsPerPixel,NewLineEnd);
  NewSize:=NewBytesPerLine*PtrUInt(Height);
  //DebugLn(['ReAlignRawImageLines OldBytesPerLine=',OldBytesPerLine,' NewBytesPerLine=',NewBytesPerLine]);

  // enlarge before
  if OldSize<NewSize then
    ReAllocMem(Data,NewSize);

  // move data
  OldPos:=Data;
  NewPos:=Data;
  if OldBytesPerLine>NewBytesPerLine then begin
    // compress
    for y:=0 to Height-1 do begin
      System.Move(OldPos^,NewPos^,NewBytesPerLine);
      inc(OldPos,OldBytesPerLine);
      inc(NewPos,NewBytesPerLine);
    end;
  end else begin
    // expand
    inc(OldPos,OldSize);
    inc(NewPos,NewSize);
    for y:=Height-1 downto 0 do begin
      dec(OldPos,OldBytesPerLine);
      dec(NewPos,NewBytesPerLine);
      System.Move(OldPos^,NewPos^,OldBytesPerLine);
    end;
  end;

  // shrink after
  if OldSize>NewSize then
    ReAllocMem(Data,NewSize);

  Size:=NewSize;
  OldLineEnd:=NewLineEnd;
end;
{$endif}

//------------------------------------------------------------------------------
procedure InternalInit;
var
  Prec: Integer;
  HighValue: word;
  Bits: word;
  CurShift, DShift: Integer;
begin
  for Prec := 0 to 15 do
  begin
    for HighValue := 0 to 7 do
    begin
      // HighValue represents the three highest bits
      // For example:
      //   Prec=5 and the read value is %10110
      //   => HighValue=%101
      // copy the HighValue till all missing bits are set
      // For example:
      //   Prec=5, HighValue=%110
      // => MissingBits[5,6]:=%0000011011011011
      //   because 00000 110 110 110 11
      MissingBits[Prec, HighValue] := 0;
      if Prec = 0 then Continue;

      if Prec>=3 then begin
        DShift := 3;
        Bits := HighValue;
      end else begin
        DShift := Prec;
        Bits := HighValue shr (3-Prec);
      end;
      
      CurShift := 16 - Prec;
      while CurShift > 0 do
      begin
        //DebugLn(['InternalInit CurShift=',CurShift,' DShift=',DShift]);
        if CurShift >= DShift then
          MissingBits[Prec, HighValue] :=
            MissingBits[Prec, HighValue] or (Bits shl (CurShift - DShift))
        else
          MissingBits[Prec, HighValue] :=
            MissingBits[Prec, HighValue] or (Bits shr (DShift - CurShift));
        Dec(CurShift, DShift);
      end;
    end;
  end;
end;

initialization
  InternalInit;

end.