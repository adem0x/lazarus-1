{
 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

  Author: Mattias Gaertner

  Abstract:
    Find in files dialog form.

}
unit FindInFilesDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLLinux, Controls, StdCtrls, Forms, Buttons, ExtCtrls,
  LResources, LazarusIDEStrConsts;

type
  TLazFindInFilesDialog = class(TForm)
    TextToFindLabel: TLabel;
    TextToFindEdit: TEdit;
    OptionsGroupBox: TGroupBox;
    CaseSensitiveCheckBox: TCheckBox;
    WholeWordsOnlyCheckBox: TCheckBox;
    RegularExpressionsCheckBox: TCheckBox;
    WhereRadioGroup: TRadioGroup;
    DirectoryOptionsGroupBox: TGroupBox;
    DirectoryLabel: TLabel;
    DirectoryComboBox: TComboBox;
    DirectoryBrowse: TBitBtn;
    FileMaskLabel: TLabel;
    FileMaskComboBox: TComboBox;
    IncludeSubDirsCheckBox: TCheckBox;
    OkButton: TButton;
    CancelButton: TButton;
    procedure LazFindInFilesDialogResize(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  public
    constructor Create(AOwner:TComponent); override;
  end;


var FindInFilesDialog: TLazFindInFilesDialog;


implementation

{ TLazFindInFilesDialog }

constructor TLazFindInFilesDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    Caption:=srkmecFindInFiles;
    Width:=320;
    Height:=430;
    Position:=poScreenCenter;
    OnResize:=@LazFindInFilesDialogResize;

    TextToFindLabel:=TLabel.Create(Self);
    with TextToFindLabel do begin
      Name:='TextToFindLabel';
      Parent:=Self;
      SetBounds(8,8,80,Height);
      Caption:=lisFindFileTextToFind;
      Visible:=true;
    end;
    
    TextToFindEdit:=TEdit.Create(Self);
    with TextToFindEdit do begin
      Name:='TextToFindEdit';
      Parent:=Self;
      SetBounds(TextToFindLabel.Left+TextToFindLabel.Width+5,
        TextToFindLabel.Top-2,
        Self.ClientWidth-TextToFindLabel.Left-TextToFindLabel.Width-13,
        Height);
      Text:='';
      Visible:=true;
    end;
    
    OptionsGroupBox:=TGroupBox.Create(Self);
    with OptionsGroupBox do begin
      Name:='OptionsGroupBox';
      Parent:=Self;
      SetBounds(8,TextToFindLabel.Top+TextToFindLabel.Height+10,
        Self.ClientWidth-20,95);
      Caption:=dlgFROpts;
      Visible:=true;
    end;
    
    CaseSensitiveCheckBox:=TCheckBox.Create(Self);
    with CaseSensitiveCheckBox do begin
      Name:='CaseSensitiveCheckBox';
      Parent:=OptionsGroupBox;
      SetBounds(8,2,OptionsGroupBox.ClientWidth-20,20);
      Caption:=lisFindFileCaseSensitive;
      Visible:=true;
    end;
    
    WholeWordsOnlyCheckBox:=TCheckBox.Create(Self);
    with WholeWordsOnlyCheckBox do begin
      Name:='WholeWordsOnlyCheckBox';
      Parent:=OptionsGroupBox;
      SetBounds(CaseSensitiveCheckBox.Left,
           CaseSensitiveCheckBox.Top+CaseSensitiveCheckBox.Height+5,
           CaseSensitiveCheckBox.Width,20);
      Caption:=lisFindFileWholeWordsOnly;
      Visible:=true;
    end;
    
    RegularExpressionsCheckBox:=TCheckBox.Create(Self);
    with RegularExpressionsCheckBox do begin
      Name:='RegularExpressionsCheckBox';
      Parent:=OptionsGroupBox;
      SetBounds(CaseSensitiveCheckBox.Left,
           WholeWordsOnlyCheckBox.Top+WholeWordsOnlyCheckBox.Height+5,
           CaseSensitiveCheckBox.Width,20);
      Caption:=lisFindFileRegularExpressions;
      Visible:=true;
    end;
    
    WhereRadioGroup:=TRadioGroup.Create(Self);
    with WhereRadioGroup do begin
      Name:='WhereRadioGroup';
      Parent:=Self;
      SetBounds(8,OptionsGroupBox.Top+OptionsGroupBox.Height+10,
        Self.ClientWidth-20,90);
      Caption:=lisFindFileWhere;
      Items.BeginUpdate;
      Items.Add(lisFindFilesearchAllFilesInProject);
      Items.Add(lisFindFilesearchAllOpenFiles);
      Items.Add(lisFindFilesearchInDirectories);
      Items.EndUpdate;
      Visible:=true;
    end;
    
    DirectoryOptionsGroupBox:=TGroupBox.Create(Self);
    with DirectoryOptionsGroupBox do begin
      Name:='DirectoryOptionsGroupBox';
      Parent:=Self;
      SetBounds(8,WhereRadioGroup.Top+WhereRadioGroup.Height+10,
        Self.ClientWidth-20,135);
      Caption:=lisFindFileDirectoryOptions;
      Visible:=true;
    end;
    
    DirectoryLabel:=TLabel.Create(Self);
    with DirectoryLabel do begin
      Name:='DirectoryLabel';
      Parent:=DirectoryOptionsGroupBox;
      SetBounds(8,5,80,Height);
      Caption:=lisCodeToolsDefsInsertBehindDirectory;
      Visible:=true;
    end;
    
    DirectoryComboBox:=TComboBox.Create(Self);
    with DirectoryComboBox do begin
      Name:='DirectoryComboBox';
      Parent:=DirectoryOptionsGroupBox;
      Left:=DirectoryLabel.Left+DirectoryLabel.Width+5;
      Top:=DirectoryLabel.Top-2;
      Width:=Parent.ClientWidth-Left-8-25-5;
      Visible:=true;
    end;
    
    DirectoryBrowse:=TBitBtn.Create(Self);
    with DirectoryBrowse do begin
      Name:='DirectoryBrowse';
      Parent:=DirectoryOptionsGroupBox;
      SetBounds(DirectoryComboBox.Left+DirectoryComboBox.Width+5,
        DirectoryComboBox.Top,25,25);
      Caption:='...';
      Visible:=true;
    end;
    
    FileMaskLabel:=TLabel.Create(Self);
    with FileMaskLabel do begin
      Name:='FileMaskLabel';
      Parent:=DirectoryOptionsGroupBox;
      SetBounds(8,DirectoryComboBox.Top+DirectoryComboBox.Height+5,200,Height);
      Caption:=lisFindFileFileMaskBak;
      Visible:=true;
    end;
    
    FileMaskComboBox:=TComboBox.Create(Self);
    with FileMaskComboBox do begin
      Name:='FileMaskComboBox';
      Parent:=DirectoryOptionsGroupBox;
      SetBounds(FileMaskLabel.Left, FileMaskLabel.Top+FileMaskLabel.Height+3,
         Self.ClientWidth-20-5-25,Height);
      Visible:=true;
    end;
    
    IncludeSubDirsCheckBox:=TCheckBox.Create(Self);
    with IncludeSubDirsCheckBox do begin
      Name:='IncludeSubDirsCheckBox';
      Parent:=DirectoryOptionsGroupBox;
      SetBounds(8,FileMaskComboBox.Top+FileMaskComboBox.Height+10,
          150,Height);
      Caption:=lisFindFileIncludeSubDirectories;
      Visible:=true;
    end;
    
    OkButton:=TButton.Create(Self);
    with OkButton do begin
      Name:='OkButton';
      Parent:=Self;
      SetBounds(Self.ClientWidth-200,Self.ClientHeight-40,80,Height);
      Caption:=lisLazBuildOk;
      OnClick:=@OkButtonClick;
      Visible:=true;
    end;
    
    CancelButton:=TButton.Create(Self);
    with CancelButton do begin
      Name:='CancelButton';
      Parent:=Self;
      SetBounds(Self.ClientWidth-100,Self.ClientHeight-40,80,Height);
      Caption:=dlgCancel;
      OnClick:=@CancelButtonClick;
      Visible:=true;
    end;
  end;
  LazFindInFilesDialogResize(nil);
end;

procedure TLazFindInFilesDialog.LazFindInFilesDialogResize(Sender: TObject);
begin
  with TextToFindLabel do begin
    SetBounds(8,8,80,Height);
  end;

  with TextToFindEdit do begin
    SetBounds(TextToFindLabel.Left+TextToFindLabel.Width+5,
      TextToFindLabel.Top-2,
      Self.ClientWidth-TextToFindLabel.Left-TextToFindLabel.Width-13,
      Height);
  end;

  with OptionsGroupBox do begin
    SetBounds(8,TextToFindLabel.Top+TextToFindLabel.Height+10,
      Self.ClientWidth-20,95);
  end;

  with CaseSensitiveCheckBox do begin
    SetBounds(8,2,OptionsGroupBox.ClientWidth-20,20);
  end;

  with WholeWordsOnlyCheckBox do begin
    SetBounds(CaseSensitiveCheckBox.Left,
         CaseSensitiveCheckBox.Top+CaseSensitiveCheckBox.Height+5,
         CaseSensitiveCheckBox.Width,20);
  end;

  with RegularExpressionsCheckBox do begin
    SetBounds(CaseSensitiveCheckBox.Left,
         WholeWordsOnlyCheckBox.Top+WholeWordsOnlyCheckBox.Height+5,
         CaseSensitiveCheckBox.Width,20);
  end;

  with WhereRadioGroup do begin
    SetBounds(8,OptionsGroupBox.Top+OptionsGroupBox.Height+10,
      Self.ClientWidth-20,90);
  end;

  with DirectoryOptionsGroupBox do begin
    SetBounds(8,WhereRadioGroup.Top+WhereRadioGroup.Height+10,
      Self.ClientWidth-20,135);
  end;

  with DirectoryLabel do begin
    SetBounds(8,5,80,Height);
  end;

  with DirectoryComboBox do begin
    Left:=DirectoryLabel.Left+DirectoryLabel.Width+5;
    Top:=DirectoryLabel.Top-2;
    Width:=Parent.ClientWidth-Left-8-25-5;
  end;

  with DirectoryBrowse do begin
    SetBounds(DirectoryComboBox.Left+DirectoryComboBox.Width+5,
      DirectoryComboBox.Top,25,25);
  end;

  with FileMaskLabel do begin
    SetBounds(8,DirectoryComboBox.Top+DirectoryComboBox.Height+5,200,Height);
  end;

  with FileMaskComboBox do begin
    SetBounds(FileMaskLabel.Left, FileMaskLabel.Top+FileMaskLabel.Height+3,
       Self.ClientWidth-20-5-25,Height);
  end;

  with IncludeSubDirsCheckBox do begin
    SetBounds(8,FileMaskComboBox.Top+FileMaskComboBox.Height+10,
        150,Height);
  end;

  with OkButton do begin
    SetBounds(Self.ClientWidth-200,Self.ClientHeight-40,80,Height);
  end;

  with CancelButton do begin
    SetBounds(Self.ClientWidth-100,Self.ClientHeight-40,80,Height);
  end;
end;

procedure TLazFindInFilesDialog.OkButtonClick(Sender: TObject);
begin
  ModalResult:=mrOk;
end;

procedure TLazFindInFilesDialog.CancelButtonClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

end.

