unit fElastic;
(* Demonstrate elastic dock sites.
  This form has dock sites (panels) on its left, right and bottom.

  Empty panels should be invisible, what's a bit tricky. They cannot have
  Visible=False, because this would disallow to dock anything into them.
  So the width/height of the panels is set to zero instead.

  When a first control is docked, the dock site is enlarged.
  Fine adjustment can be made with the splitters beneath the controls.

  When the last control is undocked, the dock site is shrinked again.

Planned extensions:
- using an DockManager, so that more than only one control can be docked
  into every panel.
*)

(* Observed problems:

The right panel does not shrink.
Form doesn't shrink at the right side.

Object Inspector says: the bottom panel's OnGetSiteInfo method is incompatible
  with other OnGetSiteInfo methods.
*)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls,
  EasyDockSite;

type
  TDockingSite = class(TForm)
    buNewForm: TButton;
    Panel1: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    splitBottom: TSplitter;
    splitLeft: TSplitter;
    splitRight: TSplitter;
    StatusBar1: TStatusBar;
    procedure buNewFormClick(Sender: TObject);
    procedure pnlLeftDockDrop(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer);
    procedure pnlLeftDockOver(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure pnlLeftGetSiteInfo(Sender: TObject; DockClient: TControl;
      var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
    procedure pnlLeftUnDock(Sender: TObject; Client: TControl;
      NewTarget: TWinControl; var Allow: Boolean);
  private
    FAutoExpand: boolean;
    procedure SetAutoExpand(NewValue: boolean);
  public
  published
    property AutoExpand: boolean read FAutoExpand write SetAutoExpand default True;
  end;

var
  DockingSite: TDockingSite;

implementation

uses
  LCLIntf;

//uses  fDockClient;  //test only

{ TDockingSite }

procedure TDockingSite.buNewFormClick(Sender: TObject);
var
  Client: TPanel;
begin
  //TDockingClient.Create(self);
  Client := TPanel.Create(self);
  Client.DragMode := dmAutomatic;
  Client.DragKind := dkDock;
  Client.Visible := True;
  Client.ManualFloat(Rect(200,200, 400,400));
end;

procedure TDockingSite.pnlLeftDockDrop(Sender: TObject;
  Source: TDragDockObject; X, Y: Integer);
var
  w: integer;
  r: TRect;
  Site: TWinControl absolute Sender;
begin
(* Adjust docksite extent, if required.
  H/V depending on align LR/TB.
  Take 1/3 of the form's extent for the dock site.
  When changed, ensure that the form layout is updated.
*)
  if (TWinControl(Source.DragTarget).DockClientCount > 1)
  or ((Site.Width > 1) and (Site.Height > 1)) //NoteBook!
  then
    exit; //no adjustments of the dock site required
  with Source do begin
    if DragTarget.Align in [alLeft, alRight] then begin
      w := self.Width div 3;
      if DragTarget.Width < w then begin
      //enlarge docksite
        DisableAlign; //form(?)
        DragTarget.Width := w;
        if DragTarget.Align = alRight then begin
          if AutoExpand then begin
            r := self.BoundsRect;
            inc(r.Right, w);
            BoundsRect := r;
          end else begin
            dec(DragTarget.Left, w);
            dec(splitRight.Left, w);
          end;
        end else if AutoExpand then begin
        //enlarge left
          r := BoundsRect;
          dec(r.Left, w);
          BoundsRect := r;
        end;
        EnableAlign;
      end;
    end else begin
      w := self.Height div 3;
      if DragTarget.Height < w then begin
      //enlarge docksite
        DisableAlign; //form(?)
        DragTarget.Height := w;
        if DragTarget.Align = alBottom then begin
          if AutoExpand then begin
            //dec(self.Left, w);
            r := self.BoundsRect;
            inc(r.Bottom, w);
            BoundsRect := r;
            inc(StatusBar1.Top, w);
          end else begin
            dec(splitBottom.Top, w);
            dec(DragTarget.Top, w);
          end;
        end;
        EnableAlign;
      end;
    end;
    //Control.Align := alClient;
  end;
end;

procedure TDockingSite.pnlLeftDockOver(Sender: TObject;
  Source: TDragDockObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
var
  r: TRect;

  procedure Adjust(dw, dh: integer);
  begin
  (* r.TopLeft in screen coords, r.BottomRight is W/H(?)
    negative values mean expansion towards screen origin
  *)
    if dw <> 0 then begin
      r.Right := r.Left;
      inc(r.Bottom, r.Top);
      if dw > 0 then
        inc(r.Right, dw)
      else
        inc(r.Left, dw);
    end else begin
      r.Bottom := r.Top;
      inc(r.Right, r.Left);
      if dh > 0 then
        inc(r.Bottom, dh)
      else
        inc(r.Top, dh);
    end;
  end;

var
  Site: TWinControl;  // absolute Sender;
  dw, dh: integer;
  dummy: boolean;
begin
(* This handler has to determine the intended DockRect,
  and the alignment within this rectangle.

  This is impossible when the mouse leaves the InfluenceRect,
  i.e. when the site is not yet expanded :-(

  For a shrinked site we only can display the intended DockRect,
  and signal alClient.
*)
  if Source.DragTarget = nil then
    exit; //shit happens :-(
  if State = dsDragMove then begin
    TObject(Site) := Source.DragTarget;
    if Site.DockClientCount > 0 then
      exit; //everything should be okay
  //make DockRect reflect the docking area
    //with Source do begin
      //StatusBar1.SimpleText := AlignNames[Source.DropAlign];
    {$IFnDEF old}
      r := Site.BoundsRect; //XYWH
      r.TopLeft := Site.Parent.ClientToScreen(r.TopLeft);
    {$ELSE}
      GetWindowRect(TWinControl(Source.DragTarget).handle, r);
      //Site.GetSiteInfo(Site, r, Point(0,0), dummy);
    {$ENDIF}
      dw := Width div 3;  //r.Right := r.Left + dw;
      dh := Height div 3; //r.Bottom := r.Top + dh;
    //determine inside/outside
      case Site.Align of
      alLeft:   if AutoExpand then Adjust(-dw, 0) else Adjust(dw, 0);
      alRight:  if AutoExpand then Adjust(dw, 0) else Adjust(-dw, 0);
      alBottom: if AutoExpand then Adjust(0, dh) else Adjust(0, -dh);
      else      exit;
      end;
      Source.DockRect := r;
    //end;
    Accept := True;
  end;
end;

procedure TDockingSite.pnlLeftGetSiteInfo(Sender: TObject;
  DockClient: TControl; var InfluenceRect: TRect; MousePos: TPoint;
  var CanDock: Boolean);
begin
  CanDock := True;
end;

procedure TDockingSite.pnlLeftUnDock(Sender: TObject; Client: TControl;
  NewTarget: TWinControl; var Allow: Boolean);
var
  Site: TWinControl absolute Sender;
  wh: integer;
  r: TRect;
begin
(* When the last client is undocked, shrink the dock site to zero extent.
  Called *before* the dock client is removed.
*)
  if Site.DockClientCount <= 1 then begin
  //become empty, hide the dock site
    DisableAlign;
    case Site.Align of
    alLeft:
      begin
        wh := Site.Width;
        Site.Width := 0; //behaves as expected
        if AutoExpand then begin
          r := BoundsRect;
          inc(r.Left, wh);
          BoundsRect := r;
        end;
      end;
    alRight:
      begin //problem: does NOT resize?
        wh := Site.Width;
        Site.Width := 0;
        if AutoExpand then begin
          r := BoundsRect;
          dec(r.Right, wh);
          BoundsRect := r; //does not resize :-(
        end else begin
          inc(Site.Left, wh);
          inc(splitRight.Left, wh); //doesn't help :-(
        end;
      end;
    alBottom:
      begin
        wh := Site.Height;
        Site.Height := 0;
        if AutoExpand then begin
          r := BoundsRect;
          dec(r.Bottom, wh);
          BoundsRect := r;
          dec(splitBottom.Top, wh);
          dec(StatusBar1.Top, wh);
        end else begin
          inc(Site.Top, wh);
          splitBottom.Top := Site.Top - splitBottom.Height - 10;
        end;
      end;
    end;
    EnableAlign;
    //RecreateWnd(self); - doesn't help
  end;
end;

procedure TDockingSite.SetAutoExpand(NewValue: boolean);
begin
  FAutoExpand:=NewValue;
end;

initialization
  {$I felastic.lrs}
  DefaultDockManagerClass := TEasyTree;

end.

