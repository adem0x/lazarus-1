unit Gtk2Themes;

{$mode objfpc}{$H+}

interface

uses
  // rtl
  Types, Classes, SysUtils,
  // os
  glib2,  gdk2, gtk2, gdk2pixbuf, Pango,
  // lcl
  LCLType, LCLProc, LCLIntf, Graphics, Themes, TmSchema, Forms,
  // widgetset
  Gtk2Def, Gtk2Int, Gtk2Proc, Gtk2Globals;

type
  TGtkPainterType =
  (
    gptNone,
    gptDefault,
    gptHLine,
    gptVLine,
    gptShadow,
    gptBox,
    gptBoxGap,
    gptFlatBox,
    gptCheck,
    gptOption,
    gptTab,
    gptSlider,
    gptHandle,
    gptExpander,
    gptResizeGrip,
    gptFocus,
    gptArrow,
    gptPixmap
  );

  TGtkStyleParams = record
    Style      : PGtkStyle;       // paint style
    Painter    : TGtkPainterType; // type of paint handler
    Widget     : PGtkWidget;      // widget
    Window     : PGdkWindow;      // paint window
    Origin     : TPoint;          // offset
    State      : TGtkStateType;   // Style state
    Shadow     : TGtkShadowType;  // Shadow
    Detail     : String;          // Detail (button, checkbox, ...)
    Orientation: TGtkOrientation; // Orientation (horizontal/vertical)
    ArrowType  : TGtkArrowType;   // type of arrow
    Fill       : Boolean;         // fill inside area
    GapSide    : TGtkPositionType;//
    GapX       : gint;
    GapWidth   : gint;
    MaxWidth   : gint;            // max area width
    Expander   : TGtkExpanderStyle; // treeview expander
    ExpanderSize: Integer;
    Edge       : TGdkWindowEdge;
    IsHot      : Boolean;
  end;

type
  { TGtk2ThemeServices }

  TGtk2ThemeServices = class(TThemeServices)
  protected
    procedure DrawPixmap(DC: HDC; Area: PGdkRectangle; PixmapIndex: Byte); virtual;

    function InitThemes: Boolean; override;
    function UseThemes: Boolean; override;
    function ThemedControlsEnabled: Boolean; override;

    procedure InternalDrawParentBackground(Window: HWND; Target: HDC; Bounds: PRect); override;
    function GetBaseDetailsSize(Details: TThemedElementDetails): TSize;

    function GetGtkStyleParams(DC: HDC; Details: TThemedElementDetails; AIndex: Integer): TGtkStyleParams; virtual;
    function GetParamsCount(Details: TThemedElementDetails): Integer; virtual;

    procedure Gtk1DrawElement(DC: HDC; Details: TThemedElementDetails;
      const R: TRect; ClipRect: PRect);
    function GetGtk1StyleParams(DC: HDC; Details: TThemedElementDetails;
      AIndex: Integer): TGtkStyleParams;
  public
    function GetDetailSize(Details: TThemedElementDetails): TSize; override;
    function GetStockImage(StockID: LongInt; out Image, Mask: HBitmap): Boolean; override;
    function GetOption(AOption: TThemeOption): Integer; override;
    procedure DrawElement(DC: HDC; Details: TThemedElementDetails;
       const R: TRect; ClipRect: PRect); override;

    procedure DrawIcon(DC: HDC; Details: TThemedElementDetails; const R: TRect; himl: HIMAGELIST; Index: Integer); override;
    procedure DrawText(DC: HDC; Details: TThemedElementDetails; const S: String; R: TRect; Flags, Flags2: Cardinal); override;

    function ContentRect(DC: HDC; Details: TThemedElementDetails; BoundingRect: TRect): TRect; override;
    function HasTransparentParts(Details: TThemedElementDetails): Boolean; override;
  end;

