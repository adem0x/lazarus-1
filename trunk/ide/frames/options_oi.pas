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
unit options_OI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, StdCtrls, Dialogs, Spin, LCLProc,
  ObjectInspector, LazarusIDEStrConsts, EnvironmentOpts, IDEOptionsIntf,
  ColorBox, Graphics;

type
  TColorRec = record
    ColorName: String;
    ColorValue: TColor;
  end;

  { TOIOptionsFrame }

  TOIOptionsFrame = class(TAbstractIDEOptionsEditor)
    BtnUseDefaultLazarusColors: TButton;
    BtnUseDefaultDelphiColors: TButton;
    OIShowGutterCheckBox: TCheckBox;
    ColorBox: TColorBox;
    ColorsListBox: TColorListBox;
    ObjectInspectorColorsGroupBox: TGroupBox;
    OIAutoShowCheckBox: TCheckBox;
    OIBoldNonDefaultCheckBox: TCheckBox;
    OIDefaultItemHeightLabel: TLabel;
    OIDefaultItemHeightSpinEdit: TSpinEdit;
    OIDrawGridLinesCheckBox: TCheckBox;
    OIMiscGroupBox: TGroupBox;
    OIShowHintCheckBox: TCheckBox;
    procedure BtnUseDefaultDelphiColorsClick(Sender: TObject);
    procedure BtnUseDefaultLazarusColorsClick(Sender: TObject);
    procedure ColorBoxChange(Sender: TObject);
    procedure ColorsListBoxGetColors(Sender: TCustomColorListBox;
      Items: TStrings);
    procedure ColorsListBoxSelectionChange(Sender: TObject; User: boolean);
  private
    FStoredColors: array of TColorRec;
    FLoaded: Boolean;
    procedure ChangeColor(AIndex: Integer; NewColor: TColor);
  public
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  end; 

implementation

type
  THackColorListBox = class(TColorListBox);


{ TOIOptionsFrame }

procedure TOIOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  ObjectInspectorColorsGroupBox.Caption := dlgEnvColors;
  OIMiscGroupBox.Caption := dlgOIMiscellaneous;
  OIDefaultItemHeightLabel.Caption := dlgOIItemHeight;
  OIShowHintCheckBox.Caption := lisShowHintsInObjectInspector;
  OIAutoShowCheckBox.Caption := lisAutoShowObjectInspector;
  OIBoldNonDefaultCheckBox.Caption := lisBoldNonDefaultObjectInspector;
  OIDrawGridLinesCheckBox.Caption := lisDrawGridLinesObjectInspector;
  OIShowGutterCheckBox.Caption := lisShowGutterInObjectInspector;

  SetLength(FStoredColors, 10);
  FStoredColors[0].ColorName := dlgBackColor;
  FStoredColors[1].ColorName := dlgPropGutterColor;
  FStoredColors[2].ColorName := dlgPropGutterEdgeColor;
  FStoredColors[3].ColorName := dlgHighlightColor;
  FStoredColors[4].ColorName := dlgHighlightFontColor;
  FStoredColors[5].ColorName := dlgPropNameColor;
  FStoredColors[6].ColorName := dlgValueColor;
  FStoredColors[7].ColorName := dlgDefValueColor;
  FStoredColors[8].ColorName := dlgSubPropColor;
  FStoredColors[9].ColorName := dlgReferenceColor;

  BtnUseDefaultLazarusColors.Caption := dlgOIUseDefaultLazarusColors;
  BtnUseDefaultDelphiColors.Caption := dlgOIUseDefaultDelphiColors;

  FLoaded := False;
end;

procedure TOIOptionsFrame.ColorsListBoxGetColors(Sender: TCustomColorListBox;
  Items: TStrings);
var
  i: integer;
begin
  if not FLoaded then
    Exit;
  for i := Low(FStoredColors) to High(FStoredColors) do
    Items.AddObject(FStoredColors[i].ColorName, TObject(PtrInt(FStoredColors[i].ColorValue)));
end;

procedure TOIOptionsFrame.ChangeColor(AIndex: Integer; NewColor: TColor);
begin
  ColorsListBox.Items.Objects[AIndex] := TObject(PtrInt(NewColor));
end;

procedure TOIOptionsFrame.ColorBoxChange(Sender: TObject);
begin
  if not FLoaded or (ColorsListBox.ItemIndex < 0) then
    Exit;
  ChangeColor(ColorsListBox.ItemIndex, ColorBox.Selected);
  ColorsListBox.Invalidate;
end;

