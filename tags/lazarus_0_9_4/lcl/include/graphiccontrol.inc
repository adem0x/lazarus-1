{%MainUnit ../controls.pp}

{******************************************************************************
                                     TGraphicControl
 ******************************************************************************
 
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

{------------------------------------------------------------------------------
  Method:  TGraphicControl.Create
  Params:  none
  Returns: Nothing

  Constructor for the class.
 ------------------------------------------------------------------------------}
constructor TGraphicControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
end;

{------------------------------------------------------------------------------
  Method: TGraphicControl.Destroy
  Params:  None
  Returns: Nothing

  Destructor for the class.
 ------------------------------------------------------------------------------}
destructor TGraphicControl.Destroy;
begin
  FCanvas.Free;
  inherited Destroy;
end;

{------------------------------------------------------------------------------
  Method: TGraphicControl.WMPaint
  Params:   Msg: The paint message
  Returns:  nothing

  Paint event handler.
 ------------------------------------------------------------------------------}
procedure TGraphicControl.WMPaint(var Message: TLMPaint);
begin
  if Message.DC <> 0 then
  begin
    Canvas.Lock;
    try
      Canvas.Handle := Message.DC;
      try
        Paint;
      finally
        Canvas.Handle := 0;
      end;
    finally
      Canvas.Unlock;
    end;
  end;
end;

{------------------------------------------------------------------------------
  Method: TGraphicControl.Paint
  Params:   none
  Returns:  nothing

  Default paint handler. Derived classed should paint themselves 
 ------------------------------------------------------------------------------}
procedure TGraphicControl.Paint;
begin
  Assert(False, Format('Trace:[TGraphicControl.Paint] %s', [ClassName]));
  if Assigned(FOnPaint) then FOnPaint(Self);
end;

// included by controls.pp


{ =============================================================================

  $Log$
  Revision 1.9  2004/04/10 17:58:57  mattias
  implemented mainunit hints for include files

  Revision 1.8  2004/02/23 18:24:38  mattias
  completed new TToolBar

  Revision 1.7  2003/06/13 21:08:53  mattias
  moved TColorButton to dialogs.pp

  Revision 1.6  2003/03/11 07:46:43  mattias
  more localization for gtk- and win32-interface and lcl

  Revision 1.5  2002/09/13 11:49:47  lazarus
  Cleanups, extended TStatusBar, graphic control cleanups.

  Revision 1.4  2002/08/26 17:28:21  lazarus
  MG: fixed speedbutton in designmode

  Revision 1.3  2002/05/10 06:05:52  lazarus
  MG: changed license to LGPL

  Revision 1.2  2001/04/02 14:45:26  lazarus
  MG: bugfixes for TBevel

  Revision 1.1  2000/07/13 10:28:25  michael
  + Initial import

  Revision 1.2  2000/05/09 02:07:40  lazarus
  Replaced writelns with Asserts.                          CAW

  Revision 1.1  2000/04/02 20:49:56  lazarus
  MWE:
    Moved lazarus/lcl/*.inc files to lazarus/lcl/include

  Revision 1.4  2000/03/15 00:51:57  lazarus
  MWE:
    + Added LM_Paint on expose
    + Added forced creation of gdkwindow if needed
    ~ Modified DrawFrameControl
    + Added BF_ADJUST support on DrawEdge
    - Commented out LM_IMAGECHANGED in TgtkObject.IntSendMessage3
       (It did not compile)

  Revision 1.3  1999/12/14 00:16:43  lazarus
  MWE:
    Renamed LM... message handlers to WM... to be compatible and to
      get more edit parts to compile
    Started to implement GetSystemMetrics
    Removed some Lazarus specific parts from mwEdit

  Revision 1.2  1999/12/07 01:19:25  lazarus
  MWE:
    Removed some double events
    Changed location of SetCallBack
    Added call to remove signals
    Restructured somethings
    Started to add default handlers in TWinControl
    Made some parts of TControl and TWinControl more delphi compatible
    ... and lots more ...


}