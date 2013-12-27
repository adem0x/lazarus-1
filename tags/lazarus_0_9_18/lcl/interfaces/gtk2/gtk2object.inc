{%MainUnit gtk2int.pp}
{******************************************************************************
                                   TGtk2WidgetSet
 ******************************************************************************

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

{$IFOPT C-}
// Uncomment for local trace
//  {$C+}
//  {$DEFINE ASSERT_IS_ON}
{$ENDIF}

function GTK2FocusCB( widget: PGtkWidget; event:PGdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
var
  Status : gBoolean;
begin
  Status := GTKFocusCB(Widget, Event, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

function GTK2FocusCBAfter(widget: PGtkWidget; event:PGdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
var
  Status : gBoolean;
begin
  Status := GTKFocusCBAfter(Widget, Event, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

function gtk2HideCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
var
   Status : GBoolean;
begin
  Status := gtkHideCB(Widget, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

function GTK2KeyDown(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
begin
  //debugln('GTK2KeyDown ',DbgSName(TObject(Data)));
  Result := HandleGtkKeyUpDown(Widget, Event, Data, True);
end;

function GTK2KeyDownAfter(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
begin
  //debugln('GTK2KeyDownAfter ',DbgSName(TObject(Data)));
  Result := HandleGtkKeyUpDown(Widget, Event, Data, False);
end;

function GTK2KeyUp(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
begin
  //debugln('GTK2KeyUp ',DbgSName(TObject(Data)));
  Result := HandleGtkKeyUpDown(Widget, Event, Data, True);
end;

function GTK2KeyUpAfter(Widget: PGtkWidget; Event : pgdkeventkey;
  Data: gPointer) : GBoolean; cdecl;
begin
  //debugln('GTK2KeyUpAfter ',DbgSName(TObject(Data)));
  Result := HandleGtkKeyUpDown(Widget, Event, Data, False);
end;

function GTK2KillFocusCB(widget: PGtkWidget; event:PGdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
var
  Status : gBoolean;
begin
  Status := GTKKillFocusCB(Widget, Event, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

function GTK2KillFocusCBAfter(widget: PGtkWidget; event:PGdkEventFocus;
  data: gPointer) : GBoolean; cdecl;
var
  Status : gBoolean;
begin
  Status := GTKKillFocusCBAfter(Widget, Event, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

function gtk2showCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
var
   Status : GBoolean;
begin
  Status := gtkshowCB(Widget, Data);

  if GtkWidgetIsA(Widget,GTK_APIWIDGETCLIENT_TYPE) then
    Result := Status
  else
    Result := False;
end;

{$IFDEF HasGTK2_6}
procedure Gtk2FileChooserResponseCB(widget: PGtkFileChooser; arg1: gint; data: gpointer); cdecl;

  procedure AddFile(List: TStrings; const NewFile: string);
  var
    i: Integer;
  begin
    for i:=0 to List.Count-1 do
      if List[i]=NewFile then exit;
    List.Add(NewFile);
  end;

var
  TheDialog: TFileDialog;
  cFilename: PChar;
  cFilenames: PGSList;
  cFilenames1: PGSList;
  Files: TStringList;
begin
  theDialog := TFileDialog(data);

  if arg1 = GTK_RESPONSE_CANCEL then begin  
    TheDialog.UserChoice := mrCancel;
    Exit;
  end;

  if theDialog is TOpenDialog then begin
    if ofAllowMultiSelect in TOpenDialog(theDialog).Options then begin
      TheDialog.FileName := '';
      Files := TStringList(TheDialog.Files);
      Files.Clear;

      cFilenames := gtk_file_chooser_get_filenames(widget);
      if Assigned(cFilenames) then begin

        cFilenames1 := cFilenames;
        while Assigned(cFilenames1) do begin
          cFilename := PChar(cFilenames1^.data);

          if Assigned(cFilename) then begin
            AddFile(Files, cFilename);
            g_free(cFilename);
          end;

          cFilenames1 := cFilenames1^.next;
        end;
        
        g_slist_free(cFilenames);
      end;
    end;
  end;

  cFilename := gtk_file_chooser_get_filename(widget);
  if Assigned(cFilename) then begin
    TheDialog.FileName := cFilename;
    g_free(cFilename);
  end;

  //?? StoreCommonDialogSetup(theDialog);
  theDialog.UserChoice := mrOK;
end;
{$ENDIF}

Procedure gtk_clb_toggle(cellrenderertoggle : PGtkCellRendererToggle; arg1 : PGChar;
                         WinControl: TWinControl); cdecl;
var
  aWidget : PGTKWidget;
  aTreeModel : PGtkTreeModel;
  aTreeIter : TGtkTreeIter;
  value : pgValue;
begin
  aWidget := GetWidgetInfo(Pointer(WinControl.Handle), True)^.CoreWidget;
  aTreeModel := gtk_tree_view_get_model (GTK_TREE_VIEW(aWidget));
  if (gtk_tree_model_get_iter_from_string (aTreeModel, @aTreeIter, arg1)) then begin
    aTreeIter.stamp := GTK_LIST_STORE (aTreeModel)^.stamp; //strange hack
    value := g_new0(SizeOf(TgValue), 1);
    gtk_tree_model_get_value(aTreeModel, @aTreeIter, 0, value);

    g_value_set_boolean(value, not g_value_get_boolean(value));

    gtk_list_store_set_value (GTK_LIST_STORE (aTreeModel), @aTreeIter, 0, value);
    g_value_unset(value);
    g_free(value);
  end;
end;

Procedure gtk_clb_toggle_row_activated(treeview : PGtkTreeView; arg1 : PGtkTreePath;
                                  arg2 : PGtkTreeViewColumn; data : gpointer); cdecl;
var
  aTreeModel : PGtkTreeModel;
  aTreeIter : TGtkTreeIter;
  value : PGValue;
begin
  aTreeModel := gtk_tree_view_get_model (treeview);
  if (gtk_tree_model_get_iter (aTreeModel, @aTreeIter, arg1)) then begin
    aTreeIter.stamp := GTK_LIST_STORE (aTreeModel)^.stamp; //strange hack
    value := g_new0(SizeOf(TgValue), 1);
    gtk_tree_model_get_value(aTreeModel, @aTreeIter, 0, value);

    g_value_set_boolean(value, not g_value_get_boolean(value));

    gtk_list_store_set_value (GTK_LIST_STORE (aTreeModel), @aTreeIter, 0, value);
    g_value_unset(value);
    g_free(value);
  end;
end;

{$IfNDef GTK2_2}
Procedure gtkTreeSelectionCountSelectedRows(model : PGtkTreeModel; path : PGtkTreePath;
                                  iter : PGtkTreeIter; data : PGint); cdecl;
begin
  If Assigned(Data) then
    Inc(Data^);
end;

Type
  PPGList = ^PGList;
  
Procedure gtkTreeSelectionGetSelectedRows(model : PGtkTreeModel; path : PGtkTreePath;
                                  iter : PGtkTreeIter; data : PPGList); cdecl;
begin
  If Assigned(Data) then
    Data^ := g_list_append(Data^, gtk_tree_path_copy(path));
end;
{$EndIf}

{------------------------------------------------------------------------------
  procedure TGtk2WidgetSet.AppendText(Sender: TObject; Str: PChar);
 ------------------------------------------------------------------------------}
procedure TGtk2WidgetSet.AppendText(Sender: TObject; Str: PChar);
var
  Widget : PGtkWidget;
  aTextBuffer : PGtkTextBuffer;
  aTextIter1  : TGtkTextIter;
  aTextIter2  : TGtkTextIter;
begin
  if Str=nil then exit;

  if (Sender is TWinControl) then begin
    case TWinControl(Sender).fCompStyle of
      csMemo:
      begin
       Widget:= GetWidgetInfo(Pointer(TWinControl(Sender).Handle), True)^.CoreWidget;
        aTextBuffer := gtk_text_view_get_buffer(GTK_TEXT_VIEW(Widget));
        gtk_text_buffer_begin_user_action(aTextBuffer);
        gtk_text_buffer_get_bounds(aTextBuffer, @aTextIter1, @aTextIter2);
        gtk_text_buffer_insert(aTextBuffer, @aTextIter2, str, StrLen(str));
        gtk_text_buffer_end_user_action(aTextBuffer);
      end;
      {else
        inherited AppendText(Sender, Str);}
    end;
  end;
end;

function TGtk2WidgetSet.CreateComponent(Sender : TObject): THandle;
var
  p: PGtkWidget;                 // ptr to the newly created GtkWidget
  CompStyle: integer;            // componentstyle (type) of GtkWidget which will be created
  SetupProps : boolean;
begin
  p := nil;
  SetupProps:= false;

  CompStyle := GetCompStyle(Sender);

  case CompStyle of
  csEdit :
    begin
      p :=  gtk_entry_new();
      gtk_editable_set_editable (PGtkEditable(P), not TCustomEdit(Sender).ReadOnly);
      gtk_widget_show_all(P);
    end;
    else begin
      Result:=Inherited CreateComponent(Sender);
      Exit;
    end;
  end; //end case
  FinishComponentCreate(Sender, P, SetupProps);
  Result := THandle(P);
end;

function TGtk2WidgetSet.GetText(Sender: TComponent; var Text: String): Boolean;
var
  CS: PChar;
  Widget : PGtkWidget;
  aTextBuffer : PGtkTextBuffer;
  aTextIter1  : TGtkTextIter;
  aTextIter2  : TGtkTextIter;
begin
  Result := True;
  case TControl(Sender).fCompStyle of
   csEdit: begin
             Widget:= GTK_WIDGET(Pointer(TWinControl(Sender).Handle));
             CS := gtk_editable_get_chars(GTK_EDITABLE(Widget), 0, -1);
             Text := StrPas(CS);
             g_free(CS);
           end;

   csMemo    : begin
                 Widget:= GetWidgetInfo(Pointer(TWinControl(Sender).Handle), True)^.CoreWidget;
                  aTextBuffer := gtk_text_view_get_buffer(GTK_TEXT_VIEW(Widget));
                  gtk_text_buffer_get_bounds(aTextBuffer, @aTextIter1, @aTextIter2);
                  CS := gtk_text_buffer_get_text(aTextBuffer, @aTextIter1, @aTextIter2, True);
                  Text := StrPas(CS);
                  g_free(CS);
               end;
  {else
    Result := inherited GetText(Sender, Text);}
  end;
end;


procedure Tgtk2widgetset.HookSignals(const AGTKObject: PGTKObject; const ALCLObject: TObject);
begin
  if (ALCLObject is TWinControl) then
     Begin
       inherited HookSignals(AGTKObject,ALCLObject);
     End;

  if (ALCLObject is TControl) then begin
    case TControl(ALCLObject).FCompStyle of
    csEdit:
      begin
        SetCallback(LM_CHANGED, AGTKObject, ALCLObject);
        SetCallback(LM_ACTIVATE, AGTKObject,ALCLObject);
        SetCallback(LM_CUTTOCLIP, AGTKObject,ALCLObject);
        SetCallback(LM_COPYTOCLIP, AGTKObject,ALCLObject);
        SetCallback(LM_PASTEFROMCLIP, AGTKObject,ALCLObject);
      end;

    csMemo:
      begin
        // SetCallback(LM_CHANGED, AGTKObject,ALCLObject);
        //SetCallback(LM_ACTIVATE, AGTKObject,ALCLObject);
        SetCallback(LM_CUTTOCLIP, AGTKObject,ALCLObject);
        SetCallback(LM_COPYTOCLIP, AGTKObject,ALCLObject);
        SetCallback(LM_PASTEFROMCLIP, AGTKObject,ALCLObject);
       //SetCallback(LM_INSERTTEXT, AGTKObject,ALCLObject);
      end;
    end; //case
  end
  else
    If (ALCLObject is TMenuItem) then begin
      SetCallback(LM_ACTIVATE,AGTKObject,ALCLObject);
    end;
end;

{------------------------------------------------------------------------------
  Function: TGtk2WidgetSet.SetCallback
  Params: Msg - message for which to set a callback
          sender - object to which callback will be send
  Returns:  nothing

  Applies a Message to the sender
 ------------------------------------------------------------------------------}
procedure TGTK2WidgetSet.SetCallback(const AMsg: LongInt; const AGTKObject: PGTKObject; const ALCLObject: TObject);

  procedure ConnectSenderSignal(const AnObject:PGTKObject; const ASignal: PChar;
    const ACallBackProc: Pointer);
  begin
    ConnectSignal(AnObject,ASignal,ACallBackProc,TComponent(ALCLObject));
  end;

  procedure ConnectSenderSignalAfter(const AnObject:PGTKObject;
    const ASignal: PChar; const ACallBackProc: Pointer);
  begin
    ConnectSignalAfter(AnObject,ASignal,ACallBackProc,TComponent(ALCLObject));
  end;

  procedure ConnectSenderSignal(const AnObject:PGTKObject; const ASignal: PChar;
    const ACallBackProc: Pointer; const ReqSignalMask: TGdkEventMask);
  begin
    ConnectSignal(AnObject,ASignal,ACallBackProc,ALCLObject,
                  ReqSignalMask);
  end;

  procedure ConnectSenderSignalAfter(const AnObject:PGTKObject;
    const ASignal: PChar; const ACallBackProc: Pointer;
    const ReqSignalMask: TGdkEventMask);
  begin
    ConnectSignalAfter(AnObject,ASignal,ACallBackProc,ALCLObject,
                       ReqSignalMask);
  end;

  procedure ConnectFocusEvents(const AnObject: PGTKObject);
  begin
    ConnectSenderSignal(AnObject, 'focus-in-event', @gtk2FocusCB);
    ConnectSenderSignalAfter(AnObject, 'focus-in-event', @gtk2FocusCBAfter);
    ConnectSenderSignal(AnObject, 'focus-out-event', @gtk2KillFocusCB);
    ConnectSenderSignalAfter(AnObject, 'focus-out-event', @gtk2KillFocusCBAfter);
  end;

  procedure ConnectKeyPressReleaseEvents(const AnObject: PGTKObject);
  begin
    //debugln('gtk2object ConnectKeyPressReleaseEvents A ALCLObject=',DbgSName(ALCLObject));
    ConnectSenderSignal(AnObject,
      'key-press-event', @GTK2KeyDown, GDK_KEY_PRESS_MASK);
    ConnectSenderSignalAfter(AnObject,
      'key-press-event', @GTK2KeyDownAfter, GDK_KEY_PRESS_MASK);
    ConnectSenderSignal(AnObject,
      'key-release-event', @GTK2KeyUp, GDK_KEY_RELEASE_MASK);
    ConnectSenderSignalAfter(AnObject,
      'key-release-event', @GTK2KeyUpAfter, GDK_KEY_RELEASE_MASK);
  end;

var
  gObject, gFixed, gCore: PGTKObject;
begin
  //debugln('gtk2object.inc TGtkWidgetSet.SetCallback A ALCLObject=',DbgSName(ALCLObject),' AMsg=',dbgs(AMsg));
  gObject := AGTKObject;
  if gObject = nil then Exit;

  // gFixed is the widget with the client area (e.g. TGroupBox, TForm have this)
  gFixed := PGTKObject(GetFixedWidget(gObject));
  if gFixed = nil then gFixed := gObject;

  // gCore is the main widget (e.g. TListView has this)
  gCore:= PGtkObject(GetWidgetInfo(gObject, True)^.CoreWidget);

  case AMsg of
    LM_FOCUS :
    begin
      if (ALCLObject is TCustomComboBox) then begin
        ConnectFocusEvents(PgtkObject(PgtkCombo(gObject)^.entry));
        ConnectFocusEvents(PgtkObject(PgtkCombo(gObject)^.list));
      end else begin
        ConnectFocusEvents(gCore);
      end;
    end;

    LM_CHAR,
    LM_KEYDOWN,
    LM_KEYUP,
    
    LM_SYSCHAR,
    LM_SYSKEYDOWN,
    LM_SYSKEYUP:
    begin
      if (ALCLObject is TCustomComboBox) then begin
        ConnectKeyPressReleaseEvents(PgtkObject(PgtkCombo(gObject)^.entry));
      end
      else if (ALCLObject is TCustomForm) then begin
        ConnectKeyPressReleaseEvents(gObject);
      end;
      ConnectKeyPressReleaseEvents(gCore);
    end;


    LM_SHOWWINDOW :
    begin
      ConnectSenderSignal(gObject, 'show', @gtk2showCB);
      ConnectSenderSignal(gObject, 'hide', @gtk2hideCB);
    end;

  else
    Inherited SetCallback(AMsg, AGTKObject, ALCLObject);
  end;
end;

Function TGtk2WidgetSet.LoadStockPixmap(StockID: longint) : HBitmap;
var
  Pixmap : PGDIObject;
  StockName : PChar;
  IconSet : PGtkIconSet;
  Pixbuf : PGDKPixbuf;
begin
  Case StockID Of
    idButtonOk : StockName := GTK_STOCK_OK;
    idButtonCancel : StockName := GTK_STOCK_CANCEL;
    idButtonYes : StockName := GTK_STOCK_YES;
    idButtonNo : StockName := GTK_STOCK_NO;
    idButtonHelp : StockName := GTK_STOCK_HELP;
    idButtonAbort : StockName := GTK_STOCK_CANCEL;
    idButtonClose : StockName := GTK_STOCK_QUIT;

    idDialogWarning : StockName := GTK_STOCK_DIALOG_WARNING;
    idDialogError : StockName := GTK_STOCK_DIALOG_ERROR;
    idDialogInfo : StockName := GTK_STOCK_DIALOG_INFO;
    idDialogConfirm : StockName := GTK_STOCK_DIALOG_QUESTION;
   else begin
      Result := inherited LoadStockPixmap(StockID);
      exit;
    end;
  end;

  if (StockID >= idButtonBase) and (StockID <= idDialogBase) then
    IconSet := gtk_style_lookup_icon_set(GetStyle(lgsButton), StockName)
  else
    IconSet := gtk_style_lookup_icon_set(GetStyle(lgsWindow), StockName);

  If (IconSet = nil) then begin
    Result := inherited LoadStockPixmap(StockID);
    exit;
  end;

  if (StockID >= idButtonBase) and (StockID <= idDialogBase) then
    pixbuf := gtk_icon_set_render_icon(IconSet, GetStyle(lgsbutton), GTK_TEXT_DIR_NONE, GTK_STATE_NORMAL, GTK_ICON_SIZE_BUTTON, GetStyleWidget(lgsbutton), nil)
  else
    pixbuf := gtk_icon_set_render_icon(IconSet, GetStyle(lgswindow), GTK_TEXT_DIR_NONE, GTK_STATE_NORMAL, GTK_ICON_SIZE_DIALOG, GetStyleWidget(lgswindow), nil);

  Pixmap := NewGDIObject(gdiBitmap);
  With Pixmap^ do begin
    GDIBitmapType := gbPixmap;
    visual := gdk_visual_get_system();
    gdk_visual_ref(visual);
    colormap := gdk_colormap_get_system();
    gdk_colormap_ref(colormap);
    gdk_pixbuf_render_pixmap_and_mask(pixbuf, GDIPixmapObject, GDIBitmapMaskObject, 128);
  end;

  gdk_pixbuf_unref(pixbuf);
  Result := HBitmap(Pixmap);
end;

(*
{------------------------------------------------------------------------------
  Method: TGtk2WidgetSet.SetLabel
  Params:  sender - the calling object
           data   - String (PChar) to be set as label for a control
  Returns: Nothing

  Sets the label text on a widget
 ------------------------------------------------------------------------------}
procedure TGtk2WidgetSet.SetLabel(Sender : TObject; Data : Pointer);
var
  Widget : PGtkWidget;
  aTextBuffer : PGtkTextBuffer;
  aTextIter1  : TGtkTextIter;
  aTextIter2  : TGtkTextIter;

  DC : hDC;
  aLabel, pLabel: pchar;
  AccelKey : integer;
begin
  if Sender is TMenuItem then begin
    //inherited SetLabel(Sender, Data);
    exit;
  end;

  if Sender is TWinControl
  then Assert(False, Format('Trace:  [TGtk2WidgetSet.SetLabel] %s --> label %s', [Sender.ClassName, TControl(Sender).Caption]))
  else begin
    Assert(False, Format('Trace:WARNING: [TGtk2WidgetSet.SetLabel] %s --> No Decendant of TWinControl', [Sender.ClassName]));
    RaiseGDBException('[TGtk2WidgetSet.SetLabel] ERROR: Sender ('+Sender.Classname+')'
        +' is not TWinControl ');
  end;

  Widget := PGtkWidget(TWinControl(Sender).Handle);
  Assert(Widget = nil, 'Trace:WARNING: [TGtk2WidgetSet.SetLabel] --> got nil pointer');
  Assert(False, 'Trace:Setting Str1 in SetLabel');
  pLabel := pchar(Data);

  case TControl(Sender).fCompStyle of
  csEdit        : begin
                    gtk_entry_set_text(pGtkEntry(Widget), pLabel);
                    {LockOnChange(PGtkObject(Widget),+1);
                    gtk_editable_delete_text(pGtkEditable(P), 0, -1);
                    gtk_editable_insert_text(pGtkEditable(P), pLabel, StrLen(pLabel). 0);
                    LockOnChange(PGtkObject(Widget),-1);}
                  end;

  csLabel:
    begin
      gtk_label_set_use_underline(PGtkLabel(Widget), True);
      if TLabel(Sender).ShowAccelChar then begin
        If TLabel(sender).WordWrap and (TLabel(Sender).Caption<>'') then begin
          DC := GetDC(TLabel(Sender).Handle);
          aLabel := ForceLineBreaks(DC, pLabel, TLabel(Sender).Width, True);
          DeleteDC(DC);
        end
        else
          aLabel:= Ampersands2Underscore(pLabel);

        try
          gtk_label_set_label(pGtkLabel(Widget), aLabel);
          AccelKey:= gtk_label_get_mnemonic_keyval(pGtkLabel(Widget));
          Accelerate(TComponent(Sender),Widget,AccelKey,0,'grab_focus');
        finally
   StrDispose(aLabel);
 end;

      end else begin
        If TLabel(sender).WordWrap then begin
          DC := GetDC(TLabel(Sender).Handle);
          aLabel := ForceLineBreaks(DC, pLabel, TLabel(Sender).Width, False);
          gtk_label_set_label(PGtkLabel(Widget), aLabel);
   StrDispose(aLabel);
          DeleteDC(DC);
        end
        else
          gtk_label_set_label(PGtkLabel(Widget), pLabel);
      end;
    end;

  csMemo        : begin
                    Widget:= PGtkWidget(GetWidgetInfo(Widget, True)^.CoreWidget);
                    aTextBuffer := gtk_text_view_get_buffer(GTK_TEXT_VIEW(Widget));
                    gtk_text_buffer_begin_user_action(aTextBuffer);
                    gtk_text_buffer_get_bounds(aTextBuffer, @aTextIter1, @aTextIter2);
                    gtk_text_buffer_delete(aTextBuffer, @aTextIter1, @aTextIter2);
                    gtk_text_buffer_get_bounds(aTextBuffer, @aTextIter1, @aTextIter2);
                    gtk_text_buffer_insert(aTextBuffer, @aTextIter1, pLabel, StrLen(pLabel));
                    gtk_text_buffer_end_user_action(aTextBuffer);
                  end;
  {else
    inherited SetLabel(Sender, Data);}
  end;
  Assert(False, Format('trace:  [TGtk2WidgetSet.SetLabel] %s --> END', [Sender.ClassName]));
end;
*)


{------------------------------------------------------------------------------
  Method: TGtk2WidgetSet.SetProperties
  Params:  Sender : the lcl object which called this func via SenMessage
  Returns: currently always 0

  Depending on the compStyle, this function will apply all properties of
  the calling object to the corresponding GTK2 object.
 ------------------------------------------------------------------------------}
(*function TGtk2WidgetSet.SetProperties(Sender : TObject) : integer;
const
  cLabelAlignX : array[TAlignment] of gfloat = (0.0, 1.0, 0.5);
  cLabelAlignY : array[TTextLayout] of gfloat = (0.0, 0.5, 1.0);
  cLabelAlign : array[TAlignment] of TGtkJustification = (GTK_JUSTIFY_LEFT, GTK_JUSTIFY_RIGHT, GTK_JUSTIFY_CENTER);
var
  wHandle    : Pointer;
  Widget, ImplWidget   : PGtkWidget;
  i : Longint;
  aTextBuffer : PGtkTextBuffer;
  aTextIter1  : TGtkTextIter;
  aTextIter2  : TGtkTextIter;
begin
  Result := 0;     // default if nobody sets it

  if Sender is TWinControl
  then
    Assert(False, Format('Trace:  [TGtk2WidgetSet.SetProperties] %s', [Sender.ClassName]))
  else
    RaiseGDBException('TGtk2WidgetSet.SetProperties: '
                   +' Sender.ClassName='+Sender.ClassName);

  wHandle:= Pointer(TWinControl(Sender).Handle);
  Widget:= GTK_WIDGET(wHandle);

  case TControl(Sender).fCompStyle of
  csEdit :
    with TCustomEdit(Sender) do
      begin
        gtk_editable_set_editable(GTK_ENTRY(wHandle), not (TCustomEdit(Sender).ReadOnly));
        gtk_entry_set_max_length(GTK_ENTRY(wHandle), TCustomEdit(Sender).MaxLength);
        gtk_entry_set_visibility(GTK_ENTRY(wHandle), (TCustomEdit(Sender).EchoMode = emNormal) and (TCustomEdit(Sender).PassWordChar=#0));
        if (TCustomEdit(Sender).EchoMode = emNone) then
          gtk_entry_set_invisible_char(GTK_ENTRY(wHandle), 0)
        else
          gtk_entry_set_invisible_char(GTK_ENTRY(wHandle), Longint(TCustomEdit(Sender).PassWordChar));
      end;

  csLabel :
     with TLabel(Sender) do
     begin
       gtk_label_set_line_wrap(GTK_LABEL(wHandle), False);
       gtk_misc_set_alignment(GTK_MISC(wHandle), cLabelAlignX[Alignment],
                              0.0);
       gtk_label_set_line_wrap(GTK_LABEL(wHandle), TRUE);
       gtk_label_set_justify(GTK_LABEL(wHandle), cLabelAlign[Alignment]);
     end;

  csMemo:
    begin
      ImplWidget:= GetWidgetInfo(wHandle, true)^.CoreWidget;

      gtk_text_view_set_editable (PGtkTextView(ImplWidget), not TCustomMemo(Sender).ReadOnly);
      if TCustomMemo(Sender).WordWrap then
        gtk_text_view_set_wrap_mode(PGtkTextView(ImplWidget), GTK_WRAP_WORD)
      else
        gtk_text_view_set_wrap_mode(PGtkTextView(ImplWidget), GTK_WRAP_NONE);


      case (Sender as TCustomMemo).Scrollbars of
        ssHorizontal:     gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_ALWAYS, GTK_POLICY_NEVER);
        ssVertical:       gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_NEVER, GTK_POLICY_ALWAYS);
        ssBoth:           gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_ALWAYS, GTK_POLICY_ALWAYS);
        ssAutoHorizontal: gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_AUTOMATIC, GTK_POLICY_NEVER);
        ssAutoVertical:   gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
        ssAutoBoth:       gtk_scrolled_window_set_policy(
                            GTK_SCROLLED_WINDOW(wHandle),
                            GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
      else
        gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(wHandle),
                                       GTK_POLICY_NEVER, GTK_POLICY_NEVER);
      end;

      If (TCustomMemo(Sender).MaxLength >= 0) then begin
          aTextBuffer := gtk_text_view_get_buffer(GTK_TEXT_VIEW(ImplWidget));
   i:= gtk_text_buffer_get_char_count(aTextBuffer);
   if i > TCustomMemo(Sender).MaxLength then begin
             gtk_text_buffer_get_bounds(aTextBuffer, nil, @aTextIter2);
             gtk_text_buffer_get_iter_at_offset(aTextBuffer, @aTextIter1, i);
             gtk_text_buffer_delete(aTextBuffer, @aTextIter1, @aTextIter2);
   end;
      end;
    end;
  else
    Result := inherited SetProperties(Sender);
  end;
end; *)

{------------------------------------------------------------------------------
  procedure TGtk2WidgetSet.SetSelectionMode(Sender: TObject; Widget: PGtkWidget;
    MultiSelect, ExtendedSelect: boolean);
------------------------------------------------------------------------------}
procedure TGtk2WidgetSet.SetSelectionMode(Sender: TObject; Widget: PGtkWidget;
  MultiSelect, ExtendedSelect: boolean);
var
  AControl: TWinControl;
  SelectionMode: TGtkSelectionMode;
  Selection : PGtkTreeSelection;
begin
  AControl:=TWinControl(Sender);
  if (AControl is TWinControl) and
    (AControl.fCompStyle in [csListBox, csCheckListBox, csCListBox]) then
  begin
    if MultiSelect then
      SelectionMode:= GTK_SELECTION_MULTIPLE
    else
      SelectionMode:= GTK_SELECTION_SINGLE;
      
    case AControl.fCompStyle of

    csListBox, csCheckListBox:
      begin
        Selection := gtk_tree_view_get_selection(GTK_TREE_VIEW(
           GetWidgetInfo(Widget, True)^.CoreWidget));
        gtk_tree_selection_set_mode(Selection, SelectionMode);
      end;
     else
       inherited SetSelectionMode(Sender, Widget, MultiSelect, ExtendedSelect);
    end;
  end;
end;

(*
{------------------------------------------------------------------------------
  function TGtk2WidgetSet.SetTopIndex(Sender: TObject; NewTopIndex: integer
    ): integer;
------------------------------------------------------------------------------}
function TGtk2WidgetSet.SetTopIndex(Sender: TObject; NewTopIndex: integer
  ): integer;
var
  aTreeView: PGtkTreeView;
  aTreeModel  : PGtkTreeModel;
  aTreeColumn  : PGtkTreeViewColumn;
  aTreeIter   : TGtkTreeIter;
  aTreePath   : PGtkTreePath;
  Count : Integer;
begin
  Result:=0;
  if not (Sender is TWinControl) then exit;
  case TWinControl(Sender).fCompStyle of

  csListBox, csCheckListBox:
    begin
      aTreeView := GTK_TREE_VIEW(GetWidgetInfo(Pointer(TWinControl(Sender).Handle), True)^.CoreWidget);
      aTreeModel := gtk_tree_view_get_model(aTreeView);

      If NewTopIndex < 0 then
        NewTopIndex := 0
      else begin
        Count := gtk_tree_model_iter_n_children(aTreeModel,nil);

        If NewTopIndex >= Count then
          NewTopIndex := Count - 1;
      end;
      
      if gtk_tree_model_iter_nth_child(aTreeModel,@aTreeIter, nil, NewTopIndex) then begin
        aTreePath := gtk_tree_model_get_path(aTreeModel, @aTreeIter);
        aTreeColumn := gtk_tree_view_get_column(aTreeView, 0);
        gtk_tree_view_scroll_to_cell(aTreeView, aTreePath, aTreeColumn, False, 0.0, 0.0);
        gtk_tree_path_free(aTreePath);
      end;
    end;
  end;
end;
*)

{------------------------------------------------------------------------------
  Function: TGtk2WidgetSet.InitializeOpenDialog
  Params: OpenDialog: TOpenDialog; SelWidget: PGtkWidget
  Returns: -

  Adds some functionality to a gtk file selection dialog.
  - multiselection
  - range selection
  - close on escape
  - file information
  - history pulldown
  - filter pulldown
  - preview control

  requires: gtk+ 2.6
 ------------------------------------------------------------------------------}
procedure TGtk2WidgetSet.InitializeOpenDialog(OpenDialog: TOpenDialog;
  SelWidget: PGtkWidget);
{$IFDEF HasGTK2_6}
var
  FileSelWidget: PGtkFileChooser;
  HelpButton: PGtkWidget;
{$ENDIF}
begin
{$IFDEF HasGTK2_6}
  FileSelWidget := GTK_FILE_CHOOSER(SelWidget);

  // Help button
  if (ofShowHelp in OpenDialog.Options) then begin
    HelpButton := gtk_dialog_add_button(FileSelWidget, GTK_STOCK_HELP, GTK_RESPONSE_NONE);

    g_signal_connect( gtk_object(HelpButton),
      'clicked', gtk_signal_func(@gtkDialogHelpclickedCB), OpenDialog);
  end;

  if ofAllowMultiSelect in OpenDialog.Options then
    gtk_file_chooser_set_select_multiple(FileSelWidget, True);

  // History List - a frame with an option menu
  CreateOpenDialogHistory(OpenDialog, SelWidget);

//  // Filter - a frame with an option menu
  CreateOpenDialogFilter(OpenDialog,SelWidget);

  // Details - a frame with a label
  if (ofViewDetail in OpenDialog.Options) then begin

    // create the frame around the information
    FrameWidget:=gtk_frame_new(PChar(rsFileInformation));
    gtk_box_pack_start(GTK_BOX(FileSelWidget^.main_vbox),
                       FrameWidget,false,false,0);
    gtk_widget_show(FrameWidget);
    // create a HBox, so that the information is left justified
    HBox:=gtk_hbox_new(false,0);
    gtk_container_add(GTK_CONTAINER(FrameWidget), HBox);
    // create the label for the file information
    FileDetailLabel:=gtk_label_new(PChar(rsDefaultFileInfoValue));
    gtk_box_pack_start(GTK_BOX(HBox),FileDetailLabel,false,false,5);
    gtk_widget_show_all(HBox);
  end else
    FileDetailLabel:=nil;
  gtk_object_set_data(PGtkObject(SelWidget), 'FileDetailLabel',
                      FileDetailLabel);

  // preview
  if (OpenDialog is TPreviewFileDialog) then
    CreatePreviewDialogControl(TPreviewFileDialog(OpenDialog), SelWidget);

  // set initial filename
  if OpenDialog.Filename<>'' then
    gtk_file_chooser_set_filename(FileSelWidget, PChar(OpenDialog.Filename));

  //if InitialFilter <> 'none' then
  //  PopulateFileAndDirectoryLists(FileSelWidget, InitialFilter);
{$ELSE}
  inherited InitializeOpenDialog(OpenDialog,SelWidget);
{$ENDIF NONO}
end;

{------------------------------------------------------------------------------
  Function: TGtk2WidgetSet.InitializeFileDialog
  Params: FileDialog: TFileDialog; var SelWidget: PGtkWidget
  Returns: -

  Creates a new TFile/Open/SaveDialog
  requires: gtk+ 2.6
 ------------------------------------------------------------------------------}
procedure TGtk2WidgetSet.InitializeFileDialog(FileDialog: TFileDialog;
  var SelWidget: PGtkWidget; Title: PChar);
{$IFDEF HasGTK2_6}
var
  Action: TGtkFileChooserAction; 
  Button1: String;
{$ENDIF}
begin
{$IFDEF HasGTK2_6}
  Action := GTK_FILE_CHOOSER_ACTION_OPEN;
  Button1 := GTK_STOCK_OPEN;

  if FileDialog is TSaveDialog then begin
    Action := GTK_FILE_CHOOSER_ACTION_SAVE;
    Button1 := GTK_STOCK_CANCEL;
  end;

  SelWidget := gtk_file_chooser_dialog_new(Title, nil, Action, 
    PChar(GTK_STOCK_CANCEL), [GTK_RESPONSE_CANCEL, PChar(Button1), GTK_RESPONSE_OK, nil]);

  g_signal_connect(SelWidget, 'response', gtk_signal_func(@Gtk2FileChooserResponseCB), FileDialog);

(*gtk 2.8 
  if FileDialog is TSaveDialog then begin
    gtk_file_chooser_set_do_overwrite_confirmation(SelWidget,  
      ofOverwritePrompt in TOpenDialog(theDialog).Options);
  end;
*)

  if FileDialog is TOpenDialog then
    InitializeOpenDialog(TOpenDialog(FileDialog), SelWidget);

  InitializeCommonDialog(TCommonDialog(FileDialog), SelWidget);
{$ELSE}
  inherited InitializeFileDialog(FileDialog,SelWidget,Title);
{$ENDIF}
end;

function TGtk2WidgetSet.CreateOpenDialogFilter(OpenDialog: TOpenDialog;
  SelWidget: PGtkWidget): string;
{$IFDEF HasGTK2_6}
var
  FilterList: TFPList;
  i, j: integer;
  s: String;
  GtkFilter: PGtkFileFilter;
{$ENDIF}
begin
{$IFDEF HasGTK2_6}
  ExtractFilterList(OpenDialog.Filter, FilterList, false);
  if FilterList.Count > 0 then begin
    j := 1;
    for i := 0 to FilterList.Count-1 do begin
      GtkFilter := gtk_file_filter_new();

      gtk_file_filter_add_pattern(GtkFilter, PFileSelFilterEntry(FilterList[i])^.Mask);
      gtk_file_filter_set_name(GtkFilter, PFileSelFilterEntry(FilterList[i])^.Description);

      gtk_file_chooser_add_filter(SelWidget, GtkFilter);

      if j = OpenDialog.FilterIndex then 
        gtk_file_chooser_set_filter(SelWidget, GtkFilter);

      Inc(j);
      GtkFilter := nil;
    end;
  end;

  gtk_object_set_data(PGtkObject(SelWidget), 'LCLFilterList', FilterList);

  Result := 'hm'; { Don't use '' as null return as this is used for *.* }
{$ELSE}
  Result:=inherited CreateOpenDialogFilter(OpenDialog,SelWidget);
{$ENDIF}
end;

procedure TGtk2WidgetSet.CreatePreviewDialogControl(
  PreviewDialog: TPreviewFileDialog; SelWidget: PGtkWidget);
{$IFDEF HasGTK2_6}
var
  PreviewWidget: PGtkWidget;
  AControl: TPreviewFileControl;
  FileChooser: PGtkFileChooser;
{$ENDIF}
begin
  {$IFDEF HasGTK2_6}
  AControl := PreviewDialog.PreviewFileControl;
  if AControl = nil then Exit;

  FileChooser := PGtkFileChooser(SelWidget);

  PreviewWidget := PGtkWidget(AControl.Handle);

  gtk_object_set_data(PGtkObject(PreviewWidget),'LCLPreviewFixed',
                      PreviewWidget);
  gtk_widget_set_size_request(PreviewWidget,AControl.Width,AControl.Height);

  gtk_file_chooser_set_preview_widget(FileChooser, PreviewWidget);

  gtk_widget_show(PreviewWidget);
  {$ELSE}
  inherited CreatePreviewDialogControl(PreviewDialog,SelWidget);
  {$ENDIF}
end;

{$IFDEF ASSERT_IS_ON}
  {$UNDEF ASSERT_IS_ON}
  {$C-}
{$ENDIF}