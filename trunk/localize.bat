@echo off
REM
REM Make sure you have your setings correctly
REM
REM Usage: localize
REM
REM This script should be executed after adding new resource strings and after
REM udating the translated .po files.
REM
REM This script
REM - converts all compiled .rst files to .po files,
REM - updates all translated xx.po files
REM

REM set LazInstall=C:\lazarus\
set ArchOS=i386-win32

echo.

REM Compile tools if updatepofiles is missing

if exist tools\updatepofiles.exe goto SkipTools
echo The updatepofiles tool was not found, compiling tools ...
echo.
cd tools
make updatepofiles.exe
cd..
if not exist tools\updatepofiles.exe goto Exit_Error

:SkipTools

echo Updating language files ...

echo on

@REM IDE
@set IDE_RST=units\%ArchOS%\LazarusIDEStrConsts.rst
rstconv -c UTF-8 -i %IDE_RST% -o languages\lazaruside.po
tools\updatepofiles languages\lazaruside.po

@REM IDEIntf
@set ObjInsp_RST=ideintf\units\%ArchOS%\ObjInspStrConsts.rst
rstconv -c UTF-8 -i %ObjInsp_RST% -o ideintf\languages\objinspstrconsts.po
tools\updatepofiles ideintf\languages\objinspstrconsts.po

@REM INSTALLER
@set Installer_RST=tools\install\win\installerstrconsts.rst
if not exist %Installer_RST% goto SkipInstaller
rstconv -c UTF-8 -i %Installer_RST% -o languages\installerstrconsts.po
tools\updatepofiles languages\installerstrconsts.po
:SkipInstaller

@REM CodeTools
@set CodeTools_RST=components\codetools\units\%ArchOS%\CodeToolsStrConsts.rst
rstconv -c UTF-8 -i %CodeTools_RST% -o components\codetools\languages\codetoolsstrconsts.po
tools\updatepofiles components\codetools\languages\codetoolsstrconsts.po

@REM SynEdit
@set SynEdit_RST=components\synedit\units\%ArchOS%\SynEditStrConst.rst
rstconv -c UTF-8 -i %SynEdit_RST% -o components\synedit\languages\synedit.po
tools\updatepofiles components\synedit\languages\synedit.po

@REM SynMacroRecorder
@set SynMacroRec_RST=components\synedit\units\%ArchOS%\synmacrorecorder.rst
rstconv -c UTF-8 -i %SynMacroRec_RST% -o components\synedit\languages\synmacrorecorder.po
tools\updatepofiles components\synedit\languages\synmacrorecorder.po

@REM SynUniHighLighterShellScript
@set SynUniHighLighterShellScript_RST=components\synedit\units\%ArchOS%\synhighlighterunixshellscript.rst
rstconv -c UTF-8 -i %SynUniHighLighterShellScript_RST% -o components\synedit\languages\synhighlighterunixshellscript.po
tools\updatepofiles components\synedit\languages\synhighlighterunixshellscript.po

@REM LCL
@set LCL_RST=lcl\units\%ArchOS%\lclstrconsts.rst
rstconv -c UTF-8 -i %LCL_RST% -o lcl\languages\lclstrconsts.po
tools\updatepofiles lcl\languages\lclstrconsts.po

@REM CGI
@set CGI_RST=components\cgi\lib\%ArchOS%\cgimodules.rst
rstconv -c UTF-8 -i %CGI_RST% -o components\cgi\languages\cgimodules.po
tools\updatepofiles components\cgi\languages\cgimodules.po

@REM LazReport
@set LazReport_RST=components\lazreport\source\lib\%ArchOS%\lr_const.rst
rstconv -c UTF-8 -i %LazReport_RST% -o components\lazreport\source\languages\lr_const.po
tools\updatepofiles components\lazreport\source\languages\lr_const.po

@REM MemDS
@set MemDS_RST=components\memds\lib\%ArchOS%\frmselectdataset.rst
rstconv -c UTF-8 -i %MemDS_RST% -o components\memds\languages\frmselectdataset.po
tools\updatepofiles components\memds\languages\frmselectdataset.po

@REM Printers
@set Printers_RST=components\printers\design\lib\%ArchOS%\ideprinting.rst
rstconv -c UTF-8 -i %Printers_RST% -o components\printers\design\languages\ideprinting.po
tools\updatepofiles components\printers\design\languages\ideprinting.po

@REM ProjectTemplates
@set ProjectTemplates_RST=components\projecttemplates\lib\%ArchOS%\frmtemplatevariables.rst
rstconv -c UTF-8 -i %ProjectTemplates_RST% -o components\projecttemplates\languages\frmtemplatevariables.po
tools\updatepofiles components\projecttemplates\languages\frmtemplatevariables.po

@set ProjectTemplates_RST=components\projecttemplates\lib\%ArchOS%\idetemplateproject.rst
rstconv -c UTF-8 -i %ProjectTemplates_RST% -o components\projecttemplates\languages\idetemplateproject.po
tools\updatepofiles components\projecttemplates\languages\idetemplateproject.po

@set ProjectTemplates_RST=components\projecttemplates\lib\%ArchOS%\projecttemplates.rst
rstconv -c UTF-8 -i %ProjectTemplates_RST% -o components\projecttemplates\languages\projecttemplates.po
tools\updatepofiles components\projecttemplates\languages\projecttemplates.po

@REM TDBF
@set TDBF_RST=components\tdbf\lib\%ArchOS%\registerdbf.rst
rstconv -c UTF-8 -i %TDBF_RST% -o components\tdbf\languages\registerdbf.po
tools\updatepofiles components\tdbf\languages\registerdbf.po

@REM TP_IPro
@set TP_IPro_RST=components\turbopower_ipro\units\%ArchOS%\ipconst.rst
rstconv -c UTF-8 -i %TP_IPro_RST% -o components\turbopower_ipro\languages\ipconst.po
tools\updatepofiles components\turbopower_ipro\languages\ipconst.po

@set TP_IPro_RST=components\turbopower_ipro\units\%ArchOS%\iputils.rst
rstconv -c UTF-8 -i %TP_IPro_RST% -o components\turbopower_ipro\languages\iputils.po
tools\updatepofiles components\turbopower_ipro\languages\iputils.po

@REM MessageComposer
@set MessageComposer_RST=components\messagecomposer\lib\%ArchOS%\messagecomposer.rst
rstconv -c UTF-8 -i %MessageComposer_RST% -o components\messagecomposer\languages\messagecomposer.po
tools\updatepofiles components\messagecomposer\languages\messagecomposer.po

@REM LazReport editor sample
@set LREditor_RST=components\lazreport\samples\editor\maincalleditor.rst
if not exist %LREditor_RST% goto SkipLREditor
rstconv -c UTF-8 -i %LREditor_RST% -o components\lazreport\samples\editor\languages\calleditorwithpkg.po
tools\updatepofiles components\lazreport\samples\editor\languages\calleditorwithpkg.po
:SkipLREditor

@goto Exit

:Exit_Error
echo Unable to compile updatepofiles tool

:Exit