const
  // most common maps
  GtkButtonMap: array[0..6] of TGtkStateType =
  (
{ filter ?          } GTK_STATE_NORMAL,
{ normal            } GTK_STATE_NORMAL,
{ hot               } GTK_STATE_PRELIGHT,
{ pressed           } GTK_STATE_ACTIVE,
{ disabled          } GTK_STATE_INSENSITIVE,
{ defaulted/checked } GTK_STATE_ACTIVE,
{ hot + checked     } GTK_STATE_ACTIVE
  );
  GtkRadioCheckBoxMap: array[0..12] of TGtkStateType =
  (
{ Filler            } GTK_STATE_NORMAL,
{ UNCHECKEDNORMAL   } GTK_STATE_NORMAL,
{ UNCHECKEDHOT      } GTK_STATE_PRELIGHT,
{ UNCHECKEDPRESSED  } GTK_STATE_ACTIVE,
{ UNCHECKEDDISABLED } GTK_STATE_INSENSITIVE,
{ CHECKEDNORMAL     } GTK_STATE_NORMAL,
{ CHECKEDHOT        } GTK_STATE_PRELIGHT,
{ CHECKEDPRESSED    } GTK_STATE_ACTIVE,
{ CHECKEDDISABLED   } GTK_STATE_INSENSITIVE,
{ MIXEDNORMAL       } GTK_STATE_NORMAL,
{ MIXEDHOT          } GTK_STATE_PRELIGHT,
{ MIXEDPRESSED      } GTK_STATE_ACTIVE,
{ MIXEDDISABLED     } GTK_STATE_INSENSITIVE
  );
  GtkTitleButtonMap: array[0..5] of TGtkStateType =
  (
{ filter ?          } GTK_STATE_NORMAL,
{ normal            } GTK_STATE_NORMAL,
{ hot               } GTK_STATE_PRELIGHT,
{ pressed           } GTK_STATE_ACTIVE,
{ disabled          } GTK_STATE_INSENSITIVE,
{ inactive          } GTK_STATE_INSENSITIVE
  );

implementation

{$I gtk2stdpixmaps.inc}

function GetColumnButtonFromTreeView(AWidget: PGtkWidget): PGtkWidget;
var
  AColumn: PGtkTreeViewColumn;
begin
  Result := nil;
  if not GTK_IS_TREE_VIEW(AWidget) then
    exit;

  AColumn := gtk_tree_view_get_column(PGtkTreeView(AWidget), 0);
  if AColumn = nil then
    Exit;
  Result := AColumn^.button;
end;

{ TGtk2ThemeServices }

procedure TGtk2ThemeServices.DrawPixmap(DC: HDC; Area: PGdkRectangle;
  PixmapIndex: Byte);
var
  APixmap, APixmapMask: PGdkPixmap;
  DevCtx: TGtkDeviceContext absolute DC;
  w, h: gint;
begin
  if (PixmapIndex >= Low(PixmapArray)) and (PixmapIndex <= High(PixmapArray)) then
  begin
    APixmapMask := nil;
    APixmap := gdk_pixmap_create_from_xpm_d(DevCtx.Drawable,
      APixmapMask, nil, PixmapArray[PixmapIndex]);
    if APixmap <> nil then
    begin
      gdk_drawable_get_size(APixmap, @w, @h);
      w := (Area^.Width - w) div 2;
      if w < 0 then
        w := 0;
      h := (Area^.Height - h) div 2;
      if h < 0 then
        h := 0;
      if APixmapMask <> nil then
      begin
        gdk_gc_set_clip_mask(DevCtx.GC, APixmapMask);
        gdk_gc_set_clip_origin(DevCtx.GC, Area^.x + w, Area^.y + h);
      end;
      gdk_draw_pixmap(DevCtx.Drawable, DevCtx.GC, APixmap, 0, 0, Area^.x + w, Area^.y + h,
        Area^.Width, Area^.Height);
      if APixmapMask <> nil then
        DevCtx.ResetGCClipping;
      gdk_pixmap_unref(APixmap);
    end;
    if APixmapMask <> nil then
      gdk_pixmap_unref(APixmapMask);
  end;
end;

function TGtk2ThemeServices.InitThemes: Boolean;
begin
  Result:=True;
end;

function TGtk2ThemeServices.UseThemes: Boolean;
begin
  Result:=True;
end;

function TGtk2ThemeServices.ThemedControlsEnabled: Boolean;
begin
  Result:=True;
end;

procedure TGtk2ThemeServices.InternalDrawParentBackground(Window: HWND;
  Target: HDC; Bounds: PRect);
begin
  // ?
end;

function TGtk2ThemeServices.GetBaseDetailsSize(Details: TThemedElementDetails): TSize;
begin
  Result := inherited GetDetailSize(Details);
end;


function TGtk2ThemeServices.GetGtk1StyleParams(DC: HDC;
  Details: TThemedElementDetails; AIndex: Integer): TGtkStyleParams;
var
  DevCtx: TGtkDeviceContext absolute DC;
  ClientWidget: PGtkWidget;
