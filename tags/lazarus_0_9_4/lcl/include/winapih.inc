{%MainUnit ../lclintf.pp}
// included by interfacebase.pp and lclintf.pp

(******************************************************************************
  All Winapi related stuff goes here.
  This file is used by both LCLIntf.pas and InterfaceBase.pp
  If a procedure is platform dependent then it should have the following tail:
    {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
  If a procedure isn't platform dependent, it is no part of InterfaseBase and
  should be surrounded by:
    {$IFNDEF IF_BASE_MEMBER}
      procedure MyProc;
    {$ENDIF}

  !! Keep this alphabetical and place a pointer to the independent part
  !! if needed

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

 ******************************************************************************)

{******************************************************************************
  Platform specific stuff
                                                                             
  Note:
    the IFNDEF IF_BASE_MEMBER section is at the end
 ******************************************************************************}
//##apiwiz##sps##   // Do not remove

function Arc(DC: HDC; x,y,width,height,angle1,angle2 : Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function AngleChord(DC: HDC; x,y,width,height,angle1,angle2 : Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

Function BeginPaint(Handle : hwnd; var PS : TPaintStruct): hdc; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function BitBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Rop: DWORD): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function BringWindowToTop(hWnd : HWND): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function CallNextHookEx(hhk : HHOOK; ncode : Integer; WParam: WParam; LParam: LParam) : Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CallWindowProc(lpPrevWndFunc : TFarProc; Handle : HWND; Msg : UINT; WParam: WParam; LParam: LParam): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function CharLowerBuff --> independent
function ClienttoScreen(Handle : HWND; var P : TPoint) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CombineRgn(Dest, Src1, Src2 : HRGN; fnCombineMode : Longint) : Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateBitmap(Width, Height: Integer; Planes, BitCount: Longint; BitmapBits: Pointer): HBITMAP; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateBrushIndirect(const LogBrush: TLogBrush): HBRUSH; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateCaret(Handle: HWND; Bitmap: hBitmap; width, Height: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateCompatibleBitmap(DC: HDC; Width, Height: Integer): HBITMAP; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateCompatibleDC(DC: HDC): HDC; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateDIBitmap(DC: HDC; var InfoHeader: TBitmapInfoHeader;
  dwUsage: DWORD; InitBits: PChar; var InitInfo: TBitmapInfo;
  wUsage: UINT): HBITMAP; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateDIBSection(DC: HDC; const BitmapInfo: tagBitmapInfo; Usage: UINT;
  var Bits: Pointer; SectionHandle: THandle; Offset: DWORD): HBITMAP; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateEllipticRgn(p1, p2, p3, p4: Integer): HRGN; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function CreateEllipticRgnIndirect --> independent
//function CreateFont --> independent
function CreateFontIndirect(const LogFont: TLogFont): HFONT; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateFontIndirectEx(const LogFont: TLogFont; const LongFontName: string): HFONT; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreatePalette(const LogPalette: TLogPalette): HPalette; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function CreatePen --> independent
function CreatePenIndirect(const LogPen: TLogPen): HPEN; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreatePolygonRgn(Points: PPoint; NumPts: Integer; FillMode: integer): HRGN; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function CreateRectRgn(X1,Y1,X2,Y2 : Integer): HRGN; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function CreateRectRgnIndirect --> independent

procedure DeleteCriticalSection(var CritSection: TCriticalSection); {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DeleteDC(hDC: HDC): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DeleteObject(GDIObject: HGDIOBJ): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DestroyCaret(Handle : HWND): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DPtoLP(DC: HDC; var Points; Count: Integer): BOOL; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DrawFrameControl(DC: HDC; var Rect : TRect; uType, uState : Cardinal) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DrawEdge(DC: HDC; var Rect: TRect; edge: Cardinal; grfFlags: Cardinal): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function DrawText(DC: HDC; Str: PChar; Count: Integer; var Rect: TRect; Flags: Cardinal): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function EnableScrollBar(Wnd: HWND; wSBflags, wArrows: Cardinal): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function EnableWindow(hWnd: HWND; bEnable: Boolean): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function EndPaint(Handle : hwnd; var PS : TPaintStruct): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
procedure EnterCriticalSection(var CritSection: TCriticalSection); {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function Ellipse(DC: HDC; x1, y1, x2, y2: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function EqualRect --> independent
Function ExcludeClipRect(dc: hdc; Left, Top, Right, Bottom : Integer) : Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ExtTextOut(DC: HDC; X, Y: Integer; Options: Longint; Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ExtSelectClipRGN(dc: hdc; rgn : hrgn; Mode : Longint) : Integer;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function FillRect(DC: HDC; const Rect: TRect; Brush: HBRUSH): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function FillRgn(DC: HDC; RegionHnd: HRGN; hbr: HBRUSH): BOOL; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function FloodFill(DC: HDC; X, Y: Integer;
                   Color: TGraphicsColor;
                   FillStyle: TGraphicsFillStyle;
                   Brush: HBRUSH): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function FrameRect(DC: HDC; const ARect: TRect; hBr: HBRUSH): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

Function GetActiveWindow : HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetBitmapBits(Bitmap: HBITMAP; Count: Longint;  Bits: Pointer): Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetCapture : HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetCaretPos(var lpPoint: TPoint): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetClientRect(handle : HWND; var Rect: TRect) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetClipBox(DC : hDC; lpRect : PRect) : Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetClipRGN(DC : hDC; RGN : hRGN) : Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetCursorPos(var lpPoint: TPoint): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetCharABCWidths(DC: HDC; p2, p3: UINT; const ABCStructs): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF} //pbd
function GetDC(hWnd: HWND): HDC; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetDeviceCaps(DC: HDC; Index: Integer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetDIBits(DC: HDC; Bitmap: HBitmap; StartScan, NumScans: UINT; Bits: Pointer; var BitInfo: BitmapInfo; Usage: UINT): Integer;{$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetFocus: HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetFontLanguageInfo(DC: HDC): DWord; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetKeyState(nVirtKey: Integer): Smallint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetMapMode(DC: HDC): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetObject(GDIObject: HGDIOBJ; BufSize: Integer; Buf: Pointer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetPaletteEntries(Palette: HPALETTE; StartIndex, NumEntries: UINT;
  var PaletteEntries): UINT; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function GetParent(Handle : HWND): HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function GetProp(Handle : hwnd; Str : PChar): Pointer;{$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function GetRgnBox(RGN : HRGN; lpRect : PRect) : Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetScrollInfo(Handle: HWND; SBStyle: Integer; var ScrollInfo: TScrollInfo): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function GetScrollPos --> independent
//function GetScrollRange --> independent
function GetStockObject(Value: Integer): LongInt; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetSysColor(nIndex: Integer): DWORD; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetSystemPaletteEntries(DC: HDC; StartIndex, NumEntries: UINT;
  var PaletteEntries): UINT; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetSystemMetrics(nIndex: Integer): Integer;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetTextColor(DC: HDC) : TColorRef; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetTextExtentExPoint(DC: HDC; Str: PChar; Count, MaxWidth: Integer; MaxCount, PartialWidths: PInteger; var Size: TSize): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetTextExtentPoint(DC: HDC; Str: PChar; Count: Integer; var Size: LCLType.TSize): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetTextExtentPoint32(DC: HDC; Str: PChar; Count: Integer; var Size: LCLType.TSize): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetTextMetrics(DC: HDC; var TM: TTextMetric): Boolean;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetWindowLong(Handle : hwnd; int : Integer): Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetWindowRect(Handle : hwnd; var Rect : TRect): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetWindowSize(Handle : hwnd; var Width, Height: integer): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GetWindowOrgEx(dc : hdc; P : PPoint): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function GradientFill(DC: HDC; Vertices: PTriVertex; NumVertices : Longint;
  Meshes: Pointer; NumMeshes : Longint; Mode : Longint): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function HideCaret(hWnd: HWND): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

//function InflateRect --> independent
Procedure InitializeCriticalSection(var CritSection: TCriticalSection); {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function IntersectClipRect(dc: hdc; Left, Top, Right,Bottom: Integer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function IntersectRect --> independent
Function InvalidateRect(aHandle : HWND; ARect : pRect; bErase : Boolean) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function IsCharAlphaNumeric --> independent
function IsDBCSLeadByte(TestChar: Byte): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function IsRectEmpty --> independent
function IsWindowVisible(handle: HWND): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

Procedure LeaveCriticalSection(var CritSection: TCriticalSection); {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function LineTo(DC: HDC; X, Y: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function MaskBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Mask: HBITMAP; XMask, YMask: Integer; Rop: DWORD): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function MaskBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Mask: HBITMAP; XMask, YMask: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function MessageBox(hWnd: HWND; lpText, lpCaption: PChar; uType: Cardinal): integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function MoveToEx(DC: HDC; X, Y: Integer; OldPoint: PPoint): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

//function OffsetRect --> independent

function PeekMessage(var lpMsg : TMsg; Handle : HWND; wMsgFilterMin, wMsgFilterMax,wRemoveMsg : UINT): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function Pie(DC: HDC; EllipseX1,EllipseY1,EllipseX2,EllipseY2,
             StartX,StartY,EndX,EndY: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function PolyBezier(DC: HDC; Points: PPoint;  NumPts: Integer; Filled, Continuous: boolean): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function Polygon(DC: HDC; Points: PPoint;  NumPts: Integer; Winding: boolean): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function Polyline(DC: HDC; Points: PPoint; NumPts: Integer): boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function PostMessage(Handle: HWND; Msg: Cardinal; WParam: WParam; LParam: LParam): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function PtInRegion(RGN: HRGN; X, Y: Integer) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function PtInRect --> independent

function RealizePalette(DC: HDC): Cardinal; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function Rectangle(DC: HDC; X1, Y1, X2, Y2: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function RectVisible(dc : hdc; const ARect: TRect) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ReleaseCapture : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ReleaseDC(hWnd: HWND; DC: HDC): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function RestoreDC(DC: HDC; SavedDC: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function RoundRect(DC : hDC; X1, Y1, X2, Y2: Integer; RX,RY : Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function SaveDC(DC: HDC): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function ScreenToClient(Handle : HWND; var P : TPoint) : Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function ScrollWindow --> independent deprecated calls ScrollWindowEx
function ScrollWindowEx(hWnd: HWND; dx, dy: Integer; prcScroll, prcClip: PRect; hrgnUpdate: HRGN; prcUpdate: PRect; flags: UINT): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function SelectClipRGN(DC : hDC; RGN : HRGN) : Longint; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SelectObject(DC: HDC; GDIObj: HGDIOBJ): HGDIOBJ; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SelectPalette(DC: HDC; Palette: HPALETTE; ForceBackground: Boolean): HPALETTE; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SendMessage(HandleWnd: HWND; Msg: Cardinal; WParam: WParam; LParam: LParam): LResult; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetActiveWindow(Handle: HWND): HWND;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetBkColor(DC: HDC; Color: TColorRef): TColorRef; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF} //pbd
Function SetBkMode(DC: HDC; bkMode : Integer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function SetCapture (Value : LongInt): LongInt; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetCaretPos(X, Y: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetCaretPosEx(handle: HWnd; X, Y: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetCursor(hCursor: HICON): HCURSOR; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetFocus(hWnd: HWND): HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetMapMode(DC: HDC; MapMode: Integer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function SetProp(Handle: hwnd; Str : PChar; Data : Pointer) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function SetRect --> independent
//function SetRectEmpty --> independent
function SetScrollInfo(Handle: HWND; SBStyle: Integer; ScrollInfo: TScrollInfo; Redraw : Boolean): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//function SetScrollPos --> independent
//function SetScrollRange --> independent
function SetStretchBltMode(DC: HDC; StretchMode: Integer): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetSysColors(cElements: Integer; const lpaElements; const lpaRgbValues): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetTextAlign(DC: HDC; Flags: UINT): UINT; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
Function SetTextCharacterExtra(_hdc : hdc; nCharExtra : Integer):Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetTextColor(DC: HDC; Color: TColorRef): TColorRef; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetWindowLong(Handle: HWND; Idx: Integer; NewLong : Longint): Longint;{$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetWindowOrgEx(dc : hdc; NewX, NewY : Integer; OldPoint: PPoint): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function SetWindowPos(hWnd: HWND; hWndInsertAfter: HWND;
       X, Y, cx, cy: Integer; uFlags: UINT): Boolean;  {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ShowCaret(hWnd: HWND): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ShowScrollBar(Handle: HWND; wBar: Integer; bShow: Boolean): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function ShowWindow(hWnd: HWND; nCmdShow: Integer): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
procedure Sleep(dwMilliseconds: DWORD); {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function StretchBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; Rop: Cardinal): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
function StretchDIBits(DC: HDC; DestX, DestY, DestWidth, DestHeight, SrcX,
  SrcY, SrcWidth, SrcHeight: Integer; Bits: Pointer; var BitsInfo: TBitmapInfo;
  Usage: UINT; Rop: DWORD): Integer; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

Function TextOut(DC: HDC; X,Y : Integer; Str : Pchar; Count: Integer) : Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

function UpdateWindow(Handle: HWND): Boolean; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

//function UnionRect --> independent

function VkKeyScan(AChar: Char): Short; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}

Function WindowFromPoint(Point : TPoint) : HWND; {$IFDEF IF_BASE_MEMBER}virtual;{$ENDIF}
//##apiwiz##eps##     // Do not remove
{******************************************************************************
  Platform independent stuff
 ******************************************************************************}

{$IFNDEF IF_BASE_MEMBER}

//##apiwiz##spi##    // Do not remove

function AdjustWindowRectEx(Var Rect: TRect; Style1: Word; MenuExist : Boolean;
  Style2 : Word) : Boolean;

function CharLowerBuff(pStr : PChar; Len : Integer): Integer;
function CopyRect(var DestRect: TRect; const SrcRect: TRect): Boolean;
function CreateEllipticRgnIndirect(const ARect: TRect): HRGN;
function CreateFont(Height, Width, Escapement, Orientation, Weight: Integer;
  Italic, Underline, StrikeOut, CharSet, OutputPrecision, ClipPrecision,
  Quality, PitchAndFamily: Byte; FaceName: PChar): HFONT;
function CreatePen(Style, Width: Integer; Color: TColorRef): HPEN;
function CreateRectRgnIndirect(const ARect: TRect): HRGN;

function EqualRect(const lprc1, lprc2: TRect): Boolean;

function GetScrollPos(Handle: HWND; nBar: Integer): Integer;
function GetScrollRange(Handle: HWND; nBar: Integer; var lpMinPos, lpMaxPos: Integer): Boolean;

function InflateRect(var ARect: TRect; dx, dy: Integer): Boolean;
function IntersectRect(var DestRect: TRect; const SrcRect1, SrcRect2: TRect): Boolean;
Function IsCharAlphaNumeric(c : Char) : Boolean;
function IsRectEmpty(const ARect: TRect): Boolean;

function MakeWParam(l, h: Word): WPARAM;
function MakeLParam(l, h: Word): LPARAM;
function MakeLResult(l, h: Word): LRESULT;

function OffSetRect(var Rect: TRect; dx,dy: Integer): Boolean;

function PtInRect(Rect : TRect; Point : TPoint) : Boolean;
function PointToSmallPoint(const P : TPoint) : TSmallPoint;

function ScrollWindow(hWnd: HWND; XAmount, YAmount: Integer; Rect, ClipRect: PRect): Boolean;
function SetRect(Var ARect : TRect; xLeft,yTop,xRight,yBottom : Integer) : Boolean;
function SetRectEmpty(var ARect: TRect): Boolean;
function SetScrollPos(Handle: HWND; nBar, nPos: Integer; bRedraw: Boolean): Integer;
function SetScrollRange(Handle: HWND; nBar, nMinPos, nMaxPos: Integer; bRedraw: Boolean): Boolean;
Function SmallPointToPoint(const P : TSmallPoint) : Tpoint;

function UnionRect(var DestRect: TRect; const SrcRect1, SrcRect2: TRect): Boolean; //pbd

function GetRValue(RGB : DWORD) : BYTE;
function GetGValue(RGB : DWORD) : BYTE;
function GetBValue(RGB : DWORD) : BYTE;

function RGB(R, G, B : Byte) : TColorRef;

//##apiwiz##epi##    // Do not remove


{$ENDIF}

{ =============================================================================

  $Log$
  Revision 1.101  2005/01/01 20:17:30  mattias
  implemented gtk GetTextExtentPoint for UTF8

  Revision 1.100  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.99  2004/03/22 19:10:04  mattias
  implemented icons for TPage in gtk, mask for TCustomImageList

  Revision 1.98  2004/03/06 21:57:14  mattias
  fixed compilation under fpc 1.9.3

  Revision 1.97  2004/02/23 08:19:04  micha
  revert intf split

  Revision 1.95  2003/12/29 14:22:22  micha
  fix a lot of range check errors win32

  Revision 1.94  2003/11/24 11:03:07  marc
  * Splitted winapi*.inc into a winapi and a lcl interface communication part

  Revision 1.93  2003/11/14 21:17:59  micha
  new maskblt method for transparency blitting

  Revision 1.92  2003/11/10 16:15:32  micha
  cleanups; win32 fpimage support

  Revision 1.91  2003/11/07 18:48:52  micha
  symmetry getdesignerdc, releasedesignerdc

  Revision 1.90  2003/11/03 22:37:41  mattias
  fixed vert scrollbar, implemented GetDesignerDC

  Revision 1.89  2003/10/16 23:54:27  marc
  Implemented new gtk keyevent handling

  Revision 1.88  2003/08/31 17:30:49  mattias
  fixed TControl painting for win32

  Revision 1.87  2003/08/26 08:12:33  mattias
  applied listbox/combobox patch from Karl

  Revision 1.86  2003/08/25 16:43:32  mattias
  moved many graphics types form graphtype.pp to graphics.pp

  Revision 1.85  2003/08/19 12:23:23  mattias
  moved types from graphtype.pp back to graphics.pp

  Revision 1.84  2003/08/18 19:24:18  mattias
  fixed TCanvas.Pie

  Revision 1.83  2003/07/06 20:40:34  mattias
  TWinControl.WmSize/Move now updates interface messages smarter

  Revision 1.82  2003/07/04 10:12:16  mattias
  added default message handler to win32 interface

  Revision 1.81  2003/07/02 15:56:15  mattias
  fixed win32 painting and started creating bitmaps from rawimages

  Revision 1.80  2003/07/02 10:02:51  mattias
  fixed TPaintStruct

  Revision 1.79  2003/07/01 15:37:03  mattias
  fixed exception handling

  Revision 1.78  2003/07/01 14:06:45  mattias
  made Begin/EndPaint interface dependent

  Revision 1.77  2003/07/01 09:29:51  mattias
  attaching menuitems topdown

  Revision 1.76  2002/08/19 15:15:24  mattias
  implemented TPairSplitter

  Revision 1.75  2002/08/17 23:41:34  mattias
  many clipping fixes

  Revision 1.74  2003/04/11 17:10:20  mattias
  added but not implemented ComboBoxDropDown

  Revision 1.73  2003/03/29 17:20:05  mattias
  added TMemoScrollBar

  Revision 1.72  2003/03/17 20:53:16  mattias
  removed SetRadioButtonGroupMode

  Revision 1.71  2003/03/17 20:50:30  mattias
  fixed TRadioGroup.ItemIndex=-1

  Revision 1.70  2003/03/17 08:51:09  mattias
  added IsWindowVisible

  Revision 1.69  2003/03/16 13:47:45  mattias
  improved rpm building and added support for 1.0.7

  Revision 1.68  2003/03/15 13:26:07  mattias
  fixes for fpc 1.1

  Revision 1.67  2003/02/28 19:54:05  mattias
  added ShowWindow

  Revision 1.66  2003/02/28 10:14:29  mattias
  started package system (packager)

  Revision 1.65  2003/02/26 12:44:52  mattias
  readonly flag is now only saved if user set

  Revision 1.64  2003/01/27 13:49:16  mattias
  reduced speedbutton invalidates, added TCanvas.Frame

  Revision 1.63  2003/01/01 12:38:53  mattias
  clean ups

  Revision 1.62  2002/12/30 17:24:08  mattias
  added history to identifier completion

  Revision 1.61  2002/12/27 17:12:38  mattias
  added more Delphi win32 compatibility functions

  Revision 1.60  2002/12/26 11:00:14  mattias
  added included by to unitinfo and a few win32 functions

  Revision 1.59  2002/12/25 13:30:37  mattias
  added more windows funcs and fixed jump to compiler error end of file

  Revision 1.58  2002/12/25 10:21:05  mattias
  made Form.Close more Delphish, added some windows compatibility functions

  Revision 1.57  2002/12/05 22:16:30  mattias
  double byte char font started

  Revision 1.56  2002/11/30 11:22:54  mattias
  statusbar now uses invalidaterect

  Revision 1.55  2002/11/23 13:48:44  mattias
  added Timer patch from Vincent Snijders

  Revision 1.54  2002/11/09 15:02:07  lazarus
  MG: fixed LM_LVChangedItem, OnShowHint, small bugs

  Revision 1.53  2002/10/31 21:29:47  lazarus
  MG: implemented TControlScrollBar.Size

  Revision 1.52  2002/10/23 14:36:53  lazarus
  AJ:Fixes to PromptUser;Switched ShowMessage* to use NotifyUser*;
     fixed TGraphicPropertyEditor for when Property is nil.

  Revision 1.51  2002/10/16 16:58:22  lazarus
  MG: moved SendCachedLCLMessages

  Revision 1.50  2002/10/14 18:36:57  lazarus
  AJ: Improvements/Fixes to new PromptUser API

  Revision 1.49  2002/10/12 16:36:40  lazarus
  AJ: added new QueryUser/NotifyUser

  Revision 1.48  2002/10/11 16:00:39  lazarus
  AJ: made InputQuery Interface Dependant

  Revision 1.47  2002/10/10 13:29:08  lazarus
  AJ: added LoadStockPixmap routine & minor fixes to/for GNOMEInt

  Revision 1.46  2002/10/03 14:47:31  lazarus
  MG: added TComboBox.OnPopup+OnCloseUp+ItemWidth

  Revision 1.45  2002/09/27 20:52:23  lazarus
  MWE: Applied patch from "Andrew Johnson" <aj_genius@hotmail.com>

  Here is the run down of what it includes -

   -Vasily Volchenko's Updated Russian Localizations

   -improvements to GTK Styles/SysColors
   -initial GTK Palette code - (untested, and for now useless)

   -Hint Windows and Modal dialogs now try to stay transient to
    the main program form, aka they stay on top of the main form
    and usually minimize/maximize with it.

   -fixes to Form BorderStyle code(tool windows needed a border)

   -fixes DrawFrameControl DFCS_BUTTONPUSH to match Win32 better
    when flat

   -fixes DrawFrameControl DFCS_BUTTONCHECK to match Win32 better
    and to match GTK theme better. It works most of the time now,
    but some themes, noteably Default, don't work.

   -fixes bug in Bitmap code which broke compiling in NoGDKPixbuf
    mode.

   -misc other cleanups/ fixes in gtk interface

   -speedbutton's should now draw correctly when flat in Win32

   -I have included an experimental new CheckBox(disabled by
    default) which has initial support for cbGrayed(Tri-State),
    and WordWrap, and misc other improvements. It is not done, it
    is mostly a quick hack to test DrawFrameControl
    DFCS_BUTTONCHECK, however it offers many improvements which
    can be seen in cbsCheck/cbsCrissCross (aka non-themed) state.

   -fixes Message Dialogs to more accurately determine
    button Spacing/Size, and Label Spacing/Size based on current
    System font.
   -fixes MessageDlgPos, & ShowMessagePos in Dialogs
   -adds InputQuery & InputBox to Dialogs

   -re-arranges & somewhat re-designs Control Tabbing, it now
    partially works - wrapping around doesn't work, and
    subcontrols(Panels & Children, etc) don't work. TabOrder now
    works to an extent. I am not sure what is wrong with my code,
    based on my other tests at least wrapping and TabOrder SHOULD
    work properly, but.. Anyone want to try and fix?

   -SynEdit(Code Editor) now changes mouse cursor to match
    position(aka over scrollbar/gutter vs over text edit)

   -adds a TRegion property to Graphics.pp, and Canvas. Once I
    figure out how to handle complex regions(aka polygons) data
    properly I will add Region functions to the canvas itself
    (SetClipRect, intersectClipRect etc.)

   -BitBtn now has a Stored flag on Glyph so it doesn't store to
    lfm/lrs if Glyph is Empty, or if Glyph is not bkCustom(aka
    bkOk, bkCancel, etc.) This should fix most crashes with older
    GDKPixbuf libs.

  Revision 1.44  2002/09/19 19:56:14  lazarus
  MG: accelerated designer drawings

  Revision 1.43  2002/09/18 17:07:25  lazarus
  MG: added patch from Andrew

  Revision 1.42  2002/09/12 05:56:15  lazarus
  MG: gradient fill, minor issues from Andrew

  Revision 1.41  2002/09/10 06:49:19  lazarus
  MG: scrollingwincontrol from Andrew

  Revision 1.40  2002/09/09 14:01:06  lazarus
  MG: improved TScreen and ShowModal

  Revision 1.39  2002/08/30 12:32:21  lazarus
  MG: MoveWindowOrgEx, Splitted FWinControls/FControls, TControl drawing, Better DesignerDrawing, ...

  Revision 1.38  2002/08/28 09:40:49  lazarus
  MG: reduced paint messages and DC getting/releasing

  Revision 1.37  2002/08/19 20:34:47  lazarus
  MG: improved Clipping, TextOut, Polygon functions

  Revision 1.36  2002/08/17 15:45:33  lazarus
  MG: removed ClientRectBugfix defines

  Revision 1.35  2002/08/15 15:46:49  lazarus
  MG: added changes from Andrew (Clipping)

  Revision 1.34  2002/08/13 07:08:24  lazarus
  MG: added gdkpixbuf.pp and changes from Andrew Johnson

  Revision 1.33  2002/08/08 18:05:46  lazarus
  MG: added graphics extensions from Andrew Johnson

  Revision 1.32  2002/08/08 17:26:38  lazarus
  MG: added property TMenuItems.RightJustify

  Revision 1.31  2002/08/08 09:07:06  lazarus
  MG: TMenuItem can now be created/destroyed/moved at any time

  Revision 1.30  2002/08/07 09:55:30  lazarus
  MG: codecompletion now checks for filebreaks, savefile now checks for filedate

  Revision 1.29  2002/08/05 10:45:03  lazarus
  MG: TMenuItem.Caption can now be set after creation

  Revision 1.28  2002/06/21 15:41:56  lazarus
  MG: moved RectVisible, ExcludeClipRect and IntersectClipRect to interface dependent functions

  Revision 1.27  2002/06/04 15:17:22  lazarus
  MG: improved TFont for XLFD font names

  Revision 1.26  2002/05/27 17:58:42  lazarus
  MG: added command line help

  Revision 1.25  2002/05/24 07:16:32  lazarus
  MG: started mouse bugfix and completed Makefile.fpc

  Revision 1.24  2002/05/10 06:05:56  lazarus
  MG: changed license to LGPL

  Revision 1.23  2002/05/09 12:41:28  lazarus
  MG: further clientrect bugfixes

  Revision 1.22  2002/03/27 00:33:54  lazarus
  MWE:
    * Cleanup in lmessages
    * Added Listview selection and notification events
    + introduced commctrl

  Revision 1.21  2002/03/08 16:16:55  lazarus
  MG: fixed parser of end blocks in initialization section added label sections

  Revision 1.20  2002/02/03 00:24:01  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.19  2002/01/02 15:24:58  lazarus
  MG: added TCanvas.Polygon and TCanvas.Polyline

  Revision 1.18  2001/12/28 11:41:51  lazarus
  MG: added TCanvas.Ellipse, TCanvas.Pie

  Revision 1.17  2001/12/27 16:31:28  lazarus
  MG: implemented TCanvas.Arc

  Revision 1.16  2001/12/12 14:23:18  lazarus
  MG: implemented DestroyCaret

  Revision 1.15  2001/11/14 17:46:58  lazarus
  Changes to make toggling between form and unit work.
  Added BringWindowToTop
  Shane

  Revision 1.14  2001/11/12 16:56:07  lazarus
  MG: CLIPBOARD

  Revision 1.13  2001/10/10 17:55:04  lazarus
  MG: fixed caret lost, gtk cleanup, bracket lvls, bookmark saving

  Revision 1.12  2001/06/26 21:44:32  lazarus
  MG: reduced paint messages

  Revision 1.11  2001/06/14 23:13:30  lazarus
  MWE:
    * Fixed some syntax errors for the latest 1.0.5 compiler

  Revision 1.10  2001/04/06 22:25:14  lazarus
  * TTimer uses winapi-interface now instead of sendmessage-interface, stoppok

  Revision 1.9  2001/03/26 14:58:31  lazarus
  MG: setwindowpos + bugfixes

  Revision 1.8  2001/02/16 19:13:31  lazarus
  Added some functions
  Shane

  Revision 1.7  2001/01/23 18:42:10  lazarus
  Added InvalidateRect to gtkwinapi.inc
  Shane

  Revision 1.6  2000/09/10 23:08:30  lazarus
  MWE:
    + Added CreateCompatibeleBitamp function
    + Updated TWinControl.WMPaint
    + Added some checks to avoid gtk/gdk errors
    - Removed no fixed warning from GetDC
    - Removed some output

  Revision 1.5  2000/08/14 12:31:12  lazarus
  Minor modifications for SynEdit .
  Shane

  Revision 1.4  2000/08/11 14:59:09  lazarus
  Adding all the Synedit files.
  Changed the GDK_KEY_PRESS and GDK_KEY_RELEASE stuff to fix the problem in the editor with the shift key being ignored.
  Shane

  Revision 1.3  2000/08/10 18:56:24  lazarus
  Added some winapi calls.
  Most don't have code yet.
  SetTextCharacterExtra
  CharLowerBuff
  IsCharAlphaNumeric
  Shane

  Revision 1.2  2000/07/30 21:48:32  lazarus
  MWE:
    = Moved ObjectToGTKObject to GTKProc unit
    * Fixed array checking in LoadPixmap
    = Moved LM_SETENABLED to API func EnableWindow and EnableMenuItem
    ~ Some cleanup

  Revision 1.1  2000/07/13 10:28:28  michael
  + Initial import

}
