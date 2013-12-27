{
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
unit GTKGlobals;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, InterfaceBase,
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2,
  {$ELSE}
  glib, gdk, gtk,
  {$ENDIF}
  LMessages, LCLProc, Controls, Forms, LCLIntf, LCLType, GTKDef, DynHashArray;

{$I dragicons.inc}

var
  // gtk-interface options
  UseTransientForModalWindows: boolean;
  UpdatingTransientWindows: boolean;

  // mouse --------------------------------------------------------------------
type
  TMouseCaptureType = (
    mctGTK,     // gtk is handling capturing
    mctGTKIntf, // gtk interface has captured the mouse
    mctLCL      // a LCL control has captured the mouse
    );
  
var
  //drag icons
  //TrashCan_Open : PgdkPixmap;
  //TrashCan_Open_Mask : PGdkPixmap;
  //TrashCan_Closed : PGdkPixmap;
  //TrashCan_Closed_Mask : PGdkPixmap;
  Drag_Icon : PgdkPixmap;
  Drag_Mask : PgdkPixmap;

  //Dragging : Boolean;

  MouseCaptureWidget: PGtkWidget;
  MouseCaptureType: TMouseCaptureType;
  MouseCaptureIndex: cardinal;

const
  DblClickTime = 250;// 250 miliseconds or less between clicks is a double click
  DblClickThreshold = 3;// max Movement between two clicks of a DblClick

type
  TLastMouseClick = record
    Down: boolean;
    TheTime: TDateTime; // last Down time
    ClickCount: integer;
    Component: TComponent;
    Window: PGdkWindow;
    WindowPoint: TPoint;
  end;

const
  EmptyLastMouseClick: TLastMouseClick =
    (Down: false; TheTime: -1; ClickCount: 0; Component: nil;
     Window: nil; WindowPoint: (X: 0; Y: 0));

var
  LastLeft, LastMiddle, LastRight: TLastMouseClick;
  
  // mouse cursors
var
  GDKMouseCursors:   array[crLow..crHigh] of pGDKCursor;
  // mapping from TCursor to gdk cursor index
  CursorToGDKCursor: array[crLow..crHigh] of integer;

var
  LastFileSelectRow : gint;

// styles -------------------------------------------------------------------
type
  TLazGtkStyle = (
    lgsGTK_Default, // without anything
    lgsDefault,     // with rc file
    lgsButton,
    lgsLabel,
    lgsWindow,
    lgsCheckbox,
    lgsRadiobutton,
    lgsMenu,
    lgsMenuitem,
    lgsList,
    lgsVerticalScrollbar,
    lgsHorizontalScrollbar,
    lgsTooltip,
    lgsVerticalPaned,
    lgsHorizontalPaned,
    lgsNotebook,
    lgsStatusBar,
    // user defined
    lgsUserDefined
    );

const
  LazGtkStyleNames: array[TLazGtkStyle] of string = (
    'gtk_default',
    'default',
    'button',
    'label',
    'window',
    'checkbox',
    'radiobutton',
    'menu',
    'menuitem',
    'list',
    'vertical scrollbar',
    'horizontal scrollbar',
    'tooltip',
    'vertical paned',
    'horizontal paned',
    'statusbar',
    'notebook',
    ''
    );

var
  Styles : TStrings;

const
  KEYMAP_VKUNKNOWN = $10000;
  KEYMAP_TOGGLE    = $20000;
  KEYMAP_EXTENDED  = $40000;

// PDB: note this is a hack. Windows maintains a system wide
//      system color table we will have to have our own
//      to be able to do the translations required from
//      window manager to window manager this means every
//      application will carry its own color table
//      we set the defaults here to reduce the initial
//      processing of creating a default table
// MWE: Naaaaah, not a hack, just something temporary
const
  SysColorMap: array [0..MAX_SYS_COLORS] of DWORD = (
    $C0C0C0,     {COLOR_SCROLLBAR}
    $808000,     {COLOR_BACKGROUND}
    $800000,     {COLOR_ACTIVECAPTION}
    $808080,     {COLOR_INACTIVECAPTION}
    $C0C0C0,     {COLOR_MENU}
    $FFFFFF,     {COLOR_WINDOW}
    $000000,     {COLOR_WINDOWFRAME}
    $000000,     {COLOR_MENUTEXT}
    $000000,     {COLOR_WINDOWTEXT}
    $FFFFFF,     {COLOR_CAPTIONTEXT}
    $C0C0C0,     {COLOR_ACTIVEBORDER}
    $C0C0C0,     {COLOR_INACTIVEBORDER}
    $808080,     {COLOR_APPWORKSPACE}
    $800000,     {COLOR_HIGHLIGHT}
    $FFFFFF,     {COLOR_HIGHLIGHTTEXT}
    $D0D0D0,     {COLOR_BTNFACE}
    $808080,     {COLOR_BTNSHADOW}
    $808080,     {COLOR_GRAYTEXT}
    $000000,     {COLOR_BTNTEXT}
    $C0C0C0,     {COLOR_INACTIVECAPTIONTEXT}
    $F0F0F0,     {COLOR_BTNHIGHLIGHT}
    $000000,     {COLOR_3DDKSHADOW}
    $C0C0C0,     {COLOR_3DLIGHT}
    $000000,     {COLOR_INFOTEXT}
    $E1FFFF,     {COLOR_INFOBK}
    $000000,     {unassigned}
    $000000,     {COLOR_HOTLIGHT}
    $000000,     {COLOR_GRADIENTACTIVECAPTION}
    $000000,     {COLOR_GRADIENTINACTIVECAPTION}
    $D0D0D0,     {COLOR_FORM}
    
    // CLX base, mapped, pseudo, rgb values
    $000000,   // COLOR_clForeground
    $000000,   // COLOR_clButton
    $000000,   // COLOR_clLight
    $000000,   // COLOR_clMidlight
    $000000,   // COLOR_clDark
    $000000,   // COLOR_clMid
    $000000,   // COLOR_clText
    $000000,   // COLOR_clBrightText
    $000000,   // COLOR_clButtonText
    $000000,   // COLOR_clBase
    $000000,   // COLOR_clShadow
    $000000,   // COLOR_clHighlightedText

    // CLX normal, mapped, pseudo, rgb values
    $000000,   // COLOR_clNormalForeground
    $000000,   // COLOR_clNormalButton
    $000000,   // COLOR_clNormalLight
    $000000,   // COLOR_clNormalMidlight
    $000000,   // COLOR_clNormalDark
    $000000,   // COLOR_clNormalMid
    $000000,   // COLOR_clNormalText
    $000000,   // COLOR_clNormalBrightText
    $000000,   // COLOR_clNormalButtonText
    $000000,   // COLOR_clNormalBase
    $000000,   // COLOR_clNormalBackground
    $000000,   // COLOR_clNormalShadow
    $000000,   // COLOR_clNormalHighlight
    $000000,   // COLOR_clNormalHighlightedText

    // CLX disabled, mapped, pseudo, rgb values
    $000000,   // COLOR_clDisabledForeground
    $000000,   // COLOR_clDisabledButton
    $000000,   // COLOR_clDisabledLight
    $000000,   // COLOR_clDisabledMidlight
    $000000,   // COLOR_clDisabledDark
    $000000,   // COLOR_clDisabledMid
    $000000,   // COLOR_clDisabledText
    $000000,   // COLOR_clDisabledBrightText
    $000000,   // COLOR_clDisabledButtonText
    $000000,   // COLOR_clDisabledBase
    $000000,   // COLOR_clDisabledBackground
    $000000,   // COLOR_clDisabledShadow
    $000000,   // COLOR_clDisabledHighlight
    $000000,   // COLOR_clDisabledHighlightedText

    // CLX active, mapped, pseudo, rgb values
    $000000,   // COLOR_clActiveForeground
    $000000,   // COLOR_clActiveButton
    $000000,   // COLOR_clActiveLight
    $000000,   // COLOR_clActiveMidlight
    $000000,   // COLOR_clActiveDark
    $000000,   // COLOR_clActiveMid
    $000000,   // COLOR_clActiveText
    $000000,   // COLOR_clActiveBrightText
    $000000,   // COLOR_clActiveButtonText
    $000000,   // COLOR_clActiveBase
    $000000,   // COLOR_clActiveBackground
    $000000,   // COLOR_clActiveShadow
    $000000,   // COLOR_clActiveHighlight
    $000000    // COLOR_clActiveHighlightedText
  ); {end _SysColors}

const
  {$ifdef GTK2}GTK_WINDOW_DIALOG=GTK_WINDOW_TOPLEVEL;{$endif}
  FormStyleMap : array[TFormBorderStyle] of TGtkWindowType = (
    // GTK_WINDOW_DIALOG for stay on top forms
    GTK_WINDOW_DIALOG,  // bsNone
    GTK_WINDOW_TOPLEVEL,// bsSingle
    GTK_WINDOW_TOPLEVEL,// bsSizeable
    GTK_WINDOW_DIALOG,  // bsDialog
    GTK_WINDOW_TOPLEVEL,  // bsToolWindow
    GTK_WINDOW_TOPLEVEL   // bsSizeToolWin
  );
  FormResizableMap : array[TFormBorderStyle] of gint = (
    0, // bsNone
    1, // bsSingle
    1, // bsSizeable
    1, // bsDialog
    0, // bsToolWindow
    1  // bsSizeToolWin
  );


  // signals ------------------------------------------------------------------
type

  //Defined in gtksignal.c
  PGtkHandler = ^TGtkHandler;
  TGtkHandler = record
    id:               guint;
    next:             PGtkHandler;
    prev:             PGtkHandler;
    flags:            guint; // -->  blocked : 20 bits,
                             //      object_signal : 1 bit,
                             //      after : 1 bit,
                             //      no_marshal : 1 bit
    ref_count:        guint16;
    signal_id:        guint16;
    func:             TGtkSignalFunc;
    func_data:        gpointer;
    destroy_func:     {$ifdef GTK2}TGtkSignalFunc{$else}TGtkSignalDestroy{$endif};
  end;

const
  bmSignalAfter = $00200000;

type
  { lazarus GtkInterface definition for additional timer data, not in gtk }
  PGtkITimerInfo = ^TGtkITimerinfo;
  TGtkITimerInfo = record
    TimerHandle: guint;        // the gtk handle for this timer
    TimerFunc  : TFNTimerProc; // owner function to handle timer
  end;

var
  // FTimerData contains the currently running timers
  FTimerData : TFPList;   // list of PGtkITimerinfo

var
  gtk_handler_quark: TGQuark;


// Internal Paint message:
const
  LM_GTKPaint         = LM_INTERFACEFIRST + 0;
  
  GtkPaint_LCLWidget = 1;
  GtkPaint_GtkWidget = 2;

type
  TLMGtkPaintData = class
  public
    Widget: PGtkWidget;
    State: integer; // see GtkPaint_xxx
    RepaintAll: boolean;
    Rect: TRect;
  end;

  TLMGtkPaint = record
    Msg: Cardinal;
    Data: TLMGtkPaintData; // WParam
    Unused: LPARAM;       // LParam
    Result: LRESULT;
  end;

var
  CurrentSentPaintMessageTarget: TObject;

const
  TARGET_STRING = 1;
  TARGET_ROOTWIN = 2;

{off $DEFINE DEBUG_CLIPBOARD}
var
  // All clipboard events are handled by only one widget - the ClipboardWidget
  // This widget is typically the main form
  ClipboardWidget: PGtkWidget;
  // each selection has an gtk identifier (an atom)
  ClipboardTypeAtoms: array[TClipboardType] of cardinal;
  // each active request will procduce an TClipboardEventData stored in this list
  ClipboardSelectionData: TFPList; // list of PClipboardEventData
  // each selection can have an user defined handler (normally set by the lcl)
  ClipboardHandler: array[TClipboardType] of TClipboardRequestEvent;
  // boolean array, telling what gtk format is automatically supported by
  // gtk interface and not by the program (the lcl)
  ClipboardExtraGtkFormats: array[TClipboardType,TGtkClipboardFormat] of boolean;
  // lists of supported targets
  ClipboardTargetEntries: array[TClipboardType] of PGtkTargetEntry;
  ClipboardTargetEntryCnt: array[TClipboardType] of integer;

  // each main widget that was resized by the gtk is stored here
  // (hasharray of PGtkWidget)
  FWidgetsResized: TDynHashArray;
  // each fixed widget that was resized by the gtk is stored here
  // (hasharray of PGtkWidget)
  FFixWidgetsResized: TDynHashArray;

const
  aGtkJustification: array[TAlignment] of TGTKJustification =
    (GTK_JUSTIFY_LEFT,GTK_JUSTIFY_RIGHT,GTK_JUSTIFY_CENTER);

  aGtkSelectionMode: Array[Boolean] of TGtkSelectionMode =
    (GTK_SELECTION_SINGLE,GTk_SELECTION_EXTENDED);

  { file dialog }

type
  PFileSelHistoryEntry = ^TFileSelHistoryEntry;
  TFileSelHistoryEntry = record
      Filename: PChar;
      MenuItem: PGtkWidget;
    end;

  PFileSelFilterEntry = ^TFileSelFilterEntry;
  TFileSelFilterEntry = record
      Description: PChar;
      Mask: PChar;
      FilterIndex: integer;
      MenuItem: PGtkWidget;
    end;
    
  { Menu }

type
  TCheckMenuItemDrawProc =
    procedure (check_menu_item:PGtkCheckMenuItem; area:PGdkRectangle); cdecl;

  TMenuSizeRequestProc =
    procedure (widget:PGtkWidget; requisition:PGtkRequisition); cdecl;

const
  OldCheckMenuItemDrawProc: TCheckMenuItemDrawProc = nil;
  OldMenuSizeRequestProc: TMenuSizeRequestProc = nil;
  OldCheckMenuItemToggleSize: integer = 0;


  { Accelerators }
type
  PAcceleratorKey = ^TAcceleratorKey;
  TAcceleratorKey = record
    Key: guint;
    Mods: TGdkModifierType;
    Signal: string;
    Realized: boolean;
  end;
  
  // modal windows
var
  ModalWindows: TFPList; // list of PGtkWindow


// gtk object data names
const
  odnScrollArea = 'scroll_area'; // the gtk_scrolled_window of a widget
                                 // used by TCustomForm and TScrollbox
  odnScrollBar = 'ScrollBar'; // Gives the scrollbar the tgtkrange is belonging to
                              // Used by TScrollbar, TScrollbox and TWinApiWidget

const
  CallBackDefaultReturn = {$IFDEF GTK2}false{$ELSE}true{$ENDIF};


// font
var
  AvgFontCharsBuffer: array[#32..#127] of char;
  AvgFontCharsBufLen: integer;
  
type
  Charsetstr=string[15];
  PCharSetEncodingRec=^TCharSetEncodingRec;
  TCharSetEncodingRec=record
    CharSet: byte;              // winapi charset value
    CharSetReg:CharSetStr;      // Charset Registry Pattern
    CharSetCod:CharSetStr;      // Charset Encoding Pattern
    EnumMap: boolean;           // this mapping is meanful when enumerating fonts?
    CharsetRegPart: boolean;    // is CharsetReg a partial pattern?
    CharsetCodPart: boolean;    // is CharsetCod a partial pattern?
  end;

var
  CharSetEncodingList: TList;
  
  procedure AddCharsetEncoding(CharSet: Byte; CharSetReg, CharSetCod: CharSetStr;
    ToEnum:boolean=true; CrPart:boolean=false; CcPart:boolean=false);
  procedure ClearCharsetEncodings;
  procedure CreateDefaultCharsetEncodings;
  

{$IFDEF DebugLCLComponents}
var
  DebugGtkWidgets: TDebugLCLItems = nil;
{$ENDIF}

implementation


procedure InternalInit;
var
  c: char;
begin
  for c:=Low(AvgFontCharsBuffer) to High(AvgFontCharsBuffer) do
    AvgFontCharsBuffer[c]:=c;
  AvgFontCharsBufLen:=ord(High(AvgFontCharsBuffer))-ord(Low(AvgFontCharsBuffer));
  AvgFontCharsBuffer[high(AvgFontCharsBuffer)]:=#0;
  ModalWindows:=nil;
  UseTransientForModalWindows:=true;
  UpdatingTransientWindows:=false;
  CurrentSentPaintMessageTarget:=nil;
  
  {$IFDEF DebugLCLComponents}
  DebugGtkWidgets:=TDebugLCLItems.Create;
  {$ENDIF}
end;

procedure AddCharsetEncoding(CharSet: Byte; CharSetReg, CharSetCod: CharSetStr;
  ToEnum:boolean=true; CrPart:boolean=false; CcPart:boolean=false);
var
  Rec: PCharsetEncodingRec;
begin
   New(Rec);
   Rec^.Charset := CharSet;
   Rec^.CharsetReg := CharSetReg;
   Rec^.CharsetCod := CharSetCod;
   Rec^.EnumMap := ToEnum;
   Rec^.CharsetRegPart := CrPart;
   Rec^.CharsetCodPart := CcPart;
   CharSetEncodingList.Add(Rec);
end;

procedure ClearCharsetEncodings;
var
  Rec: PCharsetEncodingRec;
  i: Integer;
begin
  for i:=0 to CharsetEncodingList.Count-1 do begin
    Rec := CharsetEncodingList[i];
    if Rec<>nil then
      Dispose(Rec);
  end;
  CharsetEncodingList.Clear;
end;

procedure CreateDefaultCharsetEncodings;
begin
  ClearCharsetEncodings;

  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '1',    false);
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '3',    false);
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '15',   false);
  AddCharsetEncoding(ANSI_CHARSET,        'ansi',     '0');
  AddCharsetEncoding(ANSI_CHARSET,        '*',        'cp1252');
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '*');
  AddCharsetEncoding(DEFAULT_CHARSET,     '*',        '*');
  AddCharsetEncoding(SYMBOL_CHARSET,      '*',        'fontspecific');
  AddCharsetEncoding(MAC_CHARSET,         '*',        'cpxxxx'); // todo
  AddCharsetEncoding(SHIFTJIS_CHARSET,    'jis',      '0',    true, true);
  AddCharsetEncoding(SHIFTJIS_CHARSET,    '*',        'cp932');
  AddCharsetEncoding(HANGEUL_CHARSET,     '*',        'cp949');
  AddCharsetEncoding(JOHAB_CHARSET,       '*',        'cp1361');
  AddCharsetEncoding(GB2312_CHARSET,      'gb2312',   '0',    true, true);
  AddCharsetEncoding(CHINESEBIG5_CHARSET, 'big5',     '0',    true, true);
  AddCharsetEncoding(CHINESEBIG5_CHARSET, '*',        'cp950');
  AddCharsetEncoding(GREEK_CHARSET,       'iso8859',  '7');
  AddCharsetEncoding(GREEK_CHARSET,       '*',        'cp1253');
  AddCharsetEncoding(TURKISH_CHARSET,     'iso8859',  '9');
  AddCharsetEncoding(TURKISH_CHARSET,     '*',        'cp1254');
  AddCharsetEncoding(VIETNAMESE_CHARSET,  '*',        'cp1258');
  AddCharsetEncoding(HEBREW_CHARSET,      'iso8859',  '8');
  AddCharsetEncoding(HEBREW_CHARSET,      '*',        'cp1255');
  AddCharsetEncoding(ARABIC_CHARSET,      'iso8859',  '6');
  AddCharsetEncoding(ARABIC_CHARSET,      '*',        'cp1256');
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '13');
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '4');  // northern europe
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '14'); // CELTIC_CHARSET
  AddCharsetEncoding(BALTIC_CHARSET,      '*',        'cp1257');
  AddCharsetEncoding(RUSSIAN_CHARSET,     'iso8859',  '5');
  AddCharsetEncoding(RUSSIAN_CHARSET,     'koi8',     '*');
  AddCharsetEncoding(RUSSIAN_CHARSET,     '*',        'cp1251');
  AddCharsetEncoding(THAI_CHARSET,        'iso8859',  '11');
  AddCharsetEncoding(THAI_CHARSET,        'tis620',   '*',  true, true);
  AddCharsetEncoding(THAI_CHARSET,        '*',        'cp874');
  AddCharsetEncoding(EASTEUROPE_CHARSET,  'iso8859',  '2');
  AddCharsetEncoding(EASTEUROPE_CHARSET,  '*',        'cp1250');
  AddCharsetEncoding(OEM_CHARSET,         'ascii',    '0');
  AddCharsetEncoding(OEM_CHARSET,         'iso646',   '*',  true, true);
  AddCharsetEncoding(FCS_ISO_10646_1,     'iso10646', '1');
  AddCharsetEncoding(FCS_ISO_8859_1,      'iso8859',  '1');
  AddCharsetEncoding(FCS_ISO_8859_2,      'iso8859',  '2');
  AddCharsetEncoding(FCS_ISO_8859_3,      'iso8859',  '3');
  AddCharsetEncoding(FCS_ISO_8859_4,      'iso8859',  '4');
  AddCharsetEncoding(FCS_ISO_8859_5,      'iso8859',  '5');
  AddCharsetEncoding(FCS_ISO_8859_6,      'iso8859',  '6');
  AddCharsetEncoding(FCS_ISO_8859_7,      'iso8859',  '7');
  AddCharsetEncoding(FCS_ISO_8859_8,      'iso8859',  '8');
  AddCharsetEncoding(FCS_ISO_8859_9,      'iso8859',  '9');
  AddCharsetEncoding(FCS_ISO_8859_10,     'iso8859',  '10');
  AddCharsetEncoding(FCS_ISO_8859_15,     'iso8859',  '15');
  
end;

initialization
  InternalInit;

end.