begin
  FillByte(Result, SizeOf(Result), 0);
  if not Gtk2WidgetSet.IsValidDC(DC) then Exit;

  Result.Widget := DevCtx.Widget;
  if Result.Widget <> nil then
  begin
    ClientWidget := GetFixedWidget(Result.Widget);
    if ClientWidget <> nil then
      Result.Widget := ClientWidget;
    Result.Style := gtk_widget_get_style(Result.Widget);
  end;
  Result.Window := DevCtx.Drawable;
  Result.Origin := DevCtx.Offset;

  Result.Painter := gptDefault;
  Result.State := GTK_STATE_NORMAL;
  Result.Detail := '';
  Result.Shadow := GTK_SHADOW_NONE;
  Result.ArrowType := GTK_ARROW_UP;
  Result.Fill := False;
  Result.IsHot := False;
  Result.GapSide := GTK_POS_LEFT;
  Result.GapWidth := 0;
  Result.GapX := 0;
  Result.MaxWidth := 0;

  case Details.Element of
    teButton:
      begin
        case Details.Part of
          BP_PUSHBUTTON:
            begin
              Result.Widget := GetStyleWidget(lgsButton);
              if Result.Style = nil then
                Result.Style := GetStyle(lgsButton);
              Result.State := GtkButtonMap[Details.State];
              if Details.State = PBS_PRESSED then
                Result.Shadow := GTK_SHADOW_IN
              else
                Result.Shadow := GTK_SHADOW_OUT;

              Result.IsHot:= Result.State = GTK_STATE_PRELIGHT;
              Result.Detail := 'button';
              Result.Painter := gptBox;
            end;
          BP_RADIOBUTTON:
            begin
              Result.Widget := GetStyleWidget(lgsRadiobutton);
              if Result.Style = nil then
                Result.Style := GetStyle(lgsRadiobutton);
              Result.State := GtkRadioCheckBoxMap[Details.State];
              if Details.State >= RBS_CHECKEDNORMAL then
                Result.Shadow := GTK_SHADOW_IN
              else
                Result.Shadow := GTK_SHADOW_OUT;
              Result.Detail := 'radiobutton';
              Result.Painter := gptOption;
            end;
          BP_CHECKBOX:
            begin
              Result.Widget := GetStyleWidget(lgsCheckbox);
              if Result.Style = nil then
                Result.Style := GetStyle(lgsCheckbox);
              Result.State := GtkRadioCheckBoxMap[Details.State];
              Result.Detail := 'checkbutton';
              if Details.State >= CBS_MIXEDNORMAL then
                result.Shadow := GTK_SHADOW_ETCHED_IN
              else
              if Details.State >= CBS_CHECKEDNORMAL then
                Result.Shadow := GTK_SHADOW_IN
              else
                Result.Shadow := GTK_SHADOW_OUT;
              Result.Painter := gptCheck;
            end;
        end;
      end;
    teHeader:
      begin
        Result.Widget := GetStyleWidget(lgsButton);
        if Result.Style = nil then
          Result.Style := GetStyle(lgsButton);
        Result.State := GtkButtonMap[Details.State];
        if Details.State = PBS_PRESSED then
          Result.Shadow := GTK_SHADOW_IN
        else
          Result.Shadow := GTK_SHADOW_OUT;

        Result.IsHot := Result.State = GTK_STATE_PRELIGHT;

        Result.Detail := 'button';
        Result.Painter := gptBox;
      end;
    teStatus:
      begin
        Result.Widget := GetStyleWidget(lgsStatusBar);
        if Result.Style = nil then
          Result.Style := GetStyle(lgsStatusBar);
        Result.Detail := 'statubar';
        Result.State := GTK_STATE_NORMAL;
        case Details.Part of
          SP_PANE:
            begin
              Result.Painter := gptShadow;
              Result.Shadow := GTK_SHADOW_OUT;
            end;
          SP_GRIPPER:
            begin
              Result.Painter := gptResizeGrip;
              Result.Edge := GDK_WINDOW_EDGE_SOUTH_EAST;
            end;
        end;
      end;
    teToolBar:
      begin
        case Details.Part of
          TP_BUTTON,
          TP_DROPDOWNBUTTON,
          TP_SPLITBUTTON,
          TP_SPLITBUTTONDROPDOWN:
            begin
              if (Details.Part = TP_SPLITBUTTONDROPDOWN) and (AIndex = 1) then
              begin
                Result.Detail := 'arrow';
                Result.ArrowType := GTK_ARROW_DOWN;
                Result.Fill := True;
                Result.Painter := gptArrow;
                Result.MaxWidth := 10;
              end
              else
              begin
                Result.Widget := GetStyleWidget(lgsToolButton);
                if Result.Style = nil then
                  Result.Style := GetStyle(lgsToolButton);
                Result.State := GtkButtonMap[Details.State];
                if Details.State in [TS_PRESSED, TS_CHECKED, TS_HOTCHECKED] then
                  Result.Shadow := GTK_SHADOW_IN
                else
                if Details.State in [TS_HOT] then
                  Result.Shadow := GTK_SHADOW_ETCHED_IN
                else
                  Result.Shadow := GTK_SHADOW_NONE;

                Result.IsHot := Details.State in [TS_HOT, TS_HOTCHECKED];

                Result.Detail := 'button';
                if Result.Shadow = GTK_SHADOW_NONE then
                  Result.Painter := gptNone
                else
                  Result.Painter := gptBox;
              end;
            end;
          TP_SEPARATOR,
          TP_SEPARATORVERT:
            begin
              Result.State := GTK_STATE_NORMAL;
              Result.Shadow := GTK_SHADOW_NONE;
              Result.Detail := 'toolbar';
              if Details.Part = TP_SEPARATOR then
                Result.Painter := gptVLine
              else
                Result.Painter := gptHLine;
            end;
        end;
      end;
    teRebar:
      begin
        case Details.Part of
          RP_GRIPPER, RP_GRIPPERVERT:
            begin
              Result.State := GTK_STATE_NORMAL;
              Result.Shadow := GTK_SHADOW_NONE;
{ This code has problems with some (is not most) of gtk1 themes.
But at least Ubuntu >= 6.10 works fine. So it is commented out and switched
to alternate splitter painting}

              if Details.Part = RP_GRIPPER then
              begin
                Result.Detail := 'hpaned';
                Result.Widget := GetStyleWidget(lgsHorizontalPaned);
                if Result.Style = nil then
                  Result.Style := GetStyle(lgsHorizontalPaned);
              end
              else
              begin
                Result.Detail := 'vpaned';
                Result.Widget := GetStyleWidget(lgsVerticalPaned);
                if Result.Style = nil then
                  Result.Style := GetStyle(lgsVerticalPaned);
              end;
              Result.Painter := gptBox;

