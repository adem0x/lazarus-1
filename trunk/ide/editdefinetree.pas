{ /***************************************************************************
                     editdefinetree.pas  -  Lazarus IDE unit
                     ---------------------------------------

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

  Author: Mattias Gaertner
 
  Abstract:
    - procs to transfer the compiler options to the CodeTools
}
unit EditDefineTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IDEProcs, CodeToolManager, DefineTemplates,
  CompilerOptions, TransferMacros, LinkScanner, FileProcs;

procedure CreateProjectDefineTemplate(CompOpts: TCompilerOptions;
  const SrcPath: string);
procedure SetAdditionalGlobalSrcPathToCodeToolBoss(const SrcPath: string);
function FindCurrentProjectDirTemplate: TDefineTemplate;
function FindCurrentProjectDirSrcPathTemplate: TDefineTemplate;
function FindPackagesTemplate: TDefineTemplate;
function FindPackageTemplateWithID(const PkgID: string): TDefineTemplate;
function CreatePackagesTemplate: TDefineTemplate;
function CreatePackageTemplateWithID(const PkgID: string): TDefineTemplate;

const
  ProjectDirDefTemplName = 'Current Project Directory';
  ProjectDirSrcPathTemplName = 'SrcPathAddition';
  PackagesDefTemplName = 'Packages';
  PkgOutputDirDefTemplName = 'Output Directory';

implementation


function FindCurrentProjectDirTemplate: TDefineTemplate;
begin
  Result:=CodeToolBoss.DefineTree.FindDefineTemplateByName(
    ProjectDirDefTemplName,true);
end;

function FindCurrentProjectDirSrcPathTemplate: TDefineTemplate;
begin
  Result:=FindCurrentProjectDirTemplate;
  if Result<>nil then
    Result:=Result.FindChildByName(ProjectDirSrcPathTemplName);
end;

function FindPackagesTemplate: TDefineTemplate;
begin
  Result:=CodeToolBoss.DefineTree.FindDefineTemplateByName(
    PackagesDefTemplName,true);
end;

function FindPackageTemplateWithID(const PkgID: string): TDefineTemplate;
var
  PkgTempl: TDefineTemplate;
begin
  PkgTempl:=FindPackagesTemplate;
  if PkgTempl=nil then
    Result:=nil
  else
    Result:=PkgTempl.FindChildByName(PkgID);
end;

function CreatePackagesTemplate: TDefineTemplate;
begin
  Result:=FindPackagesTemplate;
  if Result<>nil then exit;
  Result:=TDefineTemplate.Create(PackagesDefTemplName,'All packages','','',
                                 da_Block);
  Result.Flags:=[dtfAutoGenerated];
  // insert behind all
  CodeToolBoss.DefineTree.ReplaceRootSameName(Result);
end;

function CreatePackageTemplateWithID(const PkgID: string): TDefineTemplate;
var
  PkgTempl: TDefineTemplate;
begin
  PkgTempl:=CreatePackagesTemplate;
  Result:=PkgTempl.FindChildByName(PkgID);
  if Result<>nil then exit;
  Result:=TDefineTemplate.Create(PkgID,PkgID,'','',da_Block);
  Result.Flags:=[dtfAutoGenerated];
  PkgTempl.AddChild(Result);
end;

function ConvertTransferMacrosToExternalMacros(const s: string): string;
var
  Count, i, j: integer;
begin
  Count:=0;
  for i:=1 to length(s)-1 do begin
    if ((i=1) or (s[i-1]<>SpecialChar))
    and (s[i]='$') and (s[i+1] in ['(','{']) then
      inc(Count);
  end;
  SetLength(Result,Length(s)+Count);
  i:=1;
  j:=1;
  while (i<=length(s)) do begin
    if (i<length(s))
    and ((s[i]='$') and (s[i+1] in ['(','{']))
    and ((i=1) or (s[i-1]<>SpecialChar))
    then begin
      Result[j]:=s[i];
      Result[j+1]:='(';
      inc(j,2);
      inc(i);
      Result[j]:=ExternalMacroStart;
    end else if (i>=2) and (s[i-1]<>SpecialChar) and (s[i]='}') then begin
      Result[j]:=')';
    end else begin
      Result[j]:=s[i];
    end;
    inc(j);
    inc(i);
  end;
end;

procedure CreateProjectDefineTemplate(CompOpts: TCompilerOptions;
  const SrcPath: string);
var ProjectDir, s: string;
  ProjTempl: TDefineTemplate;
begin
  { ToDo:
  
    StackChecks
    DontUseConfigFile
    AdditionalConfigFile
  }
  // define macros for project directory
  ProjectDir:='$('+ExternalMacroStart+'ProjectDir)';

  // create define node for current project directory -------------------------
  ProjTempl:=TDefineTemplate.Create(ProjectDirDefTemplName,
    'Current Project Directory','',ProjectDir,da_Directory);
  ProjTempl.Flags:=[dtfAutoGenerated,dtfProjectSpecific];

  // FPC modes ----------------------------------------------------------------
  if CompOpts.DelphiCompat then begin
    // set mode DELPHI
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to DELPHI',CompilerModeVars[cmDELPHI],'1',da_DefineRecurse));
  end else if CompOpts.TPCompatible then begin
    // set mode TP
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to TP',CompilerModeVars[cmTP],'1',da_DefineRecurse));
  end else if CompOpts.GPCCompat then begin
    // set mode GPC
    ProjTempl.AddChild(TDefineTemplate.Create('MODE',
    'set FPC mode to GPC',CompilerModeVars[cmGPC],'1',da_DefineRecurse));
  end;
  
  // Checks -------------------------------------------------------------------
  if CompOpts.IOChecks then begin
    // set IO checking on
    ProjTempl.AddChild(TDefineTemplate.Create('IOCHECKS on',
    'set IOCHECKS on','IOCHECKS','1',da_DefineRecurse));
  end;
  if CompOpts.RangeChecks then begin
    // set Range checking on
    ProjTempl.AddChild(TDefineTemplate.Create('RANGECHECKS on',
    'set RANGECHECKS on','RANGECHECKS','1',da_DefineRecurse));
  end;
  if CompOpts.OverflowChecks then begin
    // set Overflow checking on
    ProjTempl.AddChild(TDefineTemplate.Create('OVERFLOWCHECKS on',
    'set OVERFLOWCHECKS on','OVERFLOWCHECKS','1',da_DefineRecurse));
  end;

  // Hidden used units --------------------------------------------------------
  if CompOpts.UseLineInfoUnit then begin
    // use lineinfo unit
    ProjTempl.AddChild(TDefineTemplate.Create('Use LINEINFO unit',
    'use LineInfo unit',ExternalMacroStart+'UseLineInfo','1',da_DefineRecurse));
  end;
  if CompOpts.UseHeaptrc then begin
    // use heaptrc unit
    ProjTempl.AddChild(TDefineTemplate.Create('Use HEAPTRC unit',
    'use HeapTrc unit',ExternalMacroStart+'UseHeapTrcUnit','1',da_DefineRecurse));
  end;
  
  // Paths --------------------------------------------------------------------
  
  // Include Path
  if CompOpts.IncludeFiles<>'' then begin
    // add include paths
    ProjTempl.AddChild(TDefineTemplate.Create('IncludePath',
      'include path addition',ExternalMacroStart+'INCPATH',
      ConvertTransferMacrosToExternalMacros(CompOpts.IncludeFiles)+';'
      +'$('+ExternalMacroStart+'INCPATH)',
      da_DefineRecurse));
  end;
  // compiled unit path (ppu/ppw/dcu files)
  s:=CompOpts.OtherUnitFiles;
  if (CompOpts.UnitOutputDirectory<>'') then begin
    if s<>'' then
      s:=s+';'+CompOpts.UnitOutputDirectory
    else
      s:=CompOpts.UnitOutputDirectory;
  end;
  if s<>'' then begin
    // add compiled unit path
    ProjTempl.AddChild(TDefineTemplate.Create('UnitPath',
      'unit path addition',ExternalMacroStart+'UnitPath',
      ConvertTransferMacrosToExternalMacros(s)+';'
      +'$('+ExternalMacroStart+'UnitPath)',
      da_DefineRecurse));
  end;
  // source path (unitpath + sources for the CodeTools, hidden to the compiler)
  if (SrcPath<>'') or (s<>'') then begin
    // add compiled unit path
    ProjTempl.AddChild(TDefineTemplate.Create('SrcPath',
      'source path addition',ExternalMacroStart+'SrcPath',
      ConvertTransferMacrosToExternalMacros(s+';'+SrcPath)+';'
      +'$('+ExternalMacroStart+'SrcPath)',
      da_DefineRecurse));
  end;

  // LCL Widget Type ----------------------------------------------------------
  if CodeToolBoss.GlobalValues[ExternalMacroStart+'LCLWidgetType']<>
    CompOpts.LCLWidgetType then
  begin
    CodeToolBoss.GlobalValues[ExternalMacroStart+'LCLWidgetType']:=
      CompOpts.LCLWidgetType;
    CodeToolBoss.DefineTree.ClearCache;
  end;
  

  // --------------------------------------------------------------------------
  // replace project defines in DefineTree
  CodeToolBoss.DefineTree.ReplaceRootSameName(ProjTempl);
end;

procedure SetAdditionalGlobalSrcPathToCodeToolBoss(const SrcPath: string);
var DefTempl: TDefineTemplate;
begin
  if SrcPath<>'' then begin
    DefTempl:=TDefineTemplate.Create('GlobalSrcPathAdd',
      'Global Source Path addition',ExternalMacroStart+'SRCPATH',
      ConvertTransferMacrosToExternalMacros(SrcPath)+';'
        +'$('+ExternalMacroStart+'SRCPATH)',
        da_DefineRecurse);
    DefTempl.Flags:=[dtfAutoGenerated];
    CodeToolBoss.DefineTree.ReplaceRootSameName(DefTempl);
  end else begin
    CodeToolBoss.DefineTree.RemoveRootDefineTemplateByName('GlobalSrcPathAdd');
  end;
end;


end.

