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
}
unit frmgeneratesql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, Buttons, StdCtrls, Spin, RTTICtrls, fpdatadict;

type

  { TGenerateSQLForm }

  TGenerateSQLForm = class(TForm)
    BOK: TButton;
    BCancel: TButton;
    BGenerate: TButton;
    CBTables: TComboBox;
    LCBTables: TLabel;
    Label2: TLabel;
    LLBKeyFields: TLabel;
    LBKeyFields: TListBox;
    LBFields: TListBox;
    LSEIndent: TLabel;
    LSELineLength: TLabel;
    MDelete: TMemo;
    MCreate: TMemo;
    MUpdate: TMemo;
    MInsert: TMemo;
    MSelect: TMemo;
    PKeyFields: TPanel;
    POptions: TPanel;
    PSelectFields: TPanel;
    PCSQL: TPageControl;
    PButtons: TPanel;
    SELineLength: TTISpinEdit;
    SEIndent: TTISpinEdit;
    CLBOptions: TTICheckGroup;
    TSCreate: TTabSheet;
    TSFields: TTabSheet;
    TSSelect: TTabSheet;
    TSInsert: TTabSheet;
    TSUpdate: TTabSheet;
    TSDelete: TTabSheet;
    procedure BGenerateClick(Sender: TObject);
    procedure CBTablesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LBKeyFieldsClick(Sender: TObject);
    procedure TSResize(Sender: TObject);
  private
    FGetTableDef: TDDTableDef;
    FTableDefs : TDDTableDefs;
    FGenerator : TFPDDSQLEngine;
    FSQLGenerated : Boolean;
    function GetSQLStatement(Index: integer): TStrings;
    function GetTableDef: TDDTableDef;
    function GetTableName: String;
    procedure SetTableDefs(const AValue: TDDTableDefs);
    procedure SetTableName(const AValue: String);
    Procedure SetFieldLists(TD : TDDTableDef);
    { private declarations }
  public
    { public declarations }
    Procedure RefreshTableList;
    Procedure GenerateSQL;
    Procedure ClearSQL;
    Property TableDefs : TDDTableDefs Read FTableDefs Write SetTableDefs;
    Property TableName : String Read GetTableName Write SetTableName;
    Property SelectSQL : TStrings Index 0 Read GetSQLStatement;
    Property TableDef  : TDDTableDef Read GetTableDef;
  end; 

var
  GenerateSQLForm: TGenerateSQLForm;

implementation

{ TGenerateSQLForm }

ResourceString
  SErrSelectTable  = 'No table selected. Please select a table';
  SErrSelectFields = 'No fields selected. Please select some fields';
  
procedure TGenerateSQLForm.TSResize(Sender: TObject);

Var
  W : Integer;
  
begin
  W:=TSFields.CLientWidth div 3;
  POPtions.Width:=W;
  PSelectFIelds.Width:=W;
end;

procedure TGenerateSQLForm.SetTableDefs(const AValue: TDDTableDefs);
begin
  if (FTableDefs=AValue) then
    exit;
  FTableDefs:=AValue;
  RefreshTableList;
end;

function TGenerateSQLForm.GetTableName: String;
begin
  Result:=CBTables.Text;
end;

function TGenerateSQLForm.GetSQLStatement(Index: integer): TStrings;
begin
  Case Index of
    0 : Result:=MSelect.Lines;
  end;
end;

function TGenerateSQLForm.GetTableDef: TDDTableDef;
begin
  With CBTables do
    If (ItemIndex=-1) then
      Result:=Nil
    else
      Result:=Items.Objects[ItemIndex] as TDDTableDef;
end;

Procedure TGenerateSQLForm.RefreshTableList;

Var
  TN : String;
  I : Integer;
begin
  TN:=CBTables.Text;
  With CBTables.Items do
    begin
    Clear;
    If Assigned(FTableDefs) then
      For I:=0 to FTableDefs.Count-1 do
        AddObject(FTableDefs[i].TableName,FTableDefs[i]);
    end;
  With CBTables do
    If (TN<>'') then
      ItemIndex:=Items.IndexOf(TN);
end;

procedure TGenerateSQLForm.ClearSQL;

begin
  MSelect.Clear;
  MInsert.Clear;
  MUpdate.Clear;
  MDelete.Clear;
  MCreate.Clear;
  FSQLGenerated:=False;
  BOK.Default:=False;
  BGenerate.Default:=True;
end;

procedure TGenerateSQLForm.GenerateSQL;

  Function CreateFieldListFromLB(LB : TListBox) : TFPDDFieldList;
  
  Var
    I : integer;
  
  begin
    Result:=TFPDDFieldList.Create(False);
    try
      With LB do
        For I:=0 to Items.Count-1 do
          If Selected[i] then
            Result.Add(Items.Objects[i]);
    except
      Result.Free;
      Raise;
    end;

  end;

Var
  I : integer;
  KL,FL : TFPDDFieldList;
  
begin
  ClearSQL;
  If (TableName='') then
    Raise Exception.Create(SErrSelectTable);
  If (LBFields.SelCount=0) then
    Raise Exception.Create(SErrSelectFields);
  KL:=CreateFieldListFromLB(LBKeyFields);
  try
    FL:=CreateFieldListFromLB(LBFields);
    try
      With FGenerator do
        begin
        TableDef:=Self.TableDef;
        CreateSelectSQLStrings(FL,KL,MSelect.Lines);
        CreateInsertSQLStrings(FL,MInsert.Lines);
        CreateUpdateSQLStrings(FL,KL,MUpdate.Lines);
        CreateDeleteSQLStrings(KL,MDelete.Lines);
        CreateCreateSQLStrings(FL,KL,MCreate.Lines);
        end;
      FSQLGenerated:=True;
      BGenerate.Default:=False;
      BOK.Default:=True;
      PCSQL.ActivePage:=TSSelect;
    finally
      FL.Free;
    end;
  finally
    KL.Free;
  end;
end;

procedure TGenerateSQLForm.SetTableName(const AValue: String);

begin
  With CBTables do
    ItemIndex:=Items.IndexOf(AValue);
end;

procedure TGenerateSQLForm.SetFieldLists(TD: TDDTableDef);

  Procedure FillLB(LB : TListBox);

  Var
    I : Integer;
    
  begin
    With LB.Items do
      begin
      Clear;
      If Assigned(TD) then
        For I:=0 to TD.Fields.Count-1 do
          AddObject(TD.FIelds[i].FieldName,TD.FIelds[i]);
      end;
  end;
  
begin
  FillLB(LBKeyFields);
  FillLB(LBFields);
end;

procedure TGenerateSQLForm.CBTablesChange(Sender: TObject);

begin
  With CBTables do
    If (ItemIndex<>-1) Then
      SetFieldLists(Items.Objects[ItemIndex] as TDDTableDef)
    else
      SetFieldLists(Nil);
  ClearSQL;
end;

procedure TGenerateSQLForm.FormCreate(Sender: TObject);
begin
  FGenerator:=TFPDDSQLEngine.Create;
  CLBOptions.Link.TIObject:=FGenerator;
  SEIndent.Link.TIObject:=FGenerator;
  SELineLength.Link.TIObject:=FGenerator;
end;

procedure TGenerateSQLForm.LBKeyFieldsClick(Sender: TObject);
begin

end;

procedure TGenerateSQLForm.BGenerateClick(Sender: TObject);
begin
  GenerateSQL;
end;

initialization
  {$I frmgeneratesql.lrs}

end.