{                  Result.Detail := 'paned';
              Result.Painter := gptHandle;
              if Details.Part = RP_GRIPPER then
                Result.Orientation := GTK_ORIENTATION_VERTICAL
              else
                Result.Orientation := GTK_ORIENTATION_HORIZONTAL;}
            end;
          RP_BAND:
            begin
              Result.State := GtkButtonMap[Details.State];
              Result.Shadow := GTK_SHADOW_NONE;
              Result.Detail := 'paned';
              Result.Painter := gptFlatBox;
            end;
        end;
      end;
    teWindow:
      begin
        if Details.Part in [WP_MDIMINBUTTON, WP_MDIRESTOREBUTTON, WP_MDICLOSEBUTTON] then
        begin
          Result.State := GtkTitleButtonMap[Details.State];
          Result.Shadow := GTK_SHADOW_NONE;
          case Details.Part of
            WP_MDIMINBUTTON: Result.Detail := #1;
            WP_MDIRESTOREBUTTON: Result.Detail := #2;
            WP_MDICLOSEBUTTON: Result.Detail := #3;
          end;
          Result.Painter := gptPixmap;
        end;
      end;
    teTab:
      begin
        Result.Widget := GetStyleWidget(lgsNotebook);
        if Result.Style = nil then
          Result.Style := GetStyle(lgsNotebook);
        Result.State := GTK_STATE_NORMAL;
        Result.Shadow := GTK_SHADOW_OUT;
        Result.Detail := 'notebook';
        if Details.Part in [TABP_PANE, TABP_BODY] then
        begin
          {Result.GapSide := GTK_POS_TOP;
          Result.GapX := 20;
          Result.GapWidth := 40;}
          Result.Painter := gptBox;
        end;
      end;
    teToolTip:
      begin
        Result.Style := GetStyle(lgsTooltip);
        Result.Widget := GetStyleWidget(lgsTooltip);
        Result.State := GTK_STATE_NORMAL;
        Result.Shadow := GTK_SHADOW_OUT;
        Result.Detail := 'tooltip';
        if Details.Part = TTP_STANDARD then
          Result.Painter := gptFlatBox;
      end;
  end;
  if Result.Style = nil then
    Result.Style := gtk_widget_get_default_style();
