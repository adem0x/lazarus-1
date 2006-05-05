{ $Id$}
{
 *****************************************************************************
 *                             GtkWSExtCtrls.pp                              * 
 *                             ----------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit GtkWSExtCtrls;

{$mode objfpc}{$H+}

interface

uses
  LCLProc, LCLType, LCLIntf, Controls,
{$IFDEF GTK2}
  gtk2, gdk2, gdk2PixBuf, glib2,
{$ELSE GTK2}
  gtk, gdk, glib,
{$ENDIF GTK2}
  GtkGlobals, GtkProc, GtkDef, ExtCtrls, Classes,
  WSExtCtrls, WSLCLClasses, gtkint, interfacebase;

type

  { TGtkWSCustomPage }

  TGtkWSCustomPage = class(TWSCustomPage)
  private
  protected
  public
    class procedure UpdateProperties(const ACustomPage: TCustomPage); override;
  end;

  { TGtkWSCustomNotebook }

  TGtkWSCustomNotebook = class(TWSCustomNotebook)
  private
  protected
  public
    class procedure AddPage(const ANotebook: TCustomNotebook; 
      const AChild: TCustomPage; const AIndex: integer); override;
    class procedure MovePage(const ANotebook: TCustomNotebook; 
      const AChild: TCustomPage; const NewIndex: integer); override;
    class procedure RemovePage(const ANotebook: TCustomNotebook; 
      const AIndex: integer); override;
    
    class function GetNotebookMinTabHeight(const AWinControl: TWinControl): integer; override;
    class function GetNotebookMinTabWidth(const AWinControl: TWinControl): integer; override;
    class function GetTabIndexAtPos(const ANotebook: TCustomNotebook; const AClientPos: TPoint): integer; override;
    class procedure SetPageIndex(const ANotebook: TCustomNotebook; const AIndex: integer); override;
    class procedure SetTabPosition(const ANotebook: TCustomNotebook; const ATabPosition: TTabPosition); override;
    class procedure ShowTabs(const ANotebook: TCustomNotebook; AShowTabs: boolean); override;
  end;

  { TGtkWSPage }

  TGtkWSPage = class(TWSPage)
  private
  protected
  public
  end;

  { TGtkWSNotebook }

  TGtkWSNotebook = class(TWSNotebook)
  private
  protected
  public
  end;

  { TGtkWSShape }

  TGtkWSShape = class(TWSShape)
  private
  protected
  public
  end;

  { TGtkWSCustomSplitter }

  TGtkWSCustomSplitter = class(TWSCustomSplitter)
  private
  protected
  public
    class procedure DrawSplitter(const ASplitter: TCustomSplitter); override;
  end;

  { TGtkWSSplitter }

  TGtkWSSplitter = class(TWSSplitter)
  private
  protected
  public
  end;

  { TGtkWSPaintBox }

  TGtkWSPaintBox = class(TWSPaintBox)
  private
  protected
  public
  end;

  { TGtkWSCustomImage }

  TGtkWSCustomImage = class(TWSCustomImage)
  private
  protected
  public
  end;

  { TGtkWSImage }

  TGtkWSImage = class(TWSImage)
  private
  protected
  public
  end;

  { TGtkWSBevel }

  TGtkWSBevel = class(TWSBevel)
  private
  protected
  public
  end;

  { TGtkWSCustomRadioGroup }

  TGtkWSCustomRadioGroup = class(TWSCustomRadioGroup)
  private
  protected
  public
  end;

  { TGtkWSRadioGroup }

  TGtkWSRadioGroup = class(TWSRadioGroup)
  private
  protected
  public
  end;

  { TGtkWSCustomCheckGroup }

  TGtkWSCustomCheckGroup = class(TWSCustomCheckGroup)
  private
  protected
  public
  end;

  { TGtkWSCheckGroup }

  TGtkWSCheckGroup = class(TWSCheckGroup)
  private
  protected
  public
  end;

  { TGtkWSCustomLabeledEdit }

  TGtkWSCustomLabeledEdit = class(TWSCustomLabeledEdit)
  private
  protected
  public
  end;

  { TGtkWSLabeledEdit }

  TGtkWSLabeledEdit = class(TWSLabeledEdit)
  private
  protected
  public
  end;

  { TGtkWSCustomPanel }

  TGtkWSCustomPanel = class(TWSCustomPanel)
  private
  protected
  public
    class procedure SetColor(const AWinControl: TWinControl); override;
  end;

  { TGtkWSPanel }

  TGtkWSPanel = class(TWSPanel)
  private
  protected
  public
  end;

implementation

{ TGtkWSCustomPage }

procedure TGtkWSCustomPage.UpdateProperties(const ACustomPage: TCustomPage);
begin
  UpdateNotebookPageTab(nil, ACustomPage);
end;

{ TGtkWSCustomNotebook }

procedure TGtkWSCustomNotebook.AddPage(const ANotebook: TCustomNotebook; 
  const AChild: TCustomPage; const AIndex: integer);
{
  Inserts a new page to a notebook at position Index. The ANotebook is a
  TCustomNoteBook, the AChild one of its TCustomPage. Both handles must already
  be created. ANoteBook Handle is a PGtkNoteBook and APage handle is a
  PGtkFixed.
  This procedure creates a new tab with an optional image, the page caption and
  an optional close button. The image and the caption will also be added to the
  tab popup menu.
}
var
  NoteBookWidget: PGtkWidget;  // the notebook
  PageWidget: PGtkWidget;      // the page (content widget)
  TabWidget: PGtkWidget;       // the tab (hbox containing a pixmap, a label
                               //          and a close button)
  TabLabelWidget: PGtkWidget;  // the label in the tab
  MenuWidget: PGtkWidget;      // the popup menu (hbox containing a pixmap and
                               // a label)
  MenuLabelWidget: PGtkWidget; // the label in the popup menu item
begin
  NoteBookWidget:=PGtkWidget(ANoteBook.Handle);
  PageWidget:=PGtkWidget(AChild.Handle);
  
  // Check if already created. if so just show it because it is invisible
  if gtk_notebook_get_tab_label(PGtkNoteBook(NoteBookWidget), PageWidget) <> nil then begin
    gtk_widget_show(PageWidget);
    exit;
  end;
  
  // create the tab (hbox container)
  TabWidget:=gtk_hbox_new(false,1);
  begin
    gtk_object_set_data(PGtkObject(TabWidget), 'TabImage', nil);
    gtk_object_set_data(PGtkObject(TabWidget), 'TabCloseBtn', nil);
    // put a label into the tab
    TabLabelWidget:=gtk_label_new('');
    gtk_object_set_data(PGtkObject(TabWidget), 'TabLabel', TabLabelWidget);
    gtk_widget_show(TabLabelWidget);
    gtk_box_pack_start_defaults(PGtkBox(TabWidget),TabLabelWidget);
  end;
  gtk_widget_show(TabWidget);

  // create popup menu
  MenuWidget:=gtk_hbox_new(false,2);
  begin
    // set icon widget to nil
    gtk_object_set_data(PGtkObject(MenuWidget), 'TabImage', nil);
    // put a label into the menu
    MenuLabelWidget:=gtk_label_new('');
    gtk_object_set_data(PGtkObject(MenuWidget), 'TabLabel', MenuLabelWidget);
    gtk_widget_show(MenuLabelWidget);
    gtk_box_pack_start_defaults(PGtkBox(MenuWidget),MenuLabelWidget);
  end;

  gtk_widget_show(MenuWidget);

  RemoveDummyNoteBookPage(PGtkNotebook(NoteBookWidget));
  gtk_notebook_insert_page_menu(GTK_NOTEBOOK(NotebookWidget), PageWidget,
    TabWidget, MenuWidget, AIndex);

  UpdateNotebookPageTab(ANoteBook, AChild);
  UpdateNoteBookClientWidget(ANoteBook);
end;

procedure TGtkWSCustomNotebook.MovePage(const ANotebook: TCustomNotebook; 
  const AChild: TCustomPage; const NewIndex: integer);
var
  NoteBookWidget: PGtkNotebook;
begin
  NoteBookWidget:=PGtkNotebook(ANoteBook.Handle);
  gtk_notebook_reorder_child(NoteBookWidget, PGtkWidget(AChild.Handle), NewIndex);
  UpdateNoteBookClientWidget(ANoteBook);
end;

procedure TGtkWSCustomNotebook.RemovePage(const ANotebook: TCustomNotebook; 
  const AIndex: integer);
var
  PageWidget: PGtkWidget;
  Page: TCustomPage;
begin
  // The gtk does not provide a function to remove a page without destroying it.
  // Luckily the LCL destroys the Handle, when a page is removed, so this
  // function is not needed.
  // However this is usefull for the TCustomPage.TabVisible property. :)
  Page:=ANotebook.Page[AIndex];
  if not Page.HandleAllocated then exit;
  PageWidget := PGtkWidget(Page.Handle);
  gtk_widget_hide(PageWidget);
end;

function TGtkWSCustomNotebook.GetNotebookMinTabHeight(
  const AWinControl: TWinControl): integer;
var
  NBWidget: PGTKWidget;
  BorderWidth: Integer;
  {$IFDEF Gtk1}
  Requisition: TGtkRequisition;
  {$ENDIF}
  Page: PGtkNotebookPage;
begin
  Result:=inherited GetNotebookMinTabHeight(AWinControl);
  //debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight A ',dbgs(Result));
  exit;

  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight A ',dbgs(AWinControl.HandleAllocated));
  if AWinControl.HandleAllocated then
    NBWidget:=PGTKWidget(AWinControl.Handle)
  else
    NBWidget:=GetStyleWidget(lgsNotebook);

  // ToDo: find out how to create a fully working hidden Notebook style widget

  if (NBWidget=nil) then begin
    Result:=inherited GetNotebookMinTabHeight(AWinControl);
    exit;
  end;
  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight NBWidget: ',GetWidgetDebugReport(NBWidget),
   ' ',dbgs(NBWidget^.allocation.width),'x',dbgs(NBWidget^.allocation.height));
  
  BorderWidth:=(PGtkContainer(NBWidget)^.flag0 and bm_TGtkContainer_border_width)
               shr bp_TGtkContainer_border_width;
  if PGtkNoteBook(NBWidget)^.first_tab<>nil then
    Page:=PGtkNoteBook(NBWidget)^.cur_page;

  Result:=BorderWidth;
  {$IFDEF GTK2}
  if (Page<>nil) then begin
    debugln('TGtkWSCustomNotebook.RemovePage TODO');
  end;
  {$ELSE GTK2}
  if (NBWidget^.thestyle<>nil) and (PGtkStyle(NBWidget^.thestyle)^.klass<>nil) then
    inc(Result,PGtkStyle(NBWidget^.thestyle)^.klass^.ythickness);
  if (Page<>nil) and (Page^.child<>nil) then begin
    gtk_widget_size_request(Page^.Child, @Requisition);
    gtk_widget_map(Page^.child);
    debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight B ',dbgs(Page^.child^.allocation.height),
      ' ',GetWidgetDebugReport(Page^.child),' Requisition=',dbgs(Requisition.height));
    inc(Result,Page^.child^.allocation.height);
  end;
  {$ENDIF GTK2}
  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight END ',dbgs(Result),' ',
    GetWidgetDebugReport(NBWidget));
