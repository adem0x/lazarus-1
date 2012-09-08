{
   File generated automatically by Lazarus Package Manager

   fpmake.pp for SynEdit 1.0

   This file was generated on 09/07/12
}

{$ifndef ALLPACKAGES} 
{$mode objfpc}{$H+}
program fpmake;

uses fpmkunit;
{$endif ALLPACKAGES}

procedure add_SynEdit;

var
  P : TPackage;
  T : TTarget;

begin
  with Installer do
    begin
    P:=AddPAckage('synedit');
    P.Version:='1.0';

{$ifdef ALLPACKAGES}
    // when this is part of a meta package, set here the sub directory
    P.Directory:='components/synedit';
{$endif ALLPACKAGES}

    P.Dependencies.Add('lcl');
    P.Dependencies.Add('lazutils');
    p.Dependencies.Add('fcl-registry');
    P.Options.Add('-MObjFPC');
    P.Options.Add('-Scghi');
    P.Options.Add('-CR');
    P.Options.Add('-O1');
    P.Options.Add('-g');
    P.Options.Add('-gl');
    P.Options.Add('-vewnh');
    P.Options.Add('-l');
    P.Options.Add('-vm4055,5024');
    P.Options.Add('-dLCL');
    P.Options.Add('-dLCL$(LCL_PLATFORM)');
    P.Options.Add('-CR');
    P.Options.Add('-dgc');
    P.Options.Add('-Fu../../lcl/units/$(CPU_TARGET)-$(OS_TARGET)/$(LCL_PLATFORM)');
    P.Options.Add('-Fu../../lcl/units/$(CPU_TARGET)-$(OS_TARGET)');
    P.Options.Add('-Fu../lazutils/lib/$(CPU_TARGET)-$(OS_TARGET)');
    P.Options.Add('-Fu../../packager/units/$(CPU_TARGET)-$(OS_TARGET)');
    P.Options.Add('-Fu.');
    T:=P.Targets.AddUnit('allsynedit.pas');
    t.Dependencies.AddUnit('synbeautifier');
    t.Dependencies.AddUnit('syncompletion');
    t.Dependencies.AddUnit('synedit');
    t.Dependencies.AddUnit('syneditautocomplete');
    t.Dependencies.AddUnit('syneditexport');
    t.Dependencies.AddUnit('syneditfoldedview');
    t.Dependencies.AddUnit('synedithighlighter');
    t.Dependencies.AddUnit('synedithighlighterfoldbase');
    t.Dependencies.AddUnit('synedithighlighterxmlbase');
    t.Dependencies.AddUnit('syneditkeycmds');
    t.Dependencies.AddUnit('lazsyneditmousecmdstypes');
    t.Dependencies.AddUnit('synhighlighterpo');
    t.Dependencies.AddUnit('syneditlines');
    t.Dependencies.AddUnit('syneditmarks');
    t.Dependencies.AddUnit('syneditmarkup');
    t.Dependencies.AddUnit('syneditmarkupbracket');
    t.Dependencies.AddUnit('syneditmarkupctrlmouselink');
    t.Dependencies.AddUnit('syneditmarkuphighall');
    t.Dependencies.AddUnit('syneditmarkupselection');
    t.Dependencies.AddUnit('syneditmarkupspecialline');
    t.Dependencies.AddUnit('syneditmarkupwordgroup');
    t.Dependencies.AddUnit('syneditmiscclasses');
    t.Dependencies.AddUnit('syneditmiscprocs');
    t.Dependencies.AddUnit('syneditmousecmds');
    t.Dependencies.AddUnit('syneditplugins');
    t.Dependencies.AddUnit('syneditpointclasses');
    t.Dependencies.AddUnit('syneditregexsearch');
    t.Dependencies.AddUnit('syneditsearch');
    t.Dependencies.AddUnit('syneditstrconst');
    t.Dependencies.AddUnit('synedittextbase');
    t.Dependencies.AddUnit('synedittextbuffer');
    t.Dependencies.AddUnit('synedittextdoublewidthchars');
    t.Dependencies.AddUnit('synedittexttabexpander');
    t.Dependencies.AddUnit('synedittexttrimmer');
    t.Dependencies.AddUnit('synedittypes');
    t.Dependencies.AddUnit('synexporthtml');
    t.Dependencies.AddUnit('syngutter');
    t.Dependencies.AddUnit('syngutterbase');
    t.Dependencies.AddUnit('syngutterchanges');
    t.Dependencies.AddUnit('synguttercodefolding');
    t.Dependencies.AddUnit('syngutterlinenumber');
    t.Dependencies.AddUnit('syngutterlineoverview');
    t.Dependencies.AddUnit('synguttermarks');
    t.Dependencies.AddUnit('synhighlighterany');
    t.Dependencies.AddUnit('synhighlightercpp');
    t.Dependencies.AddUnit('synhighlightercss');
    t.Dependencies.AddUnit('synhighlighterdiff');
    t.Dependencies.AddUnit('synhighlighterhashentries');
    t.Dependencies.AddUnit('synhighlighterhtml');
    t.Dependencies.AddUnit('synhighlighterjava');
    t.Dependencies.AddUnit('synhighlighterjscript');
    t.Dependencies.AddUnit('synhighlighterlfm');
    t.Dependencies.AddUnit('synhighlightermulti');
    t.Dependencies.AddUnit('synhighlighterpas');
    t.Dependencies.AddUnit('synhighlighterperl');
    t.Dependencies.AddUnit('synhighlighterphp');
    t.Dependencies.AddUnit('synhighlighterposition');
    t.Dependencies.AddUnit('synhighlighterpython');
    t.Dependencies.AddUnit('synhighlightersql');
    t.Dependencies.AddUnit('synhighlightertex');
    t.Dependencies.AddUnit('synhighlighterunixshellscript');
    t.Dependencies.AddUnit('synhighlightervb');
    t.Dependencies.AddUnit('synhighlighterxml');
    t.Dependencies.AddUnit('synmacrorecorder');
    t.Dependencies.AddUnit('synmemo');
    t.Dependencies.AddUnit('synpluginsyncroedit');
    t.Dependencies.AddUnit('synpluginsyncronizededitbase');
    t.Dependencies.AddUnit('synplugintemplateedit');
    t.Dependencies.AddUnit('lazsynedittext');
    t.Dependencies.AddUnit('lazsyntextarea');
    t.Dependencies.AddUnit('synregexpr');
    t.Dependencies.AddUnit('syntextdrawer');
    t.Dependencies.AddUnit('syneditmarkupguttermark');
    t.Dependencies.AddUnit('synhighlighterbat');
    t.Dependencies.AddUnit('synhighlighterini');
    t.Dependencies.AddUnit('syneditmarkupspecialchar');

    T:=P.Targets.AddUnit('synbeautifier.pas');
    T:=P.Targets.AddUnit('syncompletion.pas');
    P.Sources.AddSrc('lazsynimm.pas');
    T:=P.Targets.AddUnit('synedit.pp');
    T:=P.Targets.AddUnit('syneditautocomplete.pp');
    T:=P.Targets.AddUnit('syneditexport.pas');
    T:=P.Targets.AddUnit('syneditfoldedview.pp');
    T:=P.Targets.AddUnit('synedithighlighter.pp');
    T:=P.Targets.AddUnit('synedithighlighterfoldbase.pas');
    T:=P.Targets.AddUnit('synedithighlighterxmlbase.pas');
    T:=P.Targets.AddUnit('syneditkeycmds.pp');
    T:=P.Targets.AddUnit('lazsyneditmousecmdstypes.pp');
    T:=P.Targets.AddUnit('synhighlighterpo.pp');
    T:=P.Targets.AddUnit('syneditlines.pas');
    T:=P.Targets.AddUnit('syneditmarks.pp');
    T:=P.Targets.AddUnit('syneditmarkup.pp');
    T:=P.Targets.AddUnit('syneditmarkupbracket.pp');
    T:=P.Targets.AddUnit('syneditmarkupctrlmouselink.pp');
    T:=P.Targets.AddUnit('syneditmarkuphighall.pp');
    T:=P.Targets.AddUnit('syneditmarkupselection.pp');
    T:=P.Targets.AddUnit('syneditmarkupspecialline.pp');
    T:=P.Targets.AddUnit('syneditmarkupwordgroup.pp');
    T:=P.Targets.AddUnit('syneditmiscclasses.pp');
    T:=P.Targets.AddUnit('syneditmiscprocs.pp');
    T:=P.Targets.AddUnit('syneditmousecmds.pp');
    T:=P.Targets.AddUnit('syneditplugins.pas');
    T:=P.Targets.AddUnit('syneditpointclasses.pas');
    T:=P.Targets.AddUnit('syneditregexsearch.pas');
    T:=P.Targets.AddUnit('syneditsearch.pp');
    T:=P.Targets.AddUnit('syneditstrconst.pp');
    T:=P.Targets.AddUnit('synedittextbase.pas');
    T:=P.Targets.AddUnit('synedittextbuffer.pp');
    T:=P.Targets.AddUnit('synedittextdoublewidthchars.pas');
    T:=P.Targets.AddUnit('synedittexttabexpander.pas');
    T:=P.Targets.AddUnit('synedittexttrimmer.pas');
    T:=P.Targets.AddUnit('synedittypes.pp');
    T:=P.Targets.AddUnit('synexporthtml.pas');
    T:=P.Targets.AddUnit('syngutter.pp');
    T:=P.Targets.AddUnit('syngutterbase.pp');
    T:=P.Targets.AddUnit('syngutterchanges.pas');
    T:=P.Targets.AddUnit('synguttercodefolding.pp');
    T:=P.Targets.AddUnit('syngutterlinenumber.pp');
    T:=P.Targets.AddUnit('syngutterlineoverview.pp');
    T:=P.Targets.AddUnit('synguttermarks.pp');
    T:=P.Targets.AddUnit('synhighlighterany.pas');
    T:=P.Targets.AddUnit('synhighlightercpp.pp');
    T:=P.Targets.AddUnit('synhighlightercss.pas');
    T:=P.Targets.AddUnit('synhighlighterdiff.pas');
    T:=P.Targets.AddUnit('synhighlighterhashentries.pas');
    T:=P.Targets.AddUnit('synhighlighterhtml.pp');
    T:=P.Targets.AddUnit('synhighlighterjava.pas');
    T:=P.Targets.AddUnit('synhighlighterjscript.pas');
    T:=P.Targets.AddUnit('synhighlighterlfm.pas');
    T:=P.Targets.AddUnit('synhighlightermulti.pas');
    T:=P.Targets.AddUnit('synhighlighterpas.pp');
    T:=P.Targets.AddUnit('synhighlighterperl.pas');
    T:=P.Targets.AddUnit('synhighlighterphp.pas');
    T:=P.Targets.AddUnit('synhighlighterposition.pas');
    T:=P.Targets.AddUnit('synhighlighterpython.pas');
    T:=P.Targets.AddUnit('synhighlightersql.pas');
    T:=P.Targets.AddUnit('synhighlightertex.pas');
    T:=P.Targets.AddUnit('synhighlighterunixshellscript.pas');
    T:=P.Targets.AddUnit('synhighlightervb.pas');
    T:=P.Targets.AddUnit('synhighlighterxml.pas');
    T:=P.Targets.AddUnit('synmacrorecorder.pas');
    T:=P.Targets.AddUnit('synmemo.pas');
    T:=P.Targets.AddUnit('synpluginsyncroedit.pp');
    T:=P.Targets.AddUnit('synpluginsyncronizededitbase.pp');
    T:=P.Targets.AddUnit('synplugintemplateedit.pp');
    T:=P.Targets.AddUnit('lazsynedittext.pas');
    T:=P.Targets.AddUnit('lazsyntextarea.pp');
    T:=P.Targets.AddUnit('synregexpr.pas');
    T:=P.Targets.AddUnit('syntextdrawer.pp');
    T:=P.Targets.AddUnit('syneditmarkupguttermark.pp');
    T:=P.Targets.AddUnit('synhighlighterbat.pas');
    T:=P.Targets.AddUnit('synhighlighterini.pas');
    T:=P.Targets.AddUnit('syneditmarkupspecialchar.pp');

    // copy the compiled file, so the IDE knows how the package was compiled
    P.InstallFiles.Add('SynEdit.compiled',AllOSes,'$(unitinstalldir)');

    end;
end;

{$ifndef ALLPACKAGES}
begin
  add_SynEdit;
  Installer.Run;
end.
{$endif ALLPACKAGES}
