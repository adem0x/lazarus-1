{
 /***************************************************************************
                  project.pp  -  project utility class file
                  -----------------------------------------
          TProject is responsible for managing a complete project.


              Initial Revision  : Sun Mar 28 23:15:32 CST 1999


 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

}
unit frmCustomApplicationOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons,
  LazarusIDEStrConsts;

type

  { TCustomApplicationOptionsForm }

  TCustomApplicationOptionsForm = class(TForm)
    BCancel: TBitBtn;
    BOK: TBitBtn;
    CGOptions: TCheckGroup;
    EClassName: TEdit;
    ETitle: TEdit;
    LETitle: TLabel;
    LEClassName: TLabel;
    procedure EClassNameKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    function GetAppName: String;
    function GetBool(Index: integer): Boolean;
    function GetTitle: String;
  private
    { private declarations }
  public
    { public declarations }
    Property Title : String Read GetTitle;
    Property AppClassName : String Read GetAppName;
    Property CodeUsage : Boolean Index 0 Read GetBool;
    Property CodeStopOnError : Boolean Index 1 Read GetBool;
    Property CodeConstructor : Boolean Index 2 Read GetBool;
    Property CodeDestructor : Boolean Index 3 Read GetBool;
    Property CodeCheckOptions : Boolean Index 4 Read GetBool;
  end;

var
  CustomApplicationOptionsForm: TCustomApplicationOptionsForm;

implementation

{ TCustomApplicationOptionsForm }

function TCustomApplicationOptionsForm.GetAppName: String;
begin
  Result:=EClassName.Text;
end;

procedure TCustomApplicationOptionsForm.EClassNameKeyPress(Sender: TObject;
  var Key: char);

Const
  Alpha = ['a'..'z','A'..'Z'];
  Num   = ['0'..'9'];
  Oth   = ['_',#8,#9,#27]; // allow Backspace, tab, escape
  AllowedKeys = Alpha+Num+Oth;
  
begin
  If Not (Key in AllowedKeys) then
    Key:=#0;
end;

procedure TCustomApplicationOptionsForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Caption:= lisNewConsoleApplication;
  LEClassName.Caption:= lisApplicationClassName;
  LETitle.Caption:= lisTitle;
  CGOptions.Caption:= lisCodeGenerationOptions;
  CGOptions.Items.Clear;
  CGOptions.Items.Add(lisUsageMessageHOption);
  CGOptions.Items.Add(lisStopOnException);
  CGOptions.Items.Add(lisConstructorCode);
  CGOptions.Items.Add(lisDestructorCode);
  CGOptions.Items.Add(lisCheckOptions);

  // set all defaults to true
  for i:=0 to CGOptions.Items.Count-1 do
    CGOptions.Checked[i]:= true;

  BOK.Caption:= lisOkBtn;
  BCancel.Caption:= dlgCancel;

  BOK.LoadGlyphFromLazarusResource('btn_ok');
  BCancel.LoadGlyphFromLazarusResource('btn_cancel');
end;

function TCustomApplicationOptionsForm.GetBool(Index: integer): Boolean;
begin
  Result:= CGOptions.Checked[Index];
end;

function TCustomApplicationOptionsForm.GetTitle: String;
begin
  Result:=ETitle.Text;
end;

initialization
  {$I frmcustomapplicationoptions.lrs}

end.