end;

function TGtkWSCustomNotebook.GetNotebookMinTabWidth(
  const AWinControl: TWinControl): integer;
begin
  Result:=inherited GetNotebookMinTabWidth(AWinControl);
end;

{ Code pasted from LM_GETITEMINDEX message implementation
     csNotebook:
       begin
         TLMNotebookEvent(Data^).Page :=
           gtk_notebook_get_current_page(PGtkNotebook(Handle));
         UpdateNoteBookClientWidget(ACustomListBox);
       end;
}

function TGtkWSCustomNotebook.GetTabIndexAtPos(const ANotebook: TCustomNotebook;
  const AClientPos: TPoint): integer;
var
  NoteBookWidget: PGtkNotebook;
  i: integer;
  TabWidget: PGtkWidget;
  PageWidget: PGtkWidget;
  NotebookPos: TPoint;
  PageListItem: PGList;
begin
  Result:=-1;
  NoteBookWidget:=PGtkNotebook(ANotebook.Handle);
  if (NotebookWidget=nil) then exit;
  NotebookPos:=AClientPos;
  // go through all tabs
  i:=0;
  PageListItem:=NoteBookWidget^.Children;
  while PageListItem<>nil do begin
    PageWidget:=PGtkWidget(PageListItem^.Data);
    if PageWidget<>nil then begin
      TabWidget:=gtk_notebook_get_tab_label(NoteBookWidget, PageWidget);
      if TabWidget<>nil then begin
        // test if position is in tabwidget
        if (TabWidget^.Allocation.X<=NoteBookPos.X)
        and (TabWidget^.Allocation.Y<=NoteBookPos.Y)
        and (TabWidget^.Allocation.X+TabWidget^.Allocation.Width>NoteBookPos.X)
        and (TabWidget^.Allocation.Y+TabWidget^.Allocation.Height>NoteBookPos.Y)
        then begin
          Result:=i;
          exit;
        end;
      end;
    end;
    PageListItem:=PageListItem^.Next;
    inc(i);
  end;