end;


function TGtk2ThemeServices.GetGtkStyleParams(DC: HDC;
  Details: TThemedElementDetails; AIndex: Integer): TGtkStyleParams;
begin
  Result := GetGtk1StyleParams(DC, Details, AIndex);
  
  // override some styles
  if Result.Style <> nil then
    case Details.Element of
      teHeader:
        begin
          Result.Widget := GetColumnButtonFromTreeView(GetStyleWidget(lgsTreeView));
          if Result.Widget = nil then
            Result.Widget := GetStyleWidget(lgsTreeView);
          Result.State := GtkButtonMap[Details.State];
          if Details.State = PBS_PRESSED then
            Result.Shadow := GTK_SHADOW_IN
          else
            Result.Shadow := GTK_SHADOW_OUT;

          Result.IsHot:= Result.State = GTK_STATE_PRELIGHT;

          Result.Detail := 'button';
          Result.Painter := gptBox;
        end;
      teRebar:
        begin
          case Details.Part of
            RP_GRIPPER, RP_GRIPPERVERT:
              begin
                Result.State := GTK_STATE_NORMAL;
                Result.Shadow := GTK_SHADOW_NONE;
                Result.Detail := 'paned';
                Result.Painter := gptHandle;
                if Details.Part = RP_GRIPPER then
                begin
                  Result.Orientation := GTK_ORIENTATION_VERTICAL;
                  Result.Widget := GetStyleWidget(lgsVerticalPaned);
                end
                else
                begin
                  Result.Orientation := GTK_ORIENTATION_HORIZONTAL;
                  Result.Widget := GetStyleWidget(lgsHorizontalPaned);
                end;
              end;
            RP_BAND:
              begin
                Result.Widget := GetStyleWidget(lgsVerticalPaned);
                Result.State := GtkButtonMap[Details.State];
                Result.Shadow := GTK_SHADOW_NONE;
                Result.Detail := 'paned';
                Result.Painter := gptFlatBox;
              end;
          end;
        end;
      teTreeview:
        begin
          if Details.Part in [TVP_GLYPH, TVP_HOTGLYPH] then
          begin
            Result.Painter := gptExpander;
            Result.Shadow := GTK_SHADOW_NONE;
            if Details.Part = TVP_GLYPH then
              Result.State := GTK_STATE_NORMAL
            else
              Result.State := GTK_STATE_PRELIGHT;
            Result.Widget := GetStyleWidget(lgsTreeView);
            Result.Detail := 'treeview';
            if Details.State = GLPS_CLOSED then
              Result.Expander := GTK_EXPANDER_COLLAPSED
            else
              Result.Expander := GTK_EXPANDER_EXPANDED;

            Result.ExpanderSize := GetDetailSize(Details).cx;
          end
          else
          if Details.Part = TVP_TREEITEM then
          begin
            Result.Widget := GetStyleWidget(lgsTreeView);
            Result.Shadow := GTK_SHADOW_NONE;
            if AIndex = 0 then
            begin
              Result.Painter := gptFlatBox;
              case Details.State of
                TREIS_SELECTED,
                TREIS_HOTSELECTED: Result.State := GTK_STATE_SELECTED;
                TREIS_SELECTEDNOTFOCUS: Result.State := GTK_STATE_ACTIVE;
                TREIS_HOT: Result.State := GTK_STATE_PRELIGHT;
                TREIS_DISABLED: Result.State := GTK_STATE_INSENSITIVE;
              else
                Result.State := GTK_STATE_NORMAL;
              end;
              Result.Detail := 'cell_even';
            end
            else
            if AIndex = 1 then
            begin
              Result.Detail := 'treeview';
              if Details.State = TREIS_SELECTED then
              begin
                Result.State := GTK_STATE_SELECTED;
                Result.Painter := gptFocus
              end
              else
              begin
                Result.State := GTK_STATE_NORMAL;
                Result.Painter := gptNone;
              end;
            end;
          end;
        end;
    end;
end;