procedure TOIOptionsFrame.BtnUseDefaultLazarusColorsClick(Sender: TObject);
begin
  ChangeColor(0, DefBackgroundColor);
  ChangeColor(1, DefGutterColor);
  ChangeColor(2, DefGutterEdgeColor);
  ChangeColor(3, DefHighlightColor);
  ChangeColor(4, DefHighlightFontColor);
  ChangeColor(5, DefNameColor);
  ChangeColor(6, DefValueColor);
  ChangeColor(7, DefDefaultValueColor);
  ChangeColor(8, DefSubPropertiesColor);
  ChangeColor(9, DefReferencesColor);
  ColorsListBox.Invalidate;
end;

procedure TOIOptionsFrame.BtnUseDefaultDelphiColorsClick(Sender: TObject);
begin
  ChangeColor(0, clWindow);
  ChangeColor(1, clCream);
  ChangeColor(2, clGray);
  ChangeColor(3, $E0E0E0);
  ChangeColor(4, clBlack);
  ChangeColor(5, clBtnText);
  ChangeColor(6, clNavy);
  ChangeColor(7, clNavy);
  ChangeColor(8, clGreen);
  ChangeColor(9, clMaroon);
  ColorsListBox.Invalidate;
end;

procedure TOIOptionsFrame.ColorsListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  if not (FLoaded and User) then
    Exit;
  ColorBox.Selected := ColorsListBox.Selected;
end;

function TOIOptionsFrame.GetTitle: String;
begin
  Result := dlgObjInsp;
end;

procedure TOIOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    FStoredColors[0].ColorValue := ObjectInspectorOptions.GridBackgroundColor;
    FStoredColors[1].ColorValue := ObjectInspectorOptions.GutterColor;
    FStoredColors[2].ColorValue := ObjectInspectorOptions.GutterEdgeColor;
    FStoredColors[3].ColorValue := ObjectInspectorOptions.HighlightColor;
    FStoredColors[4].ColorValue := ObjectInspectorOptions.HighlightFontColor;
    FStoredColors[5].ColorValue := ObjectInspectorOptions.PropertyNameColor;
    FStoredColors[6].ColorValue := ObjectInspectorOptions.ValueColor;
    FStoredColors[7].ColorValue := ObjectInspectorOptions.DefaultValueColor;
    FStoredColors[8].ColorValue := ObjectInspectorOptions.SubPropertiesColor;
    FStoredColors[9].ColorValue := ObjectInspectorOptions.ReferencesColor;

    OIDefaultItemHeightSpinEdit.Value:=ObjectInspectorOptions.DefaultItemHeight;
    OIShowHintCheckBox.Checked := ObjectInspectorOptions.ShowHints;
    OIAutoShowCheckBox.Checked := ObjectInspectorOptions.AutoShow;
    OIBoldNonDefaultCheckBox.Checked := ObjectInspectorOptions.BoldNonDefaultValues;
    OIDrawGridLinesCheckBox.Checked := ObjectInspectorOptions.DrawGridLines;
    OIShowGutterCheckBox.Checked := ObjectInspectorOptions.ShowGutter;
  end;
  FLoaded := True;
  THackColorListBox(ColorsListBox).SetColorList;
end;

procedure TOIOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
begin
  with AOptions as TEnvironmentOptions do
  begin
    ObjectInspectorOptions.GridBackgroundColor := ColorsListBox.Colors[0];
    ObjectInspectorOptions.GutterColor := ColorsListBox.Colors[1];
    ObjectInspectorOptions.GutterEdgeColor := ColorsListBox.Colors[2];
    ObjectInspectorOptions.HighlightColor := ColorsListBox.Colors[3];
    ObjectInspectorOptions.HighlightFontColor := ColorsListBox.Colors[4];
    ObjectInspectorOptions.PropertyNameColor := ColorsListBox.Colors[5];
    ObjectInspectorOptions.ValueColor := ColorsListBox.Colors[6];
    ObjectInspectorOptions.DefaultValueColor := ColorsListBox.Colors[7];
    ObjectInspectorOptions.SubPropertiesColor := ColorsListBox.Colors[8];
    ObjectInspectorOptions.ReferencesColor := ColorsListBox.Colors[9];

    ObjectInspectorOptions.DefaultItemHeight:=
       RoundToInt(OIDefaultItemHeightSpinEdit.Value);
    ObjectInspectorOptions.ShowHints := OIShowHintCheckBox.Checked;
    ObjectInspectorOptions.AutoShow := OIAutoShowCheckBox.Checked;
    ObjectInspectorOptions.BoldNonDefaultValues := OIBoldNonDefaultCheckBox.Checked;
    ObjectInspectorOptions.DrawGridLines := OIDrawGridLinesCheckBox.Checked;
    ObjectInspectorOptions.ShowGutter := OIShowGutterCheckBox.Checked;
  end;
end;

class function TOIOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  {$I options_oi.lrs}
  RegisterIDEOptionsEditor(GroupEnvironment, TOIOptionsFrame, EnvOptionsOI);
end.

