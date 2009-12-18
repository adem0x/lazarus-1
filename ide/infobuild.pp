{
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
 Dialog box used during compile or build

 $Author$    Guadagnini David
 $Date$      Feb-28-2008
 $Revision$  2.1
}
unit InfoBuild;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  LCLProc, ExtCtrls, StdCtrls, ExtDlgs, LazIDEIntf, LazarusIDEStrConsts;

type

  { TCompileInfoDlg }

  TCompileInfoDlg = class (TForm)
    BClose: TBitBtn;
    lbInfo: TLabel;
    LInfoError: TLabel;
    LInfoHint: TLabel;
    LInfoLines: TLabel;
    LInfoNote: TLabel;
    LInfoWarning: TLabel;
    LNError: TLabel;
    LNHint: TLabel;
    LNLines: TLabel;
    LNNote: TLabel;
    LNWarning: TLabel;
    pnlLines: TPanel;
    Panel3: TPanel;
    pnlNotesErrors: TPanel;
    pnlHintsWarnings: TPanel;
    pnlHintsWarnings1: TPanel;
    pnlHintsWarnings2: TPanel;
    pnlErrors: TPanel;
    pnlInfo: TPanel;
    pnlButton: TPanel;
    PCurrentStatus : TLabel;
    Panel1 : TPanel;
    PnlTitle : TPanel;
    procedure BCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    NHints    : Integer;
    NWarnings : Integer;
    NErrors   : Integer;
    NNotes    : Integer;
    NLines    : Integer;
    ToAbort   : Boolean;
  public
    procedure SetProjectName(const Sname: String);
    procedure SetStatus(const SStatus: String);
    procedure SetCanClose;
    procedure MakeBold;
  end;

  TCompileProgressClass = class of TCompileProgress;

  { TCompileProgress }

  TCompileProgress = class
    class procedure CreateDialog(AOwner: TComponent; const AProject, AStatus: String);
    class procedure Close;
    class procedure Show;
    class procedure Hide;
    class procedure SetEnabled(AValue: Boolean);
    class procedure SetStatus(const AStatus: String);
    class procedure SetProject(const AProject: String);
    class procedure Ready(const AMessage: String = '');
    class procedure Ready(const AMessage: String; const AParams: array of const);
  end;

var
  CompileProgress: TCompileProgressClass = TCompileProgress;

implementation

var
  MCompileInfoDlg: TCompileInfoDlg;
  MCompileDialogEnabled: Boolean = False;

{ TCompileInfoDlg }

procedure TCompileInfoDlg.BCloseClick(Sender: TObject);
begin
  if ToAbort then
  begin
    LazarusIDE.AbortBuild;
    SetStatus('Aborted...!');
    MakeBold;
    SetCanClose;
  end else
    Close;
end;

procedure TCompileInfoDlg.FormCreate (Sender: TObject);
begin
  NHints    := 0;
  NWarnings := 0;
  NErrors   := 0;
  NNotes    := 0;
  NLines    := 0;


  LInfoLines.Caption   := lisInfoBuildLines;
  LInfoError.Caption   := lisInfoBuildErrors;
  LInfoHint.Caption    := lisInfoBuildHint;
  LInfoWarning.Caption := lisInfoBuildWarning;
  LInfoNote.Caption    := lisInfoBuildNote;
  BClose.Kind          := bkNoToAll;
  BClose.Caption       := lisInfoBuildMakeAbort;
  Caption              := lisInfoBuildCaption;

  ToAbort              := True;
  BClose.LoadGlyphFromLazarusResource('btn_ok');

  SetProjectName('');
  SetStatus('');
end;


procedure TCompileInfoDlg.SetProjectName(const Sname : String);
begin
  lbInfo.Caption := lisInfoBuildBuild + ' '+ ExtractFileName(Sname);
end;

procedure TCompileInfoDlg.SetStatus(const SStatus : String);
Var
  S  : String;
  Ok : Boolean;
  NL : Integer;
  iLoc:Integer;
