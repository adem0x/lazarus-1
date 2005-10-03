{ $Id$}
{
 *****************************************************************************
 *                              CarbonWSStdCtrls.pp                              *
 *                              ---------------                              *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit CarbonWSStdCtrls;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  FPCMacOSAll, CarbonDef, CarbonProc, CarbonUtils,
  Controls, StdCtrls, LCLType,
////////////////////////////////////////////////////
  WSStdCtrls, WSLCLClasses, WSControls, WSProc,
  CarbonWSControls, CarbonPrivate;
type

  { TCarbonWSScrollBar }

  TCarbonWSScrollBar = class(TWSScrollBar)
  private
  protected
  public
  end;

  { TCarbonWSCustomGroupBox }

  TCarbonWSCustomGroupBox = class(TWSCustomGroupBox)
  private
  protected
  public
  end;

  { TCarbonWSGroupBox }

  TCarbonWSGroupBox = class(TWSGroupBox)
  private
  protected
  public
  end;

  { TCarbonWSCustomComboBox }

  TCarbonWSCustomComboBox = class(TWSCustomComboBox)
  private
  protected
  public
  end;

  { TCarbonWSComboBox }

  TCarbonWSComboBox = class(TWSComboBox)
  private
  protected
  public
  end;

  { TCarbonWSCustomListBox }

  TCarbonWSCustomListBox = class(TWSCustomListBox)
  private
  protected
  public
  end;

  { TCarbonWSListBox }

  TCarbonWSListBox = class(TWSListBox)
  private
  protected
  public
  end;

  { TCarbonWSCustomEdit }

  TCarbonWSCustomEdit = class(TWSCustomEdit)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;

    class function  GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function  GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); override;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;

    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer); override;
  end;

  { TCarbonWSCustomMemo }

  TCarbonWSCustomMemo = class(TWSCustomMemo)
  private
  protected
  public
  end;

  { TCarbonWSEdit }

  TCarbonWSEdit = class(TWSEdit)
  private
  protected
  public
  end;

  { TCarbonWSMemo }

  TCarbonWSMemo = class(TWSMemo)
  private
  protected
  public
  end;

  { TCarbonWSCustomLabel }

  {TCarbonWSCustomLabel = class(TWSCustomLabel)
  private
  protected
  public
  end;}

  { TCarbonWSLabel }

  {TCarbonWSLabel = class(TWSLabel)
  private
  protected
  public
  end;}

  { TCarbonWSButtonControl }

  TCarbonWSButtonControl = class(TWSButtonControl)
  private
  protected
  public
  end;

  { TCarbonWSCustomCheckBox }

  TCarbonWSCustomCheckBox = class(TWSCustomCheckBox)
  private
  protected
  public
  end;

  { TCarbonWSCheckBox }

  TCarbonWSCheckBox = class(TWSCheckBox)
  private
  protected
  public
  end;

  { TCarbonWSToggleBox }

  TCarbonWSToggleBox = class(TWSToggleBox)
  private
  protected
  public
  end;

  { TCarbonWSRadioButton }

  TCarbonWSRadioButton = class(TWSRadioButton)
  private
  protected
  public
  end;

  { TCarbonWSCustomStaticText }

  TCarbonWSCustomStaticText = class(TWSCustomStaticText)
  private
  protected
  public
  end;

  { TCarbonWSStaticText }

  TCarbonWSStaticText = class(TWSStaticText)
  private
  protected
  public
  end;


implementation

function  TCarbonWSCustomEdit.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  Edit: TCustomEdit;
  Control: ControlRef;
  CFString: CFStringRef;
  R: Rect;
  Info: PWidgetInfo;
  IsResize: PBoolean;
begin
  Result := 0;
  Edit := AWinControl as TCustomEdit;

  R.Left := AParams.X;
  R.Top := AParams.Y;
  R.Right := AParams.X + AParams.Width;
  R.Bottom := AParams.Y + AParams.Height;

  CFString := CFStringCreateWithCString(nil, Pointer(AParams.Caption), DEFAULT_CFSTRING_ENCODING);
  if CreateEditTextControl(WindowRef(AParams.WndParent), R, CFString, (Edit.PasswordChar <> #0),true, nil, Control) = noErr
  then Result := TLCLIntfHandle(Control);
  CFRelease(Pointer(CFString));
  if Result = 0 then Exit;

  New(IsResize);
  IsResize^ := Edit.PasswordChar <> #0;

  Info := CreateWidgetInfo(Control, AWinControl);
  Info^.UserData := IsResize;
  Info^.DataOwner := True;
  TCarbonPrivateHandleClass(WSPrivate).RegisterEvents(Info);
end;

function  TCarbonWSCustomEdit.GetSelStart(const ACustomEdit: TCustomEdit): integer;
var
  Control: ControlRef;
  SelData: ControlEditTextSelectionRec;
  RecSize: FPCMacOSAll.Size;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelStart')
  then Exit;

  Result := 0;
  Control := ControlRef(ACustomEdit.Handle);
  if GetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
      SizeOf(ControlEditTextSelectionRec), @SelData, @RecSize) <> noErr
  then Exit;

  Result := SelData.SelStart;
end;

function  TCarbonWSCustomEdit.GetSelLength(const ACustomEdit: TCustomEdit): integer;
var
  Control: ControlRef;
  SelData: ControlEditTextSelectionRec;
  RecSize: FPCMacOSAll.Size;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelLength')
  then Exit;

  Result := 0;
  Control := ControlRef(ACustomEdit.Handle);

  if GetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
                    SizeOf(ControlEditTextSelectionRec), @SelData, @RecSize) <> noErr then exit;

  Result := SelData.SelEnd - SelData.SelStart;
