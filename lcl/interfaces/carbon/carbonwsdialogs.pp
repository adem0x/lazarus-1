{ $Id$}
{
 *****************************************************************************
 *                              CarbonWSDialogs.pp                           * 
 *                              --------------                               * 
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
unit CarbonWSDialogs;

{$mode objfpc}{$H+}

interface

// debugging defines
{$I carbondebug.inc}

uses
  // libs
  FPCMacOSAll,
  {$IFDEF VER2_0}
  FontPanel, // will be removed
  {$ENDIF}
  // LCL
  Classes, SysUtils, Controls, Dialogs, LCLType, LCLProc, Masks, Graphics,
  // widgetset
  WSLCLClasses, WSProc, WSDialogs,
  // LCL Carbon
  CarbonDef, CarbonPrivate;
  
type

  { TCarbonWSCommonDialog }

  TCarbonWSCommonDialog = class(TWSCommonDialog)
  private
  protected
  public
  end;

  { TCarbonWSFileDialog }

  TCarbonWSFileDialog = class(TWSFileDialog)
  private
  protected
  public
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
  end;

  { TCarbonWSOpenDialog }

  TCarbonWSOpenDialog = class(TWSOpenDialog)
  private
  protected
  public
  end;

  { TCarbonWSSaveDialog }

  TCarbonWSSaveDialog = class(TWSSaveDialog)
  private
  protected
  public
  end;

  { TCarbonWSSelectDirectoryDialog }

  TCarbonWSSelectDirectoryDialog = class(TWSSelectDirectoryDialog)
  private
  protected
  public
  end;

  { TCarbonWSColorDialog }

  TCarbonWSColorDialog = class(TWSColorDialog)
  private
  protected
  public
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
  end;

  { TCarbonWSColorButton }

  TCarbonWSColorButton = class(TWSColorButton)
  private
  protected
  public
  end;

  { TCarbonWSFontDialog }

  TCarbonWSFontDialog = class(TWSFontDialog)
  private
  protected
  public
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
  end;


implementation

uses
  CarbonProc, CarbonDbgConsts, CarbonInt, CarbonUtils, CarbonGDIObjects;

{ TCarbonWSFileDialog }

var
  FilterMask: TMaskList;

function FilterCallback(var theItem: AEDesc; info: NavFileOrFolderInfoPtr;
 callbackUD: UnivPtr; filterMode: NavFilterModes): Boolean; stdcall;
 {Custom filter callback function. Pointer to this function is passed as
   inFilterProc to NavCreateGetFileDialog and NavCreateChooseFolderDialog.
  If theItem file should be highlighted in file dialog, return True;
   if it should be dimmed in file dialog, return False.
  The callbackUD param contains file dialog object passed as inClientData
   to NavCreateGetFileDialog and NavCreateChooseFolderDialog.}
var
  FileRef: FSRef;
  FileURL: CFURLRef;
  FileCFStr: CFStringRef;
  FilePath: string;
begin
  Result := True;
  
  if callbackUD = nil then  // No user data passed?
    Exit;
  if TFileDialog(callbackUD).Filter = '' then  // No filter passed?
    Exit;
  if TFileDialog(callbackUD) is TOpenDialog then
  begin
    if info^.isFolder then  // Don't dim folder?
      Exit;
  end
  else  {Must be TSelectDirectoryDialog}
  begin
    if not info^.isFolder then  // Dim file?
    begin
      Result := False;
      Exit;
    end;
  end;

  if OSError(AEGetDescData(theItem, @FileRef, SizeOf(FSRef)), 
             'FilterByExtCallback', '', 'AEGetDescData') then Exit;
                     
  FileURL := CFURLCreateFromFSRef(kCFAllocatorDefault, FileRef);
  FileCFStr := CFURLCopyFileSystemPath(FileURL, kCFURLPOSIXPathStyle);
          
  FilePath := CFStringToStr(FileCFStr);

  FreeCFString(FileURL);
  FreeCFString(FileCFStr);

  Result := (FilterMask = nil) or FilterMask.Matches(ExtractFilename(FilePath));
  //DebugLn('FilterCallback ' + DbgS(FilterMask) + ' ' + ExtractFilename(FilePath) + ' ' + DbgS(Result));
end;  {FilterCallback}


{------------------------------------------------------------------------------
  Method:  TCarbonWSFileDialog.ShowModal
  Params:  ACommonDialog - LCL common dialog
  
  Shows a file dialog (open, save, slect directory) in Carbon interface. Sets
  ACommonDialog.UserChoice to mrOK or mrCancel. If mrOK, also sets
  ACommonDialog.FileName to first file selected and adds file(s) selected to
  ACommonDialog.Files.
 ------------------------------------------------------------------------------}
class procedure TCarbonWSFileDialog.ShowModal(const ACommonDialog: TCommonDialog);
 {
  Called by Execute method of TOpenDialog, TSaveDialog and TSelectDirectoryDialog.
   TODO: Figure out how to use dialog's InitialDir property.
 }
var
  FileDialog: TFileDialog;
  CreationOptions: NavDialogCreationOptions;
  FilterUPP: NavObjectFilterUPP;
  DialogRef: NavDialogRef;
  DialogReply: NavReplyRecord;
  FileCount: Integer;
  FileIdx: Integer;
  Keyword: AEKeyword;
  FileDesc: AEDesc;
  FileRef: FSRef;
  FileURL: CFURLRef;
  FileCFStr: CFStringRef;
  Filters: TParseStringList;
begin
  {$IFDEF VerboseWSClass}
    DebugLn('TCarbonWSFileDialog.ShowModal for ' + ACommonDialog.Name);
  {$ENDIF}

  FileDialog := ACommonDialog as TFileDialog;

  // Initialize record to default values
  if OSError(NavGetDefaultDialogCreationOptions(CreationOptions),
    Self, SShowModal, 'NavGetDefaultDialogCreationOptions') then Exit;

  if FileDialog.Title <> '' then  // Override dialog's default title?
    CreateCFString(FileDialog.Title, CreationOptions.windowTitle);

  FileDialog.UserChoice := mrCancel; // Return this if user cancels or we need to exit

  FilterUPP := NewNavObjectFilterUPP(NavObjectFilterProcPtr(@FilterCallback));

  Filters := TParseStringList.Create(FileDialog.Filter, '|');
  try
    if (FileDialog.FilterIndex > 0) and
      (FileDialog.FilterIndex * 2 - 1 <= Filters.Count) then
    begin
      //DebugLn('Filter ' + Filters[FileDialog.FilterIndex * 2 - 1]);
      FilterMask := TMaskList.Create(Filters[FileDialog.FilterIndex * 2 - 1]);
    end;
  finally
    Filters.Free;
  end;
  
  try
    if FileDialog is TSaveDialog then
    begin  // Checking for TSaveDialog first since it's descendent of TOpenDialog
      CreateCFString(ExtractFileName(FileDialog.FileName),
        CreationOptions.saveFileName);  // Note doesn't like path
        
      if ofOverwritePrompt in TOpenDialog(FileDialog).Options then
        CreationOptions.optionFlags :=
           CreationOptions.optionFlags xor kNavDontConfirmReplacement
      else
        CreationOptions.optionFlags :=
          CreationOptions.optionFlags or kNavDontConfirmReplacement;
         
      // Create Save dialog
      if OSError(
        NavCreatePutFileDialog(@CreationOptions, 0, 0, nil, nil, DialogRef),
         Self, SShowModal, 'NavCreatePutFileDialog') then Exit;
    end
    else
      if FileDialog is TSelectDirectoryDialog then // Create Choose folder dialog
      begin
        if OSError(
          NavCreateChooseFolderDialog(@CreationOptions, nil, 
           FilterUPP, UnivPtr(FileDialog), DialogRef),
           Self, SShowModal, 'NavCreateChooseFolderDialog') then Exit;
      end
      else
        if FileDialog is TOpenDialog then
        begin
          if not (ofAllowMultiSelect in TOpenDialog(FileDialog).Options) then
            CreationOptions.optionFlags :=
              CreationOptions.optionFlags xor kNavAllowMultipleFiles
          else
            CreationOptions.optionFlags :=
              CreationOptions.optionFlags or kNavAllowMultipleFiles;

          // Create Open dialog
          if OSError(
            NavCreateGetFileDialog(@CreationOptions, nil, nil, nil, 
             FilterUPP, UnivPtr(FileDialog), DialogRef),
             Self, SShowModal, 'NavCreateGetFileDialog') then Exit;
        end;

    try
      // Display dialog
      if OSError(NavDialogRun(DialogRef), Self, SShowModal, 'NavDialogRun') then Exit;
      
      if NavDialogGetUserAction(DialogRef) <> kNavUserActionCancel then // User OK?
      begin
        if OSError(NavDialogGetReply(DialogRef, DialogReply), Self, SShowModal,
          'NavDialogGetReply') then Exit;  // Get user's selection
          
        if OSError(AECountItems(DialogReply.Selection, FileCount), Self,
          SShowModal, 'AECountItems') then Exit;
          
        FileDialog.Files.Clear;
        for FileIdx := 1 to FileCount do
        begin
          if OSError(AEGetNthDesc(DialogReply.Selection, FileIdx, typeFSRef,
            @Keyword, FileDesc), Self, SShowModal, 'AEGetNthDesc') then Exit;
          // Get file reference
          if OSError(AEGetDescData(FileDesc, @FileRef, SizeOf(FSRef)), Self,
            SShowModal, 'AEGetDescData') then Exit;
            
          if OSError(AEDisposeDesc(FileDesc), Self, SShowModal,
            'AEDisposeDesc') then Exit;
          
          FileURL := CFURLCreateFromFSRef(kCFAllocatorDefault, FileRef); // Get URL
          FileCFStr := CFURLCopyFileSystemPath(FileURL, kCFURLPOSIXPathStyle); // Get path
          
          FileDialog.Files.Add(CFStringToStr(FileCFStr));

          FreeCFString(FileURL);
          FreeCFString(FileCFStr);
          // Note: Previous 5 lines replace next 2 lines and eliminate need
          //   to decide what size to make FileBuf array.
          //   See http://developer.apple.com/technotes/tn2002/tn2078.html
          //  FSRefMakePath(FileRef, @FileBuf, SizeOf(FileBuf));  {Get file path}
          //  FileDialog.Files.Add(string(FileBuf));  //FileBuf contains UTF8 C string
        end;
          
        FileDialog.FileName := FileDialog.Files.Strings[0];

        if FileDialog is TSaveDialog then
          FileDialog.FileName := FileDialog.FileName + PathDelim +
            CFStringToStr(NavDialogGetSaveFileName(DialogRef));
            {Note: Not at all clear from Apple docs that NavReplyRecord.Selection
              returns only path to file's folder with Save dialog. Also, what they
              mean by the "full file name" returned by NavDialogGetSaveFileName
              must mean extension and not path to file's folder.}
              
        // Dispose of data that record points to (?)
        if OSError(NavDisposeReply(DialogReply), Self, SShowModal,
          'NavDisposeReply') then Exit;
          
        FileDialog.UserChoice := mrOK;
      end;
    finally
      NavDialogDispose(DialogRef);  // Dispose of dialog
    end;

  finally
    FreeAndNil(FilterMask);
    DisposeNavObjectFilterUPP(FilterUPP);
    FreeCFString(CreationOptions.windowTitle);
    FreeCFString(CreationOptions.saveFileName);
  end;
end;  {TCarbonWSFileDialog.ShowModal}

{ TCarbonWSColorDialog }

{------------------------------------------------------------------------------
  Method:  TCarbonWSColorDialog.ShowModal
  Params:  ACommonDialog - LCL color dialog

  Shows Carbon interface color picker
 ------------------------------------------------------------------------------}
class procedure TCarbonWSColorDialog.ShowModal(
  const ACommonDialog: TCommonDialog);
var
  ColorInfo: ColorPickerInfo;
  ColorDialog: TColorDialog;
begin
  {$IFDEF VerboseWSClass}
    DebugLn('TCarbonWSColorDialog.ShowModal for ' + ACommonDialog.Name);
  {$ENDIF}
  
  ACommonDialog.UserChoice := mrCancel;
  ColorDialog := ACommonDialog as TColorDialog;
  
  FillChar(ColorInfo, SizeOf(ColorPickerInfo), 0);
  ColorInfo.theColor.color.rgb := CMRGBColor(ColorToRGBColor(ColorDialog.Color));
  ColorInfo.theColor.profile := nil;
  ColorInfo.dstProfile := nil;
  ColorInfo.flags := kColorPickerDialogIsModal or kColorPickerDialogIsMoveable or
    kColorPickerInPickerDialog;
  ColorInfo.placeWhere :=  kCenterOnMainScreen;
  ColorInfo.pickerType := 0; // use last picker subtype
  ColorInfo.eventProc := nil;
  ColorInfo.colorProc := nil;
  // ColorDialog.Title is ignored, ColorInfo.prompt is not shown anywhere
  
  if OSError(PickColor(ColorInfo), Self, SShowModal, 'PickColor') then Exit;
  
  if ColorInfo.newColorChosen then
  begin
    ColorDialog.Color := RGBColorToColor(RGBColor(ColorInfo.theColor.color.rgb));
    ACommonDialog.UserChoice := mrOK;
  end;
end;

var
  FontDialog: TFontDialog;

{ TCarbonWSFontDialog }

function CarbonFontDialog_Selection(ANextHandler: EventHandlerCallRef;
  AEvent: EventRef;
  AWidget: TCarbonWidget): OSStatus; {$IFDEF darwin}mwpascal;{$ENDIF}
var
  AFontDialog: TFontDialog;
  ID: ATSUFontID;
  Size: Fixed;
  Color: RGBColor;
  Style: FMFontStyle;
const
  SName = 'CarbonFontDialog_Selection';
begin
  {$IFDEF VerboseWSClass}
    DebugLn('CarbonFontDialog_Selection: ', DbgSName(FontDialog));
  {$ENDIF}

  Result := CallNextEventHandler(ANextHandler, AEvent);

  // get font panel settings
    
  if GetEventParameter(AEvent, kEventParamATSUFontID, typeATSUFontID,
    nil, SizeOf(ID), nil, @ID) = noErr then
  begin
    DebugLn('ID: ' + DbgS(ID));
    FontDialog.Font.Name := CarbonFontIDToFontName(ID);
  end;
  
  if GetEventParameter(AEvent, kEventParamATSUFontSize, typeATSUSize,
    nil, SizeOf(Size), nil, @Size) = noErr then
  begin
    DebugLn('Size: ' + DbgS(RoundFixed(Size)));
    FontDialog.Font.Size := RoundFixed(Size);
  end;
  
  if GetEventParameter(AEvent, kEventParamFontColor, typeFontColor,
    nil, SizeOf(Color), nil, @Color) = noErr then
  begin
    DebugLn('Color: ' + DbgS(RGBColorToColor(Color)));
    FontDialog.Font.Color := RGBColorToColor(Color);
  end;
  
  if GetEventParameter(AEvent, kEventParamFMFontStyle, typeFMFontStyle,
    nil, SizeOf(Style), nil, @Style) = noErr then
  begin
    DebugLn('Style: ' + DbgS(Style));
    FontDialog.Font.Style := [];
    if (Style and FPCMacOSAll.bold) > 0 then
      FontDialog.Font.Style := FontDialog.Font.Style + [fsBold];
    if (Style and FPCMacOSAll.italic) > 0 then
      FontDialog.Font.Style := FontDialog.Font.Style + [fsItalic];
    if (Style and FPCMacOSAll.underline) > 0 then
      FontDialog.Font.Style := FontDialog.Font.Style + [fsUnderline];
  end;
  
  // TODO: fsStrikeOut
    
  FontDialog.UserChoice := mrOK;
end;

function CarbonFontDialog_Close(ANextHandler: EventHandlerCallRef;
  AEvent: EventRef;
  AWidget: TCarbonWidget): OSStatus; {$IFDEF darwin}mwpascal;{$ENDIF}
var
  AFontDialog: TFontDialog;
begin
  {$IFDEF VerboseWSClass}
    DebugLn('CarbonFontDialog_Close: ', DbgSName(FontDialog));
  {$ENDIF}

  Result := CallNextEventHandler(ANextHandler, AEvent);
  
  CarbonWidgetSet.SetMainMenuEnabled(True);
  
  // hide font panel
  if FPIsFontPanelVisible then
    OSError(FPShowHideFontPanel, 'CarbonFontDialog_Close', 'FPShowHideFontPanel');
end;

{------------------------------------------------------------------------------
  Method:  TCarbonWSFontDialog.ShowModal
  Params:  ACommonDialog - LCL font dialog

  Shows Carbon interface font panel
 ------------------------------------------------------------------------------}
class procedure TCarbonWSFontDialog.ShowModal(const ACommonDialog: TCommonDialog);
var
  AFontDialog: TFontDialog;
  TmpSpec: EventTypeSpec;
  Dialog: WindowRef;
  Style: ATSUStyle;
  ID: ATSUFontID;
  M: ATSUTextMeasurement;
  C: RGBColor;
  Attr: ATSUAttributeTag;
  S: ByteCount;
  A: ATSUAttributeValuePtr;
begin
  {$IFDEF VerboseWSClass}
    DebugLn('TCarbonWSFontDialog.ShowModal for ' + ACommonDialog.Name);
  {$ENDIF}
  
  AFontDialog := ACommonDialog as TFontDialog;
  AFontDialog.UserChoice := mrCancel;

  if OSError(
    CreateNewWindow(kModalWindowClass,
      kWindowCompositingAttribute or kWindowStandardHandlerAttribute, GetCarbonRect(0, 0, 0, 0), Dialog),
    Self, SShowModal, 'CreateNewWindow') then Exit;
    
  try
    TmpSpec := MakeEventSpec(kEventClassFont, kEventFontPanelClosed);
    InstallWindowEventHandler(Dialog,
      RegisterEventHandler(@CarbonFontDialog_Close),
      1, @TmpSpec, nil, nil);

    TmpSpec := MakeEventSpec(kEventClassFont, kEventFontSelection);
    InstallWindowEventHandler(Dialog,
      RegisterEventHandler(@CarbonFontDialog_Selection),
      1, @TmpSpec, nil, nil);


    OSError(ATSUCreateAndCopyStyle(TCarbonFont(AFontDialog.Font.Handle).Style, Style),
      Self, SShowModal, 'ATSUCreateAndCopyStyle');
      
    // force set font ID
    if ATSUGetAttribute(Style, kATSUFontTag, SizeOf(ID), @ID, nil) = kATSUNotSetErr then
    begin
      Attr := kATSUFontTag;
      A := @ID;
      S := SizeOf(ID);
      OSError(ATSUSetAttributes(Style, 1, @Attr, @S, @A), Self, SShowModal,
        'ATSUSetAttributes', 'kATSUFontTag');
    end;
    
    // force set font size
    if ATSUGetAttribute(Style, kATSUSizeTag, SizeOf(M), @M, nil) = kATSUNotSetErr then
    begin
      Attr := kATSUSizeTag;
      A := @M;
      S := SizeOf(M);
      OSError(ATSUSetAttributes(Style, 1, @Attr, @S, @A), Self, SShowModal,
        'ATSUSetAttributes', 'kATSUSizeTag');
    end;
    
    // force set font color
    if ATSUGetAttribute(Style, kATSUColorTag, SizeOf(C), @C, nil) = kATSUNotSetErr then
    begin
      Attr := kATSUColorTag;
      A := @C;
      S := SizeOf(C);
      OSError(ATSUSetAttributes(Style, 1, @Attr, @S, @A), Self, SShowModal,
        'ATSUSetAttributes', 'kATSUSizeTag');
    end;

    if OSError(SetFontInfoForSelection(kFontSelectionATSUIType, 1,
      @Style, GetWindowEventTarget(Dialog)),
      Self, SShowModal, 'SetFontInfoForSelection') then Exit;

    CarbonWidgetSet.SetMainMenuEnabled(False);

    FontDialog := AFontDialog;
    FPCMacOSAll.ShowWindow(Dialog);

    // show font panel
    if not FPIsFontPanelVisible then
      OSError(FPShowHideFontPanel, Self, SShowModal, 'FPShowHideFontPanel');
      
    while FPIsFontPanelVisible do
      CarbonWidgetSet.AppProcessMessages;

  finally
    DisposeWindow(Dialog);
    CarbonWidgetSet.SetMainMenuEnabled(True);
  end;
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TCommonDialog, TCarbonWSCommonDialog);
  RegisterWSComponent(TFileDialog, TCarbonWSFileDialog);
//  RegisterWSComponent(TOpenDialog, TCarbonWSOpenDialog);
//  RegisterWSComponent(TSaveDialog, TCarbonWSSaveDialog);
//  RegisterWSComponent(TSelectDirectoryDialog, TCarbonWSSelectDirectoryDialog);
  RegisterWSComponent(TColorDialog, TCarbonWSColorDialog);
//  RegisterWSComponent(TColorButton, TCarbonWSColorButton);
  RegisterWSComponent(TFontDialog, TCarbonWSFontDialog);
////////////////////////////////////////////////////
end.