end;

procedure TGtkWSCustomNotebook.SetPageIndex(const ANotebook: TCustomNotebook; const AIndex: integer);
begin
  gtk_notebook_set_page(PGtkNotebook(ANotebook.Handle), AIndex);
  UpdateNoteBookClientWidget(ANotebook);
end;

procedure TGtkWSCustomNotebook.SetTabPosition(const ANotebook: TCustomNotebook; const ATabPosition: TTabPosition);
var
  GtkNotebook: PGtkNotebook;
begin
  GtkNotebook := PGtkNotebook(ANotebook.Handle);
  case ATabPosition of
    tpTop   : gtk_notebook_set_tab_pos(GtkNotebook, GTK_POS_TOP);
    tpBottom: gtk_notebook_set_tab_pos(GtkNotebook, GTK_POS_BOTTOM);
    tpLeft  : gtk_notebook_set_tab_pos(GtkNotebook, GTK_POS_LEFT);
    tpRight : gtk_notebook_set_tab_pos(GtkNotebook, GTK_POS_RIGHT);
  end;
end;

procedure TGtkWSCustomNotebook.ShowTabs(const ANotebook: TCustomNotebook; AShowTabs: boolean);
begin
  gtk_notebook_set_show_tabs(PGtkNotebook(ANotebook.Handle), AShowTabs);