function TGtk2ThemeServices.GetParamsCount(Details: TThemedElementDetails): Integer;
begin
  if (Details.Element = teTreeview) and (Details.Part = TVP_TREEITEM) then
    Result := 2
  else
  begin
    Result := 1;
    if (Details.Element = teToolBar) and (Details.Part = TP_SPLITBUTTONDROPDOWN) then
      inc(Result); // + Arrow
  end;
end;

function TGtk2ThemeServices.GetDetailSize(Details: TThemedElementDetails): TSize;
var
  AValue: TGValue;
begin
  if (Details.Element = teTreeView) and (Details.Part in [TVP_GLYPH, TVP_HOTGLYPH]) then
  begin
    FillChar(AValue, SizeOf(AValue), 0);
    g_value_init(@AValue, G_TYPE_INT);
    gtk_widget_style_get_property(GetStyleWidget(lgsTreeView), 'expander-size', @AValue);
    Result := Size(AValue.data[0].v_int, AValue.data[0].v_int);
  end
  else
    Result := GetBaseDetailsSize(Details);
end;

function TGtk2ThemeServices.GetStockImage(StockID: LongInt; out Image, Mask: HBitmap): Boolean;
var
  GDIObj: PGDIObject;
  StockName: PChar;
  Style: PGtkStyle;
  IconSet: PGtkIconSet;
  Pixbuf: PGDKPixbuf;
begin
  case StockID of
    idButtonOk: StockName := GTK_STOCK_OK;
    idButtonCancel: StockName := GTK_STOCK_CANCEL;
    idButtonYes: StockName := GTK_STOCK_YES;
    idButtonYesToAll: StockName := GTK_STOCK_YES;
    idButtonNo: StockName := GTK_STOCK_NO;
    idButtonNoToAll: StockName := GTK_STOCK_NO;
    idButtonHelp: StockName := GTK_STOCK_HELP;
    idButtonAbort: StockName := GTK_STOCK_STOP;
    idButtonClose: StockName := GTK_STOCK_CLOSE;
    // this is disputable but anyway stock icons looks like our own
    idButtonAll: StockName := GTK_STOCK_APPLY;
    idButtonIgnore: StockName := GTK_STOCK_DELETE;
    idButtonRetry: StockName := GTK_STOCK_REFRESH;
    idButtonOpen: StockName := GTK_STOCK_OPEN;
    idButtonSave: StockName := GTK_STOCK_SAVE;
    idButtonShield: StockName := GTK_STOCK_DIALOG_AUTHENTICATION;

    idDialogWarning : StockName := GTK_STOCK_DIALOG_WARNING;
    idDialogError: StockName := GTK_STOCK_DIALOG_ERROR;
    idDialogInfo: StockName := GTK_STOCK_DIALOG_INFO;
    idDialogConfirm: StockName := GTK_STOCK_DIALOG_QUESTION;
    idDialogShield: StockName := GTK_STOCK_DIALOG_AUTHENTICATION;
  else
    begin
       Result := inherited GetStockImage(StockID, Image, Mask);
       Exit;
    end;
  end;

  if (StockID >= idButtonBase) and (StockID <= idDialogBase) then
    Style := GetStyle(lgsButton)
  else
    Style := GetStyle(lgsWindow);

  if (Style = nil) or (not GTK_IS_STYLE(Style)) then
  begin
    Result := inherited GetStockImage(StockID, Image, Mask);
    Exit;
  end;

  IconSet := gtk_style_lookup_icon_set(Style, StockName);

  if (IconSet = nil) then
  begin
    Result := inherited GetStockImage(StockID, Image, Mask);
    Exit;
  end;

  if (StockID >= idButtonBase) and (StockID <= idDialogBase) then
    Pixbuf := gtk_icon_set_render_icon(IconSet, Style,
      GTK_TEXT_DIR_NONE, GTK_STATE_NORMAL, GTK_ICON_SIZE_BUTTON, GetStyleWidget(lgsbutton), nil)
  else
    Pixbuf := gtk_icon_set_render_icon(IconSet, Style,
      GTK_TEXT_DIR_NONE, GTK_STATE_NORMAL, GTK_ICON_SIZE_DIALOG, GetStyleWidget(lgswindow), nil);

  GDIObj := Gtk2Widgetset.NewGDIObject(gdiBitmap);
  with GDIObj^ do
  begin
    GDIBitmapType := gbPixbuf;
    visual := gdk_visual_get_system();
    gdk_visual_ref(visual);
    colormap := gdk_colormap_get_system();
    gdk_colormap_ref(colormap);
    GDIPixbufObject := Pixbuf;
  end;

  Image := HBitmap(PtrUInt(GDIObj));
  Mask := 0;
  Result := True;
