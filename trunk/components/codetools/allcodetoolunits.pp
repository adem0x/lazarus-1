{  $Id$  }
{
 /***************************************************************************
                            allcodetoolunits.pp

                      dummy unit to compile all units 

 /***************************************************************************
}
unit AllCodeToolUnits;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF VER2_3}
  MemCheck,
  {$ENDIF}
  CodeToolManager, CustomCodeTool, PascalParserTool, PascalReaderTool,
  FindDeclarationTool, StdCodeTools, MethodJumpTool, EventCodeTool,
  CodeCompletionTool, LinkScanner, FindDeclarationCache, BasicCodeTools,
  CodeTree, CodeAtom, SourceChanger, CodeToolMemManager, CodeCache,
  KeywordFuncLists, SourceLog, ExprEval, DefineTemplates, FileProcs,
  CodeToolsStrConsts, DirectoryCacher,
  MultiKeyWordListTool, ResourceCodeTool, CodeToolsStructs, CacheCodeTools,
  // fast xml units, changes not merged in current fpc
  Laz_DOM, Laz_XMLCfg, Laz_XMLRead, Laz_XMLWrite, Laz_XMLStreaming;

implementation

end.