end;

{ TGtkWSCustomSplitter }

procedure TGtkWSCustomSplitter.DrawSplitter(const ASplitter: TCustomSplitter);
var
  Widget: PGtkWidget;
  ClientWidget: Pointer;
  DCOrigin: TPoint;
  Detail: PChar;
  Area: TGdkRectangle;
  Style: PGtkStyle;
  AWindow: PGdkWindow;
  DevContext: TDeviceContext;
  ARect: TRect;
begin
  if not ASplitter.HandleAllocated then exit;
  DevContext:=TDeviceContext(ASplitter.Canvas.Handle);
  Widget:=PGtkWidget(ASplitter.Handle);
  ClientWidget:=GetFixedWidget(Widget);
  if ClientWidget<>nil then
    Widget:=ClientWidget;
  AWindow:=DevContext.Drawable;

  Style:=GetStyle(lgsButton);
  if ASplitter.ResizeAnchor in [akTop,akBottom] then begin
    Detail:='hpaned';
  end else begin
    Detail:='vpaned';
  end;

  DCOrigin:=GetDCOffset(DevContext);
  Area.X:=DCOrigin.X;
  Area.Y:=DCOrigin.Y;
  Area.Width:=ASplitter.Width;
  Area.Height:=ASplitter.Height;
  
  if ASplitter.Beveled then begin
    ARect:=Bounds(Area.x,Area.y,Area.Width,Area.Height);
    DrawEdge(HDC(DevContext),ARect,BDR_RAISEDOUTER,BF_ADJUST+BF_RECT);
    Area.X:=ARect.Left;
    Area.Y:=ARect.Top;
    Area.Width:=ARect.Right-ARect.Left;
    Area.Height:=ARect.Bottom-ARect.Top;
  end;

  gtk_paint_box(Style, AWindow,
    GTK_WIDGET_STATE(Widget),
    GTK_SHADOW_NONE,
    @Area, Widget, Detail,
    Area.X,Area.Y,Area.Width,Area.Height);
