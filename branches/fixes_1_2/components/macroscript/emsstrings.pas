unit EMSStrings;

{$mode objfpc}{$H+}

interface

resourcestring
  EmsSelfTestErrCaption = 'Error in EditorMacroScript';
  EmsSelfTestFailed = 'The package EditorMacroScript (pascalscript macros)' +
    ' has detected a problem and was de-activated. %0:s' +
    'The package failed its selftest with the message:%0:s "%1:s"';
  EmsSelfTestFailedLastTime = 'The package EditorMacroScript (pascalscript macros)' +
    ' has detected a problem and was de-activated. %0:s' +
    'The package selftest was not completed during the last start of the IDE"';
  EMSStatusTitle = 'Status';
  EMSEditorMacroTitle = 'Editor Macro Script';
  EMSBtnTestAgain = 'Test again';
  EMSNotSupported = 'Scripting not active. Not supported on this platform or CPU';
  EMSNotActive = 'Scripting not active. Selftest failed';
  EMSActive = 'Scripting active';
  EMSPending = 'Scripting not active. Selftest will run next time the IDE is '
    +'started';

implementation

end.
