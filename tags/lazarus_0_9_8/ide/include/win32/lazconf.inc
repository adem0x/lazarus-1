{***************************************************************************
                               lazconf.inc
 ***************************************************************************

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
uses
  windows;

const
  DefaultFPCSrcDirs: array[1..2] of string = (
    '$(LazarusDir)\fpcsrc',  // this value is set in internalinit
    'c:\pp\source'
    );

var
  PrimaryConfigPath,
  SecondaryConfigPath: string;

function GetDefaultTargetOS: string;
begin
  Result:='win32';
end;

procedure GetDefaultLCLLibPaths(List: TStrings);
begin
end;

{---------------------------------------------------------------------------
  getPrimaryConfigPath function
 ---------------------------------------------------------------------------}
function GetPrimaryConfigPath: String;
begin
  Result := PrimaryConfigPath;
end;

{---------------------------------------------------------------------------
  getSecondaryConfigPath function
 ---------------------------------------------------------------------------}
function GetSecondaryConfigPath: String;
begin
  Result := SecondaryConfigPath;
end;

{---------------------------------------------------------------------------
  createPrimaryConfigPath procedure
 ---------------------------------------------------------------------------}
procedure createPrimaryConfigPath;
begin
  CreateDir(GetPrimaryConfigPath);
end;

{---------------------------------------------------------------------------
  SetPrimaryConfigPath procedure
 ---------------------------------------------------------------------------}
procedure SetPrimaryConfigPath(const NewValue: String);
begin
  PrimaryConfigPath:=NewValue;
end;

{---------------------------------------------------------------------------
  SetSecondaryConfigPath procedure
 ---------------------------------------------------------------------------}
procedure SetSecondaryConfigPath(const NewValue: String);
begin
  SecondaryConfigPath:=NewValue;
end;

{---------------------------------------------------------------------------
  CopySecondaryConfigFile procedure
 ---------------------------------------------------------------------------}
procedure CopySecondaryConfigFile(const AFilename: String);
var
  PrimaryFilename, SecondaryFilename: string;
  SrcFS, DestFS: TFileStream;
begin
  PrimaryFilename:=GetPrimaryConfigPath+PathDelim+AFilename;
  SecondaryFilename:=GetSecondaryConfigPath+PathDelim+AFilename;
  if (not FileExists(PrimaryFilename))
  and (FileExists(SecondaryFilename)) then begin
    try
      SrcFS:=TFileStream.Create(SecondaryFilename,fmOpenRead);
      try
        DestFS:=TFileStream.Create(PrimaryFilename,fmCreate);
        try
          DestFS.CopyFrom(SrcFS,SrcFS.Size);
        finally
          DestFS.Free;
        end;
      finally
        SrcFS.Free;
      end;
    except
    end;
  end;
end;

function FindDefaultCompilerPath: string;
begin
  Result:=SearchFileInPath(GetDefaultCompilerFilename,
                           AppendPathDelim(ProgramDirectory)+'pp\bin\i386-win32',
                           SysUtils.GetEnvironmentVariable('PATH'),';',
                           []);
  if Result<>'' then exit;
  Result:='c:\pp\bin\i386-win32\ppc386.exe';
  if not FileExists(Result) then Result:='';
end;

function FindDefaultMakePath: string;
begin
  Result:=SearchFileInPath('make.exe',
                           AppendPathDelim(ProgramDirectory)+'pp\bin\i386-win32',
                           SysUtils.GetEnvironmentVariable('PATH'),';',
                           []);
end;

function CreateCompilerTestPascalFilename: string;
var
  fs: TFileStream;
begin
  Result:=AppendPathDelim(GetPrimaryConfigPath)+'compilertest.pas';
  if not FileExists(Result) then begin
    fs:=TFileStream.Create(Result,fmCreate);
    fs.Free;
  end;
end;

{---------------------------------------------------------------------------
  function GetDefaultExecutableExt: string;
 ---------------------------------------------------------------------------}
function GetDefaultExecutableExt: string;
begin
  Result:='.exe';
end;

function GetDefaultCompiledUnitExt(FPCVersion, FPCRelease: integer): string;
begin
  if (FPCVersion=1) and (FPCRelease=0) then
    Result:='.ppw'
  else
    Result:='.ppu';
end;

function OSLocksExecutables: boolean;
begin
  Result:=true;
end;

function GetDefaultTestBuildDirectory: string;
begin
  Result:=SysUtils.GetEnvironmentVariable('TEMP');
  if Result<>'' then exit;
  Result:='c:\temp\';
  if DirPathExists(Result) then exit;
  Result:='c:\windows\temp\';
end;

procedure GetDefaultCompilerFilenames(List: TStrings);
begin
  List.Add(AppendPathDelim(ProgramDirectory)+'pp\bin\i386-win32\ppc386.exe');
  List.Add('c:\pp\bin\i386-win32\ppc386.exe');
end;

procedure GetDefaultMakeFilenames(List: TStrings);
begin
  List.Add(AppendPathDelim(ProgramDirectory)+'pp\bin\i386-win32\make.exe');
  List.Add('c:\pp\bin\i386-win32\make.exe');
end;

procedure GetDefaultTestBuildDirs(List: TStrings);
begin
  List.Add('c:\tmp\');
  List.Add('c:\windows\temp\');
end;

function GetDefaultLCLWidgetType: string;
begin
  Result:='win32';
end;

procedure GetLanguageIDs(var Lang, FallbackLang: string);
var
  Buffer: array[1..4] of char;
  Country: string;
  UserLCID: LCID;
begin
  //defaults
  Lang := '';
  FallbackLang:='';
  UserLCID := GetUserDefaultLCID;
  if GetLocaleInfo(UserLCID, LOCALE_SABBREVLANGNAME, @Buffer, 4)<>0 then
    FallbackLang := lowercase(copy(Buffer,1,2));
  if GetLocaleInfo(UserLCID, LOCALE_SABBREVCTRYNAME, @Buffer, 4)<>0 then begin
    Country := copy(Buffer,1,2);

    // some 2 letter codes are not the first two letters of the 3 letter code
    // there are probably more, but first let us see if there are translations
    if (Buffer='PRT') then Country:='PT';

    Lang := FallbackLang+'_'+Country;
  end;
end;

procedure GetDefaultBrowser(var Browser, Params: string);
begin
  Browser:= SearchFileInPath('rundll32.exe','',
                           SysUtils.GetEnvironmentVariable('PATH'),';',
                           [sffDontSearchInBasePath]);
  Params:='url.dll,FileProtocolHandler %s';
end;

{---------------------------------------------------------------------------
  procedure InternalInit;
 ---------------------------------------------------------------------------}
procedure InternalInit;
begin
  PrimaryConfigPath:=ChompPathDelim(ExtractFilePath(Paramstr(0)));
  SecondaryConfigPath:=SysUtils.GetEnvironmentVariable('WINDIR');
  If SecondaryConfigPath = '' Then
    SecondaryConfigPath:='c:\windows';
  DefaultFPCSrcDirs[1]:=AppendPathDelim(ProgramDirectory)+'fpcsrc';
end;

{
  $Log$
  Revision 1.29  2005/04/17 20:23:23  vincents
  implemented finding ppc386.exe and fpc source installed by win32 installer (bug 699)

  Revision 1.28  2005/04/17 11:15:41  vincents
  implemented using default browser on windows

  Revision 1.27  2005/03/23 10:45:05  mattias
  fixed ambigious with ambiguous

  Revision 1.26  2004/12/09 14:30:12  vincents
  moved GetLanguageIDs from Translations to LazConf

  Revision 1.25  2004/12/04 01:17:41  mattias
  implemented Target Directory for IDE

  Revision 1.24  2004/08/20 09:47:36  mattias
  added darwin libpaths to Makefile and LCL Usage lib paths

  Revision 1.23  2004/08/16 18:05:29  vincents
  replaced GetEnv from dos unit by GetEnvironmentVariable from SysUtils unit

  Revision 1.22  2004/08/13 12:28:01  mattias
  replaced ppc386 with platform independent name

  Revision 1.21  2004/07/30 15:34:09  vincents
  make executable location is a environment option now.

  Revision 1.20  2003/12/21 13:58:06  mattias
  renamed DirectoryExists to DirPathExists to reduce ambiguousity

  Revision 1.19  2003/12/20 01:20:52  mattias
  splitted output directories for cross compilation

  Revision 1.18  2003/11/16 19:28:33  mattias
  build lazarus now uses custom compiler path

  Revision 1.17  2003/11/15 13:07:09  mattias
  added ambiguous unit check for IDE

  Revision 1.16  2003/09/17 22:06:56  mattias
  implemented default lcl widget type

  Revision 1.15  2003/09/09 11:22:17  mattias
  added fileexists for secondary config files

  Revision 1.14  2003/09/09 11:11:02  mattias
  fixed win32 intf showmoadl and lazconf

  Revision 1.13  2003/08/25 12:16:14  marco
   * reverted last patch. CVS dirty.

  Revision 1.12  2003/08/25 11:58:59  marco
   * fixed duplicate dos reference

  Revision 1.11  2003/08/18 10:02:37  mattias
  fixed win32 lazconf and improved enclose selection

  Revision 1.10  2003/08/15 14:28:48  mattias
  clean up win32 ifdefs

  Revision 1.9  2003/08/15 14:01:20  mattias
  combined lazconf things for unix

  Revision 1.8  2003/02/06 20:46:51  mattias
  default fpc src dirs and clean ups

  Revision 1.7  2002/12/20 11:08:47  mattias
  method resolution clause, class ancestor find declaration, 1.1. makros

  Revision 1.6  2002/07/01 05:53:31  lazarus
  MG: improved default make path for build lazarus

  Revision 1.5  2002/05/10 06:57:51  lazarus
  MG: updated licenses

  Revision 1.4  2001/12/16 22:24:55  lazarus
  MG: changes for new compiler 20011216

  Revision 1.3  2001/12/10 08:44:23  lazarus
  MG: added search for compiler, if not set

  Revision 1.2  2001/05/27 11:52:01  lazarus
  MG: added --primary-config-path=<filename> cmd line option

  Revision 1.1  2000/07/13 10:28:22  michael
  + Initial import

  Revision 1.1  2000/04/21 05:12:42  lazarus
  Added lazconf.pp file.
  Added include/linux and include/win32 directories.
  Added lazconf.inc files for both linux and win32.


}
