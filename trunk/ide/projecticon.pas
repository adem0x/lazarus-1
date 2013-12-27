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
  Classes, SysUtils, FileUtil, Laz2_XMLCfg, lazutf8classes, Process, LCLProc,
  Controls, Graphics, Forms, CodeToolManager, FileProcs, LazConf, LResources,
  resource, groupiconresource, ProjectIntf, ProjectResourcesIntf;
   
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
    procedure LoadDefaultIcon;

    function UpdateResources(AResources: TAbstractProjectResources;
                             const MainFilename: string): Boolean; override;
    procedure WriteToProjectFile(AConfig: {TXMLConfig}TObject; Path: String); override;
    procedure ReadFromProjectFile(AConfig: {TXMLConfig}TObject; Path: String); override;

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

procedure TProjectIcon.LoadDefaultIcon;
var
  ResStream: TMemoryStream;
  Icon: TIcon;
begin
  // Load default icon
  Icon := TIcon.Create;
  ResStream := TMemoryStream.Create;
  try
    Icon.LoadFromResourceName(HInstance, 'MAINICONPROJECT');
    Icon.SaveToStream(ResStream);
    ResStream.Position := 0;
    SetStream(ResStream);
  finally
    ResStream.Free;
    Icon.Free;
  end;
end;

function TProjectIcon.UpdateResources(AResources: TAbstractProjectResources;
  const MainFilename: string): Boolean;
var
  AResource: TStream;
  AName: TResourceDesc;
  ARes: TGroupIconResource;
  ItemStream: TStream;
begin
  Result := True;

  if FData = nil then
    Exit;

  SetFileNames(MainFilename);
  if FilenameIsAbsolute(FIcoFileName) then
    if not CreateIconFile then begin
      debugln(['TProjectIcon.UpdateResources CreateIconFile "'+FIcoFileName+'" failed']);
      exit(false);
    end;

  AName := TResourceDesc.Create('MAINICON');
  ARes := TGroupIconResource.Create(nil, AName); //type is always RT_GROUP_ICON
  aName.Free; //not needed anymore
  AResource := GetStream;
  if AResource<>nil then
    try
      ItemStream:=nil;
      try
        ItemStream:=ARes.ItemData;
      except
        on E: Exception do begin
          DebugLn(['TProjectIcon.UpdateResources ignoring bug in fcl: ',E.Message]);
        end;
      end;
      if ItemStream<>nil then
        ItemStream.CopyFrom(AResource, AResource.Size);
    finally
      AResource.Free;
    end
  else
    ARes.ItemData.Size:=0;

  AResources.AddSystemResource(ARes);
end;

procedure TProjectIcon.WriteToProjectFile(AConfig: TObject; Path: String);
begin
  TXMLConfig(AConfig).SetDeleteValue(Path+'General/Icon/Value', BoolToStr(IsEmpty), BoolToStr(true));
end;

procedure TProjectIcon.ReadFromProjectFile(AConfig: TObject; Path: String);
begin
  with TXMLConfig(AConfig) do
  begin
    IcoFileName := ChangeFileExt(FileName, '.ico');
    IsEmpty := StrToBoolDef(GetValue(Path+'General/Icon/Value', BoolToStr(true)), False);
  end;
end;

function TProjectIcon.CreateIconFile: Boolean;
var
  fs: TFileStreamUTF8;
begin
  Result := False;
  if IsEmpty then exit;
  try
    if FileExistsUTF8(FIcoFileName) then
      fs:=TFileStreamUTF8.Create(FIcoFileName,fmOpenWrite)
    else
      fs:=TFileStreamUTF8.Create(FIcoFileName,fmCreate);
    try
      fs.Write(FData[0],length(FData));
      Result:=true;
    finally
      fs.Free;
    end;
  except
    on E: Exception do
      debugln(['TProjectIcon.CreateIconFile "'+FIcoFileName+'": '+E.Message]);
  end;
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
  NewData: TIconData;
  fs: TFileStreamUTF8;
begin
  if IsEmpty=AValue then exit;
  if AValue then
    IconData := nil
  else
  begin
    // We need to restore data from the .ico file
    IconData := nil;
    try
      fs:=TFileStreamUTF8.Create(FIcoFileName,fmOpenRead);
      try
        SetLength(NewData, fs.Size);
        if length(NewData)>0 then
          fs.Read(NewData[0],length(NewData));
        IconData := NewData;
      finally
        fs.Free
      end;
    except
    end;
  end;
  Modified := True;
end;

constructor TProjectIcon.Create;
begin
  inherited Create;
  FData := nil;
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

initialization
  RegisterProjectResource(TProjectIcon);

end.
