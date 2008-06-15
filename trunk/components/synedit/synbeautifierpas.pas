{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/
Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.
-------------------------------------------------------------------------------}
unit SynBeautifierPas;

{$I synedit.inc}

interface

uses
  Classes, SysUtils, LCLProc, SynEdit;
  
type

  { TSynBeautifierPas }

  TSynBeautifierPas = class(TSynCustomBeautifier)
  public
    function GetIndentForLineBreak(Editor: TCustomSynEdit;
                    InsertPos: TPoint; var NextText: string): integer; override;
  end;

implementation

{ TSynBeautifierPas }

function TSynBeautifierPas.GetIndentForLineBreak(Editor: TCustomSynEdit;
  InsertPos: TPoint; var NextText: string): integer;
begin
  Result:=inherited GetIndentForLineBreak(Editor, InsertPos, NextText);
end;

end.