end;

procedure ButtonImagesChange(ASettings: PGtkSettings; pspec: PGParamSpec; Services: TGtk2ThemeServices); cdecl;
begin
  Application.IntfThemeOptionChange(Services, toShowButtonImages);
  Services.IntfDoOnThemeChange;
end;

procedure MenuImagesChange(ASettings: PGtkSettings; pspec: PGParamSpec; Services: TGtk2ThemeServices); cdecl;
begin
  Application.IntfThemeOptionChange(Services, toShowMenuImages);
  Services.IntfDoOnThemeChange;
end;

function TGtk2ThemeServices.GetOption(AOption: TThemeOption): Integer;
var
  ASettings: PGtkSettings;
  BoolSetting: gboolean;
  Widget: PGtkWidget;
  Signal: guint;
begin
  case AOption of
    toShowButtonImages:
      begin
        Widget := GetStyleWidget(lgsButton);
        ASettings := gtk_widget_get_settings(Widget);
        BoolSetting := True; // default
        g_object_get(ASettings, 'gtk-button-images', @BoolSetting, nil);
        Result := Ord(BoolSetting = True);
        if g_object_get_data(PGObject(Widget), 'lcl-images-change-callback') = nil then
        begin
          Signal := g_signal_connect(ASettings, 'notify::gtk-button-images', TGCallback(@ButtonImagesChange), Self);
          g_object_set_data(PGObject(Widget), 'lcl-images-change-callback', Pointer(PtrUInt(Signal)))
        end;
      end;
    toShowMenuImages:
      begin
        Widget := GetStyleWidget(lgsMenuitem);
        ASettings := gtk_widget_get_settings(Widget);
        BoolSetting := False; // default
        g_object_get(ASettings, 'gtk-menu-images', @BoolSetting, nil);
        Result := Ord(BoolSetting = True);
        if g_object_get_data(PGObject(Widget), 'lcl-images-change-callback') = nil then
        begin
          Signal := g_signal_connect(ASettings, 'notify::gtk-menu-images', TGCallback(@MenuImagesChange), Self);
          g_object_set_data(PGObject(Widget), 'lcl-images-change-callback', Pointer(PtrUInt(Signal)))
        end;
      end;
  else
    Result := inherited GetOption(AOption);
  end;
end;

procedure TGtk2ThemeServices.Gtk1DrawElement(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; ClipRect: PRect);
var
  DevCtx: TGtkDeviceContext absolute DC;
  Area: TGdkRectangle;
  StyleParams: TGtkStyleParams;
  i: integer;
  RDest: TRect;