begin

  S  := LowerCase(SStatus);

  if (pos('warning(s)', s) > 0) or
     (pos('hint(s)',    s) > 0) or
     (pos('note(s)',    s) > 0) then exit;

  Ok := True;

  if (Pos('hint:', s) > 0) then
  begin
    Inc(NHints);
    LNHint.Caption := IntToStr(NHints);
    Ok             := False;
  end;

  If Pos('warning:', s) > 0 then
  begin
    Inc(NWarnings);
    LNWarning.Caption := IntToStr(NWarnings);
    Ok                := False;
  end;

  If (Pos('fatal:', s) > 0) Or (Pos('error:', s) > 0) then
  begin
    Inc(NErrors);
    LNError.Caption := IntToStr(NErrors);
    Ok              := False;
  end;

  If (Pos('note:', s) > 0) then
  begin
    Inc(NNotes);
    LNNote.Caption := IntToStr(NNotes);
    Ok             := False;
  end;
  iLoc:=Pos('lines compiled', s);
  If (iLoc> 0) then begin
    s := copy(s, 1, iLoc-1);
    while copy(s, 1, 1) = ' ' do delete(s, 1, 1);
    while copy(s, length(s), 1) = ' ' do delete(s, length(s), 1);
    
    NL := StrTointDef(S,0);
    NLines := NLines + NL;
    LNLines.Caption := FormatFloat('#,##0',NLines);
    Ok              := false;
  end;
  If Ok then PCurrentStatus.Caption := SStatus;
  pnlInfo.Refresh;
end;

procedure TCompileInfoDlg.SetCanClose;
begin
  ToAbort        := False;
  BClose.Kind    := bkOk;
  BClose.Caption := lisMenuClose;
end;

procedure TCompileInfoDlg.MakeBold;
begin
  PCurrentStatus.Font.Style:= PCurrentStatus.Font.Style + [fsBold];
end;


{ TCompileProgress }

class procedure TCompileProgress.Close;
begin
  FreeAndNil(MCompileInfoDlg);
end;

class procedure TCompileProgress.CreateDialog(AOwner: TComponent; const AProject, AStatus: String);
begin
  Close;
  if MCompileDialogEnabled then
  begin
    MCompileInfoDlg := TCompileInfoDlg.Create(AOwner);
    MCompileInfoDlg.SetProjectName(AProject);
    MCompileInfoDlg.SetStatus(AStatus);
    // delay show til actual compile
    //MCompileInfoDlg.Show;
  end;
end;

class procedure TCompileProgress.Hide;
begin
  if MCompileInfoDlg = nil then Exit;
  MCompileInfoDlg.Hide;
end;

class procedure TCompileProgress.SetEnabled(AValue: Boolean);
begin
  MCompileDialogEnabled := AValue;
end;

class procedure TCompileProgress.SetProject(const AProject: String);
begin
  if MCompileInfoDlg = nil then Exit;
  MCompileInfoDlg.SetProjectName(AProject);
end;

class procedure TCompileProgress.Ready(const AMessage: String);
begin
  if MCompileInfoDlg = nil then Exit;
  if AMessage <> ''
  then begin
    MCompileInfoDlg.SetStatus(AMessage);
    MCompileInfoDlg.MakeBold;
  end;
  MCompileInfoDlg.SetCanClose;
end;

class procedure TCompileProgress.Ready(const AMessage: String; const AParams: array of const);
begin
  if MCompileInfoDlg = nil then Exit;
  Ready(Format(AMessage, AParams));
end;

class procedure TCompileProgress.SetStatus(const AStatus: String);
begin
  if MCompileInfoDlg = nil then Exit;
  MCompileInfoDlg.SetStatus(AStatus);
end;

class procedure TCompileProgress.Show;
begin
  if MCompileInfoDlg = nil then Exit;
  MCompileInfoDlg.Show;
end;

initialization
  {$I infobuild.lrs}

end.