end;


procedure TGtkWSCustomPanel.SetColor(const AWinControl: TWinControl);
var
  MainWidget: PGtkWidget;

begin
  if not AWinControl.HandleAllocated then exit;
{  if  ((csOpaque in AWinControl.ControlStyle)
  and GtkWidgetIsA(pGtkWidget(AWinControl.handle),GTKAPIWidget_GetType)) then
    exit;
}
  //DebugLn('TGtkWSWinControl.SetColor ',DbgSName(AWinControl));
{  GtkWidgetSet.SetWidgetColor(pGtkWidget(AWinControl.handle),
                              AWinControl.font.color, AWinControl.color,
                              [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,
                               GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);
}
//    GtkWidgetSet.setWidgetFont(pGtkWidget(AWinControl.handle),aWinControl.font);


  MainWidget:=GetFixedWidget(pGtkWidget(AWinControl.handle));
  if MainWidget<>nil then
  GtkWidgetSet.SetWidgetColor(MainWidget,
                              AWinControl.font.color, AWinControl.color,
                              [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,
                               GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);

  UpdateWidgetStyleOfControl(AWinControl);
end;


initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomPage, TGtkWSCustomPage);
  RegisterWSComponent(TCustomNotebook, TGtkWSCustomNotebook);
//  RegisterWSComponent(TPage, TGtkWSPage);
//  RegisterWSComponent(TNotebook, TGtkWSNotebook);
//  RegisterWSComponent(TShape, TGtkWSShape);
  RegisterWSComponent(TCustomSplitter, TGtkWSCustomSplitter);
//  RegisterWSComponent(TSplitter, TGtkWSSplitter);
//  RegisterWSComponent(TPaintBox, TGtkWSPaintBox);
//  RegisterWSComponent(TCustomImage, TGtkWSCustomImage);
//  RegisterWSComponent(TImage, TGtkWSImage);
//  RegisterWSComponent(TBevel, TGtkWSBevel);
//  RegisterWSComponent(TCustomRadioGroup, TGtkWSCustomRadioGroup);
//  RegisterWSComponent(TRadioGroup, TGtkWSRadioGroup);
//  RegisterWSComponent(TCustomCheckGroup, TGtkWSCustomCheckGroup);
//  RegisterWSComponent(TCheckGroup, TGtkWSCheckGroup);
//  RegisterWSComponent(TCustomLabeledEdit, TGtkWSCustomLabeledEdit);
//  RegisterWSComponent(TLabeledEdit, TGtkWSLabeledEdit);
  RegisterWSComponent(TCustomPanel, TGtkWSCustomPanel);
//  RegisterWSComponent(TPanel, TGtkWSPanel);
////////////////////////////////////////////////////

end.