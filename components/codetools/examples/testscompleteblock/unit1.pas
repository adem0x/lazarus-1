unit unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

implementation

{$IFDEF record} {$I record1.inc} {$ENDIF}

{$IFDEF procedurebegin} {$I procedurebegin1.inc} {$ENDIF}
{$IFDEF procedurebeginend} {$I procedurebeginend1.inc} {$ENDIF}

{$IFDEF whilebegin} {$I whilebegin1.inc} {$ENDIF}

{$IFDEF caseend} {$I caseend1.inc} {$ENDIF}

{$IFDEF caseelseend} {$I caseelseend1.inc} {$ENDIF}

{$IFDEF casecolon} {$I casecolon1.inc} {$ENDIF}

{$IFDEF repeatifelse} {$I repeatifelse1.inc} {$ENDIF}

{$IFDEF ifbegin} {$I ifbegin1.inc} {$ENDIF}
{$IFDEF beginwithoutindent} {$I beginwithoutindent1.inc} {$ENDIF}

end.

