{
 /***************************************************************************
                        projecticon.pas  -  Lazarus IDE unit
                        ---------------------------------------
               TProjectIcon is responsible for the inclusion of the 
             icon in windows executables as rc file and others as .lrs.


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
unit ProjectIcon;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Process, LCLProc, Controls, Forms,
  CodeToolManager, LazConf, LResources, resource, groupiconresource,
  ProjectIntf, ProjectResourcesIntf;
   
type
  TIconData = array of byte;

  { TProjectIcon }

  TProjectIcon = class(TAbstractProjectResource)
  private
    FData: TIconData;
    FIcoFileName: string;
    function GetIsEmpry: Boolean;
    procedure SetIconData(const AValue: TIconData);
    procedure SetFileNames(const MainFilename: string);
    procedure SetIsEmpty(const AValue: Boolean);
  public
    constructor Create; override;

    function GetStream: TStream;
    procedure SetStream(AStream: TStream);

    function UpdateResources(AResources: TAbstractProjectResources;
                             const MainFilename: string): Boolean; override;
    function CreateIconFile: Boolean;

    property IconData: TIconData read FData write SetIconData;
    property IsEmpty: Boolean read GetIsEmpry write SetIsEmpty;
    property IcoFileName: String read FIcoFileName write FIcoFileName;
  end;

implementation

function TProjectIcon.GetStream: TStream;
begin
  if length(FData)>0 then
  begin
    Result := TMemoryStream.Create;
    Result.WriteBuffer(FData[0], Length(FData));
    Result.Position := 0;
  end
  else
    Result := nil;
end;

procedure TProjectIcon.SetStream(AStream: TStream);
var
  NewIconData: TIconData;
begin
  NewIconData := nil;
  if (AStream <> nil) then
  begin
    SetLength(NewIconData, AStream.Size);
    AStream.ReadBuffer(NewIconData[0], AStream.Size);
  end;
  IconData := NewIconData;
end;

function TProjectIcon.UpdateResources(AResources: TAbstractProjectResources;
  const MainFilename: string): Boolean;
var
  AResource: TStream;
  AName: TResourceDesc;
  ARes: TGroupIconResource;
begin
  Result := True;

  if FData = nil then
    Exit;

  SetFileNames(MainFilename);
  if FilenameIsAbsolute(FIcoFileName) then
    CreateIconFile;

{ to create an lrs with icon we can use this but there is no reason anymore
  if AResources.ResourceType <> rtRes then
  begin
    AResource := GetStream;
    try
      AResources.AddLazarusResource(AResource, 'MAINICON', 'ICO');
    finally
      AResource.Free;
    end;
  end;
}

  AName := TResourceDesc.Create('MAINICON');
  ARes := TGroupIconResource.Create(nil, AName); //type is always RT_GROUP_ICON
  aName.Free; //not needed anymore
  AResource := GetStream;
  try
    ARes.ItemData.CopyFrom(AResource, AResource.Size);
  finally
    AResource.Free;
  end;

  AResources.AddSystemResource(ARes);
end;

function TProjectIcon.CreateIconFile: Boolean;
var
  FileStream, AStream: TStream;
begin
  Result := False;
  AStream := GetStream;
  FileStream := nil;
  try
    FileStream := TFileStream.Create(UTF8ToSys(FicoFileName), fmCreate);
    FileStream.CopyFrom(AStream, AStream.Size);
    Result := True;
  finally
    FileStream.Free;
  end;
  AStream.Free;
end;

{-----------------------------------------------------------------------------
 TProjectIcon SetFileNames
-----------------------------------------------------------------------------}
procedure TProjectIcon.SetFileNames(const MainFilename: string);
begin
  FIcoFileName := ExtractFilePath(MainFilename) +
    ExtractFileNameWithoutExt(ExtractFileName(MainFileName)) + '.ico';
end;

procedure TProjectIcon.SetIsEmpty(const AValue: Boolean);
var
  AStream: TStream;
  NewData: TIconData;
begin
  if AValue then
    IconData := nil
  else
  begin
    // We need to restore data from the .ico file
    if FileExistsUTF8(FicoFileName) then
    begin
      AStream := TFileStream.Create(UTF8ToSys(FicoFileName), fmOpenRead);
      try
        SetLength(NewData, AStream.Size);
        AStream.ReadBuffer(NewData[0], AStream.Size);
        IconData := NewData;
      finally
        AStream.Free;
      end;
    end
    else
      IconData := nil;
  end;
end;

constructor TProjectIcon.Create;
var
  DefaultRes: TLResource;
  ResStream: TLazarusResourceStream;
begin
  inherited Create;

  FData := nil;

  // Load default icon
  DefaultRes := LazarusResources.Find('LazarusProject', 'ICO');
  if DefaultRes <> nil then
  begin
    ResStream := TLazarusResourceStream.CreateFromHandle(DefaultRes);
    SetStream(ResStream);
    ResStream.Free;
  end;
end;

procedure TProjectIcon.SetIconData(const AValue: TIconData);
begin
  if (Length(AValue) = Length(FData)) and
     (FData <> nil) and
     (CompareByte(AValue[0], FData[0], Length(FData)) = 0)
  then
    Exit;
  FData := AValue;
  Modified := True;
end;

function TProjectIcon.GetIsEmpry: Boolean;
begin
  Result := FData = nil;
end;

end.