begin
  if IsRectEmpty(R) then
    Exit;
  for i := 0 to GetParamsCount(Details) - 1 do
  begin
    StyleParams := GetGtkStyleParams(DC, Details, i);
    if StyleParams.Style <> nil then
    begin
      if DevCtx.HasTransf then
      begin
        if ClipRect <> nil then RDest := ClipRect^ else RDest := R;
        RDest := DevCtx.TransfRectIndirect(R);
        DevCtx.TransfNormalize(RDest.Left, RDest.Right);
        DevCtx.TransfNormalize(RDest.Top, RDest.Bottom);
        Area := GdkRectFromRect(RDest);
      end
      else if ClipRect <> nil then
        Area := GdkRectFromRect(ClipRect^)
      else
        Area := GdkRectFromRect(R);


      // move to origin
      inc(Area.x, StyleParams.Origin.x);
      inc(Area.y, StyleParams.Origin.y);

      with StyleParams do
      begin
        if Painter = gptExpander then
        begin
          // Better to draw expander with the ExpanderSize, but sometimes it
          // will not look very well. The best can we do is to use the same odd/even
          // amount of pixels => expand/shrink area.width and area.height a bit

          // Area.width := ExpanderSize;
          if Odd(Area.width) <> Odd(ExpanderSize) then
            if Area.width < ExpanderSize then
              inc(Area.width)
            else
              dec(Area.width);
          // Area.height := ExpanderSize;
          if Odd(Area.height) <> Odd(ExpanderSize) then
            if Area.height < ExpanderSize then
              inc(Area.height)
            else
              dec(Area.height);
        end;
        if (MaxWidth <> 0) then
        begin
          if Area.width > MaxWidth then
          begin
            inc(Area.x, (Area.width - MaxWidth) div 2);
            Area.width := MaxWidth;
          end;
        end;
        case Painter of
          gptDefault: inherited DrawElement(DC, Details, R, ClipRect);
          gptBox:
            gtk_paint_box(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptBoxGap:
            gtk_paint_box_gap(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height,
              GapSide, GapX, GapWidth);
          gptHLine  : gtk_paint_hline(
              Style, Window,
              State, @Area,
              Widget, PChar(Detail),
              Area.x, Area.x + Area.Width, Area.y);
          gptVLine  : gtk_paint_vline(
              Style, Window,
              State, @Area,
              Widget, PChar(Detail),
              Area.y, Area.y + Area.Height, Area.x);
          gptShadow : gtk_paint_shadow(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptFlatBox: gtk_paint_flat_box(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptCheck  : gtk_paint_check(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptOption : gtk_paint_option(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptTab    : gtk_paint_tab(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptSlider : gtk_paint_slider(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height,
              Orientation);
          gptHandle : gtk_paint_handle(
              Style, Window,
              State, Shadow,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height,
              Orientation);

          gptExpander: gtk_paint_expander(
              Style, Window, State,
              @Area, Widget, PChar(Detail),
              Area.x + Area.width shr 1, Area.y + Area.height shr 1,
              Expander);
          gptResizeGrip: gtk_paint_resize_grip(
              Style, Window, State,
              @Area, Widget,
              PChar(Detail), Edge,
              Area.x, Area.y,
              Area.Width, Area.Height);

          gptFocus : gtk_paint_focus(
              Style, Window, State,
              @Area, Widget, PChar(Detail),
              Area.x, Area.y,
              Area.Width, Area.Height);
          gptArrow: gtk_paint_arrow(
             Style, Window,
             State, Shadow,
             @Area, Widget, PChar(Detail),
             ArrowType, Fill,
             Area.x, Area.y, Area.width, Area.height
           );
          gptPixmap: DrawPixmap(DC, @Area, Ord(Detail[1]));
        end;
      end;
    end;
  end;
end;

procedure TGtk2ThemeServices.DrawElement(DC: HDC;
  Details: TThemedElementDetails; const R: TRect; ClipRect: PRect);
var
  Widget: PGtkWidget;
begin
  if (Details.Element = teTreeview) and (Details.Part = TVP_TREEITEM) and
     (Details.State = TREIS_SELECTED) then
  begin
    // lie to cleanlooks theme
    Widget := GetStyleWidget(lgsTreeView);
    GTK_WIDGET_SET_FLAGS(Widget, GTK_HAS_FOCUS);
    Gtk1DrawElement(DC, Details, R, ClipRect);
    GTK_WIDGET_UNSET_FLAGS(Widget, GTK_HAS_FOCUS);
  end
  else
    Gtk1DrawElement(DC, Details, R, ClipRect);
end;

procedure TGtk2ThemeServices.DrawIcon(DC: HDC; Details: TThemedElementDetails;
  const R: TRect; himl: HIMAGELIST; Index: Integer);
begin

end;

procedure TGtk2ThemeServices.DrawText(DC: HDC; Details: TThemedElementDetails;
  const S: String; R: TRect; Flags, Flags2: Cardinal);
var
  StyleParams: TGtkStyleParams;
  P: PChar;
  tmpRect: TRect;
begin
  StyleParams := GetGtkStyleParams(DC, Details, 0);
  if StyleParams.Style <> nil then
    with StyleParams do
    begin
      P := PChar(S);
      tmpRect := R;
      Gtk2Widgetset.DrawText(DC, P, Length(S), tmpRect, Flags);
      // TODO: parse flags
      //gtk_draw_string(Style, Window, State, R.Left + Origin.x, R.Top + Origin.y, P);
    end;
end;

function TGtk2ThemeServices.ContentRect(DC: HDC;
  Details: TThemedElementDetails; BoundingRect: TRect): TRect;
var
  StyleParams: TGtkStyleParams;
begin
  Result := BoundingRect;
  StyleParams := GetGtkStyleParams(DC, Details, 0);
  if StyleParams.Style <> nil then
    InflateRect(Result,
      -StyleParams.Style^.xthickness,
      -StyleParams.Style^.ythickness);
end;

function TGtk2ThemeServices.HasTransparentParts(Details: TThemedElementDetails): Boolean;
begin
  Result := True; // ?
end;

end.
