unit toolbartest;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  customdrawncontrols, customdrawndrawers, ComCtrls, StdCtrls;

type

  { TFormToolBar }

  TFormToolBar = class(TForm)
    ImageList1: TImageList;
    Label1: TLabel;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    lToolBar: TCDToolBar;
  end;

var
  FormToolBar: TFormToolBar;

implementation

uses
  mainform;

{$R *.lfm}

{ TFormToolBar }

procedure TFormToolBar.FormCreate(Sender: TObject);
var
  lBmp: TBitmap;
  lItem: TCDToolBarItem;
begin
  lBmp := TBitmap.Create;

  lToolBar := TCDToolBar.Create(Self);
  lToolBar.Parent := Self;
  lBmp.LoadFromFile('/usr/share/magnifier/lupa.bmp');
  lItem := lToolBar.AddItem(tikButton);
  lItem.Image := lBmp;
  lItem.Caption := 'Btn 1';
  lToolBar.Parent := Self;
  lToolBar.Parent := Self;
end;

procedure TFormToolBar.FormShow(Sender: TObject);
begin
  lToolBar.DrawStyle := TCDDrawStyle(formCDControlsTest.comboDrawer.ItemIndex);
end;

end.