end;

procedure TCarbonWSCustomEdit.SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase);
begin
 // TODO
end;

procedure TCarbonWSCustomEdit.SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode);
begin
 //TODO
end;

procedure TCarbonWSCustomEdit.SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer);
begin
 //AFAICS this will have to be checked in a callback
end;

procedure TCarbonWSCustomEdit.SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char);
var
  Control: ControlRef;
  NeedsPassword: Boolean;
  IsPassword: Boolean;
  Info: PWidgetInfo;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetReadOnly')
  then Exit;

  Info := GetWidgetInfo(Pointer(ACustomEdit.Handle));
  IsPassword := PBoolean(Info^.UserData)^;
  NeedsPassword := (NewChar <> #0);

  if IsPassword = NeedsPassword then exit;
  PBoolean(Info^.UserData)^ := NeedsPassword;
  RecreateWnd(ACustomEdit);

end;

procedure TCarbonWSCustomEdit.SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean);
var
  Control: ControlRef;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetReadOnly')
  then Exit;

  Control := ControlRef(ACustomEdit.Handle);

  SetControlData(Control, kControlEntireControl, kControlEditTextLockedTag,
                 SizeOf(Boolean), @NewReadOnly);
end;

procedure TCarbonWSCustomEdit.SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer);
var
  Control: ControlRef;
  SelData: ControlEditTextSelectionRec;
  RecSize: FPCMacOSAll.Size;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelStart')
  then Exit;

  Control := ControlRef(ACustomEdit.Handle);

  if GetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
                    SizeOf(ControlEditTextSelectionRec), @SelData, @RecSize) <> noErr then exit;

  SelData.SelStart := NewStart;
  SetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
                 SizeOf(ControlEditTextSelectionRec), @SelData);

end;

procedure TCarbonWSCustomEdit.SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer);
var
  Control: ControlRef;
  SelData: ControlEditTextSelectionRec;
  RecSize: FPCMacOSAll.Size;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelLength')
  then Exit;

  Control := ControlRef(ACustomEdit.Handle);
  if GetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
                    SizeOf(ControlEditTextSelectionRec), @SelData, @RecSize) <> noErr then Exit;

  SelData.SelEnd := SelData.SelStart + NewLength;
  SetControlData(Control, kControlEntireControl, kControlEditTextSelectionTag,
                 SizeOf(ControlEditTextSelectionRec), @SelData);

end;

procedure TCarbonWSCustomEdit.GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer);
begin
  //TODO
end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TScrollBar, TCarbonWSScrollBar);
//  RegisterWSComponent(TCustomGroupBox, TCarbonWSCustomGroupBox);
//  RegisterWSComponent(TGroupBox, TCarbonWSGroupBox);
//  RegisterWSComponent(TCustomComboBox, TCarbonWSCustomComboBox);
//  RegisterWSComponent(TComboBox, TCarbonWSComboBox);
//  RegisterWSComponent(TCustomListBox, TCarbonWSCustomListBox);
//  RegisterWSComponent(TListBox, TCarbonWSListBox);
  RegisterWSComponent(TCustomEdit, TCarbonWSCustomEdit);
//  RegisterWSComponent(TCustomMemo, TCarbonWSCustomMemo);
//  RegisterWSComponent(TEdit, TCarbonWSEdit);
//  RegisterWSComponent(TMemo, TCarbonWSMemo);
//  RegisterWSComponent(TCustomLabel, TCarbonWSCustomLabel);
//  RegisterWSComponent(TLabel, TCarbonWSLabel);
//  RegisterWSComponent(TButtonControl, TCarbonWSButtonControl);
//  RegisterWSComponent(TCustomCheckBox, TCarbonWSCustomCheckBox);
//  RegisterWSComponent(TCheckBox, TCarbonWSCheckBox);
//  RegisterWSComponent(TCheckBox, TCarbonWSCheckBox);
//  RegisterWSComponent(TToggleBox, TCarbonWSToggleBox);
//  RegisterWSComponent(TRadioButton, TCarbonWSRadioButton);
//  RegisterWSComponent(TCustomStaticText, TCarbonWSCustomStaticText);
//  RegisterWSComponent(TStaticText, TCarbonWSStaticText);
////////////////////////////////////////////////////
end.
